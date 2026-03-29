# Build Your First Behaviour Model

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

This is **Chapter 5 of 10** in the beginner path.

If you already have a trained model and only want predictions, you can
skip ahead to [Chapter 6: Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md).

## Who this page is for

This page is for users who have raw files and observations ready and
want to train a first model.

## What you will achieve

By the end of this page, you will know:

- how to start a beginner-friendly training run
- what `moover` is doing during that run
- where to find your outputs
- how to interpret the first few metrics without drowning in jargon

## Why this matters

This is the point where your prepared files turn into a behaviour model
you can reuse and share.

## What we’re doing

We are using raw accelerometer data plus behaviour observations to
build, validate, and export a first Random Forest model.

## The beginner path

For most new users, the easiest option is the guided wizard:

``` r
# Open the training wizard.
# The wizard asks where your files are and then runs the beginner workflow.
wizard_train()
```

The wizard asks you where your files are, whether you want to optimise
for deployment, and which label should be treated as the positive class
in a binary model.

## The same workflow in copy-pasteable code

The code below is trying to achieve a complete beginner training run
without optimisation.

``` r
library(moover)

# Create a run specification that points moover at your workspace.
# The workspace root is the folder that contains data_raw/, tech.csv, and observations.csv.
spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(
    # tech.csv links animal ids and accelerometer ids when needed.
    tech_file = "tech.csv",
    # observations.csv contains the labelled behaviour periods for training.
    path = "observations.csv"
  ),
  features = list(
    # Use the standard beginner-friendly feature set.
    selection = "standard",
    standard_set = "manual5"
  ),
  optimise = list(
    # Keep the first run simple.
    # We are not searching over many candidate models here.
    enabled = FALSE
  ),
  model = list(
    # In a binary model, this is the class treated as the positive outcome.
    positive_class = "grazing"
  )
)

# Run the full workflow.
# Here, stage = "all" means import, feature building, training, evaluation, and export.
run_pipeline(spec, stage = "all")
```

## What `moover` does during the run

In plain language, the workflow does this:

1.  reads your raw accelerometer files
2.  standardises the timestamps
3.  groups the samples into fixed time blocks
4.  calculates features from each block
5.  matches the blocks to the behaviour observations
6.  trains and validates the model
7.  exports the model bundle and support files

## What the main metrics mean

### Accuracy

This is the proportion of predictions that were correct overall.

### Macro F1

This gives each behaviour class equal weight, which helps when classes
are unbalanced.

### Confusion matrix

This shows where the model is getting behaviours right and where it is
mixing them up.

### LOCO

`moover` uses LOCO evaluation, which means testing on animals the model
has not seen in training. This is a more realistic check than simply
testing on the same animals used to build the model.

## What success looks like

After a successful run, you should have:

- a run folder in `runs/`
- results files and plots
- an exported model bundle in the run’s `models/` folder
- test vectors and feature manifest files for sharing or checking the
  model later

## Common mistakes

- Starting a training run before checking raw-file previews.
- Using observation labels that do not match the intended behaviour
  classes.
- Forgetting that a local run may take time.
- Turning optimisation on too early when you only want a first working
  model.

**Move through the tutorial**  
Previous chapter: [Chapter 4. Record Observations for
Training](https://wobblytwilliams.github.io/moover/articles/recording-observations.md)  
Next chapter: [Chapter 6. Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md)
