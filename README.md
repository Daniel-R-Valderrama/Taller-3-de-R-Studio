# Taller 3 · Datos geoespaciales, web scraping y herramientas de visualización

Taller de Programación en R · Facultad de Economía, Universidad de los Andes · 2026-2
Profesor: Santiago Neira Hernández · Profesores asistentes: Juan Pablo Rocha, Camilo Alexander Ramírez, Sergio Andrés Vasquez Jimenez

Este README fija las reglas con las que se escribe y se audita todo el código del repositorio. Cualquier línea de código debe poder rastrearse a una clase del inventario (sección 3) o estar marcada como no vista (regla 3).

---

## 1. Contenido del taller

### 1.1 Ejercicios

| Ejercicio | Literal | Tema | Puntos |
|---|---|---|---|
| 1. Datos geoespaciales | A | IDF departamental artificial: media ponderada del IDF municipal con ponderador población × VA, proyección del VA 2023 a 2024, mapa departamental e interpretación | 1,0 |
| | B | Intento de mapa del IDF municipal y explicación de los problemas computacionales (bono si se resuelve y se presenta) | 0,5 |
| 2. Web scraping y API | A | IBR overnight diaria, 01/01/2020 a 31/10/2025 (Banco de la República) | 0,7 |
| | B | SOFR overnight diaria, 01/01/2020 a 31/10/2025 (Fed de Nueva York) | 0,7 |
| | C | Gráfico de doble eje (SOFR izquierda, IBR derecha), frecuencia elegida y comparación de tendencias | 0,6 |
| 3. Aplicativo Shiny | A | Pestaña 1: mapa interactivo del IDF departamental con top 3 de municipios por IDF municipal | 0,5 |
| | B | Pestaña 2: doble eje interactivo, consulta por fecha y devaluación implícita π = (1 + i_d)/(1 + i_e) − 1 | 0,5 |
| | C | Pestaña 3: gráfica libre en plotly con al menos un widget y texto explicativo escrito por el grupo | 0,5 |
| **Total** | | | **5,0 + bonos** |

Bonos: mapa municipal resuelto (1B) y mejor diseño del aplicativo (3).

### 1.2 Entregables

| # | Entregable | Observación |
|---|---|---|
| 1 | Script(s) en R | Código de tratamiento, extracción y gráficas |
| 2 | Archivo RMarkdown y documento generado | El documento contiene gráficas, tablas, verificaciones e interpretaciones del grupo |
| 3 | Aplicativo Shiny con tres pestañas | Datos geoespaciales, series financieras y diseño libre |
| 4 | Base de datos del literal 3C | Solo si la gráfica libre usa datos que no están en el repositorio |
| 5 | Enlace o anexo de la conversación con IA | Obligatorio. Omitirlo resta una unidad a la nota total |
| 6 | Nota sobre paquetes no vistos | Indicar en la entrega cuáles se usaron y cómo se marcaron (regla 3) |

### 1.3 Archivos propuestos

```
Taller 3/
├── README.md
├── 00_reinstalar_paquetes.R
├── 01_datos_geoespaciales.R
├── 02_tasas_api_scraping.R
├── Taller3_documento.Rmd
├── Taller3_documento.html
├── app_shiny/
│   ├── app.R
│   └── datos/
├── Bases de Datos/
├── Resultados/
└── anexos/
```

| Archivo o carpeta | Contenido | Lee de | Escribe en |
|---|---|---|---|
| `00_reinstalar_paquetes.R` | Reinstalación de paquetes en una sesión nueva de R, cuando hay errores de versiones | | |
| `01_datos_geoespaciales.R` | Ejercicio 1: lectura, llaves, uniones, ponderadores, proyección del VA, mapas | `Bases de Datos/` | `Resultados/`, `app_shiny/datos/` |
| `02_tasas_api_scraping.R` | Ejercicio 2: extracción por API y por scraping, registro de extracción, limpieza de fechas, gráficas | Internet | `Resultados/`, `app_shiny/datos/` |
| `app_shiny/app.R` | Ejercicio 3: aplicativo con tres pestañas | `app_shiny/datos/` | Nada |
| `app_shiny/datos/` | Objetos `.rds` ya procesados que usa la app, más la base del literal 3C | | |
| `Taller3_documento.Rmd` | Documento final: resultados, verificaciones e interpretaciones del grupo | `Resultados/` | `Taller3_documento.html` |
| `Bases de Datos/` | Shapefiles DANE y Excel de DNP y DANE tal como se descargaron | | Nunca se escribe aquí |
| `Resultados/` | Figuras, tablas y objetos con prefijo de punto y literal (`1_A_`, `2_C_`), objetos (`.rds`), registro de extracción, descargas del scraping | | |
| `anexos/` | Conversación con IA exportada o archivo con el enlace | | |

Ruta del taller: `C:\Users\Daniel\OneDrive\Escritorio\2026-2\R\Taller 3`, con las subcarpetas `Bases de Datos` y `Resultados`.

Orden de ejecución: `01_datos_geoespaciales.R` → `02_tasas_api_scraping.R` → `Taller3_documento.Rmd` → `app_shiny/app.R`.

---

## 2. Reglas de desarrollo

1. **Funciones permitidas.** Se puede usar cualquier función de base R o de un paquete del inventario (sección 3), aunque esa función puntual no se haya visto en clase. El criterio de auditoría es el paquete, no la función.

2. **Paquetes nuevos solo si no hay alternativa.** Antes de cargar un paquete fuera del inventario hay que intentar resolver la tarea con base R o con el inventario. Candidatos según lo que pide el enunciado:

   | Paquete candidato | Para qué | Ejercicio | Alternativa con el inventario | Recomendación |
   |---|---|---|---|---|
   | `rvest` | Leer HTML y extraer tablas o enlaces (web scraping) | 2 | `readLines()` + `grep()` / `regmatches()` de base R, que sirven en páginas HTML estáticas y simples | Usar si la página tiene tablas o enlaces que la regex vuelve frágil. Es el candidato más probable |
   | `jsonlite` | Convertir respuestas JSON de una API a data frame | 2 | Pedir a la API el formato CSV y leerlo con `readr::read_csv()` | Evitar si la API ofrece CSV |
   | `httr2` (o `httr`) | Peticiones HTTP con parámetros, encabezados o manejo de errores | 2 | `readr::read_csv(url)` o `download.file()` cuando la consulta cabe en una URL | Solo si la API exige encabezados o autenticación |
   | `readxl` | Leer Excel en formato antiguo `.xls` | 1 | `openxlsx::read.xlsx()` lee `.xlsx` pero no `.xls` | Solo si algún original llega como `.xls`. No convertir el archivo a mano (regla 5) |
   | `rmapshaper` | Simplificar polígonos conservando la topología entre vecinos | 1B | `sf::st_simplify()` | Probar primero `st_simplify()`. Usar solo si deja huecos o solapamientos visibles |
   | `chromote` o `RSelenium` | Páginas que cargan los datos con JavaScript | 2 | Ninguna dentro del inventario | Último recurso. Antes, revisar si la página tiene un enlace de descarga o un servicio web |

   No hacen falta: `stringr` (sirven `gsub()`, `trimws()`, `toupper()`, `iconv()`), `janitor` (sirven `names()` y `tolower()`), `readxl` si todo es `.xlsx`.

