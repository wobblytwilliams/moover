# Scripted Reruns and Saved Specs

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

This is **Chapter 9 of 10** in the beginner path.

Up to this point, we have focused on the beginner path. Now we move one
step toward reproducibility and automation.

The key idea in this chapter is simple: a *spec* is just a saved set of
instructions for a `moover` run.

## Why saved specs are useful

When people run a workflow interactively, they often remember the broad
choices but forget the exact settings. A saved spec solves that problem.
It records the file locations and settings in a form that can be reused.

That means a spec is useful for at least three reasons:

1.  you can rerun the same workflow later
2.  you can share the run instructions with a colleague
3.  you can move from interactive work to scripted work without changing
    the underlying pipeline

## Create a spec in code

Here is a simple example of a spec for a training workflow.

``` r
library(moover)

spec <- create_spec(
  workspace = list(root = "my_moover_workspace"),
  labels = list(
    tech_file = "tech.csv",
    path = "observations.csv"
  ),
  features = list(
    selection = "standard",
    standard_set = "manual5"
  ),
  optimise = list(enabled = FALSE)
)
```

Once you have the spec, you can rerun the same workflow directly.

``` r
run_pipeline(spec, stage = "all")
```

## Use a saved JSON spec

`moover` also writes specs to JSON so that runs can be reproduced later
without stepping through the wizard again.

``` r
# Re-run a workflow from a previously saved JSON spec.
run_pipeline("runs/20260330_012345/spec/run_spec.json", stage = "all")
```

You do not need to hand-edit JSON to benefit from this. Most beginners
can think of the JSON file as a saved record of the choices they already
made.

## A good workflow to aim for

A common pattern is:

1.  start with the wizard
2.  let `moover` save the spec for you
3.  rerun that same spec later in code when you want something
    repeatable

That is a nice bridge between beginner and advanced use. You do not have
to jump straight into scripting on day one.

**Move through the tutorial**  
Previous chapter: [Chapter 8. Optimise a Model for
Deployment](https://wobblytwilliams.github.io/moover/articles/optimise-a-model-for-deployment.md)  
Next chapter: [Chapter 10. Troubleshooting and
Glossary](https://wobblytwilliams.github.io/moover/articles/troubleshooting-and-glossary.md)
