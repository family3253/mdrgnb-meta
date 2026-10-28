# Public analysis snippets

This directory contains small, de-identified R examples for a prediction-model meta-analysis.

It includes no patient-level data, extracted study records, citation labels, cohort identifiers, local paths, author information, model objects, or generated results. The examples use a generic input schema and are intended to illustrate analysis patterns rather than reproduce a particular submission.

The snippets cover:

- conversion of reported AUC values and confidence intervals to the logit scale;
- REML random-effects synthesis with `metafor`;
- cluster-robust CR2 inference with `clubSandwich`; and
- a report-level sensitivity-analysis pattern.

Required packages are `metafor` and `clubSandwich`. Supply a local CSV with the columns documented in `analysis_snippets.R`; keep that file outside the repository.

```r
source("analysis_snippets.R")
dat <- read.csv("aggregate_effects.csv")
result <- fit_cluster_robust_model(dat)
print(result)
```

The code is a compact public example and is not a complete reproduction package.
