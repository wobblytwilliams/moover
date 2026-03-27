moover_feature_sets <- function() {
  list(
    manual5 = c("z_mean", "Incl_mean", "Energy_mean", "z_min", "SVM_sd")
  )
}

moover_list_raw_files <- function(spec) {
  raw_dir <- moover_normalize_path(spec$ingest$raw_dir, base = spec$workspace$root, must_work = TRUE)
  list.files(
    path = raw_dir,
    pattern = spec$ingest$raw_file_pattern,
    full.names = TRUE,
    recursive = isTRUE(spec$ingest$recursive)
  )
}

moover_load_tech <- function(spec, required = FALSE) {
  tech_path <- spec$labels$tech_file %||% ""
  if (!nzchar(tech_path)) {
    if (required) stop("A tech file is required for this workflow.")
    return(NULL)
  }
  tech_path <- moover_normalize_path(tech_path, base = spec$workspace$root, must_work = required)
  if (!file.exists(tech_path)) {
    if (required) stop("Tech file not found: ", tech_path)
    return(NULL)
  }
  dt <- data.table::fread(tech_path)
  id_col <- spec$schema$tech$id
  acc_col <- spec$schema$tech$accelerometer
  if (!all(c(id_col, acc_col) %in% names(dt))) {
    stop("Tech file must include mapped columns for id and accelerometer.")
  }
  dt <- dt[, .(
    id = as.character(get(id_col)),
    accelerometer = as.character(get(acc_col))
  )]
  unique(dt)
}

moover_prepare_tech_file <- function(spec, run_paths, required = FALSE) {
  tech <- moover_load_tech(spec, required = required)
  if (is.null(tech)) return(NULL)
  data.table::fwrite(tech, run_paths$prepared_tech_file)
  tech
}

moover_prepare_observations_file <- function(spec, run_paths, required = FALSE) {
  obs_path <- spec$labels$path %||% ""
  if (!nzchar(obs_path)) {
    if (required) stop("An observation file is required for this workflow.")
    return(NULL)
  }
  obs_path <- moover_normalize_path(obs_path, base = spec$workspace$root, must_work = required)
  if (!file.exists(obs_path)) {
    if (required) stop("Observation file not found: ", obs_path)
    return(NULL)
  }
  dt <- data.table::fread(obs_path)
  id_col <- spec$schema$observations$id
  label_col <- spec$schema$observations$label
  start_col <- spec$schema$observations$start
  end_col <- spec$schema$observations$end
  if (!all(c(id_col, label_col, start_col, end_col) %in% names(dt))) {
    stop("Observation file must include mapped id, label, start, and end columns.")
  }
  start_ms <- moover_parse_time_to_unix_ms(
    dt[[start_col]],
    time_format = spec$schema$observations$time_format,
    tz_local = spec$ingest$timezone
  )
  end_ms <- moover_parse_time_to_unix_ms(
    dt[[end_col]],
    time_format = spec$schema$observations$time_format,
    tz_local = spec$ingest$timezone
  )
  out <- data.table::data.table(
    id = as.character(dt[[id_col]]),
    start = moover_unix_ms_to_iso_utc(start_ms),
    end = moover_unix_ms_to_iso_utc(end_ms),
    behaviour = as.character(dt[[label_col]])
  )
  if (!is.null(spec$labels$class_filter) && length(spec$labels$class_filter) > 0L) {
    out <- out[behaviour %chin% as.character(spec$labels$class_filter)]
  }
  data.table::fwrite(out, run_paths$prepared_obs_file)
  out
}

moover_lookup_id <- function(source_id, id_type = "id", tech = NULL) {
  source_id <- as.character(source_id)
  if (is.null(tech) || nrow(tech) == 0L) return(source_id)
  if (identical(id_type, "accelerometer")) {
    matched <- tech[match(source_id, accelerometer), id]
    return(ifelse(is.na(matched), source_id, matched))
  }
  source_id
}

moover_lookup_accelerometer <- function(source_id, id_type = "id", tech = NULL) {
  source_id <- as.character(source_id)
  if (is.null(tech) || nrow(tech) == 0L) return(source_id)
  if (identical(id_type, "id")) {
    matched <- tech[match(source_id, id), accelerometer]
    return(ifelse(is.na(matched), source_id, matched))
  }
  source_id
}

moover_canonicalise_cqu_file <- function(path, spec, tech = NULL) {
  dt <- read_raw_cquformat(
    path,
    use_legacy_header_reader = isTRUE(spec$ingest$use_legacy_raw_reader)
  )
  data.table::setDT(dt)
  if (!inherits(dt$datetime, "POSIXct")) {
    dt <- dt[is_valid_datetime_string(datetime)]
    dt[, datetime_utc := parse_raw_datetime_to_utc(datetime, tz_local_noz = spec$ingest$timezone)]
  } else {
    dt[, datetime_utc := lubridate::with_tz(as.POSIXct(datetime), tzone = "UTC")]
  }
  dt[, `:=`(
    x = to_numeric_direct(x),
    y = to_numeric_direct(y),
    z = to_numeric_direct(z)
  )]
  dt <- dt[is.finite(x) & is.finite(y) & is.finite(z) & !is.na(datetime_utc)]
  acc_id <- extract_accelerometer_from_filename(path)
  if (is.na(acc_id) || !nzchar(acc_id)) {
    acc_id <- tools::file_path_sans_ext(basename(path))
  }
  dt[, accelerometer := as.character(acc_id)]
  dt[, id := moover_lookup_id(accelerometer, id_type = "accelerometer", tech = tech)]
  dt[, t_unix_ms := as.numeric(datetime_utc) * 1000]
  dt[, .(id, accelerometer, t_unix_ms, x, y, z)]
}

