# Taller 3 · Taller de Programación en R (2026-2)


Datos geoespaciales, web scraping y herramientas de visualización.

---

## 1. Contenido del taller

| Ejercicio | Tema | Puntos |
|:--|:--|:--|
| 1 | Datos geoespaciales: IDF artificial departamental (A) y mapa municipal (B) | 1,5 |
| 2 | Web scraping y API: IBR ON (Banco de la República) y SOFR ON (Fed de Nueva York) | 2,0 |
| 3 | Aplicativo Shiny con tres pestañas: geoespacial, series financieras y diseño libre | 1,5 |

### Entregables

1. Script en R, archivo RMarkdown y el documento generado.
2. Aplicativo Shiny con tres pestañas.
3. Base de datos del literal 3C, si aplica.
4. Enlace o anexo de la conversación con IA (omitirlo resta una unidad).

### Archivos propuestos

| Archivo | Contenido |
|:--|:--|
| `01_Ejercicio_1_geoespacial.R` | IDF artificial departamental y mapa municipal |
| `02_Ejercicio_2_tasas.R` | Extracción y gráficos de IBR y SOFR |
| `app_taller3/app.R` | Aplicativo Shiny (ejercicio 3) |
| `Taller_3.Rmd` | Documento con resultados e interpretaciones |
| `output/` | Gráficos, tablas y bases intermedias generadas |

---

## 2. Reglas de desarrollo

El objetivo es que todo el código se pueda auditar con lo visto en clase.

1. **Herramientas permitidas.** Cualquier función que venga por defecto en R (`base`, `stats`, `utils`, `graphics`, `grDevices`) o que pertenezca a un paquete visto en clase (sección 3), aunque la función específica no se haya visto (por ejemplo `bind_rows()` o `anti_join()`).

2. **Paquetes nuevos solo si no hay alternativa.** Se confirman uno por uno al llegar a cada punto. Candidatos:
   - `sf`: lectura de shapefiles (ejercicio 1).
   - `rvest`: web scraping (ejercicio 2).
   - `jsonlite`: solo si la API no devuelve CSV (ejercicio 2).

3. **Marcado de paquetes no vistos.**
   - Lista al inicio del script con cada paquete no visto y para qué se usa.
   - Comentario `# [NO VISTO EN CLASE]` en cada línea que lo use.
   - En la entrega se explica este sistema de marcado.

4. **Formateo de texto con base R.** `sprintf()` y `formatC()` están permitidas, por ejemplo para rellenar códigos DIVIPOLA con ceros (`05001`). Llevan un comentario corto de qué hacen.

5. **Estructura del código.** Se sigue la plantilla de la sección 4, igual al estilo de los scripts de clase. Nunca se modifican los archivos originales. Al corregir, se entregan solo los bloques que cambian.

6. **Verificaciones obligatorias.**
   - En cada unión: `nrow()` antes y después, y número de códigos sin pareja.
   - Ponderadores: `sum(w) == 1` por departamento.
   - Al menos un cálculo comprobado por dos caminos distintos.
   - Una observación de cada tasa contrastada con la fuente oficial.

7. **Lo que no se hace con IA.** Las interpretaciones de los resultados y los textos explicativos del Shiny los escribe el grupo.

8. **Funciones no vistas en clase.** Aunque estén permitidas por la regla 1, llevan un comentario corto que explique qué hacen.

---

## 3. Inventario de lo visto en clase

Nota: no se tienen los scripts de las Clases 5 y 10. Si se consiguen, se agregan aquí.

### Paquetes vistos

