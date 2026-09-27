#' Simulate a through-year system with known true growth
#'
#' Students grow linearly, `theta(t) = theta0 + g * t`, and take interims at
#' `times` (reported on their own scale, `scale[1] + scale[2] * theta`,
#' with error from a Rasch form of `interim_items` items) and the summative at
#' t = 1. Late enrollers miss the first `late_missing` interims. "Fast
#' growers" gain an extra `fast_extra` logits after the last interim (e.g. a
#' spring intervention), which interims cannot reveal. They are the
#' hardest case for prior-informed scoring.
#'
#' Two cohorts: `calibration` (last year: summative observed, used to link)
#' and `operational` (this year: summative not yet taken). A second,
#' independent set of interim scores (`*_r2`) supports decision-consistency
#' analyses.
#'
#' @param n_calibration,n_operational Cohort sizes.
#' @param times Interim occasions as fractions of the year.
#' @param theta0_mean,theta0_sd,growth_mean,growth_sd True-score model.
#' @param p_fast,fast_extra Share of fast growers and their extra growth.
#' @param p_late,late_missing Share of late enrollers and interims they miss.
#' @param scale Interim reporting scale: intercept and slope.
#' @param interim_items Items per interim form (sets measurement error).
#' @param summative_se SE of the calibration cohort's summative scores.
#' @param seed Optional seed.
#' @return A `ty_sim` data frame, one row per student.
#' @examples
#' sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
#' head(sim[c("id", "cohort", "late", "fast", "I1", "I2", "I3", "S")])
#' @export
ty_simulate <- function(n_calibration = 3000, n_operational = 3000,
                        times = c(0.2, 0.5, 0.8),
                        theta0_mean = -0.6, theta0_sd = 1,
                        growth_mean = 0.6, growth_sd = 0.25,
                        p_fast = 0.1, fast_extra = 0.6,
                        p_late = 0.1, late_missing = 2,
                        scale = c(200, 10), interim_items = 30,
                        summative_se = 0.3, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  N <- n_calibration + n_operational
  K <- length(times)
  cohort <- rep(c("calibration", "operational"), c(n_calibration, n_operational))
  theta0 <- stats::rnorm(N, theta0_mean, theta0_sd)
  g <- stats::rnorm(N, growth_mean, growth_sd)
  fast <- stats::runif(N) < p_fast
  late <- stats::runif(N) < p_late
  ib <- stats::rnorm(interim_items, 0, 1)
  se_at <- function(th) 1 / sqrt(vapply(th, function(t) {
    p <- stats::plogis(t - ib); sum(p * (1 - p))
  }, 0))

  out <- data.frame(id = sprintf("S%05d", seq_len(N)), cohort = cohort,
                    late = late, fast = fast, stringsAsFactors = FALSE)
  for (k in seq_len(K)) {
    th <- theta0 + g * times[k]
    se <- se_at(th)
    obs <- function() scale[1] + scale[2] * (th + stats::rnorm(N, 0, se))
    miss <- late & k <= late_missing
    nm <- paste0("I", k)
    out[[paste0("theta_", nm)]] <- th
    out[[nm]] <- ifelse(miss, NA, obs())
    out[[paste0(nm, "_se")]] <- ifelse(miss, NA, scale[2] * se)
    out[[paste0(nm, "_r2")]] <- ifelse(miss, NA, obs())
  }
  out$theta_S <- theta0 + g + fast * fast_extra
  cal <- cohort == "calibration"
  out$S <- ifelse(cal, out$theta_S + stats::rnorm(N, 0, summative_se), NA)
  out$S_se <- ifelse(cal, summative_se, NA)
  structure(out, class = c("ty_sim", "data.frame"),
            interims = paste0("I", seq_len(K)), times = times, scale = scale)
}
