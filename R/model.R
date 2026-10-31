# Common estimand (participant datasets): favorable-direction standardized
# difference in within-person change, MT minus comparator. Positive is benefit.
# Estimates use observed paired completers, without covariate adjustment.

estimate_participant_contrast <- function(long, spec) {
  d <- long |>
    dplyr::filter(study == spec$study, outcome == spec$outcome,
                  arm %in% c(spec$treated, spec$control),
                  as.character(time) %in% c("Baseline", "Post")) |>
    dplyr::mutate(time = as.character(time)) |>
    dplyr::select(participant, arm, time, value, direction) |>
    dplyr::distinct(participant, arm, time, .keep_all = TRUE) |>
    tidyr::pivot_wider(names_from = time, values_from = value) |>
    dplyr::filter(is.finite(Baseline), is.finite(Post))
  if (nrow(d) < 6) return(NULL)
  a <- d[d$arm == spec$treated, , drop = FALSE]
  b <- d[d$arm == spec$control, , drop = FALSE]
  n1 <- nrow(a); n0 <- nrow(b)
  if (min(n1, n0) < 3) return(NULL)
  pooled_baseline <- sqrt(((n1 - 1) * stats::var(a$Baseline) +
                            (n0 - 1) * stats::var(b$Baseline)) / (n1 + n0 - 2))
  if (!is.finite(pooled_baseline) || pooled_baseline <= 0) return(NULL)
  delta_a <- a$Post - a$Baseline
  delta_b <- b$Post - b$Baseline
  direction <- unique(d$direction)
  if (length(direction) != 1L) return(NULL)
  df <- n1 + n0 - 2
  j <- 1 - 3 / (4 * df - 1) # small-sample Hedges correction
  yi <- j * direction * (mean(delta_a) - mean(delta_b)) / pooled_baseline
  sei <- j * sqrt(stats::var(delta_a) / n1 + stats::var(delta_b) / n0) / pooled_baseline
  if (!is.finite(sei) || sei <= 0) return(NULL)
  tibble::tibble(
    study = spec$study, domain = spec$domain, outcome = spec$outcome,
    estimate = yi, se = sei, lower = yi - 1.96 * sei,
    upper = yi + 1.96 * sei, n_treated = n1, n_control = n0,
    contrast = spec$contrast, comparison_type = if (spec$study == "Esteban-Cárdenas") "Dose comparison" else "MT versus comparator",
    source = "Unadjusted paired-completer Hedges-corrected difference in changes / pooled baseline SD",
    note = "Approximate CI: ignores uncertainty in baseline SD and uses unadjusted observed cases."
  )
}

build_effects <- function(atlas) {
  rows <- lapply(seq_len(nrow(atlas$primary)), function(i)
    estimate_participant_contrast(atlas$long, atlas$primary[i, ]))
  dplyr::bind_rows(dplyr::bind_rows(rows), atlas$middel_effects) |>
    dplyr::filter(is.finite(estimate), is.finite(se), se > 0) |>
    dplyr::mutate(interval = sprintf("%.2f [%.2f, %.2f]", estimate, lower, upper),
                  n_label = dplyr::if_else(is.na(n_treated), "ITT adjusted",
                    paste0("n=", n_treated, "+", n_control)))
}

# Restricted maximum-likelihood between-study variance for y_i ~ N(mu, v_i+tau²).
# With few studies, estimates and shrinkage are especially unstable.
pool_effects <- function(d, method = "REML") {
  d <- dplyr::filter(d, is.finite(estimate), is.finite(se), se > 0)
  if (!nrow(d)) return(NULL)
  y <- d$estimate; v <- pmax(d$se^2, 1e-10)
  tau2 <- 0
  if (identical(method, "REML") && length(y) >= 2L) {
    objective <- function(t) {
      w <- 1 / (v + t); mu <- sum(w * y) / sum(w)
      sum(log(v + t)) + log(sum(w)) + sum(w * (y - mu)^2)
    }
    upper <- max(2, stats::var(y) * 10, na.rm = TRUE)
    opt <- stats::optimize(objective, interval = c(0, upper))
    tau2 <- if (objective(0) <= opt$objective) 0 else opt$minimum
  }
  w <- 1 / (v + tau2)
  mu <- sum(w * y) / sum(w)
  se_mu <- sqrt(1 / sum(w))
  # EB deviations conditioned on plug-in pooled mu and tau². Uncertainty in
  # mu/tau² is omitted. Never interpret these as definitive interactions.
  shrink <- if (tau2 > 0) tau2 / (tau2 + v) else rep(0, length(y))
  d$deviation <- shrink * (y - mu)
  d$deviation_se <- sqrt(pmax(0, tau2 * v / (tau2 + v)))
  d$study_fitted <- mu + d$deviation
  q <- if (length(y) > 1) stats::qchisq(0.95, df = length(y) - 1) else NA_real_
  list(data = d, k = length(y), mu = mu, se = se_mu,
       lower = mu - 1.96 * se_mu, upper = mu + 1.96 * se_mu,
       tau = sqrt(tau2), method = if (length(y) == 1) "Single study" else method,
       prediction_lower = if (length(y) >= 3) mu - 1.96 * sqrt(se_mu^2 + tau2) else NA_real_,
       prediction_upper = if (length(y) >= 3) mu + 1.96 * sqrt(se_mu^2 + tau2) else NA_real_)
}

aggregate_trajectories <- function(d) {
  d |>
    dplyr::group_by(study, domain, outcome, time, arm) |>
    dplyr::summarise(n = dplyr::n_distinct(participant), avg = mean(value),
      sd = stats::sd(value), .groups = "drop") |>
    dplyr::mutate(se = sd / sqrt(n), lower = avg - 1.96 * se,
      upper = avg + 1.96 * se)
}