3. **Marcado de paquetes no vistos.** Cada script lista, en la sección CONFIGURACIÓN INICIAL DEL AMBIENTE debajo de `#otros paquetes para este punto`, los paquetes no vistos que usa (o escribe "ninguno"). Toda línea que use uno de ellos termina con `# [NO VISTO EN CLASE]`. Además, esas funciones se llaman siempre con prefijo `paquete::funcion()`, para que la auditoría se pueda hacer buscando el nombre del paquete. Este mismo sistema se describe en la nota de entrega.

4. **Formato de texto.** `sprintf()` y `formatC()` están permitidas para formatear texto (rellenar códigos DIVIPOLA con ceros, imprimir tasas con dos decimales, armar mensajes). Cada uso lleva un comentario corto que diga qué formatea.

5. **Organización y archivos.**
   - Cada script empieza con el bloque fijo de la sección 4 (`# Taller 3, Punto X`, CONFIGURACIÓN INICIAL DEL AMBIENTE y DIRECTORIO DE TRABAJO). Después vienen bloques numerados (`BLOQUE 1`, `BLOQUE 2`, ...). Cada bloque hace una sola cosa y termina con su verificación.
   - Los paquetes no se instalan desde los scripts del taller: si hay errores de versiones se corre `00_reinstalar_paquetes.R` en una sesión nueva.
   - `setwd()` va en DIRECTORIO DE TRABAJO, con la ruta armada a partir de `Sys.getenv("USERNAME")` hasta la carpeta `Taller 3`. Excepciones: `app.R` no usa `setwd()` (Shiny ya trabaja desde la carpeta de la app) y el `.Rmd` fija la ruta con `knitr::opts_knit$set(root.dir = ...)`.
   - Los archivos de `Bases de Datos/` nunca se modifican, ni a mano ni desde R. Todo resultado se escribe en `Resultados/` o `app_shiny/datos/`.
   - Al corregir código se entregan solo los bloques que cambian, completos y con su número.
   - El estilo de escritura sigue la sección 6 (patrones de los Talleres 1 y 2), para que el grupo pueda auditar el código comparándolo con lo que ya escribió.

6. **Verificaciones.** Cada paso lleva su verificación inmediatamente después. Mínimo obligatorio:

   | Verificación | Dónde | Cómo |
   |---|---|---|
   | Filas antes y después de cada unión | 1, 2 | `nrow()` antes y después, con `if` y `cat("Alerta: ...")` como en el Taller 2 |
   | Llaves sin pareja | 1, 2 | `anti_join()` en ambos sentidos y conteo con `nrow()` |
   | Llaves duplicadas | 1 | `count(llave) %>% filter(n > 1)` en cada base antes de unir |
   | Ponderadores suman 1 por departamento | 1A | `group_by(cod_dpto) %>% summarise(sum(w))` comparado con 1 usando una tolerancia |
   | Precios del VA y tasa de crecimiento | 1A | Registrar en comentario la base de precios del anexo; tasa con `round(tasa, 2)` antes de aplicarla |
   | Cálculo comprobado por otro procedimiento | 1A | IDF departamental con `sum(idf * w)` contra `weighted.mean(idf, L * VA)` |
   | Serie correcta | 2A, 2B | Confirmar que es IBR overnight y SOFR overnight, con unidad y convención de tasa documentadas |
   | Rango de fechas | 2A, 2B | `min()` y `max()` de la fecha dentro de 01/01/2020 a 31/10/2025; número de observaciones |
   | Registro de extracción | 2 | Fuente, serie, método, URL y fecha de consulta en `Resultados/2_registro_extraccion.xlsx` |
   | Observación contrastada con la fuente oficial | 2A, 2B | Al menos una fecha por tasa, comparada con el valor publicado y anotada en el registro |
   | Fechas sin observación | 2C, 3B | Conteo de `NA` por serie después de unir IBR y SOFR por fecha |
   | Tasa faltante en la app | 3B | `validate(need(...))` con mensaje al usuario |

7. **Uso de IA según el enunciado.**
   - Se permite IA para el código y el desarrollo técnico. La conversación se enlaza o se adjunta en `anexos/`; sin eso se pierde una unidad de la nota total.
   - No se permite IA para redactar las interpretaciones. En el código y en el `.Rmd` la IA deja el marcador `[INTERPRETACIÓN: la escribe el grupo]` y no lo llena.
   - Quedan bajo esta regla, por ser texto de análisis: interpretación del mapa (1A), justificación de la tasa de crecimiento elegida (1A), explicación de los problemas computacionales del mapa municipal (1B), comparación de tendencias IBR y SOFR (2C) y el cuadro de texto de la gráfica libre (3C).
   - La IA sí puede documentar en comentarios de código lo que el código hace (por ejemplo, "se toma el promedio mensual de los días con dato").
   - La responsabilidad por la exactitud del taller es del grupo, aunque se use IA.

8. **Funciones no vistas.** Una función de un paquete del inventario que no se haya visto en clase se puede usar (regla 1), pero lleva un comentario corto en la misma línea o en la anterior con el formato `# Función no vista: qué hace`.

---

## 3. Inventario

Lo visto en clase es la única fuente de verdad para auditar. Faltan las Clases 5, 10 y 12; si se recuperan, se agregan aquí.

