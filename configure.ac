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

# We want to access the "PC" (Program Counter) register from a struct
# ucontext.  Every system has its own way of doing that.  We try all the
# possibilities we know about.  Note REG_PC should come first (REG_RIP
# is also defined on solaris, but does the wrong thing).  But don't
# bother if we're not doing cpu-profiling.
# [*] means that we've not actually tested one of these systems
AC_PC_FROM_UCONTEXT(AC_MSG_WARN(Could not find the PC))

# Also make sure we get standard PRI... definitions, even with glibc.
# We have to use AH_VERBATIM because we need the #ifdef guard (gcc buglet)
AH_VERBATIM([__STDC_FORMAT_MACROS],
            [/* C99 says: define this to get the PRI... macros from stdint.h */
#ifndef __STDC_FORMAT_MACROS
# define __STDC_FORMAT_MACROS 1
#endif])

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

# Ask R for the C++ configuration.
if test -z "${R_HOME}"; then
    AC_MSG_ERROR([Could not determine R_HOME.])
fi
CPPFLAGS=`"${R_HOME}/bin/R" CMD config CPPFLAGS`
CXX=`"${R_HOME}/bin/R" CMD config CXX`
CXXFLAGS=`"${R_HOME}/bin/R" CMD config CXXFLAGS`
AC_LANG(C++)
AC_PROG_CXX

# Ensure we have libprofiler.
#
# First, try to use pkg-config, which is the best option when available,
# otherwise fall back on AC_CHECK_HEADERS and generic cpp/linker flags.
have_libprofiler=no
LIBPROFILER_CXXFLAGS=""
LIBPROFILER_LIBS="-lprofiler"

PKG_PROG_PKG_CONFIG

if test [ -n "$PKG_CONFIG" ] ; then
  AC_MSG_CHECKING([pkg-config for libprofiler])
  if $PKG_CONFIG --exists libprofiler; then
    have_libprofiler=yes
    LIBPROFILER_CXXFLAGS=`"${PKG_CONFIG}" --cflags libprofiler`
    LIBPROFILER_LIBS=`"${PKG_CONFIG}" --libs libprofiler`
  fi
  AC_MSG_RESULT([${have_libprofiler}])
fi

if test "x${have_libprofiler}" = xno; then
  AC_CHECK_HEADERS([gperftools/stacktrace.h],[have_libprofiler=yes])
fi

if test "x${have_libprofiler}" = xno; then
  AC_MSG_FAILURE([
  ---------------------------------------------
   'libprofiler' and its header files from Google's 'gperftools'
   suite are required.

   Please install:

   * libgoogle-perftools-dev (on Debian and Ubuntu)
   * gperftools-devel (on Fedora, CentOS and RHEL)
   * gperftools (on Arch)

   and try again.

   If you believe this library is installed on your system but
   this script is simply unable to find it, you can specify the
   include and lib paths manually:

   R CMD INSTALL ${PACKAGE_NAME} \\
     --configure-vars='LIBS=-L/path/to/libs CPPFLAGS=-I/path/to/headers'
  ---------------------------------------------])
fi

# Write generated files
AC_SUBST([PKG_CPPFLAGS],["${PKG_CPPFLAGS} ${LIBPROFILER_CXXFLAGS}"])
AC_SUBST([PKG_LIBS],["${PKG_LIBS} ${LIBPROFILER_LIBS}"])
AC_CONFIG_FILES([src/Makevars])
AC_OUTPUT

echo "
${PACKAGE_NAME} $PACKAGE_VERSION
================

cppflags: ${PKG_CPPFLAGS}
libs: ${PKG_LIBS}
"
