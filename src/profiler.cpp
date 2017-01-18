#include <Rcpp.h>

#include "profiler.h"

#include <signal.h>
#include <gperftools/profiler.h>

struct ProfilerDaisyChain::Impl {
  struct sigaction oldact;
};

ProfilerDaisyChain::ProfilerDaisyChain() : impl(new Impl) {
}

ProfilerDaisyChain::~ProfilerDaisyChain() {
}

void ProfilerDaisyChain::start(const std::string& path) {
  sigaction(SIGPROF, NULL, &impl->oldact);
  if (impl->oldact.sa_flags & SA_SIGINFO) {
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
  if (impl->oldact.sa_handler != SIG_DFL && impl->oldact.sa_handler != SIG_IGN) {
    impl->oldact.sa_handler(SIGPROF);
  }
  sigaction(SIGPROF, &myact, NULL);
  return 1;
}
