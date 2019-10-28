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
		C_EXP											;-- 15
		C_ALPHAX										;-- 16
		C_SLASH											;-- 17
		C_BSLASH										;-- 18
		C_LESSER										;-- 19
		C_GREATER										;-- 20
		C_PERCENT										;-- 21
		C_COMMA											;-- 22
		C_SEMICOL										;-- 23
		C_AT											;-- 24
		C_DOT											;-- 25
		C_MONEY											;-- 26
		C_PLUS											;-- 27
		C_MINUS											;-- 28
		C_CARET											;-- 29
		C_BIN											;-- 30
		C_WORD											;-- 31
		C_ILLEGAL										;-- 32
		C_EOF											;-- 33
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
		000100000000000000000000000000000000000000000000000000000000000000
	}
	
	skip-table: #{
		0101000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		00000000000000000000
	}

	path-ending: #{
		010100000101010101000100000100000000000000010001000000000000000001
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
	
	;-- Bit-array for BDELNPTbdelnpt
	char-names-1st: #{0000000000000000345011003450110000000000000000000000000000000000}

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
		C_WORD											;-- 3D		=
		C_GREATER										;-- 3E		>
		C_WORD											;-- 3F		?
		C_AT											;-- 40		@
		C_ALPHAX C_ALPHAX C_ALPHAX C_ALPHAX			 	;-- 41-44	A-D
		(C_EXP or C_FLAG_EXP)							;-- 45		E
		C_ALPHAX										;-- 46		F
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 47-4C	G-L
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 4D-52	M-R
		C_WORD C_WORD C_WORD C_WORD C_WORD 				;-- 53-57	S-W
		C_X												;-- 58		X
		C_WORD C_WORD							 		;-- 59-5A	Y-Z
		C_BLOCK_OP										;-- 5B		[
		C_BSLASH										;-- 5C		\
		C_BLOCK_CL										;-- 5D		]
		(C_CARET or C_FLAG_CARET)						;-- 5E		^
		C_WORD											;-- 5F		_
		C_WORD											;-- 60		`
		C_ALPHAX C_ALPHAX C_ALPHAX C_ALPHAX			 	;-- 61-64	a-d
		(C_EXP or C_FLAG_EXP)							;-- 65		e
		C_ALPHAX										;-- 66		f
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 67-6C	g-l
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
		LEX_ERR_STRING: 1
		
		LEX_ERROR										;-- keep it last
	]
	
	state!: alias struct! [
		buffer	[red-value!]							;-- static or dynamic stash buffer (for recursive calls)
		head	[red-value!]
		tail	[red-value!]
		slots	[integer!]
		input	[byte-ptr!]
		in-end	[byte-ptr!]
		in-pos	[byte-ptr!]
		line	[integer!]								;-- current line number
		nline	[integer!]								;-- new lines count for new token
		err		[integer!]
		entry	[integer!]								;-- entry state for the FSM
	]
	
	scanner!: alias function! [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]]

	stash: as cell! 0									;-- special buffer for hatching any-blocks series
	stash-size: 1000									;-- pre-allocated cells	number
	depth: 0											;-- recursive calls depth

	alloc-slot: func [state [state!] return: [red-value!] /local slot [red-value!]][
		if state/head + state/slots <= state/tail [
			assert false
			0 ;TBD: expand
		]
		slot: state/tail
		slot/header: TYPE_UNSET
		if state/nline > 0 [slot/header: slot/header or flag-new-line]
		state/tail: state/tail + 1
		slot
	]
	
	store-any-block: func [slot [cell!] src [cell!] items [integer!] type [integer!]
		/local
			blk [red-block!]
			s	[series!]
	][
		either zero? items [
			block/make-at as red-block! slot 1
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
	
	open-block: func [state [state!] type [integer!] hint [integer!] 
		/local p [red-point!] len [integer!]
	][
		len: (as-integer state/tail - state/head) >> 4
		p: as red-point! alloc-slot state
		set-type as cell! p TYPE_POINT					;-- use the slot for stack info
		p/x: len
		p/y: type
		p/z: hint
		
		state/head: state/tail							;-- points just after p
		state/entry: S_START
	]

	close-block: func [state [state!] type [integer!] final [integer!]
		return: [integer!]
		/local	
			p	  [red-point!]
			len	  [integer!]
			hint  [integer!]
	][
		p: as red-point! state/head - 1
		assert all [state/buffer <= p TYPE_OF(p) = TYPE_POINT]
		either type = -1 [
			type: either final = -1 [p/y][final]
		][
			if p/y <> type [throw LEX_ERROR]
		]
		len: (as-integer state/tail - state/head) >> 4
		state/tail: state/head
		state/head: as cell! p - p/x
		hint: p/z
		
		store-any-block as cell! p state/tail len type	;-- p slot gets overwritten here
		
		p: as red-point! state/head - 1					;-- get parent series
		either all [
			state/buffer <= p
			not any [p/y = TYPE_BLOCK p/y = TYPE_PAREN p/y = TYPE_MAP]
		][												;-- any-path! case
			state/entry: S_PATH
		][
			state/entry: S_START
		]
		hint
	]
	
	decode-2: func [s [byte-ptr!] e [byte-ptr!] ser [series!]
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
					default [throw LEX_ERROR]
				]
			]
			if all [cnt <> 0 cnt <> 8][throw LEX_ERROR]
			p/value: as byte! c
			p: p + 1
		]
		ser/tail: as cell! p
	]
	
	decode-16: func [s [byte-ptr!] e [byte-ptr!] ser [series!]
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
			until [								;-- scans 2 hex characters, skip the rest
				index: 1 + as-integer s/1
				class: as-integer bin16-classes/index
				s: s + 1
				index: fstate * 5 + class + 1
				fstate: as-integer bin16-FSM/index
				any [fstate - S_BIN_FINAL_STATES > 0 s >= e]
			]
			if fstate = T_BIN_ERROR [throw LEX_ERROR]
			index: 1 + as-integer pos/1			;-- converts the 2 hex chars using tables
			c: as-integer hexa-table/index
			index: 1 + as-integer pos/2
			p/value: as byte! c << 4 or as-integer hexa-table/index
			p: p + 1
		]
		ser/tail: as cell! p
	]
	
	decode-64: func [s [byte-ptr!] e [byte-ptr!] ser [series!]
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
						true [throw LEX_ERROR]
					]
					break
				]
			][
				if val = 80h [throw LEX_ERROR]
			]
			s: s + 1
		]
		ser/tail: as red-value! p
	]
	
	scan-percent-char: func [s [byte-ptr!] e [byte-ptr!] cp [int-ptr!] return: [byte-ptr!]
		/local
			c	  [integer!]
			c2	  [integer!]
			index [integer!]
	][
		if s + 1 >= e [throw LEX_ERROR]
		c: 0
		index: 1 + as-integer s/1						;-- converts the 2 hex chars using a lookup table
		c: as-integer hexa-table/index					;-- decode high nibble
		index: 1 + as-integer s/2
		c2: as-integer hexa-table/index					;-- decode low nibble
		if any [c = -1 c2 = -1][throw LEX_ERROR]
		cp/value: c << 4 or c2
		s + 2
	]
	
	scan-escaped-char: func [s [byte-ptr!] e [byte-ptr!] cp [int-ptr!] return: [byte-ptr!]
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
			c: as-integer s/2
			pos: c >>> 3 + 1
			bit: as-byte 1 << (c and 7)
			either char-names-1st/pos and bit = null-byte [ ;-- hex escaped char @@ "e" as 1st!
				p: s + 1
				c: 0
				cb: as byte! 0
				while [all [p/1 <> #")" p < e]][
					index: 1 + as-integer p/1			;-- converts the 2 hex chars using a lookup table
					cb: hexa-table/index				;-- decode one nibble at a time
					if cb = #"^(FF)" [throw LEX_ERROR]
					c: c << 4 + as-integer cb
					p: p + 1
				]
				if any [p = e p/1 <> #")" (as-integer p - s) > 7][throw LEX_ERROR] ;-- limit of 6 hexa characters.
				p: p + 1								;-- skip )
			][											;-- named escaped char
				src: s + 1								;-- skip (
				entry: escape-names
				loop 7 [
					if zero? platform/strnicmp src as byte-ptr! entry/1 entry/2 [break]
					entry: entry + 3
				]
				assert escape-names + (7 * 3) > entry 
				len: entry/2 + 1
				if src/len <> #")" [throw LEX_ERROR]
				c: entry/3
				p: src + len
			]
		][
			c: as-integer s/1
			pos: c >>> 3 + 1
			bit: as-byte 1 << (c and 7)
			either char-special/pos and bit = null-byte [ ;-- "regular" escaped char
				if any [s/1 < #"^(40)" #"^(5F)" < s/1][throw LEX_ERROR]
				c: as-integer s/1 - #"@"
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

	scan-eof: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-error: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-block-open: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			type [integer!]
	][
		type: either s/1 = #"(" [TYPE_PAREN][TYPE_BLOCK]
		open-block state type -1
		state/in-pos: e + 1								;-- skip delimiter
	]

	scan-block-close: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		close-block state TYPE_BLOCK -1
		state/in-pos: e	+ 1								;-- skip ]
	]
	
	scan-paren-close: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			blk	 [red-block!]
	][
		if TYPE_MAP = close-block state TYPE_PAREN -1 [
			blk: as red-block! state/tail - 1
			map/make-at as cell! blk blk block/rs-length? blk
		]
		state/in-pos: e	+ 1								;-- skip )
	]

	scan-string: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
			esc	   [byte!]
			w?	   [logic!]
			c	   [byte!]
	][
		s: s + 1										;-- skip start delimiter
		len: as-integer e - s
		unit: 1 << (flags >>> 30)
		if unit > 4 [unit: 4]

		either flags and C_FLAG_CARET = 0 [				;-- fast path when no escape sequence
			str: string/make-at alloc-slot state len unit
			ser: GET_BUFFER(str)
			switch unit [
				UCS-1 [copy-memory as byte-ptr! ser/offset s len]
				UCS-2 [
					cp: -1
					p: as byte-ptr! ser/offset
					while [s < e][
						s: decode-utf8-char s :cp
						if cp = -1 [throw LEX_ERROR]
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
						if cp = -1 [throw LEX_ERROR]
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
								class: lex-classes/index
								switch class [
									C_DIGIT C_ZERO C_ALPHAX C_EXP [0]
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
			
			str: string/make-at alloc-slot state len - extra unit
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
						if cp = -1 [throw LEX_ERROR]
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
						if cp = -1 [throw LEX_ERROR]
						p4/value: cp
						p4: p4 + 1
					]
					ser/tail: as cell! p4
				]
			]
			assert (as byte-ptr! ser/offset) + ser/size > as byte-ptr! ser/tail
		]
		state/in-pos: e + 1								;-- skip ending delimiter
	]
	
	scan-word: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			type [integer!]
	][
		type: TYPE_WORD
		if flags and C_FLAG_COLON <> 0 [
			case [
				s/1 = #":" [s: s + 1 type: TYPE_GET_WORD]
				e/0 = #":" [e: e - 1 type: TYPE_SET_WORD]
				all [e/1 = #":" state/entry = S_PATH][0] ;-- do nothing if in a path
				true	   [throw LEX_ERROR]
			]
		]
		if s/1 = #"'" [s: s + 1 type: TYPE_LIT_WORD]

		cell: alloc-slot state
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		set-type cell type
	
		if type = TYPE_SET_WORD [state/in-pos: e + 1]	;-- skip ending delimiter
	]

	scan-file: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			p	 [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		either s/2 = #"^"" [s: s + 1][					;-- skip "
			p: s until [p: p + 1 any [p/1 = #"%" p = e]] ;-- check if any %xx 
			if p < e [flags: flags or C_FLAG_ESC_HEX or C_FLAG_CARET]
		]
		scan-string state s e flags
		cell: state/tail - 1
		set-type cell TYPE_FILE							;-- preserve header's flags
		if s/1 = #"^"" [assert e/1 = #"^"" e: e + 1]
		state/in-pos: e 								;-- reset the input position to delimiter byte
	]

	scan-binary: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			bin	 [red-binary!]
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
			default [throw LEX_ERROR 0]
		]
		bin: binary/make-at alloc-slot state size
		ser: GET_BUFFER(bin)
		switch base [
			16 [decode-16 s e ser]
			64 [decode-64 s e ser]
			 2 [decode-2  s e ser]
			default [assert false 0]
		]
		assert (as byte-ptr! ser/offset) + ser/size > as byte-ptr! ser/tail
		state/in-pos: e + 1								;-- skip }
	]
	
	scan-char: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			char  [red-char!]
			len	  [integer!]
			c	  [integer!]
	][
		assert all [s/1 = #"#" s/2 = #"^"" e/1 = #"^""]
		len: as-integer e - s
		if len = 2 [throw LEX_ERROR]					;-- #""
		
		either s/3 = #"^^" [
			if len = 3 [throw LEX_ERROR]				;-- #"^"
			c: -1
			scan-escaped-char s + 3 e :c
		][												;-- simple char
			c: as-integer s/3
		]
		if c > 0010FFFFh [throw LEX_ERROR]
		
		char: as red-char! alloc-slot state
		set-type as cell! char TYPE_CHAR
		char/value: c
		
		state/in-pos: e + 1								;-- skip "
	]
	
	scan-map-open: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]][
		open-block state TYPE_PAREN TYPE_MAP
		state/in-pos: e + 1								;-- skip (
	]
	
	scan-construct: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
		end: p + (3 * 4)								;-- point to end of array
		loop 4 [
			if zero? platform/strnicmp s as byte-ptr! p/1 p/2 [break]
			p: p + 3
		]
		if p = end [throw LEX_ERROR]					;-- no match, error case
		len: p/2 + 1
		if s/len <> #"]" [throw LEX_ERROR]
		
		dt: as red-datatype! alloc-slot state
		either p < dtypes [
			set-type as cell! dt TYPE_LOGIC
			dt/value: p/3
		][
			set-type as cell! dt p/3
		]
		state/in-pos: e + 1								;-- skip ]
	]
	
	scan-ref-issue: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			type [integer!]
	][
		type: either s/1 = #"#" [TYPE_ISSUE][assert s/1 = #"/" TYPE_REFINEMENT]
		s: s + 1
		cell: alloc-slot state
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		set-type cell type
		state/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-percent: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			fl [red-float!]
	][
		assert e/1 = #"%"
		scan-float state s e flags
		fl: as red-float! state/tail - 1
		set-type as cell! fl TYPE_PERCENT
		fl/value: fl/value / 100.0
		
		state/in-pos: e + 1								;-- skip ending delimiter
	]
		
	scan-integer: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		return: [integer!]
		/local
			p	[byte-ptr!]
			len [integer!]
			i	[integer!]
	][
		p: s
		if flags and C_FLAG_SIGN <> 0 [p: p + 1]		;-- skip sign if present
		
		either (as-integer e - p) = 1 [					;-- fast path for 1-digit integers
			i: as-integer (p/1 - #"0")
		][
			len: as-integer e - p
			if len > 10 [
				scan-float state s e flags				;-- overflow, fall back on float
				return 0
			]
			i: 0
			either flags and C_FLAG_QUOTE = 0 [			;-- no quote, faster path
				loop len [
					i: 10 * i + as-integer (p/1 - #"0")
					p: p + 1
				]
			][											;-- process with quote(s)
				loop len [
					if e/1 <> #"'" [i: 10 * i + as-integer (p/1 - #"0")]
					p: p + 1
				]
			]
			assert p = e
		]
		if s/value = #"-" [i: 0 - i]
		if flags and C_FLAG_NOSTORE = 0 [
			integer/make-at alloc-slot state i
		]
		state/in-pos: e									;-- reset the input position to delimiter byte
		i
	]
	
	scan-float: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			fl	[red-float!]
			err	[integer!]
	][
		err: 0
		fl: as red-float! alloc-slot state
		set-type as cell! fl TYPE_FLOAT
		fl/value: red-dtoa/string-to-float s e :err
		if err <> 0 [throw LEX_ERROR]
		state/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-tuple: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			i	 [integer!]
			pos  [integer!]
			tp	 [byte-ptr!]
			p	 [byte-ptr!]
	][
		cell: alloc-slot state
		tp: (as byte-ptr! cell) + 4
		pos: 0
		i: 0
		p: s

		loop as-integer e - s [
			either p/1 = #"." [
				pos: pos + 1
				if any [i < 0 i > 255 pos > 12][throw LEX_ERROR]
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
		state/in-pos: e									;-- reset the input position to delimiter byte
	]

	scan-date: func [lex [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			field [int-ptr!]
			state [integer!]
			class [integer!]
			index [integer!]
			cp	  [integer!]
			c	  [integer!]
			pos	  [integer!]
			month [integer!]
	][
;probe "scan-date"
		field: system/stack/allocate/zero 12
		c: 0
		state: S_DT_START
		loop as-integer e - s [
;probe ["--- " s/1 " ---"]
			cp: as-integer s/1
			class: as-integer date-classes/cp
;?? class
			index: state * (size? date-char-classes!) + class
			state: as-integer date-transitions/index
			
			pos: as-integer fields-table/state
			field/pos: c
;?? state
;?? cp
			c: either null-byte = reset-table/state [
				 c * 10 + as-integer date-cumul/cp
			][0]
;?? c
			s: s + 1
;?? c
		]
		
		index: state * (size? date-char-classes!) + C_DT_EOF
		state: as-integer date-transitions/index
;?? state
		pos: as-integer fields-table/state
;?? pos
		field/pos: c
		
		month: field/3
		if any [month > 12 month < 1][					;-- month as a word	
			month: switch month [						;-- convert hashed word to correct value
				8128 81372323	[1]
				7756 776512323	[2]
				8432 843942		[3]
				7382 739006		[4]
				8353			[5]						;-- "May" has no longer form
				8328 83349		[6]
				8326 83263		[7]
				7421 7430330	[8]
				9070 480839780	[9]
				8570 85786372	[10]
				8676 868374372	[11]
				7557 756474372	[12]
				default 		[throw LEX_ERROR 0]
			]
			field/3: month
		]
comment {
		probe [
			"-----------------"
			"^/trash: "	field/1
			"^/year : " field/2
			"^/month: " field/3
			"^/day  : " field/4
			"^/hour : " field/5
			"^/min  : " field/6
			"^/sec  : " field/7
			"^/nano : " field/8
			"^/week : " field/9
			"^/wday : " field/10
			"^/TZ-h : " field/11
			"^/TZ-m : " field/12
		]
}		
		date/set-all
			 as red-date! alloc-slot lex
			 field/2									;-- year 
			 field/3									;-- month
			 field/4									;-- day  
			 field/5									;-- hour 
			 field/6									;-- min  
			 field/7									;-- sec  
			 field/8									;-- nano
	]
	
	scan-pair: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
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
			alloc-slot state
			scan-integer state s p flags or C_FLAG_NOSTORE
			scan-integer state p + 1 e flags or C_FLAG_NOSTORE

		state/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-time: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-money: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-tag: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		scan-string state s e flags
		cell: state/tail - 1
		set-type cell TYPE_TAG							;-- preserve header's flags
		state/in-pos: e + 1								;-- skip ending delimiter
	]
	
	scan-url: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			p	 [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		p: s while [all [p/1 <> #"%" p < e]][p: p + 1] 	;-- check if any %xx 
		if p < e [flags: flags or C_FLAG_ESC_HEX or C_FLAG_CARET]
		scan-string state s - 1 e flags					;-- compensate for lack of starting delimiter
		cell: state/tail - 1
		set-type cell TYPE_URL							;-- preserve header's flags
		state/in-pos: e 								;-- reset the input position to delimiter byte
	]
	
	scan-email: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			cell [cell!]
			p	 [byte-ptr!]
	][
		flags: flags and not C_FLAG_CARET				;-- clears caret flag
		scan-string state s - 1 e flags					;-- compensate for lack of starting delimiter
		cell: state/tail - 1
		set-type cell TYPE_EMAIL						;-- preserve header's flags
		state/in-pos: e 								;-- reset the input position to delimiter byte
	]
	
	scan-path-open: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			type [integer!]
	][
		type: switch s/1 [
			#"'" [s: s + 1 flags: flags and not C_FLAG_QUOTE TYPE_LIT_PATH]
			#":" [s: s + 1 flags: flags and not C_FLAG_COLON TYPE_GET_PATH]
			default [TYPE_PATH]
		]
		open-block state type -1						;-- open a new path series
		scan-word state s e flags						;-- load the head word
		state/entry: S_PATH								;-- overwrites the S_START set by open-block
		state/in-pos: e + 1								;-- skip /
	]
	
	scan-path-item: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			type	[integer!]
			cp		[integer!]
			index	[integer!]
			close?	[logic!]
	][
		close?: either e >= state/in-end [yes][			;-- EOF reached
			cp: as-integer e/1
			index: lex-classes/cp and FFh + 1			;-- query the class of ending character
			as-logic path-ending/index					;-- lookup if the character class is ending path
		]
		either close? [
			type: either all [e < state/in-end e/1 = #":"][
				state/in-pos: e + 1						;-- skip :
				TYPE_SET_PATH
			][-1]
			close-block state -1 type
		][
			if all [e < state/in-end e/1 = #":"][throw LEX_ERROR] ;-- set-words not allowed inside paths
			state/in-pos: e + 1							;-- skip /
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
		:scan-tuple										;-- T_TUPLE
		:scan-date										;-- T_DATE
		:scan-pair										;-- T_PAIR
		:scan-time										;-- T_TIME
		:scan-money										;-- T_MONEY
		:scan-tag										;-- T_TAG
		:scan-url										;-- T_URL
		:scan-email										;-- T_EMAIL
		:scan-path-open									;-- T_PATH
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
		line:  1
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
				line: line + line-table/class
				
				if state > --EXIT_STATES-- [term?: yes break]
				p: p + 1
			]
			unless term? [
				index: state * (size? character-classes!) + C_EOF
				state: as-integer transitions/index
			]
			lex/in-pos: p
			lex/line: line
			lex/nline: line - mark
			
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
			state [state! value]
	][
		depth: depth + 1
		
		state/buffer: stash								;TBD: support dyn buffer case
		state/head:	  stash
		state/tail:	  stash
		state/slots:  stash-size						;TBD: support dyn buffer case
		state/input:  src
		state/in-end: src + len
		state/in-pos: src
		state/err:	  0
		state/entry:  S_START
		
		catch LEX_ERROR [scan-tokens state]
		if system/thrown > 0 [
			probe "Syntax error"						;TBD: error handling
		]
		slots: (as-integer state/tail - state/head) >> 4
		store-any-block dst state/head slots TYPE_BLOCK
		
		depth: depth - 1
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
		reset-table: reset-table + 1
	]

]