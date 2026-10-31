# Leakage-safe baseline preprocessing and grouped cross-validation.
# Prediction accuracy is measured on the observed factual outcome only.

make_blueprint <- function(train, features) {
  out <- list()
  for (f in features) {
    x <- train[[f]]
    if (is.numeric(x) || is.integer(x) || is.logical(x)) {
      x <- suppressWarnings(as.numeric(x)); x[!is.finite(x)] <- NA_real_
      med <- stats::median(x, na.rm = TRUE)
      if (!is.finite(med)) med <- 0
      x[is.na(x)] <- med
      mu <- mean(x); sd <- stats::sd(x)
      if (!is.finite(sd) || sd < 1e-8) sd <- 1
      out[[f]] <- list(type = "numeric", median = med, mean = mu, sd = sd,
                       missing_flag = any(!is.finite(suppressWarnings(as.numeric(train[[f]])))))
    } else {
      x <- trimws(as.character(x))
      x[is.na(x) | !nzchar(x)] <- "(missing)"
      tab <- sort(table(x), decreasing = TRUE)
      # Rare categories stay in a catch-all category, especially useful for
      # the small inpatient trial with diverse diagnoses.
      levels <- names(tab)[tab >= 3L]
      levels <- head(levels, 10L)
      if (!length(levels)) levels <- names(tab)[1]
      out[[f]] <- list(type = "categorical", levels = levels)
    }
  }
  out
}

baseline_matrix <- function(new_data, blueprint) {
  n <- nrow(new_data); columns <- list()
  for (f in names(blueprint)) {
    p <- blueprint[[f]]
    if (is.null(new_data[[f]])) stop("Prediction data missing baseline feature: ", f)
    if (p$type == "numeric") {
      x <- suppressWarnings(as.numeric(new_data[[f]]))
      miss <- !is.finite(x)
      x[miss] <- p$median
      columns[[paste0("x_", safe_id(f))]] <- (x - p$mean) / p$sd
      if (isTRUE(p$missing_flag))
        columns[[paste0("missing_", safe_id(f))]] <- as.numeric(miss)
    } else {
      x <- trimws(as.character(new_data[[f]]))
      x[is.na(x) | !nzchar(x)] <- "(missing)"
      for (v in p$levels) {
        name <- paste0("cat_", safe_id(f), "_", safe_id(v))
        columns[[name]] <- as.numeric(x == v)
      }
    }
  }
  if (!length(columns)) stop("No usable baseline features")
  m <- do.call(cbind, columns)
  if (!is.matrix(m)) m <- matrix(m, nrow = n)
  colnames(m) <- make.unique(names(columns))
  storage.mode(m) <- "double"
  if (any(!is.finite(m))) stop("Non-finite model matrix after preprocessing")
  m
}

design_matrix <- function(data, blueprint, override_treatment = NULL) {
  base <- baseline_matrix(data, blueprint)
  tr <- if (is.null(override_treatment)) data$treatment else rep(override_treatment, nrow(data))
  tr <- as.numeric(tr)
  if (any(!is.finite(tr))) stop("Treatment must be available for every row")
  interactions <- sweep(base, 1L, tr, FUN = "*")
  colnames(interactions) <- paste0("tr_x_", colnames(base))
  cbind(base, treatment = tr, interactions)
}

make_group_folds <- function(d, k_requested = 5L, seed = 1L) {
  group <- as.character(d$cluster)
  if (anyNA(group) || any(!nzchar(group))) stop("Missing cluster identifier")
  u <- unique(group)
  arm <- vapply(u, function(g) {
    a <- unique(d$treatment[group == g])
    if (length(a) != 1L) stop("Mixed treatment arms within cluster: ", g)
    a
  }, numeric(1))
  nby <- table(factor(arm, levels = c(0, 1)))
  k <- min(as.integer(k_requested), min(nby))
  if (k < 3L) stop("Fewer than three independently randomized units per arm")
  set.seed(seed)
  lookup <- setNames(integer(length(u)), u)
  for (a in c(0, 1)) {
    ids <- sample(u[arm == a])
    lookup[ids] <- rep(seq_len(k), length.out = length(ids))
  }
  as.integer(lookup[group])
}

