# moover

`moover` helps animal scientists turn movement data into behaviour
outputs.

It is designed for people who want to work locally on their own
computer, without needing a high-performance computing (HPC)
environment. Larger runs can still take time, but the goal is to make
behaviour modelling practical and approachable for beginners.

## Who `moover` is for

`moover` is for animal scientists, including nutritionists and other
researchers who may be new to accelerometer pipelines, machine learning,
or R package workflows.

## Installation

Install the development version from GitHub with:

``` r
install.packages("devtools")
devtools::install_github("wobblytwilliams/moover")
```

## Start here

If you are new to `moover`, start with the first tutorial:

[Start Here: Your First Successful
Run](https://wobblytwilliams.github.io/moover/articles/getting-started.html)

That walkthrough uses packaged example data so you can get one complete
success before working with your own files.

## Typical beginner journey

1.  Set up a workspace on your computer.
2.  Try the packaged example data.
3.  Prepare your own accelerometer files.
4.  Record or tidy your observations for training.
5.  Build a model.
6.  Predict behaviour on new data.

## Advanced users

If you already know the workflow and want reproducible reruns, saved
instructions, or command-line execution, see the advanced tutorial on
scripted reruns and saved specs:

[Scripted Reruns and Saved
Specs](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.html)

## Documentation

The full tutorial and reference site is here:

<https://wobblytwilliams.github.io/moover/>

The beginner path walks through:

- your first successful run
- setting up folders and understanding the workspace
- preparing accelerometer files
- recording observations for training
- building a first model
- predicting with an existing model
- understanding the results and export folder

## Included example data

The package ships with a small example workspace under:

``` r
system.file("extdata", "example_workspace", package = "moover")
```

## What `moover` does

- ingests raw accelerometer data
- converts it into a standard 5-column movement format
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

## TODO

- parquet and arrow ingestion support
- additional model backends beyond Random Forest
