Red/System [
	Title:   "String! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %string.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

string: context [
	verbose: 0
	
	make-from: func [
		parent	[red-block!]
		s 		[c-string!]								;-- input string buffer
		return:	[node!]
		/local 
			size [integer!]
			series [series!]
			p	 [node!]
			str	 [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/make-from"]]
		
		size: system/words/length? s
		p: alloc-series size 1 0						;-- align string data to head of buffer 
		series: as series! p/value 
		copy-memory 
			as byte-ptr! series/offset
			as byte-ptr! s
			size
		series/tail: as cell! (as byte-ptr! series/tail) + size
		
		assert (as byte-ptr! series/tail) < ((as byte-ptr! series) + series/size)

		str: as red-string! ALLOC_TAIL(parent)
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		str/node: p
		
		p
	]
	
	rs-make-at: func [
		slot	[cell!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[node!]
		/local 
			p	[node!]
			str	[red-string!]
	][
		p: alloc-series size 1 0
		set-type slot TYPE_STRING						;@@ decide to use or not 'set-type...
		str: as red-string! slot
		str/head: 0
		str/node: p
		p
	]
	
	append-char: func [
		s		[series!]
		cp		[integer!]								;-- codepoint
		/local
			p1	[byte-ptr!]
			p4	[int-ptr!]
	][
		switch GET_UNIT(s) [
			Latin1 [
				case [
					cp <= FFh [
						p1: alloc-tail-unit s 1
						p1/value: as-byte cp
					]
					cp <= FFFFh [
						s: unicode/latin1-to-UCS2 s
						append-char s cp
					]
					true [
						s: unicode/UCS2-to-UCS4 s
						append-char s cp
					]
				]
			]
			UCS-2 [
				either cp <= FFFFh [
					p1: alloc-tail-unit s 2
					p1/1: as-byte (cp and FFh)
					p1/2: as-byte (cp >> 8)
				][
					s: unicode/UCS2-to-UCS4 s
					append-char s cp
				]
			]
			UCS-4 [
				p4: as int-ptr! alloc-tail-unit s 4
				p4/value: cp
			]
		]
	]
	
	push: func [
		src		[c-string!]								;-- UTF-8 source string buffer
		return: [red-value!]
		/local
			str  [red-string!]
			size [integer!]
	][
		size: 1 + length? src
		str: as red-string! stack/push
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		str/node: unicode/load-utf8 src size			;@@ try to avoid length? call
		str/cache: either size < 64 [src][null]			;-- cache only small strings (experimental)
		as red-value! str
	]
	
	;-- Actions -- 
	
	make: func [
	
	][
	
	]
	
	form: func [
		part 		[integer!]
		return: 	[integer!]
		/local
			arg		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/form"]]

		arg: stack/arguments
		copy-cell 
			arg
			arg + 1										;@@ free allocated series in actions/form!!
		part											;@@ implement full support for /part
	]

	
	datatype/register [
		TYPE_STRING
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		:form
		null			;mold
		null			;get-path
		null			;set-path		
		;-- Scalar actions --
		null			;absolute
		null			;add
		null			;divide
		null			;multiply
		null			;negate
		null			;power
		null			;remainder
		null			;round
		null			;subtract
		null			;even?
		null			;odd?
		;-- Bitwise actions --
		null			;and~
		null			;complement
		null			;or~
		null			;xor~
		;-- Series actions --
		null			;append
		null			;at
		null			;back
		null			;change
		null			;clear
		null			;copy
		null			;find
		null			;head
		null			;head?
		null			;index-of
		null			;insert
		null			;length-of
		null			;next
		null			;pick
		null			;poke
		null			;remove
		null			;reverse
		null			;select
		null			;sort
		null			;skip
		null			;swap
		null			;tail
		null			;tail?
		null			;take
		null			;trim
		;-- I/O actions --
		null			;create
		null			;close
		null			;delete
		null			;modify
		null			;open
		null			;open?
		null			;query
		null			;read
		null			;rename
		null			;update
		null			;write
	]
]