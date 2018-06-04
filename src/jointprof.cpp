#include <Rcpp.h>

#include "jointprof_types.h"


using namespace Rcpp;

// [[Rcpp::export]]
List init_profiler_impl() {
  ProfilerDaisyChain* dc = new ProfilerDaisyChain();
  return List::create(XPtr<ProfilerDaisyChain>(dc));
}

// [[Rcpp::export]]
void start_profiler_impl(List ldc, std::string path) {
  XPtr<ProfilerDaisyChain> pdc = ldc[0];
  ProfilerDaisyChain* dc = pdc.get();
  dc->start(std::string(path));
}

// [[Rcpp::export]]
void stop_profiler_impl(List ldc) {
  XPtr<ProfilerDaisyChain> pdc = ldc[0];
  ProfilerDaisyChain* dc = pdc.get();
  dc->stop();
}

RcppExport void R_unload_jointprof(DllInfo *dll) {
  ProfilerDaisyChain::remove_handler();
}
