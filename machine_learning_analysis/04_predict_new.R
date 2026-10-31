# Use with bundles saved under ../data/ml_models/ for the future Shiny tab.
# Do NOT source 03_run_all.R; loading a saved model does not retrain it.

if (!exists("predict_candidate", mode = "function")) {
  if (!exists("ml_config")) source("00_config.R")
  source("02_model_engine.R")
}

load_predictor <- function(task_id) {
  path <- file.path(ml_config$models_dir, paste0(task_id, ".rds"))
  if (!file.exists(path)) stop("No saved model: ", path)
  readRDS(path)
}

predict_response <- function(bundle, new_profiles) {
  d <- as.data.frame(new_profiles)
  if (!"baseline_z" %in% names(d)) {
    if (!"baseline" %in% names(d) || !is.finite(bundle$baseline_sd))
      stop("Provide baseline_z, or baseline in original units for a single-study model.")
    d$baseline_z <- (d$baseline - bundle$baseline_mean) / bundle$baseline_sd
  }
  missing <- setdiff(bundle$features, names(d))
  if (length(missing)) stop("Provide baseline predictors: ", paste(missing, collapse = ", "))
  # Estimates on the standardized *favorable change* scale.
  pred_control <- predict_candidate(bundle, d, treatment_override = 0)
  pred_treated <- predict_candidate(bundle, d, treatment_override = 1)
  tau <- pred_treated - pred_control
  out <- data.frame(predicted_change_control_sd = pred_control,
    predicted_change_music_therapy_sd = pred_treated,
    conditional_benefit_sd = tau)
  if (is.finite(bundle$baseline_sd) && is.finite(bundle$direction))
    out$conditional_post_score_difference_original_units <-
      bundle$direction * bundle$baseline_sd * tau
  attr(out, "warning") <- "Conditional model contrasts are exploratory, NOT validated individual treatment effects."
  out
}

predict_causal_forest <- function(task_id, new_profiles) {
  if (!requireNamespace("grf", quietly = TRUE)) stop("Install grf for causal forest predictions")
  path <- file.path(ml_config$models_dir, paste0(task_id, "_causal_forest.rds"))
  fit <- readRDS(path)
  x <- baseline_matrix(as.data.frame(new_profiles), fit$blueprint)
  p <- grf::predict(fit$model, newdata = x, estimate.variance = TRUE)
  data.frame(conditional_benefit_sd = as.numeric(p$predictions),
    approximate_se = if (!is.null(p$variance.estimates)) sqrt(as.numeric(p$variance.estimates)) else NA_real_)
}

# Example after training:
# model <- load_predictor("mused_depression_bdi_depression")
# model$features  # inspect the exact baseline inputs expected
# predict_response(model, profiles) # supply all baseline fields in model$features
