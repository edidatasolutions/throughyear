# Batched Cholesky of n symmetric q x q matrices stored as an n x q x q array.
batch_chol <- function(S) {
  q <- dim(S)[2]; L <- array(0, dim(S))
  for (j in seq_len(q)) {
    prev <- seq_len(j - 1)
    s <- S[, j, j]
    if (j > 1) s <- s - rowSums(matrix(L[, j, prev], ncol = j - 1)^2)
    L[, j, j] <- sqrt(s)
    if (j < q) for (i in (j + 1):q) {
      s <- S[, i, j]
      if (j > 1) s <- s - rowSums(matrix(L[, i, prev], ncol = j - 1) *
                                    matrix(L[, j, prev], ncol = j - 1))
      L[, i, j] <- s / L[, j, j]
    }
  }
  L
}

# Solve (L_n L_n') x_n = b_n for every n; b is n x q.
batch_solve <- function(L, b) {
  q <- ncol(b); y <- b
  for (i in seq_len(q)) {
    if (i > 1) for (k in seq_len(i - 1)) y[, i] <- y[, i] - L[, i, k] * y[, k]
    y[, i] <- y[, i] / L[, i, i]
  }
  x <- y
  for (i in rev(seq_len(q))) {
    if (i < q) for (k in (i + 1):q) x[, i] <- x[, i] - L[, k, i] * x[, k]
    x[, i] <- x[, i] / L[, i, i]
  }
  x
}

#' Link interims to the summative scale
#'
#' Latent-variable linking. The true scores on all occasions
#' (interims on their own reporting scales, and the summative) are jointly
#' multivariate normal, `tau ~ MVN(mu, Sigma)`. Each observed score equals
#' its true score plus error with the reported (known) SE, and any score may
#' be missing. `mu` and `Sigma` are estimated by EM from all students; only
#' the calibration cohort needs summative scores. Because measurement error
#' is modeled rather than ignored, the regression of summative on interims is
#' not attenuated, and a student's projection carries their own interim
#' precision forward.
#'
#' @param data Data frame with interim scores, the summative score, and their
#'   SEs.
#' @param interims Interim score columns, in time order.
#' @param summative Summative score column (NA for students without one yet).
#' @param se_suffix Suffix of the SE columns.
#' @param max_iter,tol EM controls; `tol` is relative to the largest
#'   parameter in `Sigma`, so it does not depend on the reporting scales.
#' @return A `ty_link` object with `mu`, `Sigma`, `vars`, `summative`,
#'   `converged`, `iterations` (EM step evaluations), `loglik`.
#' @examples
#' sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
#' link <- ty_link(sim)
#' link
#' @export
ty_link <- function(data, interims = attr(data, "interims"), summative = "S",
                    se_suffix = "_se", max_iter = 1000, tol = 1e-6) {
  vars <- c(interims, summative)
  Y <- as.matrix(data[vars])
  SE <- as.matrix(data[paste0(vars, se_suffix)])
  if (any(!is.na(Y) & is.na(SE))) stop("Every observed score needs an SE.")
  keep <- rowSums(!is.na(Y)) > 0
  Y <- Y[keep, , drop = FALSE]; SE <- SE[keep, , drop = FALSE]
  if (sum(!is.na(Y[, summative])) < 30) stop("Need at least 30 students with summative scores.")
  N <- nrow(Y); p <- ncol(Y)
  obs <- !is.na(Y)
  pattern <- apply(obs, 1, function(o) paste(which(o), collapse = ","))
  groups <- split(seq_len(N), pattern)
  lt <- lower.tri(diag(p), diag = TRUE)
  pack <- function(mu, Sigma) c(mu, Sigma[lt])
  unpack <- function(par) {
    S <- matrix(0, p, p); S[lt] <- par[-seq_len(p)]
    S <- S + t(S) - diag(diag(S))
    list(mu = par[seq_len(p)], Sigma = S)
  }
  # One EM step from `par`; also returns the observed-data log-likelihood at
  # `par`. Within a missingness pattern every student's covariance is
  # Soo + diag(SE_n^2), so the E-step is batched over students: it needs only
  # each student's Soo_n^-1 (y_n - mu) and the sum of the Soo_n^-1.
  em_step <- function(par) {
    u <- unpack(par); mu <- u$mu; Sigma <- u$Sigma
    M <- matrix(0, N, p); Vsum <- N * Sigma; ll <- 0
    for (grp in groups) {
      o <- obs[grp[1], ]
      Sxo <- Sigma[, o, drop = FALSE]; Soo <- Sigma[o, o, drop = FALSE]
      q <- sum(o); n <- length(grp)
      S <- array(rep(Soo, each = n), c(n, q, q))
      for (j in seq_len(q)) S[, j, j] <- S[, j, j] + SE[grp, which(o)[j]]^2
      L <- batch_chol(S)
      res <- sweep(Y[grp, o, drop = FALSE], 2, mu[o])
      x <- batch_solve(L, res)
      M[grp, ] <- sweep(x %*% t(Sxo), 2, mu, "+")
      Sinv_sum <- vapply(seq_len(q), function(k) {
        e <- matrix(0, n, q); e[, k] <- 1
        colSums(batch_solve(L, e))
      }, numeric(q))
      Vsum <- Vsum - Sxo %*% matrix(Sinv_sum, q) %*% t(Sxo)
      diagL <- vapply(seq_len(q), function(j) L[, j, j], numeric(n))
      ll <- ll - sum(log(diagL)) - 0.5 * sum(res * x)
    }
    mu_new <- colMeans(M)
    Sigma_new <- (crossprod(sweep(M, 2, mu_new)) + Vsum) / N
    list(par = pack(mu_new, Sigma_new), ll = ll)
  }
  is_pd <- function(par) {
    ev <- eigen(unpack(par)$Sigma, symmetric = TRUE, only.values = TRUE)$values
    all(ev > 1e-10)
  }

  # EM accelerated with SQUAREM (squared extrapolation), falling back to a
  # plain EM step whenever the extrapolation leaves the parameter space or
  # lowers the likelihood. Plain EM crawls here because interim true scores
  # are very highly correlated.
  par <- pack(colMeans(Y, na.rm = TRUE), diag(apply(Y, 2, stats::var, na.rm = TRUE)))
  converged <- FALSE; evals <- 0; ll_old <- -Inf
  while (evals < max_iter) {
    s1 <- em_step(par); s2 <- em_step(s1$par); evals <- evals + 2
    r <- s1$par - par; v <- s2$par - s1$par - r
    alpha <- if (sum(v^2) > 0) min(-sqrt(sum(r^2) / sum(v^2)), -1) else -1
    cand <- par - 2 * alpha * r + alpha^2 * v
    nxt <- s2$par
    if (is_pd(cand)) {
      s3 <- em_step(cand); evals <- evals + 1
      if (s3$ll >= s1$ll) nxt <- s3$par
    }
    scale <- max(abs(unpack(par)$Sigma))
    delta <- max(abs(nxt - par)) / scale
    par <- nxt
    if (delta < tol) { converged <- TRUE; break }
  }
  u <- unpack(par)
  mu <- u$mu; Sigma <- u$Sigma
  names(mu) <- vars; dimnames(Sigma) <- list(vars, vars)
  structure(list(mu = mu, Sigma = Sigma, vars = vars, interims = interims,
                 summative = summative, se_suffix = se_suffix,
                 converged = converged, iterations = evals, n = N,
                 loglik = em_step(par)$ll),
            class = "ty_link")
}

