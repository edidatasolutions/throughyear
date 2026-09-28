# Compare routing and scoring policies

Administers the MST under five policies to the same examinees:

- cold:

  Full routing module, population prior for routing and scoring.

- prior_route:

  Full routing module, student's interim prior for routing only;
  population prior for the reported score.

- prior_both:

  Interim prior for routing and for the reported score.

- prior_short:

  Interim prior for routing with a shortened routing module (\`short_n\`
  items); population prior for scoring.

- prior_only:

  Route on the interim prior alone (no routing module); population prior
  for scoring.

## Usage

``` r
ty_policies(mst, theta, prior, population = NULL, short_n = 6, seed = NULL)
```

## Arguments

- mst:

  A \`ty_mst\`.

- theta:

  True summative abilities.

- prior:

  Student priors (\`mean\`, \`sd\`) from \`predict()\` on a \`ty_link\`.

- population:

  Population prior \`c(mean, sd)\`; default: moments of the student
  priors' implied marginal.

- short_n:

  Routing items for \`prior_short\`.

- seed:

  Optional seed (each policy gets its own stream).

## Value

A \`ty_policies\` object: named list of \[ty_administer()\] results,
plus \`theta\`.

## Examples

``` r
sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
op <- sim[sim$cohort == "operational", ]
prior <- predict(ty_link(sim), op)
pol <- ty_policies(ty_mst_default(), op$theta_S, prior, seed = 1)
summary(pol)
#>        policy   n routing_accuracy routed_too_easy routed_too_hard mean_items
#> 1        cold 500            0.688           0.156           0.156         36
#> 2 prior_route 500            0.848           0.062           0.090         36
#> 3  prior_both 500            0.870           0.064           0.066         36
#> 4 prior_short 500            0.840           0.074           0.086         30
#> 5  prior_only 500            0.844           0.068           0.088         24
#>           bias      rmse   mean_se
#> 1 -0.022841197 0.3673707 0.3505375
#> 2  0.007636885 0.3491542 0.3497850
#> 3  0.018125193 0.2584345 0.2431927
#> 4  0.003427651 0.3758321 0.3748904
#> 5 -0.008561548 0.4233342 0.4114557
```
