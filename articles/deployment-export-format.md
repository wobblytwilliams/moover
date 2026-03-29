# Understand Your Results and Export Folder

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

This is **Chapter 7 of 10** in the beginner path.

## Who this page is for

This page is for users who have finished a run and want help
understanding the output folders.

## What you will achieve

By the end of this page, you will know:

- what the main output folders are for
- which files matter most for everyday use
- which files are useful for collaborators or embedded deployment work
- where to look first when checking whether a run behaved as expected

## Why this matters

A finished run can look busy. This page helps you understand which files
are the practical ones and which files are mainly there for
reproducibility or sharing.

## What we’re doing

We are walking through a completed run folder and explaining the most
important outputs in plain language.

## A typical run structure

A run usually looks something like this:

``` text
runs/<run_id>/
  spec/
  results/
  models/
  plots/
  qc/
```

## The folders in plain language

### `spec/`

This stores the saved instructions used for the run.

### `results/`

This contains the main data outputs created during the workflow.

### `models/`

This is where exported model bundles are written.

### `plots/`

This contains figures that help you inspect model behaviour.

### `qc/`

This holds previews and quality-check files, especially helpful when you
want to confirm that data import worked as expected.

## Key files you are likely to use

### For the R user

- `metrics_overall.csv`
- `metrics_by_class.csv`
- `confusion_matrix.csv`
- prediction outputs in `results/`

### For collaborators checking the model

- `feature_manifest.csv`
- `test_vectors.csv`
- `test_vectors_all.csv`

### For someone implementing the model elsewhere

- `rf_tree_dump.json`
- `feature_manifest.csv`
- `model_spec.json`
- test vectors for checking feature values and predictions

## What the exported model bundle is for

The model bundle is the shareable package of files that lets someone:

- reload the model in R
- inspect what features were used
- test another implementation against known outputs
- understand how the model was configured

## What success looks like

You should be able to answer these practical questions:

- Which file tells me the overall model performance?
- Which folder contains the exported model I can share?
- Which files would a collaborator use to check their own
  implementation?

## Common mistakes

- Looking at `_internal/` before checking the run folder.
- Treating every output file as equally important.
- Sharing only the model object and forgetting the feature manifest and
  test vectors.

**Move through the tutorial**  
Previous chapter: [Chapter 6. Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md)  
Next chapter: [Chapter 8. Optimise a Model for
Deployment](https://wobblytwilliams.github.io/moover/articles/optimise-a-model-for-deployment.md)
