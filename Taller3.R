# Taller 3, Punto 1
cat("\014")
rm(list = ls())
# ==============================================================================
# CONFIGURACIÓN INICIAL DEL AMBIENTE
# ==============================================================================

# Si es la primera vez o tienen errores de versiones, NO instalen desde aquí:
# instalen los paquetes con install.packages() en una sesión nueva de R, antes
# de correr este script.
# CUIDADO: instalar un paquete que ya está cargado deja la instalación a medias.
# CUIDADO: chromote controla Google Chrome, así que Chrome debe estar instalado.
# CUIDADO: se cargan en el mismo orden de antes. Si dos paquetes tienen una
# función con el mismo nombre, gana el último cargado (por ejemplo, DT va
# después de shiny); cambiar el orden puede cambiar qué función se usa.

# ---------- Punto 1: datos geoespaciales ----------
library(sf)          # datos geoespaciales (shapefiles, proyecciones, geometrías)
library(dplyr)       # manipulación de datos
library(ggplot2)     # visualización (geom_sf dibuja mapas)
library(ggrepel)     # etiquetas que no se solapan
library(BAMMtools)   # getJenksBreaks(): clasificación por cortes naturales
library(openxlsx)      # lectura de los Excel de DNP y DANE y exportación de tablas
library(RColorBrewer)  # paletas de color para el mapa
library(docstring)     # documentación de la función de verificación de uniones

# ---------- Punto 2: web scraping y API ----------
library(robotstxt)  # lee las reglas del archivo robots.txt
library(httr2)      # petición del robots.txt con user-agent y límite de tiempo
library(chromote)   # navegador "sin pantalla" para páginas dinámicas
library(rvest)      # convierte el HTML de la tabla en data frame
library(stringr)    # manipulación de texto
library(scales)     # formato de los ejes
library(plotly)     # gráfica interactiva
library(htmlwidgets) # guardar la gráfica interactiva en HTML
library(httr)       # peticiones a APIs (SOFR)
library(jsonlite)   # lectura del formato JSON (SOFR)

# ---------- Punto 3: aplicativo Shiny ----------
library(shiny)
library(shinydashboard)
library(DT)

# CÓMO SE MARCA LO NO VISTO EN CLASE (aplica a este script y a app_shiny/app.R)
# - Paquete no visto: se nombra en esta sección y cada línea que lo usa termina
#   en  # [NO VISTO EN CLASE]
# - Función no vista de un paquete que sí se vio: la línea lleva el comentario
#   # Función no vista: <para qué sirve>
# - formatC() y sprintf() (base R, formato de números y de texto) llevan el
#   comentario "formatC: ..." o "sprintf: ..." en la línea donde se usan.

# Paquetes no vistos en clase (Punto 1):
#   readxl: lectura del Excel del IDF (DNP). openxlsx no lo puede abrir porque
#   el archivo escribe sus etiquetas XML con prefijo "x:" y openxlsx responde
#   "Workbook has no worksheet". Se llama siempre como readxl::read_excel() y
#   la línea termina en # [NO VISTO EN CLASE]. No se carga con library().

# ==============================================================================
# DIRECTORIO DE TRABAJO
# ==============================================================================

#username <- Sys.getenv("USERNAME")     # usuario del sistema


# ajustarla a la ubicación de SU carpeta "Taller 3".
#ruta_taller <- paste0("C:/Users/", username,
 #                     "/OneDrive/Escritorio/2026-2/R/Taller 3")


#Configuración MacOs
username <- Sys.getenv("USER")
ruta_taller <- paste0("/Users/", username, "/Documents/Maestría/R/Taller 3 def")

setwd(ruta_taller)

# CUIDADO: "Bases de Datos" es solo lectura. Nada se escribe ahí.
ruta_bases      <- file.path(ruta_taller, "Bases de Datos")
ruta_resultados <- file.path(ruta_taller, "Resultados")
ruta_app_datos  <- file.path(ruta_taller, "app_shiny", "datos")
dir.create(ruta_resultados, showWarnings = FALSE)
dir.create(ruta_app_datos, showWarnings = FALSE, recursive = TRUE)

# Verificación Programática 1: las carpetas existen
if (dir.exists(ruta_bases) & dir.exists(ruta_resultados) & dir.exists(ruta_app_datos)) {
  cat("Verificación exitosa: carpetas encontradas en", getwd(), "\n")
} else {
  cat("Alerta: revise la ruta del taller\n")
}


# =============================================================================
# BLOQUE 1. PARÁMETROS Y FUNCIÓN DE VERIFICACIÓN
# =============================================================================

# Estructura revisada en los originales. read.xlsx() reemplaza los espacios
# de los encabezados por puntos ("Código Municipio" queda "Código.Municipio").
# readxl::read_excel() los deja con espacios ("Código Entidad").

# ---------- Archivos originales ----------
# CUIDADO: el DNP le pone al archivo la fecha y la hora de la descarga
# (ConsultaIDF_2024_IDF - Municipios_AAAAMMDDHHMMSS.xlsx), así que el nombre
# cambia en cada computador. Se busca por el inicio del nombre.
arch_idf <- list.files(ruta_bases, pattern = "^ConsultaIDF.*Municipios.*\\.xlsx$")   # DNP, IDF municipal 2024
arch_pob <- "PPED-AreaMun-2018-2042_VP.xlsx"                          # DANE, población municipal por área
arch_va  <- "anex-PIBDep-ValorAgreMuni-2011-2024p.xlsx"               # DANE, VA municipal 2011-2024p
carpeta_shp_dpto <- "MGN2025_DPTO_POLITICO"                           # DANE Geoportal, MGN 2025
carpeta_shp_mpio <- "MGN2025_MPIO_GRAFICO"                            # DANE Geoportal, MGN 2025

# Verificación Programática: hay un solo Excel del IDF municipal en la carpeta
if (length(arch_idf) != 1) {
  cat("Alerta: se encontraron", length(arch_idf), "archivos del IDF municipal en", ruta_bases,
      "(debe haber uno solo)\n")
} else {
  cat("Verificación exitosa: IDF municipal en", arch_idf, "\n")
}
arch_idf <- arch_idf[1]                  # si hubiera varios, se usa el primero

# ---------- Hojas y fila del encabezado ----------
# IDF: hoja única; la fila 16 trae títulos de dimensiones y la 17 los encabezados.
# Con readxl se indica cuántas filas saltar antes del encabezado (16).
hoja_idf <- 1;  filas_saltar_idf <- 16
# Población: hojas "Índice", "PPED", "PobMunicipalxÁrea". Se usa el número
# de hoja para evitar problemas con la tilde en Windows.
hoja_pob <- 3;  fila_pob <- 8
# VA: "Cuadro 1" (hoja 2) trae la serie 2011-2024p con un año por columna.
hoja_va  <- 2;  fila_va  <- 11

# ---------- Columnas de cada base ----------
# IDF municipal (DNP), nombres con espacios porque se lee con readxl
col_idf_cod    <- "Código Entidad"   # código DIVIPOLA del municipio (texto, 5 dígitos)
col_idf_nombre <- "Entidad"          # nombre del municipio
col_idf_valor  <- "IDF"              # IDF con bonos (resultado oficial). Alternativa: "IDF Sin Bonos"

