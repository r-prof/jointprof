.my_env <- new.env(parent = emptyenv())

#' Starts and stops profiling
#'
#' `start_profiler()` initiates profiling.
#'
#' @param path Path to the output file. Other files based on this path
#'   may be created.
#'
#' @export
start_profiler <- function(path = "1.out") {
  pprof_path <- tempfile("gprofiler", fileext = ".prof")
  rprof_path <- tempfile("gprofiler", fileext = ".out")
  message("Temporary files: ", pprof_path, ", ", rprof_path)

  prof_data <- init_profiler_impl()
  utils::Rprof(filename = rprof_path, line.profiling = TRUE, gc.profiling = TRUE)
  start_profiler_impl(prof_data, pprof_path)
  .my_env$prof_data <- prof_data
  .my_env$path <- path
  .my_env$pprof_path <- pprof_path
  .my_env$rprof_path <- rprof_path
}

#' `stop_profiler()` terminates profiling. The results are available with
#' [get_profiler_traces()].
#'
#' @export
#' @rdname start_profiler
stop_profiler <- function() {
  on.exit(rm(list = ls(.my_env), pos = .my_env), add = TRUE)

  utils::Rprof(NULL)
  stop_profiler_impl(.my_env$prof_data)

  combine_profiles(.my_env$path, .my_env$pprof_path, .my_env$rprof_path)
  file.copy(.my_env$pprof_path, paste0(.my_env$path, ".prof"), overwrite = TRUE)
  invisible(NULL)
}

#' Parse profiler output
#'
#' Combines the profiler output obtained from [start_profiler()] into
#' a nested tibble.
#'
#' @param path The path to the profiler output.
#' @importFrom tidyr %>%
#' @export
get_profiler_traces <- function(path = "1.out") {
  rprof_path <- path
  pprof_path <- paste0(path, ".prof")

  traces <- system2(
    get_pprof_path(),
    c("-unit", "us", "-lines", "-traces", shQuote(pprof_path)),
    stdout = TRUE)

  pprof_nested <-
    strsplit(paste(traces, collapse = "\n"), "\n-+[+]-+\n?")[[1L]][-1L] %>%
    tibble::enframe(name = "index", value = "gprofiler") %>%
    dplyr::mutate(count = as.numeric(sub("^ +([0-9]+).*$", "\\1", gprofiler)) / 10000) %>%
    dplyr::slice(., rep(seq_len(nrow(.)), count)) %>%
    dplyr::transmute(time = seq_along(gprofiler), gprofiler = parse_pprof(gprofiler))

  rprof_nested <-
    profvis:::parse_rprof(rprof_path)$prof %>%
    tibble::as_tibble() %>%
    tidyr::nest(-time, .key = rprof)

  stopifnot(pprof_nested$time == rprof_nested$time)
  tibble::as_tibble(cbind(pprof_nested, rprof_nested[-1]))
}

parse_pprof <- function(output) {
  lapply(output, parse_pprof_one)
}

parse_pprof_one <- function(output_item) {
  output_lines <- strsplit(output_item, "\n", fixed = TRUE)[[1]]
  rx <- "^(?:| *[0-9][^ ]+) +(?:[?][?]|[<]unknown[>]|(.+) +(?:[?][?]|([^ ]+):([0-9]+)))$"
  invalid <- grep(rx, output_lines, invert = TRUE)
  if (length(invalid) > 0) {
    stop(
      "Unexpected profiler output:\n",
      paste0(format(invalid), ": ", output_lines[invalid]),
      call. = FALSE
    )
  }

  tibble::tibble(
    label = empty_to_na(gsub(rx, "\\1", output_lines)),
    filename = empty_to_na(gsub(rx, "\\2", output_lines)),
    line = empty_to_na(gsub(rx, "\\3", output_lines))
  )
}

empty_to_na <- function(x) {
  x[x == ""] <- NA_character_
  x
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
