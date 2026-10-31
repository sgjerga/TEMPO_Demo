# Run from the ResonanceAtlas/ root after training:
#   source("tests/prediction_smoke_test.R")
# This validates the saved-model interface without retraining.

source(file.path("R", "prediction_view.R"))
source(file.path("machine_learning_analysis", "01_build_tasks.R"))
stopifnot(identical(binary_01(c("SC", "GMT")), c(0, 1)),
          identical(binary_01(c("SC", "RCS")), c(0, 1)))
app_lines <- readLines("app.R", warn = FALSE)
stopifnot(any(grepl('tabPanel("04  Integration"', app_lines, fixed = TRUE)),
          any(grepl('actionButton("pred_run"', app_lines, fixed = TRUE)),
          any(grepl('eventReactive(input$pred_run', app_lines, fixed = TRUE)))
stopifnot(
  prediction_category_label("Esteban-Cárdenas", "gender", "Femenino") == "Female",
  prediction_category_label("Esteban-Cárdenas", "education", "Técnico o tecnológico") ==
    "Technical or vocational education",
  prediction_category_label("Esteban-Cárdenas", "diagnosis", "Depresivo") ==
    "Depressive disorder",
  prediction_category_label("Esteban-Cárdenas", "expectation", "Muy positiva") ==
    "Very positive",
  prediction_category_label("MUSED", "gender", "Femenino") == "Femenino"
)
catalog <- read_prediction_catalog()
if (nzchar(catalog$warning)) {
  message("Prediction catalogue not yet ready: ", catalog$warning)
} else {
  stopifnot(is.data.frame(catalog$eligible), is.data.frame(catalog$all))
  message(sprintf("Prediction catalogue: %d/%d models passed the research-only screen.",
                  nrow(catalog$eligible), nrow(catalog$all)))
  message(sprintf("Saved training reports flag %d model(s) with zero arm contrast.",
                  sum(catalog$all$flat_treatment_contrast)))
  for (i in seq_len(nrow(catalog$eligible))) {
    id <- catalog$eligible$task_id[i]
    bundle <- catalog$bundles[[id]]
    stopifnot(identical(bundle$task_id, id),
              all(bundle$features %in% names(bundle$blueprint)))
    # Supply a plausible baseline profile with fold-fitted median/mode inputs.
    d <- data.frame(baseline_z = 0)
    for (f in setdiff(bundle$features, "baseline_z")) {
      p <- bundle$blueprint[[f]]
      d[[f]] <- if (p$type == "numeric") p$median else p$levels[1]
    }
    a <- predict_candidate(bundle, d, treatment_override = 1)
    b <- predict_candidate(bundle, d, treatment_override = 0)
    curve <- prediction_sensitivity(bundle, d)
    stopifnot(length(a) == 1L, length(b) == 1L,
              all(is.finite(c(a, b, curve$predicted_benefit))), nrow(curve) == 41L)
    message("PASS: ", id)
  }
}
message("PASS: prediction-tab model catalogue and available scorers checked.")
