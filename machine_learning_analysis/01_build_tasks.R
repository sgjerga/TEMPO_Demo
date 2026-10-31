# Builds one analysis dataset per study/domain, with strictly baseline features.
# Source the app's established study mappings so arms/scales are identical.

binary_01 <- function(x) {
  v <- tolower(trimws(as.character(x)))
  # MIDDEL's public ANCOVA scripts explicitly use a factor contrast GMT2:
  # randomized factors are coded 1 = absent, 2 = present. This is DIFFERENT
  # from the usual numeric 0/1 scheme; interpreting 1 as treated loses an arm.
  present <- unique(v[!is.na(v) & nzchar(v)])
  if (length(present) && all(present %in% c("1", "2")) && "2" %in% present)
    return(ifelse(v == "2", 1, ifelse(v == "1", 0, NA_real_)))
  ans <- rep(NA_real_, length(v))
  # The included international MIDDEL RData actually encodes its arms as
  # SC/GMT (and SC/RCS), as recorded by the user's import diagnostics.
  ans[v %in% c("0", "false", "no", "control", "no gmt", "no rcs",
                  "sc", "standard care")] <- 0
  ans[v %in% c("1", "true", "yes", "gmt", "rcs")] <- 1
  ans
}

baseline_feature_table <- function(atlas, study) {
  d <- atlas$long |>
    dplyr::filter(.data$study == .env$study, as.character(time) == "Baseline") |>
    dplyr::group_by(participant, outcome) |>
    dplyr::summarise(value = mean(value), .groups = "drop") |>
    tidyr::pivot_wider(names_from = outcome, values_from = value, names_prefix = "baseline_")
  names(d) <- make.names(names(d), unique = TRUE)
  d
}

baseline_covariates <- function(study) {
  if (study == "MUSED") {
    d <- read_source_csv("MUSED/MUSED_main_2024-11-03.csv")
    return(data.frame(participant = as.character(d$id), age = d$age, bmi = d$bmi,
                      childhood_trauma = d$CTQ, baseline_hrv = d$HRV_mesor_pre))
  }
  if (study == "Finnerty & Trainor") {
    d <- readxl::read_excel(file.path(ml_config$source_dir,
      "Finnerty/OSF_WEEK1_6_All_Data.xlsx"), .name_repair = "unique")
    return(data.frame(participant = as.character(d[["ID #"]]),
      gender = as.character(d$Gender), birth_year = suppressWarnings(as.numeric(d[["Year of Birth"]])),
      extraversion = d$Extroversion, agreeableness = d$Agreeableness,
      conscientiousness = d$Conscientiousness,
      emotional_stability = d[["Emotional Stability"]], openness = d$Openness))
  }
  if (study == "Esteban-Cárdenas") {
    d <- read_source_csv("Esteban_Cardenas/Base Music Therapy Psychiatry 2024.csv")
    return(data.frame(participant = as.character(d$ID), age = d$Edad,
      gender = as.character(d$Genero), education = as.character(d$Escolaridad),
      diagnosis = as.character(d[["Eje diagnóstico"]]), expectation = as.character(d$Expectativa)))
  }
  if (study == "Yu, Lee & Lu") {
    d <- readxl::read_excel(file.path(ml_config$source_dir,
      "Yu_Lee_Lu/5.1_84703393_2_MT tele-intervention III-I pre-test_15_15.xlsx"))
    return(data.frame(participant = as.character(d[["Participant No."]]),
                      age = d$Age, gender = as.character(d$Gender)))
  }
  data.frame(participant = character())
}

