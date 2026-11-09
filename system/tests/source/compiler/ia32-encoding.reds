Red/System [
	Title:   "Red/System IA-32 instruction encoding test source"
	File: 	 %ia32-encoding.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;-- Compiled by ia32-encoding-test.r, which checks the emitted code; never run.

ia32-enc-state: 0
system/atomic/store :ia32-enc-state 1				;-- memory fence: no MFENCE below cpu-version 4.0
