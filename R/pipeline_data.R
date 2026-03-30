ensure_dir <- function(path) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  invisible(path)
}

canonical_dataset_path <- function(config) {
  file.path(config$paths$out_model_dir, "labelled_epochs_all_features.rds")
}

extract_accelerometer_from_filename <- function(path) {
  bn <- basename(path)
  m <- regexec("-([A-Za-z][0-9]{2})_cqu", bn)
  reg <- regmatches(bn, m)[[1]]
  if (length(reg) < 2L) return(NA_character_)
  reg[2]
}

read_raw_cquformat <- function(path, use_legacy_header_reader = FALSE) {
  if (isTRUE(use_legacy_header_reader)) {
    dt <- data.table::fread(path, header = TRUE, fill = TRUE)
    data.table::setnames(dt, trimws(names(dt)))
    
    cand_dt <- intersect(names(dt), c("datetime", "Datetime", "timestamp", "Timestamp", "time", "Time"))
    cand_x <- intersect(names(dt), c("x", "X"))
    cand_y <- intersect(names(dt), c("y", "Y"))
    cand_z <- intersect(names(dt), c("z", "Z"))
    
    if (length(cand_dt) >= 1L && length(cand_x) >= 1L && length(cand_y) >= 1L && length(cand_z) >= 1L) {
      return(dt[, .(
        datetime = get(cand_dt[1]),
        x = get(cand_x[1]),
        y = get(cand_y[1]),
        z = get(cand_z[1])
      )])
    }
    
    if (ncol(dt) < 4L) {
      stop("Raw file has <4 columns after legacy fread(header=TRUE): ", basename(path))
    }
    
    first4 <- names(dt)[1:4]
    dt <- dt[, ..first4]
    data.table::setnames(dt, c("datetime", "x", "y", "z"))
    return(dt)
  }
  
  dt <- data.table::fread(
    path,
    header = FALSE,
    fill = TRUE,
    select = 1:4,
    colClasses = "character"
  )
  if (ncol(dt) < 4L) {
    stop("Raw file has <4 columns after fread(fill=TRUE): ", basename(path))
  }
  
  data.table::setnames(dt, c("datetime", "x", "y", "z"))
  dt[, `:=`(
    datetime = trimws(as.character(datetime)),
    x = trimws(as.character(x)),
    y = trimws(as.character(y)),
    z = trimws(as.character(z))
  )]
  
  header_like <- nrow(dt) >= 1L &&
    tolower(dt$datetime[1]) %in% c("datetime", "timestamp", "time") &&
    tolower(dt$x[1]) == "x" &&
    tolower(dt$y[1]) == "y" &&
    tolower(dt$z[1]) == "z"
  if (header_like) {
    dt <- dt[-1L]
  }
  
  dt
}

is_valid_datetime_string <- function(x) {
  grepl("^\\d{4}-\\d{2}-\\d{2}[ T]\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z)?$", x)
}

to_numeric_direct <- function(x) {
  suppressWarnings(as.numeric(trimws(as.character(x))))
}

parse_raw_datetime_to_utc <- function(x, tz_local_noz) {
  x <- trimws(as.character(x))
  out <- as.POSIXct(rep(NA_real_, length(x)), origin = "1970-01-01", tz = "UTC")
  valid <- is_valid_datetime_string(x)
  if (!any(valid)) return(out)
  
  x_valid <- x[valid]
  has_z <- grepl("Z$", x_valid)
  
  if (any(has_z)) {
    tmp_utc <- lubridate::ymd_hms(
      gsub("T", " ", sub("Z$", "", x_valid[has_z])),
      tz = "UTC",
      quiet = TRUE
    )
    out[which(valid)[has_z]] <- tmp_utc
  }
  if (any(!has_z)) {
    tmp_local <- lubridate::ymd_hms(
      gsub("T", " ", x_valid[!has_z]),
      tz = tz_local_noz,
      quiet = TRUE
    )
    out[which(valid)[!has_z]] <- lubridate::with_tz(tmp_local, tzone = "UTC")
  }
  
  out
}

