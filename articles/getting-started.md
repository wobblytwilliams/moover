# Start Here: Your First Successful Run

## You are here

You are at the start of the beginner path: **1 of 10**.

If you already have a model and only want predictions, you can jump
ahead to [Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md).

## Who this page is for

This page is for first-time `moover` users who want one complete success
before using their own data.

## What you will achieve

By the end of this page, you will have:

- copied the packaged example workspace to a writable folder
- run a complete training workflow
- found the output folder for that run
- seen what a finished `moover` run looks like

## Why this matters

Starting with example data lowers the pressure. It helps you learn the
workflow first, so that when you move to your own files you are only
solving one new problem at a time.

## Before you start

You need:

- `moover` installed
- a normal writable folder on your computer
- a little patience while the run completes locally

## What we’re doing

We are going to copy the packaged example workspace into a temporary
writable folder and run a full beginner-friendly model build from that
example data.

Because the beginner wizard is interactive, the code below shows the
same job in a copy-pasteable scripted form. When you do this on your own
machine, you can also use
[`wizard_train()`](https://wobblytwilliams.github.io/moover/reference/wizard_train.md).

## Do this

``` r
library(moover)

example_dir <- system.file("extdata", "example_workspace", package = "moover")
workspace_dir <- file.path(tempdir(), "moover_first_run")
dir.create(workspace_dir, recursive = TRUE, showWarnings = FALSE)

file.copy(
  from = list.files(example_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE),
  to = workspace_dir,
  recursive = TRUE
)

spec <- create_spec(
  workspace = list(root = workspace_dir),
  labels = list(
    tech_file = "tech.csv",
    path = "observations.csv"
  ),
  features = list(
    selection = "standard",
    standard_set = "manual5"
  ),
  optimise = list(enabled = FALSE)
)

run_pipeline(spec, stage = "all")
```

If you would rather be guided step by step, use the wizard instead:

``` r
wizard_train()
```

## What success looks like

A successful first run will leave you with:

- a new folder inside `runs/`
- a `results/` folder containing summaries and intermediate outputs
- a `models/` folder containing an exported model bundle
- plots and quality-check files you can inspect later

If you open the workspace folder after the run, you should be able to
point to a specific run directory and say, “That is the run I just
completed.”

## Common mistakes

- Trying to run inside the installed package folder instead of a
  writable copy.
- Forgetting that local runs can take a little time, even on example
  data.
- Starting with your own files before you have seen a successful run.

## What’s next

Now that you have seen one complete run, continue to [Set Up Your
Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)
to understand the folder structure you will use for your own projects.
