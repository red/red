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
		C_FLAG_ESC_HEX: 00000200h						;-- percent-escaped mode
		C_FLAG_NOSTORE: 00000100h						;-- do not store decoded value
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
		C_BIN											;-- 35
		C_WORD											;-- 36
		C_ILLEGAL										;-- 37
		C_EOF											;-- 38
	]
		
	#enum bin16-char-classes! [
		C_BIN_SKIP										;-- 0
		C_BIN_BLANK										;-- 1
		C_BIN_LINE										;-- 2
		C_BIN_HEXA										;-- 3
		C_BIN_CMT										;-- 4
	]
	
	#enum bin16-states! [
		S_BIN_START										;-- 0
		S_BIN_1ST										;-- 1
		S_BIN_CMT										;-- 2
		S_BIN_FINAL_STATES								;-- 3
		T_BIN_BYTE										;-- 4
		T_BIN_ERROR										;-- 5
	]
	
	line-table: #{
		0001000000000000000000000000000000000000000000000000000000000000
		0000000000000000
	}
	
	skip-table: #{
		0100000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		000000000000000000000000000000000000000000000000
	}

	path-ending: #{
		0101000001010101010001000001000000000000000000010000000001000000
		00000000000101
	}
	
	bin16-classes: #{
		0000000000000000000102000001000000000000000000000000000000000000
		0100000000000000000000000000000003030303030303030303000400000000
		0003030303030300000000000000000000000000000000000000000000000000
		0003030303030300000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
	}
	
	bin16-FSM: #{
		0000000102
		0505050405
		0202000202
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
	
	;-- Bit-array for /-~^{}"
	char-special: #{0000000004A00000000000400000006800000000000000000000000000000000}
	
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
	;--- word --- length -- value ---
		"true"		4		true
		"false"		5		false
		"none!"		5		TYPE_NONE
		"none"		4		TYPE_NONE
		;... to be eventually completed
	]
	
	months: [
		"January" "February" "March" "April" "May" "June" "July"
		"August" "September" "October" "November" "December"
	]

	lex-classes: [
		(C_EOF or C_FLAG_EOF)							;-- 00		NUL
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN	;-- 01-08
		C_BLANK											;-- 09		TAB
		C_LINE 											;-- 0A		LF
		C_BIN											;-- 0B
		C_BIN											;-- 0C
		C_BLANK											;-- 0D		CR
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN	;-- 0E-15
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN	;-- 16-1D
		C_BIN C_BIN										;-- 1E-1F
		C_BLANK											;-- 20
		C_WORD											;-- 21		!
		C_DBL_QUOTE										;-- 22		"
		(C_SHARP or C_FLAG_SHARP)						;-- 23		#
		C_MONEY											;-- 24		$
		C_PERCENT										;-- 25		%
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
		C_WORD C_WORD C_WORD							;-- F0-F2
		FL_UCS4 FL_UCS4									;-- F3-F4
		C_ILLEGAL C_ILLEGAL C_ILLEGAL C_ILLEGAL 		;-- F5-F8
		C_ILLEGAL C_ILLEGAL C_ILLEGAL C_ILLEGAL 		;-- F9-FC
		C_ILLEGAL C_ILLEGAL C_ILLEGAL			 		;-- FD-FF
	]
	
	#enum errors! [
		ERR_BAD_CHAR: 	  -1
		ERR_MALCONSTRUCT: -2
		ERR_MISSING: 	  -3
		ERR_CLOSING: 	  -4
		LEX_INT_OVERFLOW: -5
		LEX_ERR:		  10
	]
	
	state!: alias struct! [
		next		[state!]							;-- link to next state! structure (recursive calls)
		buffer		[red-value!]						;-- static or dynamic stash buffer (recursive calls)
		head		[red-value!]
		tail		[red-value!]
		slots		[integer!]
		input		[byte-ptr!]
		in-end		[byte-ptr!]
		in-pos		[byte-ptr!]
		line		[integer!]							;-- current line number
		nline		[integer!]							;-- new lines count for new token
		type		[integer!]							;-- sub-type in a typeclass
		entry		[integer!]							;-- entry state for the FSM
		prev		[integer!]							;-- previous state before forced EOF transition
		exit		[integer!]							;-- exit state for the FSM
		closing		[integer!]							;-- any-block! expected closing delimiter type 
		mstr-s		[byte-ptr!]							;-- multiline string saved start position
		mstr-nest	[integer!]							;-- multiline string nested {} counting
		mstr-flags	[integer!]							;-- multiline string accumulated flags
		fun-ptr		[red-function!]						;-- callback function pointer or NULL
		fun-locs	[integer!]							;-- number of local words in callback function
		in-series	[red-series!]						;-- optional back reference to input series
	]
	
	scanner!: alias function! [lex [state!] s e [byte-ptr!] flags [integer!]]

	utf8-bufsize:	100'000
	utf8-buffer:	as byte-ptr! 0
	scanners:		as int-ptr! 0						;-- scan functions jump table (dynamically filled)
	stash:			as cell! 0							;-- special buffer for hatching any-blocks series
	stash-size:		1000								;-- pre-allocated cells	number
	root-state:		as state! 0							;-- global entry point to state struct list
	depth:			0									;-- recursive calls depth
	
	min-integer: as byte-ptr! "-2147483648"				;-- used in scan-integer
	flags-LG: C_FLAG_LESSER or C_FLAG_GREATER

	throw-error: func [lex [state!] s e [byte-ptr!] type [integer!]
		/local
			pos  [red-string!]
			line [red-string!]
			po	 [red-point!]
			p	 [byte-ptr!]
			len	 [integer!]
			c	 [byte!]
	][
		if lex/fun-ptr <> null [unless fire-event lex words/_error TYPE_ERROR null s e [throw LEX_ERR]]
		e: lex/in-end
		len: 0
		if null? s [									;-- determine token's start
			either lex/head = lex/buffer [s: lex/input][
				po: as red-point! lex/head - 1			;-- take start of the parent series
				either TYPE_OF(po) <> TYPE_POINT [s: lex/input][s: lex/input + po/z]
			]
		]
		p: s
		while [all [p < e p/1 <> #"^/" s + 30 > p]][p: unicode/fast-decode-utf8-char p :len]
		if p > e [p: e]
		len: as-integer p - s
		pos: string/load as-c-string s len UTF-8
		
		line: string/rs-make-at stack/push* 20
		string/concatenate-literal line "(line "
		string/concatenate-literal line integer/form-signed lex/line
		string/append-char GET_BUFFER(line) as-integer #")"
		
		lex/tail: lex/buffer							;-- clear accumulated values
		depth: depth - 1
		if zero? depth [root-state: null]
		
		switch type [
			ERR_BAD_CHAR 	 [fire [TO_ERROR(syntax bad-char) line pos]]
			ERR_MALCONSTRUCT [fire [TO_ERROR(syntax malconstruct) line pos]]
			ERR_CLOSING
			ERR_MISSING		 [
				c: either type = ERR_CLOSING [#"_"][	;-- force a closing character
					either lex/in-pos < lex/in-end [lex/in-pos/1][lex/in-pos/0] ;-- guess opening/closing
				]
				type: switch lex/closing [
					TYPE_BLOCK [as-integer either c = #"]" [#"["][#"]"]]
					TYPE_MAP
					TYPE_PAREN [as-integer either c = #")" [#"("][#")"]]
					default [assert false 0]			;-- should not happen
				]
				fire [TO_ERROR(syntax missing) line char/push type pos]
			]
			default [fire [TO_ERROR(syntax invalid) line datatype/push type pos]]
		]
	]
	
	fire-event: func [
		lex		[state!]
		event   [red-word!]
		type	[integer!]
		value	[red-value!]
		s		[byte-ptr!]
		e		[byte-ptr!]
		return: [logic!]
		/local
			len x y [integer!]
			ser	  [red-series!]
			res	  [red-value!]
			blk	  [red-block!]
			int	  [red-integer!]
			more  [series!]
			ctx	  [node!]
			cont? [logic!]
	][
		if all [event = words/_scan type = -2][event: words/_error type: TYPE_ERROR]

		more: as series! lex/fun-ptr/more/value
		int: as red-integer! more/offset + 4
		ctx: either TYPE_OF(int) = TYPE_INTEGER [as node! int/value][lex/fun-ptr/ctx]
		
		stack/mark-func words/_body	ctx
		stack/push as red-value! event					;-- event
		ser: as red-series! stack/push as red-value! lex/in-series ;-- input
		
		either type < 0 [								;-- type
			blk: as red-block! #get system/lexer/exit-states
			either TYPE_OF(blk) <> TYPE_BLOCK [none/push][
				stack/push block/rs-abs-at blk (0 - type) - 1	;-- 1-based access
			]
		][
			either zero? type [none/push][datatype/push type]
		]
		either all [lex/in-series <> null TYPE_OF(lex/in-series) <> TYPE_BINARY][
			x: unicode/count-chars lex/input s
			y: x + unicode/count-chars s e
		][
			x: as-integer s - lex/input
			y: as-integer e - lex/input
		]
		ser/head: y										;-- 0-based offset
		integer/push lex/line							;-- line number
		either null? value [pair/push x + 1 y + 1][stack/push value] ;-- token

		if lex/fun-locs > 0 [_function/init-locals 1 + lex/fun-locs]	;-- +1 for /local refinement
		catch RED_THROWN_ERROR [_function/call lex/fun-ptr global-ctx]	;FIXME: hardcoded origin context
		if system/thrown <> 0 [re-throw]

		if ser/head <> y [
			lex/in-series/head: ser/head
			either TYPE_OF(ser) = TYPE_BINARY [
				lex/in-pos: lex/input + ser/head
			][
				lex/in-pos: unicode/skip-chars lex/input lex/in-end ser/head
			]
		]
		cont?: logic/top-true?
		stack/unwind
		cont?
	]
	
	mark-buffers: func [/local s [state!]][
		if root-state <> null [
			s: root-state
			until [
				assert s/buffer < s/tail
				collector/mark-values s/buffer s/tail
				if s/in-series <> null [collector/keep s/in-series/node]
				s: s/next
				null? s
			]
		]
	]
	
	alloc-slot: func [lex [state!] return: [red-value!]
		/local 
			slot [red-value!]
			size deltaH deltaT [integer!]
	][
		size: lex/slots
		if lex/buffer + size <= lex/tail [
			deltaH: (as-integer lex/head - lex/buffer) >> 4
			deltaT: (as-integer lex/tail - lex/buffer) >> 4
			lex/slots: size * 2
			lex/buffer: as cell! realloc as byte-ptr! lex/buffer lex/slots << 4
			if null? lex/buffer [fire [TO_ERROR(internal no-memory)]]
			lex/head: lex/buffer + deltaH
			lex/tail: lex/buffer + deltaT
			if depth = 1 [
				stash: lex/buffer
				stash-size: lex/slots
			]
		]
		slot: lex/tail
		slot/header: TYPE_UNSET
		if lex/nline > 0 [slot/header: slot/header or flag-new-line]
		lex/tail: slot + 1
		slot
	]
	
	store-any-block: func [slot [cell!] src [cell!] items [integer!] type [integer!]
		/local
			blk [red-block!]
			s	[series!]
	][
		either zero? items [
			blk: block/make-at as red-block! slot 1
			blk/header: blk/header and type-mask or type
		][
			blk: block/make-at as red-block! slot items
			blk/header: blk/header and type-mask or type
			s: GET_BUFFER(blk)
			copy-memory 
				as byte-ptr! s/offset
				as byte-ptr! src
				items << 4
			s/tail: s/offset + items
		]
	]
	
	open-block: func [lex [state!] type [integer!] hint [integer!] pos [byte-ptr!]
		/local 
			p	[red-point!]
			len [integer!]
	][
		if null? pos [pos: lex/in-pos]
		if lex/fun-ptr <> null [unless fire-event lex words/_open type null pos pos [exit]]
		len: (as-integer lex/tail - lex/head) >> 4
		p: as red-point! alloc-slot lex
		set-type as cell! p TYPE_POINT					;-- use the slot for stack info
		p/x: len
		p/y: type << 16 or (hint and FFFFh)
		p/z: as-integer pos - lex/input					;-- opening delimiter offset saved (error handling)
		
		lex/head: lex/tail								;-- points just after p
		lex/entry: S_START
	]

	close-block: func [lex [state!] s e [byte-ptr!] type [integer!] final [integer!]
		return: [integer!]
		/local	
			p [red-point!]
			len	hint stype [integer!]
			do-error [subroutine!]
	][
		do-error: [
			lex/closing: type
			throw-error lex s e ERR_MISSING
		]
		p: as red-point! lex/head - 1
		if lex/fun-ptr <> null [
			if all [lex/buffer <= p TYPE_OF(p) = TYPE_POINT][type: p/y >> 16]
			unless fire-event lex words/_close type null s e [return 0]
		]
		stype: p/y >> 16
		unless all [lex/buffer <= p TYPE_OF(p) = TYPE_POINT][do-error]
		either type = -1 [type: either final = -1 [stype][final]][if stype <> type [do-error]]
		
		len: (as-integer lex/tail - lex/head) >> 4
		lex/tail: lex/head
		lex/head: as cell! p - p/x
		hint: p/y and FFFFh << 16 >> 16

		store-any-block as cell! p lex/tail len type	;-- p slot gets overwritten here
		
		p: as red-point! lex/head - 1					;-- get parent series
		stype: p/y >> 16
		either all [
			lex/buffer <= p
			not any [stype = TYPE_BLOCK stype = TYPE_PAREN stype = TYPE_MAP]
		][												;-- any-path! case
			lex/entry: S_PATH
		][
			lex/entry: S_START
		]
		hint
	]
	
	decode-2: func [s e [byte-ptr!] ser [series!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p	[byte-ptr!]
			c	[integer!]
			cnt	[integer!]
	][
		p: as byte-ptr! ser/offset
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
				p/value: as byte! c
				p: p + 1
			][
				if cnt <> 8 [return s]
			]
		]
		ser/tail: as cell! p
		null
	]
	
	decode-16: func [s e [byte-ptr!] ser [series!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p pos [byte-ptr!]
			c index class fstate [integer!]
	][
		p: as byte-ptr! ser/offset
		while [s < e][
			fstate: S_BIN_START
			pos: s
			until [										;-- scans 2 hex characters, skip the rest
				index: 1 + as-integer s/1
				class: as-integer bin16-classes/index
				s: s + 1
				index: fstate * 5 + class + 1
				fstate: as-integer bin16-FSM/index
				any [fstate - S_BIN_FINAL_STATES > 0 s >= e]
			]
			if fstate = T_BIN_ERROR [return s]
			index: 1 + as-integer pos/1					;-- converts the 2 hex chars using tables
			c: as-integer hexa-table/index
			index: 1 + as-integer pos/2
			p/value: as byte! c << 4 or as-integer hexa-table/index
			p: p + 1
		]
		ser/tail: as cell! p
		null
	]
	
	decode-64: func [s e [byte-ptr!] ser [series!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p [byte-ptr!]
			val accum flip index [integer!]
	][
		p: as byte-ptr! ser/offset
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
						p/1: as-byte accum >> 16
						p/2: as-byte accum >> 8
						p/3: as-byte accum
						p: p + 3
						accum: 0
						flip: 0
					]
				][										;-- special padding: "="
					s: s + 1
					case [
						flip = 3 [
							p/1: as-byte accum >> 10
							p/2: as-byte accum >> 2
							p: p + 2
							flip: 0
						]
						flip = 2 [
							s: s + 1
							p/1: as-byte accum >> 4
							p: p + 1
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
		ser/tail: as red-value! p
		null
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
							if cb = #"^(FF)" [cp/value: -1 return p]
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
				if all [#"^(40)" < s/1 s/1 < #"^(5F)"][c: as-integer s/1 - #"@"]
			][											;-- escaped special char
				c: switch s/1 [
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

	scan-eof: func [lex [state!] s e [byte-ptr!] flags [integer!]][]
	
	scan-error: func [lex [state!] s e [byte-ptr!] flags [integer!] /local type index [integer!]][
		either lex/prev < --EXIT_STATES-- [
			index: lex/prev + 1
			index: as-integer prev-table/index
			if zero? index [index: ERR_BAD_CHAR]		;-- fallback when no specific type detected
			throw-error lex s e index
		][
			throw-error lex s e ERR_BAD_CHAR
		]
	]
	
	scan-block-open: func [lex [state!] s e [byte-ptr!] flags [integer!] /local	type [integer!]][
		type: either s/1 = #"(" [TYPE_PAREN][TYPE_BLOCK]
		open-block lex type -1 null
		lex/in-pos: e + 1								;-- skip delimiter
	]

	scan-block-close: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		close-block lex s e TYPE_BLOCK -1
		lex/in-pos: e + 1								;-- skip ]
	]
	
	scan-paren-close: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			blk	 [red-block!]
	][
		if TYPE_MAP = close-block lex s e TYPE_PAREN -1 [
			blk: as red-block! lex/tail - 1
			map/make-at as cell! blk blk block/rs-length? blk
		]
		lex/in-pos: e + 1								;-- skip )
	]

	scan-mstring-open: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		if lex/fun-ptr <> null [fire-event lex words/_open TYPE_STRING null s e]
		if zero? lex/mstr-nest [lex/mstr-s: s]
		lex/mstr-nest: lex/mstr-nest + 1
		lex/mstr-flags: lex/mstr-flags or flags
		lex/entry: S_M_STRING
		lex/in-pos: e + 1								;-- skip {
	]
	
	scan-mstring-close: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		if lex/fun-ptr <> null [fire-event lex words/_close TYPE_STRING null s e]
		lex/mstr-nest: lex/mstr-nest - 1

		either zero? lex/mstr-nest [
			scan-string lex lex/mstr-s e lex/mstr-flags or flags
			lex/mstr-s: null
			lex/mstr-flags: 0
			lex/entry: S_START
		][
			if e + 1 = lex/in-end [throw-error lex s e TYPE_STRING]
		]
		lex/in-pos: e + 1								;-- skip }
	]
	
	scan-map-open: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		open-block lex TYPE_PAREN TYPE_MAP null
		lex/in-pos: e + 1								;-- skip (
	]
	
	scan-path-open: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			pos  [byte-ptr!]
			type [integer!]
	][
		pos: s
		type: switch s/1 [
			#"'" [s: s + 1 flags: flags and not C_FLAG_QUOTE TYPE_LIT_PATH]
			#":" [s: s + 1 flags: flags and not C_FLAG_COLON TYPE_GET_PATH]
			default [TYPE_PATH]
		]
		open-block lex type -1 pos						;-- open a new path series
		scan-word lex s e flags							;-- load the head word
		lex/entry: S_PATH								;-- overwrites the S_START set by open-block
		lex/in-pos: e + 1								;-- skip /
	]

	scan-path-item: func [lex [state!] s e [byte-ptr!] flags [integer!]
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
			close-block lex s e -1 type
		][
			if e + 1 = lex/in-end [throw-error lex null e TYPE_PATH] ;-- incomplete path error
			if e/1 = #":" [throw-error lex null e TYPE_PATH] ;-- set-words not allowed inside paths
			lex/in-pos: e + 1							;-- skip /
		]
	]
			
	scan-comment: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		if lex/fun-ptr <> null [fire-event lex words/_open T_CMT - --EXIT_STATES-- null s e]
	]

	scan-construct: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			dt		[red-datatype!]
			len		[integer!]
			p dtypes end [int-ptr!]
	][
		s: s + 2										;-- skip #[
		p: cons-syntax
		dtypes: p + (3 * 2)
		end: p + size? cons-syntax						;-- point to end of array
		loop 4 [
			if zero? platform/strnicmp s as byte-ptr! p/1 p/2 [break]
			p: p + 3
		]
		if p = end [throw-error lex s e ERR_MALCONSTRUCT] ;-- no match, error case
		len: p/2 + 1
		if s/len <> #"]" [throw-error lex s e ERR_MALCONSTRUCT]

		dt: as red-datatype! alloc-slot lex
		either p < dtypes [
			set-type as cell! dt TYPE_LOGIC
			dt/value: p/3
		][
			set-type as cell! dt p/3
		]
		lex/in-pos: e + 1								;-- skip ]
	]
	
	scan-string: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			len unit index class digits extra cp type [integer!]
			str    [red-string!]
			ser	   [series!]
			p pos  [byte-ptr!]
			p4	   [int-ptr!]
			esc	c  [byte!]
			w?	   [logic!]
	][
		s: s + 1										;-- skip start delimiter
		len: as-integer e - s
		unit: 1 << (flags >>> 30)
		if unit > 4 [unit: 4]
		type: either lex/type = -1 [TYPE_STRING][lex/type]

		either flags and C_FLAG_CARET = 0 [				;-- fast path when no escape sequence
			str: string/make-at alloc-slot lex len unit
			ser: GET_BUFFER(str)
			switch unit [
				UCS-1 [copy-memory as byte-ptr! ser/offset s len]
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
				]
			]
			ser/tail: as cell! (as byte-ptr! ser/offset) + (len << (unit >> 1))
		][
			;-- prescan the string for determining unit and accurate final codepoints count
			extra: 0									;-- count extra bytes used by escape sequences
			if all [unit < UCS-4 flags and C_FLAG_ESC_HEX = 0][
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
			esc: either flags and C_FLAG_ESC_HEX = 0 [#"^^"][#"%"]

			str: string/make-at alloc-slot lex len - extra unit
			ser: GET_BUFFER(str)
			switch unit [
				UCS-1 [
					p: as byte-ptr! ser/offset
					while [s < e][
						either s/1 = esc [
							s: either esc = #"^^" [
								scan-escaped-char s + 1 e :cp
							][
								scan-percent-char s + 1 e :cp
							]
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
						s: either s/1 = esc [
							either esc = #"^^" [
								scan-escaped-char s + 1 e :cp
							][
								scan-percent-char s + 1 e :cp
							]
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
						s: either s/1 = esc [
							either esc = #"^^" [
								scan-escaped-char s + 1 e :cp
							][
								scan-percent-char s + 1 e :cp
							]
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
	
	scan-word: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			cp type class index [integer!]
			p pos s-pos e-pos [byte-ptr!]
	][
		s-pos: s e-pos: e
		if flags and flags-LG = flags-LG [				;-- handle word<tag> cases
			p: s
			while [all [p < e p/1 <> #"<"]][p: p + 1]	;-- search <
			if p + 1 < e [
				pos: p
				p: p + 1
				cp: as-integer p/1						;-- check for valid tag
				class: lex-classes/cp and FFh
				index: S_LESSER * (size? character-classes!) + class ;-- simulate transition from S_LESSER
				if (as-integer transitions/index) = S_TAG [	  ;-- check if valid tag starting is recognized
					while [all [p < e p/1 <> #">"]][p: p + 1] ;-- search >
					if p < e [
						e: pos							;-- cut the word before <
						lex/in-pos: pos					;-- resume scanning from <
					]
				]
			]
		]
		type: TYPE_WORD
		if flags and C_FLAG_COLON <> 0 [
			case [
				s/1 = #":" [s: s + 1 type: TYPE_GET_WORD]
				e/0 = #":" [e: e - 1 type: TYPE_SET_WORD]
				all [e/1 = #":" lex/entry = S_PATH][0]	;-- do nothing if in a path
				true	   [throw-error lex s e type]
			]
		]
		if s/1 = #"'" [
			if type = TYPE_SET_WORD [throw-error lex s e TYPE_LIT_WORD]
			s: s + 1 type: TYPE_LIT_WORD
		]
		if s/1 = #"/" [									;-- //...
			p: s + 1
			while [all [p < e p/1 = #"/"]][p: p + 1]
			if p < e [throw-error lex s e TYPE_REFINEMENT]
		]
		if lex/fun-ptr <> null [unless fire-event lex words/_scan type null s-pos e-pos [exit]]
		cell: alloc-slot lex
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		set-type cell type
	
		if type = TYPE_SET_WORD [lex/in-pos: e + 1]		;-- skip ending delimiter
	]

	scan-file: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			p [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		either s/2 = #"^"" [s: s + 1][					;-- skip "
			p: s until [p: p + 1 any [p/1 = #"%" p = e]] ;-- check if any %xx 
			if p < e [flags: flags or C_FLAG_ESC_HEX or C_FLAG_CARET]
		]
		lex/type: TYPE_FILE
		scan-string lex s e flags
		if s/1 = #"^"" [assert e/1 = #"^"" e: e + 1]
		lex/in-pos: e 									;-- reset the input position to delimiter byte
	]

	scan-binary: func [lex [state!] s e [byte-ptr!] flags [integer!]
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
		bin: binary/make-at alloc-slot lex size
		ser: GET_BUFFER(bin)
		err: switch base [
			16 [decode-16 s e ser]
			64 [decode-64 s e ser]
			 2 [decode-2  s e ser]
			default [assert false null]
		]
		if err <> null [throw-error lex err e TYPE_BINARY]
		assert (as byte-ptr! ser/offset) + ser/size >= as byte-ptr! ser/tail
		lex/in-pos: e + 1								;-- skip }
	]
	
	scan-char: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			char  [red-char!]
			len	c [integer!]
	][
		assert all [s/1 = #"#" s/2 = #"^"" e/1 = #"^""]
		len: as-integer e - s
		if len = 2 [throw-error lex s e TYPE_CHAR]		;-- #""
		
		either s/3 = #"^^" [
			if len = 3 [throw-error lex s e TYPE_CHAR]	;-- #"^"
			c: -1
			scan-escaped-char s + 3 e :c
		][												;-- simple char
			c: as-integer s/3
		]
		if any [c > 0010FFFFh c = -1][throw-error lex s e TYPE_CHAR]
		
		char: as red-char! alloc-slot lex
		set-type as cell! char TYPE_CHAR
		char/value: c
		
		lex/in-pos: e + 1								;-- skip "
	]
	
	scan-ref-issue: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			type [integer!]
			p	 [byte-ptr!]
	][
		type: either s/1 = #"#" [
			if s + 1 = e [throw-error lex s e TYPE_ISSUE]
			TYPE_ISSUE
		][
			assert s/1 = #"/"
			either s + 1 = e [s: s - 1 TYPE_WORD][
				either s/2 = #"/" [						;-- //...
					scan-word lex s e flags
					exit
					0
				][
					TYPE_REFINEMENT
				]
			]
		]
		if lex/fun-ptr <> null [unless fire-event lex words/_scan type null s e [exit]]
		s: s + 1
		cell: alloc-slot lex
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		set-type cell type
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-percent: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			fl [red-float!]
	][
		assert e/1 = #"%"
		scan-float lex s e flags
		fl: as red-float! lex/tail - 1
		set-type as cell! fl TYPE_PERCENT
		fl/value: fl/value / 100.0
		
		lex/in-pos: e + 1								;-- skip ending delimiter
	]
		
	scan-integer: func [lex [state!] s e [byte-ptr!] flags [integer!]
		return: [integer!]
		/local
			p	  [byte-ptr!]
			len i [integer!]
			o?	  [logic!]
	][
		p: s
		if flags and C_FLAG_SIGN <> 0 [p: p + 1]		;-- skip sign if present
		
		either (as-integer e - p) = 1 [					;-- fast path for 1-digit integers
			i: as-integer (p/1 - #"0")
		][
			len: as-integer e - p
			if len > 10 [
				scan-float lex s e flags				;-- overflow, fall back on float
				return 0
			]
			i: 0
			o?: no
			either flags and C_FLAG_QUOTE = 0 [			;-- no quote, faster path
				loop len [
					i: 10 * i + as-integer (p/1 - #"0")
					o?: o? or system/cpu/overflow?
					p: p + 1
				]
			][											;-- process with quote(s)
				loop len [
					if p/1 <> #"'" [
						i: 10 * i + as-integer (p/1 - #"0")
						o?: o? or system/cpu/overflow?
					]
					p: p + 1
				]
			]
			assert p = e
			if o? [
				len: as-integer e - s					;-- account for sign in len now
				either all [len = 11 zero? compare-memory s min-integer len][
					i: 80000000h
					s: s + 1							;-- ensure that the 0 subtraction does not occur
				][
					scan-float lex s e flags			;-- overflow, fall back on float
					return 0
				]
			]
		]
		if s/value = #"-" [i: 0 - i]
		if flags and C_FLAG_NOSTORE = 0 [
			integer/make-at alloc-slot lex i
		]
		lex/in-pos: e									;-- reset the input position to delimiter byte
		i
	]
	
	scan-float: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			fl	[red-float!]
			err	[integer!]
	][
		err: 0
		fl: as red-float! alloc-slot lex
		set-type as cell! fl TYPE_FLOAT
		fl/value: dtoa/to-float s e :err
		if err <> 0 [throw-error lex s e TYPE_FLOAT]
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-float-special: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			fl	 [red-float!]
			p	 [byte-ptr!]
			f	 [float!]
			neg? [logic!]
	][
		p: s
		neg?: either p/1 = #"-" [p: p + 1 yes][no]
		if any [p/1 <> #"1" p/2 <> #"." p/3 <> #"#"][throw-error lex s e TYPE_FLOAT]
		p: p + 3
		either zero? platform/strnicmp p as byte-ptr! "NAN" 3 [f: 1.#NAN][
			either zero? platform/strnicmp p as byte-ptr! "INF" 3 [
				f: either neg? [-1.#INF][1.#INF]
			][
				throw-error lex s e TYPE_FLOAT
			]
		]
		fl: as red-float! alloc-slot lex
		set-type as cell! fl TYPE_FLOAT
		fl/value: f
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-tuple: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			cell  [cell!]
			i pos [integer!]
			tp p  [byte-ptr!]
	][
		cell: alloc-slot lex
		tp: (as byte-ptr! cell) + 4
		pos: 0
		i: 0
		p: s

		loop as-integer e - s [
			either p/1 = #"." [
				pos: pos + 1
				if any [i < 0 i > 255 pos > 12 p/2 = #"."][throw-error lex s e TYPE_TUPLE]
				tp/pos: as byte! i
				i: 0
			][
				i: i * 10 + as-integer (p/1 - #"0")
			]
			p: p + 1
		]
		pos: pos + 1									;-- last number
		tp/pos: as byte! i
		cell/header: cell/header and type-mask or TYPE_TUPLE or (pos << 19)
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]


	scan-date: func [lex [state!] s e [byte-ptr!] flags [integer!]
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
				if all [p < e p/1 <> #"Z"][
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
			calc-time
		]
		store-date: [
			dt: date/make-at alloc-slot lex year month day tm tz-h tz-m time? TZ?
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
			if p/1 <> #"Z" [							;-- yyymmddThhmmZ
				p: grab-float p e :sec :err
				check-err
				if all [p < e p/1 <> #"Z"][
					TZ?: yes
					neg?: p/1 = #"-"
					either any [p/1 = #"+" neg?][		;-- yyymmddThhmm+-hhmm
						p: p + 1
						TZ-h: grab2r
						if neg? [TZ-h: 0 - TZ-h]
						TZ-m: grab2r
					][
						do-error
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
					if week or wday <> 0 [date/set-isoweek dt week]
					if wday <> 0 [
						if any [wday < 1 wday > 7][do-error]
						date/set-weekday dt wday
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
					date/set-yearday dt yday			;-- yyyy-ddd
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
			if any [dlen > ylen day > year][
				len: day day: year year: len ylen: dlen ;-- swap day <=> year
			]
			if all [year < 100 ylen <= 2][				;-- expand short yy forms
				ylen: either year < 50 [2000][1900]
				year: year + ylen
			]
			if all [p < e any [p/1 = #"/" p/1 = #"T"]][grab-time-TZ]
		]
		if any [
			day > 31 month > 12 year > 9999 year < -9999
			tz-h > 15 tz-h < -15						;-- out of range TZ
			hour > 23 min > 59 sec >= 60.0
			all [day = 29 month = 2 not date/leap-year? year]
		][
			do-error
		]
		store-date
	]
	
	scan-pair: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			index [integer!]
			class [integer!]
			p	  [byte-ptr!]
	][
		p: s
		until [
			p: p + 1									;-- x separator cannot be at start
			index: as-integer p/1
			class: lex-classes/index
			class = C_X
		]
		pair/make-at 
			alloc-slot lex
			scan-integer lex s p flags or C_FLAG_NOSTORE
			scan-integer lex p + 1 e flags or C_FLAG_NOSTORE

		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-time: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			err hour min len [integer!]
			p mark [byte-ptr!]
			tm [float!]
			do-error [subroutine!]
	][
		p: s
		err: hour: 0
		do-error: [throw-error lex s e TYPE_TIME]

		p: grab-integer p e flags :hour :err
		if any [err <> 0 p/1 <> #":"][do-error]
		p: p + 1
		
		min: 0
		mark: p
		p: grab-integer p e flags :min :err
		if any [err <> 0 min < 0][do-error]
		p: p + 1
	
		if p < e [
			if any [all [p/0 <> #"." p/0 <> #":"] flags and C_FLAG_EXP <> 0][do-error]
			if p/0 = #"." [
				min: hour
				hour: 0
				p: mark
			]
			tm: dtoa/to-float p e :err
			if any [err <> 0 tm < 0.0][do-error]
		]
		
		tm: (3600.0 * as-float hour) + (60.0 * as-float min) + tm
		if hour < 0 [tm: 0.0 - tm]
		time/make-at tm alloc-slot lex
	]
	
	scan-money: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		;;TBD: implement this function once money! type is done
		throw-error lex s e ERR_BAD_CHAR
	]
	
	scan-tag: func [lex [state!] s e [byte-ptr!] flags [integer!]][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		lex/type: TYPE_TAG
		scan-string lex s e flags
		lex/in-pos: e + 1								;-- skip ending delimiter
	]
	
	scan-url: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			p [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		p: s while [all [p/1 <> #"%" p < e]][p: p + 1] 	;-- check if any %xx 
		if p < e [flags: flags or C_FLAG_ESC_HEX or C_FLAG_CARET]
		lex/type: TYPE_URL
		scan-string lex s - 1 e flags					;-- compensate for lack of starting delimiter
		lex/in-pos: e 									;-- reset the input position to delimiter byte
	]
	
	scan-email: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			p [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		lex/type: TYPE_EMAIL
		scan-string lex s - 1 e flags					;-- compensate for lack of starting delimiter
		lex/in-pos: e 									;-- reset the input position to delimiter byte
	]
	
	scan-hex: func [lex [state!] s e [byte-ptr!] flags [integer!]
		/local
			int		[red-integer!]
			i index [integer!]
			cb		[byte!]
	][
		i: 0
		cb: null-byte
		if e/1 <> #"h" [e: e - 1]						;-- when coming from number states
		assert e/1 = #"h"
		if all [any [s/1 < #"0" s/1 > #"9"] s + 1 >= e][
			throw-error lex s e TYPE_WORD
		]
		while [s < e][
			index: 1 + as-integer s/1					;-- converts the 2 hex chars using a lookup table
			cb: hexa-table/index						;-- decode one nibble at a time
			assert cb <> #"^(FF)"
			i: i << 4 + as-integer cb
			s: s + 1
		]
		assert all [s = e s/1 = #"h"]
		int: as red-integer! alloc-slot lex
		set-type as cell! int TYPE_INTEGER
		int/value: i
		lex/in-pos: e + 1								;-- skip h
	]

	scan-tokens: func [
		lex  [state!]
		one? [logic!]
		/local
			cp class index state prev flags line mark offset [integer!]
			p e	start s [byte-ptr!]
			slot		[cell!]
			term? load?	[logic!]
			do-scan		[scanner!]
	][
		line: 1
		until [
			flags: 0
			term?: no
			state: lex/entry
			prev: state
			p: lex/in-pos
			start: p
			mark: line
			offset: 0
			
			loop as-integer lex/in-end - p [
				#if debug? = yes [if verbose > 0 [probe ["=== " p/1 " ==="]]]
				cp: as-integer p/value
				flags: lex-classes/cp and FFFFFF00h or flags
				class: lex-classes/cp and FFh
				index: state * (size? character-classes!) + class
				prev: state
				state: as-integer transitions/index
				#if debug? = yes [if verbose > 0 [?? state]]
				offset: offset + as-integer skip-table/state
				if state > --EXIT_STATES-- [term?: yes break]
				line: line + as-integer line-table/class
				p: p + 1
			]
			unless term? [
				prev: state
				index: state * (size? character-classes!) + C_EOF
				state: as-integer transitions/index
				#if debug? = yes [if verbose > 0 [?? state]]
			]
			s: start + offset
			assert state <= T_HEX
			assert s <= p
			
			lex/in-pos: p
			lex/line:   line
			lex/nline:  line - mark
			lex/exit:   state
			lex/prev:	prev
			lex/type:	-1
			load?:		yes
			
			index: state - --EXIT_STATES--
			if lex/fun-ptr <> null [
				if state >= T_STRING [load?: fire-event lex words/_scan 0 - index null s lex/in-pos]
			]
			if load? [
				do-scan: as scanner! scanners/index
				catch LEX_ERR [do-scan lex s p flags]

				if all [state >= T_STRING lex/fun-ptr <> null][ ;-- for < T_STRING, events are triggered from scan-*
					slot: lex/tail - 1
					unless fire-event lex words/_load TYPE_OF(slot) slot s lex/in-pos [lex/tail: slot]
				]
				if all [lex/entry = S_PATH state <> T_PATH][
					scan-path-item lex s lex/in-pos flags	;-- lex/in-pos could have changed
				]
			]
			if all [one? state <> T_BLK_OP state <> T_PAR_OP state <> T_MSTR_OP][exit]
			lex/in-pos >= lex/in-end
		]
		
		if lex/entry = S_M_STRING [catch LEX_ERR [throw-error lex start lex/in-end TYPE_STRING]]
		assert lex/in-pos = lex/in-end
	]

	scan: func [
		dst   [red-value!]								;-- destination slot
		src   [byte-ptr!]								;-- UTF-8 buffer
		size  [integer!]								;-- buffer size in bytes
		one?  [logic!]									;-- scan a single value
		wrap? [logic!]									;-- force returned loaded value(s) in a block
		len   [int-ptr!]								;-- return the consumed input length
		fun	  [red-function!]							;-- optional callback function
		ser	  [red-series!]								;-- optional input series back-reference
		/local
			blk	  	 [red-block!]
			p	  	 [red-point!]
			slots 	 [integer!]
			s	  	 [series!]
			lex	  	 [state! value]
			clean-up [subroutine!]
	][
		if zero? depth [root-state: lex]
		depth: depth + 1
		clean-up: [
			depth: depth - 1
			if zero? depth [root-state: null]
		]
		
		lex/next:		null							;-- last element of the states linked list
		lex/buffer:		stash							;TBD: support dyn buffer case
		lex/head:		stash
		lex/tail:		stash
		lex/slots:		stash-size						;TBD: support dyn buffer case
		lex/input:		src
		lex/in-end:		src + size
		lex/in-pos:		src
		lex/entry:		S_START
		lex/type:		-1
		lex/mstr-nest:	0
		lex/mstr-flags: 0
		lex/fun-ptr:	fun
		lex/fun-locs:	0
		lex/in-series:	ser
		
		if fun <> null [lex/fun-locs: _function/count-locals fun/spec 0 no]
		
		scan-tokens lex one?

		slots: (as-integer lex/tail - lex/buffer) >> 4
		if slots > 0 [
			p: as red-point! either lex/buffer < lex/head [lex/head - 1][lex/buffer]
			if TYPE_OF(p) = TYPE_POINT [
				lex/closing: p/y >> 16
				catch LEX_ERR [throw-error lex lex/input + p/z lex/in-end ERR_CLOSING]
				if system/thrown <> 0 [dst/header: TYPE_NONE clean-up exit]
			]
		]
		either all [one? not wrap? slots > 0][
			copy-cell lex/buffer dst					;-- copy first loaded value only
		][
			store-any-block dst lex/buffer slots TYPE_BLOCK
		]
		len/value: as-integer lex/in-pos - lex/input
		clean-up
	]

	load-string: func [
		dst   [red-value!]								;-- destination slot
		str	  [red-string!]
		size  [integer!]
		one?  [logic!]
		wrap? [logic!]
		len	  [int-ptr!]
		fun	  [red-function!]							;-- optional callback function
		/local
			s [series!]
			unit buf-size ignore [integer!]
	][
		ignore: 0
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		
		if size = -1 [size: string/rs-length? str]
		buf-size: size * unit
		if buf-size > utf8-bufsize [
			free utf8-buffer
			utf8-buffer: allocate buf-size
			utf8-bufsize: buf-size
		]
		size: unicode/to-utf8-buffer str utf8-buffer size
		if null? len [len: :ignore]
		scan dst utf8-buffer size one? wrap? len fun as red-series! str
	]
	
	set-jump-table: func [[variadic] count [integer!] list [int-ptr!] /local i [integer!] s [int-ptr!]][
		scanners: as int-ptr! allocate count * size? int-ptr!
		s: scanners
		until [
			s/value: list/value
			list: list + 1
			count: count - 1
			s: s + 1
			zero? count
		]
	]
	
	init: func [][
		stash: as cell! allocate stash-size * size? cell!
		utf8-buffer: allocate utf8-bufsize
		
		;-- switch following tables to zero-based indexing
		lex-classes: lex-classes + 1
		transitions: transitions + 1
		skip-table: skip-table + 1
		line-table: line-table + 1
		
		set-jump-table [
			:scan-eof									;-- T_EOF
			:scan-error									;-- T_ERROR
			:scan-block-open							;-- T_BLK_OP
			:scan-block-close							;-- T_BLK_CL
			:scan-block-open							;-- T_PAR_OP
			:scan-paren-close							;-- T_PAR_CL
			:scan-mstring-open							;-- T_MSTR_OP (multiline string)
			:scan-mstring-close							;-- T_MSTR_CL (multiline string)
			:scan-map-open								;-- T_MAP_OP
			:scan-path-open								;-- T_PATH
			:scan-construct								;-- T_CONS_MK
			:scan-comment								;-- T_CMT
			:scan-word									;-- T_WORD
			:scan-ref-issue								;-- T_REFINE
			:scan-ref-issue								;-- T_ISSUE
			:scan-string								;-- T_STRING
			:scan-file									;-- T_FILE
			:scan-binary								;-- T_BINARY
			:scan-char									;-- T_CHAR
			:scan-percent								;-- T_PERCENT
			:scan-integer								;-- T_INTEGER
			:scan-float									;-- T_FLOAT
			:scan-float-special							;-- T_FLOAT_SP
			:scan-tuple									;-- T_TUPLE
			:scan-date									;-- T_DATE
			:scan-pair									;-- T_PAIR
			:scan-time									;-- T_TIME
			:scan-money									;-- T_MONEY
			:scan-tag									;-- T_TAG
			:scan-url									;-- T_URL
			:scan-email									;-- T_EMAIL
			:scan-hex									;-- T_HEX
		]
	]

]