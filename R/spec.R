moover_default_spec <- function() {
  structure(
    list(
      package_version = "0.0.0.9000",
      workspace = list(
        root = moover_normalize_path(getwd(), must_work = FALSE),
        data_raw_dir = "data_raw",
        runs_dir = "runs",
        internal_dir = "_internal"
      ),
      run = list(
        run_id = moover_timestamp_run_id(),
        label = NULL
      ),
      ingest = list(
        format = "cqu",
        raw_dir = "data_raw",
        raw_file_pattern = "_cquFormat\\.csv$",
        recursive = FALSE,
        timezone = "Australia/Brisbane",
        downsample_keep_every_n = 2L,
        chunk_rows = NULL,
        large_file_warning_bytes = 524288000,
        write_canonical_accel = TRUE,
        preview_n = 12L,
        use_legacy_raw_reader = FALSE,
        delimiter = ","
      ),
      schema = list(
        raw = list(
          datetime = "datetime",
          x = "x",
          y = "y",
          z = "z",
          id = "id",
          id_type = "id",
          time_format = "iso8601_local"
        ),
        tech = list(
          id = "id",
          accelerometer = "accelerometer"
        ),
        observations = list(
          id = "id",
          label = "label",
          start = "start_unix_ms",
          end = "end_unix_ms",
          time_format = "unix_ms"
        )
      ),
      labels = list(
        tech_file = "tech.csv",
        path = "observations.csv",
        majority_thresh = 0.5,
        edge_trim_seconds = 5L,
        min_bout_seconds = 30L,
        class_filter = NULL
      ),
      epochs = list(
        lengths = c(10L),
        raw_epoch_seconds = 10L,
        alignment = "absolute"
      ),
      features = list(
        selection = "all",
        standard_set = "manual5",
        manual_features = NULL,
        include_rolling = FALSE,
        roll_windows_seconds = c(30L, 60L),
        roll_fns = c("mean", "sd", "cv"),
        roll_on_selected_base_features_only = TRUE
      ),
      model = list(
        backend = "ranger_rf",
        mode = "binary",
        positive_class = "grazing",
        seed = 1L,
        num_threads = 1L,
        include_class_weights = FALSE,
        num_trees = 10L,
        min_node_size = 5L
      ),
      optimise = list(
        enabled = FALSE,
        epochs_to_run = c(10L),
        importance_num_trees = 500L,
        topN_grid = c(1L, 2L, 3L, 5L, 10L, 15L, 20L, 30L),
        enable_rolling_search = TRUE,
        roll_windows_seconds = c(30L, 60L),
        roll_fns = c("mean", "sd", "cv"),
        na_drop_mode = "warmup",
        num_trees_grid = c(10L, 25L),
        min_node_size_grid = c(5L, 10L),
        accuracy_tolerance = 0.005,
        selection_mode = "profile",
        selected_profile_name = "best_balanced",
        selected_candidate_id = NULL
      ),
      predict = list(
        model_bundle = NULL,
        raw_dir = NULL,
        output_level = "epoch",
        summary_outputs = character(),
        include_raw = FALSE,
        predict_after_export = FALSE
      ),
      export = list(
        export_tag = "moover_export",
        include_raw_test_vectors = TRUE,
        include_prev_raw_context = TRUE,
        test_vectors_feature_set = "modelled",
        test_vectors_sample_n = 2000L,
        test_vectors_sample_max = 3000L,
        prediction_source = "full_model",
        write_test_vectors_all = TRUE,
        export_tree_dump_json = TRUE,
        tree_dump_max_trees = 50L
      )
    ),
    class = "moover_spec"
  )
}

#' Create a moover Specification
#'
#' Builds a reproducible package spec that can be written to JSON and reused in
#' scripted or interactive workflows.
#'
#' @param workspace,ingest,schema,labels,epochs,features,model,optimise,predict,export
#'   Named lists that override the default spec sections.
#' @param run Optional named list for run metadata.
#' @param path Optional path to write the JSON spec.
#' @param interactive Included for compatibility with wizard helpers.
#'
#' @return An object of class `moover_spec`.
#' @export
create_spec <- function(workspace = list(), ingest = list(), schema = list(),
                        labels = list(), epochs = list(), features = list(),
                        model = list(), optimise = list(), predict = list(),
                        export = list(), run = list(), path = NULL,
                        interactive = FALSE) {
  spec <- moover_default_spec()
  overrides <- list(
    workspace = workspace,
    ingest = ingest,
    schema = schema,
    labels = labels,
    epochs = epochs,
    features = features,
    model = model,
    optimise = optimise,
    predict = predict,
    export = export,
    run = run
  )
  spec <- moover_deep_merge(spec, overrides)
  spec$workspace$root <- moover_normalize_path(spec$workspace$root, must_work = FALSE)
  if (!is.null(path)) {
    moover_write_json(spec, moover_normalize_path(path, base = spec$workspace$root, must_work = FALSE))
  }
  spec
}

moover_spec_path_default <- function(spec) {
  run_paths <- moover_run_paths(spec)
  moover_ensure_run_dirs(run_paths)
  run_paths$run_spec_file
}

moover_write_spec <- function(spec, path = NULL) {
  path <- path %||% moover_spec_path_default(spec)
  moover_write_json(spec, path)
}

moover_read_spec <- function(spec) {
  if (inherits(spec, "moover_spec")) return(spec)
  if (!is.character(spec) || length(spec) != 1L) {
    stop("`spec` must be a moover_spec object or a path to JSON.")
  }
  path <- moover_normalize_path(spec, must_work = TRUE)
  parsed <- jsonlite::read_json(path, simplifyVector = FALSE)
  class(parsed) <- "moover_spec"
  parsed
}

#' @export
print.moover_spec <- function(x, ...) {
  cat("<moover_spec>\n", sep = "")
  cat("  workspace: ", x$workspace$root, "\n", sep = "")
  cat("  run_id: ", x$run$run_id, "\n", sep = "")
  cat("  ingest format: ", x$ingest$format, "\n", sep = "")
  cat("  model backend: ", x$model$backend, "\n", sep = "")
  cat("  optimise enabled: ", isTRUE(x$optimise$enabled), "\n", sep = "")
  invisible(x)
}
