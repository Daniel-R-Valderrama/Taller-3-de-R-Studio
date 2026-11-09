# Taller 3 · Datos geoespaciales, web scraping y herramientas de visualización

Taller de Programación en R · Facultad de Economía, Universidad de los Andes · 2026-2
Profesor: Santiago Neira Hernández · Profesores asistentes: Juan Pablo Rocha, Camilo Alexander Ramírez, Sergio Andrés Vasquez Jimenez

Este README fija las reglas con las que se escribe y se audita todo el código del repositorio. Cualquier línea de código debe poder rastrearse a una clase del inventario (sección 3, construida con el script de clases `script_ejemplo.R`) o estar marcada como no vista (reglas 3 y 8).

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
| `Bases de Datos/` | IDF DNP 2024 municipios, `PPED-AreaMun-2018-2042_VP` (población), `anex-PIBDep-ValorAgreMuni-2011-2024p` (VA municipal) y las carpetas de shapefiles `MGN2025_DPTO_POLITICO` y `MGN2025_MPIO_GRAFICO`, tal como se descargaron | | Nunca se escribe aquí |
| `Resultados/` | Figuras, tablas y objetos con prefijo de punto y literal (`1_A_`, `2_C_`), objetos (`.rds`), registro de extracción, descargas del scraping | | |
| `anexos/` | Conversación con IA exportada o archivo con el enlace | | |

Ruta del taller: `C:\Users\Daniel\OneDrive\Escritorio\2026-2\R\Taller 3`, con las subcarpetas `Bases de Datos` y `Resultados`.

Orden de ejecución: `01_datos_geoespaciales.R` → `02_tasas_api_scraping.R` → `Taller3_documento.Rmd` → `app_shiny/app.R`.

---

## 2. Reglas de desarrollo

1. **Funciones permitidas.** Se puede usar cualquier función de base R o de un paquete del inventario (sección 3), aunque esa función puntual no se haya visto en clase. Primero se busca la alternativa que sí se vio (tabla 3.3); si no existe, la función lleva la marca de la regla 8.

2. **Paquetes nuevos solo si no hay alternativa.** Antes de cargar un paquete fuera del inventario hay que intentar resolver la tarea con base R o con el inventario. Candidatos según lo que pide el enunciado:

   | Paquete candidato | Para qué | Ejercicio | Alternativa con el inventario | Recomendación |
   |---|---|---|---|---|
   | `rvest` | Leer HTML y extraer tablas o enlaces (web scraping) | 2 | `readLines()` + `grep()` / `regmatches()` de base R, que sirven en páginas HTML estáticas y simples | Usar si la página tiene tablas o enlaces que la regex vuelve frágil. Es el candidato más probable |
   | `jsonlite` | Convertir respuestas JSON de una API a data frame | 2 | Pedir a la API el formato CSV y leerlo con `readr::read_csv()` | Evitar si la API ofrece CSV |
   | `httr2` (o `httr`) | Peticiones HTTP con parámetros, encabezados o manejo de errores | 2 | `readr::read_csv(url)` o `download.file()` cuando la consulta cabe en una URL | Solo si la API exige encabezados o autenticación |
   | `readxl` | Leer Excel en formato antiguo `.xls` | 1 | `openxlsx::read.xlsx()` lee `.xlsx` pero no `.xls` | Solo si algún original llega como `.xls`. No convertir el archivo a mano (regla 5) |
   | `rmapshaper` | Simplificar polígonos conservando la topología entre vecinos | 1B | `sf::st_simplify()` | Probar primero `st_simplify()`. Usar solo si deja huecos o solapamientos visibles |
   | `chromote` o `RSelenium` | Páginas que cargan los datos con JavaScript | 2 | Ninguna dentro del inventario | Último recurso. Antes, revisar si la página tiene un enlace de descarga o un servicio web |

   Ninguna de las clases disponibles (1 a 4, 6 a 9, 11 y 13) hace web scraping ni consulta APIs, así que cualquier paquete para eso es no visto, salvo que aparezca en las Clases 10 o 12.

   No hacen falta: `stringr` (sirven `gsub()`, `trimws()`, `toupper()`, `iconv()`), `janitor` (sirven `names()` y `tolower()`), `readxl` si todo es `.xlsx`.

3. **Marcado de paquetes no vistos.** Cada script lista, en la sección CONFIGURACIÓN INICIAL DEL AMBIENTE debajo de `#otros paquetes para este punto`, los paquetes no vistos que usa (o escribe "ninguno"). Toda línea que use uno de ellos termina con `# [NO VISTO EN CLASE]`. Además, esas funciones se llaman siempre con prefijo `paquete::funcion()`, para que la auditoría se pueda hacer buscando el nombre del paquete. Este mismo sistema se describe en la nota de entrega.

4. **Formato de texto.** `sprintf()` y `formatC()` están permitidas para formatear texto (rellenar códigos DIVIPOLA con ceros, imprimir tasas con dos decimales, armar mensajes). Cada uso lleva un comentario corto que diga qué formatea.

5. **Organización y archivos.**
   - Cada script empieza con el bloque fijo de la sección 4 (`# Taller 3, Punto X`, CONFIGURACIÓN INICIAL DEL AMBIENTE y DIRECTORIO DE TRABAJO). Después vienen bloques numerados (`BLOQUE 1`, `BLOQUE 2`, ...). Cada bloque hace una sola cosa y termina con su verificación.
   - Los paquetes no se instalan desde los scripts del taller: si hay errores de versiones se corre `00_reinstalar_paquetes.R` en una sesión nueva.
   - `setwd()` va en DIRECTORIO DE TRABAJO, con la ruta armada a partir de `Sys.getenv("USERNAME")` hasta la carpeta `Taller 3`. Excepciones: `app.R` no usa `setwd()` (Shiny ya trabaja desde la carpeta de la app) y el `.Rmd` vive en la carpeta `Taller 3` y usa rutas relativas, porque se compila en una sesión nueva desde su propia carpeta (Clase 9).
   - Los archivos de `Bases de Datos/` nunca se modifican, ni a mano ni desde R. Todo resultado se escribe en `Resultados/` o `app_shiny/datos/`.
   - Al corregir código se entregan solo los bloques que cambian, completos y con su número.
   - El estilo de escritura sigue la sección 6 (patrones de los Talleres 1 y 2), para que el grupo pueda auditar el código comparándolo con lo que ya escribió.

6. **Verificaciones.** Cada paso lleva su verificación inmediatamente después. Mínimo obligatorio:

   | Verificación | Dónde | Cómo |
   |---|---|---|
   | Filas antes y después de cada unión | 1, 2 | `nrow()` antes y después, con `if` y `cat("Alerta: ...")` como en el Taller 2 |
   | Llaves sin pareja | 1, 2 | `%in%` en ambos sentidos con la función `verificar_llaves()` (molde 5.1) |
   | Llaves duplicadas | 1 | `length(x) - length(unique(x))`, o `group_by(llave) %>% summarise(n = n()) %>% filter(n > 1)` |
   | Ponderadores suman 1 por departamento | 1A | `group_by(cod_dpto) %>% summarise(sum(w))` comparado con 1 usando una tolerancia |
   | Precios del VA y tasa de crecimiento | 1A | Registrar en comentario la base de precios del anexo; tasa con `round(tasa, 2)` antes de aplicarla |
   | Cálculo comprobado por otro procedimiento | 1A | IDF departamental con `dplyr` contra un loop `for` por departamento (molde 5.5) |
   | Serie correcta | 2A, 2B | Confirmar que es IBR overnight y SOFR overnight, con unidad y convención de tasa documentadas |
   | Rango de fechas | 2A, 2B | `min()` y `max()` de la fecha dentro de 01/01/2020 a 31/10/2025; número de observaciones |
   | Registro de extracción | 2 | Fuente, serie, método, URL y fecha de consulta en `Resultados/2_registro_extraccion.xlsx` |
   | Observación contrastada con la fuente oficial | 2A, 2B | Al menos una fecha por tasa, comparada con el valor publicado y anotada en el registro |
   | Fechas sin observación | 2C, 3B | Calendario completo con `seq(by = "day")` + `left_join()` (Clase 8) y `colSums(is.na())` por serie |
   | Tasa faltante en la app | 3B | `if` / `else` dentro de `renderText()` con mensaje al usuario (Clase 9) |
   | CRS | 1, 3A | `st_crs(a) == st_crs(b)` antes de cualquier unión espacial; `st_transform(x, 4326)` antes de leaflet (Clase 13) |

