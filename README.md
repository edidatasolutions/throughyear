# throughyear

**The through-year system, not the single test, as the unit of analysis.**

States are moving to through-year models, in which interims given during the
year feed into or partly replace the spring summative (for example, interims
routing into a multistage end-of-grade test). throughyear answers the
questions every state now scripts by hand:

- How do interims link to the summative scale, uncertainty included?
- Does routing on interim priors beat a cold start?
- Do priors lock some students into easier paths or biased scores?
- Is a through-year score defensible as a replacement for the summative?

```r
library(throughyear)

sim  <- ty_simulate(seed = 1)                     # or your data
link <- ty_link(sim)                              # latent MVN, EM, missing interims OK
op   <- sim[sim$cohort == "operational", ]
pr   <- predict(link, op)                         # summative prior per student

mst  <- ty_mst_default()                          # 12-item router, 3 x 24-item modules
pol  <- ty_policies(mst, op$theta_S, pr)          # cold vs prior-informed policies
summary(pol)
ty_fairness(pol, list(late = op$late, fast = op$fast))
ty_decisions(mst, op$theta_S, pr, predict(link, op, suffix = "_r2"), cut = 0.3)
```

## Installation

From CRAN (once released):

```r
install.packages("throughyear")
```

Development version from GitHub:

```r
install.packages("pak")
pak::pak("edidatasolutions/throughyear")
```

## Linking

All occasions' true scores (interims on their own reporting scales, and the
summative) are jointly multivariate normal. Observed scores add known
measurement error, and any score may be missing. EM uses SQUAREM acceleration
and an E-step batched by missingness pattern, which makes it fast even though
interim true scores correlate around 0.99. A student's summative prior is
the conditional distribution given their interims, so measurement error
carries forward and late enrollers get wider priors rather than wrong ones.

## Validation (known truth, 3 replications, `inst/validation/known_truth.R`)

3,000 calibration and 3,000 operational students; 3 interims; 10% late
enrollers missing 2 interims; 10% "fast growers" who gain +0.6 logits after
the last interim.

**Priors are calibrated:** z mean 0.02, SD 0.99, 90% intervals cover 90.5%.
Late enrollers get wider priors (0.45 vs 0.35) that are still calibrated
(coverage 91%). Latent correlations are recovered to within 0.01.

**Policies** (1-3 MST):

| policy | routing accuracy | items | RMSE |
|---|---|---|---|
| cold start | 70% | 36 | 0.35 |
| prior for routing only | 84% | 36 | 0.35 |
| prior for routing and scoring | 84% | 36 | 0.25 |
| prior + 6-item router | 84% | 30 | 0.38 |
| prior only, no router | 83% | 24 | 0.42 |

**Fairness is not one-directional:**

| group | policy | routed too easy | score bias |
|---|---|---|---|
| fast growers | cold | 15% | -0.05 |
| fast growers | prior routing only | 28% | -0.04 |
| fast growers | prior routing + scoring | 30% | **-0.30** |
| lowest interim quintile | cold | 2% | **+0.15** |
| lowest interim quintile | prior routing + scoring | 6% | -0.01 |

Scoring with the interim prior penalizes students whose growth accelerated
after the last interim. Using the prior for routing only keeps their reported
scores unbiased. The conventional population prior has its own bias: it
over-reports the lowest scorers. Routing with priors does send fast growers
to easier modules more often (28% vs 15%), which costs them some precision
but not bias.

**Summative replacement** (proficiency cut at theta = 0.3):

| method | accuracy | consistency | fast growers wrongly "not proficient" |
|---|---|---|---|
| single summative | 89.6% | 85.2% | 6.0% |
| through-year projection alone | 90.1% | 89.2% | **22.3%** |
| summative scored with interim prior | 93.1% | 91.2% | 11.7% |

Overall accuracy of a through-year replacement looks as good as the
summative's, but it misclassifies late bloomers at nearly four times the rate.
That is the defensibility question for accountability.

## Status and assumptions

Done: `ty_simulate`, `ty_link` (+`predict`), `ty_mst`, `ty_mst_default`,
`ty_administer`, `ty_policies`, `ty_fairness`, `ty_decisions`. Rasch MST;
linear growth in the simulator (linking itself is distribution-free beyond
multivariate normality). Next: growth-aware links (occasion timing as a
covariate), adaptive shrinkage of the prior (discounting it when interim
evidence is stale), subgroup-calibrated priors, and 1-2-3 panel designs.
