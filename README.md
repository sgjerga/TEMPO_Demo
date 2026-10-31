# TEMPO — Therapy Effects across Multiple Psychological Outcomes

An interactive R/Shiny application based on the five supplied study datasets.
The five tabs are **Overview**, **Trajectories**, **Domain Atlas**,
**Integration**, and **Predictions**.
**TEMPO** stands for **Therapy Effects across Multiple Psychological Outcomes**.
The branded home header includes the approved five-study musical logo from
`www/tempo-logo.png`; keep the `www/` folder alongside `app.R` so Shiny can
serve the image. The logo's name is available to screen readers via its alt
text, and the full acronym is displayed beneath it.
The visual theme uses **gold (`#C89A2B`) → white (`#FFFFFF`) → dark grey
(`#34383F`)**. Positive, favorable standardized effects are displayed in gold;
negative effects in dark grey; values near zero in white. All data sources,
prediction models, and scientific calculations are preserved from the latest
app version.

## Quick start

1. Install **R 4.2+** and **RStudio** (optional, but convenient).
2. Extract the complete updated TEMPO archive. Do **not** separate the
   `app.R`, `R/`, `data/`, and `www/` folders.
3. In R or the RStudio console, run:

   ```r
   install.packages(c(
     "shiny", "bslib", "dplyr", "tidyr", "tibble", "ggplot2",
     "plotly", "DT", "readxl", "scales"
   ))
   shiny::runApp("/absolute/path/to/TEMPO", launch.browser = TRUE)
   ```

   Alternatively, open `TEMPO/app.R` in RStudio and click **Run App**.
   If your current working directory is already the extracted `TEMPO`
   folder, run `shiny::runApp(".")`.

4. In the left sidebar, select any combination of studies. Tabs 1 and 3 respond
   to the selection. Tab 2 offers measure-level original-scale trajectories for
   one selected study at a time. Tab 4 runs domain-specific evidence synthesis.
5. Hover over plotted points/cells for interpretations and sample sizes, or
   export the selected effects from the integration tab.

Before launching, you can verify dataset ingestion and effect calculations:

```r
# Run from inside the extracted TEMPO directory:
source("tests/smoke_test.R")
source("tests/theme_smoke_test.R")
```

The first test checks that all five studies load, international MIDDEL
estimates can be read, and each selected domain can be analyzed. The theme
test checks that `app.R` parses and retains TEMPO branding and the requested
gold-white-dark-grey colors. Successful runs print `PASS: ...` messages.

The initial run only reads local data. No network access is needed beyond the
first-time package installation and optional online font loading. The visual
interface can also fall back to local system fonts.

## Prediction tab (05) and its models

The **05 Predictions** tab reads existing model objects in `data/ml_models/`
and cross-validation results in `data/ml_reports/model_registry.csv`. **The
app does not train models at startup.** Run the training pipeline once, using
the instructions below, then restart the Shiny app.

The tab normally shows models that pass the research-only minimum screen in
`R/prediction_view.R`:

- Saved model exists, is readable, and the required R prediction package is installed.
- At least **70** complete baseline/post pairs, with **25 per trial arm**.
- Outer cross-validated factual outcome **R² ≥ 0.10** and finite RMSE.
- For clustered and pooled designs, additional minimum sample/cluster checks.

These are display filters, **not proof of robust individual treatment-effect
estimation or external validation**. Trial-specific case mix, treatment
comparators, baseline measurement scales, and selection bias remain important.
MUSED models are listed first. They use a study-specific minimum of 35 paired
participants and 10 per arm, subject to available fitted models and prediction
diagnostics. As for all studies, model cards report actual held-out metrics.

For **Esteban-Cárdenas**, the app displays baseline gender, education,
diagnosis, and expectation categories in **English**, while retaining the
original Spanish strings internally when scoring previously trained RDS
models. Retraining is therefore not required for this language change.
The user chooses the target domain (default: depression), then a screened
model and baseline profile. After entering or changing any inputs, click
**Predict outcomes**. Previously calculated results are cleared when the
inputs change, so stale values are not presented as new predictions. The app predicts favorable standardized
change in both trial arms and their model-implied difference. Hover over plots
for details. The sensitivity plot varies the initial outcome score while holding
the other inputs constant. A profile's default inputs are dataset medians or
common categories, not observed patients.

