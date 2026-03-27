# Run a moover Pipeline

Executes one stage or a full workflow from a JSON spec or spec object.

## Usage

``` r
run_pipeline(
  spec,
  stage = c("import", "features", "train", "optimise", "predict", "export", "all")
)
```

## Arguments

- spec:

  A `moover_spec` object or path to a JSON spec.

- stage:

  One of `"import"`, `"features"`, `"train"`, `"optimise"`, `"predict"`,
  `"export"`, or `"all"`.

## Value

The stage result.