# Población (DANE)
# CUIDADO: en este archivo MPIO es el código y DPMP es el nombre del municipio.
col_pob_cod   <- "MPIO"              # código DIVIPOLA del municipio
col_pob_anio  <- "AÑO"               # año de la proyección
col_pob_area  <- "ÁREA.GEOGRÁFICA"   # Total, Cabecera Municipal, Centros Poblados y Rural Disperso
col_pob_valor <- "TOTAL"             # población
valor_area_total <- "Total"          # categoría que corresponde al total municipal

# Valor agregado (DANE)
col_va_cod   <- "Código.Municipio"   # código DIVIPOLA del municipio
col_va_valor <- "2023"               # columna del año 2023 en el Cuadro 1

# Shapefiles (DANE). CUIDADO: confirmar con names() en el BLOQUE 2.
col_shp_dpto_cod    <- "dpto_ccdgo"  # código del departamento (2 dígitos)
col_shp_dpto_nombre <- "dpto_cnmbr"  # nombre del departamento
col_shp_mpio_cod    <- "mpio_cdpmp"  # código del municipio (5 dígitos)

# ---------- Parámetros del cálculo ----------
anio_pob     <- 2024     # año de la población
n_clases     <- 5        # clases del mapa (getJenksBreaks devuelve n_clases + 1 cortes)
tolerancia   <- 1e-6     # tolerancia para comparar números
epsg_metros  <- 3116     # MAGNA-SIRGAS Bogotá, en metros (alternativa: 9377, origen nacional)
dtol_mpio    <- 500      # metros de tolerancia para simplificar el mapa municipal
dtol_app     <- 1000     # metros de tolerancia para la versión liviana de la app

# ---------- San Andrés y Providencia: recuadros ampliados ----------
# CUIDADO: las islas miden pocos km² y en el mapa nacional casi no se ven.
# Se dibujan aparte, ampliadas, en dos recuadros sobre el mar Caribe.
# Todas las coordenadas van en grados (longitud, latitud), EPSG 4326.
caja_san_andres  <- c(xmin = -81.76, ymin = 12.47, xmax = -81.66, ymax = 12.61)   # isla de San Andrés
caja_providencia <- c(xmin = -81.42, ymin = 13.30, xmax = -81.33, ymax = 13.41)   # Providencia y Santa Catalina
lim_x_continente <- c(-79.9, -66.8)   # longitud del mapa principal (deja el archipiélago por fuera)
lim_y_continente <- c(-4.3, 12.6)     # latitud del mapa principal
pos_san_andres   <- c(xmin = -79.8, xmax = -77.6, ymin = 10.9, ymax = 12.6)   # dónde va el recuadro de San Andrés
pos_providencia  <- c(xmin = -79.8, xmax = -77.6, ymin = 9.1,  ymax = 10.8)   # dónde va el recuadro de Providencia

# ---------- Función de verificación de uniones ----------
verificar_union <- function(x, y, llave) {
  #' Verificar llaves antes de una unión
  #'
  #' Cuenta duplicados y llaves sin pareja en ambos sentidos.
  #'
  #' @param x data frame de la izquierda
  #' @param y data frame de la derecha
  #' @param llave nombre de la columna llave (texto)
  #' @return lista con duplicados y llaves sin pareja
  #' @examples
  #' verificar_union(idf_mun, pob_mun, "cod_mpio")
  if (!(llave %in% names(x)) | !(llave %in% names(y))) {
    stop("La llave no existe en alguna de las dos bases")
  }
  dup_x <- x %>% count(.data[[llave]]) %>% filter(n > 1)
  dup_y <- y %>% count(.data[[llave]]) %>% filter(n > 1)
  solo_x <- x %>% anti_join(y, by = llave)
  solo_y <- y %>% anti_join(x, by = llave)
  cat("Duplicados en x:", nrow(dup_x), "| Duplicados en y:", nrow(dup_y), "\n")
  cat("Sin pareja en y:", nrow(solo_x), "| Sin pareja en x:", nrow(solo_y), "\n")
  return(list(dup_x = dup_x, dup_y = dup_y, solo_x = solo_x, solo_y = solo_y))
}

docstring(verificar_union)

# ---------- Función para los recuadros de las islas ----------
crear_recuadro <- function(datos, caja, titulo, variable) {
  #' Recuadro ampliado de una isla
  #'
  #' Recorta un mapa sf a una caja de coordenadas y lo dibuja con la misma
  #' escala de colores del mapa principal, sin leyenda.
  #'
  #' @param datos objeto sf en EPSG 4326 con la variable de clase (factor)
  #' @param caja vector con xmin, ymin, xmax y ymax en grados
  #' @param titulo texto que va encima del recuadro
  #' @param variable nombre de la columna de clase, entre comillas
  #' @return objeto gráfico listo para annotation_custom()
  #' @examples
  #' crear_recuadro(mapa_dpto, caja_san_andres, "San Andrés", "idf_clase")
  if (!(variable %in% names(datos))) {
    stop("La variable no está en los datos")
  }
  if (!is.factor(datos[[variable]])) {
    warning("La variable no es factor: los colores pueden no coincidir con el mapa principal")
  }
  # suppressWarnings: st_crop avisa que los atributos se copian igual a cada pedazo
  datos_isla <- suppressWarnings(st_crop(datos, caja))   # Función no vista: recorta las geometrías a la caja
  if (nrow(datos_isla) == 0) {
    stop("La caja no contiene ninguna geometría: revise las coordenadas")
  }
  g <- ggplot(datos_isla) +
    geom_sf(aes(fill = .data[[variable]]), color = "white", linewidth = 0.2) +
    scale_fill_brewer(palette = "YlGnBu", na.value = "grey80",
                      drop = FALSE,          # mismos niveles que el mapa principal = mismos colores
                      guide = "none") +      # sin leyenda: la del mapa principal sirve
    labs(title = titulo, x = NULL, y = NULL) +
    theme_bw() +
    theme(axis.text = element_blank(),
          axis.ticks = element_blank(),
          panel.grid = element_blank(),
          plot.title = element_text(size = 7, face = "bold"),
          plot.background = element_rect(color = "grey30", fill = "white"))
  return(ggplotGrob(g))   # Función no vista: convierte el ggplot en un objeto gráfico
}

docstring(crear_recuadro)


# =============================================================================
# BLOQUE 2. CARGA DE DATOS ORIGINALES
# =============================================================================

# CUIDADO: los anexos del DANE traen filas de títulos arriba de la tabla.
# Se saltan con startRow; el archivo original no se toca.

# ---------- IDF municipal 2024 (DNP) ----------
# CUIDADO: read.xlsx() falla con este archivo ("Workbook has no worksheet").
# Se lee con readxl; el original no se toca.
idf_raw <- readxl::read_excel(file.path(ruta_bases, arch_idf),   # [NO VISTO EN CLASE]
                              sheet = hoja_idf, skip = filas_saltar_idf)   # [NO VISTO EN CLASE]
idf_raw <- as.data.frame(idf_raw)        # de tibble a data frame, como las demás bases

# Verificación
dim(idf_raw)
names(idf_raw)
head(idf_raw)
tail(idf_raw)   # revisar notas al pie o filas de totales

# ---------- Población municipal 2024 (DANE) ----------
pob_raw <- read.xlsx(file.path(ruta_bases, arch_pob),
                     sheet = hoja_pob, startRow = fila_pob)

# Verificación
dim(pob_raw)
names(pob_raw)
head(pob_raw)
tail(pob_raw)

# ---------- Valor agregado municipal 2023 (DANE) ----------
va_raw <- read.xlsx(file.path(ruta_bases, arch_va),
                    sheet = hoja_va, startRow = fila_va)

