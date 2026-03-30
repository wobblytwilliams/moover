# moover

<p align="center">
  <img src="moover_hex.png" alt="moover package logo" width="220">
</p>

`moover` helps animal scientists turn movement data into behaviour outputs.

The main idea is simplicity. If you can load a package, read in data, and make a plot in R, you should be able to use `moover` to build a Random Forest behaviour model and apply it to predict behaviour.

It is designed for people who want to work locally on their own computer, without needing a high-performance computing (HPC) environment. Larger runs can still take time, but the goal is to make behaviour modelling practical and approachable for beginners.

In `moover`, the usual pattern is:

- raw accelerometer files can live wherever they already live, including a network drive or portable drive
- the workspace keeps the local derived outputs for each run, such as previews, epoch features, optimisation results, model bundles, and test vectors
- epoch-level data is expected to be held locally so runs stay reproducible and easier to revisit

## Who `moover` is for

`moover` is for animal scientists, including nutritionists and other researchers who may be new to accelerometer pipelines, machine learning, or R package workflows.

## What you need to provide

`moover` is built around a simple contract.

If you can provide:

- accelerometer data in a standard format with a timestamp and `x`, `y`, `z`
- a `tech.csv` file linking animals to sensors and deployment periods
- an `observations.csv` file in a standard labelled-bout format

then `moover` does the rest.

It will:

- standardise the input data
- compute features across fixed time blocks
- train a Random Forest model
- check accuracy using standard validation methods such as leave-one-animal-out testing
- export a reusable model bundle
- apply that model to a larger raw dataset

And if you do not want to train a model yourself, `moover` also lets collaborators share model bundles so you can run prediction on your own data without rebuilding the model from scratch.

## Installation

Install the development version from GitHub with:

```r
install.packages("devtools")
devtools::install_github("wobblytwilliams/moover")
```

## Start here

If you are new to `moover`, start with the first tutorial:

[Start Here: Your First Successful Run](https://wobblytwilliams.github.io/moover/articles/getting-started.html)

That walkthrough uses packaged real-data examples so you can get one complete success before working with your own files.

## Typical beginner journey

1. Set up a workspace on your computer.
2. Try the packaged real-data examples.
3. Prepare your own accelerometer files.
4. Record or tidy your observations for training.
5. Train, validate, and export a model.
6. Predict behaviour on a larger raw dataset or with a shared bundle.

## Advanced users

If you already know the workflow and want reproducible reruns, saved instructions, or command-line execution, see the advanced tutorial on scripted reruns and saved specs:

[Scripted Reruns and Saved Specs](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.html)

## Documentation

The full tutorial and reference site is here:

https://wobblytwilliams.github.io/moover/

The beginner path is organised as a 10-chapter walkthrough and walks through:

- your first successful run
- setting up folders and understanding the workspace
- preparing accelerometer files
- recording observations for training
- training, validating, exporting, and then predicting on a larger raw dataset
- predicting with a shipped model bundle
- understanding the results and export folder

## Included example data

The package ships with three beginner-friendly real-data examples:

```r
system.file("extdata", "example_train_workspace", package = "moover")
system.file("extdata", "example_predict_raw", package = "moover")
system.file("extdata", "example_model_bundle", package = "moover")
```

These are designed to work together:

- `example_train_workspace` is a curated labelled training workspace
- `example_predict_raw` is a larger raw-only dataset used for prediction
- `example_model_bundle` is a shipped model bundle you can apply directly

## What `moover` does

- ingests raw accelerometer data
- converts it into a standard 5-column movement format
- uses simple support files for tech details and observations
- generates features from fixed time blocks
- trains and optimises Random Forest models
- evaluates models with beginner-friendly summaries and metrics
- exports reusable model bundles
- predicts behaviour on new datasets

## Current focus for v1

- beginner-friendly local workflows
- Random Forest models
- reusable and shareable model bundles
- support for CQU-style and generic delimited input files
- support for external raw-data folders with local run outputs
- fixed-size chunked reading for larger raw files when needed

## Storage note

Version 1 keeps the storage choices simple on purpose:

- raw files can be read directly from outside the workspace
- local run outputs are written as CSV.gz and RDS files
- Parquet is not required for the beginner workflow

We may add optional Parquet or Arrow-based local caching later if intermediate-file read and write time becomes a real bottleneck, but it is not needed to get started.

## TODO

- additional model backends beyond Random Forest
