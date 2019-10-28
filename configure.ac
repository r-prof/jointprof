## Process this file with autoconf to produce configure.
## In general, the safest way to proceed is to run ./autogen.sh

# make sure we're interpreted by some minimal autoconf
AC_PREREQ([2.59])

AC_INIT([jointprof],[0.0.1.9000])

# The argument here is just something that should be in the current directory
# (for sanity checking)
AC_CONFIG_SRCDIR(DESCRIPTION)
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([src/config.h])

# Check whether some low-level functions/files are available
AC_HEADER_STDC

# TODO(csilvers): we could remove a lot when WITH_CPU_PROFILER etc is "no".
AC_CHECK_TYPES([__int64])       # defined in some windows platforms
# We also need <ucontext.h>/<sys/ucontext.h>, but we get those from
# AC_PC_FROM_UCONTEXT, below.

# We want to access the "PC" (Program Counter) register from a struct
# ucontext.  Every system has its own way of doing that.  We try all the
# possibilities we know about.  Note REG_PC should come first (REG_RIP
# is also defined on solaris, but does the wrong thing).  But don't
# bother if we're not doing cpu-profiling.
# [*] means that we've not actually tested one of these systems
AC_PC_FROM_UCONTEXT(AC_MSG_WARN(Could not find the PC))

# Defines PRIuS
AC_COMPILER_CHARACTERISTICS

# Also make sure we get standard PRI... definitions, even with glibc.
# We have to use AH_VERBATIM because we need the #ifdef guard (gcc buglet)
AH_VERBATIM([__STDC_FORMAT_MACROS],
            [/* C99 says: define this to get the PRI... macros from stdint.h */
#ifndef __STDC_FORMAT_MACROS
# define __STDC_FORMAT_MACROS 1
#endif])

# Solaris 10 6/06 has a bug where /usr/sfw/lib/libstdc++.la is empty.
# If so, we replace it with our own version.
LIBSTDCXX_LA_LINKER_FLAG=
if test -f /usr/sfw/lib/libstdc++.la && ! test -s /usr/sfw/lib/libstdc++.la
then
  LIBSTDCXX_LA_LINKER_FLAG='-L$(top_srcdir)/src/solaris'
fi
AC_SUBST(LIBSTDCXX_LA_LINKER_FLAG)

# In theory, config.h files shouldn't need a header guard, but we do,
# because we (maybe) #include windows/mingw.h from within config.h,
# and it #includes other .h files.  These all have header guards, so
# the end result is if config.h is #included twice, its #undefs get
# evaluated twice, but all the ones in mingw.h/etc only get evaluated
# once, potentially causing trouble.  c.f.
#   http://code.google.com/p/gperftools/issues/detail?id=246
AH_TOP([
#ifndef GPERFTOOLS_CONFIG_H_
#define GPERFTOOLS_CONFIG_H_
])

# MinGW uses autoconf, but also needs the windows shim routines
# (since it doesn't have its own support for, say, pthreads).
# This requires us to #include a special header file, and also to
# link in some windows versions of .o's instead of the unix versions.
#
# Also, manually mark systems where we have to be careful how early
# we run pthreads.  TODO(csilvers): turn this into an autoconf check.
AH_BOTTOM([
#ifdef __MINGW32__
#include "windows/mingw.h"
#endif

#endif  /* #ifndef GPERFTOOLS_CONFIG_H_ */
])

# Write generated configuration file
AC_OUTPUT
