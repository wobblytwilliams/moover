# Export a moover Model Bundle

Writes a deployable model bundle containing the trained model, specs,
feature manifest, metrics, plots, and test vectors.

## Usage

``` r
export_model(spec, fitted_model = NULL)
```

## Arguments

- spec:

  A `moover_spec` object or path to a JSON spec.

- fitted_model:

  Optional result from
  [`train_model()`](https://wobblytwilliams.github.io/moover/reference/train_model.md).
  If `NULL`, the cached fit for the run is used.

## Value

The export directory.
