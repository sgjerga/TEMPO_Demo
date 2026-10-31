# TEMPO — source-specific extraction and auditable outcome dictionary.
# No person-level rows are exported from the app; only aggregates are displayed.

study_info <- tibble::tribble(
  ~study, ~population, ~design, ~sample, ~intervention, ~comparison, ~available, ~reference,
  "MUSED", "Women with major depressive disorder, Germany", "Individual RCT; waitlist control", "102 randomized", "Group music therapy", "Waitlist", "BDI, HDRS, TICS, daily burden, salivary cortisol, coping and HRV", "https://doi.org/10.1016/j.jad.2025.01.011",
  "MIDDEL", "Older care-home residents with dementia and depression, multinational", "2 × 2 cluster-randomized trial", "1,021 randomized; 751 in primary 6-month ITT ANCOVA", "Group music therapy (GMT), with/without choir", "No GMT (some receive choir)", "MADRS, cognition, neuropsychiatric symptoms and quality of life; Australian individual trajectories", "https://doi.org/10.1136/bmjopen-2018-023436",
  "Finnerty & Trainor", "University students, Canada", "Individual RCT", "145 rows in provided week-1/6 file", "Six weekly group music-therapy sessions", "Campus life as usual", "PSS, STAI-S, hair cortisol, WHOQOL; session-level stress/anxiety", "https://doi.org/10.1371/journal.pmen.0000312",
  "Esteban-Cárdenas", "Adult psychiatric inpatients, Colombia", "Dose-comparison RCT; completers", "91 randomized; 74 completed", "Five music-therapy sessions / week", "One music-therapy session / week", "DASS-21 depression, anxiety and stress; life satisfaction, CISMA", "https://doi.org/10.1371/journal.pone.0317950",
  "Yu, Lee & Lu", "Chinese college students during COVID-19", "Three-arm pilot RCT", "16 randomized; 14 in post-test file", "Online music therapy", "No-intervention control; support arm also available", "Beck anxiety (BAI-C) and depression (BDI-13), baseline/post/follow-up", "https://doi.org/10.17632/mcr7vd5f5d.3"
)

# Bibliographic sources displayed on Overview. MIDDEL has both a 2019 protocol
# (the source given with the request) and its later primary trial publication.
study_references <- tibble::tribble(
  ~study, ~citation, ~url,
  "MUSED", "Gaebel, C., et al. (2025). Effects of group music therapy on depressive symptoms in women — The MUSED-study: Results from a randomized-controlled trial. Journal of Affective Disorders, 374, 1–10.", "https://doi.org/10.1016/j.jad.2025.01.011",
  "MIDDEL", "Gold, C., et al. (2019). Music Interventions for Dementia and Depression in ELderly care (MIDDEL): Protocol and statistical analysis plan for a multinational cluster-randomised trial. BMJ Open, 9, e023436.", "https://doi.org/10.1136/bmjopen-2018-023436",
  "MIDDEL", "Sveinsdottir, V., et al. (2025). Clinical effectiveness of music interventions for dementia and depression in older people (MIDDEL): A multinational, cluster-randomised controlled trial. The Lancet Healthy Longevity, 6(12), 100783.", "https://doi.org/10.1016/j.lanhl.2025.100783",
  "Finnerty & Trainor", "Finnerty, R., & Trainor, L. (2025). Group music therapy for the proactive management of stress and anxiety. PLOS Mental Health, 2(8), e0000312.", "https://doi.org/10.1371/journal.pmen.0000312",
  "Esteban-Cárdenas", "Esteban-Cárdenas, M., et al. (2026). High-frequency vs. low-frequency MIDI-assisted group music therapy in psychiatric inpatients: A randomized controlled trial. PLOS ONE, 21(4), e0317950.", "https://doi.org/10.1371/journal.pone.0317950",
  "Yu, Lee & Lu", "Yu, R., Lee, M.-S., & Lu, X. (2020). Music therapy tele-intervention for Chinese college students with anxiety and depression during COVID-19 pandemic: A pilot, randomized controlled study [Dataset, version 3]. Mendeley Data.", "https://doi.org/10.17632/mcr7vd5f5d.3"
)

