
<!-- README.md is generated from README.Rmd. Please edit that file -->
jointprof
=========

[![Travis build status](https://travis-ci.org/r-prof/jointprof.svg?branch=master)](https://travis-ci.org/r-prof/jointprof) [![Coverage status](https://codecov.io/gh/r-prof/jointprof/branch/master/graph/badge.svg)](https://codecov.io/github/r-prof/jointprof?branch=master) [![CRAN status](http://www.r-pkg.org/badges/version/jointprof)](https://cran.r-project.org/package=jointprof)

The goal of jointprof is to assist profiling R packages that include native code (C++, C, Fortran, ...). It collects profiling output simultaneously using [Rprof](https://www.rdocumentation.org/packages/utils/versions/3.4.3/topics/Rprof) and [gperftools](https://github.com/gperftools/gperftools) and provides a unified view of profiling data.

See the [guide](https://r-prof.github.io/jointprof/articles/guide.html) for a more detailed overview, or take a look at the [internals](https://r-prof.github.io/jointprof/articles/internals.html) document if you're curious.

Installation
------------

Tested on Ubuntu only. Other Linux distributions may work if you install the right system dependencies ([let me know](https://github.com/r-prof/jointprof/issues) which!). OS X currently doesn't work, Windows, and Solaris are not supported.

``` sh
sudo apt install \
  libgoogle-perftools-dev \
  libprotoc-dev libprotobuf-dev protobuf-compiler \
  golang-go \
  graphviz
```

``` r
# install.packages("remotes")
remotes::install_github("r-prof/jointprof")
```

Usage
-----

``` r
library(jointprof)

target_file <- "Rprof.out"

# Collect profile data
start_profiler(target_file)
## code to be profiled
stop_profiler()

# Analyze profile data
summaryRprof(target_file)
profvis::profvis(prof_input = target_file)
proftools::readProfileData(target_file)
prof.tree::prof.tree(target_file)

# Convert to pprof format and analyze
pprof_target_file <- "Rprof.pb.gz"
profile_data <- profile::read_rprof(target_file)
profile::write_rprof(profile_data, pprof_target_file)
system2(
  find_pprof(),
  c(
    "-http",
    "localhost:8080",
    shQuote(pprof_target_file)
  )
)
```

Acknowledgment
--------------

This project is being realized with financial support from the

<img src="https://www.r-consortium.org/wp-content/uploads/sites/13/2016/09/RConsortium_Horizontal_Pantone.png" width="400">