| Paquete | Clase | Uso principal |
|:--|:--|:--|
| `docstring` | 3 | Documentación de funciones |
| `openxlsx` | 4, 6, 7 | Leer y escribir Excel |
| `dplyr` | 6 | Manipulación de datos |
| `tidyr` | 6 | Formato ancho y largo |
| `readr` | 6 | Lectura de CSV (`read_csv`) |
| `ggplot2` | 7, 8 | Gráficos |
| `lubridate` | 7, 8 | Fechas |
| `RColorBrewer` | 7 | Paletas (`display.brewer.all`) |
| `ggthemes` | 8 | Temas prediseñados |
| `plotly` | 8, 9 | Gráficos interactivos |
| `gganimate`, `gifski` | 8 | Animaciones y exportación a GIF |
| `ggrepel` | 8 | Etiquetas sin superposición |
| `gapminder` | 8, 9 | Datos de ejemplo |
| `scales` | 8 | Formato de ejes |
| `htmlwidgets` | 8 | Guardar gráficos interactivos en HTML |
| `rmarkdown`, `quarto` | 9 | Documentos reproducibles |
| `DT` | 9 | Tablas interactivas |
| `leaflet` | 9 | Mapas interactivos |
| `crosstalk` | 9 | Widgets conectados |
| `shiny`, `shinydashboard` | 9 | Aplicativos web |
| `modelsummary` | 11 | Tablas descriptivas y de regresión |
| `lmtest`, `sandwich` | 11 | Pruebas y errores robustos |
| `fixest` | 11 | Efectos fijos, cluster y VI |
| `AER` | 11 | Variables instrumentales (`ivreg`) |

### Clase 1: introducción

- Tipos básicos: `typeof()`, `class()`, `print()`, `NA`.
- Vectores: `c()`, `1:10`, `seq(by = )`, asignación con `<-`.
- Indexación: `x[1]`, `x[2:4]`, `x[c(1, 3)]`.
- Aritmética vectorizada y conversión con `as.numeric()`.

### Clase 2: estructuras de datos

- Enteros (`1L`), factores (`factor(levels = , ordered = )`, `as.factor()`, `levels()`).
- Secuencias: `seq(length.out = )`.
- Matrices: `matrix(byrow = , dimnames = )`, `dim()`, `nrow()`, `ncol()`, `array()`.
- Listas: `list()`, `str()`, `[ ]`, `[[ ]]`, `$`, eliminar con `NULL`.
- Indexación negativa y lógica, `which()`, `sum()` y `mean()` sobre lógicos.
- Familias `is.*()` y `as.*()`, `round()`, `as.integer()`.
- Operadores: `%%`, `==`, `!=`, `&`, `|`, `!`, reciclaje, `na.rm = TRUE`.
- Texto: `paste()`, `paste0()`.
- Álgebra: `%*%`, `t()`, `solve()`, `crossprod()`, `tcrossprod()`.
- Simulación: `set.seed()`, `runif()`, `rnorm()`, `rbinom()`, `rpois()`, `sample()`.
- Ambiente: `ls()`, `rm()`.

### Clase 3: flujos de control y funciones

- Condicionales: `if`, `else if`, `else`, `ifelse()`.
- Bucles: `for`, `while`.
- Funciones: `function()`, `return()`, documentación con `#'` y `docstring()`.
- Manejo de errores: `stop()`, `warning()`, `any()`.
- Texto: `substr()`, `cat()`.

### Clase 4: data frames

- `data.frame()`, `str()`, `names()`, `head()`, `tail()`, `View()`.
- Ordenar: `order()` (incluye varias columnas, `-`, `decreasing = c()`, `method = "radix"`).
- Seleccionar columnas por posición o nombre: `df[, c(...)]`.
- Faltantes: `is.na()`, `colSums()`, `colMeans()`, `complete.cases()`.
- Nombres: `colnames()`, `rownames()`.
- Rutas: `getwd()`, `setwd()`, `Sys.getenv()`.
- Lectura: `read.table()`, `read.csv(sep = )`, `read.xlsx()`.
- Familia apply: `apply(MARGIN = )`, `lapply()`, funciones propias dentro de `apply`.
- `quantile()`, `max()`, `min()`, `data()`.

### Clase 6: dplyr y tidyr

- `table()`, `prop.table()`, `unique()`, `length()`.
- Verbos: `select()`, `mutate()`, `filter()`, `arrange()`, `desc()`.
- Recodificar: `case_when()`.
- Agrupar: `group_by()`, `summarise()`, `n()`, `n_groups()`, `.groups = "drop"`.
- Pipe `%>%`, `starts_with()`.
- Formatos: `pivot_longer()`, `pivot_wider(names_prefix = )`.
- Uniones: `left_join(by = )`.
- Lectura y exportación: `read_csv()`, `write.csv(row.names = FALSE)`, `write.xlsx()` con varias hojas.

