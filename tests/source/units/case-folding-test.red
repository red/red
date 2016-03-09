Red [
	Title:   "Red case folding test script"
	Author:  "Peter W A Wood"
	File: 	 %case-folding-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "case-folding"

do-test-number: 0
dont-test-number: 0

do-fold: func [lower upper] [
	do-test-number: do-test-number + 1
	--test-- append copy "case-folding-" do-test-number
		--assert lower = upper
		--assert equal? lower upper
		--assert strict-equal? uppercase copy lower upper
		--assert upper == uppercase copy lower
		--assert strict-equal? lower lowercase copy upper
		--assert lower == lowercase copy upper
]

dont-fold: func [lower upper] [
	dont-test-number: dont-test-number + 1
	--test-- append copy "not-case-folding-" dont-test-number
		--assert lower <> upper
		--assert not equal? lower upper
		--assert not equal? uppercase copy lower upper
		--assert upper <> uppercase copy lower
		--assert not equal? lower lowercase copy upper
		--assert lower <> lowercase copy upper
]

===start-group=== "case-folding"
	
	do-fold "abcde" "ABCDE"
	do-fold "ba^(FB04)e" "BA^(FB04)E"
	do-fold "cant^(F9)" "CANT^(D9)"
	do-fold "cantu^(0300)" "CANTU^(0300)"
	do-fold "stra^(DF)e" "STRA^(1E9E)E"
	do-fold "i" "I"
	do-fold "^(0149)" "^(0149)"
	do-fold "^(03B0)" "^(03B0)"
	do-fold "^(0587)" "^(0587)"
	do-fold "^(1E96)" "^(1E96)"
	do-fold "^(1F80)" "^(1F88)"
	do-fold "^(1FB3)" "^(1FBC)"
	do-fold "^(03B9)" "^(1FBE)"
	do-fold "^(1FF3)" "^(1FFC)"
	do-fold "^(03C9)" "^(2126)"
	do-fold "^(2173)" "^(2163)"
	do-fold "^(EE)" "^(CE)"
	do-fold "^(0101)" "^(0100)"
	
===end-group===

===start-group=== "not-case-folding"
	
	dont-fold "ba^(FB04)e" "BAFFLE"
	dont-fold "stra^(DF)e" "STRASSE"
	dont-fold "weiss" "wie^(DF)"
	dont-fold "i" "^(0130)"
	dont-fold "^(0131)" "I"
	dont-fold "^(0149)" "^(02BC)^(6E)"
	dont-fold "^(03C5)^(0308)^(0301)" "^(03B0)"
	dont-fold "^(0565)^(0582)" "^(0587)"
	dont-fold "^(1E96)" "^(68)^(0331)"
	dont-fold "^(1F80)" "^(1F00)^(03B9)"
	dont-fold "^(03B1)^(03B9)" "^(1FBC)"
	dont-fold "^(03C9)^(03B9)" "^(1FFC)"
	
===end-group===

===start-group=== "manual case folding"

	--test-- "manual-case-folding-1"
		--assert "abcde" = "aBCDE"
		--assert equal? "abcde" "aBCDE"
		--assert strict-equal? lowercase "aBCDE" "abcde"
		--assert "abcde" == lowercase "aBCDE"
		
	--test-- "manual-case-folding-2"
		--assert "Abcde" = "ABCDE"
		--assert equal? "Abcde" "ABCDE"
		--assert strict-equal? uppercase "Abcde" "ABCDE"
		--assert "ABCDE" == uppercase "Abcde"
		
	--test-- "manual-case-folding-3"
		--assert "s" = "^(017F)"
		--assert "S" = "^(017F)"
		--assert "s" = "S"
		--assert "S" == uppercase "^(017F)"
		--assert "^(017F)" == lowercase "^(017F)"
		--assert "s" == lowercase "S"
		--assert "S" == uppercase "s"
		
===end-group===

~~~end-file~~~
