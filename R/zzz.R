# This is picked up by Rcpp, adds the correct entry in the CallEntries table
dummy <- function() {
  dll <- NULL
  invisible(.C("R_unload_jointprof", dll, PACKAGE = 'jointprof'))
}