### Clase 7: ggplot2

- Carga de paquetes con `install_if_missing()` y `lapply(paquetes, library, character.only = TRUE)`.
- `file.path()`, `distinct(.keep_all = TRUE)`, `%in%`.
- Estructura: `ggplot(datos, aes())` + capas.
- Geometrías: `geom_point()`, `geom_line()`, `geom_vline()`, `geom_hline()`, `geom_histogram()`, `geom_density()`, `geom_bar()`, `geom_boxplot()`, `geom_jitter()`, `geom_violin()`, `geom_count()`, `geom_smooth(method = "lm")`, `geom_text()`, `geom_label()`.
- Estética: `color`, `fill`, `size`, `shape`, `linetype`.
- Escalas: `scale_y_log10()`, `scale_x_continuous()`, `scale_y_continuous()`, `scale_color_brewer()`, `scale_color_distiller()`, `scale_color_gradient()`, `scale_color_discrete()`.
- Facetas: `facet_grid()`, `facet_wrap()`.
- Temas y textos: `theme_bw()`, `theme_minimal()`, `theme_void()`, `labs()`, `theme(element_text(), legend.position = )`.
- Torta: `geom_bar(stat = "identity")` + `coord_polar()` + `position_stack()`.

### Clase 8: visualización avanzada

- Fechas: `as.Date(format = )`, `year()`, `month()`, `day()`, `week()`, `wday()`, `seq(by = "day")`.
- Completar fechas faltantes: `expand.grid()` + `left_join()` + reemplazo de `NA` por 0.
- `dir.create()`, `which.max()`, `range()`.
- Temas: `theme_stata()`, `theme_excel_new()`, `theme_economist()`.
- Interactivos: `ggplotly(tooltip = "text")`.
- Heatmap: `geom_tile()`, `scale_fill_gradient()`, `scale_y_discrete(limits = rev)`.
- Animaciones: `transition_reveal()`, `transition_time()`, `view_follow()`, `animate()`, `anim_save()`.
- Anotaciones: `geom_label_repel()`, `annotate()`, `facet_wrap(scales = "free_y")`.
- Escalas: `scale_color_viridis_d()`, `scale_size()`, `scale_color_manual()`, `label_dollar()`, `label_number()`.
- **Doble eje:** transformación min-max + `sec_axis()` (base para el ejercicio 2C).
- Guardado: `ggsave()`, `htmlwidgets::saveWidget()`.

### Clase 9: RMarkdown, Quarto, htmlwidgets y Shiny

- RMarkdown: YAML, chunks (`echo`, `include`, `eval`, `message`, `warning`, `fig.height`), código en línea, `render()`, `writeLines()`, `browseURL()`.
- Quarto: `#|` en chunks, `embed-resources: true`, `quarto_render()`, `file.copy()`, `file.remove()`.
- plotly nativo: `plot_ly()`, `layout()`, `hovertemplate`.
- DT: `datatable()`, `formatStyle()`, `styleColorBar()`, `formatCurrency()`, `formatRound()`.
- leaflet: `addProviderTiles(providers$Esri.WorldStreetMap)`, `setView()`, `addMarkers()`, `addCircleMarkers()`, `popup`, `label`.
- crosstalk: `SharedData$new()`, `bscols()`.
- Shiny (UI): `fluidPage()`, `titlePanel()`, `sidebarLayout()`, `sidebarPanel()`, `mainPanel()`, `tabsetPanel()`, `tabPanel()`, `h2()`, `h3()`, `p()`, `br()`, `hr()`, `tags$ul()`.
- Shiny (inputs): `textInput()`, `numericInput()`, `selectInput()`, `sliderInput()`, `checkboxGroupInput()`, `checkboxInput()`. Mencionados: `dateInput()`, `fileInput()`, `radioButtons()`, `actionButton()` con `observeEvent()`.
- Shiny (outputs): `textOutput()`/`renderText()`, `tableOutput()`/`renderTable()`, `plotOutput()`/`renderPlot()`, `verbatimTextOutput()`/`renderPrint()`, `plotlyOutput()`/`renderPlotly()`, `DTOutput()`/`renderDT()`.
- Reactividad: `reactive()`.
- shinydashboard: `dashboardPage()`, `dashboardHeader()`, `dashboardSidebar()`, `sidebarMenu()`, `menuItem()`, `dashboardBody()`, `tabItems()`, `tabItem()`, `fluidRow()`, `box()`, `valueBox()`, `icon()`.

