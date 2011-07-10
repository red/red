Red/System [
	Title:   "Red/System BSD common runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %BSD.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

;; sources:
;;	http://fxr.watson.org/fxr/source/sys/signal.h?v=FREEBSD82
;;  http://fxr.watson.org/fxr/source/sys/signal.h?v=NETBSD5
;;	http://fxr.watson.org/fxr/source/sys/signal.h?v=OPENBSD
;;  http://fxr.watson.org/fxr/source/bsd/sys/signal.h?v=xnu-1456.1.26;im=excerpts

#define	SIGILL		 4						;-- Illegal instruction
#define SIGBUS		10						;-- Bus access error
#define	SIGFPE		 8						;-- Floating point error
#define	SIGSEGV		11						;-- Segmentation violation
#define SIGSYS		12						;-- Non-existant system call


#define SA_SIGINFO   0040h
#define SA_RESTART   0002h

stdin:  0
stdout: 1
stderr: 2
