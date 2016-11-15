#' @export
start_profiler <- function(path) {
  start_profiler_impl(path)
}

#' @export
stop_profiler <- function() {
  stop_profiler_impl()
}
