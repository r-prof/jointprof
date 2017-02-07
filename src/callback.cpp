#include <Rcpp.h>

// [[Rcpp::export]]
void callback1_cpp() {
  Rcpp::Function("callback1_r", Rcpp::Environment::namespace_env("gprofiler")) ();
}

// [[Rcpp::export]]
void callback2_cpp() {
  Rcpp::Function("callback2_r", Rcpp::Environment::namespace_env("gprofiler")) ();
}

// [[Rcpp::export]]
void callback3_cpp() {
  Rcpp::Function("callback3_r", Rcpp::Environment::namespace_env("gprofiler")) ();
}
