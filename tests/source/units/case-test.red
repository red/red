Red [
	Title:   "Red case function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %case-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015, Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "case"

===start-group=== "case basics"

	--test-- "case-basic-1"
	ci:  0
	cia: 1
	case [true [0]]
	--assert cia = 1
	
	--test-- "case-basic-2"
	ci:  1
	cia: 2
	case [ci = 1 [cia: 2]]
	--assert cia = 2
	
	--test-- "case-basic-3"
	ci:  1
	cia: 2
	case [true [cia: 3]]
	--assert cia = 3
	
	--test-- "case-basic-4"
	ci:  0
	cia: 2
	case [ci <> 0 [cia: 0] true [cia: 3]]
	--assert cia = 3
	
	--test-- "case-basic-5"
	ci:  99
	cia: 2
	case [ci = 1 [cia: 2] true [cia: 3]]
	--assert cia = 3
	
	--test-- "case-basic-6"
	ci:  0
	cia: 1
	cia: case [true [2]]
	--assert cia = 2
	
	--test-- "case-basic-7"
	ci:  0
	cia: 2
	cia: case [ci <> 0 [0] true [3]]
	--assert cia = 3
	
	--test-- "case-basic-8"
	ci:  1
	cia: 2
	cia: case [ci = 1 [3]]
	--assert cia = 3
	
	--test-- "case-basic-9"
	ci:  1
	cia: 2
	case [ci = 1 [case [ci <> 0 [cia: 3] true [cia: 4]]]]
	--assert cia = 3
	
	--test-- "case-basic-10"
	ci:  1
	cia: 2
	cia: case [ci = 1 [case [ci <> 0 [3] true [4]]]]
	--assert cia = 3
	
	--test-- "case-basic-11"
	ci:  1
	cia: 2
	cia: case [ci = 1 [switch/default ci [1 [3]][4]]]
	--assert cia = 3
	
===end-group===

===start-group=== "case basics local"

	case-fun: func [/local ci cia][
		--test-- "case-loc-1"
		ci:  0
		cia: 1
		case [true [0]]
		--assert cia = 1

		--test-- "case-loc-2"
		ci:  1
		cia: 2
		case [ci = 1 [cia: 2]]
		--assert cia = 2

		--test-- "case-loc-3"
		ci:  1
		cia: 2
		case [true [cia: 3]]
		--assert cia = 3

		--test-- "case-loc-4"
		ci:  0
		cia: 2
		case [ci <> 0 [cia: 0] true [cia: 3]]
		--assert cia = 3

		--test-- "case-loc-5"
		ci:  99
		cia: 2
		case [ci = 1 [cia: 2] true [cia: 3]]
		--assert cia = 3

		--test-- "case-loc-6"
		ci:  0
		cia: 1
		cia: case [true [2]]
		--assert cia = 2

		--test-- "case-loc-7"
		ci:  0
		cia: 2
		cia: case [ci <> 0 [0] true [3]]
		--assert cia = 3

		--test-- "case-loc-8"
		ci:  1
		cia: 2
		cia: case [ci = 1 [3]]
		--assert cia = 3

		--test-- "case-loc-9"
		ci:  1
		cia: 2
		case [ci = 1 [case [ci <> 0 [cia: 3] true [cia: 4]]]]
		--assert cia = 3

		--test-- "case-loc-10"
		ci:  1
		cia: 2
		cia: case [ci = 1 [case [ci <> 0 [3] true [4]]]]
		--assert cia = 3

		--test-- "case-loc-11"
		ci:  1
		cia: 2
		cia: case [ci = 1 [switch/default ci [1 [3]][4]]]
		--assert cia = 3
	]
	case-fun
	
===end-group===

===start-group=== "case integer!"
	
	--test-- "case-int-1"
	  ci: 1
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 1 = cia
	
	--test-- "case-int-2"
	  ci: 2
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 2 = cia
	
	--test-- "case-int-3"
	  ci: 3
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 3 = cia
	
	--test-- "case-int-4"
	  ci: 9
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	  --assert 3 = cia

	--test-- "case-int-5"
	  ci: 1
	--assert 1 = case [ ci = 1 [1] ci = 2 [2] true [3]]

	--test-- "case-int-6"
	  ci: 1
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 1 = cres
	
	--test-- "case-int-7"
	  ci: 2
	--assert 2 = case [ ci = 1 [1] ci = 2 [2] true [3]]
		
	--test-- "case-int-8"
	  ci: 2
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 2 = cres

	--test-- "case-int-9"
	  ci: 3
	--assert 3 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-10"
	  ci: 3
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 3 = cres
	
	--test-- "case-int-11"
	  ci: 10
	--assert 3 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-12"
	  ci: 10
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 3 = cres

	case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]

	--test-- "case-int-13"
	  ci: 1
	  cia: 0
	--assert 1 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-14"
	  ci: 1
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 1 = cres
	
	--test-- "case-int-15"
	  ci: 2
	  cia: 0
	--assert 2 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-16"
	  ci: 2
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 2 = cres
	
	--test-- "case-int-17"
	  ci: 3
	  cia: 0
	--assert 3 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-18"
	  ci: 3
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 3 = cres
	
	--test-- "case-int-19"
	  ci: 9
	  cia: 0
	--assert 3 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-20"
	  ci: 9
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 3 = cres
	
===end-group===


===start-group=== "case logic!"

  --test-- "case-logic-1"
    cl: true
  --assert case [ cl = true [true] cl = false [false] true [false]]
  
  --test-- "case-logic-2"
    cl: false
  --assert false = case [ cl = true [true] cl = false [false] true [true]]

===end-group===

===start-group=== "case reported issues"

	--test-- "case-issue-504"
	--assert 1 = case [true 1 false 2]
	
===end-group===	

~~~end-file~~~