### Clase 11: econometría

- Descriptivas: `datasummary_skim()`, `datasummary_balance()`, `datasummary()`, `datasummary_correlation()`, `datasummary_crosstab()`.
- Regresión: `lm()`, `summary()`, `factor()`, `coef()`, `resid()`.
- Supuestos: `bptest()`, `shapiro.test()`, `plot(modelo, which = )`.
- Errores: `coeftest()`, `vcovHC()`, `vcov = c("classical", "HC1", "bootstrap")`.
- Tablas y gráficos: `modelsummary()`, `modelplot()`, exportación a HTML y LaTeX.
- `feols()` con efectos fijos, `vcov = "hetero"`, `cluster = ~`.
- Interacciones (`*`) y VI con `ivreg()` y `feols()`.
- `save()`, `read.csv(na.strings = )`.

---

## 4. Plantilla de estructura del código

Todos los scripts siguen el formato de los scripts de clase:

```r
# =============================================================================
# TALLER 3 - EJERCICIO X: TÍTULO
# =============================================================================
# Integrantes: ...
# Objetivos:
# - ...
# - ...
#
# PAQUETES NO VISTOS EN CLASE
# - sf: lectura de shapefiles  -> líneas marcadas con # [NO VISTO EN CLASE]
#
# FUENTES
# - Fuente, serie, método de extracción y fecha de consulta
# =============================================================================


# =============================================================================
# BLOQUE 1: CONFIGURACIÓN INICIAL DEL AMBIENTE
# =============================================================================

library(dplyr)
library(ggplot2)


# =============================================================================
# BLOQUE 2: DIRECTORIO DE TRABAJO Y CARGA DE DATOS
# =============================================================================

username <- Sys.getenv("USERNAME")

# CUIDADO: cada integrante ajusta la ruta a su computador
ruta_datos <- paste0("C:/Users/", username, "/...")
setwd(ruta_datos)

dir.create("output", showWarnings = FALSE)


# =============================================================================
# BLOQUE 3: TEMA DEL BLOQUE
# =============================================================================

# ---------- Subtema ----------
# Comentario que explica qué se hace y por qué
objeto <- datos %>%
  filter(...) %>%
  mutate(...)

# Verificación inmediata del paso anterior
nrow(objeto)

# CUIDADO: advertencia sobre un error común o una decisión importante
```

### Convenciones

| Elemento | Convención |
|:--|:--|
| Títulos de bloque | `# ===` + `# BLOQUE N: TÍTULO EN MAYÚSCULAS` + `# ===` |
| Subtemas | `# ---------- Subtema ----------` |
| Advertencias | `# CUIDADO: ...` (mismo estilo del profesor) |
| Nombres de objetos | `snake_case` en español: `idf_municipal`, `pob_2024` |
| Comentarios | En español, explican el porqué, no solo el qué |
| Pipes | `%>%`, un verbo por línea |
| Verificaciones | Justo después del paso que verifican |
| Funciones no vistas | Comentario al lado: `# formatC(): rellena con ceros` |
| Paquetes no vistos | `# [NO VISTO EN CLASE]` en cada línea que los use |
| Exportaciones | Siempre a la carpeta `output/` |

---

## 5. Patrones de código por tipo de tarea

Copiados de la forma en que se escribió en clase. Cuando haya que programar algo de este tipo, se parte de estos moldes y solo se cambian nombres de bases y variables.

### 5.1 Edición de bases de datos (Clase 6, EDA con dplyr)