7. **Uso de IA según el enunciado.**
   - Se permite IA para el código y el desarrollo técnico. La conversación se enlaza o se adjunta en `anexos/`; sin eso se pierde una unidad de la nota total.
   - No se permite IA para redactar las interpretaciones. En el código y en el `.Rmd` la IA deja el marcador `[INTERPRETACIÓN: la escribe el grupo]` y no lo llena.
   - Quedan bajo esta regla, por ser texto de análisis: interpretación del mapa (1A), justificación de la tasa de crecimiento elegida (1A), explicación de los problemas computacionales del mapa municipal (1B), comparación de tendencias IBR y SOFR (2C) y el cuadro de texto de la gráfica libre (3C).
   - La IA sí puede documentar en comentarios de código lo que el código hace (por ejemplo, "se toma el promedio mensual de los días con dato").
   - La responsabilidad por la exactitud del taller es del grupo, aunque se use IA.

8. **Funciones no vistas.** Una función de un paquete del inventario que no se haya visto en clase se puede usar (regla 1), pero lleva un comentario corto en la misma línea o en la anterior con el formato `# Función no vista: qué hace`.

---

## 3. Inventario (verificado con el script de clases)

Fuente: `script_ejemplo.R`, que reúne los scripts de las Clases 1, 2, 3, 4, 6, 7, 8, 9, 11 y 13. Las funciones se extrajeron directamente del código de cada clase. Faltan las Clases 5, 10 y 12. Ninguna de las clases disponibles hace web scraping ni consulta una API. Si eso se vio en la 10 o la 12, hay que actualizar esta sección.

### 3.1 Paquetes por clase

| Paquete | Clase(s) | Qué se hizo en clase | ¿Lo usa el taller? |
|---|---|---|---|
| base R | 1 a 4 (y todas) | Tipos, vectores, factores, matrices, listas, indexación lógica, `if`/`for`/`while`, funciones con `stop()`/`warning()`, data frames, `apply()` | Sí, en todo |
| `docstring` | 3 | Documentación `#'` dentro de la función y `docstring()` para verla | Sí, funciones propias |
| `openxlsx` | 4, 6, 7 | `read.xlsx(archivo, sheet = 1)`, `write.xlsx(list(...), archivo)` | Sí, originales DNP/DANE y registro |
| `dplyr` | 6, 7, 8, 9, 11, 13 | `select`, `mutate`, `filter`, `arrange(desc())`, `group_by` + `summarise(.groups = "drop")`, `n()`, `n_groups()`, `left_join`, `distinct(.keep_all = TRUE)`, `case_when`, `starts_with`, `n_distinct` | Sí, en todo |
| `tidyr` | 6 | `pivot_longer(cols, names_to, values_to)`, `pivot_wider(names_from, values_from, names_prefix)` | Sí, anexos DANE en formato ancho |
| `readr` | 6 | `read_csv()` | Sí, API de SOFR en CSV |
| `ggplot2` | 7, 8, 9, 11, 13 | Geoms básicos, `facet_wrap`, escalas, `labs`, `theme`, `theme_bw/minimal/void`, `sec_axis`, `geom_tile`, `geom_sf`, `ggsave` | Sí, ejercicios 1 y 2 |
| `RColorBrewer` | 7 | `display.brewer.all()`; paletas usadas con `scale_*_brewer()` | Sí, mapas |
| `lubridate` | 7 (cargado), 8 | `year()`, `month()`, `day()`, `week()`, `wday(label = TRUE, week_start = 1)` | Sí, ejercicio 2 |
| `ggthemes` | 8 | `theme_stata()`, `theme_economist()`, `theme_excel_new()` | Opcional |
| `plotly` | 8, 9 | `ggplotly(p, tooltip = "text")`, `plot_ly(type = "scatter", mode = ..., hovertemplate)`, `layout()` | Sí, 3B y 3C |
| `gganimate`, `gifski` | 8 | `transition_reveal`, `transition_time`, `animate`, `anim_save` | No |
| `ggrepel` | 8, 13 | `geom_label_repel`, `geom_text_repel(stat = "sf_coordinates")` | Sí, etiquetas del mapa |
| `gapminder` | 8, 9 | Base de ejemplo | Opcional en 3C |
| `scales` | 8, 9 | `label_dollar()`, `label_number(big.mark)`, `comma()` | Sí, ejes |
| `htmlwidgets` | 8, 13 | `htmlwidgets::saveWidget(widget, file, selfcontained = TRUE)` | Sí |
| `rmarkdown` | 9 | `render(archivo, output_dir)` | Sí |
| `knitr` | 9 | Opciones de chunk (`echo`, `include`, `eval`, `message`, `warning`, `fig.height`) | Sí |
| `quarto` | 9 | `quarto::quarto_render()` | No |
| `DT` | 9 | `datatable(options, colnames, filter, caption)`, `formatStyle`, `formatCurrency`, `formatRound` | Sí, top 3 en 3A |
| `leaflet` | 9, 13 | `addProviderTiles(providers$Esri.WorldStreetMap)`, `setView`, `addCircleMarkers`, `addPolygons`, `colorBin`, `addLegend`, `highlightOptions`, `addLayersControl` | Sí, 3A |
| `crosstalk` | 9 | `SharedData$new()`, `bscols()` | Opcional en 3C |
| `shiny` | 9 | `fluidPage`, `sidebarLayout`, inputs, `render*`/`*Output`, `reactive()`, `tabsetPanel`, `shinyApp` | Sí, ejercicio 3 |
| `shinydashboard` | 9 | `dashboardPage`, `sidebarMenu`, `menuItem(icon)`, `tabItems`, `fluidRow`, `box(status, solidHeader, width)`, `valueBox` | Sí, ejercicio 3 |
| `modelsummary`, `lmtest`, `sandwich`, `fixest`, `AER` | 11 | Tablas y modelos econométricos | No |
| `estimatr` | 11 | Se carga pero no se usa | No cuenta como visto |
| `sf` | 13 | `st_read(carpeta)`, `st_crs`, `st_sfc`, `st_point`, `st_coordinates`, `st_transform`, `st_as_sf`, `st_join`, `st_drop_geometry`, `st_area` | Sí, ejercicio 1 y 3A |
| `BAMMtools` | 13 | `getJenksBreaks(x, 6)` | Sí, clases del mapa |

### 3.2 Funciones vistas por clase (las que sirven para el taller)

