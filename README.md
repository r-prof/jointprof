
<!-- README.md is generated from README.Rmd. Please edit that file -->
gprofiler
=========

The goal of gprofiler is to assist profiling R packages that include native code (C++, C, Fortran, ...). It collects profiling output simultaneously using [Rprof](https://www.rdocumentation.org/packages/utils/versions/3.3.2/topics/Rprof) and [gperftools](https://github.com/gperftools/gperftools) and provides a unified view of profiling data. At present this is but a feasibility study: it requires Ubuntu Linux 64-bit and the `libgoogle-perftools-dev` package.

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
gprofiler::stop_profiler()
```

A unified view is created with `get_profiler_traces()`. Currently this returns a nested data frame with two list columns, one for the native trace and one for the R trace. Each row represents one sample:

``` r
gprofiler::get_profiler_traces()
#> # A tibble: 37 x 3
#>     time gprofiler             rprof
#>    <int>    <list>            <list>
#>  1     1 <chr [1]> <tibble [38 x 7]>
#>  2     2 <chr [1]> <tibble [35 x 7]>
#>  3     3 <chr [1]> <tibble [40 x 7]>
#>  4     4 <chr [1]> <tibble [41 x 7]>
#>  5     5 <chr [1]> <tibble [30 x 7]>
#>  6     6 <chr [1]> <tibble [36 x 7]>
#>  7     7 <chr [1]> <tibble [34 x 7]>
#>  8     8 <chr [1]> <tibble [38 x 7]>
#>  9     9 <chr [1]> <tibble [49 x 7]>
#> 10    10 <chr [1]> <tibble [35 x 7]>
#> # ... with 27 more rows
```

Below is another example where an R function calls a C++ function that calls back into R.

``` r
gprofiler::start_profiler()
gprofiler::callback2_r()
#> NULL
gprofiler::stop_profiler()
gprofiler::get_profiler_traces()
#> # A tibble: 84 x 3
#>     time gprofiler             rprof
#>    <int>    <list>            <list>
#>  1     1 <chr [1]> <tibble [20 x 7]>
#>  2     2 <chr [1]> <tibble [20 x 7]>
#>  3     3 <chr [1]> <tibble [20 x 7]>
#>  4     4 <chr [1]> <tibble [20 x 7]>
#>  5     5 <chr [1]> <tibble [20 x 7]>
#>  6     6 <chr [1]> <tibble [20 x 7]>
#>  7     7 <chr [1]> <tibble [20 x 7]>
#>  8     8 <chr [1]> <tibble [20 x 7]>
#>  9     9 <chr [1]> <tibble [20 x 7]>
#> 10    10 <chr [1]> <tibble [20 x 7]>
#> # ... with 74 more rows
```

Eventually, the result will be an `Rprof`-compatible data format which can be consumed by `profvis` and other existing packages.
