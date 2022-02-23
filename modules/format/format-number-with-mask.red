Red [
	Title:       "Mask number formatter"
	Description: https://github.com/hiiamboris/red-formatting/discussions/15
	Author:      @hiiamboris
	Rights:      "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
]

; #include %charmaps.red

; #include %../common/localize-macro.red
; #include %../common/assert.red
; #include %../common/new-each.red
; #include %../common/composite.red
; #include %../common/error-macro.red
; #include %../common/count.red
; #include %../common/clock.red
                              
; #include %../common/profiling.red
; #include %../common/show-trace.red


exponent-of: function [
	"Returns the exponent E of number X = M * (10 ** E), 1 <= M < 10"
	x [integer! float!]
	;; return: none for zero and +-inf/nan (to integer overflows)
][
	attempt [to integer! round/floor log-10 absolute x]
]

#assert [
	0    = exponent-of 1
	0    = exponent-of 1.0
	0    = exponent-of 9.9
	0    = exponent-of 9.99999999999999
	1    = exponent-of 10
	1    = exponent-of 99.9999999999999
	20   = exponent-of 1e20
	-1   = exponent-of 0.99999999999999
	none = exponent-of 0
	none = exponent-of 0.0
	-300 = exponent-of 1e-300
	300  = exponent-of 1e300
]


