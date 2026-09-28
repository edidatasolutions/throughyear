---
title: 'throughyear: Linking, routing and fairness for through-year assessment'
tags:
  - R
  - psychometrics
  - through-year assessment
  - multistage testing
  - linking
authors:
  - name: Daniel Edi
    orcid: 0000-0001-5475-819X
    affiliation: 1
affiliations:
  - name: Independent Researcher
    index: 1
date: 27 September 2026
bibliography: paper.bib
---

<!-- DRAFT. Verify every reference and number before submission. Check the
journal's policy on disclosing AI-assisted software and writing. -->

# Summary

In through-year assessment, interims given during the school year feed into
or partly replace the spring summative. `throughyear` treats the whole system
as the unit of analysis. It links interims to the summative scale with a
latent multivariate normal model that carries each score's measurement error
forward and handles missing interims. The model is estimated by EM
[@dempster1977] with SQUAREM acceleration [@varadhan2008]. The package
simulates cold-start versus prior-informed routing in a two-stage
multistage test [@yan2014], checks whether priors disadvantage late
enrollers, low scorers or students whose growth accelerated after the last
interim, and evaluates the decision accuracy and consistency of through-year
scores against a single summative.

# Statement of need

Adaptive and multistage testing packages [@magis2017] simulate one test in
isolation. States adopting through-year designs must instead answer
system-level questions: how well interims predict summative outcomes, whether
interim results can serve as routing priors, and when a through-year score is
defensible for accountability. Each state currently answers them with its own
scripts.

# Validation

In known-truth simulations, linked priors were calibrated (z-score SD 0.99,
90% coverage 90.5%), and late enrollers received wider but still calibrated
priors. Prior-informed routing raised routing accuracy from 70% to 84%. Using
the prior to score as well as to route biased students with late growth by
-0.30 logits, while routing-only use kept them unbiased. Replacing the
summative with the interim projection wrongly classified 22% of those
students as not proficient, versus 6% for the summative, even though overall
accuracy was similar.

# Acknowledgements

Software development and drafting were assisted by Claude (Anthropic). The author designed the methods, reviewed and validated all code and results, and takes full responsibility for the content.

# References
