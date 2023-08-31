Red/System [
	Title:   "Image routine functions"
	Author:  "Qingtian Xie"
	File: 	 %image-stub.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2023 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define IMG_NODE_HAS_BUFFER		1
#define IMG_NODE_MODIFIED		2

OS-image: context [
	img-node!: alias struct! [
		flags	[integer!]	;-- bit 0: if set, has buffer | bit 1: if set, buffer has been modified
		handle	[int-ptr!]
		buffer	[int-ptr!]
		size	[integer!]
	]

	width?: func [
		handle		[node!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! handle/value) + 1
		IMAGE_WIDTH(inode/size)
	]

	height?: func [
		handle		[node!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! handle/value) + 1
		IMAGE_HEIGHT(inode/size)
	]
	
	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		if zero? inode/flags [
			inode/flags: IMG_NODE_HAS_BUFFER
			inode/buffer: pixbuf-to-buf inode/handle
		]
		if write? [inode/flags: inode/flags or IMG_NODE_MODIFIED]
		as integer! inode
	]

	unlock-bitmap: func [					;-- do nothing on Quartz backend
		img			[red-image!]
		data		[integer!]
	][]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! handle
		stride/value: IMAGE_WIDTH(inode/size) * 4
		inode/buffer
	]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
		/local
			node	[img-node!]
			buf		[int-ptr!]
	][
		node: as img-node! (as series! bitmap/value) + 1
		if zero? node/flags [
			node/flags: IMG_NODE_HAS_BUFFER
			node/buffer: pixbuf-to-buf node/handle
		]
		buf: node/buffer + index
		buf/value
	]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
		/local
			node	[img-node!]
			buf		[int-ptr!]
	][
		node: as img-node! (as series! bitmap/value) + 1
		if zero? node/flags [
			node/flags: IMG_NODE_HAS_BUFFER
			node/buffer: pixbuf-to-buf node/handle
		]
		node/flags: node/flags or IMG_NODE_MODIFIED
		buf: node/buffer + index
		buf/value: color
		color
	]

	delete: func [img [red-image!] /local inode [img-node!]][
		inode: as img-node! (as series! img/node/value) + 1
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
		/local
			pixbuf	[handle!]
			np		[handle!]
	][
		pixbuf: to-pixbuf img
		np: null
		as integer! make-node np null 0 width height
	]

	make-node: func [
		handle	[int-ptr!]
		buffer	[int-ptr!]
		flags	[integer!]
		width	[integer!]
		height	[integer!]
		return: [node!]
		/local
			node	[node!]
			inode	[img-node!]
	][
		node: alloc-cells 1					;-- 16 bytes
		inode: as img-node! (as series! node/value) + 1
		inode/flags: flags
		inode/handle: handle
		inode/buffer: buffer
		inode/size: height << 16 or width
		node
	]

	;-- ARGB(image! buffer) <-> ABGR(gtk)
	revert: func [
		src		[byte-ptr!]
		dst		[byte-ptr!]
		w		[integer!]
		h		[integer!]
		chs		[integer!]
		/local
			count	[integer!]
	][
		count: w * h
		loop count [
			dst/1: src/3
			dst/2: src/2
			dst/3: src/1
			either chs = 3 [
				dst/4: #"^(FF)"
				src: src + 3
			][
				dst/4: src/4
				src: src + 4
			]
			dst: dst + 4
		]
	]

	pixbuf-to-buf: func [
		pixbuf			[int-ptr!]
		return:			[int-ptr!]
	][
		pixbuf
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
	][
		null
	]

	load-pixbuf: func [
		h		[int-ptr!]
		return:	[node!]
	][
		null
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
	][
		null
	]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb-bin	[red-binary!]
		alpha-bin [red-binary!]
		color	[red-tuple!]
		return: [node!]
		/local
			a			[integer!]
			r			[integer!]
			b			[integer!]
			g			[integer!]
			x			[integer!]
			y			[integer!]
			scan0		[int-ptr!]
			pos			[integer!]
			rgb		[byte-ptr!]
			alpha	[byte-ptr!]
			len		[integer!]
			len2	[integer!]
	][
		scan0: as int-ptr! allocate width * height * 4
		y: 0
		either null? color [
			either rgb-bin <> null [
				len: binary/rs-length? rgb-bin
				len: len / 3 * 3
				rgb: binary/rs-head rgb-bin
			][len: 0]
			either alpha-bin <> null [
				len2: binary/rs-length? alpha-bin
				alpha: binary/rs-head alpha-bin
			][len2: 0]

			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					either len2 > 0 [
						a: 255 - as-integer alpha/1
						alpha: alpha + 1
						len2: len2 - 1
					][a: 255]
					either len > 0 [
						r: as-integer rgb/1
						g: as-integer rgb/2
						b: as-integer rgb/3
						rgb: rgb + 3
						len: len - 3
					][r: 255 g: 255 b: 255]
					scan0/pos: r << 16 or (g << 8) or b or (a << 24)
					x: x + 1
				]
				y: y + 1
			]
		][
			r: color/array1
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
			r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					scan0/pos: r
					x: x + 1
				]
				y: y + 1
			]
		]
		null
	]

	make-pixbuf: func [
		image	[red-image!]
		return: [int-ptr!]
	][
		null
	]

	to-pixbuf: func [
		img		[red-image!]
		return: [int-ptr!]
		/local
			inode	[img-node!]
			pixbuf	[int-ptr!]
			width 	[integer!]
			height 	[integer!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		inode/handle
	]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
	][
		slot
	]

	copy-rect: func [
		dst		[byte-ptr!]
		ds		[integer!]
		src		[byte-ptr!]
		ss		[integer!]
		x		[integer!]
		y		[integer!]
		lines	[integer!]
		/local
			offset	[integer!]
			from	[byte-ptr!]
			to		[byte-ptr!]
	][
		offset: y * ss + (x * 4)
		from: src + offset
		to: dst
		loop lines [
			copy-memory to from ds
			to: to + ds
			from: from + ss
		]
	]

	clone: func [
		src			[red-image!]
		dst			[red-image!]
		return:		[red-image!]
		/local
			inode0	[img-node!]
			width	[integer!]
			height	[integer!]
			pixels	[integer!]
			handle0	[int-ptr!]
			handle	[int-ptr!]
			scan0	[int-ptr!]
	][
		inode0: as img-node! (as series! src/node/value) + 1
		handle0: inode0/handle
		width: IMAGE_WIDTH(inode0/size)
		height: IMAGE_HEIGHT(inode0/size)
		pixels: width * height * 4

		dst/size: src/size
		dst/header: TYPE_IMAGE
		dst/head: 0
		return dst
	]

	copy: func [
		src		[red-image!]
		dst		[red-image!]
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		return: [red-image!]
		/local
			inode0	[img-node!]
			width	[integer!]
			height	[integer!]
			src-buf [byte-ptr!]
			dst-buf [byte-ptr!]
			handle0	[int-ptr!]
			handle	[int-ptr!]
			scan0	[int-ptr!]
	][
		inode0: as img-node! (as series! src/node/value) + 1
		handle0: inode0/handle
		width: IMAGE_WIDTH(inode0/size)
		height: IMAGE_HEIGHT(inode0/size)
		dst/size: h << 16 or w
		dst/header: TYPE_IMAGE
		dst/head: 0
		dst
	]
]


