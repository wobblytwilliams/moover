# Getting Started

`moover` works in any folder. You do not need an `.Rproj` file.

## 1. Initialise a workspace

``` r
library(moover)

init_workspace("my_moover_workspace")
```

This creates:

- `data_raw/`
- `runs/`
- `_internal/`

## 2. Add your files

Put raw accelerometer files into `data_raw/`.

For training workflows, also place:

- `tech.csv`
- `observations.csv`

in the workspace root, or point to them explicitly in your spec.

## 3. Choose your workflow

For beginners:

``` r
wizard_train()
wizard_predict()
```

For scripted reruns:

``` r
spec <- create_spec()
run_pipeline(spec, stage = "all")
```

## 4. Example data

You can inspect the packaged example workspace:

``` r
system.file("extdata", "example_workspace", package = "moover")
```
