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
	
	#enum date-char-classes! [
		C_DT_DIGIT										;-- 0
		C_DT_LETTER										;-- 1
		C_DT_SLASH										;-- 2
		C_DT_DASH										;-- 3
		C_DT_T											;-- 4
		C_DT_W											;-- 5
		C_DT_PLUS										;-- 6
		C_DT_COLON										;-- 7
		C_DT_DOT										;-- 8
		C_DT_Z											;-- 9
		C_DT_ILLEGAL									;-- 10
		C_DT_EOF										;-- 11
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
		000000000000000000000000000000000000000000
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
	
	date-cumul: #{
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000010203040506070809000000000000
		004142434445464748494A004C4D4E4F50005253005556000003000000000000
		004142434445464748494A004C4D4E4F50005253005556000003000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
	}
	
	date-classes: #{
		0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A
		0A0A0A0A0A0A0A0A0A0A0A060A03080200000000000000000000070A0A0A0A0A
		0A010101010101010101010A01010101010A0101040101050A01090A0A0A0A0A
		0A010101010101010101010A01010101010A01010101010A0A010A0A0A0A0A0A
		0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A
		0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A
		0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A
		0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A
	}

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
		C_LESSER										;-- 3C		<
		C_EQUAL											;-- 3D		=
		C_GREATER										;-- 3E		>
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

	;; For UTF-8 decoding, uses DFA algorithm: http://bjoern.hoehrmann.de/utf-8/decoder/dfa/#variations
	
	utf8d: #{
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		0101010101010101010101010101010109090909090909090909090909090909
		0707070707070707070707070707070707070707070707070707070707070707
		0808020202020202020202020202020202020202020202020202020202020202
		0A0303030303030303030303030403030B060606050808080808080808080808
		000C18243C60540C0C0C30480C0C0C0C0C0C0C0C0C0C0C0C0C000C0C0C0C0C00
		0C000C0C0C180C0C0C0C0C180C180C0C0C0C0C0C0C0C0C180C0C0C0C0C180C0C
		0C0C0C0C0C180C0C0C0C0C0C0C0C0C240C240C0C0C240C0C0C0C0C240C240C0C
		0C240C0C0C0C0C0C0C0C0C0C 
	}
	
	decode-utf8-char: func [
		p		[byte-ptr!]
		cp		[int-ptr!]
		return: [byte-ptr!]
		/local
			state [integer!]
			byte  [integer!]
			idx	  [integer!]
			type  [integer!]
	][
		state: 0
		forever [
			byte: as-integer p/value
			idx: byte + 1
			type: as-integer utf8d/idx
			
			idx: 256 + state + type + 1
			state: as-integer utf8d/idx
			
			switch state [
				0 [										;-- ACCEPT
					cp/value: FFh >> type and byte
					return p + 1
				]
				12 [									;-- REJECT
					cp/value: -1
					return p
				]
				default [
					cp/value: byte and 3Fh or (cp/value << 6)
					p: p + 1
				]
			]
		]
		as byte-ptr! 0									;-- never reached, just make compiler happy
	]
	
	#enum errors! [
		ERR_BAD_CHAR: 	  -1
		ERR_MALCONSTRUCT: -2
		ERR_MISSING: 	  -3
		LEX_INT_OVERFLOW: -4
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
		exit		[integer!]							;-- exit state for the FSM
		closing		[integer!]							;-- any-block! expected closing delimiter type 
		mstr-s		[byte-ptr!]							;-- multiline string saved start position
		mstr-nest	[integer!]							;-- multiline string nested {} counting
		mstr-flags	[integer!]							;-- multiline string accumulated flags
	]
	
	scanner!: alias function! [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]]

	stash: as cell! 0									;-- special buffer for hatching any-blocks series
	stash-size: 1000									;-- pre-allocated cells	number
	root-state: as state! 0								;-- global entry point to state struct list
	depth: 0											;-- recursive calls depth
	
	min-integer: as byte-ptr! "-2147483648"				;-- used in scan-integer
	

	throw-error: func [lex [state!] s [byte-ptr!] e [byte-ptr!] type [integer!]
		/local
			pos  [red-string!]
			line [red-integer!]
			len	 [integer!]
	][
		e: lex/in-end
		e: either s + 40 < e [s + 40][e]				;FIXME: accurately find the 40th codepoint position
		len: as-integer e - s
		pos: string/load as-c-string s len UTF-8
		line: integer/push lex/line
		lex/tail: lex/buffer							;-- clear accumulated values
		depth: depth - 1
		
		switch type [
			ERR_BAD_CHAR 	 [fire [TO_ERROR(syntax bad-char) line pos]]
			ERR_MALCONSTRUCT [fire [TO_ERROR(syntax malconstruct) line pos]]
			ERR_MISSING		 [
				type: switch lex/closing [
					TYPE_BLOCK [as-integer #"]"]
					TYPE_MAP
					TYPE_PAREN [as-integer #")"]
					default [assert false 0]			;-- should not happen
				]
				fire [TO_ERROR(syntax missing) line char/push type pos]
			]
			default [fire [TO_ERROR(syntax invalid) line datatype/push type pos]]
		]
	]
	
	mark-buffers: func [/local s [state!]][
		if root-state <> null [
			s: root-state
			until [
				assert s/buffer < s/tail
				collector/mark-values s/buffer s/tail
				s: s/next
				null? s
			]
		]
	]
	
	alloc-slot: func [lex [state!] return: [red-value!]
		/local 
			slot   [red-value!]
			size   [integer!]
			deltaH [integer!]
			deltaT [integer!]
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
	
	open-block: func [lex [state!] type [integer!] hint [integer!] 
		/local 
			p	[red-point!]
			len [integer!]
	][
		len: (as-integer lex/tail - lex/head) >> 4
		p: as red-point! alloc-slot lex
		set-type as cell! p TYPE_POINT					;-- use the slot for stack info
		p/x: len
		p/y: type
		p/z: hint
		
		lex/head: lex/tail								;-- points just after p
		lex/entry: S_START
	]

	close-block: func [lex [state!] s [byte-ptr!] e [byte-ptr!] type [integer!] final [integer!]
		return: [integer!]
		/local	
			p	  [red-point!]
			len	  [integer!]
			hint  [integer!]
	][
		p: as red-point! lex/head - 1
		assert all [lex/buffer <= p TYPE_OF(p) = TYPE_POINT]
		either type = -1 [
			type: either final = -1 [p/y][final]
		][
			if p/y <> type [
				lex/closing: type
				throw-error lex s e ERR_MISSING
			]
		]
		len: (as-integer lex/tail - lex/head) >> 4
		lex/tail: lex/head
		lex/head: as cell! p - p/x
		hint: p/z
	
		store-any-block as cell! p lex/tail len type	;-- p slot gets overwritten here
		
		p: as red-point! lex/head - 1					;-- get parent series
		either all [
			lex/buffer <= p
			not any [p/y = TYPE_BLOCK p/y = TYPE_PAREN p/y = TYPE_MAP]
		][												;-- any-path! case
			lex/entry: S_PATH
		][
			lex/entry: S_START
		]
		hint
	]
	
	decode-2: func [s [byte-ptr!] e [byte-ptr!] ser [series!]
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
	
	decode-16: func [s [byte-ptr!] e [byte-ptr!] ser [series!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p	   [byte-ptr!]
			pos	   [byte-ptr!]
			c	   [integer!]
			index  [integer!]
			class  [integer!]
			fstate [integer!]
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
	
	decode-64: func [s [byte-ptr!] e [byte-ptr!] ser [series!]
		return: [byte-ptr!]								;-- null: ok, not null: error position
		/local
			p	  [byte-ptr!]
			c	  [integer!]
			val   [integer!]
			accum [integer!]
			flip  [integer!]
			index [integer!]
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
		ser/tail: as red-value! p
		null
	]
	
	grab-integer: func [s [byte-ptr!] e [byte-ptr!] flags [integer!] dst [int-ptr!] err [int-ptr!]
		return: [byte-ptr!]
		/local
			p	 [byte-ptr!]
			len	 [integer!]
			i	 [integer!]
			c	 [integer!]
			neg? [logic!]
			o?	 [logic!]
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

	grab-digits: func [s [byte-ptr!] e [byte-ptr!] exact [integer!] max [integer!] dst [int-ptr!] err [int-ptr!]
		return: [byte-ptr!]
		/local
			p [byte-ptr!]
			i [integer!]
			c [integer!]
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
	
	grab-float: func [s [byte-ptr!] e [byte-ptr!] dst [float-ptr!] err [int-ptr!]
		return: [byte-ptr!]
		/local
			p [byte-ptr!]
	][
		p: s
		while [all [p < e any [all [p/1 >= #"0" p/1 <= #"9"] p/1 = #"."]]][p: p + 1]
		dst/value: dtoa/to-float s p err
		p
	]
	
	scan-percent-char: func [s [byte-ptr!] e [byte-ptr!] cp [int-ptr!]
		return: [byte-ptr!]								;-- -1 if error
		/local
			c	  [integer!]
			c2	  [integer!]
			index [integer!]
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
	
	scan-escaped-char: func [s [byte-ptr!] e [byte-ptr!] cp [int-ptr!]
		return: [byte-ptr!]								;-- -1 if error
		/local
			p	  [byte-ptr!]
			src	  [byte-ptr!]
			len	  [integer!]
			c	  [integer!]
			pos	  [integer!]
			index [integer!]
			entry [int-ptr!]
			cb	  [byte!]
			bit	  [byte!]
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
				if any [s/1 < #"^(40)" #"^(5F)" < s/1][c: as-integer s/1 - #"@"]
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

	scan-eof: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][]
	
	scan-error: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		throw-error lex s e ERR_BAD_CHAR
	]
	
	scan-block-open: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			type [integer!]
	][
		type: either s/1 = #"(" [TYPE_PAREN][TYPE_BLOCK]
		open-block lex type -1
		lex/in-pos: e + 1								;-- skip delimiter
	]

	scan-block-close: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		close-block lex s e TYPE_BLOCK -1
		lex/in-pos: e + 1								;-- skip ]
	]
	
	scan-paren-close: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			blk	 [red-block!]
	][
		if TYPE_MAP = close-block lex s e TYPE_PAREN -1 [
			blk: as red-block! lex/tail - 1
			map/make-at as cell! blk blk block/rs-length? blk
		]
		lex/in-pos: e + 1								;-- skip )
	]

	scan-string: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			str    [red-string!]
			ser	   [series!]
			p	   [byte-ptr!]
			pos	   [byte-ptr!]
			p4	   [int-ptr!]
			len	   [integer!]
			unit   [integer!]
			index  [integer!]
			class  [integer!]
			digits [integer!]
			extra  [integer!]
			cp	   [integer!]
			type   [integer!]
			esc	   [byte!]
			w?	   [logic!]
			c	   [byte!]
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
						s: decode-utf8-char s :cp
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
						s: decode-utf8-char s :cp
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
							decode-utf8-char s :cp
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
							decode-utf8-char s :cp
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

	scan-mstring-open: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		if zero? lex/mstr-nest [lex/mstr-s: s]
		lex/mstr-nest: lex/mstr-nest + 1
		lex/mstr-flags: lex/mstr-flags or flags
		lex/entry: S_M_STRING
		lex/in-pos: e + 1								;-- skip {
	]
	
	scan-mstring-close: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		lex/mstr-nest: lex/mstr-nest - 1

		either zero? lex/mstr-nest [
			scan-string lex lex/mstr-s e lex/mstr-flags or flags
			lex/mstr-s: null
			lex/entry: S_START
		][
			if e + 1 = lex/in-end [throw-error lex s e TYPE_STRING]
		]
		lex/in-pos: e + 1								;-- skip }
	]
	
	scan-word: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			type [integer!]
	][
		type: TYPE_WORD
		if flags and C_FLAG_COLON <> 0 [
			case [
				s/1 = #":" [s: s + 1 type: TYPE_GET_WORD]
				e/0 = #":" [e: e - 1 type: TYPE_SET_WORD]
				all [e/1 = #":" lex/entry = S_PATH][0]	;-- do nothing if in a path
				true	   [throw-error lex s e type]
			]
		]
		if s/1 = #"'" [s: s + 1 type: TYPE_LIT_WORD]

		cell: alloc-slot lex
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		set-type cell type
	
		if type = TYPE_SET_WORD [lex/in-pos: e + 1]		;-- skip ending delimiter
	]

	scan-file: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			p	 [byte-ptr!]
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

	scan-binary: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			bin	 [red-binary!]
			err	 [byte-ptr!]
			ser	 [series!]
			len	 [integer!]
			size [integer!]
			base [integer!]
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
	
	scan-char: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			char  [red-char!]
			len	  [integer!]
			c	  [integer!]
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
	
	scan-map-open: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		open-block lex TYPE_PAREN TYPE_MAP
		lex/in-pos: e + 1								;-- skip (
	]
	
	scan-construct: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			dt		[red-datatype!]
			p		[int-ptr!]
			dtypes	[int-ptr!]
			end		[int-ptr!]
			len		[integer!]
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
	
	scan-ref-issue: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			type [integer!]
	][
		type: either s/1 = #"#" [TYPE_ISSUE][
			assert s/1 = #"/"
			either s + 1 = e [s: s - 1 TYPE_WORD][TYPE_REFINEMENT]
		]
		s: s + 1
		cell: alloc-slot lex
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		set-type cell type
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-percent: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
		
	scan-integer: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		return: [integer!]
		/local
			p	[byte-ptr!]
			len [integer!]
			i	[integer!]
			o?  [logic!]
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
	
	scan-float: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
	
	scan-float-special: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
	
	scan-tuple: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			i	 [integer!]
			pos  [integer!]
			tp	 [byte-ptr!]
			p	 [byte-ptr!]
	][
		cell: alloc-slot lex
		tp: (as byte-ptr! cell) + 4
		pos: 0
		i: 0
		p: s

		loop as-integer e - s [
			either p/1 = #"." [
				pos: pos + 1
				if any [i < 0 i > 255 pos > 12][throw-error lex s e TYPE_TUPLE]
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


	scan-date: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			p	  [byte-ptr!]
			me	  [byte-ptr!]
			m	  [int-ptr!]
			err	  [integer!]
			year  [integer!]
			month [integer!]
			day	  [integer!]
			hour  [integer!]
			min	  [integer!]
			tz-h  [integer!]
			tz-m  [integer!]
			len	  [integer!]
			ylen  [integer!]
			dlen  [integer!]
			sec	  [float!]
			tm	  [float!]
			sep	  [byte!]
			time? [logic!]
			TZ?	  [logic!]
			neg?  [logic!]
	][
		p: s
		err:   0
		year:  0
		month: 0
		day:   0
		hour:  0
		min:   0
		tz-h:  0
		tz-m:  0
		sec:   0.0
		tm:	   0.0
		time?: no
		TZ?:   no
		
		me: p
		p: grab-digits p e 0 4 :year :err
		ylen: as-integer p - me
		if err <> 0 [throw-error lex s e TYPE_DATE]
		sep: p/1
		either all [sep >= #"0" sep <= #"9"][			;-- ISO dates
			p: grab-digits p e 2 2 :month :err
			if any [err <> 0 p = e][throw-error lex s e TYPE_DATE]
			p: grab-digits p e 2 2 :day :err
			if any [err <> 0 p = e p/1 <> #"T"][throw-error lex s e TYPE_DATE]
			time?: yes
			p: grab-digits p + 1 e 2 2 :hour :err
			if any [err <> 0 p = e][throw-error lex s e TYPE_DATE]
			p: grab-digits p e 2 2 :min :err
			if any [err <> 0 p = e][throw-error lex s e TYPE_DATE]
			if p/1 <> #"Z" [
				p: grab-float p e :sec :err
				if all [p < e p/1 <> #"Z"][
					TZ?: yes
					neg?: p/1 = #"-"
					either any [p/1 = #"+" neg?][
						p: grab-digits p + 1 e 2 2 :TZ-h :err
						if err <> 0 [throw-error lex s e TYPE_DATE]
						if neg? [TZ-h: 0 - TZ-h]
						p: grab-digits p e 2 2 :TZ-m :err
						if err <> 0 [throw-error lex s e TYPE_DATE]
					][
						throw-error lex s e TYPE_DATE
					]
				]
			]
		][
			if all [sep <> #"-" sep <> #"/"][throw-error lex s e TYPE_DATE]

			either all [sep = #"-" ylen = 4 p/2 = #"W"][
				p: grab-digits p + 2 e 2 2 :week :err
				if err <> 0 [throw-error lex s e TYPE_DATE]
				if all [p < e p/1 = #"-"][
					p: grab-digits p + 2 e 1 1 :wday :err
				]
			]

			p: grab-digits p + 1 e 0 2 :month :err
			if err <> 0 [
				me: p
				while [all [me < e me/1 <> sep]][me: me + 1]
				len: as-integer me - p
				if any [len < 3 len > 9][throw-error lex s e TYPE_DATE] ;-- invalid month name
				m: months
				loop 12 [
					if zero? platform/strnicmp p as byte-ptr! m/1 len [break]
					m: m + 1
				]
				if months + 12 = m [throw-error lex s e TYPE_DATE] ;-- invalid month name
				month: (as-integer m - months) >> 2 + 1
				err: 0
				p: me
			]
			if p/1 <> sep [throw-error lex s e TYPE_DATE]
			p: p + 1
			me: p
			p: grab-digits p e 0 4 :day :err			;-- could be year also
			dlen: as-integer p - me
			if err <> 0 [throw-error lex s e TYPE_DATE]
			if day > year [len: day day: year year: len ylen: dlen]
			if all [year < 100 ylen <= 2][				;-- expand short yy forms
				ylen: either year < 50 [2000][1900]
				year: year + ylen
			]
			if all [p < e any [p/1 = #"/" p/1 = #"T"]][
				time?: yes
				p: grab-digits p + 1 e 0 2 :hour :err
				if any [err <> 0 p = e p/1 <> #":"][throw-error lex s e TYPE_DATE]
				p: grab-digits p + 1 e 0 2 :min :err
				if err <> 0 [throw-error lex s e TYPE_DATE]
				if p < e [
					if p/1 = #":" [p: grab-float p + 1 e :sec :err]
					if all [p < e p/1 <> #"Z"][
						neg?: p/1 = #"-"
						either any [p/1 = #"+" neg?][
							p: grab-digits p + 1 e 0 2 :TZ-h :err
							if neg? [TZ-h: 0 - TZ-h]
							if err <> 0 [throw-error lex s e TYPE_DATE]
							if p < e [
								if p/1 = #":" [p: p + 1]
								p: grab-digits p e 0 2 :TZ-m :err
							]
						][
							throw-error lex s e TYPE_DATE
						]
					]
				]
			]
		]
		if time? [tm: (3600.0 * as-float hour) + (60.0 * as-float min) + sec]
		
		if any [
			day > 31 month > 12 year > 9999 year < -9999
			tz-h > 15 tz-h < -15						;-- out of range TZ
			hour > 23 min > 59 sec >= 60.0
			all [day = 29 month = 2 not date/leap-year? year]
		][
			throw-error lex s e TYPE_DATE
		]	
		date/make-at2 alloc-slot lex year month day tm tz-h tz-m time? TZ?
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]

	scan-date2: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell  [cell!]
			dt	  [red-date!]
			df	  [lexer-dt-array!]
			b	  [byte-ptr!]
			p	  [byte-ptr!]
			me	  [byte-ptr!]
			m	  [int-ptr!]
			field [int-ptr!]
			type  [integer!]
			state [integer!]
			class [integer!]
			index [integer!]
			cp	  [integer!]
			c	  [integer!]
			pos	  [integer!]
			len	  [integer!]
			neg?  [logic!]
	][
		c: 0											;-- accumulator (fields decoding)
		b: s
		field: system/stack/allocate/zero 17 			;-- date/time fields array
		state: S_DT_START

		loop as-integer e - s [
			cp: as-integer s/1
			class: as-integer date-classes/cp
			index: state * (size? date-char-classes!) + class
			state: as-integer date-transitions/index
			c: c * 10 + as-integer date-cumul/cp
			pos: as-integer fields-table/state
			field/pos: c
			pos: as-integer fields-ptr-table/state
			field/pos: as-integer s
			if null-byte = reset-table/state [c: 0]
			s: s + 1
		]
		if state <= T_DT_ERROR [						;-- if no terminal state reached, forces EOF input
			if state = T_DT_ERROR [throw-error lex b e TYPE_DATE]
			index: state * (size? date-char-classes!) + C_DT_EOF
			state: as-integer date-transitions/index
			pos: as-integer fields-table/state
			field/pos: c
		]
		df: as lexer-dt-array! field + 1

		p: as byte-ptr! df/TZ-sign
		neg?: all [p <> null p/1 = #"-"]			;-- detect negative TZ
		cell: alloc-slot lex

		either df/week or df/wday or df/yday <> 0 [ ;-- special ISO formats
			df/month: 1								;-- ensures valid month (will be changed later)
			df/day: 1								;-- ensures valid day   (will be changed later)
			dt: date/make-at cell df state >= T_TM_HM neg? ;-- create red-date!
			if null? dt [throw-error lex b e TYPE_DATE]

			if df/week or df/wday <> 0 [			;-- yyyy-Www
				date/set-isoweek dt df/week
			]
			c: df/wday
			if c <> 0 [								;-- yyyy-Www-d
				if any [c < 1 c > 7][throw-error lex b e TYPE_DATE]
				date/set-weekday dt c
			]
			if df/yday <> 0 [date/set-yearday dt df/yday] ;-- yyyy-ddd
		][
			p: as byte-ptr! df/month-begin
			me: as byte-ptr! df/sep2
			if df/month-begin or df/sep2 <> 0 [
				if any [null? p null? me p/1 <> me/1][
					throw-error lex b e TYPE_DATE	;-- inconsistent separator
				]
			]
			if df/year < 100 [						;-- expand short yy forms
				me: (as byte-ptr! df/sep2) + 3
				unless all [me < e (as-integer me/1 - #"0") <= 9][ ;-- check if year field has 2 digits
					c: either df/year < 50 [2000][1900]
					df/year: df/year + c
				]
			]
			if df/month-end <> 0 [					;-- if month is named
				p: p + 1							;-- name start
				me: as byte-ptr! df/month-end		;-- name end
				len: as-integer me - p + 1
				if any [len < 3 len > 9][throw-error lex b e TYPE_DATE] ;-- invalid month name
				m: months
				loop 12 [
					if zero? platform/strnicmp p as byte-ptr! m/1 len [break]
					m: m + 1
				]
				if months + 12 = m [throw-error lex b e TYPE_DATE] ;-- invalid month name
				df/month: (as-integer m - months) >> 2 + 1
			]
			dt: date/make-at cell df state >= T_TM_HM neg? ;-- create red-date!
			if null? dt [throw-error lex b e TYPE_DATE]
		]
		lex/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-pair: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
	
	scan-time: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			p	 [byte-ptr!]
			mark [byte-ptr!]
			err	 [integer!]
			hour [integer!]
			min	 [integer!]
			len	 [integer!]
			tm	 [float!]
	][
		p: s
		err:  0
		hour: 0

		p: grab-integer p e flags :hour :err
		if any [err <> 0 p/1 <> #":"][throw-error lex s e TYPE_TIME]
		p: p + 1
		
		min: 0
		mark: p
		p: grab-integer p e flags :min :err
		if any [err <> 0 min < 0][throw-error lex s e TYPE_TIME]
		p: p + 1
	
		if p < e [
			if any [all [p/0 <> #"." p/0 <> #":"] flags and C_FLAG_EXP <> 0][throw-error lex s e TYPE_TIME]
			if p/0 = #"." [
				min: hour
				hour: 0
				p: mark
			]
			tm: dtoa/to-float p e :err
			if any [err <> 0 tm < 0.0][throw-error lex s e TYPE_TIME]
		]
		
		tm: (3600.0 * as-float hour) + (60.0 * as-float min) + tm
		if hour < 0 [tm: 0.0 - tm]
		time/make-at tm alloc-slot lex
	]
	
	scan-money: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		;;TBD: implement this function once money! type is done
		throw-error lex s e ERR_BAD_CHAR
	]
	
	scan-tag: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		lex/type: TYPE_TAG
		scan-string lex s e flags
		lex/in-pos: e + 1								;-- skip ending delimiter
	]
	
	scan-url: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
	
	scan-email: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			p [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		lex/type: TYPE_EMAIL
		scan-string lex s - 1 e flags					;-- compensate for lack of starting delimiter
		lex/in-pos: e 									;-- reset the input position to delimiter byte
	]
	
	scan-path-open: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			type [integer!]
	][
		type: switch s/1 [
			#"'" [s: s + 1 flags: flags and not C_FLAG_QUOTE TYPE_LIT_PATH]
			#":" [s: s + 1 flags: flags and not C_FLAG_COLON TYPE_GET_PATH]
			default [TYPE_PATH]
		]
		open-block lex type -1							;-- open a new path series
		scan-word lex s e flags							;-- load the head word
		lex/entry: S_PATH								;-- overwrites the S_START set by open-block
		lex/in-pos: e + 1								;-- skip /
	]
	
	scan-hex: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			int	  [red-integer!]
			index [integer!]
			i	  [integer!]
			cb	  [byte!]
	][
		i: 0
		cb: null-byte
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
	
	scan-comment: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		;TBD: trigger an event
	]

	
	scan-path-item: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
				lex/in-pos: e + 1						;-- skip :
				TYPE_SET_PATH
			][-1]
			close-block lex s e -1 type
		][
			if all [e < lex/in-end e/1 = #":"][
				throw-error lex s e TYPE_PATH			;-- set-words not allowed inside paths
			]
			lex/in-pos: e + 1							;-- skip /
		]
	]

	scanners: [
		:scan-eof										;-- T_EOF
		:scan-error										;-- T_ERROR
		:scan-block-open								;-- T_BLK_OP
		:scan-block-close								;-- T_BLK_CL
		:scan-block-open								;-- T_PAR_OP
		:scan-paren-close								;-- T_PAR_CL
		:scan-string									;-- T_STRING
		:scan-mstring-open								;-- T_MSTR_OP (multiline string)
		:scan-mstring-close								;-- T_MSTR_CL (multiline string)
		:scan-word										;-- T_WORD
		:scan-file										;-- T_FILE
		:scan-ref-issue									;-- T_REFINE
		:scan-binary									;-- T_BINARY
		:scan-char										;-- T_CHAR
		:scan-map-open									;-- T_MAP_OP
		:scan-construct									;-- T_CONS_MK
		:scan-ref-issue									;-- T_ISSUE
		:scan-percent									;-- T_PERCENT
		:scan-integer									;-- T_INTEGER
		:scan-float										;-- T_FLOAT
		:scan-float-special								;-- T_FLOAT_SP
		:scan-tuple										;-- T_TUPLE
		:scan-date										;-- T_DATE
		:scan-pair										;-- T_PAIR
		:scan-time										;-- T_TIME
		:scan-money										;-- T_MONEY
		:scan-tag										;-- T_TAG
		:scan-url										;-- T_URL
		:scan-email										;-- T_EMAIL
		:scan-path-open									;-- T_PATH
		:scan-hex										;-- T_HEX
		:scan-comment									;-- T_CMT
	]

	scan-tokens: func [
		lex [state!]
		/local
			p		[byte-ptr!]
			e		[byte-ptr!]
			start	[byte-ptr!]
			cp		[integer!]
			class	[integer!]
			index	[integer!]
			state	[integer!]
			flags	[integer!]
			line	[integer!]
			mark	[integer!]
			offset	[integer!]
			s		[series!]
			term?	[logic!]
			do-scan [scanner!]
	][
		line: 1
		until [
			flags: 0
			term?: no
			state: lex/entry
			p: lex/in-pos
			start: p
			mark: line
			offset: 0
			
			loop as-integer lex/in-end - p [
				cp: as-integer p/value
				flags: lex-classes/cp and FFFFFF00h or flags
				class: lex-classes/cp and FFh
				
				index: state * (size? character-classes!) + class
				state: as-integer transitions/index
				
				offset: offset + as-integer skip-table/state
				if state > --EXIT_STATES-- [term?: yes break]
				line: line + as-integer line-table/class
				p: p + 1
			]
			unless term? [
				index: state * (size? character-classes!) + C_EOF
				state: as-integer transitions/index
			]
			assert state <= T_CMT
			assert start + offset <= p
			
			lex/in-pos: p
			lex/line:   line
			lex/nline:  line - mark
			lex/exit:   state
			lex/type:	-1
			
			index: state - --EXIT_STATES--
			do-scan: as scanner! scanners/index
			do-scan lex start + offset p flags
			
			if all [lex/entry = S_PATH state <> T_PATH][
				scan-path-item lex start + offset lex/in-pos flags ;-- lex/in-pos could have changed
			]
			lex/in-pos >= lex/in-end
		]
		assert lex/in-pos = lex/in-end
	]

	scan: func [
		dst [red-value!]								;-- destination slot
		src [byte-ptr!]									;-- UTF-8 buffer
		len [integer!]									;-- buffer size in bytes
		/local
			blk	  [red-block!]
			slots [integer!]
			s	  [series!]
			lex	  [state! value]
	][
		if zero? depth [root-state: lex]
		depth: depth + 1
		
		lex/next:		null							;-- last element of the states linked list
		lex/buffer:		stash							;TBD: support dyn buffer case
		lex/head:		stash
		lex/tail:		stash
		lex/slots:		stash-size						;TBD: support dyn buffer case
		lex/input:		src
		lex/in-end:		src + len
		lex/in-pos:		src
		lex/entry:		S_START
		lex/type:		-1
		lex/mstr-nest:	0
		
		scan-tokens lex

		slots: (as-integer lex/tail - lex/buffer) >> 4
		store-any-block dst lex/buffer slots TYPE_BLOCK
		
		depth: depth - 1
		if zero? depth [root-state: null]
	]
	
	init: func [][
		stash: as cell! allocate stash-size * size? cell!
		
		;-- switch following tables to zero-based indexing
		lex-classes: lex-classes + 1
		transitions: transitions + 1
		skip-table: skip-table + 1
		line-table: line-table + 1
		
		date-classes: date-classes + 1
		date-transitions: date-transitions + 1
		date-cumul: date-cumul + 1
		fields-table: fields-table + 1
		fields-ptr-table: fields-ptr-table + 1
		reset-table: reset-table + 1
	]

]