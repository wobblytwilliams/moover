# Record Observations for Training

## You are here

This is **4 of 10** in the beginner path.

## Who this page is for

This page is for users who want to train a model from observed
behaviours.

## What you will achieve

By the end of this page, you will understand:

- what an observation bout is
- how to organise one row per labelled behaviour period
- why naming consistency matters
- what to check before starting model training

## Why this matters

A model can only learn from the behaviour labels you provide. Clear,
consistent observations give you a much better chance of getting a
useful model.

## What we’re doing

We are building a training table where each row describes one labelled
behaviour period for one animal.

## A beginner-friendly way to think about the table

Each row answers four simple questions:

- Which animal was this?
- What behaviour was it showing?
- When did that behaviour start?
- When did it end?

A simple beginner-friendly example might look like this:

``` text
animal_id,behaviour,start_time,end_time
cow_1,grazing,2025-01-01 10:00:00,2025-01-01 10:02:00
cow_1,resting,2025-01-01 10:02:00,2025-01-01 10:04:00
```

Internally, `moover` maps that information into the fields it needs for
training.

## A directly mapped example

If your file is already in the package’s preferred format, it may look
like this:

``` text
id,label,start_unix_ms,end_unix_ms
cow_1,grazing,1735689600000,1735689720000
cow_1,resting,1735689720000,1735689840000
```

## Do this

If your observation file uses friendly names like `animal_id` and
`start_time`, map them in the spec:

``` r
spec <- create_spec(
  schema = list(
    observations = list(
      id = "animal_id",
      label = "behaviour",
      start = "start_time",
      end = "end_time",
      time_format = "iso8601_local"
    )
  )
)
```

## Why consistent label spelling matters

`grazing`, `Grazing`, and `graze` may look similar to a person, but to a
model they are different labels unless you standardise them.

Choose one spelling per behaviour and stick to it.

## Observation quality-check checklist

Before training, check that:

- each row is one behaviour period
- IDs match the IDs used in your accelerometer workflow
- start and end times are in the correct order
- behaviour names are spelled consistently
- there are no accidental overlaps unless they are truly intended

## What success looks like

A good observation table feels boring in the best way. It is tidy,
consistent, and easy to scan.

## Common mistakes

- Overlapping bouts that should really be separate.
- Inconsistent behaviour names.
- IDs that do not match the accelerometer data.
- Start and end times recorded in the wrong timezone or wrong format.

## What’s next

With raw files and observation labels ready, continue to [Build Your
First Behaviour
Model](https://wobblytwilliams.github.io/moover/articles/build-a-model.md).
