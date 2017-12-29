#ifndef __GPROFILER_PROFILER_H
#define __GPROFILER_PROFILER_H

#include <memory>

class ProfilerDaisyChain {
private:
  ProfilerDaisyChain(const ProfilerDaisyChain&);

public:
  ProfilerDaisyChain();
  ~ProfilerDaisyChain();

  void start(const std::string& path);
  void stop();

private:
  struct Impl;
  std::unique_ptr<Impl> impl;
};

#endif // #ifndef __GPROFILER_PROFILER_H