safe_min_na <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) return(NA_real_)
  min(x)
}

safe_max_na <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) return(NA_real_)
  max(x)
}

downsample_every_n <- function(dt, n_keep) {
  stopifnot("datetime_utc" %in% names(dt))
  data.table::setDT(dt)
  if (nrow(dt) == 0L) return(dt)
  data.table::setorder(dt, datetime_utc)
  dt[seq(1L, .N, by = n_keep)]
}

add_epoch_ids_utc <- function(dt, epoch_seconds = 10L) {
  stopifnot("datetime_utc" %in% names(dt))
  data.table::setDT(dt)
  
  dt[, `:=`(
    epoch_start_10s = NA_character_,
    epoch_end_10s = NA_character_,
    epoch_id_10s = NA_character_,
    ms_to_origin_utc = NA_character_
  )]
  
  if (nrow(dt) == 0L) return(dt)
  
  bucket <- floor(as.numeric(dt$datetime_utc) / epoch_seconds)
  epoch_start_utc <- as.POSIXct(bucket * epoch_seconds, origin = "1970-01-01", tz = "UTC")
  epoch_end_utc <- epoch_start_utc + epoch_seconds
  
  # Add a tiny epsilon before rounding to stabilize millisecond formatting
  # across equivalent timezone parse paths.
  dt[, ms_to_origin_utc := sprintf("%.0f", (as.numeric(datetime_utc) * 1000) + 1e-04)]
  dt[, epoch_start_10s := format(epoch_start_utc, "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")]
  dt[, epoch_end_10s := format(epoch_end_utc, "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")]
  dt[, epoch_id_10s := paste0(epoch_start_10s, "_", epoch_seconds, "s")]
  dt
}

fmt_num_chr <- function(x) {
  formatC(x, format = "fg", digits = 10, flag = "#")
}

add_sample_features <- function(dt) {
  data.table::setDT(dt)
  data.table::setorder(dt, datetime_utc)
  
  dt[, `:=`(
    SMA_samp = abs(x) + abs(y) + abs(z),
    SVM_samp = sqrt(x^2 + y^2 + z^2),
    MV_samp = abs(data.table::shift(x, 1L, type = "lag") - x) +
      abs(data.table::shift(y, 1L, type = "lag") - y) +
      abs(data.table::shift(z, 1L, type = "lag") - z),
    Energy_samp = (x^2 + y^2 + z^2)^2,
    Entropy_samp = (1 + (x + y + z))^2 * log(1 + (x + y + z)^2),
    Pitch_deg = atan2(-x, sqrt(y^2 + z^2)) * 180 / pi,
    Roll_deg = atan2(y, z) * 180 / pi,
    Incl_deg = atan2(sqrt(x^2 + y^2), z) * 180 / pi
  )]
  
  dt
}

