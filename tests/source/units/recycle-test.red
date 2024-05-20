Red [
	Title:   "Red recycle test script"
	Author:  "Peter W A Wood"
	File: 	 %recycle-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "recycle test"

===start-group=== "recycle block"
	
	--test-- "recycle-block-1"
		rb1-mem: none
		rb1-mem2: none
		recycle				
		rb1-mem: stats
		
		rb1-b: make block! [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20] 
		rb1-b: none
		recycle
		
		rb1-mem2: stats
		--assert rb1-mem2 <= rb1-mem
		
	--test-- "recycle-block-2"
		rb2-mem: none
		rb2-mem2: none
		rb2-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		loop 1000 [rb2-b: copy rb2-b]
		recycle
		rb2-mem: stats
		
		loop 1000 [rb2-b: copy rb2-b]
		recycle
		
		rb2-mem2: stats
		--assert rb2-mem2 <= rb2-mem
		
	--test-- "recycle-block-3"
		rb3-mem: none
		rb3-mem2: none
		rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		recycle
		rb3-mem: stats
		
		loop 2000 [
			rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		]
		recycle
		
		rb3-mem2: stats
		--assert rb3-mem2 <= rb3-mem
	
	--test-- "recycle-block-4"
		rb4-mem: none
		rb4-mem2: none
		rb4-bb: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb4-bb rb4-bb]
		rb4-b: copy rb4-bb
		recycle
		rb4-mem: stats
		
		loop 2000 [
			rb4-b: copy rb4-bb
			recycle
		]
		rb4-b: none
		recycle
		
		rb4-mem2: stats
		--assert rb4-mem2 <= rb4-mem

	--test-- "recycle-block-5"
		rb5-mem: none
		rb5-mem2: none
		rb5-m: #[b: [1 2 3 4 5 6 7 8 9 10]]
		recycle
		rb5-mem: stats
		
		loop 2000 [ rb5-m/b: copy [1 2 3 4 5 6 7 8 9 10] ]
		recycle
		
		rb5-mem2: stats
		--assert rb5-mem2 <= rb5-mem
	
	--test-- "recycle-block-6"
		rb6-mem: none
		rb6-mem2: none
		rb6-o: make object! [ b: copy [1 2 3 4 5 6 7 8 9 10] ]
		recycle
		rb6-mem: stats
		
		loop 2000 [ rb6-o/b: copy [1 2 3 4 5 6 7 8 9 20] ]
		recycle
		
		rb6-mem2: stats
		--assert rb6-mem2 <= rb6-mem
		
		--test-- "recycle-block-7"
		rb7-mem: none
		rb7-mem2: none
		rb7-b: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb7-b rb7-b]
		rb7-bbbbb: compose [bbbb [bbb [bb [b (copy rb7-b)]]]]
		recycle
		rb7-mem: stats
		
		rb7-bbbbb/bbbb/bbb/bb/b: none
		recycle
		
		rb7-mem2: stats
		--assert rb7-mem2 <= rb7-mem
		
	--test-- "recycle-block-8"
		clear []
		rb8-mem: none
		rb8-mem2: none
		rb8-b: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb8-b rb8-b]
		recycle
		rb8-mem: stats
		
		clear rb8-b
		recycle
		
		rb8-mem2: stats
		--assert rb8-mem2 <= rb8-mem
		
	--test-- "recycle-block-9"
		rb9-mem: none
		rb9-mem2: none
		rb9-b: []
		loop 100 [append/only rb9-b copy [1 2 3 4 5 6 7 8 9 10]]
		recycle
		rb9-mem: stats
		
		remove/part rb9-b 50
		recycle
		
		rb9-mem2: stats
		--assert rb9-mem2 <= rb9-mem
		

	--test-- "recycle-block-10"
		rb10-mem: none
		rb10-mem2: none
		rb10-b: make block! 100
		loop 100 [ append rb10-b copy "12345678901234567890" ]
		recycle
		rb10-mem: stats
		
		remove/part rb10-b 50
		recycle
		
		rb10-mem2: stats
		--assert rb10-mem2 <= rb10-mem
	
	--test-- "recycle-block-11"
		rb11-mem: none
		rb11-mem2: none
		rb11-b: make block! 100
		loop 100 [append/only rb11-b copy [1 2 3 4 5 6 7 8 9 10]]
		recycle
		rb11-mem: stats
		
		remove/part skip rb11-b 50 50				;-- discard 2nd half
		recycle
		
		rb11-mem2: stats
		--assert rb11-mem2 <= rb11-mem
		
	--test-- "recycle-block-12"
		rb12-mem: none
		rb12-mem2: none
		rb12-b: make block! 100000
		rb12-s: "abcde"
		recycle
		rb12-mem: stats
		
		loop 100000 [ append rb12-b copy rb12-s ]
		loop 100000 [ remove rb12-b ]
		recycle
		
		rb12-mem2: stats
		--assert rb12-mem2 <= rb12-mem
		
	--test-- "Recycle-block-13"
		rb13-mem: none
		rb13-mem2: none
		rb13-b: [[[[[[[[[[[[[[[[[[[[[s: none]]]]]]]]]]]]]]]]]]]]]
		rb13-s: "1234567890"
		loop 10 [ append rb13-s rb13-s ]
		recycle
		rb13-mem: stats
		
		rb13-b/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/s: copy rb13-s
		rb13-b/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/1/s: none
		recycle
		
		rb13-mem2: stats
		--assert rb13-mem2 <= rb13-mem
		