| Paquete | Clase(s) | Uso principal | ¿Lo usa el taller? |
|---|---|---|---|
| base R | 1, 2 (y todas) | Objetos, vectores, data frames, funciones, condicionales, ciclos, `paste0()`, `cat()`, `nrow()`, `saveRDS()`, `readRDS()` | Sí, en todo |
| `docstring` | 3 | Documentar funciones propias con comentarios `#'` y consultarlas con `docstring()` | Sí, funciones auxiliares de verificación |
| `openxlsx` | 4, 6, 7 | Leer y escribir archivos `.xlsx` | Sí, originales DNP/DANE y registro de extracción |
| `dplyr` | 6, 7, 8 | Manipulación de datos: `filter()`, `mutate()`, `group_by()`, `summarise()`, uniones `*_join()` | Sí, en todo |
| `tidyr` | 6 | Reestructurar datos (`pivot_longer()`, `pivot_wider()`), `fill()`, `drop_na()` | Sí, anexos DANE en formato ancho y series |
| `readr` | 6 | Leer y escribir texto plano (`read_csv()`, `write_csv()`) | Sí, API de SOFR en CSV |
| `ggplot2` | 7, 8, 13 | Gráficas estáticas y mapas con `geom_sf()` | Sí, ejercicios 1 y 2 |
| `lubridate` | 7, 8 | Fechas: `ymd()`, `floor_date()`, `year()`, `month()` | Sí, ejercicio 2 |
| `RColorBrewer` | 7 | Paletas de color secuenciales y cualitativas | Sí, mapas |
| `ggthemes` | 8 | Temas predefinidos para ggplot2 | Opcional |
| `plotly` | 8, 9 | Gráficas interactivas (`ggplotly()`, `plot_ly()`) | Sí, 3B y 3C (obligatorio en 3C) |
| `gganimate` | 8 | Animación de gráficas ggplot2 | No |
| `gifski` | 8 | Exportar animaciones a GIF | No |
| `ggrepel` | 8, 13 | Etiquetas que no se superponen, también sobre mapas | Sí, nombres de departamentos |
| `gapminder` | 8, 9 | Base de datos de ejemplo | Opcional en 3C |
| `scales` | 8 | Formato de ejes y etiquetas (porcentajes, separadores) | Sí, ejes de tasas |
| `htmlwidgets` | 8 | Guardar widgets interactivos como HTML (`saveWidget()`) | Sí, exportar mapas y plotly |
| `rmarkdown` | 9 | Generar el documento desde el `.Rmd` | Sí |
| `knitr` | 9 | Opciones de chunks, `kable()` para tablas | Sí |
| `quarto` | 9 | Documentos Quarto | No (se usa RMarkdown) |
| `DT` | 9 | Tablas interactivas | Sí, top 3 de municipios en 3A |
| `leaflet` | 9, 13 | Mapas interactivos | Sí, 3A |
| `crosstalk` | 9 | Filtros compartidos entre widgets sin servidor | Opcional en 3C |
| `shiny` | 9 | Aplicativos interactivos | Sí, ejercicio 3 |
| `shinydashboard` | 9 | Estructura de tablero con pestañas | Sí, ejercicio 3 |
| `modelsummary` | 11 | Tablas de regresión | No |
| `lmtest` | 11 | Pruebas sobre modelos lineales | No |
| `sandwich` | 11 | Errores estándar robustos | No |
| `fixest` | 11 | Regresiones con efectos fijos | No |
| `AER` | 11 | Datos y modelos de econometría aplicada | No |
| `estimatr` | 11 | Se cargó en clase pero no se usó | No. No cuenta como visto |
| `sf` | 13 | Leer shapefiles, transformar proyecciones, uniones y simplificación de geometrías | Sí, ejercicio 1 y 3A |
| `BAMMtools` | 13 | Cortes naturales de Jenks (`getJenksBreaks()`) para clasificar valores en mapas | Sí, escala de colores del mapa |

---

## 4. Plantilla de estructura del código

Todo script de un punto empieza con este bloque fijo, sin cambios salvo el número del punto, los paquetes y la lista de no vistos. Después siguen los bloques numerados.

```r
# Taller 3, Punto X
cat("\014")
rm(list = ls())
# ==============================================================================
# CONFIGURACIÓN INICIAL DEL AMBIENTE
# ==============================================================================

# Si es la primera vez o tienen errores de versiones, NO instalen desde aquí:
# corran primero el script 00_reinstalar_paquetes.R en una sesión nueva de R.
# CUIDADO: instalar un paquete que ya está cargado deja la instalación a medias.

library(sf)          # datos geoespaciales (shapefiles, proyecciones, geometrías)
library(dplyr)       # manipulación de datos
library(ggplot2)     # visualización (geom_sf dibuja mapas)
library(ggrepel)     # etiquetas que no se solapan
library(BAMMtools)   # getJenksBreaks(): clasificación por cortes naturales
library(leaflet)     # mapas interactivos

#otros paquetes para este punto
library(openxlsx)      # lectura de los Excel de DNP y DANE
library(RColorBrewer)  # paletas de color para el mapa

# Paquetes no vistos en clase: ninguno
#   (si hay alguno: nombre y para qué se usa; cada línea que lo use
#    termina en # [NO VISTO EN CLASE])

# ==============================================================================
# DIRECTORIO DE TRABAJO
# ==============================================================================

username <- Sys.getenv("USERNAME")     # usuario del sistema


# ajustarla a la ubicación de SU carpeta "Taller 3".
ruta_taller <- paste0("C:/Users/", username,
                      "/OneDrive/Escritorio/2026-2/R/Taller 3")

#Configuración MacOs
#username <- Sys.getenv("USER")
#ruta_taller <- paste0("/Users/", username, "/Taller 3")

setwd(ruta_taller)

# CUIDADO: "Bases de Datos" es solo lectura. Nada se escribe ahí.
ruta_bases      <- file.path(ruta_taller, "Bases de Datos")
ruta_resultados <- file.path(ruta_taller, "Resultados")
dir.create(ruta_resultados, showWarnings = FALSE)

# Verificación Programática 1: las carpetas existen
if (dir.exists(ruta_bases) & dir.exists(ruta_resultados)) {
  cat("Verificación exitosa: carpetas encontradas en", getwd(), "\n")
} else {
  cat("Alerta: revise la ruta del taller\n")
}


# =============================================================================
# BLOQUE 1. CARGA DE DATOS ORIGINALES
# =============================================================================

# ---------- IDF municipal (DNP) ----------
idf_raw <- read.xlsx(file.path(ruta_bases, "nombre_archivo_idf.xlsx"),
                     sheet = 1, startRow = 1)

# Verificación
dim(idf_raw)
names(idf_raw)
head(idf_raw)


# =============================================================================
# BLOQUE 2. LIMPIEZA Y LLAVES
# =============================================================================

# ... cada subtema con su verificación justo después ...


# =============================================================================
# BLOQUE N. EXPORTAR RESULTADOS
# =============================================================================

saveRDS(objeto, file.path(ruta_resultados, "objeto.rds"))
saveRDS(objeto, "app_shiny/datos/objeto.rds")

# Verificación
file.exists(file.path(ruta_resultados, "objeto.rds"))

# [INTERPRETACIÓN: la escribe el grupo en el .Rmd]
```

