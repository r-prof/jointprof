#include <Rcpp.h>

#include "gprofiler_types.h"


using namespace Rcpp;

// [[Rcpp::export]]
List start_profiler_impl(CharacterVector path) {
  if (path.length() != 1)
    stop("start_profiler() expects scalar path");
  ProfilerDaisyChain* dc = new ProfilerDaisyChain();
  dc->start(std::string(path[0]));
  return List::create(XPtr<ProfilerDaisyChain>(dc));
}

// [[Rcpp::export]]
void stop_profiler_impl(List ldc) {
  XPtr<ProfilerDaisyChain> pdc = ldc[0];
  ProfilerDaisyChain* dc = pdc.get();
  dc->stop();
}