| Clase | Funciones y operadores |
|---|---|
| 1 | `print`, `typeof`, `class`, `as.numeric`, `seq`, `c`, `:`, `<-`, indexación `[ ]` |
| 2 | `factor(levels, ordered)`, `as.factor`, `levels`, `matrix`, `array`, `list`, `str`, `which`, `is.na`, `is.numeric`, `as.character`, `as.integer`, `round`, `sum`, `mean(na.rm = TRUE)`, `paste`, `paste0`, `%%`, `&`, `\|`, `!`, `%*%`, `t`, `solve`, `set.seed`, `runif`, `rnorm`, `sample`, `ls`, `rm`, `nrow`, `ncol`, `dim` |
| 3 | `if`/`else if`/`else`, `ifelse`, `for`, `while`, `function`, `return`, `stop`, `warning`, `any`, `length`, `substr`, `cat`, `docstring` |
| 4 | `data.frame`, `str`, `names`, `head`, `tail`, `View`, `order(decreasing)`, `colnames`, `rownames`, `complete.cases`, `colSums(is.na())`, `colMeans`, `data()`, `getwd`, `Sys.getenv("USERNAME")`, `setwd`, `read.table`, `read.csv`, `read.xlsx`, `apply(MARGIN, FUN)`, `lapply`, `max`, `min` |
| 6 | `read_csv`, `unique`, `table`, `prop.table`, `select`, `mutate`, `ifelse`, `case_when`, `filter`, `group_by`, `n_groups`, `summarise`, `n`, `arrange`, `desc`, `%>%`, `pivot_longer`, `pivot_wider`, `starts_with`, `left_join`, `write.csv(row.names = FALSE)`, `write.xlsx(list(...))` |
| 7 | `file.path`, `distinct(.keep_all = TRUE)`, `%in%`, `ggplot`, `aes`, `geom_point/line/bar/boxplot/jitter/violin/histogram/density/count/smooth/text/label/vline/hline`, `scale_y_log10`, `scale_x_continuous(limits, breaks)`, `scale_y_continuous(name, breaks, labels)`, `scale_color_brewer`, `scale_color_distiller`, `scale_color_gradient`, `facet_grid`, `facet_wrap`, `labs`, `theme(element_text)`, `theme_bw`, `theme_minimal`, `theme_void`, `coord_polar`, `position_stack` |
| 8 | `cat("\014")`, `dir.create(showWarnings = FALSE)`, `as.Date(x, format = "%d/%m/%Y")`, `range`, `seq(by = "day")`, `expand.grid`, `left_join` para completar fechas, reemplazo de `NA` por indexación, `year`, `month`, `day`, `week`, `wday`, `format(fecha, "%d/%m/%Y")`, `which.max`, `sort`, `ggplotly`, `geom_tile`, `scale_fill_gradient`, `scale_color_manual`, `scale_color_viridis_d`, `facet_wrap(scales = "free_y")`, `geom_label_repel`, `sec_axis` con transformación min-max, `label_dollar`, `label_number`, `ggsave(units = "in"/"px", dpi)`, `htmlwidgets::saveWidget`, `list.files` |
| 9 | `writeLines`, `render(output_dir)`, `browseURL`, `plot_ly`, `layout`, `datatable`, `leaflet`, `addProviderTiles`, `setView`, `addCircleMarkers(popup, label)`, `SharedData$new`, `bscols`, `fluidPage`, `titlePanel`, `sidebarLayout`, `sidebarPanel`, `mainPanel`, `h2/h3/h4`, `p`, `br`, `hr`, `textInput`, `numericInput`, `selectInput`, `sliderInput`, `checkboxGroupInput`, `checkboxInput`, `textOutput/renderText`, `tableOutput/renderTable`, `plotOutput/renderPlot`, `verbatimTextOutput/renderPrint`, `plotlyOutput/renderPlotly`, `DTOutput/renderDT`, `reactive`, `tabsetPanel`, `tabPanel`, `dashboardPage/Header/Sidebar/Body`, `sidebarMenu`, `menuItem`, `tabItems`, `tabItem`, `fluidRow`, `box`, `valueBox/valueBoxOutput/renderValueBox`, `icon`, `shinyApp(ui = ui, server = server)` |
| 11 | `save(..., file = ".RData")`, `file.path`, `all`, `dir.create`, `annotate` (lo demás es econometría) |
| 13 | `st_read`, `st_crs`, `st_sfc`, `st_point`, `st_coordinates`, `st_transform`, `st_as_sf(coords, crs)`, `st_join`, `st_drop_geometry`, `st_area`, `geom_sf`, `scale_fill_brewer`, `scale_fill_viridis_c`, `getJenksBreaks`, `cut(breaks, include.lowest = TRUE, dig.lab = 3)`, `geom_text_repel(stat = "sf_coordinates", min.segment.length = 0)`, `geom_col`, `colorBin`, `addPolygons(label, popup, highlightOptions, group)`, `addLegend(position)`, `addLayersControl`, `file.exists`, `intersect`, `ggsave(bg = "white")` |

Solo se mencionan en comentarios, sin usarse: `dateInput()`, `fileInput()`, `radioButtons()`, `actionButton()` y `observeEvent()` (Clase 9, sección "OTROS INPUTS ÚTILES"). Cuentan como funciones no vistas (regla 8).

### 3.3 Funciones que el taller necesitaría y no aparecen en clase

Primero se busca la alternativa vista. Si no existe, la función se usa con el comentario `# Función no vista: ...` (regla 8). Si es de un paquete fuera del inventario, se aplica la regla 3.

| Función | Paquete | Para qué | Alternativa vista en clase | Decisión |
|---|---|---|---|---|
| `anti_join()` | dplyr | Llaves sin pareja | `x[!(x %in% y)]` con `%in%` (Clase 7) | Usar la alternativa |
| `count()` | dplyr | Duplicados | `group_by() %>% summarise(n = n())` (Clase 6) | Usar la alternativa |
| `duplicated()` | base | Duplicados | `length(x) - length(unique(x))` (Clases 3 y 6) | Usar la alternativa |
| `rename()` | dplyr | Renombrar columnas | `mutate(nuevo = viejo)` + `select()`, o `colnames()` (Clases 4 y 6) | Usar la alternativa |
| `slice_max()` | dplyr | Top 3 municipios | `arrange(desc(x)) %>% head(3)` (Clases 9 y 13) | Usar la alternativa |
| `weighted.mean()` | base | Segundo cálculo del IDF | `sum(x * w) / sum(w)` y un loop `for` (Clase 3) | Usar la alternativa |
| `ymd()`, `mdy()` | lubridate | Texto a fecha | `as.Date(x, format = "...")` (Clase 8) | Usar la alternativa |
| `floor_date()` | lubridate | Agregar por mes | `year()` + `month()` y `group_by()` (Clase 8) | Usar la alternativa |
| `tidyr::fill()` | tidyr | Rellenar fechas sin dato | Dejar `NA` y reportarlo (Clase 8 completa fechas con `left_join`) | No usar |
| `validate(need())` | shiny | Avisar si falta una tasa | `if` / `else` dentro del `render*()` (Clase 9, Ejemplo 4) | Usar la alternativa |
| `leafletOutput()`, `renderLeaflet()` | leaflet | Mapa dentro de Shiny | Ninguna | Usar con comentario |
| `dateInput()` | shiny | Digitar la fecha en 3B | Solo mencionada en la Clase 9 | Usar con comentario |
| `updateSelectInput()`, `input$<id>_shape_click` | shiny/leaflet | Seleccionar departamento con clic | `selectInput()` basta para el enunciado | Opcional, con comentario |
| `add_trace()`, `layout(yaxis2 = ...)` | plotly | Doble eje interactivo | Ninguna (`ggplotly()` pierde el eje secundario) | Usar con comentario |
| `saveRDS()`, `readRDS()` | base | Pasar objetos `sf` a la app y al Rmd | `save()` (Clase 11), pero `load()` no se vio | Usar con comentario |
| `st_simplify()`, `st_make_valid()`, `st_is_valid()` | sf | Mapa municipal (1B) | Ninguna | Usar con comentario |
| `knitr::kable()` | knitr | Tablas en el documento | `datatable()` (Clase 9); `kable` sí se usó en el Taller 2 | Usar con comentario |
| `formatC()`, `sprintf()` | base | Ceros a la izquierda en DIVIPOLA | Ninguna simple | Regla 4 |
| `nchar()`, `toupper()`, `iconv()` | base | Revisar llaves y nombres | Ninguna simple | Usar con comentario |
| `download.file()`, `readLines()`, `regmatches()`, `Sys.time()` | base | Extracción y registro | Ninguna | Usar con comentario |
| `object.size()`, `system.time()` | base | Diagnóstico del mapa municipal | Ninguna | Usar con comentario |

