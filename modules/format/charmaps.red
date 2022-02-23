Red [
	Title:       "Char maps for format L10N"
	Description: "Provide L10N of symbols (mainly digits) across formatting module"
	Author:      @hiiamboris
	Rights:      "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
    Notes: {
    	Char map reflects how each symbol is translated in a given locale.
    	Date/time uses only digits translation,
    	Number formatter - also superscript, separators and special float names.
    	
    	`testing` charmap is only used by number formatter,
    	mainly to distinguish financial from normal digits.
    }
]

; #include %locale.red
; #include %../common/new-each.red

context [
	digit-list:  "0123456789"
	superscript: "0⁰1¹2²3³4⁴5⁵6⁶7⁷8⁸9⁹+⁺-⁻(⁽)⁾"			;-- hardcoded
	; subscript: "0₀1₁2₂3₃4₄5₅6₆7₇8₈9₉+₊-₋(₍)₎"			;-- not used yet
	
	;@@ temporary helper until we have a proper one in runtime
	map-each: function ['word series code /eval] [
		collect [
			looper: either integer? series ['repeat]['foreach]
			system/words/:looper (word) series [
				keep either eval [reduce do code][do code]
			]
		]
	]
	
	;; prepare charmap for 'testing' locale
	build-test-charmap: function [] [
		ct: #()											;-- for testing: chars are fixed and differ from prototypes
		ct/superscript: to map! map-each/eval [x y] superscript [[x y]]
		ct/finance:     to map! map-each/eval x digit-list [	;-- fin digits should differ from default ones
			[x pick "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" x - #"0" + 1]		;-- so we can distinguish them in tests
		]
		put ct/finance #"$" func [size] [
			pick ["¥" "CN¥" "CNY" "Chinese yuan"] size			;-- names should differ is the only requirement
		]
		ct/finance/(#"."): #","
		ct/finance/(#" "): #"."
		ct/default:     to map! map-each/eval x digit-list [
			[x pick "0123456789" x - #"0" + 1]
		]
		foreach [x y] "..EEx× '++--(())%%‰‰" [ct/default/:x: y]
		; ct/default/(#"#"): ""									;-- empty for hash, used to remove `#`s
		ct/default/nan: "NaN"
		ct/default/inf: "INF"
		ct
	]
	
	formatting/build-charmap: function [
		"Fill char-map with data from system/locale"
		/for lc-name [word!] "Default: system/locale/locale"
	][
		if lc-name = 'testing [
			return formatting/charmaps/testing: build-test-charmap
		] 
		
		lc-name: any [
			lc-name
			system/locale/locale
			do make error! rejoin ["Unsupported locale "lc-name]
		]
		; any [lc-name  ERROR "Unsupported locale (lc-name)"]
		unless lc-name = 'testing [system/locale/tools/expand-locale lc-name]
		loc: system/locale/list/:lc-name
		#assert [loc]
		
		cm: make map! []
		cm/superscript:  to map! map-each/eval [x y] superscript [[x y]]
		
		sys: loc/numbers/system 
		dig: loc/numbers/:sys/digits
		fin: loc/numbers/:sys/fin-digits
		#assert [dig]
		#assert [fin]
		cm/finance:      to map! map-each/eval i 10 [[#"0" + i - 1  pick fin i]]
     	
		sym: loc/numbers/:sys/symbols
		cm/default: def: to map! map-each/eval i 10 [[#"0" + i - 1  pick dig i]]
		extend def reduce [
			; #"." sym/decimal
			; #"E" sym/exponential
			; #" " sym/group
			; #"-" sym/minus
			; #"+" sym/plus
			; #"%" sym/percent
			; #"‰" sym/permille
			; #"x" sym/superscripting-exponent
			; #"#" ""										;-- used to remove absent digits
			'nan sym/nan
			'inf sym/infinity
     	]
     	formatting/charmaps/:lc-name: cm
	]
	
	;; called by format functions when they need this data
	formatting/update-charmap: function [
		"Fill char-map with data for chosen locale only if it's empty"
		/for lc-name [word!] "Default: system/locale/locale"
	][
		loc: any [lc-name system/locale/locale]
		#assert [loc]
		any [
			formatting/charmaps/:loc					;-- this works for testing locale as well
			formatting/build-charmap/for loc
		]
	]
	
]
