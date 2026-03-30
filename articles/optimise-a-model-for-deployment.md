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

This is **Chapter 8 of 10** in the beginner path.

This chapter is optional. You do not need optimisation to build a useful
first model. Optimisation becomes helpful when you want to balance model
performance against model size, memory use, or embedded deployment
constraints.

## Why optimise at all?

A model with the best possible accuracy is not always the most practical
model. On an embedded device, for example, you may need a smaller model
even if that means giving up a little performance.

So optimisation is really about choosing a trade-off. In `moover`, that
usually means comparing candidates that differ in things like:

- feature subset size
- number of trees
- minimum node size
- rolling features on or off

## The idea of a candidate model

When `moover` optimises, it does not commit to one model immediately.
Instead, it trains and evaluates multiple candidate models and writes
tables that help you compare them.

In other words, optimisation answers a practical question: *Which model
is good enough, and small enough, for the job I care about?*

## Running optimisation

You can turn optimisation on in the training wizard, or you can do it
explicitly in code.

``` r
library(moover)

spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(
    tech_file = "tech.csv",
    path = "observations.csv"
  ),
  optimise = list(
    enabled = TRUE
  )
)

# Run only the optimisation stage.
optimise_model(spec)
```

## How to read the candidate tables

The optimisation output usually includes candidate tables that list, for
each model:

- accuracy
- macro F1
- model size proxy
- key model settings

A good way to read those tables is to start by deciding what you care
about most. For example:

- Do you want the best possible accuracy?
- Do you want the smallest model above a threshold?
- Do you want a balanced compromise?

Once that decision is clear, the candidate tables become much easier to
interpret.

## A beginner-friendly way to think about the trade-off

If you are new to optimisation, this is a sensible order to follow:

1.  build a working model first
2.  decide what size or speed constraint matters
3.  compare candidates against that constraint
4.  choose the smallest model that still performs well enough

That order keeps optimisation grounded in a practical goal rather than
turning it into a search for abstract “best” settings.

**Move through the tutorial**  
Previous chapter: [Chapter 7. Understand Your Results and Export
Folder](https://wobblytwilliams.github.io/moover/articles/deployment-export-format.md)  
Next chapter: [Chapter 9. Scripted Reruns and Saved
Specs](https://wobblytwilliams.github.io/moover/articles/scripted-reruns-and-saved-specs.md)
