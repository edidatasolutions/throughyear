# Replication study for the throughyear manuscript: the design of
# known_truth.R over independent seeds (means with Monte Carlo SEs).
# Usage: Rscript inst/validation/replication_study.R [n_reps] [n_workers]
args <- commandArgs(trailingOnly = TRUE)
n_reps <- if (length(args) >= 1) as.integer(args[1]) else 100
n_workers <- if (length(args) >= 2) as.integer(args[2]) else max(1, parallel::detectCores() - 2)

one_rep <- function(seed) {
  suppressPackageStartupMessages(library(throughyear))
  sim <- ty_simulate(seed = seed)
  lk <- ty_link(sim)
  op <- sim[sim$cohort == "operational", ]
  pr <- predict(lk, op); pr2 <- predict(lk, op, suffix = "_r2")
  z <- (op$theta_S - pr$mean) / pr$sd
  low <- pr$mean < stats::quantile(pr$mean, 0.2)
  groups <- list(all = rep(TRUE, nrow(op)), late = op$late, fast = op$fast, low = low)
  tv <- cbind(200 + 10 * sim$theta_I1, 200 + 10 * sim$theta_I2, 200 + 10 * sim$theta_I3, sim$theta_S)
  out <- list(seed = seed, link_converged = lk$converged,
              link_max_cor_err = max(abs(stats::cov2cor(lk$Sigma) - stats::cor(tv))))
  for (g in names(groups)) {
    s <- groups[[g]]
    out[[paste0("z_mean_", g)]] <- mean(z[s]); out[[paste0("z_sd_", g)]] <- stats::sd(z[s])
    out[[paste0("cover90_", g)]] <- mean(abs(z[s]) < 1.645); out[[paste0("prior_sd_", g)]] <- mean(pr$sd[s])
  }
  mst <- ty_mst_default()
  pol <- ty_policies(mst, op$theta_S, pr, seed = seed)
  s <- summary(pol)
  for (i in seq_len(nrow(s))) for (v in c("routing_accuracy", "routed_too_easy", "mean_items", "bias", "rmse"))
    out[[paste0(s$policy[i], "_", v)]] <- s[[v]][i]
  fr <- ty_fairness(pol, groups[-1])
  for (i in seq_len(nrow(fr))) for (v in c("routed_too_easy", "bias", "rmse"))
    out[[paste0("fair_", fr$group[i], "_", fr$policy[i], "_", v)]] <- fr[[v]][i]
  dec <- ty_decisions(mst, op$theta_S, pr, pr2, cut = 0.3, groups = groups[c("late", "fast")], seed = seed)
  for (i in seq_len(nrow(dec))) for (v in c("accuracy", "consistency", "false_proficient", "false_not_proficient"))
    out[[paste0("dec_", dec$group[i], "_", dec$method[i], "_", v)]] <- dec[[v]][i]
  as.data.frame(out)
}

t0 <- Sys.time()
cl <- parallel::makeCluster(n_workers)
invisible(parallel::clusterCall(cl, function(p) .libPaths(c(p, .libPaths())), .libPaths()[1]))
res <- do.call(rbind, parallel::parLapply(cl, 50000 + seq_len(n_reps), one_rep))
parallel::stopCluster(cl)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
out_dir <- if (dir.exists("inst/validation")) "inst/validation" else "."
saveRDS(res, file.path(out_dir, "replication_results.rds"))

mse <- function(v) { v <- v[!is.na(v)]; c(mean(v), stats::sd(v) / sqrt(length(v))) }
fmt <- function(v, d = 3) { m <- mse(v); sprintf(paste0("%.", d, "f (%.", d, "f)"), m[1], m[2]) }
cat(sprintf("Replications: %d | workers: %d | %.1f minutes\nValues: mean (Monte Carlo SE)\n\n", nrow(res), n_workers, elapsed))
cat("Linking: converged", mean(res$link_converged), "| max latent correlation error", fmt(res$link_max_cor_err, 4), "\n")
for (g in c("all", "late", "fast", "low"))
  cat(sprintf("  %-5s z mean %s, z SD %s, 90%% coverage %s, prior SD %s\n", g, fmt(res[[paste0("z_mean_", g)]]),
              fmt(res[[paste0("z_sd_", g)]]), fmt(res[[paste0("cover90_", g)]]), fmt(res[[paste0("prior_sd_", g)]])))
cat("\nTable 1. Policies\n")
for (p in c("cold", "prior_route", "prior_both", "prior_short", "prior_only"))
  cat(sprintf("  %-12s routing %s | items %s | bias %s | RMSE %s\n", p, fmt(res[[paste0(p, "_routing_accuracy")]]),
              fmt(res[[paste0(p, "_mean_items")]], 1), fmt(res[[paste0(p, "_bias")]]), fmt(res[[paste0(p, "_rmse")]])))
cat("\nTable 2. Fairness: routed too easy | bias\n")
for (g in c("fast", "late", "low")) for (p in c("cold", "prior_route", "prior_both", "prior_only"))
  cat(sprintf("  %-5s %-12s %s | %s\n", g, p, fmt(res[[sprintf("fair_%s_%s_routed_too_easy", g, p)]]),
              fmt(res[[sprintf("fair_%s_%s_bias", g, p)]])))
cat("\nTable 3. Decisions at theta = 0.3: accuracy | consistency | false not-proficient\n")
for (g in c("all", "fast", "late")) for (m in c("summative", "through_year", "combined"))
  cat(sprintf("  %-5s %-13s %s | %s | %s\n", g, m, fmt(res[[sprintf("dec_%s_%s_accuracy", g, m)]]),
              fmt(res[[sprintf("dec_%s_%s_consistency", g, m)]]), fmt(res[[sprintf("dec_%s_%s_false_not_proficient", g, m)]])))
