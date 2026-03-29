# Scripted Reruns and Saved Specs

## You are here

This is **Chapter 9 of 10** in the tutorial path, and it is aimed at
advanced or repeat users.

## Who this page is for

This page is for users who already understand the beginner workflow and
now want reproducible reruns or automation.

## What you will achieve

By the end of this page, you will know:

- what a saved instruction file is in `moover`
- how to create one
- how to rerun a pipeline from it
- when scripted reruns are more helpful than the wizard

## Why this matters

The wizard is a great way to learn. Saved instructions are a great way
to repeat a workflow reliably.

## What we’re doing

We are taking the same choices you might make in the wizard and saving
them as a reusable spec.

## A beginner-friendly way to think about a spec

A spec is just a saved set of instructions for a run.

It records things like:

- where your files are
- what the timestamps mean
- which workflow you want to run
- which model settings you chose

## Do this

The first code block is trying to create a reusable in-memory spec and
run it immediately.

``` r
library(moover)

spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(
    # Path to the animal/device mapping file.
    tech_file = "tech.csv",
    # Path to the behaviour observations used for training.
    path = "observations.csv"
  ),
  features = list(
    # Use the standard beginner-friendly feature set.
    selection = "standard",
    standard_set = "manual5"
  )
)

# Run the saved instructions.
run_pipeline(spec, stage = "all")
```

The second code block is trying to write those instructions to a JSON
file so you can reuse them later.

``` r
create_spec(
  workspace = list(root = "my_moover_workspace"),
  # Write the saved instructions to disk.
  path = "saved_run_spec.json"
)
```

To rerun from that saved file later:

``` r
# Read the saved instructions from disk and run them again.
run_pipeline("saved_run_spec.json", stage = "all")
```

## Command-line option

You can also run the packaged script from the command line:

``` sh
Rscript inst/scripts/run_pipeline.R --spec saved_run_spec.json --stage all
```

## What success looks like

You should be able to save a workflow once and rerun it later without
clicking back through the wizard.

## Common mistakes

- Jumping into specs before understanding the beginner workflow.
- Editing a saved spec without keeping track of what changed.
- Assuming a saved spec will work if the file layout has changed
  underneath it.

**Move through the tutorial**  
Previous chapter: [Chapter 8. Optimise a Model for
Deployment](https://wobblytwilliams.github.io/moover/articles/optimise-a-model-for-deployment.md)  
Next chapter: [Chapter 10. Troubleshooting and
Glossary](https://wobblytwilliams.github.io/moover/articles/troubleshooting-and-glossary.md)
