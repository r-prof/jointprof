.my_env <- new.env(parent = emptyenv())

#' @export
start_profiler <- function(path = "1.prof") {
  Rprof(filename = paste0(path, ".out"), line.profiling = TRUE)
  .my_env$prof_data <- start_profiler_impl(path)
}

#' @export
stop_profiler <- function() {
  on.exit(.my_env$prof_data <- NULL, add = TRUE)
  stop_profiler_impl(.my_env$prof_data)
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
