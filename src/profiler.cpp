#include <Rcpp.h>

#include "profiler.h"

#include <signal.h>
#include <gperftools/profiler.h>

struct ProfilerDaisyChain::Impl {
  Impl() : initact(), oldact() {}
  struct sigaction initact;
  struct sigaction oldact;
};

ProfilerDaisyChain::ProfilerDaisyChain() : impl(new Impl) {
  sigaction(SIGPROF, NULL, &impl->initact);
}

ProfilerDaisyChain::~ProfilerDaisyChain() {
}

void ProfilerDaisyChain::start(const std::string& path) {
  sigaction(SIGPROF, NULL, &impl->oldact);

  // Check that the handler requires three arguments
  if (impl->oldact.sa_flags & SA_SIGINFO) {
    Rcpp::stop("oops");
  }

  ProfilerOptions options;
  memset(&options, 0, sizeof(options));
  options.filter_in_thread = &filter_in_thread;
  options.filter_in_thread_arg = reinterpret_cast<void*>(this);
  int ret = ProfilerStartWithOptions(path.c_str(), &options);
  if (!ret) {
    Rcpp::stop("Error starting profiler");
  }

  sigaction(SIGPROF, &impl->initact, NULL);
}

void ProfilerDaisyChain::stop() {
  ProfilerStop();
  sigaction(SIGPROF, &impl->initact, NULL);
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
