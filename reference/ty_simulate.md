# Simulate a through-year system with known true growth

Students grow linearly, \`theta(t) = theta0 + g \* t\`, and take
interims at \`times\` (reported on their own scale, \`scale\[1\] +
scale\[2\] \* theta\`, with error from a Rasch form of \`interim_items\`
items) and the summative at t = 1. Late enrollers miss the first
\`late_missing\` interims. "Fast growers" gain an extra \`fast_extra\`
logits after the last interim (e.g. a spring intervention), which
interims cannot reveal. They are the hardest case for prior-informed
scoring.

## Usage

``` r
ty_simulate(
  n_calibration = 3000,
  n_operational = 3000,
  times = c(0.2, 0.5, 0.8),
  theta0_mean = -0.6,
  theta0_sd = 1,
  growth_mean = 0.6,
  growth_sd = 0.25,
  p_fast = 0.1,
  fast_extra = 0.6,
  p_late = 0.1,
  late_missing = 2,
  scale = c(200, 10),
  interim_items = 30,
  summative_se = 0.3,
  seed = NULL
)
```

## Arguments

- n_calibration, n_operational:

  Cohort sizes.

- times:

  Interim occasions as fractions of the year.

- theta0_mean, theta0_sd, growth_mean, growth_sd:

  True-score model.

- p_fast, fast_extra:

  Share of fast growers and their extra growth.

- p_late, late_missing:

  Share of late enrollers and interims they miss.

- scale:

  Interim reporting scale: intercept and slope.

- interim_items:

  Items per interim form (sets measurement error).

- summative_se:

  SE of the calibration cohort's summative scores.

- seed:

  Optional seed.

## Value

A \`ty_sim\` data frame, one row per student.

## Details

Two cohorts: \`calibration\` (last year: summative observed, used to
link) and \`operational\` (this year: summative not yet taken). A
second, independent set of interim scores (\`\*\_r2\`) supports
decision-consistency analyses.

## Examples

``` r
sim <- ty_simulate(n_calibration = 300, n_operational = 300, seed = 1)
head(sim[c("id", "cohort", "late", "fast", "I1", "I2", "I3", "S")])
#>       id      cohort  late  fast       I1       I2       I3          S
#> 1 S00001 calibration FALSE  TRUE 184.5541 196.4382 189.2712 -0.2992317
#> 2 S00002 calibration FALSE  TRUE 195.1590 193.7398 205.8098  1.3310255
#> 3 S00003 calibration FALSE FALSE 180.0460 191.0278 194.9717 -0.7313841
#> 4 S00004 calibration FALSE FALSE 217.2454 213.8085 217.6036  2.0792275
#> 5 S00005 calibration FALSE  TRUE 196.0563 199.6011 192.8997  0.7238655
#> 6 S00006 calibration FALSE FALSE 192.0438 187.3062 187.3337 -1.9784995
```
