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

This is **Chapter 3 of 10** in the beginner path.

Raw accelerometer data often looks intimidating at first, but `moover`
only needs a small amount of structure from you. In version 1, the
package supports two routes:

1.  CQU-style accelerometer files
2.  generic delimited files, such as CSV files, that you map
    interactively

We’ll look at both.

## The two input routes

If your files already look like the standard CQU format, `moover` can
read them directly. If they do not, that is still fine. The wizard can
preview a generic file and ask which columns contain the time stamp, the
three axes, and the identifier.

That means you do **not** need to rewrite every dataset into a new file
format just to get started.

## A CQU-style file

Let’s look at one of the example files that ships with `moover`.

``` r
library(moover)

# Find one example CQU-style accelerometer file.
cqu_file <- system.file(
  "extdata", "example_workspace", "data_raw", "demo-A01_cquFormat.csv",
  package = "moover"
)

# Preview the first few rows.
head(read.csv(cqu_file))
```

A CQU-style file is expected to have a time column plus `x`, `y`, and
`z`. `moover` then converts that file into its internal standard format:

- `id`
- `t_unix_ms`
- `x`
- `y`
- `z`

You do not have to create those five columns yourself for a CQU-style
file. `moover` creates them during import.

## A generic delimited file

Now consider a dataset that is just a normal CSV file with column names
chosen by the researcher or sensor software.

``` r
# Preview the generic example file that ships with the package.
generic_file <- system.file("extdata", "generic_example.csv", package = "moover")
head(read.csv(generic_file))
```

This is where the generic import path helps. Instead of forcing you to
rename everything in advance, `moover` can ask which columns mean what.

``` r
# Open the import wizard.
# If you choose "Generic delimited files", moover will show a preview
# and ask which columns contain time, x, y, z, and id.
wizard_import()
```

## What `moover` needs to know

No matter which route you use, `moover` eventually needs the same pieces
of information:

- when each sample was recorded
- the x, y, and z acceleration values
- which animal or logger the row belongs to

Internally, it converts everything to one standard 5-column layout in
UTC milliseconds. That standardisation is important because the later
steps, such as building epochs and calculating features, depend on time
being handled consistently.

## Common problems to catch early

Most import problems are easier to fix before you start model building.
Here are the main ones to watch for:

- timestamps interpreted in the wrong format or timezone
- animal ids that do not match the ids used elsewhere in the workspace
- missing headers in generic files
- x, y, and z columns mapped in the wrong order
- a folder that mixes different file structures together

The wizard helps here because it shows previews before going further. If
the preview looks wrong, that is the moment to stop and correct the
mapping.

## A good beginner habit

Before training a model, always do one small import run and look at the
preview output. That one habit prevents a lot of confusion later.

**Move through the tutorial**  
Previous chapter: [Chapter 2. Set Up Your
Workspace](https://wobblytwilliams.github.io/moover/articles/set-up-your-workspace.md)  
Next chapter: [Chapter 4. Record Observations for
Training](https://wobblytwilliams.github.io/moover/articles/recording-observations.md)
