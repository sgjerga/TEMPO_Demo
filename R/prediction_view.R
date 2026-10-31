# TEMPO: prediction-tab model screening and profile helpers.
# This file deliberately never trains models or modifies data/.

# Keep the scoring implementation identical to the standalone training scripts.
# Sourcing its function definitions does not execute the training pipeline.
safe_id <- function(s) {
  x <- gsub("[^a-z0-9]+", "_", tolower(iconv(s, to = "ASCII//TRANSLIT")))
  gsub("^_+|_+$", "", x)
}
source(file.path("machine_learning_analysis", "02_model_engine.R"), local = TRUE)

prediction_domains <- c("Depression", "Anxiety", "Cognition", "Neuropsychiatric",
                        "Quality of life", "Stress")
prediction_domain_choices <- c("Depression" = "Depression", "Anxiety" = "Anxiety",
  "Cognition" = "Cognition", "Neuropsychiatry" = "Neuropsychiatric",
  "Quality of Life" = "Quality of life", "Stress" = "Stress")

# These are modest *minimum display* checks for factual prediction. Passing
# them does not validate a personalized treatment effect or clinical use.
prediction_screen <- list(min_n = 70L, min_per_arm = 25L, min_cv_r2 = 0.10,
                          min_cluster_units = 10L, min_pooled_n = 150L,
                          mused_min_n = 35L, mused_min_per_arm = 10L)