compute_epoch_features_utc <- function(dt, epoch_secs) {
  data.table::setDT(dt)
  if (nrow(dt) == 0L) {
    return(data.table::data.table(
      epoch_start = as.POSIXct(character(0), tz = "UTC"),
      epoch_end = as.POSIXct(character(0), tz = "UTC")
    ))
  }
  
  dt[, epoch_bucket := floor(as.numeric(datetime_utc) / epoch_secs)]
  dt[, epoch_start := as.POSIXct(epoch_bucket * epoch_secs, origin = "1970-01-01", tz = "UTC")]
  dt[, epoch_end := epoch_start + epoch_secs]
  
  out <- dt[, {
    x_static <- mean(x)
    y_static <- mean(y)
    z_static <- mean(z)
    
    x_dyn <- x - x_static
    y_dyn <- y - y_static
    z_dyn <- z - z_static
    odba_samp <- abs(x_dyn) + abs(y_dyn) + abs(z_dyn)
    
    .(
      n_samples = .N,
      x_mean = x_static, x_sd = sd(x), x_min = min(x), x_max = max(x), x_range = max(x) - min(x),
      y_mean = y_static, y_sd = sd(y), y_min = min(y), y_max = max(y), y_range = max(y) - min(y),
      z_mean = z_static, z_sd = sd(z), z_min = min(z), z_max = max(z), z_range = max(z) - min(z),
      ODBA_mean = mean(odba_samp), ODBA_sd = sd(odba_samp), ODBA_min = min(odba_samp), ODBA_max = max(odba_samp),
      SMA_mean = mean(SMA_samp), SMA_sd = sd(SMA_samp), SMA_min = min(SMA_samp), SMA_max = max(SMA_samp),
      SVM_mean = mean(SVM_samp), SVM_sd = sd(SVM_samp), SVM_min = min(SVM_samp), SVM_max = max(SVM_samp),
      MV_mean = mean(MV_samp, na.rm = TRUE), MV_sd = sd(MV_samp, na.rm = TRUE),
      MV_min = safe_min_na(MV_samp), MV_max = safe_max_na(MV_samp),
      Energy_mean = mean(Energy_samp), Energy_sd = sd(Energy_samp), Energy_min = min(Energy_samp), Energy_max = max(Energy_samp),
      Entropy_mean = mean(Entropy_samp), Entropy_sd = sd(Entropy_samp), Entropy_min = min(Entropy_samp), Entropy_max = max(Entropy_samp),
      Pitch_mean = mean(Pitch_deg), Pitch_sd = sd(Pitch_deg),
      Roll_mean = mean(Roll_deg), Roll_sd = sd(Roll_deg),
      Incl_mean = mean(Incl_deg), Incl_sd = sd(Incl_deg)
    )
  }, by = .(epoch_bucket, epoch_start, epoch_end)]
  
  out[, epoch_seconds := as.integer(epoch_secs)]
  out[, epoch_bucket := NULL]
  out
}

build_epoch_raw_nesting <- function(dt, epoch_secs, raw_nest_delim, raw_max_samples_per_epoch = NULL) {
  data.table::setDT(dt)
  if (nrow(dt) == 0L) {
    return(data.table::data.table(
      epoch_start = as.POSIXct(character(0), tz = "UTC"),
      epoch_end = as.POSIXct(character(0), tz = "UTC"),
      raw_ms = character(0),
      raw_x = character(0),
      raw_y = character(0),
      raw_z = character(0),
      n_raw = integer(0)
    ))
  }
  
  dt <- data.table::copy(dt)
  dt[, epoch_bucket := floor(as.numeric(datetime_utc) / epoch_secs)]
  dt[, epoch_start := as.POSIXct(epoch_bucket * epoch_secs, origin = "1970-01-01", tz = "UTC")]
  dt[, epoch_end := epoch_start + epoch_secs]
  dt[, ms_num := suppressWarnings(as.numeric(ms_to_origin_utc))]
  data.table::setorder(dt, epoch_start, ms_num)
  dt[, `:=`(
    prev_raw_ms = data.table::shift(ms_to_origin_utc, 1L, type = "lag"),
    prev_raw_x = data.table::shift(x, 1L, type = "lag"),
    prev_raw_y = data.table::shift(y, 1L, type = "lag"),
    prev_raw_z = data.table::shift(z, 1L, type = "lag")
  )]
  dt[, ms_num := NULL]
  
  if (!is.null(raw_max_samples_per_epoch) && is.numeric(raw_max_samples_per_epoch) && raw_max_samples_per_epoch > 0) {
    dt[, rn := seq_len(.N), by = .(epoch_start)]
    dt <- dt[rn <= raw_max_samples_per_epoch]
    dt[, rn := NULL]
  }
  
  out <- dt[, .(
    prev_raw_ms = {
      val <- prev_raw_ms[1L]
      ifelse(is.na(val), "", val)
    },
    prev_raw_x = {
      val <- prev_raw_x[1L]
      ifelse(is.na(val), "", fmt_num_chr(val))
    },
    prev_raw_y = {
      val <- prev_raw_y[1L]
      ifelse(is.na(val), "", fmt_num_chr(val))
    },
    prev_raw_z = {
      val <- prev_raw_z[1L]
      ifelse(is.na(val), "", fmt_num_chr(val))
    },
    raw_ms = paste(ms_to_origin_utc, collapse = raw_nest_delim),
    raw_x = paste(fmt_num_chr(x), collapse = raw_nest_delim),
    raw_y = paste(fmt_num_chr(y), collapse = raw_nest_delim),
    raw_z = paste(fmt_num_chr(z), collapse = raw_nest_delim),
    n_raw = as.integer(.N)
  ), by = .(epoch_start, epoch_end)]
  
  out
}

