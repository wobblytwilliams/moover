make_roll_tag <- function(config) {
  if (!isTRUE(config$optimise$enable_rolling_search)) return("noroll")
  paste0(
    "roll",
    paste(config$optimise$roll_windows_seconds, collapse = "_"),
    "_",
    paste(config$optimise$roll_fns, collapse = "_")
  )
}

make_optimisation_run_id <- function(config) {
  sprintf(
    "canonical_opt_epoch%s_%s_%s_seed%s",
    paste(config$optimise$epochs_to_run, collapse = "-"),
    config$model$mode,
    make_roll_tag(config),
    config$model$seed
  )
}

optimisation_output_dir <- function(config) {
  file.path(config$paths$optimization_base_dir, make_optimisation_run_id(config))
}

class_levels_from_config <- function(config, y) {
  if (identical(config$model$mode, "binary")) {
    return(c(config$model$positive_class, "not_grazing"))
  }
  sort(unique(as.character(y)))
}

make_class_weights <- function(y_factor) {
  tab <- table(y_factor)
  w <- as.numeric(sum(tab) / (length(tab) * tab))
  names(w) <- names(tab)
  w
}

rf_fit <- function(train_dt, predictors, num_trees, min_node_size, seed, num_threads,
                   include_class_weights, importance_mode) {
  cw <- NULL
  if (isTRUE(include_class_weights)) {
    cw <- make_class_weights(train_dt$behaviour)
  }
  
  ranger::ranger(
    formula = behaviour ~ .,
    data = train_dt[, c("behaviour", predictors), with = FALSE],
    num.trees = num_trees,
    mtry = max(1L, floor(sqrt(length(predictors)))),
    min.node.size = min_node_size,
    importance = importance_mode,
    probability = TRUE,
    classification = TRUE,
    respect.unordered.factors = "order",
    seed = seed,
    num.threads = num_threads,
    class.weights = cw
  )
}

predict_fold <- function(rf, test_dt, predictors, num_threads, all_levels) {
  prob <- predict(rf, data = test_dt[, ..predictors], num.threads = num_threads)$predictions
  prob_dt <- data.table::as.data.table(prob)
  pred_class <- colnames(prob)[max.col(prob, ties.method = "first")]
  
  fold_out <- data.table::data.table(
    id = test_dt$id,
    epoch_start = test_dt$epoch_start,
    epoch_end = test_dt$epoch_end,
    truth = test_dt$behaviour,
    predicted = factor(pred_class, levels = all_levels)
  )
  data.table::setnames(prob_dt, paste0("prob_", colnames(prob_dt)))
  cbind(fold_out, prob_dt)
}

calc_macro_f1_from_vectors <- function(truth, predicted) {
  cm2 <- table(truth, predicted)
  cls <- rownames(cm2)
  if (length(cls) == 0L) return(NA_real_)
  
  f1s <- vapply(cls, function(cl) {
    tp <- cm2[cl, cl]
    fp <- sum(cm2[, cl]) - tp
    fn <- sum(cm2[cl, ]) - tp
    prec <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
    rec <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
    if (is.na(prec) || is.na(rec) || (prec + rec) == 0) return(NA_real_)
    2 * prec * rec / (prec + rec)
  }, numeric(1))
  
  mean(f1s, na.rm = TRUE)
}

