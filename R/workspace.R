#' Initialise a moover Workspace
#'
#' Creates a standard folder layout in any working directory without requiring
#' an `.Rproj` file.
#'
#' @param path Workspace root. Defaults to the current working directory.
#'
#' @return A list of workspace paths with class `moover_workspace`.
#' @export
init_workspace <- function(path = getwd()) {
  root <- moover_normalize_path(path, must_work = FALSE)
  dirs <- list(
    root = root,
    data_raw = file.path(root, "data_raw"),
    runs = file.path(root, "runs"),
    internal = file.path(root, "_internal")
  )
  for (p in dirs) {
    moover_ensure_dir(p)
  }
  class(dirs) <- "moover_workspace"
  dirs
}

#' @export
print.moover_workspace <- function(x, ...) {
  cat("<moover_workspace>\n", sep = "")
  cat("  root: ", x$root, "\n", sep = "")
  cat("  data_raw: ", x$data_raw, "\n", sep = "")
  cat("  runs: ", x$runs, "\n", sep = "")
  cat("  _internal: ", x$internal, "\n", sep = "")
  invisible(x)
}

moover_run_paths <- function(spec) {
  run_id <- spec$run$run_id %||% moover_timestamp_run_id()
  root <- spec$workspace$root
  run_root <- file.path(root, spec$workspace$runs_dir, run_id)
  out <- list(
    run_id = run_id,
    run_root = run_root,
    spec_dir = file.path(run_root, "spec"),
    results_dir = file.path(run_root, "results"),
    models_dir = file.path(run_root, "models"),
    plots_dir = file.path(run_root, "plots"),
    qc_dir = file.path(run_root, "qc"),
    internal_dir = file.path(root, spec$workspace$internal_dir),
    raw_dir = file.path(root, spec$workspace$data_raw_dir)
  )
  out$data_dir <- file.path(out$results_dir, "data")
  out$optimise_dir <- file.path(out$results_dir, "optimisation")
  out$fit_cache <- file.path(out$internal_dir, paste0("fit_", run_id, ".rds"))
  out$canonical_raw_dir <- file.path(out$internal_dir, paste0("prepared_raw_", run_id))
  out$prepared_tech_file <- file.path(out$spec_dir, "tech.csv")
  out$prepared_obs_file <- file.path(out$spec_dir, "observations.csv")
  out$run_spec_file <- file.path(out$spec_dir, "run_spec.json")
  out$canonical_accel_file <- file.path(out$data_dir, "canonical_accel.csv.gz")
  out$canonical_preview_file <- file.path(out$qc_dir, "canonical_accel_preview.csv")
  out$import_summary_file <- file.path(out$qc_dir, "import_summary.json")
  out
}

moover_ensure_run_dirs <- function(run_paths) {
  dirs <- c(
    run_paths$run_root,
    run_paths$spec_dir,
    run_paths$results_dir,
    run_paths$models_dir,
    run_paths$plots_dir,
    run_paths$qc_dir,
    run_paths$internal_dir,
    run_paths$data_dir,
    run_paths$optimise_dir
  )
  for (p in dirs) {
    moover_ensure_dir(p)
  }
  invisible(run_paths)
}
