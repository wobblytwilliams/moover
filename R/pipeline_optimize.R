compute_fold_aware_importance <- function(dt_epoch, base_predictors, config) {
  dt_epoch <- data.table::copy(dt_epoch)
  all_levels <- class_levels_from_config(config, dt_epoch$behaviour)
  dt_epoch[, behaviour := factor(as.character(behaviour), levels = all_levels)]
  cow_ids <- sort(unique(dt_epoch$id))
  imp_by_fold_list <- list()
  
  for (i in seq_along(cow_ids)) {
    test_cow <- cow_ids[i]
    train_dt <- dt_epoch[id != test_cow, c("behaviour", base_predictors), with = FALSE]
    if (nrow(train_dt) == 0L) next
    
    rf_imp <- rf_fit(
      train_dt = train_dt,
      predictors = base_predictors,
      num_trees = config$optimise$importance_num_trees,
      min_node_size = min(config$optimise$min_node_size_grid),
      seed = config$model$seed,
      num_threads = config$model$num_threads,
      include_class_weights = config$model$include_class_weights,
      importance_mode = "permutation"
    )
    
    vi <- rf_imp$variable.importance
    imp_by_fold_list[[i]] <- data.table::data.table(
      holdout_id = test_cow,
      feature = names(vi),
      importance = as.numeric(vi)
    )
    
    rm(rf_imp, train_dt, vi)
    gc()
  }
  
  imp_by_fold <- data.table::rbindlist(imp_by_fold_list, use.names = TRUE, fill = TRUE)
  if (nrow(imp_by_fold) == 0L) stop("No fold-aware importance results produced.")
  
  imp_agg <- imp_by_fold[, .(
    importance_median = median(importance, na.rm = TRUE),
    importance_mean = mean(importance, na.rm = TRUE)
  ), by = .(feature)][order(-importance_median, -importance_mean, feature)]
  
  list(
    importance_by_fold = imp_by_fold,
    importance_aggregated = imp_agg,
    ranked_features = imp_agg$feature
  )
}

build_topn_feature_sets <- function(ranked_features, epoch_seconds, topN_grid) {
  topN_grid <- sort(unique(as.integer(topN_grid)))
  topN_grid <- topN_grid[topN_grid > 0L]
  topN_grid <- topN_grid[topN_grid <= length(ranked_features)]
  
  out <- data.table::rbindlist(lapply(topN_grid, function(n) {
    data.table::data.table(
      epoch_seconds = epoch_seconds,
      topN = n,
      topN_label = as.character(n),
      feature = ranked_features[seq_len(n)],
      rank = seq_len(n)
    )
  }), use.names = TRUE, fill = TRUE)
  
  all_row <- data.table::data.table(
    epoch_seconds = epoch_seconds,
    topN = length(ranked_features),
    topN_label = "ALL",
    feature = ranked_features,
    rank = seq_along(ranked_features)
  )
  
  data.table::rbindlist(list(out, all_row), use.names = TRUE, fill = TRUE)
}

make_candidate_id <- function(epoch_seconds, topN_label, rolling_enabled, num_trees, min_node_size) {
  sprintf(
    "ep%ss_top%s_%s_trees%s_node%s",
    epoch_seconds,
    tolower(as.character(topN_label)),
    if (isTRUE(rolling_enabled)) "roll" else "noroll",
    num_trees,
    min_node_size
  )
}

scale01 <- function(x) {
  rng <- range(x, na.rm = TRUE)
  if (!all(is.finite(rng)) || diff(rng) == 0) return(rep(0, length(x)))
  (x - rng[1]) / (rng[2] - rng[1])
}

compute_complexity_score <- function(dt) {
  scale01(dt$model_size_bytes) +
    scale01(dt$predictor_count) +
    0.25 * as.numeric(dt$rolling_enabled) +
    scale01(dt$num_trees) +
    scale01(1 / dt$epoch_seconds)
}

compute_pareto_frontier <- function(dt) {
  dt <- data.table::copy(dt)
  dt[, is_pareto := TRUE]
  
  for (i in seq_len(nrow(dt))) {
    dominates <- dt[
      seq_len(.N) != i &
        accuracy >= dt$accuracy[i] &
        model_size_bytes <= dt$model_size_bytes[i] &
        (accuracy > dt$accuracy[i] | model_size_bytes < dt$model_size_bytes[i]),
      .N
    ] > 0L
    dt$is_pareto[i] <- !dominates
  }
  
  dt
}

