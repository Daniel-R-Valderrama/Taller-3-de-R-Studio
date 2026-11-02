# =============================================================================
# BLOQUE 1: CONFIGURACIÓN INICIAL DEL AMBIENTE
# =============================================================================

install_if_missing <- function(paquete) {
  if (!require(paquete, character.only = TRUE)) {
    install.packages(paquete)
  }
}


# Paquetes no vistos en clase:
# - jsonlite: lee la respuesta JSON del servicio de SUAMECA -> # [NO VISTO EN CLASE]
# - rvest: muestra que el HTML de la página no trae la tabla -> # [NO VISTO EN CLASE]
# - fredr: consulta la API de FRED (Reserva Federal de St. Louis)  -> # [NO VISTO EN CLASE]
paquetes <- c("dplyr", "readr", "lubridate", "ggplot2", "scales",
              "plotly", "htmlwidgets", "jsonlite", "rvest", "fredr")
lapply(paquetes, install_if_missing)
lapply(paquetes, library, character.only = TRUE)
# =============================================================================
# BLOQUE 2: DIRECTORIO DE TRABAJO
# =============================================================================

username <- Sys.getenv("USER")      # En Mac es USER; en Windows es USERNAME

# CUIDADO: cada integrante ajusta la ruta a su computador
ruta_datos <- paste0("/Users/", username, "/Documents/Maestría/R/Taller 3/Taller 3")
setwd(ruta_datos)

dir.create("output", showWarnings = FALSE)


# =============================================================================
# BLOQUE 3: PUNTO 2.1 - IBR OVERNIGHT (BANCO DE LA REPÚBLICA)
# =============================================================================

# ---------- ¿Por qué no se lee la tabla directamente del HTML? ----------
# La página de SUAMECA es una aplicación Angular: el HTML llega "vacío" y los
# datos se cargan después con JavaScript desde un servicio interno.
url_pagina <- "https://suameca.banrep.gov.co/estadisticas-economicas/informacionSerie/241/tasas_interes_indicador_bancario_referencia_ibr"

html_pagina <- read_html(url_pagina)                     # [NO VISTO EN CLASE] read_html(): descarga y lee el HTML
length(html_elements(html_pagina, "table"))              # [NO VISTO EN CLASE] html_elements(): busca etiquetas <table>
# Resultado esperado: 0 -> el HTML no contiene la serie, hay que ir al servicio JSON

# ---------- Consulta al servicio de SUAMECA ----------
# Es el mismo servicio que usa la página para dibujar el gráfico (idSerie = 241)
url_servicio <- paste0("https://suameca.banrep.gov.co/estadisticas-economicas-back/rest/",
                       "estadisticaEconomicaRestService/consultaInformacionSerie?idSerie=241")

ibr_json <- fromJSON(url_servicio)                       # [NO VISTO EN CLASE] fromJSON(): convierte el JSON en lista / data frame

# Metadatos de la serie: confirman que se descargó la serie correcta
ibr_json$nombre
ibr_json$unidad
ibr_json$descripcionPeriodicidad

# ---------- De la respuesta a un data frame ----------
# "data" trae una matriz de dos columnas: [fecha en milisegundos, valor]
matriz_ibr <- ibr_json$data[[1]]
dim(matriz_ibr)

ibr_bruto <- data.frame(
  MILISEGUNDOS = matriz_ibr[, 1],
  IBR_ON       = matriz_ibr[, 2]
)
head(ibr_bruto)

# ---------- Fechas ----------
# CUIDADO: la fecha viene como milisegundos desde 1970-01-01 (formato Unix).
# Cada dato corresponde a la medianoche en Bogotá (05:00 UTC). Si se convierte
# en UTC sin fijar la zona horaria, se puede correr un día.
ibr_bruto <- ibr_bruto %>%
  mutate(FECHA_HORA = as.POSIXct(MILISEGUNDOS / 1000,   # as.POSIXct(): segundos desde 1970 a fecha-hora
                                 origin = "1970-01-01",
                                 tz = "America/Bogota"),
         FECHA      = as.Date(FECHA_HORA, tz = "America/Bogota"))

range(ibr_bruto$FECHA)                                    # toda la historia: desde 2008

