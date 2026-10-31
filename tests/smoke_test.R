# Run from the ResonanceAtlas folder:
#   Rscript tests/smoke_test.R
# Or within RStudio:
#   source("tests/smoke_test.R")

library(dplyr)
library(tidyr)
library(tibble)
library(readxl)

source(file.path("R", "data_pipeline.R"))
source(file.path("R", "model.R"))

atlas <- load_atlas()
effects <- build_effects(atlas)

stopifnot(
  length(unique(atlas$long$study)) == 5L,
  all(c("MUSED", "MIDDEL", "Finnerty & Trainor", "Esteban-Cárdenas", "Yu, Lee & Lu") %in% atlas$long$study),
  sum(effects$study == "MIDDEL") >= 3L,
  all(is.finite(effects$estimate)),
  all(is.finite(effects$se)),
  all(effects$se > 0)
)

for (domain in unique(effects$domain)) {
  result <- pool_effects(effects[effects$domain == domain, , drop = FALSE])
  stopifnot(!is.null(result), is.finite(result$mu), is.finite(result$se))
}

cat("PASS: 5 studies loaded; ", nrow(atlas$long), " observed records; ",
    nrow(effects), " estimable study-domain effects.\n", sep = "")
