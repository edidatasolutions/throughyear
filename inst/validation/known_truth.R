# Known-truth validation for throughyear, 3 replications.
# 3,000 calibration + 3,000 operational students; 3 interims (reported on a
# 200 + 10*theta scale); 10% late enrollers (miss 2 interims); 10% fast
# growers (+0.6 logits after the last interim); 1-3 MST summative.
library(throughyear)

reps <- 3
cal_rows <- list(); pol_rows <- list(); fair_rows <- list(); dec_rows <- list()
mst <- ty_mst_default()
for (rep in seq_len(reps)) {
  sim <- ty_simulate(seed = 700 + rep)
  lk <- ty_link(sim)
  op <- sim[sim$cohort == "operational", ]
  pr <- predict(lk, op); pr2 <- predict(lk, op, suffix = "_r2")
  z <- (op$theta_S - pr$mean) / pr$sd
  low <- pr$mean < stats::quantile(pr$mean, 0.2)
  groups <- list(all = rep(TRUE, nrow(op)), late = op$late, fast = op$fast,
                 low_interim = low)
  for (g in names(groups)) {
    s <- groups[[g]]
    cal_rows[[length(cal_rows) + 1]] <- data.frame(group = g, z_mean = mean(z[s]),
      z_sd = sd(z[s]), cover90 = mean(abs(z[s]) < 1.645), prior_sd = mean(pr$sd[s]))
  }
  pol <- ty_policies(mst, op$theta_S, pr, seed = rep)
  pol_rows[[rep]] <- summary(pol)
  fair_rows[[rep]] <- ty_fairness(pol, groups[-1])
  dec_rows[[rep]] <- ty_decisions(mst, op$theta_S, pr, pr2, cut = 0.3,
                                  groups = groups[c("late", "fast")], seed = rep)
}
agg <- function(df, by) {
  num <- vapply(df, is.numeric, TRUE) & !(names(df) %in% by)
  out <- stats::aggregate(df[num], df[by], mean)
  out
}
cat("Linking: calibration of summative priors (z = (true - prior mean) / prior sd)\n")
print(agg(do.call(rbind, cal_rows), "group"), digits = 3, row.names = FALSE)
cat("\nRouting and scoring policies:\n")
print(agg(do.call(rbind, pol_rows), "policy"), digits = 3, row.names = FALSE)
cat("\nFairness by group:\n")
f <- agg(do.call(rbind, fair_rows), c("group", "policy"))
print(f[order(f$group, f$policy), c("group", "policy", "routing_accuracy",
                                    "routed_too_easy", "bias", "rmse")],
      digits = 3, row.names = FALSE)
cat("\nProficiency decisions at theta = 0.3:\n")
d <- agg(do.call(rbind, dec_rows), c("group", "method"))
print(d[order(d$group, d$method), c("group", "method", "accuracy", "consistency",
                                    "false_proficient", "false_not_proficient")],
      digits = 3, row.names = FALSE)
