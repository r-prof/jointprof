
<!-- README.md is generated from README.Rmd. Please edit that file -->
gprofiler
=========

The goal of gprofiler is to assist profiling R packages that include native code (C++, C, Fortran, ...). It collects profiling output simultaneously using [Rprof](https://www.rdocumentation.org/packages/utils/versions/3.3.2/topics/Rprof) and [gperftools](https://github.com/gperftools/gperftools) and provides a unified view of profiling data. At present this is but a feasibility study: it requires Ubuntu Linux 64-bit and the `libgoogle-perftools-dev` package.

Example
-------

The following example writes the `iris` data 100 times to an in-memory SQLite database. Profiling data are collected at both R and native levels, native stack traces are commingled with the R stack traces where appropriate. The results are written (to `1.out` by default) in an `Rprof`-compatible data format, which can be consumed by `profvis` and other existing packages.

``` r
library(DBI)

gprofiler::start_profiler()
#> Temporary files: /tmp/RtmpdL5s6L/gprofiler362930d84cf.prof, /tmp/RtmpdL5s6L/gprofiler362925db0a18.out
con <- dbConnect(RSQLite::SQLite(), ":memory:")
invisible(lapply(1:100, function(x)
  dbWriteTable(con, paste0("iris", x), iris)))
dbDisconnect(con)
gprofiler::stop_profiler()

nrow(profile::read_rprof("1.out")$samples)
#> [1] 41
```

Below is another example where an R function calls a C++ function that calls back into R.

``` r
gprofiler::start_profiler()
#> Temporary files: /tmp/RtmpdL5s6L/gprofiler36295d602e5f.prof, /tmp/RtmpdL5s6L/gprofiler36295750cd99.out
gprofiler::callback2_r()
#> NULL
gprofiler::stop_profiler()

nrow(profile::read_rprof("1.out")$samples)
#> [1] 89
```

### Acknowledgment

This project is being realized with financial support from the

<img src="https://www.r-consortium.org/wp-content/uploads/sites/13/2016/09/RConsortium_Horizontal_Pantone.png" width="400">