feature_definition_lookup <- function(feature_name) {
  if (identical(feature_name, "n_samples")) {
    return("Number of downsampled accelerometer samples contributing to the epoch.")
  }
  if (startsWith(feature_name, "roll")) {
    return("Trailing rolling feature: roll{windowSeconds}_{fn}_{baseFeature}, computed over a right-aligned window of prior epochs (including current epoch).")
  }
  if (grepl("^(x|y|z)_(mean|sd|min|max|range)$", feature_name)) {
    axis <- sub("^(x|y|z)_.*$", "\\1", feature_name)
    stat <- sub("^(x|y|z)_", "", feature_name)
    if (identical(stat, "mean")) return(paste0("Epoch mean of ", axis, " (static component; mean of samples within epoch)."))
    if (identical(stat, "sd")) return(paste0("Epoch standard deviation of ", axis, " samples."))
    if (identical(stat, "min")) return(paste0("Epoch minimum of ", axis, " samples."))
    if (identical(stat, "max")) return(paste0("Epoch maximum of ", axis, " samples."))
    if (identical(stat, "range")) return(paste0("Epoch range of ", axis, " samples (max minus min)."))
  }
  if (grepl("^ODBA_(mean|sd|min|max)$", feature_name)) {
    stat <- sub("^ODBA_", "", feature_name)
    return(paste0(
      "Overall Dynamic Body Acceleration (ODBA) summarised per epoch. ODBA_samp = |x_dyn| + |y_dyn| + |z_dyn|, ",
      "where x_dyn = x - mean(x) within epoch (and similarly for y,z). Statistic: ", stat, "."
    ))
  }
  if (grepl("^(SMA|SVM|MV|Energy|Entropy)_(mean|sd|min|max)$", feature_name)) {
    sig <- sub("_(mean|sd|min|max)$", "", feature_name)
    stat <- sub("^(SMA|SVM|MV|Energy|Entropy)_", "", feature_name)
    sig_def <- switch(
      sig,
      "SMA" = "SMA_samp = |x| + |y| + |z| (signal magnitude area per sample).",
      "SVM" = "SVM_samp = sqrt(x^2 + y^2 + z^2) (signal vector magnitude per sample).",
      "MV" = "MV_samp = |x[t-1]-x[t]| + |y[t-1]-y[t]| + |z[t-1]-z[t]| (sample-to-sample movement variation; lagged difference on the continuous downsampled stream, so the first sample in an epoch can depend on the prior epoch).",
      "Energy" = "Energy_samp = (x^2 + y^2 + z^2)^2 (energy proxy per sample).",
      "Entropy" = "Entropy_samp = (1 + (x + y + z))^2 * log(1 + (x + y + z)^2) (entropy-like proxy per sample).",
      "Signal definition unknown."
    )
    return(paste0("Epoch summary of ", sig, " derived at sample level. ", sig_def, " Statistic: ", stat, "."))
  }
  if (grepl("^(Pitch|Roll|Incl)_(mean|sd)$", feature_name)) {
    ang <- sub("_(mean|sd)$", "", feature_name)
    stat <- sub("^(Pitch|Roll|Incl)_", "", feature_name)
    ang_def <- switch(
      ang,
      "Pitch" = "Pitch_deg = atan2(-x, sqrt(y^2 + z^2)) * 180/pi.",
      "Roll" = "Roll_deg = atan2(y, z) * 180/pi.",
      "Incl" = "Incl_deg = atan2(sqrt(x^2 + y^2), z) * 180/pi.",
      "Angle definition unknown."
    )
    return(paste0("Epoch summary of ", ang, " angle (degrees). ", ang_def, " Statistic: ", stat, "."))
  }
  "Definition not recognised. This feature may be derived by a different feature-engineering revision."
}

dump_ranger_trees <- function(rf, max_trees = NULL) {
  n_trees <- rf$num.trees
  if (!is.null(max_trees)) n_trees <- min(n_trees, max_trees)
  trees <- vector("list", n_trees)
  for (t in seq_len(n_trees)) {
    trees[[t]] <- data.table::as.data.table(ranger::treeInfo(rf, tree = t))
  }
  list(num_trees_dumped = n_trees, trees = trees)
}

candidate_base_features <- function(candidate) {
  vals <- strsplit(as.character(candidate$selected_base_features), "|", fixed = TRUE)[[1]]
  vals[nzchar(vals)]
}

candidate_predictors <- function(dt_epoch, candidate, config) {
  base_feats <- candidate_base_features(candidate)
  predictors <- base_feats
  
  if (isTRUE(candidate$rolling_enabled)) {
    roll_bases <- if (isTRUE(config$optimise$roll_on_selected_base_features_only)) {
      base_feats
    } else {
      get_base_feature_names(dt_epoch)
    }
    roll_cols <- unlist(lapply(config$optimise$roll_windows_seconds, function(w) {
      unlist(lapply(config$optimise$roll_fns, function(fn) {
        paste0("roll", w, "_", fn, "_", roll_bases)
      }), use.names = FALSE)
    }), use.names = FALSE)
    roll_cols <- intersect(roll_cols, names(dt_epoch))
    predictors <- c(predictors, roll_cols)
  }
  
  predictors <- unique(predictors)
  predictors[predictors %in% names(dt_epoch)]
}

