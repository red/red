Red [
	Title:   "Red bugs tests"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test1992.red
	Tabs:	 4
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Needs:	 'View
	ToDo:	 "Cleanup temporary files"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "bugs"

===start-group=== "regression"

	; --test-- "#5"

	; --test-- "#28"

	; --test-- "#32"

	; --test-- "#55"

	; --test-- "#59"

	; --test-- "#63"

	; --test-- "#65"

	; --test-- "#71"

	; --test-- "#76"

	; --test-- "#88"

	; --test-- "#89"

	; --test-- "#114"

	; --test-- "#117"

	; --test-- "#121"

	; --test-- "#122"

	; --test-- "#123"

	; --test-- "#125"

	; --test-- "#131"

	; --test-- "#134"

	; --test-- "#136"

	; --test-- "#137"

	; --test-- "#138"

	; --test-- "#139"

	; --test-- "#146"

	; --test-- "#148"

	; --test-- "#149"

	; --test-- "#150"

	; --test-- "#151"

	; --test-- "#153"

	; --test-- "#154"

	; --test-- "#157"

	; --test-- "#158"

	; --test-- "#159"

	; --test-- "#160"

	; --test-- "#161"

	; --test-- "#162"

	; --test-- "#164"

	; --test-- "#165"

	; --test-- "#167"

	; --test-- "#168"

	; --test-- "#169"

	; --test-- "#170"

	; --test-- "#171"

	; --test-- "#172"

	; --test-- "#173"

	; --test-- "#174"

	; --test-- "#175"

	; --test-- "#178"

	; --test-- "#188"

	; --test-- "#198"

	; --test-- "#200"
		; quick-test bug

	; --test-- "#204"
		; no code

	; --test-- "#205"
		; R/S

	; --test-- "#207"
		; R/S

	; --test-- "#208"
		; R/S

	; --test-- "#209"
		; R/S

	; --test-- "#210"
		; R/S

	; --test-- "#212"
		; R/S

	; --test-- "#216"
		; R/S

	; --test-- "#217"
		; R/S

	; --test-- "#220"
		; R/S

	; --test-- "#221"
		; R/S

	; --test-- "#222"
		; R/S

	; --test-- "#223"
		; R/S

	; --test-- "#224"
		; R/S

	; --test-- "#225"
		; R/S

	; --test-- "#226"
		; R/S

	; --test-- "#227"
		; R/S

	; --test-- "#228"
		; R/S

	; --test-- "#229"
		; R/S

	; --test-- "#231"
		; R/S

	; --test-- "#233"
		; R/S

	; --test-- "#234"
		; R/S

	; --test-- "#235"
		; R/S

	; --test-- "#236"
		; R/S

	; --test-- "#238"
		; R/S

	; --test-- "#239"
		; R/S

	; --test-- "#241"
		; R/S

	; --test-- "#243"
		; R/S

	; --test-- "#244"
		; R/S

	; --test-- "#245"
		; R/S

	; --test-- "#250"
		; R/S

	; --test-- "#253"
		; R/S

	; --test-- "#254"
		; R/S

	; --test-- "#257"
		; R/S

	; --test-- "#258"
		; R/S

	; --test-- "#261"
		; R/S

	--test-- "#262"
		--assert not error? try [#"^(00)"]

	; --test-- "#263"
		; R/S

	; --test-- "#265"
		; R/S

	; --test-- "#269"
		; R/S

	; --test-- "#272"
		; R/S

	; --test-- "#273"
		; R/S

	; --test-- "#274"
		; should check for print output

	; --test-- "#275"
		; R/S

	; --test-- "#276"
		; R/S

	; --test-- "#278"
		; R/S

	; --test-- "#279"
		; R/S

	; --test-- "#281"
		; R/S

	; --test-- "#282"
		; R/S

	; --test-- "#284"
		; R/S

	; --test-- "#285"
		; R/S

	; --test-- "#288"
		; R/S

	; --test-- "#289"
		; R/S

	; --test-- "#290"
		; R/S

	; --test-- "#291"
		; R/S

	--test-- "#292"
		--assert error? try [load {#"""}]

	; --test-- "#293"
		; R/S

	; --test-- "#298"
		; R/S

	; --test-- "#300"
		; R/S

	; --test-- "#304"
		; TODO

	--test-- "#306"
		s: mold []
		--assert equal? #"[" s/1

	--test-- "#308"
		bar: func [] [foo]
		foo: func [] [42]
		--assert not error? try [bar]
		unset [foo bar]

	--test-- "#310"
		--assert equal? "good" either true ["good"] ["bad"]
		--assert equal? "good" either false ["bad"] ["good"]
		--assert equal? "good" either 42 ["good"] ["bad"]

	; --test-- "#312"
		; should check for compilation error

	; --test-- "#313"
		; TODO

	; --test-- "#316"
		; R/S

	; --test-- "#317"
		; R/S

	--test-- "#321"
		--assert none? probe if false [1]
		--assert error? probe try [1 + if false [2]]

	; --test-- "#323"
		; should check for compilation error

	; --test-- "#324"
		; NOTE: seems to be buggy still

	--test-- "#326"
		; should check for compilation error
		--assert not error? try [func[:a [integer!]] []]

	; --test-- "#328"
		; should check for compilation error

	; --test-- "#330"
		; TODO
		; not sure what is the buggy behaviour, there’s no example

	--test-- "#331"
		foo: func [] ["ERR"]
		foo: func [] ["ok"]
		--assert equal? "ok" foo

	; --test-- "#332"
		; should check for compilation error
		; (return and exit outside of function)

	; --test-- "#334"
		; R/S

	; --test-- "#338"
		; R/S

	; --test-- "#340"
		; R/S

	; --test-- "#342"
		; TODO

	; --test-- "#344"
		; R/S

	--test-- "#345"
		spec: spec-of :set
		--assert (index? find spec 'value) < ((index? find spec /any))

	; --test-- "#346"
		; R/S

	; --test-- "#347"
		; should check for compilation error

	; --test-- "#348"
		; R/S

	; --test-- "#355"
		; should check for crash

	--test-- "#356"
		--assert not error? try [if true []]

	; --test-- "#357"
		; TODO

	; --test-- "#358"
		; should check for crash

	; --test-- "#360"
		; should check for compilation error

	; --test-- "#362"
		; should check for compilation error

	; --test-- "#363"
		; should check for compilation error

	; --test-- "#364"
		; TODO: #include problem

	; --test-- "#366"
		; TODO: compilation problem with dir paths

	; --test-- "#367"
		; should check for compilation error

	; --test-- "#369"
		; should check for compilation error

	; --test-- "#370"
		; should check for compilation error

	; --test-- "#372"
		; should check for compilation error

	; --test-- "#373"
		; should check for compilation error

	; --test-- "#374"
		; should check for compilation error

	; --test-- "#376"
		; should check for compilation error

	; --test-- "#377"
		; should check for compilation error

	; --test-- "#379"
		; R/S

	; --test-- "#381"
		; R/S

	; --test-- "#383"
		; should check for print output

	; --test-- "#384"
		; TODO

	; --test-- "#385"
		; TODO

	--test-- "#386"
		; should check for crash
		--assert equal? [3 3 2 1] find/reverse tail [1 2 3 3 2 1] [3 3]


	--test-- "#388"
		--assert equal? word! type? 'a

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

	; --test-- "#391"
		; should check for compilation error

	; --test-- "#392"
		; should check for compilation error

	; --test-- "#393"
		; R/S

	; --test-- "#394"
		; should check for print output

	--test-- "#395"
		--assert switch 'yes [yes [true]]

	; --test-- "#396"
		; should check for compilation error

	--test-- "#397"
		--assert not error? try [do [append [] 1]]

	; --test-- "#398"
		; should check for compilation error

	--test-- "#399"
		x: 1

		f: function [
		][
			x: 2
			b: [x]
			do b
		]
		--assert equal? 2 f

	; --test-- "#400"
		; should check for print output

	--test-- "#401"
		y: none ; prevent " undefined word y" compiler error
		set 'x 'y
		set x 1
		--assert equal? 1 y
		do [set x 1]
		--assert equal? 1 y
		unset [x y]

	; --test-- "#402"
		; should check for compilation error

	--test-- "#403"
		f: func [
			a       [block!]
			return: [block!]
			/local  b x
		][
			b: copy []

			either block? x: a/1 [
				append/only b  f x
			][
				append b x
			]
			b
		]
		--assert equal? [1] f [1]
		--assert equal? [[2]] f [[2]]
		--assert equal? [[[3]]] f [[[3]]]
		unset 'f

	--test-- "#404"
		x: 'y
		y: 1
		--assert equal? 'y x
		--assert equal? 'y get 'x
		--assert equal? 1 get x
		--assert equal? 1 do [get x]

	; --test-- "#405"
		; should check for compilation error

	; --test-- "#406"
		; should check for compilation error

	--test-- "#407"
		; should check for crash
		f: func [
			/local x
		] [
			x: 'y
			set x 1
		]
		f
		--assert equal? 1 y
		unset [f y]

	--test-- "#409"
		g: func [
			b [block!]
		] [
			reduce [b do b]
		]
		f: func [
			"!"
			x
			/r
		] [
			g [x]
		]
		--assert equal? [[x] "!"] f "!"

	; --test-- "#411"
		; R/S

	; --test-- "#412"
		; should check for crash

	; --test-- "#413"
		; should check compilation time

	; --test-- "#414"
		; should check for print output

	; --test-- "#415"
		; should check for compiler error

	--test-- "#416"
		b: [none]
		f: func [p q] [
			reduce [p q]
		]
		--assert equal? [1 none] do [f 1 b/1]
		unset [b f]

	; --test-- "#417"
		; R/S

	; --test-- "#418"
		; see #420

	; --test-- "#419"
		; R/S

	--test-- "#420"
		; should check for crash
		--assert not error? try [
			f: function [
			] [
				g: func [
				] [
				]
			]
			f
		]

	--test-- "#422"
		--assert not error? try [function [n [integer!]] []]

	--test-- "#423"
		; should check for crash
		--assert error? try [
			load s: {
    x/
}
		]
		unset 's

	--test-- "#424"
		--assert empty? load ";2"

	--test-- "#425"
		--assert not error? try [func [return: [integer!]] []]

	; --test-- "#426"
		; compiler behaviour

	--test-- "#427"
		out: copy ""
		f: func [
			/local count
		] [
			repeat count 5 [
				append out count
			]
		]
		f
		--assert equal? "12345" out
		unset 'out

	; --test-- "#428"
		; should check for crash

	--test-- "#429"
		--assert equal? {#"^^-"} mold tab

	--test-- "#430"
		--assert equal? "  x" form ["" [] x]
		--assert equal? " a  a " form [[""] [a] [] [a] [[[]]]]

	; --test-- "#431"
		; should check for print output

	; --test-- "#432"
		; TODO

	; --test-- "#435"
		; should check for compilation error

	; --test-- "#437"
		; should check for print output

	--test-- "#443"
		f: function [] [out: copy [] foreach [i j] [1 2 3 4] [append out i] out]
		--assert equal? [1 3] f
		--assert equal? [/local out i j] spec-of :f
		--assert error? try [do [i]]
		--assert error? try [do [j]]
		unset [f out]

	--test-- "#449"
		s: copy ""
		--assert equal? "1111111111" append/dup s #"1" 10
		--assert equal? "1111111111" s
		--assert equal? 10 length? s
		unset 's

	; --test-- "#453"
		; should check for compilation error

	--test-- "#455"
		types: copy [] 
		foreach word words-of system/words [
			all [
				value? word 
				append types type? get word
			]
		]
		--assert 1 < length? unique types
		unset 'types

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

	; --test-- "#460"
		; should check for crash

	; --test-- "#461"
		; should check for crash
print 465
	--test-- "#465"
		s: make string! 0
		append s #"B"
		--assert equal? "B" s
		append s #"C"
		--assert equal? "BC" s
		append s #"D"
		--assert equal? "BCD" s

	; --test-- "#468"
		; R/S

	; --test-- "#473"
		; R/S

	; --test-- "#474"
		; R/S

	; --test-- "#475"
		; R/S

	; --test-- "#481"
		; R/S

	; --test-- "#482"
		; should check for print output

	; --test-- "#483"
		; R/S

	; --test-- "#484"
		; R/S
print 486
	--test-- "#486"
		; should check for print output
		b: [x]
		print b/1

	; --test-- "#488"
		; Rebol GC bug (probably, TODO)

	--test-- "#490"
		--assert equal? "" insert "" #"!"
		--assert equal? "" insert "" "!"

	--test-- "#491"
		--assert equal? 2 load next "1 2"

	--test-- "#492"
		; should check for compiler error
		flexfun-s: function [
			s [string!] 
			return: [string!]
		] [
			return s
		]
		flexfun-i: function [
			i [integer!] 
			return: [integer!] 
		] [
			return i
		]
		flexfun: function [
			n [integer! float! string!] 
			return: [string! integer! logic!] 
			/local rv
		] [
			rv: type? n
			either "string" = rv [uitstr: flexfun-s n] [uitint: flexfun-i n]
		]
		unset [flexfun flexfun-i flexfun-s uitint uitstr]

	; --test-- "#493"
		; R/S

	; --test-- "#494"
		; TODO: example throws strang compiler error

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

	; --test-- "#506"
		; compiler error

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
		b: [x 0]
		i: 'x
		b/:i: 1
		--assert equal? [x 1] b
		unset 'b

	--test-- "#512"
		x: 0
		--assert zero? case [yes x]
		unset 'x

	--test-- "#513"
		--assert equal? {#"^^^^"} mold #"^^"

	--test-- "#514"
		--assert equal? 1 length? "^^"
		--assert equal? {"^^^^"} mold "^^"

	; --test-- "#515"
		; no example

	; --test-- "#518"
		; R/S

	; --test-- "#519"
		; should check print output

	--test-- "#520"
		--assert not not probe all []

	--test-- "#522"
		--assert not error? try [{{x}}]

;	--test-- "#523"
;		--assert unset? load ":x"

	--test-- "#524"
		s: "^(1234)B"
		--assert equal? "B" find s "B"
		--assert equal? "B" find s next "AB"
		unset 's

	--test-- "#525"
		--assert not error? try [load {^/}]
		--assert not error? try [load {{^/}}]

	; --test-- "#526"
		; R/S

	; --test-- "#528"
		; R/S

	; --test-- "#530"
		; should check for print output

	; --test-- "#531"
		; should check for compiler error

	; --test-- "#532"
		; R/S

	; --test-- "#533"
		; R/S

	; --test-- "#535"
		; R/S

	; --test-- "#537"
		; should check for compiler error

	; --test-- "#538"
		; should check for compiler error

	; --test-- "#539"
		; should check for compiler error

	; --test-- "#540"
		; should check for compiler error

	; --test-- "#541"
		; compiler problem

	; --test-- "#542"
		; precompiled library problem

	; --test-- "#545"
		; broken library

	; --test-- "#547"
		; broken release

	; --test-- "#548"
		; R/S

	; --test-- "#552"
		; R/S

	--test-- "#553"
		; should check for crash
		b: 23
		probe quote b
		probe quote :b
		unset 'b

	; --test-- "#554"
		; R/S

	; --test-- "#555"
		; R/S

	--test-- "#558"
		o: copy ""
		foreach x 'a/b/c [append o x]
		--assert equal? o "abc"
		o: copy ""
		foreach x quote (i + 1) [append o x]
		--assert equal? o "i+1"
		unset 'o

	--test-- "#559"
		--assert equal? load "x/y:" quote x/y:
		--assert equal? load "x:" quote x:

	--test-- "#560"
		fx: function [
			value
			out	[string!]
		][
			either block? value [
				string: copy ""

				foreach x value [
					fx x tail string
				]
				insert insert insert out  0 string #"]"
				out
			][
				insert insert insert insert out  1 #":" value #","
				out
			]
		]

		fx [a [b c d]]
		s: ""
		--assert equal? "01:a,01:b,1:c,1:d,]]" s
		unset [fx s]


	--test-- "#562"
		--assert not parse "+" [any [#"+" if (no)]]

	--test-- "#563"
		; should check for print output
		r: [#"+" if (probe fx "-")]
		fx: func [
			t [string!]
		][
			parse t [any r]
		]
		--assert not fx "-"
		--assert not fx "+"
		unset [fx r]


	; --test-- "#564"
		; should check for crash

	; --test-- "#565"
		; should check for crash

	--test-- "#569"
		size: 1
		--assert equal? ["1"] parse "1" [collect [keep copy value size skip]]
		size: 2
		--assert equal? ["12"] parse "12" [collect [keep copy value size skip]]
		unset 'size

	--test-- "#570"
		--assert not strict-equal? 'a 'A
		--assert not strict-equal? 'test 'Test

	--test-- "#572"
		sp: func [x y] [return parse "aa" [collect [keep skip]]]
		--assert equal? [#"a"] sp "q" "w"
		sp: func [x y] [parse "aa" [collect [keep skip]]]
		--assert equal? [#"a"] sp "q" "w"
		unset 'sp

	--test-- "#573"
		--assert error? try [load "{"]

	; --test-- "#574"
		; should check for crash

	--test-- "#581"
		--assert not error? try [do "S: 1 S"]

	; --test-- "#584"
		; console behaviour

	--test-- "#586"
		t: reduce [block!]
		--assert equal? reduce [block!] find t block!
		--assert equal? reduce [block!] find t type? []
		unset 't

	; --test-- "#587"
		; should check for crash

	; --test-- "#589"
		; must be separate file

	--test-- "#592"
		--assert file? %x
		--assert file? copy %x

	--test-- "#593"
		--assert equal? [#"1"] parse "12" [collect [keep skip]]
		--assert equal? ["1"] parse "12" [collect [keep copy x skip]]
		--assert equal? [#"1"] parse "12" [collect [keep skip]]

	; --test-- "#594"
		; should check for print output

	--test-- "#596"
		list: ""
		parse "a" [collect into list some [keep skip]]
		--assert equal? "a" head list
		unset 'list

	--test-- "#598"
		--assert equal? [""] parse "" [collect [(s: "") collect into s [] keep (s)]]
		--assert equal? [[]] parse [] [collect [(b: []) collect into b [] keep (b)]]
		unset [b s]

	--test-- "#599"
		--assert equal? "<?>" form ["<?>"]
		--assert equal? "<?>" append "" ["<?>"]
		--assert equal? "<?>" head insert "" ["<?>"]

	--test-- "#601"
		b: [] parse "!" [collect into b [keep 0 skip]]
		--assert empty? head b
		unset 'b

	--test-- "#604"
		--assert equal? "_" form "_"
		--assert equal? "_" form #"_"

	--test-- "#605"
		--assert none? length? none
		--assert error? try [1 + none] ; #621

	; --test-- "#606"
		; must be separate file

	; --test-- "#608"
		; must be separate file

	; --test-- "#609"
		; console behaviour

	--test-- "#616"
		; NOTE: 'f must be function (as defined elswhere in this tests), 
		; 		otherwise tests can’t be compiled, so we use 'fis here instead
		;		same with g->gis
		e: copy ""
		fis: [b_c c_d]
		append e fis
		--assert equal? "b_cc_d" e
		a: copy ""
		c: [glp_set_prob_name glp_get_prob_name]
		append a c
		--assert equal? "glp_set_prob_nameglp_get_prob_name" a
		b: copy ""
		d: load "glp_set_prob_name glp_get_prob_name"
		append b d
		--assert equal? "glp_set_prob_nameglp_get_prob_name" b
		gis: copy ""
		h: [bc cd]
		append gis h
		--assert equal? "bccd" gis
		unset [a b c d e fis gis h]

	; --test-- "#620"
		; should check for print output

	--test-- "#625"
		--assert equal? #"^(1F)" first "^(1f)"

	; --test-- "#626"
		; see #637

	--test-- "#628"
		--assert equal? "make objec" mold/part context [a: "1" b: "2"] 10

	; --test-- "#630"
		; should check for crash
		; st1: "<id"
		; delimiter: charset "<"
		; rule: [ some [delimiter | copy c skip ] ]
		; print parse-trace st1 rule


	; --test-- "#633"
		; should check for compiler error
		not error? try [#"^(back)"]

	; --test-- "#634"
		; should check for crash

	; --test-- "#637"
		; TODO: syntax error in compiler

	; --test-- "#644"
		; TODO: how to check for hangup?

	--test-- "#645"
		not error? try [
			comment [
				1 + 1
			]
		]

	--test-- "#646"
		--assert not error? try [foreach x [] []]

	--test-- "#647"
		--assert error? try [load "type? quote '1" ]

	; --test-- "#650"
		; NOTE still a bug, crashes test
	;	f: func [/1]
	;	probe f/1

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

	; --test-- "#659"
		; should check for crash

	; --test-- "#660"
		; console building problem

	; --test-- "#667"
		; should check for crash

	; --test-- "#669"
		; TODO: compiler issue

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
		letter: charset "ABCDEF"
		--assert parse "FFh" [2 8 letter #"h"]

	--test-- "#702"
		--assert not error? try [
			command: [
				if-defined | if-not-defined | define | function | comment
			]
		]
		unset 'command

	; --test-- "#704"
		; console behaviour

	; --test-- "#706"
		; console behaviour

	--test-- "#710"
		; FIXME: not sure if both test should work or both should throw an error.
		;		first tests works with 061, while second does not
		--assert probe equal? 
			1.373691897708523e131
			probe do load "27847278432473892748932789483290483789743824832478237843927849327492 * 4932948478392784372894783927403290437147389024920147892940729142"
;		--assert not error? try [74789 * 849032]

	--test-- "#714"
		a: load/all "a"
		b: load/all "b"
		--assert equal? [a] a
		--assert equal? [b] b

	--test-- "#715"
		; FIXME: interpreter and compiler give different results: ...^^2 for compiler, ...2 for interpreter
		--assert equal? "blahblah^^2" probe append "blah" "blah^2"

	; --test-- "#716"
		; platfor specific compilation problem

	; --test-- "#720"
		; console compilation problem

	; --test-- "#725"
		; should check for print output

	; --test-- "#726"
		; should check for print output

	--test-- "#727"
		x: 0
		rule: [(x: 1)]
		parse "a" [collect rule]
		--assert equal? 1 x
		unset 'x

	; --test-- "#740"
		; should check for print output

	; --test-- "#745"
		; should check for print output

	; --test-- "#748"
		; should check for print output
;		txt: "Hello world"
;		parse txt [ while any [ remove "l" | skip ] ]
;		print txt

	; --test-- "#751"
		; R/S

	--test-- "#757"
		--assert not error? try [x: "^(FF)"]
		unset 'x

	--test-- "#764"
		; NOTE: some test cannot be compiled, because compiler refuses them
		f: function[][os: 1] 
		--assert equal? 1 probe f
		f: function[][os: 1 os]
		--assert equal? 1 probe f
		f: function[os][os] 
		--assert equal? 1 probe f 1
		f:func[][os: 1] 
		--assert equal? 1 probe f
		f: func[][os: 1 os] 
		--assert equal? 1 probe f
		f: func[os][os] 
		--assert equal? 1 probe f 1
		f: has [os][os: 1] 
		--assert equal? 1 probe f
;		--assert error? try [equal? 1 os]
		f: has [os][os: 1 os] 
		--assert equal? 1 probe f
;		--assert error? try [equal? 1 os]
		f: does [os: 1] 
		--assert equal? 1 probe f
		f: does [os: 1 os] 
		--assert equal? 1 probe f
		unset [f os]

	; --test-- "#765"
		; TODO

	--test-- "#770"
		f: function [][
			blk: [1 2 3 4 5]
			foreach i blk [
				case [
					i > 1 [return i]
				]
			]
		]
		g: function [][if f [return 1]]
		--assert equal? 1 g
		f: function [][
			case [
				2 > 1 [return true]
			]
		]
		g: function [][if f [return 1]]
		--assert equal? 1 g
		f: function [][if true [return true]]
		g: function [][if f [return 1]]
		--assert equal? 1 g
		g: function [][if true [return 1]]
		--assert equal? 1 g
		f: function [][true ]
		g: function [][if f [return 1]]
		--assert equal? 1 g
		f: function [][if true [return true]]
		g: function [][if (f) [return 1]]
		--assert equal? 1 g
		f: function [][if true [return true]]
		g: function [][if not not f [return 1]]
		--assert equal? 1 g
		f: function [][if true [return 'X]]
		g: function [][if f [return 1]]
		--assert equal? 1 g
		unset [f g]

	; --test-- "#776"
		; console behaviour

	--test-- "#778"
		; should check for crash
		f: function[][ return 1 ]
		t: (f)
		--assert not error? try [f]
		--assert not error? try [t: f]

	--test-- "#785"
		nd: charset [not #"0" - #"9"]
		zero: charset #"0"
		nd-zero: union nd zero
		--assert not find nd #"0"
		--assert not find nd #"1"
		--assert find nd #"B"
		--assert find nd #"}"
		--assert find zero #"0"
		--assert not find zero #"1"
		--assert not find zero #"B"
		--assert not find zero #"}"
		--assert find nd-zero #"0"
		--assert not find nd-zero #"1"
		--assert find nd-zero #"B"
		--assert find nd-zero #"}"
		unset [nd zero nd-zero]

	--test-- "#787"
		--assert equal? ["a"] head reduce/into "a" []
		--assert equal? ["a"] head compose/into "a" []

	--test-- "#789"
		--assert not error? try [load "-2147483648"]

	--test-- "#791"
		blk: [2 #[none] 64 #[none]]
		result: copy []
		parse blk [
			collect into result [
				any [
					set s integer! keep (s) | skip
				]
			]
		]
		--assert equal? [2 64] result
		--assert not tail? result
		--assert equal? [2 64] head result
		unset [blk result]

	; --test-- "#796"
		; console behaviour

	; --test-- "#800"
		; console behaviour (ask)

	; --test-- "#806"
		; precompiled console problem

	; --test-- "#810"
		; R/S

	; --test-- "#817"
		; TODO: need more info

	; --test-- "#818"
		; TODO: need more info

	--test-- "#820"
	; should check for print output
	; also see #430
		print [1 2 3]
		print [1 space 3]
		print [1 space space 3]

	--test-- "#825"
		the-text: "outside"
		the-fun: function [] [the-text: "Hello, World!" print the-text]
		--assert equal? spec-of :the-fun [/local the-text]
		the-fun: func [] [the-text: "Hello, World!" print the-text]
		--assert equal? spec-of :the-fun []
		the-fun: function [/extern the-text] [the-text: "Hello, World!" print the-text]
		--assert equal? spec-of :the-fun []
		the-fun: func [/local the-text] [the-text: "Hello, World!" print the-text]
		--assert equal? spec-of :the-fun [/local the-text]
		the-fun: func [extern the-text] [the-text: "Hello, World!" print the-text]
		--assert equal? spec-of :the-fun [extern the-text]
		the-fun: func [local the-text] [the-text: "Hello, World!" print the-text]
		--assert equal? spec-of :the-fun [local the-text]
		unset [the-text the-fun]

	--test-- "#829"
		; should check print output
		print "a^@b"

	; --test-- "#831"
	; 	FIXIME: not fixed yet, crashes compiler
	; 	f: function [][1]
	; 	f: function [][1]

	; 	f: 100
	; 	--assert not equal? f 100

	--test-- "#832"
		; should check for print output
		r: routine [
			/local expected [c-string!]
		][
			expected: {^(F0)^(9D)^(84)^(A2)}
			print [length? expected lf]
		]
		r
		unset 'r

	--test-- "#837"
		; should check for crash
		s: "123"
		--assert error? try [load {s/"1"}]

	--test-- "#839"
		; should check for crash
		--assert not error? try [take/part "as" 4]

	--test-- "#847"
		; should check for print output
		foo-test: routine [
			/local inf nan
		][
			inf: 1e308 + 1e308
			nan: 0.0 * inf
			print-line inf
			print-line nan
			print-line ["inf > nan: " inf > nan]
			print-line ["inf < nan: " inf < nan]
			print-line ["inf <> nan: " inf <> nan]
			print-line ["inf = nan: " inf = nan]
		]
		foo-test

	--test-- "#849"
		--assert equal? 1.2 1.2
		--assert equal? "ščř" "ščř"
		--assert equal? 1.2 1.2
		--assert equal? -1.0203 -1.0203

	--test-- "#853"
	the-text: "outside"
	the-fun: function [
		/extern the-text
	] [
		the-text: "Hello, World!"  
		the-text
	]
	--assert equal? the-fun "Hello, World!"
	--assert equal? the-text "Hello, World!"
	unset [the-text the-fun]

	--test-- "#854"
		f1: function [/r1 v1 v2 /r2 v3][
			out: copy {}
			either r1 [
				append out reduce [v1 v2]
			][
				append out "We're not v1 or v2."
			]
			either r2 [append out v3][append out "I'm not v3."]
			out
		]
		--assert equal? f1 "We're not v1 or v2.I'm not v3."
		--assert equal?
			f1/r1 "I'm v1!" "I'm v2!"
			"I'm v1!I'm v2!I'm not v3."
		--assert equal? 
			f1/r1/r2 "I'm v1!" "I'm v2!" "I'm v3!"
			"I'm v1!I'm v2!I'm v3!"
		--assert equal? 
			f1/r2/r1 "I'm v3!" "I'm v1!" "I'm v2!"
			"I'm v1!I'm v2!I'm v3!"
		unset 'f1

	--test-- "#856"
		--assert equal? [a bčř 10] load "a bčř 10"

	; --test-- "#858"
		; R/S

	; --test-- "#861"
		; R/S, system specific

	--test-- "#869"
		--assert not error? try [load {[1 2.3]}]

	--test-- "#871"
		--assert word? first first [:a/b]

	--test-- "#873"
		parse s: "" [insert (#0)]
		--assert equal? "0" head s
		unset 's

	--test-- "#876"
		--assert error? try [
			foreach w words-of system/words [
				if w = 'xx [
					print [w tab type? get w]
				]
			]
		]

	; --test-- "#877"
		; needs to check print output
		; #system [
		; 	print-line ["In Red/System 1.23 = " 1.23]
		; ]

		; print ["In Red 1.23 =" 1.23]

	; --test-- "#880"
		; R/S, system specific

	; --test-- "#884"
		; TODO: case-sensitivity in header -- needs tests in separate files

	; --test-- "#893"
		; console precompilation problem

	--test-- "#899"
		--assert error? try [load {p: [a/b:/c]}]

	--test-- "#902"
		; should check for crash
		--assert not error? try [
			parse http://rebol.info/foo [
				"http" opt "s" "://rebol.info" to end
			]
		]

	--test-- "#913"
		person: make object! [
			name: none
			new: func [ n ][
				make self [
					name: n
				]
			]
		]

		Bob: person/new "Bob"
		--assert equal? "Bob" Bob/name
		unset [person Bob]

	; --test-- "#916"
	; 	; should check for compiler error
	; 	--assert error? try [round/x 1]
	; 	--assert error? try [append/y [] 2]

	--test-- "#917"
		; should check for crash
		--assert not error? try [o: context [a: b: none]]

	--test-- "#918"
		; should check for compiler error
		f: func [o [object!]] [
			o/a: 1
		]
		o: object [a: 0]
		unset [f o]

	--test-- "#919"
		o: context [
			a: 0
			set 'f does [a: 1]
		]
		equal? f object [a: 1]
		unset 'o

	--test-- "#920"
		f: func [o [object!]] [
			o/a: 1
		]
		--assert equal? 1 f object [a: 0]
		o: object [a: 0]
		--assert equal? 1 f o
		unset [f o]

	--test-- "#923"
		; should check print output
		c: context [
			a: none
			?? a

			f: does [
				?? a
				print a
				print [a]
			]
		]
		c/f
		unset 'c

	--test-- "#927"
		f: does [
			object [
				a: 1
				g: does [a]
			]
		]

		--assert object? obj: f
		--assert function? obj/g

		obj: object [
			a: 1
			f: does [a]
		]
		--assert equal? 1 obj/a
		--assert equal? 1 obj/f
		unset [f obj]

	--test-- "#928"
		o: object [
			a: 1

			c: context [
				b: 2

				f: does [a]
			]
		]
		--assert not error? try [o/c/f]
		--assert equal? 1 o/c/f
		unset 'o

	--test-- "#929"
		out: copy ""
		c: context [
			f: does [
				append out "*"
			]
			g: does [
				do [f]
				append out "!"
				f
			]
		]
		--assert equal? "*!*" c/g
		unset [out c]

	--test-- "#930"
		; should check for compiler crash
		c: context [
			f: function [
				/extern x
				/local y
			][
				x: 1
				set 'y 2
			]
		]
		unset 'c

	--test-- "#931"
		p1: context [
			a: 1
			f: does [a]
		]

		p2: context [
			a: 2
		]

		ch: make p1 p2
		--assert equal? 2 ch/f
		unset [p1 p2 ch]

	--test-- "#932"
		p1: context [
			a: 1
			f: does [a]
		]
		p2: context [
			a: 2
			f: does [100]
		]
		ch: make p1 p2
		--assert equal? 100 ch/f
		unset [p1 p2 ch]

	; --test-- "#934"
	; 	; should check for compiler error
	; 	print*: :print
	; 	print: does []
	; 	; TODO: something something
	; 	print: :print*

	--test-- "#939"
		b: [#"x" #"y"]
		--assert not error? try [b/(#"x")]
		--assert equal? #"y" b/(#"x")
		unset 'b

	; --test-- "#943"
	; 	TODO: IMO this bug is double bag, it should not accept "5 at all"
	; 	; needs to check for print output
	; 	bar: func [/with a [block!] b][
	; 		?? a 
	; 		?? b
	; 	]
	; 	bar/with 5 6

	--test-- "#946"
		; should check for compiler error
		f: function [
			a [object!]
		][
			a/b
		]
		unset 'f

	--test-- "#947"
		; should check for compiler error
		f: func [
			o [object!]
		][
			if o/a [o/a]
		]
		unset 'f

	--test-- "#956"
		; should check for compiler error
		f: function [
			o [object!]
		][
			if o/a [
				all [o]
			]
		]
		unset 'f

	--test-- "#957"
		; should check for compiler error
		f: function [
			o [object!]
		] [
			switch o/a [
				0 [
					switch 0 [
						0 [
						]
					]
				]
			]
		]
		unset 'f

	--test-- "#959"
		; should check for compiler error
		c: context [
			x: none

			f: func [
				o [object!]
			] [
				x: o/a
			]
		]
		unset 'c

	--test-- "#960"
		; should check for compiler error
		c: object [
			d: object [
			]
		]

		f: func [
		][
			c/d
		]
		unset [c f]

	--test-- "#962"
		; should check for compiler error
		f: function [
			o [object!]
		] [
			v: none

			case [
				all [
					o/a = o/a
					o/a = o/a
				] [
				]
			]
		]
		unset 'f

	; --test-- "#965"
		; should check for compiler error
		; f: func [
		; 	o [object!]
		; ] [
		; 	if yes [
		; 		append o/a o/b
		; 	]
		; ]

	; --test-- "#967"
		; R/S

	; --test-- "#969"
		; compilation error

	; --test-- "#970"
		; library compilation problem

	--test-- "#971"
		c: context [
			set 'f does []
		]
		--assert not unset? 'f
		unset [c f]

	--test-- "#973"
		a: func [] [
			repeat i 2 [i]
		]
		b: copy []
		repeat j 2 [append b a]
		--assert equal? [2 2] b
		unset [a b]

	--test-- "#974"
		--assert not error? try [random 3]

	--test-- "#980"
		c: context [
			set 'f does []
		]
		--assert not error? try [f]
		unset [c f]

	--test-- "#981"
		b: [a: none]
		--assert equal? object b context b
		unset 'b

	--test-- "#983"
		f: func [
			o
		] [
			switch o/x [
				0 []
			]
		]
		--assert unset? f object [x: 0]
		unset 'f

	; --test-- "#988"
		; TODO: platform specific compilation problem

	--test-- "#990"
		f: func [
			o [object!]
		] [
			switch type?/word o/x [
				integer! [
					'integer
				]
			]
		]
		--assert equal? 'integer f object [x: 0]
		unset 'f

	--test-- "#993"
		f: func [
			o [object!]
			/local a
		] [
			switch a: type? o/x [
				integer! [
					print "?"
				]
			]
		]
		--assert not error? try [f object [x: 0]]
		unset 'f

	; --test-- "#994"
		; TODO: caused by Rebol GC bug

	; --test-- "#995"
		; TODO: architecture specific problem

	; --test-- "#1001"
		; should check PRINT output

	; --test-- "#1003"
		; TODO: reactor test (seem not to work somehow)

	; --test-- "#1005"
		; precompiled binary error

	; --test-- "#1019"
		; TODO: library compilation problem

	; --test-- "#1020"
		; console behaviour

	--test-- "#1022"
		; should check for crash
		--assert not parse [%file] [#"."]

	; --test-- "#1031"
		; should check PRINT output from R/S

	--test-- "#1035"
		; should check for crash
		global-count: 0
		global-count-inc: function [
			condition [logic!]
		][
			if condition [global-count: global-count + 1]
		]
		--assert error? try [global-count-inc true]
		unset [global-count global-count-inc]

	--test-- "#1042"
		; should check for compilation error

		varia: 0
		print power -1 varia

		varia: 1
		print power -1 varia

		unset 'varia

	--test-- "#1050"
		; should check for compilation error
		--assert not error? try [add: func [a b /local] [a + b]]

	; --test-- "#1054"
	;	TODO: should check for compiler error
	; 	unset 'a
	; 	book: object [list-fields: does [words-of self]]
	; 	try [print a] ; needs to trigger error
	; 	--assert not error? try [words-of book]

	--test-- "#1055"
		my-context: context [
			do-something: routine [ 
				num [integer!] 
				return: [integer!]
				/local
				ret
			] [
				ret: num + 1
				ret
			]
		]

		--assert equal? 2 my-context/do-something 1
		unset 'my-context

	; --test-- "#1059"
		; TODO: should check for crash

;	--test-- "#1063"
; 		TODO: help not defined in compiler
;		--assert not error? try [help]

	; --test-- "#1071"
		; should check for crash

	; --test-- "#1074"
	;	TODO: should check for compiler error
	; 	unset 'd
	; 	--assert error? try [d]
	; 	x: [d 1]
	; 	--assert equal? 1 select x 'd
	; 	--assert error? try [select x d]
	; 	--assert error? try [d]
	; 	unset 'x

	; --test-- "#1075"
		; should check for crash

	; --test-- "#1079"
		; TODO: console behaviour

	--test-- "#1080"
		; should check for crash
		--assert error? try [load "x:"]

	; --test-- "#1083"
		; should check for crash

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

	--test-- "#1090"
		#system-global [
			data!: alias struct! [
				count [integer!]
			]
			data: declare data!
		]
		begin: routine [] [
			data/count: 0
		]
		count: routine [
			return: [integer!]
		] [
			data/count
		]
		begin
		prin count print " rows processed"
		--assert not error? try [print [count "rows processed"]]

	--test-- "#1093"
		str: none ; othrwise compiler would complain that STR has no value
		parse "abcde" ["xyz" | copy str to end]
		--assert equal? "abcde" str
		unset 'str

	; --test-- "#1098"
		; console behaviour

	; --test-- "#1102"
		; TODO

	--test-- "#1113"
		a: "abcz"  
		b: 5 
		--assert none? a/5 
		--assert none? a/:b
		--assert error? try [a/b]
		unset [a b]

	; --test-- "#1115"
		; console behaviour

	--test-- "#1116"
		o: object [
			sin*: :sin
			set 'sin does [
				sin* none
			]
		]
		e: try [sin]
		; NOTE: uses NOT NOT to convert to logic!, because --assert does not accept NONE
		--assert not not all [
			error? e
			not equal? '<anon> e/arg3
		]

	; --test-- "#1117"
		; should check for crash

	--test-- "#1119"
		--assert error? try [append/only: [a b c] [d e]]

	--test-- "#1120"
		; should check for crash
		--assert error? try [load {b: [] parse "1" [copy t to end (append b t)])}]
		--assert error? try [load {b: [] parse "1" [some [copy t to end (append b t)]])}]

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

	; --test-- "#1135"
	; 	; should check for crash
	; 	a: func [v [block!]][error? try v]
	; 	--assert a [unset-word]

	--test-- "#1136"
		e: try [load {a: func [][set 'b: 1]}]
		--assert not not all [
			equal? e/type 'syntax
			equal? e/id 'invalid
			equal? e/arg1 lit-word!
		]

	--test-- "#1141"
		; should check for compilation error
		o: object [
			A: 1
		]
		s: 'A
		--assert not error? [print o/:s]


	--test-- "#1143"
		--assert not error? try [
			do [
				a: object [
					b: object [
						c: 1
					]
					d: does [
						make a [b: none]
						probe b/c
					]
				]
				a/d
			]
		]
		--assert equal? 1 z: do [
			a: object [
				b: object [
					c: 1
				]
				d: does [
					probe b/c
				]
			]
			e: copy/deep a
			f: make e [b: none]
			a/d
		]

	--test-- "#1144"
		f: function [][
			op: :form
			append op 1 2
		]
		--assert not error? try [a]

	; --test-- "#1146"
		; console behaviour

	; --test-- "#1147"
		; console behaviour

	--test-- "#1148"
		try-func: func [v [block!]][error? try v]
		--assert try-func [unset-word]

	; --test-- "#1153"
		; TODO

	--test-- "#1154"
	f: function [
		/s string [string!]
		/i integer [integer!]
	][]
	--assert not error? try [do [f/i/s 1 "a"]]

	--test-- "#1158"
		ret: copy []
		v: make vector! [1 2 3 4 5 6 7 8 9]
		foreach [v1 v2 v3] v [repend ret [v1 v2 V3]]
		--assert equal? [1 2 3 4 5 6 7 8 9] ret
		unset [v ret]

	--test-- "#1159"
		; should check for compilation error
		--assert not error? try [
			f: function [
				/a
				/b
			][
				if a [b: true]
			]
		]

	--test-- "#1160"
		abc: 2
		--assert not error? try [print [ABC]]

	--test-- "#1163"
		f: function [
			/l
		][
			b: []
			if l [return b]
			append b 1
		]
		--assert not error? try [foreach a f/l [print a]]
		f: does [return [1]]
		--assert not error? foreach a f [print a]
		unset [b f] ; cleanup

	; --test-- "#1164"
		; console behaviour

	--test-- "#1167"
		ret: copy []
		--assert block? case/all [
 			1 < 2 [append ret 1]
    		true [append ret 2]
		]
		--assert equal? [1 2] ret

	--test-- "#1168"
		; TODO: should check for compilation error (throws compilation error, but is fine in console)
		;--assert not error? try [case [1 > 2 [print "math is broken"] 1 < 2]]
		; should check for crash

	; --test-- "#1169"
		; console behaviour

	; --test-- "#1171"

;	--test-- "#1176"
;		; TODO: should check for compilation error
;		--assert error? try [blk: reduce [does [asdf]]]
;		--assert error? try [blk/1]
;		; should check for crash

	; --test-- "#1186"
		; console behaviour

	--test-- "#1195"
		m: make map! [a: 1 b: 2]
		--assert not error? try [m/b: none]
		; should check for crash

	--test-- "#1199"
		test: func [input [block!] /local exp-res reason] [
			exp-res: get input/expect
		]
		--assert not error? try [test ["" expect true]]

	--test-- "#1206"
		m: #(a 1 b 2)
		m/a: none
		m/a: none
	;	--assert equal? m #(b 2) ; -- cannot work because of 2209
		--assert equal? [b] keys-of m
		--assert equal? [2] values-of m

	--test-- "#1207"
		o: make object! [a: 1 b: 2]
;		--assert error? try [o/c] ; should check for compilation error
;		--assert error? try [o/c: 3] ; should check for compilation error
		--assert not error? try [o] ; should test for crash

	--test-- "#1209"
		; should test for freeze
		--assert not error? try [parse [a: 1.2.3] [some [remove tuple! | skip]]]

	--test-- "#1213"
		--assert error? try [load "1.2..4"]

	--test-- "#1218"
		--assert error? try [load "p: [a/b:/c]"]

	--test-- "#1222"
		o: make object! [a: 1 b: 7 c: 13]
		--assert error? try [o/("c")]

;	--test-- "#1230"
;		TODO: should check for compilation error
;		o: make object! [a: 1 b: 7 c: 13]
;		--assert error? try [set [o/b o/c] [2 3]]

	; --test-- "#1232"
		; TODO

; 	FIXME: causes internal compiler error, see #2198
;	--test-- "#1238"
;		e: try [pick/case #(a 1 b 2) 'B]
;		--assert equal? 'case e/arg2

	--test-- "#1243"
		b: ["A" "a" "b" "B"]
		d: ["E" "e" "b" "B"]
		--assert equal? ["A" "a" "b" "B" "E" "e"] union/skip b d 2

	; --test-- "#1245"
		; TODO

	; --test-- "#1246"
		; console behaviour

	--test-- "#1259"
		--assert not equal? charset "abc" negate charset "abc"
	
	--test-- "#1265"
		--assert equal? -1x-2 negate 1x2

	--test-- "#1275"
		o: context [f: does [self]]
		x: o/f
		--assert same? o x

	; --test-- "#1281"
		; TODO

	; --test-- "#1284"
		; crush.dll problem

	; --test-- "#1290"
		; GUI

	; --test-- "#1293"
		; should check for compiler crash

	--test-- "#1307"
		h: make hash! [1x2 0 3x4 1]
		--assert equal? 0 select h 1x2
		--assert equal? make hash! [3x4 1] find h 3x4

	; --test-- "#1322"
		; R/S

	; --test-- "#1324"
		; TODO: should check for compiler error

	--test-- "#1329"
		--assert not error? try [and~ #{01} #{FF}]
		--assert not error? try [or~ #{01} #{FF}]
		--assert not error? try [xor~ #{01} #{FF}]

	--test-- "#1345"
		; should check for crash
		url: http://autocomplete.wunderground.com/aq?format=JSON&lang=zh&query=Beijing
		json: read url

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
		e: try [load {(5+2)}]
		--assert all [
			equal? e/id 'invalid
			equal? e/arg1 integer!
		]
		e: try [load {[5+2]}]
		--assert all [
			equal? e/id 'invalid
			equal? e/arg1 integer!
		]

	; --test-- "#1397"
		; R/S

	--test-- "#1400"
		; should check for crash
		--assert error? try [make op! 'x]

	--test-- "#1416"
		; should check for crash
		a: "1234" 
		b: skip a 2 
		copy/part b a
		
		a: skip "1234" 2
		--assert equal? "12" copy/part a -2

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
		--assert not error? try [o: make object! compose [a: (add 1 1)]]

	; --test-- "#1422"
		; GUI

	; --test-- "#1424"
		; GUI

	--test-- "#1427"
		o1: object [
			make: function [
				return: [object!]
			] [
				temp: object [] 
				temp
			]
		]
		o2: object []
		make o1/make o2


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
		write %test.txt ""
		write/append %test.txt "hi"
		write/append %test.txt "there"
		--assert equal? "hithere" read %test.txt

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
		o: make object! [f: 5]
		--assert error? try [do load {set [o/f] 10}]

	; --test-- "#1493"
		; GUI

	; --test-- "#1496"
		; GUI

	--test-- "#1499"
		unset 'b
		--assert error? try [get 'b]
		--assert unset? get/any 'b

	; --test-- "#1500"
		; GUI

	--test-- "#1501"
		c: 0
		foreach i make image! 100x100 [c: c + 1]
		--assert equal? 10'000 c

	; --test-- "#1502"
		; GUI

	--test-- "#1509"
		ctx: object [
			f: func [val /ref][val] 
			t: does [f/ref 1]
		]
		not error? try [ctx/t]

	--test-- "#1515"
		--assert not error? try [1.222090944E+33 // -2147483648.0] ; expected 0
		--assert equal? 0.0 1.222090944E+33 % -2147483648.0 

	; --test-- "#1519"
		; TODO: call-test.red problem

	; --test-- "#1522"
		; GUI

	--test-- "#1524"
		; should check for crash
		error? try [parse [x][keep 1]]

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
		fl: to float! 7
		--assert 7 = to integer! fl

	; --test-- "#1545"
		; R/S problem on ARM

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

	--test-- "#1589"
		; should check for crash
		--assert equal? 1.#NaN power -1 0.5

	--test-- "#1590"
		str: "1.1.1"
		find/part str "1." 2
		--assert equal? "1.1" str: skip str 2
		
	; --test-- "#1591"
		; console behaviour

	; --test-- "#1592"
		; GUI

	; --test-- "#1593"
		; GUI

	; --test-- "#1596"
		; GUI

	--test-- "#1598"
		; should check for crash
		--assert error? try [3x4 // 1.1]

	; --test-- "#1600"
		; GUI

	; --test-- "#1606"
		; console behaviour

	; --test-- "#1607"
		; TODO: random crash?

	--test-- "#1609"
		not error? try [parse-trace "12345678" ["1" to end]]

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

	; --test-- "#1679"
	; 	; should check for compilation error -throws error
	; 	switch 1 []

	--test-- "#1680"
		f: func [] [keys-of #(1 2) none]
		--assert not error? try [f]

	; --test-- "#1683"
		; GUI

	; --test-- "#1684"
		; GUI

	; --test-- "#1694"
	; 	f: func [x] [x]
	; 	e: try [f/only 3]
	; 	--assert equal? e/arg2 'only

	--test-- "#1698"
		; should check for crash
		--assert not error? [
			h: make hash! []
			loop 10 [insert tail h 1]
		]

	; --test-- "#1700"
		; TODO: Linux/Wine specific

	; --test-- "#1702"
		; TODO: try to isolate the bug, or put to separate file

	; --test-- "#1709"
		; TODO: WHAT is not defined in compiler

	; --test-- "#1710"
		; should check for compiler error

	; --test-- "#1715"
		; console behaviour

	; --test-- "#1717"
		; GUI

	; --test-- "#1718"
		; GUI

	; --test-- "#1720"
		; should check for crash

	--test-- "#1723"
		write %中坜 "test"
		--assert equal? "test" read %中坜

	--test-- "#1729"
		not error? try [123456789123456789]
		equal? 123456789123456789 1.234567891234568e17

	--test-- "#1730"
		; should check for crash
		not error? try [reduce does ["ok"]]

	; --test-- "#1732"
		; FIXME: example throws error: eval-command has no value

	--test-- "#1741"
		--assert not error? try [foreach a [1 2 3 4][break]]
		--assert not error? try [repeat n 4 [break]]

	; --test-- "#1745"
		; GUI

	--test-- "#1746"
		; should check for crash
		s: make object! [m: func [][] b: func [arg] [compose/deep [(arg)]]]
		s2: make s []
		--assert equal? [1] s/b 1

	--test-- "#1750"
		e: try [load "2#{FF}"]
		--assert all [
			equal? e/type 'syntax
			equal? e/id 'invalid
			equal? e/arg1 binary!
		]
		e: try [load "64#{AA}"]
		--assert all [
			equal? e/type 'syntax
			equal? e/id 'invalid
			equal? e/arg1 binary!
		]
		e: try [load "4#{0}"]
		--assert all [
			equal? e/type 'syntax
			equal? e/id 'invalid
			equal? e/arg1 integer!
		]
		not error? try [load "16#{AA}"]

	; --test-- "#1751"
		; R/S

	; --test-- "#1753"
		; TODO take a look

	; --test-- "#1754"
		; GUI

	; --test-- "#1755"
		; GUI

	--test-- "#1758"
		; should check for crash
		--assert error? try [system/options/path: none]

	; --test-- "#1762"
		; GUI console behaviour

	; --test-- "#1764"
		; console behaviour (nonGUI)

	--test-- "#1768"
		--assert error? try [load {a: %{test ing.txt}}]

	; --test-- "#1769"
		; console behaviour

	; --test-- "#1774"
		; needs to be in separate file probably

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

	--test-- "#1807"
		m: #(a: 1)
		a: m/a
		--assert not error? try [probe a]
		--assert not error? try [print type? a]
		--assert not error? try [?? a]

	; --test-- "#1809"
		; GUI

	--test-- "#1814"
		t: 1.4.3
		--assert equal? 1 min min t/1 t/2 t/3
		--assert equal? 4 max max t/1 t/2 t/3
		--assert equal? 49 50 - t/1
		--assert equal? 21 20 + t/1
		--assert equal? 21 t/1 + 20

	; --test-- "#1816"
		; GUI

	; --test-- "#1817"
		; GUI

	; --test-- "#1820"
		; GUI

	--test-- "#1829"
		md5: does ['MD5]
		--assert function? do "probe :md5"

	; --test-- "#1831"
	; 	; should check for crash
	; 	function [a] [repeat a/1]
	;
	; FIXME: throws compilation error:

;*** Compilation Error: invalid function spec block: [1]
;*** in file: %/E/Code/aaa/rebolek/red/tests/source/units/regression-test.red
;*** near: [[a
;        /local a 1
;    ] [repeat a/1]

	--test-- "#1834"
		--assert equal? #(a: 3) extend/case extend/case make map! [a 1] [a 2] [a 3]

	--test-- "#1835"
		m: make map! [a 1 A 2]
		--assert equal? 2 select/case m 'A
		--assert equal? 1 select/case m 'a
		--assert equal?
			make map! [a: 1 a 2]
			make map! [a 1 a: 2]
		m: make map! [a 1 A 2 a: 3 :a 4]
		--assert equal? m #(a: 4 A: 2)

	; --test-- "#1836"
		; should check for crash

	; --test-- "#1838"
		; GUI

;	--test-- "#1842"
;		; should check for crash
;		--assert error? try [throw 10]

	; --test-- "#1847"
		; GUI

	; --test-- "#1853"
		; GUI

	--test-- "#1858"
		; should check for crash
		--assert error? try [
			f: func [] [f]
			f
		]

	--test-- "#1865"
		--assert not equal? 2 (a: 'ok 1 + 1 :a)
		--assert equal? 'ok (a: 'ok 1 + 1 :a)

	; --test-- "#1866"
	; 	; should check for crash
	; 	--assert error? try [parse "abc" [(return 1)]]
	;	FIXME: throws *** Runtime Error 95: no CATCH for THROW
	;		but when compiled separately, works

	--test-- "#1867"
		; original error should result in endless loop. how to check it?
		rule: [
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
		x: [1 2 "[" a b "]" 3 4]
		--assert parse x rule

	; --test-- "#1868"
		; compiler error

	; --test-- "#1869"
		; GUI

	; --test-- "#1872"
		; GUI

	; --test-- "#1874"
		; GUI

	--test-- "#1878"
		; should check for crash
		--assert not error? try [
			digit: charset "0123456789"
			content: "a&&1b&&2c"
			block: copy [] parse content [
				collect into block any [
					remove keep ["&&" some digit] 
					(remove/part head block 1 probe head block) 
				| 	skip
				]
			]
		]


	; --test-- "#1879"
		; GUI

	; --test-- "#1880"
		; Rebol GC bug

	--test-- "#1881"
		--assert not error? try [
			rule: [ 
				any [
					mark: set a [ any-word! ] (
						if [ ][ ]
					) | into rule | skip
				] 
			]
		]

	--test-- "#1882"
		a: "X"
		digit: charset "0123456789"
		content: "a&&1&&2&&3m"
		block: copy [] 
		parse content [
			collect into block any [
				remove keep ["&&" some digit] insert (a) 
			|	skip
			]
		]
		--assert equal? content "aXXXm"

	; --test-- "#1883"
		; GUI

	; --test-- "#1884"
		; GUI

	--test-- "#1887"
		s: {a
b}
		--assert equal? {a^/b} s
		--assert not equal? {a^M^/b} s

	; --test-- "#1889"
		; GUI

	; --test-- "#1892"
		; binding problem when including external file 
		; TODO: needs separate file for testing

	--test-- "#1893"
		--assert equal? (1.4.8 * 3) (3 * 1.4.8)

	--test-- "#1894"
		; should check for crash
		unset 'test
		--assert error? try [parse [1] [collect into test keep [skip]]]

	; --test-- "#1895"
	; 	; should check for crash
	; NOTE: this test works in console, but not when compiled
	; 	fn: func [body [block!]] [collect [do body]]
	; 	fn [x: 1]
	; 	--assert equal? x 1

	; --test-- "#1900"
		; GUI

	--test-- "#1905"
		x: [a b c 4 d e f]
		move/part x skip x 3 2
		--assert equal? x [c 4 a b d e f]

	; --test-- "#1907"
		; should check for crash

	; --test-- "#1910"
		; GUI

	--test-- "#1911"
		m: make map! []
		k: "a"
		put m k 1
		k: "b"
		--assert error? try [set m k]

	; --test-- "#1916"
		; GUI

	; --test-- "#1919"
		; GUI console behaviour

	; --test-- "#1920"
		; GUI

	--test-- "#1923"
		a: [1 2 3] 
		forall a [if a/1 = 2 [break]]
		--assert equal? a [2 3]

	; --test-- "#1925"
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

	; --test-- "#1935"
;		--assert error? try [test/:]
;		; NOTE: bug should crash, how to test it?

	; --test-- "#1937"
		; GUI console behaviour

	--test-- "#1939"
		unset 'a
		--assert error? try [parse blk: [1][change integer! a]]

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

	; --test-- "#1969"
		; FIXME: still a problem in R/S

		; foo: func [a [float!] b [float!]][a + b]

		; out: #system [
		; 	#call [foo 2.0 4.0]
		; 	fl: as red-float! stack/arguments
		; 	probe fl/value
		; ]
		; print ["*** out:" out]


	; --test-- "#1974"
		f: func [p [string!]] [print p]
		--assert error? try [f 'spec] 	; NOTE: this should check that it does not crash
										; 		how to do it?

	; --test-- "#1983"
		; R/S

	; --test-- "#1991"
		; console behaviour

	; --test-- "#1992"
		; GUI

	--test-- "#1993"
		unset 'range
		unset 'a
		range: [0 0] 
		a: range/1: 1
		--assert equal? [1 0] range

	; --test-- "#1995"
	; 	; NOTE: currently still a bug
	; 	unset 'a
	; 	--assert error? try [load/next "(]" 'a]

	--test-- "#1996"
		blk: [a b #x #y 2 3]
		put blk 2 4
		--assert equal? [a b #x #y 2 4] blk

	; --test-- "#1999"
		; R/S

	; --test-- "#2003"
		; GUI console

	--test-- "#2007"
		; NOTE: how to check for crash?
		--assert not error? [make image! 0x0]

	--test-- "#2012"
		random/seed 1
		t: random 0:0:1
		--assert equal? 0:00:00.0 round t

	--test-- "#2014"
		--assert equal? 1:00:00 / 0:0:1 3600.0

	--test-- "#2015"
		--assert error? try [0:0:2 ** 5]

	; --test-- "#2019"
		; R/S

	--test-- "#2021"
		--assert error? try [set 'vv first reduce [()]]
	
	--test-- "#2024"
		write %test.txt "abcdef"
		--assert equal? "bcdef" read/seek %test.txt 1

	--test-- "#2031"
		--assert equal? ["1" "3" "" "3" "" ""] split "1,3,.3,," charset ".,"

	--test-- "#2033"
		--assert not error? try [func [x "radius" y "degrees"][x + y]]
;		--assert error? try [func [x "radius" [integer!] y [integer!] "degrees"][x + y]] ; test for #2027 -- how to test for compiler errors?

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
		x: 1.2.3.4.5.6.7.8.9.10
		--assert equal? x 1.2.3.4.5.6.7.8.9.10
		x: 1.2.3.4.5.6.7.8.9.10.11.12
		--assert equal? x 1.2.3.4.5.6.7.8.9.10.11.12

	--test-- "#2069"
		--assert equal? "abc1abc2abc3" unique/skip "abc1abc2abc3" 3

	; --test-- "#2070"

	--test-- "#2072"
		m: make map! 10
		a: [1 2 3]
		m/a: a
		save %file m
		n: load %file
		--assert equal? m n

	--test-- "#2077"
		sum: function [list [block!]] [
			total: 0
			foreach i list [total: i + total]
			total
		]
		r: make reactor! [l: [3 4 5 6] total: is [sum l]]
		r/l: append copy r/l 5
		--assert not error? try [append r/l 5]

	--test-- "#2079"
		i: make image! 2x2
		--assert not error? try [foreach p i [p]]

	; --test-- "#2081"

	--test-- "#2083"
		a: make reactor! [x: 1 y: is [x + 1] z: is [y + 1]]
		a/x: 4
		--assert equal? 6 a/z

;	--test-- "#2085"
		; FIME: throws error: *** Script Error: y has no value
;		--assert error? try [d: make reactor! [x: is [y + 1] y: is [x + 3]]]

	; --test-- "#2096"

	--test-- "#2097"
		write %test.bin #{00000000}
		write/seek %test.bin #{AAAA} 2
		--assert equal? #{0000AAAA} read/binary %test.bin
		write/seek %test.bin #{BBBB} 0
		--assert equal? #{BBBBAAAA} read/binary %test.bin

	; --test-- "#2098"
		; GUI

	--test-- "#2099"
		original: read/binary http://www.rebol.com/how-to/graphics/button.gif
		write/binary %button.gif original
		saved: read/binary %button.gif
		--assert equal? saved original

	; --test-- "#2104"
		; console behaviour - #1995

	; --test-- "#2105"
		; infinite loop - how to catch it?

	--test-- "#2108"
		--assert parse "x" [to [end]]

	; --test-- "#2109"
		; console

	; --test-- "#2113"
		; FIXME: got "compilation error"

		; a: make object! [
		; 	act-state: make object! [
		; 		finish?: false
		; 		fn-callback: none
		; 	]
		; 	start: function[callback][
		; 		self/act-state/fn-callback: :callback
		; 	]
		; ]
		; callback1: function[][bad-value: "xyz"]
		; a/start :callback1
		; --assert not value? 'bad-value
	
	; --test-- "#2118"
		; GUI

	--test-- "#2125"
		--assert 2 = length? find reduce [integer! 1] integer!

	; --test-- "#2133"
		; TODO: compiler error

	; --test-- "#2135"
		; TODO: R/S

	--test-- "#2136"
		blk: copy []
		insert/dup blk 0 3
		insert/dup blk 1 2
		--assert equal? blk [1 1 0 0 0]

	--test-- "#2137"
		repeat n 56 [to string! debase/base at form to-hex n + 191 7 16]
		; NOTE: how to catch crash? - should crash in old version

	--test-- "#2138"
		b: [1 2 3 4 5]
		forall b [i: b/1: form b/1]
		--assert equal? b ["1" "2" "3" "4" "5"]

	--test-- "#2139"
		--assert equal? 1% 1% * 1

	--test-- "#2143"
		; NOTE: how to catch crash? - should crash in old version
		ts: [test: 10]
		t-o: object []
		make t-o ts

	--test-- "#2146"
		test: make hash! [a: 10]
		--assert equal? 10 test/a
		test: make hash! [a: 10 a 20]
		--assert equal? 10 test/a

	; --test-- "#2147"
		; GUI

	; --test-- "#2149"
		; GUI

;	--test-- "#2152"
;		--assert error? try [func [/x x] []]
;		; causes compiler error

;	--test-- "#2155"
;		--assert error? try [func [h [integer!!]] [h]]
;		; causes compiler error

	--test-- "#2157"
		--assert error? try [-2147483648 / -1]
		--assert error? try [-2147483648 % -1]
		--assert error? try [remainder -2147483648 -1]

	--test-- "#2159"
		--assert equal? #{3030303030303134} append #{} to-hex 20
		; bug causes crash

	--test-- "#2160"
		--assert not error? try [extract/into/index [1 2 3 4 5 6] 2 b: [] 2]

	; --test-- "#2162"
		; write/info https://api.github.com/user [GET [User-Agent: "me"]]
		; crashes runtime

	; --test-- "#2163"
		; TODO: get some example, description is not good enough

	--test-- "#2166"
		x: 2147483648
		--assert not equal? x -2147483648
		--assert equal? x 2147483648.0

	; --test-- "#2170"
		; GUI

	; --test-- "#2171"
		; FIXME: still a bug, crashes testing
	; 	quote1: func ['val] [val]
	; 	--assert probe equal? first [()] quote1 () ; this test throws *** Script Error: quote1 does not allow unset! for its 'val argument
	; 	--assert probe error? try [quote1 (test)]
	; 	unset 'quote1

	--test-- "#2173"
		--assert not parse [] [return]
		--assert not parse [] [parse]
		--assert not parse [] ["why"]
		--assert not parse [] [red]
		--assert not parse [] [append]
	;	--assert not parse [] [help] ; still a bug, crashes testing

	--test-- "#2177"

		--assert not new-line? [foo]
		--assert new-line? [
			foo
		]

	--test-- "#2187"
		--assert error? try [load {64#{aaa }}]

	--test-- "#2195"
		e: try [load "system/options/"]
		--assert equal? "system/options/" e/arg2
		unset 'e

	--test-- "#2196"
		m: #()
		repeat k 70 [
			m/:k: {x}
			m/:k: none
		]
		--assert empty? keys-of m
		unset 'm

	--test-- "#2209"
		m: #(a 1 b 2)
		m/a: none
		--assert equal? #(b: 2) m
		unset 'm

	; --test-- "#2223"
		; GUI

	--test-- "#2227"
		--assert equal? ["1"] split "1^/" #"^/"
		--assert equal? ["1" "2"] split "1^/2^/" #"^/"

===end-group===

~~~end-file~~~