label_epochs_majority <- function(epoch_dt, obs_dt_cow, epoch_secs, majority_thresh = 0.5) {
  if (nrow(obs_dt_cow) == 0L) {
    epoch_dt[, behaviour := NA_character_]
    return(epoch_dt)
  }
  
  ed <- data.table::copy(epoch_dt)
  od <- data.table::copy(obs_dt_cow)
  
  ed[, `:=`(start = epoch_start, end = epoch_end)]
  od[, `:=`(start = start, end = end)]
  
  ed <- ed[!is.na(start) & !is.na(end)]
  od <- od[!is.na(start) & !is.na(end)]
  
  if (nrow(ed) == 0L || nrow(od) == 0L) {
    epoch_dt[, behaviour := NA_character_]
    return(epoch_dt)
  }
  
  data.table::setkey(od, start, end)
  data.table::setkey(ed, start, end)
  hits <- data.table::foverlaps(ed, od, type = "any", nomatch = 0L)
  
  if (nrow(hits) == 0L) {
    epoch_dt[, behaviour := NA_character_]
    return(epoch_dt)
  }
  
  hits[, overlap_secs := as.numeric(pmin(end, i.end) - pmax(start, i.start), units = "secs")]
  hits <- hits[overlap_secs > 0]
  if (nrow(hits) == 0L) {
    epoch_dt[, behaviour := NA_character_]
    return(epoch_dt)
  }
  
  best <- hits[, .(overlap_secs = sum(overlap_secs)), by = .(epoch_start = i.start, epoch_end = i.end, behaviour)]
  data.table::setorder(best, epoch_start, -overlap_secs)
  best_max <- best[, .SD[1], by = .(epoch_start, epoch_end)]
  best_max[, overlap_prop := overlap_secs / epoch_secs]
  best_max[overlap_prop <= majority_thresh, behaviour := NA_character_]
  
  epoch_dt[best_max, on = .(epoch_start, epoch_end), behaviour := i.behaviour]
  epoch_dt
}

apply_label_hygiene <- function(DT,
                                enable_min_bout_duration,
                                min_bout_seconds,
                                enable_edge_trimming,
                                edge_trim_seconds) {
  DT <- data.table::copy(DT)
  data.table::setorder(DT, id, epoch_start)
  
  DT[, bout_id := {
    b <- as.character(behaviour)
    cumsum(c(TRUE, b[-1] != b[-.N]))
  }, by = id]
  
  bouts <- DT[, .(
    behaviour = behaviour[1],
    bout_start = min(epoch_start),
    bout_end = max(epoch_end),
    n_epochs = .N
  ), by = .(id, bout_id)]
  bouts[, bout_dur_secs := as.numeric(difftime(bout_end, bout_start, units = "secs"))]
  
  if (isTRUE(enable_min_bout_duration) && is.numeric(min_bout_seconds) && min_bout_seconds > 0) {
    keep_bouts <- bouts[bout_dur_secs >= min_bout_seconds, .(id, bout_id)]
    DT <- DT[keep_bouts, on = .(id, bout_id), nomatch = 0L]
  }
  
  data.table::setorder(DT, id, epoch_start)
  DT[, bout_id := {
    b <- as.character(behaviour)
    cumsum(c(TRUE, b[-1] != b[-.N]))
  }, by = id]
  
  bouts2 <- DT[, .(
    bout_start = min(epoch_start),
    bout_end = max(epoch_end)
  ), by = .(id, bout_id)]
  
  if (isTRUE(enable_edge_trimming) && is.numeric(edge_trim_seconds) && edge_trim_seconds > 0) {
    DT[bouts2, `:=`(
      bout_start = i.bout_start,
      bout_end = i.bout_end
    ), on = .(id, bout_id)]
    
    DT[, `:=`(
      sec_from_bout_start = as.numeric(difftime(epoch_start, bout_start, units = "secs")),
      sec_to_bout_end = as.numeric(difftime(bout_end, epoch_end, units = "secs"))
    )]
    
    DT <- DT[sec_from_bout_start >= edge_trim_seconds & sec_to_bout_end >= edge_trim_seconds]
    DT[, c("sec_from_bout_start", "sec_to_bout_end", "bout_start", "bout_end") := NULL]
  }
  
  DT[, bout_id := NULL]
  DT
}

