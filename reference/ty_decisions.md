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
sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
op <- sim[sim$cohort == "operational", ]
link <- ty_link(sim)
ty_decisions(ty_mst_default(), op$theta_S, predict(link, op),
             predict(link, op, suffix = "_r2"), cut = 0.3,
             groups = list(fast = op$fast), seed = 1)
#>         method group   n  accuracy consistency false_proficient
#> 1    summative   all 300 0.9266667   0.8500000       0.03666667
#> 2    summative  fast  30 1.0000000   0.8666667       0.00000000
#> 3 through_year   all 300 0.9033333   0.9066667       0.03666667
#> 4 through_year  fast  30 0.7666667   1.0000000       0.00000000
#> 5     combined   all 300 0.9266667   0.9000000       0.02000000
#> 6     combined  fast  30 0.8000000   0.8000000       0.00000000
#>   false_not_proficient
#> 1           0.03666667
#> 2           0.00000000
#> 3           0.06000000
#> 4           0.23333333
#> 5           0.05333333
#> 6           0.20000000
```
