# Define a two-stage multistage test

Define a two-stage multistage test

## Usage

``` r
ty_mst(routing_b, modules, cuts = NULL)
```

## Arguments

- routing_b:

  Rasch difficulties of the routing module, in the order items would be
  dropped from the end when the module is shortened.

- modules:

  Named list of second-stage modules (difficulty vectors), ordered from
  easiest to hardest.

- cuts:

  Routing cuts on theta; by default the points where adjacent modules'
  information functions cross.

## Value

A \`ty_mst\`.

## Examples

``` r
mst <- ty_mst(routing_b = seq(-1.5, 1.5, length.out = 10),
              modules = list(easy = rnorm(20, -1, 0.5), hard = rnorm(20, 1, 0.5)))
mst$cuts   # where the two modules' information functions cross
#> [1] 0.002470153
```