### Convenciones

| Elemento | Convención | Ejemplo |
|---|---|---|
| Nombres de scripts | Número de ejercicio + tema, minúsculas y guion bajo | `01_datos_geoespaciales.R` |
| Inicio del script | `# Taller 3, Punto X`, `cat("\014")`, `rm(list = ls())`, CONFIGURACIÓN INICIAL DEL AMBIENTE y DIRECTORIO DE TRABAJO | Ver plantilla |
| Paquetes | Un `library()` por línea con comentario de para qué sirve; los del punto debajo de `#otros paquetes para este punto` | `library(sf)          # datos geoespaciales` |
| Rutas | `ruta_taller` con `setwd()`; `ruta_bases` y `ruta_resultados` con `file.path()`, como en el Taller 2 | `read.xlsx(file.path(ruta_bases, "archivo.xlsx"))` |
| Secciones | `# ====` arriba y abajo, `BLOQUE N.` y título en MAYÚSCULAS | `# BLOQUE 3. UNIÓN DE BASES` |
| Subtemas | `# ---------- Subtema ----------` | `# ---------- Llaves DIVIPOLA ----------` |
| Avisos | `# CUIDADO: ...` | `# CUIDADO: el shapefile debe ir a la izquierda del join` |
| Paquete no visto | `paquete::funcion()` y `# [NO VISTO EN CLASE]` al final de la línea | `rvest::read_html(url) # [NO VISTO EN CLASE]` |
| Función no vista de paquete visto | `# Función no vista: qué hace` | `# Función no vista: st_simplify reduce vértices` |
| Uso de `sprintf()` / `formatC()` | Comentario que diga qué formatea | `# formatC: código municipal a 5 dígitos` |
| Pipe | `%>%` | |
| Comentarios | En español | |
| Objetos | Minúsculas con guion bajo; sufijo `_raw` para datos recién leídos | `idf_raw`, `idf_mun`, `shp_dpto` |
| Llaves | Siempre texto, con ceros a la izquierda | `cod_dpto` (2 caracteres), `cod_mpio` (5 caracteres) |
| Fechas | Clase `Date` | `fecha` |
| Tasas | Sufijo de unidad en el nombre | `ibr_pct`, `ibr_dec`, `sofr_pct` |
| Salidas | Número de punto y literal al inicio, como en el Taller 2 (`2_2_tasas_sexo.png`) | `Resultados/1_A_mapa_idf_dpto.png`, `Resultados/1_A_idf_dpto.xlsx` |
| Interpretaciones | Marcador sin llenar | `[INTERPRETACIÓN: la escribe el grupo]` |

---

## 5. Patrones de código por tipo de tarea

Cada molde indica la clase de la que sale. Los nombres de archivos, hojas y columnas son de ejemplo: se ajustan después de inspeccionar cada original con `names()` y `head()`.

### 5.1 Función auxiliar documentada para verificar uniones (Clases 2, 3 y 6)

```r
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
  dup_x <- x %>% count(.data[[llave]]) %>% filter(n > 1)
  dup_y <- y %>% count(.data[[llave]]) %>% filter(n > 1)
  solo_x <- x %>% anti_join(y, by = llave)
  solo_y <- y %>% anti_join(x, by = llave)
  cat("Duplicados en x:", nrow(dup_x), "| Duplicados en y:", nrow(dup_y), "\n")
  cat("Sin pareja en y:", nrow(solo_x), "| Sin pareja en x:", nrow(solo_y), "\n")
  return(list(dup_x = dup_x, dup_y = dup_y, solo_x = solo_x, solo_y = solo_y))
}

library(docstring)
docstring(verificar_union)
```

### 5.2 Lectura de originales en Excel sin modificarlos (Clase 4)

```r
# ---------- Población municipal 2024 (DANE) ----------
# CUIDADO: los anexos del DANE traen filas de títulos arriba de la tabla.
# Se saltan con startRow; el archivo original no se toca.
pob_raw <- read.xlsx(file.path(ruta_bases, "proyecciones_poblacion_municipal.xlsx"),
                     sheet = 1, startRow = 9)

# Verificación
dim(pob_raw)
names(pob_raw)
tail(pob_raw)   # revisar notas al pie que hay que quitar
```

### 5.3 Llaves DIVIPOLA y filtros de filas que no son municipios (Clase 6 + regla 4)

```r
# ---------- Llaves DIVIPOLA ----------
pob_mun <- pob_raw %>%
  rename(cod_mpio = COD_MPIO, anio = AÑO, poblacion = Total) %>%
  filter(anio == 2024) %>%
  mutate(cod_mpio = formatC(as.integer(cod_mpio), width = 5, flag = "0"),  # formatC: código municipal a 5 dígitos
         cod_dpto = substr(cod_mpio, 1, 2)) %>%
  select(cod_dpto, cod_mpio, poblacion)

# Verificación
table(nchar(pob_mun$cod_mpio))           # todos deben tener 5
pob_mun %>% count(cod_mpio) %>% filter(n > 1)
n_distinct(pob_mun$cod_dpto)             # 33 incluyendo Bogotá

# CUIDADO: si el código viene con área (total, cabecera, centro poblado),
# filtrar el total antes de unir para no duplicar municipios.
```

Para nombres con tildes, si hiciera falta compararlos: `toupper(iconv(x, to = "ASCII//TRANSLIT"))` de base R.

### 5.4 Unión con verificación de filas y llaves (Clase 6)

```r
# ---------- Unión IDF + población ----------
chequeo <- verificar_union(idf_mun, pob_mun, "cod_mpio")
chequeo$solo_x            # municipios con IDF sin población: revisar uno por uno

n_antes <- nrow(idf_mun)
base_mun <- idf_mun %>%
  left_join(pob_mun %>% select(-cod_dpto), by = "cod_mpio")
n_despues <- nrow(base_mun)

# Verificación Programática 2: el pegue no aumenta las filas de la base
if (n_despues != n_antes) {
  cat("Alerta: el pegue multiplicó filas (", n_antes, "->", n_despues, ")\n")
} else {
  cat("Verificación exitosa: el pegue conserva", n_despues, "filas\n")
}
sum(is.na(base_mun$poblacion))
```