**Why two arm predictions can be identical:** An earlier training version
penalized the treatment indicator as well as the effect-modification terms.
When regularization removed every treatment-related coefficient, both
counterfactual outcome predictions necessarily became identical. The app now
checks fitted coefficients and explains this case explicitly. Updated
`machine_learning_analysis/02_model_engine.R` leaves the randomized treatment
**main effect unpenalized** while retaining regularization on baseline and
interaction predictors. Retrain using `source("03_run_all.R")` from the
`machine_learning_analysis/` directory to update existing `.rds` models and
cross-validation reports. Back up the original `data/ml_models/` and
`data/ml_reports/` first if you wish to compare results. This modelling change
does **not** force an arm difference: equal predictions remain possible when
supported by the data. Individual treatment effects are not validated by
outcome prediction RMSE/R².

The attached model reports actually show **zero estimated treatment contrast**
across training profiles for MUSED depression, MUSED stress, Finnerty WHOQOL
psychological, Esteban depression, and Esteban life satisfaction. These saved
models legitimately produce the same arm forecasts regardless of profile;
adding a button cannot create missing model signal. Their model cards include
a neutral diagnostic note. The supplied MUSED models also have negative held-out
R², so they should not be interpreted as validated personalized predictors.
The random-forest training code has also been corrected to use the S3
`stats::predict()` method, and the international MIDDEL importer now accepts
its actual randomized arm strings (`SC`, `GMT`, `RCS`). Re-run the training
workflow to assess refreshed model coefficients and held-out performance.

If a domain has no eligible model, the tab explains why rather than fabricating
a prediction. The supplied archive did **not** include MIDDEL model
objects, so cognition and neuropsychiatry will remain unavailable until
successful MIDDEL training and internal screening.

**Installing the update on an existing project:** Replace `app.R`,
`R/prediction_view.R`, and `machine_learning_analysis/02_model_engine.R`;
add `tests/prediction_smoke_test.R` if necessary, and optionally update
the README. Do **not** replace your own `data/ml_models/` or
`data/ml_reports/` folders with an older archive.

In RStudio, after training, you can test the saved models from the project
root without refitting them:

```r
source("tests/prediction_smoke_test.R")
shiny::runApp(".")
```

The prediction server needs `glmnet` for ridge/elastic-net bundles and
`ranger` for forest bundles. Install these if the selected model uses them.

### Optional predictive modelling workflow

An additional standalone training workflow lives in
`machine_learning_analysis/`. It builds baseline-only predictive models for
depression, anxiety, stress, quality of life, cognition, and neuropsychiatric
symptoms using the available participant-level trial records. It also fits
exploratory pooled depression and stress models where feasible.

After installing its dependencies, run the following from the
`machine_learning_analysis/` working directory:

```r
source("03_run_all.R")
```

The workflow saves fitted models to `data/ml_models/` and an auditable model
registry, cross-validation metrics, and task audit to `data/ml_reports/`.
See `machine_learning_analysis/README.md` for dependencies, comparisons,
interpretation, exclusions, and a prediction-loading example. **This workflow
does not add or change any Shiny tab yet.**

## Folder structure

```text
TEMPO/
  app.R                     # Five interactive Shiny tabs and CSS
  www/tempo-logo.png        # Five-study musical logo used in the home header
  R/
    data_pipeline.R         # Study-specific source mappings and harmonization
    model.R                 # Effect estimation and inverse-variance pooling
    prediction_view.R       # Screen and serve the fitted ML prediction bundles
  tests/smoke_test.R        # Local ingestion/model sanity checks
  tests/theme_smoke_test.R  # Theme and application syntax sanity checks
  tests/prediction_smoke_test.R # Saved-model interface checks
  data/src_integrative/     # Exact datasets supplied by the researcher
  machine_learning_analysis/ # Standalone R training and prediction scripts
  README.md
```

