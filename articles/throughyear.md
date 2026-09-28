# Evaluating a through-year assessment system

In a through-year model, interims given during the year feed into, or
partly replace, the spring summative. throughyear treats the whole
system as the unit of analysis.

## Two cohorts

Last year’s cohort (calibration) has interims and summative scores; this
year’s cohort (operational) has only interims. Some students enrolled
late and missed interims. Others (“fast growers”) gained ground after
the last interim, which interims cannot reveal.

``` r

library(throughyear)
sim <- ty_simulate(n_calibration = 1500, n_operational = 1500, seed = 11)
head(sim[c("cohort", "late", "fast", "I1", "I2", "I3", "S")])
#>        cohort  late  fast       I1       I2       I3          S
#> 1 calibration FALSE FALSE 189.7451 194.2627 205.1059  0.1309086
#> 2 calibration FALSE FALSE 199.4090 201.6093 201.5448  0.5601257
#> 3 calibration FALSE FALSE 177.0745 179.7455 187.0588 -1.3871895
#> 4 calibration  TRUE FALSE       NA       NA 194.8215 -0.5202908
#> 5 calibration FALSE FALSE 202.2683 205.9519 209.8681  0.5491410
#> 6 calibration FALSE FALSE 188.7954 192.8429 196.2195 -0.9826085
```

## Link interims to the summative scale

``` r

link <- ty_link(sim)
link
#> <ty_link> 3000 students | 3 interims -> S | EM converged in 189 iterations
#> latent means:
#>      I1      I2      I3       S 
#> 195.458 197.323 199.073   0.087 
#> latent correlations:
#>       I1    I2    I3     S
#> I1 1.000 0.994 0.989 0.965
#> I2 0.994 1.000 0.994 0.976
#> I3 0.989 0.994 1.000 0.981
#> S  0.965 0.976 0.981 1.000
op <- sim[sim$cohort == "operational", ]
prior <- predict(link, op)
aggregate(prior$sd, list(late_enroller = op$late), mean)
#>   late_enroller         x
#> 1         FALSE 0.3316873
#> 2          TRUE 0.4455323
```

Measurement error is carried forward: fewer or noisier interims give
wider priors, not wrong ones.

## Routing policies

``` r

mst <- ty_mst_default()
pol <- ty_policies(mst, op$theta_S, prior, seed = 1)
summary(pol)[c("policy", "routing_accuracy", "mean_items", "bias", "rmse")]
#>        policy routing_accuracy mean_items          bias      rmse
#> 1        cold        0.7093333         36  0.0009719754 0.3399590
#> 2 prior_route        0.8586667         36  0.0008716408 0.3435161
#> 3  prior_both        0.8493333         36 -0.0064346982 0.2452487
#> 4 prior_short        0.8540000         30  0.0039293059 0.3789190
#> 5  prior_only        0.8340000         24 -0.0080730354 0.4099369
```

## Fairness

``` r

fair <- ty_fairness(pol, list(late = op$late, fast = op$fast))
fair[c("policy", "group", "routed_too_easy", "bias")]
#>         policy group routed_too_easy        bias
#> 1         cold  late      0.15602837 -0.01764066
#> 2         cold  fast      0.17266187 -0.06216104
#> 3  prior_route  late      0.07092199  0.04052520
#> 4  prior_route  fast      0.30215827 -0.08633598
#> 5   prior_both  late      0.07801418 -0.01236379
#> 6   prior_both  fast      0.31654676 -0.31137606
#> 7  prior_short  late      0.07092199  0.05851682
#> 8  prior_short  fast      0.33093525 -0.08946388
#> 9   prior_only  late      0.10638298  0.01009961
#> 10  prior_only  fast      0.35971223 -0.06105708
```

Scoring with the interim prior biases fast growers downward; using the
prior only for routing keeps their reported scores unbiased.

## Can a through-year score replace the summative?

``` r

ty_decisions(mst, op$theta_S, prior, predict(link, op, suffix = "_r2"),
             cut = 0.3, groups = list(fast = op$fast), seed = 2)
#>         method group    n  accuracy consistency false_proficient
#> 1    summative   all 1500 0.8980000   0.8393333       0.05266667
#> 2    summative  fast  139 0.9136691   0.8345324       0.04316547
#> 3 through_year   all 1500 0.9080000   0.8893333       0.04133333
#> 4 through_year  fast  139 0.7769784   0.8201439       0.00000000
#> 5     combined   all 1500 0.9353333   0.9080000       0.03466667
#> 6     combined  fast  139 0.9064748   0.8848921       0.00000000
#>   false_not_proficient
#> 1           0.04933333
#> 2           0.04316547
#> 3           0.05066667
#> 4           0.22302158
#> 5           0.03000000
#> 6           0.09352518
```
