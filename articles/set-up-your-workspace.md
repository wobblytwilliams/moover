# Set Up Your Workspace

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

This is **Chapter 2 of 10** in the beginner path.

A `moover` workspace is just an ordinary folder on your computer. You do
not need a high-performance cluster, and you do not need an `.Rproj`
file. What you do need is a consistent place for local outputs, run
histories, and a small number of support files.

In this chapter, we’ll do three things:

1.  create a workspace
2.  look at the folder structure
3.  decide where your main input files belong

## Create the workspace

The
[`init_workspace()`](https://wobblytwilliams.github.io/moover/reference/init_workspace.md)
function creates the standard folder structure. If the folders already
exist, it leaves them in place.

``` r
library(moover)

# Create a moover workspace in a folder of your choice.
# If the folder does not exist yet, moover will create it.
ws <- init_workspace("my_moover_workspace")

# Print the key folder paths that moover will use.
ws
```

That one step gives you the basic structure `moover` expects.

## What the folders are for

A beginner-friendly workspace is helpful because the same questions come
up every time: where are the model outputs, where did the package save
this run, and which folder should I share with a colleague?

A standard `moover` workspace looks like this:

``` text
my_moover_workspace/
  data_raw/
  runs/
  _internal/
  tech.csv
  observations.csv
```

Here is what those folders mean in practice.

### `data_raw/`

This is the default place for raw accelerometer files inside the
workspace. If that is convenient, use it. The files stay here unchanged,
and `moover` reads from this folder without expecting you to hand-edit
them during a run.

Just as importantly, this folder is **optional**. If your raw data is
too large to copy locally, or it already lives on a network drive or
portable drive, you can point `moover` to that external folder instead.

### `runs/`

Every time you run a workflow, `moover` creates a new run folder here.
That makes each run traceable. You can come back later and see exactly
what happened during that run.

### `_internal/`

This folder is for helper files that `moover` writes for its own use.
Most beginners do not need to work directly in this folder, but it is
part of keeping the workflow reproducible.

## Where the main input files go

For a training workflow, two extra files usually sit at the top level of
the workspace:

- `tech.csv`
- `observations.csv`

The `tech.csv` file links animal ids to accelerometer ids when that
mapping is needed. The `observations.csv` file holds the labelled
behaviour periods you want the model to learn from.

A common beginner setup looks like this:

``` text
my_moover_workspace/
  data_raw/
    animal_01_cquFormat.csv
    animal_02_cquFormat.csv
  runs/
  _internal/
  tech.csv
  observations.csv
```

That is the simplest arrangement, and it is a good place to start.

## When your raw data lives somewhere else

Many real projects have more raw data than is comfortable to duplicate
inside a teaching workspace. That is fine. In `moover`, the workspace is
the local home for the **derived** data and outputs. The raw data can
stay somewhere else.

For example, you might have:

``` text
my_moover_workspace/
  runs/
  _internal/
  tech.csv
  observations.csv

E:/portable_drive/cattle_trial_raw/
  animal_01_cquFormat.csv
  animal_02_cquFormat.csv
```

In that situation, you point `ingest$raw_dir` to
`E:/portable_drive/cattle_trial_raw/`, and `moover` will still write the
preview files, epoch dataset, optimisation results, model bundle, and
test vectors into the workspace on your local machine.

That split is worth remembering:

- raw data can be external
- run outputs stay local
- epoch-level data is expected to be held locally

## What a run folder looks like

When you start a run, `moover` creates a self-contained folder inside
`runs/`. The exact name changes from run to run, but the structure is
consistent.

``` text
runs/
  20260330_012345/
    spec/
    results/
    models/
    plots/
    qc/
```

That structure is useful because it means you can answer practical
questions later:

- Which settings did I use?
- Which model export belongs to this run?
- Where are the plots and metrics?

## A note on runtime

`moover` is designed to run locally on an ordinary computer. Larger
datasets can still take time, and that is normal. The main goal of the
package is not to pretend the work is instant; it is to make the work
manageable and understandable for beginners.

If your raw files are very large, `moover` can also read them in
fixed-size chunks instead of trying to load the whole file at once. That
chunk size is controlled with `ingest$chunk_rows`. We use a fixed row
count on purpose because it is easier to explain, easier to reproduce,
and less fragile than trying to guess what your available RAM happens to
be at the moment.

**Move through the tutorial**  
Previous chapter: [Chapter 1. Start
Here](https://wobblytwilliams.github.io/moover/articles/getting-started.md)  
Next chapter: [Chapter 3. Prepare Your Accelerometer
Files](https://wobblytwilliams.github.io/moover/articles/accelerometer-input-formats.md)
