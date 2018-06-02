context("integration")

test_that("simple integration test", {
  skip_on_os(c("solaris", "windows"))

  path <- tempfile("jointprof", fileext = ".prof")

  start_profiler(path)

  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  invisible(lapply(1:100, function(x)
    DBI::dbWriteTable(con, paste0("iris", x), iris)))
  DBI::dbDisconnect(con)

  ds_vis <- withVisible(stop_profiler())
  expect_false(ds_vis$visible)
  expect_error(profile::validate_profile(ds_vis$value), NA)
})