train_candidate <- function(train, feature_names, algorithm, seed) {
  blue <- make_blueprint(train, feature_names)
  x <- design_matrix(train, blue)
  y <- train$y
  if (algorithm %in% c("ridge", "elastic_net")) {
    k <- make_group_folds(train, ml_config$inner_folds, seed + 11L)
    alpha <- if (algorithm == "ridge") 0 else 0.5
    # Preserve the randomized treatment main effect while penalizing baseline
    # predictors and effect-modification terms. Previously lambda.1se could
    # shrink *all* treatment terms to zero, so predictions for both arms were
    # identical for every participant regardless of their baseline profile.
    # This does not force a beneficial treatment effect: the freely estimated
    # treatment coefficient can still be zero or negative when data support it.
    penalty <- rep(1, ncol(x))
    penalty[colnames(x) == "treatment"] <- 0
    model <- glmnet::cv.glmnet(x, y, alpha = alpha, family = "gaussian",
                              foldid = k, type.measure = "mse", standardize = FALSE,
                              penalty.factor = penalty)
    return(list(algorithm = algorithm, blueprint = blue, model = model))
  }
  if (algorithm == "random_forest") {
    if (!requireNamespace("ranger", quietly = TRUE)) stop("ranger not installed")
    dat <- as.data.frame(x)
    dat$y <- y
    model <- ranger::ranger(dependent.variable.name = "y", data = dat,
                            num.trees = 500L, min.node.size = max(10L, floor(nrow(train)/20)),
                            seed = seed, num.threads = 1)
    return(list(algorithm = algorithm, blueprint = blue, model = model))
  }
  stop("Unknown learner: ", algorithm)
}

predict_candidate <- function(fit, newdata, treatment_override = NULL) {
  x <- design_matrix(newdata, fit$blueprint, treatment_override)
  if (fit$algorithm %in% c("ridge", "elastic_net"))
    return(as.numeric(stats::predict(fit$model, newx = x, s = "lambda.1se")))
  if (fit$algorithm == "random_forest")
    # ranger registers an S3 predict() method; ranger::predict is not exported.
    return(as.numeric(stats::predict(fit$model, data = as.data.frame(x))$predictions))
  stop("Unknown learner")
}

evaluate_candidate <- function(d, feature_names, algo, outer, seed) {
  oof <- rep(NA_real_, nrow(d))
  for (f in sort(unique(outer))) {
    train <- d[outer != f, , drop = FALSE]
    test <- d[outer == f, , drop = FALSE]
    if (length(unique(train$treatment)) != 2) stop("Training fold lacks one arm")
    fit <- train_candidate(train, feature_names, algo, seed + f * 37L)
    oof[outer == f] <- predict_candidate(fit, test)
  }
  if (any(!is.finite(oof))) stop("Nonfinite cross-validated predictions")
  rmse <- sqrt(mean((d$y - oof)^2))
  mae <- mean(abs(d$y - oof))
  r2 <- if (stats::var(d$y) > 0) 1 - sum((d$y - oof)^2) / sum((d$y - mean(d$y))^2) else NA_real_
  list(rmse = rmse, mae = mae, r2 = r2, oof = oof)
}

