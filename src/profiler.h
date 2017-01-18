#ifndef __GPROFILER_PROFILER_H
#define __GPROFILER_PROFILER_H

#include <signal.h>

class ProfilerDaisyChain {
public:
  ProfilerDaisyChain();

  void start(const std::string& path);
  void stop();

private:
  static int filter_in_thread(void* this_);
  int filter_in_thread();

private:
  struct sigaction oldact;
};

#endif // #ifndef __GPROFILER_PROFILER_H
