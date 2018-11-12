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

~~~end-file~~~
