# Initialise a moover Workspace

Creates a standard folder layout in any working directory without
requiring an `.Rproj` file.

## Usage

``` r
init_workspace(path = getwd())
```

## Arguments

- path:

  Workspace root. Defaults to the current working directory.

## Value

A list of workspace paths with class `moover_workspace`.