===end-group===

===start-group=== "recycle map"

	--test-- "recycle-map-1"
		rm1-mem: none
		rm1-mem2: none
		rm1-map: none
		recycle
		rm1-mem: stats
		
		rm1-map: #[a: 1 b: 2 c: 3 d: 4]
		rm1-map: none
		
		recycle
		rm1-mem2: stats
		--assert rm1-mem2 <= rm1-mem
	--test-- "recycle-map-2"
		rm2-mem: none
		rm2-mem2: none
		rm2-map: none
		recycle
		rm2-mem: stats
		
		rm2-map: make map! [ a: 1 b: [ 1 2 3 4 5 6 7 8 9 10 ] ]
		rm2-map: none
		recycle
		
		rm2-mem2: stats
		--assert rm2-mem2 <= rm2-mem
		
	--test-- "recycle-map-3"
		rm3-mem: none
		rm3-mem2: none
		rm3-map: none
		rm3-map-1: make map! [ a: 1 b: [ 1 2 3 4 5 6 7 8 9 10 ] ]
		rm3-map-2: copy rm3-map-1
		rm3-map-3: copy rm3-map-1
		rm3-map-4: copy rm3-map-1
		recycle
		rm3-mem: stats
		
		rm3-map: make map! [
			a: rm3-map-1
			b: rm3-map-2
			c: rm3-map-3
			d: rm3-map-4
		]
		rm3-map: none
		recycle
		
		rm3-mem2: stats
		--assert rm3-mem2 <= rm3-mem
		
	--test-- "recycle-map-4"
		rm4-mem: none
		rm4-mem2: none
		rm4-map-1: make map! [ a: 1 b: [ 1 2 3 4 5 6 7 8 9 10 ] ]
		rm4-map-2: copy rm4-map-1
		rm4-map-3: copy rm4-map-1
		rm4-map-4: copy rm4-map-1
		rm4-map: make map! compose [
			a: (copy rm4-map-1)
			b: (copy rm4-map-2)
			c: (copy rm4-map-3)
			d: (copy rm4-map-4)
		]

		rm4-mem: stats

		rm4-map/a: none
		rm4-map/b: none
		rm4-map/c: none
		rm4-map/d: none
		recycle
		
		rm4-mem2: stats
		--assert rm4-mem2 <= rm4-mem

		--test-- "recycle-map-5"
		rm5-mem: none
		rm5-mem2: none
		rm5-map: #[a: 1 b: 2 c: 3 d: 4]
		rm5-str: "12345678901234567890"
		recycle
		rm5-mem: stats
		
		rm5-map/a: (copy rm5-str)
		rm5-map/b: (copy rm5-str)
		rm5-map/c: (copy rm5-str)
		rm5-map/d: (copy rm5-str)
		rm5-map/a: none
		rm5-map/b: none
		rm5-map/c: none
		rm5-map/d: none
		recycle
		
		rm5-mem2: stats
		--assert rm5-mem2 <= rm5-mem

	--test-- "recycle-map-6"
		rm6-mem: none
		rm6-mem2: none
		rm6-map: #[
			a: 1 b: 2 c: 3 d: 4 e: 5 f: 6
			g: 7 h: 8 i: 9 j: 10 k: 11 l: 12
		]
		rm6-str: "12345678901234567890"
		loop 10 [ append rm6-str rm6-str ]
		recycle
		rm6-mem: stats
		
		rm6-map/a: (copy rm6-str)
		rm6-map/b: (copy rm6-str)
		rm6-map/c: (copy rm6-str)
		rm6-map/d: (copy rm6-str)
		rm6-map/e: (copy rm6-str)
		rm6-map/f: (copy rm6-str)
		rm6-map/g: (copy rm6-str)
		rm6-map/h: (copy rm6-str)
		rm6-map/i: (copy rm6-str)
		rm6-map/j: (copy rm6-str)
		rm6-map/k: (copy rm6-str)
		rm6-map/l: (copy rm6-str)
		rm6-map/a: none
		rm6-map/b: none
		rm6-map/c: none
		rm6-map/d: none
		rm6-map/e: none
		rm6-map/f: none
		rm6-map/g: none
		rm6-map/h: none
		rm6-map/i: none
		rm6-map/j: none
		rm6-map/k: none
		rm6-map/l: none
		recycle
		
		rm6-mem2: stats
		--assert rm6-mem2 <= rm6-mem
		
	--test-- "recycle-map-7"
		rm7-mem: none
		rm7-mem2: none
		rm7-map: none
		rm7-str: "12345678901234567890"
		loop 10 [ append rm7-str rm7-str ]
		recycle
		rm7-mem: stats
		
		rm7-map: make map! compose [
			a: (copy rm7-str)
			b: (copy rm7-str)
			c: (copy rm7-str)
			d: (copy rm7-str)
			e: (copy rm7-str)
			f: (copy rm7-str)
			g: (copy rm7-str)
			h: (copy rm7-str)
			i: (copy rm7-str)
			j: (copy rm7-str)
			k: (copy rm7-str)
			l: (copy rm7-str)
		]
		rm7-map: none
		recycle
		
		rm7-mem2: stats
		--assert rm7-mem2 <= rm7-mem
		
	--test-- "recycle-map-8"
		rm8-mem: none
		rm8-mem2: none
		rm8-map: #[
			a: "" b: "" c: "" d: "" e: "" f: ""
			g: "" h: "" i: "" j: "" k: "" l: ""
		]
		rm8-str: append make string! 200 "12345678901234567890"
		loop 10 [ append rm8-str rm8-str ]
		recycle
		rm8-mem: stats
		
		rm8-map/a: rm8-str
		rm8-map/b: rm8-str
		rm8-map/c: rm8-str
		rm8-map/d: rm8-str
		rm8-map/e: rm8-str
		rm8-map/f: rm8-str
		rm8-map/g: rm8-str
		rm8-map/h: rm8-str
		rm8-map/i: rm8-str
		rm8-map/j: rm8-str
		rm8-map/k: rm8-str
		rm8-map/l: rm8-str
		rm8-str: none
		recycle
		
		rm8-mem2: stats
		--assert rm8-mem2 <= rm8-mem
		
		