# Verificación
getSheetNames(file.path(ruta_bases, arch_va))   # Función no vista: lista las hojas del Excel
dim(va_raw)
names(va_raw)
head(va_raw)
tail(va_raw)

# ---------- Shapefiles departamental y municipal (DANE) ----------
# Se busca el .shp dentro de cada carpeta para no depender del nombre interno.
arch_shp_dpto <- list.files(file.path(ruta_bases, carpeta_shp_dpto), pattern = "\\.shp$",
                            full.names = TRUE, recursive = TRUE)
arch_shp_mpio <- list.files(file.path(ruta_bases, carpeta_shp_mpio), pattern = "\\.shp$",
                            full.names = TRUE, recursive = TRUE)

# Verificación Programática 2: hay un solo .shp en cada carpeta
if (length(arch_shp_dpto) != 1 | length(arch_shp_mpio) != 1) {
  cat("Alerta: revise las carpetas del MGN; se encontraron", length(arch_shp_dpto),
      "y", length(arch_shp_mpio), "archivos .shp\n")
} else {
  cat("Verificación exitosa:", basename(arch_shp_dpto), "y", basename(arch_shp_mpio), "\n")
}

shp_dpto_raw <- st_read(arch_shp_dpto[1])
shp_mpio_raw <- st_read(arch_shp_mpio[1])

# Verificación
names(shp_dpto_raw)
names(shp_mpio_raw)
nrow(shp_dpto_raw)       # 33 incluyendo Bogotá
nrow(shp_mpio_raw)
st_crs(shp_dpto_raw)
st_crs(shp_mpio_raw)


# =============================================================================
# BLOQUE 3. LIMPIEZA Y LLAVES DIVIPOLA
# =============================================================================

# CUIDADO: los códigos se filtran ANTES de rellenar con ceros. Un código
# departamental (por ejemplo 5) quedaría como "00005" y parecería un municipio.
# Los códigos municipales válidos van de 05001 en adelante.

# ---------- IDF municipal ----------
idf_mun <- idf_raw %>%
  rename(cod_mpio = all_of(col_idf_cod),        # Función no vista: all_of selecciona columnas por nombre en texto
         nombre_mpio = all_of(col_idf_nombre),
         idf = all_of(col_idf_valor)) %>%
  mutate(cod_num = suppressWarnings(as.integer(cod_mpio))) %>%   # textos como "Total" quedan NA
  filter(!is.na(cod_num), cod_num >= 1000) %>%
  mutate(cod_mpio = formatC(cod_num, width = 5, flag = "0"),     # formatC: código municipal a 5 dígitos
         cod_dpto = substr(cod_mpio, 1, 2),
         idf = suppressWarnings(as.numeric(idf))) %>%
  select(cod_dpto, cod_mpio, nombre_mpio, idf)

# Verificación
table(nchar(idf_mun$cod_mpio))           # todos deben tener 5
idf_mun %>% count(cod_mpio) %>% filter(n > 1)
n_distinct(idf_mun$cod_dpto)             # 33 incluyendo Bogotá
sum(is.na(idf_mun$idf))                  # municipios sin puntaje IDF
summary(idf_mun$idf)

# ---------- Población 2024 ----------
pob_mun <- pob_raw %>%
  rename(cod_mpio = all_of(col_pob_cod),
         anio = all_of(col_pob_anio),
         area = all_of(col_pob_area),
         poblacion = all_of(col_pob_valor)) %>%
  filter(anio == anio_pob) %>%
  filter(area == valor_area_total) %>%   # solo el total municipal, no cabecera ni rural
  mutate(cod_num = suppressWarnings(as.integer(cod_mpio))) %>%
  filter(!is.na(cod_num), cod_num >= 1000) %>%
  mutate(cod_mpio = formatC(cod_num, width = 5, flag = "0"),     # formatC: código municipal a 5 dígitos
         poblacion = as.numeric(poblacion)) %>%
  select(cod_mpio, poblacion)

# Verificación
table(nchar(pob_mun$cod_mpio))
pob_mun %>% count(cod_mpio) %>% filter(n > 1)   # si hay duplicados, el filtro de área falló
sum(is.na(pob_mun$poblacion))
cat("Población total", anio_pob, ":", format(sum(pob_mun$poblacion), big.mark = ".", decimal.mark = ","), "\n")

# ---------- Valor agregado 2023 ----------
# Precios del VA según el anexo (Cuadro 1): precios corrientes, base 2015,
# miles de millones de pesos. La columna 2024 es provisional (2024p) y no se
# usa: el enunciado pide proyectar 2023 a 2024.
va_mun <- va_raw %>%
  rename(cod_mpio = all_of(col_va_cod),
         va_2023 = all_of(col_va_valor)) %>%
  mutate(cod_num = suppressWarnings(as.integer(cod_mpio))) %>%
  filter(!is.na(cod_num), cod_num >= 1000) %>%
  mutate(cod_mpio = formatC(cod_num, width = 5, flag = "0"),     # formatC: código municipal a 5 dígitos
         va_2023 = as.numeric(va_2023)) %>%
  select(cod_mpio, va_2023)

# Verificación
table(nchar(va_mun$cod_mpio))
va_mun %>% count(cod_mpio) %>% filter(n > 1)
sum(is.na(va_mun$va_2023))
summary(va_mun$va_2023)

# Verificación Programática 3: municipios con VA 2023 igual a cero o negativo
# CUIDADO: un VA de cero deja el ponderador del municipio en cero. En el anexo
# pasa con Nuevo Belén de Bajirá (27493), creado en diciembre de 2023, y con
# Mapiripana (94663). El grupo decide cómo tratarlos y lo explica.
va_cero <- va_mun %>% filter(va_2023 <= 0)
if (nrow(va_cero) > 0) {
  cat("Alerta:", nrow(va_cero), "municipios con VA 2023 <= 0:", va_cero$cod_mpio, "\n")
} else {
  cat("Verificación exitosa: todos los municipios tienen VA 2023 positivo\n")
}

# ---------- Shapefile departamental ----------
shp_dpto <- shp_dpto_raw %>%
  rename(cod_dpto = all_of(col_shp_dpto_cod),
         nombre_dpto = all_of(col_shp_dpto_nombre)) %>%
  mutate(cod_dpto = formatC(as.integer(cod_dpto), width = 2, flag = "0")) %>%   # formatC: código departamental a 2 dígitos
  select(cod_dpto, nombre_dpto)

# Verificación
table(nchar(shp_dpto$cod_dpto))
shp_dpto %>% st_drop_geometry() %>% count(cod_dpto) %>% filter(n > 1)
class(shp_dpto)                          # debe seguir siendo "sf"

# ---------- Shapefile municipal ----------
shp_mpio <- shp_mpio_raw %>%
  rename(cod_mpio = all_of(col_shp_mpio_cod)) %>%
  mutate(cod_mpio = formatC(as.integer(cod_mpio), width = 5, flag = "0")) %>%   # formatC: código municipal a 5 dígitos
  select(cod_mpio)

# Verificación
table(nchar(shp_mpio$cod_mpio))
shp_mpio %>% st_drop_geometry() %>% count(cod_mpio) %>% filter(n > 1)


# =============================================================================
# BLOQUE 4. UNIÓN DE BASES MUNICIPALES
# =============================================================================