# Dataset-level licensing provenance, checked 2026-10-31. A publication's
# Creative Commons licence is not assumed to apply to an external data deposit.
# The three OSF projects are public; OSF API node_license is null for each.
# This is not a statement that they have an explicit "No License" restriction.
dataset_licensing <- tibble::tribble(
  ~study, ~credit, ~data_url, ~license_label, ~license_url, ~license_note,
  "MUSED", "Gaebel, C., Jarczok, M. N., Aguilar-Raab, C., Rittner, S., Warth, M., Stoffel, M., & Ditzen, B. Psychobiological Stress Regulation Through Group Music Therapy in Depressive Women [Dataset]. heiDATA.", "https://doi.org/10.11588/DATA/L9TEVQ", "CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/", "Reuse and adaptation allowed with attribution and an indication of changes.",
  "MIDDEL", "MIDDEL research consortium. Music Interventions for Dementia and Depression in ELderly care (MIDDEL) [Data collection]. OSF.", "https://osf.io/tpdhu/overview", "Public OSF project; no project licence specified", NA_character_, "OSF public-content terms apply, subject to copyright and any file-specific conditions.",
  "Finnerty & Trainor", "Finnerty, R., & Trainor, L. Group Music Therapy for Proactive Wellness [Data collection]. OSF.", "https://osf.io/xuqb7/overview", "Public OSF project; no project licence specified", NA_character_, "OSF public-content terms apply, subject to copyright and any file-specific conditions.",
  "Esteban-Cárdenas", "Ferro, E. High-Frequency vs Low-Frequency Music Therapy in Psychiatric Inpatients: A Randomized Controlled Trial [Data collection]. OSF.", "https://osf.io/384fb/overview", "Public OSF project; no project licence specified", NA_character_, "OSF public-content terms apply, subject to copyright and any file-specific conditions.",
  "Yu, Lee & Lu", "Yu, R., Lee, M.-S., & Lu, X. (2020). Music therapy tele-intervention for Chinese college students with anxiety and depression during COVID-19 pandemic: A pilot, randomized controlled study [Dataset, version 3]. Mendeley Data.", "https://doi.org/10.17632/mcr7vd5f5d.3", "CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/", "Reuse and adaptation allowed with attribution and an indication of changes."
)

domain_details <- tibble::tribble(
  ~domain, ~definition,
  "Depression", "Depressive symptom burden; lower questionnaire scores indicate benefit.",
  "Anxiety", "State or symptom anxiety; lower questionnaire scores indicate benefit.",
  "Stress", "Perceived or symptom stress; lower questionnaire scores indicate benefit.",
  "Quality of life", "Self-reported positive well-being or life satisfaction; higher is better.",
  "Cognition", "Cognitive performance; higher is better.",
  "Neuropsychiatric", "Neuropsychiatric symptom severity; lower is better.",
  "Physiological stress", "Cortisol concentration; distinct materials and collection windows, descriptive only."
)