# ---------- Filtro del período (2020-01-01 a 2025-10-31) ----------
ibr_on <- ibr_bruto %>%
  filter(FECHA >= as.Date("2020-01-01"),
         FECHA <= as.Date("2025-10-31")) %>%
  select(FECHA, IBR_ON) %>%
  arrange(FECHA)

# Verificaciones inmediatas
nrow(ibr_on)                                              # días hábiles con dato
range(ibr_on$FECHA)                                       # 2020-01-02 a 2025-10-31 (el 1 de enero es festivo)
sum(is.na(ibr_on$IBR_ON))                                 # faltantes en el valor
sum(duplicated(ibr_on$FECHA))                             # fechas repetidas: debe ser 0

# Verificación por dos caminos: número de días con dato
nrow(ibr_on) == length(unique(ibr_on$FECHA))              # debe ser TRUE

# ---------- Contraste con la fuente oficial ----------
# Valores que muestra la página de SUAMECA (se revisaron a mano en la página)
ibr_on %>% filter(FECHA %in% as.Date(c("2020-01-02", "2023-06-30", "2025-10-31")))
# Esperado: 2020-01-02 = 4,114 | 2023-06-30 = 12,270 | 2025-10-31 = 8,730

summary(ibr_on$IBR_ON)

# ---------- Calendario diario completo (patrón Clase 8) ----------
# La IBR solo se publica en días hábiles. Para unirla después con la SOFR se
# arma un calendario con TODOS los días del período.
fechas <- seq(as.Date("2020-01-01"), as.Date("2025-10-31"), by = "day")

df_full       <- data.frame(FECHA = fechas)
ibr_on_diaria <- left_join(df_full, ibr_on, by = "FECHA")

nrow(df_full) == nrow(ibr_on_diaria)                      # el join no debe duplicar filas
sum(!(ibr_on$FECHA %in% df_full$FECHA))                   # fechas sin pareja: debe ser 0
sum(is.na(ibr_on_diaria$IBR_ON))                          # fines de semana y festivos

# CUIDADO: en tasas, un día sin dato NO es cero. Se deja NA y se explica en el documento.

# ---------- Exportar ----------
write.csv(ibr_on,        "output/ibr_on_dias_habiles.csv", row.names = FALSE)
write.csv(ibr_on_diaria, "output/ibr_on_calendario.csv",   row.names = FALSE)

# ---------- Lectura del CSV exportado ----------
# Se trabaja desde el CSV para que el gráfico no dependa de volver a consultar la página
ibr_csv <- read_csv("output/ibr_on_dias_habiles.csv")
str(ibr_csv)
class(ibr_csv$FECHA)                                      # debe ser "Date" (read_csv reconoce AAAA-MM-DD)
nrow(ibr_csv) == nrow(ibr_on)                             # el CSV conserva todas las filas

# ---------- Datos para el gráfico ----------
# Se usa el CSV de días hábiles: con el de calendario, la línea se cortaría en
# cada fin de semana y festivo (NA).
ibr_grafico <- ibr_csv %>%
  arrange(FECHA)

nrow(ibr_grafico)                                         # días hábiles graficados
range(ibr_grafico$FECHA)                                  # 2020-01-02 a 2025-10-31

# Máximo y mínimo del período, verificados por dos caminos
ibr_grafico[which.max(ibr_grafico$IBR_ON), ]              # camino 1: which.max()
ibr_grafico %>% arrange(desc(IBR_ON)) %>% head(1)         # camino 2: ordenar y tomar el primero
ibr_grafico[which.min(ibr_grafico$IBR_ON), ]
ibr_grafico %>% arrange(IBR_ON) %>% head(1)

# ---------- Gráfico base ----------
p_ibr_basico <- ggplot(ibr_grafico, aes(x = FECHA, y = IBR_ON)) +
  geom_line(color = "darkblue", linewidth = 0.8) +
  labs(title    = "Evolución diaria de la IBR overnight",
       subtitle = "Período: enero 2020 - octubre 2025 (días hábiles)",
       x        = "Fecha",
       y        = "Tasa nominal, base 360 (%)",
       caption  = "Fuente: Banco de la República, SUAMECA (serie 241, IBR overnight nominal, base 360).")

p_ibr_basico

# ---------- Tema personalizado ----------
p_ibr_custom <- p_ibr_basico +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # scale_x_date(): marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %")) +
  theme_minimal() +
  theme(plot.title       = element_text(size = 14, face = "bold"),
        plot.subtitle    = element_text(size = 12, color = "gray50"),
        axis.text.x      = element_text(angle = 45, hjust = 1),
        panel.grid.minor = element_blank())

