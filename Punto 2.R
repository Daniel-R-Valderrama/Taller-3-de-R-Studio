# Taller 3, Punto 2
cat("\014")
rm(list = ls())
# ==============================================================================
# Objetivos:
# - 2.A Extraer por web scraping la IBR overnight diaria del Banco de la
#   República (SUAMECA), del 01/01/2020 al 31/10/2025
# - 2.B Obtener por API la SOFR overnight diaria de la Fed de Nueva York, en
#   el mismo periodo
# - 2.C Gráfico de doble eje (SOFR izquierda, IBR derecha) con promedios mensuales
# - Limpiar fechas y valores, verificar las series y exportarlas en CSV y XLSX
# Métodos: IBR con scraping dinámico (chromote, Clase 12.1, ejemplo de la TRM);
#          SOFR con la API de la Fed de Nueva York (Clase 12.2, ejemplo del Banco Mundial)
# ==============================================================================

# ==============================================================================
# CONFIGURACIÓN INICIAL DEL AMBIENTE
# ==============================================================================

# Si es la primera vez o tienen errores de versiones, NO instalen desde aquí:
# corran primero el script 00_reinstalar_paquetes.R en una sesión nueva de R.
# CUIDADO: instalar un paquete que ya está cargado deja la instalación a medias.
# CUIDADO: chromote controla Google Chrome, así que Chrome debe estar instalado.

library(robotstxt)  # lee las reglas del archivo robots.txt
library(httr2)      # petición del robots.txt con user-agent y límite de tiempo
library(chromote)   # navegador "sin pantalla" para páginas dinámicas
library(rvest)      # convierte el HTML de la tabla en data frame
library(stringr)    # manipulación de texto
library(dplyr)      # manipulación de datos
library(openxlsx)   # exportar a Excel
library(ggplot2)    # gráfica estática
library(scales)     # formato de los ejes
library(plotly)     # gráfica interactiva
library(htmlwidgets) # guardar la gráfica interactiva en HTML
library(httr)       # peticiones a APIs (SOFR)
library(jsonlite)   # lectura del formato JSON (SOFR)

#otros paquetes para este punto
# Paquetes no vistos en clase: ninguno

# ==============================================================================
# DIRECTORIO DE TRABAJO
# ==============================================================================

# CUIDADO: esta es la ruta de la carpeta de David (Mac). Cada integrante debe
# ajustarla a la ubicación de SU carpeta "Taller 3".

#Configuración MacOs
username    <- Sys.getenv("USER")      # en Mac es USER; en Windows es USERNAME
ruta_taller <- paste0("/Users/", username, "/Documents/Maestría/R/Taller 3/Taller 3")

#Configuración Windows
#username    <- Sys.getenv("USERNAME")
#ruta_taller <- paste0("C:/Users/", username, "/OneDrive/Escritorio/2026-2/R/Taller 3")

setwd(ruta_taller)

ruta_resultados <- file.path(ruta_taller, "output")
dir.create(ruta_resultados, showWarnings = FALSE)

# Verificación Programática 1: la carpeta de salida existe
if (!dir.exists(ruta_resultados)) {
  cat("Alerta: no existe la carpeta de salida", ruta_resultados, "\n")
} else {
  cat("Verificación exitosa: carpeta de salida en", ruta_resultados, "\n")
}

# ---------- Parámetros del punto ----------
fecha_inicio <- as.Date("2020-01-01")   # inicio del periodo pedido
fecha_fin    <- as.Date("2025-10-31")   # fin del periodo pedido

url_ibr <- "https://suameca.banrep.gov.co/estadisticas-economicas/informacionSerie/241/tasas_interes_indicador_bancario_referencia_ibr"
ruta_ibr <- "/estadisticas-economicas/informacionSerie/241/tasas_interes_indicador_bancario_referencia_ibr"

# CUIDADO: el user-agent le dice al dueño del sitio quién hace las peticiones
# y cómo contactarlo (Clase 12.1).
mi_user_agent <- "Taller 3 de R, Uniandes - scraping educativo (ds.moralesc@uniandes.edu.co)"


# =============================================================================
# BLOQUE 1. ÉTICA WEB: ROBOTS.TXT Y PAUSA
# =============================================================================

# ---------- Función para leer robots.txt (Clase 12.1) ----------
leer_robots <- function(dominio) {
  #' Lee e interpreta el robots.txt de un dominio
  #'
  #' @param dominio Dominio sin "https://", por ejemplo "suameca.banrep.gov.co".
  #' @return Objeto robotstxt con $check(), $permissions y $crawl_delay.
  #' @examples
  #' leer_robots("suameca.banrep.gov.co")

  # - req_timeout(): si el sitio no responde en 20 segundos, se rinde con error
  # - req_error(): no convierte en error los códigos 4xx y 5xx, para revisarlos
  # - Código 404: el sitio no tiene robots.txt, así que no hay reglas que leer
  respuesta <- request(paste0("https://", dominio, "/robots.txt")) %>%
    req_user_agent(mi_user_agent) %>%
    req_timeout(20) %>%
    req_error(is_error = function(resp) FALSE) %>%
    req_perform()

  codigo <- resp_status(respuesta)
  if (!codigo %in% c(200, 404)) {
    stop("No se pudo leer el robots.txt de ", dominio, " (código ", codigo, ").")
  }

  texto_robots <- if (codigo == 200) resp_body_string(respuesta) else ""
  robotstxt(domain = dominio, text = texto_robots)
}

reglas_banrep <- leer_robots("suameca.banrep.gov.co")

# Verificación Programática 2: el robots.txt permite la ruta de la IBR
permitido_ibr <- reglas_banrep$check(paths = ruta_ibr, bot = "*")
if (!permitido_ibr) {
  stop("El robots.txt del BanRep no permite scrapear la ruta de la IBR. No se sigue.")
} else {
  cat("Verificación exitosa: el robots.txt permite la ruta de la IBR\n")
}

# ---------- Pausa mínima entre peticiones ----------
# Si el sitio no pide un crawl delay, se esperan 5 segundos de todos modos
pausa_segundos <- max(5, as.numeric(reglas_banrep$crawl_delay$value), na.rm = TRUE)
pausa_segundos