read_prediction_catalog <- function(root = ".") {
  registry_path <- file.path(root, "data", "ml_reports", "model_registry.csv")
  empty <- list(all = data.frame(), eligible = data.frame(), bundles = list(),
                warning = "")
  if (!file.exists(registry_path)) {
    empty$warning <- "No model_registry.csv found. Run source('03_run_all.R') from machine_learning_analysis/ first."
    return(empty)
  }
  d <- tryCatch(utils::read.csv(registry_path, stringsAsFactors = FALSE),
                error = function(e) e)
  if (inherits(d, "error")) {
    empty$warning <- paste("Cannot read model registry:", conditionMessage(d))
    return(empty)
  }
  mandatory <- c("task_id", "study", "domain", "outcome", "comparison", "timepoint",
                 "design", "status", "n", "n_treated", "n_control", "n_clusters",
                 "algorithm", "cv_rmse", "cv_mae", "cv_r2")
  absent <- setdiff(mandatory, names(d))
  if (length(absent)) {
    empty$warning <- paste("Model registry lacks required columns:", paste(absent, collapse = ", "))
    return(empty)
  }
  d$eligible <- rep(FALSE, nrow(d))
  d$quality_tier <- rep("Unavailable", nrow(d))
  d$screen_reason <- rep("", nrow(d))
  d$display_name <- paste(d$study, "·", d$outcome)
  d$flat_treatment_contrast <- rep(FALSE, nrow(d))
  summary_path <- file.path(root, "data", "ml_reports", "prediction_summaries.csv")
  if (file.exists(summary_path)) {
    s <- tryCatch(utils::read.csv(summary_path, stringsAsFactors = FALSE),
                  error = function(e) NULL)
    if (!is.null(s) && all(c("task_id", "mean_predicted_benefit",
                             "sd_predicted_benefit") %in% names(s))) {
      ix <- match(d$task_id, s$task_id)
      mu <- suppressWarnings(as.numeric(s$mean_predicted_benefit[ix]))
      sd <- suppressWarnings(as.numeric(s$sd_predicted_benefit[ix]))
      d$flat_treatment_contrast <- is.finite(mu) & is.finite(sd) &
        abs(mu) < 1e-9 & abs(sd) < 1e-9
    }
  }
  bundles <- list()
  for (i in seq_len(nrow(d))) {
    row <- d[i, , drop = FALSE]
    why <- character()
    quality_issues <- character()
    num <- function(nm) suppressWarnings(as.numeric(row[[nm]][1]))
    if (is.na(row$status) || row$status != "TRAINED") why <- c(why, "Model not trained")
    if (!is.character(row$task_id) || is.na(row$task_id) ||
        !grepl("^[a-z0-9_]+$", row$task_id)) why <- c(why, "Unsafe task identifier")
    if (!is.finite(num("n")) || num("n") < prediction_screen$min_n)
      quality_issues <- c(quality_issues, "Below 70 complete observations")
    if (!is.finite(num("n_treated")) || !is.finite(num("n_control")) ||
        min(num("n_treated"), num("n_control")) < prediction_screen$min_per_arm)
      quality_issues <- c(quality_issues, "Below 25 observations per arm")
    if (!is.finite(num("cv_r2")) || num("cv_r2") < prediction_screen$min_cv_r2 ||
        !is.finite(num("cv_rmse")) || num("cv_rmse") <= 0)
      quality_issues <- c(quality_issues, "Held-out R² below 0.10 or RMSE unavailable")
    if (identical(row$design[1], "Cluster randomized") &&
        (!is.finite(num("n_clusters")) || num("n_clusters") < prediction_screen$min_cluster_units))
      why <- c(why, "Too few independent randomized clusters")
    if (identical(row$study[1], "Pooled exploratory") &&
        (!is.finite(num("n")) || num("n") < prediction_screen$min_pooled_n))
      why <- c(why, "Pooled analysis too small")
    if (!row$domain[1] %in% prediction_domains) why <- c(why, "Domain not supported")
    # MUSED is the project's priority trial. Keep its *trained* models
    # accessible even below the conservative general display screen, but only
    # with adequate minimal data and a finite measured held-out RMSE. Flag the
    # weaker evidence prominently; it is never labelled validated/robust.
    mused_preview <- identical(row$study[1], "MUSED") &&
      is.finite(num("n")) && num("n") >= prediction_screen$mused_min_n &&
      is.finite(num("n_treated")) && is.finite(num("n_control")) &&
      min(num("n_treated"), num("n_control")) >= prediction_screen$mused_min_per_arm &&
      is.finite(num("cv_rmse")) && num("cv_rmse") > 0
    if (!mused_preview) why <- c(why, quality_issues)
    if (identical(row$study[1], "MUSED") && !mused_preview)
      why <- c(why, "MUSED minimum training or reporting requirements not met")
    if (!length(why)) {
      # Use the registry identifier, not a user-supplied path, to prevent file
      # traversal and make the app independent of where the project is installed.
      model_file <- file.path(root, "data", "ml_models", paste0(row$task_id, ".rds"))
      if (!file.exists(model_file)) {
        why <- c(why, "Model file missing")
      } else {
        bundle <- tryCatch(readRDS(model_file), error = function(e) e)
        if (inherits(bundle, "error") || !is.list(bundle) ||
            is.null(bundle$model) || is.null(bundle$blueprint) ||
            is.null(bundle$features) || !identical(bundle$task_id, row$task_id)) {
          why <- c(why, "Saved model unreadable or inconsistent")
        } else if (length(bundle$algorithm) != 1L ||
                   !bundle$algorithm %in% c("ridge", "elastic_net", "random_forest")) {
          why <- c(why, "Unsupported learner")
        } else if (bundle$algorithm %in% c("ridge", "elastic_net") &&
                   !requireNamespace("glmnet", quietly = TRUE)) {
          why <- c(why, "Install glmnet to load this model")
        } else if (bundle$algorithm == "random_forest" &&
                   !requireNamespace("ranger", quietly = TRUE)) {
          why <- c(why, "Install ranger to load this model")
        } else if (!all(bundle$features %in% names(bundle$blueprint))) {
          why <- c(why, "Model feature blueprint is incomplete")
        } else {
          bundles[[row$task_id]] <- bundle
        }
      }
    }
    d$eligible[i] <- !length(why)
    d$quality_tier[i] <- if (length(why)) "Unavailable" else if (length(quality_issues))
      "Exploratory MUSED" else "Internally screened"
    d$screen_reason[i] <- if (length(why)) paste(why, collapse = "; ") else if (length(quality_issues))
      paste("Priority-study exploratory preview:", paste(quality_issues, collapse = "; ")) else
      "Passed internal display screen"
  }
  list(all = d, eligible = d[d$eligible, , drop = FALSE], bundles = bundles,
       warning = "")
}

filter_prediction_catalog <- function(eligible, selected_studies) {
  if (!nrow(eligible) || !length(selected_studies)) return(eligible[FALSE, , drop = FALSE])
  keep <- vapply(seq_len(nrow(eligible)), function(i) {
    r <- eligible[i, ]
    if (r$study != "Pooled exploratory") return(r$study %in% selected_studies)
    required <- switch(r$domain, Depression = c("MUSED", "MIDDEL"),
      Stress = c("MUSED", "Finnerty & Trainor"), character())
    length(required) > 0 && all(required %in% selected_studies)
  }, logical(1))
  eligible[keep, , drop = FALSE]
}

