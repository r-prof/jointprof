.my_env <- new.env(parent = emptyenv())

#' Starts and stops profiling
#'
#' `start_profiler()` initiates profiling.
#'
#' @param path Path to the output file. Other files based on this path
#'   may be created.
#'
#' @export
start_profiler <- function(path = "Rprof.out") {
  stop_if_not_linux()

  pprof_path <- tempfile("gprofiler", fileext = ".prof")
  rprof_path <- tempfile("gprofiler", fileext = ".out")
  message("Temporary files: ", pprof_path, ", ", rprof_path)

  prof_data <- init_profiler_impl()
  utils::Rprof(filename = rprof_path, line.profiling = TRUE, gc.profiling = TRUE)
  start_profiler_impl(prof_data, pprof_path)
  .my_env$prof_data <- prof_data
  .my_env$path <- path
  .my_env$pprof_path <- pprof_path
  .my_env$rprof_path <- rprof_path
}

#' `stop_profiler()` terminates profiling. The results are written to the
#' Rprof-compatible file given specified by the `path` argument.
#'
#' @export
#' @rdname start_profiler
stop_profiler <- function() {
  stop_if_not_linux()

  on.exit(rm(list = ls(.my_env), pos = .my_env), add = TRUE)

  utils::Rprof(NULL)
  stop_profiler_impl(.my_env$prof_data)

  combine_profiles(.my_env$path, .my_env$pprof_path, .my_env$rprof_path)
  file.copy(.my_env$pprof_path, paste0(.my_env$path, ".prof"), overwrite = TRUE)
  invisible(NULL)
}

stop_if_not_linux <- function() {
  if (tolower(Sys.info()[["sysname"]]) != "linux") {
    abort("This function is only supported on Linux")
  }
}

#' @export
show_profiler_pdf <- function(path = "1.prof", focus = NULL) {
  pprof_exit_code <- system2(
    get_pprof_path(),
    c("-lines", "-evince", if (!is.null(focus)) paste0("-focus=", focus),
      shQuote(path)),
    wait = FALSE)
  if (pprof_exit_code != 0) {
    warning("pprof exited with ", pprof_exit_code)
  }
}

get_pprof_path <- function() {
  system.file("bin", "pprof", package = utils::packageName())
}