Evidencia para la entrega: guardar `chequeo` y los conteos en `Resultados/1_A_verificacion_uniones.xlsx` con `write.xlsx()`.

### 5.5 Proyección del VA, ponderadores e IDF departamental (Clase 6 + base R)

```r
# ---------- Proyección del VA 2023 a 2024 ----------
# Precios del VA según el anexo: [anotar aquí lo que dice el archivo]
tasa_pib_2024 <- round(X.XX, 2)          # tasa porcentual elegida por el grupo
# [INTERPRETACIÓN: la justificación de la tasa la escribe el grupo]

base_mun <- base_mun %>%
  mutate(va_2024 = va_2023 * (1 + tasa_pib_2024 / 100))

# ---------- Ponderadores ----------
base_mun <- base_mun %>%
  filter(!is.na(idf), !is.na(poblacion), !is.na(va_2024)) %>%
  group_by(cod_dpto) %>%
  mutate(w = (poblacion * va_2024) / sum(poblacion * va_2024)) %>%
  ungroup()

# Verificación Programática 3: ponderadores suman 1 por departamento
suma_w <- base_mun %>% group_by(cod_dpto) %>% summarise(suma = sum(w), .groups = "drop")
if (all(abs(suma_w$suma - 1) < 1e-6)) {
  cat("Verificación exitosa: los ponderadores suman 1 en los", nrow(suma_w), "departamentos\n")
} else {
  warning("Hay departamentos cuyos ponderadores no suman 1")
}

# ---------- IDF departamental ----------
idf_dpto <- base_mun %>%
  group_by(cod_dpto) %>%
  summarise(idf_dpto = sum(idf * w),
            idf_dpto_chequeo = weighted.mean(idf, poblacion * va_2024),
            n_mpios = n(), .groups = "drop")

# Verificación Programática 4: cálculo comprobado por otro procedimiento
if (all(abs(idf_dpto$idf_dpto - idf_dpto$idf_dpto_chequeo) < 1e-6)) {
  cat("Verificación exitosa: sum(idf * w) coincide con weighted.mean()\n")
} else {
  cat("Alerta: los dos cálculos del IDF departamental no coinciden\n")
}
summary(idf_dpto$idf_dpto)
```

### 5.6 Shapefile y mapa coroplético con cortes de Jenks (Clases 7 y 13)

```r
# ---------- Shapefile departamental ----------
shp_dpto <- st_read(file.path(ruta_bases, "shp_departamentos/archivo.shp"))
names(shp_dpto)
st_crs(shp_dpto)

# CUIDADO: el objeto sf va a la izquierda del join para conservar la geometría.
n_antes <- nrow(shp_dpto)
mapa_dpto <- shp_dpto %>%
  mutate(cod_dpto = as.character(DPTO_CCDGO)) %>%
  left_join(idf_dpto, by = "cod_dpto")
if (nrow(mapa_dpto) != n_antes) cat("Alerta: el pegue con el shapefile cambió el número de filas\n")
sum(is.na(mapa_dpto$idf_dpto))
class(mapa_dpto)                         # debe seguir siendo "sf"

# ---------- Clases con cortes naturales ----------
cortes <- getJenksBreaks(mapa_dpto$idf_dpto, k = 6)
mapa_dpto <- mapa_dpto %>%
  mutate(idf_clase = cut(idf_dpto, breaks = cortes, include.lowest = TRUE))
table(mapa_dpto$idf_clase, useNA = "ifany")

# ---------- Mapa ----------
fig_mapa <- ggplot(mapa_dpto) +
  geom_sf(aes(fill = idf_clase), color = "white", linewidth = 0.2) +
  geom_text_repel(aes(geometry = geometry, label = nombre_dpto),
                  stat = "sf_coordinates", size = 2.5) +
  scale_fill_brewer(palette = "YlGnBu", name = "IDF departamental",
                    na.value = "grey80") +
  labs(title = "Índice de Desempeño Fiscal artificial por departamento, 2024",
       subtitle = "Media ponderada del IDF municipal (ponderador: población × VA)",
       caption = "Fuente: DNP, DANE. Cálculos propios.") +
  theme_void()

ggsave(filename = file.path(ruta_resultados, "1_A_mapa_idf_dpto.png"),
       plot = fig_mapa, width = 8, height = 9, units = "in", dpi = 300)
```

### 5.7 Mapa municipal: diagnóstico y simplificación (Clase 13)

```r
# ---------- Diagnóstico ----------
shp_mpio <- st_read(file.path(ruta_bases, "shp_municipios/archivo.shp"))
nrow(shp_mpio)
print(object.size(shp_mpio), units = "Mb")
sum(!st_is_valid(shp_mpio))              # geometrías inválidas

system.time(print(ggplot(shp_mpio) + geom_sf()))   # tiempo de dibujo original

# ---------- Corrección y simplificación ----------
shp_mpio_simple <- shp_mpio %>%
  st_make_valid() %>%                    # Función no vista: corrige geometrías inválidas
  st_transform(3116) %>%                 # proyección en metros para que dTolerance esté en metros
  st_simplify(preserveTopology = TRUE, dTolerance = 500)   # Función no vista: reduce vértices

# Verificación
print(object.size(shp_mpio_simple), units = "Mb")
system.time(print(ggplot(shp_mpio_simple) + geom_sf()))
```

Los tiempos y tamaños medidos sirven de insumo; la explicación de los problemas la escribe el grupo. El EPSG 3116 (MAGNA-SIRGAS Bogotá) es una opción a confirmar.

### 5.8 SOFR por API en formato CSV (Clase 6)

```r
# ---------- Extracción SOFR: API de Markets Data (Fed de Nueva York) ----------
# CUIDADO: confirmar la ruta exacta y los parámetros en la documentación de la API.
url_sofr <- paste0("https://markets.newyorkfed.org/api/rates/secured/sofr/search.csv",
                   "?startDate=2020-01-01&endDate=2025-10-31")
fecha_consulta_sofr <- Sys.time()
sofr_raw <- read_csv(url_sofr)

# Verificación
dim(sofr_raw)
names(sofr_raw)
head(sofr_raw)
```

Con esto la API se consume sin paquetes nuevos. Si solo hubiera JSON, el candidato es `jsonlite` (regla 2).