prediction_feature_label <- function(f) {
  lookup <- c(age = "Age (years)", bmi = "Body mass index (BMI)",
    gender = "Gender in source data", sex = "Sex in source data",
    birth_year = "Year of birth", childhood_trauma = "Childhood trauma score (CTQ)",
    baseline_hrv = "Baseline HRV mesor", emotional_stability = "Emotional stability score",
    other_baseline_depression = "Baseline depression score (other instrument)",
    choir = "Randomized choir condition (0 = no, 1 = yes)",
    study_label = "Source trial / population", expectation = "Baseline expectation",
    education = "Education", diagnosis = "Diagnosis category")
  if (f %in% names(lookup)) return(unname(lookup[[f]]))
  out <- gsub("[._]", " ", sub("^baseline_", "Baseline ", f))
  tools::toTitleCase(out)
}

prediction_feature_id <- function(i) paste0("pred_feature_", i)

# Display-only translations: the SELECT VALUES remain the original Spanish
# strings, so existing RDS blueprints receive exactly what they were trained on.
# Never recode model inputs without retraining the models.
prediction_category_label <- function(study, feature, value) {
  if (value == "(missing)") return("Not recorded")
  if (study != "Esteban-Cárdenas") return(value)
  translations <- switch(feature,
    gender = c(Femenino = "Female", Masculino = "Male"),
    education = c(
      "Postgrado" = "Postgraduate degree",
      "Universitario incompleto" = "Incomplete university education",
      "Universitario completo" = "Completed university education",
      "Secundaria completa" = "Completed secondary education",
      "Secundaria incompleta" = "Incomplete secondary education",
      "Técnico o tecnológico" = "Technical or vocational education"),
    diagnosis = c(
      "Depresivo" = "Depressive disorder",
      "Bipolaridad" = "Bipolar disorder",
      "Ansioso o relacionado a estrés" = "Anxiety or stress-related disorder",
      "Psicosis" = "Psychotic disorder",
      "Otros" = "Other diagnosis"),
    expectation = c(
      "Muy positiva" = "Very positive",
      "Positiva" = "Positive",
      "Neutral" = "Neutral"),
    NULL)
  if (!is.null(translations) && value %in% names(translations))
    return(unname(translations[[value]]))
  value
}

prediction_form <- function(bundle) {
  widgets <- list()
  if (is.finite(bundle$baseline_sd) && is.finite(bundle$baseline_mean)) {
    widgets[[length(widgets) + 1L]] <- shiny::div(class = "pred-field",
      title = paste("Original scale at baseline for", bundle$outcome,
                    "(used to calculate the standardized baseline input)."),
      shiny::numericInput("pred_baseline", paste("Baseline", bundle$outcome, "(original units)"),
                          value = round(bundle$baseline_mean, 2), step = 0.5))
  } else {
    widgets[[length(widgets) + 1L]] <- shiny::div(class = "pred-field",
      title = "Baseline score relative to the mean and standard deviation within the original study.",
      shiny::numericInput("pred_baseline", "Baseline score (study-standardized z value)",
                          value = 0, step = 0.1))
  }
  for (i in seq_along(bundle$features)) {
    f <- bundle$features[[i]]
    if (f == "baseline_z") next
    p <- bundle$blueprint[[f]]
    lbl <- prediction_feature_label(f)
    id <- prediction_feature_id(i)
    if (f == "choir") {
      ctrl <- shiny::selectInput(id, lbl, choices = c("No choir / not applicable" = "0",
                                                           "Choir assigned" = "1"), selected = "0")
    } else if (p$type == "numeric") {
      default <- if (is.finite(p$median)) round(p$median, 2) else 0
      ctrl <- shiny::numericInput(id, lbl, value = default,
                                  step = if (grepl("age|year", f)) 1 else 0.1)
    } else {
      levels <- as.character(p$levels)
      names_english <- vapply(levels,
        function(v) prediction_category_label(bundle$study, f, v), character(1))
      ctrl <- shiny::selectInput(id, lbl,
        choices = setNames(levels, make.unique(names_english)), selected = levels[1])
    }
    widgets[[length(widgets) + 1L]] <- shiny::div(class = "pred-field",
      title = paste("Pre-treatment predictor:", lbl, ". Initial values use training-set medians or common categories; replace them with your actual scenario."),
      ctrl)
  }
  shiny::div(class = "pred-input-grid", widgets)
}