---

## 4. Plantilla de estructura del código

Todo script de un punto empieza con este bloque fijo, sin cambios salvo el número del punto, los objetivos (como en los encabezados del profesor), los paquetes y la lista de no vistos. Después siguen los bloques numerados.

```r
# Taller 3, Punto X
cat("\014")
rm(list = ls())
# ==============================================================================
# Objetivos:
# - Calcular el IDF departamental artificial (ponderador población × VA)
# - Construir el mapa departamental con clases de Jenks
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
library(docstring)     # documentación de funciones propias

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
str(idf_raw)
names(idf_raw)
head(idf_raw)


# =============================================================================
# BLOQUE 2. LIMPIEZA Y LLAVES
# =============================================================================

# ... cada subtema con su verificación justo después ...


# =============================================================================
# BLOQUE N. EXPORTAR RESULTADOS
# =============================================================================

saveRDS(objeto, file.path(ruta_resultados, "objeto.rds"))   # Función no vista: guarda el objeto (también sf)
saveRDS(objeto, "app_shiny/datos/objeto.rds")               # Función no vista

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
| Avisos | `# CUIDADO: ...`, explicando el error que uno cometería (estilo del profesor) | `# CUIDADO: el shapefile debe ir a la izquierda del join` |
| Paquete no visto | `paquete::funcion()` y `# [NO VISTO EN CLASE]` al final de la línea | `rvest::read_html(url) # [NO VISTO EN CLASE]` |
| Función no vista (base R o paquete visto) | `# Función no vista: qué hace`; revisar antes la tabla 3.3 | `# Función no vista: st_simplify reduce vértices` |
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

Cada molde dice de qué clase sale y usa solo funciones vistas, salvo las marcadas. Los nombres de archivos, hojas y columnas son de ejemplo: se ajustan después de inspeccionar cada original con `str()`, `names()` y `head()`.

### 5.1 Función para revisar llaves antes de un pegue (Clases 3, 6 y 7)

```r
# ---------- Función de verificación de llaves ----------
verificar_llaves <- function(x, y, llave) {
  #' Verificar llaves antes de un pegue
  #'
  #' Cuenta llaves duplicadas en cada base y llaves sin pareja en ambos sentidos.
  #'
  #' @param x Data frame de la izquierda (la base que se conserva).
  #' @param y Data frame de la derecha.
  #' @param llave Nombre de la columna llave, entre comillas.
  #' @return Lista con los duplicados y las llaves sin pareja.
  #' @examples
  #' verificar_llaves(idf_mun, pob_mun, "cod_mpio")

  if (!(llave %in% names(x)) | !(llave %in% names(y))) {
    stop("La llave no está en las dos bases.")
  }

  dup_x  <- length(x[[llave]]) - length(unique(x[[llave]]))
  dup_y  <- length(y[[llave]]) - length(unique(y[[llave]]))
  solo_x <- unique(x[[llave]][!(x[[llave]] %in% y[[llave]])])
  solo_y <- unique(y[[llave]][!(y[[llave]] %in% x[[llave]])])

  cat("Duplicados en x:", dup_x, "| Duplicados en y:", dup_y, "\n")
  cat("Llaves de x sin pareja en y:", length(solo_x),
      "| Llaves de y sin pareja en x:", length(solo_y), "\n")

  return(list(dup_x = dup_x, dup_y = dup_y, solo_x = solo_x, solo_y = solo_y))
}

docstring(verificar_llaves)
```

### 5.2 Lectura de originales en Excel sin modificarlos (Clase 4)

```r
# ---------- Población municipal 2024 (DANE) ----------
# CUIDADO: los anexos del DANE traen filas de títulos arriba de la tabla.
# Se saltan con startRow; el archivo original no se toca.
pob_raw <- read.xlsx(file.path(ruta_bases, "PPED-AreaMun-2018-2042_VP.xlsx"),
                     sheet = 1, startRow = 9)

# Verificación
str(pob_raw)
names(pob_raw)
tail(pob_raw)          # revisar notas al pie que hay que quitar
```

### 5.3 Llaves DIVIPOLA (Clase 6 + regla 4)

```r
# ---------- Llaves DIVIPOLA ----------
pob_mun <- pob_raw %>%
  filter(AÑO == 2024) %>%
  mutate(cod_mpio  = formatC(as.integer(COD_MPIO), width = 5, flag = "0"),  # formatC: código municipal a 5 dígitos
         cod_dpto  = substr(cod_mpio, 1, 2),
         poblacion = as.numeric(Total)) %>%
  select(cod_dpto, cod_mpio, poblacion)

# Verificación
table(nchar(pob_mun$cod_mpio))           # Función no vista: nchar cuenta caracteres; todos deben ser 5
length(unique(pob_mun$cod_dpto))         # 33 incluyendo Bogotá

duplicados <- pob_mun %>%
  group_by(cod_mpio) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1)
nrow(duplicados)                         # debe salir 0

# CUIDADO: si la base trae varias filas por municipio (total, cabecera,
# centro poblado), hay que quedarse con el total antes de unir.
```

### 5.4 Pegue con verificación (Clase 6 + estilo Taller 2)

```r
# ---------- Pegue IDF + población ----------
chequeo_pob <- verificar_llaves(idf_mun, pob_mun, "cod_mpio")
chequeo_pob$solo_x       # municipios con IDF sin población: revisar uno por uno

filas_base <- nrow(idf_mun)
base_mun <- idf_mun %>%
  left_join(pob_mun %>% select(cod_mpio, poblacion), by = "cod_mpio")

# Verificación Programática 2: el pegue no aumenta las filas de la base
if (nrow(base_mun) != filas_base) {
  cat("Alerta: el pegue multiplicó filas (", filas_base, "->", nrow(base_mun), ")\n")
} else {
  cat("Verificación exitosa: el pegue conserva", nrow(base_mun), "filas\n")
}
sum(is.na(base_mun$poblacion))
```

Evidencia para la entrega: guardar los conteos de `chequeo_pob` en `Resultados/1_A_verificacion_uniones.xlsx` con `write.xlsx()`.

### 5.5 Proyección del VA, ponderadores e IDF departamental (Clases 3 y 6)

