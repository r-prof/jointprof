context("integration")

test_that("simple integration test", {
  skip_on_os(c("mac", "solaris", "windows"))

  path <- tempfile("gprofiler", fileext = ".prof")

  start_profiler(path)

  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  invisible(lapply(1:100, function(x)
    DBI::dbWriteTable(con, paste0("iris", x), iris)))
  DBI::dbDisconnect(con)

  stop_profiler()
  expect_true(TRUE)
})

test_that("simple failure test", {
  skip_on_os("linux")

  path <- tempfile("gprofiler", fileext = ".prof")

  expect_error(start_profiler(path), "Linux")
  expect_error(stop_profiler(), "Linux")
})
