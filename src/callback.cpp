#include <Rcpp.h>

// [[Rcpp::export]]
void callback1_cpp() {
  static Rcpp::Function cb("callback1_r", Rcpp::Environment::namespace_env("jointprof"));
  cb();
}

// [[Rcpp::export]]
void callback2_cpp() {
  static Rcpp::Function cb("callback2_r", Rcpp::Environment::namespace_env("jointprof"));
  cb();
}

// [[Rcpp::export]]
void callback3_cpp() {
  static Rcpp::Function cb("callback3_r", Rcpp::Environment::namespace_env("jointprof"));
  cb();
}
