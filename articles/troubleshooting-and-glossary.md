# Troubleshooting and Glossary

## You are here

This is **Chapter 10 of 10** in the tutorial path.

## Who this page is for

This page is for anyone who got stuck, feels unsure about a term, or
wants a quick place to look before asking for help.

## What you will achieve

By the end of this page, you will have:

- a checklist of common problems
- plain-language definitions for important `moover` terms
- pointers to the most relevant tutorial pages

## Why this matters

Beginners often do not need more detail. They need the right next clue.

## Common problems and where to look

### My raw files are not being read correctly

Check:

- the file format tutorial: [Chapter 3. Prepare Your Accelerometer
  Files](https://wobblytwilliams.github.io/moover/articles/accelerometer-input-formats.md)
- the preview file written into `qc/`
- whether your timestamp column was mapped correctly

### My observations are not matching properly

Check:

- the observation tutorial: [Chapter 4. Record Observations for
  Training](https://wobblytwilliams.github.io/moover/articles/recording-observations.md)
- whether IDs match the accelerometer workflow
- whether start and end times are in the correct timezone or format

### I do not understand where the outputs went

Check:

- [Chapter 2. Set Up Your
  Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)
- [Chapter 7. Understand Your Results and Export
  Folder](https://wobblytwilliams.github.io/moover/articles/deployment-export-format.md)

### My run is taking longer than I expected

This can be normal on a local computer, especially for optimisation or
larger datasets. Start with a simpler run first, then add complexity
once you trust the workflow.

### I only want predictions, not model training

Go straight to [Chapter 6. Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md).

## Plain-language glossary

### Workspace

The folder that holds your raw files, runs, and internal working files.

### Standard 5-column movement format

The internal layout used downstream by `moover`: `id`, `t_unix_ms`, `x`,
`y`, `z`.

### Fixed time block

A short, fixed chunk of time used to group raw samples before
calculating features. In more technical writing this is often called an
epoch.

### Feature

A summary value calculated from a fixed time block of movement data.

### Observation bout

One labelled behaviour period with a start time and end time.

### Model bundle

The shareable folder containing the trained model plus supporting files.

### Test vectors

Reference rows used by collaborators to check that they can reproduce
the same feature values and predictions in another implementation.

### LOCO

Short for leave-one-cow-out. In plain language, it means testing on
animals the model has not seen in training.

### Saved spec

A saved set of instructions describing how a run should be carried out.

## When to ask for help

Ask for help when:

- you cannot tell whether the imported timestamps are correct
- your IDs are not matching between files
- you are unsure whether your output files are sensible
- you are deciding between model candidates for deployment

When you ask, it helps to share:

- a small example of the file you are using
- the run folder or the relevant quality-check files
- the exact step where you became unsure

**Move through the tutorial**  
Previous chapter: [Chapter 9. Scripted Reruns and Saved
Specs](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.md)  
Start again: [Chapter 1. Start
Here](https://wobblytwilliams.github.io/moover/articles/getting-started.md)
