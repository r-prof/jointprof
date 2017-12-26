context("integration")

test_that("simple integration test", {
  path <- tempfile("gprofiler", fileext = ".prof")

  start_profiler(path)

  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  invisible(lapply(1:100, function(x)
    DBI::dbWriteTable(con, paste0("iris", x), iris)))
  DBI::dbDisconnect(con)

  stop_profiler()
})
