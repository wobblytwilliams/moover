# Deployment Export Format

Every exported model bundle is designed to support:

- prediction in R
- inspection by collaborators
- implementation in another language
- embedded deployment

## Bundle contents

Expected files include:

- `rf_model_full.rds`
- `model_spec.json`
- `export_config.json`
- `feature_manifest.csv`
- `feature_manifest.json`
- `metrics_overall.csv`
- `metrics_by_class.csv`
- `confusion_matrix.csv`
- `test_vectors.csv`
- `test_vectors_all.csv`
- `rf_tree_dump.json`

## Feature specification

The feature manifest records:

- feature names
- whether a feature is rolling
- textual definitions

## Embedded deployment

The RF tree dump JSON is intended to help collaborators recreate the
trained model logic outside R.

Test vectors are included so that collaborators can check:

- feature calculations
- class predictions
- class probabilities

against an independent implementation.
