# TEMPO — predictive modelling (serving tab 05)

This directory contains a standalone *training workflow* for the existing
TEMPO app. It reads the supplied datasets from `../data/`, reuses the
app's outcome dictionary in `../R/data_pipeline.R`, and writes fitted `.rds`
models plus diagnostics under `../data/`. The Shiny `05 Predictions` tab
reads these saved outputs; **running training does not itself modify the UI**.

## Install and run

Start in RStudio or a terminal with the **working directory set to**
`TEMPO/machine_learning_analysis/`. The existing app's `data/` and
`R/` directories must be one level above this directory.

```r
install.packages(c("dplyr", "tidyr", "tibble", "readxl", "glmnet"))

# Recommended additional learners (may require compilation on some computers):
install.packages(c("ranger", "grf"))

setwd("/path/to/TEMPO/machine_learning_analysis")
source("03_run_all.R")
```

`ranger` and `grf` are **optional**. Without them, the workflow still trains
ridge and elastic-net models; optional learner results are simply omitted.

You can reduce runtime by changing `fit_causal_forest = FALSE` in `00_config.R`.
The training workflow generally runs on a laptop; international MIDDEL causal
forests may require several minutes or more, depending on hardware.

### Scripts

| Script | What it does |
| --- | --- |
| `00_config.R` | Input/output paths, sample-size thresholds, seeds and dependencies |
| `01_build_tasks.R` | Produces study/domain modelling tasks and baseline-only predictors |
| `02_model_engine.R` | Fold-specific preprocessing, learners, grouped CV, model saving |
| `03_run_all.R` | Run **this one** to train everything and generate reports |
| `04_predict_new.R` | Load an existing model and estimate outcomes under either arm for *new baseline profiles* |

Do not run scripts `01` and `02` directly; the entry point sources them in the
correct order.

## Results

```text
TEMPO/
  R/data_pipeline.R
  data/
    src_integrative/               # original supplied data, unchanged
    ml_models/                     # created on first training run
      <study_domain_outcome>.rds    # fitted best-performing S-learner
      <...>_causal_forest.rds       # optional supplementary CATE model
    ml_reports/
      task_audit.csv               # sample sizes, contrasts and features
      model_registry.csv           # TRAINED / SKIPPED / ERROR and paths
      cv_candidate_metrics.csv     # held-out factual RMSE/MAE/R² per learner
      prediction_summaries.csv     # model-implied benefit distributions (training sample)
      causal_forest_registry.csv   # optional forest status
  machine_learning_analysis/
    00_config.R
    01_build_tasks.R
    02_model_engine.R
    03_run_all.R
    04_predict_new.R
```

The `model_registry.csv` file is the catalogue used by the Shiny
`05 Predictions` tab. It stores project-relative `data/ml_models/*.rds` paths and the
scientific context necessary to explain each prediction. **No individual-level
predictions are written by default.**

## Which studies/outcomes can be modelled?

| Study | Outcomes | Comparison | Important limit |
| --- | --- | --- | --- |
| **MUSED** | Depression (BDI), stress (TICS) | GMT vs waitlist | ~85 paired completers; high-dimensional heterogeneity is weakly identified |
| **Finnerty & Trainor** | Anxiety (STAI-S), stress (PSS), quality of life (WHOQOL psychological) | GMT vs campus-life control | Baseline personality and hair cortisol can be predictors; attendance/post measures **excluded** |
| **Esteban-Cárdenas** | Depression, anxiety, stress (DASS-21), life satisfaction | **Five vs one music-therapy session** | An intervention **dose effect**, NOT treatment vs no treatment |
| **MIDDEL international** | Depression (MADRS), cognition (SIB-8), neuropsychiatric symptoms (NPI severity), quality of life (EQ-VAS) | GMT vs no GMT, adjusting for choir | Residents nested in randomized care-home units; **cluster-based CV** |
| **Yu, Lee & Lu** | Depression (BDI-13), anxiety (BAI-C) | Music therapy vs no-treatment control | 14 post-test rows across *three* groups; modelling tasks recorded but **skipped as too small** |

MIDDEL uses **participant-level** `df.resident.wide` from the nested
`rproject_middel_public_251126.zip/data/data_public.rdata` file. Unlike the
previous exploratory visualization, the modelling workflow can therefore
use the available cognition, NPI and quality-of-life responses. The four
modalities are modelled separately, not jointly as independent outcomes.
The international sample replaces the smaller Australian sample for modelling;
they are not fitted twice as independent studies.

### Exploratory pooled models

When possible, the script also constructs:

- `pooled_depression`: MUSED + MIDDEL (baseline-standardized depression).
- `pooled_stress`: MUSED + Finnerty & Trainor (baseline-standardized stress).

The pooled S-learners include a study indicator and treatment-by-study
interactions. Standardized symptom scores make numeric modelling possible,
but **not measurement-invariant**. Treatment controls and follow-up windows
remain different. Active-dose Esteban and tiny Yu are excluded from pooling.
These models assess within-study validation performance and **must not be
interpreted as validated transport to a new population**. To switch them off,
set `fit_pooled = FALSE`.

## Prediction target, treatment estimand and interpretation

All supervised outcomes are *favorable standardized changes*:

```text
  Y = direction * (post - baseline) / SD(baseline within study)
  direction = -1 for symptoms; +1 for cognition or positive quality of life
```