make_candidate_profiles <- function(dt, accuracy_tolerance) {
  best_acc <- max(dt$accuracy, na.rm = TRUE)
  within_tol <- dt[accuracy >= (best_acc - accuracy_tolerance)]
  
  best_accuracy <- dt[order(-accuracy, model_size_bytes, predictor_count, num_trees, min_node_size)][1]
  best_small_model <- within_tol[order(model_size_bytes, -accuracy, predictor_count, num_trees, min_node_size)][1]
  best_balanced <- within_tol[order(complexity_score, -accuracy, model_size_bytes, predictor_count)][1]
  
  data.table::rbindlist(list(
    data.table::copy(best_accuracy)[, profile_name := "best_accuracy"],
    data.table::copy(best_small_model)[, profile_name := "best_small_model"],
    data.table::copy(best_balanced)[, profile_name := "best_balanced"]
  ), use.names = TRUE, fill = TRUE)
}

write_optimization_plots <- function(candidate_results, out_dir, config) {
  if (nrow(candidate_results) == 0L) return(invisible(NULL))
  
  p1 <- ggplot2::ggplot(
    candidate_results,
    ggplot2::aes(
      x = n_base_features,
      y = accuracy,
      colour = factor(epoch_seconds),
      shape = factor(rolling_enabled)
    )
  ) +
    ggplot2::geom_point(size = 2) +
    ggplot2::facet_grid(min_node_size ~ num_trees, labeller = ggplot2::label_both) +
    ggplot2::labs(
      title = "Accuracy vs feature count",
      x = "Number of base features",
      y = "Accuracy",
      colour = "Epoch (s)",
      shape = "Rolling"
    ) +
    ggplot2::theme_minimal()
  ggplot2::ggsave(file.path(out_dir, "plot_accuracy_vs_feature_count.png"), p1, width = 12, height = 7, dpi = config$optimise$plots_dpi)
  
  p2 <- ggplot2::ggplot(
    candidate_results,
    ggplot2::aes(
      x = model_size_bytes,
      y = accuracy,
      colour = factor(epoch_seconds),
      shape = factor(rolling_enabled)
    )
  ) +
    ggplot2::geom_point(size = 2) +
    ggplot2::facet_grid(min_node_size ~ num_trees, labeller = ggplot2::label_both) +
    ggplot2::labs(
      title = "Accuracy vs model size",
      x = "Serialized model size (bytes)",
      y = "Accuracy",
      colour = "Epoch (s)",
      shape = "Rolling"
    ) +
    ggplot2::theme_minimal()
  ggplot2::ggsave(file.path(out_dir, "plot_accuracy_vs_model_size.png"), p2, width = 12, height = 7, dpi = config$optimise$plots_dpi)
  
  epoch_summary <- candidate_results[, .(
    best_accuracy = max(accuracy, na.rm = TRUE),
    smallest_model_bytes = min(model_size_bytes, na.rm = TRUE)
  ), by = .(epoch_seconds, rolling_enabled)]
  
  p3 <- ggplot2::ggplot(
    epoch_summary,
    ggplot2::aes(x = epoch_seconds, y = best_accuracy, colour = factor(rolling_enabled))
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(
      title = "Best candidate accuracy by epoch length",
      x = "Epoch length (s)",
      y = "Best accuracy",
      colour = "Rolling"
    ) +
    ggplot2::theme_minimal()
  ggplot2::ggsave(file.path(out_dir, "plot_epoch_summary.png"), p3, width = 10, height = 6, dpi = config$optimise$plots_dpi)
  
  invisible(NULL)
}

optimise_candidates <- function(config) {
  ensure_dir(config$paths$optimization_base_dir)
  out_dir <- optimisation_output_dir(config)
  ensure_dir(out_dir)
  
  dt <- load_canonical_dataset(config)
  candidate_rows <- list()
  recall_rows <- list()
  feature_sets_all <- list()
  
  for (epoch_seconds_keep in config$optimise$epochs_to_run) {
    message("Optimising epoch: ", epoch_seconds_keep, "s")
    epoch_out_dir <- file.path(out_dir, paste0("epoch_", epoch_seconds_keep, "s"))
    ensure_dir(epoch_out_dir)
    
    dt_epoch <- dt[epoch_seconds == epoch_seconds_keep]
    dt_epoch <- dt_epoch[!is.na(behaviour) & behaviour != ""]
    if (nrow(dt_epoch) == 0L) next
    
    base_predictors <- get_base_feature_names(dt_epoch)
    if (length(base_predictors) < 2L) next
    
    dt_imp <- apply_na_policy(
      DT = dt_epoch,
      predictors = base_predictors,
      na_drop_mode = "all_predictors",
      enable_rolling_features = FALSE,
      roll_windows_seconds = integer(0)
    )
    if (nrow(dt_imp) == 0L || data.table::uniqueN(dt_imp$id) < 2L) next
    
    imp_res <- compute_fold_aware_importance(dt_imp, base_predictors, config)
    data.table::fwrite(imp_res$importance_by_fold, file.path(epoch_out_dir, "importance_by_fold.csv"))
    data.table::fwrite(imp_res$importance_aggregated, file.path(epoch_out_dir, "importance_aggregated.csv"))
    
    feature_sets <- build_topn_feature_sets(imp_res$ranked_features, epoch_seconds_keep, config$optimise$topN_grid)
    data.table::fwrite(feature_sets, file.path(epoch_out_dir, "feature_sets.csv"))
    feature_sets_all[[as.character(epoch_seconds_keep)]] <- feature_sets
    
    topN_labels <- unique(feature_sets$topN_label)
    topN_labels <- c(setdiff(topN_labels, "ALL"), "ALL")
    rolling_options <- if (isTRUE(config$optimise$enable_rolling_search)) c(FALSE, TRUE) else FALSE
    
    for (topN_label in topN_labels) {
      lab <- as.character(topN_label)
      selected_base <- feature_sets[topN_label == lab, feature]
      n_base <- length(selected_base)
      selected_base_str <- paste(selected_base, collapse = "|")
      
      for (rolling_enabled in rolling_options) {
        for (num_trees in config$optimise$num_trees_grid) {
          for (min_node_size in config$optimise$min_node_size_grid) {
              candidate <- data.table::data.table(
                candidate_id = make_candidate_id(epoch_seconds_keep, lab, rolling_enabled, num_trees, min_node_size),
                epoch_seconds = as.integer(epoch_seconds_keep),
                topN_label = lab,
                rolling_enabled = isTRUE(rolling_enabled),
                n_base_features = as.integer(n_base),
                selected_base_features = selected_base_str,
              num_trees = as.integer(num_trees),
              min_node_size = as.integer(min_node_size)
            )
            
            message("Evaluating candidate: ", candidate$candidate_id)
            eval_res <- tryCatch(
              evaluate_candidate_loco(dt_epoch, candidate, config),
              error = function(e) {
                message("Skipping candidate ", candidate$candidate_id, ": ", e$message)
                NULL
              }
            )
            if (is.null(eval_res)) next
            
            model_size_bytes <- measure_model_size_bytes(eval_res$prepared_data, eval_res$predictors, candidate, config)
            metrics_wide <- data.table::dcast(eval_res$metrics_overall, . ~ metric, value.var = "estimate")
            recall_wide <- data.table::dcast(eval_res$recall_by_class, . ~ class, value.var = "recall")
            if ("." %in% names(metrics_wide)) metrics_wide[, . := NULL]
            if ("." %in% names(recall_wide)) recall_wide[, . := NULL]
            if (ncol(recall_wide) > 0L) {
              data.table::setnames(recall_wide, names(recall_wide), paste0("recall_", names(recall_wide)))
            }
            
            row_dt <- cbind(
              candidate,
              data.table::data.table(
                predictor_count = length(eval_res$predictors),
                predictor_names = paste(eval_res$predictors, collapse = "|"),
                model_size_bytes = model_size_bytes
              ),
              metrics_wide,
              recall_wide
            )
            candidate_rows[[candidate$candidate_id]] <- row_dt
            
            rec_dt <- data.table::copy(eval_res$recall_by_class)
            rec_dt[, `:=`(
              candidate_id = candidate$candidate_id,
              epoch_seconds = candidate$epoch_seconds,
              topN_label = candidate$topN_label,
              rolling_enabled = candidate$rolling_enabled,
              num_trees = candidate$num_trees,
              min_node_size = candidate$min_node_size
            )]
            recall_rows[[candidate$candidate_id]] <- rec_dt
          }
        }
      }
    }
  }
  
  candidate_results <- data.table::rbindlist(candidate_rows, use.names = TRUE, fill = TRUE)
  if (nrow(candidate_results) == 0L) stop("No optimisation candidates were evaluated successfully.")
  
  candidate_results[, complexity_score := compute_complexity_score(candidate_results)]
  candidate_results <- compute_pareto_frontier(candidate_results)
  candidate_results <- candidate_results[order(-accuracy, model_size_bytes, predictor_count)]
  
  candidate_recall_by_class <- data.table::rbindlist(recall_rows, use.names = TRUE, fill = TRUE)
  candidate_pareto_frontier <- candidate_results[is_pareto == TRUE]
  candidate_profiles <- make_candidate_profiles(candidate_results, config$selection$accuracy_tolerance)
  
  data.table::fwrite(candidate_results, file.path(out_dir, "candidate_results.csv"))
  data.table::fwrite(candidate_recall_by_class, file.path(out_dir, "candidate_recall_by_class.csv"))
  data.table::fwrite(data.table::rbindlist(feature_sets_all, use.names = TRUE, fill = TRUE), file.path(out_dir, "candidate_feature_sets.csv"))
  data.table::fwrite(candidate_pareto_frontier, file.path(out_dir, "candidate_pareto_frontier.csv"))
  data.table::fwrite(candidate_profiles, file.path(out_dir, "candidate_profiles.csv"))
  
  write_optimization_plots(candidate_results, out_dir, config)
  message("Wrote optimisation outputs: ", normalizePath(out_dir))
  
  invisible(out_dir)
}