prepare_candidate_rows <- function(dt_epoch, candidate, config, keep_all_cols = TRUE) {
  dt_epoch <- data.table::copy(dt_epoch)
  predictors <- candidate_predictors(dt_epoch, candidate, config)
  predictors <- predictors[vapply(dt_epoch[, ..predictors], is.numeric, logical(1))]
  
  if (length(predictors) < 1L) {
    stop("Candidate has no available numeric predictors: ", candidate$candidate_id)
  }
  
  if (!isTRUE(keep_all_cols)) {
    keep_cols <- unique(c("id", "epoch_start", "epoch_end", "epoch_seconds", "behaviour", predictors))
    dt_epoch <- dt_epoch[, ..keep_cols]
  }
  
  na_mode <- if (isTRUE(candidate$rolling_enabled)) config$optimise$na_drop_mode else "all_predictors"
  dt_epoch <- apply_na_policy(
    DT = dt_epoch,
    predictors = predictors,
    na_drop_mode = na_mode,
    enable_rolling_features = isTRUE(candidate$rolling_enabled),
    roll_windows_seconds = config$optimise$roll_windows_seconds
  )
  
  if (nrow(dt_epoch) == 0L) {
    stop("No rows remain after NA handling for candidate: ", candidate$candidate_id)
  }
  
  all_levels <- class_levels_from_config(config, dt_epoch$behaviour)
  dt_epoch[, behaviour := factor(as.character(behaviour), levels = all_levels)]
  
  list(
    data = dt_epoch,
    predictors = predictors,
    all_levels = all_levels
  )
}

evaluate_candidate_loco <- function(dt_epoch, candidate, config) {
  prepared <- prepare_candidate_rows(dt_epoch, candidate, config, keep_all_cols = TRUE)
  model_dt <- prepared$data
  predictors <- prepared$predictors
  all_levels <- prepared$all_levels
  
  cow_ids <- sort(unique(model_dt$id))
  if (length(cow_ids) < 2L) {
    stop("Need at least 2 ids for LOCO evaluation.")
  }
  
  pred_list <- vector("list", length(cow_ids))
  for (i in seq_along(cow_ids)) {
    test_cow <- cow_ids[i]
    train_dt <- model_dt[id != test_cow, c("behaviour", predictors), with = FALSE]
    test_dt <- model_dt[id == test_cow]
    if (nrow(test_dt) == 0L) next
    
    rf <- rf_fit(
      train_dt = train_dt,
      predictors = predictors,
      num_trees = as.integer(candidate$num_trees),
      min_node_size = as.integer(candidate$min_node_size),
      seed = config$model$seed,
      num_threads = config$model$num_threads,
      include_class_weights = config$model$include_class_weights,
      importance_mode = "impurity"
    )
    
    pred_list[[i]] <- predict_fold(rf, test_dt, predictors, config$model$num_threads, all_levels)
    rm(rf, train_dt, test_dt)
    gc()
  }
  
  pred_dt <- data.table::rbindlist(pred_list, use.names = TRUE, fill = TRUE)
  if (nrow(pred_dt) == 0L) stop("No LOCO predictions produced for candidate: ", candidate$candidate_id)
  pred_dt <- pred_dt[!is.na(truth) & !is.na(predicted)]
  pred_df <- as.data.frame(pred_dt)
  
  acc <- suppressWarnings(yardstick::accuracy(pred_df, truth = truth, estimate = predicted))
  macro <- suppressWarnings(yardstick::f_meas(pred_df, truth = truth, estimate = predicted, estimator = "macro"))
  weighted <- suppressWarnings(yardstick::f_meas(pred_df, truth = truth, estimate = predicted, estimator = "macro_weighted"))
  
  metrics_overall <- data.table::rbindlist(list(
    data.table::as.data.table(acc)[, .(metric = "accuracy", estimate = .estimate)],
    data.table::as.data.table(macro)[, .(metric = "macro_f1", estimate = .estimate)],
    data.table::as.data.table(weighted)[, .(metric = "weighted_f1", estimate = .estimate)]
  ))
  
  recall_by_class <- pred_dt[, .(
    support = .N,
    recall = mean(predicted == truth)
  ), by = .(class = as.character(truth))][order(-support)]
  
  cm <- yardstick::conf_mat(pred_df, truth = truth, estimate = predicted)
  cm_counts <- data.table::as.data.table(as.data.frame(cm$table))
  data.table::setnames(cm_counts, c("truth", "predicted", "n"))
  
  metrics_by_class <- data.table::rbindlist(lapply(all_levels, function(cl) {
    tp <- cm_counts[truth == cl & predicted == cl, sum(n)]
    fp <- cm_counts[truth != cl & predicted == cl, sum(n)]
    fn <- cm_counts[truth == cl & predicted != cl, sum(n)]
    tp <- ifelse(is.na(tp), 0, tp)
    fp <- ifelse(is.na(fp), 0, fp)
    fn <- ifelse(is.na(fn), 0, fn)
    precision_cl <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
    recall_cl <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
    f1_cl <- if (is.na(precision_cl) || is.na(recall_cl) || (precision_cl + recall_cl) == 0) NA_real_ else 2 * precision_cl * recall_cl / (precision_cl + recall_cl)
    data.table::data.table(
      class = cl,
      support = cm_counts[truth == cl, sum(n)],
      precision = precision_cl,
      recall = recall_cl,
      f1 = f1_cl
    )
  }), use.names = TRUE, fill = TRUE)[order(-support)]
  
  metrics_by_cow <- pred_dt[, .(
    support = .N,
    accuracy = mean(predicted == truth),
    macro_f1 = calc_macro_f1_from_vectors(truth, predicted)
  ), by = .(id)][order(-support)]
  
  list(
    prepared_data = model_dt,
    predictors = predictors,
    all_levels = all_levels,
    pred_dt = pred_dt,
    metrics_overall = metrics_overall,
    recall_by_class = recall_by_class,
    confusion_matrix = cm_counts,
    metrics_by_class = metrics_by_class,
    metrics_by_cow = metrics_by_cow
  )
}