```r
# ---------- Proyección del VA 2023 a 2024 ----------
# Precios del VA: corrientes (anexo DANE anex-PIBDep-ValorAgreMuni-2011-2024p)
# Tasa elegida por el grupo: crecimiento del PIB nominal 2024 de Colombia,
# anexo DANE "PIB total por departamentos", fila COLOMBIA, precios corrientes.
tasa_pib_2024 <- round(7.95, 2)        # constante en R; el anexo no se carga
# [INTERPRETACIÓN: la justificación de la tasa la escribe el grupo]

base_mun <- base_mun %>%
  mutate(va_2024 = va_2023 * (1 + tasa_pib_2024 / 100))

# ---------- Ponderadores ----------
base_mun <- base_mun %>%
  filter(!is.na(idf), !is.na(poblacion), !is.na(va_2024)) %>%
  group_by(cod_dpto) %>%
  mutate(w = (poblacion * va_2024) / sum(poblacion * va_2024)) %>%
  ungroup()                            # Función no vista: quita la agrupación

# Verificación Programática 3: los ponderadores suman 1 por departamento
suma_w <- base_mun %>%
  group_by(cod_dpto) %>%
  summarise(suma = sum(w), .groups = "drop")

if (all(abs(suma_w$suma - 1) < 1e-6)) {
  cat("Verificación exitosa: los ponderadores suman 1 en los", nrow(suma_w), "departamentos\n")
} else {
  warning("Hay departamentos cuyos ponderadores no suman 1")
}

# ---------- IDF departamental (procedimiento 1: dplyr) ----------
idf_dpto <- base_mun %>%
  group_by(cod_dpto) %>%
  summarise(idf_dpto = sum(idf * w),
            n_mpios  = n(),
            .groups  = "drop")

# ---------- IDF departamental (procedimiento 2: loop, Clase 3) ----------
idf_loop <- c()
for (d in idf_dpto$cod_dpto) {
  sub <- base_mun[base_mun$cod_dpto == d, ]
  idf_loop[d] <- sum(sub$idf * sub$poblacion * sub$va_2024) / sum(sub$poblacion * sub$va_2024)
}
idf_dpto$idf_loop <- idf_loop[idf_dpto$cod_dpto]

# Verificación Programática 4: cálculo comprobado por otro procedimiento
if (all(abs(idf_dpto$idf_dpto - idf_dpto$idf_loop) < 1e-6)) {
  cat("Verificación exitosa: el loop reproduce el IDF departamental\n")
} else {
  cat("Alerta: los dos procedimientos no coinciden\n")
}
summary(idf_dpto$idf_dpto)
```

`ungroup()` se puede evitar calculando los ponderadores en un `summarise()` aparte y pegándolos con `left_join()`. Queda a decisión del grupo.

### 5.6 Shapefile y mapa coroplético con Jenks (Clase 13)

```r
# ---------- Shapefile departamental ----------
# CUIDADO: el shapefile son varios archivos (.shp, .dbf, .shx, .prj); a
# st_read() se le pasa la CARPETA que los contiene (Clase 13).
shp_dpto <- st_read(file.path(ruta_bases, "MGN2025_DPTO_POLITICO"))
class(shp_dpto)
names(shp_dpto)
st_crs(shp_dpto)$input

# CUIDADO: el sf va a la IZQUIERDA del left_join para conservar la geometría.
filas_shp <- nrow(shp_dpto)
mapa_dpto <- shp_dpto %>%
  mutate(cod_dpto = as.character(DPTO_CCDGO)) %>%
  left_join(idf_dpto, by = "cod_dpto")

# Verificación Programática 5: el pegue con el shapefile
if (nrow(mapa_dpto) != filas_shp) cat("Alerta: el pegue con el shapefile cambió el número de filas\n")
sum(is.na(mapa_dpto$idf_dpto))         # departamentos sin IDF

# ---------- Función de mapa (adaptada de mapa_jenks, Clase 13) ----------
mapa_jenks <- function(datos, variable, titulo_leyenda, paleta) {
  #' Mapa coroplético con cortes naturales de Jenks
  #'
  #' @param datos Objeto sf con la variable a mapear.
  #' @param variable Nombre de la columna, entre comillas.
  #' @param titulo_leyenda Título de la leyenda.
  #' @param paleta Paleta de ColorBrewer (por ejemplo "YlGnBu").
  #' @return Un ggplot con el mapa.
  #' @examples
  #' mapa_jenks(mapa_dpto, "idf_dpto", "IDF departamental", "YlGnBu")

  if (any(is.na(datos[[variable]]))) {
    warning("La variable tiene NA: esos polígonos quedan sin clase.")
  }

  cortes <- getJenksBreaks(datos[[variable]], 6)     # 6 cortes = 5 clases
  datos$clase <- cut(datos[[variable]], breaks = cortes,
                     include.lowest = TRUE, dig.lab = 3)

  ggplot(datos) +
    geom_sf(aes(fill = clase), color = "white", linewidth = 0.1) +
    scale_fill_brewer(palette = paleta, name = titulo_leyenda) +
    theme_void() +
    theme(legend.position = "bottom",
          plot.title = element_text(face = "bold"))
}

g_mapa_idf <- mapa_jenks(mapa_dpto, "idf_dpto", "IDF departamental", "YlGnBu") +
  geom_text_repel(aes(label = nombre_dpto, geometry = geometry),
                  stat = "sf_coordinates", size = 2.5,
                  min.segment.length = 0) +
  labs(title    = "Índice de Desempeño Fiscal artificial por departamento, 2024",
       subtitle = "Media ponderada del IDF municipal (ponderador: población × VA). Clases de Jenks",
       caption  = "Fuente: DNP, DANE. Cálculos propios.")
g_mapa_idf

# bg = "white" evita el fondo transparente de theme_void() (Clase 13)
ggsave(filename = file.path(ruta_resultados, "1_A_mapa_idf_dpto.png"),
       plot = g_mapa_idf, width = 8, height = 9, units = "in", dpi = 300, bg = "white")
```

Si hay que resumir una base `sf` con `group_by()` + `summarise()`, antes se quita la geometría con `st_drop_geometry()`; si no, el cálculo se vuelve lentísimo (Clase 13).

### 5.7 Mapa municipal: diagnóstico y simplificación (Clase 13 + funciones no vistas)

```r
# ---------- Diagnóstico ----------
shp_mpio <- st_read(file.path(ruta_bases, "MGN2025_MPIO_GRAFICO"))
nrow(shp_mpio)
print(object.size(shp_mpio), units = "Mb")         # Función no vista: tamaño en memoria
sum(!st_is_valid(shp_mpio))                         # Función no vista: geometrías inválidas

system.time(print(ggplot(shp_mpio) + geom_sf()))    # Función no vista: tiempo de dibujo

# ---------- Corrección y simplificación ----------
shp_mpio_simple <- shp_mpio %>%
  st_make_valid() %>%                                # Función no vista: corrige geometrías inválidas
  st_transform(3116) %>%                             # proyección en metros (dTolerance en metros)
  st_simplify(preserveTopology = TRUE, dTolerance = 500)   # Función no vista: reduce vértices

# Verificación
print(object.size(shp_mpio_simple), units = "Mb")
system.time(print(ggplot(shp_mpio_simple) + geom_sf()))
```

Los tiempos y tamaños son insumo; la explicación de los problemas la escribe el grupo. EPSG 3116 (MAGNA-SIRGAS Bogotá) está por confirmar. Si el shapefile del DANE ya viene en metros, se usa su propio CRS.

### 5.8 SOFR por API en formato CSV (Clase 6)

```r
# ---------- Extracción SOFR: API de Markets Data (Fed de Nueva York) ----------
# CUIDADO: confirmar la ruta exacta y los parámetros en la documentación de la API.
url_sofr <- paste0("https://markets.newyorkfed.org/api/rates/secured/sofr/search.csv",
                   "?startDate=2020-01-01&endDate=2025-10-31")
fecha_consulta_sofr <- Sys.time()                    # Función no vista: fecha y hora de la consulta
sofr_raw <- read_csv(url_sofr)

# Verificación
str(sofr_raw)
head(sofr_raw)
```

Con esto la API se consume con `read_csv()`, que sí se vio. Si solo hubiera JSON, el candidato es `jsonlite` (regla 2).

### 5.9 IBR por web scraping (paquete no visto)

