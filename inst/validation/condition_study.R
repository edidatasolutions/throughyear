# Multi-condition simulation for the throughyear manuscript.
# Factors: items per interim form (15, 30, 45: interim precision) x share of
# fast growers (5%, 20%) x their extra growth after the last interim (0.3,
# 0.6 logits). Fixed: 3,000 calibration and 3,000 operational students, three
# interims, 10% late enrollers, 1-3 MST, proficiency cut theta = 0.3.
# Progress is appended to condition_progress.log.
# Usage: Rscript inst/validation/condition_study.R [n_reps] [n_workers]
args <- commandArgs(trailingOnly = TRUE)
n_reps <- if (length(args) >= 1) as.integer(args[1]) else 50
n_workers <- if (length(args) >= 2) as.integer(args[2]) else max(1, parallel::detectCores() - 2)
out_dir <- if (dir.exists("inst/validation")) "inst/validation" else "."
log_file <- normalizePath(file.path(out_dir, "condition_progress.log"), mustWork = FALSE)
cat("", file = log_file)

design <- expand.grid(interim_items = c(15, 30, 45), p_fast = c(0.05, 0.20), fast_extra = c(0.3, 0.6))
design$cell <- seq_len(nrow(design))
jobs <- merge(design, data.frame(rep = seq_len(n_reps)))
jobs$seed <- 150000 + jobs$cell * 1000 + jobs$rep

one_job <- function(j, log_file) {
  suppressPackageStartupMessages(library(throughyear))
  t0 <- Sys.time()
  sim <- ty_simulate(interim_items = j$interim_items, p_fast = j$p_fast, fast_extra = j$fast_extra, seed = j$seed)
  lk <- ty_link(sim)
  op <- sim[sim$cohort == "operational", ]
  pr <- predict(lk, op); pr2 <- predict(lk, op, suffix = "_r2")
  z <- (op$theta_S - pr$mean) / pr$sd
  low <- pr$mean < stats::quantile(pr$mean, 0.2)
  groups <- list(late = op$late, fast = op$fast, low = low)
  out <- data.frame(j[c("cell", "interim_items", "p_fast", "fast_extra", "rep", "seed")],
                    converged = lk$converged, cover_all = mean(abs(z) < 1.645),
                    cover_fast = mean(abs(z[op$fast]) < 1.645), cover_other = mean(abs(z[!op$fast]) < 1.645),
                    prior_sd = mean(pr$sd))
  pol <- ty_policies(ty_mst_default(), op$theta_S, pr, seed = j$seed)
  s <- summary(pol)
  for (p in c("cold", "prior_route", "prior_both")) {
    out[[paste0(p, "_routing")]] <- s$routing_accuracy[s$policy == p]
    out[[paste0(p, "_rmse")]] <- s$rmse[s$policy == p]
  }
  fr <- ty_fairness(pol, groups)
  for (g in c("fast", "low")) for (p in c("cold", "prior_route", "prior_both")) {
    k <- fr$group == g & fr$policy == p
    out[[sprintf("%s_%s_bias", g, p)]] <- fr$bias[k]
    out[[sprintf("%s_%s_easy", g, p)]] <- fr$routed_too_easy[k]
  }
  dec <- ty_decisions(ty_mst_default(), op$theta_S, pr, pr2, cut = 0.3, groups = groups["fast"], seed = j$seed)
  for (g in c("all", "fast")) for (m in c("summative", "through_year", "combined")) {
    k <- dec$group == g & dec$method == m
    out[[sprintf("%s_%s_acc", g, m)]] <- dec$accuracy[k]
    out[[sprintf("%s_%s_fnp", g, m)]] <- dec$false_not_proficient[k]
  }
  cat(sprintf("%s cell %d rep %d done in %.0fs\n", format(Sys.time(), "%H:%M:%S"), j$cell, j$rep,
              as.numeric(difftime(Sys.time(), t0, units = "secs"))), file = log_file, append = TRUE)
  out
}

t0 <- Sys.time()
cl <- parallel::makeCluster(n_workers)
invisible(parallel::clusterCall(cl, function(p) .libPaths(c(p, .libPaths())), .libPaths()[1]))
res <- do.call(rbind, parallel::parLapplyLB(cl, split(jobs, seq_len(nrow(jobs))), one_job, log_file = log_file))
parallel::stopCluster(cl)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
saveRDS(res, file.path(out_dir, "condition_results.rds"))
cat(sprintf("Conditions: %d | replications per condition: %d | %.1f minutes\n", nrow(design), n_reps, elapsed))
