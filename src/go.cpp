#include <Rcpp.h>
#include "main.h"

// [[Rcpp::export]]
int godouble(int x){
  return cgo_DoubleIt(x);
}

// [[Rcpp::export]]
int run_pprof(std::string path, std::string target_path) {
  GoString go_path = { path.c_str(), path.length() };
  GoString go_target_path = { target_path.c_str(), target_path.length() };
  GoString ret = cgo_run_pprof(go_path, go_target_path);
  if (ret.n > 0) {
    Rcpp::stop("Error fetching native profile: %s", std::string(ret.p, ret.n));
  }
  return 0;
}
