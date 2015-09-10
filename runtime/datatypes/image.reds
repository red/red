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

	load-in: func [
		filename [c-string!]							;-- UTF-8 file pathname
		blk		 [red-block!]
		return:  [red-image!]
		/local
			img  [red-image!]
	][
		img: as red-image! either null = blk [stack/push*][ALLOC_TAIL(blk)]
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		img/head: 0
		img/node: as node! load-image filename
		img
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
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		img/head: 0

		h: height? hr
		img/size: h << 16 or width? hr
		img/node: as node! hr
		if file? [stack/pop 1]
		img
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
			data	[int-ptr!]
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

		data: get-data as-integer img/node
		y: 0
		count: 0
		while [y < height][
			x: 0
			while [x < width][
				pixel: get-pixel data x y
				string/concatenate-literal buffer string/byte-to-hex pixel and 00FF0000h >> 16
				string/concatenate-literal buffer string/byte-to-hex pixel and FF00h >> 8
				string/concatenate-literal buffer string/byte-to-hex pixel and FFh
				count: count + 1
				if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
				part: part - 6
				if all [OPTION?(arg) part <= 0][return part]
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
					pixel: get-pixel data x y
					string/concatenate-literal buffer string/byte-to-hex pixel and FF000000h >> 24
					count: count + 1
					if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
					part: part - 2
					x: x + 1
				]
				y: y + 1
			]
			string/append-char GET_BUFFER(buffer) as-integer #"}"
		]
		update-data as-integer img/node data
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
			null		;eval-path
			null			;set-path
			null			;compare
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
			null			;pick
			null			;poke
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
