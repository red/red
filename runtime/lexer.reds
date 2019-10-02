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
	
	#enum lex-states! [
		S_START
		S_BLANK
		S_LINE_CMT
		S_LINE_STR
		S_SKIP_STR
		S_M_STRING
		S_SKIP_MSTR
		S_FILE_1ST
		S_FILE
		S_SKIP_FILE
		S_SLASH
		S_SHARP
		S_BINARY
		S_LINE_CMT2
		S_CHAR
		S_SKIP_CHAR
		S_CONSTRUCT
		S_ISSUE
		S_NUMBER
		S_DOTNUM
		S_DECIMAL
		S_DEC_SPECIAL
		S_TUPLE
		S_DATE
		S_TIME_1ST
		S_TIME
		S_PAIR_1ST
		S_PAIR
		S_MONEY_1ST
		S_MONEY
		S_MONEY_DEC
		S_LESSER
		S_TAG
		S_TAG_STR
		S_SKIP_STR2
		S_TAG_STR2
		S_SKIP_STR3
		S_SIGN
		S_WORD
		S_WORDSET
		S_URL
		S_EMAIL
		--EXIT_STATES--
		T_EOF
		T_ERROR
		T_BLK_OP
		T_BLK_CL
		T_PAR_OP
		T_PAR_CL
		T_STRING
		T_STR_ALT
		T_WORD
		T_FILE
		T_REFINE
		T_BINARY
		T_CHAR
		T_MAP_OP
		T_CONS_MK
		T_ISSUE
		T_PERCENT
		T_INTEGER
		T_FLOAT
		T_TUPLE
		T_DATE
		T_PAIR
		T_TIME
		T_MONEY
		T_TAG
		T_URL
		T_EMAIL
		T_PATH	
	]
	
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
	
	utf8d: [ ;[byte! 8]
		; The first part of the table maps bytes to character classes that
		; to reduce the size of the transition table and create bitmasks.
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1   9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 
		7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7   7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 
		8 8 2 2 2 2 2 2 2 2 2 2 2 2 2 2   2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 
		10 3 3 3 3 3 3 3 3 3 3 3 3 4 3 3  11 6 6 6 5 8 8 8 8 8 8 8 8 8 8 8 
	
		; The second part is a transition table that maps a combination
		; of a state of the automaton and a character class to a state.
		0  12 24 36 60 96 84 12 12 12 48 72  12 12 12 12 12 12 12 12 12 12 12 12 
		12  0 12 12 12 12 12  0 12  0 12 12  12 24 12 12 12 12 12 24 12 24 12 12 
		12 12 12 12 12 12 12 24 12 12 12 12  12 24 12 12 12 12 12 12 12 24 12 12 
		12 12 12 12 12 12 12 36 12 36 12 12  12 36 12 12 12 12 12 36 12 36 12 12 
		12 36 12 12 12 12 12 12 12 12 12 12  
	]
	
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
			type: utf8d/idx
			
			idx: 256 + state + type + 1
			state: utf8d/idx
			
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