# Optimise a Model for Deployment

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

This is **Chapter 8 of 10** in the beginner path, and it is optional.

## Who this page is for

This page is for users who already have a working model and now need to
make choices about size, speed, and performance.

## What you will achieve

By the end of this page, you will understand:

- why a smaller model may be useful
- what tradeoffs are involved
- where the candidate comparison files are written
- how to choose a candidate that matches your priorities

## Why this matters

If you are deploying onto a device with limited memory, the best model
is not always the largest or most accurate one. Sometimes a slightly
smaller model is the better practical choice.

## What we’re doing

We are comparing multiple candidate models and choosing one based on a
tradeoff among accuracy, macro F1, and model size.

## The beginner message

You do not need to do this for your first successful run. Optimisation
is a later step once you already trust the basic workflow.

## Do this

The code below is trying to achieve a full run where `moover` tests
multiple model candidates instead of training just one fixed model.

``` r
spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  optimise = list(
    # Turn on candidate search.
    # This tells moover to compare multiple model settings before exporting one.
    enabled = TRUE
  )
)

# Run the full workflow, including optimisation.
run_pipeline(spec, stage = "all")
```

## What to look at in the candidate tables

The main candidate comparison table helps you compare things like:

- accuracy
- macro F1
- number of features
- number of trees
- minimum node size
- model size proxy

A practical way to read the table is:

1.  decide what minimum performance you can accept
2.  filter to candidates above that level
3.  choose the smallest or simplest remaining model

## What success looks like

A good optimisation outcome is not “the biggest table.” It is a
confident choice that matches your real deployment needs.

## Common mistakes

- Optimising before you have a baseline model that already works.
- Focusing only on accuracy and ignoring size.
- Making the model tiny without checking whether the performance drop is
  acceptable.

**Move through the tutorial**  
Previous chapter: [Chapter 7. Understand Your Results and Export
Folder](https://wobblytwilliams.github.io/moover/articles/deployment-export-format.md)  
Next chapter: [Chapter 9. Scripted Reruns and Saved
Specs](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.md)
