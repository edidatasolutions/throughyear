# Projected summative score (the prior) from interims

Conditional distribution of the summative true score given a student's
observed interims and their SEs. Missing interims simply drop out, so
late enrollers get wider priors rather than wrong ones.

## Usage

``` r
# S3 method for class 'ty_link'
predict(object, newdata, suffix = "", ...)
```

## Arguments

- object:

  A \`ty_link\`.

- newdata:

  Data frame with the interim columns and their SEs.

- suffix:

  Optional suffix of alternative interim columns (e.g. \`"\_r2"\` for a
  replicate set); SEs are still read from the \`\_se\` columns.

- ...:

  Unused.

## Value

Data frame: \`mean\`, \`sd\`, \`n_interims\`.

## Examples

``` r
sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
link <- ty_link(sim)
op <- sim[sim$cohort == "operational", ]
prior <- predict(link, op)
# late enrollers get wider priors
aggregate(prior$sd, list(late = op$late), mean)
#>    late         x
#> 1 FALSE 0.3132153
#> 2  TRUE 0.4598928
```
