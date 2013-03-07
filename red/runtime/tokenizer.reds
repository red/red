Red/System [
	Title:   "Red data loader"
	Author:  "Nenad Rakocevic"
	File: 	 %tokenizer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]


tokenizer: context [

	#enum errors! [
		ERR_PREMATURE_END
		ERR_STRING_DELIMIT
		ERR_INVALID_INTEGER
	]

	throw-error: func [id [integer!]][
		print "*** Load Error: "
		print switch id [
			ERR_PREMATURE_END	["unmatched ] closing bracket"]
			ERR_STRING_DELIMIT 	["string ending delimiter not found"]
			ERR_INVALID_INTEGER	["invalid integer"]
		]
		print-line #"!"
	]
	
	skip-spaces: func [
		src		[c-string!]
		return: [c-string!]
		/local
			c	[byte!]
	][
		while [
			c: src/1
			any [
				c = #" "
				c = #"^/"
				c = #"^M"
				c = #"^-"
			]
		][
			if c = null-byte [return src]
			src: src + 1
		]
		src
	]

	scan-string: func [
		s		[c-string!]
		blk		[red-block!]
		return: [c-string!]
		/local
			e	  [c-string!]
			c	  [byte!]
			saved [byte!]
	][
		s: s + 1										;-- skip first double quote
		e: s + 1
		c: e/1
		
		while [all [c <> null-byte c <> #"^""]][
			e: e + 1
			c: e/1
		]
		if c <> #"^"" [throw-error ERR_STRING_DELIMIT]
		saved: e/1										;@@ allocate a new buffer instead
		e/1: null-byte
		string/load-in s (as-integer e - s) + 1 blk
		e/1: saved
		either c = #"^"" [e + 1][e]
	]
	
	scan-integer: func [
		s		 [c-string!]
		blk		 [red-block!]
		return:  [c-string!]
		/local
			e	 [c-string!]
			c	 [byte!]
			i	 [integer!]
	][
		e: s
		c: e/1
		i: 0
		
		while [
			all [c <> null-byte #"0" <= c c <= #"9"]
		][
			i: i * 10
			i: i + (c - #"0")
			e: e + 1
			c: e/1
		]
		integer/load-in i blk
		e
	]
	
	scan-word: func [
		s		  [c-string!]
		blk		  [red-block!]
		type	  [integer!]
		return:   [c-string!]
		/local
			e	  [c-string!]
			c	  [byte!]
			saved [byte!]
			set?  [logic!]
	][
		e: s + 1
		c: e/1

		while [
			all [
				c <> null-byte
				c <> #" "
				c <> #"^/"
				c <> #"^M"
				c <> #"^-"
				c <> #":"
				c <> #"^""
				c <> #"["
				c <> #"]"
				c <> #"("
				c <> #")"
				c <> #"{"
				c <> #"}"
			]
		][
			e: e + 1
			c: e/1
		]
		set?: e/1 = #":"
		saved: e/1										;@@ allocate a new buffer instead
		e/1: null-byte
		case [
			type = TYPE_GET_WORD	[get-word/load-in s blk]
			type = TYPE_LIT_WORD	[lit-word/load-in s blk]
			type = TYPE_REFINEMENT	[refinement/load-in s blk]
			set?				 	[set-word/load-in s blk]
			true				 	[word/load-in s blk]
		]	
		e/1: saved
		either set? [e + 1][e]
	]
	
	scan-block: func [
		src		[c-string!]
		blk		[red-block!]
		return: [c-string!]
	][
		src: scan src blk
		src + 1											;-- skip ] character
	]
	
	scan-paren: func [
		src		 [c-string!]
		blk		 [red-block!]
		return:  [c-string!]
		/local
			s	 [series!]
			slot [red-value!]
	][
		src: scan src blk
		s: GET_BUFFER(blk)
		slot: s/tail - 1
		slot/header: TYPE_PAREN
		src + 1											;-- skip ) character
		
	]
	
	scan: func [
		src		  [c-string!]
		parent	  [red-block!]
		return:	  [c-string!]
		/local
			blk	  [red-block!]
			start [c-string!]
			end	  [c-string!]
			c	  [byte!]
	][
		blk: either null? parent [
			block/push* 4								;-- arbitrary start size
		][
			block/make-in parent 4						;-- arbitrary start size
		]
		
		while [
			src: skip-spaces src
			c: src/1
			all [
				c <> null-byte
				c <> #"]"
				c <> #")"
			]
		][		
			case [
				c = #"^"" [src: scan-string src blk]
				c = #"["  [src: scan-block src + 1 blk]
				c = #"("  [src: scan-paren src + 1 blk]
				c = #":"  [src: scan-word src + 1 blk TYPE_GET_WORD]
				c = #"'"  [src: scan-word src + 1 blk TYPE_LIT_WORD]
				c = #"/"  [src: scan-word src + 1 blk TYPE_REFINEMENT]
				all [#"0" <= c c <= #"9"][src: scan-integer src blk]
				all [#" " <= c c <= #"ÿ"][src: scan-word src blk TYPE_WORD]
			]
		]	
		if null? parent [
			if src/1 <> null-byte [throw-error ERR_PREMATURE_END]
			stack/set-last as red-value! blk
		]
		src
	]
	
]