### 5.9 IBR por web scraping (paquete no visto)

```r
# ---------- Extracción IBR: web scraping (Banco de la República) ----------
# Paquetes no vistos: rvest (lectura de HTML)
url_ibr <- "URL_DE_LA_PAGINA_DEL_IBR"   # anotar la página oficial usada
fecha_consulta_ibr <- Sys.time()

pagina_ibr <- rvest::read_html(url_ibr)                                  # [NO VISTO EN CLASE]
enlaces <- pagina_ibr %>% rvest::html_elements("a") %>% rvest::html_attr("href")   # [NO VISTO EN CLASE]
enlaces[grepl("ibr", enlaces, ignore.case = TRUE)]

# Si la página trae la tabla en HTML:
tablas <- pagina_ibr %>% rvest::html_table()                             # [NO VISTO EN CLASE]

# Si trae un enlace de descarga a Excel:
download.file(url_archivo_ibr, file.path(ruta_resultados, "2_A_ibr_descarga.xlsx"), mode = "wb")
ibr_raw <- read.xlsx(file.path(ruta_resultados, "2_A_ibr_descarga.xlsx"))

# Verificación
dim(ibr_raw)
names(ibr_raw)
```

Alternativa sin paquetes nuevos para páginas HTML simples:

```r
html <- readLines(url_ibr, warn = FALSE, encoding = "UTF-8")
enlaces <- regmatches(html, regexpr('href="[^"]+"', html))
```

CUIDADO: el archivo descargado va a `Resultados/` porque es un resultado de la extracción, no un original entregado por el enunciado.

### 5.10 Registro de extracción (Clases 4 y 6)

```r
# ---------- Registro de extracción ----------
registro <- data.frame(
  fuente         = c("Banco de la República", "Federal Reserve Bank of New York"),
  serie          = c("IBR overnight", "SOFR overnight"),
  metodo         = c("Web scraping", "API"),
  url            = c(url_ibr, url_sofr),
  fecha_consulta = format(c(fecha_consulta_ibr, fecha_consulta_sofr), "%Y-%m-%d %H:%M"),
  unidad         = c("[completar]", "[completar]"),
  convencion     = c("[completar]", "[completar]"),
  n_obs          = c(nrow(ibr), nrow(sofr)),
  fecha_min      = c(min(ibr$fecha), min(sofr$fecha)),
  fecha_max      = c(max(ibr$fecha), max(sofr$fecha)),
  fecha_contraste       = c("[fecha]", "[fecha]"),
  valor_extraido        = c(NA, NA),
  valor_fuente_oficial  = c(NA, NA),
  correccion            = c("[describir o 'ninguna']", "[describir o 'ninguna']")
)

write.xlsx(registro, file.path(ruta_resultados, "2_registro_extraccion.xlsx"))

# Verificación
registro
```

### 5.11 Fechas, filtro de rango y unión de series (Clases 6 y 7)

```r
# ---------- Limpieza de fechas y tasas ----------
sofr <- sofr_raw %>%
  rename(fecha = `Effective Date`, sofr_pct = `Rate (%)`) %>%
  mutate(fecha = mdy(fecha)) %>%
  filter(fecha >= ymd("2020-01-01"), fecha <= ymd("2025-10-31")) %>%
  select(fecha, sofr_pct) %>%
  arrange(fecha)

# Verificación
range(sofr$fecha)
nrow(sofr)
sum(duplicated(sofr$fecha))
summary(sofr$sofr_pct)

# ---------- Unión por fecha ----------
# CUIDADO: los festivos de Colombia y Estados Unidos no coinciden.
tasas <- full_join(ibr, sofr, by = "fecha") %>% arrange(fecha)

# Verificación
nrow(ibr); nrow(sofr); nrow(tasas)
colSums(is.na(tasas))                    # fechas sin observación por serie

# ---------- Agregación (frecuencia elegida por el grupo) ----------
tasas_mes <- tasas %>%
  mutate(mes = floor_date(fecha, "month")) %>%
  group_by(mes) %>%
  summarise(ibr_pct = mean(ibr_pct, na.rm = TRUE),
            sofr_pct = mean(sofr_pct, na.rm = TRUE),
            dias_ibr = sum(!is.na(ibr_pct)),
            dias_sofr = sum(!is.na(sofr_pct)))

# Verificación
nrow(tasas_mes)                          # 70 meses entre ene-2020 y oct-2025
summary(tasas_mes$dias_ibr)
```

Si en la app se quiere rellenar con el último dato disponible: `tidyr::fill(ibr_pct, .direction = "down")` (Clase 6). La decisión y su explicación quedan en el documento.

### 5.12 Gráfico de doble eje estático (Clases 7 y 8)

```r
# ---------- Doble eje: SOFR izquierda, IBR derecha ----------
factor_eje <- max(tasas_mes$ibr_pct, na.rm = TRUE) / max(tasas_mes$sofr_pct, na.rm = TRUE)

fig_doble <- ggplot(tasas_mes, aes(x = mes)) +
  geom_line(aes(y = sofr_pct, color = "SOFR ON")) +
  geom_line(aes(y = ibr_pct / factor_eje, color = "IBR ON")) +
  scale_y_continuous(name = "SOFR (% anual)",
                     sec.axis = sec_axis(~ . * factor_eje, name = "IBR (% anual)")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b-%Y") +
  scale_color_brewer(palette = "Set1", name = NULL) +
  labs(title = "IBR overnight y SOFR overnight",
       subtitle = "Promedio mensual, enero 2020 a octubre 2025",
       x = NULL,
       caption = "Fuente: Banco de la República; Federal Reserve Bank of New York.") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(filename = file.path(ruta_resultados, "2_C_doble_eje.png"),
       plot = fig_doble, width = 9, height = 5, units = "in", dpi = 300)

# Verificación Programática: el factor de escala es válido
if (!is.finite(factor_eje) | factor_eje <= 0) cat("Alerta: revise el factor de escala del doble eje\n")
```

### 5.13 Doble eje interactivo en plotly (Clases 8 y 9)

```r
# ---------- Doble eje interactivo ----------
fig_doble_int <- plot_ly(tasas) %>%
  add_lines(x = ~fecha, y = ~sofr_pct, name = "SOFR ON (% anual)") %>%
  add_lines(x = ~fecha, y = ~ibr_pct, name = "IBR ON (% anual)", yaxis = "y2") %>%
  layout(title = "IBR overnight y SOFR overnight, 2020-2025",
         yaxis  = list(title = "SOFR (% anual)"),
         yaxis2 = list(title = "IBR (% anual)", overlaying = "y", side = "right"),
         xaxis  = list(title = ""),
         legend = list(orientation = "h"))

htmlwidgets::saveWidget(widget = fig_doble_int,
                        file = file.path(ruta_resultados, "3_B_doble_eje_interactivo.html"),
                        selfcontained = TRUE)
```