p_ibr_custom

# ---------- Guardar ----------
ggsave(filename = "output/ibr_on_evolucion.png", plot = p_ibr_custom,
       width = 10, height = 6, units = "in", dpi = 300)

# ---------- Gráfico interactivo (patrón Clase 8: ggplot a plotly) ----------
# Columna de texto para el tooltip (<b> = negrilla, <br> = salto de línea)
ibr_grafico_int <- ibr_grafico %>%
  mutate(text = paste0("<b>", format(FECHA, "%d/%m/%Y"), "</b>",
                       "<br>IBR ON: ", round(IBR_ON, 3), " %"))

p_ibr_int <- ggplot(ibr_grafico_int, aes(x = FECHA, y = IBR_ON, text = text)) +
  geom_line(aes(group = 1), color = "darkblue", linewidth = 0.8) +  # "text" rompe la agrupación: hay que forzarla
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # scale_x_date(): marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %")) +
  labs(title = "Evolución diaria de la IBR overnight",
       x     = "Fecha",
       y     = "Tasa nominal, base 360 (%)") +
  theme_minimal() +
  theme(plot.title       = element_text(size = 14, face = "bold"),
        axis.text.x      = element_text(angle = 45, hjust = 1),
        panel.grid.minor = element_blank())

# CUIDADO: ggplotly() no conserva el subtítulo ni el caption de ggplot.
# Se agregan con layout(): el período en el título y la fuente como anotación.
p_ibr_plotly <- ggplotly(p_ibr_int, tooltip = "text") %>%
  layout(title = list(text = paste0("<b>Evolución diaria de la IBR overnight</b>",
                                    "<br><sup>Período: enero 2020 - octubre 2025 (días hábiles)</sup>")),
         annotations = list(                                      # annotations: texto libre dentro del gráfico (plotly)
           text      = "Fuente: Banco de la República, SUAMECA (serie 241, IBR ON nominal, base 360).",
           x = 0, y = -0.25, xref = "paper", yref = "paper",
           showarrow = FALSE, xanchor = "left",
           font      = list(size = 10, color = "gray")))

p_ibr_plotly

# ---------- Guardar el interactivo ----------
htmlwidgets::saveWidget(widget = p_ibr_plotly,
                        file   = "output/ibr_on_evolucion.html",
                        selfcontained = TRUE)
# =============================================================================
# BLOQUE 4: PUNTO 2.2 - SOFR OVERNIGHT (FED DE NUEVA YORK, VÍA FRED)
# =============================================================================

# ---------- Clave de acceso a FRED ----------
# La clave está guardada en el archivo .Renviron del proyecto, no en el código.
# CUIDADO: si se editó .Renviron con R abierto, hay que reiniciar R antes de correr esto.
fred_key <- Sys.getenv("FRED_API_KEY")

if (fred_key == "") {
  stop("No se encontró FRED_API_KEY. Revise el archivo .Renviron y reinicie R.")
}
nchar(fred_key)                                           # debe ser 32

fredr_set_key(fred_key)                                   # [NO VISTO EN CLASE] fredr_set_key(): registra la clave para la sesión

# ---------- Metadatos de la serie ----------
# Confirman que se consulta la serie correcta antes de descargar los datos
sofr_info <- fredr_series(series_id = "SOFR")             # [NO VISTO EN CLASE] fredr_series(): descripción de la serie
sofr_info$title
sofr_info$units
sofr_info$frequency

# ---------- Descarga de la SOFR (mismo período que la IBR) ----------
sofr_bruto <- fredr(series_id         = "SOFR",           # [NO VISTO EN CLASE] fredr(): descarga las observaciones
                    observation_start = as.Date("2020-01-01"),
                    observation_end   = as.Date("2025-10-31"),
                    frequency         = "d")              # d = diaria (frecuencia original de la serie)

str(sofr_bruto)
head(sofr_bruto)
# fredr devuelve: date, series_id, value, realtime_start, realtime_end

# ---------- Selección y nombres ----------
sofr_on <- sofr_bruto %>%
  select(date, value) %>%
  rename(FECHA = date, SOFR_ON = value) %>%               # rename(): cambia el nombre de las columnas
  arrange(FECHA)

