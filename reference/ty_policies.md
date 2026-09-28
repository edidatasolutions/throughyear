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
sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
op <- sim[sim$cohort == "operational", ]
prior <- predict(ty_link(sim), op)
pol <- ty_policies(ty_mst_default(), op$theta_S, prior, seed = 1)
summary(pol)
#>        policy   n routing_accuracy routed_too_easy routed_too_hard mean_items
#> 1        cold 300             0.73      0.12000000      0.15000000         36
#> 2 prior_route 300             0.87      0.05000000      0.08000000         36
#> 3  prior_both 300             0.86      0.05666667      0.08333333         36
#> 4 prior_short 300             0.83      0.06666667      0.10333333         30
#> 5  prior_only 300             0.82      0.07000000      0.11000000         24
#>           bias      rmse   mean_se
#> 1 -0.010955884 0.3519350 0.3488391
#> 2 -0.006595008 0.3514604 0.3461850
#> 3  0.009668233 0.2565423 0.2559708
#> 4  0.012397010 0.3756825 0.3723276
#> 5 -0.021422683 0.4211025 0.4077246
```
