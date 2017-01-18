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

#' @importFrom tidyr %>%
#' @export
get_profiler_traces <- function(path = "1.prof") {
  traces <- system2(
    get_pprof_path(),
    c("-lines", "-traces", shQuote(path)),
    stdout = TRUE)

  pprof_nested <-
    strsplit(paste(traces, collapse = "\n"), "\n-+[+]-+\n")[[1L]][-1L] %>%
    as.list %>%
    tibble::enframe(name = "time", value = "gprofiler")

  rprof_nested <- profvis:::parse_rprof(paste0(path, ".out"))$prof %>%
    tibble::as_tibble %>%
    tidyr::nest(-time, .key = rprof)

  stopifnot(pprof_nested$time == rprof_nested$time)
  tibble::as_tibble(cbind(pprof_nested, rprof_nested[-1]))
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