```r
# ---------- Extracción IBR: web scraping (Banco de la República) ----------
url_ibr <- "URL_DE_LA_PAGINA_DEL_IBR"   # anotar la página oficial usada
fecha_consulta_ibr <- Sys.time()        # Función no vista: fecha y hora de la consulta

pagina_ibr <- rvest::read_html(url_ibr)                                             # [NO VISTO EN CLASE]
enlaces <- pagina_ibr %>% rvest::html_elements("a") %>% rvest::html_attr("href")   # [NO VISTO EN CLASE]
enlaces[grepl("ibr", enlaces, ignore.case = TRUE)]   # Función no vista: grepl busca texto

# Si la página trae la tabla en HTML:
tablas <- pagina_ibr %>% rvest::html_table()                                        # [NO VISTO EN CLASE]

# Si trae un enlace de descarga a Excel:
download.file(url_archivo_ibr, file.path(ruta_resultados, "2_A_ibr_descarga.xlsx"),
              mode = "wb")                           # Función no vista: descarga el archivo
ibr_raw <- read.xlsx(file.path(ruta_resultados, "2_A_ibr_descarga.xlsx"))

# Verificación
str(ibr_raw)
```

Alternativa sin paquetes nuevos para páginas HTML simples:

```r
html <- readLines(url_ibr, warn = FALSE, encoding = "UTF-8")          # Función no vista: lee la página como texto
enlaces <- regmatches(html, regexpr('href="[^"]+"', html))            # Función no vista: extrae los enlaces
```

CUIDADO: la descarga va a `Resultados/` porque es un producto de la extracción, no un original del enunciado.

### 5.10 Registro de extracción (Clases 4, 6 y 8)

```r
# ---------- Registro de extracción ----------
registro <- data.frame(
  fuente               = c("Banco de la República", "Federal Reserve Bank of New York"),
  serie                = c("IBR overnight", "SOFR overnight"),
  metodo               = c("Web scraping", "API"),
  url                  = c(url_ibr, url_sofr),
  fecha_consulta       = format(c(fecha_consulta_ibr, fecha_consulta_sofr), "%d/%m/%Y %H:%M"),
  unidad               = c("[completar]", "[completar]"),
  convencion           = c("[completar]", "[completar]"),
  n_obs                = c(nrow(ibr), nrow(sofr)),
  fecha_min            = format(c(min(ibr$fecha), min(sofr$fecha)), "%d/%m/%Y"),
  fecha_max            = format(c(max(ibr$fecha), max(sofr$fecha)), "%d/%m/%Y"),
  fecha_contraste      = c("[fecha]", "[fecha]"),
  valor_extraido       = c(NA, NA),
  valor_fuente_oficial = c(NA, NA),
  correccion           = c("[describir o 'ninguna']", "[describir o 'ninguna']")
)

write.xlsx(registro, file.path(ruta_resultados, "2_registro_extraccion.xlsx"))

# Verificación
registro
```

### 5.11 Fechas, calendario completo y agregación (Clase 8)

```r
# ---------- Texto a fecha (Clase 8) ----------
sofr <- sofr_raw %>%
  mutate(fecha    = as.Date(`Effective Date`, format = "%m/%d/%Y"),
         sofr_pct = as.numeric(`Rate (%)`)) %>%
  filter(fecha >= as.Date("2020-01-01"), fecha <= as.Date("2025-10-31")) %>%
  select(fecha, sofr_pct) %>%
  arrange(fecha)

# Verificación
range(sofr$fecha)
nrow(sofr)
length(sofr$fecha) - length(unique(sofr$fecha))   # debe salir 0: sin fechas repetidas

# ---------- Calendario completo (mismo método de la Clase 8) ----------
# Paso 1: secuencia con TODOS los días del periodo
fechas <- data.frame(fecha = seq(as.Date("2020-01-01"), as.Date("2025-10-31"), by = "day"))

# Paso 2: pegar cada serie al calendario
tasas <- fechas %>%
  left_join(ibr,  by = "fecha") %>%
  left_join(sofr, by = "fecha")

# Paso 3: verificar
nrow(fechas) == nrow(tasas)            # el pegue no debe duplicar filas
colSums(is.na(tasas))                  # días sin dato por serie

# CUIDADO: en la Clase 8 los días sin denuncias se volvieron 0. Con tasas NO:
# un festivo o un fin de semana no tiene tasa 0, simplemente no tiene dato.
# Se deja NA y se explica en el documento cómo se trató.

# ---------- Agregación mensual (frecuencia elegida por el grupo) ----------
tasas_mes <- tasas %>%
  mutate(anio = year(fecha), mes = month(fecha)) %>%
  group_by(anio, mes) %>%
  summarise(dias_ibr  = sum(!is.na(ibr_pct)),       # los conteos van ANTES de los promedios
            dias_sofr = sum(!is.na(sofr_pct)),
            ibr_pct   = mean(ibr_pct,  na.rm = TRUE),
            sofr_pct  = mean(sofr_pct, na.rm = TRUE),
            .groups   = "drop") %>%
  mutate(fecha_mes = as.Date(paste0(anio, "-", mes, "-01")))

# Verificación
nrow(tasas_mes)                        # 70 meses entre ene-2020 y oct-2025
summary(tasas_mes$dias_ibr)
```

CUIDADO: dentro de `summarise()`, una columna que se sobrescribe (como `ibr_pct`) cambia para las líneas siguientes. Por eso los conteos de días van antes de los promedios.

### 5.12 Doble eje estático con transformación min-max (Clase 8)

```r
# ---------- Doble eje: SOFR izquierda, IBR derecha ----------
# Transformación MIN-MAX de la Clase 8: el mínimo de la IBR se ubica en el
# mínimo de la SOFR y el máximo en el máximo.
min_sofr  <- min(tasas_mes$sofr_pct, na.rm = TRUE)
min_ibr   <- min(tasas_mes$ibr_pct,  na.rm = TRUE)
pendiente <- (max(tasas_mes$sofr_pct, na.rm = TRUE) - min_sofr) /
             (max(tasas_mes$ibr_pct,  na.rm = TRUE) - min_ibr)

tasas_mes <- tasas_mes %>%
  mutate(ibr_escalada = min_sofr + (ibr_pct - min_ibr) * pendiente)

g_doble_eje <- ggplot(tasas_mes, aes(x = fecha_mes)) +
  geom_line(aes(y = sofr_pct,     color = "SOFR ON"), linewidth = 1) +
  geom_line(aes(y = ibr_escalada, color = "IBR ON"),  linewidth = 1) +
  scale_y_continuous(name = "SOFR ON (% anual)",
                     sec.axis = sec_axis(~ min_ibr + (. - min_sofr) / pendiente,
                                         name = "IBR ON (% anual)")) +
  scale_color_manual(values = c("SOFR ON" = "#1F5F99", "IBR ON" = "#C0392B")) +
  labs(title    = "IBR overnight y SOFR overnight",
       subtitle = "Promedio mensual, enero de 2020 a octubre de 2025",
       x = "Mes", color = NULL,
       caption  = "Fuente: Banco de la República; Federal Reserve Bank of New York. Cálculos propios.") +
  theme_bw() +
  theme(legend.position    = "bottom",
        axis.title.y.left  = element_text(color = "#1F5F99"),
        axis.title.y.right = element_text(color = "#C0392B"),
        plot.title         = element_text(face = "bold"))
g_doble_eje

ggsave(filename = file.path(ruta_resultados, "2_C_doble_eje.png"),
       plot = g_doble_eje, width = 10, height = 6, units = "in", dpi = 300)

# CUIDADO (Clase 8): con min-max las dos líneas empiezan y terminan en el
# mismo punto por construcción. Los cruces y la distancia entre líneas no
# significan nada; lo que se puede leer es la FORMA de cada serie.
```

### 5.13 Doble eje interactivo en plotly (Clase 9 + funciones no vistas)

