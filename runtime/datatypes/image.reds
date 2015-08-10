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
			file? [logic!]
	][
		img: as red-image! slot
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		img/head: 0
		file?: TYPE_OF(src) = TYPE_FILE
		if file? [
			;str: as red-string! stack/push*			;@@ FIX it, seems it is a bug
			str: declare red-string!
			str: string/rs-make-at as cell! str string/rs-length? as red-string! src
			file/to-local-path src str no
			src: str
		]
		img/node: as node! load-image
			#either OS = 'Windows [
				unicode/to-utf16 src
			][
				len: -1
				unicode/to-utf8 src :len
			]
		;if file? [stack/pop 1]							;@@ FIX it, seems it is a bug
		img
	]

	;-- Actions --

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		type	 [integer!]
		return:	 [red-image!]
		/local
			img [red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/make"]]

		img: as red-image! string/make proto spec type
		set-type as red-value! img TYPE_IMAGE
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
			height [integer!]
			width  [integer!]
			blk [red-block!]
			rgb [red-binary!]
			p-rgb [byte-ptr!]
			p-alpha [byte-ptr!]
			s	[series!]
			alpha [red-binary!]
			pixel [integer!]
			x		[integer!]
			y		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "img/serialize"]]

		string/concatenate-literal buffer "make image! "

		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)
		blk: block/make-at as red-block! stack/push* 3
		pair/make-in blk width height
		rgb: binary/make-in blk width * height * 3
		s: GET_BUFFER(rgb)
		s/tail: as cell! (as byte-ptr! s/tail ) + (width * height * 3)
		alpha: binary/make-in blk width * height
		s: GET_BUFFER(alpha)
		s/tail: as cell! (as byte-ptr! s/tail) + (width * height)
		p-rgb: binary/rs-head rgb
		p-alpha: binary/rs-head alpha
		x: 0
		y: 0
		while [y < height][
			while [x < width][
				pixel: get-pixel img/node x y
                p-rgb/1: as-byte pixel and 00FF0000h >> 16
                p-rgb/2: as-byte pixel and FF00h >> 8
				p-rgb/3: as-byte pixel and FFh
                p-alpha/1: as-byte pixel and FF000000h >> 24
                p-rgb: p-rgb + 3
                p-alpha: p-alpha + 1
                x: x + 1
			]
			y: y + 1
		]
		part: block/mold blk buffer only? all? flat? arg part -1
		stack/pop 1
		part
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
			TYPE_SERIES
			"image!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			null			;to
			:form
			:mold
			INHERIT_ACTION	;eval-path
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
			null			;append
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			null			;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
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
