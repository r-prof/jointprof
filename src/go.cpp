#include <Rcpp.h>
#include "main.h"

// [[Rcpp::export]]
int godouble(int x){
  return cgo_DoubleIt(x);
}

// [[Rcpp::export]]
void run_pprof(){
  cgo_run_pprof();
}
