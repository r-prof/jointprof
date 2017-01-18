#include <Rcpp.h>

#include "gprofiler_types.h"


ProfilerDaisyChain::ProfilerDaisyChain() {
  options.filter_in_thread = &filter_in_thread;
  options.filter_in_thread_arg = reinterpret_cast<void*>(this);
  sigaction(SIGPROF, NULL, &oldact);
  if (oldact.sa_flags & SA_SIGINFO) {
    Rcpp::stop("oops");
  }
}

const ProfilerOptions& ProfilerDaisyChain::get_options() const {
  return options;
}

int ProfilerDaisyChain::filter_in_thread(void* this_) {
  ProfilerDaisyChain* this_ptr = reinterpret_cast<ProfilerDaisyChain*>(this_);
  return this_ptr->filter_in_thread();
}

int ProfilerDaisyChain::filter_in_thread() {
  struct sigaction myact;
  sigaction(SIGPROF, NULL, &myact);
  if (oldact.sa_handler != SIG_DFL && oldact.sa_handler != SIG_IGN) {
    oldact.sa_handler(SIGPROF);
  }
  sigaction(SIGPROF, &myact, NULL);
  return 1;
}

using namespace Rcpp;

// [[Rcpp::export]]
void start_profiler_impl(CharacterVector path) {
  if (path.length() != 1)
    stop("start_profiler() expects scalar path");
  ProfilerDaisyChain* dc = new ProfilerDaisyChain();
  ProfilerStartWithOptions(path[0], &dc->get_options());
}

// [[Rcpp::export]]
void stop_profiler_impl() {
  ProfilerStop();
}
