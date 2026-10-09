# Analysis of condition_study.R: condition means, eta-squared and figures.
# Usage: Rscript inst/validation/condition_analysis.R
dir <- if (dir.exists("inst/validation")) "inst/validation" else "."
res <- readRDS(file.path(dir, "condition_results.rds"))
fig_dir <- if (dir.exists("paper")) "paper/figures" else "figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
keys <- c("interim_items", "p_fast", "fast_extra")
res$routing_gain <- res$prior_route_routing - res$cold_routing
res$rmse_gain <- 1 - res$prior_both_rmse / res$cold_rmse
res$fast_bias_gap <- res$fast_prior_both_bias - res$fast_prior_route_bias
res$fnp_gap <- res$fast_through_year_fnp - res$fast_summative_fnp
res$acc_gap <- res$all_through_year_acc - res$all_summative_acc
cat(sprintf("Data sets: %d | converged: %.3f\n\n", nrow(res), mean(res$converged)))
vars <- c("cover_other", "cover_fast", "cold_routing", "prior_route_routing", "rmse_gain",
          "fast_prior_route_bias", "fast_prior_both_bias", "low_cold_bias", "low_prior_both_bias",
          "all_summative_acc", "all_through_year_acc", "all_combined_acc",
          "fast_summative_fnp", "fast_through_year_fnp", "fast_combined_fnp")
agg <- stats::aggregate(res[vars], res[keys], mean)
cat("Condition means\n"); print(format(agg, digits = 3), row.names = FALSE)
cat("\nRanges over conditions\n")
print(t(sapply(res[c(vars, "routing_gain", "fast_bias_gap", "fnp_gap", "acc_gap")], function(v) {
  a <- stats::aggregate(v, res[keys], mean)$x; round(c(min = min(a), max = max(a)), 3) })))
eta2 <- function(v) {
  d <- res; d[keys] <- lapply(d[keys], factor)
  a <- stats::anova(stats::lm(stats::as.formula(paste(v, "~ (interim_items + p_fast + fast_extra)^2")), d))
  stats::setNames(round(a[["Sum Sq"]] / sum(a[["Sum Sq"]]), 3), rownames(a))
}
cat("\nEta-squared\n")
print(do.call(rbind, lapply(c(routing_gain = "routing_gain", rmse_gain = "rmse_gain", fast_bias_prior_both = "fast_prior_both_bias",
                             fast_bias_gap = "fast_bias_gap", fnp_gap = "fnp_gap", acc_gap = "acc_gap", cover_fast = "cover_fast"), eta2)))

line_set <- function(y, ylab, main, ylim, ref = NULL, legend_pos = NULL) {
  graphics::plot(NA, xlim = c(12, 48), ylim = ylim, xaxt = "n", las = 1, xlab = "Items per interim form",
                 ylab = ylab, main = main)
  graphics::axis(1, at = c(15, 30, 45))
  if (!is.null(ref)) graphics::abline(h = ref, lty = 3, col = "gray60")
  i <- 0
  for (pf in c(0.05, 0.20)) for (fe in c(0.3, 0.6)) {
    i <- i + 1; s <- agg$p_fast == pf & agg$fast_extra == fe
    graphics::lines(agg$interim_items[s], y[s], type = "b", lwd = 1.4, lty = c(1, 2)[match(pf, c(0.05, 0.20))],
                    col = c("gray55", "black")[match(fe, c(0.3, 0.6))], pch = c(1, 16, 2, 17)[i])
  }
  if (!is.null(legend_pos))
    graphics::legend(legend_pos, bty = "n", cex = 0.72, lwd = 1.4,
                     legend = c("5% fast, +0.3", "5% fast, +0.6", "20% fast, +0.3", "20% fast, +0.6"),
                     lty = c(1, 1, 2, 2), col = c("gray55", "black", "gray55", "black"), pch = c(1, 16, 2, 17))
}
grDevices::png(file.path(fig_dir, "figure1_conditions.png"), width = 7, height = 3.4, units = "in", res = 300)
op <- graphics::par(mfrow = c(1, 2), mar = c(4, 4.4, 2, 0.5), cex = 0.85, cex.main = 0.95)
line_set(agg$fast_prior_both_bias, "Score bias (logits)", "(a) Fast growers: prior used to score",
         c(min(agg$fast_prior_both_bias) * 1.15, 0.02), ref = 0, legend_pos = "topright")
line_set(agg$fast_through_year_fnp - agg$fast_summative_fnp, "Difference in proportion",
         "(b) Extra false not-proficient", c(0, max(agg$fast_through_year_fnp - agg$fast_summative_fnp) * 1.1))
graphics::par(op); grDevices::dev.off()
cat("\nFigure written to", fig_dir, "\n")