safe_iqr <- function(x) {
  stats::IQR(x, na.rm = TRUE, type = 7)
}

safe_cv <- function(x) {
  m <- mean(x, na.rm = TRUE)
  s <- stats::sd(x, na.rm = TRUE)
  if (is.na(m) || m == 0) return(NA_real_)
  s / m
}

add_trailing_roll_features <- function(DT, time_col, by_col, feature_cols,
                                       pred_epoch, roll_windows_seconds, roll_fns) {
  DT <- data.table::copy(DT)
  data.table::setorderv(DT, cols = c(by_col, time_col))
  
  for (w in roll_windows_seconds) {
    k <- as.integer(round(w / pred_epoch))
    if (k < 2L) next
    
    for (v in feature_cols) {
      if ("mean" %in% roll_fns) {
        DT[, (paste0("roll", w, "_mean_", v)) := data.table::frollmean(get(v), n = k, align = "right"), by = by_col]
      }
      if ("sd" %in% roll_fns) {
        DT[, (paste0("roll", w, "_sd_", v)) := data.table::frollapply(get(v), n = k, align = "right", FUN = stats::sd, na.rm = TRUE), by = by_col]
      }
      if ("iqr" %in% roll_fns) {
        DT[, (paste0("roll", w, "_iqr_", v)) := data.table::frollapply(get(v), n = k, align = "right", FUN = safe_iqr), by = by_col]
      }
      if ("cv" %in% roll_fns) {
        DT[, (paste0("roll", w, "_cv_", v)) := data.table::frollapply(get(v), n = k, align = "right", FUN = safe_cv), by = by_col]
      }
    }
  }
  
  DT
}

apply_na_policy <- function(DT, predictors, na_drop_mode,
                            enable_rolling_features, roll_windows_seconds) {
  DT <- data.table::copy(DT)
  
  if (na_drop_mode == "warmup") {
    if (isTRUE(enable_rolling_features) && length(roll_windows_seconds) > 0L) {
      max_w <- max(roll_windows_seconds)
      warmup_cols <- grep(paste0("^roll", max_w, "_"), names(DT), value = TRUE)
      if (length(warmup_cols) > 0L) {
        DT <- DT[stats::complete.cases(DT[, ..warmup_cols])]
      }
    }
  } else if (na_drop_mode == "all_predictors") {
    na_any <- DT[, Reduce(`|`, lapply(.SD, is.na)), .SDcols = predictors]
    if (any(na_any)) DT <- DT[!na_any]
  } else if (na_drop_mode == "none") {
    NULL
  } else {
    stop("Unknown na_drop_mode: ", na_drop_mode)
  }
  
  na_any2 <- DT[, Reduce(`|`, lapply(.SD, is.na)), .SDcols = predictors]
  if (any(na_any2)) DT <- DT[!na_any2]
  DT
}

