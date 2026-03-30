# Start Here: Your First Successful Run

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

You are at the start of the beginner path: **Chapter 1 of 10**.

If you already have a model and only want predictions, jump to [Chapter
6: Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md).

This chapter is for first-time `moover` users who want one clean,
successful run before they bring in their own files. That first
successful run matters. It tells you that the software is working, that
your local setup is working, and that you know where the outputs will
appear.

We’ll do four things in this chapter:

1.  find the example workspace that ships with `moover`
2.  copy it into a writable folder on your own computer
3.  create a simple run specification
4.  run the full beginner workflow

## Why start with example data?

When people begin with their own files straight away, there are often
two problems tangled together: learning the workflow and checking the
data structure. The example workspace separates those two jobs. First we
learn the workflow. Then we move on to your files.

## Find and copy the example workspace

The package ships with a small example workspace. We don’t run directly
inside the installed package folder, because installed package files
should be treated as read-only. Instead, we copy that example workspace
into a folder we can write to.

``` r
library(moover)

# Find the example workspace that ships inside the moover package.
# This folder already contains raw accelerometer files, a tech table,
# and an observations table.
example_dir <- system.file("extdata", "example_workspace", package = "moover")

# Choose a writable folder on your own computer.
# In a real session you would usually point this somewhere permanent,
# such as a project folder in Documents.
workspace_dir <- file.path(tempdir(), "moover_first_run")
dir.create(workspace_dir, recursive = TRUE, showWarnings = FALSE)

# Copy the example workspace into that writable location.
# After this step, you have your own working copy of the example files.
file.copy(
  from = list.files(example_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE),
  to = workspace_dir,
  recursive = TRUE
)
```

At this point, you have a normal `moover` workspace on your own machine.
In the next chapter we’ll look at that folder structure in more detail.
For now, we just need it in place so the run has somewhere to write its
outputs.

## Create a simple run specification

Next, we create a small object that stores the instructions for the run.
`moover` calls this a specification, or *spec* for short. You do not
need to write JSON by hand. The
[`create_spec()`](https://wobblytwilliams.github.io/moover/reference/create_spec.md)
function builds that instruction set for you.

In this first example we keep things simple:

- we point `moover` to the example workspace
- we tell it where the tech and observation files are
- we use the standard beginner feature set
- we turn optimisation off for now

``` r
# Create a simple run specification.
# The workspace root is the folder we just copied the example files into.
spec <- create_spec(
  workspace = list(root = workspace_dir),
  labels = list(
    # tech.csv links animal ids and accelerometer ids when needed.
    tech_file = "tech.csv",
    # observations.csv contains the labelled behaviour periods.
    path = "observations.csv"
  ),
  features = list(
    # Use the beginner-friendly standard feature set.
    selection = "standard",
    standard_set = "manual5"
  ),
  optimise = list(
    # Keep the first run simpler and quicker.
    enabled = FALSE
  )
)
```

## Run the full workflow

Now we can hand the spec to
[`run_pipeline()`](https://wobblytwilliams.github.io/moover/reference/run_pipeline.md).
In this beginner example, `stage = "all"` means:

1.  import the raw accelerometer files
2.  build epoch features
3.  match those features to the observations
4.  train and validate the model
5.  export the finished model bundle

``` r
# Run the full beginner workflow.
# This may still take a little time on a normal computer, and that is expected.
run_pipeline(spec, stage = "all")
```

If you would rather answer questions interactively than write code, you
can do the same job with the wizard:

``` r
# Open the beginner training wizard.
# The wizard explains each question before asking for input.
wizard_train()
```

## Look at what the run created

After the run finishes, the most important thing is simply to open the
workspace and look around. A finished `moover` run should not feel
mysterious. You should be able to point to the run folder and say, “That
is the run I just completed.”

You should now see:

- a new folder inside `runs/`
- a `results/` folder containing intermediate outputs and summaries
- a `models/` folder containing an exported model bundle
- plots and quality-check files you can inspect later

That is enough for a first success. You do not need to understand every
file yet. Right now, the goal is confidence: you have a complete run, on
your own machine, using the same workflow you will later use on your own
data.

**Move through the tutorial**  
Next chapter: [Chapter 2. Set Up Your
Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)
