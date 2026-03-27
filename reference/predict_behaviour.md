# Predict Behaviour from an Existing Model

Applies an exported model bundle to new raw accelerometer data and
writes epoch-level predictions into the current run.

## Usage

``` r
predict_behaviour(spec, model_bundle = NULL)
```

## Arguments

- spec:

  A `moover_spec` object or path to a JSON spec.

- model_bundle:

  A bundle object returned by
  [`load_model_bundle()`](https://wobblytwilliams.github.io/moover/reference/load_model_bundle.md)
  or a path to an exported model bundle directory. If `NULL`,
  `spec$predict$model_bundle` is used.

## Value

A data table of epoch-level predictions.
