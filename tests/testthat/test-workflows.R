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