# ---------- Unión IDF + población ----------
chequeo_pob <- verificar_union(idf_mun, pob_mun, "cod_mpio")
chequeo_pob$solo_x            # municipios con IDF sin población: revisar uno por uno
chequeo_pob$solo_y            # municipios con población sin IDF

n_antes <- nrow(idf_mun)
base_mun <- idf_mun %>%
  mutate(Info_IDF = 1) %>%
  left_join(pob_mun %>% mutate(Info_POB = 1), by = "cod_mpio")
n_despues <- nrow(base_mun)

# Verificación Programática 4: el pegue con población no aumenta las filas
if (n_despues != n_antes) {
  cat("Alerta: el pegue con población multiplicó filas (", n_antes, "->", n_despues, ")\n")
} else {
  cat("Verificación exitosa: el pegue con población conserva", n_despues, "filas\n")
}
cat("Municipios con IDF emparejados con población:", sum(!is.na(base_mun$Info_POB)), "de", n_despues, "\n")

# ---------- Unión con valor agregado ----------
chequeo_va <- verificar_union(base_mun, va_mun, "cod_mpio")
chequeo_va$solo_x             # municipios sin VA
chequeo_va$solo_y             # municipios con VA que no están en la base del IDF

n_antes <- nrow(base_mun)
base_mun <- base_mun %>%
  left_join(va_mun %>% mutate(Info_VA = 1), by = "cod_mpio")
n_despues <- nrow(base_mun)

# Verificación Programática 5: el pegue con VA no aumenta las filas
if (n_despues != n_antes) {
  cat("Alerta: el pegue con VA multiplicó filas (", n_antes, "->", n_despues, ")\n")
} else {
  cat("Verificación exitosa: el pegue con VA conserva", n_despues, "filas\n")
}
cat("Municipios emparejados con VA:", sum(!is.na(base_mun$Info_VA)), "de", n_despues, "\n")

# ---------- Resumen de faltantes ----------
resumen_faltantes <- data.frame(
  concepto = c("Municipios en la base del IDF",
               "Sin puntaje IDF",
               "Sin población 2024",
               "Sin VA 2023",
               "Con los tres datos completos"),
  municipios = c(nrow(base_mun),
                 sum(is.na(base_mun$idf)),
                 sum(is.na(base_mun$poblacion)),
                 sum(is.na(base_mun$va_2023)),
                 sum(!is.na(base_mun$idf) & !is.na(base_mun$poblacion) & !is.na(base_mun$va_2023)))
)
resumen_faltantes

# ---------- Evidencia de la unión revisada ----------
write.xlsx(list("Resumen" = resumen_faltantes,
                "IDF_sin_poblacion" = chequeo_pob$solo_x,
                "Poblacion_sin_IDF" = chequeo_pob$solo_y,
                "IDF_sin_VA" = chequeo_va$solo_x,
                "VA_sin_IDF" = chequeo_va$solo_y),
           file.path(ruta_resultados, "1_A_verificacion_uniones.xlsx"),
           overwrite = TRUE)

# Verificación
file.exists(file.path(ruta_resultados, "1_A_verificacion_uniones.xlsx"))


# =============================================================================
# BLOQUE 5. PROYECCIÓN DEL VA Y PONDERADORES
# =============================================================================

#a. Proyecten el VA de 2023 a 2024 con el crecimiento del PIB de Colombia en 2024.
#   Redondeen la tasa porcentual a dos decimales antes de aplicarla.

# ---------- Proyección del VA 2023 a 2024 ----------
# El VA está a precios corrientes, así que se usa el crecimiento del PIB
# nominal de Colombia en 2024.
# Fuente: DANE, Cuentas nacionales departamentales, anexo "PIB total por
# departamentos", serie 2005-2025pr, base 2015, publicado el 3 de julio de 2026.
# Fila COLOMBIA, precios corrientes, miles de millones de pesos:
#   2023 (columna U): 1.587.200
#   2024p (columna V): 1.713.316
# Cálculo en Excel: =(V11-U11)/U11*100 = 7,946 -> 7,95 con dos decimales.
# Coincide con el 7,9 % a precios corrientes del boletín de Cuentas Nacionales Anuales 2024p.
# El anexo no se carga en R; la tasa queda como constante.
tasa_pib_2024 <- 7.95                    # crecimiento % del PIB nominal 2024, redondeado a dos decimales

# Verificación: la constante coincide con el cálculo desde los valores del anexo
round((1713316 - 1587200) / 1587200 * 100, 2) == tasa_pib_2024   # debe dar TRUE

cat("Tasa aplicada:", sprintf("%.2f %%", tasa_pib_2024), "\n")   # sprintf: tasa con dos decimales

base_mun <- base_mun %>%
  mutate(va_2024 = va_2023 * (1 + tasa_pib_2024 / 100))

# Verificación Programática 6: la razón VA 2024 / VA 2023 es la misma en todos los municipios
razon_va <- base_mun$va_2024 / base_mun$va_2023
if (all(abs(razon_va - (1 + tasa_pib_2024 / 100)) < tolerancia, na.rm = TRUE)) {
  cat("Verificación exitosa: el VA 2024 es el VA 2023 por", 1 + tasa_pib_2024 / 100, "\n")
} else {
  cat("Alerta: la proyección del VA no se aplicó de forma uniforme\n")
}

# ---------- Ponderadores ----------
# Solo entran los municipios con IDF, población y VA. Los excluidos quedan
# registrados en 1_A_verificacion_uniones.xlsx.
base_mun_w <- base_mun %>%
  filter(!is.na(idf), !is.na(poblacion), !is.na(va_2024)) %>%
  group_by(cod_dpto) %>%
  mutate(w = (poblacion * va_2024) / sum(poblacion * va_2024)) %>%
  ungroup()

cat("Municipios que entran al cálculo:", nrow(base_mun_w), "de", nrow(base_mun), "\n")

# Verificación Programática 7: ponderadores suman 1 por departamento
suma_w <- base_mun_w %>%
  group_by(cod_dpto) %>%
  summarise(suma = sum(w), .groups = "drop")
if (all(abs(suma_w$suma - 1) < tolerancia)) {
  cat("Verificación exitosa: los ponderadores suman 1 en los", nrow(suma_w), "departamentos\n")
} else {
  warning("Hay departamentos cuyos ponderadores no suman 1")
}
summary(base_mun_w$w)
sum(base_mun_w$w < 0)                    # debe ser 0


# =============================================================================
# BLOQUE 6. IDF DEPARTAMENTAL
# =============================================================================

#A. Calculen el IDF departamental como una media ponderada del IDF municipal,
#   con el producto de población y VA como ponderador.

# ---------- Cálculo principal y chequeos ----------
idf_dpto <- base_mun_w %>%
  group_by(cod_dpto) %>%
  summarise(idf_dpto = sum(idf * w),
            idf_dpto_chequeo = weighted.mean(idf, poblacion * va_2024),
            idf_dpto_va2023 = weighted.mean(idf, poblacion * va_2023),
            idf_promedio_simple = mean(idf),
            n_mpios = n(),
            poblacion = sum(poblacion),
            va_2024 = sum(va_2024),
            .groups = "drop")

# Verificación Programática 8: cálculo comprobado por otro procedimiento
if (all(abs(idf_dpto$idf_dpto - idf_dpto$idf_dpto_chequeo) < tolerancia)) {
  cat("Verificación exitosa: sum(idf * w) coincide con weighted.mean()\n")
} else {
  cat("Alerta: los dos cálculos del IDF departamental no coinciden\n")
}

