Red/System [
	Title:   "Image! datatype runtime functions"
	Author:  "Qingtian Xie"
	File:	 %image.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

image: context [
	verbose: 0

	#define IMAGE_WIDTH(size)  (size and FFFFh) 
	#define IMAGE_HEIGHT(size) (size >> 16) 

	;--------------------------------------------
	;-- Import OS dependent functions
	;-- load-image: func [								;-- return handle
	;-- 	filename [c-string!]
	;-- 	return:  [integer!]
	;-- ]
	;--------------------------------------------
	#switch OS [
		Windows  [#include %image-gdiplus.reds]
		Syllable []
		MacOSX   []
		Android  []
		FreeBSD  []
		#default []										;-- Linux
	]

	known-image?: func [
		data	[red-binary!]
		return: [logic!]
		/local
			p	[byte-ptr!]
	][
		p: binary/rs-head data
		either any [
			all [										;-- PNG
				p/1 = #"^(89)"
				p/2 = #"P" p/3 = #"N" p/4 = #"G"
			]
			all [p/1 = #"^(FF)" p/2 = #"^(D8)" p/3 = #"^(FF)"]	;-- jpg/jpeg
			all [p/1 = #"B" p/2 = #"M"]					;-- BMP
			all [										;-- GIF
				p/1 = #"G" p/2 = #"I" p/3 = #"F"
				p/4 = #"8" p/5 = #"9" p/6 = #"a"
			]
		][true][false]
	]

	init-image: func [
		img		[red-image!]
		handle  [integer!]
		return: [red-image!]
	][
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		img/head: 0

		h: height? handle
		img/size: h << 16 or width? handle
		img/node: as node! handle
		img
	]

	load-binary: func [
		data	[red-binary!]
		return: [red-image!]
		/local
			img [red-image!]
	][
		either known-image? data [
			init-image
				as red-image! stack/push*
				OS-load-binary binary/rs-head data binary/rs-length? data
		][as red-image! none-value]
	]

	load-in: func [
		filename [c-string!]							;-- UTF-8 file pathname
		blk		 [red-block!]
		return:  [red-image!]
		/local
			img  [red-image!]
	][
		img: as red-image! either null = blk [stack/push*][ALLOC_TAIL(blk)]
		init-image img load-image filename
	]

	load: func [
		filename [c-string!]							;-- UTF-8 file pathname
		return:  [red-image!]
	][
		load-in filename null
	]

	push: func [
		img [red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/push"]]
		
		copy-cell as red-value! img stack/push*
	]

	make-at: func [
		slot	[red-value!]
		src		[red-string!]
		return:	[red-image!]
		/local
			img   [red-image!]
			str   [red-string!]
			len   [integer!]
			hr    [integer!]
			h     [integer!]
			file? [logic!]
	][
		file?: TYPE_OF(src) = TYPE_FILE
		if file? [
			str: string/rs-make-at stack/push* string/rs-length? src
			file/to-local-path src str no
			src: str
		]
		#either OS = 'Windows [
			hr: load-image unicode/to-utf16 src
		][
			len: -1
			hr: load-image unicode/to-utf8 src :len
		]

		img: as red-image! slot
		init-image img hr
		if file? [stack/pop 1]
		img
	]

	extract-data: func [
		img		[red-image!]
		alpha?	[logic!]
		return: [red-binary!]
		/local
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			sz		[integer!]
			bin		[red-binary!]
			s		[series!]
			p		[byte-ptr!]
			stride	[integer!]
			bitmap	[integer!]
			pos		[integer!]
			pixel	[integer!]
			data	[int-ptr!]
	][
		w: IMAGE_WIDTH(img/size)
		h: IMAGE_HEIGHT(img/size)
		sz: either alpha? [w * h][w * h * 3]
		bin: binary/make-at stack/push* sz
		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/tail) + sz
		p: as byte-ptr! s/offset

		stride: 0
		bitmap: lock-bitmap as-integer img/node
		data: get-data bitmap :stride
		y: 0
		while [y < h][
			x: 0
			while [x < w][
				pos: stride >> 2 * y + x + 1
				pixel: data/pos
				either alpha? [
					p/1: as-byte pixel >>> 24
					p: p + 1
				][
					p/1: as-byte pixel and 00FF0000h >> 16
					p/2: as-byte pixel and FF00h >> 8
					p/3: as-byte pixel and FFh
					p: p + 3
				]
				x: x + 1
			]
			y: y + 1
		]
		unlock-bitmap as-integer img/node bitmap
		bin
	]

	;-- Actions --

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-image!]
		/local
			img		[red-image!]
			pair	[red-pair!]
			blk		[red-block!]
			bin		[red-binary!]
			rgb		[byte-ptr!]
			alpha	[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/make"]]

		img: as red-image! stack/push*
		img/header: TYPE_IMAGE
		img/head: 0

		rgb: null
		alpha: null
		switch TYPE_OF(spec) [
			TYPE_PAIR [
				pair: as red-pair! spec
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				pair: as red-pair! block/rs-head blk
				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					rgb: binary/rs-head bin
				]
				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					alpha: binary/rs-head bin
				]
			]
			default [fire [TO_ERROR(syntax malconstruct) spec]]
		]

		img/size: pair/y << 16 or pair/x
		img/node: as node! make-image pair/x pair/y rgb alpha
		img
	]

	serialize: func [
		img		[red-image!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		mold?	[logic!]
		return: [integer!]
		/local
			height	[integer!]
			width	[integer!]
			alpha?	[logic!]
			formed	[c-string!]
			pixel	[integer!]
			x		[integer!]
			y		[integer!]
			count	[integer!]
			bitmap	[integer!]
			data	[int-ptr!]
			stride	[integer!]
			pos		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/serialize"]]

		alpha?: no
		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)

		string/concatenate-literal buffer "make image! ["
		part: part - 13
		formed: integer/form-signed width
		string/concatenate-literal buffer formed
		part: part - length? formed

		string/append-char GET_BUFFER(buffer) as-integer #"x"
		formed: integer/form-signed height
		string/concatenate-literal buffer formed
		part: part - length? formed

		string/append-char GET_BUFFER(buffer) as-integer space
		string/concatenate-literal buffer "#{^/"
		part: part - 5

		stride: 0
		bitmap: lock-bitmap as-integer img/node
		data: get-data bitmap :stride
		y: 0
		count: 0
		while [y < height][
			x: 0
			while [x < width][
				pos: stride >> 2 * y + x + 1
				pixel: data/pos
				string/concatenate-literal buffer string/byte-to-hex pixel and 00FF0000h >> 16
				string/concatenate-literal buffer string/byte-to-hex pixel and FF00h >> 8
				string/concatenate-literal buffer string/byte-to-hex pixel and FFh
				count: count + 1
				if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
				part: part - 6
				if all [OPTION?(arg) part <= 0][
					unlock-bitmap as-integer img/node bitmap
					return part
				]
				if pixel and FF000000h >> 24 <> 0 [alpha?: yes]
				x: x + 1
			]
			y: y + 1
		]
		string/append-char GET_BUFFER(buffer) as-integer #"}"

		if alpha? [
			string/append-char GET_BUFFER(buffer) as-integer space
			string/concatenate-literal buffer "#{^/"
			part: part - 5
			y: 0
			count: 0
			while [y < height][
				x: 0
				while [x < width][
					pos: stride >> 2 * y + x + 1
					pixel: data/pos
					string/concatenate-literal buffer string/byte-to-hex pixel and FF000000h >> 24
					count: count + 1
					if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
					part: part - 2
					if all [OPTION?(arg) part <= 0][
						unlock-bitmap as-integer img/node bitmap
						return part
					]
					x: x + 1
				]
				y: y + 1
			]
			string/append-char GET_BUFFER(buffer) as-integer #"}"
		]
		unlock-bitmap as-integer img/node bitmap
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 2												;-- #"}" and #"]"
	]

	form: func [
		img		  [red-image!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/form"]]

		serialize img buffer no no no arg part no
	]

	mold: func [
		img		[red-image!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/mold"]]

		serialize img buffer only? all? flat? arg part yes
	]

	;--- Reading actions ---

	pick: func [
		img		[red-image!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			width	[integer!]
			height	[integer!]
			offset	[integer!]
			pixel	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/pick"]]

		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)
		offset: img/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		either any [
			zero? index
			offset < 0
			offset >= (width * height)
		][
			none-value
		][
			pixel: get-pixel as-integer img/node offset
			as red-value! tuple/rs-make [
					pixel and 00FF0000h >> 16
					pixel and FF00h >> 8
					pixel and FFh
					pixel and FF000000h >> 24
				]
		]
	]

	poke: func [
		img		[red-image!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			color	[red-tuple!]
			offset	[integer!]
			p		[byte-ptr!]
			r		[integer!]
			g		[integer!]
			b		[integer!]
			a		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/poke"]]

		offset: img/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		either any [
			zero? index
			offset < 0
			offset >= (IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size))
		][
			fire [TO_ERROR(script out-of-range) boxed]
		][
			color: as red-tuple! data
			p: (as byte-ptr! color) + 4
			r: as-integer p/1
			g: as-integer p/2
			b: as-integer p/3
			a: either TUPLE_SIZE(color) > 3 [as-integer p/4][255]
			set-pixel as-integer img/node offset a << 24 or (r << 16) or (g << 8) or b
		]
		as red-value! data
	]

	eval-path: func [
		parent	[red-image!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			int	 [red-integer!]
			set? [logic!]
			w	 [red-word!]
			sym  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/eval-path"]]

		set?: value <> null
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				either set? [
					poke parent int/value value element
				][
					pick parent int/value element
				]
			]
			TYPE_WORD [
				if set? [--NOT_IMPLEMENTED--]					;@@ TBD handle set word
				w: as red-word! element
				sym: symbol/resolve w/symbol
				case [
					sym = words/size [
						pair/push IMAGE_WIDTH(parent/size) IMAGE_HEIGHT(parent/size)
					]
					sym = words/rgb [
						extract-data parent no
					]
					sym = words/alpha [
						extract-data parent yes
					]
					true [
						fire [TO_ERROR(script invalid-path) stack/arguments element]
						null
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-path) stack/arguments element]
				null
			]
		]
	]

	compare: func [
		arg1	[red-image!]								;-- first operand
		arg2	[red-image!]								;-- second operand
		op		[integer!]									;-- type of comparison
		return:	[integer!]
		/local
			type [integer!]
			res  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image!/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_IMAGE [RETURN_COMPARE_OTHER]

		switch op [
			COMP_EQUAL
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT((as-integer arg1/node) (as-integer arg2/node))
			]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		datatype/register [
			TYPE_IMAGE
			TYPE_VALUE
			"image!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
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
			null			;index?
			null			;insert
			null			;length?
			null			;next
			:pick
			:poke
			null			;put
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
]
