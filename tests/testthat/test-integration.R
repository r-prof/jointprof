context("integration")

test_that("simple integration test", {
  skip_on_os(c("mac", "solaris", "windows"))

  path <- tempfile("gprofiler", fileext = ".prof")

  start_profiler(path)

  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  invisible(lapply(1:100, function(x)
    DBI::dbWriteTable(con, paste0("iris", x), iris)))
  DBI::dbDisconnect(con)

  ds_vis <- withVisible(stop_profiler())
  expect_false(ds_vis$visible)
  expect_error(profile::validate_profile(ds_vis$value), NA)
})

test_that("simple failure test", {
  skip_on_os("linux")

  path <- tempfile("gprofiler", fileext = ".prof")

  expect_error(start_profiler(path), "Linux")
  expect_error(stop_profiler(), "Linux")
})
