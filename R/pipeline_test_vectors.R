build_test_vector_table <- function(dt_rows, predictors, include_raw, feature_set, config,
                                    rf_full = NULL, prediction_dt = NULL) {
  if (!is.null(prediction_dt)) {
    pred_dt <- data.table::copy(prediction_dt)
    data.table::setDT(pred_dt)
    pred_dt[, id := as.character(id)]
    pred_dt[, epoch_start := normalise_epoch_time_utc(epoch_start)]
    pred_dt[, epoch_end := normalise_epoch_time_utc(epoch_end)]
    
    rows_dt <- data.table::copy(dt_rows)
    data.table::setDT(rows_dt)
    rows_dt[, id := as.character(id)]
    rows_dt[, epoch_start := normalise_epoch_time_utc(epoch_start)]
    rows_dt[, epoch_end := normalise_epoch_time_utc(epoch_end)]
    
    data.table::setkey(pred_dt, id, epoch_start, epoch_end)
    data.table::setkey(rows_dt, id, epoch_start, epoch_end)
    joined <- pred_dt[rows_dt, nomatch = 0L]
    if (nrow(joined) == 0L) stop("No overlap between supplied predictions and candidate rows.")
    
    truth <- joined$truth
    predicted <- joined$predicted
    prob_cols <- grep("^prob_", names(joined), value = TRUE)
    prob_dt <- joined[, ..prob_cols]
    source_dt <- joined
  } else {
    prob <- predict(rf_full, data = dt_rows[, ..predictors], num.threads = config$model$num_threads)$predictions
    prob_dt <- data.table::as.data.table(prob)
    pred_class <- colnames(prob)[max.col(prob, ties.method = "first")]
    predicted <- factor(pred_class, levels = colnames(prob))
    data.table::setnames(prob_dt, paste0("prob_", colnames(prob_dt)))
    prob_cols <- names(prob_dt)
    truth <- dt_rows$behaviour
    source_dt <- dt_rows
  }
  
  feature_cols <- if (identical(feature_set, "all")) {
    get_all_feature_columns(source_dt)
  } else {
    predictors
  }
  feature_cols <- unique(feature_cols)
  
  tv_out <- data.table::data.table(
    id = source_dt$id,
    epoch_start = source_dt$epoch_start,
    epoch_end = source_dt$epoch_end,
    truth = truth,
    predicted = predicted
  )
  tv_out <- cbind(tv_out, source_dt[, ..feature_cols], prob_dt)
  
  if (isTRUE(include_raw)) {
    raw_cols <- c("raw_ms", "raw_x", "raw_y", "raw_z", "n_raw")
    if (isTRUE(config$test_vectors$include_prev_raw_context)) {
      raw_cols <- c(raw_cols, "prev_raw_ms", "prev_raw_x", "prev_raw_y", "prev_raw_z")
    }
    raw_cols <- raw_cols[raw_cols %in% names(source_dt)]
    tv_out <- cbind(tv_out, source_dt[, ..raw_cols])
    data.table::setcolorder(tv_out, c(
      "id", "epoch_start", "epoch_end", "truth", "predicted",
      feature_cols, prob_cols,
      raw_cols
    ))
  } else {
    data.table::setcolorder(tv_out, c(
      "id", "epoch_start", "epoch_end", "truth", "predicted",
      feature_cols, prob_cols
    ))
  }
  
  tv_out
}

