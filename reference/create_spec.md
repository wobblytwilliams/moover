# Create a moover Specification

Builds a reproducible package spec that can be written to JSON and
reused in scripted or interactive workflows.

## Usage

``` r
create_spec(
  workspace = list(),
  ingest = list(),
  schema = list(),
  labels = list(),
  epochs = list(),
  features = list(),
  model = list(),
  optimise = list(),
  predict = list(),
  export = list(),
  run = list(),
  path = NULL,
  interactive = FALSE
)
```

## Arguments

- workspace, ingest, schema, labels, epochs, features, model, optimise,
  predict, export:

  Named lists that override the default spec sections.

- run:

  Optional named list for run metadata.

- path:

  Optional path to write the JSON spec.

- interactive:

  Included for compatibility with wizard helpers.

## Value

An object of class `moover_spec`.
