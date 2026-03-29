# Start Here: Your First Successful Run

## You are here

You are at the start of the beginner path: **Chapter 1 of 10**.

If you already have a model and only want predictions, jump to [Chapter
6: Predict Behaviour with an Existing
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

We are going to take the small example workspace that comes with
`moover`, copy it into a folder that you are allowed to write into,
create a simple run specification, and then run the full beginner
workflow.

This is a very deliberate first step:

- [`system.file()`](https://rdrr.io/r/base/system.file.html) finds the
  packaged example data
- [`file.copy()`](https://rdrr.io/r/base/files.html) moves that example
  into your own working area
- [`create_spec()`](https://wobblytwilliams.github.io/moover/reference/create_spec.md)
  records the instructions for the run
- `run_pipeline(..., stage = "all")` carries out the full workflow from
  input files to exported model bundle

## Why we are not starting with your own files yet

If something goes wrong on your very first run, it is helpful to know
whether the problem is:

- the software workflow itself, or
- the structure of your own files

Using packaged example data lets you separate those two questions.

## Do this

The code below is trying to achieve one complete successful run with
known-good example data.

``` r
library(moover)

# Find the example workspace that ships inside the moover package.
# This folder already contains sample raw files, a tech table, and observations.
example_dir <- system.file("extdata", "example_workspace", package = "moover")

# Choose a writable folder on your own computer.
# We copy the example files there because installed package folders should be treated as read-only.
workspace_dir <- file.path(tempdir(), "moover_first_run")
dir.create(workspace_dir, recursive = TRUE, showWarnings = FALSE)

# Copy the example workspace into that writable location.
# After this step, you have your own working copy of the example project.
file.copy(
  from = list.files(example_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE),
  to = workspace_dir,
  recursive = TRUE
)

# Create a simple run specification.
# - workspace: where the run should happen
# - labels: which files contain the mapping table and behaviour observations
# - features: use the beginner-friendly standard feature set
# - optimise: FALSE keeps the first run simpler and quicker
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

# Run the full workflow.
# In this beginner example, "all" means:
# import data -> build features -> train the model -> export the bundle.
run_pipeline(spec, stage = "all")
```

If you would rather be guided step by step, use the wizard instead:

``` r
# This opens the beginner training wizard and asks you questions interactively.
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

**Move through the tutorial**  
Next chapter: [Chapter 2. Set Up Your
Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)