normalise_epoch_time_utc <- function(x) {
  if (inherits(x, "POSIXct")) {
    return(lubridate::with_tz(as.POSIXct(x), tzone = "UTC"))
  }
  x <- as.character(x)
  x <- gsub("T", " ", x, fixed = TRUE)
  x <- sub("Z$", "", x)
  suppressWarnings(lubridate::parse_date_time(x, orders = c("Ymd HMS", "Ymd HMSOS"), tz = "UTC"))
}

get_base_feature_names <- function(DT) {
  exclude <- c(
    "id", "epoch_start", "epoch_end", "epoch_seconds", "behaviour",
    "raw_ms", "raw_x", "raw_y", "raw_z", "n_raw",
    "prev_raw_ms", "prev_raw_x", "prev_raw_y", "prev_raw_z"
  )
  cols <- setdiff(names(DT), exclude)
  cols <- cols[!startsWith(cols, "roll")]
  cols[vapply(DT[, ..cols], is.numeric, logical(1))]
}

get_all_feature_columns <- function(DT) {
  exclude <- c(
    "id", "epoch_start", "epoch_end", "epoch_seconds", "behaviour",
    "raw_ms", "raw_x", "raw_y", "raw_z", "n_raw",
    "prev_raw_ms", "prev_raw_x", "prev_raw_y", "prev_raw_z",
    "truth", "predicted"
  )
  cols <- setdiff(names(DT), exclude)
  prob_cols <- grep("^prob_", cols, value = TRUE)
  setdiff(cols, prob_cols)
}

load_canonical_dataset <- function(config) {
  path <- canonical_dataset_path(config)
  if (!file.exists(path)) stop("Canonical dataset not found: ", path)
  dt <- readRDS(path)
  data.table::setDT(dt)
  dt[, epoch_start := normalise_epoch_time_utc(epoch_start)]
  dt[, epoch_end := normalise_epoch_time_utc(epoch_end)]
  dt
}

