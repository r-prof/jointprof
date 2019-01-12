#' @title Visualize profile data with `pprof`.
#' @export
#' @description
#' [`pprof`](https://github.com/google/pprof)
#' is a tool for visualization and analysis of profile data,
#' implemented in Go. See <https://r-prof.github.io/jointprof>
#' for installation instructions.
#'
#' The `vis_pprof()` function launches a local web server
#' to display profile data interactively.
#'
#' @param path Character, path to a profile data file in
#'   [`pprof`](https://github.com/google/pprof) format.
#'   Convert between formats using the
#'   [`profile`](https://github.com/r-prof/profile) package.
#'
#' @param host Character, IP address or complete hostname.
#'   Determines which computers can connect to the
#'   local [`pprof`](https://github.com/google/pprof) web server.
#'   In most cases, the default `"localhost"` is fine.
#'   To allow remote connections from other computers, use `"0.0.0.0"`.
#'
#' @param port Character, port number to host the interactive displays.
#'   If `NULL` (default) a random port between 49152 and 65355 is
#'   selected uniformly at random.
#'
#'   A port number is a number between 0 and 65535 to identify a service
#'   running on a computer. Ports 49152 to 65355 tend to be
#'   more available than 1024 to 49151. Avoid ports 0 to 1023.
#'
#' @examples
#' \dontrun{
#' # Collect profile data.
#' target_file <- tempfile()
#' Rprof(target_file) # or start_profiler(target_file)
#' replicate(100, sessionInfo())
#' Rprof(NULL) # or stop_profiler()
#'
#' # Convert to pprof format.
#' pprof_target_file <- tempfile()
#' profile_data <- profile::read_rprof(target_file)
#' profile::write_pprof(profile_data, pprof_target_file)
#'
#' # Visualize profile data.
#' vis_pprof(pprof_target_file, port = 50001)
#'
#' # Now, navigate to http://localhost:50001 in a web browser.
#'
#' # Listen to remote connections.
#' vis_pprof(pprof_target_file, host = "0.0.0.0", port = 50002)
#'
#' # Now, if the computer running vis_pprof() is available over your
#' # network, you can connect a different computer to the local
#' # pprof web server.
#' # E.g. http://domain-running-pprof.com:50002 or http:\\1.2.3.4:50002
#' # in a web browser.
#' }
vis_pprof <- function(path, host = "localhost", port = NULL) {
  server <- sprintf("%s:%s", host, port %||% random_port())
  message("local pprof server: http://", server)
  system2(find_pprof(), c("-http", server, shQuote(path)))
}

random_port <- function(from = 49152L, to = 65355L) {
  sample(seq.int(from = from, to = to, by = 1L), size = 1)
}