### 5.14 Mapa departamental en leaflet (Clases 9 y 13)

```r
# ---------- Mapa interactivo ----------
# CUIDADO: leaflet necesita coordenadas en EPSG 4326.
mapa_dpto_ll <- st_transform(mapa_dpto, 4326)

pal <- colorBin("YlGnBu", domain = mapa_dpto_ll$idf_dpto, bins = cortes)

leaflet(mapa_dpto_ll) %>%
  addTiles() %>%
  addPolygons(layerId = ~cod_dpto,
              fillColor = ~pal(idf_dpto), fillOpacity = 0.8,
              color = "white", weight = 1,
              label = ~paste0(nombre_dpto, ": IDF departamental ", round(idf_dpto, 1))) %>%
  addLegend(pal = pal, values = ~idf_dpto, title = "IDF departamental")
```

### 5.15 Aplicativo Shiny con tres pestañas (Clase 9)

```r
# =============================================================================
# CONFIGURACIÓN INICIAL DEL AMBIENTE
# =============================================================================
# CUIDADO: app.R no usa setwd(); Shiny trabaja desde la carpeta app_shiny/.
library(shiny)
library(shinydashboard)
library(leaflet)
library(plotly)
library(DT)
library(dplyr)
library(sf)

mapa_dpto <- readRDS("datos/mapa_dpto.rds")
base_mun  <- readRDS("datos/base_mun.rds")
tasas     <- readRDS("datos/tasas.rds")

# =============================================================================
# BLOQUE 1. INTERFAZ
# =============================================================================
ui <- dashboardPage(
  dashboardHeader(title = "Taller 3"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Datos geoespaciales", tabName = "geo"),
      menuItem("Series financieras", tabName = "tasas"),
      menuItem("Diseño libre", tabName = "libre")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "geo",
              selectInput("dpto", "Departamento", choices = sort(mapa_dpto$nombre_dpto)),
              leafletOutput("mapa"),
              DTOutput("top3")),
      tabItem(tabName = "tasas",
              helpText("[Instrucciones de uso]"),
              dateInput("fecha", "Fecha a consultar", value = "2025-10-31",
                        min = "2020-01-01", max = "2025-10-31"),
              plotlyOutput("doble_eje"),
              verbatimTextOutput("devaluacion")),
      tabItem(tabName = "libre",
              # widget de control obligatorio
              plotlyOutput("grafica_libre"),
              box(width = 12, "[Texto explicativo: lo escribe el grupo]"))
    )
  )
)

# =============================================================================
# BLOQUE 2. SERVIDOR
# =============================================================================
server <- function(input, output, session) {

  # ---------- Pestaña 1: top 3 municipios ----------
  output$top3 <- renderDT({
    base_mun %>%
      filter(nombre_dpto == input$dpto) %>%
      slice_max(idf, n = 3) %>%
      select(Municipio = nombre_mpio, `IDF municipal` = idf)
  })

  # Clic en el mapa actualiza el selector
  observeEvent(input$mapa_shape_click, {
    cod <- input$mapa_shape_click$id
    updateSelectInput(session, "dpto",
                      selected = mapa_dpto$nombre_dpto[mapa_dpto$cod_dpto == cod])
  })

  # ---------- Pestaña 2: devaluación implícita ----------
  output$devaluacion <- renderText({
    fila <- tasas %>% filter(fecha == input$fecha)
    validate(need(nrow(fila) == 1 && !is.na(fila$ibr_dec), "No hay dato de IBR para esa fecha."))
    validate(need(!is.na(fila$sofr_dec), "No hay dato de SOFR para esa fecha."))
    pi_dev <- (1 + fila$ibr_dec) / (1 + fila$sofr_dec) - 1
    sprintf("IBR: %.4f | SOFR: %.4f | Devaluación implícita: %.4f (%.2f %%)",   # sprintf: tasas con decimales fijos
            fila$ibr_dec, fila$sofr_dec, pi_dev, pi_dev * 100)
  })
}

shinyApp(ui, server)
```

Para el literal 3B, `ibr_dec` y `sofr_dec` se calculan en `02_tasas_api_scraping.R` con la misma convención (regla 6, verificación de serie). La conversión elegida se documenta en un comentario y en el registro.

### 5.16 Documento RMarkdown (Clase 9, con la estructura del Taller 2)

````markdown
---
title: "Taller 3: Datos geoespaciales, web scraping y visualización"
author: "Daniel Eduardo Ramirez Hoyos |
 Daniel Ricardo Valderrama |
 David Santiago Morales Camacho"
date: "`r format(Sys.Date(), '%d/%m/%Y')`"
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
username <- Sys.getenv("USERNAME")
ruta_taller <- paste0("C:/Users/", username, "/OneDrive/Escritorio/2026-2/R/Taller 3")
knitr::opts_knit$set(root.dir = ruta_taller)
```

# Punto 1

## 1.A IDF departamental artificial

```{r p1_a}
# ==============================================================================
# 1.A IDF DEPARTAMENTAL ARTIFICIAL
# ==============================================================================
ruta_resultados <- file.path(ruta_taller, "Resultados")
idf_dpto <- readRDS(file.path(ruta_resultados, "1_A_idf_dpto.rds"))
```

```{r tabla_1_a, echo=FALSE}
knitr::kable(idf_dpto,
             caption = "Tabla 1.A. IDF departamental artificial, 2024",
             format.args = list(big.mark = ".", decimal.mark = ","))
```

```{r fig_1_a, echo=FALSE}
knitr::include_graphics(file.path(ruta_resultados, "1_A_mapa_idf_dpto.png"))
```

### Análisis 1.A

*[INTERPRETACIÓN: la escribe el grupo]*
````

Igual que en el Taller 2: chunks con nombre `p<punto>_<literal>` para el código y `tabla_<punto>_<literal>` con `echo=FALSE` para las tablas; cada literal cierra con `### Análisis X.Y` en cursiva.

---

## 6. Estilo de programación del grupo (Talleres 1 y 2)

