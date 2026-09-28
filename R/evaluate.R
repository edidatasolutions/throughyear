#' Compare routing and scoring policies
#'
#' Administers the MST under five policies to the same examinees:
#' \describe{
#'   \item{cold}{Full routing module, population prior for routing and scoring.}
#'   \item{prior_route}{Full routing module, student's interim prior for
#'     routing only; population prior for the reported score.}
#'   \item{prior_both}{Interim prior for routing and for the reported score.}
#'   \item{prior_short}{Interim prior for routing with a shortened routing
#'     module (`short_n` items); population prior for scoring.}
#'   \item{prior_only}{Route on the interim prior alone (no routing module);
#'     population prior for scoring.}
#' }
#' @param mst A `ty_mst`.
#' @param theta True summative abilities.
#' @param prior Student priors (`mean`, `sd`) from `predict()` on a `ty_link`.
#' @param population Population prior `c(mean, sd)`; default: moments of the
#'   student priors' implied marginal.
#' @param short_n Routing items for `prior_short`.
#' @param seed Optional seed (each policy gets its own stream).
#' @return A `ty_policies` object: named list of [ty_administer()] results,
#'   plus `theta`.
#' @examples
#' sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
#' op <- sim[sim$cohort == "operational", ]
#' prior <- predict(ty_link(sim), op)
#' pol <- ty_policies(ty_mst_default(), op$theta_S, prior, seed = 1)
#' summary(pol)
#' @export
ty_policies <- function(mst, theta, prior, population = NULL, short_n = 6, seed = NULL) {
  if (is.null(population))
    population <- c(mean(prior$mean), sqrt(stats::var(prior$mean) + mean(prior$sd^2)))
  pop <- list(mean = population[1], sd = population[2])
  stu <- list(mean = prior$mean, sd = prior$sd)
  s <- if (is.null(seed)) NULL else seed + 0:4
  res <- list(
    cold        = ty_administer(mst, theta, pop, pop, seed = s[1]),
    prior_route = ty_administer(mst, theta, stu, pop, seed = s[2]),
    prior_both  = ty_administer(mst, theta, stu, stu, seed = s[3]),
    prior_short = ty_administer(mst, theta, stu, pop, routing_n = short_n, seed = s[4]),
    prior_only  = ty_administer(mst, theta, stu, pop, routing_n = 0, seed = s[5])
  )
  structure(list(results = res, theta = theta, population = population), class = "ty_policies")
}

policy_row <- function(r, theta) {
  data.frame(n = nrow(r),
             routing_accuracy = mean(r$module == r$correct_module),
             routed_too_easy = mean(r$module < r$correct_module),
             routed_too_hard = mean(r$module > r$correct_module),
             mean_items = mean(r$n_items),
             bias = mean(r$theta_hat - theta),
             rmse = sqrt(mean((r$theta_hat - theta)^2)),
             mean_se = mean(r$se))
}

#' @export
summary.ty_policies <- function(object, ...) {
  out <- do.call(rbind, lapply(object$results, policy_row, theta = object$theta))
  cbind(policy = names(object$results), out, row.names = NULL)
}

#' Fairness diagnostics for prior-informed routing and scoring
#'
#' For each policy and group, reports routing accuracy, the rate of being
#' routed to an easier module than the one most informative at the student's
#' true ability (the "locked into an easier path" concern), and bias and RMSE
#' of the reported score. Bias for a group that the prior systematically
#' under-predicts (late bloomers, students whose growth accelerated after the
#' last interim) is the central fairness signal.
#'
#' @param policies A `ty_policies` object.
#' @param groups Named list of logical vectors (one element per examinee).
#' @return Data frame: `policy`, `group`, and the metrics of `summary()`.
#' @examples
#' sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
#' op <- sim[sim$cohort == "operational", ]
#' prior <- predict(ty_link(sim), op)
#' pol <- ty_policies(ty_mst_default(), op$theta_S, prior, seed = 1)
#' fair <- ty_fairness(pol, list(late = op$late, fast = op$fast))
#' fair[fair$group == "fast", c("policy", "routed_too_easy", "bias")]
#' @export
ty_fairness <- function(policies, groups) {
  th <- policies$theta
  rows <- list()
  for (p in names(policies$results)) for (g in names(groups)) {
    s <- groups[[g]]
    if (!any(s)) next
    r <- policies$results[[p]][s, ]
    rows[[length(rows) + 1]] <- cbind(policy = p, group = g, policy_row(r, th[s]))
  }
  do.call(rbind, rows)
}

#' Decision accuracy and consistency: through-year vs single summative
#'
#' Compares three ways of making a proficiency decision at `cut` (theta scale):
#' \describe{
#'   \item{summative}{Single summative (cold MST, population prior).}
#'   \item{through_year}{Interim projection alone (prior mean from the link):
#'     the summative-replacement scenario.}
#'   \item{combined}{Summative scored with the interim prior (interims and
#'     summative both count).}
#' }
#' Accuracy is agreement with the true decision. Consistency is agreement
#' between two independent replications: two MST administrations, and two
#' independent sets of interim scores (`prior` and `prior_r2`).
#'
#' @param mst A `ty_mst`.
#' @param theta True summative abilities.
#' @param prior,prior_r2 Student priors from two independent interim sets.
#' @param cut Proficiency cut on the summative theta scale.
#' @param population Population prior `c(mean, sd)`.
#' @param groups Optional named list of logical vectors for subgroup rows.
#' @param seed Optional seed.
#' @return Data frame: `method`, `group`, `accuracy`, `consistency`,
#'   `false_proficient`, `false_not_proficient`.
#' @examples
#' sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
#' op <- sim[sim$cohort == "operational", ]
#' link <- ty_link(sim)
#' ty_decisions(ty_mst_default(), op$theta_S, predict(link, op),
#'              predict(link, op, suffix = "_r2"), cut = 0.3,
#'              groups = list(fast = op$fast), seed = 1)
#' @export
ty_decisions <- function(mst, theta, prior, prior_r2, cut, population = NULL,
                         groups = NULL, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (is.null(population))
    population <- c(mean(prior$mean), sqrt(stats::var(prior$mean) + mean(prior$sd^2)))
  pop <- list(mean = population[1], sd = population[2])
  s1 <- ty_administer(mst, theta, pop, pop)
  s2 <- ty_administer(mst, theta, pop, pop)
  c1 <- ty_administer(mst, theta, prior, prior)
  c2 <- ty_administer(mst, theta, prior_r2, prior_r2)
  d <- list(summative = cbind(s1$theta_hat, s2$theta_hat),
            through_year = cbind(prior$mean, prior_r2$mean),
            combined = cbind(c1$theta_hat, c2$theta_hat))
  truth <- theta >= cut
  if (is.null(groups)) groups <- list()
  groups <- c(list(all = rep(TRUE, length(theta))), groups)
  rows <- list()
  for (m in names(d)) for (g in names(groups)) {
    s <- groups[[g]]
    dec <- d[[m]][s, , drop = FALSE] >= cut
    rows[[length(rows) + 1]] <- data.frame(
      method = m, group = g, n = sum(s),
      accuracy = mean(dec[, 1] == truth[s]),
      consistency = mean(dec[, 1] == dec[, 2]),
      false_proficient = mean(dec[, 1] & !truth[s]),
      false_not_proficient = mean(!dec[, 1] & truth[s]), stringsAsFactors = FALSE)
  }
  do.call(rbind, rows)
}
