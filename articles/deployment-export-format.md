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

This is **Chapter 7 of 10** in the beginner path.

After the first successful run, many beginners ask the same question:
“Which of these files do I actually care about?” That is a good
question. A finished `moover` run contains several outputs, but you do
not need to understand every file at once.

In this chapter, we’ll walk through the main files and what they are
for.

## Start with the run folder

A completed run sits inside `runs/<run_id>/`. Inside that folder you
will usually see several subfolders, including `results/`, `models/`,
`plots/`, and `qc/`.

A useful way to think about them is this:

- `results/` holds the data products from the run
- `models/` holds the model export bundles
- `plots/` holds figures that help you inspect performance
- `qc/` holds previews and checks that help you confirm the data looked
  sensible

## The export bundle

Inside the run’s `models/` folder, you will find one or more exported
model bundles. That bundle is the part most likely to be shared with
collaborators.

A typical bundle includes:

- `rf_model_full.rds`
- `feature_manifest.csv`
- `model_spec.json`
- `metrics_overall.csv`
- `metrics_by_class.csv`
- `confusion_matrix.csv`
- `test_vectors.csv`
- `rf_tree_dump.json`

## Which files matter to different people?

Different users care about different parts of the export.

### For the R user

The most important files are usually:

- the model bundle folder itself
- `rf_model_full.rds`
- `feature_manifest.csv`
- the metrics files

These are the files you need to inspect the model in R or use it again
later.

### For a collaborator checking calculations

The most useful files are often:

- `feature_manifest.csv`
- `test_vectors.csv`
- `test_vectors_all.csv` if present
- the metrics files

These help another person confirm that features and predictions are
being reproduced correctly.

### For someone implementing the model elsewhere

The most useful files are usually:

- `feature_manifest.csv`
- `model_spec.json`
- `rf_tree_dump.json`
- the test vector files

Those files define what needs to be rebuilt outside R and provide
concrete examples to test against.

## Why test vectors matter

The test vector files are especially useful because they give you real
examples of inputs and expected outputs from the model. If somebody is
reimplementing the feature calculations in Python or on an embedded
device, the test vectors are usually the quickest way to check whether
they are getting the same results.

## You do not need to memorise everything

A common beginner mistake is to think that understanding `moover` means
understanding every file at once. It doesn’t. Start with the run folder,
the export bundle, and the main metrics. The rest becomes easier once
those parts feel familiar.

**Move through the tutorial**  
Previous chapter: [Chapter 6. Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md)  
Next chapter: [Chapter 8. Optimise a Model for
Deployment](https://wobblytwilliams.github.io/moover/articles/optimise-a-model-for-deployment.md)
