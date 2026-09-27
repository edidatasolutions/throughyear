library(throughyear)
ns <- asNamespace("throughyear")

# 1. Batched linear algebra matches base R --------------------------------------
set.seed(1)
A <- crossprod(matrix(rnorm(16), 4)) + diag(4)
d <- matrix(runif(20), 5, 4)
S <- array(rep(A, each = 5), c(5, 4, 4)); for (j in 1:4) S[, j, j] <- S[, j, j] + d[, j]
L <- ns$batch_chol(S); b <- matrix(rnorm(20), 5)
x <- ns$batch_solve(L, b)
for (n in 1:5) stopifnot(max(abs(x[n, ] - solve(A + diag(d[n, ]), b[n, ]))) < 1e-10)

# 2. Linking recovers the latent structure; priors are calibrated ------------------
sim <- ty_simulate(n_calibration = 2000, n_operational = 2000, seed = 3)
lk <- ty_link(sim)
stopifnot(lk$converged)
tv <- cbind(200 + 10 * sim$theta_I1, 200 + 10 * sim$theta_I2, 200 + 10 * sim$theta_I3, sim$theta_S)
stopifnot(max(abs(stats::cov2cor(lk$Sigma) - cor(tv))) < 0.01,
          max(abs(lk$mu - colMeans(tv)) / apply(tv, 2, sd)) < 0.05)   # in SD units
op <- sim[sim$cohort == "operational", ]
pr <- predict(lk, op)
z <- (op$theta_S - pr$mean) / pr$sd
# Calibrated for the population as a whole. (Within hidden subgroups it is
# not: the fast growers' extra growth raises the linked mean for everyone.)
stopifnot(abs(mean(z)) < 0.1, abs(sd(z) - 1) < 0.1,
          abs(mean(abs(z) < 1.645) - 0.9) < 0.03,
          mean(pr$sd[op$late]) > mean(pr$sd[!op$late]) + 0.05,   # fewer interims -> wider prior
          all(pr$n_interims[op$late] == 1))
# Fast growers are under-predicted: the hazard the fairness tools must expose.
stopifnot(mean(z[op$fast]) > 1)

# 3. MST mechanics ---------------------------------------------------------------------
mst <- ty_mst_default()
stopifnot(length(mst$cuts) == 2, abs(sum(mst$cuts)) < 1e-6, mst$cuts[1] < 0)
r <- ty_administer(mst, c(-3, 0, 3), list(mean = 0, sd = 1), list(mean = 0, sd = 1), seed = 1)
stopifnot(identical(r$correct_module, c(1L, 2L, 3L)), all(r$n_items == 36))
r0 <- ty_administer(mst, c(0, 0), list(mean = c(-2, 2), sd = 0.1), list(mean = 0, sd = 1),
                    routing_n = 0, seed = 1)
stopifnot(identical(r0$module, c(1, 3)), all(r0$n_items == 24))

# 4. Policies and fairness ----------------------------------------------------------------
pol <- ty_policies(mst, op$theta_S, pr, seed = 10)
s <- summary(pol)
acc <- setNames(s$routing_accuracy, s$policy)
stopifnot(acc[["prior_route"]] > acc[["cold"]] + 0.05,
          s$rmse[s$policy == "prior_both"] < s$rmse[s$policy == "cold"])
fr <- ty_fairness(pol, list(fast = op$fast))
bias <- setNames(fr$bias, fr$policy)
easy <- setNames(fr$routed_too_easy, fr$policy)
stopifnot(bias[["prior_both"]] < bias[["prior_route"]] - 0.1,   # scoring with the prior harms fast growers
          easy[["prior_route"]] > easy[["cold"]])                 # and routing with it sends them easier

# 5. Summative replacement ---------------------------------------------------------------------
pr2 <- predict(lk, op, suffix = "_r2")
dec <- ty_decisions(mst, op$theta_S, pr, pr2, cut = 0.3, groups = list(fast = op$fast), seed = 4)
fnp <- function(m, g) dec$false_not_proficient[dec$method == m & dec$group == g]
stopifnot(fnp("through_year", "fast") > 2 * fnp("summative", "fast"),
          all(dec$accuracy > 0.5), all(dec$consistency > 0.5))
cat("All throughyear tests passed.\n")
