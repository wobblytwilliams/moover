moover_wizard_rule <- function(char = "=") {
  cat(paste(rep(char, 78L), collapse = ""), "\n", sep = "")
}

moover_wizard_wrap <- function(text, indent = 0L, width = 78L) {
  text <- paste(text, collapse = " ")
  wrapped <- strwrap(text, width = max(40L, width - indent))
  prefix <- if (indent > 0L) paste(rep(" ", indent), collapse = "") else ""
  paste0(prefix, wrapped, collapse = "\n")
}

moover_wizard_text <- function(..., indent = 0L, blank_after = TRUE) {
  text <- paste(..., collapse = "")
  cat(moover_wizard_wrap(text, indent = indent), "\n", sep = "")
  if (isTRUE(blank_after)) cat("\n")
}

moover_wizard_bullet <- function(...) {
  text <- paste(..., collapse = "")
  wrapped <- strwrap(text, width = 74L, exdent = 2L)
  if (length(wrapped) == 0L) return(invisible(NULL))
  cat("- ", wrapped[[1]], "\n", sep = "")
  if (length(wrapped) > 1L) {
    cat(paste0("  ", wrapped[-1L], collapse = "\n"), "\n", sep = "")
  }
  invisible(NULL)
}

moover_wizard_title <- function(title, intro = NULL) {
  cat("\n")
  moover_wizard_rule("=")
  cat(title, "\n", sep = "")
  moover_wizard_rule("=")
  if (!is.null(intro)) {
    moover_wizard_text(intro)
  }
}

moover_wizard_section <- function(title, what = NULL, why = NULL) {
  cat(title, "\n", sep = "")
  cat(paste(rep("-", min(78L, nchar(title))), collapse = ""), "\n", sep = "")
  if (!is.null(what)) {
    moover_wizard_text(paste0("What we're doing: ", what))
  }
  if (!is.null(why)) {
    moover_wizard_text(paste0("Why this matters: ", why))
  }
}

moover_prompt <- function(prompt, default = NULL, details = NULL) {
  if (!is.null(details)) {
    moover_wizard_text(details, indent = 2L)
  }
  full <- if (is.null(default)) {
    paste0(prompt, ": ")
  } else {
    paste0(prompt, " [", default, "]: ")
  }
  ans <- trimws(readline(full))
  if (!nzchar(ans) && !is.null(default)) return(default)
  ans
}

moover_wizard_yes_no <- function(prompt, default = TRUE, details = NULL) {
  if (!is.null(details)) {
    moover_wizard_text(details, indent = 2L)
  }
  moover_parse_yes_no(prompt, default = default)
}

moover_choose_raw_format <- function() {
  moover_wizard_section(
    "Choose Your Raw Data Format",
    what = "I need to know what your input files look like before I can read them correctly.",
    why = "If your files already use the expected CQU style, moover can read them directly. If they are ordinary CSV or TSV files, moover can still use them, but it needs you to map the columns first."
  )
  moover_wizard_bullet("Choose 'CQU accelerometer files' if your files already look like the standard CQU/moover format with datetime, x, y, and z columns.")
  moover_wizard_bullet("Choose 'Generic delimited files' if you have your own CSV or TSV files and want moover to ask which columns contain time and accelerometer values.")
  cat("\n")
  choice <- utils::menu(
    choices = c("CQU accelerometer files", "Generic delimited files"),
    title = "Choose the raw accelerometer input format"
  )
  if (choice == 0L) stop("Wizard cancelled.", call. = FALSE)
  if (choice == 2L) "generic" else "cqu"
}