fit_one_task <- function(task) {
  d <- task$data
  result <- data.frame(task_id = task$id, study = task$study, domain = task$domain,
    outcome = task$outcome, comparison = task$contrast, timepoint = task$timepoint,
    design = task$design, n = nrow(d), n_treated = sum(d$treatment == 1),
    n_control = sum(d$treatment == 0), n_clusters = length(unique(d$cluster)),
    status = "", algorithm = NA_character_, cv_rmse = NA_real_, cv_mae = NA_real_,
    cv_r2 = NA_real_, model_path = NA_character_, message = "", stringsAsFactors = FALSE)
  if (nrow(d) < ml_config$min_n || min(result$n_treated, result$n_control) < ml_config$min_arm_n) {
    result$status <- "SKIPPED_TOO_SMALL"
    result$message <- sprintf("Minimum %s participants and %s per arm; exploratory description only",
                              ml_config$min_n, ml_config$min_arm_n)
    return(list(registry = result, candidate_metrics = NULL, prediction_summary = NULL))
  }
  outer <- tryCatch(make_group_folds(d, ml_config$outer_folds, ml_config$seed), error = function(e) e)
  if (inherits(outer, "error")) {
    result$status <- "SKIPPED_FEW_RANDOMIZATION_UNITS"; result$message <- conditionMessage(outer)
    return(list(registry = result, candidate_metrics = NULL, prediction_summary = NULL))
  }
  algos <- c("ridge", "elastic_net")
  if (nrow(d) >= ml_config$ranger_min_n && requireNamespace("ranger", quietly = TRUE))
    algos <- c(algos, "random_forest")
  metrics <- list()
  for (a in algos) {
    set.seed(ml_config$seed)
    ev <- tryCatch(evaluate_candidate(d, task$features, a, outer, ml_config$seed),
                   error = function(e) e)
    if (inherits(ev, "error")) {
      metrics[[a]] <- data.frame(task_id = task$id, algorithm = a,
        cv_rmse = NA_real_, cv_mae = NA_real_, cv_r2 = NA_real_, error = conditionMessage(ev))
    } else {
      metrics[[a]] <- data.frame(task_id = task$id, algorithm = a,
        cv_rmse = ev$rmse, cv_mae = ev$mae, cv_r2 = ev$r2, error = "")
    }
  }
  m <- dplyr::bind_rows(metrics)
  ok <- m[is.finite(m$cv_rmse), , drop = FALSE]
  if (!nrow(ok)) {
    result$status <- "TRAINING_FAILED"
    result$message <- paste(m$error, collapse = " / ")
    return(list(registry = result, candidate_metrics = m, prediction_summary = NULL))
  }
  best <- ok$algorithm[which.min(ok$cv_rmse)]
  final <- tryCatch(train_candidate(d, task$features, best, ml_config$seed + 999L),
                    error = function(e) e)
  if (inherits(final, "error")) {
    result$status <- "FINAL_TRAINING_FAILED"; result$message <- conditionMessage(final)
    return(list(registry = result, candidate_metrics = m, prediction_summary = NULL))
  }
  bundle <- c(final, list(task_id = task$id, study = task$study,
    domain = task$domain, outcome = task$outcome, comparison = task$contrast,
    design = task$design, features = task$features, timepoint = task$timepoint,
    baseline_mean = task$baseline_mean, baseline_sd = task$baseline_sd,
    direction = task$direction, target = "favorable standardized pre-post change",
    n_train = nrow(d), seed = ml_config$seed,
    warning = "Predicted conditional treatment contrast is exploratory, not validated individual causal benefit."))
  file <- paste0(task$id, ".rds")
  saveRDS(bundle, file.path(ml_config$models_dir, file))
  row <- ok[ok$algorithm == best, , drop = FALSE][1, ]
  result$status <- "TRAINED"
  result$algorithm <- best
  result$cv_rmse <- row$cv_rmse
  result$cv_mae <- row$cv_mae
  result$cv_r2 <- row$cv_r2
  result$model_path <- file.path("data", "ml_models", file)

  # These counterfactual contrasts are fitted ON the training sample. They
  # summarize model behavior, not out-of-sample CATE accuracy.
  tau <- predict_candidate(bundle, d, treatment_override = 1) -
         predict_candidate(bundle, d, treatment_override = 0)
  summary <- data.frame(task_id = task$id, domain = task$domain, study = task$study,
    n = length(tau), mean_predicted_benefit = mean(tau), sd_predicted_benefit = stats::sd(tau),
    q05 = unname(stats::quantile(tau, 0.05)), q50 = stats::median(tau),
    q95 = unname(stats::quantile(tau, 0.95)),
    fraction_favorable = mean(tau > 0),
    note = "In-sample model-implied conditional contrast; not individual treatment-effect validation")
  if (isTRUE(ml_config$save_participant_predictions)) {
    write_report(data.frame(participant = d$participant, observed_treatment = d$treatment,
      observed_standardized_change = d$y, predicted_benefit = tau), paste0(task$id, "_participant_predictions.csv"))
  }
  list(registry = result, candidate_metrics = m, prediction_summary = summary)
}

fit_optional_causal_forest <- function(task) {
  if (!isTRUE(ml_config$fit_causal_forest) || !requireNamespace("grf", quietly = TRUE)) return(NULL)
  d <- task$data
  if (nrow(d) < ml_config$grf_min_n || length(unique(d$cluster)) < ml_config$grf_min_clusters ||
      min(table(factor(d$treatment, levels = c(0, 1)))) < 50) return(NULL)
  # Do not fit on pooled heterogeneous treatment definitions by default.
  if (task$study == "Pooled exploratory") return(NULL)
  blue <- make_blueprint(d, task$features)
  x <- baseline_matrix(d, blue)
  forest <- tryCatch(grf::causal_forest(X = x, Y = d$y, W = d$treatment,
    clusters = as.factor(d$cluster), num.trees = 1500L, seed = ml_config$seed,
    W.hat = rep(mean(d$treatment), nrow(d))), error = function(e) e)
  if (inherits(forest, "error")) return(data.frame(task_id = task$id,
    status = "CAUSAL_FOREST_FAILED", message = conditionMessage(forest)))
  file <- paste0(task$id, "_causal_forest.rds")
  saveRDS(list(model = forest, blueprint = blue, study = task$study,
    domain = task$domain, target = "favorable standardized treatment contrast",
    feature_names = task$features,
    warning = "Exploratory CATE from RCT; do not treat individual estimates as observed effects."),
    file.path(ml_config$models_dir, file))
  data.frame(task_id = task$id, status = "CAUSAL_FOREST_SAVED",
    message = file)
}
