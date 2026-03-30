# Record Observations for Training

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

This is **Chapter 4 of 10** in the beginner path.

A behaviour model can only learn if the observations are recorded in a
consistent way. In `moover`, the observation file is not meant to
describe every single accelerometer sample. Instead, it describes
periods of time during which a known behaviour was observed.

We’ll do three things in this chapter:

1.  define what one observation row means
2.  look at the minimum fields the file needs
3.  check the most common problems before training

## One row means one observed bout

The easiest way to think about the observation file is this: each row
describes one labelled behaviour period for one animal.

For example, if animal A was grazing from 10:00:00 to 10:03:00, that is
one row. If the same animal was then resting from 10:03:00 to 10:08:00,
that is another row.

## The minimum information you need

At training time, `moover` needs to know four things from each row:

- which animal the observation belongs to
- which behaviour label was observed
- when the behaviour started
- when the behaviour ended

Here is a simple example.

``` r
obs_example <- data.frame(
  id = c("Cow_01", "Cow_01", "Cow_02"),
  label = c("grazing", "resting", "grazing"),
  start_unix_ms = c(1712128800000, 1712128980000, 1712128800000),
  end_unix_ms = c(1712128980000, 1712129280000, 1712129100000)
)

knitr::kable(obs_example)
```

| id     | label   | start_unix_ms |  end_unix_ms |
|:-------|:--------|--------------:|-------------:|
| Cow_01 | grazing |  1.712129e+12 | 1.712129e+12 |
| Cow_01 | resting |  1.712129e+12 | 1.712129e+12 |
| Cow_02 | grazing |  1.712129e+12 | 1.712129e+12 |

That table is deliberately simple. In your own file, the columns can
have different names if you map them in the spec, but those four ideas
must still be present.

## Why label spelling matters

The model does not know that `Graze`, `grazing`, and `GRAZING` might
mean the same thing to a human reader. To the model, those are different
labels unless you standardise them.

A good beginner habit is to choose one spelling for each behaviour and
use it everywhere.

## Time needs the same care as labels

Observation times need to line up with the accelerometer times. If they
are in the wrong timezone or mixed formats, the model may look as though
it is performing badly when the real problem is simply that the labels
are not lining up with the movement data.

This is why `moover` converts times internally to UTC milliseconds. It
gives the later steps one consistent time scale to work with.

## A short QC checklist before training

Before you start a training run, it is worth checking these questions:

- Do the animal ids match the ids used by the accelerometer data?
- Are the behaviour names spelled consistently?
- Do the start and end times make sense in the same timezone as the
  accelerometer recording?
- Are there overlapping bouts that should be resolved first?

Those checks are not glamorous, but they usually matter more than the
choice of model settings in an early project.

**Move through the tutorial**  
Previous chapter: [Chapter 3. Prepare Your Accelerometer
Files](https://wobblytwilliams.github.io/moover/articles/accelerometer-input-formats.md)  
Next chapter: [Chapter 5. Build Your First Behaviour
Model](https://wobblytwilliams.github.io/moover/articles/build-a-model.md)