En clase se vieron dos estilos: una función por línea (`df <- mutate(df, ...)`) y con pipe. **En el taller se usa el pipe**, que es el estilo del final de la Clase 6 y de las Clases 7 a 11.

```r
# ---------- Carga y vistazo rápido ----------
datos <- read.xlsx("archivo.xlsx", sheet = 1)       # o read_csv("archivo.csv")
str(datos)
cat("Dimensiones de la base de datos:", dim(datos), "\n")

# ---------- Cobertura y tabla de frecuencias ----------
unique(datos$DEPARTAMENTO)
length(unique(datos$COD_MPIO))

tabla_dptos <- table(datos$DEPARTAMENTO)
freq_dptos <- data.frame(
  DEPARTAMENTO = names(tabla_dptos),
  FRECUENCIA   = as.numeric(tabla_dptos),
  PORCENTAJE   = round(as.numeric(prop.table(tabla_dptos)) * 100, 2)
)
head(arrange(freq_dptos, desc(FRECUENCIA)), 10)

# ---------- Valores faltantes ----------
colSums(is.na(datos))
datos <- datos %>% filter(!is.na(COD_MPIO))

# ---------- Seleccionar, crear y recodificar variables ----------
datos_limpios <- datos %>%
  select(COD_DPTO, COD_MPIO, MUNICIPIO, IDF) %>%
  mutate(COD_MPIO = formatC(COD_MPIO, width = 5, flag = "0"),   # formatC(): rellena con ceros
         RANGO    = case_when(
           IDF >= 80 ~ "Rango alto",
           IDF >= 60 ~ "Rango medio",
           TRUE      ~ "Rango bajo"))

# ---------- Filtrar y reportar ----------
datos_filtro <- datos_limpios %>% filter(IDF > 70)
cat("Municipios con IDF mayor a 70:", nrow(datos_filtro), "\n")

# ---------- Agrupar y resumir ----------
resumen_dpto <- datos_limpios %>%
  group_by(COD_DPTO) %>%
  summarise(
    TOTAL_MPIOS   = n(),
    PROMEDIO_IDF  = round(mean(IDF, na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  arrange(desc(PROMEDIO_IDF))

head(resumen_dpto, 10)

# ---------- Unir bases (con verificación) ----------
# Tabla de nombres única por código (patrón de la Clase 7)
pegue <- datos %>%
  arrange(COD_DPTO) %>%
  distinct(COD_DPTO, .keep_all = TRUE) %>%
  select(COD_DPTO, DEPARTAMENTO)

nrow(resumen_dpto)                                   # antes
resumen_dpto <- left_join(resumen_dpto, pegue, by = "COD_DPTO")
nrow(resumen_dpto)                                   # después: debe ser igual
sum(!(resumen_dpto$COD_DPTO %in% pegue$COD_DPTO))    # códigos sin pareja

# ---------- Ancho a largo y largo a ancho ----------
datos_long <- datos %>%
  pivot_longer(cols = starts_with("VAR_"), names_to = "VARIABLE", values_to = "VALOR")

datos_wide <- datos_long %>%
  pivot_wider(names_from = VARIABLE, values_from = VALOR)

# ---------- Exportar ----------
write.csv(resumen_dpto, "output/resumen_dpto.csv", row.names = FALSE)
write.xlsx(list("Resumen" = resumen_dpto, "Detalle" = datos_limpios),
           "output/resultados.xlsx")
```

### 5.2 Gráficas estáticas (Clases 7 y 8)

Patrón de la Clase 8: primero un gráfico básico con `labs()` completo, luego se le suma el tema personalizado. Todo gráfico del taller debe llevar **título, período, unidades, leyenda y fuente**.

