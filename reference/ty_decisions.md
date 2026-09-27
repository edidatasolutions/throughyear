# Decision accuracy and consistency: through-year vs single summative

Compares three ways of making a proficiency decision at \`cut\` (theta
scale):

- summative:

  Single summative (cold MST, population prior).

- through_year:

  Interim projection alone (prior mean from the link): the
  summative-replacement scenario.

- combined:

  Summative scored with the interim prior (interims and summative both
  count).

Accuracy is agreement with the true decision. Consistency is agreement
between two independent replications: two MST administrations, and two
independent sets of interim scores (\`prior\` and \`prior_r2\`).

## Usage

``` r
ty_decisions(
  mst,
  theta,
  prior,
  prior_r2,
  cut,
  population = NULL,
  groups = NULL,
  seed = NULL
)
```

## Arguments

- mst:

  A \`ty_mst\`.

- theta:

  True summative abilities.

- prior, prior_r2:

  Student priors from two independent interim sets.

- cut:

  Proficiency cut on the summative theta scale.

- population:

  Population prior \`c(mean, sd)\`.

- groups:

  Optional named list of logical vectors for subgroup rows.

- seed:

  Optional seed.

## Value

Data frame: \`method\`, \`group\`, \`accuracy\`, \`consistency\`,
\`false_proficient\`, \`false_not_proficient\`.

## Examples

``` r
sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
op <- sim[sim$cohort == "operational", ]
link <- ty_link(sim)
ty_decisions(ty_mst_default(), op$theta_S, predict(link, op),
             predict(link, op, suffix = "_r2"), cut = 0.3,
             groups = list(fast = op$fast), seed = 1)
#>         method group   n  accuracy consistency false_proficient
#> 1    summative   all 500 0.8980000   0.8540000            0.044
#> 2    summative  fast  43 0.9767442   0.9302326            0.000
#> 3 through_year   all 500 0.8920000   0.8720000            0.050
#> 4 through_year  fast  43 0.7906977   0.9069767            0.000
#> 5     combined   all 500 0.9280000   0.8980000            0.034
#> 6     combined  fast  43 0.9302326   0.8837209            0.000
#>   false_not_proficient
#> 1           0.05800000
#> 2           0.02325581
#> 3           0.05800000
#> 4           0.20930233
#> 5           0.03800000
#> 6           0.06976744
```
