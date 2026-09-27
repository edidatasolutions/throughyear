# Administer a two-stage MST to simulated examinees

Routing uses the EAP after the (possibly shortened) routing module under
\`route_prior\`. With \`routing_n = 0\` the routing decision uses the
prior alone. The final score is the EAP over all administered items
under \`score_prior\`. Priors are lists with \`mean\` and \`sd\`
(scalars or one value per examinee).

## Usage

``` r
ty_administer(
  mst,
  theta,
  route_prior,
  score_prior,
  routing_n = NULL,
  grid = seq(-5, 5, by = 0.05),
  seed = NULL
)
```

## Arguments

- mst:

  A \`ty_mst\`.

- theta:

  True abilities.

- route_prior, score_prior:

  Priors for routing and for scoring.

- routing_n:

  Routing items used (default: all).

- grid:

  Theta grid.

- seed:

  Optional seed.

## Value

Data frame: \`module\`, \`correct_module\` (most informative module at
the true theta), \`route_eap\`, \`theta_hat\`, \`se\`, \`n_items\`.

## Examples

``` r
mst <- ty_mst_default()
pop <- list(mean = 0, sd = 1)
res <- ty_administer(mst, theta = rnorm(500), route_prior = pop, score_prior = pop, seed = 1)
mean(res$module == res$correct_module)   # routing accuracy
#> [1] 0.708
```
