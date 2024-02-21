Red/System [
	Title:   "Image! datatype runtime functions"
	Author:  "Qingtian Xie"
	File:	 %image.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

image: context [
	verbose: 0

	acquire-buffer: func [
		img		[red-image!]
		bitmap	[int-ptr!]
		return: [int-ptr!]
		/local
			stride	[integer!]
			data	[int-ptr!]
	][
		stride: 0
		bitmap/value: OS-image/lock-bitmap img yes
		OS-image/get-data bitmap/value :stride
	]

	release-buffer: func [
		img		  [red-image!]
		bitmap	  [integer!]
		modified? [logic!]
	][
		OS-image/unlock-bitmap img bitmap
		if modified? [
			ownership/check as red-value! img words/_poke as red-value! img -1 -1
		]
	]

	rs-pick: func [
		img		[red-image!]
		offset	[integer!]
		return: [red-tuple!]
		/local
			pixel [integer!]
	][
		if IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) = offset [
			return as red-tuple! none-value
		]
		pixel: OS-image/get-pixel img/node offset
		tuple/rs-make [
			pixel and 00FF0000h >> 16
			pixel and FF00h >> 8
			pixel and FFh
			255 - (pixel >>> 24)
		]
	]

	set-many: func [
		words	[red-block!]
		img		[red-image!]
		size	[integer!]
		/local
			i	[integer!]
			h	[integer!]
	][
		h: img/head
		i: 0
		while [i < size][
			_context/set 
				as red-word! _series/pick as red-series! words i + 1 null
				as red-value! rs-pick img i + h
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
		handle  [node!]
		return: [red-image!]
	][
		img/head: 0
		img/size: (OS-image/height? handle) << 16 or OS-image/width? handle
		img/node: handle
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		img
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [red-image!]
	][
		init-image as red-image! stack/push* as node! OS-image/resize img width height
	]

	any-resize: func [
		src			[red-image!]
		dst			[red-image!]
		crop1		[red-pair!]
		start		[red-pair!]		;-- first point
		end			[red-pair!]		;-- end point
		rect.x		[int-ptr!]
		rect.y		[int-ptr!]
		rect.w		[int-ptr!]
		rect.h		[int-ptr!]
		/local
			w		[integer!]
			h		[integer!]
			w1		[integer!]
			h1		[integer!]
			vertex	[TRANS-VERTEX! value]
			pos		[red-pair!]
			vec1	[VECTOR2D! value]
			vec2	[VECTOR2D! value]
			vec3	[VECTOR2D! value]
			crop.x	[integer!]
			crop.y	[integer!]
			crop.w	[integer!]
			crop.h	[integer!]
			crop2	[red-pair!]
			handle	[integer!]
			handle2	[integer!]
			buf		[int-ptr!]
			buf2	[int-ptr!]
			pb		[byte-ptr!]
			nbuf	[int-ptr!]
			neg-x?	[logic!]
			neg-y?	[logic!]
			pt		[red-point2D!]
			fx fy	[float32!]
	][
		w: IMAGE_WIDTH(src/size)
		h: IMAGE_HEIGHT(src/size)

		either null? start [
			vertex/v1x: as float32! 0.0
			vertex/v1y: as float32! 0.0
		][
			GET_PAIR_XY(start vertex/v1x vertex/v1y)
		]
		unless null? crop1 [
			crop2: crop1 + 1
			crop.x: crop1/x
			crop.y: crop1/y
			crop.w: crop2/x
			crop.h: crop2/y
			if crop.x + crop.w > w [
				crop.w: w - crop.x
			]
			if crop.y + crop.h > h [
				crop.h: h - crop.y
			]
		]
		case [
			start = end [
				either null? crop1 [
					w1: w h1: h
				][
					w1: crop.w h1: crop.h
				]
				vertex/v2x: vertex/v1x + as float32! w1
				vertex/v2y: vertex/v1y
				vertex/v3x: vertex/v1x + as float32! w1
				vertex/v3y: vertex/v1y + as float32! h1
				vertex/v4x: vertex/v1x
				vertex/v4y: vertex/v1y + as float32! h1
			]
			start + 1 = end [					;-- two control points
				GET_PAIR_XY(end fx fy)
				vertex/v2x: fx
				vertex/v2y: vertex/v1y
				vertex/v3x: fx
				vertex/v3y: fy
				vertex/v4x: vertex/v1x
				vertex/v4y: fy
			]
			start + 2 = end [					;-- three control points
				pos: start + 1
				GET_PAIR_XY(pos vertex/v2x vertex/v2y)
				pos: pos + 1
				GET_PAIR_XY(pos vertex/v4x vertex/v4y)
				vector2d/from-points vec1 vertex/v1x vertex/v1y vertex/v2x vertex/v2y
				vector2d/from-points vec2 vertex/v1x vertex/v1y vertex/v4x vertex/v4y
				vec3/x: vec1/x + vec2/x
				vec3/y: vec1/y + vec2/y
				vertex/v3x: as float32! vec3/x + as float! vertex/v1x
				vertex/v3y: as float32! vec3/y + as float! vertex/v1y
			]
			start + 3 = end [								;-- four control points
				pos: start + 1
				GET_PAIR_XY(pos vertex/v2x vertex/v2y)
				pos: pos + 1
				GET_PAIR_XY(pos vertex/v4x vertex/v4y)
				pos: pos + 1
				GET_PAIR_XY(pos vertex/v3x vertex/v3y)
			]
			true [
				dst/header: TYPE_NONE
				exit
			]
		]
		neg-x?: no
		neg-y?: no
		if vertex/v1x > vertex/v2x [
			neg-x?: yes
			image-utils/flip-x vertex vertex/v1x
		]
		if vertex/v2y > vertex/v3y [
			neg-y?: yes
			image-utils/flip-y vertex vertex/v1y
		]

		handle: 0
		buf: acquire-buffer src :handle
		either crop1 <> null [
			pb: allocate crop.w * crop.h * 4
			image-utils/crop as byte-ptr! buf w h crop.x crop.y crop.w crop.h pb
			nbuf: image-utils/transform as int-ptr! pb crop.w crop.h vertex rect.x rect.y rect.w rect.h
			free pb
		][
			nbuf: image-utils/transform buf w h vertex rect.x rect.y rect.w rect.h
		]
		release-buffer src handle no
		if null? nbuf [dst/header: TYPE_NONE exit]
		init-image dst OS-image/make-image rect.w/1 rect.h/1 null null null
		handle2: 0
		buf2: acquire-buffer dst :handle2
		copy-memory as byte-ptr! buf2 as byte-ptr! nbuf rect.w/1 * rect.h/1 * 4
		release-buffer dst handle2 yes
		free as byte-ptr! nbuf
		if neg-x? [
			rect.w/1: 0 - rect.w/1
		]
		if neg-y? [
			rect.h/1: 0 - rect.h/1
		]
	]

	load-binary: func [
		data	[red-binary!]
		return: [red-image!]
		/local
			h	[int-ptr!]
	][
		either known-image? data [
			h: OS-image/load-binary binary/rs-head data binary/rs-length? data
			if null? h [fire [TO_ERROR(access bad-media)]]
			init-image as red-image! stack/push* h
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
			hr    [int-ptr!]
	][
		hr: OS-image/load-image src
		if null? hr [fire [TO_ERROR(access cannot-open) src]]
		img: as red-image! slot
		init-image img hr
		img
	]

	delete: func [img [red-image!]][
		OS-image/delete img
	]

	encode: func [
		image	[red-image!]
		dst		[red-value!]
		format	[integer!]
		return: [red-value!]
	][
		if zero? image/size [fire [TO_ERROR(access bad-media)]]
		if TYPE_OF(dst) = TYPE_NONE [dst: stack/push*]
		OS-image/encode image dst format
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
		type	[integer!]
		return: [red-binary!]
		/local
			sz		[integer!]
			bytes	[integer!]
			bin		[red-binary!]
			s		[series!]
			p		[byte-ptr!]
			stride	[integer!]
			bitmap	[integer!]
			i		[integer!]
			pixel	[integer!]
			data	[int-ptr!]
	][
		sz: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		bytes: case [
			type = EXTRACT_ALPHA [sz]
			type = EXTRACT_RGB	 [sz * 3]
			true				 [sz * 4]
		]
		bin: binary/make-at stack/push* bytes
		if zero? sz [return bin]

		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/tail) + bytes
		p: as byte-ptr! s/offset

		stride: 0
		bitmap: OS-image/lock-bitmap img no
		data: OS-image/get-data bitmap :stride

		either type = EXTRACT_ARGB [
			copy-memory p as byte-ptr! data bytes
		][
			i: 1
			while [i <= sz][
				pixel: data/i
				either type = EXTRACT_ALPHA [
					p/1: as-byte 255 - (pixel >>> 24)
					p: p + 1
				][
					p/1: as-byte pixel and 00FF0000h >> 16
					p/2: as-byte pixel and FF00h >> 8
					p/3: as-byte pixel and FFh
					p: p + 3
				]
				i: i + 1
			]
		]
		OS-image/unlock-bitmap img bitmap
		bin
	]

	set-data: func [
		img		[red-image!]
		bin		[red-binary!]
		method	[integer!]
		return: [red-binary!]
		/local
			offset	[integer!]
			sz		[integer!]
			bin-sz	[integer!]
			s		[series!]
			p		[byte-ptr!]
			stride	[integer!]
			bitmap	[integer!]
			pixel	[integer!]
			tp		[red-tuple!]
			int		[red-integer!]
			color	[integer!]
			data	[int-ptr!]
			end		[int-ptr!]
			type	[integer!]
			mask	[integer!]
	][
		sz: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		if zero? sz [return bin]

		offset: img/head
		stride: 0
		bitmap: OS-image/lock-bitmap img yes
		data: OS-image/get-data bitmap :stride
		end: data + sz

		type: TYPE_OF(bin)
		either type = TYPE_BINARY [
			bin-sz: binary/rs-length? bin
			s: GET_BUFFER(bin)
			p: as byte-ptr! s/offset
			either method = EXTRACT_ARGB [
				sz: sz * 4
				if bin-sz < sz [sz: bin-sz]
				copy-memory as byte-ptr! data p sz
			][
				if method = EXTRACT_RGB [bin-sz: bin-sz / 3]	;-- number of pixels
				if bin-sz < sz [end: data + bin-sz]
				while [data < end][
					pixel: data/value
					either method = EXTRACT_ALPHA [
						pixel: pixel and 00FFFFFFh or ((255 - as-integer p/1) << 24)
						p: p + 1
					][
						pixel: pixel and FF000000h
								or ((as-integer p/1) << 16)
								or ((as-integer p/2) << 8)
								or (as-integer p/3)
						p: p + 3
					]
					data/value: pixel
					data: data + 1
				]
			]
		][
			switch type [
				TYPE_TUPLE [
					tp: as red-tuple! bin
					color: tp/array1
					if TUPLE_SIZE?(tp) = 3 [color: color and 00FFFFFFh]
				]
				TYPE_INTEGER [
					int: as red-integer! bin
					color: int/value
				]
				default [
					OS-image/unlock-bitmap img bitmap
					fire [TO_ERROR(script invalid-arg) bin]
				]
			]
			either method = EXTRACT_ARGB [
				mask: 255 - (color >>> 24) << 24
				color: color >> 16 and FFh or (color and FF00h) or (color and FFh << 16) or mask
				until [
					data/value: color
					data: data + 1
					data = end
				]
			][
				color: either method = EXTRACT_RGB [
					mask: FF000000h
					color: color and 00FFFFFFh
					color >> 16 or (color and FF00h) or (color and FFh << 16)
				][
					mask: 00FFFFFFh
					255 - color << 24
				]
				while [data < end][
					data/value: data/value and mask or color
					data: data + 1
				]
			]
		]
		OS-image/unlock-bitmap img bitmap
		ownership/check as red-value! img words/_poke as red-value! bin img/head 0
		bin
	]

	get-position: func [
		img			[red-image!]
		index		[red-integer!]
		base		[integer!]
		out-range	[int-ptr!]
		return:		[integer!]
		/local
			pair	[red-pair!]
			offset	[integer!]
			max		[integer!]
			idx		[integer!]
			w		[integer!]
			h		[integer!]
			x		[integer!]
			y		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/at"]]

		w: IMAGE_WIDTH(img/size)
		h: IMAGE_HEIGHT(img/size)
		either TYPE_OF(index) = TYPE_INTEGER [
			idx: index/value
		][											;-- pair!
			pair: as red-pair! index
			x: pair/x
			y: pair/y
			if out-range <> null [
				either base = 1 [
					if any [x > w x <= 0 y > h y <= 0][out-range/value: 1]
				][
					if any [x >= w x < 0 y >= h y < 0][out-range/value: 1]
				]
			]

			if all [base = 1 y > 0][y: y - 1]
			idx: y * w + x
		]

		if all [base = 1 idx <= 0][base: base - 1]
		offset: img/head + idx - base
		if negative? offset [offset: 0 idx: 0]
		max: w * h
		if offset >= max [offset: max idx: 0]
		if all [out-range <> null zero? idx][out-range/value: 1]
		offset
	]

	;-- Actions --

	make: func [
		proto	[red-image!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-image!]
		/local
			img		[red-image!]
			pair	[red-pair!]
			blk		[red-block!]
			bin		[red-binary!]
			rgb		[red-binary!]
			alpha	[red-binary!]
			color	[red-tuple!]
			x		[integer!]
			y		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/make"]]

		img: as red-image! stack/push*
		img/header: TYPE_IMAGE
		img/head: 0

		if all [
			TYPE_OF(spec) = TYPE_BLOCK
			zero? block/rs-length? as red-block! spec
		][
			either TYPE_OF(proto) = TYPE_IMAGE [
				return copy proto img null yes null
			][
				fire [TO_ERROR(script invalid-arg) spec]
			]
		]

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
						TYPE_BINARY [rgb: bin]
						TYPE_TUPLE	[color: as red-tuple! bin]
						default		[fire [TO_ERROR(script invalid-arg) bin]]
					]
				]
				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					check-arg-type as red-value! bin TYPE_BINARY
					alpha: bin
				]
			]
			default [return to proto spec type]
		]

		x: pair/x
		if negative? x [x: 0]
		y: pair/y
		if negative? y [y: 0]
		img/size: y << 16 or x
		img/node: OS-image/make-image x y rgb alpha color
		img
	]

	to: func [											;-- to image! face! only
		proto	[red-image!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-image!]
		/local
			ret [red-logic!]
	][
		switch TYPE_OF(spec) [
			TYPE_IMAGE [					;-- copy it
				return copy as red-image! spec proto null yes null
			]
			TYPE_OBJECT [
				#either modules contains 'View [
					spec: stack/push spec						;-- store spec to avoid corruption (#2460)
					#call [face? spec]
					ret: as red-logic! stack/arguments
					if ret/value [return exec/gui/OS-to-image as red-object! spec]
				][0]
			]
			default [0]
		]
		fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_IMAGE spec]
		as red-image! proto
	]

	serialize: func [
		img		[red-image!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			height	[integer!]
			width	[integer!]
			alpha?	[logic!]
			formed	[c-string!]
			pixel	[integer!]
			count	[integer!]
			bitmap	[integer!]
			data	[int-ptr!]
			stride	[integer!]
			size	[integer!]
			end		[int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/serialize"]]

		alpha?: no
		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)

		string/concatenate-literal buffer "make image! ["
		part: part - 13
		formed: integer/form-signed width
		string/concatenate-literal buffer formed
		part: part - system/words/length? formed

		string/append-char GET_BUFFER(buffer) as-integer #"x"
		formed: integer/form-signed height
		string/concatenate-literal buffer formed
		part: part - system/words/length? formed

		if null? img/node [							;-- empty image
			string/concatenate-literal buffer " #{}]"
			return part - 5
		]

		stride: 0
		bitmap: OS-image/lock-bitmap img no
		data: OS-image/get-data bitmap :stride
		end: data + (width * height)
		data: data + img/head
		size: as-integer end - data

		string/append-char GET_BUFFER(buffer) as-integer space
		string/concatenate-literal buffer "#{"
		part: part - 2
		if all [not flat? size > 30][
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: object/do-indent buffer indent part - 1
		]

		count: 0
		while [data < end][
			pixel: data/value
			string/concatenate-literal buffer string/byte-to-hex pixel and 00FF0000h >> 16
			string/concatenate-literal buffer string/byte-to-hex pixel and FF00h >> 8
			string/concatenate-literal buffer string/byte-to-hex pixel and FFh
			unless flat? [
				count: count + 1
				if count % 10 = 0 [
					string/append-char GET_BUFFER(buffer) as-integer lf
					part: object/do-indent buffer indent part - 1
				]
			]
			part: part - 6
			if all [OPTION?(arg) part <= 0][
				OS-image/unlock-bitmap img bitmap
				return part
			]
			if pixel >>> 24 <> 255 [alpha?: yes]
			data: data + 1
		]
		if all [not flat? size > 30 count % 10 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: object/do-indent buffer indent part - 1
		]
		string/append-char GET_BUFFER(buffer) as-integer #"}"

		if alpha? [
			data: data - (width * height)
			string/append-char GET_BUFFER(buffer) as-integer space
			string/concatenate-literal buffer "#{^/"
			part: part - 4
			count: 0
			while [data < end][
				pixel: data/value
				string/concatenate-literal buffer string/byte-to-hex 255 - (pixel >>> 24)
				unless flat? [
					count: count + 1
					if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
				]
				part: part - 2
				if all [OPTION?(arg) part <= 0][
					OS-image/unlock-bitmap img bitmap
					return part
				]
				data: data + 1
			]
			string/append-char GET_BUFFER(buffer) as-integer #"}"
		]
		OS-image/unlock-bitmap img bitmap
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

		serialize img buffer no no no arg part 0
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

		serialize img buffer only? all? flat? arg part indent + 1
	]

	length?: func [
		img		[red-image!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/length?"]]

		IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
	]

	;--- Reading actions ---

	pick: func [
		img		[red-image!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			out-range [integer!]
			offset	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/pick"]]

		out-range: 0
		offset: either null? boxed [img/head + index - 1][get-position img as red-integer! boxed 1 :out-range]
		as red-value! either out-range = 1 [none-value][rs-pick img offset]
	]

	poke: func [
		img		[red-image!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			out-range [integer!]
			color	[red-tuple!]
			offset	[integer!]
			p		[byte-ptr!]
			r		[integer!]
			g		[integer!]
			b		[integer!]
			a		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/poke"]]

		out-range: 0
		offset: get-position img as red-integer! boxed 1 :out-range
		either out-range = 1 [
			fire [TO_ERROR(script out-of-range) boxed]
		][
			unless TYPE_TUPLE = TYPE_OF(data) [fire [TO_ERROR(script invalid-arg) data]]
			color: as red-tuple! data
			p: (as byte-ptr! color) + 4
			r: as-integer p/1
			g: as-integer p/2
			b: as-integer p/3
			a: either TUPLE_SIZE?(color) > 3 [255 - as-integer p/4][255]
			OS-image/set-pixel img/node offset a << 24 or (r << 16) or (g << 8) or b
		]
		ownership/check as red-value! img words/_poke data offset 1
		as red-value! data
	]

	eval-path: func [
		parent	[red-image!]								;-- implicit type casting
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
			set? [logic!]
			w	 [red-word!]
			sym  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/eval-path"]]

		set?: value <> null
		switch TYPE_OF(element) [
			TYPE_INTEGER
			TYPE_PAIR [
				either set? [
					poke parent -1 value element
				][
					pick parent -1 element
				]
			]
			TYPE_WORD [
				w: as red-word! element
				sym: symbol/resolve w/symbol
				case [
					sym = words/size [
						if set? [fire [TO_ERROR(script invalid-path) path element]]
						pair/push IMAGE_WIDTH(parent/size) IMAGE_HEIGHT(parent/size)
					]
					sym = words/argb [
						either set? [
							set-data parent as red-binary! value EXTRACT_ARGB
						][
							extract-data parent EXTRACT_ARGB
						]
					]
					sym = words/rgb [
						either set? [
							set-data parent as red-binary! value EXTRACT_RGB
						][
							extract-data parent EXTRACT_RGB
						]
					]
					sym = words/alpha [
						either set? [
							set-data parent as red-binary! value EXTRACT_ALPHA
						][
							extract-data parent EXTRACT_ALPHA
						]
					]
					true [
						fire [TO_ERROR(script invalid-path) path element]
						null
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-path) path element]
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
			type  [integer!]
			res   [integer!]
			bmp1  [integer!]
			bmp2  [integer!]
			same? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_IMAGE [RETURN_COMPARE_OTHER]

		same?: all [
			arg1/node = arg2/node
			arg1/head = arg2/head
		]
		if op = COMP_SAME [return either same? [0][-1]]
		if all [
			same?
			any [op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL]
		][return 0]

		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				;-- 1. compare size first
				;-- 2. if the same size, compare contents
				bmp1: IMAGE_WIDTH(arg1/size) * IMAGE_HEIGHT(arg1/size)
				bmp2: IMAGE_WIDTH(arg2/size) * IMAGE_HEIGHT(arg2/size)
				either bmp1 <> bmp2 [
					res: SIGN_COMPARE_RESULT(bmp1 bmp2)
				][
					either zero? arg1/size [res: 0][
						type: 0
						bmp1: OS-image/lock-bitmap arg1 no
						bmp2: OS-image/lock-bitmap arg2 no
						res: compare-memory
							as byte-ptr! OS-image/get-data bmp1 :type
							as byte-ptr! OS-image/get-data bmp2 :type
							IMAGE_WIDTH(arg1/size) * IMAGE_HEIGHT(arg2/size) * 4
						OS-image/unlock-bitmap arg1 bmp1
						OS-image/unlock-bitmap arg2 bmp2
					]
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
		img/head: get-position img as red-integer! img + 1 1 null
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
		if IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) >= offset [
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
		img/head: get-position img as red-integer! img + 1 0 null
		img
	]

	tail?: func [
		return:	  [red-value!]
		/local
			img	   [red-image!]
			state  [red-logic!]
			offset [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/tail?"]]

		img:    as red-image! stack/arguments
		state:  as red-logic! img
		offset: img/head + 1

		state/header: TYPE_LOGIC
		state/value:  not IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) >= offset
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

	change: func [
		img		 [red-image!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg  [red-value!]
		return:	 [red-image!]
		/local
			type [integer!]
			bmp1 [integer!]
			bmp2 [integer!]
			bin1 [int-ptr!]
			bin2 [int-ptr!]
			img2 [red-image!]
			idx  [red-value! value]
			head n i1 i2 [integer!]
			w1 h1 w2 h2 [integer!]
			x x1 y1 x2 y2 [integer!]
			stride1 stride2 [integer!]
	][
		if OPTION?(dup-arg) [--NOT_IMPLEMENTED--]
		if OPTION?(part-arg) [--NOT_IMPLEMENTED--]

		head: img/head
		type: TYPE_OF(value)
		switch type [
			TYPE_TUPLE [
				ownership/check as red-value! img words/_change null head 1
				integer/make-at idx img/head
				poke img -1 idx value
				img/head: head + 1
				ownership/check as red-value! img words/_changed null head 1
			]
			TYPE_IMAGE [
				img2: as red-image! value
				w1: IMAGE_WIDTH(img/size)
				h1: IMAGE_HEIGHT(img/size)

				if w1 * h1 <= head [return img]	;-- at the tail, change nothing

				ownership/check as red-value! img words/_change null head 1

				x: head % w1
				x1: x
				y1: head / w1

				stride1: 0
				stride2: 0
				bmp1: OS-image/lock-bitmap img yes
				bin1: OS-image/get-data bmp1 :stride1
				bmp2: OS-image/lock-bitmap img2 no
				bin2: OS-image/get-data bmp2 :stride2

				w2: IMAGE_WIDTH(img2/size)
				h2: IMAGE_HEIGHT(img2/size)
				x2: 0
				y2: 0
				n: 0
				while [all [y1 < h1 y2 < h2]] [
					while [all [x1 < w1 x2 < w2]] [
						i1: y1 * w1 + x1 + 1
						i2: y2 * w2 + x2 + 1
						bin1/i1: bin2/i2
						n: n + 1
						x1: x1 + 1
						x2: x2 + 1
					]
					x1: x
					x2: 0
					y1: y1 + 1
					y2: y2 + 1
				]

				OS-image/unlock-bitmap img bmp1
				OS-image/unlock-bitmap img2 bmp2

				x1: x + w2
				if x1 > w1 [x1: w1]
				img/head: y1 - 1 * w1 + x1
				ownership/check as red-value! img words/_changed null head n
			]
			default [fire [TO_ERROR(script invalid-type) datatype/push type]]
		]
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
			int		[red-integer!]
			sz		[red-pair!]
			img1	[red-image!]
			img2	[red-image!]
			offset	[integer!]
			type	[integer!]
			x y w h	[integer!]
			width	[integer!]
			height	[integer!]
			return-empty-img [subroutine!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/copy"]]

		return-empty-img: [
			new/size: 0
			new/header: TYPE_IMAGE
			new/head: 0
			new/node: null
			return new
		]

		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)

		if any [
			width <= 0
			height <= 0
		][
			return-empty-img
		]

		offset: img/head
		either OPTION?(part-arg) [
			type: TYPE_OF(part-arg)
			case [
				type = TYPE_INTEGER [	;-- view the image as a 1-D series, return a Partx1 image 
					--NOT_IMPLEMENTED--
				]
				type = TYPE_PAIR [
					x: offset % width
					y: offset / width
					sz: as red-pair! part-arg
					case [
						all [sz/x > 0 sz/y > 0 offset < (width * height)][
							w: width - x
							h: height - y
							if sz/x < w [w: sz/x]
							if sz/y < h [h: sz/y]
						]
						all [sz/x < 0 sz/y < 0 offset > 0][
							w: 0 - sz/x
							h: 0 - sz/y
							if zero? x [x: width]
							either w > x [
								w: x
								x: 0
							][
								x: x - w
							]
							if y < height [y: y + 1]
							either h > y [
								h: y
								y: 0
							][
								y: y - h
							]
						]
						true [return-empty-img]
					]

				]
				type = TYPE_IMAGE [
					img2: as red-image! part-arg
					unless all [
						TYPE_OF(img2) = TYPE_IMAGE
						img2/node = img/node
					][
						ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
					]
					either img2/head > img/head [
						img1: img
					][
						img1: img2
						img2: img
					]

					offset: img2/head
					w: offset / width
					h: offset / width

					offset: img1/head
					x: offset % width
					y: offset / width

					w: w - x
					h: h - y
				]
				true [ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)]
			]
		][
			if zero? offset [
				return OS-image/clone img new
			]

			x: offset % width
			y: offset / width
			w: width - x
			h: height - y
		]

		either any [
			w <= 0
			h <= 0
		][
			return-empty-img
		][
			OS-image/copy img new x y w h
		]
		new
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
			:to
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
			:change
			null			;clear
			:copy
			null			;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			null			;insert
			:length?
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
