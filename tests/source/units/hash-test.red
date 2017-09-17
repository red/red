Red [
	Title:   "Red hash test script"
	Author:  "Maxim Velesyuk"
	File: 	 %hash-test.red
	Tabs:	   2
	Rights:  "Copyright (C) 2017 Maxim Velesyuk. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "hash"

===start-group=== "hash-make"
  --test-- "hash-make-1"
  --assert (make hash! [1 2 3 4]) = make hash! [1 2 3 4]
  --test-- "hash-make-2"
  --assert (make hash! [a 2 b 4]) = make hash! [a 2 b 4]
  --test-- "hash-make-3"
  --assert (make hash! [a 2 b 4]) = make hash! [b 4 a 2]
===end-group===

===start-group=== "hash->block"
  --test-- "hash->block-1"
  --assert [1 2 3 4] = to-block make hash! [1 2 3 4]
===end-group===

===start-group=== "hash<-block"
  --test-- "hash<-block-1"
  --assert (to-hash [1 2 3 4]) = make hash! [1 2 3 4]
===end-group===

===start-group=== "hash-type?"
  --test-- "hash-type-1"
  --assert hash! = type? make hash! [1 2 3 4]
  --test-- "hash-type-2"
  --assert hash! = type? to-hash [1 2 3 4]
===end-group===

===start-group=== "hash-length?"
  --test-- "hash-length-1"
  --assert 0 = length? make hash! []
  --test-- "hash-length-2"
  --assert 4 = length? make hash! [1 2 3 4]
===end-group===

===start-group=== "hash-put"
  --test-- "hash-put-1"
  hc1: make hash! []
  put hc1 'a 1
  --assert hc1 = make hash! [a 1]
  put hc1 2 3
  --assert hc1 = make hash! [a 1 2 3]
  --test-- "hash-put-2"
  hp2: make hash! [b 2]
  put hp2 'b 3
  --assert hp2 = make hash! [b 3]
  --test-- "hash-put-3"
  hp3: make hash! [b 2]
  put hp3 'a 1
  --assert hp3 = make hash! [b 2 a 1]
  put hp3 'a 4
  probe hp3
  --assert hp3 = make hash! [b 2 a 4]
  --test-- "hash-put-4"
  hp4: make hash! [b 2]
  --assert 2 = length? hp4
  put hp4 'a 1
  --assert 4 = length? hp4
===end-group===

===start-group=== "hash-select"
  --test-- "hash-select-1"
  hs1: make hash! [a 1]
  --assert 1 = select hs1 'a
  put hs1 'b 2
  --assert 2 = select hs1 'b
  --assert none? select hs1 'c
  --test-- "hash-select-2"
  hs2: make hash! []
  --assert none? select hs2 'a
  put hs2 'a 2
  --assert 2 = select hs2 'a
===end-group===

===start-group=== "hash find"
  --test-- "hash-find-1"
  hf1: make hash! [a 1]
  --assert (make hash! [a 1]) = find hf1 'a
  --assert none? find hf1 'b
  --test-- "hash-find-2"
  hf2: make hash! []
  --assert none? find hf2 'a
  put hf2 'a 2
  --assert (make hash! [a 2]) = find hf2 'a
===end-group===

===start-group=== "hash path notation"
  --test-- "hash-path-1"
  hp1: make hash! [a 1]
  --assert 1 = hp1/a
  put hp1 'a 5
  --assert 5 = hp1/a
  --test-- "hash-path-2"
  hp2: make hash! []
  --assert none? hp2/1
  put hp2 1 2
  --assert 1 = hp2/1
===end-group===

===start-group=== "hash-clear"
  --test-- "hash-clear-1"
  hc1: make hash! [a 1]
  --assert 2 = length? hc1
  clear hc1
  --assert 0 = length? hc1
  --assert hc1 = make hash! []
===end-group===

~~~end-file~~~

