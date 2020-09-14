#' Find the pprof utility
#'
#' @description
#' `pprof` is a tool for visualization and analysis of profiling data,
#' implemented in Go.
#' This function is a wrapper around [proffer::find_pprof()]
#' for determining its location on your system.
#'
#' This function will be called by [start_profiler()] to ensure
#' that profiling data can be processed by [stop_profiler()].
#' A functioning installation of `pprof` is a prerequisite to use
#' this package.
#'
#' @export
find_pprof <- function() {
  path <- proffer::pprof_path()
  if (!file.exists(path)) {
    stop("Can't find `pprof`. See `?proffer::pprof_path` for installation instructions.", call. = FALSE)
  }
  path
}
