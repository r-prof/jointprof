#ifndef __GPROFILER_PROFILER_H
#define __GPROFILER_PROFILER_H

#include <gperftools/profiler.h>
#include <signal.h>

class ProfilerDaisyChain {
public:
  ProfilerDaisyChain();

  void start(const std::string& path);
  void stop();

private:
  const ProfilerOptions& get_options() const;

  static int filter_in_thread(void* this_);
  int filter_in_thread();

private:
  ProfilerOptions options;
  struct sigaction oldact;
};

#endif // #ifndef __GPROFILER_PROFILER_H
