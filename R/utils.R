`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

moover_ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

moover_normalize_path <- function(path, base = getwd(), must_work = FALSE) {
  if (is.null(path) || !nzchar(path)) {
    stop("Path must be a non-empty string.")
  }
  if (!grepl("^[A-Za-z]:|^/|^\\\\\\\\", path)) {
    path <- file.path(base, path)
  }
  normalizePath(path, winslash = "/", mustWork = must_work)
}

moover_timestamp_run_id <- function() {
  format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
}

moover_write_json <- function(x, path) {
  if (inherits(x, c("moover_spec", "moover_workspace", "moover_model_bundle"))) {
    x <- unclass(x)
  }
  jsonlite::write_json(
    x = x,
    path = path,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )
  invisible(path)
}

moover_deep_merge <- function(base, updates) {
  if (length(updates) == 0L) return(base)
  out <- base
  for (nm in names(updates)) {
    if (is.list(base[[nm]]) && is.list(updates[[nm]]) &&
        !is.data.frame(base[[nm]]) && !is.data.frame(updates[[nm]])) {
      out[[nm]] <- moover_deep_merge(base[[nm]], updates[[nm]])
    } else {
      out[[nm]] <- updates[[nm]]
    }
  }
  out
}

moover_preview_head <- function(dt, n = 10L) {
  data.table::as.data.table(utils::head(dt, n))
}

moover_parse_time_to_unix_ms <- function(x, time_format = "iso8601_utc",
                                         tz_local = "Australia/Brisbane") {
  x <- as.character(x)
  if (identical(time_format, "unix_ms")) {
    return(as.numeric(x))
  }
  if (identical(time_format, "unix_s")) {
    return(as.numeric(x) * 1000)
  }
  if (identical(time_format, "iso8601_utc")) {
    parsed <- suppressWarnings(lubridate::ymd_hms(gsub("T", " ", sub("Z$", "", x)), tz = "UTC", quiet = TRUE))
    return(as.numeric(parsed) * 1000)
  }
  if (identical(time_format, "iso8601_local")) {
    parsed <- suppressWarnings(lubridate::ymd_hms(gsub("T", " ", x), tz = tz_local, quiet = TRUE))
    return(as.numeric(lubridate::with_tz(parsed, tzone = "UTC")) * 1000)
  }
  stop("Unsupported time_format: ", time_format)
}

moover_unix_ms_to_iso_utc <- function(x) {
  format(
    as.POSIXct(as.numeric(x) / 1000, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%dT%H:%M:%OS3Z",
    tz = "UTC"
  )
}

moover_parse_yes_no <- function(prompt, default = TRUE) {
  suffix <- if (isTRUE(default)) " [Y/n]: " else " [y/N]: "
  ans <- trimws(readline(paste0(prompt, suffix)))
  if (!nzchar(ans)) return(isTRUE(default))
  tolower(substr(ans, 1, 1)) == "y"
}

moover_console_rule <- function(char = "=", width = 78L) {
  cat(paste(rep(char, width), collapse = ""), "\n", sep = "")
}

moover_console_wrap <- function(text, indent = 0L, width = 78L) {
  text <- paste(text, collapse = " ")
  wrapped <- strwrap(text, width = max(40L, width - indent))
  prefix <- if (indent > 0L) paste(rep(" ", indent), collapse = "") else ""
  paste0(prefix, wrapped, collapse = "\n")
}

moover_console_text <- function(..., indent = 0L, blank_after = TRUE) {
  text <- paste(..., collapse = "")
  cat(moover_console_wrap(text, indent = indent), "\n", sep = "")
  if (isTRUE(blank_after)) cat("\n")
}

moover_console_bullet <- function(...) {
  text <- paste(..., collapse = "")
  wrapped <- strwrap(text, width = 74L, exdent = 2L)
  if (length(wrapped) == 0L) return(invisible(NULL))
  cat("- ", wrapped[[1]], "\n", sep = "")
  if (length(wrapped) > 1L) {
    cat(paste0("  ", wrapped[-1L], collapse = "\n"), "\n", sep = "")
  }
  invisible(NULL)
}

moover_console_header <- function(title, intro = NULL) {
  cat("\n")
  moover_console_rule("=")
  cat(title, "\n", sep = "")
  moover_console_rule("=")
  if (!is.null(intro)) {
    moover_console_text(intro)
  }
}

moover_console_step <- function(step_no, title, detail = NULL) {
  cat(sprintf("Step %s. %s\n", step_no, title))
  moover_console_rule("-", width = max(20L, min(78L, nchar(sprintf("Step %s. %s", step_no, title)))))
  if (!is.null(detail)) {
    moover_console_text("What moover is doing: ", detail)
  }
}