```r
# ---------- Doble eje interactivo ----------
# CUIDADO: ggplotly() no conserva el eje secundario de sec_axis(); por eso
# se arma con plot_ly() nativo (Clase 9).
p_doble_eje <- plot_ly(tasas, x = ~fecha, y = ~sofr_pct,
                       type = "scatter", mode = "lines", name = "SOFR ON (% anual)",
                       hovertemplate = paste("<b>Fecha:</b> %{x}<br>",
                                             "<b>SOFR:</b> %{y:.2f} %<br>",
                                             "<extra></extra>")) %>%
  add_trace(y = ~ibr_pct, name = "IBR ON (% anual)", yaxis = "y2",
            hovertemplate = paste("<b>Fecha:</b> %{x}<br>",
                                  "<b>IBR:</b> %{y:.2f} %<br>",
                                  "<extra></extra>")) %>%     # Función no vista: agrega la segunda serie
  layout(title  = "IBR overnight y SOFR overnight, 2020-2025",
         xaxis  = list(title = "Fecha"),
         yaxis  = list(title = "SOFR ON (% anual)"),
         yaxis2 = list(title = "IBR ON (% anual)",
                       overlaying = "y", side = "right"))     # Función no vista: segundo eje y

p_doble_eje

htmlwidgets::saveWidget(widget = p_doble_eje,
                        file = file.path(ruta_resultados, "3_B_doble_eje_interactivo.html"),
                        selfcontained = TRUE)
```

### 5.14 Mapa departamental en leaflet (Clases 9 y 13)

```r
# ---------- Paso 1: llevar todo a longitud/latitud ----------
# CUIDADO: leaflet SOLO entiende WGS84 (4326) (Clase 13).
mapa_dpto_wgs <- st_transform(mapa_dpto, 4326)

# ---------- Paso 2: paleta con los mismos cortes de Jenks ----------
cortes <- getJenksBreaks(mapa_dpto_wgs$idf_dpto, 6)
paleta <- colorBin("YlGnBu", domain = mapa_dpto_wgs$idf_dpto, bins = cortes)

# ---------- Paso 3: el mapa por capas ----------
# CUIDADO: addProviderTiles(providers$Esri...) y no addTiles(): OpenStreetMap
# y CartoDB fallan cuando el HTML se abre como archivo local (Clases 9 y 13).
m_idf <- leaflet() %>%
  addProviderTiles(providers$Esri.WorldStreetMap) %>%
  addPolygons(data = mapa_dpto_wgs,
              layerId = ~cod_dpto,
              fillColor = ~paleta(idf_dpto), fillOpacity = 0.7,
              color = "white", weight = 1,
              label = ~nombre_dpto,
              popup = ~paste0("<b>", nombre_dpto, "</b><br>",
                              "IDF departamental: ", round(idf_dpto, 1), "<br>",
                              "Municipios: ", n_mpios),
              highlightOptions = highlightOptions(weight = 3, color = "black",
                                                  bringToFront = TRUE),
              group = "Departamentos") %>%
  addLegend(pal = paleta, values = mapa_dpto_wgs$idf_dpto,
            title = "IDF departamental", position = "bottomright")

m_idf
```

`layerId` es un argumento no visto de `addPolygons()`; solo hace falta si se usa el clic sobre el mapa en Shiny.

### 5.15 Aplicativo Shiny con tres pestañas (Clase 9)

```r
# ==============================================================================
# CONFIGURACIÓN INICIAL DEL AMBIENTE
# ==============================================================================
# CUIDADO: app.R no usa setwd(); Shiny trabaja desde la carpeta app_shiny/.
library(shiny)
library(shinydashboard)
library(dplyr)
library(plotly)
library(DT)
library(leaflet)
library(sf)

mapa_dpto <- readRDS("datos/mapa_dpto.rds")   # Función no vista: lee objetos guardados con saveRDS
base_mun  <- readRDS("datos/base_mun.rds")    # Función no vista
tasas     <- readRDS("datos/tasas.rds")       # Función no vista

# ==============================================================================
# INTERFAZ (ui)
# ==============================================================================
ui <- dashboardPage(
  dashboardHeader(title = "Taller 3"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Datos geoespaciales", tabName = "geo",   icon = icon("map")),
      menuItem("Series financieras",  tabName = "tasas", icon = icon("chart-line")),
      menuItem("Diseño libre",        tabName = "libre", icon = icon("palette"))
    )
  ),

  dashboardBody(
    tabItems(
      # ---------- Pestaña 1: IDF ----------
      tabItem(tabName = "geo",
              fluidRow(
                box(title = "IDF departamental (índice ponderado)", status = "primary",
                    solidHeader = TRUE, width = 8,
                    leafletOutput("mapa", height = "600px")),   # Función no vista: mapa leaflet en Shiny
                box(title = "Top 3 municipios por IDF municipal", status = "info",
                    solidHeader = TRUE, width = 4,
                    selectInput("dpto", "Departamento:",
                                choices = sort(unique(base_mun$nombre_dpto))),
                    DTOutput("top3"))
              )),

      # ---------- Pestaña 2: tasas ----------
      tabItem(tabName = "tasas",
              fluidRow(
                box(title = "Instrucciones", status = "warning", solidHeader = TRUE, width = 12,
                    p("[Instrucciones de uso: las escribe el grupo]"))
              ),
              fluidRow(
                box(title = "IBR ON y SOFR ON", status = "primary", solidHeader = TRUE, width = 8,
                    plotlyOutput("doble_eje", height = "500px")),
                box(title = "Consulta por fecha", status = "info", solidHeader = TRUE, width = 4,
                    dateInput("fecha", "Fecha:", value = "2025-10-31",
                              min = "2020-01-01", max = "2025-10-31"),   # Función no vista: mencionada en Clase 9
                    verbatimTextOutput("devaluacion"))
              )),

      # ---------- Pestaña 3: diseño libre ----------
      tabItem(tabName = "libre",
              fluidRow(
                box(title = "Controles", status = "info", solidHeader = TRUE, width = 4,
                    sliderInput("anio", "Año:", min = 2020, max = 2025, value = 2025, sep = ""),
                    p("[Texto explicativo: lo escribe el grupo]")),
                box(title = "Gráfica", status = "primary", solidHeader = TRUE, width = 8,
                    plotlyOutput("grafica_libre"))
              ))
    )
  )
)

# ==============================================================================
# SERVIDOR (server)
# ==============================================================================
server <- function(input, output) {

  # ---------- Pestaña 1 ----------
  output$mapa <- renderLeaflet({          # Función no vista: dibuja el mapa leaflet en Shiny
    m_idf                                 # el mapa del molde 5.14
  })

  # REACTIVE: el filtro se calcula una vez (Clase 9)
  mpios_dpto <- reactive({
    base_mun %>%
      filter(nombre_dpto == input$dpto)
  })

  output$top3 <- renderDT({
    datatable(mpios_dpto() %>%
                arrange(desc(idf)) %>%
                head(3) %>%
                select(nombre_mpio, idf),
              colnames = c("Municipio", "IDF municipal"),
              options = list(dom = "t"))
  })

  # ---------- Pestaña 2 ----------
  output$doble_eje <- renderPlotly({
    p_doble_eje                           # el gráfico del molde 5.13
  })

  output$devaluacion <- renderText({
    fila <- tasas %>% filter(fecha == input$fecha)

    if (nrow(fila) == 0) {
      "La fecha está fuera del periodo 01/01/2020 a 31/10/2025."
    } else if (is.na(fila$ibr_dec) | is.na(fila$sofr_dec)) {
      paste0("No hay tasa para esa fecha.",
             ifelse(is.na(fila$ibr_dec),  " Falta la IBR ON.",  ""),
             ifelse(is.na(fila$sofr_dec), " Falta la SOFR ON.", ""))
    } else {
      pi_dev <- (1 + fila$ibr_dec) / (1 + fila$sofr_dec) - 1
      paste0("IBR ON: ",  round(fila$ibr_dec, 5), "\n",
             "SOFR ON: ", round(fila$sofr_dec, 5), "\n",
             "Devaluación implícita: ", round(pi_dev, 5),
             " (", round(pi_dev * 100, 3), " % [unidad según la convención elegida])")
    }
  })

  # ---------- Pestaña 3 ----------
  output$grafica_libre <- renderPlotly({
    # gráfica del grupo con ggplotly(p, tooltip = "text") o plot_ly()
  })
}

shinyApp(ui = ui, server = server)
```

