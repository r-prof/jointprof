#include <Rcpp.h>

#include "gprofiler_types.h"

using namespace Rcpp;

// [[Rcpp::export]]
void start_profiler_impl(CharacterVector path) {
  if (path.length() != 1)
    stop("start_profiler() expects scalar path");
  ProfilerDaisyChain* dc = new ProfilerDaisyChain();
  ProfilerStartWithOptions(path[0], &dc->get_options());
}

// [[Rcpp::export]]
void stop_profiler_impl() {
  ProfilerStop();
}