class(sofr_on$FECHA)                                      # debe ser "Date"

# CUIDADO: FRED puede incluir días festivos de EE. UU. con valor vacío ("."),
# que fredr convierte en NA. Esos días no son tasa cero: se eliminan aquí y
# reaparecen como NA en el calendario completo.
sum(is.na(sofr_on$SOFR_ON))                               # festivos de EE. UU. sin dato
sofr_on <- sofr_on %>% filter(!is.na(SOFR_ON))

# Verificaciones inmediatas
nrow(sofr_on)                                             # días hábiles (EE. UU.) con dato
range(sofr_on$FECHA)                                      # debe empezar el 2020-01-02 y terminar el 2025-10-31
sum(duplicated(sofr_on$FECHA))                            # fechas repetidas: debe ser 0
nrow(sofr_on) == length(unique(sofr_on$FECHA))            # verificación por dos caminos: debe ser TRUE

summary(sofr_on$SOFR_ON)

# ---------- Contraste con la fuente oficial ----------
# La SOFR la calcula y publica la Fed de Nueva York; FRED la replica.
# Se comparan a mano estos días con https://www.newyorkfed.org/markets/reference-rates/sofr
sofr_on %>% filter(FECHA %in% as.Date(c("2020-01-02", "2023-06-30", "2025-10-31")))
# Esperado (según la Fed de Nueva York): 2020-01-02 = ... | 2023-06-30 = ... | 2025-10-31 = ...

# ---------- Calendario diario completo (mismo calendario que la IBR) ----------
# Se arma de nuevo el calendario con todos los días del período para que el
# bloque no dependa de haber corrido el punto 2.1. Es idéntico al de la IBR.
fechas  <- seq(as.Date("2020-01-01"), as.Date("2025-10-31"), by = "day")
df_full <- data.frame(FECHA = fechas)

sofr_on_diaria <- left_join(df_full, sofr_on, by = "FECHA")

nrow(df_full) == nrow(sofr_on_diaria)                     # el join no debe duplicar filas
sum(!(sofr_on$FECHA %in% df_full$FECHA))                  # fechas sin pareja: debe ser 0
sum(is.na(sofr_on_diaria$SOFR_ON))                        # fines de semana y festivos de EE. UU.

# CUIDADO: los festivos de Colombia y de EE. UU. no coinciden. Hay días con IBR
# y sin SOFR, y al revés. Se dejan NA; no se rellenan ni se ponen en cero.

# ---------- Exportar ----------
write.csv(sofr_on,        "output/sofr_on_dias_habiles.csv", row.names = FALSE)
write.csv(sofr_on_diaria, "output/sofr_on_calendario.csv",   row.names = FALSE)
# ---------- Lectura del CSV exportado ----------
# Se trabaja desde el CSV para que el gráfico no dependa de volver a consultar la API
sofr_csv <- read_csv("output/sofr_on_dias_habiles.csv")
str(sofr_csv)
class(sofr_csv$FECHA)                                     # debe ser "Date" (read_csv reconoce AAAA-MM-DD)
nrow(sofr_csv) == nrow(sofr_on)                           # el CSV conserva todas las filas

# ---------- Datos para el gráfico ----------
# Se usa el CSV de días hábiles: con el de calendario, la línea se cortaría en
# cada fin de semana y festivo de EE. UU. (NA).
sofr_grafico <- sofr_csv %>%
  arrange(FECHA)

nrow(sofr_grafico)                                        # días hábiles graficados
range(sofr_grafico$FECHA)                                 # 2020-01-02 a 2025-10-31

# Máximo y mínimo del período, verificados por dos caminos
sofr_grafico[which.max(sofr_grafico$SOFR_ON), ]           # camino 1: which.max()
sofr_grafico %>% arrange(desc(SOFR_ON)) %>% head(1)       # camino 2: ordenar y tomar el primero
sofr_grafico[which.min(sofr_grafico$SOFR_ON), ]
sofr_grafico %>% arrange(SOFR_ON) %>% head(1)

# ---------- Gráfico base ----------
p_sofr_basico <- ggplot(sofr_grafico, aes(x = FECHA, y = SOFR_ON)) +
  geom_line(color = "forestgreen", linewidth = 0.8) +
  labs(title    = "Evolución diaria de la SOFR overnight",
       subtitle = "Período: enero 2020 - octubre 2025 (días hábiles de EE. UU.)",
       x        = "Fecha",
       y        = "Tasa anual, base 360 (%)",
       caption  = "Fuente: Federal Reserve Bank of New York, obtenida vía FRED (serie SOFR).")