===end-group===

===start-group=== "recycle hash"

	--test-- "recycle-hash-1"
		rh1-mem: none
		rh1-mem2: none
		rh1-hash: none
		recycle
		rh1-mem: stats
		
		rh1-hash: make hash! [1 2 3 4 5 6 7 8 9 10]
		rh1-hash: none
		recycle
		
		rh1-mem2: stats
		--assert rh1-mem2 <= rh1-mem	

	;--test-- "recycle-hash-2"
	;	rh2-mem: none
	;	rh2-mem2: none
	;	rh2-hash: make hash! [a 1]
	;	rh2-blk: []
	;	loop 20 [ append/only rh2-blk [1 2 3 4 5 6 7 8 9 10]]
	;	recycle
	;	rh2-mem: stats
		
	;	rh2-hash/a: copy rh2-blk 
	;	rh2-hash/a: none
	;	recycle
		
	;	rh2-mem2: stats
	;	--assert rh2-mem2 <= rh2-mem
		
	;--test-- "recycle-hash-3"
	;	rh3-mem: none
	;	rh3-mem2: none
	;	rh3-hash: make hash! [a 1 b 2]
	;	rh3-blk: []
	;	loop 20 [ append/only rh3-blk [1 2 3 4 5 6 7 8 9 10]]
	;	recycle
	;	rh3-mem: stats
		
	;	rh3-hash/a: copy rh3-blk
	;	rh3-hash/b: copy rh3-blk
	;	rh3-hash/a: none
	;	rh3-hash/b: none
	;	recycle
		
	;	rh3-mem2: stats
	;	--assert rh3-mem2 <= rh3-mem

	--test-- "recycle-hash-4"
		rh4-mem: none
		rh4-mem2: none
		rh4-hash: none
		rh4-blk: []
		loop 20 [ append/only rh4-blk [1 2 3 4 5 6 7 8 9 10]]
		recycle
		rh4-mem: stats
		
		rh4-hash: make hash! compose [ a (copy rh4-blk) b (copy rh4-blk) ]
		rh4-hash: none
		recycle
		
		rh4-mem2: stats
		--assert rh4-mem2 <= rh4-mem
		
	;--test-- "recycle-hash-5"
	;	rh5-mem: none
	;	rh5-mem2: none
	;	rh5-hash: make hash! [ a [] b [] ]
	;	rh5-blk: make block! 200
	;	loop 20 [ append/only rh5-blk [1 2 3 4 5 6 7 8 9 10] ]
	;	recycle
	;	rh5-mem: stats
		
	;	rh5-hash/a: rh5-blk
	;	rh5-hash/b: none
	;	recycle
		
	;	rh5-mem2: stats
	;	--assert rh5-mem2 <= rh5-mem
		
	--test-- "recycle-hash-6"
		rh6-mem: none
		rh6-mem2: none
		rh6-b: make block! 100
		loop 100 [ append/only rh6-b copy [1 2 3 4 5 6 7 8 9 10] ]
		rh6-hash: make hash! rh6-b
		rh6-b: none
		recycle
		rh6-mem: stats
		
		remove/part rh6-hash 50
		recycle
		
		rh6-mem2: stats
		;--assert rh6-mem2 <= rh6-mem
	
	--test-- "recycle-hash-7"
		rh7-mem: none
		rh7-mem2: none
		rh7-b: make block! 100
		loop 100 [ append/only rh7-b copy [1 2 3 4 5 6 7 8 9 10] ]
		rh7-hash: make hash! rh7-b
		clear rh7-b
		recycle
		rh7-mem: stats
		
		remove/part skip rh7-hash 50 50                 ;-- discard 2nd half
		recycle
		
		rh7-mem2: stats
		--assert rh7-mem2 <= rh7-mem
		
	--test-- "recycle-hash-8"
		rh8-mem: none
		rh8-mem2: none
		rh8-s: "abcde"
		rh8-b: make block! 1000
		loop 1000 [ append rh8-b copy rh8-s ]
		rh8-h: make hash! []
		recycle
		rh8-mem: stats
		
		append rh8-h copy rh8-b 
		loop 1000 [ remove rh8-h ]
		rh8-h: none
		recycle
		
		rh8-mem2: stats
		--assert rh8-mem2 <= rh8-mem
		
