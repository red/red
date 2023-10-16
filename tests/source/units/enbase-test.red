Red [
	Title:   "Red enbase test script"
	Author:  "bitbegin"
	File: 	 %enbase-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "enbase"

===start-group=== "enbase 58"

	--test-- "enbase 58 1"
		--assert strict-equal? "2pgMs77CDKsWa7MuTCEMt" enbase/base "A simple string" 58
	--test-- "enbase 58 2"
		--assert strict-equal? "udEoBfTy3JKJJioNWAmmgSLsmbc" enbase/base "A multi-line\nstring" 58
	--test-- "enbase 58 3"
		--assert strict-equal? "1EfxCKm257NbVJhJCVMzyhkvuJh1j6Zyx" enbase/base #{000295EC35D638C16B25608B4E362A214A5692D2005677274F} 58

===end-group===

===start-group=== "enbase issue"

	--test-- "enbase issue #5404"
		#either config/target <> 'ARM [
			cnt: 1e6
		][
			cnt: 1e5
		]
		--assert [{6C6F72656D20697073756D20646F6C6F722073697420616D6574}] = unique loop cnt [append [] enbase/base to #{} {lorem ipsum dolor sit amet} 16]
		recycle		;-- clean up memory

===end-group===

~~~end-file~~~
