# Import Raw Accelerometer Data

Reads configured raw files, converts them to the canonical `id`,
`t_unix_ms`, `x`, `y`, `z` layout, and writes preview and summary
artefacts into the run.

## Usage

``` r
import_accel(spec)
```

## Arguments

- spec:

  A `moover_spec` object or path to a JSON spec.

## Value

A list containing the canonical preview, summary, and output paths.
