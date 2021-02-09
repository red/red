Red [
	Title:	 "Redbin codec test script"
	Author:	 "Vladimir Vasilyev"
	File:	 %redbin-test.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Config:  [red-strict-check?: off]
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "Redbin codec"
	random/seed C0DECh								;-- seed for randomized tests
	
	test: func [value [any-type!]][load/as save/as none :value 'redbin 'redbin]
	
	;@@ TBD: #4540
	equal-func?: func [x [function!] y [function!]][
		to logic! all [
			strict-equal? mold    :x mold    :y
			strict-equal? spec-of :x spec-of :y
			strict-equal? body-of :x body-of :y
		]
	]
	
	;@@ #4526
	op: func [spec body][do [make op! func spec body]]
	
	inline: function [body [any-list!] /local rest][
		rule:   [any [ahead any-list! into rule | cycle | skip]]
		marker: [ahead ref! into [end]]
		
		cycle: [remove marker mark: refer :rest]
		refer: quote (change/only/part mark do/next mark 'rest rest)
		
		also body parse body rule
	]
	
	redbin-scan: func [datatype [datatype!] /only /local value][
		collect [
			foreach word words-of system/words [
				set/any 'value get/any word 
				if datatype = type? :value [keep/only either only [word][:value]]
			]
		]
	]
	
	===start-group=== "values"
		--test-- "unset"
			--assert () == test ()
		
		--test-- "none"
			--assert none == test none
		
		--test-- "datatype"
			datatypes: redbin-scan datatype!
			forall datatypes [--assert datatypes/1 == test datatypes/1]
		
		--test-- "logic"
			--assert true == test true
			--assert false == test false
		
		--test-- "integer"
			--assert 0 == test 0
			--assert 1 == test 1
			--assert -1 == test -1
			--assert 1337 == test 1337
			--assert (1 << 31) == test 1 << 31
			--assert (complement 1 << 31) == test complement 1 << 31
			
			loop 10 [
				value: random 1 << 30
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "char"
			--assert #"a" == test #"a"
			--assert #"A" == test #"A"
			--assert null == test null
			;@@ #4565 
			;-assert #"^D" == test #"^(4)"
			--assert #"💾" == test #"💾"
			
			loop 10 [
				value: random #"Z"
				--assert value == test value
			]
		
		--test-- "float"
			--assert 0.0 == test 0.0
			--assert 0.1 == test 0.1
			--assert -1.0 == test -1.0
			--assert "1.#NaN" == mold test 1.#NaN
			--assert 1.#INF == test 1.#INF
			--assert -1.#INF == test -1.#INF
			
			loop 10 [
				value: random 1'000'000'000'000
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "percent"
			--assert 0% == test 0%
			--assert 1% == test 1%
			--assert -1% == test -1%
			--assert 100% == test 100%
			
			loop 10 [
				value: random 10000000000000000%
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "pair"
			--assert 0x0 == test 0x0
			--assert 0x1 == test 0x1
			--assert 1x0 == test 1x0
			--assert 1x1 == test 1x1
			--assert -1x-2 == test -1x-2
			
			loop 10 [
				value: random 10000x10000
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "tuple"
			--assert 0.0.0 == test 0.0.0
			--assert 1.2.3.4.5.6.7.8.9 == test 1.2.3.4.5.6.7.8.9
			
			loop 10 [
				value: random to tuple! copy/part 64#{////////////////} 2 + random 11
				--assert value == test value
			]
		
		--test-- "time"
			--assert 0:0 == test 0:0
			--assert 1:2:3.456 == test 1:2:3.456
			
			loop 10 [
				value: random now/time/precise
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "date"
			--assert 1/1/1 == test 1/1/1
			--assert 9-Sep-99 == test 9/9/99
			
			loop 10 [
				value: random now
				--assert value == test value
			]
		
		--test-- "money"
			--assert $0 == test $0
			--assert $1 == test $1
			--assert -$1 == test -$1
			--assert -USD$1234.56789 == test -USD$1234.56789
			
			loop 10 [
				value: as-money pick system/locale/currencies/list random 170 random 1'000
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "typeset"
			typesets: redbin-scan typeset!
			forall typesets [--assert typesets/1 == test typesets/1]
			--assert strict-equal? make typeset! [] test make typeset! []
		
		--test-- "bitset"
			--assert strict-equal? charset 1 test charset 1
			--assert strict-equal? charset #{CAFE} test charset #{CAFE}
			--assert strict-equal? charset #{C0FFEE} test charset #{C0FFEE}
			--assert strict-equal? charset #{BADFACE5} test charset #{BADFACE5}
			--assert strict-equal? charset #{DEADBEEF} test charset #{DEADBEEF}
			--assert strict-equal? charset [#"a" - #"z"] test charset [#"a" - #"z"]
			--assert strict-equal? charset [not #{ABCD}] test charset [not #{ABCD}]
			
			loop 10 [
				value: charset to binary! random to tuple! copy/part 64#{////////////////} 2 + random 11
				--assert value == test value
			]
		
		--test-- "vector"
			--assert strict-equal? make vector! [] test make vector! []
			--assert strict-equal? make vector! [1] test make vector! [1]
			--assert strict-equal? make vector! [#"a"] test make vector! [#"a"]
			--assert strict-equal? make vector! [1.0] test make vector! [1.0]
			--assert strict-equal? make vector! [1%] test make vector! [1%]
			--assert strict-equal?
				next make vector! [1 2 3]
				test next make vector! [1 2 3]
			--assert strict-equal?
				skip make vector! [1% 2% 3% 4% 5%] 3
				test skip make vector! [1% 2% 3% 4% 5%] 3
			--assert strict-equal?
				make vector! [#"a" #"b" #"c"]
				head test tail make vector! [#"a" #"b" #"c"]
			
			loop 100 [
				value: attempt [
					skip make vector! reduce [
						type: random/only [integer! float! percent! char!]
						random/only [8 16 32 64]
						collect [loop random 10 [keep to get type random 100]]
					] (random 4) - 1
				]
				
				if value [							;-- some unit sizes and types are incompatible
					--assert value == test value
					--assert (index? value) == index? test value
				]
			]
		
		--test-- "binary"
			bytes: [#{} #{F0} #{CAFE} #{C0FFEE} #{BADFACE5} #{DEADBEEF}]
			forall bytes [--assert bytes/1 == head test skip bytes/1 (random 4) - 1]
			
			loop 10 [
				value: skip
					to binary! random to tuple! copy/part 64#{////////////////} 2 + random 11
					(random 4) - 1
				
				--assert value == test value
				--assert (index? value) == index? test value
			]
		
		--test-- "image"
			loop 10 [
				value: skip make image! reduce [
					random 500x500
					random 255.255.255
				] (random 4) - 1
				
				--assert value == test value
				--assert (index? value) == index? test value
			]
			
		--test-- "any-string"
			strings: [{} "string" <tag> email@address url:// %file @reference]
			forall strings [--assert strings/1 == head test skip strings/1 (random 4) - 1]
		
			loop 10 [
				value: skip to
					get random/only to block! any-string!
					rejoin collect [loop random 100 [keep to char! random 10'000]]
					(random 4) - 1
					
				--assert value == test value
				--assert (index? value) == index? test value
			]
		
		--test-- "any-list"
			blocks: [[] [1] [1 2 3] ["a" [#{BC} [[[[[[1.2.3]]]]] [[[$4.56]] [78x90]]]]]]
			forall blocks [--assert blocks/1 == head test skip blocks/1 (random 4) - 1]
			
			loop 10 [
				value: collect [
					loop random 100 [
						keep to
							get random/only [integer! float! pair! money!]
							random 1'000
					]
				]
				value: to get random/only to block! any-list!
				value: skip value (random 4) - 1
				
				--assert value == test value
				--assert (index? value) == index? test value
			]
		
		--test-- "map"
			maps: [#() #(a b) #("abcd" #(<de> [f g]))]
			forall maps [--assert maps/1 == test maps/1]
			
			loop 10 [
				value to map! collect [
					loop (random 50) << 1 [
						keep rejoin collect [loop random 100 [keep to char! random 10'000]]
					]
				]
				
				--assert value == test value
			]
		
		--test-- "any-path"
			paths: [a/b :c/(d) 'e/f/(g/:h)/:i]
			forall paths [--assert paths/1 == test paths/1]
		
		--test-- "all-word"
			values: [a 'b :c d: /e #f]
			forall values [--assert values/1 == test values/1]
			
			;loop 10 [
			;	string: rejoin collect [loop random 100 [keep to char! random 10'000]]
			;	value: to get random/only to block! all-word! string
			;	
			;	--assert value == test value
			;]
		
		--test-- "action"
			actions: redbin-scan action!
			forall actions [--assert :actions/1 == test :actions/1]

		--test-- "native"
			natives: redbin-scan native!
			forall natives [--assert :natives/1 == test :natives/1]
		
		--test-- "object"
			;@@ #4567
			objectz: reduce [
				object []
				object [foo: 'bar]
				object [foo: object [bar: object []]]
				object [foo: object [] bar: object []]
			]
			
			forall objectz [--assert objectz/1 == test objectz/1]
		
		--test-- "error"
			errors: reduce [
				try [1 / 0]
				try [transcode "$FOO"]
				make error! "User-defined"
				make error! 303
			]
			
			forall errors [--assert :errors/1 = test :errors/1]
		
		;do [										;@@ #4568
		;--test-- "function"						;@@ ???
		;	functions: redbin-scan/only function!
		;	clear find/tail functions 'red-complete-input ;@@ find something more adequate
		;	functions: exclude functions [
		;		:expand-directives					;-- routine
		;		:redbin-scan						;-- routine
		;	]
		;	
		;	forall functions [
		;		attempt [							;@@ #4552
		;			--assert equal-func? get :functions/1 test get :functions/1
		;		]
		;	]
		;	
		;	collect*: test :collect
		;	block: collect* [repeat i 10 [keep i]]
		;	--assert block == collect [repeat i 10 [keep i]]
		;	
		;	load-json*: test :load-json
		;	map: load-json* {{"a": [1, 2, {"b": "c"}]}}
		;	--assert map == load-json {{"a": [1, 2, {"b": "c"}]}}
		;	
		;	unset [collect* load-json*]
		;]
		
		--test-- "op"
			ops: redbin-scan op!
			clear find/tail ops :is ;@@ find something more adequate
			;@@ #4562, #4570
			ops: exclude ops reduce [:>> :>>> get load "<<" :is ://]
			forall ops [--assert strict-equal? spec-of :ops/1 spec-of test :ops/1]
		
			ops: reduce [							;@@ #4540
				() []
				03 [03]
				pi [pi]
				[2] [x 0 reduce [y]]
			]
			
			do [									;@@ #4526
			foreach [result body] ops [
				operator: test op [x y] body
				--assert :result = (1 operator 2)
			]
			]
			
			;@@ #2867, #4571, #4572
			do [
				///: test ://
				--assert 8 /// 3 == 2
				--assert error? try [1 /// 0]
				--assert strict-equal? spec-of :/// spec-of ://
			]
			
			unset [operator ///]					;-- hide from redbin-scanner
		
	===end-group===
	
	===start-group=== "Binding"
		--test-- "binding-1"
			ctx: context [bar: 1]
			foo: test bind quote :bar ctx
			
			--assert get-word? foo
			--assert ":bar" = mold foo
			--assert 1 == get foo
			--assert ctx == context? foo
		
		--test-- "binding-2"
			ctx: context [bar: 1]
			foo: test bind [bar] ctx
			
			--assert block? foo
			--assert "[bar]" = mold foo
			--assert foo/1 = 'bar
			--assert 1 == get foo/1
			--assert ctx == context? foo/1
		
		;@@ #734
		--test-- "binding-3"
			ctx: context [foo: 1 bar: 2]
			foo: test bind [foo: 'bar] ctx
			
			--assert block? foo
			--assert "[foo: 'bar]" = mold foo
			--assert foo/1 == quote foo:
			--assert foo/2 == to lit-word! 'bar
			--assert 1 = get foo/1
			--assert 2 = get foo/2
			--assert ctx == context? foo/1
			--assert ctx == context? foo/2
			--assert equal? context? foo/1 context? foo/2
		
		do [											;@@ ???
		--test-- "binding-4"
			word: test bind 'foo has [foo][bar]
		
			--assert word? word
			--assert 'foo = word
			--assert equal-func? has [foo][bar] context? word
		]
	===end-group===

	;===start-group=== "Header flags"					;@@ ???
	;	--test-- "newline"			
	;		block: [
	;			#a
	;			b /c
	;			:d e: 'f
	;			
	;			1
	;			2.0 3x4
	;			$5.6 7% 8.9.10.11
	;			
	;			"foo"
	;			<bar> baz@qux
	;			%foo @bar baz://qux
	;			
	;			[
	;				a/b
	;				:c/d/e 'f/g/(
	;					i
	;				)
	;				j/k/l: (
	;					#(
	;						foo: bar
	;					)
	;					#[none] #"n"
	;					#[true]
	;					#[false]
	;				)
	;			]
	;		]
	;		
	;		--assert (mold block) = mold test block
	;===end-group===
	
	===start-group=== "Cycles & References"
		--test-- "cycle-1"
			block: [@ block]
			block: test inline block
			
			--assert "[[...]]" = mold block
			--assert block/1/1 =? block
		
		--test-- "cycle-2"
			block: [@ block we need to go deeper @ block]
			block: test inline block
			
			--assert "[[...] we need to go deeper [...]]" = mold block
			--assert same? first block last block
			--assert same? block first block
			--assert block/1/7/1/7/1/7/1/7/1/7/6 == 'deeper
			reverse last block
			--assert block/2 == 'deeper
			--assert block/7/7/7/1/1/1/2 == 'deeper
		
		--test-- "cycle-3"
			map: test put map: #() 'map map
			
			--assert "#(map: #(...))" = mold/flat map
			--assert map/map/map/map =? map
		
		--test-- "cycle-4"
			append/only hash: make hash! [] hash
			hash: test hash
			
			--assert "make hash! [make hash! [...]]" = mold hash
			--assert hash/1/1 =? hash
		
		--test-- "cycle-5"
			append/only path: make path! [] path
			path: test path
			
			--assert "..." = mold path
			--assert path/1/1 =? path
		
		--test-- "cycle-6"
			ping: [pong @ pong]
			pong: [ping @ ping]
			
			inline ping
			inline pong
			
			--assert ping/pong =? pong
			--assert pong/ping =? ping
			
			set [ping pong] test reduce [ping pong]
			
			--assert ping/pong/ping/pong =? pong
			--assert pong/ping/pong/ping =? ping
		
		;@@ #4569
		--test-- "cycle-7"
			put foo: object [foo: none] 'foo :foo
			foo: test foo
			
			--assert "make object! [foo: make object! [...]]" = mold/flat foo
			--assert object? foo
			--assert object? foo/foo
			--assert foo =? foo/foo/foo
		
		--test-- "cycle-8"
			foo: test object [foo: self]
			
			--assert "make object! [foo: make object! [...]]" = mold/flat foo
			--assert object? foo
			--assert object? foo/foo
			--assert foo =? foo/foo/foo
		
		--test-- "cycle-9"
			foo: test object [foo: 'foo]
			
			--assert object? foo
			--assert "make object! [foo: 'foo]" = mold/flat foo
			--assert 'foo = get foo/foo
			--assert 'foo = get get foo/foo
			--assert foo = context? get get get foo/foo
		
		--test-- "cycle-10"
			foo: test bind 'bar context [bar: 'bar]
			ctx: context? foo
		
			--assert word? foo
			--assert "bar" = mold foo
			--assert 'bar == get foo
			
			--assert 'bar == get get foo
			
			--assert object? ctx
			--assert 'bar == ctx/bar
			--assert equal? context? foo context? get ctx/bar
		
		--test-- "reference-1"
			block: [1 2]
			paren: as paren! next block
			block: test reduce [block paren]
			
			--assert [[1 2] (2)] = block
			--assert equal? quote (1 2) head last block
			append first block 3
			--assert [[1 2 3] (2 3)] = block
			reverse last block
			--assert [[1 3 2] (3 2)] = block
			--assert same? block/1 head as block! block/2
		
		--test-- "reference-2"
			bin1: #{deadbeef}
			bin2: skip bin1 3
			block: test reduce [bin1 bin2]
			
			--assert [#{deadbeef} #{ef}] = block
			--assert block/1 =? head block/2
			append block/1 #{f00d}
			--assert block/2 = #{eff00d}
			reverse block/2
			--assert [#{deadbe0df0ef} #{0df0ef}] = block
			
		--test-- "reference-3"
			string: "abc"
			tag: as tag! next string
			block: test reduce [string tag]
			
			--assert ["abc" <bc>] = block
			--assert <abc> = head last block
			append first block 'd
			--assert ["abcd" <bcd>] = block
			reverse last block
			--assert ["adcb" <dcb>] = block
			--assert same? block/1 head as string! block/2
		
		--test-- "reference-4"
			vec1: make vector! [integer! 16 [1 2 3]]
			vec2: skip vec1 2
			block: test reduce [vec1 vec2]
			
			--assert equal? block reduce [vec1 vec2]
			--assert block/1 =? head block/2
			append block/1 4
			--assert block/2/2 == 4
			
		--test-- "reference-5"
			bit: charset "abc"
			block: test reduce [bit bit]
			
			--assert equal? block reduce [bit bit]
			--assert block/1 =? block/2
			--assert bitset? block/1
		
		--test-- "reference-6"
			img1: make image! [123x456 1.2.3]
			img2: at img1 4
			block: test reduce [img1 img2]
			
			--assert block = reduce [img1 img2]
			--assert block/1 =? head block/2
			--assert image? block/1
			--assert 4 == index? block/2
			--assert block/2/size == 123x456
			--assert block/1/1 == 1.2.3.0
		
		--test-- "reference-7"
			block1: reduce [:append :append reduce [:append]] 
			block: test block1
			
			--assert block == block1
			--assert action? :block/1
			--assert :block/1 =? :block/2
			--assert :block/2 =? :block/3/1
			--assert :append == :block/1
		
		--test-- "reference-8"
			block1: test reduce [:bind :bind reduce [:bind]]
			block: test block1
			
			--assert block == block1
			--assert native? :block/1
			--assert :block/1 =? :block/2
			--assert :block/2 =? :block/3/1
			--assert :bind == :block/1
		
		--test-- "reference-9"
			obj: object [foo: [1 2 3]]
			block1: reduce [obj next obj/foo]
			block: test block1
			
			--assert block == block1
			--assert object? block/1
			--assert block/1/foo =? head block/2
			reverse block/2
			--assert block/1/foo == [1 3 2]
		
		--test-- "reference-10"
			obj: object [foo: 1]
			block: test reduce [in obj 'foo obj]
			
			--assert "[foo make object! [foo: 1]]" = mold/flat block
			--assert word? block/1
			--assert object? block/2
			--assert block/1 == 'foo
			--assert block/2 == obj
			--assert block/2 =? context? block/1
		
		do [										;@@ #2207
		--test-- "reference-11"
			foo: does [bar]
			block: test reduce [:foo :foo]
			
			--assert 2 = length? block
			--assert function? :block/1
			--assert function? :block/2
			--assert equal-func? :foo :block/1
			--assert :block/1 =? :block/2
		
		--test-- "reference-12"
			foo: has [bar][]
			block: test reduce [bind 'bar :foo :foo]
			
			--assert 2 = length? block
			--assert 'bar = block/1
			--assert function? :block/2
			--assert equal-func? :foo :block/2
			--assert equal-func? context? block/1 :block/2
		
		--test-- "reference-13"
			foo: does [1 2 [3 4]]
			block: test reduce [:foo next body-of :foo tail last body-of :foo]
			
			--assert 3 = length? block
			--assert "[func [][1 2 [3 4]] [2 [3 4]] []]" = mold/flat block
			--assert function? :block/1
			--assert equal-func? :foo :block/1
			--assert block? block/2
			--assert block? block/3
			--assert same? body-of :block/1 head block/2
			--assert same? last body-of :block/1 head block/3
		
		--test-- "reference-14"
			foo: func [bar [integer! none!]][]
			block: test reduce [:foo next spec-of :foo tail last spec-of :foo]
			
			--assert 3 = length? block
			--assert "[func [bar [integer! none!]][] [[integer! none!]] []]" = mold/flat block
			--assert function? :block/1
			--assert equal-func? :foo :block/1
			--assert block? block/2
			--assert block? block/3
			--assert same? spec-of :block/1 head block/2
			--assert same? last spec-of :block/1 head block/3
		]
		
		--test-- "reference-15"
			block: body-of :mod
			--assert block == test block
		
		do [										;@@ #2207
		--test-- "reference-16"
			foo: func [x y][a b]
			foo: test reduce [:foo spec-of :foo]
			--assert :foo/2 =? spec-of :foo/1
		
			foo: func [x y][a b]
			foo: test reduce [:foo body-of :foo]
			--assert :foo/2 =? body-of :foo/1
			
			;@@ #4526
			foo: make op! func [x y][a b]
			foo: test reduce [:foo spec-of :foo]
			--assert :foo/2 =? spec-of :foo/1
			
			foo: test reduce [:as-pair spec-of :as-pair]
			--assert :foo/2 =? spec-of :foo/1
			
			;@@ #4526
			foo: make op! :as-pair
			foo: test reduce [:foo spec-of :foo]
			--assert :foo/2 =? spec-of :foo/1
		
		--test-- "reference-17"
			foo: func [x y][a b]
			foo: test reduce [spec-of :foo :foo]
			--assert :foo/1 =? spec-of :foo/2
			
			foo: func [x y][a b]
			foo: test reduce [body-of :foo :foo]
			--assert :foo/1 =? body-of :foo/2
			
			;@@ #4526
			foo: make op! func [x y][]
			foo: test reduce [spec-of :foo :foo]
			--assert :foo/1 =? spec-of :foo/2
			
			foo: test reduce [spec-of :as-pair :as-pair]
			--assert :foo/1 =? spec-of :foo/2
			
			;@@ #4526
			foo: make op! :as-pair
			foo: test reduce [spec-of :foo :foo]
			--assert :foo/1 =? spec-of :foo/2
		
		--test-- "reference-18"
			foo: func [x y][a b]
			bar: make op! :foo
			block: test reduce [:bar :foo]
			
			--assert op? :block/1
			--assert function? :block/2
			--assert equal? spec-of :bar spec-of :block/1
			--assert equal-func? :foo :block/2
			
			unset 'bar								;-- hide from redbin-scanner
		]
	
	===end-group===
	
	===start-group=== "Codec errors"
		--test-- "errors-1" --assert error? try [load/as #{} 'redbin]
		--test-- "errors-2" --assert error? try [load/as to binary! "REDBIN" 'redbin]
		--test-- "errors-3" --assert error? try [test :>>]
		--test-- "errors-4" --assert error? try [test :as-ipv4]
	
	===end-group===
	
	===start-group=== "Symbols"
		--test-- "symbols-1"
			a: copy b: save/as none [foo 'bar baz: :qux #foo /bar] 'redbin
			loop 3 [
				load/as b 'redbin
				--assert a == b
			]
		
		--test-- "symbols-2"
			symbols: save/as none [foo :foo 'foo foo: /foo #foo] 'redbin
			table:   skip symbols 16				;-- skip header
			buffer:  skip table 4					;-- skip # of entries
			string:  skip buffer 8					;-- skip buffer size and single entry
			
			--assert 4 == symbols/8										;-- symbol table is present
			--assert 1 == to integer! reverse copy/part table 4			;-- single entry
			--assert 8 == to integer! reverse copy/part buffer 4		;-- buffer 8 bytes in size
			--assert "foo^@^@^@^@^@" == to string! copy/part string 8	;-- NUL padding is present
			
	===end-group===

	===start-group=== "Stress tests"

		--test-- "stress-1"
			s1b: make [] 100000
			s1bin: #{}
			loop 10 [
				repeat s1i 5000 [append s1b form s1i]
				s1t: dt [save/as clear s1bin s1b 'redbin]
				s1b2: load/as s1bin 'redbin
				recycle
				--assert s1b == s1b2
				--assert s1t < 0:0:1					;-- should be ~40ms
			]
			unset [s1b s1b2 s1bin]

		--test-- "stress-2"
			s2m: make #() 100'000
			s2bin: #{}
			repeat s2i 100'000 [put s2m s2i form s2i]
			s2t: dt [save/as s2bin s2m 'redbin]
			s2m2: load/as s2bin 'redbin
			--assert s2m == s2m2
			--assert s2t < 0:0:5						;-- should be ~300ms
			recycle

	===end-group===

~~~end-file~~~
