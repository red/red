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

	set-many: func [
		words	[red-block!]
		img		[red-image!]
		size	[integer!]
		/local
			v [red-value!]
			i [integer!]
	][
		i: 1
		while [i <= size][
			_context/set (as red-word! _series/pick as red-series! words i null) image/pick img i null
			i: i + 1
		]
	]

	known-image?: func [
		data	[red-binary!]
		return: [logic!]
		/local
			p	[byte-ptr!]
	][
		p: binary/rs-head data
		any [
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
		]
	]

	init-image: func [
		img		[red-image!]
		handle  [integer!]
		return: [red-image!]
	][
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		img/head: 0

		img/size: (OS-image/height? handle) << 16 or OS-image/width? handle
		img/node: as node! handle
		img
	]
	
	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [red-image!]
	][
		init-image as red-image! stack/push* OS-image/resize img width height
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
				OS-image/load-binary binary/rs-head data binary/rs-length? data
		][as red-image! none-value]
	]

	push: func [
		img [red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/push"]]
		
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
		hr: OS-image/load-image file/to-OS-path src
		if hr = -1 [fire [TO_ERROR(access cannot-open) src]]
		img: as red-image! slot
		init-image img hr
		img
	]
	
	delete: func [img [red-image!]][
		OS-image/delete img
	]
	
	encode: func [
		image	[red-image!]
		format	[integer!]
		return: [red-binary!]
	][
		OS-image/encode image format stack/push*
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
		bitmap: OS-image/lock-bitmap as-integer img/node no
		data: OS-image/get-data bitmap :stride
		x: img/head % w
		y: img/head / w
		while [y < h][
			while [x < w][
				pos: stride >> 2 * y + x + 1
				pixel: data/pos
				either alpha? [
					p/1: as-byte 255 - (pixel >>> 24)
					p: p + 1
				][
					p/1: as-byte pixel and 00FF0000h >> 16
					p/2: as-byte pixel and FF00h >> 8
					p/3: as-byte pixel and FFh
					p: p + 3
				]
				x: x + 1
			]
			x: 0
			y: y + 1
		]
		OS-image/unlock-bitmap as-integer img/node bitmap
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
			offset	[integer!]
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

		offset: img/head
		stride: 0
		bitmap: OS-image/lock-bitmap as-integer img/node yes
		data: OS-image/get-data bitmap :stride
		x: offset % w
		y: offset / w
		either type = TYPE_BINARY [
			while [y < h][
				while [x < w][
					pos: stride >> 2 * y + x + 1
					pixel: data/pos
					either alpha? [
						pixel: pixel and 00FFFFFFh or ((255 - as-integer p/1) << 24)
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
				x: 0
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
			color: either alpha? [255 - color << 24][
				color: color and 00FFFFFFh
				color >> 16 or (color and FF00h) or (color and FFh << 16)
			]
			while [y < h][
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
				x: 0
				y: y + 1
			]
		]
		OS-image/unlock-bitmap as-integer img/node bitmap
		ownership/check as red-value! img words/_poke as red-value! bin img/head 0
		bin
	]

	get-position: func [
		base		[integer!]
		return:		[integer!]
		/local
			img		[red-image!]
			index	[red-integer!]
			s		[series!]
			offset	[integer!]
			max		[integer!]
			idx		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/at"]]
		
		img: as red-image! stack/arguments
		index: as red-integer! img + 1

		either TYPE_OF(index) = TYPE_INTEGER [
			idx: index/value
			if all [base = 1 idx <= 0][base: base - 1]
		][
			--NOT_IMPLEMENTED--
		]

		offset: img/head + idx - base
		if negative? offset [offset: 0]
		max: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		if offset > max [offset: max]
		offset
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
		#if debug? = yes [if verbose > 0 [print-line "image/make"]]

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
		img/node: as node! OS-image/make-image pair/x pair/y rgb alpha color
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
			offset	[integer!]
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
		#if debug? = yes [if verbose > 0 [print-line "image/serialize"]]

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
		bitmap: OS-image/lock-bitmap as-integer img/node no
		data: OS-image/get-data bitmap :stride
		offset: img/head
		stride: stride / 4
		x: offset % width
		y: offset / width
		count: 0
		while [y < height][
			while [x < width][
				pos: stride * y + x + 1
				pixel: data/pos
				string/concatenate-literal buffer string/byte-to-hex pixel and 00FF0000h >> 16
				string/concatenate-literal buffer string/byte-to-hex pixel and FF00h >> 8
				string/concatenate-literal buffer string/byte-to-hex pixel and FFh
				count: count + 1
				if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
				part: part - 6
				if all [OPTION?(arg) part <= 0][
					OS-image/unlock-bitmap as-integer img/node bitmap
					return part
				]
				if pixel >>> 24 <> 255 [alpha?: yes]
				x: x + 1
			]
			x: 0
			y: y + 1
		]
		string/append-char GET_BUFFER(buffer) as-integer #"}"

		if alpha? [
			string/append-char GET_BUFFER(buffer) as-integer space
			string/concatenate-literal buffer "#{^/"
			part: part - 5
			x: offset % width
			y: offset / width
			count: 0
			while [y < height][
				while [x < width][
					pos: stride * y + x + 1
					pixel: data/pos
					string/concatenate-literal buffer string/byte-to-hex 255 - (pixel >>> 24)
					count: count + 1
					if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
					part: part - 2
					if all [OPTION?(arg) part <= 0][
						OS-image/unlock-bitmap as-integer img/node bitmap
						return part
					]
					x: x + 1
				]
				x: 0
				y: y + 1
			]
			string/append-char GET_BUFFER(buffer) as-integer #"}"
		]
		OS-image/unlock-bitmap as-integer img/node bitmap
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
		#if debug? = yes [if verbose > 0 [print-line "image/form"]]

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
		#if debug? = yes [if verbose > 0 [print-line "image/mold"]]

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
			pixel: OS-image/get-pixel as-integer img/node offset
			as red-value! tuple/rs-make [
				pixel and 00FF0000h >> 16
				pixel and FF00h >> 8
				pixel and FFh
				255 - (pixel >>> 24)
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
			a: either TUPLE_SIZE?(color) > 3 [255 - as-integer p/4][255]
			OS-image/set-pixel as-integer img/node offset a << 24 or (r << 16) or (g << 8) or b
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
			bmp1 [integer!]
			bmp2 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_IMAGE [RETURN_COMPARE_OTHER]

		switch op [
			COMP_EQUAL
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				either any [
					arg1/size <> arg2/size
					all [arg1/size = arg2/size arg1/head <> arg2/head]
				][
					res: 1
				][
					type: 0
					bmp1: OS-image/lock-bitmap as-integer arg1/node no
					bmp2: OS-image/lock-bitmap as-integer arg2/node no
					res: compare-memory
						as byte-ptr! OS-image/get-data bmp1 :type
						as byte-ptr! OS-image/get-data bmp2 :type
						IMAGE_WIDTH(arg1/size) * IMAGE_HEIGHT(arg2/size) * 4
					OS-image/unlock-bitmap as-integer arg1/node bmp1
					OS-image/unlock-bitmap as-integer arg2/node bmp2
				]
			]
			default [
				res: -2
			]
		]
		res
	]

	;--- Series actions ---

	at: func [
		return:	[red-image!]
		/local
			img	[red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/at"]]

		img: as red-image! stack/arguments
		img/head: get-position 1
		img
	]

	next: func [
		return:	[red-image!]
		/local
			img		[red-image!]
			offset	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/next"]]

		img: as red-image! stack/arguments
		offset: img/head + 1
		if IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) >= offset  [
			img/head: offset
		]
		img
	]

	skip: func [
		return:	[red-image!]
		/local
			img	[red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/skip"]]

		img: as red-image! stack/arguments
		img/head: get-position 0
		img
	]

	tail?: func [
		return:	  [red-value!]
		/local
			img	  [red-image!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/tail?"]]

		img:   as red-image! stack/arguments
		state: as red-logic! img

		state/header: TYPE_LOGIC
		state/value:  IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) <= img/head 
		as red-value! state
	]

	tail: func [
		return:	[red-image!]
		/local
			img	[red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/tail"]]

		img: as red-image! stack/arguments
		img/head: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		img
	]

	copy: func [
		img	    	[red-image!]
		new			[red-image!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-image!]
		/local
			part?	[logic!]
			int		[red-integer!]
			img2	[red-image!]
			offset	[integer!]
			part	[integer!]
			type	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/copy"]]

		offset: img/head
		part: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) - offset
		part?: no

		if OPTION?(part-arg) [
			part?: yes
			type: TYPE_OF(part-arg)
			case [
				type = TYPE_INTEGER [
					int: as red-integer! part-arg
					part: either int/value > part [part][int/value]
				]
				type = TYPE_PAIR [0]
				true [
					img2: as red-image! part-arg
					unless all [
						TYPE_OF(img2) = TYPE_IMAGE
						img2/node = img/node
					][
						ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
					]
					part: img2/head - img/head
				]
			]
		]

		if negative? part [
			part: 0 - part
			offset: offset - part
			if negative? offset [offset: 0 part: img/head]
		]

		OS-image/clone img new part as red-pair! part-arg part?
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
			:at
			INHERIT_ACTION	;back
			null			;change
			null			;clear
			:copy
			null			;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			null			;insert
			null			;length?
			null			;move
			:next
			:pick
			:poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			:skip
			null			;swap
			:tail
			:tail?
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
