# Predict Behaviour with an Existing Model

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

This is **Chapter 6 of 10** in the beginner path.

## Who this page is for

This page is for users who already have an exported model bundle and
want to apply it to new accelerometer data.

## What you will achieve

By the end of this page, you will know:

- when to use an existing model instead of training a new one
- which files you need for prediction
- where to find the epoch-level output
- how to request simple summaries if you need them

## Why this matters

Many collaborators will never train a model themselves. They only need a
safe and understandable way to use an existing one.

## What we’re doing

We are taking a model bundle that already exists and applying it to new
raw movement data.

## What you need

You need:

- a model bundle folder
- a workspace with raw files in `data_raw/`
- a `tech.csv` file if your IDs need mapping

## The beginner path

The guided option is:

``` r
# Open the prediction wizard.
# The wizard asks where the model bundle is and where the new raw data lives.
wizard_predict()
```

## The same workflow in copy-pasteable code

The code below is trying to achieve one prediction run on new raw data
using a model that already exists.

``` r
library(moover)

spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(
    # There are no training observations in this workflow.
    path = NULL
  ),
  predict = list(
    # Point to the folder that contains the exported model bundle.
    model_bundle = "path/to/exported_bundle"
  )
)

# Run only the prediction step.
# This reads the new raw files, calculates the required features, and writes predictions.
run_pipeline(spec, stage = "predict")
```

## Optional summaries

If you want more than epoch-level predictions, the code below adds
hourly and daily summaries.

``` r
spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(path = NULL),
  predict = list(
    # Use an existing exported model.
    model_bundle = "path/to/exported_bundle",
    # Ask moover to also write summary tables.
    summary_outputs = c("hourly", "daily")
  )
)
```

## Compatibility checklist

Before predicting with an existing model, check that you are using:

- the same type of sensor data
- the same expected feature inputs
- a broadly similar recording setup where that matters
- the right ID mapping for your animals or devices

## What success looks like

A successful run should give you an epoch-level prediction file in the
run’s `results/` folder. If you requested summaries, you should also see
those files written there.

## Common mistakes

- Pointing to the wrong bundle directory.
- Predicting on raw files that do not match the expected input style.
- Forgetting to provide `tech.csv` when IDs need mapping.
- Expecting a prediction model to work well on very different data
  collection setups without checking compatibility.

**Move through the tutorial**  
Previous chapter: [Chapter 5. Build Your First Behaviour
Model](https://wobblytwilliams.github.io/moover/articles/build-a-model.md)  
Next chapter: [Chapter 7. Understand Your Results and Export
Folder](https://wobblytwilliams.github.io/moover/articles/deployment-export-format.md)