p_sofr_basico

# ---------- Tema personalizado ----------
p_sofr_custom <- p_sofr_basico +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # scale_x_date(): marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %")) +
  theme_minimal() +
  theme(plot.title       = element_text(size = 14, face = "bold"),
        plot.subtitle    = element_text(size = 12, color = "gray50"),
        axis.text.x      = element_text(angle = 45, hjust = 1),
        panel.grid.minor = element_blank())

p_sofr_custom

# ---------- Guardar ----------
ggsave(filename = "output/sofr_on_evolucion.png", plot = p_sofr_custom,
       width = 10, height = 6, units = "in", dpi = 300)

# ---------- Gráfico interactivo (patrón Clase 8: ggplot a plotly) ----------
# Columna de texto para el tooltip (<b> = negrilla, <br> = salto de línea)
sofr_grafico_int <- sofr_grafico %>%
  mutate(text = paste0("<b>", format(FECHA, "%d/%m/%Y"), "</b>",
                       "<br>SOFR ON: ", round(SOFR_ON, 2), " %"))

p_sofr_int <- ggplot(sofr_grafico_int, aes(x = FECHA, y = SOFR_ON, text = text)) +
  geom_line(aes(group = 1), color = "forestgreen", linewidth = 0.8) +  # "text" rompe la agrupación: hay que forzarla
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +      # scale_x_date(): marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %")) +
  labs(title = "Evolución diaria de la SOFR overnight",
       x     = "Fecha",
       y     = "Tasa anual, base 360 (%)") +
  theme_minimal() +
  theme(plot.title       = element_text(size = 14, face = "bold"),
        axis.text.x      = element_text(angle = 45, hjust = 1),
        panel.grid.minor = element_blank())

# CUIDADO: ggplotly() no conserva el subtítulo ni el caption de ggplot.
# Se agregan con layout(): el período en el título y la fuente como anotación.
p_sofr_plotly <- ggplotly(p_sofr_int, tooltip = "text") %>%
  layout(title = list(text = paste0("<b>Evolución diaria de la SOFR overnight</b>",
                                    "<br><sup>Período: enero 2020 - octubre 2025 (días hábiles de EE. UU.)</sup>")),
         annotations = list(                                      # annotations: texto libre dentro del gráfico (plotly)
           text      = "Fuente: Federal Reserve Bank of New York, obtenida vía FRED (serie SOFR).",
           x = 0, y = -0.25, xref = "paper", yref = "paper",
           showarrow = FALSE, xanchor = "left",
           font      = list(size = 10, color = "gray")))

p_sofr_plotly

# ---------- Guardar el interactivo ----------
htmlwidgets::saveWidget(widget = p_sofr_plotly,
                        file   = "output/sofr_on_evolucion.html",
                        selfcontained = TRUE)
# =============================================================================
# BLOQUE 5: PUNTO 2.3 - IBR Y SOFR OVERNIGHT: PROMEDIO MENSUAL A DOS EJES
# =============================================================================

# ---------- Lectura de las bases de días hábiles ----------
# CUIDADO: se usan los CSV de días hábiles de CADA tasa por separado, no una base
# unida por fecha. Si se unieran primero y se dejaran solo los días con ambas
# tasas, se perderían los festivos de EE. UU. que son hábiles en Colombia (y al revés).
ibr_dh  <- read_csv("output/ibr_on_dias_habiles.csv")
sofr_dh <- read_csv("output/sofr_on_dias_habiles.csv")

nrow(ibr_dh)
nrow(sofr_dh)
sum(is.na(ibr_dh$IBR_ON))                                 # debe ser 0
sum(is.na(sofr_dh$SOFR_ON))                               # debe ser 0

# ---------- Promedio mensual de cada tasa sobre sus propios días hábiles ----------
# MES = primer día del mes, para que el eje x siga siendo una fecha
ibr_mensual <- ibr_dh %>%
  mutate(MES = as.Date(paste0(year(FECHA), "-", month(FECHA), "-01"))) %>%
  group_by(MES) %>%
  summarise(IBR_ON     = mean(IBR_ON),
            DIAS_IBR   = n(),                             # días hábiles en Colombia usados en el promedio
            .groups = "drop")

