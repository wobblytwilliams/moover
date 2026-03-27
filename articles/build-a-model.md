# Build a Model

This walkthrough goes from raw data and observations to an exported
model bundle.

## Step 1. Initialise the workspace

``` r
library(moover)
init_workspace()
```

## Step 2. Create a spec

``` r
spec <- create_spec(
  labels = list(
    tech_file = "tech.csv",
    path = "observations.csv"
  ),
  optimise = list(
    enabled = TRUE
  )
)
```

## Step 3. Run the full workflow

``` r
run_pipeline(spec, stage = "all")
```

This will:

- validate and preview the raw data
- build canonical epoch features
- optimise candidate models
- train the selected model
- export the model bundle and test vectors

## Beginner option

``` r
wizard_train()
```
