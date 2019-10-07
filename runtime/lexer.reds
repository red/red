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
		C_FLAG_UCS4:		80000000h
		C_FLAG_UCS2:		40000000h
		C_FLAG_CARET:		20000000h
		C_FLAG_DOT:			10000000h
		C_FLAG_COMMA:		08000000h
		C_FLAG_COLON:		04000000h
		C_FLAG_QUOTE:		02000000h
		C_FLAG_EXP:			01000000h
		C_FLAG_SHARP:		00800000h
	]
	
	#define F_UCS4		[(C_WORD  or C_FLAG_UCS4)]
	#define F_UCS2		[(C_WORD  or C_FLAG_UCS2)]
	#define F_CARET		[(C_CARET or C_FLAG_CARET)]
	#define F_DOT		[(C_DOT   or C_FLAG_DOT)]
	#define F_COMMA		[(C_COMMA or C_FLAG_COMMA)]
	#define F_COLON		[(C_COLON or C_FLAG_COLON)]
	#define F_QUOTE		[(C_QUOTE or C_FLAG_QUOTE)]
	#define F_EXP		[(C_EXP   or C_FLAG_EXP)]
	#define F_SHARP		[(C_SHARP or C_FLAG_SHARP)]

	#enum character-classes! [
		C_BLANK
		C_LINE
		C_DIGIT
		C_ZERO
		C_BLOCK_OP
		C_BLOCK_CL
		C_PAREN_OP
		C_PAREN_CL
		C_STRING_OP
		C_STRING_CL
		C_DBL_QUOTE
		C_SHARP
		C_QUOTE
		C_COLON
		C_X
		C_EXP
		C_ALPHAX
		C_SLASH
		C_BSLASH
		C_LESSER
		C_GREATER
		C_PERCENT
		C_COMMA
		C_SEMICOL
		C_AT
		C_DOT
		C_MONEY
		C_SIGN
		C_CARET
		C_BIN
		C_WORD
		C_ILLEGAL
		C_EOF
	]

	lex-classes: [
		C_EOF											;-- 00		NUL
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN	;-- 01-08
		C_BLANK											;-- 09		TAB
		C_BLANK 										;-- 0A		LF
		C_BIN											;-- 0B
		C_BIN											;-- 0C
		C_BLANK											;-- 0D		CR
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN	;-- 0E-15
		C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN C_BIN	;-- 16-1D
		C_BIN C_BIN										;-- 1E-1F
		C_BLANK											;-- 20
		C_WORD											;-- 21		!
		C_DBL_QUOTE										;-- 22		"
		F_SHARP											;-- 23		#
		C_MONEY											;-- 24		$
		C_PERCENT										;-- 25		%
		C_WORD											;-- 26		&
		F_QUOTE											;-- 27		'
		C_PAREN_OP										;-- 28		(
		C_PAREN_CL										;-- 29		)
		C_WORD											;-- 2A		*
		C_SIGN											;-- 2B		+
		F_COMMA											;-- 2C		,
		C_SIGN											;-- 2D		-
		F_DOT											;-- 2E		.
		C_SLASH											;-- 2F		/
		C_ZERO											;-- 30		0
		C_DIGIT C_DIGIT C_DIGIT C_DIGIT C_DIGIT			;-- 31-35	1-5
		C_DIGIT C_DIGIT C_DIGIT C_DIGIT					;-- 36-39	6-9
		F_COLON											;-- 3A		:
		C_SEMICOL										;-- 3B		;
		C_LESSER										;-- 3C		<
		C_WORD											;-- 3D		=
		C_GREATER										;-- 3E		>
		C_WORD											;-- 3F		?
		C_AT											;-- 40		@
		C_ALPHAX C_ALPHAX C_ALPHAX C_ALPHAX			 	;-- 41-44	A-D
		F_EXP											;-- 45		E
		C_ALPHAX										;-- 46		F
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 47-4C	G-L
		C_WORD C_WORD C_WORD C_WORD C_WORD C_WORD 		;-- 4D-52	M-R
		C_WORD C_WORD C_WORD C_WORD C_WORD 				;-- 53-57	S-W
		C_X												;-- 58		X
		C_WORD C_WORD							 		;-- 59-5A	Y-Z
		C_BLOCK_OP										;-- 5B		[
		C_BSLASH										;-- 5C		\
		C_BLOCK_CL										;-- 5D		]
		F_CARET											;-- 5E		^
		C_WORD											;-- 5F		_
		C_WORD											;-- 60		`
		C_ALPHAX C_ALPHAX C_ALPHAX C_ALPHAX			 	;-- 61-64	a-d
		F_EXP											;-- 65		e
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
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2;-- C2-C8
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2;-- C9-CF
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2;-- D0-D6
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2;-- D7-DD
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2;-- DE-E4
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2 F_UCS2;-- E5-EB
		F_UCS2 F_UCS2 F_UCS2 F_UCS2 C_WORD C_WORD C_WORD;-- EC-F2
		F_UCS4 F_UCS4									;-- F3-F4
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
		parent   [red-block!]							;-- any-block! accepted
		buffer	 [red-value!]							;-- special buffer for hatching any-blocks
		buf-head [red-value!]
		buf-tail [red-value!]
		head     [byte-ptr!]
		remain   [integer!]
		pos      [byte-ptr!]
		err	     [integer!]
	]
	
	scanner!: alias function! [state [state!] return: [byte-ptr!]]


	scan-string: func [state [state!] return: [byte-ptr!]
		/local
			p [byte-ptr!]
			e [byte-ptr!]
			c [byte!]
	][
		p: state/pos
		e: state/pos + state/remain
		while [c: p/value all [p < e c <> #"^""]][
			either c = #"^^" [p: p + 2][
				if c = #"^/" [state/pos: p throw LEX_ERR_STRING]
				p: p + 1
			]
		]
		
		e: p
		p: state/pos
		;decode/converte the string
		
		p
	]

	scan-alt-string: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-block: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-paren: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-paren-close: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-comment: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-file: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-refinement: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-money: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-lesser: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-lit: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-get: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-sharp: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-tokens: func [
		lex [state!]
		/local
			parent	[red-block!]
			p		[byte-ptr!]
			e		[byte-ptr!]
			cp		[integer!]
			class	[integer!]
			index	[integer!]
			state	[integer!]
			line	[integer!]
			s		[series!]
	][
		parent: lex/parent
		s:  GET_BUFFER(parent)
		p:  lex/pos
		state: 0
		line: 1

		loop lex/remain [
			cp: 1 + as-integer p/value
			class: lex-classes/cp		
			index: state + class + 1
			state: as-integer transitions/index
			;line: line + line-table/class
			p: p + 1
			if state > --EXIT_STATES-- [break]
		]

		lex/remain: as-integer p - lex/pos
		lex/pos: p
		
		
	]
	
	scan: func [
		dst [red-block!]								;-- destination block
		src [byte-ptr!]									;-- UTF-8 buffer
		len [integer!]									;-- buffer size in bytes
		/local
			stack [red-block!]
			state [state! value]
	][
		state/parent: block/make-in dst 100
		state/buffer: as cell! alloc-big 1000 * size? cell!
		state/buf-head: state/buffer
		state/buf-tail: state/buffer + 1000
		state/head: src
		state/remain: len
		state/pos:  src
		state/err:  0
		
		catch LEX_ERROR [scan-tokens state]
		if system/thrown > 0 [
			0 ; error handling
		]
	]
	
	init: func [][
	
	]

]