build_canonical_dataset <- function(config) {
  ensure_dir(config$paths$out_model_dir)
  ensure_dir(config$paths$out_raw_ds_dir)
  
  if (!file.exists(config$paths$tech_file)) stop("Missing tech_file: ", config$paths$tech_file)
  if (!file.exists(config$paths$obs_file)) stop("Missing obs_file: ", config$paths$obs_file)
  
  tech <- data.table::fread(config$paths$tech_file)
  obs <- data.table::fread(config$paths$obs_file)
  data.table::setnames(tech, trimws(names(tech)))
  data.table::setnames(obs, trimws(names(obs)))
  
  if (!all(c("id", "accelerometer") %in% names(tech))) stop("tech.csv must include columns: id, accelerometer")
  if (!all(c("id", "start", "end", "behaviour") %in% names(obs))) stop("observations.csv must include columns: id, start, end, behaviour")
  
  tech[, id := as.character(id)]
  tech[, accelerometer := as.character(accelerometer)]
  obs[, id := as.character(id)]
  obs[, behaviour := as.character(behaviour)]
  if (inherits(obs$start, "POSIXct")) {
    obs[, start := lubridate::with_tz(as.POSIXct(start), tzone = "UTC")]
  } else {
    obs[, start := lubridate::ymd_hms(gsub("T", " ", sub("Z$", "", as.character(start))), tz = "UTC", quiet = TRUE)]
  }
  if (inherits(obs$end, "POSIXct")) {
    obs[, end := lubridate::with_tz(as.POSIXct(end), tzone = "UTC")]
  } else {
    obs[, end := lubridate::ymd_hms(gsub("T", " ", sub("Z$", "", as.character(end))), tz = "UTC", quiet = TRUE)]
  }
  
  bad_obs <- obs[is.na(start) | is.na(end)]
  if (nrow(bad_obs) > 0L) stop("Unparseable observation timestamps detected in observations.csv")
  
  obs_cows <- unique(obs$id)
  tech <- tech[id %in% obs_cows]
  data.table::setkey(obs, id, start, end)
  
  raw_files <- unlist(lapply(config$paths$raw_dirs, function(d) {
    if (!dir.exists(d)) return(character())
    list.files(d, pattern = config$paths$raw_file_pattern, full.names = TRUE)
  }))
  if (length(raw_files) == 0L) stop("No raw files found under configured raw_dirs.")
  
  moover_console_bullet(paste0("Raw files available: ", length(raw_files)))
  out_rows <- list()
  
  for (f in raw_files) {
    acc_id <- extract_accelerometer_from_filename(f)
    if (is.na(acc_id)) next
    
    tech_rows <- tech[accelerometer == acc_id]
    if (nrow(tech_rows) == 0L) next
    
    dt_raw <- read_raw_cquformat(
      f,
      use_legacy_header_reader = isTRUE(config$data$use_legacy_raw_reader)
    )
    data.table::setDT(dt_raw)
    
    if (!inherits(dt_raw$datetime, "POSIXct")) {
      dt_raw[, datetime := trimws(as.character(datetime))]
      dt_raw <- dt_raw[is_valid_datetime_string(datetime)]
      if (nrow(dt_raw) == 0L) next
      
      dt_raw[, datetime_utc := parse_raw_datetime_to_utc(datetime, tz_local_noz = config$data$tz_local_raw_noz)]
    } else {
      dt_raw[, datetime_utc := lubridate::with_tz(as.POSIXct(datetime), tzone = "UTC")]
    }
    dt_raw[, `:=`(
      x = to_numeric_direct(x),
      y = to_numeric_direct(y),
      z = to_numeric_direct(z)
    )]
    dt_raw <- dt_raw[is.finite(x) & is.finite(y) & is.finite(z) & !is.na(datetime_utc)]
    if (nrow(dt_raw) < 2L) next
    
    dt_ds <- downsample_every_n(dt_raw, config$data$downsample_keep_every_n)
    if (nrow(dt_ds) < 2L) next
    
    dt_ds <- add_epoch_ids_utc(dt_ds, epoch_seconds = config$data$epoch_seconds_for_raw_id)
    dt_ds <- add_sample_features(dt_ds)
    
    if (isTRUE(config$data$write_downsampled_raw)) {
      out_raw_name <- sub("\\.csv$", "", basename(f))
      out_raw_path <- file.path(config$paths$out_raw_ds_dir, paste0(out_raw_name, "_ds12p5_every2.csv"))
      data.table::fwrite(dt_ds[, .(datetime_utc, ms_to_origin_utc, x, y, z, epoch_start_10s, epoch_end_10s, epoch_id_10s)], out_raw_path)
    }
    
    for (epoch_secs in config$data$epoch_lengths) {
      feat_dt <- compute_epoch_features_utc(data.table::copy(dt_ds), epoch_secs)
      raw_nested_dt <- build_epoch_raw_nesting(
        data.table::copy(dt_ds),
        epoch_secs = epoch_secs,
        raw_nest_delim = config$data$raw_nest_delim,
        raw_max_samples_per_epoch = config$data$raw_max_samples_per_epoch
      )
      data.table::setkey(feat_dt, epoch_start, epoch_end)
      data.table::setkey(raw_nested_dt, epoch_start, epoch_end)
      
      for (i in seq_len(nrow(tech_rows))) {
        cow_id <- tech_rows$id[i]
        obs_cow <- obs[J(cow_id)]
        if (nrow(obs_cow) == 0L) next
        
        ep <- data.table::copy(feat_dt)
        ep[, id := as.character(cow_id)]
        ep <- label_epochs_majority(
          epoch_dt = ep,
          obs_dt_cow = obs_cow[, .(start, end, behaviour)],
          epoch_secs = epoch_secs,
          majority_thresh = config$data$majority_thresh
        )
        ep <- ep[!is.na(behaviour) & behaviour != ""]
        if (nrow(ep) == 0L) next
        
        joined <- raw_nested_dt[ep, on = .(epoch_start, epoch_end)]
        joined[is.na(raw_ms), raw_ms := ""]
        joined[is.na(raw_x), raw_x := ""]
        joined[is.na(raw_y), raw_y := ""]
        joined[is.na(raw_z), raw_z := ""]
        joined[is.na(n_raw), n_raw := 0L]
        joined[is.na(prev_raw_ms), prev_raw_ms := ""]
        joined[is.na(prev_raw_x), prev_raw_x := ""]
        joined[is.na(prev_raw_y), prev_raw_y := ""]
        joined[is.na(prev_raw_z), prev_raw_z := ""]
        
        keep_cols <- c(
          "id", "epoch_start", "epoch_end", "epoch_seconds", "behaviour",
          get_base_feature_names(ep),
          "raw_ms", "raw_x", "raw_y", "raw_z", "n_raw",
          "prev_raw_ms", "prev_raw_x", "prev_raw_y", "prev_raw_z"
        )
        out_rows[[length(out_rows) + 1L]] <- joined[, ..keep_cols]
      }
    }
    
    rm(dt_raw, dt_ds)
    gc()
  }
  
  dt <- data.table::rbindlist(out_rows, use.names = TRUE, fill = TRUE)
  if (nrow(dt) == 0L) stop("No labelled epochs produced.")
  
  if (identical(config$model$mode, "binary")) {
    dt[, behaviour := ifelse(behaviour == config$model$positive_class, config$model$positive_class, "not_grazing")]
  }
  
  if (isTRUE(config$data$sparse_epoch_drop$drop_sparse_epochs)) {
    med_n <- median(dt$n_samples, na.rm = TRUE)
    thr <- config$data$sparse_epoch_drop$sparse_frac_of_median * med_n
    dt <- dt[n_samples >= thr]
  }
  
  hygiene_dt <- dt[, .(
    id, epoch_start, epoch_end, behaviour,
    tmp_row_id = .I
  )]
  hygiene_dt <- apply_label_hygiene(
    DT = hygiene_dt,
    enable_min_bout_duration = config$data$label_hygiene$enable_min_bout_duration,
    min_bout_seconds = config$data$label_hygiene$min_bout_seconds,
    enable_edge_trimming = config$data$label_hygiene$enable_edge_trimming,
    edge_trim_seconds = config$data$label_hygiene$edge_trim_seconds
  )
  dt <- dt[hygiene_dt$tmp_row_id]
  
  data.table::setorder(dt, epoch_seconds, id, epoch_start)
  
  if (isTRUE(config$optimise$enable_rolling_search)) {
    moover_console_bullet("Adding rolling features to the epoch dataset.")
    epoch_tables <- vector("list", length(unique(dt$epoch_seconds)))
    epoch_values <- sort(unique(dt$epoch_seconds))
    for (i in seq_along(epoch_values)) {
      ep <- epoch_values[i]
      sub_dt <- data.table::copy(dt[epoch_seconds == ep])
      base_cols <- get_base_feature_names(sub_dt)
      base_cols <- base_cols[vapply(sub_dt[, ..base_cols], is.numeric, logical(1))]
      sub_dt <- add_trailing_roll_features(
        DT = sub_dt,
        time_col = "epoch_start",
        by_col = "id",
        feature_cols = base_cols,
        pred_epoch = ep,
        roll_windows_seconds = config$optimise$roll_windows_seconds,
        roll_fns = config$optimise$roll_fns
      )
      epoch_tables[[i]] <- sub_dt
    }
    dt <- data.table::rbindlist(epoch_tables, use.names = TRUE, fill = TRUE)
    data.table::setorder(dt, epoch_seconds, id, epoch_start)
  }
  
  ensure_dir(dirname(canonical_dataset_path(config)))
  saveRDS(dt, canonical_dataset_path(config))
  moover_console_bullet(paste0("Canonical dataset saved to: ", normalizePath(canonical_dataset_path(config))))
  moover_console_bullet(paste0("Dataset size: ", nrow(dt), " rows x ", ncol(dt), " columns"))
  cat("\n")
  
  invisible(canonical_dataset_path(config))
}
