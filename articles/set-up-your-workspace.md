# Set Up Your Workspace

Open the chapter list

1.  [Chapter 1. Start
    Here](https://wobblytwilliams.github.io/moover/articles/getting-started.md)
2.  [Chapter 2. Set Up Your
    Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)
3.  [Chapter 3. Prepare Accelerometer
    Files](https://wobblytwilliams.github.io/moover/articles/accelerometer-input-formats.md)
4.  [Chapter 4. Record
    Observations](https://wobblytwilliams.github.io/moover/articles/recording-observations.md)
5.  [Chapter 5. Build Your First
    Model](https://wobblytwilliams.github.io/moover/articles/build-a-model.md)
6.  [Chapter 6. Predict with a
    Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md)
7.  [Chapter 7. Understand Your
    Results](https://wobblytwilliams.github.io/moover/articles/deployment-export-format.md)
8.  [Chapter 8. Optimise for
    Deployment](https://wobblytwilliams.github.io/moover/articles/optimise-a-model-for-deployment.md)
9.  [Chapter 9. Scripted
    Reruns](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.md)
10. [Chapter 10.
    Troubleshooting](https://wobblytwilliams.github.io/moover/articles/troubleshooting-and-glossary.md)

## You are here

This is **Chapter 2 of 10** in the beginner path.

## Who this page is for

This page is for users who want to feel comfortable with the project
folders before training or prediction.

## What you will achieve

By the end of this page, you will understand:

- what `data_raw/`, `runs/`, and `_internal/` are for
- where `tech.csv` and `observations.csv` belong
- what a run folder contains
- what to expect from a local workflow on a normal computer

## Why this matters

Many beginners feel unsure before they even start because the folder
layout looks unfamiliar. This page is here to make the workspace feel
predictable rather than technical.

## What we’re doing

We are creating a clean workspace and walking through each folder in
plain language.

The key idea is that `moover` separates:

- your raw input files
- the outputs from each run
- the temporary internal working files used while the package is doing
  its job

## Do this

The code below is trying to create the standard folder structure that
`moover` expects.

``` r
library(moover)

# Create a new moover workspace called "my_moover_workspace".
# This is your project folder for one piece of work.
init_workspace("my_moover_workspace")
```

[`init_workspace()`](https://wobblytwilliams.github.io/moover/reference/init_workspace.md)
does not train a model or import data. It simply prepares the folder
structure so the next steps are easier to follow.

After that, your workspace should contain this basic structure:

``` text
my_moover_workspace/
  data_raw/
  runs/
  _internal/
```

For a training workflow, you will usually also have:

``` text
my_moover_workspace/
  tech.csv
  observations.csv
  data_raw/
  runs/
  _internal/
```

## What the folders mean

### `data_raw/`

This is where your raw accelerometer files go.

### `runs/`

Every time you run a workflow, `moover` creates a new run folder here.
This keeps outputs separate and helps you track what happened in each
run.

### `_internal/`

This is working space used by the package. Most beginners do not need to
edit anything in here.

### `tech.csv`

This links animal IDs and accelerometer IDs when needed.

### `observations.csv`

This contains the behaviour observations used for training.

## Why each run gets its own folder

A run folder is a saved record of one attempt. That means you can:

- keep old runs
- compare runs
- come back later and see what settings were used
- avoid overwriting previous work by accident

## What success looks like

You should be able to look at your workspace and answer these questions
confidently:

- Where do my raw files go?
- Where do my observation files go?
- Where will the outputs appear?

## Common mistakes

- Putting raw files directly in the workspace root instead of
  `data_raw/`.
- Putting `tech.csv` or `observations.csv` inside `runs/`.
- Deleting `_internal/` while a workflow is still running.
- Expecting a local workflow to finish instantly on large datasets.

## A note on runtime

`moover` is designed to work locally on a normal computer. You do not
need HPC. Some jobs can still take time, especially when you optimise
several models, but the folder structure is designed to help you work
step by step and keep track of progress.

**Move through the tutorial**  
Previous chapter: [Chapter 1. Start
Here](https://wobblytwilliams.github.io/moover/articles/getting-started.md)  
Next chapter: [Chapter 3. Prepare Your Accelerometer
Files](https://wobblytwilliams.github.io/moover/articles/accelerometer-input-formats.md)
