Red/System [
	Title:   "Red/System system test script"
	Author:  "Nenad Rakocevic"
	File: 	 %system-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "system"

===start-group=== "system/cpu/overflow?"

	;-- Use variables for operands to prevent constant folding.
	;-- Capture overflow? into a variable BEFORE calling --assert,
	;-- because on x64 the function call frame setup (SUB RSP) clobbers flags.

	--test-- "of-1"  x: 1          a: x + 2             of?: system/cpu/overflow?  --assert not of?
	--test-- "of-2"  x: 1000       a: x + 2000          of?: system/cpu/overflow?  --assert not of?
	--test-- "of-3"  x: 2000000000 a: x + 2000000000    of?: system/cpu/overflow?  --assert     of?
	--test-- "of-4"  x: -2000000000 a: x - 2000000000   of?: system/cpu/overflow?  --assert     of?
	--test-- "of-5"  x: 1000       a: x * 2000          of?: system/cpu/overflow?  --assert not of?
	--test-- "of-6"  x: 1000000    a: x * 2000000       of?: system/cpu/overflow?  --assert     of?
	--test-- "of-7"  x: 2147483647 a: x + 1             of?: system/cpu/overflow?  --assert     of?
	--test-- "of-8"  x: -2         a: x - 2147483647    of?: system/cpu/overflow?  --assert     of?
	--test-- "of-9"  x: -2147483648 a: x - 1            of?: system/cpu/overflow?  --assert     of?
	--test-- "of-10" x: 2147483647 a: x * 2             of?: system/cpu/overflow?  --assert     of?
	--test-- "of-11" x: 0          a: x + 0             of?: system/cpu/overflow?  --assert not of?
	--test-- "of-12" x: 0          a: x * 0             of?: system/cpu/overflow?  --assert not of?
	--test-- "of-13" x: 1          a: x * 0             of?: system/cpu/overflow?  --assert not of?
	--test-- "of-14" x: -2147483648 a: x * -1           of?: system/cpu/overflow?  --assert     of?
	--test-- "of-15" x: 2147483647 a: x / -1            of?: system/cpu/overflow?  --assert not of?

===end-group===

===start-group=== "system/stack/push-all pop-all"

	--test-- "save-all-1"
		#either target = 'IA-32 [
			aa: system/cpu/eax
			system/stack/push-all
			system/cpu/eax: 123
			system/stack/pop-all
			bb: system/cpu/eax
		][
			aa: system/cpu/r0
			system/stack/push-all
			system/cpu/r0: 123
			system/stack/pop-all
			bb: system/cpu/r0
		]
		--assert aa = bb

===end-group===

===start-group=== "system/stack/top and frame"

	--test-- "stack-top-1"
		st1: system/stack/top
		--assert st1 <> null

	--test-- "stack-frame-1"
		sf-fn: func [return: [int-ptr!] /local v [int-ptr!]][
			v: system/stack/frame
			v
		]
		--assert null <> sf-fn

	--test-- "stack-top-frame-diff"
		sf-fn2: func [return: [integer!] /local t [int-ptr!] f [int-ptr!]][
			t: system/stack/top
			f: system/stack/frame
			either t <> f [1][0]
		]
		--assert 1 = sf-fn2

===end-group===

===start-group=== "system/pc"

	--test-- "pc-1"
		pc1: system/pc
		--assert pc1 <> null

	--test-- "pc-2"
		pc2: system/pc
		pc3: system/pc
		--assert pc2 <> pc3

===end-group===

===start-group=== "system/stack/allocate and free"

	--test-- "alloc-1"
		alloc-test: func [
			return: [logic!]
			/local saved-sp [int-ptr!] buf [int-ptr!] restored-sp [int-ptr!]
		][
			saved-sp: system/stack/top
			buf: system/stack/allocate 10
			system/stack/free 10			
			restored-sp: system/stack/top
			saved-sp = restored-sp
		]
		--assert alloc-test

===end-group===

===start-group=== "system/cpu register read/write"

	--test-- "reg-rw-1"
		#either target = 'IA-32 [
			system/cpu/ecx: 42
			rcx-val: system/cpu/ecx
			--assert rcx-val = 42
		][
			system/cpu/r2: 42
			rcx-val: system/cpu/r2
			--assert rcx-val = 42
		]

===end-group===

~~~end-file~~~
