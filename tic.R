if (Sys.getenv("BUILD_PKGDOWN") != "") {
  get_stage("install") %>%
    add_step(step_install_deps())

  get_stage("deploy") %>%
    add_step(step_build_pkgdown())

  if (ci()$get_branch() == "master" && Sys.getenv("id_rsa") != "") {
    # pkgdown documentation can be built optionally. Other example criteria:
    # - `inherits(ci(), "TravisCI")`: Only for Travis CI
    # - `ci()$is_tag()`: Only for tags, not for branches
    # - `Sys.getenv("BUILD_PKGDOWN") != ""`: If the env var "BUILD_PKGDOWN" is set
    # - `Sys.getenv("TRAVIS_EVENT_TYPE") == "cron"`: Only for Travis cron jobs
    get_stage("before_deploy") %>%
      add_step(step_setup_ssh())

    get_stage("deploy") %>%
      add_step(step_push_deploy(path = "docs", branch = "gh-pages"))
  }
} else {
  do_package_checks()
}
