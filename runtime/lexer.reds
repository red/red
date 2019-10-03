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
		C_UCS2
		C_UCS4
		C_NO_OP
		C_WORD
		C_ILLEGAL
		C_EOF
	]
	
	lex-classes: [
		C_EOF											;-- 00, NUL
		C_NO_OP											;-- 01
		C_NO_OP											;-- 02
		C_NO_OP											;-- 03
		C_NO_OP											;-- 04
		C_NO_OP											;-- 05
		C_NO_OP											;-- 06
		C_NO_OP											;-- 07
		C_NO_OP											;-- 08
		C_BLANK											;-- 09 TAB
		C_BLANK											;-- 0A LF
		C_NO_OP											;-- 0B
		C_NO_OP											;-- 0C
		C_BLANK											;-- 0D CR
		;...
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