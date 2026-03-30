example_workspace_copy <- function() {
  src <- testthat::test_path("..", "..", "inst", "extdata", "example_workspace")
  dst <- file.path(tempdir(), paste0("moover_example_", as.integer(Sys.time()), "_", sample.int(1000, 1)))
  dir.create(dst, recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(src, full.names = TRUE, all.files = TRUE, no.. = TRUE), dst, recursive = TRUE)
  dst
}

test_that("init_workspace creates the standard folders", {
  root <- file.path(tempdir(), paste0("moover_ws_", sample.int(1000, 1)))
  ws <- init_workspace(root)
  expect_s3_class(ws, "moover_workspace")
  expect_true(dir.exists(file.path(root, "data_raw")))
  expect_true(dir.exists(file.path(root, "runs")))
  expect_true(dir.exists(file.path(root, "_internal")))
})

test_that("import and feature building work on the packaged example workspace", {
  root <- example_workspace_copy()
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(raw_dir = file.path(root, "data_raw")),
    labels = list(
      tech_file = file.path(root, "tech.csv"),
      path = file.path(root, "observations.csv")
    ),
    features = list(
      selection = "standard",
      standard_set = "manual5"
    ),
    model = list(
      positive_class = "grazing",
      num_threads = 1L
    ),
    run = list(run_id = "test_build")
  )
  imported <- import_accel(spec)
  expect_true(file.exists(imported$preview_file))
  expect_true(file.exists(imported$canonical_accel_file))
  path <- build_epoch_features(spec)
  expect_true(file.exists(path))
  dt <- readRDS(path)
  expect_true(nrow(dt) > 0L)
  expect_true(all(c("id", "epoch_start", "epoch_end", "behaviour") %in% names(dt)))
})

test_that("train, export, and predict work end to end", {
  root <- example_workspace_copy()
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(raw_dir = file.path(root, "data_raw")),
    labels = list(
      tech_file = file.path(root, "tech.csv"),
      path = file.path(root, "observations.csv")
    ),
    features = list(
      selection = "standard",
      standard_set = "manual5"
    ),
    model = list(
      positive_class = "grazing",
      num_threads = 1L,
      num_trees = 3L,
      min_node_size = 30L
    ),
    optimise = list(enabled = FALSE),
    export = list(export_tag = "moover_export"),
    run = list(run_id = "test_train")
  )
  fit <- train_model(spec)
  expect_true(file.exists(fit$run_paths$fit_cache))
  export_dir <- export_model(spec, fit)
  expect_true(file.exists(file.path(export_dir, "rf_model_full.rds")))
  expect_true(file.exists(file.path(export_dir, "test_vectors.csv")))
  pred_spec <- create_spec(
    workspace = list(root = root),
    ingest = list(raw_dir = file.path(root, "data_raw")),
    labels = list(
      tech_file = file.path(root, "tech.csv"),
      path = NULL
    ),
    predict = list(model_bundle = export_dir),
    run = list(run_id = "test_predict")
  )
  preds <- predict_behaviour(pred_spec)
  expect_true(nrow(preds) > 0L)
  expect_true(all(c("id", "predicted") %in% names(preds)))
})

test_that("raw files can live outside the workspace while outputs stay local", {
  root <- example_workspace_copy()
  external_raw <- file.path(tempdir(), paste0("moover_external_raw_", sample.int(1000, 1)))
  dir.create(external_raw, recursive = TRUE, showWarnings = FALSE)
  raw_files <- list.files(file.path(root, "data_raw"), full.names = TRUE)
  file.copy(raw_files, external_raw, overwrite = TRUE)

  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(raw_dir = external_raw),
    labels = list(
      tech_file = file.path(root, "tech.csv"),
      path = file.path(root, "observations.csv")
    ),
    features = list(
      selection = "standard",
      standard_set = "manual5"
    ),
    model = list(
      positive_class = "grazing",
      num_threads = 1L
    ),
    run = list(run_id = "test_external_raw")
  )

  imported <- import_accel(spec)
  epoch_path <- build_epoch_features(spec)
  run_paths <- moover_run_paths(spec)

  expect_true(file.exists(imported$preview_file))
  expect_true(file.exists(imported$canonical_accel_file))
  expect_true(file.exists(epoch_path))
  expect_true(startsWith(normalizePath(imported$canonical_accel_file, winslash = "/"), normalizePath(run_paths$run_root, winslash = "/")))
  expect_true(startsWith(normalizePath(epoch_path, winslash = "/"), normalizePath(run_paths$run_root, winslash = "/")))
})

test_that("chunked and whole-file ingestion produce the same canonical epoch features", {
  root <- example_workspace_copy()
  common_args <- list(
    workspace = list(root = root),
    labels = list(
      tech_file = file.path(root, "tech.csv"),
      path = file.path(root, "observations.csv")
    ),
    features = list(
      selection = "standard",
      standard_set = "manual5"
    ),
    model = list(
      positive_class = "grazing",
      num_threads = 1L
    )
  )

  spec_whole <- do.call(create_spec, c(common_args, list(
    ingest = list(raw_dir = file.path(root, "data_raw"), chunk_rows = NULL),
    run = list(run_id = "test_chunk_whole")
  )))
  spec_chunked <- do.call(create_spec, c(common_args, list(
    ingest = list(raw_dir = file.path(root, "data_raw"), chunk_rows = 25L),
    run = list(run_id = "test_chunked")
  )))

  whole_path <- build_epoch_features(spec_whole)
  chunked_path <- build_epoch_features(spec_chunked)

  whole <- data.table::as.data.table(readRDS(whole_path))
  chunked <- data.table::as.data.table(readRDS(chunked_path))
  data.table::setorderv(whole, c("id", "epoch_seconds", "epoch_start", "epoch_end"))
  data.table::setorderv(chunked, c("id", "epoch_seconds", "epoch_start", "epoch_end"))

  key_cols <- c("id", "epoch_seconds", "epoch_start", "epoch_end", "behaviour", "raw_ms", "prev_raw_ms", "n_raw")
  expect_equal(whole[, ..key_cols], chunked[, ..key_cols])
  expect_equal(whole$MV_mean, chunked$MV_mean, tolerance = 1e-12)
  expect_equal(whole$SVM_sd, chunked$SVM_sd, tolerance = 1e-12)
})

test_that("large-file preflight warning suggests chunked reading", {
  root <- example_workspace_copy()
  warning_raw <- file.path(tempdir(), paste0("moover_warning_raw_", sample.int(1000, 1)))
  dir.create(warning_raw, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    from = list.files(file.path(root, "data_raw"), full.names = TRUE)[1],
    to = warning_raw,
    overwrite = TRUE
  )
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(
      raw_dir = warning_raw,
      chunk_rows = NULL,
      large_file_warning_bytes = 1
    ),
    run = list(run_id = "test_large_file_warning")
  )

  expect_warning(
    imported <- import_accel(spec),
    "ingest\\$chunk_rows"
  )
  expect_true(file.exists(imported$preview_file))
})