formatting/number-ctx: context [
	sign!:         charset "+-"
	brace!:        charset "()"
	digit!:        charset "0123456789"
	digit19!:      charset  "123456789"
	figure!:       charset "0123456789#"
	; figure+space!: charset "0123456789# "
	exponent!:     charset "Ex"
	separator!:    charset " ."
	indentation!:  charset [" ^(A0)^(202F)^(205F)^(3000)" #"^(2000)" - #"^(200A)"]
	hash:          #"#"
	dollar:        #"$"
	permille:      #"‰"
	
	#assert [not parse "eX" [any exponent!]]			;-- charsets case sensitive?
	
	
	;;=======  INDEPENDENT FUNCS  =======
	
	
	take-last: function [series] [						;@@ workaround for #5066
		top: back tail series
		also :top/1 clear top
	]
	
	grouping?: function [
		"Extract all group sizes (reversed) from a mask with spaces"
		digits [string!] "only digits, # and spaces allowed"
		buf    [block!]  "where to extract (cleared)"
	][
		clear buf
		parse/case digits [collect into buf any [
			remove any #" " p1: some figure! p2: keep (offset? p1 p2)
		]]
		if 2 <= length? buf [buf/1: max buf/1 buf/2]	;-- 1st group is grown up to 2nd
		reverse buf										;-- now group before last is the primary one
	]
	
	rounding?: function [
		"Convert string of digits into integer rounding period"
		digits [string!] "may start with #s; no spaces"
	][
		#assert [not find digits #" "]
		either digits: find digits digit19! [to integer! digits][0]
	]
	
	split-money: function [
		"Split-float analog for money values"
		x [money!] base [integer!]
	][
		r: ["" "" "" "" ""]
		parse s: mold/all x [remove thru #"$" to #"." p:]	;-- an allocation we can't get rid of :(
		if all [base <> 0  x <> $0] [
			either base > 0 [							;-- separator moves left
				whole: -1 - base + index? p
				remove p
				if whole <= 0 [insert/dup s #"0" 1 - whole  whole: 1]
				insert p: skip s whole #"."
			][											;-- separator moves right 
				frac: -1 + base + length? p
				remove p
				if frac <= 0 [append/dup s #"0" 1 - frac  frac: 1]
				insert skip tail s negate frac #"."
				parse s [remove any [#"0" not #"."] to #"." p:]	;-- remove leading zeroes
			]
		]
		append      clear r/1 pick "-+" x < $0
		append/part clear r/2 s p
		append      clear r/3 next p
		append      clear r/4 pick "-+" base < 0
		append      clear r/5 absolute base
		r
	]
	
	#assert [
		["+" "0" "00000"         "+" "0"] = split-money  $0         0
		["+" "0" "00000"         "+" "5"] = split-money  $0         5
		["+" "0" "00000"         "-" "3"] = split-money  $0        -3
		["-" "123" "45670"       "+" "0"] = split-money -$123.4567  0
		["-" "1" "2345670"       "+" "2"] = split-money -$123.4567  2
		["-" "12345" "670"       "-" "2"] = split-money -$123.4567 -2
		["-" "12345670000" "0"   "-" "8"] = split-money -$123.4567 -8
		["-" "0" "0000012345670" "+" "8"] = split-money -$123.4567  8
		["+" "0" "123"           "-" "2"] = split-money  $0.00123  -2
	]
		
		
	;;=======  FUNCS USING SHARED DATA  =======
	
	
	;; modifiable shared data starts with `.` to avoid name collisions
	.head:   object [whole: frac: exp: none]			;-- before 1st digit/hash of each scope
	.tail:   object [whole: frac: exp: none]			;-- after last digit/hash of each scope
	.signs:  object [whole:       exp: none]			;-- yes => sign is present in the mask, don't emit default sign
	.groups: object [whole: frac: exp: none]			;-- group sizes; 'frac' is used in significant mode only
	.min:    object [whole: frac: exp: none]			;-- min digits: count of digits
	.max:    object [whole: frac: exp: none]			;-- max digits: count of digits and '#'
	.masks:  object [whole: frac: exp: none]			;-- holds digits, hash & space only
	.split:  object [sign: whole: frac: exp-sign: exp: none]	;-- parts of the number after split-float
	.mask:       none									;-- used for error reporting only
	.currency:   none									;-- pos of $$$ in the mask or none
	.got-frac?:  none									;-- whether fractional part is present in the mask
	.got-exp?:   none									;-- whether exponent part is present in the mask
	.multiplier: none									;-- 100 or 1000 - for percents
	.scope:      none									;-- scope of the mask currently processed: whole/frac/exp
	.context:    none									;-- localization context: default/superscript/finance
	.charmap:    none									;-- charmap (locale) chosen for current format run
	.locale:     none									;-- current locale for currency formatting
	.curr-name:  none									;-- current currency name
	.number:     none									;-- number being formatted
	.base:       none									;-- exponent of number in formatted output
	.out:        none									;-- output buffer
	.cache:      #()									;-- analysis results for every mask
	
	cacheable: context [								;-- properties of mask itself, independent of the number
		objects: [.head .tail .signs .groups .min .max .masks]
		scalars: [.mask .currency .got-frac? .got-exp? .multiplier]
	]
	
	reset: does [
		foreach w [.head .tail .signs .groups .min .max .split] [
			set get w none
		]
		set .masks ["" "" ""]
		foreach w [whole frac exp] [clear .masks/:w]
		set [.mask .currency .got-frac? .got-exp? .multiplier
			 .scope .context .charmap .locale .curr-name .out] none
	]
	
	;; caching cuts total processing time by 10% (tiny) to 30% (long masks)
	;; which is not much, so I'm not sure it's worth it
	from-cache: function [
		"Fetch mask analysis results from the cache"
		mask [string!]
	][
		unless cached: select .cache mask [return no]
		set self cached/1
		cached: next cached
		repeat i length? cacheable/objects [
			set get cacheable/objects/:i cached/:i
		]
		yes
	]
	
	;; helper used by `cache` internally
	cache-object: function [mask [string!] copied [string!] obj [object!] /only words [block!]] [
		words: any [words words-of obj]
		body: clear []
		foreach word words [							;@@ should be map-each/into
			value: get in obj word
			repend body [
				to set-word! word
				case [
					all [
						string? value
						same? head value head mask
					][
						skip copied offset? mask value
					]
					series? value [copy value]
					'scalar [value]
				]
			]
		]
		do [construct/only body]						;@@ DO for compiler - #4071
	]
	
	cache: function [
		"Stash mask analysis results in the cache"
		mask [string!]
	][
		copied: copy mask
		scalars: cache-object/only mask copied self cacheable/scalars
		objects: reduce [scalars]
		foreach obj-name cacheable/objects [			;@@ should be map-each/into
			append objects cache-object mask copied get obj-name
		]
		put .cache copied objects
	]
	
	localize-char: function [
		"Get localized version of a char or string"
		char [char!]
	][
		any [
			select .charmap/:.context :char
			.charmap/default/:char
			char
		]
	]
	
	get-currency: function [
		"Get currency name of given mask size"
		size [integer!]
	][
		; #assert [size <= 4]							;-- 4 removed per team decision
		#assert [size <= 3]
		list: system/locale/list/:.locale/currency-names/:.curr-name
		#assert [block? :list]
		sizes: [
			list/char
			list/std
			.curr-name
			; 'cardinal									;-- removed per team decision
		]
		curr: any at sizes size
		; if curr = 'cardinal [							;-- removed per team decision
			; width: system/locale/cardinal/:.locale
				; n: absolute .number						;-- abs value
				; round/to/floor n 1.0					;-- int part before split: float because may overflow int32
				; max .min/frac length? .split/frac		;-- count of frac digits with trailing 0s
				; none									;-- unused
				; none									;-- unused
				; .base									;-- exponent in formatted value
			; curr: any [
				; list/:width
				; list/other								;-- fallback to other because currencies may not use all forms
				; list/name								;-- fallback to title for exotic currencies (no spelling data)
			; ]
			; #assert [curr] 
		; ]
		curr
	]
	
	get-sign: function ["Get sign for relevant (mantissa/exponent) scope"] [
		either .scope = 'exp [.split/exp-sign/1][.split/sign/1]
	]
				
	get-lengths: function [
		"Count min/max digits and ensure they're in order"
		word [word!] token1 [char! word!] token2 [char! word!] name [word!]
	][
		parse/case digits: .masks/:word compose/into [
			any (token1) p: any (token2)
			[end | (do make error! rejoin [token1" cannot follow "token2" in the "name" part of "mold .mask])]
			; [end | (ERROR "(token1) cannot follow (token2) in the (name) part of (mold .mask)")]
		] clear []
		.min/:word: either token1 = hash [length? p][-1 + index? p]
		.max/:word: length? digits
	]
	
	;@@ this is an interesting func to tackle in morph: 2 sources, one is also target
	regroup: function [
		"Insert .groups/:scope separators into reversed .split/:scope"
		scope [word!] "whole/frac/exp"
		/after len [integer!] "Skip first LEN digits"
	][
		g2: pick tail .groups/:scope -2					;-- get primary group
		unless g2 [exit]								;-- do nothing if mask has no groups
		len: any [len 0]
		s: .split/:scope
		gs: .groups/:scope
		s: skip s gs/1
		while [not tail? s] [
			if len < index? s [s: insert s #" "]		;-- separator will be localized, not here
			g: any [first gs: next gs  g2]				;-- use primary group once exhausted the others
			s: skip s g
		]
	]
	
	pad-mask-parts: function ["Pad .split/* masks with 0/# as required by .min/.max"] [
		either .got-frac? [
			;; fractional mode: extend .split/* to masks lengths; '#' serves as a vanishing digit in masks
			pad/with pad/with .split/whole .min/whole #"0" .max/whole #"#"
			pad/with          .split/frac  .min/frac  #"0"
		][
			;; significant mode: whole & fractional parts should be processed as one
			total: add  length? .split/whole  length? .split/frac
			;; leading zeroes move the location of first significant digit:
			if .split/whole = "0" [						;-- can only have 1 leading zero in whole part
				total: total - index? any [find .split/frac digit19!  tail .split/frac]
			]
			append/dup .split/frac #"0" .min/whole - total
		]
		if .got-exp? [
			pad/with pad/with .split/exp .min/exp #"0" .max/exp #"#"
		]
	]
		
	
	round-number: function [
		"Round NUMBER to EXP-STEP and return [rounded base exp]"
		number [float! integer! money!]
		exp-step [integer!] "Exponent base period (e.g. 3 for engineering)"
	][
		float: to float! number
		exp:   any [exponent-of float 0]
		base:  round/floor/to either .got-exp? [exp][0] exp-step
		rounding-manti:									;-- mantissa rounding depends on exp rounding (base)
			either .got-frac? [							;-- fractional mode: join whole & frac rounding
				rf: rounding? .masks/frac
				rw: rounding? .masks/whole
				pow: 10.0 ** length? .masks/frac
				if rw + rf = 0 [rf: 1.0]					;-- if no rounding defined, round to last frac digit
				rf / pow + rw
			][											;-- significant mode: no frac part
				rw: max 1 rounding? .masks/whole			;-- default rounding: to last significant digit
				rw * power 10.0 exp - base - .min/whole + 1
			]
		if .multiplier [								;-- percent/permille case
			float:  float  * .multiplier				;@@ modification shouldn't cause issues if we use 15 digits only?
			number: number * .multiplier				;@@ mb forbid usage of % given money! value?
		]
		
		;; round the number now
		prec: rounding-manti * power 10 base
		rounded: any [									;-- note: round/even is statistically neutral, ICU-recommended
			all [										;-- try to round money as money if possible
				money? number
				any [
					if prec <= 1e-5 [prec: $0]				;-- if it's below money precision
					attempt [prec: to money! prec]			;-- or if prec is convertible to money
				]
				attempt [round/even/to number prec]			;-- may overflow - see #5002 ;@@ remove attempt once fixed
			]
			round/even/to float to float! prec			;-- case for floats, ints, and extreme money values
		]
		
		;; rounding might have changed the exponent and this is real tricky
		;; e.g. number=9.6E3 -> rounded=10E3, which we may want to output as 1E4
		;; or number=1E3 given mask "5E3" -> rounded=0 (base=none) we want to output as 0E3
		;; (because 0E0 would be just wrong, as our number is 1000E0)
		;; so we have to repeat calculation, but not reset the base to 0 or none
		if all [
			.got-exp?									;-- we don't care for this in fractional mode
			new-exp: exponent-of to float! rounded 		;-- preserve exp from becoming none or 0
		][
			exp: new-exp
			base: round/floor/to exp exp-step
		]
		reduce/into [rounded base exp] clear []
	]
	
	
	;;=======  MASK MERGING  =======
	
	
	{	Some memo here, but it's only the idea, doesn't cover all the intricacies:
		
		significant (applies to mantissa only):
			ignore all #s
			insert non-significant zeroes (and dot) before the first 0
			insert significant digit (maybe zero) for each 0
			switches to frac part when exhausts wholes, automatically, and this inserts "."
			separators in the mask are ignored (after inferring groups)
				formatted parts should be separated in advance and separators inserted
				for that, both whole and frac has to be padded with 0s up to total significants + leading zeros
		whole (applies to exp, whole in frac mode):
			does not emit "." because it exists in the mask
				yet "." disappears if empty fraction part 
			need .split/whole length >= number of figures (incl #)
				insert 0 for each extra 0 in the mask, then
				insert # for each extra # in the mask
			extra wholes are inserted before first figure is emitted,
			so need to know the lengths of all mask parts and length of formatted number parts
				part present in the mask doesn't have to be separated, e.g.:
				`0_ 00`: if we ignore space and insert our separator,
				we don't know if it's `0_ 00` or `0 _00` and mess it up
				so we both insert our separators and pass mask separators
		frac (applies to frac part in frac mode):
			need no separation (because formatted frac length <= frac mask length)
				just insert digit for each 0 and #
			# gets eaten if no more digits, while 0 emits 0
				so trailing 0s have to be removed from formatted frac
			separators have to check for more digits and get eaten too!
				for that, we have to extend formatted fraction to count of 0s
				separators after that should only be emitted if there's more digits to follow
	}
	
	;; quotation rule is shared between all merge* funcs:
	;; '' works as single quote both inside '...' range and outside it
	;; this is unlike ICU and SQL which treat '' as empty string and '''' as single quote
	;; I don't think their behavior is at all useful in numeric masks, because they're mostly single letter
	;; and use case of splitting "$$$" into two masks "$$''$" is of zero value
	=emit-literal=: [
		#"'" [
			#"'" not #"'" keep (#"'")					;-- "x''x" case
		|	some [
				"''" keep (#"'")						;-- "x' '' 'x" case
			|	keep to #"'"
			] #"'"
		]
	]
	
	merge-part: function [
		"Merge part of the mask outside whole, fraction and exponent"
		start [string!] "starting offset"
		end   [string!] "ending offset"
		/local x
		/extern
			.scope			;-- only need to know if we're in exp part or not, to emit sign of mantissa or exp
			.context		;-- may switch to superscript
	][
		out: tail .out
		local: :localize-char
		parse/case/part start [collect into out any [	;-- /case to not accept %O, X, e as %o, x, E
			=emit-literal=
		|	set x exponent! keep (local x) (.scope: 'exp)
			any keep indentation!						;-- let indentation go before `10`
			opt [
				if (x = #"x") keep (local #"1") keep (local #"0")
				(.context: 'superscript)				;-- superscript for the next sign and digits
			]
		|	s: some dollar e: keep (
				; if 4 < size: offset? s e [			;-- 4 removed per team decision
				if 3 < size: offset? s e [
					do make error! rejoin ["Unsupported currency mask '"copy/part s e"' in "mold .mask]
					; ERROR "Unsupported currency mask '(copy/part s e)' in (mold .mask)"
				]
				fn: any [
					:.charmap/finance/:dollar			;-- used by testing locale
					:get-currency						;-- by all the others
				]
				fn size
			)
		|	#"+" keep (local get-sign)					;-- kept sign depends on .scope
		|	#"-" opt [if (#"-" = get-sign) keep (local #"-")]
		|	set x brace! opt [if (.split/sign/1 = #"-") keep (local x)]		;-- braces ignore exponent sign
		|	[permille | "%o"] keep (local permille)
		|	#"%" keep (local #"%")
		|	#"." opt [
				(.scope: 'frac)
				if (any [								;-- only emit decimal separator if will be digits after
					all [
						x: .masks/frac/1				;-- non empty fraction mask?
						find digit! x					;-- got guaranteed digits
					]
					find .split/frac digit19!			;-- at least one of '#'s will emit a digit
				])
				keep (local #".")
			]
		|	keep skip 
		]] end
	]
	
	merge-significant: function ["Merge whole mask as significant digits" /local] [
		#assert [.head/whole]
		#assert [not .head/whole =? .tail/whole]
		#assert [find figure! .head/whole/1]			;-- we should be before 1st figure
		out: tail .out
		local: :localize-char
		;; operates on whole mantissa (whole + frac formatted)
		joined: clear ""
		unless tail? .split/frac [append append joined .split/frac "."]
		append joined .split/whole
		#assert [not find joined hash]					;-- only digits & separators expected
		
		parse/case/part .head/whole [collect into out [	;-- /case because faster
			;; insert sign first
			opt [if (not .signs/whole) if (#"-" = .split/sign/1) keep (local #"-")]
			;; insert non-significant zeroes
			opt [
				if (find joined digit19!)				;-- not all zeroes?
				while [
					if (find "0 ." last joined)			;-- may transcend into fraction part
					keep (local take-last joined)		;-- if it has no significant digits
				]
			]
			;; now we sub each '0' with a digit, optionally prepending group or decimal separator
			any [
				digit! while [
					(#assert [not tail? joined])		;-- have to be grouped in advance, so should be long enough
					keep (local c: take-last joined)
					if (find separator! c)				;-- stop after a digit, repeat after any separator
				]
			|	[#" " | hash]							;-- ignored
			|	=emit-literal=
			|	keep skip
			]
			;; now we also emit the rest of whole if it's not ended, but mask is exhausted
			opt [
				if (any [
					find joined #"."					;-- decimal is ahead, so we haven't exhausted all wholes 
					tail? .split/frac					;-- no formatted decimal, so we only have wholes
				])
				while [
					if (c: take-last joined)
					if (#"." <> c)
					keep (local c)
				]
			]
		]] .tail/whole
	]
	
	merge-whole: function [
		"Merge whole mask as positional digits"
		name [word!] "'whole (of mantissa) or 'exp"
		/local
	][
		; if .head/:name =? .tail/:name [exit]			can happen on ".000" mask - and we still emit wholes
		#assert [.head/:name]
		#assert [any [.head/:name =? .tail/:name  find figure! .head/:name/1]]	;-- mask is empty or starts with a figure
		#assert [not find .masks/:name #" " ]			;-- mask should be devoid of separators here
		part: .split/:name
		local: :localize-char
		;; this cannot be within parse/part because won't run if part is empty:
		;; emit default sign?
		all [
			not .signs/:name							;-- no explicit sign in the mask
			#"-" = get-sign								;-- value is negative
			append .out local #"-"
		]
		;; insert non-significant zeroes before the mask
		extra: (length? part) - (length? .masks/:name)	;-- more digits than in the mask?
		loop extra [append .out local take-last part]
		;; process the mask now
		out: tail .out
		parse/case/part .head/:name [collect into out [	;-- /case because faster
			any [
				figure!
					(#assert [
						not tail? part					;-- has to be padded in advance
						#" " <> last part				;-- should be digit or '#' (mask has it's own separators)
					])
					keep (local c: take-last part)
			|	#" " opt [if (c <> hash) keep (local #" ")]		;-- eat separators before 1st digit (c = hash) 
			|	=emit-literal=
			|	keep skip
			]
		]] .tail/:name
	]
	
	merge-frac: function ["Merge fractional mask" /local] [
		#assert [.head/frac]
		if .head/frac =? .tail/frac [exit]				;-- exit if always empty frac part (00.)
		#assert [find figure! .head/frac/1]				;-- should start with a figure
		#assert [not find .masks/frac #" " ]			;-- mask should be devoid of separators here
		;; insert non-significant zeroes first
		out: tail .out
		frac: .split/frac
		local: :localize-char
		parse/case/part .head/frac [collect into out any [		;-- /case because faster
			digit! keep (local any [take-last frac  #"0"])
		|	hash   keep (local any [take-last frac  hash])		;-- only emit a digit if present (hash -> "")
		|	#" " opt [if (not tail? frac) keep (local #" ")]	;-- emit separators only if digits ahead
		|	=emit-literal=
		|	keep skip
		]] .tail/frac
	]
	
	merge-mask: function [
		"Merge specific mask (dispatch)"
		name [word!] "whole/frac/exp"
	][
		switch name [
			exp [
				merge-whole name
				self/.context: if .currency ['finance]	;-- turn off superscript if it was on
			]
			whole [
				either .got-frac? [merge-whole name][merge-significant]
			]
			frac [merge-frac]
		]
		.tail/:name										;-- return end of mask
	]
		

	;; extracts figures and separators from the mask - into .masks
	analyze-ctx: context [
		p: x: none
		emit: func [c] [append .masks/:.scope c]
		=string=: [#"'" thru #"'"]						;-- just skipped, uninteresting
		=figure=: [
			set x figure! (
				unless .head/:.scope [.head/:.scope: p]	;-- first figure determines scope's head
				.tail/:.scope: next p					;-- last figure determines scope's tail
				emit x
			)
		]
		=currency=: [set .currency some dollar]			;-- used to switch digits & separators to monetary
		=curr-sep=: [
			if (.scope = 'whole) if (.head/whole)		;-- only recognized as separator after whole digits
			=currency=
		]
		=grpsep=: [set x #" " (emit x)]					;-- spaces later serve to extract group size
		=decsep=: [
			set .got-frac? [#"." | =curr-sep=]
			opt [if (.scope <> 'whole) (do make error! rejoin ["Extra decimal separator detected in "mold .mask])]
			; opt [if (.scope <> 'whole) (ERROR "Extra decimal separator detected in (mold .mask)")]
			(
				unless .tail/whole [.head/whole: .tail/whole: p]	;-- define whole part if it wasn't before
				.scope: 'frac
			)
		]
		=exp=: [
			set .got-exp? exponent!
			opt [if (.scope = 'exp) (do make error! rejoin ["Extra exponent detected in "mold .mask])]
			; opt [if (.scope = 'exp) (ERROR "Extra exponent detected in (mold .mask)")]
			(
				unless .tail/whole [.head/whole: .tail/whole: p]	;-- define whole part if it wasn't before
				unless .tail/frac  [.head/frac:  .tail/frac:  p]	;-- define frac part if it wasn't before
				.scope: 'exp
			)
		]
		=sign=: [
			sign! (put .signs either .scope = 'exp ['exp]['whole] yes)	;-- needed to insert sign when unspecified
		]
		=braces=: [brace! (.signs/whole: yes)] 						;-- also needed to insert sign when unspecified
		=percents=: [
			["%o" | permille] opt [if (.multiplier) (do make error! rejoin ["Extra permille marker in "mold .mask])]
			; ["%o" | permille] opt [if (.multiplier) (ERROR "Extra permille marker in (mold .mask)")]
			(.multiplier: 1000)
		|	#"%"              opt [if (.multiplier) (do make error! rejoin ["Extra percent marker in "mold .mask])] 
		; |	#"%"              opt [if (.multiplier) (ERROR "Extra percent marker in (mold .mask)")] 
			(.multiplier: 100)
		]
		
		analyze-mask: func [mask] [
			.scope: 'whole
			parse/case mask [any [
				p: =figure= | =string= | =grpsep= | =decsep= | =exp=
				| =sign= | =braces= | =currency= | =percents= | skip
			]]
			if any [
				not .head/whole
				all [.head/whole =? .tail/whole  .head/frac =? .tail/frac]
			] [do make error! rejoin ["Mask "mold .mask" has no place for digits"]]
			; ] [ERROR "Mask (mold .mask) has no place for digits"]
			if all [.got-exp? .head/exp =? .tail/exp] [
				do make error! rejoin ["Mask "mold .mask" is missing exponent digits"]
				; ERROR "Mask (mold .mask) is missing exponent digits"
			]
			if all [.got-frac? = #"$" .head/frac =? .tail/frac] [
				.got-frac?: none						;-- `$` only works as decimal separator if followed by fraction
			]
		]
	]
		
	;;=======  THE ENTRY POINT  =======
	
	formatting/format-number-with-mask: format-number-with-mask: function [
		"Format a number, using a mask as a template" 
		num  [number! money!]
		mask [string!] {e.g. "# ##0.###"}
		/in locale [word! none!] "Override default locale"
		/extern .mask .scope .got-frac? .got-exp? .context .charmap .out .locale .curr-name .number .base
	][
		num: .number: to float! orig: num				;-- normalize input
		reset
		
		;; select (and prepare) charmap for localization
		.locale: system/locale/tools/expand-locale locale
		.charmap: formatting/update-charmap/for .locale
		#assert [.locale]
		.curr-name: any [
			if money? orig [orig/code]
			if .locale <> 'testing [
				system/locale/list/:.locale/currency
			]
		]

		special: case [
			nan? num ['nan]
			1.#inf = absolute num ['inf]
		]
		
		.out: result: clear ""							;-- copied before returning for less overhead
		
		;; this part is independent from number and depends on mask only
		;; so we try to get analysis result from the cache if possible
		if any [special  not from-cache mask] [
		
			;; fills .masks, sets .head .tail .got-exp? .got-frac? .signs .multiplier .currency 
			analyze-ctx/analyze-mask .mask: mask
			
			;; special floats handled here because we still may want to keep prefix & suffix
			;; and higher level `format` func doesn't know how to keep them
			if special [
				.scope: 'whole  .context: none
				.split/sign: either num > 0 ["+"]["-"]
				merge-part mask .head/whole					;-- emit prefix
				if all [special = 'inf  not .signs/whole] [	;-- emit sign for inf
					append .out .split/sign
				]
				append .out .charmap/default/:special		;-- whole mask is replaced by nan/inf
				mask-end: any [.tail/exp .tail/frac .tail/whole]
				merge-part mask-end tail mask				;-- emit suffix
				return copy result
			]
			
			;; find all group sizes & remove spaces
			.groups/whole: grouping? .masks/whole []
			.groups/exp:   grouping? .masks/exp   []
			trim/all .masks/frac
			
			;; calc .min & .max; check order between 0s and #s
			;;          array  token1 token2  part-name
			get-lengths 'whole hash 'digit! 'whole
			get-lengths 'frac  'digit! hash 'fractional
			get-lengths 'exp   hash 'digit! 'exponent
			
			cache mask
		]
		
		set [rounded: .base: exp:] round-number orig rounding? .masks/exp

		;; split the number into string
		;; fails on 17 digits: round/even/to 0.00263  10.0 * (10 ** -6)  -> 0.0026299999...
		;; fails on 16 digits: round/even/to 1.234E-30 1.0 * (10 ** -30) -> 9.9999999999...
		set .split any [
			if money? rounded [split-money rounded .base]
			formatting/split-float* rounded .base 15 ["" "" "" "" ""]
		]
		
		;; clean formatted parts from extra zeroes
		frac-hashes: skip .split/frac .min/frac
		clear any [										;-- clear trailing 0s from fraction
			find/last/tail frac-hashes digit19!
			frac-hashes
		]
		if all [
			.split/whole = "0"
			.got-frac?									;-- leave 0. in significant mode
			not tail? .split/frac						;-- leave 0. if fraction is also zero
		] [clear .split/whole]
		#assert [
			;; sanity check on the length of whole part derivable from exp & base
			any [
				(length? .split/whole) = (exp - .base + 1)
				not .got-exp?
				num = 0
			]
		]
		
		;; reverse masks in order to use take/last
		;; pad-mask-parts & regroup both assume expansion to the right, hence fraction is reversed after
		reverse .split/whole
		reverse .split/exp
		
		pad-mask-parts									;-- first grow split parts to mask sizes
		either .got-frac? [								;-- then we can regroup them (fill with separators)
			regroup/after 'whole .max/whole
		][
			.groups/frac: .groups/whole					;-- separate groups for fraction aren't supported
			regroup 'frac								;-- so we just mirror whole groups onto fraction
			regroup 'whole								;-- in significant mode we regroup full pattern
		]
		regroup/after 'exp .max/exp
		reverse .split/frac

		;; finally we can emit the mask parts
		.scope: 'whole									;-- tracks what kind of sign we're emitting: exp or mantissa
		.context: if .currency ['finance]				;-- affects digits: normal or monetary
		merge-part .mask .head/whole
		pos: merge-mask 'whole
		if all [.got-frac? .head/frac] [
			merge-part pos .head/frac
			frac: tail result
			pos: merge-mask 'frac
		]
		if all [.got-exp? .head/exp] [
			merge-part pos .head/exp
			pos: merge-mask 'exp
		]
		merge-part pos tail .mask
		copy result
	]
	
	; formatting/update-charmap							;@@ prebuild it for english or not?
]


#localize [#assert [
	;; for testing we use 'testing' locale
	fmt: func [num mask] [formatting/format-number-with-mask/in num mask 'testing]
	

	;; significant digits, decimal
	     "1"         = fmt    1        "0"
	    "10"         = fmt   10        "0"
	    "10"         = fmt   14        "0"
	    "20"         = fmt   19        "0"
	    "20"         = fmt   25        "0"				;-- rounding to even
	    "40"         = fmt   35        "0"
	    "50"         = fmt   35        "5"
	     "0"         = fmt   35        "9"
	    "90"         = fmt   75        "9"
	   "900"         = fmt  753        "9"
	   "100"         = fmt   96        "0"
	    "96"         = fmt   96        "00"
	   "960"         = fmt  965        "00"
	   "965"         = fmt  965        "000"
	   "965.0"       = fmt  965        "0000"
	   "965.00"      = fmt  965        "00000"
	   "965.30"      = fmt  965.3      "00000"
	   "965.34"      = fmt  965.34     "00000"
	   "965.35"      = fmt  965.346    "00000"
	  
	     "1"         = fmt    0.96     "0"
	     "0.3"       = fmt    0.3      "0"				;-- not just ".3" - that only possible in fractional mode
	     "0.3"       = fmt    0.26     "0"
	     "0.03"      = fmt    0.026    "0"
	     "0.003"     = fmt    0.0026   "0"
	     "0.0026"    = fmt    0.0026   "00"
	     "0.0260"    = fmt    0.026    "000"
	     "0.2600"    = fmt    0.26     "0000"
	     "2.600"     = fmt    2.6      "0000"
	    "26.00"      = fmt   26        "0000"
	   "260.0"       = fmt  260        "0000"
	  "2600"         = fmt 2600        "0000"
	   
	     "0"         = fmt    0        "0"
	     "0.0"       = fmt    0        "00"				;-- zero starts with 1 whole digit and switches into fraction
	     "0.00"      = fmt    0        "000"
	     "0.000"     = fmt    0        "0000"
	 
	   "9'6"         = fmt   96        "0 0"
	 "9'6'0"         = fmt  965        "0 0"
	  "9'65"         = fmt  965        "0 00"
	  "9'65.0"       = fmt  965        "00 00"
	  "96'5.0'0"     = fmt  965        "0000 0"
	   "965.00"      = fmt  965        "0 0 000"
	  "9'65.00"      = fmt  965        "00 0 00"
	 "9'6'5.0'0"     = fmt  965        "0 0 0 0 0"
	  "9'65.30"      = fmt  965.3      "000 00"
	  "9'65.34"      = fmt  965.34     "0 00 00"
	  "96'5.3'5"     = fmt  965.346    "00 00 0"
	  
	     "0.0'0'2'6" = fmt    0.0026   "0 0"
	     "0.02'60"   = fmt    0.026    "0 00"
	     "0.0'26'0"  = fmt    0.026    "00 0"
	     "0.0'2'6'0" = fmt    0.026    "0 0 0"
	     "0.26'00"   = fmt    0.26     "00 00"
	     "0.2'60'0"  = fmt    0.26     "0 00 0"
	     "2.60'0"    = fmt    2.6      "00 00"
	   "2'6.0'0"     = fmt   26        "000 0"
	   "2'6.0'0"     = fmt   26        "0 00 0"
	  "2'60.0"       = fmt  260        "00 00"
	"2'60'0"         = fmt 2600        "0 00 0"
	   
	     "0.0"       = fmt    0        "0 0"
	     "0.0'0"     = fmt    0        "00 0"
	     "0.00'0"    = fmt    0        "00 00"
	 
	 
	     "1"         = fmt    1        "#0"
	    "10"         = fmt   10        "#0"
	    "50"         = fmt   35        "#5"
	     "0"         = fmt   35        "#9"
	    "90"         = fmt   75        "###9"
	   "900"         = fmt  753        "###9"
	   "100"         = fmt   96        "###0"
	    "96"         = fmt   96        "###00"
	   "960"         = fmt  965        "###00"
	   "965"         = fmt  965        "###000"
	   "965.0"       = fmt  965        "###0000"
	   "965.00"      = fmt  965        "###00000"
	   "965.30"      = fmt  965.3      "###00000"
	   "965.34"      = fmt  965.34     "###00000"
	   "965.35"      = fmt  965.346    "###00000"
	  
	     "1"         = fmt    0.96     "##0"
	     "0.3"       = fmt    0.26     "##0"
	     "0.03"      = fmt    0.026    "##0"
	     "0.003"     = fmt    0.0026   "##0"
	     "0.0026"    = fmt    0.0026   "##00"
	     "0.0260"    = fmt    0.026    "##000"
	     "0.2600"    = fmt    0.26     "##0000"
	     "2.600"     = fmt    2.6      "##0000"
	    "26.00"      = fmt   26        "##0000"
	   "260.0"       = fmt  260        "##0000"
	  "2600"         = fmt 2600        "##0000"
	   
	     "0"         = fmt    0        "#0"
	     "0.0"       = fmt    0        "#00"			;-- zero starts with 1 whole digit and switches into fraction
	     "0.00"      = fmt    0        "#000"
	     "0.000"     = fmt    0        "#0000"
	 
	   "9'6"         = fmt   96        "#0 0"
	 "9'6'0"         = fmt  965        "# 0 0"
	  "9'65"         = fmt  965        "#0 00"
	  "9'65.0"       = fmt  965        "#00 00"
	  "96'5.0'0"     = fmt  965        "#0000 0"
	  "96'5.0'0"     = fmt  965        "# 0000 0"
	   "965.00"      = fmt  965        "# 00000"
	   "965.0"       = fmt  965        "# 0 000"
	  "9'65.00"      = fmt  965        "##00 0 00"
	  "9'65.0"       = fmt  965        "##0 0 00"
	  "9'65"         = fmt  965        "## 0 00"
	  "9'60"         = fmt  965        "## 00"
	 "9'6'0"         = fmt  965        "# 0 0"
   "1'0'0'0"         = fmt  965        "# # 0"			;-- 1000 is nearer than 900
	 "10'00"         = fmt  965        "# #0"
	  "1000"         = fmt  965        "##0"
	  
	     "0.0'0'3"   = fmt    0.0026   "# 0"
	     "0.00'26"   = fmt    0.0026   "# 00"
	     "0.00'3"    = fmt    0.0026   "# #0"
	     "0.0'02'6"  = fmt    0.0026   "# #0 0"
	     "0.03"      = fmt    0.026    "# #0"
	     "0.0'26"    = fmt    0.026    "#0 0"
	     "0.0'2'6"   = fmt    0.026    "# 0 0"
	   "3'0"         = fmt   26        "### 0"
	   "2'6.0"       = fmt   26        "# 00 0"
	  "2'60"         = fmt  260        "#0 00"
	"2'60'0"         = fmt 2604        "# 00 0"
	   
	     "0.0"       = fmt    0        "#0 0"
	     "0.0'0"     = fmt    0        "#00 0"
	     "0.00'0"    = fmt    0        "#00 00"
	 
	  "1'00'0000'00'000'0" = fmt 1e12     "###0 00 000 0"
	  "1'00'0000'00'000'0" = fmt 1e12     "#### ## #00 0"
	  "10'00'000'00'000'0" = fmt 1e12     "### ## #00 0"
	 "1'00'00'00'00'000'0" = fmt 1e12     "## ## #00 0"
	 
	  "1'23'4000'00'000'0" = fmt 1.234e12 "###0 00 000 0"
	  "1'23'0000'00'000'0" = fmt 1.234e12 "#### ## #00 0"
	  "12'30'000'00'000'0" = fmt 1.234e12 "### ## #00 0"
	 "1'23'00'00'00'000'0" = fmt 1.234e12 "## ## #00 0"
	 
	        "1'2'345'7'00" = fmt 12345678 "000 0 00" 
	      "0.00'1'234'5'7" = fmt 0.0012345678 "000 0 00" 
	      
	      
	 
	 ;; fractional digits, decimal
	     "0.0"      = fmt     0        "0.0"
	     "1.0"      = fmt     1        "0.0"
	     "0.1"      = fmt     0.1      "0.0"
	     "1.2"      = fmt     1.2      "0.0"
	     "1.2"      = fmt     1.24     "0.0"
	     "1.3"      = fmt     1.26     "0.0"
	   
	     "1.000"    = fmt     1        "0.000"
	     "1.200"    = fmt     1.2      "0.000"
	     "1.230"    = fmt     1.23     "0.000"
	     "1.234"    = fmt     1.234    "0.000"
	     "1.235"    = fmt     1.2346   "0.000"
	     "0.235"    = fmt     0.2346   "0.000"
	     "0.035"    = fmt     0.0346   "0.000"
	     "0.005"    = fmt     0.0046   "0.000"
	     "0.001"    = fmt     0.0006   "0.000"
	     "0.000"    = fmt     0.0004   "0.000"
	     "1.000"    = fmt     1        "0.000"
	    "12.000"    = fmt    12        "0.000"
	   "123.000"    = fmt   123        "0.000"
	   "123.400"    = fmt   123.4      "0.000"
	   "123.450"    = fmt   123.45     "0.000"
	   "123.456"    = fmt   123.456    "0.000"
	   "123.457"    = fmt   123.4567   "0.000"
	   "123.400"    = fmt   123.4    "000.000"
	  "0123.400"    = fmt   123.4   "0000.000"
	  "0123"        = fmt   123.4   "0000."
	  "0124"        = fmt   123.6   "0000."
	  "0001"        = fmt     0.6   "0000."
	  "0000"        = fmt     0.4   "0000."
	     "1.0000"   = fmt     1         ".0000"
	    "12.0000"   = fmt    12         ".0000"
	      ".3000"   = fmt     0.3       ".0000"
	      ".0300"   = fmt     0.03      ".0000"
	      ".0305"   = fmt     0.03046   ".0000"
	  
	     "1.0'00"   = fmt     1        "0.0 00"
	     "1.20'0"   = fmt     1.2      "0.00 0"
	     "1.2'3'0"  = fmt     1.23     "0.0 0 0"
	     "1.23'5"   = fmt     1.2346   "0.00 0"
	  "1'23.4'00"   = fmt   123.4   "0 00.0 00"
	 "01'23.40'0"   = fmt   123.4  "00 00.00 0"
	 "0'123"        = fmt   123.4  "0 000."
	"0'12'4"        = fmt   123.6 "0 00 0."
	    "12.0'00'0" = fmt    12         ".0 00 0"
	      ".30'00"  = fmt     0.3       ".00 00"
	  
	    "00.0"      = fmt     0       "00.0"
	   "000.0"      = fmt     0      "000.0"
	  "0000.0"      = fmt     0     "0000.0"
	  "0000.00"     = fmt     0     "0000.00"
	  "0000.000"    = fmt     0     "0000.000"
	  "0000.0000"   = fmt     0     "0000.0000"
	  "0000"        = fmt     0     "0000."
	    "00"        = fmt     0       "00."
	     "0"        = fmt     0        "0."
	      ".0"      = fmt     0         ".0"
	      ".00"     = fmt     0         ".00"
	      ".0000"   = fmt     0         ".0000"
	"0'00'0.00'00"  = fmt     0     "0 00 0.00 00"
	
	
	     "1.0'0"    = fmt     1        "0.0 0#"
	     "1.0"      = fmt     1        "0.0 ##"
	     "1.0"      = fmt     1        "0.0 # #"
	     "1.0"      = fmt     1        "0.0# #"
	     "1.2"      = fmt     1.2      "0.## #"
	     "1.2'3"    = fmt     1.23     "0.# # #"
	     "1.2'3'5"  = fmt     1.2346   "0.# # #"
	     "1.23'5"   = fmt     1.2346   "0.## #"
	  "1'23.4'0"    = fmt   123.4   "# 00.0 0#"
	  "1'23.4"      = fmt   123.4  "#0 00.0# #"
	  "1'23"        = fmt   123.4  "## 00."
	  "12'4"        = fmt   123.6 "# ## 0."
	    "12.0'0"    = fmt    12         ".0 0# #"
	      ".34'567" = fmt     0.345673  ".00 ###"
	  
	  "1'00'0000'00'000'0" = fmt 1e12     "#### ## #00 0.# ## ###"
	  "00'0"               = fmt 1e-12    "#### ## #00 0.# ## ###"
	  "00'0.0'01'234"      = fmt 12345e-7 "#### ## #00 0.# ## ###"
	
	
	
	;; E exponent
	
	       "1E0"     = fmt    1        "0E0"
	       "1E1"     = fmt   10        "0E0"
	       "1E1"     = fmt   14        "0E0"
	       "2E1"     = fmt   19        "0E0"
	       "2E1"     = fmt   25        "0E0"			;-- rounding to even
	       "4E1"     = fmt   35        "0E0"
	       "5E1"     = fmt   35        "5E0"
	       "0E1"     = fmt   35        "9E0"
	       "9E1"     = fmt   75        "9E0"
	       "9E2"     = fmt  753        "9E0"
	       "1E2"     = fmt   96        "0E0"
	     "9.6E1"     = fmt   96        "00E0"
	     "9.6E2"     = fmt  965        "00E0"
	    "9.65E2"     = fmt  965        "000E0"
	   "9.650E2"     = fmt  965        "0000E0"
	   "9.653E2"     = fmt  965.3      "0000E0"
	   "9.654E2"     = fmt  965.36     "0000E0"
	   
	       "1E0"     = fmt    0.96     "0E0"
	       "3E-1"    = fmt    0.3      "0E0"
	       "3E-1"    = fmt    0.26     "0E0"
	       "3E-2"    = fmt    0.026    "0E0"
	     "2.6E-3"    = fmt    0.0026   "00E0"
	    "2.60E-2"    = fmt    0.026    "000E0"
	   "2.600E-1"    = fmt    0.26     "0000E0"
	   "2.600E0"     = fmt    2.6      "0000E0"
	   
	       "0E0"     = fmt    0        "0E0"
	     "0.0E0"     = fmt    0        "00E0"
	    "0.00E0"     = fmt    0        "000E0"
	   "0.000E0"     = fmt    0        "0000E0"
	   
	     "9.6E1"     = fmt   96        "0 0E0"
	   "9.6'5E2"     = fmt  965        "00 0E0"
	   "9.6'5E2"     = fmt  965        "0 0 0E0"
	  "9.6'50E2"     = fmt  965        "#000 0E0"
	  "9.6'50E2"     = fmt  965        "#0 00 0E0"
	
	 "9.65'00E2"     = fmt  965        "000 00E1"
	"9.6'50'0E2"     = fmt  965        "00 00 0E2"
	 "9'65.00E0"     = fmt  965        "000 00E3"		;-- exp is rounded down only
	"96'5.0'0E0"     = fmt  965        "0000 0E4"
	"96'5.0'0E0"     = fmt  965        "0000 0E5"
	"96'5.3'5E0"     = fmt  965.346    "0000 0E5"
  "9'6'5'000'0'00E0" = fmt  965E6      "000 0 00E9"
	  
	     "2.6E-3"    = fmt    0.0026   "0 0E0"
	     "2'6E-4"    = fmt    0.0026   "0 0E4"
	   "2'6'0E-5"    = fmt    0.0026   "0 0E5"
	   "2'6'0E-5"    = fmt    0.00263  "0 0E5"
	    "26'3E-5"    = fmt    0.00263  "00 0E5"
	  "2'63'0E-6"    = fmt    0.00263  "00 0E6"
	   
	     "0.0E0"     = fmt    0        "0 0E0"
	   "0.0'0E0"     = fmt    0        "00 0E0"
	  "0.00'0E0"     = fmt    0        "00 00E0"
	 
	 
	       "1E1"     = fmt   10        "#0E0"
	       "5E1"     = fmt   35        "#5E0"
	       "0E1"     = fmt   35        "#9E0"			;-- exp persists thru rounding to 0
	 "9.650'0E2"     = fmt  965        "###00 000E0"
	  
	        "1.0'000'00E12" = fmt 1e12  "###0 00 000 0E0"
	        "10'0.0'000E10" = fmt 1e12  "###0 00 000 0E5"
	"1'00'0000'00'000'0E00" = fmt 1e12  "###0 00 000 0E13"	;-- E00 because of 13 rounding
	
	
	     "0.0E0"     = fmt    0        "0.0E0"
	     "1.0E0"     = fmt    1        "0.0E0"
	     "1.3E0"     = fmt    1.26     "0.0E0"
	 "001.000E0"     = fmt    1        "000.000E0"
	 "001.000E0"     = fmt    1        "000.000E3"
	 "001.000E2"     = fmt    1e2      "000.000E0"	;-- such mask will always have 2 leading zeroes
	 "100.000E0"     = fmt    1e2      "000.000E5"
	 "100.000E0"     = fmt    1e2      "#00.000E5"
	     "120E0"     = fmt  1.2e2      "##0.###E5"	;-- fraction present => round to last digit of it
	   "120.0E0"     = fmt  1.2e2      "###.0##E5"
	 "123.457E0"     = fmt  1.234567e2 "###.0##E5"
	   "120.0E5"     = fmt  1.2e7      "###.0##E5"
	 "123.457E5"     = fmt  1.234567e7 "###.0##E5"
	       
	 "001E-21"       = fmt  1.234E-21  "000.E3"
	 "001E-24"       = fmt  1.234E-24  "000.E3"
	 "001E-27"       = fmt  1.234E-27  "000.E3"
	 "001E-30"       = fmt  1.234E-30  "000.E3"
	 "001E-33"       = fmt  1.234E-33  "000.E3"
	 "001E-36"       = fmt  1.234E-36  "000.E3"
	 "001E-39"       = fmt  1.234E-39  "000.E3"
	 "001E-42"       = fmt  1.234E-42  "000.E3"
	 "001E-300"      = fmt  1.234E-300 "000.E3"
	 "001E-303"      = fmt  1.234E-303 "000.E3"
	 
	 "123E0"         = fmt 123.4567    "001E3"
	 "123E0"         = fmt 123.4567    "001.E3"			;-- check that empty fraction does not increase rounding
	 
	 "123.0E0"       = fmt 123.4567    "001.0E3"		;-- check that rounding does not mess up zeroes
	 "123.00E0"      = fmt 123.4567    "001.00E3"
	 "123.000E0"     = fmt 123.4567    "001.000E3"
	 "123.457E0"     = fmt 123.4567    "000.001E3"
	 "123.457E0"     = fmt 123.4567    "000.000E3"
	 
	;; x
	            "100.000×10⁰"   = fmt         1e2  "#00.000x5"
	            "123.457×10⁰"   = fmt  1.234567e2  "###.0##x5"
	            "123.457×10⁵"   = fmt  1.234567e7  "###.0##x5"
	 "1'00'0000'00'000'0×10⁰⁰"  = fmt         1e12 "###0 00 000 0x13"	;-- E00 because of 13 rounding
	"1'00'0000'00'000'0 × 10⁰⁰" = fmt         1e12 "###0 00 000 0 x 13"
	        "10'0.0'000 × 10¹⁰" = fmt         1e12 "###0 00 000 0 x 10"
	
	;; default sign
	
	 "-1'23'00'00'00'000'0"  = fmt -1.234e12     "## ## #00 0"
	 "-1'2'345'7'00"         = fmt -12345678     "000 0 00" 
	      "-.0305"           = fmt -0.03046      ".0000"
	     "-0.00'1'234'5'7"   = fmt -0.0012345678 "000 0 00" 
	  "-00'0.0'01'234"       = fmt -12345e-7     "#### ## #00 0.# ## ###"
	      
	     "-2.60E-2"          = fmt -0.026        "000E0"
	     "-1.0'000'00E12"    = fmt -1e12         "###0 00 000 0E0"
	   "-123.457E-5"         = fmt -1.234567e-3  "###.0##E5"
	   "-123.457×10⁻⁵"       = fmt -1.234567e-3  "###.0##x5"
	  "-123.457 × 10⁻⁵"      = fmt -1.234567e-3  "###.0## x 5"
	   
	;; sign: +
	
	 "+1'23'00'00'00'000'0"  = fmt  1.234e12     "+## ## #00 0"
	 "-1'23'00'00'00'000'0"  = fmt -1.234e12     "+## ## #00 0"
	 "+1'23'00'00'00'000'0+" = fmt  1.234e12     "+## ## #00 0+"
	 "-1'23'00'00'00'000'0-" = fmt -1.234e12     "+## ## #00 0+"
	 "+1'2'345'7'00"         = fmt  12345678     "+000 0 00" 
	 "-1'2'345'7'00"         = fmt -12345678     "+000 0 00" 
	      "+.0305"           = fmt  0.03046      "+.0000"
	      "+.0305+"          = fmt  0.03046      "+.0000+"
	      "-.0305"           = fmt -0.03046      "+.0000"
	      "-.0305-"          = fmt -0.03046      "+.0000+"
	     "+0.00'1'234'5'7"   = fmt  0.0012345678 "+000 0 00" 
	     "-0.00'1'234'5'7"   = fmt -0.0012345678 "+000 0 00" 
	  "+00'0.0'01'234"       = fmt  12345e-7     "+#### ## #00 0.# ## ###"
	  "-00'0.0'01'234"       = fmt -12345e-7     "+#### ## #00 0.# ## ###"
	  "-00'0.0'01'234-"      = fmt -12345e-7     "+#### ## #00 0.# ## ###+"
	   "00'0.0'01'234-"      = fmt -12345e-7      "#### ## #00 0.# ## ###+"
	      
	      "2.60E-2"          = fmt  0.026        "000E+0"
	     "+2.60E-2-"         = fmt  0.026       "+000E+0+"		;-- signs after 'E' belong to exponent scope
	     "-2.60E-2"          = fmt -0.026       "+000E+0"
	     "-2.60E-2-"         = fmt -0.026       "+000E+0+"
	      "1.0'000'00E+12"   = fmt  1e12         "###0 00 000 0E+0"
	     "+1.0'000'00E+12"   = fmt  1e12        "+###0 00 000 0E+0"
	     "-1.0'000'00E+12"   = fmt -1e12        "+###0 00 000 0E+0"
	    "- 1.0'000'00E+12"   = fmt -1e12       "+ ###0 00 000 0E+0"
	   "+123.457E5"          = fmt  1.234567e7  "+###.0##E5"
	   "+123.457E+5"         = fmt  1.234567e7  "+###.0##E+5"
	   "+123.457×10⁺⁵"       = fmt  1.234567e7  "+###.0##x+5"
	   "-123.457×10⁺⁵"       = fmt -1.234567e7  "+###.0##x+5"
	  "+ 123.457×10⁻⁵"       = fmt  1.234567e-3 "+ ###.0##x+5"
	  "- 123.457×10⁻⁵"       = fmt -1.234567e-3 "+ ###.0##x+5"
	            
	      "+.0000"           = fmt 0            "+.0000"		;@@ should there be -0.0 too or we don't want such detail?
	"+0'00'0.00'00"          = fmt 0            "+0 00 0.00 00"
	     "+0.000"            = fmt 0            "+#0000"
	     "+0.000E+0"         = fmt 0            "+0000E+0"
	     
	;; sign: -
	
	  "1'23'00'00'00'000'0"  = fmt  1.234e12     "-## ## #00 0"
	 "-1'23'00'00'00'000'0"  = fmt -1.234e12     "-## ## #00 0"
	  "1'23'00'00'00'000'0"  = fmt  1.234e12     "-## ## #00 0-"
	 "-1'23'00'00'00'000'0-" = fmt -1.234e12     "-## ## #00 0-"
	  "1'2'345'7'00"         = fmt  12345678     "-000 0 00" 
	 "-1'2'345'7'00"         = fmt -12345678     "-000 0 00" 
	       ".0305"           = fmt  0.03046      "-.0000"
	       ".0305"           = fmt  0.03046      "-.0000-"
	       ".0305+"          = fmt  0.03046      "-.0000+"
	      "-.0305"           = fmt -0.03046      "-.0000"
	      "-.0305-"          = fmt -0.03046      "-.0000-"
	      "-.0305-"          = fmt -0.03046      "-.0000+"
	      "0.00'1'234'5'7"   = fmt  0.0012345678 "-000 0 00" 
	     "-0.00'1'234'5'7"   = fmt -0.0012345678 "-000 0 00" 
	   "00'0.0'01'234"       = fmt  12345e-7     "-#### ## #00 0.# ## ###"
	  "-00'0.0'01'234"       = fmt -12345e-7     "-#### ## #00 0.# ## ###"
	  "-00'0.0'01'234-"      = fmt -12345e-7     "-#### ## #00 0.# ## ###-"
	   "00'0.0'01'234-"      = fmt -12345e-7      "#### ## #00 0.# ## ###-"
	      
	      "2.60E-2"          = fmt  0.026        "000E-0"
	      "2.60E-2-"         = fmt  0.026       "-000E-0-"		;-- signs after 'E' belong to exponent scope
	     "-2.60E-2"          = fmt -0.026       "-000E-0"
	     "-2.60E-2-"         = fmt -0.026       "-000E-0-"
	      "1.0'000'00E12"    = fmt  1e12         "###0 00 000 0E-0"
	      "1.0'000'00E12"    = fmt  1e12        "-###0 00 000 0E-0"
	     "-1.0'000'00E12"    = fmt -1e12        "-###0 00 000 0E-0"
	    "- 1.0'000'00E12"    = fmt -1e12       "- ###0 00 000 0E-0"
	    "123.457E5"          = fmt  1.234567e7  "-###.0##E5"
	    "123.457E5"          = fmt  1.234567e7  "-###.0##E-5"
	    "123.457×10⁵"        = fmt  1.234567e7  "-###.0##x-5"
	   "-123.457×10⁵"        = fmt -1.234567e7  "-###.0##x-5"
	   " 123.457×10⁻⁵"       = fmt  1.234567e-3 "- ###.0##x-5"
	  "- 123.457×10⁻⁵"       = fmt -1.234567e-3 "- ###.0##x-5"
	            
	       ".0000"           = fmt 0            "-.0000"		;@@ should there be -0.0 too or we don't want such detail?
	 "0'00'0.00'00"          = fmt 0            "-0 00 0.00 00"
	      "0.000"            = fmt 0            "-#0000"
	      "0.000E+0"         = fmt 0            "-0000E+0"
	
	;; ()
	
	  "1'23'00'00'00'000'0"  = fmt  1.234e12      "(## ## #00 0)"
	 "(1'23'00'00'00'000'0)" = fmt -1.234e12      "(## ## #00 0)"
	  "1'23'00'00'00'000'0"  = fmt  1.234e12     "-(## ## #00 0)-"
	"-(1'23'00'00'00'000'0)-"= fmt -1.234e12     "-(## ## #00 0)-"
	  "1'2'345'7'00"         = fmt  12345678      "(000 0 00)" 
	 "(1'2'345'7'00)"        = fmt -12345678      "(000 0 00)" 
	       ".0305"           = fmt  0.03046      "(.0000)"
	       ".0305"           = fmt  0.03046      "(.0000-)"
	       ".0305+"          = fmt  0.03046      "(.0000+)"
	      "(.0305)"          = fmt -0.03046      "(.0000)"
	      "(.0305-)"         = fmt -0.03046      "(.0000-)"
	      "(.0305-)"         = fmt -0.03046      "(.0000+)"
	      "0.00'1'234'5'7"   = fmt  0.0012345678 "(000 0 00)" 
	     "(0.00'1'234'5'7)"  = fmt -0.0012345678 "(000 0 00)" 
	   "00'0.0'01'234"       = fmt  12345e-7    "-(#### ## #00 0.# ## ###)"
	 "-(00'0.0'01'234)"      = fmt -12345e-7    "-(#### ## #00 0.# ## ###)"
	  "(00'0.0'01'234)"      = fmt -12345e-7     "(#### ## #00 0.# ## ###)"
	  "(00'0.0'01'234)-"     = fmt -12345e-7     "(#### ## #00 0.# ## ###)-"
	      
	 "(- 123.457×10⁻⁵ )"     = fmt -1.234567e-3  "(- ###.0##x-5 )"
	 "(- 123.457× 10⁻⁵)"     = fmt -1.234567e-3  "(- ###.0##x -5)"
	            
	       ".0000"           = fmt 0             "(.0000)"
	      
	;; %
	
	      "3.0%"              = fmt 0.03         "00%"
	     "03%"                = fmt 0.03         "00.%"
	     "30%"                = fmt 0.3          "00.%"
	   "1234.6%"              = fmt 12.3456       "0.0%"
	   "1234.5000%"           = fmt 12.345         ".0000%"
	       ".0000%"           = fmt 0             "(.0000)%"
	       ".0000%"           = fmt 0             "(.0000%)"
	      "1.2E6%"            = fmt 12345         "0.0E0%"
	       
	;; %o
	
	      "30‰"               = fmt 0.03         "00%o"
	     "03‰"                = fmt 0.003        "00.%o"
	    "300‰"                = fmt 0.3          "00.%o"
	   "1234.6‰"              = fmt 1.23456       "0.0%o"
	   "1234.5000‰"           = fmt 1.2345         ".0000%o"
	      "1.2E7‰"            = fmt 12345         "0.0E0%o"
	     "-1.2E-1‰"           = fmt -0.000123    "-0.0E0%o"
	      
	;; '
	
	 "12#3.457E5"    = fmt  1.234567e7   "#'#'#.0##E5"
	 "1'2'3'__4.6."  = fmt  1234.567   "# '__'0.0'.'"
	 "1'2'3__'4.6."  = fmt  1234.567   "#'__' 0.0'.'"
	    "123__4.6."  = fmt  1234.567    "#'__'0.0'.'"
	 
	;; unused chars passthru
	
	 "~12~3.457E5"   = fmt  1.234567e7    "~#~#.0##E5"
	 "1'2'3]'[4.6:"  = fmt  1234.567     "#] [0.0:"
	"1'2'3'[]'4.6!"  = fmt  1234.567    "# [] 0.0!"
	    "123[]4.6eX" = fmt  1234.567      "#[]0.0eX"
	 
	;; arbitrary padding
	
	   "  12'''34 . 6 "  = fmt  1234.567    "  #  00   00 . 0 "
	"  0''12'''34 . 6 "  = fmt  1234.567    "  0  00   00 . 0 "
	
	;; currency
	
	  "¥𝟙𝟚𝟛,𝟜𝟝𝟟"          = fmt   123.4567     "$0.000"
	   "𝟙𝟚𝟛,𝟜𝟝𝟟¥"         = fmt   123.4567      "0.000$"
	   "𝟙𝟚𝟛¥𝟜𝟝𝟟"          = fmt   123.4567      "0$000"
	 "𝟙𝟚𝟛CN¥𝟜𝟝𝟟"          = fmt   123.4567      "0$$000"
	   "𝟙𝟚𝟛,𝟜𝟝𝟟 CNY"      = fmt   123.4567      "0.000 $$$"
	 "¥ 𝟙𝟚𝟛,𝟜𝟝𝟟 CNY CN¥"  = fmt   123.4567    "$ 0.000 $$$ $$"
	"¥ 𝟙.𝟚𝟛,𝟜.𝟝𝟟 CNY CN¥" = fmt   123.4567 "$ # #0.0 00 $$$ $$"
	   "𝟙𝟚𝟘¥"                = fmt   123.4567      "00$"		;-- shouldn't treat $ as decimal separator here
	
	;; special floats
	"<< NaN >>"   = fmt  1.#nan "<< #0.00E+0 >>"
	"<< +INF >>"  = fmt  1.#inf "<< #0.00E+0 >>"
	"<< -INF >>"  = fmt -1.#inf "<< #0.00E+0 >>"
	
	;; some tricky rounding cases
	"1E4" = fmt 9.6E3 "0E0"								;-- not "10E3" !
	"0E3" = fmt   1E3 "5E3"								;-- not 1000E0 nor 0E0 !
			
	;; money!
	;; testing locale is limited and can't handle it
	fmt: func [num mask] [formatting/format-number-with-mask/in num mask 'en]
	
	           "€ 1,23.4560"       = fmt               EUR$123.456      "$ # #0.0000"
	           "€00123.4560"       = fmt               EUR$123.456      "$00000.0000"
	              "123€46"         = fmt               EUR$123.456           "0$00"
	            "00123.4560 €"     = fmt               EUR$123.456       "00000.0000 $$"
	            "00123.4560 EUR"   = fmt               EUR$123.456       "00000.0000 $$$"
	            ; "00123.4560 euros" = fmt               EUR$123.456       "00000.0000 $$$$"	;-- removed per team decision
	"12345678901234567.89012 EUR"  = fmt EUR$12345678901234567.89012     "00000.00000 $$$"
	"12345678901234568 EUR"        = fmt EUR$12345678901234567.89012         "0. $$$"
	"12,345,678,901,234,568 EUR"   = fmt EUR$12345678901234567.89012 "0 000 000. $$$"
	"12,345,680,000,000,000 EUR"   = fmt EUR$12345678901234567.89012 "0 000 000 $$$"
	
	                "1.2E2"        = fmt               EUR$123.456           "0.0E0"
	                "1.2E-3"       = fmt               EUR$0.00123           "0.0E0"
	              "123.5E0"        = fmt               EUR$123.456           "0.0E3"
	
	;@@ these have rounding issues due to #5002 and fall back to floats:
	"12345678901234600.0000 EUR"   = fmt EUR$12345678901234567.89012     "00000.0000 $$$"
	"12345678901234600.00 EUR"     = fmt EUR$12345678901234567.89012         "0.50 $$$"
	"12345678901234600.0 EUR"      = fmt EUR$12345678901234567.89012         "0.5 $$$"
	
	;; quotation rules
	"12E3"     = fmt 123 "0'E'0."
	"12'3"     = fmt 123 "0''0."
	"12'3"     = fmt 123 "0''''0."
	"12E'03"   = fmt 123 "0'E''0'0."
	"12'E'03"  = fmt 123 "0'''E''0'0."
	"12'E'0'3" = fmt 123 "0'''E''0'''0."

]] 

; prof/each/times [
    ; formatting/format-number-with-mask  100  "0."
    ; formatting/format-number-with-mask  -1e12       "- ###0 00 000 0E-0"
; ] 10000
