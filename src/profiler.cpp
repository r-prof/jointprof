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
  // FIXME: Query value during init of the library, and not during init of the class
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

  // Compatibility with gperftools <= 2.4:
  // Older versions changed the signal handler when starting the profiler,
  // as of gperftools 2.5 the signal handler is installed when the library is loaded.
  // We check if starting the profiler has changed the signal handler; if not,
  // we use the signal handler that was active when the library was loaded
  struct sigaction newact;
  sigaction(SIGPROF, NULL, &newact);

  if (newact.sa_handler == impl->oldact.sa_handler) {
    sigaction(SIGPROF, &impl->initact, NULL);
  }
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
