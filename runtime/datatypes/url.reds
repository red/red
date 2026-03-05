Red/System [
	Title:   "Url! datatype runtime functions"
	Author:  "Xie Qingtian"
	File: 	 %url.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

url: context [
	verbose: 0

	#enum escape-type! [
		;ESC_CHAR: FDh
		ESC_URI:  FEh			;-- RFC 3986
		ESC_URL:  FFh			;-- similar encodeURI
	]

	;-- Hex values encoding table for special characters in URLs (FF => no-op)
	escape-url-chars: #{								;-- ESC_URL: #"^(FF)"
		FF FF FF FF FF FF FF FF ;-- 07h
		FF FF FF FF FF FF FF FF ;-- 0Fh
		FF FF FF FF FF FF FF FF ;-- 17h
		FF FF FF FF FF FF FF FF ;-- 1Fh
		FF FF FF FF FF FF FF FF ;-- 27h
		FF FF FF FF FF FF FF FF ;-- 2Fh
		00 01 02 03 04 05 06 07 ;-- 37h		#"0"-#"9" => 0-9
		08 09 FF FF FF FF FF FF ;-- 3Fh
		FF 0A 0B 0C 0D 0E 0F FF ;-- 47h		#"A"-#"F" => 10-15
		FF FF FF FF FF FF FF FF ;-- 4Fh
		FF FF FF FF FF FF FF FF ;-- 57h
		FF FF FF FF FF FF FF FF ;-- 5Fh
		FF 0A 0B 0C 0D 0E 0F FF ;-- 67h		#"a"-#"f" => 10-15
		FF FF FF FF FF FF FF FF ;-- 6Fh
		FF FF FF FF FF FF FF FF ;-- 77h
		FF FF FF FF FF FF FF FF ;-- 7Fh
	}

	;-- URI special characters encoding table (RFC3986 rules)
	;-- FF: pass-thru, 00: escape character
	uri-encode-tbl: #{
		00 00 00 00 00 00 00 00 ;-- 07h
		00 00 00 00 00 00 00 00 ;-- 0Fh
		00 00 00 00 00 00 00 00 ;-- 17h
		00 00 00 00 00 00 00 00 ;-- 1Fh
		00 00 00 00 00 00 00 00 ;-- 27h
		00 00 00 00 00 FF FF 00 ;-- 2Fh
		FF FF FF FF FF FF FF FF ;-- 37h
		FF FF 00 00 00 00 00 00 ;-- 3Fh
		00 FF FF FF FF FF FF FF ;-- 47h
		FF FF FF FF FF FF FF FF ;-- 4Fh
		FF FF FF FF FF FF FF FF ;-- 57h
		FF FF FF 00 00 00 00 FF ;-- 5Fh
		00 FF FF FF FF FF FF FF ;-- 67h
		FF FF FF FF FF FF FF FF ;-- 6Fh
		FF FF FF FF FF FF FF FF ;-- 77h
		FF FF FF 00 00 00 FF 00 ;-- 7Fh
	}

	;-- URL special characters encoding table (encodeURI rules)
	;-- FF: pass-thru, 00: escape character
	url-encode-tbl: #{
		00 00 00 00 00 00 00 00 ;-- 07h
		00 00 00 00 00 00 00 00 ;-- 0Fh
		00 00 00 00 00 00 00 00 ;-- 17h
		00 00 00 00 00 00 00 00 ;-- 1Fh
		00 FF 00 FF FF 00 FF FF ;-- 27h
		FF FF FF FF FF FF FF FF ;-- 2Fh
		FF FF FF FF FF FF FF FF ;-- 37h
		FF FF FF 00 00 FF 00 FF ;-- 3Fh
		FF FF FF FF FF FF FF FF ;-- 47h
		FF FF FF FF FF FF FF FF ;-- 4Fh
		FF FF FF FF FF FF FF FF ;-- 57h
		FF FF FF 00 00 00 00 FF ;-- 5Fh
		00 FF FF FF FF FF FF FF ;-- 67h
		FF FF FF FF FF FF FF FF ;-- 6Fh
		FF FF FF FF FF FF FF FF ;-- 77h
		FF FF FF 00 00 00 FF 00 ;-- 7Fh
	}

	decode-char: func [
		p			[byte-ptr!]
		rp			[byte-ptr!]
		return:		[logic!]
		/local
			ch		[integer!]
			v1		[integer!]
			v2		[integer!]
	][
		ch: as integer! p/1
		if ch > MAX_URL_CHARS [return false]
		if p/1 <> #"%" [return false]
		v1: 1 + as-integer p/2
		v2: 1 + as-integer p/3
		v1: as-integer escape-url-chars/v1
		v2: as-integer escape-url-chars/v2
		if any [
			v1 = ESC_URL
			v2 = ESC_URL
		][return false]

		v1: v1 << 4 + v2
		rp/1: as byte! v1
		return true
	]

	decode: func [
		str			[red-string!]
		url			[red-string!]
		/local
			data	[byte-ptr!]
			end		[byte-ptr!]
			p		[byte-ptr!]
			pc		[byte-ptr!]
			s		[series!]
			slen	[integer!]
			size	[integer!]
			code	[integer!]
			u		[integer!]
			ch2		[byte!]
			ch		[byte!]
			enc?	[logic!]
	][
		slen: -1
		data: as byte-ptr! unicode/to-utf8 str :slen
		if slen = 0 [exit]
		end: data + slen
		s: GET_BUFFER(url)

		ch: #"^@" ch2: #"^@"
		while [data < end][
			enc?: false
			if decode-char data :ch [
				size: unicode/utf8-char-size? as-integer ch
				p: data + 3
				enc?: true
				if size <> 0 [
					loop size - 1 [
						unless decode-char p :ch2 [
							enc?: false
							break
						]
						p: p + 3
					]
				]
			]
			either enc? [
				either size = 0 [
					s: string/append-char s as integer! ch
					data: data + 3
				][
					code: 0
					p: as byte-ptr! :code
					p/1: ch
					p: p + 1
					data: data + 3
					loop size - 1 [
						decode-char data :ch
						p/1: ch
						p: p + 1
						data: data + 3
					]
					u: unicode/decode-utf8-char as c-string! :code :size
					s: string/append-char s u
				]
			][
				size: as integer! end - data
				u: unicode/decode-utf8-char as c-string! data :size
				s: string/append-char s u
				data: data + size
			]
		]
	]

	encode-char: func [
		type		[integer!]
		pch			[byte-ptr!]
		psize		[int-ptr!]
		return:		[byte-ptr!]
		/local
			ss		[c-string!]
			tbl		[byte-ptr!]
			pcode	[byte-ptr!]
			str		[c-string!]
			ch		[integer!]
			index	[integer!]
			code	[integer!]
	][
		ss: "%00"
		tbl: either type = ESC_URI [uri-encode-tbl][url-encode-tbl]
		ch: as integer! pch/1
		either ch > MAX_URL_CHARS [
			code: 0
		][
			index: ch + 1
			code: as integer! tbl/index
		]
		either code = FFh [
			pcode: pch
			psize/1: 1
		][
			str: string/byte-to-hex ch
			ss/2: str/1
			ss/3: str/2
			pcode: as byte-ptr! ss
			psize/1: 3
		]
		pcode
	]

	encode: func [
		str			[red-string!]
		url			[red-string!]
		type		[integer!]
		/local
			slen	[integer!]
			data	[byte-ptr!]
			end		[byte-ptr!]
			s		[series!]
			dst		[byte-ptr!]
			p		[byte-ptr!]
			node	[node!]
			size	[integer!]			
	][
		slen: -1
		data: as byte-ptr! unicode/to-utf8 str :slen
		if slen = 0 [exit]
		end: data + slen
		s: GET_BUFFER(url)

		size: 0
		while [data < end][
			p: encode-char type data :size
			loop size [
				node: s/node
				dst: alloc-tail-unit s 1
				dst/1: p/1
				s: as series! node/value
				p: p + 1
			]
			data: data + 1
		]
	]

	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		return:  [red-string!]
		/local
			str  [red-string!]
			ret  [red-string!]
			len  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/load"]]
		str: string/load src size UTF-8
		ret: as red-string! stack/push*
		len: string/rs-length? str
		string/make-at as red-value! ret len Latin1
		decode str ret
		stack/set-last as red-value! ret
		ret
	]

	push: func [
		url [red-url!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/push"]]

		copy-cell as red-value! url stack/push*
	]
	
	to-port: func [
		url		[red-url!]
		new?	[logic!]
		read?	[logic!]
		write?	[logic!]
		seek?	[logic!]
		allow	[red-value!]
		open?	[logic!]
		return:	[red-value!]
		/local
			p	[red-object!]
			v	[red-url! value]
	][
		copy-cell as red-value! url as red-value! v	
		#call [url-parser/parse-url url]
		p: as red-object! stack/arguments

		either TYPE_OF(p) = TYPE_OBJECT [
			p: port/make none-value as red-value! p TYPE_NONE
			if open? [actions/open as red-value! p new? read? write? seek? allow]
		][
			fire [TO_ERROR(script invalid-arg) v]
		]
		as red-value! p
	]

	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-url!]
		/local
			type2 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/make"]]
		
		type2: TYPE_OF(spec)
		as red-url! either all [type = TYPE_URL ANY_LIST?(type2)][ ;-- file! inherits from url!
			to proto spec type
		][
			string/make as red-string! proto spec type
		]
	]

	mold: func [
		url     [red-url!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			int		[red-integer!]
			limit?	[logic!]
			slen	[integer!]
			data	[byte-ptr!]
			end		[byte-ptr!]
			size	[integer!]
			p		[byte-ptr!]
			num		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/mold"]]

		limit?: OPTION?(arg)

		slen: -1
		data: as byte-ptr! unicode/to-utf8 url :slen
		if slen = 0 [return 0]
		end: data + slen

		num: 0
		size: 0
		while [data < end][
			p: encode-char ESC_URL data :size
			loop size [
				string/append-char GET_BUFFER(buffer) as-integer p/1
				num: num + 1
				if all [
					limit?
					num >= part
				][
					return part - num
				]
				p: p + 1
			]
			data: data + 1
		]
		part - num
	]
	
	to: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-string!]
		/local
			buffer [red-string!]
			blk	   [red-block!]
			value  [red-value!]
			tail   [red-value!]
			type2  [integer!]
			s	   [series!]
			sep	   [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/to"]]

		type2: TYPE_OF(spec)
		either all [type = TYPE_URL ANY_LIST?(type2)][ ;-- file! inherits from url!
			buffer: string/make-at proto 16 1
			buffer/header: TYPE_URL

			blk: as red-block! spec
			s: GET_BUFFER(blk)
			value: s/offset + blk/head
			tail: s/tail
			if value = tail [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_URL spec]
			]
			actions/form value buffer null 0
			value: value + 1
			string/concatenate-literal buffer "://"
			if value = tail [return buffer]
			
			actions/form value buffer null 0
			value: value + 1
			if value = tail [return buffer]
			
			if TYPE_OF(value) = TYPE_INTEGER [
				string/concatenate-literal buffer ":"
				actions/form value buffer null 0
				value: value + 1
				if value = tail [return buffer]
			]
			string/append-char GET_BUFFER(buffer) as-integer #"/"
			until [
				actions/form value buffer null 0
				value: value + 1
				if value + 1 <= tail [
					sep: either TYPE_OF(value) = TYPE_ISSUE [#"#"][#"/"]
					string/append-char GET_BUFFER(buffer) as-integer sep
				]
				value = tail
			]
			buffer
		][
			string/to proto spec type
		]
	]

	eval-path: func [
		parent	[red-string!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		gparent [red-value!]
		p-item	[red-value!]
		index	[integer!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		evt?	[logic!]
		return:	[red-value!]
		/local
			s s2 [series!] 
			str new  [red-string!]
			unit unit2 len len2 slash [integer!]
			left right [logic!]
	][
		either value <> null [							;-- set-path
			fire [TO_ERROR(script bad-path-set) path element]
		][
			s: GET_BUFFER(parent)
			unit: GET_UNIT(s)
			len: string/rs-length? parent
			new: string/make-at stack/push* 16 + len unit
			if TYPE_OF(element) = TYPE_GET_WORD [element: _context/get as red-word! element]
			
			actions/form element new null 0
			s2: GET_BUFFER(new)
			unit2: GET_UNIT(s2)
			len2: string/rs-length? new

			slash: as-integer #"/"
			left:  all [len > 0   slash = string/get-char (as byte-ptr! s/tail) - unit unit]
			right: all [len2 > 0  slash = string/get-char (as byte-ptr! s2/offset) unit2]
			case [
				all [not left not right][new/node/value: as-integer string/insert-char s2 0 as-integer #"/"]
				all [left right][s/tail: as red-value! (as byte-ptr! s/tail) - unit]
				true [0]
			]
			string/concatenate new parent -1 0 yes yes
			set-type as red-value! new TYPE_OF(parent)
		]
		as red-value! new
	]

	;-- I/O actions
	
	open: func [
		url		[red-url!]
		new?	[logic!]
		read?	[logic!]
		write?	[logic!]
		seek?	[logic!]
		allow	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/open"]]
		to-port url new? read? write? seek? allow yes
	]
	
	read: func [
		src		[red-value!]
		part	[red-value!]
		seek	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		as-arg	[red-value!]
		return:	[red-value!]
		/local
			p [red-object!]
	][
		either string/rs-match as red-string! src "http" [
			if any [
				OPTION?(part)
				OPTION?(seek)
				OPTION?(as-arg)
			][
				--NOT_IMPLEMENTED--
			]
			part: simple-io/request-http words/get as red-url! src null null binary? lines? info?
			if TYPE_OF(part) = TYPE_NONE [fire [TO_ERROR(access no-connect) src]]
			part
		][
			p: as red-object! to-port as red-url! src no no no OPTION?(seek) none-value no
			port/read p part seek binary? lines? info? as-arg
		]
	]

	write: func [
		dest	[red-url!]
		data	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		append? [logic!]
		part	[red-value!]
		seek	[red-value!]
		allow	[red-value!]
		as-arg	[red-value!]
		return:	[red-value!]
		/local
			blk		[red-block!]
			method	[red-word!]
			header	[red-block!]
			p		[red-object!]
			action	[integer!]
			sym		[integer!]
	][
		either string/rs-match as red-string! dest "http" [
			if any [
				OPTION?(seek)
				OPTION?(allow)
				OPTION?(as-arg)
			][
				--NOT_IMPLEMENTED--
			]

			header: null
			either TYPE_OF(data) = TYPE_BLOCK [
				blk: as red-block! data
				either 0 = block/rs-length? blk [
					action: words/get
				][
					method: as red-word! block/rs-head blk
					if TYPE_OF(method) <> TYPE_WORD [
						fire [TO_ERROR(script invalid-arg) method]
					]
					action: symbol/resolve method/symbol
					unless block/rs-next blk [
						header: as red-block! block/rs-head blk
						if TYPE_OF(header) <> TYPE_BLOCK [
							fire [TO_ERROR(script invalid-arg) header]
						]
					]
					data: as red-value! either block/rs-next blk [null][block/rs-head blk]
				]
			][
				action: words/post
			]

			if all [
				data <> null
				TYPE_OF(data) <> TYPE_BLOCK
				TYPE_OF(data) <> TYPE_STRING
				TYPE_OF(data) <> TYPE_BINARY
			][
				fire [TO_ERROR(script invalid-arg) data]
			]
			part: simple-io/request-http action dest header data binary? lines? info?
			if TYPE_OF(part) = TYPE_NONE [fire [TO_ERROR(access no-connect) dest]]
			part
		][
			data: stack/push data
			p: as red-object! to-port as red-url! dest no no no OPTION?(seek) none-value no
			port/write p data binary? lines? info? append? part seek allow as-arg
		]
	]

	init: does [
		datatype/register [
			TYPE_URL
			TYPE_STRING
			"url!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			INHERIT_ACTION	;form
			:mold
			:eval-path
			null			;set-path
			INHERIT_ACTION	;compare
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
			INHERIT_ACTION	;append
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			INHERIT_ACTION	;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;move
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			null			;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			null			;sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
			:open
			null			;open?
			null			;query
			:read
			null			;rename
			null			;update
			:write
		]
	]
]