## Included studies & comparisons

| Study | Main population | Primary synthesis comparison | Individual trajectories |
| --- | --- | --- | --- |
| MUSED | Women with major depressive disorder | Group music therapy vs waitlist | BDI, HDRS, TICS, daily salivary cortisol |
| MIDDEL | Older care-home residents with dementia/depression | International adjusted factorial GMT vs no GMT, 6 months | Australian subset MADRS, 0/3/6/12 months |
| Finnerty & Trainor | Canadian university students | Group music therapy vs campus life as usual | PSS, STAI-S, WHOQOL, hair cortisol |
| Esteban-Cárdenas | Colombian psychiatric inpatients | Five vs **one** music-therapy session (optional integration) | DASS-21, life satisfaction |
| Yu, Lee & Lu | Chinese university students during COVID-19 | Online music therapy vs usual-care/no-intervention group | BAI, BDI-13, 3 randomized groups |

## Harmonization dictionary

Each study may contribute **at most one primary instrument per psychological
domain** to a pooled effect, so that multiple related scales in the same study
are not treated as statistically independent:

- **Depression:** MUSED BDI, MIDDEL MADRS, Esteban DASS-21 depression,
  Yu/Lee/Lu BDI-13.
- **Anxiety:** Finnerty STAI-S, Esteban DASS-21 anxiety, Yu/Lee/Lu BAI.
- **Stress:** MUSED TICS, Finnerty PSS, Esteban DASS-21 stress.
- **Quality of life:** Finnerty WHOQOL psychological score, MIDDEL EQ-VAS,
  Esteban satisfaction with life.
- **Cognition and neuropsychiatric symptoms:** MIDDEL SIB-8 and NPI severity,
  respectively; single-study domains, so **no cross-study inference**.
- **Physiological stress:** MUSED salivary cortisol and Finnerty hair cortisol
  are available as descriptive curves **only** (different biological specimens,
  periods, collection conditions, and measurement scales).

Other measures remain visible where extracted; unextracted columns are still
preserved in the supplied raw source files.

## Effect model and its limitations

For ordinary individual-randomized two-arm datasets, the app computes an
**exploratory, unadjusted, paired-completer** standardized difference in change:

```text
  g = J(df) * direction * [mean(Post - Pre)_MT - mean(Post - Pre)_Ctrl]
              / pooled_baseline_SD

  J(df) = 1 - 3/(4*df - 1), df = n_MT + n_Ctrl - 2

  SE(g) ≈ J(df) / pooled_baseline_SD *
          sqrt[Var(change_MT)/n_MT + Var(change_Ctrl)/n_Ctrl]
```

`direction = -1` for symptom severity (lower is beneficial), and `+1` for
well-being/cognition (higher is beneficial). Thus, **positive means favorable
for the therapy or higher-dose group**. Intervals are `estimate ± 1.96*SE`.
They neglect baseline-SD estimation uncertainty and do not account for baseline
covariates, missing-not-at-random outcomes, or other design intricacies.

**MIDDEL exception:** For international MIDDEL, the app reads the adjusted
intent-to-treat, cluster-aware *factorial GMT main-effect* estimate from the
source project’s ANCOVA tables. For MADRS, the adjusted regression coefficient
and its confidence interval are divided by the SD of baseline MADRS across the
international baseline file (a proxy for the analyzed six-month sample SD).
For the other MIDDEL outcomes the published Cohen's d and its CI are used, but
these numbers were rounded to one decimal. This is a **different estimator**
from the simple paired-completer contrasts. The main factor comparison is GMT
versus no GMT, **averaged across choir conditions**, not pure GMT vs usual care.
The Australian trajectory rows are part of MIDDEL, and are **never pooled as
an independent experiment**.

### Common and study-specific effects

For one selected domain, with one `y_i` and known estimated sampling variance
`v_i` per study, the exploratory model is:

```text
  y_i | mu, u_i ~ Normal(mu + u_i, v_i)
  u_i ~ Normal(0, tau^2)
```