===end-group===

===start-group=== "recycle vector"

	--test-- "recycle-vector-1"
		rv1-mem: none
		rv1-mem2: none
		rv1-vec: none
		recycle
		rv1-mem: stats
		
		rv1-vec: make vector! 500000
		rv1-vec: none
		recycle
		
		rv1-mem2: stats
		--assert rv1-mem2 <= rv1-mem
		
	--test-- "recycle-vector-2"
		rv2-mem: none
		rv2-mem2: none
		rv2-vec: none
		recycle
		rv2-mem: stats
		
		loop 500 [
			rv2-vec: make vector! 500000
			recycle 
		]
		rv2-vec: none
		recycle
		
		rv2-mem2: stats
		--assert rv2-mem2 <= rv2-mem
	
	
	--test-- "recycle-vector-3"
		rv3-mem: none
		rv3-mem2: none
		rv3-vec: none
		rv3-size: 2 ** 24 + 1
		recycle
		rv3-mem: stats
		
		;rv3-vec: rv3-size                 ;; currently causes out of memory
		recycle
		
		rv3-mem2: stats
		--assert rv3-mem2 <= rv3-mem
		
	--test-- "recycle-vector-4"
		rv4-mem: none
		rv4-mem2: none
		rv4-vec: none
		rv4-size: 2 ** 24 + 1
		recycle
		rv4-mem: stats

		loop 500 [
			;rv4-vec: make vector! rv4-size  ;; currently causes out of memory
			rv4-vec: none
			recycle
		]
		rv4-vec: none
		recycle
		
		rv4-mem2: stats
		--assert rv4-mem2 <= rv4-mem
		