`ibr_dec` y `sofr_dec` se calculan en `02_tasas_api_scraping.R` con la misma convención (regla 6). Los objetos `m_idf` y `p_doble_eje` se guardan con `saveRDS()` desde los scripts o se reconstruyen en `app.R`; lo segundo es más fácil de auditar.

### 5.16 Documento RMarkdown (Clase 9 + estructura del Taller 2)

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
# CUIDADO (Clase 9): el documento corre en una sesión NUEVA. Todo lo que
# necesite (paquetes, datos) se carga aquí. El .Rmd vive en la carpeta
# Taller 3, así que las rutas son relativas a ella.
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
ruta_resultados <- "Resultados"
```

# Punto 1

## 1.A IDF departamental artificial

```{r p1_a}
# ==============================================================================
# 1.A IDF DEPARTAMENTAL ARTIFICIAL
# ==============================================================================
idf_dpto   <- readRDS(file.path(ruta_resultados, "1_A_idf_dpto.rds"))      # Función no vista
g_mapa_idf <- readRDS(file.path(ruta_resultados, "1_A_g_mapa_idf.rds"))    # Función no vista
```

```{r tabla_1_a, echo=FALSE}
knitr::kable(idf_dpto,
             caption = "Tabla 1.A. IDF departamental artificial, 2024",
             format.args = list(big.mark = ".", decimal.mark = ","))   # Función no vista (usada en el Taller 2)
```

```{r fig_1_a, echo=FALSE, fig.height=9}
g_mapa_idf
```

El IDF se calculó para `r nrow(idf_dpto)` departamentos.

### Análisis 1.A

*[INTERPRETACIÓN: la escribe el grupo]*
````

Se compila con el botón Knit o con `render("Taller3_documento.Rmd")` (Clase 9). El código en línea `` `r ...` `` (Clase 9) sirve para que las cifras del texto salgan de los datos; las frases de interpretación las escribe el grupo.

---

## 6. Estilo de programación (Talleres 1 y 2 y scripts de clase)

El código nuevo debe parecerse al de las entregas `Entrega_Final_Taller_1.R` y `Taller_2_markdown.Rmd` (6.1 y 6.2) y al de los scripts de clase (6.3), para que el grupo lo reconozca y lo audite sin esfuerzo. Cuando algo de esta sección choque con las convenciones genéricas de la sección 4, gana esta sección, salvo el bloque de inicio fijo y las marcas de no visto.

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

### 6.3 Cómo estructura y programa el profesor (script de clases)

El grupo ya copia buena parte de esto. Lo que sigue se toma de los scripts de clase y se mantiene en el taller.

| Elemento | Cómo lo hace el profesor | Ejemplo | Clase |
|---|---|---|---|
| Encabezado | Bloque `# ====` con `CLASE N: TÍTULO`, fuentes o base de datos, profesor y `Objetivos:` con viñetas `# - ...` | `# CLASE 13: DATOS GEOESPACIALES` | 4 a 13 |
| Inicio | `cat("\014")` y `rm(list = ls())` | | 7, 8 |
| Paquetes | Un `library()` por línea con comentario alineado; aviso de no instalar desde el script y usar `00_reinstalar_paquetes.R` | `library(BAMMtools)   # getJenksBreaks(): ...` | 8, 13 |
| Instalación | Se abandonó `install_if_missing()` de la Clase 7; desde la Clase 8 no se instala nada en el script | | 7 → 8 |
| Ruta | `username <- Sys.getenv("USERNAME")`, `ruta_datos <- paste0("C:/Users/", username, ...)`, `setwd()`, aviso `# CUIDADO: esta ruta es la de la carpeta de Santiago...` | | 4 a 13 |
| Carpeta de salida | `dir.create("output", showWarnings = FALSE)` y al final `cat("Archivos guardados en:", ...)` o `list.files("output")` | | 8, 9, 11, 13 |
| Secciones | `# ====` + TÍTULO EN MAYÚSCULAS; subtemas `# ---------- Subtema ----------` | `# UNIÓN ESPACIAL: CONTAR ACCIDENTES POR UPZ` | todas |
| Pasos | Comentarios `# Paso 1: ...`, `# Paso 2: ...` dentro de una tarea larga | Completar fechas y mapa leaflet | 8, 13 |
| Avisos | `# CUIDADO:` explicando el error que uno cometería: "uno podría pensar que... No es así" | `# CUIDADO: leaflet SOLO entiende WGS84 (4326)` | 8, 9, 13 |
| Chequeos en línea | Comparación directa con el resultado esperado en comentario | `nrow(df_full) == nrow(df_complete)   # el join no debe duplicar filas`; `st_crs(a) == st_crs(b)   # debe salir TRUE` | 8, 13 |
| Chequeos de actividad | `# CHEQUEO: debe salir ...` con el valor esperado | `# CHEQUEO: debe salir 490` | 11, 13 |
| Pipes | Un verbo por línea, sangría de dos espacios | | 6 en adelante |
| Comentarios de argumentos | Al final de la línea, explicando qué hace cada argumento | `include.lowest = TRUE` "es indispensable: sin él la UPZ con el valor mínimo queda en NA" | 7, 13 |
| Funciones para repetir | Si un gráfico se repite, se vuelve función (Clase 3) | `mapa_jenks(datos, variable, titulo_leyenda, paleta)` | 13 |
| Gráficas | `labs(title, subtitle, x, y, caption = "Fuente: ...")`; `theme_minimal()`/`theme_bw()`/`theme_void()` en mapas; `theme(legend.position = "bottom", plot.title = element_text(face = "bold"))` | | 7, 8, 13 |
| Exportar | `ggsave(filename, plot, width, height, units = "in", dpi = 300)`, con `bg = "white"` en mapas con `theme_void()`; `htmlwidgets::saveWidget(widget, file, selfcontained = TRUE)` | | 8, 13 |
| Mapas | `st_read()` sobre la carpeta; revisar `st_crs()` antes de unir; `st_drop_geometry()` antes de resumir; el `sf` a la izquierda del `left_join` | | 13 |
| Leaflet | `addProviderTiles(providers$Esri.WorldStreetMap)`, nunca `addTiles()`; `group` y `addLayersControl()` para capas | | 9, 13 |
| Shiny | `reactive()` para el filtro que usan varios outputs; `if (nrow(datos) > 0) { ... } else { "No hay datos..." }` para casos vacíos; `inherit.aes = FALSE` en `geom_smooth()` con tooltips | | 9 |
| Tooltips | Columna `text` armada con `paste0()` y `<br>`, luego `ggplotly(p, tooltip = "text")` | | 8, 9 |
| DT | `datatable(options = list(pageLength, language = list(search = "Buscar:", ...)), colnames, filter = "top")` | | 9 |

Cuando el estilo del grupo (6.1) y el del profesor difieren, se usa el del grupo para las verificaciones ("Verificación Programática N") y el del profesor para todo lo demás.