# =============================================================================
# BLOQUE 2. SCRAPING DINÁMICO DE LA IBR CON CHROMOTE
# =============================================================================

# La página de SUAMECA arma los datos con JavaScript: no vienen en el HTML
# inicial. La tabla con toda la serie diaria solo aparece después de hacer
# clic en "Vista tabla". Por eso se controla un navegador (Clase 12.1, TRM).
# CUIDADO: es la parte más pesada. Puede tardar uno o dos minutos.

# ---------- Abrir Chrome y el visor ----------
navegador <- ChromoteSession$new()
# CUIDADO: $view() abre el visor en el Chrome normal, con el perfil del usuario.
# En Mac falla con "Failed to create ... SingletonLock: Operation not permitted"
# si Chrome ya está abierto o RStudio no tiene permiso sobre ese perfil. El
# visor solo sirve para mirar: el scraping funciona igual sin él. Si quieren
# verlo, cierren Chrome por completo (Cmd + Q) y quiten el # de la línea.
#navegador$view()                        # ventana para ver lo que hace el navegador

# ---------- Esperar sin adivinar los segundos (Clase 12.1) ----------
esperar_a <- function(codigo_js, max_segundos = 60) {
  #' Espera a que una condición JavaScript se cumpla en la página
  #'
  #' @param codigo_js Código JavaScript que responde true o false.
  #' @param max_segundos Tiempo máximo de espera.
  #' @return TRUE apenas se cumple la condición; FALSE si se acaba el tiempo.
  #' @examples
  #' esperar_a("document.querySelector('#vistaTabla') !== null")

  for (i in 1:(max_segundos / 2)) {
    Sys.sleep(2)
    listo <- navegador$Runtime$evaluate(codigo_js)$result$value
    if (isTRUE(listo)) return(TRUE)
  }
  FALSE
}

# ---------- Navegar a la página de la IBR ----------
Sys.sleep(pausa_segundos)                # pausa después de pedir el robots.txt
fecha_consulta_ibr <- Sys.time()         # Función no vista: fecha y hora de la consulta
navegador$Page$navigate(url_ibr)

# La página está lista cuando ya se dibujó la gráfica y el botón dice "Vista tabla"
js_hay_boton_tabla <- "
  (document.querySelector('#vistaTabla') || {textContent: ''}).textContent.includes('Vista tabla') &&
  document.querySelector('.highcharts-container') !== null
"

if (!esperar_a(js_hay_boton_tabla)) {
  stop("La página de la IBR no cargó o el botón 'Vista tabla' cambió. Revisen el visor.")
}

# ---------- Clic en "Vista tabla" ----------
navegador$Runtime$evaluate("document.querySelector('#vistaTabla').click()")

# CUIDADO: la IBR se publica desde 2008, así que la tabla completa tiene miles
# de filas. Se espera a que tenga más de 100 para saber que ya se dibujó.
js_hay_tabla_ibr <- "
  document.querySelectorAll('[id^=\"highcharts-data-table\"] tr').length > 100
"

if (!esperar_a(js_hay_tabla_ibr)) {
  stop("La tabla de la IBR no cargó. Revisen en el visor si el botón funcionó.")
}

# ---------- Extraer solo la tabla y cerrar el navegador ----------
html_ibr <- navegador$Runtime$evaluate(
  "document.querySelector('[id^=\"highcharts-data-table\"]').outerHTML"
)$result$value

navegador$close()

# Se guarda el HTML para poder inspeccionarlo si algo falla (Clase 12.1)
writeLines(html_ibr, file.path(ruta_resultados, "2_A_ibr_tabla_html.txt"))

# ---------- Del HTML a un data frame ----------
ibr_raw <- read_html(html_ibr) %>%
  html_element("table") %>%
  html_table()


ibr_raw <- as.data.frame(ibr_raw)        # el tibble de rvest pasa a data frame

# Verificación
dim(ibr_raw)
names(ibr_raw)
head(ibr_raw)


# =============================================================================
# BLOQUE 3. SELECCIÓN DE LA SERIE OVERNIGHT
# =============================================================================

# CUIDADO: la página puede traer varias series (plazos de la IBR, nominal o
# efectiva). La columna se busca por su NOMBRE, no por su posición, porque el
# orden puede cambiar si el BanRep edita la página.
# La primera columna es la fecha.
col_fecha <- names(ibr_raw)[1]
col_ibr   <- names(ibr_raw)[str_detect(tolower(names(ibr_raw)), "overnight")]

# Si la tabla trae una sola serie, esa es la de la página (serie 241)
if (length(col_ibr) == 0 & ncol(ibr_raw) == 2) {
  col_ibr <- names(ibr_raw)[2]
}

# Verificación Programática 3: se encontró exactamente una columna de IBR overnight
if (length(col_ibr) != 1) {
  stop("No se encontró una única columna de IBR overnight. Columnas: ",
       paste(names(ibr_raw), collapse = " | "))
} else {
  cat("Verificación exitosa: columna de fecha =", col_fecha,
      "| columna de IBR =", col_ibr, "\n")
}


# =============================================================================
# BLOQUE 4. LIMPIEZA DE FECHAS Y VALORES
# =============================================================================

# ---------- Texto a número ----------
# CUIDADO: si la tabla trae coma decimal ("4,114"), as.numeric() da NA.
# Se reemplaza la coma por punto antes de convertir.
valores_ibr <- as.character(ibr_raw[[col_ibr]])
valores_ibr <- str_replace(valores_ibr, ",", ".")

# ---------- Texto a fecha (Clase 8) ----------
# El formato de la tabla de SUAMECA es "AAAA/MM/DD" (igual que la TRM, Clase 12.1)
ibr_diaria <- data.frame(
  fecha   = as.Date(as.character(ibr_raw[[col_fecha]]), format = "%Y/%m/%d"),
  ibr_pct = as.numeric(valores_ibr)
)

