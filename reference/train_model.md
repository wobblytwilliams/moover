# Train a moover Model

Trains a Random Forest model either from the selected optimisation
candidate or from the feature/model settings in the spec.

## Usage

``` r
train_model(spec)
```

## Arguments

- spec:

  A `moover_spec` object or path to a JSON spec.

## Value

A fitted model bundle stored in the run cache and returned as a list.
