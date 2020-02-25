#' Profile an expression and show in pprof
#'
#' Profiles an expression with [start_profiler()] and [stop_profiler()]
#' and visualizes results with [proffer::serve_pprof()].
#' Drop-in replacement for [proffer::pprof()] and [profvis::profvis()].
#'
#' @param expr Expression to profile.
#' @param ... Passed on to [proffer::serve_pprof()].
#'
#' @export
# FIXME: Examples
joint_pprof <- function(expr, ...) {
  pprof <- comingle_pprof(expr)
  proffer::serve_pprof(pprof, ...)
}
