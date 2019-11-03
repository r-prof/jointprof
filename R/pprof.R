#' Find the pprof utility
#'
#' @description
#' `pprof` is a tool for visualization and analysis of profiling data,
#' implemented in Go.
#' The `find_pprof()` function looks for the `pprof` executable
#' in the `bin` subdirectory of the `GOPATH`
#' (by default `~/go`, can be overridden by setting the `GOPATH`
#' environment variable).
#' It fails if no `pprof` executable can be found.
#'
#' This function will be called by [start_profiler()] to ensure
#' that profiling data can be processed by [stop_profiler()].
#' A functioning installation of `pprof` is a prerequisite to use
#' this package.
#'
#' @section Installation:
#'
#' 1. Install Go 1.7 or newer (if necessary).
#'
#' 1. Install `pprof` into your `GOPATH`:
#'
#'     ```
#'     go get github.com/google/pprof
#'     ```
#'
#' See also the instructions on `pprof`'s
#' [GitHub page](https://github.com/google/pprof#building-pprof).
#'
#'
#' @export
find_pprof <- function() {
  gopath <- get_gopath()
  path <- file.path(gopath, "bin", "pprof")
  if (!file.exists(path)) {
    stop("Can't find pprof on your `GOPATH`. See `?find_pprof` for installation instructions.", call. = FALSE)
  }
  if (file.access(path, 1) != 0) {
    stop("File ", path, " must have executable bit set. See `?find_pprof` for installation instructions.", call. = FALSE)
  }

  path
}

.gopath_env <- new.env(parent = emptyenv())

get_gopath <- function() {
  if (is.null(.gopath_env$gopath)) {
    if (nchar(Sys.which("go")) == 0) {
      stop("The 'go' compiler tools must be installed. See `?find_pprof` for installation instructions.", call. = FALSE)
    }
    gopath <- system2("go", c("env", "GOPATH"), stdout = TRUE)
    if (!dir.exists(gopath)) {
      stop("`GOPATH` does not yet exist. See `?find_pprof` for installation instructions.", call. = FALSE)
    }
    .gopath_env$gopath <- gopath
  }

  .gopath_env$gopath
}
