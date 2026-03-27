#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
spec <- NULL
stage <- "all"
i <- 1L
while (i <= length(args)) {
  key <- args[[i]]
  val <- if (i < length(args)) args[[i + 1L]] else NULL
  if (identical(key, "--spec") && !is.null(val)) {
    spec <- val
    i <- i + 2L
    next
  }
  if (identical(key, "--stage") && !is.null(val)) {
    stage <- val
    i <- i + 2L
    next
  }
  stop("Unknown or incomplete argument: ", key)
}

if (is.null(spec)) {
  stop("Usage: Rscript run_pipeline.R --spec path/to/run_spec.json --stage <stage>")
}

moover::run_pipeline(spec = spec, stage = stage)
