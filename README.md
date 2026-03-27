# moover

`moover` converts movement data into behaviour workflows for animal scientists.

It is designed to support both:

- beginner-friendly guided workflows
- reproducible scripted workflows from JSON specs

It is designed to work locally on a normal computer, without requiring access to a high-performance computing (HPC) environment. Larger runs can still take time, but the goal is to make model building, optimisation, and prediction accessible to beginners working on their own machines.

## Installation

Install the development version from GitHub with:

```r
install.packages("devtools")
devtools::install_github("wobblytwilliams/moover")
```

## What `moover` does

- ingests raw accelerometer data
- converts it to a canonical movement format
- generates epoch features
- trains and optimises Random Forest models
- evaluates models with LOCO metrics and plots
- exports reusable and embedded-friendly model bundles
- predicts behaviour on new datasets using existing bundles

## Core workflows

### 1. Use an existing model

```r
spec <- moover::create_spec(
  predict = list(model_bundle = "path/to/exported_bundle")
)

moover::run_pipeline(spec, stage = "predict")
```

### 2. Train and export a new model

```r
spec <- moover::create_spec(
  labels = list(
    tech_file = "tech.csv",
    path = "observations.csv"
  )
)

moover::run_pipeline(spec, stage = "all")
```

### 3. Optimise for embedded deployment

```r
spec <- moover::create_spec(
  optimise = list(enabled = TRUE)
)

moover::run_pipeline(spec, stage = "all")
```

## Getting started

```r
moover::init_workspace()
moover::wizard_train()
```

## Documentation

The pkgdown site is intended to be the main tutorial and reference hub:

https://wobblytwilliams.github.io/moover/

It includes walkthroughs for:

- setting up folders
- formatting observations
- formatting accelerometer input files
- understanding exported deployment bundles
- building a model
- predicting with an existing model

## Included example data

The package ships with a small example workspace under:

```r
system.file("extdata", "example_workspace", package = "moover")
```

## TODO

- parquet and arrow ingestion support
- additional model backends beyond Random Forest
