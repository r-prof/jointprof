#include <Rcpp.h>

#include <gperftools/profiler.h>

#include <signal.h>

using namespace Rcpp;

class ProfilerDaisyChain {
public:
  ProfilerDaisyChain() {
    options.filter_in_thread = &filter_in_thread;
    options.filter_in_thread_arg = reinterpret_cast<void*>(this);
    sigaction(SIGPROF, NULL, &oldact);
    if (oldact.sa_flags & SA_SIGINFO) {
      stop("oops");
    }
  }

public:
  const ProfilerOptions& get_options() const {
    return options;
  }

  static int filter_in_thread(void* this_) {
    ProfilerDaisyChain* this_ptr = reinterpret_cast<ProfilerDaisyChain*>(this_);
    return this_ptr->filter_in_thread();
  }

private:
  int filter_in_thread() {
    struct sigaction myact;
    sigaction(SIGPROF, NULL, &myact);
    if (oldact.sa_handler != SIG_DFL && oldact.sa_handler != SIG_IGN) {
      oldact.sa_handler(SIGPROF);
    }
    sigaction(SIGPROF, &myact, NULL);
    return 1;
  }

private:
  ProfilerOptions options;
  struct sigaction oldact;
};

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
