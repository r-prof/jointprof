
<!-- README.md is generated from README.Rmd. Please edit that file -->
gprofiler
=========

The goal of gprofiler is to assist profiling R packages that include native code (C++, C, Fortran, ...). It collects profiling output simultaneously using [Rprof](https://www.rdocumentation.org/packages/utils/versions/3.3.2/topics/Rprof) and [gperftools](https://github.com/gperftools/gperftools) and provides a unified view of profiling data. At present this is but a feasibility study: it requires Ubuntu Linux 64-bit and the `libgoogle-perftools-dev` package.

Example
-------

The following example writes the `iris` data 100 times to an in-memory SQLite database and collects profiling data. By default, the profiling data are collected in two files, `1.out` (R) and `1.out.prof` (native).

``` r
library(DBI)

gprofiler::start_profiler()
#> Temporary files: /tmp/Rtmp6ZWoiW/gprofiler4ac148b4ba91.prof, /tmp/Rtmp6ZWoiW/gprofiler4ac148376cf9.out
con <- dbConnect(RSQLite::SQLite(), ":memory:")
invisible(lapply(1:100, function(x)
  dbWriteTable(con, paste0("iris", x), iris)))
dbDisconnect(con)
gprofiler::stop_profiler()
```

A unified view is created with `get_profiler_traces()`. Currently this returns a nested data frame with two list columns, one for the native trace and one for the R trace. Each row represents one sample:

``` r
gprofiler::get_profiler_traces()
#> # A tibble: 79 x 3
#>     time gprofiler         rprof            
#>    <int> <list>            <list>           
#>  1     1 <tibble [63 × 3]> <tibble [38 × 7]>
#>  2     2 <tibble [63 × 3]> <tibble [38 × 7]>
#>  3     3 <tibble [63 × 3]> <tibble [38 × 7]>
#>  4     4 <tibble [63 × 3]> <tibble [36 × 7]>
#>  5     5 <tibble [63 × 3]> <tibble [35 × 7]>
#>  6     6 <tibble [63 × 3]> <tibble [36 × 7]>
#>  7     7 <tibble [63 × 3]> <tibble [36 × 7]>
#>  8     8 <tibble [63 × 3]> <tibble [36 × 7]>
#>  9     9 <tibble [63 × 3]> <tibble [36 × 7]>
#> 10    10 <tibble [64 × 3]> <tibble [35 × 7]>
#> # ... with 69 more rows
```

Below is another example where an R function calls a C++ function that calls back into R.

``` r
gprofiler::start_profiler()
#> Temporary files: /tmp/Rtmp6ZWoiW/gprofiler4ac1389eb0bc.prof, /tmp/Rtmp6ZWoiW/gprofiler4ac175e66ded.out
gprofiler::callback2_r()
#> NULL
gprofiler::stop_profiler()
gprofiler::get_profiler_traces()
#> # A tibble: 172 x 3
#>     time gprofiler         rprof            
#>    <int> <list>            <list>           
#>  1     1 <tibble [63 × 3]> <tibble [21 × 7]>
#>  2     2 <tibble [63 × 3]> <tibble [21 × 7]>
#>  3     3 <tibble [63 × 3]> <tibble [21 × 7]>
#>  4     4 <tibble [63 × 3]> <tibble [21 × 7]>
#>  5     5 <tibble [63 × 3]> <tibble [21 × 7]>
#>  6     6 <tibble [63 × 3]> <tibble [20 × 7]>
#>  7     7 <tibble [63 × 3]> <tibble [20 × 7]>
#>  8     8 <tibble [63 × 3]> <tibble [20 × 7]>
#>  9     9 <tibble [63 × 3]> <tibble [20 × 7]>
#> 10    10 <tibble [63 × 3]> <tibble [20 × 7]>
#> # ... with 162 more rows
```

Eventually, the result will be an `Rprof`-compatible data format which can be consumed by `profvis` and other existing packages.

### Acknowledgment

This project is being realized with financial support from the

<img src="https://www.r-consortium.org/wp-content/uploads/sites/13/2016/09/RConsortium_Horizontal_Pantone.png" width="400">