===end-group===

===start-group=== "recycle object"

	--test-- "recycle-object-1"
		ro1-o: none
		ro1-mem: none
		ro1-mem2: none
		copy ""
		recycle
		ro1-mem: stats
		
		ro1-o: make object! copy [
			a: [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ]
			b: [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ]
			c: [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ]
			d: [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ]
			e: [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ]
		]
		ro1-o: none
		recycle
		
		ro1-mem2: stats
		--assert ro1-mem2 <= ro1-mem
		
	--test-- "recycle-object-2"
		ro2-o: none
		ro2-mem: none
		ro2-mem2: none
		recycle
		ro2-mem: stats
		
		ro2-o: make object! copy [
			a: [ "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20" ]
			b: [ "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20" ]
			c: [ "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20" ]
			d: [ "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20" ]
			e: [ "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20" ]
		]
		clear select ro2-o 'a
		clear select ro2-o 'b
		clear select ro2-o 'c
		clear select ro2-o 'd
		clear select ro2-o 'e
		ro2-o: none
		recycle
		
		ro2-mem2: stats
		--assert ro2-mem2 <= ro2-mem

	--test-- "recycle-object-3"
		ro3-mem: none
		ro3-mem2: none
		do [
			ro3-o: make object! copy [
				a: make object! copy [ a: [ "1 2 3 4 5 6 7 8 9 10 11 12 13" ] ]
				b: make object! copy [ b: [ "1 2 3 4 5 6 7 8 9 10 11 12 13" ] ]
				c: make object! copy [ c: [ "1 2 3 4 5 6 7 8 9 10 11 12 13" ] ]
				d: make object! copy [ d: [ "1 2 3 4 5 6 7 8 9 10 11 12 13" ] ]
				e: make object! copy [ e: [ "1 2 3 4 5 6 7 8 9 10 11 12 13" ] ]
			]
		]
		recycle
		ro3-mem: stats
		
		ro3-o/a/a: none
		recycle
		
		ro3-mem2: stats
		--assert ro3-mem2 <= ro3-mem

	--test-- "recycle-object-4"
		ro4-mem: none
		ro4-mem2: none
		ro4-o: make object! copy [
			a: make object! copy [
				b: make object! copy [ 
					c: make object! copy [
						d: make object! copy [
							e: make object! copy [ e: [ "1 2 3 4 5 6 7 8 9" ] ]
						]
					]
				]
			]
		]
		recycle
		ro4-mem: stats
		
		ro4-o/a/b/c/d/e/e: none
		recycle
		
		ro4-mem2: stats
		--assert ro4-mem2 <= ro4-mem

	--test-- "recycle-object-5"
		ro5-o: none
		ro5-mem: none
		ro5-mem2: none
		recycle
		ro5-mem: stats
		
		ro5-o: make object! copy [
			a: make object! copy [
			b: make object! copy [ 
			c: make object! copy [
			d: make object! copy [
			e: make object! copy [
			f: make object! copy [
			g: make object! copy [
			h: make object! copy [
			i: make object! copy [
			j: make object! copy [
			k: make object! copy [ data: [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ] ]
		] ] ] ] ] ] ] ] ] ] ]
		ro5-o: none
		recycle
		
		ro5-mem2: stats
		--assert ro5-mem2 <= ro5-mem

	--test-- "recycle-object-6"
		ro6-mem: none
		ro6-mem2: none
		ro6-o: make object! copy [
			a: make object! copy [
			b: make object! copy [ 
			c: make object! copy [
			d: make object! copy [
			e: make object! copy [
			f: make object! copy [
			g: make object! copy [
			h: make object! copy [
			i: make object! copy [
			j: make object! copy [
			k: make object! copy [ data: "12345678901234567890" ]
		] ] ] ] ] ] ] ] ] ] ]
		recycle
		ro6-mem: stats
		
		ro6-o/a/b/c/d/e/f/g/h/i/j/k/data: none
		recycle
		
		ro6-mem2: stats
		--assert ro6-mem2 <= ro6-mem

	--test-- "recycle-object-7"    					;-- really a check of 'stats
		ro7-o1: none
		ro7-o2: none
		ro7-o3: none
		ro7-o4: none
		ro7-o5: none
		ro7-mem: none
		ro7-mem2: none
		recycle
		ro7-mem: stats
		
		ro7-o1: do [ make object! [ a: "1234567891011121314151617181920" ] ]
		ro7-o2: do [ make object! [ a: "1234567891011121314151617181920" ] ]
		ro7-o3: do [ make object! [ a: "1234567891011121314151617181920" ] ]
		ro7-o4: do [ make object! [ a: "1234567891011121314151617181920" ] ]
		ro7-o5: do [ make object! [ a: "1234567891011121314151617181920" ] ]
		recycle
		
		ro7-mem2: stats
		--assert ro7-mem2 > ro7-mem

	--test-- "recycle-object-8"
		ro8-mem: none
		ro8-mem1: none
		ro8-o: make object! copy [
			ro8-m: #[m: "12345678901234567890"]
		]
		recycle
		ro8-mem: stats

		ro8-o/ro8-m/m: none
		recycle
		
		ro8-mem2: stats
		--assert ro8-mem2 <= ro8-mem
		
	--test-- "recycle-object-9"
		ro9-o: none
		ro9-m: none
		ro9-mem: none
		ro9-mem1: none
		ro9-o: make object! copy [
			ro9-m: #[m: #[m: #[m: #[m: #[m: #[m: "12345678901234567890"]]]]]]
		]
		recycle
		ro9-mem: stats
		
		ro9-o/ro9-m/m/m/m/m/m/m: none
		recycle
		
		ro9-mem2: stats
		--assert ro9-mem2 <= ro9-mem

===end-group===

===start-group=== "recycle issues"

	#if config/target <> 'ARM [
	--test-- "recycle-issue-5325"
		k: 10 n: 49 m: 100000
		block2: make [] k * n
		recycle/off
		repeat i k [clock [repeat j n [append/only block2 copy append/dup make [] m 0 m]]]
		recycle
		--assert true	;-- no crashes
	]

===end-group===

~~~end-file~~~