# Verificación Programática 4: ninguna fecha ni valor quedó en NA al convertir
na_fecha <- sum(is.na(ibr_diaria$fecha))
na_valor <- sum(is.na(ibr_diaria$ibr_pct))
if (na_fecha > 0 | na_valor > 0) {
  cat("Alerta:", na_fecha, "fechas y", na_valor, "valores quedaron en NA.",
      "Revisen el formato en 2_A_ibr_tabla_html.txt\n")
} else {
  cat("Verificación exitosa: todas las fechas y valores se convirtieron\n")
}

range(ibr_diaria$fecha, na.rm = TRUE)    # toda la historia publicada (desde 2008)

# ---------- Filtro del periodo pedido ----------
ibr_on <- ibr_diaria %>%
  filter(fecha >= fecha_inicio,
         fecha <= fecha_fin) %>%
  arrange(fecha)

# Verificación Programática 5: rango de fechas, observaciones y duplicados
range(ibr_on$fecha)                      # 2020-01-02 a 2025-10-31 (el 1 de enero es festivo)
nrow(ibr_on)                             # días hábiles con dato (aprox. 1.426)
duplicados_ibr <- length(ibr_on$fecha) - length(unique(ibr_on$fecha))

if (min(ibr_on$fecha) < fecha_inicio | max(ibr_on$fecha) > fecha_fin) {
  cat("Alerta: hay fechas fuera del periodo pedido\n")
} else if (duplicados_ibr > 0) {
  cat("Alerta: hay", duplicados_ibr, "fechas repetidas\n")
} else {
  cat("Verificación exitosa:", nrow(ibr_on), "días con dato entre",
      format(min(ibr_on$fecha), "%d/%m/%Y"), "y",
      format(max(ibr_on$fecha), "%d/%m/%Y"), "sin fechas repetidas\n")
}

summary(ibr_on$ibr_pct)

# ---------- Contraste con la fuente oficial ----------
# Valores que muestra la página de SUAMECA, revisados a mano en la página
# CHEQUEO: debe salir 2020-01-02 = 4,114 | 2023-06-30 = 12,270 | 2025-10-31 = 8,730
ibr_on %>% filter(fecha %in% as.Date(c("2020-01-02", "2023-06-30", "2025-10-31")))


# =============================================================================
# BLOQUE 5. CALENDARIO DIARIO COMPLETO
# =============================================================================

# La IBR solo se publica en días hábiles de Colombia. Para unirla después con
# la SOFR se arma un calendario con TODOS los días del periodo (Clase 8).
# Paso 1: secuencia con todos los días
fechas <- data.frame(fecha = seq(fecha_inicio, fecha_fin, by = "day"))

# Paso 2: pegar la IBR al calendario
ibr_on_calendario <- fechas %>%
  left_join(ibr_on, by = "fecha")

# Verificación Programática 6: el pegue no duplica filas y todas las fechas tienen pareja
if (nrow(ibr_on_calendario) != nrow(fechas)) {
  cat("Alerta: el pegue con el calendario cambió el número de filas\n")
} else if (sum(!(ibr_on$fecha %in% fechas$fecha)) > 0) {
  cat("Alerta: hay fechas de la IBR que no están en el calendario\n")
} else {
  cat("Verificación exitosa:", nrow(fechas), "días en el calendario;",
      sum(is.na(ibr_on_calendario$ibr_pct)), "sin IBR (fines de semana y festivos)\n")
}

# CUIDADO: en tasas, un día sin dato NO es cero. Se deja NA y se explica en
# el documento cómo se trató.


# =============================================================================
# BLOQUE 6. EXPORTAR RESULTADOS
# =============================================================================

# ---------- Registro de la extracción ----------
registro_ibr <- data.frame(
  fuente         = "Banco de la República, SUAMECA (serie 241)",
  serie          = col_ibr,
  metodo         = "Web scraping dinámico (chromote, botón 'Vista tabla')",
  url            = url_ibr,
  fecha_consulta = format(fecha_consulta_ibr, "%d/%m/%Y %H:%M"),
  # Unidad y convención: glosario del BanRep (https://www.banrep.gov.co/es/glosario/ibr)
  # y ficha metodológica del IBR (BanRep / Asobancaria)
  unidad         = "Porcentaje (%) nominal anual",
  convencion     = "Tasa nominal base 360 (año de 360 días y mes de 30 días); el BanRep publica además la tasa efectiva",
  n_obs          = nrow(ibr_on),
  fecha_min      = format(min(ibr_on$fecha), "%d/%m/%Y"),
  fecha_max      = format(max(ibr_on$fecha), "%d/%m/%Y")
)

registro_ibr

# ---------- CSV ----------
write.csv(ibr_on,            file.path(ruta_resultados, "2_A_ibr_on_dias_habiles.csv"), row.names = FALSE)
write.csv(ibr_on_calendario, file.path(ruta_resultados, "2_A_ibr_on_calendario.csv"),   row.names = FALSE)

# ---------- XLSX (una hoja por tabla) ----------
write.xlsx(list("Dias habiles" = ibr_on,
                "Calendario"   = ibr_on_calendario,
                "Registro"     = registro_ibr),
           file.path(ruta_resultados, "2_A_ibr_on.xlsx"),
           overwrite = TRUE)

# Verificación Programática 7: los archivos se escribieron y el CSV conserva las filas
archivos_ibr <- file.path(ruta_resultados, c("2_A_ibr_on_dias_habiles.csv",
                                             "2_A_ibr_on_calendario.csv",
                                             "2_A_ibr_on.xlsx"))
ibr_csv <- read.csv(archivos_ibr[1])

if (!all(file.exists(archivos_ibr))) {
  cat("Alerta: falta algún archivo de salida\n")
} else if (nrow(ibr_csv) != nrow(ibr_on)) {
  cat("Alerta: el CSV no conserva todas las filas\n")
} else {
  cat("Verificación exitosa: archivos guardados en", ruta_resultados, "\n")
}

list.files(ruta_resultados, pattern = "^2_A_")

# =============================================================================
# BLOQUE 7. GRÁFICAS DE LA IBR OVERNIGHT DIARIA
# =============================================================================

