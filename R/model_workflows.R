moover_make_pipeline_config <- function(spec, run_paths) {
  roll_windows <- spec$optimise$roll_windows_seconds %||% spec$features$roll_windows_seconds
  roll_fns <- spec$optimise$roll_fns %||% spec$features$roll_fns
  raw_dirs <- if (identical(spec$ingest$format, "generic")) {
    c(run_paths$canonical_raw_dir)
  } else {
    c(moover_normalize_path(spec$ingest$raw_dir, base = spec$workspace$root, must_work = TRUE))
  }
  list(
    paths = list(
      tech_file = run_paths$prepared_tech_file,
      obs_file = run_paths$prepared_obs_file,
      raw_dirs = raw_dirs,
      raw_file_pattern = "_cquFormat\\.csv$",
      out_model_dir = run_paths$data_dir,
      out_raw_ds_dir = file.path(run_paths$qc_dir, "raw_downsampled"),
      optimization_base_dir = run_paths$optimise_dir,
      export_base_dir = run_paths$models_dir
    ),
    model = list(
      mode = spec$model$mode,
      positive_class = spec$model$positive_class,
      seed = as.integer(spec$model$seed),
      num_threads = as.integer(spec$model$num_threads),
      include_class_weights = isTRUE(spec$model$include_class_weights)
    ),
    data = list(
      epoch_lengths = as.integer(spec$epochs$lengths),
      downsample_keep_every_n = as.integer(spec$ingest$downsample_keep_every_n),
      chunk_rows = spec$ingest$chunk_rows,
      use_legacy_raw_reader = isTRUE(spec$ingest$use_legacy_raw_reader),
      epoch_seconds_for_raw_id = as.integer(spec$epochs$raw_epoch_seconds %||% min(spec$epochs$lengths)),
      tz_local_raw_noz = spec$ingest$timezone,
      raw_nest_delim = "|",
      raw_max_samples_per_epoch = NULL,
      majority_thresh = spec$labels$majority_thresh,
      write_downsampled_raw = TRUE,
      label_hygiene = list(
        enable_edge_trimming = TRUE,
        edge_trim_seconds = as.integer(spec$labels$edge_trim_seconds),
        enable_min_bout_duration = TRUE,
        min_bout_seconds = as.integer(spec$labels$min_bout_seconds)
      ),
      sparse_epoch_drop = list(
        drop_sparse_epochs = TRUE,
        sparse_frac_of_median = 0.5
      )
    ),
    optimise = list(
      epochs_to_run = as.integer(spec$optimise$epochs_to_run %||% spec$epochs$lengths),
      importance_num_trees = as.integer(spec$optimise$importance_num_trees),
      topN_grid = as.integer(spec$optimise$topN_grid),
      enable_rolling_search = isTRUE(spec$features$include_rolling) ||
        isTRUE(spec$optimise$enabled && spec$optimise$enable_rolling_search),
      roll_windows_seconds = as.integer(roll_windows),
      roll_fns = as.character(roll_fns),
      roll_on_selected_base_features_only = isTRUE(spec$features$roll_on_selected_base_features_only),
      na_drop_mode = spec$optimise$na_drop_mode,
      num_trees_grid = as.integer(spec$optimise$num_trees_grid),
      min_node_size_grid = as.integer(spec$optimise$min_node_size_grid),
      plots_dpi = 150L
    ),
    selection = list(
      selection_mode = spec$optimise$selection_mode %||% "profile",
      selected_candidate_id = spec$optimise$selected_candidate_id,
      selected_profile_name = spec$optimise$selected_profile_name,
      accuracy_tolerance = spec$optimise$accuracy_tolerance,
      manual_candidate = NULL
    ),
    export = list(
      export_tag = spec$export$export_tag,
      export_tree_dump_json = isTRUE(spec$export$export_tree_dump_json),
      tree_dump_max_trees = as.integer(spec$export$tree_dump_max_trees)
    ),
    test_vectors = list(
      test_vectors_sample_n = as.integer(spec$export$test_vectors_sample_n),
      test_vectors_sample_max = as.integer(spec$export$test_vectors_sample_max),
      test_vector_feature_set = spec$export$test_vectors_feature_set,
      include_raw_in_test_vectors = isTRUE(spec$export$include_raw_test_vectors),
      include_prev_raw_context = isTRUE(spec$export$include_prev_raw_context),
      prediction_source = spec$export$prediction_source,
      write_test_vectors_all = isTRUE(spec$export$write_test_vectors_all),
      set_seed_test_vectors = as.integer(spec$model$seed)
    )
  )
}