moover_canonicalise_generic_file <- function(path, spec, tech = NULL) {
  dt <- data.table::fread(
    file = path,
    sep = spec$ingest$delimiter
  )
  raw_schema <- spec$schema$raw
  needed <- c(raw_schema$datetime, raw_schema$x, raw_schema$y, raw_schema$z)
  if (!is.null(raw_schema$id) && nzchar(raw_schema$id)) {
    needed <- c(needed, raw_schema$id)
  }
  if (!all(needed %in% names(dt))) {
    stop("Generic raw file is missing one or more mapped columns: ", basename(path))
  }
  t_unix_ms <- moover_parse_time_to_unix_ms(
    dt[[raw_schema$datetime]],
    time_format = raw_schema$time_format,
    tz_local = spec$ingest$timezone
  )
  source_id <- if (!is.null(raw_schema$id) && nzchar(raw_schema$id)) {
    as.character(dt[[raw_schema$id]])
  } else {
    rep(tools::file_path_sans_ext(basename(path)), nrow(dt))
  }
  out <- data.table::data.table(
    id = moover_lookup_id(source_id, id_type = raw_schema$id_type, tech = tech),
    accelerometer = moover_lookup_accelerometer(source_id, id_type = raw_schema$id_type, tech = tech),
    t_unix_ms = as.numeric(t_unix_ms),
    x = as.numeric(dt[[raw_schema$x]]),
    y = as.numeric(dt[[raw_schema$y]]),
    z = as.numeric(dt[[raw_schema$z]])
  )
  out[is.finite(x) & is.finite(y) & is.finite(z) & is.finite(t_unix_ms)]
}

moover_collect_canonical_accel <- function(spec, tech = NULL) {
  files <- moover_list_raw_files(spec)
  if (length(files) == 0L) {
    stop("No raw accelerometer files found in ", spec$ingest$raw_dir)
  }
  canonical <- data.table::rbindlist(lapply(files, function(path) {
    if (identical(spec$ingest$format, "cqu")) {
      moover_canonicalise_cqu_file(path, spec, tech = tech)
    } else {
      moover_canonicalise_generic_file(path, spec, tech = tech)
    }
  }), use.names = TRUE, fill = TRUE)
  data.table::setorder(canonical, id, t_unix_ms)
  canonical
}

moover_write_generic_as_cqu <- function(canonical_dt, run_paths) {
  moover_ensure_dir(run_paths$canonical_raw_dir)
  data.table::setDT(canonical_dt)
  for (acc in unique(canonical_dt$accelerometer)) {
    sub <- canonical_dt[accelerometer == acc]
    if (nrow(sub) == 0L) next
    out <- data.table::data.table(
      datetime = moover_unix_ms_to_iso_utc(sub$t_unix_ms),
      x = sub$x,
      y = sub$y,
      z = sub$z
    )
    data.table::fwrite(
      out,
      file.path(run_paths$canonical_raw_dir, paste0("prepared-", acc, "_cquFormat.csv"))
    )
  }
  invisible(run_paths$canonical_raw_dir)
}

moover_prepare_inputs <- function(spec, run_paths, require_labels = FALSE) {
  moover_ensure_run_dirs(run_paths)
  moover_write_spec(spec, run_paths$run_spec_file)
  tech <- moover_prepare_tech_file(spec, run_paths, required = require_labels)
  obs <- moover_prepare_observations_file(spec, run_paths, required = require_labels)
  canonical <- moover_collect_canonical_accel(spec, tech = tech)
  if (identical(spec$ingest$format, "generic")) {
    moover_write_generic_as_cqu(canonical, run_paths)
  }
  if (isTRUE(spec$ingest$write_canonical_accel)) {
    data.table::fwrite(canonical[, .(id, t_unix_ms, x, y, z)], run_paths$canonical_accel_file)
  }
  preview <- moover_preview_head(canonical[, .(id, t_unix_ms, x, y, z)], spec$ingest$preview_n)
  data.table::fwrite(preview, run_paths$canonical_preview_file)
  summary <- list(
    n_rows = nrow(canonical),
    n_ids = data.table::uniqueN(canonical$id),
    raw_format = spec$ingest$format,
    preview_file = run_paths$canonical_preview_file,
    canonical_accel_file = if (isTRUE(spec$ingest$write_canonical_accel)) run_paths$canonical_accel_file else NULL
  )
  moover_write_json(summary, run_paths$import_summary_file)
  list(
    tech = tech,
    observations = obs,
    canonical = canonical,
    summary = summary
  )
}

#' Import Raw Accelerometer Data
#'
#' Reads configured raw files, converts them to the canonical `id`, `t_unix_ms`,
#' `x`, `y`, `z` layout, and writes preview and summary artefacts into the run.
#'
#' @param spec A `moover_spec` object or path to a JSON spec.
#'
#' @return A list containing the canonical preview, summary, and output paths.
#' @export
import_accel <- function(spec) {
  spec <- moover_read_spec(spec)
  run_paths <- moover_run_paths(spec)
  prep <- moover_prepare_inputs(spec, run_paths, require_labels = FALSE)
  message("Imported raw accelerometer data for run ", run_paths$run_id)
  list(
    run_id = run_paths$run_id,
    preview_file = run_paths$canonical_preview_file,
    canonical_accel_file = run_paths$canonical_accel_file,
    summary_file = run_paths$import_summary_file,
    preview = moover_preview_head(prep$canonical, spec$ingest$preview_n),
    summary = prep$summary
  )
}
