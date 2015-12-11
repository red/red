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

#enum image-format! [
	IMAGE_BMP
	IMAGE_PNG
	IMAGE_GIF
	IMAGE_JPEG
	IMAGE_TIFF
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
		Windows  [#include %../../modules/view/backends/windows/image-gdiplus.reds]
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

		img/size: (height? handle) << 16 or width? handle
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
	][
		hr: load-image file/to-OS-path src
		if hr = -1 [fire [TO_ERROR(access cannot-open) src]]
		img: as red-image! slot
		init-image img hr
		img
	]

	decode: func [
		data	[red-value!]
		return: [red-image!]
	][
		either TYPE_OF(data) = TYPE_BINARY [
			load-binary as red-binary! data
		][
			make-at stack/push* as red-string! data
		]
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
		bitmap: lock-bitmap as-integer img/node no
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

	set-data: func [
		img		[red-image!]
		bin		[red-binary!]
		alpha?	[logic!]
		return: [red-binary!]
		/local
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			s		[series!]
			p		[byte-ptr!]
			stride	[integer!]
			bitmap	[integer!]
			pos		[integer!]
			pixel	[integer!]
			tp		[red-tuple!]
			int		[red-integer!]
			color	[integer!]
			data	[int-ptr!]
			type	[integer!]
	][
		w: IMAGE_WIDTH(img/size)
		h: IMAGE_HEIGHT(img/size)

		type: TYPE_OF(bin)

		if type = TYPE_BINARY [
			s: GET_BUFFER(bin)
			p: as byte-ptr! s/offset
		]

		stride: 0
		bitmap: lock-bitmap as-integer img/node yes
		data: get-data bitmap :stride
		y: 0
		either type = TYPE_BINARY [
			while [y < h][
				x: 0
				while [x < w][
					pos: stride >> 2 * y + x + 1
					pixel: data/pos
					either alpha? [
						pixel: pixel and 00FFFFFFh or ((as-integer p/1) << 24)
						p: p + 1
					][
						pixel: pixel and FF000000h
								or ((as-integer p/1) << 16)
								or ((as-integer p/2) << 8)
								or (as-integer p/3)
						p: p + 3
					]
					data/pos: pixel
					x: x + 1
				]
				y: y + 1
			]
		][
			either type = TYPE_TUPLE [
				tp: as red-tuple! bin
				color: tp/array1
			][
				int: as red-integer! bin
				color: int/value
			]
			color: either alpha? [color << 24][
				color: color and 00FFFFFFh
				color >> 16 or (color and FF00h) or (color and FFh << 16)
			]
			while [y < h][
				x: 0
				while [x < w][
					pos: stride >> 2 * y + x + 1
					pixel: data/pos
					pixel: either alpha? [
						pixel and 00FFFFFFh or color
					][
						pixel and FF000000h or color
					]
					data/pos: pixel
					x: x + 1
				]
				y: y + 1
			]
		]
		unlock-bitmap as-integer img/node bitmap
		ownership/check as red-value! img words/_poke as red-value! bin img/head 0
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
			color	[red-tuple!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/make"]]

		img: as red-image! stack/push*
		img/header: TYPE_IMAGE
		img/head: 0

		rgb:   null
		alpha: null
		color: null
		switch TYPE_OF(spec) [
			TYPE_PAIR [
				pair: as red-pair! spec
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				pair: as red-pair! block/rs-head blk
				check-arg-type as red-value! pair TYPE_PAIR

				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					switch TYPE_OF(bin) [
						TYPE_BINARY [rgb: binary/rs-head bin]
						TYPE_TUPLE	[color: as red-tuple! bin]
						default		[fire [TO_ERROR(script invalid-arg) bin]]
					]
				]
				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					check-arg-type as red-value! bin TYPE_BINARY
					alpha: binary/rs-head bin
				]
			]
			default [fire [TO_ERROR(syntax malconstruct) spec]]
		]

		img/size: pair/y << 16 or pair/x
		img/node: as node! make-image pair/x pair/y rgb alpha color
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
		bitmap: lock-bitmap as-integer img/node no
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
				if pixel and FF000000h >>> 24 <> 255 [alpha?: yes]
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
			a: either TUPLE_SIZE?(color) > 3 [as-integer p/4][255]
			set-pixel as-integer img/node offset a << 24 or (r << 16) or (g << 8) or b
		]
		ownership/check as red-value! img words/_poke data offset 1
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
				w: as red-word! element
				sym: symbol/resolve w/symbol
				case [
					sym = words/size [
						pair/push IMAGE_WIDTH(parent/size) IMAGE_HEIGHT(parent/size)
					]
					sym = words/rgb [
						either set? [
							set-data parent as red-binary! value no
						][
							extract-data parent no
						]
					]
					sym = words/alpha [
						either set? [
							set-data parent as red-binary! value yes
						][
							extract-data parent yes
						]
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
			TYPE_SERIES
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
			INHERIT_ACTION	;modify
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