moover_resolve_manual_features <- function(spec, dt_epoch) {
  selection <- tolower(spec$features$selection %||% "all")
  if (identical(selection, "all")) {
    return(get_base_feature_names(dt_epoch))
  }
  if (identical(selection, "standard")) {
    fs <- moover_feature_sets()[[spec$features$standard_set]]
    if (is.null(fs)) stop("Unknown standard feature set: ", spec$features$standard_set)
    return(fs)
  }
  if (identical(selection, "manual")) {
    if (is.null(spec$features$manual_features) || length(spec$features$manual_features) < 1L) {
      stop("features$manual_features must be supplied when selection = 'manual'.")
    }
    return(as.character(spec$features$manual_features))
  }
  stop("Unknown features$selection: ", spec$features$selection)
}

moover_prepare_training_candidate <- function(spec, dt_epoch) {
  epoch_seconds <- as.integer(spec$epochs$lengths[[1]])
  feats <- moover_resolve_manual_features(spec, dt_epoch)
  topn_label <- switch(
    tolower(spec$features$selection %||% "all"),
    all = "all",
    standard = spec$features$standard_set,
    manual = paste0("manual", length(feats)),
    paste0("manual", length(feats))
  )
  data.table::data.table(
    candidate_id = sprintf(
      "ep%ss_%s_%s_trees%s_node%s",
      epoch_seconds,
      tolower(topn_label),
      if (isTRUE(spec$features$include_rolling)) "roll" else "noroll",
      spec$model$num_trees,
      spec$model$min_node_size
    ),
    epoch_seconds = epoch_seconds,
    topN_label = topn_label,
    rolling_enabled = isTRUE(spec$features$include_rolling),
    n_base_features = length(feats),
    selected_base_features = paste(feats, collapse = "|"),
    num_trees = as.integer(spec$model$num_trees),
    min_node_size = as.integer(spec$model$min_node_size)
  )
}

moover_apply_manual_selection <- function(config, candidate) {
  config$selection$selection_mode <- "manual"
  config$selection$selected_candidate_id <- NULL
  config$selection$selected_profile_name <- NULL
  config$selection$manual_candidate <- list(
    epoch_seconds = as.integer(candidate$epoch_seconds),
    manual_features = strsplit(as.character(candidate$selected_base_features), "|", fixed = TRUE)[[1]],
    rolling_enabled = isTRUE(candidate$rolling_enabled),
    num_trees = as.integer(candidate$num_trees),
    min_node_size = as.integer(candidate$min_node_size),
    candidate_id = as.character(candidate$candidate_id),
    topN_label = as.character(candidate$topN_label)
  )
  config
}