# Verificación Programática 9: la proyección del VA no cambia los ponderadores.
# Como todos los municipios crecen a la misma tasa, (1 + tasa) se cancela en w.
if (all(abs(idf_dpto$idf_dpto - idf_dpto$idf_dpto_va2023) < tolerancia)) {
  cat("Verificación exitosa: el IDF departamental es el mismo con VA 2023 y VA 2024\n")
} else {
  cat("Alerta: el IDF cambia con la proyección; revise si la tasa es uniforme\n")
}

# Verificación Programática 10: la media ponderada queda dentro del rango municipal
rango_dpto <- base_mun_w %>%
  group_by(cod_dpto) %>%
  summarise(idf_min = min(idf), idf_max = max(idf), .groups = "drop") %>%
  left_join(idf_dpto %>% select(cod_dpto, idf_dpto), by = "cod_dpto")
if (all(rango_dpto$idf_dpto >= rango_dpto$idf_min - tolerancia &
        rango_dpto$idf_dpto <= rango_dpto$idf_max + tolerancia)) {
  cat("Verificación exitosa: cada IDF departamental está entre el mínimo y el máximo municipal\n")
} else {
  cat("Alerta: hay un IDF departamental fuera del rango de sus municipios\n")
}

# CUIDADO: Bogotá (11) es un solo municipio, así que su IDF departamental es
# su IDF municipal. Lo mismo pasa en San Andrés (88): la base del DNP solo trae
# a Providencia (88564), porque la isla de San Andrés (88001) no tiene IDF municipal.
idf_dpto %>% filter(n_mpios == 1)

summary(idf_dpto$idf_dpto)


# =============================================================================
# BLOQUE 7. MAPA DEPARTAMENTAL
# =============================================================================

# ---------- Unión con el shapefile ----------
chequeo_shp_dpto <- verificar_union(shp_dpto, idf_dpto, "cod_dpto")
chequeo_shp_dpto$solo_x       # departamentos del mapa sin IDF

# CUIDADO: el objeto sf va a la izquierda del join para conservar la geometría.
n_antes <- nrow(shp_dpto)
mapa_dpto <- shp_dpto %>%
  left_join(idf_dpto, by = "cod_dpto")
n_despues <- nrow(mapa_dpto)

# Verificación Programática 11: el pegue con el shapefile conserva las filas
if (n_despues != n_antes) {
  cat("Alerta: el pegue con el shapefile cambió el número de filas (", n_antes, "->", n_despues, ")\n")
} else {
  cat("Verificación exitosa: el pegue con el shapefile conserva", n_despues, "departamentos\n")
}
sum(is.na(mapa_dpto$idf_dpto))
class(mapa_dpto)                         # debe seguir siendo "sf"

# ---------- Clases con cortes naturales ----------
cortes_dpto <- getJenksBreaks(mapa_dpto$idf_dpto[!is.na(mapa_dpto$idf_dpto)], k = n_clases + 1)
cortes_dpto

etiquetas_dpto <- paste0(formatC(cortes_dpto[-length(cortes_dpto)], format = "f", digits = 1, decimal.mark = ","),   # formatC: límites de clase con un decimal y coma decimal
                         " - ",
                         formatC(cortes_dpto[-1], format = "f", digits = 1, decimal.mark = ","))

mapa_dpto <- mapa_dpto %>%
  mutate(idf_clase = cut(idf_dpto, breaks = cortes_dpto,
                         labels = etiquetas_dpto, include.lowest = TRUE))

# Verificación
table(mapa_dpto$idf_clase, useNA = "ifany")
length(unique(cortes_dpto)) == n_clases + 1   # cortes sin repetir

# ---------- Etiqueta con el valor del IDF ----------
mapa_dpto <- mapa_dpto %>%
  mutate(idf_etiqueta = formatC(idf_dpto, format = "f", digits = 1, decimal.mark = ","))   # formatC: IDF con un decimal y coma decimal
mapa_dpto$idf_etiqueta[is.na(mapa_dpto$idf_dpto)] <- ""   # sin etiqueta si no hay IDF

# Verificación
head(mapa_dpto %>% st_drop_geometry() %>% select(nombre_dpto, idf_dpto, idf_etiqueta))

# ---------- Recuadros de San Andrés y Providencia ----------
# CUIDADO: el departamento 88 es un solo polígono con las dos islas; los dos
# recuadros muestran el mismo IDF departamental (el de Providencia, único
# municipio del archipiélago con IDF).
st_crs(mapa_dpto)$IsGeographic           # debe salir TRUE: coordenadas en grados, como las cajas
etiqueta_88 <- mapa_dpto$idf_etiqueta[mapa_dpto$cod_dpto == "88"]

recuadro_sa_dpto  <- crear_recuadro(mapa_dpto, caja_san_andres,
                                    paste0("San Andrés\nIDF dpto.: ", etiqueta_88), "idf_clase")
recuadro_pro_dpto <- crear_recuadro(mapa_dpto, caja_providencia,
                                    paste0("Providencia y Santa Catalina\nIDF dpto.: ", etiqueta_88), "idf_clase")

# ---------- Mapa ----------
g_mapa_dpto <- ggplot(mapa_dpto) +
  geom_sf(aes(fill = idf_clase), color = "white", linewidth = 0.2) +
  # CUIDADO: el departamento 88 queda fuera del mapa principal (va en los
  # recuadros); si se deja aquí, su etiqueta aparece suelta en el borde.
  geom_text_repel(data = mapa_dpto %>% filter(cod_dpto != "88"),
                  aes(geometry = geometry, label = idf_etiqueta),
                  stat = "sf_coordinates", size = 2.5, fontface = "bold",
                  min.segment.length = 0) +
  scale_fill_brewer(palette = "YlGnBu", name = "IDF departamental\n(cortes de Jenks)",
                    na.value = "grey80", drop = FALSE) +
  labs(title = "Índice de Desempeño Fiscal artificial por departamento, 2024",
       subtitle = "Media ponderada del IDF municipal (ponderador: población 2024 × VA 2024 proyectado)",
       x = NULL, y = NULL,
       caption = "Fuente: DNP (IDF 2024), DANE (proyecciones de población, VA municipal 2023, MGN). Cálculos propios con R.") +
  annotation_custom(recuadro_sa_dpto,                     # Función no vista: pone un gráfico dentro de otro
                    xmin = pos_san_andres[["xmin"]], xmax = pos_san_andres[["xmax"]],
                    ymin = pos_san_andres[["ymin"]], ymax = pos_san_andres[["ymax"]]) +
  annotation_custom(recuadro_pro_dpto,
                    xmin = pos_providencia[["xmin"]], xmax = pos_providencia[["xmax"]],
                    ymin = pos_providencia[["ymin"]], ymax = pos_providencia[["ymax"]]) +
  coord_sf(xlim = lim_x_continente, ylim = lim_y_continente,   # Función no vista: limita el área del mapa
           expand = FALSE) +
  theme_bw() +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank())

g_mapa_dpto

ggsave(filename = file.path(ruta_resultados, "1_A_mapa_idf_dpto.png"),
       plot = g_mapa_dpto, width = 8, height = 9, units = "in", dpi = 300)

# Verificación
file.exists(file.path(ruta_resultados, "1_A_mapa_idf_dpto.png"))


# =============================================================================
# BLOQUE 8. MAPA MUNICIPAL (PUNTO 1B)
# =============================================================================