`mu` is the pooled/common domain effect; `tau` is the estimated between-study
SD. In **REML** mode, tau² is estimated by restricted maximum likelihood,
then the common effect is inverse-variance weighted with weights `1/(v_i+tau²)`.
In **Fixed** mode, `tau = 0` by assumption. Approximate normal 95% CIs are
shown. No Knapp-Hartung/small-k correction is applied.

The deviation view uses plug-in empirical-Bayes partial pooling:

```text
  E[u_i | data, mu_hat, tau_hat] =
      tau_hat^2 / (tau_hat^2 + v_i) * (y_i - mu_hat)
```

These are **not confirmed causal population interactions** and their displayed
conditional intervals ignore estimation uncertainty in `mu` and `tau`. When
REML estimates `tau = 0`, all displayed EB deviations become zero by
construction; this does *not* prove that populations respond identically.
With only 2–4 studies per domain, the heterogeneity estimates may be very
unstable. A single-study result is not a shared effect.

### Why the active-dose toggle exists

Esteban-Cárdenas contrasts **5 versus 1 sessions** while the others contrast
access to music therapy with study-specific absence of group MT. Treating the
active-dose experiment as if it were therapy versus no therapy would change the
estimand. Hence the integration tab **excludes Esteban by default**; enable
it only as a visibly labeled exploratory sensitivity analysis.

### Why this is not yet a definitive IPD meta-analysis

Before drawing causal claims, a publication-grade analysis should align the
target treatment/comparator, assessment windows, and randomized populations;
harmonize instruments with measurement-invariance/linking evidence; handle
missingness with appropriate methods; fit participant-level mixed models
(accounting for the MIDDEL care-home clusters); and use proper multilevel
sampling models for correlated outcomes and population-by-experiment effects.
The app is a usable **discovery / exploratory synthesis** platform and a base
for that next phase.

## Data provenance

- MUSED: https://doi.org/10.1016/j.jad.2025.01.011
- MIDDEL protocol: https://doi.org/10.1136/bmjopen-2018-023436
- MIDDEL primary findings: https://doi.org/10.1016/j.lanhl.2025.100783
- Finnerty & Trainor: https://doi.org/10.1371/journal.pmen.0000312
- Esteban-Cárdenas: https://doi.org/10.1371/journal.pone.0317950
- Yu, Lee & Lu data v3: https://doi.org/10.17632/mcr7vd5f5d.3

The original supplied data files are bundled without changing their contents.
The field-by-field extraction is documented in `R/data_pipeline.R` and is
intentionally explicit, so mappings can be audited and revised.

### Dataset licences and reuse credits

The application Overview shows dataset-level credits and links to each data
deposit and its recorded reuse terms. MUSED (heiDATA dataset DOI
`10.11588/DATA/L9TEVQ`) and Yu, Lee & Lu (Mendeley Data v3 DOI
`10.17632/mcr7vd5f5d.3`) are published under **CC BY 4.0**, which permits
reuse and adaptation with appropriate attribution and notice of changes.

The MIDDEL, Finnerty & Trainor, and Esteban-Cárdenas OSF projects are marked
**public**. As checked against the OSF API on 2026-10-31, each has a null
project-level `node_license` field (no named project licence recorded), **not**
an explicit licence prohibiting reuse. OSF's terms grant rights to use public
content subject to intellectual-property law and any applicable specific
conditions. The original datasets' file-level reuse terms are not thereby
certified to be unrestricted. A journal article's CC BY terms do not
automatically license its separately deposited data files.

TEMPO standardizes, harmonizes and summarizes the original data; these are
changes to the source material. The original authors do not endorse TEMPO.
For a more detailed audit and source URLs, see `DATA_LICENSE_REVIEW.md`.

### Import robustness

Some original CSV exports include an unnamed first column, while some Excel
WHOQOL headers contain embedded line breaks. The loader repairs only blank or
duplicate CSV headers and matches outcome columns after normalizing header
whitespace (LF/CRLF, tabs and extra spaces). The original source files and
their scientific column values are not modified. If an expected outcome field
is genuinely missing, the loader reports the study, measure, missing header,
and available field names for diagnosis.