El código nuevo debe parecerse al de las entregas `Entrega_Final_Taller_1.R` y `Taller_2_markdown.Rmd`, para que el grupo lo reconozca y lo audite sin esfuerzo. Cuando algo de esta sección choque con las convenciones genéricas de la sección 4, gana esta sección, salvo el bloque de inicio fijo y las marcas de no visto.

### 6.1 Patrones que se repiten

| Qué | Cómo lo escribe el grupo | Ejemplo real | Taller |
|---|---|---|---|
| Parámetros arriba | Se definen como objetos con comentario y todo el código depende de ellos, nunca de números escritos a mano | `n<- 1000         # tamaño de la muestra` | 1 |
| Enunciado en el script | Cada literal arranca con un comentario `#a. ...` que repite lo que pide | `#b. ¿Cuántos NA quedaron en el vector convertido?` | 1 |
| Separadores | Línea `# ====` completa entre ejercicios y secciones; `# ----` para subsecciones | `# 1.3 VARIABLES A MANTENER` entre líneas `# ----` | 1, 2 |
| Vectores de variables | Las columnas que se usan se declaran en un vector antes de leer, con comentario de qué es cada grupo | `vars_ft <- c("DIRECTORIO","SECUENCIA_P","ORDEN",...)` | 2 |
| Rutas | `username <- Sys.getenv("USERNAME")`, `paste0()` para la raíz, `file.path()` para subcarpetas, `dir.create(..., showWarnings = FALSE)`; alternativa de Mac comentada | `ruta_resultados <- file.path(ruta_base, "outputs")` | 2 |
| Lectura repetida | Loop `for` sobre años o archivos, rutas armadas con `paste0()`, `file.exists()` para nombres alternativos | `ruta_noc <- ruta_noc[file.exists(ruta_noc)][1]` | 2 |
| Verificaciones | Comentario `# Verificación Programática N: qué se revisa`, luego `if` con `cat("Alerta: ...")` o `cat("Verificación exitosa: ...")` | `if (nrow(df_mes) != filas_base) { cat("Alerta: El merge multiplicó filas en", mes, anio, "\n") }` | 2 |
| Duplicados en la llave | `nrow(df)` contra `nrow(distinct(df, llave1, llave2))` | `nrow(distinct(modulos[[m]], DIRECTORIO, SECUENCIA_P, ORDEN))` | 2 |
| Marcas de pareja | Columna `Info_X = 1` antes del `left_join` y luego `sum(!is.na(...))` para contar emparejados | `df_ft <- df_ft %>% mutate(Info_FT = 1)` | 2 |
| Tolerancia numérica | `abs(diferencia) < 1e-6` en lugar de igualdad exacta | `all(abs(chequeo_pob$diferencia) < 1e-6)` | 2 |
| Etiquetas | `case_when()` con una línea por código y `TRUE ~ ...` al final | `P3271 == 1 ~ "Hombre"` | 2 |
| Agrupaciones | `group_by()` + `summarise(..., .groups = "drop")` | | 2 |
| Porcentajes | `round(x / sum(x) * 100, 1)` en una columna `Porcentaje` | | 2 |
| Totales | Copia de la base con la categoría `"Total nacional"` unida a la original | `full_join(micro_pago, micro_pago %>% mutate(Rama = "Total nacional"), by = colnames(micro_pago))` | 2 |
| Funciones propias | Documentación `#'` con `@param`, `@return`, `@examples` dentro de la función; validaciones con `stop()` y `warning()` al inicio | `estadisticos_manuales()`, `lista_a_matriz()` | 1 |
| Reporte de resultados | `cat()` con texto y valores, con `round()` cuando hace falta | `cat("Registros EMICRON emparejados en GEIH:", ...)` | 1, 2 |
| Reemplazo de NA | Indexación directa | `ocupados_dic$P3069[is.na(ocupados_dic$P3069)] <- 999` | 2 |
| Gráficas | `labs()` con `title`, `subtitle`, `x`, `y` y `caption = "Fuente: ... Cálculos propios con ..."`; `theme_bw()` | Gráfica 2.2 | 2 |
| Exportar gráficas | `ggsave(filename = file.path(ruta_resultados, "2_2_nombre.png"), plot = g, width, height, units = "in", dpi = 300)` | | 2 |
| Interactivas | Columna `text` con `paste0()` y `ggplotly(p, tooltip = "text")`; `htmlwidgets::saveWidget(widget, file, selfcontained = TRUE)` | Gráfica 4.3 | 2 |
| Exportar tablas | `write.xlsx(list("Hoja" = df, ...), archivo, overwrite = TRUE)` para varias hojas | Exportar Punto 1 | 2 |
| Tablas en el documento | `knitr::kable(df, caption = "Tabla X.Y. ...", format.args = list(big.mark = ".", decimal.mark = ","))` | | 2 |
| Colores propios | `"#1F5F99"` (azul), `"#2E8B57"` (verde), `"#C0392B"` (rojo) con `scale_*_manual()` | Gráficas 2.2, 2.3, 4.4 | 2 |
| Memoria | `rm()` de objetos intermedios al cerrar cada punto | `rm(df_cg, df_ft, df_oc, ...)` | 2 |
| Nombres de objetos | `snake_case` descriptivo en español; prefijos `df_`, `vars_`, `ruta_`, `g_` (gráfica), `p_` (plotly), `tasa_`, `chequeo_` | `g_tasas`, `chequeo_micro` | 2 |

### 6.2 Qué no se copia de los talleres anteriores

| Hábito anterior | Por qué no se repite | Qué se hace en su lugar |
|---|---|---|
| Enunciado pegado como texto entre comillas sueltas (Taller 1) | R lo imprime en consola al correr el script | Comentario `#a. ...` |
| `help()` dentro del script (Taller 1) | Abre la ayuda cada vez que se corre | Consultar en consola, no dejarlo en el script |
| Muchos `mutate()` encadenados en una sola línea (Taller 2, punto 2.3) | Difícil de auditar línea por línea | Un `mutate()` o una condición por línea |
| Nombres mezclados (`propor.NAs`, `Sum_NAs`) (Taller 1) | Rompe la búsqueda por nombre | `snake_case` en minúsculas |
| `full_join(by = todas las columnas)` para apilar bases (Taller 2) | Si dos filas son idénticas en ambas bases, quedan como una sola | En este taller no se apilan bases; si hiciera falta, se discute antes |
| Ruta solo para Windows sin aviso | En Mac `USERNAME` viene vacío | Dejar la alternativa de Mac comentada, como en el Taller 2 |