#B. Intenten elaborar un mapa del IDF municipal y expliquen los problemas
#   computacionales encontrados.

# ---------- Diagnóstico del shapefile original ----------
nrow(shp_mpio)
print(object.size(shp_mpio), units = "Mb")
n_invalidas <- sum(!st_is_valid(shp_mpio))   # Función no vista: identifica geometrías inválidas
n_vertices  <- nrow(st_coordinates(shp_mpio))   # Función no vista: extrae los vértices de las geometrías
cat("Geometrías inválidas:", n_invalidas, "| Vértices:", format(n_vertices, big.mark = ".", decimal.mark = ","), "\n")

tiempo_original <- system.time(print(ggplot(shp_mpio) + geom_sf()))   # tiempo de dibujo original
tiempo_original

# ---------- Corrección y simplificación ----------
tiempo_simplificar <- system.time({
  shp_mpio_simple <- shp_mpio %>%
    st_make_valid() %>%                  # Función no vista: corrige geometrías inválidas
    st_transform(epsg_metros) %>%        # proyección en metros para que dTolerance esté en metros
    st_simplify(preserveTopology = TRUE, dTolerance = dtol_mpio)   # Función no vista: reduce vértices
})
tiempo_simplificar

# CUIDADO: st_make_valid() y st_simplify() pueden devolver una mezcla de tipos
# (POLYGON, MULTIPOLYGON y a veces GEOMETRYCOLLECTION). Con la mezcla, la columna
# de geometría queda como sfc_GEOMETRY y st_coordinates() no funciona.
table(st_geometry_type(shp_mpio_simple))   # Función no vista: tipo de geometría de cada fila

# ---------- Unificar el tipo de geometría ----------
shp_mpio_simple <- shp_mpio_simple %>%
  st_collection_extract("POLYGON") %>%   # Función no vista: deja solo los polígonos de cada colección
  st_cast("MULTIPOLYGON")                # Función no vista: lleva todo a MULTIPOLYGON

# Verificación
table(st_geometry_type(shp_mpio_simple))   # debe quedar solo MULTIPOLYGON
class(st_geometry(shp_mpio_simple))        # debe ser sfc_MULTIPOLYGON

# ---------- Geometrías que quedaron inválidas al simplificar ----------
# CUIDADO: el original tenía 0 inválidas, pero quitar vértices puede hacer que
# un borde se cruce consigo mismo. Se cuentan ANTES de corregir para el 1B.
invalidas_simple   <- !st_is_valid(shp_mpio_simple)
n_invalidas_simple <- sum(invalidas_simple)
shp_mpio_simple$cod_mpio[invalidas_simple]                        # qué municipio se dañó
st_is_valid(shp_mpio_simple[invalidas_simple, ], reason = TRUE)   # por qué es inválido

shp_mpio_simple <- shp_mpio_simple %>%
  st_make_valid() %>%                    # Función no vista: corrige geometrías inválidas
  st_collection_extract("POLYGON") %>%   # Función no vista: deja solo los polígonos
  st_cast("MULTIPOLYGON")                # Función no vista: lleva todo a MULTIPOLYGON

# Verificación Programática: después de corregir no quedan geometrías inválidas
if (sum(!st_is_valid(shp_mpio_simple)) > 0) {
  cat("Alerta: siguen quedando geometrías inválidas después de corregir\n")
} else {
  cat("Verificación exitosa: se corrigieron", n_invalidas_simple, "geometrías inválidas\n")
}
nrow(shp_mpio_simple) == nrow(shp_mpio)  # no se pierden municipios
print(object.size(shp_mpio_simple), units = "Mb")
n_vertices_simple <- nrow(st_coordinates(shp_mpio_simple))   # Función no vista: extrae los vértices
cat("Vértices después de simplificar:", format(n_vertices_simple, big.mark = ".", decimal.mark = ","),
    "(", round(n_vertices_simple / n_vertices * 100, 1), "% del original )\n")
sum(st_is_empty(shp_mpio_simple))        # Función no vista: polígonos que desaparecieron al simplificar
nrow(shp_mpio_simple) == nrow(shp_mpio)

tiempo_simple <- system.time(print(ggplot(shp_mpio_simple) + geom_sf()))
tiempo_simple

# ---------- Unión con el IDF municipal ----------
chequeo_shp_mpio <- verificar_union(shp_mpio_simple, base_mun, "cod_mpio")
chequeo_shp_mpio$solo_x       # polígonos sin IDF (por ejemplo, áreas no municipalizadas)

n_antes <- nrow(shp_mpio_simple)
mapa_mpio <- shp_mpio_simple %>%
  left_join(base_mun %>% select(cod_mpio, cod_dpto, nombre_mpio, idf), by = "cod_mpio")
n_despues <- nrow(mapa_mpio)

# Verificación Programática 12: el pegue con el shapefile municipal conserva las filas
if (n_despues != n_antes) {
  cat("Alerta: el pegue con el shapefile municipal cambió las filas (", n_antes, "->", n_despues, ")\n")
} else {
  cat("Verificación exitosa: el pegue con el shapefile municipal conserva", n_despues, "polígonos\n")
}
sum(is.na(mapa_mpio$idf))

# ---------- Clases y mapa ----------
cortes_mpio <- getJenksBreaks(mapa_mpio$idf[!is.na(mapa_mpio$idf)], k = n_clases + 1)

etiquetas_mpio <- paste0(formatC(cortes_mpio[-length(cortes_mpio)], format = "f", digits = 1, decimal.mark = ","),   # formatC: límites de clase con un decimal y coma decimal
                         " - ",
                         formatC(cortes_mpio[-1], format = "f", digits = 1, decimal.mark = ","))

mapa_mpio <- mapa_mpio %>%
  mutate(idf_clase = cut(idf, breaks = cortes_mpio,
                         labels = etiquetas_mpio, include.lowest = TRUE))

# Verificación
table(mapa_mpio$idf_clase, useNA = "ifany")

# ---------- Recuadros de San Andrés y Providencia ----------
# CUIDADO: las cajas de las islas están en grados; el mapa municipal está en
# metros (EPSG 3116). Se pasa a 4326 solo para dibujar.
mapa_mpio_4326 <- st_transform(mapa_mpio, 4326)
st_crs(mapa_mpio_4326)$IsGeographic      # debe salir TRUE: coordenadas en grados, como las cajas

recuadro_sa_mpio  <- crear_recuadro(mapa_mpio_4326, caja_san_andres,
                                    "San Andrés (sin IDF municipal)", "idf_clase")
recuadro_pro_mpio <- crear_recuadro(mapa_mpio_4326, caja_providencia,
                                    "Providencia y Santa Catalina", "idf_clase")