moover_prompt_generic_schema <- function(raw_dir) {
  first_file <- utils::head(list.files(raw_dir, full.names = TRUE), 1L)
  if (length(first_file) != 1L) stop("No files found to inspect in ", raw_dir)
  preview <- data.table::fread(first_file, nrows = 5L)
  moover_wizard_section(
    "Map the Columns in Your Generic File",
    what = paste0("I am going to inspect one example file so you can tell moover which columns hold time, x, y, z, and the animal identifier. The preview below comes from ", basename(first_file), "."),
    why = "This mapping step lets beginners use normal CSV files without rewriting them by hand."
  )
  moover_wizard_text("Preview of the first few rows:")
  print(preview)
  cat("\n")
  moover_wizard_text("I will now ask a short series of questions about the columns. You are not changing the file here; you are simply telling moover how to read it.")
  id_default <- if (ncol(preview) >= 5L) names(preview)[5] else "id"
  list(
    raw = list(
      datetime = moover_prompt(
        "Column containing timestamp",
        names(preview)[1],
        details = "This is the column that tells moover when each sample was recorded."
      ),
      x = moover_prompt(
        "Column containing x",
        names(preview)[2],
        details = "This should be the acceleration values for the x axis."
      ),
      y = moover_prompt(
        "Column containing y",
        names(preview)[3],
        details = "This should be the acceleration values for the y axis."
      ),
      z = moover_prompt(
        "Column containing z",
        names(preview)[4],
        details = "This should be the acceleration values for the z axis."
      ),
      id = moover_prompt(
        "Column containing id",
        id_default,
        details = "This should identify the animal or accelerometer for each row. If each file contains only one animal and you want moover to use the filename instead, you can leave this blank."
      ),
      id_type = moover_prompt(
        "Does the id column contain 'id' or 'accelerometer' values",
        "id",
        details = "Choose 'id' if the column already contains the animal identifier you want in the outputs. Choose 'accelerometer' if the column contains logger IDs that need to be linked through the tech file."
      ),
      time_format = moover_prompt(
        "Timestamp format (unix_ms, unix_s, iso8601_utc, iso8601_local)",
        "unix_ms",
        details = "This tells moover how to interpret the time column so it can convert everything to a standard UTC milliseconds format internally."
      )
    )
  )
}

moover_wizard_show_workspace <- function(workspace) {
  moover_wizard_text("Workspace ready. moover will use these folders:")
  moover_wizard_bullet(paste0("Raw data folder: ", workspace$data_raw))
  moover_wizard_bullet(paste0("Run outputs: ", workspace$runs))
  moover_wizard_bullet(paste0("Internal helper files: ", workspace$internal))
  cat("\n")
}

moover_wizard_show_saved_spec <- function(spec) {
  spec_path <- moover_spec_path_default(spec)
  moover_wizard_text("I have saved the run instructions for this wizard.")
  moover_wizard_bullet(paste0("Saved instructions: ", spec_path))
  moover_wizard_text("You do not need to edit this JSON file by hand. moover keeps it so the same run can be repeated later without answering the same questions again.")
}

moover_wizard_show_pipeline_steps <- function(include_optimise = FALSE, mode = c("train", "predict", "import")) {
  mode <- match.arg(mode)
  moover_wizard_text("If you continue, moover will do the following:")
  if (identical(mode, "import")) {
    moover_wizard_bullet("Read your raw accelerometer files.")
    moover_wizard_bullet("Convert them into the standard 5-column format: id, t_unix_ms, x, y, z.")
    moover_wizard_bullet("Save a preview and a summary so you can check that the import looks correct.")
  } else if (identical(mode, "train")) {
    moover_wizard_bullet("Read your raw accelerometer files and convert them into the standard internal format.")
    moover_wizard_bullet("Build fixed time blocks and calculate behaviour features for each block.")
    moover_wizard_bullet("Match your observations to those fixed time blocks so the model has labels to learn from.")
    if (isTRUE(include_optimise)) {
      moover_wizard_bullet("Try multiple model candidates and compare their size and performance.")
    }
    moover_wizard_bullet("Train and validate the final Random Forest model.")
    moover_wizard_bullet("Write an export folder containing the model, metrics, feature specification, and test vectors.")
  } else if (identical(mode, "predict")) {
    moover_wizard_bullet("Read your new raw accelerometer files and convert them into the standard internal format.")
    moover_wizard_bullet("Build the exact same features expected by the existing model bundle.")
    moover_wizard_bullet("Generate epoch-level behaviour predictions and save them into the run results folder.")
  }
  cat("\n")
}

