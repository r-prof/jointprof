#include <Rcpp.h>

#include "profiler.h"

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

void ProfilerDaisyChain::start(const std::string& path) {
  ProfilerStartWithOptions(path.c_str(), &get_options());
}

void ProfilerDaisyChain::stop() {
  ProfilerStop();
}
