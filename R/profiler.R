.my_env <- new.env(parent = emptyenv())

#' Starts and stops profiling
#'
#' `start_profiler()` initiates profiling.
#'
#' @param path Path to the output file. Other files based on this path
#'   may be created.
#'
#' @export
start_profiler <- function(path = "1.prof") {
  prof_data <- init_profiler_impl()
  utils::Rprof(filename = paste0(path, ".out"), line.profiling = TRUE)
  start_profiler_impl(prof_data, path)
  .my_env$prof_data <- prof_data
}

#' `stop_profiler()` terminates profiling. The results are available with
#' [get_profiler_traces()].
#'
#' @export
#' @rdname start_profiler
stop_profiler <- function() {
  on.exit(.my_env$prof_data <- NULL, add = TRUE)

  utils::Rprof(NULL)
  stop_profiler_impl(.my_env$prof_data)
}

#' Parse profiler output
#'
#' Combines the profiler output obtained from [start_profiler()] into
#' a nested tibble.
#'
#' @param path The path to the profiler output.
#' @importFrom tidyr %>%
#' @export
get_profiler_traces <- function(path = "1.prof") {
  traces <- system2(
    get_pprof_path(),
    c("-unit", "us", "-lines", "-traces", shQuote(path)),
    stdout = TRUE)

  pprof_nested <-
    strsplit(paste(traces, collapse = "\n"), "\n-+[+]-+\n")[[1L]][-1L] %>%
    tibble::enframe(name = "index", value = "gprofiler") %>%
    dplyr::mutate(count = as.numeric(sub("^ +([0-9]+).*$", "\\1", gprofiler)) / 10000) %>%
    dplyr::slice(., rep(seq_len(nrow(.)), count)) %>%
    dplyr::transmute(time = seq_along(gprofiler), gprofiler = as.list(gprofiler))

  rprof_nested <- profvis:::parse_rprof(paste0(path, ".out"))$prof %>%
    tibble::as_tibble() %>%
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
