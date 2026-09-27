# Link interims to the summative scale

Latent-variable linking. The true scores on all occasions (interims on
their own reporting scales, and the summative) are jointly multivariate
normal, \`tau ~ MVN(mu, Sigma)\`. Each observed score equals its true
score plus error with the reported (known) SE, and any score may be
missing. \`mu\` and \`Sigma\` are estimated by EM from all students;
only the calibration cohort needs summative scores. Because measurement
error is modeled rather than ignored, the regression of summative on
interims is not attenuated, and a student's projection carries their own
interim precision forward.

## Usage

``` r
ty_link(
  data,
  interims = attr(data, "interims"),
  summative = "S",
  se_suffix = "_se",
  max_iter = 1000,
  tol = 1e-06
)
```

## Arguments

- data:

  Data frame with interim scores, the summative score, and their SEs.

- interims:

  Interim score columns, in time order.

- summative:

  Summative score column (NA for students without one yet).

- se_suffix:

  Suffix of the SE columns.

- max_iter, tol:

  EM controls; \`tol\` is relative to the largest parameter in
  \`Sigma\`, so it does not depend on the reporting scales.

## Value

A \`ty_link\` object with \`mu\`, \`Sigma\`, \`vars\`, \`summative\`,
\`converged\`, \`iterations\` (EM step evaluations), \`loglik\`.

## Examples

``` r
sim <- ty_simulate(n_calibration = 500, n_operational = 500, seed = 1)
link <- ty_link(sim)
link
#> <ty_link> 1000 students | 3 interims -> S | EM converged in 219 iterations
#> latent means:
#>      I1      I2      I3       S 
#> 195.156 196.779 198.660   0.057 
#> latent correlations:
#>       I1    I2    I3     S
#> I1 1.000 0.983 0.988 0.968
#> I2 0.983 1.000 0.993 0.992
#> I3 0.988 0.993 1.000 0.982
#> S  0.968 0.992 0.982 1.000
```