#' Guided Import Wizard
#'
#' Interactively builds a simple import spec, previews the canonicalised data,
#' and writes the run spec into the current workspace.
#'
#' @return A `moover_spec` object.
#' @export
wizard_import <- function() {
  moover_wizard_title(
    "moover import wizard",
    intro = "This wizard helps you bring raw accelerometer files into moover. We will choose a workspace, describe the input files, save the run instructions, and then convert the data into moover's standard 5-column format."
  )

  moover_wizard_section(
    "Step 1. Choose a Workspace",
    what = "We need one folder where moover can keep your raw files, your outputs, and the saved instructions for this run.",
    why = "A consistent workspace structure makes it much easier for beginners to find their files later."
  )
  root <- moover_prompt(
    "Workspace root",
    getwd(),
    details = "Using the current working directory is usually fine. moover will create data_raw, runs, and _internal inside this folder if they do not already exist."
  )
  workspace <- init_workspace(root)
  moover_wizard_show_workspace(workspace)

  raw_format <- moover_choose_raw_format()

  moover_wizard_section(
    "Step 2. Point moover to Your Raw Files",
    what = "Now we need the folder that contains the raw accelerometer files you want to import.",
    why = "moover reads the files directly from this folder and keeps the original files unchanged."
  )
  raw_dir <- moover_prompt(
    "Raw data directory",
    file.path(root, "data_raw"),
    details = if (identical(raw_format, "cqu")) {
      "This folder should contain your CQU-style accelerometer files."
    } else {
      "This folder should contain the CSV or TSV files that you want moover to inspect and import."
    }
  )
  ingest <- list(format = raw_format, raw_dir = raw_dir)
  schema <- if (identical(raw_format, "generic")) moover_prompt_generic_schema(raw_dir) else list()

  moover_wizard_section(
    "Step 3. Save the Run Instructions",
    what = "Before we import anything, moover will save a small instruction file for this run.",
    why = "This makes the import reproducible, and it means you do not have to remember every setting later."
  )
  spec <- create_spec(
    workspace = list(root = root),
    ingest = ingest,
    schema = schema
  )
  moover_write_spec(spec)
  moover_wizard_show_saved_spec(spec)

  moover_wizard_section(
    "Step 4. Run the Import",
    what = "moover is ready to read the raw files and convert them into the standard internal format.",
    why = "This is the foundation for everything else in the package, including feature building, model training, and prediction."
  )
  moover_wizard_show_pipeline_steps(mode = "import")
  result <- import_accel(spec)
  moover_wizard_text("Import complete. Here is what moover created:")
  moover_wizard_bullet(paste0("Rows imported: ", format(result$summary$n_rows, big.mark = ",", scientific = FALSE, trim = TRUE)))
  moover_wizard_bullet(paste0("Animals found: ", result$summary$n_ids))
  moover_wizard_bullet(paste0("Preview file: ", result$preview_file))
  moover_wizard_bullet(paste0("Canonical accelerometer file: ", result$canonical_accel_file))
  moover_wizard_text("What success looks like: the preview file should show the standard columns id, t_unix_ms, x, y, and z. If those look sensible, you are ready to move on to feature building or model training.")

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
  moover_wizard_title(
    "moover training wizard",
    intro = "This wizard helps you build a behaviour model from raw accelerometer files and observation labels. We will work through the inputs step by step, save the run instructions, and optionally start the full training workflow for you."
  )

  moover_wizard_section(
    "Step 1. Choose a Workspace",
    what = "We need one folder where moover can store the raw files, the run outputs, and the model export.",
    why = "Keeping everything in one predictable place makes it much easier to revisit a model later or share a run with colleagues."
  )
  root <- moover_prompt(
    "Workspace root",
    getwd(),
    details = "moover will create data_raw, runs, and _internal inside this folder if they do not already exist."
  )
  workspace <- init_workspace(root)
  moover_wizard_show_workspace(workspace)

  raw_format <- moover_choose_raw_format()

  moover_wizard_section(
    "Step 2. Point moover to Your Training Files",
    what = "We need the folder containing your raw accelerometer files, plus the tech file and observation file used for training.",
    why = "The raw data tells moover how the animals moved, while the observations tell moover which behaviour was happening during each labelled period."
  )
  raw_dir <- moover_prompt(
    "Raw data directory",
    file.path(root, "data_raw"),
    details = "This is the folder containing the accelerometer files that match your labelled observations."
  )
  schema <- if (identical(raw_format, "generic")) moover_prompt_generic_schema(raw_dir) else list()
  tech_file <- moover_prompt(
    "Tech file",
    file.path(root, "tech.csv"),
    details = "The tech file links animal identifiers to accelerometer identifiers when you need that mapping."
  )
  obs_file <- moover_prompt(
    "Observation file",
    file.path(root, "observations.csv"),
    details = "The observation file should contain one row per labelled behaviour period, including the animal id, behaviour label, and start and end time."
  )

  moover_wizard_section(
    "Step 3. Decide Whether to Optimise the Model",
    what = "You can either train a model directly using the current default feature set, or ask moover to compare multiple model candidates first.",
    why = "Optimisation is helpful when you care about model size, memory use, or embedded deployment."
  )
  do_optimise <- moover_wizard_yes_no(
    "Optimise for embedded deployment before training",
    default = TRUE,
    details = "Choose yes if you want moover to compare candidate models and help you trade off model size and performance. Choose no if you simply want to train the default model more quickly."
  )
  feature_mode <- if (do_optimise) "all" else "standard"

  moover_wizard_section(
    "Step 4. Choose the Behaviour of Interest",
    what = "The current beginner workflow uses a binary Random Forest model, so moover needs to know which behaviour should be treated as the positive class.",
    why = "This makes the metrics and probability outputs easier to interpret for the behaviour you care most about."
  )
  positive_class <- moover_prompt(
    "Positive class label",
    "grazing",
    details = "For example, if you want the model to separate grazing from not grazing, enter 'grazing'."
  )

  moover_wizard_section(
    "Step 5. Save the Run Instructions",
    what = "moover will now save the settings you have chosen so far.",
    why = "Saving the instructions now means you can rerun the same workflow later without walking through the wizard again."
  )
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(
      format = raw_format,
      raw_dir = raw_dir
    ),
    schema = schema,
    labels = list(
      tech_file = tech_file,
      path = obs_file
    ),
    features = list(
      selection = feature_mode,
      standard_set = "manual5"
    ),
    optimise = list(
      enabled = do_optimise
    ),
    model = list(
      positive_class = positive_class
    )
  )
  moover_write_spec(spec)
  moover_wizard_show_saved_spec(spec)

  moover_wizard_section(
    "Step 6. Decide Whether to Start the Full Training Run Now",
    what = "You can stop after creating the saved instructions, or you can ask moover to begin the full training workflow immediately.",
    why = "This gives beginners a chance to pause and check their files before committing to a longer run."
  )
  moover_wizard_show_pipeline_steps(include_optimise = do_optimise, mode = "train")
  if (moover_wizard_yes_no(
    "Run the full training workflow now",
    default = TRUE,
    details = "Choose yes if you are happy with the file paths and settings above. Larger datasets can still take time on a normal computer, and that is expected."
  )) {
    export_dir <- run_pipeline(spec, stage = "all")
    moover_wizard_text("Training complete. moover has written a full export bundle for this run.")
    moover_wizard_bullet(paste0("Export folder: ", export_dir))
    moover_wizard_bullet(paste0("Run folder: ", moover_run_paths(spec)$run_root))
    moover_wizard_text("What success looks like: your export folder should contain the fitted model, feature manifest, metrics, and test vectors. You can now share that folder or use it for prediction on new data.")
  } else {
    moover_wizard_text("No problem. The saved instructions are already on disk, so you can rerun this same training workflow later with run_pipeline().")
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
  moover_wizard_title(
    "moover prediction wizard",
    intro = "This wizard helps you apply an existing moover model bundle to new accelerometer data. We will choose the model bundle, describe the new raw files, save the run instructions, and optionally generate predictions straight away."
  )

  moover_wizard_section(
    "Step 1. Choose a Workspace",
    what = "We need one folder where moover can store the prediction run and any output tables it creates.",
    why = "Keeping prediction outputs in a workspace makes them easy to revisit and share."
  )
  root <- moover_prompt(
    "Workspace root",
    getwd(),
    details = "moover will create data_raw, runs, and _internal inside this folder if they do not already exist."
  )
  workspace <- init_workspace(root)
  moover_wizard_show_workspace(workspace)

  moover_wizard_section(
    "Step 2. Choose the Existing Model Bundle",
    what = "Now we need the exported model folder that you want to apply to new data.",
    why = "The bundle contains the fitted model, the feature list, and the settings needed to reproduce the same feature engineering during prediction."
  )
  bundle_path <- moover_prompt(
    "Model bundle directory",
    details = "Point this to the export folder that contains files such as rf_model_full.rds and feature_manifest.csv."
  )

  raw_format <- moover_choose_raw_format()

  moover_wizard_section(
    "Step 3. Point moover to the New Raw Files",
    what = "We need the folder containing the new accelerometer files you want to classify.",
    why = "moover will read these files, build the same features used by the model, and then generate epoch-level predictions."
  )
  raw_dir <- moover_prompt(
    "Raw data directory",
    file.path(root, "data_raw"),
    details = "This folder should contain the new accelerometer files you want to classify."
  )
  schema <- if (identical(raw_format, "generic")) moover_prompt_generic_schema(raw_dir) else list()
  tech_file <- moover_prompt(
    "Tech file (optional)",
    file.path(root, "tech.csv"),
    details = "If your raw data already uses the animal id you want in the output, this file may not be needed. It is mainly used when accelerometer ids need to be linked back to animal ids."
  )

  moover_wizard_section(
    "Step 4. Choose Optional Summaries",
    what = "The main output will always be epoch-level predictions. You can also ask moover to calculate hourly summaries.",
    why = "Some users want a simple proportion-of-time summary rather than working only with epoch-level rows."
  )
  summary_outputs <- if (moover_wizard_yes_no(
    "Also write hourly summaries",
    FALSE,
    details = "Choose yes if you would like an additional file summarising the predicted proportion of time spent in each behaviour for each hour."
  )) "hourly" else character()

  moover_wizard_section(
    "Step 5. Save the Run Instructions",
    what = "moover will now save the settings for this prediction run.",
    why = "This makes it easy to rerun the exact same prediction workflow later on."
  )
  spec <- create_spec(
    workspace = list(root = root),
    ingest = list(
      format = raw_format,
      raw_dir = raw_dir
    ),
    schema = schema,
    labels = list(
      tech_file = tech_file,
      path = NULL
    ),
    predict = list(
      model_bundle = bundle_path,
      summary_outputs = summary_outputs
    )
  )
  moover_write_spec(spec)
  moover_wizard_show_saved_spec(spec)

  moover_wizard_section(
    "Step 6. Decide Whether to Run Prediction Now",
    what = "You can stop here with a saved set of instructions, or ask moover to run the prediction immediately.",
    why = "This gives you a chance to check the model bundle path and raw data folder before starting."
  )
  moover_wizard_show_pipeline_steps(mode = "predict")
  if (moover_wizard_yes_no(
    "Run prediction now",
    default = TRUE,
    details = "Choose yes if the model bundle path and raw data folder above look correct."
  )) {
    pred <- run_pipeline(spec, stage = "predict")
    run_paths <- moover_run_paths(spec)
    moover_wizard_text("Prediction complete. moover has written the prediction outputs for this run.")
    moover_wizard_bullet(paste0("Epoch predictions: ", file.path(run_paths$results_dir, "epoch_predictions.csv")))
    moover_wizard_bullet(paste0("Predicted epochs: ", format(nrow(pred), big.mark = ",", scientific = FALSE, trim = TRUE)))
    if ("hourly" %in% summary_outputs) {
      moover_wizard_bullet(paste0("Hourly summary: ", file.path(run_paths$results_dir, "hourly_summary.csv")))
    }
    moover_wizard_text("What success looks like: the epoch_predictions.csv file should contain one row per fixed time block with a predicted behaviour and class probabilities.")
  } else {
    moover_wizard_text("No problem. The saved instructions are already on disk, so you can rerun this prediction workflow later with run_pipeline().")
  }

  spec
}
