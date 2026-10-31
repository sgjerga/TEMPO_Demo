# Run scripts with the working directory set to machine_learning_analysis/.
ml_config <- list(
  seed = 20261031L,
  min_n = 35L,
  min_arm_n = 10L,
  min_clusters_per_arm = 3L,
  outer_folds = 5L,
  inner_folds = 4L,
  ranger_min_n = 90L,
  grf_min_n = 250L,
  grf_min_clusters = 20L,
  fit_causal_forest = TRUE,       # optional exploratory CATE model
  fit_pooled = TRUE,              # exploratory cross-study S-learner
  save_participant_predictions = FALSE, # privacy-conscious default
  data_dir = file.path("..", "data"),
  source_dir = file.path("..", "data", "src_integrative"),
  models_dir = file.path("..", "data", "ml_models"),
  reports_dir = file.path("..", "data", "ml_reports")
)

required_packages <- c("dplyr", "tidyr", "tibble", "readxl", "glmnet")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace,
                                              logical(1), quietly = TRUE)]
if (length(missing_packages)) stop(
  "Install these packages first: install.packages(c(",
  paste(sprintf('"%s"', missing_packages), collapse = ", "), "))"
)
if (!file.exists(file.path("..", "R", "data_pipeline.R")))
  stop("Run from the machine_learning_analysis/ directory inside TEMPO.")

dir.create(ml_config$models_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(ml_config$reports_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path("..", "R", "data_pipeline.R"))
set.seed(ml_config$seed)

safe_id <- function(s) {
  x <- gsub("[^a-z0-9]+", "_", tolower(iconv(s, to = "ASCII//TRANSLIT")))
  gsub("^_+|_+$", "", x)
}

read_source_csv <- function(rel) {
  d <- utils::read.csv(file.path(ml_config$source_dir, rel), check.names = FALSE)
  n <- names(d)
  blank <- is.na(n) | !nzchar(trimws(n))
  n[blank] <- paste0("unnamed_", which(blank))
  names(d) <- make.unique(n)
  d
}

write_report <- function(d, file) {
  utils::write.csv(d, file.path(ml_config$reports_dir, file), row.names = FALSE, na = "")
}
