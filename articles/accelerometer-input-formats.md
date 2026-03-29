# Prepare Your Accelerometer Files

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

This is **Chapter 3 of 10** in the beginner path.

## Who this page is for

This page is for users preparing their own accelerometer files for the
first time.

## What you will achieve

By the end of this page, you will know:

- which file styles `moover` supports in v1
- what the timestamp column needs to represent
- how `moover` turns different files into one standard 5-column format
- which common file problems to check before running the pipeline

## Why this matters

If the raw files are not interpreted correctly, everything downstream
becomes harder. Good inputs make the rest of the workflow much calmer.

## What we’re doing

We are making sure your accelerometer files are in a shape that `moover`
can understand.

The package supports two starting points:

- CQU-style files, which are the default
- generic delimited files, where you tell the package which columns are
  which

## The two supported input routes

### 1. CQU-style files

This is the default input route.

Expected columns:

- `datetime`
- `x`
- `y`
- `z`

Example:

``` text
datetime,x,y,z
2025-01-01T00:00:00Z,0.01,0.02,1.00
2025-01-01T00:00:01Z,0.03,0.01,0.99
```

A typical filename looks like this:

``` text
demo-A01_cquFormat.csv
```

### 2. Generic delimited files

If your files use different column names, `moover` can still work with
them. You just need to tell it which columns contain the timestamp, x,
y, z, and animal or accelerometer identifier.

## Why the timestamp matters so much

Your timestamp tells `moover` when each movement sample happened. Later
in the pipeline, the package groups samples into fixed time blocks so it
can calculate features and make behaviour predictions.

In v1, `moover` converts times internally into a standard UTC
millisecond clock. You do not need to hand-build that format yourself,
but you do need to map the input time correctly.

## The standard 5-column format used downstream

No matter which input route you choose, `moover` converts raw data into
the same internal layout:

- `id`
- `t_unix_ms`
- `x`
- `y`
- `z`

This is helpful because it means the rest of the workflow can stay
consistent.

## Do this

If your files are already in the CQU style, the simplest thing to do is
use the import wizard.

``` r
# Open the import wizard.
# The wizard asks what type of raw file you have and where the files live.
wizard_import()
```

If your files are generic delimited files, the code below is trying to
achieve one very specific thing: it tells `moover` how to interpret the
raw table.

``` r
# Create a spec for generic files instead of the default CQU-style files.
spec <- create_spec(
  ingest = list(format = "generic"),
  schema = list(
    raw = list(
      # The source column that contains the timestamp.
      datetime = "timestamp_ms",
      # The source columns for the x, y, and z acceleration values.
      x = "acc_x",
      y = "acc_y",
      z = "acc_z",
      # The column that identifies the animal or device.
      id = "animal_id",
      # Tell moover whether that id column contains animal ids or accelerometer ids.
      id_type = "id",
      # Tell moover how to interpret the timestamp values.
      time_format = "unix_ms"
    )
  )
)
```

[`create_spec()`](https://wobblytwilliams.github.io/moover/reference/create_spec.md)
is not importing the data yet. It is saving the instructions that tell
`moover` how the raw data should be read.

## What success looks like

After a successful import, you should be able to confirm that:

- the right animal or accelerometer IDs were recognised
- timestamps look sensible
- x, y, and z are numeric
- the preview file in the run folder looks like your real data

## Good files versus common problems

A good file usually has:

- one row per sample
- a clear timestamp column
- separate x, y, and z columns
- consistent formatting from top to bottom

Common problems include:

- wrong timestamp interpretation
- mismatched animal IDs
- missing headers
- swapped axis columns
- mixed file formats in the same folder

## Common mistakes

- Using local times but telling the package they are already UTC.
- Giving different files different header styles.
- Mixing accelerometer IDs and animal IDs without a proper `tech.csv`
  mapping.
- Forgetting to check the preview after import.

**Move through the tutorial**  
Previous chapter: [Chapter 2. Set Up Your
Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)  
Next chapter: [Chapter 4. Record Observations for
Training](https://wobblytwilliams.github.io/moover/articles/recording-observations.md)
