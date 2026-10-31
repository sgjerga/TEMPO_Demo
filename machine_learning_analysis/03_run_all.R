# Entry point. Set working directory to machine_learning_analysis/ and run:
#   source("03_run_all.R")

source("00_config.R")
source("01_build_tasks.R")
source("02_model_engine.R")

cat("\n=== TEMPO: baseline-only predictive modelling ===\n")
cat("Using raw data from: ", normalizePath(ml_config$source_dir), "\n", sep = "")
cat("Models will be saved in: ", normalizePath(ml_config$models_dir), "\n", sep = "")

tasks <- build_all_tasks()
if (!length(tasks)) stop("No modelling datasets were constructed.")

audit <- dplyr::bind_rows(lapply(tasks, function(t) {
  d <- t$data
  data.frame(task_id = t$id, study = t$study, domain = t$domain, outcome = t$outcome,
    design = t$design, endpoint = t$timepoint,
    n = nrow(d), n_treated = sum(d$treatment == 1),
    n_control = sum(d$treatment == 0), n_clusters = length(unique(d$cluster)),
    features = paste(t$features, collapse = "; "), contrast = t$contrast)
}))
write_report(audit, "task_audit.csv")

registries <- list(); candidates <- list(); summaries <- list(); forests <- list()
for (i in seq_along(tasks)) {
  t <- tasks[[i]]
  cat(sprintf("[%d/%d] %s | %s | n=%d\n", i, length(tasks), t$study, t$domain, nrow(t$data)))
  res <- tryCatch(fit_one_task(t), error = function(e) e)
  if (inherits(res, "error")) {
    registries[[length(registries) + 1L]] <- data.frame(
      task_id = t$id, study = t$study, domain = t$domain, outcome = t$outcome,
      comparison = t$contrast, timepoint = t$timepoint, design = t$design,
      n = nrow(t$data), n_treated = sum(t$data$treatment == 1),
      n_control = sum(t$data$treatment == 0), n_clusters = length(unique(t$data$cluster)),
      status = "ERROR", algorithm = NA_character_, cv_rmse = NA_real_,
      cv_mae = NA_real_, cv_r2 = NA_real_, model_path = NA_character_,
      message = conditionMessage(res))
    warning("Training issue in ", t$id, ": ", conditionMessage(res))
    next
  }
  registries[[length(registries) + 1L]] <- res$registry
  if (!is.null(res$candidate_metrics)) candidates[[length(candidates) + 1L]] <- res$candidate_metrics
  if (!is.null(res$prediction_summary)) summaries[[length(summaries) + 1L]] <- res$prediction_summary
  # Forests are supplementary CATE models, not selected by factual RMSE.
  if (res$registry$status == "TRAINED") {
    cf <- tryCatch(fit_optional_causal_forest(t), error = function(e)
      data.frame(task_id = t$id, status = "CAUSAL_FOREST_FAILED", message = conditionMessage(e)))
    if (!is.null(cf)) forests[[length(forests) + 1L]] <- cf
  }
}

registry <- dplyr::bind_rows(registries)
write_report(registry, "model_registry.csv")
write_report(dplyr::bind_rows(candidates), "cv_candidate_metrics.csv")
write_report(dplyr::bind_rows(summaries), "prediction_summaries.csv")
write_report(dplyr::bind_rows(forests), "causal_forest_registry.csv")

cat("\n=== Finished ===\n")
print(registry[, c("study", "domain", "n", "status", "algorithm", "cv_rmse")], row.names = FALSE)
cat("\nTrained: ", sum(registry$status == "TRAINED"), "/", nrow(registry),
    ". See ../data/ml_reports/model_registry.csv for skipped tasks and caveats.\n", sep = "")
cat("No models were inserted into the Shiny interface. The later Predictions tab\n",
    "can use the saved .rds bundles via 04_predict_new.R.\n", sep = "")
