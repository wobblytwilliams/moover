suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
  library(devtools)
})

script_path <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE), error = function(e) NA_character_)
project_root <- if (!is.na(script_path) && nzchar(script_path)) {
  normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}
load_all(project_root, quiet = TRUE, export_all = TRUE, helpers = FALSE)

source_root <- normalizePath("G:/My Drive/CQU/0 - R Projects/RF_Embed_v2", winslash = "/", mustWork = TRUE)
source_raw_dir <- file.path(source_root, "raw")
source_tech_file <- file.path(source_root, "tech.csv")
source_obs_file <- file.path(source_root, "observations.csv")
source_model_dir <- file.path(
  source_root,
  "model_export",
  "embedded_export_epoch10s_binary_manual5_noroll_trees10_minnode5_seed1"
)

dest_extdata <- file.path(project_root, "inst", "extdata")
dest_train_root <- file.path(dest_extdata, "example_train_workspace")
dest_predict_raw <- file.path(dest_extdata, "example_predict_raw")
dest_model_bundle <- file.path(dest_extdata, "example_model_bundle")

dir_recreate <- function(path) {
  if (dir.exists(path)) unlink(path, recursive = TRUE, force = TRUE)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

parse_obs_time_utc <- function(x) {
  if (inherits(x, "POSIXct")) {
    return(as.POSIXct(x, tz = "UTC"))
  }
  if (is.numeric(x)) {
    return(as.POSIXct(as.numeric(x), origin = "1970-01-01", tz = "UTC"))
  }
  x <- as.character(x)
  out <- suppressWarnings(lubridate::ymd_hms(gsub("T", " ", sub("Z$", "", x)), tz = "UTC", quiet = TRUE))
  if (all(is.na(out))) {
    out <- as.POSIXct(as.numeric(x), origin = "1970-01-01", tz = "UTC")
  }
  out
}

extract_training_windows <- function(obs_dt, tech_dt, buffer_seconds = 300L) {
  obs_dt <- as.data.table(obs_dt)
  tech_dt <- as.data.table(tech_dt)
  obs_dt[, `:=`(
    start_ts = parse_obs_time_utc(start),
    end_ts = parse_obs_time_utc(end),
    id = as.character(id),
    behaviour = as.character(behaviour)
  )]
  tech_dt[, `:=`(
    id = as.character(id),
    accelerometer = as.character(accelerometer)
  )]
  # Use only dates with shared raw coverage across the three accelerometers.
  obs_dt <- obs_dt[start_ts >= as.POSIXct("2026-01-08 00:00:00", tz = "UTC")]
  obs_dt <- tech_dt[obs_dt, on = "id", nomatch = 0L]
  obs_dt[, `:=`(
    win_start = start_ts - buffer_seconds,
    win_end = end_ts + buffer_seconds
  )]
  setorder(obs_dt, accelerometer, win_start, win_end)
  merged <- obs_dt[, {
    starts <- c()
    ends <- c()
    for (i in seq_len(.N)) {
      s <- win_start[i]
      e <- win_end[i]
      if (length(starts) == 0L || s > ends[length(ends)]) {
        starts <- c(starts, s)
        ends <- c(ends, e)
      } else {
        ends[length(ends)] <- max(ends[length(ends)], e)
      }
    }
    data.table(window_start = starts, window_end = ends)
  }, by = accelerometer]

  list(
    obs_filtered = obs_dt,
    windows = merged
  )
}

read_cqu_dt <- function(path) {
  dt <- fread(path, header = FALSE, select = 1:4, col.names = c("datetime", "x", "y", "z"))
  dt[, `:=`(
    datetime = trimws(as.character(datetime)),
    x = trimws(as.character(x)),
    y = trimws(as.character(y)),
    z = trimws(as.character(z))
  )]
  dt
}

write_cqu_dt <- function(dt, path) {
  fwrite(dt[, .(datetime, x, y, z)], path, col.names = FALSE)
}

curate_training_raw <- function(windows_dt, raw_dir, out_dir) {
  dir_recreate(out_dir)
  source_files <- list.files(raw_dir, pattern = "_cquFormat\\.csv$", full.names = TRUE)
  for (acc in sort(unique(windows_dt$accelerometer))) {
    acc_files <- source_files[grepl(paste0("-", acc, "_cquFormat\\.csv$"), basename(source_files))]
    acc_windows <- windows_dt[accelerometer == acc]
    keep_parts <- list()
    for (f in acc_files) {
      dt <- read_cqu_dt(f)
      dt <- dt[is_valid_datetime_string(datetime)]
      if (nrow(dt) == 0L) next
      dt[, datetime_utc := parse_raw_datetime_to_utc(datetime, tz_local_noz = "Australia/Brisbane")]
      dt <- dt[!is.na(datetime_utc)]
      keep_idx <- rep(FALSE, nrow(dt))
      for (i in seq_len(nrow(acc_windows))) {
        keep_idx <- keep_idx | (dt$datetime_utc >= acc_windows$window_start[i] & dt$datetime_utc <= acc_windows$window_end[i])
      }
      dt <- dt[keep_idx, .(datetime, x, y, z, datetime_utc)]
      if (nrow(dt) > 0L) keep_parts[[length(keep_parts) + 1L]] <- dt
    }
    acc_dt <- rbindlist(keep_parts, use.names = TRUE, fill = TRUE)
    if (nrow(acc_dt) == 0L) next
    setorder(acc_dt, datetime_utc)
    out_path <- file.path(out_dir, paste0("example-", acc, "_cquFormat.csv"))
    write_cqu_dt(acc_dt, out_path)
  }
}

build_training_workspace <- function() {
  tech_dt <- fread(source_tech_file)
  obs_dt <- fread(source_obs_file)
  training <- extract_training_windows(obs_dt, tech_dt, buffer_seconds = 300L)

  dir_recreate(dest_train_root)
  dir.create(file.path(dest_train_root, "data_raw"), recursive = TRUE, showWarnings = FALSE)

  curate_training_raw(training$windows, source_raw_dir, file.path(dest_train_root, "data_raw"))

  tech_out <- tech_dt[, .(id = as.character(id), accelerometer = as.character(accelerometer))]
  fwrite(tech_out, file.path(dest_train_root, "tech.csv"))

  obs_pkg <- unique(training$obs_filtered[, .(
    id = as.character(id),
    label = as.character(behaviour),
    start_unix_ms = as.numeric(start_ts) * 1000,
    end_unix_ms = as.numeric(end_ts) * 1000
  )])
  setorder(obs_pkg, id, start_unix_ms, end_unix_ms)
  fwrite(obs_pkg, file.path(dest_train_root, "observations.csv"))
}

build_prediction_raw <- function() {
  dir_recreate(dest_predict_raw)
  selection <- list(
    A01 = c("20260108-16001730-A01_cquFormat.csv", "20260109-09001930-A01_cquFormat.csv"),
    A02 = c("20260108-16001730-A02_cquFormat.csv", "20260109-09001930-A02_cquFormat.csv"),
    A03 = c("20260108-16001730-A03_cquFormat.csv", "20260109-09001930-A03_cquFormat.csv")
  )
  for (acc in names(selection)) {
    parts <- lapply(selection[[acc]], function(name) readLines(file.path(source_raw_dir, name)))
    out_path <- file.path(dest_predict_raw, paste0("example-", acc, "_cquFormat.csv"))
    writeLines(unlist(parts, use.names = FALSE), out_path, sep = "\n")
  }
}

build_model_spec <- function() {
  list(
    package_version = as.character(read.dcf(file.path(project_root, "DESCRIPTION"), fields = "Version")[1]),
    epochs = list(
      lengths = list(10L),
      raw_epoch_seconds = 10L,
      alignment = "absolute"
    ),
    features = list(
      selection = "manual",
      standard_set = "manual5",
      manual_features = c("z_mean", "Incl_mean", "Energy_mean", "z_min", "SVM_sd"),
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
    )
  )
}

build_export_config <- function() {
  list(
    export_id = "example_model_bundle",
    created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    tz_epoch = "UTC",
    model = list(
      mode = "binary",
      positive_class = "grazing",
      seed = 1L,
      num_threads = 1L,
      include_class_weights = FALSE
    ),
    candidate = list(
      candidate_id = "ep10s_manual5_noroll_trees10_node5",
      epoch_seconds = 10L,
      topN_label = "manual5",
      rolling_enabled = FALSE,
      n_base_features = 5L,
      selected_base_features = "z_mean|Incl_mean|Energy_mean|z_min|SVM_sd",
      num_trees = 10L,
      min_node_size = 5L
    ),
    outputs = list(
      rf_model_full_rds = "rf_model_full.rds",
      feature_manifest_csv = "feature_manifest.csv",
      feature_manifest_json = "feature_manifest.json",
      model_spec_json = "model_spec.json",
      metrics_overall_csv = "metrics_overall.csv",
      recall_by_class_csv = "recall_by_class.csv",
      confusion_matrix_csv = "confusion_matrix.csv",
      metrics_by_class_csv = "metrics_by_class.csv",
      metrics_by_cow_csv = "metrics_by_cow.csv",
      class_support_train_csv = "class_support_train.csv",
      dataset_summary_csv = "dataset_summary.csv",
      test_vectors_csv = "test_vectors.csv",
      rf_tree_dump_json = "rf_tree_dump.json"
    )
  )
}

build_example_model_bundle <- function() {
  dir_recreate(dest_model_bundle)
  files_to_copy <- c(
    "rf_model_full.rds",
    "feature_manifest.csv",
    "metrics_overall.csv",
    "recall_by_class.csv",
    "confusion_matrix.csv",
    "metrics_by_class.csv",
    "metrics_by_cow.csv",
    "class_support_train.csv",
    "dataset_summary.csv",
    "test_vectors.csv",
    "rf_tree_dump.json",
    "loco_predictions.rds"
  )
  file.copy(
    from = file.path(source_model_dir, files_to_copy),
    to = dest_model_bundle,
    overwrite = TRUE
  )

  manifest <- fread(file.path(dest_model_bundle, "feature_manifest.csv"))
  write_json(manifest, file.path(dest_model_bundle, "feature_manifest.json"), pretty = TRUE, auto_unbox = TRUE)
  write_json(build_model_spec(), file.path(dest_model_bundle, "model_spec.json"), pretty = TRUE, auto_unbox = TRUE)
  write_json(build_export_config(), file.path(dest_model_bundle, "export_config.json"), pretty = TRUE, auto_unbox = TRUE)

  selected_candidate <- data.table(
    candidate_id = "ep10s_manual5_noroll_trees10_node5",
    epoch_seconds = 10L,
    topN_label = "manual5",
    rolling_enabled = FALSE,
    n_base_features = 5L,
    selected_base_features = "z_mean|Incl_mean|Energy_mean|z_min|SVM_sd",
    num_trees = 10L,
    min_node_size = 5L
  )
  fwrite(selected_candidate, file.path(dest_model_bundle, "selected_candidate.csv"))
}

build_training_workspace()
build_prediction_raw()
build_example_model_bundle()

cat("Built real example assets under:\n")
cat("- ", dest_train_root, "\n", sep = "")
cat("- ", dest_predict_raw, "\n", sep = "")
cat("- ", dest_model_bundle, "\n", sep = "")
