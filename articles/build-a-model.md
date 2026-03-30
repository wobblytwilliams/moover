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

This is **Chapter 5 of 10** in the beginner path.

By now, you should have a workspace, raw accelerometer files, and an
observation file. In this chapter we turn those inputs into a first
behaviour model.

In broad terms, we want to do three things:

1.  tell `moover` where the files are
2.  train and validate the model
3.  export a bundle we can reuse later

Let’s do those in turn.

## The easiest path: use the wizard

For a first run, the wizard is the easiest option because it explains
each question before asking you to answer it.

``` r
library(moover)

# Open the training wizard.
# The wizard will guide you through the file paths and settings,
# and it can run the full workflow for you.
wizard_train()
```

That is the right choice for many beginners. It is also a good way to
learn the order of the steps before writing any code.

## The same workflow in code

If you prefer copy-pasteable code, we can express the same training run
with a spec. The spec simply records the choices we want `moover` to
use.

``` r
library(moover)

# Create a run specification for a beginner training run.
spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(
    # tech.csv links animal ids and accelerometer ids when that mapping is needed.
    tech_file = "tech.csv",
    # observations.csv contains the labelled behaviour periods used for training.
    path = "observations.csv"
  ),
  features = list(
    # Use the standard beginner feature set.
    selection = "standard",
    standard_set = "manual5"
  ),
  optimise = list(
    # For a first model, keep optimisation off.
    enabled = FALSE
  ),
  model = list(
    # In a binary model, this is the behaviour treated as the positive class.
    positive_class = "grazing"
  )
)

# Run the complete workflow from import through export.
run_pipeline(spec, stage = "all")
```

## What happens during the run

A model-training run can feel like a lot is happening behind the scenes,
so it helps to name the main steps plainly.

During the run, `moover` will:

1.  read the raw accelerometer files
2.  standardise the timestamps
3.  group the samples into fixed time blocks
4.  calculate features for each block
5.  line those blocks up with the observed behaviour bouts
6.  train and validate the Random Forest model
7.  write an export bundle containing the fitted model and support files

That is the full arc of the training workflow.

## What the main metrics mean

After the run, you will see several outputs. Three of the most useful
are accuracy, macro F1, and the confusion matrix.

**Accuracy** tells you the proportion of predictions that were correct
overall.

**Macro F1** gives each class equal weight. That is useful when one
behaviour is much more common than another.

The **confusion matrix** shows which behaviours are being confused with
each other. That is often more informative than accuracy alone.

`moover` also reports performance using LOCO, which means testing on
animals the model has not seen during training. That usually gives a
more realistic sense of how the model will behave on new animals.

## What you should expect to find afterwards

A successful run leaves behind a clear trail:

- a run folder inside `runs/`
- results files and quality checks
- plots showing model performance
- an exported model bundle inside the run’s `models/` folder

At this point you do not need to memorise every output file. The
important thing is to know that the model bundle is there and that it
can be used later for prediction or sharing.

**Move through the tutorial**  
Previous chapter: [Chapter 4. Record Observations for
Training](https://wobblytwilliams.github.io/moover/articles/recording-observations.md)  
Next chapter: [Chapter 6. Predict Behaviour with an Existing
Model](https://wobblytwilliams.github.io/moover/articles/predict-with-existing-model.md)