load_atlas <- function(root = file.path("data", "src_integrative")) {
  required <- c(
    "MUSED/MUSED_main_2024-11-03.csv",
    "MUSED/MUSED_momentary burden_2024-11-03.csv",
    "MUSED/MUSED_cortisol_2024_11-03.csv",
    "Finnerty/OSF_WEEK1_6_All_Data.xlsx",
    "Esteban_Cardenas/Base Music Therapy Psychiatry 2024.csv",
    "MIDDEL/Australian results/middel_au_primary_outcome.xlsx",
    "MIDDEL/international baseline data/middel_baseline_data.csv",
    "MIDDEL/International results/rproject_middel_public_251126.zip",
    "Yu_Lee_Lu/5.1_84703393_2_MT tele-intervention III-I pre-test_15_15.xlsx",
    "Yu_Lee_Lu/5.2_85706117_2_MT tele-intervention III-II post-test_14_14.xlsx",
    "Yu_Lee_Lu/5.3_86677009_2_MT tele-intervention III-III follow-up_14_14.xlsx"
  )
  missing <- required[!file.exists(file.path(root, required))]
  if (length(missing)) stop("Missing files under data/src_integrative: ", paste(missing, collapse = "; "))
  # Several exported CSVs begin with an unnamed row-index column (header "").
  # dplyr/tibble refuses any data.frame containing empty column names. Repair
  # only empty/duplicate names, preserving all original study-specific labels,
  # including accents, spaces and line breaks used in the outcome mappings.
  csv <- function(f) {
    d <- utils::read.csv(file.path(root, f), check.names = FALSE,
                         stringsAsFactors = FALSE)
    nms <- names(d)
    blank <- is.na(nms) | !nzchar(trimws(nms))
    nms[blank] <- paste0("unnamed_column_", which(blank))
    names(d) <- make.unique(nms)
    d
  }
  excel <- function(f) readxl::read_excel(file.path(root, f), sheet = 1,
                                          .name_repair = "unique")

  # One row per participant × outcome × time. 'direction' denotes favorable
  # direction in the ORIGINAL instrument, not a harmonized numeric value.
  parts <- list()
  # readxl may expose embedded Excel line breaks as CRLF ("\r\n"), LF
  # ("\n"), or whitespace. Resolve outcome columns by a normalized header
  # while keeping the original column names and original data untouched.
  canonical_header <- function(x) trimws(gsub("[[:space:]]+", " ", x))
  add <- function(d, study, outcome, domain, id, arm, columns, direction = -1,
                  source = "Individual-level data", note = "") {
    if (!length(columns)) stop("No outcome columns specified for ", study, ": ", outcome)
    actual <- names(d)
    requested <- unname(columns)
    idx <- match(canonical_header(requested), canonical_header(actual))
    if (anyNA(idx)) {
      stop("Missing outcome columns for ", study, " / ", outcome, ": ",
           paste(requested[is.na(idx)], collapse = "; "),
           ". Available headers: ", paste(actual, collapse = " | "))
    }
    columns[] <- actual[idx]
    for (key in c(id, arm)) {
      if (!(key %in% actual)) stop("Missing ", key, " in ", study, " / ", outcome)
    }
    phases <- names(columns)
    for (phase in phases) {
      parts[[length(parts) + 1L]] <<- tibble::tibble(
        study = study, participant = as.character(d[[id]]), arm = as.character(d[[arm]]),
        outcome = outcome, domain = domain, time = phase,
        value = suppressWarnings(as.numeric(d[[columns[[phase]]]])),
        direction = direction, source = source, note = note
      )
    }
  }

  # MUSED main trial file has an entirely empty 'group' column. Recover groups
  # using same IDs in the daily-burden file. Cross-check against the cortisol
  # arm labels (1=IG, 0=KG) and refuse to proceed if they disagree.
  mused <- csv("MUSED/MUSED_main_2024-11-03.csv")
  burden <- csv("MUSED/MUSED_momentary burden_2024-11-03.csv")
  cortisol <- csv("MUSED/MUSED_cortisol_2024_11-03.csv")
  key <- dplyr::summarise(dplyr::group_by(burden, id), code = dplyr::first(group), .groups = "drop")
  cort_key <- dplyr::summarise(dplyr::group_by(cortisol, id), code_c = dplyr::first(group), .groups = "drop")
  check <- dplyr::left_join(key, cort_key, by = "id")
  if (any(!is.na(check$code_c) & ifelse(check$code == 1, "IG", "KG") != check$code_c))
    stop("MUSED arm reconstruction disagrees with cortisol file. Inspect source IDs.")
  mused <- dplyr::left_join(mused, key, by = "id")
  mused$arm_label <- ifelse(mused$code == 1, "Music therapy", "Control / waitlist")
  add(mused, "MUSED", "BDI depression", "Depression", "id", "arm_label",
      c(Baseline = "BDI_pre", Post = "BDI_post", `Follow-up` = "BDI_fu"))
  add(mused, "MUSED", "HDRS depression", "Depression", "id", "arm_label",
      c(Baseline = "HDRS_pre", Post = "HDRS_post"))
  add(mused, "MUSED", "TICS chronic stress", "Stress", "id", "arm_label",
      c(Baseline = "TICS_pre", Post = "TICS_post", `Follow-up` = "TICS_fu"))

  # Daily salivary cortisol: average within person and phase for DESCRIPTIVE
  # trajectories only. Diurnal sample times and collection are not adjusted.
  cortisol$arm_label <- ifelse(cortisol$group == "IG", "Music therapy", "Control / waitlist")
  cortisol$time_label <- ifelse(tolower(as.character(cortisol$time_pre_post)) == "pre", "Baseline", "Post")
  cortisol$measure <- suppressWarnings(as.numeric(cortisol$cortisol))
  mc <- dplyr::summarise(dplyr::group_by(cortisol, id, arm_label, time_label),
                         value = mean(measure, na.rm = TRUE), .groups = "drop")
  mc <- dplyr::filter(mc, is.finite(value))
  parts[[length(parts) + 1L]] <- tibble::tibble(
    study = "MUSED", participant = as.character(mc$id), arm = mc$arm_label,
    outcome = "Salivary cortisol (daily mean)", domain = "Physiological stress",
    time = mc$time_label, value = mc$value, direction = -1,
    source = "Repeated saliva samples aggregated within person",
    note = "Exploratory: no diurnal or sample-timing correction; not meta-analyzed."
  )

  f <- excel("Finnerty/OSF_WEEK1_6_All_Data.xlsx")
  f$arm_label <- ifelse(f$Group == "MT", "Music therapy", "Control / usual life")
  add(f, "Finnerty & Trainor", "PSS perceived stress", "Stress", "ID #", "arm_label",
      c(Baseline = "Week1_PSS", Post = "Week6_PSS"))
  add(f, "Finnerty & Trainor", "STAI state anxiety", "Anxiety", "ID #", "arm_label",
      c(Baseline = "Week 1_STAI", Post = "Week6_STAI"))
  add(f, "Finnerty & Trainor", "WHOQOL psychological", "Quality of life", "ID #", "arm_label",
      c(Baseline = "Week 1\nPsychological", Post = "Week 6\nPsychological"), direction = 1)
  add(f, "Finnerty & Trainor", "WHOQOL social relationships", "Quality of life", "ID #", "arm_label",
      c(Baseline = "Week 1\nSocial Relationships", Post = "Week 6\nSocial Relationships"), direction = 1)
  add(f, "Finnerty & Trainor", "Hair cortisol", "Physiological stress", "ID #", "arm_label",
      c(Baseline = "Week1_Cortisol", Post = "Week6_Cortisol"),
      note = "Hair cortisol; distinct matrix and sampling window from salivary cortisol. Descriptive only.")

  e <- csv("Esteban_Cardenas/Base Music Therapy Psychiatry 2024.csv")
  # Arm A = high-frequency, verified against published DASS-21 stress changes.
  e$arm_label <- ifelse(e$Grupo == "A", "Music therapy (5 sessions)", "Music therapy (1 session)")
  add(e, "Esteban-Cárdenas", "DASS-21 depression", "Depression", "ID", "arm_label",
      c(Baseline = "Depresión en Dass-21 inicial", Post = "Depresión en Dass-21 final"))
  add(e, "Esteban-Cárdenas", "DASS-21 anxiety", "Anxiety", "ID", "arm_label",
      c(Baseline = "Ansiedad en Dass-21 inicial", Post = "Ansiedad en Dass-21 Final"))
  add(e, "Esteban-Cárdenas", "DASS-21 stress", "Stress", "ID", "arm_label",
      c(Baseline = "Estrés en Dass-21 Inicial", Post = "Estrés en Dass-21 Final"))
  add(e, "Esteban-Cárdenas", "SWLS life satisfaction", "Quality of life", "ID", "arm_label",
      c(Baseline = "Satisfacción inicial", Post = "Satisfacción final"), direction = 1)

  yfiles <- c(
    Baseline = "Yu_Lee_Lu/5.1_84703393_2_MT tele-intervention III-I pre-test_15_15.xlsx",
    Post = "Yu_Lee_Lu/5.2_85706117_2_MT tele-intervention III-II post-test_14_14.xlsx",
    `Follow-up` = "Yu_Lee_Lu/5.3_86677009_2_MT tele-intervention III-III follow-up_14_14.xlsx"
  )
  yg <- list(A = "Music therapy", B = "Support group", C = "Control / usual care")
  for (phase in names(yfiles)) {
    y <- excel(yfiles[[phase]])
    y <- dplyr::filter(y, Group %in% names(yg))
    y$arm_label <- unlist(yg[as.character(y$Group)], use.names = FALSE)
    for (spec in list(c("BAI anxiety", "Anxiety", "BAI Total"),
                      c("BDI-13 depression", "Depression", "BDI Total"))) {
      parts[[length(parts) + 1L]] <- tibble::tibble(
        study = "Yu, Lee & Lu", participant = as.character(y[["Participant No."]]),
        arm = y$arm_label, outcome = spec[[1]], domain = spec[[2]],
        time = phase, value = suppressWarnings(as.numeric(y[[spec[[3]]]])),
        direction = -1, source = "Randomized pilot; provided total scores",
        note = "Primary comparison: music therapy vs no-intervention control (support arm descriptive)."
      )
    }
  }

  # Australian MIDDEL subset is used for visualizing repeated measures ONLY.
  # The international adjusted trial contrast is read from the published
  # project ANCOVA summaries (below) to avoid counting Australians twice.
  au <- excel("MIDDEL/Australian results/middel_au_primary_outcome.xlsx")
  au$arm_label <- dplyr::recode(as.character(au$group),
    gmt = "GMT only", rcs = "Choir only", `gmt+rcs` = "GMT + choir", standardcare = "Standard care")
  add(au, "MIDDEL", "MADRS depression (Australian subset)", "Depression", "id", "arm_label",
      c(Baseline = "madrs.0", `3 months` = "madrs.3", `6 months` = "madrs.6", `12 months` = "madrs.12"),
      source = "Australian participant subset (318 rows); descriptive trajectory",
      note = "Nested within MIDDEL international trial; do not enter separately into pooled inference.")

  long <- dplyr::bind_rows(parts)
  long <- dplyr::filter(long, !is.na(participant), !is.na(arm), !is.na(time), is.finite(value))
  long$time <- factor(long$time, levels = c("Baseline", "Post", "3 months", "6 months", "12 months", "Follow-up"))

  # Primary outcome per study × harmonized domain: prevents using multiple
  # correlated instruments from one study as independent observations.
  primary <- tibble::tribble(
    ~study, ~domain, ~outcome, ~treated, ~control, ~contrast,
    "MUSED", "Depression", "BDI depression", "Music therapy", "Control / waitlist", "MT vs waitlist",
    "MUSED", "Stress", "TICS chronic stress", "Music therapy", "Control / waitlist", "MT vs waitlist",
    "Finnerty & Trainor", "Anxiety", "STAI state anxiety", "Music therapy", "Control / usual life", "MT vs campus life",
    "Finnerty & Trainor", "Stress", "PSS perceived stress", "Music therapy", "Control / usual life", "MT vs campus life",
    "Finnerty & Trainor", "Quality of life", "WHOQOL psychological", "Music therapy", "Control / usual life", "MT vs campus life",
    "Esteban-Cárdenas", "Depression", "DASS-21 depression", "Music therapy (5 sessions)", "Music therapy (1 session)", "5 sessions vs 1 session",
    "Esteban-Cárdenas", "Anxiety", "DASS-21 anxiety", "Music therapy (5 sessions)", "Music therapy (1 session)", "5 sessions vs 1 session",
    "Esteban-Cárdenas", "Stress", "DASS-21 stress", "Music therapy (5 sessions)", "Music therapy (1 session)", "5 sessions vs 1 session",
    "Esteban-Cárdenas", "Quality of life", "SWLS life satisfaction", "Music therapy (5 sessions)", "Music therapy (1 session)", "5 sessions vs 1 session",
    "Yu, Lee & Lu", "Depression", "BDI-13 depression", "Music therapy", "Control / usual care", "MT vs usual care",
    "Yu, Lee & Lu", "Anxiety", "BAI anxiety", "Music therapy", "Control / usual care", "MT vs usual care"
  )

  # International MIDDEL model estimates: published adjusted ITT six-month
  # factorial GMT main effect. The reported Cohen d is rounded to one decimal.
  # For MADRS, use B and its CI divided by the baseline MADRS SD for better
  # numerical precision (the 1,021-person baseline SD is a proxy).
  inner <- "rproject_middel_public/results/251120/ancova/tab_ancova_itt_all_251120.csv"
  zip <- file.path(root, "MIDDEL/International results/rproject_middel_public_251126.zip")
  # read.csv() opens a not-yet-open connection and closes it automatically.
  # Do not register an additional on.exit(close(...)): it would attempt to
  # close the already-destroyed unz() connection and abort app startup.
  tab <- utils::read.csv(unz(zip, inner), header = FALSE, sep = ";", fill = TRUE,
                         stringsAsFactors = FALSE, col.names = paste0("V", 1:8))
  base <- csv("MIDDEL/international baseline data/middel_baseline_data.csv")
  madrs_sd <- stats::sd(suppressWarnings(as.numeric(base$madrs)), na.rm = TRUE)
  parse_ci <- function(s) {
    match <- regmatches(as.character(s), regexec(
      "(-?[0-9]+(?:\\.[0-9]+)?)\\s*\\(\\s*(-?[0-9]+(?:\\.[0-9]+)?)\\s*,\\s*(-?[0-9]+(?:\\.[0-9]+)?)\\s*\\)",
      as.character(s), perl = TRUE))[[1]]
    if (length(match) != 4) return(rep(NA_real_, 3))
    as.numeric(match[2:4])
  }
  rows <- which(trimws(tab$V1) == "all GMT2")
  mrows <- list()
  for (i in rows) {
    titles <- which(grepl("^All countries:", tab$V1) & seq_len(nrow(tab)) < i)
    if (!length(titles)) next
    block <- tab$V1[max(titles)]
    spec <- if (grepl("MADRS", block)) c("Depression", "MADRS depression", "-1") else
      if (grepl("SIB-8", block)) c("Cognition", "SIB-8 cognition", "1") else
      if (grepl("Symptom severity", block)) c("Neuropsychiatric", "NPI symptoms", "-1") else
      if (grepl("EQ-VAS", block)) c("Quality of life", "EQ-VAS health status", "1") else NULL
    if (is.null(spec)) next
    sign <- as.numeric(spec[[3]])
    if (spec[[1]] == "Depression") {
      raw <- parse_ci(tab$V6[i]); divisor <- madrs_sd
      method <- "Adjusted ANCOVA B and 95% CI / international baseline MADRS SD"
    } else {
      raw <- parse_ci(tab$V8[i]); divisor <- 1
      method <- "Published adjusted Cohen d and 95% CI (rounded to 0.1)"
    }
    if (any(!is.finite(raw)) || !is.finite(divisor) || divisor <= 0) next
    e <- sign * raw[1] / divisor
    ci <- sort(sign * raw[2:3] / divisor)
    mrows[[length(mrows) + 1L]] <- tibble::tibble(
      study = "MIDDEL", domain = spec[[1]], outcome = spec[[2]],
      estimate = e, se = (ci[2] - ci[1]) / (2 * 1.96),
      lower = ci[1], upper = ci[2], n_treated = NA_integer_, n_control = NA_integer_,
      contrast = "Factorial GMT main effect vs no GMT (choir may be present)",
      source = method, comparison_type = "GMT factorial",
      note = "International MIDDEL ITT at 6 months; adjusted for cluster design. Not independent of Australian trajectories."
    )
  }
  middel_effects <- dplyr::bind_rows(mrows)
  list(long = long, primary = primary, middel_effects = middel_effects,
       baseline = base, study_info = study_info, domain_details = domain_details)
}
