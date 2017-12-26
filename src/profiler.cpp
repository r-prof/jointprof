#include <Rcpp.h>

#include "profiler.h"

#include <signal.h>
#include <fstream>
#include <gperftools/stacktrace.h>
#include "getpc.h"
#include "sysinfo.h"

struct ProfilerDaisyChain::Impl {
  Impl() : initact(), oldact() {}
  struct sigaction initact;
  struct sigaction oldact;
  std::ofstream ofs;

  void start(const std::string& path);
  void stop();

  static void static_handler(int signal, siginfo_t* info, void* ucontext);
  void handler(int signal, siginfo_t* info, void* ucontext);

  void write_header();
  void write_stack_trace(const ucontext_t* signal_ucontext);
  void write_trailer();

  static Impl* static_impl;
};

ProfilerDaisyChain::Impl* ProfilerDaisyChain::Impl::static_impl = NULL;

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
  if (static_impl) {
    Rcpp::stop("Profiler already running");
  }

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

  myact.sa_sigaction = &static_handler;
  myact.sa_flags = SA_SIGINFO;
  sigaction(SIGPROF, &myact, NULL);

  static_impl = this;
}

void ProfilerDaisyChain::stop() {
  impl->stop();
}

void ProfilerDaisyChain::Impl::stop() {
  // Before closing file, to avoid race condition
  sigaction(SIGPROF, &initact, NULL);

  static_impl = NULL;

  write_trailer();
  ofs.close();
}

void ProfilerDaisyChain::Impl::static_handler(int signal, siginfo_t* info, void* ucontext) {
  if (!static_impl) return;
  return static_impl->handler(signal, info, ucontext);
}

void ProfilerDaisyChain::Impl::handler(int signal, siginfo_t* info, void* ucontext) {
  if (signal != SIGPROF)
    return;

  write_stack_trace(reinterpret_cast<const ucontext_t*>(ucontext));

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
  const int sampling_period = 20000;
  intptr_t header[5] = {0, 3, 0, sampling_period, 0 };

  ofs.write(reinterpret_cast<const char*>(header), sizeof(header));
}

// Adapted from github.com/gperftools/gperftools:src/profiler.cc

// Copyright (c) 2005, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


void ProfilerDaisyChain::Impl::write_stack_trace(const ucontext_t* signal_ucontext) {
  const int kMaxStackDepth = 64;
  void* stack[kMaxStackDepth + 2];
  size_t stack_start = 2;

  // Under frame-pointer-based unwinding at least on x86, the
  // top-most active routine doesn't show up as a normal frame, but
  // as the "pc" value in the signal handler context.
  stack[stack_start] = GetPC(*signal_ucontext);

  // We skip the top three stack trace entries (this function,
  // SignalHandler::SignalHandler and one signal handler frame)
  // since they are artifacts of profiling and should not be
  // measured.  Other profiling related frames may be removed by
  // "pprof" at analysis time.  Instead of skipping the top frames,
  // we could skip nothing, but that would increase the profile size
  // unnecessarily.
  intptr_t depth = GetStackTraceWithContext(stack + stack_start + 1, kMaxStackDepth - 1,
                                            3, signal_ucontext);

  if (depth > 0 && stack[1] == stack[0]) {
    // in case of non-frame-pointer-based unwinding we will get
    // duplicate of PC in stack[1], which we don't want
    stack_start++;
  } else {
    depth++;  // To account for pc value in stack[0];
  }

  // First header word: value (always one)
  stack[stack_start - 2] = reinterpret_cast<void*>(1);

  // Second header word: depth
  stack[stack_start - 1] = reinterpret_cast<void*>(depth);

  ofs.write(reinterpret_cast<const char*>(&stack[stack_start - 2]), (depth + 2) * sizeof(stack[0]));
}

// Adapted from github.com/gperftools/gperftools:src/profiledata.cc

// -*- Mode: C++; c-basic-offset: 2; indent-tabs-mode: nil -*-
// Copyright (c) 2007, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

void ProfilerDaisyChain::Impl::write_trailer() {
  intptr_t binary_trailer[3] = { 0, 1, 0 };
  ofs.write(reinterpret_cast<const char*>(binary_trailer), sizeof(binary_trailer));

  ProcMapsIterator::Buffer iterbuf;
  ProcMapsIterator it(0, &iterbuf);   // 0 means "current pid"

  uint64_t start, end, offset;
  int64_t inode;
  char *flags, *filename;
  ProcMapsIterator::Buffer linebuf;
  while (it.Next(&start, &end, &flags, &offset, &inode, &filename)) {
    int written = it.FormatLine(linebuf.buf_, sizeof(linebuf.buf_),
                                start, end, flags, offset, inode, filename,
                                0);

    ofs.write(reinterpret_cast<const char*>(linebuf.buf_), written);
  }
}
