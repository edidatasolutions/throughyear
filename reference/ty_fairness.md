# Fairness diagnostics for prior-informed routing and scoring

For each policy and group, reports routing accuracy, the rate of being
routed to an easier module than the one most informative at the
student's true ability (the "locked into an easier path" concern), and
bias and RMSE of the reported score. Bias for a group that the prior
systematically under-predicts (late bloomers, students whose growth
accelerated after the last interim) is the central fairness signal.

## Usage

``` r
ty_fairness(policies, groups)
```

## Arguments

- policies:

  A \`ty_policies\` object.

- groups:

  Named list of logical vectors (one element per examinee).

## Value

Data frame: \`policy\`, \`group\`, and the metrics of \`summary()\`.

## Examples

``` r
sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
op <- sim[sim$cohort == "operational", ]
prior <- predict(ty_link(sim), op)
pol <- ty_policies(ty_mst_default(), op$theta_S, prior, seed = 1)
fair <- ty_fairness(pol, list(late = op$late, fast = op$fast))
fair[fair$group == "fast", c("policy", "routed_too_easy", "bias")]
#>         policy routed_too_easy        bias
#> 2         cold       0.1162791 -0.08065422
#> 4  prior_route       0.2325581 -0.03858849
#> 6   prior_both       0.2325581 -0.29279601
#> 8  prior_short       0.3023256 -0.01788807
#> 10  prior_only       0.3255814 -0.11648421
```
