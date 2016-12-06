#' @export
start_profiler <- function(path = "1.prof") {
  Rprof(filename = paste0(path, ".out"), line.profiling = TRUE)
  start_profiler_impl(path)
}

#' @export
stop_profiler <- function() {
  stop_profiler_impl()
  Rprof(NULL)
}

#' @export
show_profiler_pdf <- function(path = "1.prof", focus = NULL) {
  pprof_exit_code <- system2(
    "google-pprof",
    c("--lines", "--evince", shQuote(file.path(R.home("bin"), "exec/R")),
      if (!is.null(focus)) paste0("--focus=", focus),
      shQuote(path)),
    wait = FALSE)
}
