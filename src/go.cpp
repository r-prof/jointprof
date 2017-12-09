#include <Rcpp.h>
#include "main.h"

// [[Rcpp::export]]
int godouble(int x){
  return DoubleIt(x);
}
