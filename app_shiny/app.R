# Taller 3, Punto 3: aplicativo Shiny (pestañas A, B y C)
# ==============================================================================
# Objetivos:
# - Pestaña A: mapa interactivo del IDF departamental y top 3 de municipios
# - Pestaña B: doble eje interactivo IBR-SOFR y devaluación implícita por fecha
# - Pestaña C: gráfica libre (IDF municipal frente a población o VA)
# Cómo abrirla: con este archivo abierto en RStudio, botón "Run App"; o con la
# línea de runApp() al final de Taller3.R.
# Insumos: carpeta app_shiny/datos/ (los generan los puntos 1 y 2 de Taller3.R).
# ==============================================================================

# ==============================================================================
# CONFIGURACIÓN INICIAL DEL AMBIENTE
# ==============================================================================

# CUIDADO: se cargan en el mismo orden de Taller3.R. Si dos paquetes tienen una
# función con el mismo nombre, gana el último cargado (DT va después de shiny).
library(sf)             # el mapa de la pestaña A es un objeto sf
library(dplyr)          # manipulación de datos
library(RColorBrewer)   # paleta del mapa (la misma del Punto 1)
library(plotly)         # gráficas interactivas
library(shiny)
library(shinydashboard)
library(DT)             # tabla del top 3

# Paquetes no vistos en clase: ninguno
# Funciones no vistas en clase: add_sf() y event_data() de plotly (mapa con clic)
# Lo no visto se marca igual que en Taller3.R (ver su CONFIGURACIÓN INICIAL).

# =============================================================================
# DATOS (generados por los puntos 1 y 2 de Taller3.R)
# =============================================================================
# CUIDADO: con "Run App" o con runApp(), el directorio de trabajo es la carpeta
# app_shiny, así que los insumos se leen de la subcarpeta "datos".
ruta_app_datos <- "datos"

# Respaldo: si el código se corre línea por línea desde otra carpeta, se usa la
# ruta del taller (la misma de Taller3.R).
if (!dir.exists(ruta_app_datos)) {
  #Configuración Windows
  #username    <- Sys.getenv("USERNAME")
  #ruta_taller <- paste0("C:/Users/", username, "/OneDrive/Escritorio/2026-2/R/Taller 3")

  #Configuración MacOs
  username    <- Sys.getenv("USER")
  ruta_taller <- paste0("/Users/", username, "/Documents/Maestría/R/Taller 3 def")

  ruta_app_datos <- file.path(ruta_taller, "app_shiny", "datos")
}

archivos_datos <- c("mapa_dpto.rds", "base_mun.rds", "cortes_dpto.rds",
                    "ibr_on.rds", "sofr_on.rds", "tasas_mensual.rds")
faltantes <- archivos_datos[!file.exists(file.path(ruta_app_datos, archivos_datos))]
if (length(faltantes) > 0) {
  stop("Faltan archivos en ", ruta_app_datos, ": ", paste(faltantes, collapse = ", "),
       ". Corran primero Taller3.R (puntos 1 y 2).")
}

mapa        <- readRDS(file.path(ruta_app_datos, "mapa_dpto.rds"))      # sf, EPSG 4326
base_mun    <- readRDS(file.path(ruta_app_datos, "base_mun.rds"))
cortes_dpto <- readRDS(file.path(ruta_app_datos, "cortes_dpto.rds"))
ibr_on      <- readRDS(file.path(ruta_app_datos, "ibr_on.rds"))         # fecha, ibr_pct
sofr_on     <- readRDS(file.path(ruta_app_datos, "sofr_on.rds"))        # fecha, sofr_pct
tasas_mens  <- readRDS(file.path(ruta_app_datos, "tasas_mensual.rds"))  # mes, sofr_pct, ibr_pct

color_sofr <- "#2E8B57"
color_ibr  <- "#1F5F99"

fuente_tasas <- paste0("Fuente: Banco de la República, SUAMECA (serie 241, web scraping); ",
                       "Federal Reserve Bank of New York, Markets Data API. Cálculos propios.")

