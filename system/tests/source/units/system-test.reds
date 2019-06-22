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

	--test-- "of-1"  a: 0 + 0  a: 1 + 2					   --assert not system/cpu/overflow?
	--test-- "of-2"  a: 0 + 0  a: 1000 + 2000			   --assert not system/cpu/overflow?
	--test-- "of-3"  a: 0 + 0  a: 2000000000 + 2000000000  --assert		system/cpu/overflow?
	--test-- "of-4"  a: 0 + 0  a: -2000000000 - 2000000000 --assert		system/cpu/overflow?
	--test-- "of-5"  a: 0 + 0  a: 1000 * 2000			   --assert not system/cpu/overflow?
	--test-- "of-6"  a: 0 + 0  a: 1000000 * 2000000		   --assert		system/cpu/overflow?
	--test-- "of-7"  a: 0 + 0  a: 2147483647 + 1		   --assert		system/cpu/overflow?
	--test-- "of-8"  a: 0 + 0  a: -2 - 2147483647		   --assert		system/cpu/overflow?
	--test-- "of-9"  a: 0 + 0  a: -2147483648 - 1		   --assert		system/cpu/overflow?
	--test-- "of-10" a: 0 + 0  a: 2147483647 * 2		   --assert		system/cpu/overflow?
	--test-- "of-11" a: 0 + 0  a: 0 + 0					   --assert not system/cpu/overflow?
	--test-- "of-12" a: 0 + 0  a: 0 * 0					   --assert not system/cpu/overflow?
	--test-- "of-13" a: 0 + 0  a: 1 * 0					   --assert not system/cpu/overflow?
	--test-- "of-14" a: 0 + 0  a: -2147483648 * -1		   --assert     system/cpu/overflow?
    --test-- "of-15" a: 0 + 0  a: 2147483647 / -1		   --assert not system/cpu/overflow?
    ;--test-- "of-16" a: 0 + 0  a: -2147483648 / -1		   --assert     system/cpu/overflow?
    ;                                                      raises divide overflow error
    
===end-group===

===start-group=== "system/stack/*-all"

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

  
~~~end-file~~~

