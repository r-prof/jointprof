#' Find the pprof utility
#'
#' `pprof` is a tool for visualization and analysis of profiling data,
#' implemented in Go.
#' The `find_pprof()` function is a wrapper around `Sys.which()`.
#' It fails if no `pprof` executable can be found.
#'
#' @section Installation:
#' Use the instructions on `pprof`'s
#' [GitHub page](https://github.com/google/pprof#building-pprof)
#' to install it.  Make sure the `pprof` executable is on your system path.
#' @export
find_pprof <- function() {
  path <- unname(Sys.which("pprof"))
  if (path == "") {
    stop("Can't find pprof on your system path.", call. = FALSE)
  }

  path
}
