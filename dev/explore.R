for (f in list.files("C:/Users/User/Documents/throughyear/R", full.names = TRUE)) source(f)
t0 <- Sys.time()
sim <- ty_simulate(seed = 1)
lk <- ty_link(sim)
cat("link:", format(Sys.time() - t0), "\n"); print(lk)
op <- sim[sim$cohort == "operational", ]
pr <- predict(lk, op)
z <- (op$theta_S - pr$mean) / pr$sd
cat("prior z mean/sd (all):", mean(z), sd(z), " 90% cover:", mean(abs(z) < 1.645), "\n")
for (g in c("late", "fast")) {
  s <- op[[g]]
  cat(g, ": z mean", round(mean(z[s]), 3), " cover90", round(mean(abs(z[s]) < 1.645), 3),
      " mean prior sd", round(mean(pr$sd[s]), 3), " vs others", round(mean(pr$sd[!s]), 3), "\n")
}
mst <- ty_mst_default(center = 0)
cat("cuts:", mst$cuts, "\n")
t0 <- Sys.time()
pol <- ty_policies(mst, op$theta_S, pr, seed = 10)
cat("policies:", format(Sys.time() - t0), "\n")
print(summary(pol), digits = 3)
low <- pr$mean < quantile(pr$mean, 0.2)
print(ty_fairness(pol, list(late = op$late, fast = op$fast, low_interim = low,
                            fast_high = op$fast & op$theta_S > mst$cuts[2])), digits = 3)
pr2 <- predict(lk, op, suffix = "_r2")
print(ty_decisions(mst, op$theta_S, pr, pr2, cut = 0.3, groups = list(late = op$late, fast = op$fast), seed = 3),
      digits = 3)
