Red [
	Title:   "Red debase test script"
	Author:  "Peter W A Wood"
	File: 	 %debase-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "debase"

===start-group=== "debase 64"

	--test-- "debase 64 1"
		--assert strict-equal? "A simple string" to string! debase "QSBzaW1wbGUgc3RyaW5n"
	--test-- "debase 64 2"
		--assert strict-equal? "A multi-line\nstring" to string! debase "QSBtdWx0aS1saW5lXG5zdHJpbmc="
	--test-- "debase 64 3"
		--assert strict-equal? "A simple string" to string! debase/base "QSBzaW1wbGUgc3RyaW5n" 64
	--test-- "debase 64 4"
		--assert strict-equal? "A multi-line\nstring" to string! debase/base "QSBtdWx0aS1saW5lXG5zdHJpbmc=" 64
	--test-- "debase 64 5"
		--assert strict-equal? "A simple string" to string! debase/base "QSBzaW1wbGUgc3RyaW5n;^/" 64
	--test-- "debase 64 6"
		--assert strict-equal? "A simple string" to string! debase/base "QSBzaW1wb;i'm comment^/GUgc3RyaW5n" 64
	--test-- "debase 64 7"
		--assert strict-equal? "A simple string" to string! debase/base "QSBzaW1wbGUgc3RyaW5n;" 64

===end-group===

===start-group=== "debase 58"

	--test-- "debase 58 1"
		--assert strict-equal? "A simple string" to string! debase/base "2pgMs77CDKsWa7MuTCEMt" 58
	--test-- "debase 58 2"
		--assert strict-equal? "A multi-line\nstring" to string! debase/base "udEoBfTy3JKJJioNWAmmgSLsmbc" 58
	--test-- "debase 58 3"
		--assert strict-equal? "A simple string" to string! debase/base "2pgMs77CDKsWa7MuTCEMt;^/" 58
	--test-- "debase 58 4"
		--assert strict-equal? "A simple string" to string! debase/base "2pgMs77CD;i'm comment^/KsWa7MuTCEMt" 58
	--test-- "debase 58 5"
		--assert strict-equal? "A simple string" to string! debase/base "2pgMs77CDKsWa7MuTCEMt;" 58
	--test-- "debase 58 6"
		--assert strict-equal? #{000295EC35D638C16B25608B4E362A214A5692D2005677274F} debase/base "1EfxCKm257NbVJhJCVMzyhkvuJh1j6Zyx" 58

===end-group===

===start-group=== "debase 16"

	--test-- "debase 16 1"
		--assert strict-equal?
			"A simple string"
			to string! debase/base "412073696d706c6520737472696e67" 16
	--test-- "debase 16 2"
		--assert strict-equal?
			"A multi-line\nstring" 
			to string! debase/base "41206d756c74692d6c696e655c6e737472696e67" 16
	--test-- "debase 16 3"
		--assert strict-equal?
			"A simple string"
			to string! debase/base "412073696d706c6520737472696e67;^/" 16
	--test-- "debase 16 4"
		--assert strict-equal?
			"A simple string"
			to string! debase/base "412073696d7;i'm comment^/06c6520737472696e67" 16
	--test-- "debase 16 5"
		--assert strict-equal?
			"A simple string"
			to string! debase/base "412073696d706c6520737472696e67;" 16

===end-group===

===start-group=== "debase 2"

	--test-- "debase 2 1"
		--assert strict-equal?
			"^(04)^(01)"
			to string! debase/base "0000010000000001" 2

	--test-- "debase 2 2"
		--assert strict-equal?
			"^(04)^(01)"
			to string! debase/base "0000010000000001;^/" 2

	--test-- "debase 2 3"
		--assert strict-equal?
			"^(04)^(01)"
			to string! debase/base "0000010;i'm comment^/000000001" 2

	--test-- "debase 2 4"
		--assert strict-equal?
			"^(04)^(01)"
			to string! debase/base "0000010000000001;" 2

===end-group===

~~~end-file~~~