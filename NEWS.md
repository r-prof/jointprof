# jointprof 0.0.1.9001

- New `joint_pprof()`.
- New `comingle_pprof()` and `comingle_rprof()`, for use with proffer.
- Revamp the `configure` script (#45, @atheriel).
- Improve package metadata (DESCRIPTION/NAMESPACE/LICENSE) (#43).
- Remove unused `write_flat_ds()` (#42).
- Adds new error messages for possible pprof installation issues (#40).


# jointprof 0.0.1.9000

- Detailed installation instructions (#28).
- Include installation instructions in `?find_pprof`, an error in `find_pprof()` points to the help page (#30).
- Better error message in `stop_profiler()` (#26).
- Deinitialize signal handler on unload to support `pkgload::load_all()` (#32).
- Fix Travis CI on all platforms, currently requires gperftools/gperftools#1004 (#27).
- Implement `find_pprof()` in favor of a separate *pprof* package (r-prof/r-pprof#1).
- Add introductory vignette.
- Combine stack traces with the help of the _profile_ package.
- Reading files created by gperftools by parsing `pprof` output (#1).
- Support gperftools >= 2.5 (#13).


# jointprof 0.0-1

Initial release

- Proof of concept.
- Functions `start_profiler()` and `stop_profiler()` to initialize and terminate joint profiling.
    - Daisy-chain `SIGPROF` handlers, the `gperftools` profiler offers a filter which can be used to sneak in the call to the original handler installed by `Rprof()`.
- Function `get_profiler_traces()` returns joint profiling data.
    - Parsing `gperftools` data with a bleeding-edge version of `pprof` (needs `-traces` switch), Ubuntu binary included.
    - Parsing `Rprof` data with a call to an unexported `profvis` function.
- Convenience function `show_profiler_pdf()` shows a PDF of the `gperftools` data.