measure_model_size_bytes <- function(model_dt, predictors, candidate, config) {
  rf_full <- rf_fit(
    train_dt = model_dt[, c("behaviour", predictors), with = FALSE],
    predictors = predictors,
    num_trees = as.integer(candidate$num_trees),
    min_node_size = as.integer(candidate$min_node_size),
    seed = config$model$seed,
    num_threads = config$model$num_threads,
    include_class_weights = config$model$include_class_weights,
    importance_mode = "impurity"
  )
  bytes <- length(serialize(rf_full, NULL, version = 2))
  rm(rf_full)
  gc()
  as.numeric(bytes)
}

fit_full_candidate_model <- function(dt_epoch, candidate, config) {
  prepared <- prepare_candidate_rows(dt_epoch, candidate, config, keep_all_cols = TRUE)
  rf_full <- rf_fit(
    train_dt = prepared$data[, c("behaviour", prepared$predictors), with = FALSE],
    predictors = prepared$predictors,
    num_trees = as.integer(candidate$num_trees),
    min_node_size = as.integer(candidate$min_node_size),
    seed = config$model$seed,
    num_threads = config$model$num_threads,
    include_class_weights = config$model$include_class_weights,
    importance_mode = "impurity"
  )
  
  list(
    rf_full = rf_full,
    prepared_data = prepared$data,
    predictors = prepared$predictors,
    all_levels = prepared$all_levels
  )
}