# CUIDADO: se grafica la base de DÍAS HÁBILES. Con la del calendario, la línea
# se cortaría en cada fin de semana y festivo (NA).

# ---------- Máximo y mínimo del periodo (para el subtítulo) ----------
fila_max <- ibr_on[which.max(ibr_on$ibr_pct), ]
fila_min <- ibr_on[which.min(ibr_on$ibr_pct), ]

# sprintf: tasa con 2 decimales y fecha en formato dd/mm/aaaa dentro del texto
texto_extremos <- sprintf("Máximo: %.2f %% (%s). Mínimo: %.2f %% (%s).",
                          fila_max$ibr_pct, format(fila_max$fecha, "%d/%m/%Y"),
                          fila_min$ibr_pct, format(fila_min$fecha, "%d/%m/%Y"))
texto_extremos

# ---------- Gráfica estática ----------
g_ibr_diaria <- ggplot(ibr_on, aes(x = fecha, y = ibr_pct)) +
  geom_line(color = "#1F5F99", linewidth = 0.6) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %", decimal.mark = ",")) +
  labs(title    = "IBR overnight diaria",
       subtitle = paste0("Días hábiles, ", format(fecha_inicio, "%d/%m/%Y"), " a ",
                         format(fecha_fin, "%d/%m/%Y"), ". ", texto_extremos),
       x        = "Fecha",
       y        = "IBR overnight nominal (%)",
       caption  = "Fuente: Banco de la República, SUAMECA (serie 241). Web scraping. Cálculos propios.") +
  theme_bw() +
  theme(plot.title  = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

g_ibr_diaria

ggsave(filename = file.path(ruta_resultados, "2_A_ibr_on_diaria.png"),
       plot = g_ibr_diaria, width = 10, height = 6, units = "in", dpi = 300)

# ---------- Gráfica interactiva (patrón Clase 8: ggplot a plotly) ----------
# Columna de texto para el tooltip (<b> = negrilla, <br> = salto de línea)
ibr_on_int <- ibr_on %>%
  mutate(text = paste0("<b>", format(fecha, "%d/%m/%Y"), "</b>",
                       "<br>IBR ON: ", round(ibr_pct, 3), " %"))

# CUIDADO: el aes "text" rompe la agrupación de la línea; group = 1 la une de nuevo
g_ibr_int <- ggplot(ibr_on_int, aes(x = fecha, y = ibr_pct, text = text)) +
  geom_line(aes(group = 1), color = "#1F5F99", linewidth = 0.6) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %")) +
  labs(x = "Fecha",
       y = "IBR overnight nominal (%)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# CUIDADO: ggplotly() no conserva el subtítulo ni el caption de ggplot. Se
# agregan con layout(): el periodo debajo del título y la fuente como anotación.
p_ibr_diaria <- ggplotly(g_ibr_int, tooltip = "text") %>%
  layout(title = list(text = paste0("<b>IBR overnight diaria</b>",
                                    "<br><sup>Días hábiles, ",
                                    format(fecha_inicio, "%d/%m/%Y"), " a ",
                                    format(fecha_fin, "%d/%m/%Y"), "</sup>")),
         annotations = list(                     # Función no vista: argumento de layout() para texto libre
           text      = "Fuente: Banco de la República, SUAMECA (serie 241). Web scraping. Cálculos propios.",
           x = 0, y = -0.25, xref = "paper", yref = "paper",
           showarrow = FALSE, xanchor = "left",
           font      = list(size = 10, color = "gray")))

p_ibr_diaria

htmlwidgets::saveWidget(widget = p_ibr_diaria,
                        file = file.path(ruta_resultados, "2_A_ibr_on_diaria.html"),
                        selfcontained = TRUE)

# Verificación Programática 8: las dos gráficas se guardaron
archivos_graf <- file.path(ruta_resultados, c("2_A_ibr_on_diaria.png", "2_A_ibr_on_diaria.html"))
if (!all(file.exists(archivos_graf))) {
  cat("Alerta: falta alguna gráfica en", ruta_resultados, "\n")
} else {
  cat("Verificación exitosa: gráficas guardadas en", ruta_resultados, "\n")
}

# ---------- Memoria ----------
rm(html_ibr, ibr_raw, ibr_diaria, valores_ibr, fechas, ibr_csv, ibr_on_int, g_ibr_int)


# =============================================================================
# BLOQUE 8. 2.B CONSULTA A LA API DE LA FED DE NUEVA YORK (SOFR)
# =============================================================================

# La SOFR la calcula y publica la Fed de Nueva York. Su API de datos de mercado
# (Markets Data API) es pública y no pide clave. Documentación:
#   https://markets.newyorkfed.org/static/docs/markets-api.html

# URL raíz de la API: tasas de referencia garantizadas (secured), serie SOFR,
# búsqueda por rango de fechas, respuesta en JSON
url_api_sofr <- "https://markets.newyorkfed.org/api/rates/secured/sofr/search.json"

# Los parámetros salen de la documentación. Cada uno filtra la consulta:
# - startDate / endDate: el rango de fechas, en formato AAAA-MM-DD
parametros_sofr <- list(
  startDate = format(fecha_inicio, "%Y-%m-%d"),
  endDate   = format(fecha_fin,    "%Y-%m-%d")
)

# ---------- Consulta a la API ----------
# GET() pega la URL raíz con los parámetros y hace la petición
fecha_consulta_sofr <- Sys.time()        # Función no vista: fecha y hora de la consulta
respuesta_sofr <- GET(url = url_api_sofr, query = parametros_sofr)

# El link completo que se construyó (raíz + "?" + parámetros unidos con "&").
# Se puede pegar en el navegador y devuelve lo mismo.
respuesta_sofr$url

# Código de estado: 200 significa que la petición salió bien
status_code(respuesta_sofr)

# Si el código no es 200, detiene el script con un mensaje claro
stop_for_status(respuesta_sofr)


# =============================================================================
# BLOQUE 9. DEL JSON A UN DATA FRAME (SOFR)
# =============================================================================

texto_json_sofr <- content(respuesta_sofr, as = "text", encoding = "UTF-8")
datos_json_sofr <- fromJSON(texto_json_sofr)

# Los datos están en el elemento "refRates": una fila por día con la fecha
# (effectiveDate), el tipo de tasa (type) y la tasa en porcentaje (percentRate)
names(datos_json_sofr)
sofr_raw <- datos_json_sofr$refRates

# Verificación
dim(sofr_raw)
names(sofr_raw)
head(sofr_raw)

# Verificación Programática 9: la respuesta trae los campos esperados
campos_sofr <- c("effectiveDate", "type", "percentRate")
if (!all(campos_sofr %in% names(sofr_raw))) {
  stop("La respuesta de la API no trae los campos esperados. Campos: ",
       paste(names(sofr_raw), collapse = " | "))
} else if (any(sofr_raw$type != "SOFR")) {
  cat("Alerta: la respuesta trae tasas distintas a la SOFR:",
      paste(unique(sofr_raw$type), collapse = ", "), "\n")
} else {
  cat("Verificación exitosa: la respuesta trae solo la SOFR, con",
      nrow(sofr_raw), "registros\n")
}

# ---------- Limpieza: renombrar y pasar texto a número y a fecha ----------
# CUIDADO: la API devuelve los días del más reciente al más antiguo; se ordena
sofr_on <- sofr_raw %>%
  filter(type == "SOFR") %>%
  select(fecha = effectiveDate, sofr_pct = percentRate) %>%
  mutate(fecha    = as.Date(fecha, format = "%Y-%m-%d"),
         sofr_pct = as.numeric(sofr_pct)) %>%
  filter(fecha >= fecha_inicio,
         fecha <= fecha_fin) %>%
  arrange(fecha)

# Verificación Programática 10: ninguna fecha ni valor quedó en NA al convertir
na_fecha_sofr <- sum(is.na(sofr_on$fecha))
na_valor_sofr <- sum(is.na(sofr_on$sofr_pct))
if (na_fecha_sofr > 0 | na_valor_sofr > 0) {
  cat("Alerta:", na_fecha_sofr, "fechas y", na_valor_sofr, "valores quedaron en NA\n")
} else {
  cat("Verificación exitosa: todas las fechas y valores se convirtieron\n")
}

# Verificación Programática 11: rango de fechas, observaciones y duplicados
range(sofr_on$fecha)                     # 2020-01-02 a 2025-10-31 (el 1 de enero es festivo)
nrow(sofr_on)                            # días hábiles de EE. UU. con dato (aprox. 1.458)
duplicados_sofr <- length(sofr_on$fecha) - length(unique(sofr_on$fecha))

if (min(sofr_on$fecha) < fecha_inicio | max(sofr_on$fecha) > fecha_fin) {
  cat("Alerta: hay fechas fuera del periodo pedido\n")
} else if (duplicados_sofr > 0) {
  cat("Alerta: hay", duplicados_sofr, "fechas repetidas\n")
} else {
  cat("Verificación exitosa:", nrow(sofr_on), "días con dato entre",
      format(min(sofr_on$fecha), "%d/%m/%Y"), "y",
      format(max(sofr_on$fecha), "%d/%m/%Y"), "sin fechas repetidas\n")
}

summary(sofr_on$sofr_pct)

# ---------- Contraste con la fuente oficial ----------
# Valores publicados en https://www.newyorkfed.org/markets/reference-rates/sofr
# CHEQUEO: debe salir 2020-01-02 = 1,54 | 2023-06-30 = 5,09 | 2025-10-31 = 4,22
sofr_on %>% filter(fecha %in% as.Date(c("2020-01-02", "2023-06-30", "2025-10-31")))


# =============================================================================
# BLOQUE 10. CALENDARIO DIARIO COMPLETO (SOFR)
# =============================================================================

# Mismo calendario que la IBR (Clase 8). Se arma de nuevo para que el bloque
# no dependa de haber corrido el punto 2.A.
# Paso 1: secuencia con todos los días
fechas <- data.frame(fecha = seq(fecha_inicio, fecha_fin, by = "day"))

# Paso 2: pegar la SOFR al calendario
sofr_on_calendario <- fechas %>%
  left_join(sofr_on, by = "fecha")

# Verificación Programática 12: el pegue no duplica filas y todas las fechas tienen pareja
if (nrow(sofr_on_calendario) != nrow(fechas)) {
  cat("Alerta: el pegue con el calendario cambió el número de filas\n")
} else if (sum(!(sofr_on$fecha %in% fechas$fecha)) > 0) {
  cat("Alerta: hay fechas de la SOFR que no están en el calendario\n")
} else {
  cat("Verificación exitosa:", nrow(fechas), "días en el calendario;",
      sum(is.na(sofr_on_calendario$sofr_pct)), "sin SOFR (fines de semana y festivos de EE. UU.)\n")
}

# CUIDADO: los festivos de Colombia y de EE. UU. no coinciden. Hay días con IBR
# y sin SOFR, y al revés. Se dejan NA; no se rellenan ni se ponen en cero.


# =============================================================================
# BLOQUE 11. EXPORTAR RESULTADOS (SOFR)
# =============================================================================

# ---------- Registro de la extracción ----------
registro_sofr <- data.frame(
  fuente         = "Federal Reserve Bank of New York, Markets Data API",
  serie          = "SOFR (Secured Overnight Financing Rate)",
  metodo         = "API (GET + JSON)",
  url            = respuesta_sofr$url,
  fecha_consulta = format(fecha_consulta_sofr, "%d/%m/%Y %H:%M"),
  unidad         = "Porcentaje anual",
  # Convención: página "Additional Information about Reference Rates Administered by the
  # New York Fed" (https://www.newyorkfed.org/markets/reference-rates/additional-information-about-reference-rates)
  convencion     = "Actual/360 (días calendario reales sobre un año de 360 días); mediana ponderada por volumen (percentil 50) de repos overnight con garantía de Tesoros de EE. UU., redondeada al punto básico",
  n_obs          = nrow(sofr_on),
  fecha_min      = format(min(sofr_on$fecha), "%d/%m/%Y"),
  fecha_max      = format(max(sofr_on$fecha), "%d/%m/%Y")
)

registro_sofr

# ---------- CSV ----------
write.csv(sofr_on,            file.path(ruta_resultados, "2_B_sofr_on_dias_habiles.csv"), row.names = FALSE)
write.csv(sofr_on_calendario, file.path(ruta_resultados, "2_B_sofr_on_calendario.csv"),   row.names = FALSE)

# ---------- XLSX (una hoja por tabla) ----------
write.xlsx(list("Dias habiles" = sofr_on,
                "Calendario"   = sofr_on_calendario,
                "Registro"     = registro_sofr),
           file.path(ruta_resultados, "2_B_sofr_on.xlsx"),
           overwrite = TRUE)

# Verificación Programática 13: los archivos se escribieron y el CSV conserva las filas
archivos_sofr <- file.path(ruta_resultados, c("2_B_sofr_on_dias_habiles.csv",
                                              "2_B_sofr_on_calendario.csv",
                                              "2_B_sofr_on.xlsx"))
sofr_csv <- read.csv(archivos_sofr[1])

if (!all(file.exists(archivos_sofr))) {
  cat("Alerta: falta algún archivo de salida\n")
} else if (nrow(sofr_csv) != nrow(sofr_on)) {
  cat("Alerta: el CSV no conserva todas las filas\n")
} else {
  cat("Verificación exitosa: archivos guardados en", ruta_resultados, "\n")
}

list.files(ruta_resultados, pattern = "^2_B_")

# =============================================================================
# BLOQUE 12. GRÁFICAS DE LA SOFR OVERNIGHT DIARIA
# =============================================================================

# CUIDADO: se grafica la base de DÍAS HÁBILES (de EE. UU.). Con la del
# calendario, la línea se cortaría en cada fin de semana y festivo (NA).
# Se usa el verde del grupo para distinguirla del azul de la IBR.
color_sofr <- "#2E8B57"                  # verde (paleta de los Talleres 1 y 2)

# ---------- Máximo y mínimo del periodo (para el subtítulo) ----------
fila_max_sofr <- sofr_on[which.max(sofr_on$sofr_pct), ]
fila_min_sofr <- sofr_on[which.min(sofr_on$sofr_pct), ]

# CUIDADO: la SOFR estuvo varios días seguidos en su mínimo (2020-2021);
# which.min() devuelve el PRIMER día en que se alcanzó.
# sprintf: tasa con 2 decimales y fecha en formato dd/mm/aaaa dentro del texto
texto_extremos_sofr <- sprintf("Máximo: %.2f %% (%s). Mínimo: %.2f %% (primera vez: %s).",
                               fila_max_sofr$sofr_pct, format(fila_max_sofr$fecha, "%d/%m/%Y"),
                               fila_min_sofr$sofr_pct, format(fila_min_sofr$fecha, "%d/%m/%Y"))
texto_extremos_sofr

# ---------- Gráfica estática ----------
g_sofr_diaria <- ggplot(sofr_on, aes(x = fecha, y = sofr_pct)) +
  geom_line(color = color_sofr, linewidth = 0.6) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %", decimal.mark = ",")) +
  labs(title    = "SOFR overnight diaria",
       subtitle = paste0("Días hábiles de EE. UU., ", format(fecha_inicio, "%d/%m/%Y"), " a ",
                         format(fecha_fin, "%d/%m/%Y"), ". ", texto_extremos_sofr),
       x        = "Fecha",
       y        = "SOFR overnight, tasa anual (%)",
       caption  = "Fuente: Federal Reserve Bank of New York, Markets Data API. Cálculos propios.") +
  theme_bw() +
  theme(plot.title  = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

g_sofr_diaria

ggsave(filename = file.path(ruta_resultados, "2_B_sofr_on_diaria.png"),
       plot = g_sofr_diaria, width = 10, height = 6, units = "in", dpi = 300)

# ---------- Gráfica interactiva (patrón Clase 8: ggplot a plotly) ----------
# Columna de texto para el tooltip (<b> = negrilla, <br> = salto de línea)
sofr_on_int <- sofr_on %>%
  mutate(text = paste0("<b>", format(fecha, "%d/%m/%Y"), "</b>",
                       "<br>SOFR ON: ", round(sofr_pct, 2), " %"))

# CUIDADO: el aes "text" rompe la agrupación de la línea; group = 1 la une de nuevo
g_sofr_int <- ggplot(sofr_on_int, aes(x = fecha, y = sofr_pct, text = text)) +
  geom_line(aes(group = 1), color = color_sofr, linewidth = 0.6) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %")) +
  labs(x = "Fecha",
       y = "SOFR overnight, tasa anual (%)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# CUIDADO: ggplotly() no conserva el subtítulo ni el caption de ggplot. Se
# agregan con layout(): el periodo debajo del título y la fuente como anotación.
p_sofr_diaria <- ggplotly(g_sofr_int, tooltip = "text") %>%
  layout(title = list(text = paste0("<b>SOFR overnight diaria</b>",
                                    "<br><sup>Días hábiles de EE. UU., ",
                                    format(fecha_inicio, "%d/%m/%Y"), " a ",
                                    format(fecha_fin, "%d/%m/%Y"), "</sup>")),
         annotations = list(                     # Función no vista: argumento de layout() para texto libre
           text      = "Fuente: Federal Reserve Bank of New York, Markets Data API. Cálculos propios.",
           x = 0, y = -0.25, xref = "paper", yref = "paper",
           showarrow = FALSE, xanchor = "left",
           font      = list(size = 10, color = "gray")))

p_sofr_diaria

htmlwidgets::saveWidget(widget = p_sofr_diaria,
                        file = file.path(ruta_resultados, "2_B_sofr_on_diaria.html"),
                        selfcontained = TRUE)

# Verificación Programática 14: las dos gráficas se guardaron
archivos_graf_sofr <- file.path(ruta_resultados, c("2_B_sofr_on_diaria.png", "2_B_sofr_on_diaria.html"))
if (!all(file.exists(archivos_graf_sofr))) {
  cat("Alerta: falta alguna gráfica en", ruta_resultados, "\n")
} else {
  cat("Verificación exitosa: gráficas guardadas en", ruta_resultados, "\n")
}

# ---------- Memoria ----------
rm(texto_json_sofr, datos_json_sofr, sofr_raw, fechas, sofr_csv, sofr_on_int, g_sofr_int)


# =============================================================================
# BLOQUE 13. 2.C PROMEDIOS MENSUALES SOBRE LOS DÍAS HÁBILES DE CADA TASA
# =============================================================================

# CUIDADO: cada tasa se promedia sobre SUS PROPIOS días hábiles, por separado.
# Si primero se unieran por fecha y se dejaran solo los días con ambas tasas,
# se perderían los festivos de EE. UU. que son hábiles en Colombia (y al revés).
# Así los días sin dato (fines de semana y festivos) no entran al promedio.

# ---------- Promedio mensual de la IBR ----------
# mes = primer día del mes, para que el eje x siga siendo una fecha
ibr_mensual <- ibr_on %>%
  mutate(mes = as.Date(format(fecha, "%Y-%m-01"))) %>%
  group_by(mes) %>%
  summarise(dias_ibr = n(),                # días hábiles de Colombia usados en el promedio
            ibr_pct  = mean(ibr_pct),
            .groups  = "drop")

# ---------- Promedio mensual de la SOFR ----------
sofr_mensual <- sofr_on %>%
  mutate(mes = as.Date(format(fecha, "%Y-%m-01"))) %>%
  group_by(mes) %>%
  summarise(dias_sofr = n(),               # días hábiles de EE. UU. usados en el promedio
            sofr_pct  = mean(sofr_pct),
            .groups   = "drop")

# CUIDADO: dentro de summarise() el conteo va ANTES del promedio, porque la
# columna que se sobrescribe (ibr_pct, sofr_pct) cambia para las líneas siguientes.

# Verificación Programática 15: 70 meses (ene-2020 a oct-2025) y todos los días entran a algún mes
n_meses <- length(seq(fecha_inicio, fecha_fin, by = "month"))   # 70
if (nrow(ibr_mensual) != n_meses | nrow(sofr_mensual) != n_meses) {
  cat("Alerta: el número de meses no es", n_meses, "\n")
} else if (sum(ibr_mensual$dias_ibr) != nrow(ibr_on) | sum(sofr_mensual$dias_sofr) != nrow(sofr_on)) {
  cat("Alerta: hay días que no entraron a ningún promedio mensual\n")
} else {
  cat("Verificación exitosa:", n_meses, "meses por tasa; todos los días hábiles entran al promedio\n")
}

range(ibr_mensual$dias_ibr)                # días hábiles por mes en Colombia (aprox. 18 a 23)
range(sofr_mensual$dias_sofr)              # días hábiles por mes en EE. UU.

# ---------- Unión de los promedios mensuales ----------
# Se unen los PROMEDIOS (ya calculados por separado), no los datos diarios
filas_antes <- nrow(sofr_mensual)
tasas_mensual <- sofr_mensual %>%
  left_join(ibr_mensual, by = "mes")

# Verificación Programática 16: el pegue no cambia las filas y todos los meses tienen pareja
if (nrow(tasas_mensual) != filas_antes) {
  cat("Alerta: el pegue de los promedios cambió el número de filas\n")
} else if (sum(is.na(tasas_mensual$ibr_pct)) > 0) {
  cat("Alerta: hay", sum(is.na(tasas_mensual$ibr_pct)), "meses sin IBR\n")
} else {
  cat("Verificación exitosa:", nrow(tasas_mensual), "meses con las dos tasas\n")
}

head(tasas_mensual)

# ---------- Exportar los promedios mensuales ----------
write.csv(tasas_mensual, file.path(ruta_resultados, "2_C_tasas_promedio_mensual.csv"), row.names = FALSE)
write.xlsx(list("Promedio mensual" = tasas_mensual),
           file.path(ruta_resultados, "2_C_tasas_promedio_mensual.xlsx"),
           overwrite = TRUE)


# =============================================================================
# BLOQUE 14. 2.C GRÁFICO DE DOBLE EJE: SOFR IZQUIERDA, IBR DERECHA
# =============================================================================

color_ibr <- "#1F5F99"                     # azul, igual que la gráfica diaria de la IBR

titulo_doble    <- "IBR overnight y SOFR overnight: promedio mensual"
periodo_doble   <- paste0("Periodo: ", format(fecha_inicio, "%d/%m/%Y"), " a ",
                          format(fecha_fin, "%d/%m/%Y"),
                          ". Promedio de los días hábiles de cada país.")
fuente_doble    <- paste0("Fuente: Banco de la República, SUAMECA (serie 241, web scraping); ",
                          "Federal Reserve Bank of New York, Markets Data API. Cálculos propios.")
eje_sofr_doble  <- "SOFR ON: tasa anual (%)"
eje_ibr_doble   <- "IBR ON: tasa nominal (%)"

# ---------- Transformación min-max para el eje secundario (Clase 8) ----------
# ggplot solo tiene un eje y de verdad: la IBR se reescala al rango de la SOFR
# para dibujarla, y sec_axis() deshace la transformación para rotular el eje
# derecho con los valores reales de la IBR.
min_sofr  <- min(tasas_mensual$sofr_pct)
min_ibr   <- min(tasas_mensual$ibr_pct)
pendiente <- (max(tasas_mensual$sofr_pct) - min_sofr) /
             (max(tasas_mensual$ibr_pct)  - min_ibr)

tasas_mensual <- tasas_mensual %>%
  mutate(ibr_escalada = min_sofr + (ibr_pct - min_ibr) * pendiente)

# Verificación Programática 17: al deshacer la transformación se recupera la IBR original
ibr_recuperada <- min_ibr + (tasas_mensual$ibr_escalada - min_sofr) / pendiente
if (any(abs(ibr_recuperada - tasas_mensual$ibr_pct) > 1e-6)) {
  cat("Alerta: la transformación del eje derecho no recupera la IBR\n")
} else {
  cat("Verificación exitosa: el eje derecho muestra los valores reales de la IBR\n")
}

# CUIDADO (Clase 8): con min-max las dos líneas comparten mínimo y máximo por
# construcción. Que se crucen o se separen NO significa que una tasa sea mayor;
# cada línea se lee en su propio eje y lo comparable es la FORMA de cada serie.

# ---------- Gráfico estático ----------
g_doble_eje <- ggplot(tasas_mensual, aes(x = mes)) +
  geom_line(aes(y = sofr_pct,     color = "SOFR ON (eje izquierdo)"), linewidth = 1) +
  geom_line(aes(y = ibr_escalada, color = "IBR ON (eje derecho)"),    linewidth = 1) +
  scale_y_continuous(name     = eje_sofr_doble,
                     labels   = label_number(suffix = " %", decimal.mark = ","),
                     sec.axis = sec_axis(~ min_ibr + (. - min_sofr) / pendiente,
                                         name   = eje_ibr_doble,
                                         labels = label_number(suffix = " %", decimal.mark = ","))) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_color_manual(values = c("SOFR ON (eje izquierdo)" = color_sofr,
                                "IBR ON (eje derecho)"    = color_ibr)) +
  labs(title    = titulo_doble,
       subtitle = periodo_doble,
       x        = "Mes",
       color    = NULL,
       caption  = fuente_doble) +
  theme_bw() +
  theme(plot.title         = element_text(face = "bold"),
        legend.position    = "bottom",
        axis.text.x        = element_text(angle = 45, hjust = 1),
        axis.title.y.left  = element_text(color = color_sofr),
        axis.title.y.right = element_text(color = color_ibr),
        axis.text.y.left   = element_text(color = color_sofr),
        axis.text.y.right  = element_text(color = color_ibr))

g_doble_eje

ggsave(filename = file.path(ruta_resultados, "2_C_doble_eje_mensual.png"),
       plot = g_doble_eje, width = 10, height = 6, units = "in", dpi = 300)

# ---------- Gráfico interactivo (plotly nativo, Clase 9) ----------
# CUIDADO: ggplotly() no traduce sec_axis(), por eso aquí se usa plot_ly().
# En plotly no hace falta reescalar: cada serie se dibuja en su propio eje
# (yaxis y yaxis2) con sus valores reales, y el tooltip muestra el valor verdadero.
p_doble_eje <- plot_ly(tasas_mensual, x = ~mes) %>%
  add_trace(y = ~sofr_pct, name = "SOFR ON (eje izquierdo)",       # Función no vista: agrega una serie al gráfico
            type = "scatter", mode = "lines",
            line = list(color = color_sofr, width = 2),
            customdata = ~dias_sofr,                                # Función no vista: dato extra para el tooltip
            hovertemplate = paste("<b>SOFR ON</b><br>",
                                  "Mes: %{x|%b %Y}<br>",
                                  "Promedio: %{y:.2f} %<br>",
                                  "Días hábiles EE. UU.: %{customdata}",
                                  "<extra></extra>")) %>%
  add_trace(y = ~ibr_pct, name = "IBR ON (eje derecho)",
            type = "scatter", mode = "lines", yaxis = "y2",         # yaxis = "y2": se dibuja en el eje derecho
            line = list(color = color_ibr, width = 2),
            customdata = ~dias_ibr,
            hovertemplate = paste("<b>IBR ON</b><br>",
                                  "Mes: %{x|%b %Y}<br>",
                                  "Promedio: %{y:.3f} %<br>",
                                  "Días hábiles Colombia: %{customdata}",
                                  "<extra></extra>")) %>%
  layout(title  = list(text = paste0("<b>", titulo_doble, "</b><br><sup>", periodo_doble, "</sup>")),
         xaxis  = list(title = "Mes"),
         yaxis  = list(title = list(text = eje_sofr_doble, font = list(color = color_sofr)),
                       ticksuffix = " %"),
         yaxis2 = list(title = list(text = eje_ibr_doble, font = list(color = color_ibr)),
                       ticksuffix = " %",
                       overlaying = "y", side = "right"),           # Función no vista: segundo eje y, a la derecha
         legend = list(orientation = "h", x = 0, y = -0.2),         # leyenda horizontal debajo del gráfico
         margin = list(r = 80, b = 120),                            # espacio para el eje derecho y la fuente
         annotations = list(                                        # Función no vista: argumento de layout() para texto libre
           text      = fuente_doble,
           x = 0, y = -0.35, xref = "paper", yref = "paper",
           showarrow = FALSE, xanchor = "left",
           font      = list(size = 10, color = "gray")))

p_doble_eje

htmlwidgets::saveWidget(widget = p_doble_eje,
                        file = file.path(ruta_resultados, "2_C_doble_eje_mensual.html"),
                        selfcontained = TRUE)

# Verificación Programática 18: las dos gráficas se guardaron
archivos_doble <- file.path(ruta_resultados, c("2_C_doble_eje_mensual.png", "2_C_doble_eje_mensual.html"))
if (!all(file.exists(archivos_doble))) {
  cat("Alerta: falta alguna gráfica en", ruta_resultados, "\n")
} else {
  cat("Verificación exitosa: gráficas de doble eje guardadas en", ruta_resultados, "\n")
}

# ---------- Para el punto 3 ----------
ruta_app_datos <- file.path(ruta_taller, "app_shiny", "datos")
dir.create(ruta_app_datos, showWarnings = FALSE, recursive = TRUE)
saveRDS(ibr_on,        file.path(ruta_app_datos, "ibr_on.rds"))
saveRDS(sofr_on,       file.path(ruta_app_datos, "sofr_on.rds"))
saveRDS(tasas_mensual, file.path(ruta_app_datos, "tasas_mensual.rds"))
              
# [INTERPRETACIÓN: la comparación de tendencias de la IBR y la SOFR la escribe el grupo]

# ---------- Memoria ----------
rm(ibr_recuperada, filas_antes)