prediction_profile <- function(bundle, input) {
  baseline <- suppressWarnings(as.numeric(input$pred_baseline))
  if (length(baseline) != 1L || !is.finite(baseline)) stop("Enter a finite baseline value.")
  if (is.finite(bundle$baseline_sd) && bundle$baseline_sd > 0 &&
      is.finite(bundle$baseline_mean)) {
    baseline_z <- (baseline - bundle$baseline_mean) / bundle$baseline_sd
  } else {
    baseline_z <- baseline
  }
  profile <- data.frame(baseline_z = baseline_z)
  for (i in seq_along(bundle$features)) {
    f <- bundle$features[[i]]
    if (f == "baseline_z") next
    val <- input[[prediction_feature_id(i)]]
    if (is.null(val) || length(val) != 1L) stop("Specify ", prediction_feature_label(f), ".")
    if (bundle$blueprint[[f]]$type == "numeric") {
      val <- suppressWarnings(as.numeric(val))
      if (!is.finite(val)) stop("Enter a finite value for ", prediction_feature_label(f), ".")
    } else {
      val <- as.character(val)
      if (!val %in% bundle$blueprint[[f]]$levels)
        stop("Invalid category for ", prediction_feature_label(f), ".")
    }
    profile[[f]] <- val
  }
  # Other trials never randomized choir; restrict pooled profiles to valid
  # combinations rather than allowing fictional trial assignments.
  if (bundle$study == "Pooled exploratory" && "choir" %in% names(profile) &&
      "study_label" %in% names(profile) && profile$study_label != "MIDDEL")
    profile$choir <- 0
  profile
}

prediction_extrapolation <- function(bundle, profile) {
  far <- character()
  if (abs(profile$baseline_z) > 3) far <- c(far, "baseline outcome")
  for (f in setdiff(bundle$features, "baseline_z")) {
    p <- bundle$blueprint[[f]]
    if (p$type == "numeric" && is.finite(p$sd) && p$sd > 0 &&
        abs((as.numeric(profile[[f]]) - p$mean) / p$sd) > 3)
      far <- c(far, prediction_feature_label(f))
  }
  far
}

prediction_sensitivity <- function(bundle, profile, half_width = 1.5) {
  x <- seq(profile$baseline_z - half_width, profile$baseline_z + half_width, length.out = 41L)
  grid <- profile[rep(1L, length(x)), , drop = FALSE]
  grid$baseline_z <- x
  control <- predict_candidate(bundle, grid, treatment_override = 0)
  active <- predict_candidate(bundle, grid, treatment_override = 1)
  horizontal <- if (is.finite(bundle$baseline_mean) && is.finite(bundle$baseline_sd))
    bundle$baseline_mean + bundle$baseline_sd * x else x
  data.frame(baseline = horizontal, predicted_benefit = active - control,
             treated = active, control = control)
}

prediction_treatment_diagnostic <- function(bundle) {
  if (bundle$algorithm %in% c("ridge", "elastic_net")) {
    cf <- tryCatch(stats::coef(bundle$model, s = "lambda.1se"), error = function(e) NULL)
    if (!is.null(cf)) {
      names <- rownames(cf)
      relevant <- which(names == "treatment" | startsWith(names, "tr_x_"))
      if (length(relevant) && all(abs(as.numeric(cf[relevant, 1])) < 1e-10))
        return(paste(
          "All treatment-related coefficients in this saved model are zero at",
          "the selected regularization strength. It therefore produces the",
          "same prediction for both arms at every baseline profile.",
          "This reflects the fitted model, not an interface error.",
          "Re-run training with the updated learner if you want to evaluate",
          "an unpenalized main treatment contrast."
        ))
    }
    return(paste(
      "The fitted treatment terms produce no difference at this profile.",
      "This does not prove that music therapy has no effect."
    ))
  }
  paste("The fitted model yields equivalent outcomes for these two hypothetical",
        "arms at the selected profile; this is not evidence of no therapy effect.")
}