Thus, **larger Y is better**. A conditional predicted treatment benefit is

```text
  tau_hat(x) = E_hat[Y | treatment=1, X=x]
             - E_hat[Y | treatment=0, X=x]
```

where `X` includes **only** baseline characteristics plus permitted randomized
context (e.g. MIDDEL choir arm). This is the predicted *conditional average
treatment effect* under the trial's randomization and model assumptions, not
an observed patient-specific effect. For MIDDEL, the comparator may receive
choir; for Esteban both groups already receive music therapy. These cannot be
interpreted as an identical "any music therapy vs none" causal estimand.

### Learners and validation

1. Ridge (`glmnet`, α=0), with treatment and baseline-by-treatment interactions.
2. Elastic net (`glmnet`, α=0.5), same design, with a conservative 1-SE λ.
3. Optional random forest (`ranger`, baseline + arm + interactions) for
   sufficiently sized tasks.
4. Optional **supplementary** causal forest (`grf`) only on sufficiently large
   individual randomized tasks, with clusters specified for MIDDEL. It is not
   selected using predictive RMSE because its objective differs.

Imputation, categorical encoding, and numeric scaling are **learned within
each training fold**, never from held-out outcomes. Randomized care-home units
remain intact in both the outer and inner CV for MIDDEL. The selected S-learner
minimizes **out-of-fold RMSE on the observed change score**. Reports also give
MAE and R²; negative R² is possible and should be taken seriously.

The randomized **main treatment indicator is now unpenalized**
(`penalty.factor = 0` for `treatment`). Baseline predictors and treatment-by-
baseline interactions remain penalized. This avoids removing the entire
arm contrast purely through regularization, but it does not force a treatment
effect or guarantee different model predictions. The change takes effect only
after rerunning `source("03_run_all.R")`; previously saved `.rds` bundles were
fitted with the earlier penalty settings. Save a copy of the old models and
reports if you want to compare model estimates and held-out performance.

### Corrections informed by the supplied training reports

- `ranger` random-forest models previously failed validation because
  `ranger::predict` is not exported. They now use `stats::predict` to dispatch
  to the registered `predict.ranger` method.
- International MIDDEL resident data encode randomized conditions using
  `SC` (standard care), `GMT` and `RCS`, which the prior decoder did not
  recognize. The revised importer now recognizes those labels. If the source
  archive is unchanged, this should restore MIDDEL tasks; confirm successful
  import in `task_audit.csv` and `model_registry.csv` after training.
- Existing `.rds` models remain unchanged until training is run again. The
  supplied `prediction_summaries.csv` contains **exactly zero** model-implied
  treatment contrast for several models. This is a fitted-model property,
  not a Shiny calculation failure. It does not prove zero clinical efficacy.

**Critical caveat:** These are **factual prediction** metrics. They do **not**
validate the patient-level counterfactual difference, because each participant
is only observed under one randomized condition. The generated benefit
distribution is computed after refitting the learner to the whole study,
and is therefore a description of model behavior, not validated treatment
heterogeneity. See the [GRF guide](https://grf-labs.github.io/grf/articles/grf_guide.html)
for formal heterogeneous-treatment-effect methods and assumptions.

### Statistical and clinical limits

- Post-treatment missingness is not assumed random. Only observed paired
  completers are used; this is not a full intention-to-treat analysis.
- Nested country, center, care-home and therapist structures are not fully
  represented in every learner. MIDDEL has care-home-grouped evaluation.
- No treatment effect can be recovered for outcomes absent from participant
  records, or from baseline-only international snapshots.
- The MUSED cortisol and Finnerty hair cortisol measures enter as **baseline
  predictors** where available, not as interchangeable therapy endpoints.
- The tiny Yu pilot is audited but not fitted; forcing flexible ML on 4–5
  participants per arm would be misleading.
- Any subgroup/CATE direction should be considered **hypothesis-generating**.
  External validation, interval estimation, calibration, and independent
  trial replication are necessary before clinical or therapeutic decisions.

## Using saved models in the Shiny prediction tab

After training, restart the Shiny app from the project root. Its prediction
view automatically screens model validity, sample sizes (at least 70 total and
25 per arm) and held-out factual R² (at least 0.10). A domain without a
passing model shows an explicit unavailable message. The app never displays
all trained models automatically. The screen does **not** validate conditional
treatment benefit, and the interface keeps this distinction visible.

The app prioritizes **MUSED**, allowing its trained depression and stress
models to be selected subject to minimum sample-size and file-validity checks.
For Esteban-Cárdenas, Spanish categorical
source values are shown in English in the prediction UI, with the original
category strings retained when supplying inputs to trained models.

```r
setwd("/path/to/TEMPO/machine_learning_analysis")
source("00_config.R")
source("02_model_engine.R")
source("04_predict_new.R")

model <- load_predictor("mused_depression_bdi_depression")
print(model$features)  # required baseline feature names

# new_profiles must be a data.frame with baseline_z (or raw baseline)
# and every baseline covariate in model$features. For example:
# predictions <- predict_response(model, new_profiles)
```

The predictions are in **favorable baseline-SD units**; the helper also
provides the corresponding post-score contrast in original units for a
single-study model. Keep the comparator, source population and cautionary
label visible in the eventual tab.
