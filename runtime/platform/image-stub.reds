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
	][
		0
	]

	height?: func [
		handle		[node!]
		return:		[integer!]
	][
		0
	]
	
	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
	][
		0
	]

	unlock-bitmap: func [					;-- do nothing on Quartz backend
		img			[red-image!]
		data		[integer!]
	][]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
	][
		0
	]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
	][
		0
	]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
	][
		color
	]

	delete: func [node [node!]][]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
	][
		0
	]

	make-node: func [
		handle	[int-ptr!]
		buffer	[int-ptr!]
		flags	[integer!]
		width	[integer!]
		height	[integer!]
		return: [node!]
	][
		alloc-cells 1					;-- 16 bytes
	]
	
	mark: func [node [node!] /local inode [img-node!]][
		inode: as img-node! (as series! node/value) + 1
		externals/mark inode/extID
	]

	delete: func [
		node [node!]
	][

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
	][
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
	][
		null
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
	][
		dst
	]

	copy: func [
		src		[red-image!]
		dst		[red-image!]
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		return: [red-image!]
	][
		dst
	]
]


