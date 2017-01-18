## gprofiler 0.0-1 (2017-01-18)

Initial release

- Proof of concept.
- Functions `start_profiler()` and `stop_profiler()` to initialize and terminate joint profiling.
    - Daisy-chain `SIGPROF` handlers, the `gperftools` profiler offers a filter which can be used to sneak in the call to the original handler installed by `Rprof()`.
- Function `get_profiler_traces()` returns joint profiling data.
    - Parsing `gperftools` data with a bleeding-edge version of `pprof` (needs `-traces` switch), Ubuntu binary included.
    - Parsing `Rprof` data with a call to an unexported `profvis` function.
- Convenience function `show_profiler_pdf()` shows a PDF of the `gperftools` data.