resolve_selected_candidate <- function(config) {
  mode <- tolower(as.character(config$selection$selection_mode))
  if (identical(mode, "manual")) {
    man <- config$selection$manual_candidate
    if (is.null(man)) stop("selection_mode='manual' requires selection$manual_candidate in config.")
    if (is.null(man$epoch_seconds)) stop("manual_candidate requires epoch_seconds.")
    if (is.null(man$manual_features) || length(man$manual_features) < 1L) {
      stop("manual_candidate requires manual_features.")
    }
    if (is.null(man$num_trees)) stop("manual_candidate requires num_trees.")
    if (is.null(man$min_node_size)) stop("manual_candidate requires min_node_size.")
    
    manual_features <- as.character(man$manual_features)
    topn_label <- if (!is.null(man$topN_label) && nzchar(as.character(man$topN_label))) {
      as.character(man$topN_label)
    } else {
      paste0("manual", length(manual_features))
    }
    candidate_id <- if (!is.null(man$candidate_id) && nzchar(as.character(man$candidate_id))) {
      as.character(man$candidate_id)
    } else {
      sprintf(
        "ep%ss_%s_%s_trees%s_node%s",
        as.integer(man$epoch_seconds),
        topn_label,
        if (isTRUE(man$rolling_enabled)) "roll" else "noroll",
        as.integer(man$num_trees),
        as.integer(man$min_node_size)
      )
    }
    
    return(data.table::data.table(
      candidate_id = candidate_id,
      epoch_seconds = as.integer(man$epoch_seconds),
      topN_label = topn_label,
      rolling_enabled = isTRUE(man$rolling_enabled),
      n_base_features = as.integer(length(manual_features)),
      selected_base_features = paste(manual_features, collapse = "|"),
      num_trees = as.integer(man$num_trees),
      min_node_size = as.integer(man$min_node_size)
    ))
  }
  
  results_path <- file.path(optimisation_output_dir(config), "candidate_results.csv")
  profiles_path <- file.path(optimisation_output_dir(config), "candidate_profiles.csv")
  
  if (!file.exists(results_path)) stop("Candidate results not found: ", results_path)
  results <- data.table::fread(results_path)
  
  if (identical(mode, "candidate_id")) {
    selected_id <- config$selection$selected_candidate_id
    if (is.null(selected_id) || !nzchar(selected_id)) return(NULL)
    out <- results[candidate_id == selected_id]
  } else if (identical(mode, "profile")) {
    selected_profile <- config$selection$selected_profile_name
    if (is.null(selected_profile) || !nzchar(selected_profile)) return(NULL)
    if (!file.exists(profiles_path)) stop("Candidate profiles not found: ", profiles_path)
    profiles <- data.table::fread(profiles_path)
    selected_id <- profiles[profile_name == selected_profile, unique(candidate_id)]
    if (length(selected_id) != 1L) stop("Could not resolve profile selection: ", selected_profile)
    out <- results[candidate_id == selected_id]
  } else {
    stop("Unknown selection_mode: ", config$selection$selection_mode)
  }
  
  if (nrow(out) != 1L) stop("Selection did not resolve to exactly one candidate.")
  out
}

make_export_id_from_candidate <- function(candidate, config) {
  topn_label <- tolower(as.character(candidate$topN_label))
  feature_tag <- if (startsWith(topn_label, "manual")) {
    topn_label
  } else {
    paste0("top", topn_label)
  }
  rolling_tag <- if (isTRUE(candidate$rolling_enabled)) {
    paste0("withroll_", paste(config$optimise$roll_windows_seconds, collapse = "-"), "s_", paste(config$optimise$roll_fns, collapse = "-"))
  } else {
    "noroll"
  }
  sprintf(
    "%s_epoch%ss_%s_%s_%s_trees%s_minnode%s_seed%s",
    config$export$export_tag,
    candidate$epoch_seconds,
    config$model$mode,
    feature_tag,
    rolling_tag,
    candidate$num_trees,
    candidate$min_node_size,
    config$model$seed
  )
}

export_dir_from_candidate <- function(candidate, config) {
  file.path(config$paths$export_base_dir, make_export_id_from_candidate(candidate, config))
}