#' Projected summative score (the prior) from interims
#'
#' Conditional distribution of the summative true score given a student's
#' observed interims and their SEs. Missing interims simply drop out, so late
#' enrollers get wider priors rather than wrong ones.
#'
#' @param object A `ty_link`.
#' @param newdata Data frame with the interim columns and their SEs.
#' @param suffix Optional suffix of alternative interim columns (e.g. `"_r2"`
#'   for a replicate set); SEs are still read from the `_se` columns.
#' @param ... Unused.
#' @return Data frame: `mean`, `sd`, `n_interims`.
#' @examples
#' sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
#' link <- ty_link(sim)
#' op <- sim[sim$cohort == "operational", ]
#' prior <- predict(link, op)
#' # late enrollers get wider priors
#' aggregate(prior$sd, list(late = op$late), mean)
#' @export
predict.ty_link <- function(object, newdata, suffix = "", ...) {
  it <- object$interims; s <- object$summative
  Y <- as.matrix(newdata[paste0(it, suffix)])
  SE <- as.matrix(newdata[paste0(it, object$se_suffix)])
  Sg <- object$Sigma; mu <- object$mu
  out <- t(vapply(seq_len(nrow(Y)), function(n) {
    o <- !is.na(Y[n, ])
    if (!any(o)) return(c(mu[[s]], sqrt(Sg[s, s])))
    So <- Sg[it[o], it[o], drop = FALSE] + diag(SE[n, o]^2, sum(o))
    k <- Sg[s, it[o], drop = FALSE] %*% solve(So)
    c(mu[[s]] + drop(k %*% (Y[n, o] - mu[it[o]])),
      sqrt(max(Sg[s, s] - drop(k %*% Sg[it[o], s]), 1e-12)))
  }, numeric(2)))
  data.frame(mean = out[, 1], sd = out[, 2], n_interims = rowSums(!is.na(Y)))
}

#' @export
print.ty_link <- function(x, ...) {
  cat("<ty_link>", x$n, "students |", length(x$interims), "interims ->", x$summative,
      "| EM", if (x$converged) "converged" else "NOT converged", "in", x$iterations, "iterations\n")
  cat("latent means:\n"); print(round(x$mu, 3))
  cat("latent correlations:\n"); print(round(stats::cov2cor(x$Sigma), 3))
  invisible(x)
}
