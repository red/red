Red/System [
	Title:   "Red/System compiler"
	File: 	 %compiler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

compiler: context [
	#include %utils/vector.reds
	#include %utils/mempool.reds
	#include %utils/hashmap.reds
	#include %parser.reds
	#include %rst-printer.reds
	#include %op-cache.reds
	#include %type-checker.reds

	_mempool: as mempool! 0
	src-blk: as red-block! 0
	script: as cell! 0

	prin-token: func [v [cell!]][
		if null? v [exit]
		#call [prin-cell v]
	]

	;@@ the memory returned should be zeroed
	malloc: func [size [integer!] return: [byte-ptr!]][
		mempool/alloc _mempool size
	]

	calc-line: func [
		pc		[cell!]
		return: [integer!]
		/local
			idx		[integer!]
			beg		[cell!]
			header	[cell!]
			prev	[integer!]
			p		[red-pair!]
	][
		header: block/rs-abs-at src-blk 0
		beg: block/rs-head src-blk
		idx: (as-integer pc - beg) >> 4 + 1 + 2		;-- skip 2 for header: Red/System [...]
		prev: 1

		while [
			header: header + 1
			header < beg
		][
			p: as red-pair! header
			if p/y = idx [return p/x]
			if p/y > idx [return prev]
			prev: p/x
		]
		p/x
	]

	throw-error: func [
		[typed] count [integer!] list [typed-value!]
		/local
			s	[c-string!]
			w	[cell!]
			pc	[cell!]
			p	[cell!]
			h	[integer!]
	][
		pc: as cell! list/value
		list: list + 1
		count: count - 1
		
		prin "*** Parse Error: "
		until [
			either list/type = type-c-string! [
				s: as-c-string list/value prin s
			][
				w: as cell! list/value
				if w <> null [prin-token w]
			]

			count: count - 1	
			if count <> 0 [prin " "]

			list: list + 1
			zero? count
		]
		print "^/*** in file: " prin-token compiler/script
		print ["^/*** at line: " calc-line pc lf]
		p: block/rs-head src-blk
		h: src-blk/head
		src-blk/head: (as-integer pc - p) >> 4 + h
		print "*** near: " #call [prin-block src-blk 200]
		src-blk/head: h
		print "^/"
		quit 1
	]

	comp-dialect: func [
		src		[red-block!]
		job		[red-object!]
		/local
			ctx [context!]
	][
		script: object/rs-select job as cell! word/load "script"
		ctx: parser/parse-context null src null no
		type-checker/check ctx
		rst-printer/print-program ctx
	]

	init: does [
		_mempool: mempool/make
		parser/init
		op-cache/init
		type-system/init
	]

	clean: does [
		mempool/destroy _mempool
	]
]