```r
# ---------- Gráfico base ----------
p_basico <- ggplot(datos, aes(x = FECHA, y = VALOR, color = SERIE)) +
  geom_line() +
  labs(title    = "Título del gráfico",
       subtitle = "Período (enero 2020 - octubre 2025)",
       x        = "Fecha",
       y        = "Unidad (% efectivo anual)",
       color    = "Serie",
       caption  = "Fuente: ...")

# ---------- Tema personalizado ----------
p_custom <- p_basico +
  theme_minimal() +
  theme(plot.title       = element_text(size = 14, face = "bold"),
        plot.subtitle    = element_text(size = 12, color = "gray50"),
        legend.position  = "bottom",
        panel.grid.minor = element_blank())

p_custom

# ---------- Guardar ----------
ggsave(filename = "output/nombre_grafico.png", plot = p_custom,
       width = 10, height = 6, units = "in", dpi = 300)
```

**Series de tiempo con fechas faltantes** (Clase 8):

```r
# Paso 1: texto a fecha
datos$FECHA <- as.Date(datos$FECHA, format = "%d/%m/%Y")

# Paso 2: secuencia con TODOS los días del período
fechas <- seq(as.Date("2020-01-01"), as.Date("2025-10-31"), by = "day")

# Paso 3: pegar los datos observados
df_full     <- data.frame(FECHA = fechas)
df_complete <- left_join(df_full, datos, by = "FECHA")

nrow(df_full) == nrow(df_complete)   # el join no debe duplicar filas
sum(is.na(df_complete$VALOR))        # días sin observación
# CUIDADO: en tasas, un día sin dato NO es cero. Se deja NA y se explica.
```

**Gráfico de doble eje** (Clase 8, transformación min-max):

```r
# Eje izquierdo = var_izq ; eje derecho = var_der (se reescala)
min_izq   <- min(datos$var_izq, na.rm = TRUE)
min_der   <- min(datos$var_der, na.rm = TRUE)
pendiente <- (max(datos$var_izq, na.rm = TRUE) - min_izq) /
             (max(datos$var_der, na.rm = TRUE) - min_der)

datos <- datos %>%
  mutate(var_der_escalada = min_izq + (var_der - min_der) * pendiente)

p_doble_eje <- ggplot(datos, aes(x = FECHA)) +
  geom_line(aes(y = var_izq,          color = "Serie izquierda"), linewidth = 1) +
  geom_line(aes(y = var_der_escalada, color = "Serie derecha"),   linewidth = 1) +
  scale_y_continuous(name     = "Serie izquierda (unidad)",
                     sec.axis = sec_axis(~ min_der + (. - min_izq) / pendiente,
                                         name = "Serie derecha (unidad)")) +
  scale_color_manual(values = c("Serie izquierda" = "darkblue",
                                "Serie derecha"   = "forestgreen")) +
  labs(title = "...", subtitle = "...", x = "Fecha", color = NULL, caption = "Fuente: ...") +
  theme_minimal() +
  theme(legend.position    = "bottom",
        axis.title.y.left  = element_text(color = "darkblue"),
        axis.title.y.right = element_text(color = "forestgreen"),
        plot.title         = element_text(face = "bold"))
```

**Mapa estático** (`geom_sf()` es de ggplot2; el objeto lo crea `sf`):

```r
mapa_dpto <- st_read("ruta/shapefile.shp")            # [NO VISTO EN CLASE]

mapa_dpto <- left_join(mapa_dpto, resumen_dpto, by = "COD_DPTO")

p_mapa <- ggplot(mapa_dpto) +
  geom_sf(aes(fill = IDF_DPTO), color = "white", linewidth = 0.2) +
  scale_fill_distiller(palette = "RdYlGn", direction = 1, name = "IDF") +
  labs(title    = "Título del mapa",
       subtitle = "Vigencia 2024",
       caption  = "Fuente: DNP, DANE. Cálculos propios.") +
  theme_void() +
  theme(plot.title = element_text(size = 14, face = "bold"))
```

### 5.3 Gráficas interactivas (Clases 8 y 9)

**ggplot a plotly con tooltip personalizado** (Clase 8):

