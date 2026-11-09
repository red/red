REBOL [
	Title:   "Red/System IA-32 instruction encoding test script"
	File: 	 %ia32-encoding-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;; Compiles %ia32-encoding.reds for MSDOS-Old (cpu-version 1.0) and MSDOS, then checks the emitted
;; code: CPUs without SSE2 (before the Pentium 4) have no MFENCE.

~~~start-file~~~ "IA-32 encodings"

	ia32-enc-flag: qt/compile-flag
	ia32-enc-file: join qt/runnable-dir %ia32-encoding.exe		;-- PE outputs always end in .exe
	qt/compile-flag: join ia32-enc-flag " -t MSDOS-Old "
	ia32-enc-old?: --compile %source/compiler/ia32-encoding.reds
	ia32-enc-old: either ia32-enc-old? [read/binary ia32-enc-file][#{}]
	qt/compile-flag: join ia32-enc-flag " -t MSDOS "
	ia32-enc-new?: --compile %source/compiler/ia32-encoding.reds
	ia32-enc-new: either ia32-enc-new? [read/binary ia32-enc-file][#{}]
	qt/compile-flag: ia32-enc-flag

	--test-- "ia32-enc-1 compiles for MSDOS-Old and MSDOS"
		--assert none <> ia32-enc-old?
		--assert none <> ia32-enc-new?

	--test-- "ia32-enc-2 memory fence below cpu-version 4.0"
		--assert none <> find ia32-enc-old #{F0830C2400}			;-- LOCK OR dword [esp], 0
		--assert none =  find ia32-enc-old #{0FAEF0}				;-- MFENCE needs SSE2
		--assert none <> find ia32-enc-new #{0FAEF0}

	if exists? ia32-enc-file [attempt [delete ia32-enc-file]]

~~~end-file~~~