sofr_mensual <- sofr_dh %>%
  mutate(MES = as.Date(paste0(year(FECHA), "-", month(FECHA), "-01"))) %>%
  group_by(MES) %>%
  summarise(SOFR_ON    = mean(SOFR_ON),
            DIAS_SOFR  = n(),                             # días hábiles en EE. UU. usados en el promedio
            .groups = "drop")

# Verificaciones inmediatas: enero 2020 a octubre 2025 = 70 meses
nrow(ibr_mensual)                                         # debe ser 70
nrow(sofr_mensual)                                        # debe ser 70
sum(ibr_mensual$DIAS_IBR)  == nrow(ibr_dh)                # todos los días entran a algún mes
sum(sofr_mensual$DIAS_SOFR) == nrow(sofr_dh)
range(ibr_mensual$DIAS_IBR)                               # rango de días hábiles por mes (aprox. 18 a 23)
range(sofr_mensual$DIAS_SOFR)

# Verificación por dos caminos: promedio mensual con aggregate() de base R
ibr_check  <- aggregate(IBR_ON ~ MES,                     # aggregate(): agrupa y resume con una fórmula
                        data = ibr_dh %>% mutate(MES = as.Date(paste0(year(FECHA), "-", month(FECHA), "-01"))),
                        FUN  = mean)
sofr_check <- aggregate(SOFR_ON ~ MES,
                        data = sofr_dh %>% mutate(MES = as.Date(paste0(year(FECHA), "-", month(FECHA), "-01"))),
                        FUN  = mean)
all.equal(ibr_mensual$IBR_ON,   ibr_check$IBR_ON)         # debe ser TRUE
all.equal(sofr_mensual$SOFR_ON, sofr_check$SOFR_ON)       # debe ser TRUE

# ---------- Unión de los promedios mensuales ----------
# Se unen los PROMEDIOS (ya calculados por separado), no los datos diarios
nrow(sofr_mensual)                                        # antes
tasas_mensual <- left_join(sofr_mensual, ibr_mensual, by = "MES")
nrow(tasas_mensual)                                       # después: debe ser igual (70)
sum(!(sofr_mensual$MES %in% ibr_mensual$MES))             # meses sin pareja: debe ser 0
sum(is.na(tasas_mensual$IBR_ON))                          # debe ser 0

head(tasas_mensual)

# ---------- Exportar ----------
write.csv(tasas_mensual, "output/tasas_promedio_mensual.csv", row.names = FALSE)

# ---------- Transformación para el doble eje (patrón Clase 8, min-max) ----------
# Eje izquierdo = SOFR ; eje derecho = IBR (se reescala al rango de la SOFR)
min_izq   <- min(tasas_mensual$SOFR_ON, na.rm = TRUE)
min_der   <- min(tasas_mensual$IBR_ON,  na.rm = TRUE)
pendiente <- (max(tasas_mensual$SOFR_ON, na.rm = TRUE) - min_izq) /
  (max(tasas_mensual$IBR_ON,  na.rm = TRUE) - min_der)

tasas_mensual <- tasas_mensual %>%
  mutate(IBR_ESCALADA = min_izq + (IBR_ON - min_der) * pendiente)

# Verificación: al devolver la transformación se recupera la IBR original
all.equal(min_der + (tasas_mensual$IBR_ESCALADA - min_izq) / pendiente,
          tasas_mensual$IBR_ON)                           # debe ser TRUE

# CUIDADO: con doble eje, el cruce de las líneas no significa que las tasas sean
# iguales; cada línea se lee en su propio eje.