# TEXTO DE LA PESTAÑA C
# ¿qué representa cada punto? ¿de qué fuentes y años salen
# el IDF, la población y el VA? ¿en qué unidades están? ¿por qué se usa escala
# logarítmica? ¿qué relación buscan mostrar y qué muestra la correlación? ¿qué
# cambia al filtrar por departamento? Escriban 4 a 6 líneas con sus palabras.
texto_explicacion_c <- "A partir del IDF municipal 2024 (DNP) (un score de 0 a 100) vs las proyecciones poblacionales del DANE para 2024 (en personas) o el VA municipal proyectado (en miles de millones de pesos corrientes), también con datos del DANE 2023, se grafica un diagrama de dispersión con filtro departamental donde parece que la población y el VA no son suficientes para explicar el desempeño fiscal. La correlación de Pearson refuerza esta afirmación, hacen falta otras variables institucionales o de gestión para explicar completamente el desempeño fiscal. Esto no hace erróneo al IDF artificial departamental (que parte de ponderadores para tener un proxy del desempeño fiscal). El gráfico expone que se debe tener cuidado al interpretarlo ya que ponderar con la población y valor agregado de cada municipio hace que sus resultados tiendan al de grandes municipios del departamento. El eje horizontal (Población o VA 2024) se presenta en log dado que algunos municipios son muy grandes y otros muy pequeños en comparación, por lo que la escala logarítmica permite distinguir según magnitud."

# Formato con coma decimal
fmt <- function(x, d = 1) {
  ifelse(is.na(x), "sin dato",
         format(round(x, d), nsmall = d, decimal.mark = ",", trim = TRUE))
}

opciones_dpto <- c("Seleccione un departamento..." = "",
                   setNames(mapa$cod_dpto, mapa$nombre_dpto)[order(mapa$nombre_dpto)])

# =============================================================================
# INTERFAZ
# =============================================================================
ui <- dashboardPage(
  dashboardHeader(title = "Taller 3"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("A. Mapa del IDF",          tabName = "tab_a", icon = icon("map")),
      menuItem("B. IBR, SOFR y devaluación", tabName = "tab_b", icon = icon("chart-line")),
      menuItem("C. Diseño libre",          tabName = "tab_c", icon = icon("palette"))
    )
  ),
  
  dashboardBody(
    tabItems(
      
      # ------------------------------ A ------------------------------
      tabItem(tabName = "tab_a",
              fluidRow(
                column(width = 4,
                       box(title = "Cómo usar", status = "info", solidHeader = TRUE, width = 12,
                           tags$ol(
                             tags$li("Haga clic en un departamento del mapa o elíjalo en la lista."),
                             tags$li("Verá su IDF departamental y los tres municipios con mayor IDF municipal."),
                             tags$li("Para consultar el Archipiélago de San Andrés, Providencia y Santa Catalina, selecciónelo en la lista desplegable."),
                             tags$li("Pase el cursor sobre el mapa para ver el valor de cada departamento.")
                           ),
                           selectInput("dpto", "Departamento", choices = opciones_dpto)),
                       valueBoxOutput("vb_dpto", width = 12),
                       box(title = "Tres municipios con mayor IDF municipal",
                           status = "primary", solidHeader = TRUE, width = 12,
                           DTOutput("tabla_top3"),
                           uiOutput("nota_top3"),
                           hr(),
                           helpText("IDF departamental: media ponderada del IDF municipal, con ponderador ",
                                    "población 2024 × VA 2024 proyectado. IDF municipal: valor oficial del DNP, 2024."))
                ),
                column(width = 8,
                       box(title = "IDF artificial por departamento, 2024",
                           status = "primary", solidHeader = TRUE, width = 12,
                           plotlyOutput("mapa", height = 650))
                )
              )
      ),
      
      # ------------------------------ B ------------------------------
      tabItem(tabName = "tab_b",
              fluidRow(
                valueBoxOutput("vb_ibr", width = 4),
                valueBoxOutput("vb_sofr", width = 4),
                valueBoxOutput("vb_pi", width = 4)
              ),
              fluidRow(
                column(width = 4,
                       box(title = "Cómo usar", status = "info", solidHeader = TRUE, width = 12,
                           tags$ol(
                             tags$li("Elija la frecuencia del gráfico (eje izquierdo: SOFR; eje derecho: IBR)."),
                             tags$li("Escriba una fecha con formato AAAA-MM-DD, entre 2020-01-01 y 2025-10-31."),
                             tags$li("Arriba aparecen la IBR ON, la SOFR ON y la devaluación implícita de ese día.")
                           ),
                           radioButtons("frecuencia", "Frecuencia del gráfico",
                                        choices = c("Promedio mensual" = "mensual",
                                                    "Diaria (días hábiles)" = "diaria")),
                           dateInput("fecha", "Fecha de consulta", value = as.Date("2025-10-31"),
                                     min = as.Date("2020-01-01"), max = as.Date("2025-10-31"),
                                     format = "yyyy-mm-dd", language = "es"),
                           uiOutput("aviso_fecha"),
                           hr(),
                           helpText("Fórmula: π = (1 + i_d) / (1 + i_e) − 1, con i_d = IBR ON e i_e = SOFR ON, ",
                                    "en decimales (porcentaje ÷ 100). Ambas son tasas anuales, así que π es una ",
                                    "tasa de devaluación implícita ANUAL, expresada en %. La IBR de la serie 241 y ",
                                    "la SOFR son tasas nominales anuales con días calendario sobre un año de 360 ",
                                    "días (Actual/360), así que sus convenciones son comparables."))
                ),
                column(width = 8,
                       box(title = "IBR ON y SOFR ON", status = "primary", solidHeader = TRUE, width = 12,
                           plotlyOutput("grafico_tasas", height = 580))
                )
              )
      ),
      
      # ------------------------------ C ------------------------------
      tabItem(tabName = "tab_c",
              fluidRow(
                column(width = 4,
                       box(title = "Controles", status = "info", solidHeader = TRUE, width = 12,
                           radioButtons("x_c", "Variable del eje horizontal",
                                        choices = c("Población 2024 (personas)" = "poblacion",
                                                    "VA 2024 proyectado (miles de millones de pesos corrientes)" = "va_2024")),
                           selectizeInput("dptos_c", "Departamentos (vacío = todos)",
                                          choices = sort(unique(base_mun$nombre_dpto)), multiple = TRUE,
                                          options = list(placeholder = "Todos los departamentos")),
                           checkboxInput("log_c", "Escala logarítmica en el eje horizontal", TRUE),
                           checkboxInput("tend_c", "Mostrar línea de tendencia lineal", FALSE)),
                       box(title = "¿Qué muestra esta gráfica?", status = "warning",
                           solidHeader = TRUE, width = 12,
                           p(texto_explicacion_c))
                ),
                column(width = 8,
                       box(title = "IDF municipal y tamaño económico y poblacional",
                           status = "primary", solidHeader = TRUE, width = 12,
                           plotlyOutput("grafico_c", height = 600))
                )
              )
      )
    )
  )
)

