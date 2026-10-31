# TEMPO_Demo: create the Posit Connect Cloud manifest.json
#
# 1. Download this file into the TOP LEVEL of https://github.com/sgjerga/TEMPO_Demo
#    alongside app.R (or into your local checkout of that repository).
# 2. In RStudio, open the TEMPO_Demo project folder and run:
#      source("generate_tempo_manifest.R")
#    Alternatively, in a terminal from the repo root:
#      Rscript generate_tempo_manifest.R
# 3. Commit and push the generated manifest.json to the repo root.
#
# The manifest records REAL installed package versions and the R version.
# Do not hand-edit it or run this script on Posit Connect Cloud.

repo_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_dir, "app.R"))) {
  stop("Run this script with your working directory set to TEMPO_Demo/ (where app.R lives).")
}

# TEMPO Shiny runtime dependencies, based on app.R, R/ and the scoring engine.
# 'ranger' supports random-forest models. 'grf' is training-only, but
# rsconnect's static dependency detector sees the grf:: call inside the
# shared model engine, so it must be installed to create this manifest.
runtime_packages <- c(
  "shiny", "bslib", "dplyr", "tidyr", "tibble", "ggplot2",
  "plotly", "DT", "readxl", "scales", "glmnet", "ranger", "grf"
)

options(repos = c(CRAN = "https://cloud.r-project.org"))
needed <- c("rsconnect", runtime_packages)
installed <- rownames(utils::installed.packages())
missing <- setdiff(needed, installed)
if (length(missing)) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  utils::install.packages(missing, dependencies = NA)
}

still_missing <- setdiff(needed, rownames(utils::installed.packages()))
if (length(still_missing)) {
  stop("Could not install: ", paste(still_missing, collapse = ", "),
       ". Install these in R and rerun this script.")
}

# Explicitly include only TEMPO's runtime inputs. By default rsconnect scans
# every .R file in a repo, including ML *training* scripts and copied source-
# study scripts, which could add many unnecessary cloud dependencies.
required_dirs <- c("R", "www", "data/src_integrative", "data/ml_models",
                   "data/ml_reports")
missing_dirs <- required_dirs[!dir.exists(file.path(repo_dir, required_dirs))]
if (length(missing_dirs)) {
  stop("Missing TEMPO runtime directories: ",
       paste(missing_dirs, collapse = ", "))
}

scoring_engine <- "machine_learning_analysis/02_model_engine.R"
if (!file.exists(file.path(repo_dir, scoring_engine))) {
  stop("Missing scoring engine: ", scoring_engine)
}

runtime_files <- c("app.R", scoring_engine)
for (folder in required_dirs) {
  entries <- list.files(folder, recursive = TRUE, full.names = TRUE,
                        all.files = FALSE, include.dirs = FALSE)
  entries <- entries[file.exists(entries) & !dir.exists(entries)]
  # Study deposits also contain their authors' unrelated analysis scripts.
  # The Shiny app reads the exported datasets, not those analysis scripts.
  # Exclude them from deployment/dependency scanning to keep cloud builds lean.
  if (identical(folder, "data/src_integrative")) {
    entries <- entries[!grepl("\\.[Rr]$", entries)]
  }
  runtime_files <- c(runtime_files, entries)
}
runtime_files <- unique(runtime_files)

# The data files and pre-trained model bundles are part of this Shiny app's
# runtime; the app cannot display its studies or models without them.
required_inputs <- c(
  "R/data_pipeline.R", "R/model.R", "R/prediction_view.R",
  "data/ml_reports/model_registry.csv"
)
absent <- required_inputs[!file.exists(required_inputs)]
if (length(absent)) {
  stop("Missing required app file(s): ", paste(absent, collapse = ", "))
}

message("Found ", length(runtime_files), " runtime files. Scanning R dependencies...")
dependencies <- rsconnect::appDependencies(
  appDir = repo_dir,
  appFiles = runtime_files,
  appMode = "shiny",
  dependencyResolution = "library"
)

# Confirm that the essential packages were actually discovered.
essential <- c("shiny", "bslib", "dplyr", "tidyr", "tibble", "ggplot2",
               "plotly", "DT", "readxl", "scales", "glmnet")
not_detected <- setdiff(essential, dependencies$Package)
if (length(not_detected)) {
  stop("Dependency scanning did not detect: ",
       paste(not_detected, collapse = ", "),
       ". Check your app's source files before deploying.")
}

message("Generating manifest.json from your installed R environment...")
rsconnect::writeManifest(
  appDir = repo_dir,
  appFiles = runtime_files,
  appMode = "shiny",
  dependencyResolution = "library"
)

manifest_path <- file.path(repo_dir, "manifest.json")
if (!file.exists(manifest_path) || file.info(manifest_path)$size < 100) {
  stop("manifest.json was not generated successfully.")
}
message("SUCCESS: ", manifest_path)
message("R: ", as.character(getRversion()), " | scanned R packages: ", nrow(dependencies))
message("Commit manifest.json beside app.R, push to main, and redeploy on Connect Cloud.")
message("If you change R/package versions or runtime files, rerun this script and commit the new manifest.")
