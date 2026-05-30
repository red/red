Red/System [
	Title:   "Red/System variadic C-ABI argument-passing test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vararg-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

;-- Exercise the C variadic ABI through a cdecl vararg import (sprintf), then assert on the
;-- formatted result. This covers default argument promotion (float -> double), 64-bit
;-- register-pair / even-register alignment, and stack spill-over (and, on ARM, the SP
;-- alignment of the call) - all without depending on captured stdout.

vararg-buf: as c-string! allocate 256

streq?: func [a [c-string!] b [c-string!] return: [logic!] /local i [integer!]][
	i: 0
	until [
		i: i + 1
		any [a/i <> b/i  a/i = null-byte]	;-- stop at first difference or end of string
	]
	a/i = b/i								;-- equal only if both ended together
]

~~~start-file~~~ "variadic"

===start-group=== "variadic integer arguments (registers + stack spill)"
	--test-- "va-int-1"
		sprintf [vararg-buf "%d" 1]
		--assert streq? vararg-buf "1"
	--test-- "va-int-2"
		sprintf [vararg-buf "%d %d" 1 2]
		--assert streq? vararg-buf "1 2"
	--test-- "va-int-3"
		sprintf [vararg-buf "%d %d %d" 1 2 3]
		--assert streq? vararg-buf "1 2 3"
	--test-- "va-int-4"							;-- 4th integer spills onto the stack
		sprintf [vararg-buf "%d %d %d %d" 1 2 3 4]
		--assert streq? vararg-buf "1 2 3 4"
	--test-- "va-int-5"							;-- two integers spill onto the stack
		sprintf [vararg-buf "%d %d %d %d %d" 1 2 3 4 5]
		--assert streq? vararg-buf "1 2 3 4 5"
===end-group===

===start-group=== "variadic float (double) arguments"
	--test-- "va-dbl-1"
		sprintf [vararg-buf "%.2f" 1.5]
		--assert streq? vararg-buf "1.50"
	--test-- "va-int-dbl"
		sprintf [vararg-buf "%d %.2f" 1 2.5]
		--assert streq? vararg-buf "1 2.50"
	--test-- "va-dbl-dbl"
		sprintf [vararg-buf "%.2f %.2f" 1.5 2.5]
		--assert streq? vararg-buf "1.50 2.50"
===end-group===

===start-group=== "FP arg followed by a stacked arg (ARM AAPCS call-site SP alignment)"
	;-- Each of these has a 4-byte (integer) argument *after* a double, so the integer
	;-- spills to the stack and the call must keep SP 8-byte aligned. On ARM hard-float
	;-- these previously produced garbage (the double and every following argument were
	;-- misread by the variadic callee) because SP was left 4-byte aligned at the call.
	--test-- "va-dbl-int"
		sprintf [vararg-buf "%.2f %d" 1.5 9]
		--assert streq? vararg-buf "1.50 9"
	--test-- "va-int-dbl-int"
		sprintf [vararg-buf "%d %.2f %d" 42 3.14 7]
		--assert streq? vararg-buf "42 3.14 7"
	--test-- "va-2dbl-int"
		sprintf [vararg-buf "%.2f %.2f %d" 1.5 2.5 9]
		--assert streq? vararg-buf "1.50 2.50 9"
	--test-- "va-int-2dbl"
		sprintf [vararg-buf "%d %.2f %.2f" 7 1.5 2.5]
		--assert streq? vararg-buf "7 1.50 2.50"
===end-group===

~~~end-file~~~
