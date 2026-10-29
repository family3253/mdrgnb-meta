# Packages
suppressPackageStartupMessages({
  library(metafor)
  library(clubSandwich)
})

# Effect-size preparation
logit_auc <- function(x) qlogis(x)

logit_se_from_ci <- function(ci_lower, ci_upper, level = 0.95) {
  z <- qnorm(1 - (1 - level) / 2)
  (qlogis(ci_upper) - qlogis(ci_lower)) / (2 * z)
}

prepare_effects <- function(dat) {
  required <- c("auc", "ci_lower", "ci_upper", "report_key", "cluster_key")
  missing <- setdiff(required, names(dat))
  if (length(missing)) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }

  stopifnot(
    all(is.finite(dat$auc)),
    all(dat$auc > 0 & dat$auc < 1),
    all(dat$ci_lower > 0.5 & dat$ci_lower < dat$auc),
    all(dat$ci_upper > dat$auc & dat$ci_upper < 1)
  )

  dat$yi <- logit_auc(dat$auc)
  dat$vi <- logit_se_from_ci(dat$ci_lower, dat$ci_upper)^2
  dat
}

fit_cluster_robust_model <- function(dat) {
  dat <- prepare_effects(dat)

  fit <- rma.mv(
    yi,
    V = vi,
    random = ~ 1 | report_key / cluster_key,
    data = dat,
    method = "REML"
  )

  robust <- coef_test(
    fit,
    vcov = "CR2",
    cluster = dat$report_key,
    test = "Satterthwaite"
  )

  pooled <- predict(fit, transf = transf.ilogit)
  list(model = fit, robust_test = robust, pooled_auc = pooled)
}

# Report-level sensitivity
make_report_level_summaries <- function(dat) {
  dat <- prepare_effects(dat)
  split_dat <- split(dat, dat$report_key)
  do.call(rbind, lapply(split_dat, function(x) {
    data.frame(
      report_key = x$report_key[[1]],
      cluster_key = x$cluster_key[[1]],
      yi = mean(x$yi),
      vi = mean(x$vi),
      source_effects = nrow(x),
      row.names = NULL
    )
  }))
}

fit_report_level_sensitivity <- function(dat) {
  summaries <- make_report_level_summaries(dat)
  fit <- rma.uni(yi, vi, data = summaries, method = "REML")
  list(
    model = fit,
    report_summaries = summaries,
    pooled_auc = predict(fit, transf = transf.ilogit)
  )
}
