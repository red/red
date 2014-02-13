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

	#define NOT_DELIMITER?(c) [
		all [
			c <> null-byte
			c <> #" "
			c <> #"/"
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
			c <> #";"
		]
	]
	
	#define NOT_FILE_DELIMITER?(c) [
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
			c <> #";"
		]
	]

	#enum errors! [
		ERR_PREMATURE_END
		ERR_BLOCK_END
		ERR_PAREN_END
		ERR_STRING_DELIMIT
		ERR_MULTI_STRING_DELIMIT
		ERR_CHAR_DELIMIT
		ERR_INVALID_INTEGER
		ERR_INVALID_PATH
		ERR_INVALID_CHAR
		ERR_INVALID_DIGIT_WORD
	]

	throw-error: func [id [integer!]][
		print "*** Load Error: "
		print switch id [
			ERR_PREMATURE_END		 ["unmatched closing ] or )"]
			ERR_BLOCK_END			 ["unmatched ] closing bracket"]
			ERR_PAREN_END			 ["unmatched ) closing paren"]
			ERR_STRING_DELIMIT 		 [{string ending delimiter " not found}]
			ERR_MULTI_STRING_DELIMIT ["string ending delimiter } not found"]
			ERR_CHAR_DELIMIT		 [{char ending delimiter " not found}]
			ERR_INVALID_INTEGER		 ["invalid integer"]
			ERR_INVALID_PATH		 ["invalid path"]
			ERR_INVALID_CHAR		 ["invalid char"]
			ERR_INVALID_DIGIT_WORD	 ["word cannot start with a digit"]
		]
		print-line #"!"
	]
	
	preprocess: func [
		str [red-string!]
		/local
			src	 [byte-ptr!]
			tail [byte-ptr!]
			dst	 [byte-ptr!]
			s	 [series!]
			c	 [byte!]
	][
		s: 		GET_BUFFER(str)
		src:	string/rs-head str
		tail:   string/rs-tail str
		dst:	src
		
		while [src < tail][
			either src/1 = #"^^" [
				src: src + 1
				c: src/1
				dst/1: switch c [
					#"-"	[#"^-"]
					#"/"	[#"^/"]
					#"^""	[#"^""]
					#"^^"	[#"^^"]
					#"{"	[#"{"]
					#"}"	[#"}"]
					default [src/1 - #"@"]
				]
			][
				if dst <> src [dst/1: src/1]
			]
			src: src + 1
			dst: dst + 1
		]
		dst/1: null-byte
		s/tail:	as red-value! dst
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
	
	scan-comment: func [
		s		[c-string!]
		return: [c-string!]
	][
		while [not any [s/1 = #"^/" s/1 = null-byte]][s: s + 1]
		s
	]
	
	scan-char: func [
		s		[c-string!]
		blk		[red-block!]
		return: [c-string!]
		/local
			c	 [byte!]
			byte [byte!]
	][
		byte: either s/1 = #"^^" [
			s: s + 1
			c: s/1
			either all [#"@" <= c c <= #"Z"][
				c - #"@"
			][
				switch c [
					#"^"" [#"^""]
					#"/"  [#"^/"]
					#"-"  [#"^-"]
					#"?"  [#"^~"]
					#"^^" [#"^^"]
					default [throw-error ERR_INVALID_CHAR]
				]
			]
		][
			s/1
		]
		s: s + 1
		if s/1 <> #"^"" [throw-error ERR_CHAR_DELIMIT]
		
		char/load-in as-integer byte blk
		s + 1
	]
	
	scan-string-multi: func [
		s		[c-string!]
		blk		[red-block!]
		return: [c-string!]
		/local
			e	  [c-string!]
			c	  [byte!]
			saved [byte!]
			count [integer!]
	][
		s: s + 1										;-- skip opening brace
		e: s
		c: e/1
		count: 1

		while [all [c <> null-byte count > 0]][
			while [all [c <> null-byte c <> #"}"]][
				if c = #"{" [count: count + 1]
				e: e + either c = #"^^" [2][1]
				c: e/1
			]
			if c = #"}" [
				count: count - 1
				e: e + 1
				c: e/1
			]
		]
		e: e - 1
		c: e/1
		
		if c <> #"}" [throw-error ERR_MULTI_STRING_DELIMIT return e + 1]
		saved: e/1										;@@ allocate a new buffer instead
		e/1: null-byte
		preprocess string/load-in s (as-integer e - s) + 1 blk
		e/1: saved
		either c = #"}" [e + 1][e]
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
		e: s
		c: e/1
		
		while [all [c <> null-byte c <> #"^""]][
			e: e + either c = #"^^" [2][1]
			c: e/1
		]
		if c <> #"^"" [throw-error ERR_STRING_DELIMIT]
		saved: e/1										;@@ allocate a new buffer instead
		e/1: null-byte
		preprocess string/load-in s (as-integer e - s) + 1 blk
		e/1: saved
		either c = #"^"" [e + 1][e]
	]
	
	scan-file: func [
		s		[c-string!]
		blk		[red-block!]
		return: [c-string!]
		/local
			e	  [c-string!]
			c	  [byte!]
			saved [byte!]
	][
		s: s + 1										;-- skip first double quote
		e: s
		c: e/1
		
		while [NOT_FILE_DELIMITER?(c)][
			e: e + 1
			c: e/1
		]
		saved: e/1										;@@ allocate a new buffer instead
		e/1: null-byte
		file/load-in s (as-integer e - s) + 1 blk
		e/1: saved
		e
	]
	
	scan-integer: func [
		s		 [c-string!]
		blk		 [red-block!]
		neg?	 [logic!]
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
		if neg? [i: 0 - i]
		integer/load-in blk i
		e
	]
	
	scan-op: func [
		src		[c-string!]
		blk		[red-block!]
		neg?	[logic!]
		return:	[c-string!]
		/local
			c	[byte!]
	][
		c: src/2
		either all [#"0" <= c c <= #"9"][
			scan-integer src + 1 blk neg?
		][
			scan-word src blk TYPE_WORD no
		]
	]
	
	scan-word: func [
		s		  [c-string!]
		blk		  [red-block!]
		type	  [integer!]
		in-path?  [logic!]
		return:   [c-string!]
		/local
			e	  [c-string!]
			c	  [byte!]
			saved [byte!]
			set?  [logic!]
			path? [logic!]
	][
		c: s/1
		if all [#"0" <= c c <= #"9"][
			throw-error ERR_INVALID_DIGIT_WORD
			return s
		]
		e: s + 1
		c: e/1

		while [NOT_DELIMITER?(c)][
			e: e + 1
			c: e/1
		]
		set?:  all [e/1 = #":"  not in-path?]
		path?: all [e/1 = slash not in-path?]
		
		if all [
			type = TYPE_REFINEMENT
			s + 1 = e
		][
			type: TYPE_WORD								;-- / as word case
		]
		
		either path? [
			return scan-path s e blk type = TYPE_LIT_WORD
		][
			saved: e/1										;@@ allocate a new buffer instead
			e/1: null-byte
			case [
				type = TYPE_GET_WORD	[get-word/load-in s blk]
				type = TYPE_LIT_WORD	[lit-word/load-in s blk]
				type = TYPE_ISSUE		[issue/load-in s blk]
				type = TYPE_REFINEMENT	[refinement/load-in s + 1 blk]
				set?				 	[set-word/load-in s blk]
				true				 	[word/load-in s blk]
			]	
			e/1: saved
			return either set? [e + 1][e]
		]
	]
	
	scan-path: func [
		s		 [c-string!]
		src		 [c-string!]
		blk		 [red-block!]
		lit?	 [logic!]
		return:  [c-string!]
		/local
			path  [red-block!]
			saved [byte!]
			set?  [logic!]
	][
		path: block/make-in blk 4						;-- arbitrary start size
		
		saved: src/1									;-- push first element
		src/1: null-byte
		word/load-in s path								;-- store undecorated word
		src/1: saved
		c: src/1
		set?: no
		
		while [c = #"/"][
			src: src + 1
			c: src/1
			case [
				c = #"("  [src: scan-paren src + 1 path]
				c = #":"  [src: scan-word src + 1 path TYPE_GET_WORD yes]
				c = #"+"  [src: scan-op src path no]
				c = #"-"  [src: scan-op src path yes]
				all [#"0" <= c c <= #"9"][src: scan-integer src path no]
				all [#" " <  c c <= #"ÿ"][src: scan-word src path TYPE_WORD yes]
				yes [throw-error ERR_INVALID_PATH]
			]
			c: src/1
			if c = #":" [set?: yes]
		]
		
		path/header: case [
			set? [TYPE_SET_PATH]
			lit? [TYPE_LIT_PATH]
			true [TYPE_PATH]
		]
		either set? [src + 1][src]
	]
	
	scan-block: func [
		src		[c-string!]
		blk		[red-block!]
		return: [c-string!]
	][
		src: scan src block/make-in blk 4				;-- arbitrary start size
		if src/1 <> #"]" [throw-error ERR_PREMATURE_END]
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
		src: scan src block/make-in blk 4				;-- arbitrary start size
		if src/1 <> #")" [throw-error ERR_PAREN_END]
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
			parent
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
				c = #";"  [src: scan-comment src]
				c = #"+"  [src: scan-op src blk no]
				c = #"-"  [src: scan-op src blk yes]
				c = #"^"" [src: scan-string src blk]
				c = #"{"  [src: scan-string-multi src blk]
				c = #"%"  [src: scan-file src blk]
				c = #"["  [src: scan-block src + 1 blk]
				c = #"("  [src: scan-paren src + 1 blk]
				c = #":"  [src: scan-word src + 1 blk TYPE_GET_WORD no]
				c = #"'"  [src: scan-word src + 1 blk TYPE_LIT_WORD no]
				c = #"/"  [src: scan-word src blk TYPE_REFINEMENT no]
				c = #"#"  [
					c: src/2
					either c = #"^"" [
						src: scan-char src + 2 blk
					][
						src: scan-word src + 1 blk TYPE_ISSUE no
					]
				]
				all [#"0" <= c c <= #"9"][src: scan-integer src blk no]
				all [#" " <  c c <= #"ÿ"][src: scan-word src blk TYPE_WORD no]
			]
		]	
		if null? parent [
			if src/1 <> null-byte [throw-error ERR_PREMATURE_END]
			stack/set-last as red-value! blk
		]
		src
	]
	
]