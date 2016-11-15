#include <Rcpp.h>

#include <gperftools/profiler.h>

using namespace Rcpp;

// [[Rcpp::export]]
void start_profiler(CharacterVector path) {
  if (path.length() != 1)
    stop("start_profiler() expects scalar path");
  ProfilerStart(path[0]);
}

// [[Rcpp::export]]
void stop_profiler() {
  ProfilerStop();
}
