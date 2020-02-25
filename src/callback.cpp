#include <Rcpp.h>

// [[Rcpp::export]]
void callback1_cpp(Rcpp::XPtr<int> x) {
  static Rcpp::Function cb("callback1_r", Rcpp::Environment::namespace_env("jointprof"));
  cb(x);
}

// [[Rcpp::export]]
void callback2_cpp(Rcpp::XPtr<int> x) {
  static Rcpp::Function cb("callback2_r", Rcpp::Environment::namespace_env("jointprof"));
  cb(x);
}

// [[Rcpp::export]]
void callback3_cpp() {
  static Rcpp::Function cb("callback3_r", Rcpp::Environment::namespace_env("jointprof"));
  Rcpp::XPtr<int> x(new int(0));
  cb(x);
}
