Red [
	Title:   "Red case folding test script"
	Author:  "Peter W A Wood"
	File: 	 %case-folding-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

do-fold: func [lower upper] [
	test-number: 0												;; no copy on purpose
	test-number: test-number + 1
	--test-- append "case-folding-" test-number
		--assert lower = upper
		--assert equal? lower upper
		--assert equal? uppercase lower upper
		--assert upper = uppercase lower
		--assert equal? lower lowercase upper
		--assert lower = lowercase upper
]

dont-fold: func [lower upper] [
	test-number: 0												;; no copy on purpose
	test-number: test-number + 1
	--test-- append "not-case-folding-" test-number
		--assert lower <> upper
		--assert not equal? lower upper
		--assert not equal? uppercase lower upper
		--assert upper <> uppercase lower
		--assert not equal? lower lowercase upper
		--assert lower <> lowercase upper
]

~~~start-file~~~ "case-folding"

===start-group=== "case-folding"
	
	do-fold "abcde" "ABCDE"
	do-fold "Abcde"	"ABCDE"
	do-fold "ba^(FB04)e" "BA^(FB04)E"
	do-fold "cant^(F9)" "CANT^(D9)"
	do-fold "cantu^(0300)" "CANTU^(0300)"
	do-fold "stra^(DF)e" "STRA^(1E9E)E"
	do-fold "i" "I"
	do-fold "^(0149)" "^(0149)"
	do-fold "^(03B0)" "^(03B0)"
	do-fold "^(0587)" "^(0587)"
	do-fold "^(1E96)" "^(1E96)"
	do-fold "^(1F80)" "^(1F80)"
	do-fold "^(1FBC)" "^(1FB3)"
	do-fold "^(1FBE)" "^(03B9)"
	do-fold "^(1FFC)" "^(1FF3)"
	do-fold "^(2126)" "^(03C9)"
	do-fold "^(2163)" "^(2173)"
	do-fold "^(00CE)" "^(00EE)"
	do-fold "^(0100)" "^(0101)"
	do-fold "^(017F)" "^(0073)"
	
===end-group===

===start-group=== "not-case-folding"
	
	dont-fold "ba^(FB04)e" "BAFFLE"
	dont-fold "stra^(DF)e" "STRASSE"
	dont-fold "weiss" "wie^(DF)"
	dont-fold "i" "^(0130)"
	dont-fold "^(0131)" "I"
	dont-fold "^(0149)" "^(02BC)^(6E)"
	dont-fold "^(03B0)" "^(03C5)^(0308)^(0301)"
	dont-fold "^(0587)" "^(0565)^(0582)"
	dont-fold "^(1E96)" "^(68)^(0331)"
	dont-fold "^(1F80)" "^(1F00)^(03B9)"
	dont-fold "^(1FBC)"	"^(03B1)^(03B9)"
	dont-fold "^(1FFC)" "^(03C9)^(03B9)"
	
===end-group===

~~~end-file~~~