sample_test_vectors <- function(tv_out, sample_n, sample_max, seed) {
  if (nrow(tv_out) == 0L) return(tv_out)
  
  target_n <- min(as.integer(sample_n), as.integer(sample_max))
  target_n <- min(target_n, nrow(tv_out))
  if (target_n <= 0L || target_n >= nrow(tv_out)) return(tv_out)
  
  set.seed(seed)
  tv <- data.table::copy(tv_out)
  tv[, row_id__ := .I]
  tv[, truth_chr := as.character(truth)]
  classes_tv <- unique(tv$truth_chr)
  per_class <- max(1L, floor(target_n / length(classes_tv)))
  
  sampled <- data.table::rbindlist(lapply(classes_tv, function(cl) {
    sub <- tv[truth_chr == cl]
    if (nrow(sub) == 0L) return(NULL)
    take <- min(nrow(sub), per_class)
    sub[sample.int(nrow(sub), take)]
  }), use.names = TRUE, fill = TRUE)
  
  if (nrow(sampled) < target_n) {
    remaining <- target_n - nrow(sampled)
    pool <- tv[!row_id__ %in% sampled$row_id__]
    if (nrow(pool) > 0L) {
      extra <- pool[sample.int(nrow(pool), min(remaining, nrow(pool)))]
      sampled <- data.table::rbindlist(list(sampled, extra), use.names = TRUE, fill = TRUE)
    }
  }
  
  sampled[, c("truth_chr", "row_id__") := NULL]
  sampled
}

build_test_vectors_from_selected_model <- function(config) {
  candidate <- resolve_selected_candidate(config)
  export_dir <- export_dir_from_candidate(candidate, config)
  model_path <- file.path(export_dir, "rf_model_full.rds")
  manifest_path <- file.path(export_dir, "feature_manifest.csv")
  
  if (!file.exists(model_path)) stop("Exported full model not found: ", model_path)
  if (!file.exists(manifest_path)) stop("Feature manifest not found: ", manifest_path)
  
  rf_full <- readRDS(model_path)
  manifest <- data.table::fread(manifest_path)
  predictors <- as.character(manifest$feature)
  
  dt <- load_canonical_dataset(config)
  dt_epoch <- dt[epoch_seconds == as.integer(candidate$epoch_seconds)]
  prepared <- prepare_candidate_rows(dt_epoch, candidate, config, keep_all_cols = TRUE)
  
  prediction_source <- if (!is.null(config$test_vectors$prediction_source)) {
    tolower(as.character(config$test_vectors$prediction_source))
  } else {
    "full_model"
  }
  prediction_dt <- NULL
  if (identical(prediction_source, "loco")) {
    loco_rds <- file.path(export_dir, "loco_predictions.rds")
    loco_csv <- file.path(export_dir, "loco_predictions.csv")
    if (file.exists(loco_rds)) {
      prediction_dt <- readRDS(loco_rds)
    } else if (file.exists(loco_csv)) {
      prediction_dt <- data.table::fread(loco_csv)
    } else {
      stop("prediction_source='loco' but no loco_predictions.rds/csv found in export dir: ", export_dir)
    }
  } else if (!identical(prediction_source, "full_model")) {
    stop("Unknown test_vectors prediction_source: ", prediction_source)
  }
  
  tv_all <- build_test_vector_table(
    dt_rows = prepared$data,
    predictors = predictors,
    include_raw = isTRUE(config$test_vectors$include_raw_in_test_vectors),
    feature_set = config$test_vectors$test_vector_feature_set,
    config = config,
    rf_full = if (identical(prediction_source, "full_model")) rf_full else NULL,
    prediction_dt = prediction_dt
  )
  
  tv_sample <- sample_test_vectors(
    tv_out = tv_all,
    sample_n = config$test_vectors$test_vectors_sample_n,
    sample_max = config$test_vectors$test_vectors_sample_max,
    seed = config$test_vectors$set_seed_test_vectors
  )
  
  data.table::fwrite(tv_sample, file.path(export_dir, "test_vectors.csv"))
  if (isTRUE(config$test_vectors$write_test_vectors_all)) {
    data.table::fwrite(tv_all, file.path(export_dir, "test_vectors_all.csv"))
  }
  
  moover_console_bullet(paste0("Sampled test vectors saved to: ", normalizePath(file.path(export_dir, "test_vectors.csv"))))
  if (isTRUE(config$test_vectors$write_test_vectors_all)) {
    moover_console_bullet(paste0("Full test vectors saved to: ", normalizePath(file.path(export_dir, "test_vectors_all.csv"))))
  }
  cat("\n")
  
  invisible(export_dir)
}
