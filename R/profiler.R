.my_env <- new.env(parent = emptyenv())

#' Start and stop profiling
#'
#' `start_profiler()` initiates profiling. It is a replacement for [Rprof()]
#' that will include native stack traces where available. Internally, `Rprof()`
#' is used to capture R call stacks.
#'
#' @details
#' Profiling requires the `pprof` tool, which can be made available by
#' installing the \pkg{pprof} package (recommended) or by running
#' `go get github.com/google/pprof` and adding `${GOPATH}/bin` to the `PATH`.
#'
#' Set the `keep.source` and `keep.source.pkgs` options to `TRUE` (via
#' [option()]) before installing packages from source or running code to obtain
#' accurate locations in your stack traces. It is a good idea to set these
#' options in your [.Rprofile] file.
#'
#' Use the \pkg{profile} package to read the data or save the output in `pprof`
#' format for further processing.
#'
#' @param path Path to the output file.
#' @param ... Ignored, for extensibility.
#' @param numfiles,bufsize Passed on to `Rprof()` call.
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
start_profiler <- function(path = "Rprof.out", ..., numfiles = 100L, bufsize = 10000L) {
  stop_if_not_linux()

  # Make sure pprof is available, it will be needed later
  find_pprof()

  pprof_path <- tempfile("jointprof", fileext = ".prof")
  rprof_path <- tempfile("jointprof", fileext = ".out")
  message("Temporary files: ", pprof_path, ", ", rprof_path)

  prof_data <- init_profiler_impl()
  utils::Rprof(
    filename = rprof_path,
    line.profiling = TRUE,
    gc.profiling = TRUE,
    numfiles = numfiles,
    bufsize = bufsize
  )
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
#' @return `stop_profiler()` returns the profiling data like it would have
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
  if (!(tolower(Sys.info()[["sysname"]]) %in% c("linux", "darwin"))) {
    abort("This function is only supported on Linux or OS X")
  }
}