g_mapa_mpio <- ggplot(mapa_mpio_4326) +
  geom_sf(aes(fill = idf_clase), color = NA) +
  geom_sf(data = st_transform(shp_dpto, 4326), fill = NA, color = "grey30", linewidth = 0.2) +
  scale_fill_brewer(palette = "YlGnBu", name = "IDF municipal\n(cortes de Jenks)",
                    na.value = "grey80", drop = FALSE,
                    labels = function(x) ifelse(is.na(x), "Sin dato", x)) +   # la clase sin IDF se rotula "Sin dato" y no "NA"
  labs(title = "Índice de Desempeño Fiscal municipal, 2024",
       subtitle = paste0("Polígonos simplificados con tolerancia de ", dtol_mpio, " m; gris: sin dato"),
       x = NULL, y = NULL,
       caption = "Fuente: DNP (IDF 2024), DANE (MGN). Cálculos propios con R.") +
  annotation_custom(recuadro_sa_mpio,                     # Función no vista: pone un gráfico dentro de otro
                    xmin = pos_san_andres[["xmin"]], xmax = pos_san_andres[["xmax"]],
                    ymin = pos_san_andres[["ymin"]], ymax = pos_san_andres[["ymax"]]) +
  annotation_custom(recuadro_pro_mpio,
                    xmin = pos_providencia[["xmin"]], xmax = pos_providencia[["xmax"]],
                    ymin = pos_providencia[["ymin"]], ymax = pos_providencia[["ymax"]]) +
  coord_sf(xlim = lim_x_continente, ylim = lim_y_continente,   # Función no vista: limita el área del mapa
           expand = FALSE) +
  theme_bw() +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank())

tiempo_mapa_mpio <- system.time(
  ggsave(filename = file.path(ruta_resultados, "1_B_mapa_idf_mpio.png"),
         plot = g_mapa_mpio, width = 8, height = 9, units = "in", dpi = 300)
)

# Verificación
file.exists(file.path(ruta_resultados, "1_B_mapa_idf_mpio.png"))

# ---------- Insumos para la explicación del 1B ----------
diagnostico_1b <- data.frame(
  medida = c("Polígonos", "Geometrías inválidas", "Geometrías inválidas después de corregir", "Vértices",
             "Tamaño en memoria (Mb)", "Segundos para dibujar",
             "Segundos para simplificar", "Segundos para exportar el mapa final"),
  original = c(nrow(shp_mpio), n_invalidas, NA, n_vertices,
               round(as.numeric(object.size(shp_mpio)) / 1024^2, 1),
               round(tiempo_original[["elapsed"]], 1), NA, NA),
  simplificado = c(nrow(shp_mpio_simple), n_invalidas_simple, sum(!st_is_valid(shp_mpio_simple)), n_vertices_simple,
                   round(as.numeric(object.size(shp_mpio_simple)) / 1024^2, 1),
                   round(tiempo_simple[["elapsed"]], 1),
                   round(tiempo_simplificar[["elapsed"]], 1),
                   round(tiempo_mapa_mpio[["elapsed"]], 1))
)
diagnostico_1b


# =============================================================================
# BLOQUE 9. EXPORTAR RESULTADOS
# =============================================================================

# ---------- Tabla del IDF departamental ----------
tabla_idf_dpto <- mapa_dpto %>%
  st_drop_geometry() %>%
  select(cod_dpto, nombre_dpto, idf_dpto, idf_promedio_simple, n_mpios, poblacion, va_2024) %>%
  arrange(desc(idf_dpto)) %>%
  mutate(idf_dpto = round(idf_dpto, 2),
         idf_promedio_simple = round(idf_promedio_simple, 2))

write.xlsx(list("IDF_departamental" = tabla_idf_dpto,
                "Suma_ponderadores" = suma_w,
                "Rango_municipal" = rango_dpto,
                "Diagnostico_1B" = diagnostico_1b),
           file.path(ruta_resultados, "1_A_idf_dpto.xlsx"),
           overwrite = TRUE)

# ---------- Objetos para el .Rmd ----------
saveRDS(tabla_idf_dpto, file.path(ruta_resultados, "1_A_idf_dpto.rds"))
saveRDS(resumen_faltantes, file.path(ruta_resultados, "1_A_resumen_faltantes.rds"))
saveRDS(diagnostico_1b, file.path(ruta_resultados, "1_B_diagnostico.rds"))

# ---------- Objetos para la app (pestaña 1) ----------
# CUIDADO: leaflet necesita EPSG 4326. Se guarda una versión simplificada para
# que la app cargue rápido; el cálculo del IDF no cambia.
mapa_dpto_app <- mapa_dpto %>%
  st_make_valid() %>%                    # Función no vista: corrige geometrías inválidas
  st_transform(epsg_metros) %>%
  st_simplify(preserveTopology = TRUE, dTolerance = dtol_app) %>%   # Función no vista: reduce vértices
  st_collection_extract("POLYGON") %>%   # Función no vista: deja solo los polígonos de cada colección
  st_cast("MULTIPOLYGON") %>%            # Función no vista: lleva todo a MULTIPOLYGON
  st_transform(4326)

base_mun_app <- base_mun %>%
  left_join(shp_dpto %>% st_drop_geometry(), by = "cod_dpto") %>%
  select(cod_dpto, nombre_dpto, cod_mpio, nombre_mpio, idf, poblacion, va_2024)

saveRDS(mapa_dpto_app, file.path(ruta_app_datos, "mapa_dpto.rds"))
saveRDS(base_mun_app, file.path(ruta_app_datos, "base_mun.rds"))
saveRDS(cortes_dpto, file.path(ruta_app_datos, "cortes_dpto.rds"))

# Verificación
file.exists(file.path(ruta_resultados, c("1_A_idf_dpto.xlsx", "1_A_idf_dpto.rds",
                                         "1_A_resumen_faltantes.rds", "1_B_diagnostico.rds")))
file.exists(file.path(ruta_app_datos, c("mapa_dpto.rds", "base_mun.rds", "cortes_dpto.rds")))
print(object.size(mapa_dpto_app), units = "Mb")
table(st_geometry_type(mapa_dpto_app))   # debe quedar solo MULTIPOLYGON
nrow(mapa_dpto_app) == nrow(mapa_dpto)   # no se pierden departamentos
sum(is.na(base_mun_app$nombre_dpto))     # municipios sin nombre de departamento

# ---------- Memoria ----------
rm(idf_raw, pob_raw, va_raw, shp_dpto_raw, shp_mpio_raw,
   shp_mpio, shp_mpio_simple, chequeo_pob, chequeo_va,
   chequeo_shp_dpto, chequeo_shp_mpio, razon_va, n_antes, n_despues)


#-----------------------------------------

# Taller 3, Punto 2
cat("\014")
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
# instalen los paquetes con install.packages() en una sesión nueva de R, antes
# de correr este script.
# CUIDADO: chromote controla Google Chrome, así que Chrome debe estar instalado.

# Los paquetes de este punto se cargan al inicio del script.
# Paquetes no vistos en clase: ninguno

# ==============================================================================
# DIRECTORIO DE TRABAJO
# ==============================================================================

# Las rutas (ruta_taller, ruta_resultados, ruta_app_datos) se definen al
# inicio del script, en el DIRECTORIO DE TRABAJO del Punto 1.

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
  # y ficha metodológica del IBR (BanRep / Asobancaria). Conteo de días:
  # Reglamento del IBR (Asobancaria, versión de septiembre de 2024), artículo 34:
  # el plazo se cuenta en días calendario con base en 360 días.
  unidad         = "Porcentaje (%) nominal anual",
  convencion     = "Tasa nominal anual, base 360: días calendario sobre un año de 360 días (Reglamento del IBR, art. 34); el BanRep publica además la tasa efectiva",
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

# sprintf: arma el texto con la tasa y la fecha en formato dd/mm/aaaa
# formatC: tasa con 2 decimales y coma decimal
texto_extremos <- sprintf("Máximo: %s %% (%s). Mínimo: %s %% (%s).",
                          formatC(fila_max$ibr_pct, format = "f", digits = 2, decimal.mark = ","),
                          format(fila_max$fecha, "%d/%m/%Y"),
                          formatC(fila_min$ibr_pct, format = "f", digits = 2, decimal.mark = ","),
                          format(fila_min$fecha, "%d/%m/%Y"))
