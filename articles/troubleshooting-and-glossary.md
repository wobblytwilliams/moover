# Troubleshooting and Glossary

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

This is **Chapter 10 of 10** in the beginner path.

If something goes wrong, that does not mean you are “bad at R” or that
the project is failing. Most problems in an early `moover` workflow are
ordinary setup issues: a path is wrong, a timestamp is being interpreted
incorrectly, or ids do not line up across files.

This chapter collects the most common issues in one place.

## When the import preview looks wrong

If the import preview does not look sensible, stop there and fix the
import before doing anything else.

Typical causes are:

- the wrong timestamp format was chosen
- the wrong columns were mapped in a generic file
- the ids in the raw data are not the ids you expected

The preview stage exists precisely so you can catch those problems
early.

## When training fails or behaves strangely

If training runs but the results look suspicious, the most common causes
are usually in the inputs rather than the Random Forest settings.

Things to check first:

- Do the observation ids match the raw-data ids?
- Are the observation times in the right timezone and format?
- Are the behaviour labels spelled consistently?
- Do you actually have enough labelled examples for each behaviour?

These checks are usually more productive than changing model settings at
random.

## When prediction gives unexpected results

If a prediction run finishes but the outputs do not make sense, ask
whether the new data really matches the conditions the model expects.

For example:

- Is it the same type of accelerometer data?
- Are the ids being mapped correctly?
- Can the same features be rebuilt from the new files?

Unexpected predictions do not automatically mean the model is broken.
Often they mean the new dataset is not aligned with the training setup.

## A short glossary

**Accelerometer file**: the raw movement data recorded by the device.

**Canonical format**: the standard 5-column layout `moover` uses
internally: `id`, `t_unix_ms`, `x`, `y`, `z`.

**Epoch**: a fixed time block. `moover` builds features for each block.

**Feature**: a numeric summary calculated from the movement data within
an epoch.

**Model bundle**: the exported folder containing the fitted model and
supporting files.

**LOCO**: leave-one-cow-out validation, meaning the model is tested on
animals not used for training.

**Spec**: a saved set of instructions for a run.

## When to ask for help

A good moment to ask for help is after you have answered three
questions:

1.  Which chapter were you following?
2.  Which file or step seems to be causing trouble?
3.  What did the preview or output look like when it went wrong?

Those details usually make it much easier for someone else to help you
quickly.

**Move through the tutorial**  
Previous chapter: [Chapter 9. Scripted Reruns and Saved
Specs](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.md)  
Back to the start: [Chapter 1. Start
Here](https://wobblytwilliams.github.io/moover/articles/getting-started.md)
