Red/System [
	Title:   "Red values low-level lexer"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		See %docs/lexer/ for FSM descriptions.
		See %utils/generate-lexer-table.red for include file generation.
		See %utils/generate-misc-tables.red for various tables and bit-arrays generation.
	}
]

#define GET_BLOCK_TYPE(p) (p/y and FFFFh)

lexer: context [
	verbose: 0

	#include %lexer-transitions.reds
		
	#enum class-flags! [
		C_FLAG_UCS4:	80000000h						;-- at least one UCS-4 char detected
		C_FLAG_UCS2:	40000000h						;-- at least one UCS-2 char detected
		C_FLAG_CARET:	20000000h
		C_FLAG_DOT:		10000000h
		C_FLAG_COMMA:	08000000h
		C_FLAG_COLON:	04000000h
		C_FLAG_QUOTE:	02000000h
		C_FLAG_EXP:		01000000h
		C_FLAG_SHARP:	00800000h
		C_FLAG_EOF:		00400000h
		C_FLAG_SIGN:	00200000h
		C_FLAG_LESSER:	00100000h
		C_FLAG_GREATER: 00080000h
		C_FLAG_PERCENT: 00040000h
		C_FLAG_NEWLINE: 00020000h
	]
	
	#define FL_UCS4		[(C_WORD or C_FLAG_UCS4)]
	#define FL_UCS2		[(C_WORD or C_FLAG_UCS2)]

	#enum character-classes! [
		C_BLANK											;-- 0
		C_LINE											;-- 1
		C_DIGIT											;-- 2
		C_ZERO											;-- 3
		C_BLOCK_OP										;-- 4
		C_BLOCK_CL										;-- 5
		C_PAREN_OP										;-- 6
		C_PAREN_CL										;-- 7
		C_STRING_OP										;-- 8
		C_STRING_CL										;-- 9
		C_DBL_QUOTE										;-- 10
		C_SHARP											;-- 11
		C_QUOTE											;-- 12
		C_COLON											;-- 13
		C_X												;-- 14
		C_T												;-- 15
		C_H												;-- 16
		C_E_LOW											;-- 17
		C_E_UP											;-- 18
		C_ALPHAL										;-- 19
		C_ALPHAU										;-- 20
		C_SLASH											;-- 21
		C_BSLASH										;-- 22
		C_LESSER										;-- 23
		C_GREATER										;-- 24
		C_EQUAL											;-- 25
		C_PERCENT										;-- 26
		C_COMMA											;-- 27
		C_SEMICOL										;-- 28
		C_AT											;-- 29
		C_DOT											;-- 30
		C_MONEY											;-- 31
		C_PLUS											;-- 32
		C_MINUS											;-- 33
		C_CARET											;-- 34
		C_C0											;-- 35
		C_BIN											;-- 36
		C_WORD											;-- 37
		C_ILLEGAL										;-- 38
		C_EOF											;-- 39
	]
		
	#enum bin16-char-classes! [
		C_BIN_ILLEGAL									;-- 0
		C_BIN_BLANK										;-- 1
		C_BIN_HEXA										;-- 2
		C_BIN_CMT										;-- 3
	]
	
	#enum float-char-classes! [
		C_FL_ILLEGAL									;-- 0
		C_FL_SIGN										;-- 1
		C_FL_DIGIT										;-- 2
		C_FL_EXP										;-- 3
		C_FL_DOT										;-- 4
		C_FL_QUOTE										;-- 5
		C_FL_EOF										;-- 6
	]

	line-table: #{
		0001000000000000000000000000000000000000000000000000000000000000
		0000000000000000
	}
	
	path-ending: #{
		0101000001010101010001000001000000000000000000010000000001000000
		0000000000010101
	}
	
	float-classes: #{
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000005000000010001040002020202020202020202000000000000
		0000000000030000000000000000000000000000000000000000000000000000
		00000000000300
	}
	
	bin16-classes: #{
		0000000000000000000101000001000000000000000000000000000000000000
		0100000000000000000000000000000002020202020202020202000300000000
		0002020202020200000000000000000000000000000000000000000000000000
		0002020202020200000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
	}
	
	hexa-table: #{
		FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00010203040506070809FFFFFFFFFFFF
		FF0A0B0C0D0E0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		FF0A0B0C0D0E0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	}
	
	float-transitions: #{
		07000107020707
		07070103020106
		07070203070206
		07040507070707
		07070507070707
		07070507070706
		06060606060606
		07070707070707
	}
	
	;-- Bit-array for /-~^{}"
	char-special: #{0000000004A00000010000400000006800000000000000000000000000000000}
	
	escape-names: [
		"null"	4	00h
		"back"	4	08h
		"tab" 	3	09h
		"line"	4	0Ah
		"page"	4	0Ch
		"esc" 	3	1Bh
		"del" 	3	7Fh
	]
	
	cons-syntax: [
	;--- word - type ----- value -- length --
		"true"	TYPE_LOGIC true		4
		"false"	TYPE_LOGIC false	5
		"none"	TYPE_NONE  0		4
		"unset" TYPE_UNSET 0		5
	]
	
	whitespaces: [
		; https://en.wikipedia.org/wiki/Whitespace_character
		; (ASCII whitespaces are already taken care of in the lexer state machine)
		0085h											;-- NEXT LINE
		00A0h											;-- NO-BREAK SPACE
		1680h											;-- OGHAM SPACE MARK
		2000h											;-- EN QUAD
		2001h											;-- EM QUAD
		2002h											;-- EN SPACE
		2003h											;-- EM SPACE
		2004h											;-- THREE-PER-EM SPACE
		2005h											;-- FOUR-PER-EM SPACE
		2006h											;-- SIX-PER-EM SPACE
		2007h											;-- FIGURE SPACE
		2008h											;-- PUNCTATION SPACE
		2009h											;-- THIN SPACE
		200Ah											;-- HAIR SPACE
		2028h											;-- LINE SEPARATOR
		2029h											;-- PARAGRAPH SEPARATOR
		202Fh											;-- NARROW NO-BREAK SPACE
		205Fh											;-- MEDIUM MATHEMATICAL SPACE
		3000h											;-- IDEOGRAPHIC SPACE
		180Eh											;-- MONGOLIAN VOWEL SEPARATOR
		200Bh											;-- ZERO WIDTH SPACE
		200Ch											;-- ZERO WIDTH NON-JOINER
		200Dh											;-- ZERO WIDTH JOINER
		2060h											;-- WORD JOINER
	]
	
	months: [
		"January" "February" "March" "April" "May" "June" "July"
		"August" "September" "October" "November" "December"
	]
	
	days-max: #{1F1D1F1E1F1E1F1F1E1F1E1F}

	lex-classes: [
		(C_EOF or C_FLAG_EOF)							;-- 00		NUL
		C_C0 C_C0 C_C0 C_C0 C_C0 C_C0 C_C0 C_C0			;-- 01-08
		C_BLANK											;-- 09		TAB
		C_LINE 											;-- 0A		LF
		C_C0											;-- 0B
		C_C0											;-- 0C
		C_BLANK											;-- 0D		CR
		C_C0 C_C0 C_C0 C_C0 C_C0 C_C0 C_C0 C_C0			;-- 0E-15
		C_C0 C_C0 C_C0 C_C0 C_C0 C_C0 C_C0 C_C0			;-- 16-1D
		C_C0 C_C0										;-- 1E-1F
		C_BLANK											;-- 20
		C_WORD											;-- 21		!
		C_DBL_QUOTE										;-- 22		"
		(C_SHARP or C_FLAG_SHARP)						;-- 23		#
		C_MONEY											;-- 24		$
		(C_PERCENT or C_FLAG_PERCENT)					;-- 25		%
		C_WORD											;-- 26		&
		(C_QUOTE or C_FLAG_QUOTE)						;-- 27		'
		C_PAREN_OP										;-- 28		(
		C_PAREN_CL										;-- 29		)
		C_WORD											;-- 2A		*
		(C_PLUS	or C_FLAG_SIGN)							;-- 2B		+
		(C_COMMA or C_FLAG_COMMA)						;-- 2C		,
		(C_MINUS or C_FLAG_SIGN)						;-- 2D		-
		(C_DOT or C_FLAG_DOT)							;-- 2E		.
		C_SLASH											;-- 2F		/
		C_ZERO											;-- 30		0
		C_DIGIT C_DIGIT C_DIGIT C_DIGIT C_DIGIT			;-- 31-35	1-5
		C_DIGIT C_DIGIT C_DIGIT C_DIGIT					;-- 36-39	6-9
		(C_COLON or C_FLAG_COLON)						;-- 3A		:
		C_SEMICOL										;-- 3B		;
		(C_LESSER or C_FLAG_LESSER)						;-- 3C		<
		C_EQUAL											;-- 3D		=
		(C_GREATER or C_FLAG_GREATER)					;-- 3E		>
		C_WORD											;-- 3F		?
		C_AT											;-- 40		@
		C_ALPHAU C_ALPHAU C_ALPHAU C_ALPHAU			 	;-- 41-44	A-D
		(C_E_UP or C_FLAG_EXP)							;-- 45		E
		C_ALPHAU										;-- 46		F
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 47-4C	G-L
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 4D-52	M-R
		C_WORD											;-- 53		S
		C_T												;-- 54		T
		C_WORD C_WORD C_WORD			 				;-- 55-57	U-W
		C_X												;-- 58		X
		C_WORD C_WORD							 		;-- 59-5A	Y-Z
		C_BLOCK_OP										;-- 5B		[
		C_BSLASH										;-- 5C		\
		C_BLOCK_CL										;-- 5D		]
		(C_CARET or C_FLAG_CARET)						;-- 5E		^
		C_WORD											;-- 5F		_
		C_WORD											;-- 60		`
		C_ALPHAL C_ALPHAL C_ALPHAL C_ALPHAL			 	;-- 61-64	a-d
		(C_E_LOW or C_FLAG_EXP)							;-- 65		e
		C_ALPHAL										;-- 66		f
		C_WORD											;-- 67		g
		C_H												;-- 68		h
		C_WORD C_WORD C_WORD C_WORD 					;-- 69-6C	i-l
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 6D-72	m-r
		C_WORD C_WORD C_WORD C_WORD C_WORD 				;-- 73-77	s-w
		C_X												;-- 78		x
		C_WORD C_WORD							 		;-- 79-7A	y-z
		C_STRING_OP										;-- 7B		{
		C_WORD											;-- 7C		|
		C_STRING_CL										;-- 7D		}
		C_WORD											;-- 7E		~
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- 7F-86
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- 87-8E
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- 8F-96
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- 97-9E
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- 9F-A6
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- A7-AE
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- AF-B6
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN ;-- B7-BE
		C_BIN											;-- BF
		C_ILLEGAL C_ILLEGAL								;-- C0-C1
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 ;-- C2-C7
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 ;-- C8-CD
		FL_UCS2 FL_UCS2	FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 ;-- CE-D3
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 ;-- D4-D9
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2	FL_UCS2 FL_UCS2 ;-- DA-DF
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2	FL_UCS2 ;-- E0-E5
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2 ;-- E6-EB
		FL_UCS2 FL_UCS2 FL_UCS2 FL_UCS2					;-- EC-EF
		FL_UCS4 FL_UCS4 FL_UCS4							;-- F0-F2
		FL_UCS4 FL_UCS4 FL_UCS4 FL_UCS4 FL_UCS4			;-- F3-F7
		C_ILLEGAL C_ILLEGAL C_ILLEGAL C_ILLEGAL 		;-- F8-FB
		C_ILLEGAL C_ILLEGAL C_ILLEGAL C_ILLEGAL 		;-- FC-FF
	]
	
	#enum errors! [
		ERR_BAD_CHAR: 	  -1
		ERR_MALCONSTRUCT: -2
		ERR_MISSING: 	  -3
		ERR_CLOSING: 	  -4
		LEX_INT_OVERFLOW: -5
		LEX_ERR:		  10
	]
	
	#enum events! [
		EVT_PRESCAN:	1
		EVT_SCAN:		2
		EVT_LOAD:		4
		EVT_OPEN:		8
		EVT_CLOSE:		16
		EVT_ERROR:		32
	]
	
	state!: alias struct! [
		next		[state!]							;-- link to next state! structure (recursive calls)
		back		[state!]							;-- link to previous state! structure (recursive calls)
		buffer		[red-value!]						;-- static or dynamic stash buffer (recursive calls)
		head		[red-value!]
		tail		[red-value!]
		input		[byte-ptr!]							;-- input starting
		in-end		[byte-ptr!]							;-- input ending
		in-pos		[byte-ptr!]							;-- current input position
		tok-end		[byte-ptr!]							;-- token ending position
		line		[integer!]							;-- current line number
		nline		[integer!]							;-- new lines count for new token
		type		[integer!]							;-- sub-type in a typeclass
		scanned		[integer!]							;-- type of first scanned value
		entry		[integer!]							;-- entry state for the FSM
		prev		[integer!]							;-- previous state before forced EOF transition
		closing		[integer!]							;-- any-block! expected closing delimiter type 
		last		[integer!]							;-- last scanned value
		mstr-s		[byte-ptr!]							;-- multiline string saved start position
		mstr-nest	[integer!]							;-- multiline string nested {} counting
		mstr-flags	[integer!]							;-- multiline string accumulated flags
		fun-ptr		[red-function!]						;-- callback function pointer or NULL
		fun-locs	[integer!]							;-- number of local words in callback function
		fun-evts	[integer!]							;-- bitmap of allowed events
		in-series	[red-series!]						;-- optional back reference to input series
		value		[integer!]							;-- decoded integer! or char! value (from scanner to loader)
		load?		[logic!]							;-- TRUE: load values, else scan only
		pos-cache	[byte-ptr!]							;-- cached UTF-8 buffer last accessed position
		cnt-cache	[integer!]							;-- cached UTF-8 characters count
	]
	
	scanner!: alias function! [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]]
	loader!:  alias function! [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]]

	utf8-buf-size:	100'000
	utf8-buffer:	as byte-ptr! 0
	utf8-buf-tail:	as byte-ptr! 0
	scanners:		as int-ptr! 0						;-- scan functions jump table (dynamically filled)
	loaders:		as int-ptr! 0						;-- load functions jump table (dynamically filled)
	stash:			as cell! 0							;-- special buffer for hatching any-blocks series
	stash-size:		1000								;-- pre-allocated cells	number
	root-state:		as state! 0							;-- global entry point to state struct list
	spaces:			as byte-ptr! 0						;-- bitmap table for whitespace characters used as word delimiters
	spaces-size:	8290								;-- bitmap table size
	all-events:		3Fh									;-- bit-mask of all events
	
	min-integer: as byte-ptr! "-2147483648"				;-- used in load-integer
	
	smart-count: func [									;-- counts only new characters from last cached result
		lex		[state!]
		pos		[byte-ptr!]								;-- new position to count UTF-8 sequences up to.
		return: [integer!]
		/local
			base [byte-ptr!]
			len	 [integer!]
	][
		if lex/pos-cache > pos [						;-- invalidate cache if backtracking occured (error event)
			lex/pos-cache: lex/input
			lex/cnt-cache: 0
		]
		base: lex/pos-cache
		if null? base [base: lex/input]					;-- first invocation
		len: lex/cnt-cache + unicode/count-chars base pos ;-- cached count + count from cached position to new one
		lex/pos-cache: pos
		lex/cnt-cache: len
		len
	]

	decode-filter: func [fun [red-function!] return: [integer!]
		/local
			evts flag sym [integer!]
			value tail [red-word!]
			blk		   [red-block!]
			s		   [series!]
	][
		s: as series! fun/more/value
		blk: as red-block! s/offset
		if any [TYPE_OF(blk) <> TYPE_BLOCK block/rs-tail? blk][return all-events]
		blk: as red-block! block/rs-head blk
		if TYPE_OF(blk) <> TYPE_BLOCK [return all-events]
		
		s: GET_BUFFER(blk)
		value: as red-word! s/offset + blk/head
		tail:  as red-word! s/tail
		evts:  0
		while [value < tail][
			if TYPE_OF(value) = TYPE_WORD [
				sym: symbol/resolve value/symbol
				flag: case [
					sym = words/_prescan/symbol [EVT_PRESCAN]
					sym = words/_scan/symbol	[EVT_SCAN]
					sym = words/_load/symbol	[EVT_LOAD]
					sym = words/_open/symbol	[EVT_OPEN]
					sym = words/_close/symbol	[EVT_CLOSE]
					sym = words/_error/symbol	[EVT_ERROR]
					true				 		[0]
				]
				evts: evts or flag
			]
			value: value + 1
		]
		evts
	]

	throw-error: func [lex [state!] s e [byte-ptr!] type [integer!]
		/local
			pos  [red-string!]
			line [red-string!]
			po	 [red-triple!]
			slot [red-value!]
			p	 [byte-ptr!]
			len	closing t [integer!]
			c	 [byte!]
	][
		unless lex/load? [
			lex/scanned: TYPE_ERROR
			throw LEX_ERR								;-- bypass errors when scanning only
		]
		if null? s [									;-- determine token's start
			slot: lex/head
			if slot > lex/buffer [slot: lex/head - 1]
			po: as red-triple! slot						;-- take start of the parent series
			s: either TYPE_OF(po) <> TYPE_TRIPLE [lex/input][lex/input + po/z]
		]
		if lex/fun-ptr <> null [
			t: either type > 0 [type][
				case [
					lex/closing > 0 [lex/closing]
					lex/scanned > 0	[lex/scanned]
					lex/type > 0	[lex/type]
					true			[TYPE_ERROR]
				]
			]
			if lex/entry = S_PATH [close-block lex s e -1 yes]
			unless fire-event lex EVT_ERROR t null s e [throw LEX_ERR]
		]
		e: lex/in-end
		len: 0
		p: s
		while [all [p < e p/1 <> #"^/" s + 30 > p]][p: unicode/fast-decode-utf8-char p :len]
		if p > e [p: e]
		len: as-integer p - s
		pos: string/load as-c-string s len UTF-8
		
		line: string/rs-make-at stack/push* 20
		string/concatenate-literal line "(line "
		string/concatenate-literal line integer/form-signed lex/line
		string/append-char GET_BUFFER(line) as-integer #")"
		
		closing: lex/closing
		lex/closing: 0
		lex/tail: lex/buffer							;-- clear accumulated values

		if ANY_PATH?(closing) [type: ERR_BAD_CHAR]		;-- forces a better error report

		switch type [
			ERR_BAD_CHAR 	 [fire [TO_ERROR(syntax bad-char) line pos]]
			ERR_MALCONSTRUCT [fire [TO_ERROR(syntax malconstruct) line pos]]
			ERR_CLOSING
			ERR_MISSING		 [
				c: either type = ERR_CLOSING [#"_"][	;-- force a closing character
					either lex/in-pos < lex/in-end [lex/in-pos/1][lex/in-pos/0] ;-- guess opening/closing
				]
				type: switch closing [
					TYPE_BLOCK [as-integer either c = #"]" [#"["][#"]"]]
					TYPE_MAP
					TYPE_POINT2D
					TYPE_PAREN [as-integer either c = #")" [#"("][#")"]]
					default [assert false 0]			;-- should not happen
				]
				fire [TO_ERROR(syntax missing) line char/push type pos]
			]
			default [fire [TO_ERROR(syntax invalid) line datatype/push type pos]]
		]
	]
	
	fire-event: func [lex [state!] event [events!] type [integer!] value [red-value!] s e [byte-ptr!] return: [logic!]
		/local
			len x y [integer!]
			ser	  [red-series!]
			res	  [red-value!]
			blk	  [red-block!]
			evt   [red-word!]
			int	  [red-integer!]
			name  [names!]
			more  [series!]
			ctx	  [node!]
			cont? [logic!]
			ref	  [integer!]
	][
		assert lex/in-series <> null
		if lex/fun-evts and event = 0 [return true]
		if all [event = EVT_SCAN type = -2][event: EVT_ERROR type: TYPE_ERROR]
		if all [event = EVT_PRESCAN type = TYPE_ERROR lex/entry = S_M_STRING][s: lex/mstr-s]

		more: as series! lex/fun-ptr/more/value
		int: as red-integer! more/offset + 4
		ctx: either TYPE_OF(int) = TYPE_INTEGER [as node! int/value][global-ctx]
		
		stack/mark-func words/_lexer-cb	lex/fun-ptr/ctx
		evt: switch event [
			EVT_PRESCAN	[words/_prescan]
			EVT_SCAN	[words/_scan]
			EVT_LOAD	[words/_load]
			EVT_OPEN	[words/_open]
			EVT_CLOSE	[words/_close]
			EVT_ERROR	[words/_error]
			default		[assert false null]
		]
		stack/push as red-value! evt					;-- event name
		ser: as red-series! stack/push as red-value! lex/in-series ;-- input
		
		either type < 0 [								;-- type
			blk: as red-block! #get system/lexer/exit-states
			either TYPE_OF(blk) <> TYPE_BLOCK [none/push][
				stack/push block/rs-abs-at blk (0 - type) - 1 ;-- 1-based access
			]
		][
			either zero? type [none/push][datatype/push type]
		]
		either TYPE_OF(lex/in-series) = TYPE_BINARY [
			x: as-integer s - lex/input
			y: as-integer e - lex/input
		][
			x: smart-count lex s
			;x: unicode/count-chars lex/input s
			y: x + unicode/count-chars s e
		]
		ref: either any [all [type < 0 event = EVT_PRESCAN] event = EVT_OPEN][x][y]
		ref: ref + lex/in-series/head					;-- accounts for series original offset
		ser/head: ref									;-- 0-based offset
		integer/push lex/line							;-- line number
		either null? value [pair/push x + 1 y + 1][stack/push value] ;-- token

		if lex/fun-locs > 0 [_function/init-locals lex/fun-locs]
		interpreter/call lex/fun-ptr ctx as red-value! words/_lexer-cb CB_LEXER

		if ser/head <> ref [							;-- check if callback changed input offset
			ref: ser/head - lex/in-series/head
			either TYPE_OF(ser) = TYPE_BINARY [			;-- update input offset in lexer state accordingly
				lex/in-pos: lex/input + ref
			][
				lex/in-pos: unicode/skip-chars lex/input lex/in-end ref
			]
		]
		cont?: logic/top-true?
		stack/unwind
		stack/pop 1
		cont?
	]
	
	mark-buffers: func [/local s [state!]][
		if root-state <> null [
			s: root-state
			until [
				assert s/buffer <= s/tail
				collector/mark-values s/buffer s/tail
				if s/in-series <> null [collector/keep s/in-series/node]
				s: s/next
				null? s
			]
		]
	]
	
	alloc-slot: func [lex [state!] return: [red-value!]
		/local 
			slot new [red-value!]
			s [state!]
	][
		if stash + stash-size <= lex/tail [
			stash-size: stash-size * 2
			new: as cell! realloc as byte-ptr! stash stash-size << 4
			if null? new [fire [TO_ERROR(internal no-memory)]]
			s: root-state
			until [
				s/buffer: new + ((as-integer s/buffer - stash) >> 4)
				s/head:	  new + ((as-integer s/head - stash) >> 4)
				s/tail:	  new + ((as-integer s/tail - stash) >> 4)
				s: s/next
				null? s
			]
			stash: new
		]
		slot: lex/tail
		slot/header: TYPE_UNSET
		if lex/nline > 0 [slot/header: slot/header or flag-new-line]
		lex/tail: slot + 1
		slot
	]
	
	store-any-block: func [slot [cell!] src [cell!] items [integer!] type [integer!] blk [red-block!]
		/local
			s	 [series!]
			size len [integer!]
	][
		size: either zero? items [1][items]
		either null? blk [
			blk: block/make-at as red-block! slot size
			blk/head: 0
		][
			s: GET_BUFFER(blk)
			len: (as-integer s/tail - s/offset) >> size? cell!
			if (s/size >> size? cell!) - len < size [
				expand-series GET_BUFFER(blk) size << 4 + s/size
			]
		]
		blk/header: blk/header and type-mask or type

		if items <> 0 [
			s: GET_BUFFER(blk)
			copy-memory 
				as byte-ptr! s/tail
				as byte-ptr! src
				items << 4
			s/tail: s/tail + items
			assert (as-integer s/tail - s/offset) <= s/size
		]
	]
	
	open-block: func [lex [state!] type [integer!] s [byte-ptr!] e [byte-ptr!]
		/local 
			p	[red-triple!]
			len [integer!]
	][
		if null? s [s: lex/in-pos]
		if null? e [e: s]
		p: as red-triple! lex/head
		if all [lex/buffer < lex/tail TYPE_OF(p) = TYPE_TRIPLE GET_BLOCK_TYPE(p) = TYPE_POINT2D][
			throw-error lex s e TYPE_POINT2D
		]
		if lex/fun-ptr <> null [unless fire-event lex EVT_OPEN type null s e [exit]]
		len: (as-integer lex/tail - lex/head) >> 4
		p: as red-triple! alloc-slot lex
		set-type as cell! p TYPE_TRIPLE					;-- use the slot for stack info
		p/x: len
		p/y: type
		p/z: as-integer s - lex/input					;-- opening delimiter offset saved (error handling)
		lex/head: lex/tail								;-- points just after p
		lex/entry: S_START
	]

	close-block: func [lex [state!] s e [byte-ptr!] type [integer!] quiet? [logic!]
		return: [integer!]
		/local	
			p [red-triple!]
			len	stype t py cnt [integer!]
			do-error [subroutine!]
			triple?	 [logic!]
			head	 [red-value!]
	][
		do-error: [
			lex/closing: type
			throw-error lex s e ERR_MISSING
		]
		p: as red-triple! lex/head - 1
		triple?: all [lex/buffer <= p TYPE_OF(p) = TYPE_TRIPLE]
		py: GET_BLOCK_TYPE(p)
		if all [not quiet? lex/fun-ptr <> null][
			t: either all [triple? any [type <= 0 all [type = TYPE_PAREN py <> type]]][py][type]
			unless fire-event lex EVT_CLOSE t null s e [return 0]
		]
		unless triple? [do-error]						;-- postpone error checking after callback call
		stype: py
		either type = -1 [type: stype][					;-- no closing type provided, use saved one
			if all [
				any [
					type <> TYPE_SET_PATH 
					all [type = TYPE_SET_PATH any [stype = TYPE_LIT_PATH stype = TYPE_GET_PATH]]
				]
				stype <> TYPE_POINT2D
				not all [stype = TYPE_MAP type = TYPE_PAREN];-- paren can close a map or a point
				stype <> type							;-- saved type <> closing type => error
			][
				if triple? [type: py]
				do-error
			]
		]
		
		len: (as-integer lex/tail - lex/head) >> 4
		head: lex/head
		lex/head: as cell! p - p/x
		either stype = TYPE_POINT2D [
			cnt: p/y >> 16								;-- count of commas
			if any [
				cnt > 2									;-- more than 2 commas case
				all [lex/last <> TYPE_INTEGER lex/last <> TYPE_FLOAT] ;-- detect invalid type at tail (after last comma)
				all [lex/load? cnt + 1 <> len]
			][
				t: either cnt > 1 [TYPE_POINT3D][TYPE_POINT2D]
				throw-error lex lex/input + p/z e t
			]
			either lex/load? [
				make-point as cell! p head lex lex/input + p/z e
			][
				type: scan-point lex s e
				p/header: type					;-- overwrite the triple header with correct type (scanning)
			]
		][
			store-any-block as cell! p head len type null ;-- p slot gets overwritten here
		]
		lex/tail: head
		lex/scanned: type
		
		p: as red-triple! lex/head - 1					;-- get parent series
		type: GET_BLOCK_TYPE(p)
		either all [
			lex/buffer <= p
			not any [type = TYPE_BLOCK type = TYPE_PAREN type = TYPE_MAP type = TYPE_POINT2D]
		][												;-- any-path! case
			lex/entry: S_PATH
		][
			lex/entry: S_START
		]
		stype
	]
	
	decode-2: func [s e [byte-ptr!] ser [series!] load? [logic!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p	[byte-ptr!]
			c	[integer!]
			cnt	[integer!]
	][
		p: either load? [as byte-ptr! ser/offset][null]
		while [s < e][
			c: 0
			cnt: 8
			while [all [cnt > 0 s < e]][
				switch s/1 [
					#"0" #"1" [
						c: c << 1 + as-integer s/1 - #"0"
						cnt: cnt - 1
						s: s + 1
					]
					#"^-" #"^/" #" " #"^M" [s: s + 1]
					#";" [until [s: s + 1 any [s/1 = #"^/" s = e]]]
					default [return s]
				]
			]
			either zero? cnt [
				if load? [
					p/value: as byte! c
					p: p + 1
				]
			][
				if cnt <> 8 [return s]
			]
		]
		if load? [ser/tail: as cell! p]
		null
	]
	
	decode-16: func [s e [byte-ptr!] ser [series!] load? [logic!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p [byte-ptr!]
			c index class b1 [integer!]
	][
		p: either load? [as byte-ptr! ser/offset][null]
		b1: -1
		while [s < e][
			index: 1 + as-integer s/1
			class: as-integer bin16-classes/index
			switch class [
				C_BIN_HEXA [
					either b1 < 0 [b1: index][
						if load? [
							c: as-integer hexa-table/b1
							p/value: as byte! c << 4 or as-integer hexa-table/index
							p: p + 1
						]
						b1: -1
					]
				]
				C_BIN_CMT	  [until [s: s + 1 any [s/1 = lf s = e]]]
				C_BIN_ILLEGAL [return s]
				default		  [0]
			]
			s: s + 1
		]
		if b1 > 0 [return s]
		if load? [ser/tail: as cell! p]
		null
	]
	
	decode-64: func [s e [byte-ptr!] ser [series!] load? [logic!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p [byte-ptr!]
			val accum flip index [integer!]
	][
		p: either load? [as byte-ptr! ser/offset][null]
		accum: 0
		flip: 0
		while [s < e][
			if s/1 = #";" [until [s: s + 1 any [s/1 = #"^/" s = e]]] ;-- skip comments
			index: 1 + as-integer s/1
			val: as-integer binary/debase64/index
			either val < 40h [
				either s/1 <> #"=" [
					accum: accum << 6 + val
					flip: flip + 1
					if flip = 4 [
						if load? [
							p/1: as-byte accum >> 16
							p/2: as-byte accum >> 8
							p/3: as-byte accum
							p: p + 3
						]
						accum: 0
						flip: 0
					]
				][										;-- special padding: "="
					s: s + 1
					case [
						flip = 3 [
							if load? [
								p/1: as-byte accum >> 10
								p/2: as-byte accum >> 2
								p: p + 2
							]
							flip: 0
						]
						flip = 2 [
							s: s + 1
							if load? [
								p/1: as-byte accum >> 4
								p: p + 1
							]
							flip: 0
						]
						true [return s]
					]
					break
				]
			][if val = 80h [return s]]
			s: s + 1
		]
		if flip <> 0 [return s]
		if load? [ser/tail: as red-value! p]
		null
	]

	convert-percents: func [lex [state!]
		/local
			str [red-string!]
			vl	[red-string! value]
			len [integer!]
	][
		str: as red-string! lex/tail - 1
		len: string/rs-length? str
		string/make-at as red-value! :vl len Latin1
		string/decode-url str :vl
		str/node: vl/node
		str/cache: null
	]
	
	scan-point: func [lex [state!] s [byte-ptr!] e [byte-ptr!] return: [integer!]
		/local
			p   [red-triple!]
			cnt [integer!]
			do-error skip-ws [subroutine!]
	][
		do-error: [throw-error lex s e TYPE_POINT2D]
		skip-ws:  [until [s: s + 1 any [s = e s/1 <> #" "]]]
		
		p: as red-triple! either lex/buffer < lex/head [lex/head - 1][lex/head]
		if TYPE_OF(p) <> TYPE_TRIPLE [do-error]
		s: lex/input + p/z
		cnt: 0

		while [s < e][
			until [s: s + 1 any [s = e s/1 = #" " s/1 = #","]];-- find a space or a comma
			if all [s < e s/0 <> #"," s/1 <> #","][			;-- if space is preceded by comma, found!
				skip-ws										;-- skip all spaces
				if all [s < e s/1 <> #","][do-error]		;-- comma should follow, otherwise error!
			]
			cnt: cnt + 1
			skip-ws											;-- skip the spaces after the comma
		]
		either cnt = 2 [TYPE_POINT2D][TYPE_POINT3D]
	]
	
	make-point: func [slot [red-value!] head [red-value!] lex [state!] s [byte-ptr!] e [byte-ptr!]
		/local
			int		[red-integer!]
			fp		[red-float!]
			x y z t	[float32!]
			get-f32 [subroutine!]
	][
		get-f32: [
			switch TYPE_OF(fp) [
				TYPE_FLOAT   [t: as-float32 fp/value]
				TYPE_INTEGER [int: as red-integer! fp  t: as-float32 int/value]
				default		 [throw-error lex s e TYPE_POINT2D]
			]
			t
		]
		fp: as red-float! head
		x: get-f32
		fp: fp + 1
		y: get-f32
		if head + 2 = lex/tail [point2D/make-at slot x y  exit]
		fp: fp + 1
		z: get-f32
		if head + 3 < lex/tail [throw-error lex s e TYPE_POINT3D]
		point3D/make-at slot x y z
	]
	
	grab-integer: func [s e [byte-ptr!] flags [integer!] dst err [int-ptr!]
		return: [byte-ptr!]
		/local
			p [byte-ptr!]
			len i c [integer!]
			neg? o? [logic!]
	][
		p: s
		neg?: p/1 = #"-"
		if neg? [p: p + 1]

		i: 0
		o?: no
		while [p < e][
			c: as-integer (p/1 - #"0")
			either all [c >= 0 c <= 9][
				i: 10 * i + c
				o?: o? or system/cpu/overflow?
			][
				if p/1 <> #"'" [break]				;-- allow ' in integers
			]
			p: p + 1
		]
		if o? [
			len: as-integer p - s					;-- account for sign in len now
			either all [len = 11 zero? compare-memory s min-integer len][
				i: 80000000h
				neg?: no							;-- ensure that the 0 subtraction does not occur
			][
				err/value: LEX_INT_OVERFLOW
				return p
			]
		]
		if neg? [i: 0 - i]
		dst/value: i
		p
	]

	grab-digits: func [s e [byte-ptr!] exact max [integer!] dst err [int-ptr!]
		return: [byte-ptr!]
		/local
			p [byte-ptr!]
			i c [integer!]
	][
		if s = e [err/value: -2 return s]				;-- buffer end's reached
		p: s
		i: 0
		
		while [all [p < e max > 0]][
			c: as-integer (p/1 - #"0")
			either all [c >= 0 c <= 9][
				i: 10 * i + c
			][
				break
			]
			p: p + 1
			max: max - 1
		]
		if any [p = s all [exact > 0 exact <> as-integer p - s]][err/value: -1]
		dst/value: i
		p
	]
	
	grab-float: func [s e [byte-ptr!] dst [float-ptr!] err [int-ptr!]
		return: [byte-ptr!]
		/local
			p [byte-ptr!]
	][
		p: s
		while [all [p < e any [all [p/1 >= #"0" p/1 <= #"9"] p/1 = #"."]]][p: p + 1]
		dst/value: dtoa/to-float s p err
		p
	]
	
	skip-whitespaces: func [lex [state!] s e [byte-ptr!] type [integer!] return: [byte-ptr!]
		/local
			cp [integer!]
			p start base [byte-ptr!]
	][
		base: s
		cp: 0
		while [s < e][
			start: s
			s: unicode/fast-decode-utf8-char s :cp
			if cp = -1 [throw-error lex s e type]
			p: spaces + (cp >> 3)
			if any [
				cp > spaces-size
				p/value and (as-byte 128 >> (cp and 7)) = null-byte
			][
				return start
			]
		]
		s
	]
	
	scan-whitespaces: func [lex [state!] s e [byte-ptr!] type [integer!] return: [byte-ptr!]
		/local
			cp [integer!]
			p prev [byte-ptr!]
	][
		cp: 0
		while [s < e][
			prev: s
			s: unicode/fast-decode-utf8-char s :cp
			if cp = -1 [throw-error lex s e type]
			p: spaces + (cp >> 3)
			if all [
				cp < spaces-size
				p/value and (as-byte 128 >> (cp and 7)) <> null-byte
			][
				lex/tok-end: prev
				lex/in-pos:  prev
				return prev
			]
		]
		e
	]
	
	scan-percent-char: func [s e [byte-ptr!] cp [int-ptr!]
		return: [byte-ptr!]								;-- -1 if error
		/local
			c c2 index [integer!]
	][
		if s + 1 >= e [cp/value: -1 return s]
		c: 0
		index: 1 + as-integer s/1						;-- converts the 2 hex chars using a lookup table
		c: as-integer hexa-table/index					;-- decode high nibble
		index: 1 + as-integer s/2
		c2: as-integer hexa-table/index					;-- decode low nibble
		if any [c = -1 c2 = -1][cp/value: -1 return s]
		cp/value: c << 4 or c2
		s + 2
	]
	
	scan-escaped-char: func [s e [byte-ptr!] cp [int-ptr!]
		return: [byte-ptr!]								;-- -1 if error
		/local
			p src  [byte-ptr!]
			len	c pos index [integer!]
			entry  [int-ptr!]
			cb bit [byte!]
	][
		either s/1 = #"(" [								;-- note: #"^(" not allowed
			case [
				s/3 = #")" [							;-- fast-paths for 1 or 2 hex chars
					index: 1 + as-integer s/2
					cb: hexa-table/index
					if cb = #"^(FF)" [cp/value: -1 return s]
					c: as-integer cb
					p: s + 3
				]
				s/4 = #")" [
					index: 1 + as-integer s/2
					cb: hexa-table/index
					if cb = #"^(FF)" [cp/value: -1 return s]
					c: as-integer cb
					index: 1 + as-integer s/3
					cb: hexa-table/index
					if cb = #"^(FF)" [cp/value: -1 return s]
					c: c << 4 + as-integer cb
					p: s + 4
				]
				true [
					src: s + 1							;-- skip (
					entry: escape-names
					loop 7 [							;-- try to match an escape name
						if zero? platform/strnicmp src as byte-ptr! entry/1 entry/2 [break]
						entry: entry + 3
					]
					either escape-names + (size? escape-names) > entry [
						len: entry/2 + 1
						if src/len <> #")" [cp/value: -1 return src]
						c: entry/3
						p: src + len
					][									;-- not a name, fall back on hex value decoding
						p: s + 1						;-- skip (
						c: 0
						cb: null-byte
						while [all [p/1 <> #")" p < e]][
							index: 1 + as-integer p/1	;-- converts the 2 hex chars using a lookup table
							cb: hexa-table/index		;-- decode one nibble at a time
							if cb = #"^(FF)" [cp/value: -1 return s]
							c: c << 4 + as-integer cb
							p: p + 1
						]
						if any [p = e p/1 <> #")" (as-integer p - s) > 7][ ;-- limit of 6 hexa characters
							cp/value: -1 return s
						]
						p: p + 1						;-- skip )
					]
				]
			]
		][
			c: as-integer s/1
			pos: c >>> 3 + 1
			bit: as-byte 1 << (c and 7)
			either char-special/pos and bit = null-byte [ ;-- "regular" escaped char
				case [
					all [61h <= c c <= 7Ah][c: c - 60h]
					all [40h <  c c <= 5Fh][c: c - 40h] ;-- ^@ is handled by faster path
					true [0]							;-- pass-thru
				]
			][											;-- escaped special char
				c: switch s/1 [
					#"@"  [00h]
					#"/"  [0Ah]
					#"-"  [09h]
					#"^"" [22h]
					#"{"  [7Bh]
					#"}"  [7Dh]
					#"^^" [5Eh]
					#"~"  [7Fh]
					default [assert false 0]
				]
			]
			p: s + 1
		]
		cp/value: c
		p
	]

	scan-eof: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][lex/in-pos: lex/in-end]
	
	scan-error: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local type index [integer!]
	][
		either lex/prev < --EXIT_STATES-- [
			index: lex/prev
			index: as-integer type-table/index
			if zero? index [index: ERR_BAD_CHAR]		;-- fallback when no specific type detected
			if ANY_BLOCK_STRICT?(index) [s: null]
			if lex/entry = S_M_STRING [s: lex/mstr-s]
			throw-error lex s e index
		][
			throw-error lex s e ERR_BAD_CHAR
		]
	]
	
	scan-block-open: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local type [integer!]
	][
		type: either s/1 = #"(" [TYPE_PAREN][TYPE_BLOCK]
		open-block lex type null null
		lex/in-pos: e + 1								;-- skip delimiter
	]

	scan-block-close: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		catch LEX_ERR [close-block lex s e TYPE_BLOCK no]
		lex/in-pos: e + 1								;-- skip ]
	]
	
	scan-paren-close: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			blk	 [red-block!]
			value tail [red-value!]
			type [integer!]
	][
		type: close-block lex s e TYPE_PAREN no
		switch type [
			TYPE_MAP [
				lex/scanned: type
				if lex/load? [
					blk: as red-block! lex/tail - 1
					if (block/rs-length? blk) % 2 <> 0 [
						throw-error lex null e type
					]
					value: block/rs-head blk
					tail:  block/rs-tail blk
					while [value < tail][
						unless map/valid-key? TYPE_OF(value) [
							lex/tail: as red-value! blk		;-- remove the temp body from loaded values
							throw-error lex s e type
						]
						value: value + 2
					]
					map/make-at as cell! blk blk block/rs-length? blk
				]
			]
			;TYPE_POINT2D
			;TYPE_POINT3D [lex/scanned: type]
			default      [0]
		]
		lex/in-pos: e + 1								;-- skip )
	]

	scan-mstring-open: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if all [zero? lex/mstr-nest lex/fun-ptr <> null][fire-event lex EVT_OPEN TYPE_STRING null s e]
		if zero? lex/mstr-nest [lex/mstr-s: s]
		if lex/nline > 0 [flags: flags or C_FLAG_NEWLINE]
		lex/mstr-nest: lex/mstr-nest + 1
		lex/mstr-flags: lex/mstr-flags or flags
		lex/entry: S_M_STRING
		lex/in-pos: e + 1								;-- skip {
	]
	
	scan-mstring-close: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		lex/mstr-nest: lex/mstr-nest - 1
		if all [zero? lex/mstr-nest lex/fun-ptr <> null][fire-event lex EVT_CLOSE TYPE_STRING null lex/mstr-s e]

		either zero? lex/mstr-nest [
			either load? [
				if lex/fun-ptr <> null [load?: fire-event lex EVT_SCAN TYPE_STRING null lex/mstr-s e]
				if load? [
					load-string lex lex/mstr-s e lex/mstr-flags or flags yes
					if lex/fun-ptr <> null [fire-event lex EVT_LOAD TYPE_STRING lex/tail - 1 s e]
				]
			][
				scan-string lex lex/mstr-s e lex/mstr-flags or flags no
				if lex/fun-ptr <> null [fire-event lex EVT_SCAN TYPE_STRING null s e]
			]
			lex/mstr-s: null
			lex/mstr-flags: 0
			lex/entry: S_START
		][
			lex/mstr-flags: lex/mstr-flags or flags
			if e + 1 = lex/in-end [throw-error lex s e TYPE_STRING]
		]
		lex/in-pos: e + 1								;-- skip }
	]
	
	scan-map-open: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if s/1 <> #"#" [throw-error lex s e TYPE_MAP]
		open-block lex TYPE_MAP s e
		lex/in-pos: e + 1								;-- skip (
	]
	
	scan-path-open: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			slot [red-value!]
			type [integer!]
	][
		type: switch s/1 [
			#"'" 	[TYPE_LIT_PATH]
			#":" 	[TYPE_GET_PATH]
			default [TYPE_PATH]
		]
		open-block lex type s null						;-- open a new path series
		if type <> TYPE_PATH [s: s + 1]
		lex/type: TYPE_WORD
		if load? [
			flags: flags and not C_FLAG_COLON
			if lex/fun-ptr <> null [fire-event lex EVT_SCAN TYPE_WORD null s e] ;-- cannot cancel LOAD from this event
			load-word lex s e flags yes
			if lex/fun-ptr <> null [
				slot: lex/tail - 1
				unless fire-event lex EVT_LOAD TYPE_OF(slot) slot s e [lex/tail: slot]
			]
		]
		lex/entry: S_PATH								;-- overwrites the S_START set by open-block
		lex/in-pos: e + 1								;-- skip /
	]

	check-path-end: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			type	[integer!]
			cp		[integer!]
			index	[integer!]
			close?	[logic!]
	][
		close?: either e >= lex/in-end [yes][			;-- EOF reached
			cp: as-integer e/1
			index: lex-classes/cp and FFh + 1			;-- query the class of ending character
			as-logic path-ending/index					;-- lookup if the character class is ending path
		]

		either close? [
			type: either all [e < lex/in-end e/1 = #":"][
				if all [e + 1 < lex/in-end e/2 = #"/"][ ;-- detect :/ illegal sequence
					throw-error lex null e TYPE_PATH
				]
				lex/in-pos: e + 1						;-- skip :
				TYPE_SET_PATH
			][-1]
			close-block lex s e type no
		][
			if e + 1 = lex/in-end [throw-error lex null e TYPE_PATH] ;-- incomplete path error
			if e/1 = #":" [throw-error lex null e TYPE_PATH] ;-- set-words not allowed inside paths
			lex/in-pos: e + 1							;-- skip /
		]
	]
	
	scan-comment: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if lex/fun-ptr <> null [fire-event lex EVT_SCAN --EXIT_STATES-- - T_CMT null s e]
	]

	scan-construct: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			dt		 [red-datatype!]
			len type [integer!]
			p end	 [int-ptr!]
			name	 [names!]
	][
		s: s + 2										;-- skip #[
		p: cons-syntax
		end: p + size? cons-syntax						;-- point to end of array
		len: as-integer e - s
		loop 4 [
			if zero? platform/strnicmp s as byte-ptr! p/1 len [break]
			p: p + 4
		]
		either p < end [
			len: p/4 + 1
			if s/len <> #"]" [throw-error lex s e ERR_MALCONSTRUCT]
			lex/scanned: p/2
			if load? [
				dt: as red-datatype! alloc-slot lex
				set-type as cell! dt p/2
				if p/2 = TYPE_LOGIC [dt/value: p/3]
			]
		][
			type: 1
			until [
				name: name-table + type
				if zero? platform/strnicmp s as byte-ptr! name/buffer len [break]
				type: type + 1
				type > datatype/top-id
			]
			if any [
				type > datatype/top-id
				name/size + 1 < len
			][
				throw-error lex s e ERR_MALCONSTRUCT	;-- no match, error case
			]
			lex/scanned: type
			if load? [
				dt: as red-datatype! alloc-slot lex
				set-type as cell! dt TYPE_DATATYPE
				dt/value: type
			]
		]
		lex/in-pos: e + 1								;-- skip ]
	]
	
	scan-word: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			cp type class index [integer!]
			p pos [byte-ptr!]
			cell  [cell!]
	][
		type: TYPE_WORD
		e: scan-whitespaces lex s e type				;-- detect ws in word and cut word eventually

		if flags and C_FLAG_COLON <> 0 [
			case [
				all [s/1 = #":" e/0 <> #":"][type: TYPE_GET_WORD]
				all [s/1 <> #":" e/0 = #":"][type: TYPE_SET_WORD]
				all [e/1 = #":" lex/entry = S_PATH][
					if e + 1 < lex/in-end [
						cp: as-integer e/2
						index: lex-classes/cp and FFh + 1	;-- query the class of ending character
						unless as-logic path-ending/index [	;-- lookup if the character class is ending path
							throw-error lex s e type
						]
					]
				]
				true [throw-error lex s e type]
			]
		]
		if s/1 = #"'" [
			if type = TYPE_SET_WORD [throw-error lex s e TYPE_LIT_WORD]
			type: TYPE_LIT_WORD
		]
		lex/scanned: type
	]
	
	scan-issue: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if any [s + 1 = e s/1 <> #"#"][throw-error lex s e TYPE_ISSUE]
		lex/type: TYPE_ISSUE
	]
	
	scan-string: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			len unit cp type [integer!]
	][
		s: s + 1										;-- skip start delimiter
		unit: 1 << (flags >>> 30)
		if unit > 4 [unit: 4]
		type: either lex/type = -1 [TYPE_STRING][lex/type]

		either flags and C_FLAG_CARET = 0 [				;-- fast path when no escape sequence
			if unit > UCS-1 [
				cp: -1
				while [s < e][
					s: unicode/fast-decode-utf8-char s :cp
					if cp = -1 [throw-error lex s e type]
				]
			]
		][
			cp: -1
			while [s < e][
				s: either s/1 = #"^^" [
					scan-escaped-char s + 1 e :cp
				][
					unicode/fast-decode-utf8-char s :cp
				]
				if cp = -1 [throw-error lex s e type]
			]
		]
		lex/in-pos: e + 1								;-- skip ending delimiter
	]
	
	scan-comma: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			p [red-triple!]
	][
		p: as red-triple! lex/head - 1
		switch GET_BLOCK_TYPE(p) [
			TYPE_POINT2D [p/y: p/y and FFFFh or (p/y >> 16 + 1 << 16)] ;-- increments counter
			TYPE_PAREN	 [p/y: TYPE_POINT2D or 10000h]	;-- count 1 for the first comma
			default		 [throw-error lex s e TYPE_POINT2D]
		]
		lex/in-pos: e + 1								;-- skip comma
	]
	
	scan-float: func [s e [byte-ptr!] return: [logic!]
		/local
			state index class [integer!]
			p [byte-ptr!]
	][
		p: s
		state: 0										;-- S_FL_START
		until [	
			index: as-integer p/1
			class: as-integer float-classes/index
			index: state * (size? float-char-classes!) + class
			state: as-integer float-transitions/index
			p: p + 1
			p = e
		]
		index: state * (size? float-char-classes!) + C_FL_EOF
		7 <> as-integer float-transitions/index			;-- T_FL_ERROR,  true: float, false: error
	]
	
	load-integer: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		return: [integer!]
		/local
			o? neg? [logic!]
			p		[byte-ptr!]
			len i c [integer!]
			cell	[cell!]
			promote [subroutine!]
	][
		promote: [
			lex/scanned: TYPE_FLOAT
			load-float lex s e flags load?
			return 0
		]
		p: s
		neg?: s/1 = #"-"
		if any [neg? s/1 = #"+"][p: p + 1]				;-- skip sign when present
		
		either (as-integer e - p) = 1 [					;-- fast path for 1-digit integers
			i: as-integer (p/1 - #"0")
		][
			len: as-integer e - p
			if zero? len [throw-error lex s e TYPE_PAIR] ;-- catch pair/y values with no digits
			i: 0
			o?: no
			either flags and C_FLAG_QUOTE = 0 [			;-- no quote, faster path
				if len > 10 [promote]
				loop len [
					i: 10 * i
					o?: o? or system/cpu/overflow?
					i: i + as-integer (p/1 - #"0")
					o?: o? or system/cpu/overflow?
					p: p + 1
				]
			][											;-- process with quote(s)
				c: 0
				loop len [
					either p/1 <> #"'" [
						c: c + 1
						i: 10 * i
						o?: o? or system/cpu/overflow?
						i: i + as-integer (p/1 - #"0")
						o?: o? or system/cpu/overflow?
					][
						if any [p + 1 = e p/2 = #"'"][throw-error lex s e TYPE_INTEGER]
					]
					p: p + 1
				]
				if c > 10 [promote]
			]
			assert p = e
			if any [o? i < 0][
				len: as-integer e - s					;-- account for sign in len now
				either all [len = 11 zero? compare-memory s min-integer len][
					i: 80000000h
					s: s + 1							;-- ensure that the 0 subtraction does not occur
				][promote]
			]
		]
		if neg? [i: 0 - i]
		if load? [
			cell: alloc-slot lex
			integer/make-at cell i
		]
		lex/in-pos: e									;-- reset the input position to delimiter byte
		i
	]
	
	load-char: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			char	 [red-char!]
			len	c 	 [integer!]
			p		 [byte-ptr!]
			do-error [subroutine!]
	][
		do-error: [throw-error lex s e TYPE_CHAR]
		unless all [s/1 = #"#" s/2 = #"^"" s/3 <> #"^""][do-error]
		len: as-integer e - s
		if e/1 <> #"^"" [do-error]
		c: -1
		p: either s/3 = #"^^" [
			if len = 3 [do-error]						;-- #"^"
			scan-escaped-char s + 3 e :c
		][												;-- simple char
			unicode/fast-decode-utf8-char s + 2 :c
		]
		if any [c > max-char-codepoint c = -1 p < e][do-error]
		if load? [
			char: as red-char! alloc-slot lex
			set-type as cell! char TYPE_CHAR
			char/value: c
		]
		lex/in-pos: e + 1								;-- skip "
	]
	
	load-string: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			len unit index class digits extra cp type [integer!]
			str    [red-string!]
			ser	   [series!]
			p pos  [byte-ptr!]
			p4	   [int-ptr!]
			c	   [byte!]
			w?	   [logic!]
	][
		s: s + 1										;-- skip start delimiter
		len: as-integer e - s
		unit: 1 << (flags >>> 30)
		if unit > 4 [unit: 4]
		type: either lex/type = -1 [TYPE_STRING][lex/type]
		if flags and C_FLAG_NEWLINE <> 0 [lex/nline: 1]	;-- force a new-line marker (curly strings)

		either flags and C_FLAG_CARET = 0 [				;-- fast path when no escape sequence
			str: string/make-at alloc-slot lex len unit
			ser: GET_BUFFER(str)
			switch unit [
				UCS-1 [
					copy-memory as byte-ptr! ser/offset s len
					ser/tail: as cell! (as byte-ptr! ser/offset) + len
				]
				UCS-2 [
					cp: -1
					p: as byte-ptr! ser/offset
					while [s < e][
						s: unicode/fast-decode-utf8-char s :cp
						if cp = -1 [throw-error lex s e type]
						p/1: as-byte cp and FFh
						p/2: as-byte cp >> 8
						p: p + 2
					]
					ser/tail: as cell! p
				]
				UCS-4 [
					cp: -1
					p4: as int-ptr! ser/offset
					while [s < e][
						s: unicode/fast-decode-utf8-char s :cp
						if cp = -1 [throw-error lex s e type]
						p4/value: cp
						p4: p4 + 1
					]
					ser/tail: as cell! p4
				]
			]
		][
			;-- prescan the string for determining unit and accurate final codepoints count
			extra: 0									;-- count extra bytes used by escape sequences
			if unit < UCS-4 [
				p: s
				;-- check if any escaped codepoint requires higher unit
				while [p < e][
					either p/1 = #"^^" [
						p: p + 1
						either all [p + 1 < e p/1 = #"("][
							p: p + 1
							pos: p
							w?: no
							while [all [not w? p < e p/1 <> #")"]][
								index: as-integer p/1
								class: lex-classes/index and FFh ;-- mask the flags
								switch class [
									C_DIGIT C_ZERO C_ALPHAU C_ALPHAL C_E_UP C_E_LOW [0]
									default [w?: yes]	;-- early exit if not an hex value
								]
								p: p + 1
							]
							if all [w? p < e p/1 <> #")"][ ;-- finish counting characters if early exit
								while [all [p < e p/1 <> #")"]][p: p + 1]
							]
							digits: as-integer p - pos
							extra: extra + digits + 2	;-- account for parens + content
							unless w? [
								if unit = UCS-1 [
									if digits > 2 [unit: UCS-2]
									if digits > 4 [unit: UCS-4]
								]
								if all [unit = UCS-2 digits > 4][unit: UCS-4]
							]
						][
							extra: extra + 1
							p: p + 1
						]
					][p: p + 1]
				]
			]

			str: string/make-at alloc-slot lex len - extra unit
			ser: GET_BUFFER(str)
			switch unit [
				UCS-1 [
					p: as byte-ptr! ser/offset
					while [s < e][
						either s/1 = #"^^" [
							s: scan-escaped-char s + 1 e :cp
							if cp = -1 [throw-error lex s e type]
							p/value: as-byte cp
						][
							p/value: s/1
							s: s + 1
						]
						p: p + 1
					]
					ser/tail: as cell! p
				]
				UCS-2 [
					cp: -1
					p: as byte-ptr! ser/offset
					while [s < e][
						s: either s/1 = #"^^" [
							scan-escaped-char s + 1 e :cp
						][
							unicode/fast-decode-utf8-char s :cp
						]
						if cp = -1 [throw-error lex s e type]
						p/1: as-byte cp and FFh
						p/2: as-byte cp >> 8
						p: p + 2
					]
					ser/tail: as cell! p
				]
				UCS-4 [
					cp: -1
					p4: as int-ptr! ser/offset
					while [s < e][
						s: either s/1 = #"^^" [
							scan-escaped-char s + 1 e :cp
						][
							unicode/fast-decode-utf8-char s :cp
						]
						if cp = -1 [throw-error lex s e type]
						p4/value: cp
						p4: p4 + 1
					]
					ser/tail: as cell! p4
				]
			]
			assert (as byte-ptr! ser/offset) + ser/size >= as byte-ptr! ser/tail
		]
		if type <> TYPE_STRING [set-type as cell! str type]
		lex/in-pos: e + 1								;-- skip ending delimiter
	]
	
	load-word: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			cp type class index [integer!]
			p pos [byte-ptr!]
			cell [cell!]
	][
		type: either lex/type > 0 [lex/type][lex/scanned]
		
		if all [lex/type < 0 flags and C_FLAG_COLON <> 0][
			case [
				s/1 = #":" [type: TYPE_GET_WORD]
				e/0 = #":" [type: TYPE_SET_WORD]
				all [e/1 = #":" lex/entry = S_PATH][0]	;-- do nothing if in a path
				true	   [throw-error lex s e type]
			]
		]
		if s/1 = #"'" [
			if type = TYPE_SET_WORD [throw-error lex s e TYPE_LIT_WORD]
			type: TYPE_LIT_WORD
		]
		if type <> TYPE_WORD [
			switch type [
				TYPE_ISSUE
				TYPE_REFINEMENT [
					s: s + 1
					if s = e [throw-error lex s - 1 e type]
				]
				TYPE_LIT_WORD
				TYPE_GET_WORD [s: s + 1]
				TYPE_SET_WORD [e: e - 1]
				default		  [0]
			]
		]
		if load? [
			cell: alloc-slot lex
			word/make-at symbol/make-alt-utf8 s as-integer e - s cell
			set-type cell type
		]
		if type = TYPE_SET_WORD [lex/in-pos: e + 1]		;-- skip ending delimiter
	]
	
	load-refinement: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local type [integer!]
	][
		type: TYPE_REFINEMENT
		case [
			s + 1 = e [type: TYPE_WORD]
			s + 2 = e [
				case [
					s/1 = #"'" [type: TYPE_LIT_WORD]
					s/1 = #":" [type: TYPE_GET_WORD]
					e/0 = #":" [type: TYPE_SET_WORD]
					true [0]
				]
			]
			s/1 <> #"/" [throw-error lex s e TYPE_REFINEMENT]
			true [0]
		]
		either load? [
			lex/type: type
			load-word lex s e flags yes
		][
			lex/scanned: type
		]
	]

	load-file: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		either s/2 = #"^"" [s: s + 1][flags: flags and not C_FLAG_CARET]
		lex/type: TYPE_FILE
		either load? [
			load-string lex s e flags yes
			either s/1 = #"^"" [
				if e/1 <> #"^"" [throw-error lex s e TYPE_FILE]
				e: e + 1
			][
				if flags and C_FLAG_PERCENT <> 0 [convert-percents lex]
			]
		][
			scan-string lex s e flags no
			if s/1 = #"^"" [e: e + 1]					;-- skip closing double quote
		]
		lex/in-pos: e 									;-- reset the input position after delimiter byte
	]

	load-binary: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			bin	 [red-binary!]
			err	 [byte-ptr!]
			ser	 [series!]
			len size base [integer!]
	][
		either s/1 = #"#" [base: 16][					;-- default base
			base: 0
			while [s/1 <> #"#"][						;-- decode head base value
				base: base * 10 + as-integer s/1 - #"0"
				s: s + 1
			]
		]
		assert s/2 = #"{"
		s: s + 2										;-- skip #{
		len: as-integer e - s
		
		size: switch base [								;-- precalc required buffer size in bytes
			16 [len / 2]
			64 [len + 3 * 3 / 4]
			2  [len / 8]
			default [throw-error lex s e TYPE_BINARY 0]
		]
		ser: either load? [
			bin: binary/make-at alloc-slot lex size
			GET_BUFFER(bin)
		][null]
		err: switch base [
			16 [decode-16 s e ser load?]
			64 [decode-64 s e ser load?]
			 2 [decode-2  s e ser load?]
			default [assert false null]
		]
		if err <> null [throw-error lex err e TYPE_BINARY]
		assert any [not load? (as byte-ptr! ser/offset) + ser/size >= as byte-ptr! ser/tail]
		lex/in-pos: e + 1								;-- skip }
	]
	
	load-percent: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			fl [red-float!]
	][
		assert e/1 = #"%"
		load-float lex s e flags load?
		if load? [
			fl: as red-float! lex/tail - 1
			set-type as cell! fl TYPE_PERCENT
			fl/value: fl/value / 100.0
		]
		lex/in-pos: e + 1								;-- skip ending delimiter
	]

	load-float: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			err [integer!]
			fl	[red-float!]
			f	[float!]
	][
		unless scan-float s e [throw-error lex s e TYPE_FLOAT]
		
		if load? [
			err: 0
			f: dtoa/to-float s e :err
			if err <> 0 [throw-error lex s e TYPE_FLOAT]
			fl: as red-float! alloc-slot lex
			set-type as cell! fl TYPE_FLOAT
			fl/value: f
		]
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	load-float-special: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			fl	 [red-float!]
			p	 [byte-ptr!]
			f	 [float!]
			sig? [logic!]
	][
		p: s
		sig?: either any [p/1 = #"-" p/1 = #"+"] [p: p + 1 yes][no]
		if any [p/1 <> #"1" p/2 <> #"." p/3 <> #"#"][throw-error lex s e TYPE_FLOAT]
		p: p + 3
		either zero? platform/strnicmp p as byte-ptr! "NAN" 3 [f: 1.#NAN][
			either zero? platform/strnicmp p as byte-ptr! "INF" 3 [
				f: either all [sig? s/1 = #"-"] [-1.#INF][1.#INF]
			][
				throw-error lex s e TYPE_FLOAT
			]
		]
		if load? [
			fl: as red-float! alloc-slot lex
			set-type as cell! fl TYPE_FLOAT
			fl/value: f
		]
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	load-tuple: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			cell  [cell!]
			i pos [integer!]
			tp p  [byte-ptr!]
	][
		if load? [
			cell: alloc-slot lex
			tp: (as byte-ptr! cell) + 4
		]
		pos: 0
		i: 0
		p: s

		loop as-integer e - s [
			either p/1 = #"." [
				pos: pos + 1
				if any [i < 0 i > 255 pos > 12 p/2 = #"."][throw-error lex s e TYPE_TUPLE]
				if load? [tp/pos: as byte! i]
				i: 0
			][
				i: i * 10 + as-integer (p/1 - #"0")
			]
			p: p + 1
		]
		pos: pos + 1									;-- last number
		if any [i < 0 i > 255 pos > 12][throw-error lex s e TYPE_TUPLE]
		if load? [
			tp/pos: as byte! i
			cell/header: cell/header and type-mask or TYPE_TUPLE or (pos << 19)
		]
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]


	load-date: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			err year month day hour min tz-h tz-m len ylen dlen value
			week wday yday 	 [integer!]
			do-error check-err check-all grab2 grab2r grab2-max grab-time-TZ
			store-date grab4 calc-time [subroutine!]
			dt				 [red-date!]
			p me			 [byte-ptr!]
			m 	 			 [int-ptr!]
			sec	tm			 [float!]
			time? TZ? neg?	 [logic!]
			sep				 [byte!]
	][
		p: s
		dt: null 
		me: null
		err: year: month: day: hour: min: tz-h: tz-m: week: wday: yday: 0
		sec: tm: 0.0
		time?: TZ?: no
		
		do-error:  [throw-error lex s e TYPE_DATE]
		check-err: [if err <> 0 [do-error]]
		check-all: [if any [err <> 0 p = e][do-error]]
		calc-time: [tm: (3600.0 * as-float hour) + (60.0 * as-float min) + sec]
		grab2: [										;-- grab int from 2 digits exactly
			p: grab-digits p e 2 2 :value :err
			check-all									;-- bound error check
			value
		]
		grab2r: [										;-- grab int from 2 digits exactly
			p: grab-digits p e 2 2 :value :err
			check-err									;-- just check int err
			value
		]
		grab2-max: [									;-- grab int from 2 digits max
			p: grab-digits p + 1 e 0 2 :value :err
			check-err
			value
		]
		grab4: [										;-- grab int from 4 digits max
			neg?: p/1 = #"-"
			if neg? [p: p + 1]
			me: p
			p: grab-digits p e 0 4 :value :err
			check-err
			either neg? [0 - value][value]
		]
		grab-time-TZ: [
			time?: yes
			hour: grab2-max
			if p/1 <> #":" [do-error]
			min: grab2-max
			if p < e [
				if p/1 = #":" [p: grab-float p + 1 e :sec :err check-err]
				if p < e [
					either p/1 = #"Z" [p: p + 1][
						neg?: p/1 = #"-"
						either any [p/1 = #"+" neg?][
							TZ-h: grab2-max
							if neg? [TZ-h: 0 - TZ-h]
							if p < e [
								if p/1 = #":" [p: p + 1]
								p: grab-digits p e 0 2 :TZ-m :err
							]
						][
							do-error
						]
					]
				]
			]
			calc-time
		]
		store-date: [
			if p < e [do-error]
			if load? [dt: date/make-at alloc-slot lex year month day tm tz-h tz-m time? TZ?]
			lex/in-pos: e								;-- reset the input position to delimiter byte
		]
		
		year: grab4										;-- year or day
		ylen: as-integer p - me
		sep: p/1
		either all [sep >= #"0" sep <= #"9"][			;-- ISO dates
			month: grab2
			day:   grab2
			if p/1 <> #"T" [do-error]					;-- yyyymmddT...
			time?: yes
			p: p + 1
			hour: grab2
			min:  grab2
			either p/1 = #"Z" [p: p + 1][				;-- yyymmddThhmmZ
				p: grab-float p e :sec :err
				check-err
				if p < e [
					either p/1 = #"Z" [p: p + 1][
						TZ?: yes
						neg?: p/1 = #"-"
						either any [p/1 = #"+" neg?][	;-- yyymmddThhmm+-hhmm
							p: p + 1
							TZ-h: grab2r
							if neg? [TZ-h: 0 - TZ-h]
							TZ-m: grab2r
						][
							do-error
						]
					]
				]
			]
			calc-time
		][
			either sep = #"-" [
				if all [ylen = 4 p/2 = #"W"][			;-- yyyy-Www
					day: month: 1
					p: p + 2
					week: grab2r
					if all [p < e p/1 = #"-"][			;-- yyyy-Www-d
						p: grab-digits p + 1 e 1 1 :wday :err
					]
					if all [p < e p/1 = #"T"][grab-time-TZ]
					store-date
					if all [week or wday <> 0 load?][date/set-isoweek dt week]
					if wday <> 0 [
						if any [wday < 1 wday > 7][do-error]
						if load? [date/set-weekday dt wday]
					]
					exit
				]
				me: p + 1
				p: grab-digits me e 0 3 :month :err
				if all [zero? err 3 = as-integer p - me][
					if zero? month [do-error]
					yday: month
					day: month: 1
					if all [p < e p/1 = #"T"][grab-time-TZ]
					store-date
					if load? [date/set-yearday dt yday]	;-- yyyy-ddd
					exit
				]
			][
				if sep <> #"/" [do-error]
				p: grab-digits p + 1 e 0 2 :month :err	;-- yy/mm or dd/mm
			]

			if err <> 0 [								;-- try to match a month name
				me: p
				while [all [me < e me/1 <> sep]][me: me + 1]
				len: as-integer me - p
				if any [len < 3 len > 9][do-error]		;-- invalid month name
				m: months
				loop 12 [
					if zero? platform/strnicmp p as byte-ptr! m/1 len [break]
					m: m + 1
				]
				if months + 12 = m [do-error]			;-- invalid month name
				month: (as-integer m - months) >> 2 + 1
				err: 0									;-- reset eventual error from int month grabing
				p: me
			]
			if p/1 <> sep [do-error]
			p: p + 1
			day: grab4									;-- could be year also
			dlen: as-integer p - me
			if any [day < 0 day > 31 all [day <= 31 year < 100]][
				if day < 0 [dlen: dlen - 1]
				len: day day: year year: len ylen: dlen ;-- swap day <=> year
			]
			if all [year < 100 year > 0 ylen <= 2][		;-- expand short yy forms
				ylen: either year < 50 [2000][1900]
				year: year + ylen
			]
			if all [p < e any [p/1 = #"/" p/1 = #"T"]][grab-time-TZ]
		]
		if any [
			day < 1 month < 1 month > 12 year > 9999 year < -9999
			day > as-integer days-max/month
			tz-h > 15 tz-h < -15						;-- out of range TZ
			hour > 23 min > 59 sec >= 60.0
			all [day = 29 month = 2 not date/leap-year? year]
		][
			do-error
		]
		store-date
	]
	
	load-pair: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			index class x y [integer!]
			p [byte-ptr!]
	][
		if flags and C_FLAG_DOT <> 0 [throw-error lex s e TYPE_PAIR]
		p: s
		until [
			p: p + 1									;-- x separator cannot be at start
			index: as-integer p/1
			class: lex-classes/index
			class = C_X
		]
		x: load-integer lex s p flags no
		y: load-integer lex p + 1 e flags no
		if load? [pair/make-at alloc-slot lex x y]
		lex/scanned: TYPE_PAIR							;-- overwrite value set by load-integer
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	load-time: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			err hour min len [integer!]
			p mark	 [byte-ptr!]
			tm		 [float!]
			neg?	 [logic!]
			do-error [subroutine!]
	][
		p: s
		err: hour: 0
		tm: 0.0
		do-error: [throw-error lex s e TYPE_TIME]

		neg?: p/1 = #"-"
		if p/1 = #"+" [p: p + 1]						;-- leading minus is taken care by grab-integer
		p: grab-integer p e flags :hour :err
		if any [err <> 0 p/1 <> #":"][do-error]
		p: p + 1
		
		min: 0
		mark: p
		p: grab-integer p e flags :min :err
		if any [err <> 0 min < 0][do-error]
		p: p + 1
		if all [p = e p/0 = #":"][do-error]
	
		if p < e [
			if any [
				all [p/0 <> #"." p/0 <> #"," p/0 <> #":"]
				flags and C_FLAG_EXP <> 0
			][do-error]
			if any [p/0 = #"." p/0 = #","][
				min: hour
				hour: 0
				p: mark
			]
			tm: dtoa/to-float p e :err
			if any [err <> 0 tm < 0.0][do-error]
		]
		if load? [
			if any [neg? hour < 0][hour: 0 - hour neg?: yes]
			tm: (3600.0 * as-float hour) + (60.0 * as-float min) + tm
			if neg? [tm: 0.0 - tm]
			time/make-at tm (alloc-slot lex) neg?
		]
	]
	
	load-money: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			do-error	  [subroutine!]
			cur	p q st ds [byte-ptr!]
			quotes		  [integer!]
			neg?		  [logic!]
	][
		do-error: [throw-error lex s e TYPE_MONEY]
		p: s
		neg?: p/1 = #"-"
		if flags and C_FLAG_SIGN <> 0 [p: p + 1]		;-- skip sign when present
		cur: p
		while [p/1 <> #"$"][p: p + 1]					;-- cur is always < e
		either p = cur [cur: null][if cur + 3 <> p [do-error]]
		
		assert p/1 = #"$"
		if any [p + 1 = e p/2 = #"." p/2 = #"," p/2 = #"'"][do-error]
		until [p: p + 1 any [p = e all [p/1 <> #"0" p/1 <> #"'"]]]
		if any [p >= e p/1 = #"."][p: p - 1]			;-- backtrack if $0 or $0.
		st: p - 1
		ds: null
		quotes: 0
		while [p < e][
			if any [p/1 = #"." p/1 = #","][
				ds: p
				if ds + 1 = e [do-error]
				q: p + 1
				while [q < e][
					if q/1 = #"'" [do-error]			;-- check that no ' is present in decimals
					q: q + 1
				]
				break   
			]
			if p/1 = #"'" [
				if all [p + 1 < e p/2 = #"'"][do-error]
				quotes: quotes + 1
			]
			p: p + 1
		]
		if p/0 = #"'" [do-error]
		if 18 + quotes < as-integer p - st [do-error]
		if all [not null? ds 6 < as-integer e - ds][do-error]
		lex/in-pos: e									;-- reset the input position to delimiter byte
		if all [load? null? money/make-at alloc-slot lex neg? cur st ds e][do-error]
	]
	
	load-tag: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if s/1 <> #"<" [throw-error lex s e TYPE_TAG]
		if load? [
			flags: flags and not C_FLAG_CARET			;-- clears caret flag
			lex/type: TYPE_TAG
			load-string lex s e flags yes
		]
		lex/in-pos: e + 1								;-- skip ending delimiter
	]
	
	load-url: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			type [integer!]
	][
		if any [s/1 = #":" s/1 = #"'"][
			type: either s/1 = #":" [TYPE_GET_WORD][TYPE_LIT_WORD]
			throw-error lex s e type
		]
		flags: flags and not C_FLAG_CARET				;-- as the lexer can't decode utf8 url, so we don't use it anymore
		lex/type: TYPE_URL
		either load? [
			load-string lex s - 1 e flags yes			;-- compensate for lack of starting delimiter
			if flags and C_FLAG_PERCENT <> 0 [convert-percents lex]
		][
			scan-string lex s - 1 e flags no
		]
		lex/in-pos: e 									;-- reset the input position to delimiter byte
	]
	
	load-email: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if load? [
			flags: flags and not C_FLAG_CARET			;-- clears caret flag
			lex/type: TYPE_EMAIL
			load-string lex s - 1 e flags load?			;-- compensate for lack of starting delimiter
		]
		lex/in-pos: e 									;-- reset the input position to delimiter byte
	]
	
	load-ref: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]][
		if load? [
			flags: flags and not C_FLAG_CARET			;-- clears caret flag
			lex/type: TYPE_REF		
			load-string lex s e flags load?
		]
		lex/in-pos: e 									;-- reset the input position to delimiter byte		
	]
	
	load-hex: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			do-error	[subroutine!]
			int			[red-integer!]
			saved		[byte-ptr!]
			i len index [integer!]
			cb			[byte!]
	][
		do-error: [throw-error lex saved e TYPE_INTEGER]
		i: 0
		cb: null-byte
		if e/1 <> #"h" [e: e - 1]						;-- when coming from number states
		assert e/1 = #"h"
		if all [any [s/1 < #"0" s/1 > #"9"] s + 1 >= e][
			throw-error lex s e TYPE_WORD
		]
		saved: s
		len: as-integer e - s
		if any [s/1 = #"-" s/1 = #"+" len > 8 len < 2][do-error]
		while [s < e][
			if s/1 = #"'" [do-error]
			index: 1 + as-integer s/1					;-- converts the 2 hex chars using a lookup table
			cb: hexa-table/index						;-- decode one nibble at a time
			assert cb <> #"^(FF)"
			i: i << 4 + as-integer cb
			s: s + 1
		]
		assert all [s = e s/1 = #"h"]
		if load? [
			int: as red-integer! alloc-slot lex
			set-type as cell! int TYPE_INTEGER
			int/value: i
		]
		lex/in-pos: e + 1								;-- skip h
	]
	
	load-rawstring: func [lex [state!] s e [byte-ptr!] flags [integer!] load? [logic!]
		/local
			do-error [subroutine!]
			cnt cnt2 [integer!]
			p q		 [byte-ptr!]
			match?	 [logic!]
	][
		do-error: [throw-error lex s e TYPE_STRING]
		p: s
		while [p/1 = #"%"][p: p + 1]
		cnt: as-integer p - s
		q: e
		until [q: q - 1 q/1 <> #"%"]
		cnt2: as-integer e - q - 1
		if cnt < cnt2 [do-error]
		if cnt > cnt2 [									;-- trailing % count too low
			q: e
			until [										;-- searching for the right ending sequence
				if q >= lex/in-end [do-error]
				while [q/1 <> #"}"][
					q: q + 1
					if q + cnt >= lex/in-end [do-error]
				]
				q: q + 1
				match?: yes
				loop cnt [if q/1 <> #"%" [match?: no break] q: q + 1]
				match?
			]
			q: q - cnt - 1
		]
		either load? [
			flags: flags and not C_FLAG_CARET			;-- clears caret flag
			load-string lex p q flags load?	
		][
			if lex/fun-ptr <> null [
				fire-event lex EVT_OPEN  TYPE_STRING null s s + cnt
				fire-event lex EVT_CLOSE TYPE_STRING null s e - 1
			]
		]
		lex/in-pos: q + cnt + 1							;-- reset the input position to delimiter byte
	]

	scan-tokens: func [
		lex    [state!]
		one?   [logic!]
		pscan? [logic!]									;-- prescan only
		/local
			cp class index state prev flags line mark offset idx [integer!]
			term? load?	ld? scan? events? err? [logic!]
			p e	start s [byte-ptr!]
			slot		[cell!]
			do-scan		[scanner!]
			do-load		[loader!]
	][
		line: 1
		ld?: lex/load?
		events?: lex/fun-ptr <> null
		until [
			flags: 0									;=== Pre-scanning stage ===
			term?: no
			state: lex/entry
			prev: state
			p: lex/in-pos								;-- current input position
			start: p									;-- token starting position (including whitespaces)
			mark: line
			offset: 0									;-- leading whitespaces counter
			
			loop as-integer lex/in-end - p [			;-- prescanning loop
				#if debug? = yes [if verbose > 0 [probe ["=== " p/1 " ==="]]]
				cp: as-integer p/value
				flags: lex-classes/cp and FFFFFF00h or flags
				class: lex-classes/cp and FFh
				index: state * (size? character-classes!) + class
				prev: state
				state: as-integer transitions/index
				#if debug? = yes [if verbose > 0 [?? state]]
				offset: offset + as-integer skip-table/state ;-- leading whitespaces skipping
				if state > --EXIT_STATES-- [term?: yes break]
				line: line + as-integer line-table/class	 ;-- lines counting
				p: p + 1
			]
			unless term? [								;-- if EOF reached, manually force the transition
				prev: state
				index: state * (size? character-classes!) + C_EOF
				state: as-integer transitions/index
				#if debug? = yes [if verbose > 0 [?? state]]
			]
			s: start + offset							;-- real token position start
			assert state <= T_REF
			assert s <= p
			
			lex/in-pos:  p
			lex/tok-end: p
			lex/line:    line							;-- global line number
			lex/nline:   line - mark					;-- token's lines span
			lex/prev:	 prev							;-- save previous state
			lex/type:	 -1								;-- type determined by scanners
			lex/scanned: as-integer type-table/state	;-- type determined by state/types correspondence table
		
			index: state - --EXIT_STATES--				;-- scanners jump table entry calculation
			do-scan: as scanner! scanners/index
			if all [pscan? state <= T_STRING][			;-- Prescan only, early exit
				catch LEX_ERR [do-scan lex s p flags no];-- invoke scanners for delimiters and special constructs
				err?: system/thrown = LEX_ERR
				system/thrown: 0
				if err? [exit]
			]
			if state = T_WORD [
				s: skip-whitespaces lex s lex/tok-end TYPE_WORD ;-- Unicode spaces are parsed as words, skip them upfront!
				if s = p [
					either lex/in-pos < lex/in-end [continue][ ;-- empty token, move to next one
						state: T_EOF do-scan: :scan-eof index: 1 lex/scanned: 0 ;-- force EOF if empty input after skipping
					]
				]
			]

			scan?: either not events? [not pscan?][
				either lex/entry = S_M_STRING [yes][
					idx: either zero? lex/scanned [0 - index][lex/scanned]
					fire-event lex EVT_PRESCAN idx null s lex/in-pos
				]
			]
			if scan? [									;=== Scanning stage ===
				load?: any [not one? ld?]
				either state < T_STRING [				;-- invoke scanners for delimiters and special constructs
					catch LEX_ERR [do-scan lex s lex/tok-end flags ld?]
					if all [system/thrown = LEX_ERR not load?][system/thrown: 0 exit]
				][
					if any [not ld? :do-scan <> null all [events? lex/fun-evts and EVT_SCAN <> 0]][
						if :do-scan = null [do-scan: as scanner! loaders/index] ;-- use loaders if scanners not defined
						catch LEX_ERR [do-scan lex s p flags no] ;-- invoke scanner/loader with load?:no flag!
						if events? [
							load?: either system/thrown = LEX_ERR [no][
								idx: either zero? lex/scanned [0 - index][lex/scanned]
								fire-event lex EVT_SCAN idx null s lex/in-pos
							]
						]
					]
				]
				system/thrown: 0
				
				if load? [								;=== Loading stage ===
					do-load: as loader! loaders/index
					if :do-load <> null [
						catch LEX_ERR [do-load lex s lex/tok-end flags yes] ;-- invoke loader with load?:yes flag
						if all [events? system/thrown <> LEX_ERR][
							assert all [lex/tail > lex/head lex/tail > lex/buffer]
							slot: lex/tail - 1
							unless fire-event lex EVT_LOAD TYPE_OF(slot) slot s lex/in-pos [lex/tail: slot]
						]
					]
				]
				system/thrown: 0
			]
			if all [lex/entry = S_PATH state <> T_PATH state <> T_ERROR][ ;-- manual checking for path end
				catch LEX_ERR [check-path-end lex s lex/in-pos flags load?] ;-- lex/in-pos could have changed
				system/thrown: 0
			]
			if all [any [one? pscan?] lex/scanned > 0 lex/entry <> S_PATH lex/entry <> S_M_STRING state <> T_PATH][
				slot: lex/tail - 1
				if any [
					lex/tail = lex/buffer
					all [slot = lex/buffer TYPE_OF(slot) <> TYPE_TRIPLE]
				][
					exit								;-- early exit for single value request
				]
			]
			lex/last: lex/scanned
			lex/in-pos >= lex/in-end
		]
		if all [lex/entry = S_M_STRING zero? lex/scanned][ ;-- {...} string not closed
			catch LEX_ERR [throw-error lex lex/mstr-s lex/in-end TYPE_STRING]
			system/thrown: 0
		]
		assert lex/in-pos = lex/in-end
	]

	scan: func [
		dst		[red-value!]							;-- destination slot
		src		[byte-ptr!]								;-- UTF-8 buffer
		size	[integer!]								;-- buffer size in bytes
		one?	[logic!]								;-- scan a single value
		scan?	[logic!]								;-- NO: disable value scanning, only prescanning
		load?	[logic!]								;-- NO: disable value loading, only scanning
		wrap?	[logic!]								;-- force returned loaded value(s) in a block
		len		[int-ptr!]								;-- return the consumed input length in bytes (binary) or characters (string)
		fun		[red-function!]							;-- optional callback function
		ser		[red-series!]							;-- optional input series back-reference
		out		[red-block!]							;-- /into destination block or null
		return: [integer!]								;-- scanned type when one? is set, else zero
		/local
			blk	  	 [red-block!]
			p	  	 [red-triple!]
			base	 [red-value!]
			slots 	 [integer!]
			s	  	 [series!]
			prev	 [state!]
			lex	  	 [state! value]
			clean-up [subroutine!]
	][
		assert any [fun = null ser <> null]				;-- ser needs to be set if fun is set
		
		either null? root-state [
			root-state: lex
			lex/back: null
			base: stash
		][
			prev: root-state
			while [prev/next <> null][prev: prev/next]
			prev/next: lex
			lex/back: prev
			base: prev/tail
		]
		clean-up: [
			either null? root-state/next [root-state: null][lex/back/next: null]
			either all [ser <> null TYPE_OF(ser) = TYPE_STRING][
				len/value: unicode/count-chars lex/input lex/in-pos
			][
				len/value: as-integer lex/in-pos - lex/input
			]
		]
		
		lex/next:		null							;-- last element of the states linked list
		lex/buffer:		base
		lex/head:		base
		lex/tail:		base
		lex/input:		src
		lex/in-end:		src + size
		lex/in-pos:		src
		lex/entry:		S_START
		lex/type:		-1
		lex/scanned: 	0
		lex/last:		0
		lex/closing:	0
		lex/mstr-nest:	0
		lex/mstr-flags: 0
		lex/fun-ptr:	fun
		lex/fun-locs:	0
		lex/fun-evts:	0
		lex/in-series:	ser
		lex/load?:		all [scan? load?]
		
		if fun <> null [
			lex/fun-locs: _function/count-locals fun/spec 0 no
			lex/fun-evts: decode-filter fun
			lex/pos-cache: null
			lex/cnt-cache: 0
		]
		assert system/thrown = 0
		
		catch RED_THROWN_ERROR [scan-tokens lex one? not scan?]
		if system/thrown > LEX_ERR [clean-up re-throw]
		
		slots: (as-integer lex/tail - lex/buffer) >> 4
		if slots > 0 [
			p: as red-triple! either lex/buffer < lex/head [lex/head - 1][lex/buffer]
			either all [not scan? lex/entry = S_PATH lex/scanned <> TYPE_ERROR][
				lex/scanned: GET_BLOCK_TYPE(p)			;-- any-path prescanning case
			][
				if TYPE_OF(p) = TYPE_TRIPLE [			;-- unclosed any-block series case
					lex/closing: GET_BLOCK_TYPE(p)
					assert system/thrown = 0
					catch RED_THROWN_ERROR [throw-error lex lex/input + p/z lex/in-end ERR_CLOSING]
					either system/thrown <= LEX_ERR [
						if dst <> null [dst/header: TYPE_NONE] ;-- no dst when called from Parse, #4678
						system/thrown: 0
						clean-up
						return lex/scanned
					][
						clean-up
						re-throw
					]
				]
			]
		]
		if load? [
			either all [one? not wrap? slots > 0][
				if out <> null [dst: ALLOC_TAIL(out)]
				copy-cell lex/buffer dst				;-- copy first loaded value only
			][
				store-any-block dst lex/buffer slots TYPE_BLOCK out
			]
		]
		clean-up
		lex/scanned
	]

	scan-alt: func [
		dst		[red-value!]							;-- destination slot
		str		[red-string!]
		size	[integer!]
		one?	[logic!]
		scan?	[logic!]
		load?	[logic!]
		wrap?	[logic!]
		len		[int-ptr!]
		fun		[red-function!]							;-- optional callback function
		out		[red-block!]							;-- /into destination block or null
		return: [integer!]								;-- scanned type when one? is set, else zero
		/local
			unit buf-unit buf-size ignore type used [integer!]
			base extra [byte-ptr!]
			s [series!]
	][
		ignore: 0
		extra: null
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		
		if size = -1 [size: string/rs-length? str]
		either unit = 4 [buf-unit: unit][buf-unit: unit + 1]
		buf-size: size * buf-unit						;-- required (upper estimate)
		used: as-integer utf8-buf-tail - utf8-buffer
		if buf-size > (utf8-buf-size - used) [
			extra: allocate buf-size + 1				;-- fallback to a temporary buffer
			utf8-buf-tail: extra
		]
		size: unicode/to-utf8-buffer str utf8-buf-tail size
		base: utf8-buf-tail
		utf8-buf-tail: utf8-buf-tail + size + 1			;-- move at tail for new buffer; +1 for terminal NUL

		if null? len [len: :ignore]
		assert system/thrown = 0
		catch RED_THROWN_ERROR [type: scan dst base size one? scan? load? wrap? len fun as red-series! str out]
		utf8-buf-tail: utf8-buffer + used				;-- move back to original tail
		if extra <> null [free extra]
		if system/thrown <> 0 [re-throw]				;-- clean place to rethrow errors
		type
	]
	
	set-jump-tables: func [[variadic] count [integer!] list [int-ptr!] /local i [integer!] s l [int-ptr!]][
		count: count / 2
		scanners: as int-ptr! allocate count * size? int-ptr!
		loaders:  as int-ptr! allocate count * size? int-ptr!
		s: scanners
		l: loaders
		until [
			s/value: list/1
			l/value: list/2
			list: list + 2
			count: count - 1
			s: s + 1
			l: l + 1
			zero? count
		]
	]
	
	build-ws-table: func [								;-- builds Unicode whitespaces lookup bitmap table
		/local
			p	 [byte-ptr!]
			i cp [integer!]
	][
		spaces: zero-alloc spaces-size
		i: 1
		until [
			cp: whitespaces/i
			p: spaces + (cp >> 3)
			p/value: p/value or (as-byte 128 >> (cp and 7))
			i: i + 1
			i = size? whitespaces
		]
	]

	init: does [
		stash: as cell! allocate stash-size * size? cell!
		utf8-buffer: allocate utf8-buf-size
		utf8-buf-tail: utf8-buffer
		
		build-ws-table
		
		;-- switch following tables to zero-based indexing
		lex-classes: lex-classes + 1
		transitions: transitions + 1
		skip-table:  skip-table  + 1
		line-table:  line-table  + 1
		type-table:  type-table  + 1
		
		float-classes:     float-classes     + 1
		float-transitions: float-transitions + 1
		
		set-jump-tables [
			:scan-eof			null					;-- T_EOF
			:scan-error			null					;-- T_ERROR
			:scan-block-open	null					;-- T_BLK_OP
			:scan-block-close	null					;-- T_BLK_CL
			:scan-block-open	null					;-- T_PAR_OP
			:scan-paren-close	null					;-- T_PAR_CL
			:scan-mstring-open	null					;-- T_MSTR_OP (multiline string)
			:scan-mstring-close	null					;-- T_MSTR_CL (multiline string)
			:scan-map-open		null					;-- T_MAP_OP
			:scan-path-open		null					;-- T_PATH
			:scan-construct		null					;-- T_CONS_MK
			:scan-comment		null					;-- T_CMT
			:scan-comma			null					;-- T_COMMA
			:scan-string		:load-string			;-- T_STRING
			:scan-word			:load-word				;-- T_WORD
			:scan-issue			:load-word				;-- T_ISSUE
			null				:load-integer			;-- T_INTEGER
			null				:load-refinement		;-- T_REFINE
			null				:load-char				;-- T_CHAR
			null				:load-file				;-- T_FILE
			null				:load-binary			;-- T_BINARY
			null				:load-percent			;-- T_PERCENT
			null				:load-float				;-- T_FLOAT
			null				:load-float-special		;-- T_FLOAT_SP
			null				:load-tuple				;-- T_TUPLE
			null				:load-date				;-- T_DATE
			null				:load-pair				;-- T_PAIR
			null				:load-time				;-- T_TIME
			null				:load-money				;-- T_MONEY
			null				:load-tag				;-- T_TAG
			null				:load-url				;-- T_URL
			null				:load-email				;-- T_EMAIL
			null				:load-hex				;-- T_HEX
			null				:load-rawstring			;-- T_RAWSTRING
			null				:load-ref				;-- T_REF
		]
	]

]