make_task <- function(d, study, domain, outcome, contrast, direction,
                      feature_cols, design, timepoint = "Post") {
  d <- as.data.frame(d)
  d <- d[is.finite(d$baseline) & is.finite(d$post) & !is.na(d$treatment), , drop = FALSE]
  # No duplicate longitudinal records can cross folds.
  if (anyDuplicated(d$participant)) stop("Duplicated participant in ", study, " / ", outcome)
  scale_sd <- stats::sd(d$baseline)
  scale_mean <- mean(d$baseline)
  if (!is.finite(scale_sd) || scale_sd <= 0 || !nrow(d)) return(NULL)
  d$baseline_z <- (d$baseline - scale_mean) / scale_sd
  d$y <- direction * (d$post - d$baseline) / scale_sd
  feature_cols <- unique(c("baseline_z", intersect(feature_cols, names(d))))
  feature_cols <- feature_cols[vapply(d[feature_cols], function(x)
    sum(!is.na(x) & (if (is.numeric(x)) is.finite(x) else nzchar(as.character(x)))) >= 0.5 * nrow(d), logical(1))]
  feature_cols <- unique(c("baseline_z", feature_cols))
  d <- d[, unique(c("participant", "cluster", "treatment", "y", "baseline", "post",
                    "baseline_z", feature_cols)), drop = FALSE]
  list(id = safe_id(paste(study, domain, outcome, sep = "_")),
       study = study, domain = domain, outcome = outcome, contrast = contrast,
       timepoint = timepoint, design = design, data = d, features = feature_cols,
       baseline_mean = scale_mean, baseline_sd = scale_sd, direction = direction,
       grouped = design %in% c("Cluster randomized", "Exploratory pooled"))
}

build_individual_tasks <- function(atlas) {
  tasks <- list()
  specs <- atlas$primary
  for (i in seq_len(nrow(specs))) {
    s <- specs[i, ]
    wide <- atlas$long |>
      dplyr::filter(study == s$study, outcome == s$outcome,
                    arm %in% c(s$treated, s$control),
                    as.character(time) %in% c("Baseline", "Post")) |>
      dplyr::mutate(time = as.character(time)) |>
      dplyr::select(participant, arm, time, value) |>
      dplyr::distinct(participant, arm, time, .keep_all = TRUE) |>
      tidyr::pivot_wider(names_from = time, values_from = value)
    if (!all(c("Baseline", "Post") %in% names(wide))) next
    names(wide)[names(wide) == "Baseline"] <- "baseline"
    names(wide)[names(wide) == "Post"] <- "post"
    wide$treatment <- as.numeric(wide$arm == s$treated)
    wide$cluster <- paste0(s$study, "_", wide$participant)
    extra <- baseline_covariates(s$study)
    if (nrow(extra)) wide <- dplyr::left_join(wide, extra, by = "participant")
    others <- baseline_feature_table(atlas, s$study)
    if (nrow(others)) wide <- dplyr::left_join(wide, others, by = "participant")
    redundant <- make.names(paste0("baseline_", s$outcome))
    predictors <- setdiff(names(wide), c("participant", "cluster", "treatment", "arm",
      "baseline", "post", redundant))
    target_direction <- unique(atlas$long$direction[
      atlas$long$study == s$study & atlas$long$outcome == s$outcome])
    if (length(target_direction) != 1L) next
    task <- make_task(wide, s$study, s$domain, s$outcome, s$contrast,
                      target_direction, predictors, "Individual randomized")
    if (!is.null(task)) tasks[[task$id]] <- task
  }
  tasks
}

