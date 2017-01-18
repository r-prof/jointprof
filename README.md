
<!-- README.md is generated from README.Rmd. Please edit that file -->
gprofiler
=========

The goal of gprofiler is to assist profiling R packages that include native code (C++, C, Fortran, ...). It collects profiling output simultaneously using 'Rprof' and 'gprofiler' and provides a unified view of profiling data. At present this is but a feasibility study.

Example
-------

The following example writes the `iris` data 100 times to an in-memory SQLite database and collects profiling data. By default, the profiling data are collected in two files, `1.prof` (native) and `1.prof.out` (R).

``` r
library(DBI)

gprofiler::start_profiler()
con <- dbConnect(RSQLite::SQLite(), ":memory:")
invisible(lapply(1:100, function(x)
  dbWriteTable(con, paste0("iris", x), iris)))
dbDisconnect(con)
#> [1] TRUE
gprofiler::stop_profiler()
```

A unified view is created with `get_profiler_traces()`. Currently this returns a nested data frame with two list columns, one for the native trace and one for the R trace. Each row represents one sample:

``` r
gprofiler::get_profiler_traces()
#> # A tibble: 40 × 3
#>     time gprofiler             rprof
#>    <int>    <list>            <list>
#> 1      1 <chr [1]> <tibble [31 × 7]>
#> 2      2 <chr [1]> <tibble [33 × 7]>
#> 3      3 <chr [1]> <tibble [35 × 7]>
#> 4      4 <chr [1]> <tibble [34 × 7]>
#> 5      5 <chr [1]> <tibble [40 × 7]>
#> 6      6 <chr [1]> <tibble [34 × 7]>
#> 7      7 <chr [1]> <tibble [36 × 7]>
#> 8      8 <chr [1]> <tibble [40 × 7]>
#> 9      9 <chr [1]> <tibble [27 × 7]>
#> 10    10 <chr [1]> <tibble [35 × 7]>
#> # ... with 30 more rows
```

Eventually, the result will be an `Rprof`-compatible data format which can be consumed by `profvis` and other existing packages.