```r
# Columna de texto para el tooltip (<b> = negrilla, <br> = salto de línea)
datos <- datos %>%
  mutate(text = paste0("<b>", SERIE, "</b>",
                       "<br>Fecha: ", format(FECHA, "%d/%m/%Y"),
                       "<br>Valor: ", round(VALOR, 2), " %"))

p_interactivo <- ggplot(datos, aes(x = FECHA, y = VALOR, color = SERIE, text = text)) +
  geom_line(aes(group = SERIE)) +       # "text" rompe la agrupación: hay que forzarla
  labs(title = "...", x = "Fecha", y = "...", color = "Serie") +
  theme_minimal()

p_plotly <- ggplotly(p_interactivo, tooltip = "text")
p_plotly

htmlwidgets::saveWidget(widget = p_plotly, file = "output/grafico.html",
                        selfcontained = TRUE)
```

**plotly nativo** (Clase 9):

```r
plot_ly(datos, x = ~FECHA, y = ~VALOR,
        type = "scatter", mode = "lines",
        hovertemplate = paste("<b>Fecha:</b> %{x}<br>",
                              "<b>Valor:</b> %{y:.2f} %<br>",
                              "<extra></extra>")) %>%
  layout(title = "...",
         xaxis = list(title = "Fecha"),
         yaxis = list(title = "..."))
```

**Mapa interactivo con leaflet** (Clase 9). `addPolygons()` y `colorNumeric()` son de leaflet pero no se vieron en clase, así que llevan comentario:

```r
paleta <- colorNumeric(palette = "RdYlGn", domain = mapa_dpto$IDF_DPTO)  # colorNumeric(): asigna color según el valor

leaflet(mapa_dpto) %>%
  addProviderTiles(providers$Esri.WorldStreetMap) %>%   # Esri: funciona al abrir el HTML local
  addPolygons(fillColor   = ~paleta(IDF_DPTO),           # addPolygons(): dibuja los polígonos del shapefile
              fillOpacity = 0.7, color = "white", weight = 1,
              label = ~DEPARTAMENTO,
              popup = ~paste0("<b>", DEPARTAMENTO, "</b><br>",
                              "IDF departamental: ", round(IDF_DPTO, 1))) %>%
  addLegend(pal = paleta, values = ~IDF_DPTO, title = "IDF")   # addLegend(): leyenda de colores
```

### 5.4 Aplicativo Shiny (Clase 9, Ejemplos 3 y 4)

Estructura base: `ui` con barra lateral y pestañas, `server` con un `reactive()` que filtra una sola vez, y un mensaje cuando no hay datos.

```r
# =============================================================================
# PASO 1: INTERFAZ (ui)
# =============================================================================
ui <- fluidPage(
  titlePanel("Taller 3"),

  sidebarLayout(
    sidebarPanel(
      h3("Controles"),
      selectInput("dpto", "Departamento:", choices = sort(unique(datos$DEPARTAMENTO))),
      hr(),
      h4("Instrucciones"),
      p("Texto escrito por el grupo.")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Pestaña 1", plotlyOutput("grafico", height = "600px")),
        tabPanel("Pestaña 2", DTOutput("tabla")),
        tabPanel("Pestaña 3", verbatimTextOutput("resumen"))
      )
    )
  )
)

# =============================================================================
# PASO 2: LÓGICA (server)
# =============================================================================
server <- function(input, output) {

  # REACTIVE: el filtro se calcula UNA vez y lo usan todos los outputs
  datos_filtrados <- reactive({
    datos %>% filter(DEPARTAMENTO == input$dpto)
  })

  output$grafico <- renderPlotly({
    p <- ggplot(datos_filtrados(), aes(x = ..., y = ..., text = ...)) +
      geom_point() +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  output$tabla <- renderDT({
    datatable(datos_filtrados(), options = list(pageLength = 10, scrollX = TRUE))
  })

  output$resumen <- renderText({
    datos <- datos_filtrados()
    if (nrow(datos) > 0) {
      paste0("Municipios: ", nrow(datos))
    } else {
      "No hay datos para los filtros seleccionados"
    }
  })
}

# =============================================================================
# PASO 3: EJECUTAR
# =============================================================================
shinyApp(ui = ui, server = server)

# CUIDADO: mientras la app corre, la consola queda ocupada. Se cierra con STOP o Esc.
# CUIDADO: datos_filtrados() va con paréntesis; sin ellos R devuelve la "receta".
```
