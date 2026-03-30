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

This is **Chapter 6 of 10** in the beginner path.

Many people will use `moover` without ever training a model themselves.
They may receive an exported model bundle from a collaborator and want
to apply it to new accelerometer files. This chapter is for that
workflow.

We’ll do three things:

1.  identify the files you need
2.  run prediction on new data
3.  see what the outputs mean

## What you need before you begin

For prediction, you need:

- a model bundle that was exported by `moover`
- a folder of raw accelerometer files
- a `tech.csv` file if you need to map logger ids back to animal ids

In most cases, the model bundle is the main thing. It contains the
fitted model, the feature list, and the settings needed to rebuild the
same features on new data.

Just as in the training workflow, the raw files you want to predict on
do not have to be copied into the workspace. They can stay on another
drive, while `moover` writes the prediction outputs locally in the
current run folder.

## The easiest path: use the prediction wizard

The prediction wizard is a good choice when you want help checking the
bundle path and raw data path before running.

``` r
library(moover)

# Open the prediction wizard.
# The wizard explains what each path is for before asking for input.
wizard_predict()
```

## The same workflow in code

The same prediction run can also be written as a spec. Here, the most
important choice is the `model_bundle` path.

``` r
library(moover)

spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  ingest = list(
    # Point to the folder containing the new raw accelerometer files.
    # This can be inside the workspace or on an external drive.
    raw_dir = "data_raw"
  ),
  labels = list(
    # Supply tech.csv if you need it for id mapping.
    tech_file = "tech.csv",
    # No observation file is needed for prediction-only work.
    path = NULL
  ),
  predict = list(
    # This should point to the exported model folder.
    model_bundle = "path/to/exported_model_bundle",
    # Keep the default epoch-level predictions.
    summary_outputs = character()
  )
)

# Run prediction using the existing model bundle.
run_pipeline(spec, stage = "predict")
```

## What happens during prediction

Prediction is shorter than model training, but the logic is similar.
`moover` still needs to take the raw movement data through the same
feature-building process that was used during training.

In practice, it will:

1.  read the new raw data
2.  standardise the timestamps
3.  build the same fixed time blocks used by the model
4.  calculate the same features expected by the model bundle
5.  write epoch-level predictions and class probabilities

The key idea is consistency. A model is only useful on new data if the
features are rebuilt the same way.

If the raw files are very large, you can also turn on chunked reading
with `ingest$chunk_rows`. That tells `moover` to read a fixed number of
rows at a time without changing the feature definitions used for
prediction.

## What the output looks like

The main output file is `epoch_predictions.csv`. Each row represents one
fixed time block, and the file includes:

- the animal id
- the start and end time of the block
- the predicted behaviour
- class probabilities

That is usually the most useful prediction output because it keeps the
detail of the original time series.

If you choose an optional summary, `moover` can also write hourly or
daily proportion-of-time tables. Those are helpful when you want a quick
behavioural summary rather than a row for every epoch.

## A quick compatibility check

Before trusting the predictions, it is worth asking three simple
questions:

- Is this the same kind of sensor data the model was trained on?
- Can `moover` rebuild the same features the bundle expects?
- Is the recording setup broadly similar to the one used during
  training?

Those questions are not there to discourage prediction. They are there
because a good model still depends on sensible input data.

**Move through the tutorial**  
Previous chapter: [Chapter 5. Build Your First Behaviour
Model](https://wobblytwilliams.github.io/moover/articles/build-a-model.md)  
Next chapter: [Chapter 7. Understand Your Results and Export
Folder](https://wobblytwilliams.github.io/moover/articles/deployment-export-format.md)