texto_extremos

# ---------- Gráfica estática ----------
g_ibr_diaria <- ggplot(ibr_on, aes(x = fecha, y = ibr_pct)) +
  # Leyenda: como en el doble eje (BLOQUE 14), el color se asigna con un nombre
  # dentro de aes() y scale_color_manual() le da el color a ese nombre.
  geom_line(aes(color = "IBR overnight (tasa nominal anual)"), linewidth = 0.6) +
  scale_color_manual(values = c("IBR overnight (tasa nominal anual)" = "#1F5F99")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %", decimal.mark = ",")) +
  labs(title    = "IBR overnight diaria",
       subtitle = paste0("Días hábiles, ", format(fecha_inicio, "%d/%m/%Y"), " a ",
                         format(fecha_fin, "%d/%m/%Y"), ". ", texto_extremos),
       x        = "Fecha",
       y        = "IBR overnight nominal (%)",
       color    = NULL,
       caption  = "Fuente: Banco de la República, SUAMECA (serie 241). Web scraping. Cálculos propios.") +
  theme_bw() +
  theme(plot.title      = element_text(face = "bold"),
        legend.position = "bottom",
        axis.text.x     = element_text(angle = 45, hjust = 1))

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
  scale_y_continuous(labels = label_number(suffix = " %", decimal.mark = ",")) +
  labs(x = "Fecha",
       y = "IBR overnight nominal (%)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# CUIDADO: ggplotly() no conserva el subtítulo ni el caption de ggplot. Se
# agregan con layout(): el periodo debajo del título y la fuente como anotación.
# CUIDADO: ggplotly() tampoco muestra leyenda cuando hay una sola serie. Se le
# pone nombre a la serie con style() y se activa la leyenda en layout().
p_ibr_diaria <- ggplotly(g_ibr_int, tooltip = "text") %>%
  plotly::style(name = "IBR overnight (tasa nominal anual)",   # Función no vista: cambia atributos de la serie (su nombre en la leyenda)
                showlegend = TRUE, traces = 1) %>%
  layout(showlegend = TRUE,
         legend = list(x = 0.02, y = 0.98),          # leyenda dentro del gráfico, arriba a la izquierda
         title = list(text = paste0("<b>IBR overnight diaria</b>",
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
# sprintf: arma el texto con la tasa y la fecha en formato dd/mm/aaaa
# formatC: tasa con 2 decimales y coma decimal
texto_extremos_sofr <- sprintf("Máximo: %s %% (%s). Mínimo: %s %% (primera vez: %s).",
                               formatC(fila_max_sofr$sofr_pct, format = "f", digits = 2, decimal.mark = ","),
                               format(fila_max_sofr$fecha, "%d/%m/%Y"),
                               formatC(fila_min_sofr$sofr_pct, format = "f", digits = 2, decimal.mark = ","),
                               format(fila_min_sofr$fecha, "%d/%m/%Y"))
texto_extremos_sofr

# ---------- Gráfica estática ----------
g_sofr_diaria <- ggplot(sofr_on, aes(x = fecha, y = sofr_pct)) +
  # Leyenda: mismo patrón de la gráfica diaria de la IBR
  geom_line(aes(color = "SOFR overnight (tasa anual)"), linewidth = 0.6) +
  scale_color_manual(values = c("SOFR overnight (tasa anual)" = color_sofr)) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +   # Función no vista: marcas del eje de fechas cada 6 meses
  scale_y_continuous(labels = label_number(suffix = " %", decimal.mark = ",")) +
  labs(title    = "SOFR overnight diaria",
       subtitle = paste0("Días hábiles de EE. UU., ", format(fecha_inicio, "%d/%m/%Y"), " a ",
                         format(fecha_fin, "%d/%m/%Y"), ". ", texto_extremos_sofr),
       x        = "Fecha",
       y        = "SOFR overnight, tasa anual (%)",
       color    = NULL,
       caption  = "Fuente: Federal Reserve Bank of New York, Markets Data API. Cálculos propios.") +
  theme_bw() +
  theme(plot.title      = element_text(face = "bold"),
        legend.position = "bottom",
        axis.text.x     = element_text(angle = 45, hjust = 1))

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
  scale_y_continuous(labels = label_number(suffix = " %", decimal.mark = ",")) +
  labs(x = "Fecha",
       y = "SOFR overnight, tasa anual (%)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# CUIDADO: ggplotly() no conserva el subtítulo ni el caption de ggplot. Se
# agregan con layout(): el periodo debajo del título y la fuente como anotación.
# CUIDADO: igual que en la IBR, se le pone nombre a la serie con style() y se
# activa la leyenda en layout().
p_sofr_diaria <- ggplotly(g_sofr_int, tooltip = "text") %>%
  plotly::style(name = "SOFR overnight (tasa anual)",          # Función no vista: cambia atributos de la serie (su nombre en la leyenda)
                showlegend = TRUE, traces = 1) %>%
  layout(showlegend = TRUE,
         legend = list(x = 0.02, y = 0.98),          # leyenda dentro del gráfico, arriba a la izquierda
         title = list(text = paste0("<b>SOFR overnight diaria</b>",
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
# ruta_app_datos se define al inicio del script
saveRDS(ibr_on,        file.path(ruta_app_datos, "ibr_on.rds"))
saveRDS(sofr_on,       file.path(ruta_app_datos, "sofr_on.rds"))
saveRDS(tasas_mensual, file.path(ruta_app_datos, "tasas_mensual.rds"))

# ---------- Memoria ----------
rm(ibr_recuperada, filas_antes)


# Taller 3, Punto 3: aplicativo Shiny (pestañas A, B y C)
# ==============================================================================
# El código del aplicativo está en app_shiny/app.R. Lee sus insumos de
# app_shiny/datos/, que se generan en los puntos 1 y 2 de este script.
# Se puede abrir de dos formas:
# - corriendo la línea de runApp() al final de este script, o
# - abriendo app_shiny/app.R en RStudio y usando el botón "Run App" (no hace
#   falta volver a correr los puntos 1 y 2 si app_shiny/datos/ ya existe).
# ==============================================================================

# Los paquetes de este punto se cargan al inicio del script y también en app.R.
# Paquetes no vistos en clase: ninguno
# Funciones no vistas en clase: están en app.R (add_sf() y event_data() de plotly)

ruta_app <- file.path(ruta_taller, "app_shiny")

# Verificación Programática: existen el app.R y los seis insumos de la app
archivos_app <- c(file.path(ruta_app, "app.R"),
                  file.path(ruta_app_datos, c("mapa_dpto.rds", "base_mun.rds", "cortes_dpto.rds",
                                              "ibr_on.rds", "sofr_on.rds", "tasas_mensual.rds")))
if (!all(file.exists(archivos_app))) {
  cat("Alerta: falta", basename(archivos_app[!file.exists(archivos_app)]), "\n")
} else {
  cat("Verificación exitosa: app.R y sus seis insumos están en", ruta_app, "\n")
}

# CUIDADO: mientras la app está abierta la consola de R queda ocupada. Para
# cerrarla, cierre la ventana de la app o use el botón de stop de la consola.
runApp(ruta_app)                         # Función no vista: abre la app que está en la carpeta indicada