# ---------- Gráfico estático a dos ejes ----------
p_doble_eje <- ggplot(tasas_mensual, aes(x = MES)) +
  geom_line(aes(y = SOFR_ON,      color = "SOFR ON (eje izquierdo)"), linewidth = 1) +
  geom_line(aes(y = IBR_ESCALADA, color = "IBR ON (eje derecho)"),    linewidth = 1) +
  scale_y_continuous(name     = "SOFR ON: promedio mensual, tasa anual base 360 (%)",
                     sec.axis = sec_axis(~ min_der + (. - min_izq) / pendiente,
                                         name = "IBR ON: promedio mensual, tasa nominal base 360 (%)")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # scale_x_date(): marcas del eje de fechas cada 6 meses
  scale_color_manual(values = c("SOFR ON (eje izquierdo)" = "forestgreen",
                                "IBR ON (eje derecho)"    = "darkblue")) +
  labs(title    = "IBR overnight y SOFR overnight: promedio mensual",
       subtitle = "Período: enero 2020 - octubre 2025. Promedio de los días hábiles de cada país.",
       x        = "Mes",
       color    = NULL,
       caption  = paste0("Fuente: Banco de la República, SUAMECA (serie 241); ",
                         "Federal Reserve Bank of New York vía FRED (serie SOFR). Cálculos propios.")) +
  theme_minimal() +
  theme(plot.title         = element_text(size = 14, face = "bold"),
        plot.subtitle      = element_text(size = 11, color = "gray50"),
        legend.position    = "bottom",
        axis.text.x        = element_text(angle = 45, hjust = 1),
        axis.title.y.left  = element_text(color = "forestgreen"),
        axis.title.y.right = element_text(color = "darkblue"),
        panel.grid.minor   = element_blank())

p_doble_eje

ggsave(filename = "output/ibr_sofr_mensual_doble_eje.png", plot = p_doble_eje,
       width = 10, height = 6, units = "in", dpi = 300)

# ---------- Gráfico interactivo a dos ejes (plotly nativo, patrón Clase 9) ----------
# CUIDADO: ggplotly() no traduce sec_axis(), por eso aquí se usa plot_ly().
# En plotly no hace falta reescalar: cada serie se dibuja en su propio eje (yaxis y yaxis2)
# con sus valores reales, y el tooltip muestra el valor verdadero.
p_doble_plotly <- plot_ly(tasas_mensual, x = ~MES) %>%
  add_trace(y = ~SOFR_ON, name = "SOFR ON (eje izquierdo)",     # add_trace(): agrega una serie al gráfico
            type = "scatter", mode = "lines",
            line = list(color = "forestgreen", width = 2),
            customdata = ~DIAS_SOFR,                            # customdata: dato extra para el tooltip
            hovertemplate = paste("<b>SOFR ON</b><br>",
                                  "Mes: %{x|%b %Y}<br>",
                                  "Promedio: %{y:.2f} %<br>",
                                  "Días hábiles EE. UU.: %{customdata}",
                                  "<extra></extra>")) %>%
  add_trace(y = ~IBR_ON, name = "IBR ON (eje derecho)",
            type = "scatter", mode = "lines", yaxis = "y2",     # yaxis = "y2": se dibuja en el eje derecho
            line = list(color = "darkblue", width = 2),
            customdata = ~DIAS_IBR,
            hovertemplate = paste("<b>IBR ON</b><br>",
                                  "Mes: %{x|%b %Y}<br>",
                                  "Promedio: %{y:.3f} %<br>",
                                  "Días hábiles Colombia: %{customdata}",
                                  "<extra></extra>")) %>%
  layout(title  = list(text = paste0("<b>IBR overnight y SOFR overnight: promedio mensual</b>",
                                     "<br><sup>Período: enero 2020 - octubre 2025. ",
                                     "Promedio de los días hábiles de cada país.</sup>")),
         xaxis  = list(title = "Mes"),
         yaxis  = list(title = "SOFR ON: tasa anual base 360 (%)",
                       titlefont = list(color = "forestgreen")),
         yaxis2 = list(title = "IBR ON: tasa nominal base 360 (%)",  # yaxis2: segundo eje vertical
                       titlefont = list(color = "darkblue"),
                       overlaying = "y", side = "right"),            # se superpone al eje principal, a la derecha
         legend = list(orientation = "h", x = 0, y = -0.2),
         margin = list(r = 80),                                      # margen derecho para el título del eje 2
         annotations = list(                                         # annotations: texto libre dentro del gráfico
           text      = paste0("Fuente: Banco de la República, SUAMECA (serie 241); ",
                              "Federal Reserve Bank of New York vía FRED (serie SOFR). Cálculos propios."),
           x = 0, y = -0.32, xref = "paper", yref = "paper",
           showarrow = FALSE, xanchor = "left",
           font      = list(size = 10, color = "gray")))

p_doble_plotly

htmlwidgets::saveWidget(widget = p_doble_plotly,
                        file   = "output/ibr_sofr_mensual_doble_eje.html",
                        selfcontained = TRUE)

