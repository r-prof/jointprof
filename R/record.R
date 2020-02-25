#' @title Profile R and native code and record pprof samples.
#' @noRd
#' @description Run R code and record pprof samples
#'   from both R's and the native tracebacks.
#'   This function uses [start_profiler()] and [stop_profiler()]
#'   to initiate and stop the data collection.
#' @return Path to a file with pprof samples.
#' @inheritParams comingle_rprof
#' @param pprof Path to a file with pprof samples.
#'   Also returned from the function.
#' @examples
#' # Returns a path to pprof samples.
#' comingle_pprof(replicate(1e2, sample.int(1e4)))
comingle_pprof <- function(expr, pprof = tempfile(), ...) {
  rprof <- comingle_rprof(expr, ...)
  on.exit(unlink(rprof))
  proffer::to_pprof(rprof, pprof = pprof)
}

#' @title Profile R code and record Rprof samples.
#' @noRd
#' @description Run R code and record Rprof samples
#'   from both R's and the native tracebacks.
#'   This function uses [start_profiler()] and [stop_profiler()]
#'   to initiate and stop the data collection.
#' @return Path to a file with Rprof samples.
#' @param expr An R expression to profile.
#' @param rprof Path to a file with Rprof samples.
#'   Also returned from the function.
#' @param ... Passed on to `start_profiler()`.
#' @examples
#' # Returns a path to Rprof samples.
#' comingle_rprof(replicate(1e2, sample.int(1e4)))
comingle_rprof <- function(expr, rprof = tempfile(), ...) {
  on.exit(stop_profiler())
  start_profiler(path = rprof, ...)
  expr
  rprof
}
