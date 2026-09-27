module_info <- function(theta, b) {
  vapply(theta, function(t) { p <- stats::plogis(t - b); sum(p * (1 - p)) }, 0)
}

#' Define a two-stage multistage test
#'
#' @param routing_b Rasch difficulties of the routing module, in the order
#'   items would be dropped from the end when the module is shortened.
#' @param modules Named list of second-stage modules (difficulty vectors),
#'   ordered from easiest to hardest.
#' @param cuts Routing cuts on theta; by default the points where adjacent
#'   modules' information functions cross.
#' @return A `ty_mst`.
#' @examples
#' mst <- ty_mst(routing_b = seq(-1.5, 1.5, length.out = 10),
#'               modules = list(easy = rnorm(20, -1, 0.5), hard = rnorm(20, 1, 0.5)))
#' mst$cuts   # where the two modules' information functions cross
#' @export
ty_mst <- function(routing_b, modules, cuts = NULL) {
  if (is.null(names(modules))) names(modules) <- paste0("M", seq_along(modules))
  if (is.null(cuts)) {
    cuts <- vapply(seq_len(length(modules) - 1), function(m) {
      f <- function(t) module_info(t, modules[[m]]) - module_info(t, modules[[m + 1]])
      stats::uniroot(f, c(mean(modules[[m]]), mean(modules[[m + 1]])))$root
    }, 0)
  }
  structure(list(routing_b = routing_b, modules = modules, cuts = cuts), class = "ty_mst")
}

#' A default 1-3 MST: 12 routing items, easy/medium/hard modules of 24
#' @param center Center of the difficulty range.
#' @return A `ty_mst`.
#' @examples
#' ty_mst_default()$cuts
#' @export
ty_mst_default <- function(center = 0) {
  q <- stats::qnorm(stats::ppoints(24))
  # Interleave routing difficulties so shortened modules stay centered.
  rb <- center + stats::qnorm(stats::ppoints(12)) * 0.9
  ord <- order(abs(rb - center))
  ty_mst(rb[ord], list(easy = center - 1.1 + 0.5 * q, medium = center + 0.5 * q,
                       hard = center + 1.1 + 0.5 * q))
}

grid_ll <- function(X, b, grid) {
  lp <- stats::plogis(outer(b, grid, function(bb, g) g - bb))
  X %*% log(lp) + (1 - X) %*% log(1 - lp)
}

eap <- function(LL, prior_mean, prior_sd, grid) {
  pm <- rep_len(prior_mean, nrow(LL)); ps <- rep_len(prior_sd, nrow(LL))
  # Row n is divided by ps[n] (column-major recycling of a length-N vector).
  lp <- stats::dnorm(outer(pm, grid, function(m, g) g - m) / ps, log = TRUE) - log(ps)
  post <- LL + lp
  W <- exp(post - apply(post, 1, max)); W <- W / rowSums(W)
  m <- drop(W %*% grid)
  list(mean = m, sd = sqrt(pmax(drop(W %*% grid^2) - m^2, 0)))
}

#' Administer a two-stage MST to simulated examinees
#'
#' Routing uses the EAP after the (possibly shortened) routing module under
#' `route_prior`. With `routing_n = 0` the routing decision uses the prior
#' alone. The final score is the EAP over all administered items under
#' `score_prior`. Priors are lists with `mean` and `sd` (scalars or one value
#' per examinee).
#'
#' @param mst A `ty_mst`.
#' @param theta True abilities.
#' @param route_prior,score_prior Priors for routing and for scoring.
#' @param routing_n Routing items used (default: all).
#' @param grid Theta grid.
#' @param seed Optional seed.
#' @return Data frame: `module`, `correct_module` (most informative module at
#'   the true theta), `route_eap`, `theta_hat`, `se`, `n_items`.
#' @examples
#' mst <- ty_mst_default()
#' pop <- list(mean = 0, sd = 1)
#' res <- ty_administer(mst, theta = rnorm(500), route_prior = pop, score_prior = pop, seed = 1)
#' mean(res$module == res$correct_module)   # routing accuracy
#' @export
ty_administer <- function(mst, theta, route_prior, score_prior, routing_n = NULL,
                          grid = seq(-5, 5, by = 0.05), seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  N <- length(theta)
  if (is.null(routing_n)) routing_n <- length(mst$routing_b)
  rb <- mst$routing_b[seq_len(routing_n)]
  sim_resp <- function(b) {
    matrix(stats::rbinom(N * length(b), 1, stats::plogis(outer(theta, b, "-"))), N)
  }
  LLr <- if (routing_n > 0) grid_ll(sim_resp(rb), rb, grid) else matrix(0, N, length(grid))
  re <- eap(LLr, route_prior$mean, route_prior$sd, grid)
  mod <- findInterval(re$mean, mst$cuts) + 1
  LL2 <- matrix(0, N, length(grid))
  for (m in seq_along(mst$modules)) {
    s <- mod == m
    if (!any(s)) next
    b <- mst$modules[[m]]
    X <- matrix(stats::rbinom(sum(s) * length(b), 1, stats::plogis(outer(theta[s], b, "-"))), sum(s))
    LL2[s, ] <- grid_ll(X, b, grid)
  }
  sm <- rep_len(score_prior$mean, N); ss <- rep_len(score_prior$sd, N)
  fe <- eap(LLr + LL2, sm, ss, grid)
  info <- vapply(mst$modules, function(b) module_info(theta, b), numeric(N))
  info <- matrix(info, nrow = N)
  data.frame(module = mod, correct_module = max.col(info, ties.method = "first"),
             route_eap = re$mean, theta_hat = fe$mean, se = fe$sd,
             n_items = routing_n + lengths(mst$modules)[mod])
}