# =============================================================================
# SERVIDOR
# =============================================================================
server <- function(input, output, session) {
  
  # ------------------------------ A ------------------------------
  # Color de cada departamento según su clase de Jenks (misma paleta del punto 1)
  pal_clases <- brewer.pal(length(cortes_dpto) - 1, "YlGnBu")
  mapa <- mapa %>%
    mutate(color_relleno = ifelse(is.na(idf_clase), "#CCCCCC", pal_clases[as.integer(idf_clase)]),
           clase_txt = ifelse(is.na(idf_clase), "Sin dato", as.character(idf_clase)),
           texto = paste0("<b>", nombre_dpto, "</b><br>IDF departamental: ", fmt(idf_dpto))) %>%
    arrange(is.na(idf_clase), as.integer(idf_clase)) %>%     # ordena la leyenda por clase
    mutate(primera_clase = !duplicated(clase_txt))           # una sola entrada de leyenda por clase
  
  # Mapa base: un trazo por departamento (split). El código del departamento va
  # en "meta" para poder identificar el trazo después.
  mapa_base <- plot_ly(source = "mapa") %>%
    add_sf(data = mapa, split = ~cod_dpto, meta = ~cod_dpto,
           fillcolor = ~color_relleno, line = list(color = "white", width = 0.6),
           text = ~texto, hoverinfo = "text", hoveron = "fills")
  
  # CUIDADO: con split, los atributos mapeados con ~ se repiten en cada vértice
  # del polígono, y la leyenda necesita UN valor por trazo. Por eso el nombre, el
  # grupo y la visibilidad en la leyenda se asignan aquí, trazo por trazo, después
  # de construir el gráfico. Así la leyenda muestra una entrada por clase de Jenks
  # (y al hacer clic en ella se ocultan o muestran sus departamentos).
  construir_mapa <- function(p) {
    b <- plotly_build(p)
    for (i in seq_along(b$x$data)) {
      cod <- if (is.null(b$x$data[[i]]$meta)) NA_character_ else as.character(b$x$data[[i]]$meta)[1]
      j <- match(cod, mapa$cod_dpto)
      if (!is.na(j)) {
        b$x$data[[i]]$meta        <- cod
        b$x$data[[i]]$name        <- mapa$clase_txt[j]
        b$x$data[[i]]$legendgroup <- mapa$clase_txt[j]
        b$x$data[[i]]$showlegend  <- mapa$primera_clase[j]
        b$x$data[[i]]$legendrank  <- match(mapa$clase_txt[j], c(levels(mapa$idf_clase), "Sin dato"))
      }
    }
    b
  }
  
  # Código del departamento de cada trazo: sirve para saber cuál se tocó,
  # porque el clic solo informa el número de trazo
  nombres_trazos <- vapply(construir_mapa(mapa_base)$x$data,
                           function(tr) if (is.null(tr$meta)) NA_character_ else as.character(tr$meta)[1],
                           character(1))
  
  output$mapa <- renderPlotly({
    p <- mapa_base
    # Contorno rojo sobre el departamento elegido
    if (input$dpto != "") {
      p <- p %>%
        add_sf(data = mapa[mapa$cod_dpto == input$dpto, ],
               fillcolor = "rgba(0,0,0,0)", line = list(color = "#d7301f", width = 3),
               hoverinfo = "skip", showlegend = FALSE, name = "seleccion")
    }
    p <- p %>%
      layout(xaxis = list(visible = FALSE),
             yaxis = list(visible = FALSE, scaleanchor = "x", scaleratio = 1),
             legend = list(title = list(text = "<b>IDF departamental</b><br>(cortes de Jenks)")),
             margin = list(l = 0, r = 0, t = 10, b = 0)) %>%
      event_register("plotly_click")
    construir_mapa(p)
  })
  
  # Clic en el mapa -> actualiza la lista de departamentos
  observeEvent(event_data("plotly_click", source = "mapa"), {
    ck  <- event_data("plotly_click", source = "mapa")
    idx <- ck$curveNumber[1] + 1          # plotly cuenta los trazos desde 0
    if (!is.na(idx) && idx <= length(nombres_trazos)) {
      id <- nombres_trazos[idx]
      if (!is.na(id) && id %in% mapa$cod_dpto) {
        updateSelectInput(session, "dpto", selected = id)
      }
    }
  })
  
  # reactive: datos del departamento elegido (se calculan una vez)
  fila_dpto <- reactive({
    req(input$dpto != "")
    st_drop_geometry(mapa[mapa$cod_dpto == input$dpto, ])
  })
  
  mun_dpto <- reactive({
    req(input$dpto != "")
    base_mun %>% filter(cod_dpto == input$dpto, !is.na(idf))
  })
  
  output$vb_dpto <- renderValueBox({
    if (input$dpto == "") {
      valueBox("—", "Índice departamental: elija un departamento",
               icon = icon("map-location-dot"), color = "light-blue")
    } else {
      d <- fila_dpto()
      valueBox(fmt(d$idf_dpto, 2),
               paste0("ÍNDICE DEPARTAMENTAL · ", d$nombre_dpto,
                      " (media ponderada de ", d$n_mpios, " municipio(s))"),
               icon = icon("chart-pie"), color = "blue")
    }
  })
  
  output$tabla_top3 <- renderDT({
    req(input$dpto != "")
    top3 <- mun_dpto() %>%
      arrange(desc(idf)) %>%
      slice_head(n = 3) %>%
      transmute(Puesto = row_number(),
                Municipio = nombre_mpio,
                `IDF municipal` = fmt(idf, 2))
    datatable(top3, rownames = FALSE,
              options = list(dom = "t", paging = FALSE, ordering = FALSE))
  })
  
  output$nota_top3 <- renderUI({
    req(input$dpto != "")
    n <- nrow(mun_dpto())
    if (n == 0) {
      tags$em("Este departamento no tiene municipios con IDF municipal.")
    } else if (n < 3) {
      tags$em(paste0("Solo hay ", n, " municipio(s) con IDF en este departamento."))
    }
  })
  
  # ------------------------------ B ------------------------------
  # reactive: tasas de la fecha elegida (las usan las tarjetas y el aviso)
  tasas_fecha <- reactive({
    f <- input$fecha
    if (is.null(f) || is.na(f)) {
      return(list(valida = FALSE))
    }
    list(valida = TRUE, f = f,
         i = ibr_on$ibr_pct[ibr_on$fecha == f],
         s = sofr_on$sofr_pct[sofr_on$fecha == f])
  })
  
  output$vb_ibr <- renderValueBox({
    t <- tasas_fecha()
    if (!t$valida || length(t$i) == 0) {
      valueBox("Sin dato", "IBR ON", icon = icon("triangle-exclamation"), color = "yellow")
    } else {
      valueBox(paste0(fmt(t$i, 3), " %"), "IBR ON (nominal anual)",
               icon = icon("percent"), color = "blue")
    }
  })
  
  output$vb_sofr <- renderValueBox({
    t <- tasas_fecha()
    if (!t$valida || length(t$s) == 0) {
      valueBox("Sin dato", "SOFR ON", icon = icon("triangle-exclamation"), color = "yellow")
    } else {
      valueBox(paste0(fmt(t$s, 2), " %"), "SOFR ON (anual)",
               icon = icon("percent"), color = "green")
    }
  })
  
  output$vb_pi <- renderValueBox({
    t <- tasas_fecha()
    if (!t$valida || length(t$i) == 0 || length(t$s) == 0) {
      valueBox("No calculable", "Devaluación implícita π", icon = icon("ban"), color = "red")
    } else {
      pi_val <- ((1 + t$i / 100) / (1 + t$s / 100) - 1) * 100
      valueBox(paste0(fmt(pi_val, 2), " %"), "Devaluación implícita π (anual)",
               icon = icon("arrow-trend-up"), color = "purple")
    }
  })
  
  output$aviso_fecha <- renderUI({
    t <- tasas_fecha()
    if (!t$valida) {
      return(div(style = "color:#b30000;", "Fecha no válida. Escríbala con formato AAAA-MM-DD."))
    }
    faltan <- c(if (length(t$i) == 0) "IBR ON (no hay publicación en Colombia ese día)",
                if (length(t$s) == 0) "SOFR ON (no hay publicación en EE. UU. ese día)")
    if (length(faltan) > 0) {
      div(style = "background:#fff3cd; padding:10px; border-left:5px solid #e0a800;",
          strong(format(t$f, "%d/%m/%Y"), ": no se puede calcular π. Falta:"),
          tags$ul(lapply(faltan, tags$li)),
          "Pruebe con otro día hábil en ambos países.")
    }
  })
  
  output$grafico_tasas <- renderPlotly({
    if (input$frecuencia == "mensual") {
      x_s <- tasas_mens$mes;  y_s <- tasas_mens$sofr_pct
      x_i <- tasas_mens$mes;  y_i <- tasas_mens$ibr_pct
      titulo <- "IBR overnight y SOFR overnight: promedio mensual"
      ht_s <- "<b>SOFR ON</b><br>Mes: %{x|%b %Y}<br>Promedio: %{y:.2f} %<extra></extra>"
      ht_i <- "<b>IBR ON</b><br>Mes: %{x|%b %Y}<br>Promedio: %{y:.3f} %<extra></extra>"
    } else {
      x_s <- sofr_on$fecha;   y_s <- sofr_on$sofr_pct
      x_i <- ibr_on$fecha;    y_i <- ibr_on$ibr_pct
      titulo <- "IBR overnight y SOFR overnight: diaria"
      ht_s <- "<b>SOFR ON</b><br>%{x|%d/%m/%Y}<br>%{y:.2f} %<extra></extra>"
      ht_i <- "<b>IBR ON</b><br>%{x|%d/%m/%Y}<br>%{y:.3f} %<extra></extra>"
    }
    
    t <- tasas_fecha()
    linea <- if (t$valida) {
      list(list(type = "line", xref = "x", yref = "paper",
                x0 = as.character(t$f), x1 = as.character(t$f), y0 = 0, y1 = 1,
                line = list(color = "gray40", dash = "dash", width = 1)))
    } else list()
    
    plot_ly() %>%
      add_trace(x = x_s, y = y_s, name = "SOFR ON (eje izquierdo)",
                type = "scatter", mode = "lines",
                line = list(color = color_sofr, width = 2), hovertemplate = ht_s) %>%
      add_trace(x = x_i, y = y_i, name = "IBR ON (eje derecho)",
                type = "scatter", mode = "lines", yaxis = "y2",
                line = list(color = color_ibr, width = 2), hovertemplate = ht_i) %>%
      layout(title  = list(text = paste0("<b>", titulo, "</b><br><sup>Periodo: 01/01/2020 a 31/10/2025. ",
                                         "Línea punteada: fecha consultada.</sup>")),
             xaxis  = list(title = "Fecha"),
             yaxis  = list(title = list(text = "SOFR ON: tasa anual (%)", font = list(color = color_sofr)),
                           ticksuffix = " %"),
             yaxis2 = list(title = list(text = "IBR ON: tasa nominal anual (%)", font = list(color = color_ibr)),
                           ticksuffix = " %", overlaying = "y", side = "right"),
             shapes = linea,
             legend = list(orientation = "h", x = 0, y = -0.2),
             margin = list(r = 80, b = 170),
             annotations = list(list(text = gsub('; ', ';<br>', fuente_tasas), x = 0, y = -0.42,
                                     xref = "paper", yref = "paper", showarrow = FALSE,
                                     xanchor = "left", font = list(size = 10, color = "gray"))))
  })
  
  # ------------------------------ C ------------------------------
  # reactive: municipios que pasan los filtros (los usa el gráfico)
  datos_c <- reactive({
    d <- base_mun %>% filter(!is.na(idf), !is.na(poblacion), !is.na(va_2024))
    if (length(input$dptos_c) > 0) {
      d <- d %>% filter(nombre_dpto %in% input$dptos_c)
    }
    d$x <- d[[input$x_c]]
    if (input$log_c) d <- d %>% filter(x > 0)     # el logaritmo no admite ceros
    d
  })
  
  output$grafico_c <- renderPlotly({
    d <- datos_c()
    shiny::validate(shiny::need(nrow(d) > 2, "Hay muy pocos municipios con los filtros elegidos."))
    
    etiqueta_x <- if (input$x_c == "poblacion") "Población 2024 (personas)" else
      "VA 2024 proyectado (miles de millones de pesos corrientes)"
    d$texto <- paste0("<b>", d$nombre_mpio, "</b> (", d$nombre_dpto, ")",
                      "<br>IDF municipal: ", fmt(d$idf, 2),
                      "<br>", etiqueta_x, ": ",
                      format(round(d$x, 1), big.mark = ".", decimal.mark = ",", trim = TRUE))
    
    x_corr <- if (input$log_c) log10(d$x) else d$x
    corr   <- cor(x_corr, d$idf)
    
    p <- plot_ly(d, x = ~x, y = ~idf, type = "scatter", mode = "markers",
                 text = ~texto, hoverinfo = "text",
                 marker = list(color = "#1F5F99", opacity = 0.6, size = 7),
                 name = "Municipios")
    
    if (input$tend_c) {
      modelo <- lm(d$idf ~ x_corr)
      o <- order(d$x)
      p <- p %>%
        add_lines(x = d$x[o], y = fitted(modelo)[o], name = "Tendencia lineal",
                  line = list(color = "#d7301f", width = 2), hoverinfo = "skip", inherit = FALSE)
    }
    
    p %>%
      layout(title = list(text = paste0("<b>IDF municipal 2024 según ", tolower(substr(etiqueta_x, 1, 1)),
                                        substr(etiqueta_x, 2, nchar(etiqueta_x)), "</b><br><sup>",
                                        nrow(d), " municipios. Correlación de Pearson",
                                        if (input$log_c) " (con log10 del eje x)" else "", ": ",
                                        fmt(corr, 2), "</sup>")),
             xaxis = list(title = etiqueta_x, type = if (input$log_c) "log" else "linear"),
             yaxis = list(title = "IDF municipal (puntos)"),
             legend = list(orientation = "h", x = 0, y = -0.2),
             margin = list(b = 200),
             annotations = list(list(
               text = paste0("Fuente: DNP (IDF 2024), DANE (proyecciones de población y VA municipal 2023).<br>",
                             "VA 2024 proyectado con la tasa del PIB nominal. Cálculos propios."),
               x = 0, y = -0.42, xref = "paper", yref = "paper", showarrow = FALSE,
               xanchor = "left", font = list(size = 10, color = "gray"))))
  })
}

shinyApp(ui = ui, server = server)

