# Automated unit testing may not be suitable
# for interactive features like vis_pprof().

if (interactive()) {
  target_file <- tempfile()
  Rprof(target_file)
  replicate(100, sessionInfo())
  Rprof(NULL)
  pprof_target_file <- tempfile()
  profile_data <- profile::read_rprof(target_file)
  profile::write_pprof(profile_data, pprof_target_file)
  vis_pprof(pprof_target_file, port = 50003)
}
