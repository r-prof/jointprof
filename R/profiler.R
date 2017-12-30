.my_env <- new.env(parent = emptyenv())

#' Starts and stops profiling
#'
#' `start_profiler()` initiates profiling. It is a replacement for [Rprof()]
#' that will include native stack traces where available.
#'
#' @details
#' Set the `keep.source` and `keep.source.pkgs` options to `TRUE` (via
#' [option()]) before installing packages from source or running code to obtain
#' accurate locations in your stack traces. It is a good idea to set these
#' options in your [.Rprofile] file.
#'
#' Use the \pkg{profile} package to read the data or save the output in `pprof`
#' format for further processing.
#'
#' @param path Path to the output file.
#'
#' @export
#' @examples
#' \dontrun{
#' start_profiler("Rprof.out")
#' # code to be profiled
#' stop_profiler()
#'
#' profile::read_rprof("Rprof.out")
#' }
start_profiler <- function(path = "Rprof.out") {
  stop_if_not_linux()

  # Make sure pprof is available, it will be needed later
  get_pprof_path()

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
#' `Rprof()`-compatible file given specified by the `path` argument.
#'
#' @export
#' @value `stop_profiler()` returns the profiling data like it would have
#'   been read by [profile::read_rprof()].
#' @rdname start_profiler
stop_profiler <- function() {
  stop_if_not_linux()

  on.exit(rm(list = ls(.my_env), pos = .my_env), add = TRUE)

  utils::Rprof(NULL)
  stop_profiler_impl(.my_env$prof_data)

  ds <- combine_profiles(.my_env$pprof_path, .my_env$rprof_path)
  profile::write_rprof(ds, .my_env$path)
  invisible(ds)
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
