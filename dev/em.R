for (f in list.files("C:/Users/User/Documents/throughyear/R", full.names = TRUE)) source(f)
sim <- ty_simulate(seed = 1)
t0 <- Sys.time(); lk <- ty_link(sim); cat("link:", format(Sys.time() - t0), "\n"); print(lk)
cat("loglik", lk$loglik, "\n")
op <- sim[sim$cohort == "operational", ]
pr <- predict(lk, op)
z <- (op$theta_S - pr$mean) / pr$sd
cat("prior z mean/sd:", mean(z), sd(z), " cover90:", mean(abs(z) < 1.645), "\n")
# Truth for the latent covariance: summative true score vs interim true scores
cal <- sim
tv <- cbind(10 * cal$theta_I1 + 200, 10 * cal$theta_I2 + 200, 10 * cal$theta_I3 + 200, cal$theta_S)
cat("true latent correlations:\n"); print(round(cor(tv), 3))
cat("true latent means:", round(colMeans(tv), 3), "\n")
