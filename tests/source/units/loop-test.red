Red [
	Title:   "Red loops test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %loop-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "loop"

===start-group=== "basic repeat tests"

  --test-- "br1"                      ;; Documenting non-local index counter
    br1-i: 0
    repeat br1-i 100 [ ]
  --assert 100 = br1-i                
  
  --test-- "br2"                      ;; Documenting non-local index counter
    br2-i: -99
    repeat br2-i 100 [ ]
  --assert 100 = br2-i 
  
  --test-- "br3"                      ;; Documenting non-local index counter
    repeat br3-i 100 [ ]
  --assert 100 = br3-i
  
  --test-- "br4"
    br4-i: 0
    repeat br4-counter 0 [br4-i: br4-i + 1]
  --assert 0 = br4-i

  --test-- "br5"
    br5-i: 0
    repeat br5-counter 0 [br5-i: br5-i + 1]
  --assert 0 = br5-i

  --test-- "br6"
    br6-i: 0
    repeat br6-counter -1 [br6-i: br6-i + 1]
  --assert 0 = br6-i

  --test-- "br7"
    br7-i: 0
    repeat br7-counter 3.5 [br7-i: br7-i + 1]
  --assert 3 = br7-i

  --test-- "br8"
    br8-i: 0
    repeat br8-counter 10 / 4 [br8-i: br8-i + 1]
  --assert 2 = br8-i
  
===end-group===

===start-group=== "advanced repeat tests"

	--test-- "repeat counter mess"
  		rcm-n: 0
		repeat rcm-i 10 [
			repeat rcm-i 5 [
				rcm-i: rcm-i + 3
				rcm-n: rcm-n + 1
			]
		]
		--assert 50 = rcm-n
		unset [rcm-i rcm-n]

===end-group===

===start-group=== "basic until tests"

  --test-- "bu1"
    bu1-i: 0
    until [
      bu1-i: bu1-i + 1
      bu1-i > 10
    ]
  --assert bu1-i = 11 
  
===end-group=== 

===start-group=== "basic loop tests"

  --test-- "bl1"                      ;; Documenting non-local index counter
    i: 10
    loop i [i: i - 1]
  --assert i = 0
  
  --test-- "bl2"                      ;; Documenting non-local index counter
    i: -1
    loop i [i: i + 1]
  --assert i = -1
  
  --test-- "bl3"                      ;; Documenting non-local index counter
    i: 0
    loop i [i: i + 1]
  --assert i = 0
  
  --test-- "b14"
    j: 0
    loop 0 [j: j + 1]
  --assert j = 0
  
  --test-- "b15"
    j: 0
    loop -1 [j: j + 1]
  --assert j = 0

  --test-- "b16"
    j: 0
    loop 3.8 [j: j + 1]
  --assert j = 3

 --test-- "b17"
    j: 0
    loop 10 / 4 [j: j + 1]
  --assert j = 2
  
===end-group===

===start-group=== "mixed tests"
        
    --test-- "ml1"                      ;; Documenting non-local index counter
    a: 0
    repeat c 4 [
		loop 5 [a: a + 1]
	]
    --assert a = 20 

===end-group===

===start-group=== "exceptions"

	--test-- "ex1"
	i: 0
	loop 3 [i: i + 1 break i: i - 1]
	--assert i = 1
	
	--test-- "ex2"
	i: 0
	loop 3 [i: i + 1 continue i: i - 1]
	--assert i = 3
	
	--test-- "ex3"
	i: 4
	until [
		i: i - 1
		either i > 2 [continue][break]
		zero? i
	]
	--assert i = 2
	
	--test-- "ex4"
	list: [a b c]
	while [not tail? list][list: next list break]
	--assert list = [b c]
	
	--test-- "ex5"
	c: none
	repeat c 3 [either c = 1 [continue][break]]
	--assert c = 2
	
	--test-- "ex6"
	w: result: none
	foreach w [a b c][result: w either w = 'a [continue][break]]
	--assert result = 'b
	
	--test-- "ex7"
	i: 0
	loop 3 [i: i + 1 parse "1" [(break)] i: i - 1]
	--assert i = 1
	
	--test-- "ex8"
	foo-ex2: does [parse "1" [(return 124)]]
	--assert foo-ex2 = 124

===end-group===

===start-group=== "foreach"

	--test-- "foreach-1"
		fe1-b: compose [
			11 #"v" 22 #"t" 33 #"z" "string" (func[] [1])
			(make object! [i: 1])
		]
		fe1-count: 0
		foreach fe1-val fe1-b [
			fe1-count: fe1-count + 1
		]
		--assert 9 = fe1-count
		--assert 11 = first fe1-b
		--assert 9 = length? fe1-b

===end-group===

===start-group=== "forall"

	--test-- "forall-1"
		fa1-b: compose [
			11 #"v" 22 #"t" 33 #"z" "string" (func[] [1])
			(make object! [i: 1])
		]
		fa1-count: 0
		forall fa1-b [
			--assert (9 - fa1-count) = length? fa1-b
			fa1-count: fa1-count + 1
		]
		--assert 9 = fa1-count
		--assert 9 = length? fa1-b
		--assert 11 = first fa1-b

===end-group===


===start-group=== "invalid usage"

	--test-- "invalid until-1"
		--assert error? try [until []]

	--test-- "invalid foreach-1 (issue #3380)"
		--assert not error? try [foreach [x] [] [2]]
		;-- `do` is required because the compiler won't accept an empty block:
		--assert error? try [do [foreach [] [1] [2]]]
		--assert error? try [do [foreach [] [] [2]]]
		--assert error? try [foreach (tail [1]) [1] [2]]

===end-group===

===start-group=== "specific issues"

  --test-- "issue #427-1"
    issue427-acc: 0
    issue427-f: func [
      /local count
    ][
      count: #"a"
      repeat count 5 [
        issue427-acc: issue427-acc + count
      ]
      count
    ]
  --assert 5  = issue427-f
  --assert 15 = issue427-acc
  
  --test-- "issue #427-2"
    issue427-acc: 0
    issue427-f: func [
      /local count
    ][
      repeat count 5 [
        issue427-acc: issue427-acc + count
      ]
    ]
    issue427-f
  --assert 15 = issue427-acc

	--test-- "issue #3361"
  		s3361: copy []
		f3361: func [n /local i] [
			repeat i 3 [
				repend s3361 [n i]
				all [i = 1 n = 1 f3361 2]
				all [i = 2 n = 2 f3361 3]
			]
		]
		f3361 1
		--assert s3361 = [1 1  2 1 2 2  3 1 3 2 3 3  2 3  1 2 1 3]
		unset [f3361 s3361]

===end-group===
    
~~~end-file~~~
