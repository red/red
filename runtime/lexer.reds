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
]

lexer: context [

	#include %lexer-transitions.reds
		
	#enum class-flags! [
		C_FLAG_UCS4:	80000000h
		C_FLAG_UCS2:	40000000h
		C_FLAG_CARET:	20000000h
		C_FLAG_DOT:		10000000h
		C_FLAG_COMMA:	08000000h
		C_FLAG_COLON:	04000000h
		C_FLAG_QUOTE:	02000000h
		C_FLAG_EXP:		01000000h
		C_FLAG_SHARP:	00800000h
		C_FLAG_EOF:		00400000h
		C_FLAG_SIGN:	00200000h
		C_FLAG_NOSTORE: 00000100h
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
		C_SIGN											;-- 27
		C_CARET											;-- 28
		C_BIN											;-- 29
		C_WORD											;-- 30
		C_ILLEGAL										;-- 31
		C_EOF											;-- 32
	]
	
	line-table: #{
		000100000000000000000000000000000000000000000000000000000000000000
	}
	
	skip-table: #{
		0101000000000000000000000000000000000000000000000000000000000000
		0000000000000000000000000000000000000000000000000000000000000000
		00000000000000
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
		(C_SIGN	or C_FLAG_SIGN)							;-- 2B		+
		(C_COMMA or C_FLAG_COMMA)						;-- 2C		,
		(C_SIGN	or C_FLAG_SIGN)							;-- 2D		-
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
		stack     [red-block!]							;-- pairs of (offset,type)
		buffer    [red-value!]							;-- static or dynamic stash buffer (for recursive calls)
		buf-tail  [red-value!]
		buf-slots [integer!]
		input     [byte-ptr!]
		in-len    [integer!]
		in-pos    [byte-ptr!]
		err	      [integer!]
	]
	
	scanner!: alias function! [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]]

	stash: as cell! 0									;-- special buffer for hatching any-blocks series
	stack: as red-block! 0								;-- nested series stack
	stash-size: 1000									;-- pre-allocated cells	number
	depth: 0											;-- recursive calls depth

	alloc-slot: func [s [state!] return: [red-value!] /local slot [red-value!]][
		if s/buffer + s/buf-slots <= s/buf-tail [
			assert false
			0 ;TBD: expand
		]
		slot: s/buf-tail
		slot/header: TYPE_UNSET
		s/buf-tail: s/buf-tail + 1
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
			blk/header: type
			s: GET_BUFFER(blk)
			copy-memory 
				as byte-ptr! s/offset
				as byte-ptr! src
				items << 4
			s/tail: s/offset + items
		]
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
			p [red-pair!]
	][
		p: as red-pair! ALLOC_TAIL(state/stack)
		p/header: TYPE_PAIR
		p/x: (as-integer state/buf-tail - state/buffer) >> 4
		p/y: either s/1 = #"(" [TYPE_PAREN][TYPE_BLOCK]
		
		alloc-slot state								;-- reserve slot for new block value
		state/buffer: state/buf-tail
		
		state/in-pos: e + 1								;-- skip delimiter
		state/in-len: state/in-len - 1
	]

	scan-block-close: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local	
			p	 [red-pair!]
			new	 [red-value!]
			len	 [integer!]
			type [integer!]
			ser	 [series!]
	][
		ser: GET_BUFFER(state/stack)
		p: as red-pair! ser/tail - 1
		assert TYPE_OF(p) = TYPE_PAIR
		
		type: either s/1 = #")" [TYPE_PAREN][TYPE_BLOCK]
		if p/y <> type [
			0 ; error
		]

		len: (as-integer state/buf-tail - state/buffer) >> 4
		new: state/buffer - 1
		state/buf-tail: state/buffer
		state/buffer: new - p/x

		store-any-block new state/buf-tail len type
	
		ser/tail: as cell! p
		assert ser/offset <= ser/tail
		
		state/in-pos: e + 1								;-- skip ending delimiter
		state/in-len: state/in-len - 1
	]

	scan-string: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			str  [red-string!]
			ser	 [series!]
			len	 [integer!]
			unit [integer!]
			cp	 [integer!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
	][
		s: s + 1										;-- skip start delimiter
		len: as-integer e - s
		unit: 1 << (flags >>> 30)
		if unit > 4 [unit: 4]

		str: string/make-at alloc-slot state len unit
		ser: GET_BUFFER(str)
		
		switch unit [
			UCS-1 [
				either flags and C_FLAG_CARET = 0 [		;-- fast path when no escape sequence
					copy-memory as byte-ptr! ser/offset s len
					ser/tail: as cell! (as byte-ptr! ser/offset) + len
				][										;-- with escape sequence(s)
					0
				]
			]
			UCS-2 [
				either flags and C_FLAG_CARET = 0 [		;-- fast path when no escape sequence
					cp: 0
					p: as byte-ptr! ser/offset
					while [s < e][
						s: decode-utf8-char s :cp
						if cp = -1 [
							0 ; throw error
						]
						p/1: as-byte cp and FFh
						p/2: as-byte cp >> 8
						p: p + 2
					]
				][
					0
				]
			]
			UCS-4 [
				either flags and C_FLAG_CARET = 0 [		;-- fast path when no escape sequence
					cp: 0
					p4: as int-ptr! ser/offset
					while [s < e][
						s: decode-utf8-char s :cp
						if cp = -1 [
							0 ; throw error
						]
						p4/value: cp
						p4: p4 + 1
					]
				][
					0
				]
			]
		]
		state/in-pos: e + 1								;-- skip ending delimiter
		state/in-len: state/in-len - 1
	]
	
	scan-string-multi: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
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
				true	   [throw LEX_ERROR]
			]
		]
		if flags and C_FLAG_QUOTE <> 0 [
			if s/1 = #"'" [s: s + 1 type: TYPE_LIT_WORD]
		]
		cell: alloc-slot state
		word/make-at symbol/make-alt-utf8 s as-integer e - s cell
		cell/header: type
	
		if type = TYPE_SET_WORD [
			state/in-pos: e + 1						;-- skip ending delimiter
			state/in-len: state/in-len - 1		
		]
	]

	scan-file: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]

	scan-refinement: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]

	scan-binary: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	;-- Bit-array for BDELNPTbdelnpt
	char-names-1st: #{0000000000000000345011003450110000000000000000000000000000000000}
	
	;-- Bit-array for /-~^{}"
	char-special: #{0000000004A00000000000400000006800000000000000000000000000000000}
	
	scan-char: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			char  [red-char!]
			p	  [byte-ptr!]
			src	  [byte-ptr!]
			word  [c-string!]
			len	  [integer!]
			c	  [integer!]
			pos	  [integer!]
			pow	  [integer!]
			index [integer!]
			class [integer!]
			skip  [integer!]
			res	  [integer!]
			cp	  [byte!]
			bit	  [byte!]
	][
		assert all [s/1 = #"#" s/2 = #"^"" e/1 = #"^""]
		len: as-integer e - s
		if len = 2 [throw LEX_ERROR]					;-- #""
		
		either s/3 = #"^^" [
			if len = 3 [throw LEX_ERROR]				;-- #"^"
			either s/4 = #"(" [							;-- note: #"^(" not allowed
				c: as-integer s/5
				pos: c >>> 3 + 1
				bit: as-byte 1 << (c and 7)
				either char-names-1st/pos and bit = null-byte [ ;-- hex escaped char
					p: s + 4
					c: 0
					cp: as byte! 0
					pow: 0
					while [any [p/1 <> #")" p < e]][
						if p/1 <> #"0" [
							index: 1 + as-integer p/1
							class: lex-classes/index
							switch class [
								C_DIGIT  [cp: p/1 - #"0"]
								C_ALPHAX [cp: either p/1 < #"a" [p/1 - #"a"][p/1 - #"A"] cp: cp + 10]
								default  [throw LEX_ERROR]
							]
							c: c + ((as-integer cp) << pow)
						]
						pow: pow + 4
						p: p + 1
					]
					if any [p = e p/1 <> #")"][throw LEX_ERROR]
				][										;-- named escaped char
					cp: s/5
					if cp < #"a" [cp: cp or #"^(20)"]
					src: s + 5
					word: switch cp [
						#"n" [c: 00h skip: 4 "ull"]
						#"b" [c: 08h skip: 4 "ack"]
						#"t" [c: 09h skip: 3 "ab" ]
						#"l" [c: 0Ah skip: 4 "ine"]
						#"p" [c: 0Ch skip: 4 "age"]
						#"e" [c: 1Bh skip: 3 "sc" ]
						#"d" [c: 7Fh skip: 3 "el" ]
						default [assert false null]
					]
					res: platform/strnicmp src as byte-ptr! word skip - 1
					if any [res <> 0 src/skip <> #")"][throw LEX_ERROR]
				]
			][
				c: as-integer s/4
				pos: c >>> 3 + 1
				bit: as-byte 1 << (c and 7)
				either char-special/pos and bit = null-byte [ ;-- "regular" escaped char
					if any [s/4 < #"^(40)" #"^(5F)" < s/4][throw LEX_ERROR]
					c: as-integer s/4 - #"@"
				][										;-- escaped special char
					c: as-integer switch s/4 [
						#"/"  [#"^/"]
						#"-"  [#"^-"]
						#"^"" [#"^""]
						#"{"  [#"{" ]
						#"}"  [#"}" ]
						#"^^" [#"^^"]
						#"~"  [#"^~"]
						default [assert false]
					]
				]
			]
		][												;-- simple char
			c: as-integer s/3
		]
		char: as red-char! alloc-slot state
		char/header: TYPE_CHAR
		char/value: c
		
		state/in-pos: e + 1								;-- skip ending delimiter
		state/in-len: state/in-len - 1
	]
	
	scan-map-open: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-construct: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-issue: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-percent: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
		/local
			fl [red-float!]
	][
		assert e/1 = #"%"
		scan-float state s e flags
		fl: as red-float! state/buf-tail - 1
		fl/header: TYPE_PERCENT
		fl/value: fl/value / 100.0
		
		state/in-pos: e + 1								;-- skip ending delimiter
		state/in-len: state/in-len - 1
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
		fl/header: TYPE_FLOAT
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
		cell/header: TYPE_TUPLE or (pos << 19)
		state/in-pos: e									;-- reset the input position to delimiter byte
	]
	
	scan-date: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
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
			index: 1 + as-integer p/1
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
	;	/local
	][
		null
	]
	
	scan-url: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-email: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scan-path: func [state [state!] s [byte-ptr!] e [byte-ptr!] flags [integer!]
	;	/local
	][
		null
	]
	
	scanners: [
		:scan-eof										;-- T_EOF
		:scan-error										;-- T_ERROR
		:scan-block-open								;-- T_BLK_OP
		:scan-block-close								;-- T_BLK_CL
		:scan-block-open								;-- T_PAR_OP
		:scan-block-close								;-- T_PAR_CL
		:scan-string									;-- T_STRING
		:scan-string-multi								;-- T_STR_ALT
		:scan-word										;-- T_WORD
		:scan-file										;-- T_FILE
		:scan-refinement								;-- T_REFINE
		:scan-binary									;-- T_BINARY
		:scan-char										;-- T_CHAR
		:scan-map-open									;-- T_MAP_OP
		:scan-construct									;-- T_CONS_MK
		:scan-issue										;-- T_ISSUE
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
		:scan-path										;-- T_PATH
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
			offset	[integer!]
			s		[series!]
			term?	[logic!]
			do-scan [scanner!]
	][
		line:  1
		until [
			flags: 0
			term?: no
			state: S_START
			p: lex/in-pos
			start: p
			offset: 0
			
			loop lex/in-len [
				cp: 1 + as-integer p/value
				class: lex-classes/cp
				flags: class and FFFFFF00h or flags
				
				index: state * 33 + (class and FFh) + 1
				state: as-integer transitions/index
				
				index: state + 1
				offset: offset + as-integer skip-table/index
				
				index: class and FFh + 1
				line: line + line-table/index
				
				if state > --EXIT_STATES-- [term?: yes break]
				p: p + 1
			]
			unless term? [
				index: state * 33 + C_EOF + 1
				state: as-integer transitions/index
			]
			lex/in-len: lex/in-len - as-integer (p - start)
			lex/in-pos: p
			
			index: state - --EXIT_STATES--
			do-scan: as scanner! scanners/index
			do-scan lex start + offset p flags
			
			lex/in-len <= 1 
		]
		
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
		
		state/stack:	 stack
		state/buffer:	 stash							;TBD: support dyn buffer case
		state/buf-tail:	 stash
		state/buf-slots: stash-size						;TBD: support dyn buffer case
		state/input:	 src
		state/in-len:	 len
		state/in-pos:	 src
		state/err:		 0
		
		catch LEX_ERROR [scan-tokens state]
		if system/thrown > 0 [
			0 ; error handling
		]
		assert block/rs-tail? state/stack					;-- stack should be empty
	
		slots: (as-integer state/buf-tail - state/buffer) >> 4
		store-any-block dst state/buffer slots TYPE_BLOCK
		
		depth: depth - 1
	]
	
	init: func [][
		stash: as cell! allocate stash-size * size? cell!
		stack: block/make-in root 20
	]

]