build_middel_international_tasks <- function() {
  zip <- file.path(ml_config$source_dir, "MIDDEL/International results/rproject_middel_public_251126.zip")
  member <- "rproject_middel_public/data/data_public.rdata"
  temp <- tempfile("middel_training_")
  dir.create(temp)
  utils::unzip(zip, files = member, exdir = temp, junkpaths = TRUE)
  target <- file.path(temp, "data_public.rdata")
  if (!file.exists(target))
    stop("Unable to extract the MIDDEL participant-level RData from the supplied archive")
  env <- new.env(parent = baseenv())
  load(target, envir = env)
  if (!exists("df.resident.wide", envir = env, inherits = FALSE) ||
      !exists("ovars", envir = env, inherits = FALSE))
    stop("MIDDEL international archive lacks expected df.resident.wide / ovars objects")
  d <- as.data.frame(get("df.resident.wide", envir = env))
  ovars <- as.character(get("ovars", envir = env))
  required <- c("rand.gmt", "rand.rcs", "rv")
  if (!all(required %in% names(d)))
    stop("MIDDEL international records lack: ", paste(setdiff(required, names(d)), collapse = ", "))
  gmt <- binary_01(d$rand.gmt)
  rcs <- binary_01(d$rand.rcs)
  if (!all(c(0, 1) %in% unique(gmt)))
    stop("Could not decode both MIDDEL GMT arms; inspect rand.gmt levels: ",
         paste(unique(as.character(d$rand.gmt)), collapse = ", "))
  if (!all(c(0, 1) %in% unique(rcs)))
    stop("Could not decode both MIDDEL choir arms; inspect rand.rcs levels: ",
         paste(unique(as.character(d$rand.rcs)), collapse = ", "))
  specs <- list(
    list(i = 1, domain = "Depression", name = "MADRS depression", direction = -1),
    list(i = 2, domain = "Cognition", name = "SIB-8 cognition", direction = 1),
    list(i = 3, domain = "Neuropsychiatric", name = "NPI symptom severity", direction = -1),
    list(i = 5, domain = "Quality of life", name = "EQ-VAS health status", direction = 1)
  )
  tasks <- list()
  for (s in specs) {
    if (length(ovars) < s$i) next
    key <- ovars[s$i]
    pre <- paste0(key, ".0"); post <- paste0(key, ".6")
    if (!all(c(pre, post) %in% names(d))) next
    z <- data.frame(participant = paste0("MIDDEL_", seq_len(nrow(d))),
      cluster = paste0("MIDDEL_unit_", as.character(d$rv)),
      treatment = gmt, choir = rcs,
      baseline = suppressWarnings(as.numeric(as.character(d[[pre]]))),
      post = suppressWarnings(as.numeric(as.character(d[[post]]))))
    additional <- intersect(c("age", "sex", "marit", "country", "mmse"), names(d))
    for (nm in additional) z[[nm]] <- d[[nm]]
    # Baseline depressive symptom burden may predict other MIDDEL modalities.
    if (s$i != 1 && paste0(ovars[1], ".0") %in% names(d))
      z$other_baseline_depression <- suppressWarnings(as.numeric(as.character(d[[paste0(ovars[1], ".0")]])))
    task <- make_task(z, "MIDDEL", s$domain, s$name,
      "Factorial GMT vs no GMT; choir randomized independently", s$direction,
      setdiff(names(z), c("participant", "cluster", "treatment", "baseline", "post")),
      "Cluster randomized", timepoint = "6 months")
    if (!is.null(task)) tasks[[task$id]] <- task
  }
  tasks
}

build_pooled_tasks <- function(tasks) {
  out <- list()
  if (!isTRUE(ml_config$fit_pooled)) return(out)
  # Only domains shared by ≥2 trials with an MT-availability contrast;
  # exclude Esteban's active-dose design and the tiny Yu pilot.
  use <- Filter(function(x) x$study %in% c("MUSED", "Finnerty & Trainor", "MIDDEL"), tasks)
  for (domain in c("Depression", "Stress")) {
    part <- Filter(function(x) identical(x$domain, domain), use)
    if (length(unique(vapply(part, `[[`, character(1), "study"))) < 2L) next
    blocks <- lapply(part, function(t) {
      z <- t$data[, c("participant", "cluster", "treatment", "y", "baseline_z"), drop = FALSE]
      z$study_label <- t$study
      z$choir <- if ("choir" %in% names(t$data)) t$data$choir else 0
      z
    })
    d <- dplyr::bind_rows(blocks)
    # Already standardized within each study; the relative benefit score is
    # comparable for exploratory modelling, NOT a validated latent scale.
    out[[paste0("pooled_", safe_id(domain))]] <- list(
      id = paste0("pooled_", safe_id(domain)), study = "Pooled exploratory",
      domain = domain, outcome = "Study-standardized domain change",
      contrast = "Heterogeneous trial-specific MT-vs-no-MT comparisons",
      timepoint = "Study-specific post-treatment window", design = "Exploratory pooled",
      data = d, features = c("baseline_z", "study_label", "choir"),
      baseline_mean = NA_real_, baseline_sd = 1, direction = 1, grouped = TRUE)
  }
  out
}

build_all_tasks <- function() {
  atlas <- load_atlas(ml_config$source_dir)
  mid <- tryCatch(build_middel_international_tasks(), error = function(e) e)
  if (inherits(mid, "error")) {
    warning("International MIDDEL import failed (other studies will still train): ",
            conditionMessage(mid))
    write_report(data.frame(study = "MIDDEL international", status = "IMPORT_ERROR",
                            message = conditionMessage(mid)), "task_construction_warnings.csv")
    mid <- list()
  }
  tasks <- c(build_individual_tasks(atlas), mid)
  tasks <- c(tasks, build_pooled_tasks(tasks))
  tasks
}
