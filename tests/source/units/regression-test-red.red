Red [
	Title:   "Red regression tests"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test.red
	Tabs:	 4
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
;	Needs:	 'View
]

#include  %../../../quick-test/quick-test.red

;true?: func [value] [not not value]
;-test-: :--test--
;--test--: func [value] [probe value -test- value]


~~~start-file~~~ "regression-test"

===start-group=== "issues #1 - #1000"

	true?: func [value] [not not value]

	; --test-- "#5"

	; --test-- "#63"
		; TODO

	; --test-- "#65"
		; TODO

	; --test-- "#71"
		; TODO

	; --test-- "#114"
		; TODO

	; --test-- "#117"
		; TODO

	; --test-- "#121"
		; TODO

	; --test-- "#122"
		; TODO

	; --test-- "#123"
		; TODO

	; --test-- "#125"
		; TODO

	; --test-- "#131"
		; TODO

	; --test-- "#134"
		; TODO

	; --test-- "#137"
		; TODO

	; --test-- "#153"
		; TODO

	; --test-- "#154"
		; TODO

	; --test-- "#157"
		; TODO

	; --test-- "#165"
		; TODO

	; --test-- "#167"
		; TODO

	; --test-- "#168"
		; specific compiler version problem

	; --test-- "#170"
		; TODO

	; --test-- "#172"
		; TODO

	; --test-- "#174"
		; TODO

	; --test-- "#178"
		; TODO

	; --test-- "#188"
		; TODO

	; --test-- "#200"
		; quick-test bug

	; --test-- "#204"
		; no code

	; --test-- "#212"
		; NOTE: float! problem on ARM - there is ton of other float! tests
		;		that will test this as well

	; --test-- "#228"
		; TODO

	; --test-- "#234"
		; TODO

	; --test-- "#236"
		; TODO

	; --test-- "#239"
		; TODO

	; --test-- "#250"
		; TODO

	; --test-- "#258"
		; TODO

	--test-- "#262"
		--assert not error? try [#"^(00)"]

	; --test-- "#265"
		; NOTE: problem with compiling %tests/hello.red on Linux/ARM

	; --test-- "#269"
		; TODO

	; --test-- "#278"
		; TODO

	; --test-- "#279"
		; TODO

	--test-- "#292"
		--assert error? try [load {#"""}]

	--test-- "#306"
		s306: mold []
		--assert equal? #"[" s306/1

	--test-- "#308"
		; NOTE: using just `foo` won't compile -- see #2207
		bar308: func [] [foo308]
		foo308: func [] [42]
		--assert not error? try [bar308]
		unset [foo308 bar308]

	--test-- "#310"
		--assert equal? "good" either true ["good"] ["bad"]
		--assert equal? "good" either false ["bad"] ["good"]
		--assert equal? "good" either 42 ["good"] ["bad"]

	; --test-- "#313"
		; TODO

	; --test-- "#316"
		; TODO

	--test-- "#321"
		--assert none? if false [1]
		--assert error? try [1 + if false [2]]

	; --test-- "#324"
		; NOTE: seems to be buggy still

	; --test-- "#330"
		; TODO
		; not sure what is the buggy behaviour, there’s no example

	--test-- "#331"
		foo331: func [] ["ERR"]
		foo331: func [] ["ok"]
		--assert equal? "ok" foo331

	; --test-- "#340"
		; TODO

	; --test-- "#342"
		; TODO

	--test-- "#345"
		spec345: spec-of :set
		--assert (index? find spec345 'value) < ((index? find spec345 /any))

	--test-- "#356"
		--assert not error? try [if true []]

	; --test-- "#357"
		; TODO

	; --test-- "#360"
		; TODO: OPEN
		; should check for compilation error

	; --test-- "#364"
		; TODO: #include problem

	; --test-- "#366"
		; TODO: compilation problem with dir paths

	; --test-- "#381"
		; TODO: #include problem

	--test-- "#384"
		f384: func [/refine] [refine]
		--assert not f384

	; --test-- "#385"
		; TODO

	--test-- "#388"
		--assert equal? word! type? 'a

	comment { print should be mocked for this test
	--test-- "#389"
		--assert equal? 
			"default"
			switch/default 1 [
				2 [
					print 2
				]
			][
				"default"
			]
	}

	--test-- "#395"
		--assert switch 'yes [yes [true]]

	--test-- "#397"
		--assert not error? try [do [append [] 1]]

	--test-- "#399"
		x399: 1

		f399: function [
		][
			x399: 2
			b: [x399]
			do b
		]
		--assert equal? 2 f399

	--test-- "#400"
		r400: none
		t400: none
		r400: all [
			any [
				true
				t400: "*"
				true
			]	
		]
		--assert none? t400		; `any` short-circuits on 1st true
		--assert true? r400
		r400: none
		t400: none
		--assert true? all [
			any [
				false
				t400: "*"
				true
			]
			r400: "!"
		]
		--assert equal? t400 "*"
		--assert equal? r400 "!"
		r400: none
		t400: none
		--assert true? all [
			any [
				none
				t400: "*"
				true
			]
			r400: "!"
		]
		--assert equal? t400 "*"
		--assert equal? r400 "!"
		unset [r400 t400]

	--test-- "#401"
		y401: none ; prevent " undefined word y401" compiler error
		set 'x 'y401
		set x 1
		--assert equal? 1 y401
		do [set x 1]
		--assert equal? 1 y401
		unset [x y401]

	--test-- "#403"
		f403: func [
			a       [block!]
			return: [block!]
			/local  b x
		][
			b: copy []

			either block? x: a/1 [
				append/only b  f403 x
			][
				append b x
			]
			b
		]
		--assert equal? [1] f403 [1]
		--assert equal? [[2]] f403 [[2]]
		--assert equal? [[[3]]] f403 [[[3]]]
		unset 'f403

	--test-- "#404"
		x404: 'y404
		y404: 1
		--assert equal? 'y404 x404
		--assert equal? 'y404 get 'x404
		--assert equal? 1 get x404
		--assert equal? 1 do [get x404]

	--test-- "#409"
		g409: func [
			b [block!]
		] [
			reduce [b do b]
		]
		f409: func [
			"!"
			x
			/r
		] [
			g409 [x]
		]
		--assert equal? [[x] "!"] f409 "!"

	; --test-- "#411"
		; TODO

	; --test-- "#413"
		; TODO: should check compilation time

	--test-- "#416"
		b416: [none]
		f416: func [p q] [
			reduce [p q]
		]
		--assert equal? [1 none] do [f416 1 b416/1]
		unset [b416 f416]

	; --test-- "#418"
		; see #420

	--test-- "#422"
		--assert not error? try [function [n [integer!]] []]

	--test-- "#424"
		--assert empty? load ";2"

	--test-- "#425"
		--assert not error? try [func [return: [integer!]] []]

	; --test-- "#426"
		; compiler behaviour

	--test-- "#427"
		out427: copy ""
		f427: func [
			/local count
		] [
			repeat count 5 [
				append out427 count
			]
		]
		f427
		--assert equal? "12345" out427
		unset 'out427

	--test-- "#429"
		--assert equal? {#"^^-"} mold tab

	--test-- "#430"
		--assert equal? "  x" form ["" [] x]
		--assert equal? " a  a " form [[""] [a] [] [a] [[[]]]]

	comment { print should be mocked for this test
	--test-- "#431"
		--assert error? try [val431: print ""]
		unset 'val431
	}
	
	; --test-- "#432"
		; TODO

	--test-- "#443"
		unset [i j]
		f443: function [] [out: copy [] foreach [i j] [1 2 3 4] [append out i] out]
		--assert equal? [1 3] f443
		--assert equal? [/local out i j] spec-of :f443
		--assert error? try [do [i]]
		--assert error? try [do [j]]
		unset [f443 out]

	--test-- "#449"
		s449: copy ""
		--assert equal? "1111111111" append/dup s449 #"1" 10
		--assert equal? "1111111111" s449
		--assert equal? 10 length? s449
		unset 's449

	--test-- "#455"
		types455: copy [] 
		foreach word words-of system/words [
			all [
				value? word 
				append types455 type? get word
			]
		]
		--assert 1 < length? unique types455
		unset 'types455

	--test-- "#457"
		--assert equal? "b" find/tail "a/b" #"/"
		--assert equal? "/b" find "a/b" #"/"

	--test-- "#458"
		--assert equal? "[a [b] c]" mold [a [b] c]
		--assert equal? "a [b] c" mold/only [a [b] c]

	--test-- "#459"
		--assert equal? [3 7 8] find/last [1 2 3 4 5 6 3 7 8] 3
		--assert equal? [7 8] find/last/tail [1 2 3 4 5 6 3 7 8] 3
		--assert equal? "378" find/last "123456378" #"3"
		--assert equal? "78" find/last/tail "123456378" #"3"

	--test-- "#465"
		s465: make string! 0
		append s465 #"B"
		--assert equal? "B" s465
		append s465 #"C"
		--assert equal? "BC" s465
		append s465 #"D"
		--assert equal? "BCD" s465

	; --test-- "#484"
		; TODO

	; --test-- "#488"
		; Rebol GC bug (probably, TODO)

	--test-- "#490"
		--assert equal? "" insert "" #"!"
		--assert equal? "" insert "" "!"

	--test-- "#491"
		--assert equal? 2 load next "1 2"

	; --test-- "#493"
		; TODO

	; --test-- "#494"
		; TODO: example throws strange compiler error

	--test-- "#497"
		b: [1]
		p: 'b/1
		--assert equal? 1 do p

	--test-- "#498"
		--assert  equal? {{""}} mold mold {}

	--test-- "#501"
		--assert empty? at tail "abc" 0

	--test-- "#505"
		--assert equal? "ab" find/reverse tail "ab" #"a"

	; --test-- "#507"
		; R2 GC bug

	; --test-- "#508"
		; R2 GC bug

	; --test-- "#509"
		; R2 GC bug

	--test-- "#510"
		set [x] []
		--assert none? x

	--test-- "#511"
		b511: [x 0]
		i511: 'x
		b511/:i511: 1
		--assert equal? [x 1] b511
		unset [b511 i511]

	--test-- "#512"
		x512: 0
		--assert zero? case [yes x512]
		unset 'x512

	--test-- "#513"
		--assert equal? {#"^^^^"} mold #"^^"

	--test-- "#514"
		--assert equal? 1 length? "^^"
		--assert equal? {"^^^^"} mold "^^"

	; --test-- "#515"
		; no example

	; --test-- "#518"
		; TODO

	; --test-- "#519"
		; TODO: see #2225
		; should check print output

	--test-- "#520"
		; FIXME: disputable -- see the issue
		;--assert not not all []

	--test-- "#522"
		--assert not error? try [{{x}}]

	--test-- "#524"
		s524: "^(1234)B"
		--assert equal? "B" find s524 "B"
		--assert equal? "B" find s524 next "AB"
		unset 's524

	--test-- "#525"
		--assert not error? try [load {^/}]
		--assert not error? try [load {{^/}}]

	; --test-- "#531"
		; TODO: should check for compiler error

	; --test-- "#532"
		; TODO

	; --test-- "#539"
		; TODO: #inlcude path problem

	; --test-- "#541"
		; TODO: compiler problem

	; --test-- "#542"
		; precompiled library problem

	; --test-- "#545"
		; broken library

	; --test-- "#547"
		; broken release

	; --test-- "#548"
		; TODO: #include path problem

	--test-- "#558"
		o558: copy ""
		foreach x 'a/b/c [append o558 x]
		--assert equal? o558 "abc"
		o558: copy ""
		foreach x quote (i + 1) [append o558 x]
		--assert equal? o558 "i+1"
		unset 'o558

	--test-- "#559"
		--assert equal? load "x559/y:" quote x559/y:
		--assert equal? load "x559:" quote x559:

	--test-- "#560"
		fx560: function [
			value
			out	[string!]
		][
			either block? value [
				string: copy ""

				foreach x value [
					fx560 x tail string
				]
				insert insert insert out  0 string #"]"
				out
			][
				insert insert insert insert out  1 #":" value #","
				out
			]
		]

		fx560 [a [b c d]]
		s560: ""
		--assert equal? "01:a,01:b,1:c,1:d,]]" s560
		unset [fx560 s560]

	--test-- "#562"
		--assert not parse "+" [any [#"+" if (no)]]

	--test-- "#569"
		size569: 1
		--assert equal? ["1"] parse "1" [collect [keep copy value size569 skip]]
		size569: 2
		--assert equal? ["12"] parse "12" [collect [keep copy value size569 skip]]
		unset 'size569

	--test-- "#570"
		--assert not strict-equal? 'a 'A
		--assert not strict-equal? 'test 'Test

	--test-- "#572"
		;-- NOTE: `sp` is space char, shouldn't override it
		sp572: func [x y] [return parse "aa" [collect [keep skip]]]
		--assert equal? [#"a"] sp572 "q" "w"
		sp572: func [x y] [parse "aa" [collect [keep skip]]]
		--assert equal? [#"a"] sp572 "q" "w"
		unset 'sp572

	--test-- "#573"
		--assert error? try [load "{"]

	--test-- "#581"
		--assert not error? try [do "S: 1 S"]

	; --test-- "#584"
		; console behaviour

	--test-- "#586"
		t586: reduce [block!]
		--assert equal? reduce [block!] find t586 block!
		--assert equal? reduce [block!] find t586 type? []
		unset 't586

	--test-- "#592"
		--assert file? %x
		--assert file? copy %x

	--test-- "#593"
		--assert equal? [#"1"] parse "12" [collect [keep skip]]
		--assert equal? ["1"] parse "12" [collect [keep copy x skip]]
		--assert equal? [#"1"] parse "12" [collect [keep skip]]

	--test-- "#594"
		count594: 0
		letter594: charset [#"a" - #"z" #"A" - #"Z"]
		rule594: [
			some [
				"end" end (count594: count594 + 1)
			|	letter594
			]
		]
		--assert parse "blahendslkjsfdend" rule594
		--assert 1 = count594
		unset [count594 letter594 rule594]

	--test-- "#596"
		list596: ""
		parse "a" [collect into list596 some [keep skip]]
		--assert equal? "a" head list596
		unset 'list596

	--test-- "#598"
		--assert equal? [""] parse "" [collect [(s: "") collect into s [] keep (s)]]
		--assert equal? [[]] parse [] [collect [(b: []) collect into b [] keep (b)]]
		unset [b s]

	--test-- "#599"
		--assert equal? "<?>" form ["<?>"]
		--assert equal? "<?>" append "" ["<?>"]
		--assert equal? "<?>" head insert "" ["<?>"]

	--test-- "#601"
		b601: [] parse "!" [collect into b601 [keep 0 skip]]
		--assert empty? head b601
		unset 'b601

	--test-- "#604"
		--assert equal? "_" form "_"
		--assert equal? "_" form #"_"

	--test-- "#605"
		--assert none? length? none
		--assert error? try [1 + none] ; #621

	; --test-- "#609"
		; console behaviour

	--test-- "#616"
		; NOTE: 'f must be function (as defined elswhere in this tests), 
		; 		otherwise tests can’t be compiled, so we use 'fis616 here instead
		;		same with g->gis616
		e616: copy ""
		fis616: [b_c c_d]
		append e616 fis616
		--assert equal? "b_cc_d" e616
		a616: copy ""
		c616: [glp_set_prob_name glp_get_prob_name]
		append a616 c616
		--assert equal? "glp_set_prob_nameglp_get_prob_name" a616
		b616: copy ""
		d616: load "glp_set_prob_name glp_get_prob_name"
		append b616 d616
		--assert equal? "glp_set_prob_nameglp_get_prob_name" b616
		gis616: copy ""
		h616: [bc cd]
		append gis616 h616
		--assert equal? "bccd" gis616
		unset [a616 b616 c616 d616 e616 fis616 gis616 h616]

	--test-- "#625"
		--assert equal? #"^(1F)" first "^(1f)"

	; --test-- "#626"
		; see #637

	--test-- "#628"
		--assert equal? "make objec" mold/part context [a: "1" b: "2"] 10

	; --test-- "#644"
		; TODO: how to check for hangup?

	--test-- "#645"
		not error? try [
			comment [
				1 + 1
			]
		]

	--test-- "#646"
		--assert not error? try [foreach x646 [] []]

	--test-- "#647"
		--assert error? try [load "type? quote '1" ]

	--test-- "#650"
		do [								;-- interpreter only, compiler case is in compiler regression tests.
			f650: func [/1][none]
			--assert error? try [f650/1]
		]

	--test-- "#651"
		--assert equal? [1 []] load "1[]"
		--assert equal? [[] 1] load "[]1"

	; --test-- "#653"
		; TODO: need to check header

	--test-- "#655"
		--assert none? load "#[none]"

	--test-- "#656"
		--assert not error? try [load "+1"]

	--test-- "#657"
		--assert equal? {"} "^""

	; --test-- "#660"
		; console building problem

	--test-- "#678"
		--assert parse "cat" [1 "cat"]
		--assert not parse "cat" [2 "cat"]
		--assert not parse "cat" [3 "cat"]
		--assert not parse "cat" [4 "cat"]

	; --test-- "#682"
		; TODO

	; --test-- "#687"
		; console behaviour

	; --test-- "#696"
		; console behaviour

	--test-- "#699"
		letter699: charset "ABCDEF"
		--assert parse "FFh" [2 8 letter699 #"h"]

	--test-- "#702"
		--assert not error? try [
			command702: [
				if-defined | if-not-defined | define | function | comment
			]
		]
		unset 'command702

	; --test-- "#704"
		; console behaviour

	; --test-- "#706"
		; console behaviour

	--test-- "#710"
		; FIXME: not sure if both test should work or both should throw an error.
		;		first tests works with 061, while second does not
		--assert equal? 
			1.373691897708523e131
			do load "27847278432473892748932789483290483789743824832478237843927849327492 * 4932948478392784372894783927403290437147389024920147892940729142"
		; I've changed this, see issue #710			-- hiiamboris
		--assert error? try [74789 * 849032]
		;--assert not error? try [74789 * 849032]

	--test-- "#714"
		a714: load/all "a714"
		b714: load/all "b714"
		--assert equal? [a714] a714
		--assert equal? [b714] b714

	--test-- "#715"
		--assert equal? "blahblah2" append "blah" "blah^2"

	; --test-- "#716"
		; platfor specific compilation problem

	; --test-- "#720"
		; console compilation problem

	--test-- "#725"
		--assert not equal? load {"Español"} "Espa^^(F1)ol"

	--test-- "#726"
		--assert equal? load {{^(line)}} "^/"

	--test-- "#727"
		x727: 0
		rule727: [(x727: 1)]
		parse "a" [collect rule727]
		--assert equal? 1 x727
		unset 'x727
	
	--test-- "#734"
		foo: quote 'bar
		--assert lit-word? quote 'bar
		--assert lit-word? foo
		--assert lit-word? :foo
		unset 'foo
		
	--test-- "#757"
		--assert not error? try [x757: "^(FF)"]
		unset 'x757

	--test-- "#764"
		; NOTE: some test cannot be compiled, because compiler refuses them
		f764: function[][os764: 1] 
		--assert equal? 1 f764
		f764: function[][os764: 1 os764]
		--assert equal? 1 f764
		f764: function[os764][os764] 
		--assert equal? 1 f764 1
		f764: func[][os764: 1] 
		--assert equal? 1 f764
		f764: func[][os764: 1 os764] 
		--assert equal? 1 f764
		f764: func[os764][os764] 
		--assert equal? 1 f764 1
		unset 'os764
		; FIXME: only -t Linux compiler complains about equal? 1 os=unset
		f764: has [os764][os764: 1] 
		--assert equal? 1 f764
		--assert error? do [try [equal? 1 os764]]
		unset 'os764
		f764: has [os764][os764: 1 os764] 
		--assert equal? 1 f764
		--assert error? do [try [equal? 1 os764]]
		f764: does [os764: 1] 
		--assert equal? 1 f764
		f764: does [os764: 1 os764] 
		--assert equal? 1 f764
		unset [f764 os764]

	--test-- "#770"
		f770: function [][
			blk: [1 2 3 4 5]
			foreach i blk [
				case [
					i > 1 [return i]
				]
			]
		]
		g770: function [][if f770 [return 1]]
		--assert equal? 1 g770
		f770: function [][
			case [
				2 > 1 [return true]
			]
		]
		g770: function [][if f770 [return 1]]
		--assert equal? 1 g770
		f770: function [][if true [return true]]
		g770: function [][if f770 [return 1]]
		--assert equal? 1 g770
		g770: function [][if true [return 1]]
		--assert equal? 1 g770
		f770: function [][true ]
		g770: function [][if f770 [return 1]]
		--assert equal? 1 g770
		f770: function [][if true [return true]]
		g770: function [][if (f770) [return 1]]
		--assert equal? 1 g770
		f770: function [][if true [return true]]
		g770: function [][if not not f770 [return 1]]
		--assert equal? 1 g770
		f770: function [][if true [return 'X]]
		g770: function [][if f770 [return 1]]
		--assert equal? 1 g770
		unset [f770 g770]

	; --test-- "#776"
		; console behaviour

	--test-- "#785"
		nd785: charset [not #"0" - #"9"]
		zero785: charset #"0"
		nd-zero785: union nd785 zero785
		--assert not find nd785 #"0"
		--assert not find nd785 #"1"
		--assert find nd785 #"B"
		--assert find nd785 #"}"
		--assert find zero785 #"0"
		--assert not find zero785 #"1"
		--assert not find zero785 #"B"
		--assert not find zero785 #"}"
		--assert find nd-zero785 #"0"
		--assert not find nd-zero785 #"1"
		--assert find nd-zero785 #"B"
		--assert find nd-zero785 #"}"
		unset [nd785 zero785 nd-zero785]

	--test-- "#787"
		--assert equal? ["a"] head reduce/into "a" []

	--test-- "#789"
		--assert not error? try [load "-2147483648"]

	--test-- "#791"
		blk791: [2 #[none] 64 #[none]]
		result791: copy []
		parse blk791 [
			collect into result791 [
				any [
					set s integer! keep (s) | skip
				]
			]
		]
		--assert equal? [2 64] result791
		--assert not tail? result791
		--assert equal? [2 64] head result791
		unset [blk791 result791]

	; --test-- "#796"
		; console behaviour

	; --test-- "#800"
		; console behaviour (ask)

	; --test-- "#806"
		; precompiled console problem

	; --test-- "#817"
		; TODO: need more info

	; --test-- "#818"
		; TODO: need more info

	--test-- "#825"
		the-text825: "outside"
		the-fun825: function [] [the-text825: "Hello, World!" print the-text825]
		--assert equal? spec-of :the-fun825 [/local the-text825]
		the-fun825: func [] [the-text825: "Hello, World!" print the-text825]
		--assert equal? spec-of :the-fun825 []
		the-fun825: function [/extern the-text825] [the-text825: "Hello, World!" print the-text825]
		--assert equal? spec-of :the-fun825 []
		the-fun825: func [/local the-text825] [the-text825: "Hello, World!" print the-text825]
		--assert equal? spec-of :the-fun825 [/local the-text825]
		the-fun825: func [extern the-text825] [the-text825: "Hello, World!" print the-text825]
		--assert equal? spec-of :the-fun825 [extern the-text825]
		the-fun825: func [local the-text825] [the-text825: "Hello, World!" print the-text825]
		--assert equal? spec-of :the-fun825 [local the-text825]
		unset [the-text825 the-fun825]

	; --test-- "#831"
	; 	FIXME: not fixed yet, crashes compiler, see #2207
	; 	f: function [][1]
	; 	f: function [][1]

	; 	f: 100
	; 	--assert not equal? f 100

	--test-- "#849"
		--assert equal? 1.2 1.2
		--assert equal? "ščř" "ščř"
		--assert equal? 1.2 1.2
		--assert equal? -1.0203 -1.0203

	--test-- "#853"
		the-text853: "outside"
		the-fun853: function [
			/extern the-text853
		] [
			the-text853: "Hello, World!"  
			the-text853
		]
		--assert equal? the-fun853 "Hello, World!"
		--assert equal? the-text853 "Hello, World!"
		unset [the-text853 the-fun853]

	--test-- "#854"
		f854: function [/r1 v1 v2 /r2 v3][
			out: copy {}
			either r1 [
				append out reduce [v1 v2]
			][
				append out "We're not v1 or v2."
			]
			either r2 [append out v3][append out "I'm not v3."]
			out
		]
		--assert equal? f854 "We're not v1 or v2.I'm not v3."
		--assert equal?
			f854/r1 "I'm v1!" "I'm v2!"
			"I'm v1!I'm v2!I'm not v3."
		--assert equal? 
			f854/r1/r2 "I'm v1!" "I'm v2!" "I'm v3!"
			"I'm v1!I'm v2!I'm v3!"
		--assert equal? 
			f854/r2/r1 "I'm v3!" "I'm v1!" "I'm v2!"
			"I'm v1!I'm v2!I'm v3!"
		unset 'f854

	--test-- "#856"
		--assert equal? [a bčř 10] load "a bčř 10"

	--test-- "#869"
		--assert not error? try [load {[1 2.3]}]

	--test-- "#871"
		--assert word? first first [:a/b]

	--test-- "#873"
		parse s873: "" [insert (#0)]
		--assert equal? "0" head s873
		unset 's873

	comment { it should not be necessary to use print in this test
	
	--test-- "#876"
		--assert error? try [
			foreach w876 words-of system/words [
				if w876 = 'xx [
					print [w876 tab type? get w876]
				]
			]
		]
	}
	
	; --test-- "#893"
		; console precompilation problem

	--test-- "#899"
		--assert error? try [load {p: [a/b:/c]}]

	--test-- "#913"
		person913: make object! [
			name: none
			new: func [ n ][
				make self [
					name: n
				]
			]
		]

		Bob913: person913/new "Bob913"
		--assert equal? "Bob913" Bob913/name
		unset [person913 Bob913]

	--test-- "#919"
		o919: context [
			a: 0
			set 'f does [a: 1]
		]
		equal? f object [a: 1]
		unset 'o919

	--test-- "#920"
		f920: func [o920 [object!]] [
			o920/a: 1
		]
		--assert equal? 1 f920 object [a: 0]
		o920: object [a: 0]
		--assert equal? 1 f920 o920
		unset [f920 o920]

	--test-- "#927"
		f927: does [
			object [
				a: 1
				g: does [a]
			]
		]

		--assert object? obj927: f927

		; FIXME: current known compiler limitation is that it treats `g` as `:g` when `g` is a function!
		; using `do` as a temporary workaround for now
		--assert do [1 = obj927/g]

		obj927: object [
			a: 1
			f927: does [a]
		]
		--assert equal? 1 obj927/a
		--assert equal? 1 obj927/f927
		unset [f927 obj927]

	--test-- "#928"
		o928: object [
			a: 1

			c: context [
				b: 2

				f: does [a]
			]
		]
		--assert not error? try [o928/c/f]
		--assert equal? 1 o928/c/f
		unset 'o928

	--test-- "#929"
		out929: copy ""
		c929: context [
			f: does [
				append out929 "*"
			]
			g: does [
				do [f]
				append out929 "!"
				f
			]
		]
		--assert equal? "*!*" c929/g
		unset [out929 c929]

	--test-- "#931"
		p1-931: context [
			a: 1
			f: does [a]
		]

		p2-931: context [
			a: 2
		]

		ch931: make p1-931 p2-931
		--assert equal? 2 ch931/f
		unset [p1-931 p2-931 ch931]

	--test-- "#932"
		p1-932: context [
			a: 1
			f: does [a]
		]
		p2-932: context [
			a: 2
			f: does [100]
		]
		ch932: make p1-932 p2-932
		--assert equal? 100 ch932/f
		unset [p1-932 p2-932 ch932]

	--test-- "#939"
		b939: [#"x" #"y"]
		--assert not error? try [b939/(#"x")]
		--assert equal? #"y" b939/(#"x")
		unset 'b939

	; --test-- "#943"
		a943: none
		b943: none
	 	bar943: func [/with a [block!] b][
	 		a943: a 
	 		b943: b
	 	]
	 	--assert error? try [bar943/with 5 6]
	 	bar943/with [5] 6
	 	--assert a943 = [5]
	 	--assert b943 = 6

	; --test-- "#967"
		; R/S

	--test-- "#971"
		unset 'f
		c971: context [
			set 'f does []
		]
		--assert not unset? 'f
		unset [c971 f]

	--test-- "#973"
		a973: func [] [
			repeat i973 2 [i973 * 10]					;-- don't return the counter itself to better catch regressions
		]
		b973: copy []
		repeat j983 2 [append b973 a973]
		--assert equal? [20 20] b973
		unset [a973 b973 i973 j973]

	--test-- "#974"
		--assert not error? try [random 3]

	--test-- "#980"
		c980: context [
			set 'f980 does []
		]
		--assert not error? try [f980]
		unset [c980 f980]

	--test-- "#981"
		b981: [a: none]
		--assert equal? object b981 context b981
		unset 'b981

	--test-- "#983"
		f983: func [
			o
		] [
			switch o/x [
				0 []
			]
		]
		--assert unset? f983 object [x: 0]
		unset 'f983

	; --test-- "#988"
		; TODO: platform specific compilation problem

	--test-- "#990"
		f990: func [
			o [object!]
		] [
			switch type?/word o/x [
				integer! [
					'integer
				]
			]
		]
		--assert equal? 'integer f990 object [x: 0]
		unset 'f990

	comment { It should not be necessary to use  print in this test
	--test-- "#993"
		f993: func [
			o [object!]
			/local a
		] [
			switch a: type? o/x [
				integer! [
					print "?"
				]
			]
		]
		--assert not error? try [f993 object [x: 0]]
		unset 'f993
	}

	; --test-- "#994"
		; TODO: caused by Rebol GC bug

	; --test-- "#995"
		; TODO: architecture specific problem

	unset 'true?

===end-group===


===start-group=== "issues #1001 - #2000"

	true?: func [value] [not not value]

	--test-- "#1001"
		o1001: context [a: 1 b: "x"]
		--assert equal? 
			[integer! string!] 
			collect [foreach w words-of o1001 [keep type?/word get w]]
		unset 'o1001

	; --test-- "#1005"
		; precompiled binary error

	; --test-- "#1019"
		; TODO: library compilation problem

	; --test-- "#1020"
		; console behaviour

	--test-- "#1055"
		; FIXME: still unresolved in 0.6.4; see the issue
		; my-context: context [
		; 	do-something: routine [ 
		; 		num [integer!] 
		; 		return: [integer!]
		; 		/local
		; 		ret
		; 	] [
		; 		ret: num + 1
		; 		ret
		; 	]
		; ]

		; --assert equal? 2 my-context/do-something 1
		; unset 'my-context

;	--test-- "#1063"
; 		TODO: help not defined in compiler
;		--assert not error? try [help]

	 --test-- "#1074"
	 	d1074: none
	 	unset 'd1074
	 	--assert error? try [d1074]
	 	x1074: [d1074 1]
	 	--assert equal? 1 select x1074 'd1074
	 	--assert error? try [select x1074 d1074]
	 	--assert error? try [d1074]
	 	unset 'x1074

	; --test-- "#1079"
		; TODO: console behaviour

	; --test-- "#1085"
		; build server problem

	--test-- "#1088"
		b1: ["a" "b" "c" "d" "e"]
		b2: ["a" "b" "b" "d" "e"]
		b3: ["a" "b" "b" "b" "e"]
		h1: make hash! b1
		h2: make hash! b2
		h3: make hash! b3

		s2b1: select/skip b1 "c" 2
		s3b1: select/skip b1 "d" 3
		s2b2: select/skip b2 "b" 2
		s3b3: select/skip b3 "b" 3

		s2h1: select/skip h1 "c" 2
		s3h1: select/skip h1 "d" 3
		s2h2: select/skip h2 "b" 2
		s3h3: select/skip h3 "b" 3

		--assert equal? s2b1 "d"
		--assert equal? s3b1 "e"
		--assert equal? s2b2 "d"
		--assert equal? s3b3 "e"
		--assert equal? s2h1 "d"
		--assert equal? s3h1 "e"
		--assert equal? s2h2 "d"
		--assert equal? s3h3 "e"

		unset [b1 b2 b3 h1 h2 h3 s2b1 s3b1 s2b2 s3b3 s2h1 s3h1 s2h2 s3h3]

	;--test-- "#1090"		;-- requires compilation

	--test-- "#1093"
		str1093: none ; othrwise compiler would complain that STR has no value
		parse "abcde" ["xyz" | copy str1093 to end]
		--assert equal? "abcde" str1093
		unset 'str1093

	; --test-- "#1098"
		; console behaviour

	; --test-- "#1102"
		; TODO

	--test-- "#1113"
		a1113: "abcz"  
		b1113: 5 
		--assert none? a1113/5 
		--assert none? a1113/:b1113
		--assert error? try [a1113/b1113]
		unset [a1113 b1113]

	; --test-- "#1115"
		; console behaviour

	--test-- "#1116"
		o1116: object [
			sin*: :sin
			set 'sin1116 does [
				; FIXME: current known compiler limitation is that it treats `o1116/sin*` as `o1116/:sin*`
				; using `do` as a temporary workaround for now
				do [sin* none]
			]
		]
		e1116: try [sin1116]
		--assert true? all [
			error? e1116
			not equal? "<anon>" mold e1116/arg3
		]

	--test-- "#1119"
		--assert error? try [append/only: [a b c] [d e]]

	; --test-- "#1122"
		; console

	--test-- "#1126"
		--assert error? try [load "#"]
		--assert error? try [do [load "#"]]

	--test-- "#1128"
		--assert equal?
			mold [series/:i: series/(len - (i - 1)) series/(len - (i - 1)): tmp]
			{[series/:i: series/(len - (i - 1)) series/(len - (i - 1)): tmp]}

	; --test-- "#1130"
		; console behaviour

	--test-- "#1136"
		e1136: try [load {a: func [][set 'b: 1]}]
		--assert to logic! all [
			equal? e1136/type 'syntax
			equal? e1136/id 'invalid
			equal? e1136/arg2 lit-word!
		]

	comment { probe should be mocked for this test
	--test-- "#1143"
		--assert not error? try [
			do [
				a1143: object [
					b: object [
						c: 1
					]
					d: does [
						make a1143 [b: none]
						probe b/c
					]
				]
				a1143/d
			]
		]
		--assert equal? 1 z1143: do [
			a1143: object [
				b: object [
					c: 1
				]
				d: does [
					probe b/c
				]
			]
			e: copy/deep a1143
			f: make e [b: none]
			a1143/d
		]
	}
	; --test-- "#1144"
	;	; FIXME: still open
	; 	f1144: function [][
	; 		op: :form
	; 		append op 1 2
	; 	]
	; 	--assert not error? try [f1144]

	; --test-- "#1146"
		; console behaviour

	; --test-- "#1147"
		; console behaviour

	--test-- "#1148"
		try-func1148: func [v [block!]][error? try v]
		--assert try-func1148 [unset-word]

	; --test-- "#1153"
		; TODO

	--test-- "#1154"
	f1154: function [
		/s string [string!]
		/i integer [integer!]
	][]
	--assert not error? try [do [f1154/i/s 1 "a"]]

	--test-- "#1158"
		ret1158: copy []
		v1158: make vector! [1 2 3 4 5 6 7 8 9]
		foreach [v1 v2 v3] v1158 [repend ret1158 [v1 v2 V3]]
		--assert equal? [1 2 3 4 5 6 7 8 9] ret1158
		unset [v1158 ret1158]

	comment { print should be mocked or patched for this test
	--test-- "#1160"
		abc1160: 2
		--assert not error? try [print [ABC1160]]
	}

	comment { print should be mocked or patched for this test
	--test-- "#1163"
		f1163: function [
			/l
		][
			b: []
			if l [return b]
			append b 1
		]
		--assert not error? try [foreach a1163 f1163/l [print a1163]]
		f1163: does [return [1]]
		--assert not error? foreach a1163 f1163 [print a1163]
		unset 'f1163
	}

	; --test-- "#1164"
		; console behaviour

	--test-- "#1167"
		ret1167: copy []
		--assert block? case/all [
 			1 < 2 [append ret1167 1]
    		true [append ret1167 2]
		]
		--assert equal? [1 2] ret1167

	; --test-- "#1169"
		; console behaviour

	; --test-- "#1186"
		; console behaviour

	--test-- "#1199"
		test1199: func [input [block!] /local exp-res reason] [
			exp-res: get input/expect
		]
		--assert not error? try [test1199 ["" expect true]]

	--test-- "#1206"
		m1206: #(a 1 b 2)
		remove/key m1206 'a
		remove/key m1206 'a
		--assert equal? m1206 #(b 2)
		--assert equal? [b] keys-of m1206
		--assert equal? [2] values-of m1206

	--test-- "#1209"
		; should test for freeze
		--assert not error? try [parse [a: 1.2.3] [some [remove tuple! | skip]]]

	--test-- "#1213"
		--assert error? try [load "1.2..4"]

	--test-- "#1218"
		--assert error? try [load "p: [a/b:/c]"]

	--test-- "#1222"
		o1222: make object! [a: 1 b: 7 c: 13]
		--assert error? try [o1222/("c")]

	; --test-- "#1232"
		; TODO

; 	FIXME: causes internal compiler error, see #2198
;	--test-- "#1238"
;		e: try [pick/case #(a 1 b 2) 'B]
;		--assert equal? 'case e/arg2

	--test-- "#1243"
		b1243: ["A" "a" "b1243" "B"]
		d1243: ["E" "e" "b1243" "B"]
		--assert equal? ["A" "a" "b1243" "B" "E" "e"] union/skip b1243 d1243 2

	; --test-- "#1245"
		; TODO

	; --test-- "#1246"
		; console behaviour

	--test-- "#1259"
		--assert not equal? charset "abc" negate charset "abc"
	
	--test-- "#1265"
		--assert equal? -1x-2 negate 1x2

	--test-- "#1275"
		o1275: context [f: does [self]]
		x1275: o1275/f
		--assert same? o1275 x1275

	; --test-- "#1281"
		; TODO

	; --test-- "#1284"
		; crush.dll problem

	; --test-- "#1290"
		; GUI

	--test-- "#1307"
		h1307: make hash! [1x2 0 3x4 1]
		--assert equal? 0 select h1307 1x2
		--assert equal? make hash! [3x4 1] find h1307 3x4

	--test-- "#1329"
		--assert not error? try [and~ #{01} #{FF}]
		--assert not error? try [or~ #{01} #{FF}]
		--assert not error? try [xor~ #{01} #{FF}]

	--test-- "#1354"
		--assert error? try [0 ** "death"]

	--test-- "#1378"
		--assert equal? 1.1.1.1 0.0.0 + 1.1.1.1
		--assert equal? 2.1.1.1 1.0.0 + 1.1.1.1
		--assert equal? 4.4.4.0 1.2.3 + 3.2.1.0
		--assert equal? 3.3.3.3 0.1.2.3 + 3.2.1
		--assert equal? 2.2.2.0 1.1.1 * 2.2.2.0

	--test-- "#1384"
		--assert not error? try [read %.]
		--assert error? try [read %""]

	--test-- "#1396"
		e1396: try [load {(5+2)}]
		--assert all [
			equal? e1396/id 'invalid
			equal? e1396/arg2 integer!
		]
		e1396: try [load {[5+2]}]
		--assert all [
			equal? e1396/id 'invalid
			equal? e1396/arg2 integer!
		]

	--test-- "#1416"
		a1416: "1234" 
		b1416: skip a1416 2 
		copy/part b1416 a1416
		
		a1416: skip "1234" 2
		--assert equal? "12" copy/part a1416 -2
		unset [a1416 b1416]

	--test-- "#1417"
		--assert not error? try [-5 // 3]

	--test-- "#1418"
		--assert not strict-equal? 0.0 0
		--assert not strict-equal? -0.0 0
		--assert not strict-equal? +0.0 0
		--assert not strict-equal? 1.0 1
		--assert not 0.0 == 0
		--assert not -0.0 == 0
		--assert not +0.0 == 0
		--assert not 1.0 == 1

	--test-- "#1420"
		--assert not error? try [o1420: make object! compose [a: (add 1 1)]]

	; --test-- "#1422"
		; GUI

	; --test-- "#1424"
		; GUI

	; --test-- "#1435"
		; GUI

	; --test-- "#1438"
		; GUI

	; --test-- "#1443"
		; GUI

	; --test-- "#1449"
		; GUI

	; --test-- "#1451"
		; GUI

	; --test-- "#1456"
		; GUI

	; --test-- "#1457"
		; GUI

	; --test-- "#1458"
		; TODO? compiler problem with .ico file missing

	; --test-- "#1464"
		; GUI

	; --test-- "#1468"
		; GUI

	--test-- "#1472"
		--assert equal? [a] unique [a A]
		--assert equal? [a A] unique/case [a A]
		--assert equal? "a" unique "aA"
		--assert equal? "aA" unique/case "aA"

	--test-- "#1475"
		--assert logic? true
		--assert logic? false

	--test-- "#1477"
		write qt-tmp-file ""
		write/append qt-tmp-file "hi"
		write/append qt-tmp-file "there"
		--assert equal? "hithere" read qt-tmp-file

	; --test-- "#1479"
		; GUI

	; --test-- "#1481"
		; R/S

	; --test-- "#1485"
		; GUI

	; --test-- "#1487"
		; GUI

	; --test-- "#1489"
		; GUI

	--test-- "#1490"
		; should check for crash
		o1490: make object! [f: 5]
		--assert error? try [do load {set [o1490/f] 10}]
		unset 'o1490

	; --test-- "#1493"
		; GUI

	; --test-- "#1496"
		; GUI

	--test-- "#1499"
		b1499: none
		unset 'b1499
		--assert error? try [get 'b1499]
		--assert unset? get/any 'b1499

	; --test-- "#1500"
		; GUI

	--test-- "#1501"
		; requires View
		; FIXME: linux compiler won't swallow this, using `do`
		do [if all [system/view value? 'image! datatype? get 'image!] [
			c1501: 0
			foreach i1501 make image! 100x100 [c1501: c1501 + 1]
			--assert equal? 10'000 c1501
			unset 'c1501
		]]

	; --test-- "#1502"
		; GUI

	--test-- "#1509"
		ctx1509: object [
			f: func [val /ref][val] 
			t: does [f/ref 1]
		]
		not error? try [ctx1509/t]
		unset 'ctx1509

	--test-- "#1515"
		--assert not error? try [1.222090944E+33 // -2147483648.0] ; expected 0
		--assert equal? 0.0 1.222090944E+33 // -2147483648.0 
		; FIXME: this is still unfixed:
		;--assert equal? 0.0 1.222090944E+33 % -2147483648.0 

	; --test-- "#1519"
		; TODO: call-test.red problem

	; --test-- "#1522"
		; GUI

	; --test-- "#1527"
		; GUI

	; --test-- "#1528"
		; GUI

	; --test-- "#1530"
		; TODO: compiler should check for 2x #import

	; --test-- "#1537"
		; GUI

	; --test-- "#1540"
		; GUI

	--test-- "#1542"
		fl1542: to float! 7
		--assert 7 = to integer! fl1542
		unset 'fl1542

	; --test-- "#1551"
		; GUI

	; --test-- "#1557"
		; GUI

	; --test-- "#1558"
		; GUI

	; --test-- "#1559"
		; GUI

	; --test-- "#1561"
		; TODO: error in Rebol

	; --test-- "#1562"
		; GUI console behaviour

	; --test-- "#1565"
		; GUI

	; --test-- "#1566"
		; GUI console behaviour

	; --test-- "#1567"
		; GUI console behaviour

	; --test-- "#1568"
		; GUI console behaviour

	; --test-- "#1570"
		; GUI

	; --test-- "#1571"
		; GUI

	; --test-- "#1574"
		; GUI

	; --test-- "#1576"
		; GUI

	; --test-- "#1578"
		; GUI

	; --test-- "#1583"
		; GUI console behaviour

	; --test-- "#1587"
		; GUI console behaviour

	--test-- "#1590"
		str1590: "1.1.1"
		find/part str1590 "1." 2
		--assert equal? "1.1" str1590: skip str1590 2
		unset 'str1590
		
	; --test-- "#1591"
		; console behaviour

	; --test-- "#1592"
		; GUI

	; --test-- "#1593"
		; GUI

	; --test-- "#1596"
		; GUI

	; --test-- "#1600"
		; GUI

	; --test-- "#1606"
		; console behaviour

	; --test-- "#1607"
		; TODO: random crash?
	comment { This test needs to capture the output from parse-trae
	--test-- "#1609"
		not error? try [parse-trace "12345678" ["1" to end]]
	}
		
	--test-- "#1611"
		--assert parse "123" [copy a-txt "1" (a-num: to integer! a-txt) copy b-txt "2" (b-num: to integer! b-txt) "3"]

	; --test-- "#1622"
		; GUI

	; --test-- "#1624"
		; GUI

	--test-- "#1627"
		--assert same? #[none] none

	; --test-- "#1628"
		; GUI

	; --test-- "#1630"
		; GUI

	; --test-- "#1632"
		; GUI

	; --test-- "#1633"
		; GUI

	; --test-- "#1645"
		; GUI

	; --test-- "#1646"
		; GUI

	; --test-- "#1655"
		; GUI

	; --test-- "#1657"
		; GUI

	; --test-- "#1670"
		; GUI

	; --test-- "#1671"
		; GUI

	; --test-- "#1674"
		; GUI

	; --test-- "#1677"
		; GUI

	; --test-- "#1678"
		; GUI

	--test-- "#1680"
		f1680: func [] [keys-of #(1 2) none]
		--assert not error? try [f1680]
		unset 'f1680

	; --test-- "#1683"
		; GUI

	; --test-- "#1684"
		; GUI

	; --test-- "#1709"
		; TODO: WHAT is not defined in compiler

	; --test-- "#1715"
		; console behaviour

	; --test-- "#1717"
		; GUI

	; --test-- "#1718"
		; GUI

	--test-- "#1723"
		; not sure if spawning lots of files is a good idea for a general test script
		; FIXME: perhaps there should be a dedicated script for this
		; commenting this out for now 			-- hiiamboris

		; write %中坜 "test"
		; --assert equal? "test" read %中坜

	--test-- "#1729"
		not error? try [123456789123456789]
		equal? 123456789123456789 1.234567891234568e17

	--test-- "#1730"
		not error? try [reduce does ["ok"]]

	; --test-- "#1732"
		; FIXME: example throws error: eval-command has no value

	--test-- "#1741"
		--assert not error? try [foreach a1741 [1 2 3 4][break]]
		--assert not error? try [repeat n1741 4 [break]]

	; --test-- "#1745"
		; GUI

	--test-- "#1746"
		; should check for crash
		s1746: make object! [m: func [][] b: func [arg][compose/deep [(arg)]]]
		s2: make s1746 []
		--assert equal? [1] s1746/b 1
		unset [s1746 s2]

	--test-- "#1750"
		e1750: try [load "2#{FF}"]
		--assert to-logic all [
			error? :e1750
			equal? e1750/type 'syntax
			equal? e1750/id 'invalid
			equal? e1750/arg2 binary!
		]
		e1750: try [load "64#{AA}"]
		--assert to-logic all [
			error? :e1750
			equal? e1750/type 'syntax
			equal? e1750/id 'invalid
			equal? e1750/arg2 binary!
		]
		e1750: try [load "4#{0}"]
		--assert to-logic all [
			error? :e1750
			equal? e1750/type 'syntax
			equal? e1750/id 'invalid
			equal? e1750/arg2 binary!
		]
		not error? try [load "16#{AA}"]
		unset 'e1750

	; --test-- "#1751"
		; TODO: R/S

	; --test-- "#1753"
		; TODO take a look

	; --test-- "#1754"
		; GUI

	; --test-- "#1755"
		; GUI

	; --test-- "#1762"
		; GUI console behaviour

	; --test-- "#1764"
		; console behaviour (nonGUI)

	;; DEPRECATED: raw string syntax deprecates this test and issue.
	;--test-- "#1768"
	;	--assert not error? try [load {a: %{test ing.txt}}]
	;	--assert equal? [a: % "test ing.txt"] load {a: %{test ing.txt}}

	; --test-- "#1769"
		; console behaviour

	; --test-- "#1775"
		; console behaviour (nonGUI)

	; --test-- "#1781"
		; GUI console behaviour

	--test-- "#1784"
		--assert equal?
			[1 1 1 1 1 2]
			max [1 1 1 1] [1 1 1 1 1 2]
		--assert equal?
			[1 1 1 1]
			min [1 1 1 1] [1 1 1 1 1 2]

	; --test-- "#1785"
		; GUI

	; --test-- "#1790"
		; GUI

	; --test-- "#1797"
		; GUI

	--test-- "#1799"
		--assert equal?
			[1 2 3 a b c d e]
			head insert [a b c d e] [1 2 3]
		--assert equal?
			[1 2 1 2 1 2 a b c d e]
			head insert/dup [a b c d e] [1 2] 3
		--assert equal?
			[[1 2] a b c d e] 
			head insert/only [a b c d e] [1 2]
		--assert equal?
			[[1 2] [1 2] [1 2] a b c d e]
			head insert/only/dup [a b c d e] [1 2] 3
		--assert equal?
			[1 2 3 [4 5] 6 a b c d e]
			head insert [a b c d e ] [1 2 3 [4 5] 6]
		--assert equal?
			[1 2 3 [4 5] 6 1 2 3 [4 5] 6 a b c d e]
			head insert/dup [a b c d e] [1 2 3 [4 5] 6] 2
		--assert equal?
			[[1 2 3 [4 5] 6] a b c d e]
			head insert/only [a b c d e] [1 2 3 [4 5] 6]
		--assert equal?
			[[1 2 3 [4 5] 6] [1 2 3 [4 5] 6] a b c d e]
			head insert/only/dup [a b c d e] [1 2 3 [4 5] 6] 2
		--assert equal?
			[123 a b c d e]
			head insert [a b c d e] 123
		--assert equal?
			[123 123 123 a b c d e]
			head insert/dup [a b c d e] 123 3
		--assert equal?
			[123 a b c d e]
			head insert/only [a b c d e] 123
		--assert equal?
			[123 123 123 a b c d e]
			head insert/only/dup [a b c d e] 123 3
		--assert equal?
			["123" a b c d e]
			head insert [a b c d e] "123"
		--assert equal?
			["123" "123" "123" a b c d e]
			head insert/dup [a b c d e] "123" 3
		--assert equal?
			["123" a b c d e]
			head insert/only [a b c d e] "123"
		--assert equal?
			["123" "123" "123" a b c d e]
			head insert/only/dup [a b c d e] "123" 3
		--assert equal?
			[123.10.2.3 a b c d e]
			head insert [a b c d e] 123.10.2.3
		--assert equal?
			[123.10.2.3 123.10.2.3 123.10.2.3 a b c d e]
			head insert/dup [a b c d e] 123.10.2.3 3
		--assert equal?
			[123.10.2.3 a b c d e]
			head insert/only [a b c d e] 123.10.2.3
		--assert equal?
			[123.10.2.3 123.10.2.3 123.10.2.3 a b c d e]
			head insert/only/dup [a b c d e] 123.10.2.3 3
		--assert equal?
			"123abcde"
			head insert "abcde" [1 2 3]
		--assert equal?
			"121212abcde"
			head insert/dup "abcde" [1 2] 3
		--assert equal?
			"123abcde"
			head insert/only "abcde" [1 2 3]
		--assert equal?
			"121212abcde"
			head insert/only/dup "abcde" [1 2] 3
		--assert equal?
			"123 4 56abcde"
			head insert "abcde" [1 2 [3 4 5] 6]
		--assert equal?
			"123 4 56123 4 56123 4 56abcde"
			head insert/dup "abcde" [1 2 [3 4 5] 6] 3
		--assert equal?
			"123 4 56abcde"
			head insert/only "abcde" [1 2 [3 4 5] 6]
		--assert equal?
			"123 4 56123 4 56123 4 56abcde"
			head insert/only/dup "abcde" [1 2 [3 4 5] 6] 3
		--assert equal?
			"123abcde"
			head insert "abcde" 123
		--assert equal?
			"121212abcde"
			head insert/dup "abcde" 12 3
		--assert equal?
			"123abcde"
			head insert/only "abcde" 123
		--assert equal?
			"121212abcde"
			head insert/only/dup "abcde" 12 3
		--assert equal?
			"123abcde"
			head insert "abcde" "123"
		--assert equal?
			"121212abcde"
			head insert/dup "abcde" "12" 3
		--assert equal?
			"123abcde"
			head insert/only "abcde" "123"
		--assert equal?
			"121212abcde"
			head insert/only/dup "abcde" "12" 3
		--assert equal?
			"123.10.2.3abcde"
			head insert "abcde" 123.10.2.3
		--assert equal?
			"123.10.2.3123.10.2.3abcde"
			head insert/dup "abcde" 123.10.2.3 2
		--assert equal?
			"123.10.2.3abcde"
			head insert/only "abcde" 123.10.2.3
		--assert equal?
			"123.10.2.3123.10.2.3abcde"
			head insert/only/dup "abcde" 123.10.2.3 2
		--assert equal?
			[#"X" a b c d e]
			head insert [a b c d e] #"X"
		--assert equal?
			[#"X" #"X" #"X" a b c d e]
			head insert/dup [a b c d e] #"X" 3
		--assert equal?
			"XXXabcde"
			head insert/dup "abcde" #"X" 3

	comment: { print, probe and ?? should be mocked in this test
	--test-- "#1807"
		m1807: #(a1807: 1)
		a1807: m1807/a1807
		--assert not error? try [probe a1807]
		--assert not error? try [print type? a1807]
		--assert not error? try [?? a1807]
		unset [a1807 m1807]
	}

	; --test-- "#1809"
		; GUI

	--test-- "#1814"
		t1814: 1.4.3
		--assert equal? 1 min min t1814/1 t1814/2 t1814/3
		--assert equal? 4 max max t1814/1 t1814/2 t1814/3
		--assert equal? 49 50 - t1814/1
		--assert equal? 21 20 + t1814/1
		--assert equal? 21 t1814/1 + 20
		unset 't1814

	; --test-- "#1816"
		; GUI

	; --test-- "#1817"
		; GUI

	; --test-- "#1820"
		; GUI

	comment { probe should be mocked for this test 
	--test-- "#1829"
		md5: does ['MD5]
		--assert function? do "probe :md5"
		unset 'md5
	}
	
	--test-- "#1834"
		--assert equal? #(a: 3) extend/case extend/case make map! [a 1] [a 2] [a 3]

	--test-- "#1835"
		m1835: make map! [a 1 A1835 2]
		--assert equal? 2 select/case m1835 'A1835
		--assert equal? 1 select/case m1835 'a
		--assert equal?
			make map! [a: 1 a 2]
			make map! [a 1 a: 2]
		m1835: make map! [a 1 A1835 2 a: 3 :a 4]
		--assert equal? m1835 #(a: 4 A1835: 2)
		unset 'm1835

	; --test-- "#1838"
		; GUI

	; --test-- "#1847"
		; GUI

	; --test-- "#1853"
		; GUI

	--test-- "#1865"
		--assert not equal? 2 (a: 'ok 1 + 1 :a)
		--assert equal? 'ok (a: 'ok 1 + 1 :a)
		unset 'a

	--test-- "#1867"
		; TODO: original error should result in endless loop. how to check it?
		rule1867: [
			any [
				to "[" 
				start-mark: 
				skip 
				copy content 
				to "]" 
				skip 
				end-mark: 
				(insert/only remove/part start-mark end-mark content)
			]
		]
		x1867: [1 2 "[" a b "]" 3 4]
		--assert parse x1867 rule1867
		unset [rule1867 x1867]

	; --test-- "#1869"
		; GUI

	; --test-- "#1872"
		; GUI

	; --test-- "#1874"
		; GUI

	; --test-- "#1879"
		; GUI

	; --test-- "#1880"
		; Rebol GC bug

	--test-- "#1881"
		a1881: none
		--assert not error? try [
			rule1881: [ 
				any [
					mark1881: set a1881 [ any-word! ] (
						if [ ][ ]
					) | into rule1881 | skip
				] 
			]
		]
		unset [rule1881 mark1881]

	--test-- "#1882"
		a1882: "X"
		digit1882: charset "0123456789"
		content1882: "a&&1&&2&&3m"
		block1882: copy [] 
		parse content1882 [
			collect into block1882 any [
				remove keep ["&&" some digit1882] insert (a1882) 
			|	skip
			]
		]
		--assert equal? content1882 "aXXXm"
		unset [a1882 digit1882 content1882 block1882]

	; --test-- "#1883"
		; GUI

	; --test-- "#1884"
		; GUI

	--test-- "#1887"
		s1887: {a
b}
		--assert equal? {a^/b} s1887
		--assert not equal? {a^M^/b} s1887
		unset 's1887

	; --test-- "#1889"
		; GUI

	; --test-- "#1892"
		; binding problem when including external file 
		; TODO: needs separate file for testing

	--test-- "#1893"
		--assert equal? (1.4.8 * 3) (3 * 1.4.8)

	; --test-- "#1900"
		; GUI

	--test-- "#1905"
		x1905: [a b c 4 d e f]
		move/part x1905 skip x1905 3 2
		--assert equal? x1905 [c 4 a b d e f]
		unset 'x1905

	; --test-- "#1910"
		; GUI

	--test-- "#1911"
		m1911: make map! []
		k1911: "a"
		put m1911 k1911 1
		k1911: "b"
		--assert error? try [set m1911 k1911]
		unset [m1911 k1911]

	; --test-- "#1916"
		; GUI

	; --test-- "#1919"
		; GUI console behaviour

	; --test-- "#1920"
		; GUI

	--test-- "#1923"
		a1923: [1 2 3] 
		forall a1923 [if a1923/1 = 2 [break]]
		--assert equal? a1923 [2 3]
		unset 'a1923

	; --test-- "#1925"
		; OPEN
		; NOTE: Red Compiler internal error

		; test!: object [
		; clone: func [
		; 	/local ret [test!]
		; ][
		; 	ret: make test! []
		; 	;initialize ret here, in real application
		; 	ret
		; 	]
		; ]

	; --test-- "#1930"
		; GUI

	; --test-- "#1933"
		; GUI

	; --test-- "#1937"
		; GUI console behaviour

	--test-- "#1939"
		a1939: none
		unset 'a1939
		--assert error? try [parse blk1939: [1][change integer! a1939]]
		unset 'blk1939

	; --test-- "#1942"
		; GUI

	--test-- "#1947"
		--assert equal? [1] find [a 1] integer!

	; --test-- "#1953"
		; GUI console behaviour
		
	; --test-- "#1963"
		; GUI console behaviour

	; --test-- "#1965"
		; R/S

	--test-- "#1968"
		--assert not equal? mold #"^(005E)" mold #"^(001E)"
		--assert equal? {#"^^(1E)"} mold #"^(001E)"

	; --test-- "#1983"
		; TODO: no example code

	; --test-- "#1991"
		; console behaviour

	; --test-- "#1992"
		; GUI

	--test-- "#1993"
		unset [a1993 range1993]
		range1993: [0 0] 
		a1993: range1993/1: 1
		--assert equal? [1 0] range1993
		unset [a1993 range1993]

	 --test-- "#1995"
	 	a1995: none
	 	unset 'a1995
	 	--assert error? try [load/next "(]" 'a1995]

	--test-- "#1996"
		blk1996: [a b #x #y 2 3]
		put blk1996 2 4
		--assert equal? [a b #x #y 2 4] blk1996
		unset 'blk1996

	; --test-- "#1999"
		; Test exists in suite

	unset 'true?

===end-group===


===start-group=== "regressions #2001+"

	true?: func [value] [not not value]

	; --test-- "#2003"
		; GUI console

	--test-- "#2012"
		random/seed 1
		t2012: random 0:0:1
		--assert equal? 0:00:00.0 round t2012
		unset 't2012

	--test-- "#2014"
		--assert equal? 1:00:00 / 0:0:1 3600.0

	--test-- "#2015"
		--assert error? try [0:0:2 ** 5]

	--test-- "#2021"
		--assert error? try [set 'vv2021 first reduce [()]]
	
	--test-- "#2024"
		write qt-tmp-file "abcdef"
		--assert equal? "bcdef" read/seek qt-tmp-file 1

	--test-- "#2031"
		--assert equal? ["1" "3" "" "3" "" ""] split "1,3,.3,," charset ".,"

	--test-- "#2033"
		--assert not error? try [func [x "radius" y "degrees"][x + y]]

	; --test-- "#2034"
		; GUI

	; --test-- "#2041"
		; GUI

	; --test-- "#2048"
		; R/S

	; --test-- "#2050"
		; GUI console behaviour

	; --test-- "#2052"
		; GUI console behaviour

	--test-- "#2068"
;		TODO: need more info, what is maximal length of tuple?
;			it is still buggy when compiled
		x2068: 1.2.3.4.5.6.7.8.9.10
		--assert equal? x2068 1.2.3.4.5.6.7.8.9.10
		x2068: 1.2.3.4.5.6.7.8.9.10.11.12
		--assert equal? x2068 1.2.3.4.5.6.7.8.9.10.11.12
		unset 'x2068

	--test-- "#2069"
		--assert equal? "abc1abc2abc3" unique/skip "abc1abc2abc3" 3

	; --test-- "#2070"
		; GUI

	; --test-- "#2072"
		m2072: make map! 10
		a2072: [1 2 3]
		m2072/a: a2072
		save qt-tmp-file m2072
		n2072: load qt-tmp-file
		--assert equal? m2072 n2072
		unset [a2072 m2072 n2072]

	--test-- "#2077"
		; NOTE: shouldn't override the `sum` func, or next tests using it may fail
		sum2077: function [list [block!]] [
			total: 0
			foreach i list [total: i + total]
			total
		]
		r2077: make reactor! [l: [3 4 5 6] total: is [sum2077 l]]
		r2077/l: append copy r2077/l 5
		--assert not error? try [append r2077/l 5]
		unset [sum2077 r2077]

	--test-- "#2079"
		; requires View
		; FIXME: linux compiler won't swallow this, using `do`
		do [if all [system/view value? 'image! datatype? get 'image!] [
			i2079: make image! 2x2
			--assert not error? try [foreach p2079 i2079 [p2079]]
			unset 'i2079
		]]

	; --test-- "#2081"
		; GUI

	--test-- "#2083"
		a2083: make reactor! [x: 1 y: is [x + 1] z: is [y + 1]]
		a2083/x: 4
		--assert equal? 6 a2083/z
		unset 'a2083

	--test-- "#2085"
		--assert error? try [d2085: make reactor! [x: is [y + 1] y: is [x + 3]]]

	; --test-- "#2096"
		; TODO

	--test-- "#2097"
		write qt-tmp-file #{00000000}
		write/seek qt-tmp-file #{AAAA} 2
		--assert equal? #{0000AAAA} read/binary qt-tmp-file
		write/seek qt-tmp-file #{BBBB} 0
		--assert equal? #{BBBBAAAA} read/binary qt-tmp-file

	; --test-- "#2098"
		; GUI

	--test-- "#2099"
		;-- rebol.com can be down - shouldn't affect tests
		; original2072: read/binary http://www.rebol.com/how-to/graphics/button.gif
		;-- this is just the fragment of the original binary:
		original2072: #{
			47494638396146002600F700000000000E0E0E0F00041700061C1C1C1F00071F
			090F2700092F000B33333336091437000D3E000F3E091641414144383B470011
			4E0013510E1E55001459333C5D00166338426500186F001B712A3B73172D7500
			1C773343786B6E7A09247C4A567F001F81747782052383001F833C4D84465585
			3C4E860E2B87002087616A89253D8982848A0E2B8D00228E17338E747A93384E
			940023949494957D83958B8E96616D976F799A0E2F9A5D6C9E00269E9E9EA005
			2AA48B91A49498A60027A70028A7A2A3A86F7DA87D87A89499AA9EA1AB0029AB
			6A7AACACACAD052DADA2A5B09EA2B0B0B0B3A2A6B3ACAEB47483B4A7AAB5002B
		}
		write/binary qt-tmp-file original2072
		saved2072: read/binary qt-tmp-file
		--assert equal? saved2072 original2072
		unset [original2072 saved2072]

	; --test-- "#2104"
		; console behaviour - #1995

	; --test-- "#2105"
		; infinite loop - how to catch it?

	--test-- "#2108"
		--assert parse "x" [to [end]]

	; --test-- "#2109"
		; console

	--test-- "#2113"
		; FIXME: this won't compile, using `do` as a temporary workaround (see #3634)
		do [
			a: make object! [
				act-state: make object! [
					finish?: false
					fn-callback: none
				]
				start: function[callback][
					a/act-state/fn-callback: :callback
				]
			]
			callback1: function[][bad-value: "xyz"]
			a/start :callback1
		]
		unset 'bad-value
		--assert not value? 'bad-value
	
	; --test-- "#2118"
		; GUI

	--test-- "#2125"
		--assert 2 = length? find reduce [integer! 1] integer!

	; --test-- "#2133"
		; OPEN

	--test-- "#2134"
		--assert "0:09:00" = form 00:09:00
		--assert "0:01:00" = form 00:00:01 * 60
		t2134: 0:00:00 loop 60 [t2134: t2134 + 1]
		--assert "0:01:00" = form t2134
		--assert "0:00:00"        = form 0:00:01 / 10000000
		--assert "0:00:00.000001" = form 0:00:01 / 1000000
		--assert "0:00:00.00001"  = form 0:00:01 / 100000
		--assert "0:00:00.0001"   = form 0:00:01 / 10000
		--assert "0:00:00.001"    = form 0:00:01 / 1000

	--test-- "#2136"
		blk2136: copy []
		insert/dup blk2136 0 3
		insert/dup blk2136 1 2
		--assert equal? blk2136 [1 1 0 0 0]
		unset 'blk2136

	--test-- "#2138"
		b2138: [1 2 3 4 5]
		forall b2138 [i: b2138/1: form b2138/1]
		--assert equal? b2138 ["1" "2" "3" "4" "5"]
		unset [b2138 i]

	--test-- "#2139"
		--assert equal? 1% 1% * 1

	--test-- "#2146"
		test2146: make hash! [a: 10]
		--assert equal? 10 test2146/a
		test2146: make hash! [a: 10 a 20]
		--assert equal? 10 test2146/a
		unset 'test2146

	; --test-- "#2147"
		; GUI

	; --test-- "#2149"
		; GUI

	--test-- "#2152"
		--assert error? try [do load {func [/x x] []}]

	--test-- "#2155"
		--assert error? try [do load {func [h [integer!!]] [h]}]

	--test-- "#2157"
		--assert error? try [-2147483648 / -1]
		--assert error? try [-2147483648 % -1]
		--assert error? try [remainder -2147483648 -1]

	--test-- "#2160"
		--assert not error? try [extract/into/index [1 2 3 4 5 6] 2 b: [] 2]

	; --test-- "#2163"
		; TODO: get some example, description is not good enough

	--test-- "#2166"
		x2166: 2147483648
		--assert not equal? x2166 -2147483648
		--assert equal? x2166 2147483648.0
		unset 'x2166

	; --test-- "#2170"
		; GUI

	--test-- "#2171"
		quote2171: func ['val] [val]
		test2171: none
		unset 'test2171
		--assert error? try [quote2171 ()]
		--assert error? try [quote2171 (test2171)]
		unset 'quote2171

	--test-- "#2173"
		--assert not parse [] [return]
		--assert not parse [] [parse]
		--assert not parse [] ["why"]
		--assert not parse [] [red]
		--assert not parse [] [append]
	;	--assert not parse [] [help] ; help is unset when compiled

	--test-- "#2177"

		--assert not new-line? [foo]
		--assert new-line? [
			foo
		]

	--test-- "#2187"
		--assert error? try [load {64#{aaa }}]

	--test-- "#2195"
		e2195: try [load "system/options/"]
		--assert equal? "system/options/" e2195/arg3
		unset 'e2195

	--test-- "#2196"
		m2196: #()
		repeat k 70 [
			m2196/:k: {x}
			remove/key m2196 k
		]
		--assert empty? keys-of m2196
		unset 'm2196

	--test-- "#2209"
		m2209: #(a 1 b 2)
		remove/key m2209 'a
		--assert equal? #(b: 2) m2209
		unset 'm2209

	; --test-- "#2223"
		; GUI

	--test-- "#2227"
		--assert equal? ["1" ""] split "1^/" #"^/"
		--assert equal? ["1" "2" ""] split "1^/2^/" #"^/"

	--test-- "#2232"
		--assert 'ok = (a: 'ok 1 :a)
		--assert 'ok = (a: 'ok 1 + 1 :a)
		--assert 'ok = (a: 'ok 1 + 1 probe :a)
		--assert equal? 'ok (a: 'ok 1 + 1 :a)
		--assert equal? 'ok (a: 'ok 1 + 1 :a)

		n: func [/a][100]
		res: n - (1 n/a)
		--assert zero? res
		--assert n - (1 n/a) = 0
		--assert (n - (1 n/a)) = 0

		--assert zero? n - (x: 0 n)
		--assert zero? n - (x: 0 n/a)
		--assert zero? n - (x: 123 n/a)
		--assert zero? n - (1 + 2 n/a)
		--assert equal? [100] reduce [(1 + 2 n/a)]

		--assert equal? [3 100] reduce [1 + 2 n/a]
		--assert equal? [100 100 123 3] reduce [(123 n/a) (1 + 2 n/a) (n/a 123) (n/a 1 + 2)]

	--test-- "#2234"
		m2234: #(a 1 b 2)
		remove/key m2234 'a
		--assert not empty? keys-of m2234
		--assert not empty? values-of m2234
		m2234: #(a 1 b 2 c 3 d 4 e 5 f 6 g 7 h 8)
		remove/key m2234 'b
		--assert equal? [a c d e f g h] keys-of m2234
		--assert equal? [1 3 4 5 6 7 8] values-of m2234

	--test-- "#2250"
		--assert equal? [2:00:00] difference [1:00] [2:00 1:00]

	--test-- "#2253"
		--assert not error? try [3151391351465.995 // 1.0]
		unset 'true?

	--test-- "#3385"
		refs3385: [utc precise time year month day yearday weekday zone date]
		types3385: reduce [
		    date!		;21-Nov-2019/18:14:33.1411
		    time!		;18:14:33
		    integer!	;2019
		    integer!	;11
		    integer!	;21
		    integer!	;325
		    integer!	;4
		    time!		;0:00:00
		    date!		;21-Nov-2019
		    time!		;21:14:33.1411
		]    			; rest is none!
		i3385: 1
		forall refs3385 [
			foreach ref3385 next refs3385 [
				path3385: as path! reduce ['now refs3385/1 ref3385]
				--assert types3385/:i3385 = attempt [type? do path3385]
				i3385: i3385 + 1
			]
		]

	--test-- "#3098"
		block: reduce ['foo func [/bar][pick [baz qux] bar]]
		--assert 'qux = do [block/('foo)]				;-- wrapper makes sure that it's not a sub-expression
		--assert 'baz = do [block/('foo)/bar]
		
		block: reduce [block]
		--assert 'qux = do [block/1/('foo)]
		--assert 'baz = do [block/1/('foo)/bar]
	
	--test-- "#3156"
		ctx3156: context [foo3156: does ['bar3156]]
		bar3156: ctx3156/foo3156
		--assert 'bar3156 == bar3156

	--test-- "#2650"
		--assert     0.0 <> null
		--assert not 0.0 =  null
		--assert not 0.0 == null
		--assert not 0.0 =? null
		
		--assert     null <> 0.0
		--assert not null =  0.0
		--assert not null == 0.0
		--assert not null =? 0.0
		
		--assert error? try [65.0  < #"A"]
		--assert error? try [66.0  > #"B"]
		--assert error? try [-1.0 >= #"c"]
		--assert error? try [+1.0 <= #"d"]
		
		--assert error? try [#"A"  > 65.0]
		--assert error? try [#"B"  > 66.0]
		--assert error? try [#"c" <= -1.0]
		--assert error? try [#"d" >= +1.0]

	--test-- "#2431"									;-- FIXME: add `load` tests when it's fixed
		write qt-tmp-file {Red []}
		--assert unset? do qt-tmp-file					;-- should skip the header
		write qt-tmp-file {Red [] Red []}
		--assert [] = do qt-tmp-file					;-- should skip the 1st header only

	--test-- "#2671"
		--assert equal?
			"^(0) ^(1) ^(2) ^(3) ^(4) ^(5) ^(6) ^(7) ^(8) ^(9) ^(A) ^(B) ^(C) ^(D) ^(E) ^(F)"
			"^@ ^A ^B ^C ^D ^E ^F ^G ^H ^- ^/ ^K ^L ^M ^N ^O"
		
		--assert equal?
			"^A ^A ^A ^A ^A ^A"
			"^(1) ^(01) ^(001) ^(0001) ^(00001) ^(000001)"
		
		--assert error? try [transcode {"^^(0000001)"}]
		--assert error? try [transcode {"^^(skibadee-skibadanger)"}]

	--test-- "#3603"
		bu3603: reduce [()]
		rest3603: none
		--assert bu3603 = back change block3603: [] do/next block3603 'rest3603

	--test-- "#3362"
		do [											;-- FIXME: compiler doesn't like this
			spec3362-1: [return 100]
			spec3362-2: [exit]
			--assert 100 =  context spec3362-1
			--assert unset? context spec3362-2
			--assert 100 =  context [return 100]
			--assert unset? context [exit]
			unset [spec3362-1 spec3362-2]
		]
	
	--test-- "3662"
		--assert equal?
			[16  256  4096  65536  1048576 16777216 268435456]
			[10h 100h 1000h 10000h 100000h 1000000h 10000000h]
	
	--test-- "3669"
		--assert not equal? <a> <a^>
		--assert equal?     <a> load {<a^>}

	--test-- "#3588"
		x3588: []
		write qt-tmp-file {Hello Red append x3588 "try"^/Red [] append x3588 "Hoi!"}
		do qt-tmp-file
		--assert x3588 = ["Hoi!"]
		unset 'x3588

	--test-- "#3603"
		bu3603: reduce [()]
		rest3603: none
		--assert bu3603 = back change block3603: [] do/next block3603 'rest3603
		unset [bu3603 rest3603 block3603]

	--test-- "#3407"
		--assert "0:00:00.1"      = form 0:00:01 / 10
		--assert "0:00:00.01"     = form 0:00:01 / 100
		--assert "0:00:00.001"    = form 0:00:01 / 1000
		--assert "0:00:00.0001"   = form 0:00:01 / 10000
		--assert "0:00:00.00001"  = form 0:00:01 / 100000
		--assert "0:00:00.000001" = form 0:00:01 / 1000000
		--assert "0:00:00"        = form 0:00:01 / 10000000

	--test-- "#3603"
		bu3603: reduce [()]
		rest3603: none
		--assert bu3603 = back change block3603: [] do/next block3603 'rest3603

	--test-- "#3561"
		a: reduce ['b does [1 + 2] 'x 'y]
		--assert do [3 = a/b]							;-- do[] else compiler will not eval `does [1 + 2]`
		--assert 3 = do 'a/b
		--assert 3 = do quote a/b
		--assert 'a/b = do quote 'a/b
		--assert 'y = a/x
		--assert 'y = do 'a/x
		--assert 'y = do quote a/x

	--test-- "#3603"
		bu3603: reduce [()]
		rest3603: none
		--assert bu3603 = back change block3603: [] do/next block3603 'rest3603

	--test-- "#3739"
		reactor3739: func [spec] [make deep-reactor! spec]
		s3739: reactor3739 [started: no]
		a3739: reactor3739 [x: none]
		b3739: reactor3739 [x: none y: none]
		success3739: no
		react [
			if s3739/started [
				a3739/x: copy "NEW-VALUE!"
				b3739/y: copy "junk"
			]
		]
		react [ if b3739/x <> a3739/x [ b3739/x: copy a3739/x ] ]
		react [ if all [b3739/x = "NEW-VALUE!" b3739/y = "junk"] [success3739: yes] ]
		s3739/started: yes

		--assert success3739
		unset [s3739 a3739 b3739 success3739 reactor3739]

comment {
	--test-- "#3773"
		;; context? should not accept a string
		--assert error? try [
			do/expand [
				#macro ctx: func [x] [context? x]
				ctx ""
			]
		]
		;; this is reduced like: (mc 'mc) => (mc) => error (no arg)
		--assert error? try [
			do/expand [
				#macro mc: func [x] [x]
				probe quote (mc 'mc)
			]
		]
		;; :mc = func [x][x], so `mc :mc` executing `x` applies it to an empty arg list => error
		--assert error? try [
			do/expand [
				#macro mc: func [x] [x]
				probe quote (mc :mc)
			]
		]
}

	--test-- "#4056"
		i4056: either unset? :image! [[1 2]][make image! 2x2]
		--assert tail? tail i4056
		--assert tail? next next next tail i4056
		--assert not tail? i4056
		--assert tail? next next next next i4056
		--assert tail? next back next tail i4056

	--test-- "#4205 - seed random with precise time!"
		anded4205: to integer! #{FFFFFFFF}
		loop 10 [
			random/seed now/time/precise
			anded4205: anded4205 and last-random4205: random 10000
			wait 0.001
		]
		all-equal?4205: anded4205 = last-random4205
		--assert not all-equal?4205
		unset [anded4205 last-random4205 all-equal?4205]
	
	--test-- "#4451"
		path: quote :foo/bar
		--assert ":foo/bar" = mold path
		--assert get-path! = type? path
		--assert word! = type? path/1
	
	--test-- "#4305"
		block: reduce ['foo func [/bar][pick [baz qux] bar]]
		id:    func [value][value]
		--assert 'qux == block/('foo)
		--assert 'qux == id block/('foo)
		--assert 'qux == bar: block/('foo)
		--assert 'qux == bar
		
		block: reduce [block]
		--assert 'baz == block/1/('foo)/bar
		--assert 'baz == id block/1/('foo)/bar
		--assert 'baz == baz: block/1/('foo)/bar
		--assert 'baz == baz
		
	--test-- "#4505"
		do [
			saved: :find
			find find: [1000] 1000
			--assert find = [1000]
			find: :saved

		  	test: func [a b] [append a b]
		  	test test: [10 20 30] 40
		  	--assert true 			;-- just check it does not crash

			recycle/off
			b: reduce [o: object []]
			s0: stats
			loop 1000000 [pick b 1]
			--assert stats < (s0 * 2)  ;-- catches memory leaking
			recycle/on
			recycle
		]
	
	--test-- "#4517"
		foo: has [block][
			block: [:get/path]
			--assert get-path? block/1
			--assert word? block/1/1
			--assert "[:get/path]" == mold block
		]

		foo
		unset 'foo
	
	--test-- "#4522"
		--assert error? try [find/skip [1] [1] ()]
	
	--test-- "#4537"
		local: "global"
		--assert "global" == get to word! first spec-of has [foo][]
		--assert "global" == get to word! first spec-of function [][[foo:]]
		unset 'local
		
		--assert equal?
			system/words
			context? to word! to issue! in context [foo: 'bar] 'foo
		
		--assert equal?
			system/words
			context? to word! to refinement! in context [foo: 'bar] 'foo
	
	--test-- "#4563" do [							;@@ #4526
		--assert error? try [make op! :>>]
		--assert error? try [make op! make op! func [x y][]]
	]
	
	--test-- "#4567"
		objects: [foo]
		--assert 'foo == objects/1
		unset 'objects

	--test-- "#4609"
		--assert "[2.3.4.5.6 1.2.3.4.5.6]" = mold [2.3.4.5.6 1.2.3.4.5.6]
		--assert "2.3.4.5.6" = mold 2.3.4.5.6
		--assert "1.2.3.4.5.6" = mold 1.2.3.4.5.6

	--test-- "#4627"
		--assert to logic! find
			form try [transcode "]"]
			"(line 1) missing [ at ]"
		
		--assert to logic! find
			form try [null < []]
			%{#"^@" with []}%

	--test-- "4756"
			load/as #{
52454442494E0204010000006C00000002000000100000000000000008000000
75726C0000000000646174650000000028000000020000000801000000000000
0500000061622F63640000002800000004000000100000020000000090010000
090100000000000012000000687474703A2F2F6578616D706C652E6F72670000
1000000201000000830100002F00000080201D0FC0EFD14000000000
} 'redbin

	--test-- "#4766"
		saved-dir: what-dir
		change-dir qt-tmp-dir
		make-dir %tmp$
		files: []
		blk4766: []
		repeat i 20 [
			append files f4766: rejoin [%tmp$/drw i ".red"]
			write/binary f4766 append/dup copy {^/} "11 ^/^/" i
		]
		attempt [foreach f4766 files [blk4766: read/lines f4766]]
		change-dir saved-dir
		--assert 41 = length? blk4766

	--test-- "#4768"
		--assert block? body-of :is

	--test-- "#4799"
		--assert not equal? "foo" #{666F6F}
		--assert not equal? #{666F6F} "foo"
		--assert not strict-equal? "foo" #{666F6F}
		--assert not strict-equal? #{666F6F} "foo"

===end-group===

~~~end-file~~~