moover_write_eval_plots <- function(eval_res, out_dir) {
  moover_ensure_dir(out_dir)
  cm <- data.table::copy(eval_res$confusion_matrix)
  p1 <- ggplot2::ggplot(cm, ggplot2::aes(x = predicted, y = truth, fill = n)) +
    ggplot2::geom_tile() +
    ggplot2::geom_text(ggplot2::aes(label = n), colour = "white") +
    ggplot2::scale_fill_gradient(low = "#90c2e7", high = "#0b3c5d") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Confusion Matrix", x = "Predicted", y = "Truth")
  ggplot2::ggsave(file.path(out_dir, "plot_confusion_matrix.png"), p1, width = 6, height = 4, dpi = 150)
  rc <- data.table::copy(eval_res$recall_by_class)
  p2 <- ggplot2::ggplot(rc, ggplot2::aes(x = class, y = recall, fill = class)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Recall by Class", x = "Class", y = "Recall")
  ggplot2::ggsave(file.path(out_dir, "plot_recall_by_class.png"), p2, width = 6, height = 4, dpi = 150)
}

#' Build Epoch Features
#'
#' Converts configured labelled data into the canonical epoch feature dataset
#' used by training and optimisation.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#'
#' @return The path to the canonical epoch feature dataset.
#' @export
build_epoch_features <- function(spec) {
  spec <- moover_read_spec(spec)
  run_paths <- moover_run_paths(spec)
  moover_prepare_inputs(spec, run_paths, require_labels = TRUE)
  config <- moover_make_pipeline_config(spec, run_paths)
  path <- build_canonical_dataset(config)
  invisible(path)
}

#' Optimise a moover Model
#'
#' Runs the RF optimisation workflow and writes candidate tables, plots, and
#' profile selections into the current run.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#'
#' @return The optimisation output directory.
#' @export
optimise_model <- function(spec) {
  spec <- moover_read_spec(spec)
  run_paths <- moover_run_paths(spec)
  moover_prepare_inputs(spec, run_paths, require_labels = TRUE)
  config <- moover_make_pipeline_config(spec, run_paths)
  if (!file.exists(canonical_dataset_path(config))) {
    build_canonical_dataset(config)
  }
  optimise_candidates(config)
  optimisation_output_dir(config)
}

#' Train a moover Model
#'
#' Trains a Random Forest model either from the selected optimisation candidate
#' or from the feature/model settings in the spec.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#'
#' @return A fitted model bundle stored in the run cache and returned as a list.
#' @export
train_model <- function(spec) {
  spec <- moover_read_spec(spec)
  run_paths <- moover_run_paths(spec)
  moover_prepare_inputs(spec, run_paths, require_labels = TRUE)
  config <- moover_make_pipeline_config(spec, run_paths)
  if (!file.exists(canonical_dataset_path(config))) {
    build_canonical_dataset(config)
  }
  if (isTRUE(spec$optimise$enabled)) {
    results_path <- file.path(optimisation_output_dir(config), "candidate_results.csv")
    if (!file.exists(results_path)) {
      optimise_candidates(config)
    }
    candidate <- resolve_selected_candidate(config)
  } else {
    dt_tmp <- load_canonical_dataset(config)
    dt_epoch_tmp <- dt_tmp[epoch_seconds == as.integer(spec$epochs$lengths[[1]])]
    candidate <- moover_prepare_training_candidate(spec, dt_epoch_tmp)
    config <- moover_apply_manual_selection(config, candidate)
  }
  dt <- load_canonical_dataset(config)
  dt_epoch <- dt[epoch_seconds == as.integer(candidate$epoch_seconds)]
  eval_res <- evaluate_candidate_loco(dt_epoch, candidate, config)
  full_fit <- fit_full_candidate_model(dt_epoch, candidate, config)
  cache <- list(
    spec = spec,
    config = config,
    candidate = candidate,
    eval_res = eval_res,
    full_fit = full_fit,
    run_paths = run_paths
  )
  saveRDS(cache, run_paths$fit_cache)
  moover_write_eval_plots(eval_res, run_paths$plots_dir)
  cache
}

#' Export a moover Model Bundle
#'
#' Writes a deployable model bundle containing the trained model, specs,
#' feature manifest, metrics, plots, and test vectors.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#' @param fitted_model Optional result from [train_model()]. If `NULL`, the
#'   cached fit for the run is used.
#'
#' @return The export directory.
#' @export
export_model <- function(spec, fitted_model = NULL) {
  spec <- moover_read_spec(spec)
  run_paths <- moover_run_paths(spec)
  if (is.null(fitted_model)) {
    if (!file.exists(run_paths$fit_cache)) {
      fitted_model <- train_model(spec)
    } else {
      fitted_model <- readRDS(run_paths$fit_cache)
    }
  }
  export_dir <- write_export_pack(
    candidate = fitted_model$candidate,
    eval_res = fitted_model$eval_res,
    full_fit = fitted_model$full_fit,
    config = fitted_model$config
  )
  moover_write_json(fitted_model$spec, file.path(export_dir, "model_spec.json"))
  manifest_csv <- file.path(export_dir, "feature_manifest.csv")
  if (file.exists(manifest_csv)) {
    manifest <- data.table::fread(manifest_csv)
    moover_write_json(manifest, file.path(export_dir, "feature_manifest.json"))
  }
  moover_write_eval_plots(fitted_model$eval_res, export_dir)
  build_test_vectors_from_selected_model(fitted_model$config)
  invisible(export_dir)
}

#' Load a moover Model Bundle
#'
#' Loads an exported bundle from disk for prediction or inspection.
#'
#' @param path Path to an exported model bundle directory.
#'
#' @return A list with class `moover_model_bundle`.
#' @export
load_model_bundle <- function(path) {
  root <- moover_normalize_path(path, must_work = TRUE)
  bundle <- list(
    path = root,
    model = readRDS(file.path(root, "rf_model_full.rds")),
    feature_manifest = data.table::fread(file.path(root, "feature_manifest.csv")),
    export_config = jsonlite::read_json(file.path(root, "export_config.json"), simplifyVector = FALSE)
  )
  model_spec_path <- file.path(root, "model_spec.json")
  bundle$model_spec <- if (file.exists(model_spec_path)) {
    jsonlite::read_json(model_spec_path, simplifyVector = FALSE)
  } else {
    NULL
  }
  class(bundle) <- "moover_model_bundle"
  bundle
}

#' @export
print.moover_model_bundle <- function(x, ...) {
  cat("<moover_model_bundle>\n", sep = "")
  cat("  path: ", x$path, "\n", sep = "")
  cat("  features: ", nrow(x$feature_manifest), "\n", sep = "")
  invisible(x)
}

moover_prediction_spec <- function(spec, model_bundle = NULL) {
  pred_spec <- spec
  if (!is.null(pred_spec$predict$raw_dir) && nzchar(pred_spec$predict$raw_dir)) {
    pred_spec$ingest$raw_dir <- pred_spec$predict$raw_dir
  }
  if (!is.null(model_bundle)) {
    pred_spec$predict$model_bundle <- model_bundle
  }
  pred_spec
}

moover_roll_settings_from_predictors <- function(predictors) {
  roll_cols <- predictors[startsWith(predictors, "roll")]
  if (length(roll_cols) == 0L) {
    return(list(enabled = FALSE, windows = integer(0), fns = character(0)))
  }
  parts <- strsplit(roll_cols, "_", fixed = TRUE)
  windows <- unique(as.integer(sub("^roll", "", vapply(parts, `[`, character(1), 1L))))
  fns <- unique(vapply(parts, `[`, character(1), 2L))
  list(enabled = TRUE, windows = windows, fns = fns)
}

moover_build_prediction_features <- function(canonical_dt, epoch_seconds, predictors, include_raw = FALSE) {
  data.table::setDT(canonical_dt)
  out_list <- lapply(unique(canonical_dt$id), function(one_id) {
    sub <- data.table::copy(canonical_dt[id == one_id])
    sub[, datetime_utc := as.POSIXct(t_unix_ms / 1000, origin = "1970-01-01", tz = "UTC")]
    sub[, ms_to_origin_utc := sprintf("%.0f", t_unix_ms)]
    data.table::setorder(sub, datetime_utc)
    sub <- add_sample_features(sub)
    feat <- compute_epoch_features_utc(data.table::copy(sub), epoch_seconds)
    feat[, id := one_id]
    if (isTRUE(include_raw)) {
      nested <- build_epoch_raw_nesting(data.table::copy(sub), epoch_seconds, raw_nest_delim = "|")
      data.table::setkey(feat, epoch_start, epoch_end)
      data.table::setkey(nested, epoch_start, epoch_end)
      feat <- nested[feat, on = .(epoch_start, epoch_end)]
    }
    feat
  })
  out <- data.table::rbindlist(out_list, use.names = TRUE, fill = TRUE)
  roll_settings <- moover_roll_settings_from_predictors(predictors)
  if (isTRUE(roll_settings$enabled)) {
    base_cols <- get_base_feature_names(out)
    out <- add_trailing_roll_features(
      DT = out,
      time_col = "epoch_start",
      by_col = "id",
      feature_cols = base_cols,
      pred_epoch = epoch_seconds,
      roll_windows_seconds = roll_settings$windows,
      roll_fns = roll_settings$fns
    )
    out <- apply_na_policy(
      DT = out,
      predictors = predictors,
      na_drop_mode = "warmup",
      enable_rolling_features = TRUE,
      roll_windows_seconds = roll_settings$windows
    )
  } else {
    out <- apply_na_policy(
      DT = out,
      predictors = predictors,
      na_drop_mode = "all_predictors",
      enable_rolling_features = FALSE,
      roll_windows_seconds = integer(0)
    )
  }
  out
}

moover_write_prediction_summaries <- function(pred_dt, run_paths, summary_outputs = character()) {
  if ("hourly" %in% summary_outputs) {
    hourly <- data.table::copy(pred_dt)
    hourly[, hour := format(epoch_start, "%Y-%m-%dT%H:00:00Z", tz = "UTC")]
    hourly <- hourly[, .(n_epochs = .N), by = .(id, hour, predicted)]
    hourly[, prop_time := n_epochs / sum(n_epochs), by = .(id, hour)]
    data.table::fwrite(hourly, file.path(run_paths$results_dir, "hourly_summary.csv"))
  }
  if ("daily" %in% summary_outputs) {
    daily <- data.table::copy(pred_dt)
    daily[, day := format(epoch_start, "%Y-%m-%d", tz = "UTC")]
    daily <- daily[, .(n_epochs = .N), by = .(id, day, predicted)]
    daily[, prop_time := n_epochs / sum(n_epochs), by = .(id, day)]
    data.table::fwrite(daily, file.path(run_paths$results_dir, "daily_summary.csv"))
  }
}

#' Predict Behaviour from an Existing Model
#'
#' Applies an exported model bundle to new raw accelerometer data and writes
#' epoch-level predictions into the current run.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#' @param model_bundle A bundle object returned by [load_model_bundle()] or a
#'   path to an exported model bundle directory. If `NULL`, `spec$predict$model_bundle`
#'   is used.
#'
#' @return A data table of epoch-level predictions.
#' @export
predict_behaviour <- function(spec, model_bundle = NULL) {
  spec <- moover_read_spec(spec)
  bundle <- model_bundle %||% spec$predict$model_bundle
  if (is.null(bundle)) stop("Supply a model bundle path or set predict$model_bundle in the spec.")
  if (!inherits(bundle, "moover_model_bundle")) {
    bundle <- load_model_bundle(bundle)
  }
  pred_spec <- moover_prediction_spec(spec, model_bundle = bundle$path)
  run_paths <- moover_run_paths(pred_spec)
  moover_prepare_inputs(pred_spec, run_paths, require_labels = FALSE)
  tech <- moover_load_tech(pred_spec, required = FALSE)
  canonical <- moover_collect_canonical_accel(pred_spec, tech = tech)
  epoch_seconds <- bundle$model_spec$epochs$lengths[[1]] %||%
    bundle$export_config$candidate$epoch_seconds %||%
    bundle$export_config$params$epoch_seconds_keep %||%
    10L
  predictors <- as.character(bundle$feature_manifest$feature)
  feat_dt <- moover_build_prediction_features(
    canonical_dt = canonical,
    epoch_seconds = as.integer(epoch_seconds),
    predictors = predictors,
    include_raw = isTRUE(pred_spec$predict$include_raw)
  )
  probs <- predict(bundle$model, data = feat_dt[, ..predictors])$predictions
  prob_dt <- data.table::as.data.table(probs)
  pred_class <- colnames(probs)[max.col(probs, ties.method = "first")]
  data.table::setnames(prob_dt, paste0("prob_", colnames(prob_dt)))
  out <- data.table::data.table(
    id = feat_dt$id,
    epoch_start = feat_dt$epoch_start,
    epoch_end = feat_dt$epoch_end,
    predicted = pred_class
  )
  out <- cbind(out, prob_dt)
  data.table::fwrite(out, file.path(run_paths$results_dir, "epoch_predictions.csv"))
  moover_write_prediction_summaries(out, run_paths, summary_outputs = pred_spec$predict$summary_outputs)
  out
}

moover_pipeline_start <- function(spec, stage, run_paths) {
  raw_dir_value <- if (identical(stage, "predict") && !is.null(spec$predict$raw_dir) && nzchar(spec$predict$raw_dir)) {
    spec$predict$raw_dir
  } else {
    spec$ingest$raw_dir
  }
  raw_dir <- moover_normalize_path(raw_dir_value, base = spec$workspace$root, must_work = FALSE)
  workspace_root <- moover_normalize_path(spec$workspace$root, must_work = FALSE)
  chunk_rows <- spec$ingest$chunk_rows
  moover_console_header(
    "moover pipeline",
    intro = "moover will work through the requested stage and describe each step in plain language as it goes."
  )
  moover_console_bullet(paste0("Run id: ", run_paths$run_id))
  moover_console_bullet(paste0("Requested stage: ", stage))
  moover_console_bullet(paste0("Run folder: ", run_paths$run_root))
  if (moover_path_is_within(raw_dir, workspace_root)) {
    moover_console_bullet(paste0("Raw files will be read from the workspace: ", raw_dir))
  } else {
    moover_console_bullet(paste0("Raw files will be read from an external location: ", raw_dir))
  }
  moover_console_bullet("Derived files for this run will be written locally inside the run folder.")
  if (moover_is_chunked_ingest(chunk_rows)) {
    moover_console_bullet(
      paste0(
        "Large-file mode is enabled. moover will read raw data in fixed chunks of ",
        format(as.integer(chunk_rows), big.mark = ",", scientific = FALSE, trim = TRUE),
        " rows."
      )
    )
  } else {
    moover_console_bullet("Large-file mode is off. moover will read each raw file in one pass.")
  }
  cat("\n")
}

moover_pipeline_finish <- function(text = "Pipeline complete.") {
  moover_console_rule("=")
  cat(text, "\n", sep = "")
  moover_console_rule("=")
}

moover_report_fit_summary <- function(fit) {
  metrics <- data.table::as.data.table(fit$eval_res$metrics_overall)
  accuracy <- metrics[metric == "accuracy", estimate][1]
  macro_f1 <- metrics[metric == "macro_f1", estimate][1]
  moover_console_bullet(paste0("Candidate used: ", fit$candidate$candidate_id))
  moover_console_bullet(paste0("Predictors used: ", length(fit$full_fit$predictors)))
  if (!is.na(accuracy)) {
    moover_console_bullet(paste0("LOCO accuracy: ", sprintf("%.4f", accuracy)))
  }
  if (!is.na(macro_f1)) {
    moover_console_bullet(paste0("LOCO macro F1: ", sprintf("%.4f", macro_f1)))
  }
  cat("\n")
}

moover_report_export_summary <- function(export_dir, config) {
  moover_console_bullet(paste0("Export folder: ", export_dir))
  moover_console_bullet(paste0("Model bundle id: ", basename(export_dir)))
  cat("\n")
}

moover_report_prediction_summary <- function(pred_dt, run_paths, summary_outputs = character()) {
  moover_console_bullet(paste0("Epoch predictions: ", file.path(run_paths$results_dir, "epoch_predictions.csv")))
  moover_console_bullet(paste0("Predicted epochs: ", format(nrow(pred_dt), big.mark = ",", scientific = FALSE, trim = TRUE)))
  moover_console_bullet(paste0("Animals predicted: ", data.table::uniqueN(pred_dt$id)))
  if ("hourly" %in% summary_outputs) {
    moover_console_bullet(paste0("Hourly summary: ", file.path(run_paths$results_dir, "hourly_summary.csv")))
  }
  if ("daily" %in% summary_outputs) {
    moover_console_bullet(paste0("Daily summary: ", file.path(run_paths$results_dir, "daily_summary.csv")))
  }
  cat("\n")
}

#' Run a moover Pipeline
#'
#' Executes one stage or a full workflow from a JSON spec or spec object.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#' @param stage One of `"import"`, `"features"`, `"train"`, `"optimise"`,
#'   `"predict"`, `"export"`, or `"all"`.
#'
#' @return The stage result.
#' @export
run_pipeline <- function(spec, stage = c("import", "features", "train", "optimise", "predict", "export", "all")) {
  spec <- moover_read_spec(spec)
  stage <- match.arg(stage)
  run_paths <- moover_run_paths(spec)
  
  if (identical(stage, "import")) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Import and check the raw accelerometer data",
      "Read the raw files, convert them into moover's standard five-column format, and save a preview so you can quickly check that the import looks sensible."
    )
    out <- import_accel(spec)
    moover_pipeline_finish("Import complete.")
    return(out)
  }
  if (identical(stage, "features")) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Build fixed time blocks and calculate features",
      "Group the movement data into fixed time blocks and calculate the feature set needed for model training or optimisation."
    )
    out <- build_epoch_features(spec)
    moover_pipeline_finish("Feature building complete.")
    return(out)
  }
  if (identical(stage, "optimise")) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Compare candidate models",
      "Use the prepared feature dataset to compare multiple model candidates and write the optimisation tables that help you choose a trade-off between size and performance."
    )
    out <- optimise_model(spec)
    moover_console_bullet(paste0("Optimisation output folder: ", out))
    cat("\n")
    moover_pipeline_finish("Optimisation complete.")
    return(out)
  }
  if (identical(stage, "train")) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Train and validate the model",
      "Fit the Random Forest model and evaluate how well it performs on held-out animals."
    )
    out <- train_model(spec)
    moover_report_fit_summary(out)
    moover_pipeline_finish("Training complete.")
    return(out)
  }
  if (identical(stage, "export")) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Export the model bundle",
      "Write the fitted model, feature list, metrics, and test vectors into a shareable export folder."
    )
    out <- export_model(spec)
    config <- if (file.exists(run_paths$fit_cache)) readRDS(run_paths$fit_cache)$config else moover_make_pipeline_config(spec, run_paths)
    moover_report_export_summary(out, config)
    moover_pipeline_finish("Export complete.")
    return(out)
  }
  if (identical(stage, "predict")) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Predict behaviour on new data",
      "Read the new accelerometer files, rebuild the features expected by the model bundle, and write epoch-level predictions."
    )
    out <- predict_behaviour(spec)
    moover_report_prediction_summary(out, run_paths, summary_outputs = spec$predict$summary_outputs)
    moover_pipeline_finish("Prediction complete.")
    return(out)
  }
  label_path <- spec$labels$path %||% ""
  label_exists <- nzchar(label_path) &&
    file.exists(moover_normalize_path(label_path, base = spec$workspace$root, must_work = FALSE))
  if (!is.null(spec$predict$model_bundle) && !label_exists) {
    moover_pipeline_start(spec, stage, run_paths)
    moover_console_step(
      1,
      "Predict behaviour on new data",
      "No observation file was supplied, so moover will use the model bundle to generate predictions rather than run a training workflow."
    )
    out <- predict_behaviour(spec)
    moover_report_prediction_summary(out, run_paths, summary_outputs = spec$predict$summary_outputs)
    moover_pipeline_finish("Prediction complete.")
    return(out)
  }
  
  moover_pipeline_start(spec, stage, run_paths)
  
  step_no <- 1L
  moover_console_step(
    step_no,
    "Import and check the raw accelerometer data",
    "Read the raw files, convert them into moover's standard five-column format, and save a preview so you can quickly check that the import looks sensible."
  )
  import_accel(spec)
  
  step_no <- step_no + 1L
  moover_console_step(
    step_no,
    "Build fixed time blocks and calculate features",
    "Group the movement data into fixed time blocks and calculate the feature set needed for model training."
  )
  build_epoch_features(spec)
  
  if (isTRUE(spec$optimise$enabled)) {
    step_no <- step_no + 1L
    moover_console_step(
      step_no,
      "Compare candidate models",
      "Evaluate multiple model candidates so you can choose a trade-off between size and performance before fitting the final model."
    )
    optimise_model(spec)
  }
  
  step_no <- step_no + 1L
  moover_console_step(
    step_no,
    "Train and validate the model",
    "Fit the Random Forest model and check its performance on held-out animals."
  )
  fit <- train_model(spec)
  moover_report_fit_summary(fit)
  
  step_no <- step_no + 1L
  moover_console_step(
    step_no,
    "Export the model bundle and write test vectors",
    "Write the fitted model, feature list, metrics, and test vectors into a shareable export folder."
  )
  export_dir <- export_model(spec, fit)
  moover_report_export_summary(export_dir, fit$config)
  
  if (isTRUE(spec$predict$predict_after_export)) {
    step_no <- step_no + 1L
    moover_console_step(
      step_no,
      "Run prediction on new data",
      "Apply the model bundle to new accelerometer files and write epoch-level predictions."
    )
    pred_spec <- spec
    if (is.null(pred_spec$predict$model_bundle)) {
      pred_spec$predict$model_bundle <- export_dir
    }
    pred_out <- predict_behaviour(pred_spec)
    moover_report_prediction_summary(pred_out, run_paths, summary_outputs = pred_spec$predict$summary_outputs)
  }
  moover_pipeline_finish("Pipeline complete.")
  invisible(export_dir)
}
