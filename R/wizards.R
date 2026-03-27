moover_prompt <- function(prompt, default = NULL) {
  full <- if (is.null(default)) {
    paste0(prompt, ": ")
  } else {
    paste0(prompt, " [", default, "]: ")
  }
  ans <- trimws(readline(full))
  if (!nzchar(ans) && !is.null(default)) return(default)
  ans
}

moover_choose_raw_format <- function() {
  choice <- utils::menu(
    choices = c("CQU accelerometer files", "Generic delimited files"),
    title = "Choose the raw accelerometer input format"
  )
  if (choice == 2L) "generic" else "cqu"
}

moover_prompt_generic_schema <- function(raw_dir) {
  first_file <- utils::head(list.files(raw_dir, full.names = TRUE), 1L)
  if (length(first_file) != 1L) stop("No files found to inspect in ", raw_dir)
  preview <- data.table::fread(first_file, nrows = 5L)
  print(preview)
  id_default <- if (ncol(preview) >= 5L) names(preview)[5] else "id"
  list(
    raw = list(
      datetime = moover_prompt("Column containing timestamp", names(preview)[1]),
      x = moover_prompt("Column containing x", names(preview)[2]),
      y = moover_prompt("Column containing y", names(preview)[3]),
      z = moover_prompt("Column containing z", names(preview)[4]),
      id = moover_prompt("Column containing id", id_default),
      id_type = moover_prompt("Does the id column contain 'id' or 'accelerometer' values", "id"),
      time_format = moover_prompt("Timestamp format (unix_ms, unix_s, iso8601_utc, iso8601_local)", "unix_ms")
    )
  )
}

#' Guided Import Wizard
#'
#' Interactively builds a simple import spec, previews the canonicalised data,
#' and writes the run spec into the current workspace.
#'
#' @return A `moover_spec` object.
#' @export
wizard_import <- function() {
  root <- moover_prompt("Workspace root", getwd())
  init_workspace(root)
  raw_format <- moover_choose_raw_format()
  raw_dir <- moover_prompt("Raw data directory", file.path(root, "data_raw"))
  ingest <- list(format = raw_format, raw_dir = raw_dir)
  schema <- if (identical(raw_format, "generic")) moover_prompt_generic_schema(raw_dir) else list()
  spec <- create_spec(
    workspace = list(root = root),
    ingest = ingest,
    schema = schema
  )
  moover_write_spec(spec)
  import_accel(spec)
  spec
}

#' Guided Training Wizard
#'
#' Builds a training spec interactively and can immediately run the full
#' training and export workflow.
#'
#' @return A `moover_spec` object.
#' @export
wizard_train <- function() {
  root <- moover_prompt("Workspace root", getwd())
  init_workspace(root)
  raw_format <- moover_choose_raw_format()
  do_optimise <- moover_parse_yes_no("Optimise for embedded deployment before training", default = TRUE)
  feature_mode <- if (do_optimise) "all" else "standard"
  raw_dir <- moover_prompt("Raw data directory", file.path(root, "data_raw"))
  schema <- if (identical(raw_format, "generic")) moover_prompt_generic_schema(raw_dir) else list()
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(
      format = raw_format,
      raw_dir = raw_dir
    ),
    schema = schema,
    labels = list(
      tech_file = moover_prompt("Tech file", file.path(root, "tech.csv")),
      path = moover_prompt("Observation file", file.path(root, "observations.csv"))
    ),
    features = list(
      selection = feature_mode,
      standard_set = "manual5"
    ),
    optimise = list(
      enabled = do_optimise
    ),
    model = list(
      positive_class = moover_prompt("Positive class label", "grazing")
    )
  )
  moover_write_spec(spec)
  if (moover_parse_yes_no("Run the full training workflow now", default = TRUE)) {
    run_pipeline(spec, stage = "all")
  }
  spec
}

#' Guided Prediction Wizard
#'
#' Builds a simple prediction spec for applying an existing model bundle to new
#' data.
#'
#' @return A `moover_spec` object.
#' @export
wizard_predict <- function() {
  root <- moover_prompt("Workspace root", getwd())
  init_workspace(root)
  raw_format <- moover_choose_raw_format()
  bundle_path <- moover_prompt("Model bundle directory")
  raw_dir <- moover_prompt("Raw data directory", file.path(root, "data_raw"))
  schema <- if (identical(raw_format, "generic")) moover_prompt_generic_schema(raw_dir) else list()
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(
      format = raw_format,
      raw_dir = raw_dir
    ),
    schema = schema,
    labels = list(
      tech_file = moover_prompt("Tech file (optional)", file.path(root, "tech.csv")),
      path = NULL
    ),
    predict = list(
      model_bundle = bundle_path,
      summary_outputs = if (moover_parse_yes_no("Also write hourly summaries", FALSE)) "hourly" else character()
    )
  )
  moover_write_spec(spec)
  if (moover_parse_yes_no("Run prediction now", default = TRUE)) {
    run_pipeline(spec, stage = "predict")
  }
  spec
}