write_export_pack <- function(candidate, eval_res, full_fit, config) {
  export_dir <- export_dir_from_candidate(candidate, config)
  ensure_dir(export_dir)
  
  data.table::fwrite(eval_res$metrics_overall, file.path(export_dir, "metrics_overall.csv"))
  data.table::fwrite(eval_res$recall_by_class, file.path(export_dir, "recall_by_class.csv"))
  data.table::fwrite(eval_res$confusion_matrix, file.path(export_dir, "confusion_matrix.csv"))
  data.table::fwrite(eval_res$metrics_by_class, file.path(export_dir, "metrics_by_class.csv"))
  data.table::fwrite(eval_res$metrics_by_cow, file.path(export_dir, "metrics_by_cow.csv"))
  data.table::fwrite(eval_res$pred_dt, file.path(export_dir, "loco_predictions.csv"))
  saveRDS(eval_res$pred_dt, file.path(export_dir, "loco_predictions.rds"))
  
  class_support_train <- full_fit$prepared_data[, .(n_epochs = .N), by = .(behaviour)][order(-n_epochs)]
  data.table::fwrite(class_support_train, file.path(export_dir, "class_support_train.csv"))
  
  dataset_summary <- data.table::data.table(
    n_animals = data.table::uniqueN(full_fit$prepared_data$id),
    n_epochs_total = nrow(full_fit$prepared_data),
    epoch_seconds = candidate$epoch_seconds,
    tz_epoch = "UTC",
    mode = config$model$mode,
    positive_class = if (identical(config$model$mode, "binary")) config$model$positive_class else NA_character_,
    n_predictors = length(full_fit$predictors),
    start_time_min = as.character(min(full_fit$prepared_data$epoch_start, na.rm = TRUE)),
    end_time_max = as.character(max(full_fit$prepared_data$epoch_end, na.rm = TRUE))
  )
  data.table::fwrite(dataset_summary, file.path(export_dir, "dataset_summary.csv"))
  
  saveRDS(full_fit$rf_full, file.path(export_dir, "rf_model_full.rds"))
  
  manifest <- data.table::data.table(
    feature = full_fit$predictors,
    is_rolling = startsWith(full_fit$predictors, "roll"),
    definition = vapply(full_fit$predictors, feature_definition_lookup, character(1))
  )
  manifest[, `:=`(
    epoch_seconds = candidate$epoch_seconds,
    mode = config$model$mode,
    rolling_enabled = candidate$rolling_enabled,
    roll_windows_seconds = if (isTRUE(candidate$rolling_enabled)) paste(config$optimise$roll_windows_seconds, collapse = ",") else "",
    roll_fns = if (isTRUE(candidate$rolling_enabled)) paste(config$optimise$roll_fns, collapse = ",") else ""
  )]
  data.table::fwrite(manifest, file.path(export_dir, "feature_manifest.csv"))
  
  data.table::fwrite(candidate, file.path(export_dir, "selected_candidate.csv"))
  
  export_config <- list(
    export_id = basename(export_dir),
    created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    tz_epoch = "UTC",
    model = config$model,
    candidate = as.list(candidate),
    paths = config$paths,
    test_vectors = config$test_vectors,
    outputs = list(
      rf_model_full_rds = "rf_model_full.rds",
      feature_manifest_csv = "feature_manifest.csv",
      metrics_overall_csv = "metrics_overall.csv",
      recall_by_class_csv = "recall_by_class.csv",
      confusion_matrix_csv = "confusion_matrix.csv",
      metrics_by_class_csv = "metrics_by_class.csv",
      metrics_by_cow_csv = "metrics_by_cow.csv",
      class_support_train_csv = "class_support_train.csv",
      dataset_summary_csv = "dataset_summary.csv",
      loco_predictions_rds = "loco_predictions.rds",
      test_vectors_csv = "test_vectors.csv",
      test_vectors_all_csv = "test_vectors_all.csv"
    )
  )
  writeLines(
    jsonlite::toJSON(export_config, pretty = TRUE, auto_unbox = TRUE),
    con = file.path(export_dir, "export_config.json")
  )
  
  if (isTRUE(config$export$export_tree_dump_json)) {
    dump <- dump_ranger_trees(full_fit$rf_full, max_trees = config$export$tree_dump_max_trees)
    trees_json <- lapply(dump$trees, function(dt_tree) as.data.frame(dt_tree))
    out_json <- list(
      export_id = basename(export_dir),
      tz_epoch = "UTC",
      num_trees_in_model = full_fit$rf_full$num.trees,
      num_trees_dumped = dump$num_trees_dumped,
      predictors = full_fit$predictors,
      classes = full_fit$all_levels,
      trees = trees_json
    )
    writeLines(
      jsonlite::toJSON(out_json, pretty = FALSE, auto_unbox = TRUE),
      con = file.path(export_dir, "rf_tree_dump.json")
    )
  }
  
  invisible(export_dir)
}

train_and_export_selected_model <- function(config) {
  candidate <- resolve_selected_candidate(config)
  dt <- load_canonical_dataset(config)
  dt_epoch <- dt[epoch_seconds == as.integer(candidate$epoch_seconds)]
  if (nrow(dt_epoch) == 0L) stop("No canonical rows for selected epoch: ", candidate$epoch_seconds)
  
  message("Selected candidate: ", candidate$candidate_id)
  eval_res <- evaluate_candidate_loco(dt_epoch, candidate, config)
  full_fit <- fit_full_candidate_model(dt_epoch, candidate, config)
  export_dir <- write_export_pack(candidate, eval_res, full_fit, config)
  message("Wrote export pack: ", normalizePath(export_dir))
  
  invisible(export_dir)
}
