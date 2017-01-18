#include <Rcpp.h>

#include "profiler.h"

#include <gperftools/profiler.h>

ProfilerDaisyChain::ProfilerDaisyChain() {
}

void ProfilerDaisyChain::start(const std::string& path) {
  sigaction(SIGPROF, NULL, &oldact);
  if (oldact.sa_flags & SA_SIGINFO) {
    Rcpp::stop("oops");
  }

  ProfilerOptions options;
  options.filter_in_thread = &filter_in_thread;
  options.filter_in_thread_arg = reinterpret_cast<void*>(this);
  ProfilerStartWithOptions(path.c_str(), &options);
}

void ProfilerDaisyChain::stop() {
  ProfilerStop();
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
