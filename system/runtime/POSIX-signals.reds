Red/System [
	Title:  "Red/System POSIX signal number definitions"
	Author: "Richard Nyberg"
	File:   %POSIX-signals.reds
	Tabs:   4
	Rights: "Copyright (C) 2014-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]
;; sources:
;;  http://fxr.watson.org/fxr/source/include/uapi/asm-generic/siginfo.h?v=linux-2.6;im=excerpts
;;  http://fxr.watson.org/fxr/source/sys/signal.h?v=FREEBSD10
;;  http://fxr.watson.org/fxr/source/bsd/sys/signal.h?v=xnu-1456.1.26;im=excerpts

#define SIGBUS [                            ;-- Bus access error
	#switch OS [MacOSX [10] FreeBSD [10] #default [7]]
]
#define SIGILL       4                      ;-- Illegal instruction
#define SIGFPE       8                      ;-- Floating point error
#define SIGSEGV     11                      ;-- Segmentation violation
#define SIGWINCH	28						;-- Console window resizing

#define SA_SIGINFO   [#switch OS [MacOSX [0040h] FreeBSD [0040h] #default [00000004h]]]
#define SA_RESTART   [#switch OS [MacOSX [0002h] FreeBSD [0002h] #default [10000000h]]]

#define ILL_ILLOPC   1
#define ILL_ILLOPN   [#switch OS [MacOSX [4] #default [2]]]
#define ILL_ILLADR   [#switch OS [MacOSX [5] #default [3]]]
#define ILL_ILLTRP   [#switch OS [MacOSX [2] #default [4]]]
#define ILL_PRVOPC   [#switch OS [MacOSX [3] #default [5]]]
#define ILL_PRVREG   6
#define ILL_COPROC   7
#define ILL_BADSTK   8

#define BUS_ADRALN   1
#define BUS_ADRERR   2
#define BUS_OBJERR   3
#define BUS_MCERR_AR 4                      ;-- Linux based systems only
#define BUS_MCERR_AO 5                      ;-- Linux based systems only

#define SEGV_MAPERR  1
#define SEGV_ACCERR  2

#define FPE_INTDIV   [#switch OS [MacOSX [7] FreeBSD [2] #default [1]]]
#define FPE_INTOVF   [#switch OS [MacOSX [8] FreeBSD [1] #default [2]]]
#define FPE_FLTDIV   [#switch OS [MacOSX [1] #default [3]]]
#define FPE_FLTOVF   [#switch OS [MacOSX [2] #default [4]]]
#define FPE_FLTUND   [#switch OS [MacOSX [3] #default [5]]]
#define FPE_FLTRES   [#switch OS [MacOSX [4] #default [6]]]
#define FPE_FLTINV   [#switch OS [MacOSX [5] #default [7]]]
#define FPE_FLTSUB   [#switch OS [MacOSX [6] #default [8]]]
