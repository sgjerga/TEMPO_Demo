library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(DT)
library(readxl)
library(scales)

source(file.path("R", "data_pipeline.R"), local = TRUE)
source(file.path("R", "model.R"), local = TRUE)
source(file.path("R", "prediction_view.R"), local = TRUE)

atlas <- load_atlas()
effect_data <- build_effects(atlas)
trajectories <- aggregate_trajectories(atlas$long)
study_order <- atlas$study_info$study
domain_order <- atlas$domain_details$domain
prediction_models <- read_prediction_catalog()
gold <- "#C89A2B"; charcoal <- "#34383F"; ink <- "#292D32"

css <- paste0('
@import url("https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap");
:root{--gold:#C89A2B;--gold-deep:#88620E;--charcoal:#34383F;--ink:#292D32;--muted:#676D73;--shell:#F7F7F5}
body{background:linear-gradient(135deg,#EEE2C4 0%,#fff 49%,#D9DCDF 100%) fixed;
  font-family:"DM Sans",sans-serif;color:var(--ink);font-size:14px}
.container-fluid{max-width:1600px;margin:auto;padding:24px 26px 60px}
h1,h2,h3,h4,.nav>li>a{font-family:"Manrope",sans-serif}
.masthead{padding:26px 32px;margin-bottom:22px;border-radius:24px;
  background:linear-gradient(115deg,#C39327 0%,#EAD29B 35%,#FFFFFF 53%,#676C72 81%,#34383F 100%);
  color:var(--ink);box-shadow:0 17px 45px #393A3D26;position:relative;overflow:hidden}
.masthead .tagline{font-weight:500;max-width:720px;line-height:1.55;font-size:14px;
  color:#303237;margin:0;position:relative;z-index:1}
.eyebrow{font-size:11px;font-weight:800;letter-spacing:2px;text-transform:uppercase;
  opacity:.84;margin-bottom:9px;position:relative;z-index:1}
.tempo-logo-frame{position:relative;z-index:1;width:min(460px,100%);height:120px;
  overflow:hidden;background:#FFFFFF;border:1px solid #FFFFFF;border-radius:17px;
  box-shadow:0 9px 22px #34383F24;margin:5px 0 15px}
.tempo-logo-img{display:block;width:100%;height:100%;object-fit:cover;object-position:center}
.tempo-meaning{font-weight:800;font-size:13px;letter-spacing:.15px;margin:0 0 9px;
  color:#292D32;max-width:770px;position:relative;z-index:1}
.logo-orb{position:absolute;right:60px;top:-80px;width:290px;height:290px;border:1px solid #ffffff77;
  border-radius:50%;box-shadow:0 0 0 40px #ffffff1b,0 0 0 81px #ffffff12;pointer-events:none;z-index:0}
.filters{background:#ffffffed;border:1px solid #ffffff;border-radius:22px;padding:24px 20px;
  box-shadow:0 10px 45px #34383F1A;position:sticky;top:12px}
.filters h4{font-size:15px;color:var(--ink);font-weight:800;margin:0 0 15px}
.filters .checkbox{margin:13px 0}.filters .checkbox label{line-height:1.3}
.filters hr{border-color:#E7E5E0;margin:22px 0}
.filter-note{color:#53575E;font-size:12px;line-height:1.65;background:#FBF7EB;
  border-left:3px solid var(--gold);border-radius:7px;padding:12px;margin-top:12px}
.frame{background:#ffffffef;border:1px solid #ffffff;border-radius:22px;padding:18px 22px 28px;
  min-height:680px;box-shadow:0 10px 45px #34383F1A}
.nav-pills{border-bottom:1px solid #E6E5E3;padding-bottom:13px;margin-bottom:22px;display:flex;flex-wrap:wrap;gap:7px}
.nav-pills>li>a{border-radius:12px;color:#42474D;font-weight:700;padding:11px 15px;font-size:12px}
.nav-pills>li.active>a,.nav-pills>li.active>a:hover,.nav-pills>li.active>a:focus{
  background:linear-gradient(110deg,#E6C566,var(--gold));box-shadow:0 5px 12px #A77C2340;color:#26282C}
.panel-heading{font-size:22px;letter-spacing:-.55px;font-weight:800;margin:2px 0 6px}
.subheading{color:#686D73;line-height:1.65;margin-bottom:22px;max-width:900px}
.metric-row{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:13px;margin:19px 0 24px}
.metric-card{padding:19px 20px;border:1px solid #E8E6E0;border-radius:17px;
  background:linear-gradient(150deg,#FBF2D9,#fff 61%,#F1F2F3)}
.metric-card .number{font-family:Manrope,sans-serif;font-size:29px;color:var(--gold-deep);font-weight:800}
.metric-card .label{color:#676D73;font-size:12px;margin-top:4px;font-weight:700}
.study-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px;margin:8px 0 24px}
.study-card{background:#fff;border:1px solid #E8E7E4;border-radius:18px;padding:19px 20px;
  border-top:4px solid var(--gold);box-shadow:0 8px 20px #34383F10}
.study-card:nth-child(even){border-top-color:var(--charcoal)}
.study-title{font-family:Manrope,sans-serif;font-size:17px;font-weight:800;margin:0 0 7px}
.study-pop{font-size:12px;color:#777C82;margin-bottom:12px}
.study-fact{margin:6px 0;font-size:12.5px;line-height:1.5}
.study-fact b{color:#42474D}.study-card a{color:var(--gold-deep);font-weight:700}
.study-references{padding-left:22px;margin:7px 0 14px}
.study-references li{padding:10px 0 11px 5px;line-height:1.65;border-bottom:1px solid #ECEBE8;color:#50565D;font-size:12.5px}
.study-references li:last-child{border-bottom:0}
.study-references b{color:var(--ink)}
.study-references a{color:var(--gold-deep);font-weight:700;text-decoration:none;margin-left:7px}
.study-references a:hover{text-decoration:underline}
.viz-card{border:1px solid #E7E6E3;background:#fff;border-radius:17px;padding:17px 17px 9px;
  margin:14px 0 20px;box-shadow:0 6px 25px #34383F0C}
.viz-title{font-size:14px;font-weight:800;margin:0 0 5px}
.viz-note{font-size:12px;color:#6D7278;line-height:1.65;margin-bottom:12px}
.alert-note{background:#FBF7ED;border:1px solid #ECDDBB;border-radius:13px;
  padding:13px 16px;font-size:12px;line-height:1.7;color:#5F543C;margin:12px 0 20px}
.form-control{border:1px solid #DCDDDC;border-radius:10px;min-height:39px}
label.control-label{font-weight:700;color:#484C52;font-size:12px}
.btn-default{border-radius:9px;border:1px solid #DADAD7;font-weight:700;color:var(--gold-deep)}
.btn:focus{outline-color:#C89A2B}.dataTables_wrapper{font-size:12px}
/* The compact five-column dictionary should use the full card width, not its content width. */
#dictionary{width:100%!important;min-width:0}
#dictionary .dataTables_wrapper{width:100%;overflow-x:auto}
#dictionary table.dataTable{width:100%!important;min-width:600px}
#dictionary table.dataTable th,#dictionary table.dataTable td{
  white-space:normal;overflow-wrap:anywhere;vertical-align:top}
.pred-hero{border-radius:20px;background:linear-gradient(116deg,#D1A640 0%,#F1DFAF 39%,#FFFFFF 57%,#7B7E83 85%,#34383F 100%);
  color:var(--ink);padding:23px 26px;margin-bottom:24px;box-shadow:0 11px 25px #34383F26}
.pred-hero h3{font-family:Manrope,sans-serif;font-size:19px;font-weight:800;margin:4px 0 9px}
.pred-hero p{max-width:730px;line-height:1.65;margin:0;color:#33363B;font-size:12.5px}
.pred-eyebrow{letter-spacing:2px;font-size:10px;font-weight:800;text-transform:uppercase;opacity:.8}
.pred-selector{background:linear-gradient(130deg,#FBF2DD,#fff 48%,#ECEDEF);border:1px solid #E7E1D2;
  border-radius:18px;padding:18px 21px 5px;margin:11px 0 18px}
.pred-section{margin:20px 0 13px;font:800 16px Manrope,sans-serif;letter-spacing:-.35px;color:var(--ink)}
.pred-input-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px 18px;margin:17px 0 12px}
.pred-field{background:#FAFAF8;border:1px solid #E8E7E2;border-radius:14px;padding:14px 16px 1px;
  transition:box-shadow .2s,border-color .2s}
.pred-field:hover{border-color:#C9A75A;box-shadow:0 4px 12px #C89A2B26}
.pred-field .form-group{margin-bottom:13px}
.pred-guide{padding:13px 15px;color:#4E535A;line-height:1.7;font-size:12px;background:#F9F3E4;
  border-left:3px solid var(--gold);border-radius:10px;margin:9px 0 18px}
.pred-run{border:none!important;border-radius:12px!important;padding:12px 26px!important;font-weight:800!important;
  color:white!important;background:linear-gradient(105deg,#5D6167,var(--charcoal))!important;
  box-shadow:0 5px 16px #34383F33}
.pred-run:hover{background:linear-gradient(105deg,#4A4E54,#22262B)!important}
.pred-model-facts{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;margin:15px 0 13px}
.pred-fact{border-radius:13px;background:#FAF7EE;border:1px solid #E9E4D8;padding:12px 14px}
.pred-fact b{display:block;color:var(--gold-deep);font:800 19px Manrope,sans-serif;margin-bottom:4px}
.pred-fact span{font-size:11px;color:#686D74}
.pred-empty{border-radius:16px;border:1px dashed #CDCBC5;padding:25px;background:#F7F7F5;
  color:#4E535A;line-height:1.8;margin:18px 0}
.pred-positive{color:#88620E}.pred-negative{color:#34383F}
@media(max-width:1000px){.filters{position:static}.frame{margin-top:16px}.study-grid{grid-template-columns:1fr}}
@media(max-width:600px){.container-fluid{padding:12px}.masthead{padding:22px}
  .tempo-logo-frame{height:100px;margin-bottom:14px}
  .metric-row,.pred-model-facts,.pred-input-grid{grid-template-columns:1fr}.frame{padding:16px}}
')

metric <- function(number, label) {
  div(class = "metric-card", div(class = "number", number), div(class = "label", label))
}
section_title <- function(title, description) {
  tagList(div(class = "panel-heading", title), div(class = "subheading", description))
}
viz <- function(title, description, ...) {
  div(class = "viz-card", div(class = "viz-title", title),
      div(class = "viz-note", description), ...)
}

ui <- fluidPage(
  theme = bslib::bs_theme(version = 4, bg = "#ffffff", fg = ink, primary = "#88620E"),
  tags$head(tags$style(HTML(css))),
  div(class = "masthead", div(class = "logo-orb"),
      div(class = "eyebrow", "HARMONIZED MUSIC THERAPY EVIDENCE"),
      h1(class = "sr-only", "TEMPO"),
      div(class = "tempo-logo-frame",
          tags$img(src = "tempo-logo.png", class = "tempo-logo-img",
                   alt = "TEMPO - five gold study points forming a connected melody and musical note")),
      div(class = "tempo-meaning", "Therapy Effects across Multiple Psychological Outcomes"),
      p(class = "tagline", "Explore five music-therapy experiments across populations. Discover aligned psychological domains, inspect the actual measurements, and distinguish a shared signal from study-specific variation.")),
  fluidRow(
    column(3, div(class = "filters",
                  h4("01 / Study explorer"),
                  checkboxGroupInput("studies", "Include studies", choices = study_order,
                                     selected = study_order),
                  fluidRow(column(6, actionButton("select_all", "Select all", width = "100%")),
                           column(6, actionButton("select_none", "Clear", width = "100%"))),
                  hr(), h4("02 / Interpretation"),
                  div(class = "filter-note", "All standardized effects point in the same direction: positive = favorable outcome for the more intensive / active treatment. Exact interventions, controls and measurement windows differ."),
                  div(class = "filter-note", "Hover over plots for instrument, comparator, sample size, effect estimate and uncertainty. Use the integration controls to change pooling assumptions.")
    )),
    column(9, div(class = "frame",
                  tabsetPanel(id = "page", type = "pills",
                              tabPanel("01  Overview",
                                       section_title("Studies & source data", "What was studied, how the music interventions differed, and which harmonized outcome domains are actually available."),
                                       uiOutput("metrics"), uiOutput("study_cards"),
                                       viz("Studies & citations", "Full publication or dataset references for the studies currently selected. Click a DOI to open its source.",
                                           uiOutput("study_references")),
                                       viz("Data sources & licensing", "Dataset credits and reuse terms for the selected studies. Derived summaries and harmonised analyses in TEMPO are modifications of the source material.",
                                           uiOutput("dataset_licenses")),
                                       viz("Coverage map", "A colored cell means the selected study has a usable primary effect estimate in that psychological domain. Empty cells mean the outcome is absent or not used for integration.",
                                           plotlyOutput("coverage", height = "285px")),
                                       viz("Harmonization dictionary", "One primary instrument per study and domain enters integration; additional instruments remain visible as raw trajectories.",
                                           DTOutput("dictionary", width = "100%"))
                              ),
                              tabPanel("02  Trajectories",
                                       section_title("Within-study journeys", "Explore original scale scores over time. These plots are descriptive: common trends alone do not establish treatment effects."),
                                       fluidRow(column(4, selectInput("traj_study", "Study", choices = study_order, selected = "MUSED")),
                                                column(4, selectInput("traj_domain", "Domain", choices = domain_order)),
                                                column(4, selectInput("traj_outcome", "Measure", choices = character(0)))),
                                       viz("Outcome trajectories", "Points are arm means; bars represent approximate 95% confidence intervals for the mean (not treatment-effect intervals). Hover on each point for details.",
                                           plotlyOutput("trajectories", height = "430px")),
                                       div(class = "alert-note", uiOutput("traj_note")),
                                       viz("Underlying aggregate measurements", "Number of individuals with observed data at that time point. Useful for spotting attrition and unequal follow-up.",
                                           DTOutput("trajectory_table"))
                              ),
                              tabPanel("03  Domain Atlas",
                                       section_title("Shared outcome language", "Compare study-specific estimates on an approximately standardized, benefit-oriented axis while retaining distinct intervention contrasts."),
                                       div(class = "alert-note", "Domain alignment is conceptual, not measurement equivalence. Standardization does not establish that different scales or populations measure identical latent constructs. MIDDEL estimates are published, cluster-adjusted results; other effects are unadjusted complete-case contrasts."),
                                       viz("Study × domain effect fingerprint", "Gold = favorable, dark grey = unfavorable, and white = approximately zero effect. Color intensity reflects effect magnitude; blank cells have no comparable primary effect.",
                                           plotlyOutput("atlas_heatmap", height = "390px")),
                                       viz("Effect estimates & provenance", "95% intervals, outcome names, actual comparator and computation method remain attached to every point.",
                                           DTOutput("effects_table"))
                              ),
                              tabPanel("04  Integration",
                                       section_title("The common signal, and what departs from it", "An exploratory inverse-variance model estimates a shared benefit within one selected domain. Individual-study deviations are partially pooled toward that common effect."),
                                       fluidRow(column(4, selectInput("integration_domain", "Psychological domain", choices = domain_order,
                                                                      selected = "Depression")),
                                                column(4, selectInput("model", "Common-effect model", choices = c("Random effects (REML)" = "REML", "Fixed effect" = "Fixed"), selected = "REML")),
                                                column(4, div(style = "padding-top:20px;", checkboxInput("include_dose", "Include active-dose study", FALSE)))),
                                       div(class = "alert-note", "Default synthesis excludes Esteban-Cárdenas because it tests five versus one music-therapy sessions. MIDDEL's GMT factorial comparison includes some participants receiving choir singing in the non-GMT arm; all pooled results therefore remain exploratory."),
                                       uiOutput("pool_metrics"),
                                       viz("Between-study synthesis", "A point is a trial's domain-specific effect with approximate 95% CI. The diamond is the estimated common effect. Positive = greater benefit from the more active intervention.",
                                           plotlyOutput("forest", height = "350px")),
                                       viz("Study-specific departures (empirical Bayes)", "Partially pooled deviation from the common domain effect. Positive means more benefit than the common estimate; negative means less. Uncertainty is conditional on fitted heterogeneity and pooled mean.",
                                           plotlyOutput("deviations", height = "320px")),
                                       uiOutput("model_note"),
                                       viz("Data behind this synthesis", "Download-ready estimates, sample sizes and experimental contrasts. The table shows exactly what was included.",
                                           DTOutput("integration_table"),
                                           downloadButton("download_effects", "Download selected effect estimates (CSV)"))
                              ),
                              tabPanel("05  Predictions",
                                       section_title("Profile-based outcome predictions",
                                                     "Explore model-predicted changes for a hypothetical baseline profile using eligible saved models."),
                                       div(class = "pred-hero",
                                           div(class = "pred-eyebrow", "Research preview · personalized scenarios"),
                                           h3("From baseline profile to expected outcome"),
                                           p("Compare model-predicted improvement under music therapy and the actual trial comparator. Enter a baseline profile, then click Predict outcomes to calculate a new scenario.")),
                                       div(class = "pred-selector",
                                           fluidRow(
                                             column(5, selectInput("pred_domain", "01 · Outcome to predict",
                                                                   choices = prediction_domain_choices, selected = "Depression")),
                                             column(7, selectInput("pred_model", "02 · Study / trained model",
                                                                   choices = character(0))))),
                                       uiOutput("pred_availability"),
                                       uiOutput("pred_model_story"),
                                       div(class = "pred-section", "03 · Describe a baseline profile"),
                                       div(class = "pred-guide",
                                           "Enter values measured before treatment. Defaults are training-set medians or common categories, not an actual person. Hover over inputs to read their meaning. Click Predict outcomes after each change."),
                                       uiOutput("pred_inputs"),
                                       actionButton("pred_run", "Predict outcomes", class = "pred-run", icon = icon("chart-line")),
                                       div(class = "pred-section", "04 · Explore the predicted response"),
                                       uiOutput("pred_results"),
                                       fluidRow(
                                         column(6, viz("Two hypothetical treatment scenarios",
                                                       "Model-predicted favorable change in baseline-SD units. Positive means improvement. Hover for the full interpretation.",
                                                       plotlyOutput("pred_scenarios", height = "330px"))),
                                         column(6, viz("Sensitivity to the starting score",
                                                       "How this fitted model's conditional contrast changes when baseline severity varies ±1.5 SD; other inputs remain fixed. Not an uncertainty interval.",
                                                       plotlyOutput("pred_sensitivity", height = "330px")))),
                                       div(class = "alert-note",
                                           tags$b("Interpretation & safeguards. "),
                                           "The displayed difference is a model-implied conditional contrast, not an observed individual response or validated causal treatment effect. Predictive R² and RMSE evaluate observed outcomes, not counterfactual differences. Results are exploratory and must not guide clinical decisions. Only compatible saved models with sufficient basic data and performance reporting are offered.")
                              )
                  )
    ))
  )
)

server <- function(input, output, session) {
  observeEvent(input$select_all, updateCheckboxGroupInput(session, "studies", selected = study_order))
  observeEvent(input$select_none, updateCheckboxGroupInput(session, "studies", selected = character(0)))
  selected <- reactive({ if (is.null(input$studies)) character(0) else input$studies })
  selected_effects <- reactive({ effect_data |> filter(study %in% selected()) })
  selected_long <- reactive({ atlas$long |> filter(study %in% selected()) })
  
  output$metrics <- renderUI({
    e <- selected_effects()
    div(class = "metric-row", metric(length(selected()), "Selected studies"),
        metric(length(unique(e$domain)), "Integrated outcome domains"),
        metric(nrow(e), "Domain-level experimental contrasts"))
  })
  
  output$study_cards <- renderUI({
    d <- atlas$study_info |> filter(study %in% selected())
    if (!nrow(d)) return(div(class = "alert-note", "Select one or more studies from the left."))
    cards <- lapply(seq_len(nrow(d)), function(i) {
      x <- d[i, ]
      div(class = "study-card", div(class = "study-title", x$study),
          div(class = "study-pop", x$population),
          div(class = "study-fact", tags$b("Design · "), x$design),
          div(class = "study-fact", tags$b("Participants · "), x$sample),
          div(class = "study-fact", tags$b("Intervention · "), x$intervention),
          div(class = "study-fact", tags$b("Comparator · "), x$comparison),
          div(class = "study-fact", tags$b("Available files · "), x$available),
          tags$a("Open source study ↗", href = x$reference, target = "_blank", rel = "noopener noreferrer")
      )
    })
    div(class = "study-grid", cards)
  })
  
  output$study_references <- renderUI({
    refs <- study_references |> filter(study %in% selected())
    if (!nrow(refs)) return(div(class = "viz-note", "Select one or more studies to view citations."))
    tags$ol(class = "study-references", lapply(seq_len(nrow(refs)), function(i) {
      x <- refs[i, ]
      tags$li(tags$b(paste0(x$study, " · ")), x$citation,
              tags$a("DOI / source ↗", href = x$url, target = "_blank",
                     rel = "noopener noreferrer"))
    }))
  })

  output$dataset_licenses <- renderUI({
    refs <- dataset_licensing |> filter(study %in% selected())
    if (!nrow(refs)) return(div(class = "viz-note", "Select a study to see its dataset licence and credits."))
    tags$ol(class = "study-references", lapply(seq_len(nrow(refs)), function(i) {
      x <- refs[i, ]
      tags$li(
        tags$b(paste0(x$study, " · ")), x$credit,
        tags$a("Dataset ↗", href = x$data_url, target = "_blank", rel = "noopener noreferrer"),
        tags$div(tags$b("Reuse terms · "), x$license_label,
                 if (!is.na(x$license_url)) tags$a("Licence ↗", href = x$license_url,
                                                 target = "_blank", rel = "noopener noreferrer")),
        tags$div(class = "viz-note", x$license_note)
      )
    }))
  })
  
  output$coverage <- renderPlotly({
    validate(need(length(selected()) > 0, "Select at least one study."))
    # Only display domains with at least one primary effect among selected studies.
    domains_present <- domain_order[domain_order %in% unique(selected_effects()$domain)]
    validate(need(length(domains_present) > 0,
                  "None of the selected studies has a harmonized primary effect."))
    grid <- tidyr::expand_grid(study = selected(), domain = domains_present) |>
      left_join(selected_effects() |> mutate(has = 1L) |> select(study, domain, has),
                by = c("study", "domain")) |>
      mutate(label = ifelse(is.na(has), "Not entered into synthesis", "Primary effect available"),
             tooltip = paste0(study, "<br>", domain, "<br>", label))
    p <- ggplot(grid, aes(x = factor(domain, levels = domains_present),
                          y = factor(study, levels = rev(study_order)))) +
      geom_tile(aes(fill = !is.na(has), text = tooltip), color = "white", linewidth = 1.3) +
      scale_fill_manual(values = c(`TRUE` = gold, `FALSE` = "#E8E9EA"), guide = "none") +
      labs(x = NULL, y = NULL) + theme_minimal(base_size = 12) +
      theme(panel.grid = element_blank(), axis.text.x = element_text(angle = 28, hjust = 1),
            axis.text.y = element_text(color = ink), plot.margin = margin(12, 18, 18, 15))
    ggplotly(p, tooltip = "text") |> config(displayModeBar = FALSE)
  })
  
  output$dictionary <- renderDT({
    d <- selected_effects() |> select(Study = study, Domain = domain,
                                      `Primary measure` = outcome, Comparison = contrast, `Data/estimator` = source)
    datatable(d, rownames = FALSE, filter = "top", width = "100%",
              options = list(pageLength = 8, autoWidth = FALSE, scrollX = FALSE))
  })
  
  observe({
    st <- selected()
    valid <- if (!is.null(input$traj_study) && input$traj_study %in% st) input$traj_study else st[1]
    updateSelectInput(session, "traj_study", choices = st, selected = valid)
  })
  observe({
    d <- unique(atlas$long$domain[atlas$long$study == input$traj_study])
    d <- domain_order[domain_order %in% d]
    keep <- if (!is.null(input$traj_domain) && input$traj_domain %in% d) input$traj_domain else d[1]
    updateSelectInput(session, "traj_domain", choices = d, selected = keep)
  })
  observe({
    d <- unique(atlas$long$outcome[atlas$long$study == input$traj_study &
                                     atlas$long$domain == input$traj_domain])
    keep <- if (!is.null(input$traj_outcome) && input$traj_outcome %in% d) input$traj_outcome else d[1]
    updateSelectInput(session, "traj_outcome", choices = d, selected = keep)
  })
  traj <- reactive({
    trajectories |> filter(study == input$traj_study, domain == input$traj_domain,
                           outcome == input$traj_outcome, study %in% selected()) |>
      arrange(arm, time)
  })
  output$trajectories <- renderPlotly({
    d <- traj()
    validate(need(nrow(d) > 0, "Select a study and an available measure."))
    p <- plot_ly()
    arms <- unique(d$arm)
    colors <- c(gold, charcoal, "#89691F", "#777C82", "#D5B86A")
    for (i in seq_along(arms)) {
      a <- d |> filter(arm == arms[i]) |> arrange(time)
      text <- sprintf("<b>%s</b><br>%s<br>%s<br>%s<br>Mean: %.2f<br>N: %d<br>95%% mean CI: %.2f to %.2f",
                      a$study, a$arm, a$outcome, as.character(a$time), a$avg, a$n, a$lower, a$upper)
      err_up <- ifelse(is.finite(a$upper - a$avg), a$upper - a$avg, 0)
      err_dn <- ifelse(is.finite(a$avg - a$lower), a$avg - a$lower, 0)
      p <- add_trace(p, x = as.character(a$time), y = a$avg,
                     type = "scatter", mode = "lines+markers", name = arms[i],
                     line = list(color = colors[i], width = 3),
                     marker = list(color = colors[i], size = 10, line = list(color = "white", width = 1.5)),
                     error_y = list(type = "data", array = err_up, arrayminus = err_dn,
                                    symmetric = FALSE, visible = TRUE, color = colors[i], thickness = 1.4),
                     text = text, hoverinfo = "text")
    }
    layout(p, xaxis = list(title = "Assessment time", categoryorder = "array",
                           categoryarray = levels(atlas$long$time), zeroline = FALSE),
           yaxis = list(title = input$traj_outcome, zerolinecolor = "#B6B8BB", gridcolor = "#ECEDEE"),
           legend = list(orientation = "h", x = 0, y = -0.2), margin = list(b = 80, l = 75, r = 15, t = 25),
           paper_bgcolor = "white", plot_bgcolor = "white") |>
      config(displaylogo = FALSE, modeBarButtonsToRemove = c("lasso2d", "select2d"))
  })
  output$traj_note <- renderUI({
    validate(need(nrow(traj()) > 0, "No trajectory selected."))
    d <- atlas$long |> filter(study == input$traj_study, outcome == input$traj_outcome)
    special <- unique(d$note[nzchar(d$note)])
    HTML(paste0("<b>Interpretation:</b> Data remain in each instrument's original units. ",
                ifelse(unique(d$direction)[1] < 0, "Lower values are typically favorable.", "Higher values are typically favorable."),
                if (length(special)) paste0(" <b>Source note:</b> ", paste(special, collapse = " ")) else "",
                if (input$traj_study == "MIDDEL") " Australian participant trajectories overlap the international trial and are never independently pooled." else ""))
  })
  output$trajectory_table <- renderDT({
    datatable(traj() |> transmute(Arm = arm, Time = as.character(time), N = n,
                                  Mean = round(avg, 2), SD = round(sd, 2), `95% CI lower` = round(lower, 2),
                                  `95% CI upper` = round(upper, 2)), rownames = FALSE,
              options = list(pageLength = 12, scrollX = TRUE, dom = "tip"))
  })
  
  output$atlas_heatmap <- renderPlotly({
    d <- tidyr::expand_grid(study = selected(), domain = domain_order) |>
      left_join(selected_effects(), by = c("study", "domain")) |>
      mutate(tooltip = ifelse(is.finite(estimate),
                              sprintf("<b>%s · %s</b><br>%s<br>Effect: %.2f [%.2f, %.2f]<br>%s",
                                      study, domain, outcome, estimate, lower, upper, contrast),
                              paste0(study, " · ", domain, "<br>No primary effect")))
    validate(need(nrow(d) > 0, "Select at least one study."))
    p <- ggplot(d, aes(x = domain, y = factor(study, levels = rev(study_order)))) +
      geom_tile(aes(fill = estimate, text = tooltip), color = "white", linewidth = 1.3) +
      geom_text(aes(label = ifelse(is.finite(estimate), sprintf("%+.2f", estimate), "—"),
                    color = ifelse(is.finite(estimate) & estimate < -0.9, "light", "dark")),
                size = 3.4, fontface = "bold", na.rm = TRUE, show.legend = FALSE) +
      scale_color_manual(values = c(dark = ink, light = "#FFFFFF"), guide = "none") +
      scale_fill_gradient2(low = charcoal, mid = "#FFFFFF", high = gold, midpoint = 0,
                           limits = c(-2, 2), oob = scales::squish, na.value = "#ECEDEE",
                           name = "Benefit-oriented\neffect") +
      labs(x = NULL, y = NULL) + theme_minimal(base_size = 12) +
      theme(panel.grid = element_blank(), axis.text.x = element_text(angle = 25, hjust = 1),
            legend.position = "bottom", plot.margin = margin(12, 18, 14, 12))
    ggplotly(p, tooltip = "text") |> config(displayModeBar = FALSE)
  })
  output$effects_table <- renderDT({
    d <- selected_effects() |>
      transmute(Study = study, Domain = domain, Instrument = outcome,
                `Benefit-oriented effect [95% CI]` = interval, Contrast = contrast,
                `Complete pairs` = n_label, Provenance = source, Caveat = note)
    datatable(d, rownames = FALSE, filter = "top", extensions = "Buttons",
              options = list(pageLength = 10, scrollX = TRUE, dom = "Bftip",
                             buttons = c("copy", "csv")))
  })
  
  observe({
    avail <- unique(selected_effects()$domain)
    avail <- domain_order[domain_order %in% avail]
    keep <- if (!is.null(input$integration_domain) && input$integration_domain %in% avail)
      input$integration_domain else avail[1]
    updateSelectInput(session, "integration_domain", choices = avail, selected = keep)
  })
  included <- reactive({
    d <- selected_effects() |> filter(domain == input$integration_domain)
    if (!isTRUE(input$include_dose)) d <- d |> filter(comparison_type != "Dose comparison")
    d
  })
  fit <- reactive(pool_effects(included(), input$model))
  output$pool_metrics <- renderUI({
    m <- fit()
    if (is.null(m)) return(div(class = "alert-note", "No effect estimates available under the selected constraints."))
    div(class = "metric-row", metric(sprintf("%+.2f", m$mu), "Estimated shared effect (SD units)"),
        metric(sprintf("[%.2f, %.2f]", m$lower, m$upper), "Approximate 95% common-effect CI"),
        metric(sprintf("%.2f", m$tau), paste0("Between-study heterogeneity τ · k=", m$k)))
  })
  output$forest <- renderPlotly({
    m <- fit(); validate(need(!is.null(m), "No comparable effects for this selection."))
    d <- m$data |> arrange(estimate)
    d$label <- paste0(d$study, " · ", d$outcome)
    d$tip <- sprintf("<b>%s</b><br>%s<br>%s<br>Effect: %+.2f<br>95%% CI: %.2f to %.2f<br>%s",
                     d$study, d$outcome, d$contrast, d$estimate, d$lower, d$upper, d$source)
    d$err_up <- pmax(0, d$upper - d$estimate)
    d$err_dn <- pmax(0, d$estimate - d$lower)
    p <- plot_ly(d, x = ~estimate, y = ~label, type = "scatter", mode = "markers",
                 marker = list(color = gold, size = 11, line = list(color = "white", width = 2)),
                 error_x = list(type = "data", symmetric = FALSE, array = ~err_up,
                                arrayminus = ~err_dn, color = gold),
                 text = ~tip, hoverinfo = "text", name = "Study", showlegend = FALSE)
    p <- add_trace(p, x = m$mu, y = "Shared estimate", type = "scatter", mode = "markers",
                   marker = list(symbol = "diamond", size = 17, color = charcoal),
                   error_x = list(type = "data", symmetric = FALSE,
                                  array = m$upper - m$mu, arrayminus = m$mu - m$lower, color = charcoal, thickness = 3),
                   text = sprintf("<b>Shared %s effect</b><br>%.2f [%.2f, %.2f]<br>k=%d, tau=%.2f",
                                  m$method, m$mu, m$lower, m$upper, m$k, m$tau), hoverinfo = "text",
                   name = "Common", showlegend = FALSE)
    layout(p, xaxis = list(title = "Standardized contrast (positive = benefit)", zeroline = TRUE,
                           zerolinewidth = 2, zerolinecolor = "#96999D", gridcolor = "#ECEDEE"),
           yaxis = list(title = "", automargin = TRUE),
           margin = list(l = 165, r = 30, b = 70, t = 20),
           paper_bgcolor = "white", plot_bgcolor = "white") |>
      config(displaylogo = FALSE)
  })
  output$deviations <- renderPlotly({
    m <- fit(); validate(need(!is.null(m) && m$k >= 2, "Choose a domain with at least two included studies."))
    d <- m$data
    d$tip <- sprintf("<b>%s</b><br>Raw difference from shared: %+.2f<br>EB deviation: %+.2f<br>Conditional interval: [%.2f, %.2f]",
                     d$study, d$estimate - m$mu, d$deviation,
                     d$deviation - 1.96 * d$deviation_se, d$deviation + 1.96 * d$deviation_se)
    p <- plot_ly(d, x = ~deviation, y = ~study, type = "scatter", mode = "markers",
                 marker = list(color = charcoal, size = 12),
                 error_x = list(type = "data", array = ~1.96 * deviation_se, color = charcoal),
                 text = ~tip, hoverinfo = "text", showlegend = FALSE)
    layout(p, xaxis = list(title = "Partially pooled deviation from domain effect", zeroline = TRUE,
                           zerolinecolor = "#96999D", zerolinewidth = 2, gridcolor = "#ECEDEE"),
           yaxis = list(title = "", automargin = TRUE),
           margin = list(l = 125, r = 35, b = 60, t = 15),
           paper_bgcolor = "white", plot_bgcolor = "white") |> config(displaylogo = FALSE)
  })
  output$model_note <- renderUI({
    m <- fit()
    if (is.null(m)) return(NULL)
    msg <- paste0("<b>How to read:</b> The ", m$method,
                  " estimate pools one primary outcome per study within <b>", input$integration_domain,
                  "</b>. The deviations are empirical-Bayes study effects, conditional on estimated heterogeneity. ",
                  "When τ = 0, they shrink to zero by construction; this is <i>not</i> evidence that populations are identical. ",
                  "The 95% intervals rely on normal approximations; with just ", m$k,
                  " studies, τ and heterogeneity are poorly estimated. ",
                  "The source contrasts mix unadjusted completer estimates with published MIDDEL cluster-adjusted ITT analysis.")
    if (isTRUE(input$include_dose)) msg <- paste0(msg,
                                                  " <b>Active comparator included:</b> Esteban-Cárdenas is an intervention-dose effect, not therapy versus no therapy.")
    div(class = "alert-note", HTML(msg))
  })
  output$integration_table <- renderDT({
    m <- fit(); validate(need(!is.null(m), "No included contrasts."))
    d <- m$data |> transmute(Study = study, Instrument = outcome,
                             Comparison = contrast, `Effect` = round(estimate, 3), `SE` = round(se, 3),
                             `95% lower` = round(lower, 3), `95% upper` = round(upper, 3),
                             `EB deviation` = round(deviation, 3), `Method` = source)
    datatable(d, rownames = FALSE, options = list(dom = "tip", pageLength = 10, scrollX = TRUE))
  })
  output$download_effects <- downloadHandler(
    filename = function() paste0("tempo-", gsub(" ", "-", tolower(input$integration_domain)), ".csv"),
    content = function(file) utils::write.csv(included(), file, row.names = FALSE, na = "")
  )
  
  # Tab 05: the external training run owns all model files and diagnostics.
  # The app never retrains. Selection reflects each saved model and its report.
  pred_available <- reactive(filter_prediction_catalog(prediction_models$eligible, selected()))
  observe({
    d <- pred_available()
    d <- d[d$domain == input$pred_domain, , drop = FALSE]
    if (nrow(d)) d <- d[order(d$study != "MUSED", d$study, d$outcome), , drop = FALSE]
    labels <- if (nrow(d)) paste(d$study, "·", d$outcome) else character(0)
    choices <- setNames(d$task_id, labels)
    keep <- if (!is.null(input$pred_model) && input$pred_model %in% d$task_id)
      input$pred_model else if (nrow(d)) d$task_id[1] else character(0)
    updateSelectInput(session, "pred_model", choices = choices, selected = keep)
  })
  pred_row <- reactive({
    d <- pred_available()
    if (is.null(input$pred_model) || !length(input$pred_model)) return(NULL)
    match <- which(d$task_id == input$pred_model & d$domain == input$pred_domain)
    if (!length(match)) return(NULL)
    d[match[1], , drop = FALSE]
  })
  pred_bundle <- reactive({
    row <- pred_row()
    if (is.null(row)) return(NULL)
    prediction_models$bundles[[row$task_id[1]]]
  })
  output$pred_availability <- renderUI({
    d <- pred_available()
    domain_rows <- d[d$domain == input$pred_domain, , drop = FALSE]
    if (nzchar(prediction_models$warning))
      return(div(class = "alert-note", prediction_models$warning))
    if (!nrow(domain_rows)) {
      return(div(class = "pred-empty",
                 tags$b(paste0("No eligible ", tolower(input$pred_domain), " predictor is currently available.")),
                 tags$p("This can mean that no model was trained, its saved file is missing, it did not pass the internal prediction screen, or its source study is not selected in the left sidebar."),
                 tags$p("The screen considers the number of paired observations, per-arm sample sizes, held-out prediction metrics, and the availability of compatible .rds models."),
                 tags$p("Check data/ml_reports/model_registry.csv and task_construction_warnings.csv; restart Shiny after training or updating models.")))
    }
    div(class = "pred-guide",
        tags$b(sprintf("%d model%s available for this domain. ",
                       nrow(domain_rows), if (nrow(domain_rows) == 1L) "" else "s")),
        "Models are shown for the studies selected in the sidebar. Validation metrics are provided in each model card; held-out outcome performance does not validate individual treatment effects.")
  })
  
  output$pred_model_story <- renderUI({
    row <- pred_row(); bundle <- pred_bundle()
    if (is.null(row) || is.null(bundle)) return(NULL)
    name <- switch(bundle$algorithm,
                   ridge = "Ridge regression with treatment interactions",
                   elastic_net = "Elastic-net regression with treatment interactions",
                   random_forest = "Random forest with treatment interactions",
                   bundle$algorithm)
    context <- if (bundle$study == "Pooled exploratory")
      "Exploratory harmonization: outcomes were standardized within study and trial identity was included as a predictor. This does not guarantee measurement invariance or transportability."
    else if (bundle$study == "Esteban-Cárdenas")
      "ACTIVE DOSE COMPARISON: the active scenario is five sessions, and the comparator is one session. Neither arm is untreated."
    else if (bundle$study == "MIDDEL")
      "MIDDEL is cluster randomized; the GMT comparison averages over the separately randomized choir condition."
    else "The treatment contrast applies only to the stated trial population and comparator."
    feature_names <- vapply(setdiff(bundle$features, "baseline_z"),
                            prediction_feature_label, character(1))
    div(
      div(class = "pred-section", "Model card · provenance and validation"),
      if (isTRUE(row$flat_treatment_contrast))
        div(class = "pred-guide",
            tags$b("Saved-model diagnostic · no learned arm separation. "),
            "The supplied training report records a zero model-predicted treatment contrast across its training profiles. The two arm predictions will therefore coincide; changing input values cannot create a treatment signal that the saved model did not learn. Retraining is required to change the fitted model."),
      div(class = "pred-model-facts",
          div(class = "pred-fact", title = "Complete baseline/post pairs in the modelling dataset",
              tags$b(row$n), tags$span("Paired participants")),
          div(class = "pred-fact", title = "Outer cross-validated coefficient of determination for observed outcomes; not causal-effect accuracy",
              tags$b(sprintf("%.2f", row$cv_r2)), tags$span("Held-out R² (factual)")),
          div(class = "pred-fact", title = "Root mean squared error in favorable baseline-standard-deviation units",
              tags$b(sprintf("%.2f", row$cv_rmse)), tags$span("Held-out RMSE · SD units"))),
      div(class = "pred-guide",
          tags$b(paste0(bundle$study, " · ", bundle$outcome, ". ")),
          tags$span("Comparison: ", row$comparison, ". Endpoint: ", row$timepoint, ". "),
          tags$span("Model: ", name, ". "),
          tags$span("Training: ", row$n_treated, " active vs ", row$n_control,
                    " comparator observations; ", row$n_clusters, " recorded randomization IDs/units. "),
          tags$span("Baseline covariates and treatment interactions were fitted with up to five outer validation folds. Regression regularization was tuned inside the training folds. "),
          tags$span("Other baseline inputs: ", if (length(feature_names)) paste(feature_names, collapse = ", ") else "none", ". "),
          tags$b(context)))
  })
  
  output$pred_inputs <- renderUI({
    bundle <- pred_bundle()
    if (is.null(bundle)) return(div(class = "pred-empty", "Select an available model above to enter a profile."))
    prediction_form(bundle)
  })
  
  # Explicit button-driven prediction. Each click captures the complete
  # current profile; later edits invalidate that result until the next click.
  pred_run <- eventReactive(input$pred_run, {
    bundle <- pred_bundle(); row <- pred_row()
    req(!is.null(bundle), !is.null(row))
    req(!is.null(input$pred_baseline))
    tryCatch({
      profile <- prediction_profile(bundle, input)
      control <- predict_candidate(bundle, profile, treatment_override = 0)
      active <- predict_candidate(bundle, profile, treatment_override = 1)
      if (!all(is.finite(c(control, active)))) stop("Model produced a non-finite prediction.")
      list(model_id = row$task_id[1], quality_tier = row$quality_tier[1],
           profile = profile, control = control[1],
           active = active[1], benefit = active[1] - control[1],
           unusual = prediction_extrapolation(bundle, profile),
           model = bundle, error = "")
    }, error = function(e) list(model_id = row$task_id[1], error = conditionMessage(e)))
  }, ignoreInit = TRUE)
  
  pred_display <- reactive({
    x <- pred_run()
    if (is.null(x) || is.null(input$pred_model) || x$model_id != input$pred_model)
      return(NULL)
    if (nzchar(x$error)) return(x)
    current <- tryCatch(prediction_profile(pred_bundle(), input), error = function(e) NULL)
    if (is.null(current) || !isTRUE(all.equal(x$profile, current)))
      return(NULL)
    x
  })
  
  output$pred_results <- renderUI({
    x <- pred_display()
    if (is.null(x)) return(div(class = "pred-empty",
                               if (isTRUE(input$pred_run > 0))
                                 "Parameters or the model selection have changed. Click Predict outcomes to calculate the updated result."
                               else "Enter a baseline profile and click Predict outcomes to calculate your first result."))
    if (nzchar(x$error)) return(div(class = "alert-note", tags$b("Prediction not available: "), x$error))
    value <- x$benefit
    qualifier <- if (value > 0) "Favors the active condition in this model" else if (value < 0)
      "Favors the comparator in this model" else "No modeled difference"
    extrapolation <- if (length(x$unusual))
      div(class = "alert-note", tags$b("Extrapolation warning: "),
          paste("Inputs far from the training distribution:", paste(x$unusual, collapse = ", "),
                ". Treat the estimate as especially uncertain.")) else NULL
    original <- NULL
    if (is.finite(x$model$baseline_sd) && is.finite(x$model$baseline_mean) &&
        is.finite(x$model$direction)) {
      start <- x$model$baseline_mean + x$model$baseline_sd * x$profile$baseline_z
      post_control <- start + x$model$direction * x$model$baseline_sd * x$control
      post_active <- start + x$model$direction * x$model$baseline_sd * x$active
      original <- div(class = "pred-guide",
                      tags$b("Approximate original-scale post-treatment scores: "),
                      sprintf("active %.2f; comparator %.2f (%s; baseline %.2f). ",
                              post_active, post_control, x$model$outcome, start),
                      "These are unconstrained model predictions, not measured clinical scores or guaranteed valid scale ranges.")
    }
    tagList(
      div(class = "metric-row",
          metric(sprintf("%+.4f", value), "Model-implied active minus comparator · SD"),
          metric(sprintf("%+.4f", x$active), "Predicted favorable change · active"),
          metric(sprintf("%+.4f", x$control), "Predicted favorable change · comparator")),
      div(class = "pred-guide", tags$b(qualifier, ". "),
          "All values describe favorable change relative to baseline; larger is better. They are model estimates without individual-level uncertainty intervals."),
      if (abs(value) < 1e-7)
        div(class = "pred-guide", tags$b("Identical model predictions. "),
            prediction_treatment_diagnostic(x$model)),
      original, extrapolation)
  })
  
  output$pred_scenarios <- renderPlotly({
    x <- pred_display()
    validate(need(!is.null(x) && !nzchar(x$error), "Generate a prediction to see this chart."))
    is_dose <- identical(x$model$study, "Esteban-Cárdenas")
    arms <- if (is_dose) c("One MT session", "Five MT sessions") else c("Comparator", "Music therapy")
    d <- data.frame(arm = arms, expected_change = c(x$control, x$active))
    d$tip <- sprintf("<b>%s</b><br>Predicted favorable change: %+.3f SD<br>%s<br>Not an observed person-level effect",
                     d$arm, d$expected_change, x$model$comparison)
    p <- plotly::plot_ly(d, x = ~arm, y = ~expected_change, type = "bar",
                         marker = list(color = c(charcoal, gold)), text = ~tip, hoverinfo = "text",
                         showlegend = FALSE)
    plotly::layout(p,
                   xaxis = list(title = "", showgrid = FALSE),
                   yaxis = list(title = "Predicted favorable change (baseline SD)",
                                gridcolor = "#ECEDEE", zerolinecolor = "#96999D", zerolinewidth = 2),
                   margin = list(l = 64, r = 10, t = 24, b = 55),
                   paper_bgcolor = "white", plot_bgcolor = "white") |>
      plotly::config(displayModeBar = FALSE)
  })
  
  output$pred_sensitivity <- renderPlotly({
    x <- pred_display()
    validate(need(!is.null(x) && !nzchar(x$error), "Generate a prediction to see this chart."))
    d <- prediction_sensitivity(x$model, x$profile)
    d$tip <- sprintf("<b>Hypothetical baseline: %.2f</b><br>Predicted active minus comparator: %+.3f SD<br>All other inputs held fixed",
                     d$baseline, d$predicted_benefit)
    center <- if (is.finite(x$model$baseline_sd) && is.finite(x$model$baseline_mean))
      x$model$baseline_mean + x$model$baseline_sd * x$profile$baseline_z else x$profile$baseline_z
    p <- plotly::plot_ly(d, x = ~baseline, y = ~predicted_benefit,
                         type = "scatter", mode = "lines", line = list(color = gold, width = 4),
                         text = ~tip, hoverinfo = "text", showlegend = FALSE)
    p <- plotly::add_trace(p, x = center, y = x$benefit, type = "scatter",
                           mode = "markers", marker = list(color = charcoal, size = 13,
                                                           line = list(color = "white", width = 2)),
                           text = sprintf("<b>Your selected baseline</b><br>Baseline: %.2f<br>Predicted advantage: %+.3f SD", center, x$benefit),
                           hoverinfo = "text", showlegend = FALSE)
    plotly::layout(p,
                   xaxis = list(title = if (is.finite(x$model$baseline_sd))
                     paste("Baseline", x$model$outcome, "(original units)") else "Baseline z-score",
                     gridcolor = "#ECEDEE"),
                   yaxis = list(title = "Conditional contrast (SD)", gridcolor = "#ECEDEE",
                                zerolinecolor = "#96999D", zerolinewidth = 2),
                   margin = list(l = 62, r = 15, t = 24, b = 66),
                   paper_bgcolor = "white", plot_bgcolor = "white") |>
      plotly::config(displayModeBar = FALSE)
  })
}

shinyApp(ui = ui, server = server)
