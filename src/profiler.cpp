#include <Rcpp.h>

#include "profiler.h"

#include <signal.h>
#include <fstream>

struct ProfilerDaisyChain::Impl {
  Impl() : initact(), oldact() {}
  struct sigaction initact;
  struct sigaction oldact;
  std::ofstream ofs;

  void start(const std::string& path);
  void stop();

  static void handler(int signal, siginfo_t* info, void* this_);
  void handler(int signal, siginfo_t* info);

  void write_header();
  void write_stack_trace();
  void write_trailer();
};

ProfilerDaisyChain::ProfilerDaisyChain() : impl(new Impl) {
  // FIXME: Query value during init of the library, and not during init of the class
  sigaction(SIGPROF, NULL, &impl->initact);
}

ProfilerDaisyChain::~ProfilerDaisyChain() {
}

void ProfilerDaisyChain::start(const std::string& path) {
  impl->start(path);
}

void ProfilerDaisyChain::Impl::start(const std::string& path) {
  sigaction(SIGPROF, NULL, &oldact);

  // Check that the handler requires three arguments
  if (oldact.sa_flags & SA_SIGINFO) {
    Rcpp::stop("oops");
  }

  ofs.open(path, std::ios::out | std::ios::binary);
  if (ofs.fail()) {
    ofs.clear();
    Rcpp::stop("Can't create file %s", path.c_str());
  }

  this->write_header();

  struct sigaction myact;
  memset(&myact, 0, sizeof(myact));

  myact.sa_sigaction = &handler;
  myact.sa_flags = SA_SIGINFO;
  sigaction(SIGPROF, &myact, NULL);
}

void ProfilerDaisyChain::stop() {
  impl->stop();
}

void ProfilerDaisyChain::Impl::stop() {
  // Before closing file, to avoid race condition
  sigaction(SIGPROF, &initact, NULL);

  write_trailer();
  ofs.close();
}

void ProfilerDaisyChain::Impl::handler(int signal, siginfo_t* info, void* this_) {
  Impl* this_ptr = reinterpret_cast<Impl*>(this_);
  return this_ptr->handler(signal, info);
}

void ProfilerDaisyChain::Impl::handler(int signal, siginfo_t* info) {
  if (signal != SIGPROF)
    return;

  write_stack_trace();

  struct sigaction myact;
  sigaction(SIGPROF, NULL, &myact);
  if (oldact.sa_handler != SIG_DFL && oldact.sa_handler != SIG_IGN) {
    oldact.sa_handler(SIGPROF);
  }
  sigaction(SIGPROF, &myact, NULL);
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

void ProfilerDaisyChain::Impl::write_header() {

}

void ProfilerDaisyChain::Impl::write_stack_trace() {

}

void ProfilerDaisyChain::Impl::write_trailer() {

}
