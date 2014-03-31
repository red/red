Red [
	Title:   "Red loops test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %loop-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
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

===end-group===

===start-group=== "mixed tests"

    --test-- "ml1"                      ;; Documenting non-local index counter
    a: 0
    repeat c 4 [
		loop 5 [a: a + 1]
	]
    --assert a = 20

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

===end-group===

~~~end-file~~~

