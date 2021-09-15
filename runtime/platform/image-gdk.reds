Red/System [
	Title:   "Image routine functions using gdk"
	Author:  "Qingtian Xie, RCqls"
	File: 	 %image-gdk.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define IMG_NODE_HAS_BUFFER		1
#define IMG_NODE_MODIFIED		2

#enum GdkColorspace! [
	GDK_COLORSPACE_RGB
]

GError!: alias struct! [
	domain		[integer!]
	code		[integer!]
	message		[c-string!]
]

OS-image: context [

	img-node!: alias struct! [
		flags	[integer!]	;-- bit 0: if set, has buffer | bit 1: if set, buffer has been modified
		handle	[int-ptr!]
		buffer	[int-ptr!]
		size	[integer!]
	]

	#either OS = 'Windows [
		#define LIBGDK-file		"libgdk_pixbuf-2.0.dll" ;or libgdk-3-0.dll
	][
		#define LIBGDK-file		"libgdk_pixbuf-2.0.so.0" ;or libgdk-3.so.0
	]

	#import [
		LIBGDK-file cdecl [
			gdk_pixbuf_new: "gdk_pixbuf_new" [
				colorsp		[integer!]
				alpha		[logic!]
				bits		[integer!]
				width		[integer!]
				height		[integer!]
				return:		[handle!]
			]
			gdk_pixbuf_new_subpixbuf: "gdk_pixbuf_new_subpixbuf" [
				pixbuf 		[handle!]
				x			[integer!]
				y			[integer!]
				width		[integer!]
				height		[integer!]
				return:		[handle!]
			]
			gdk_pixbuf_new_from_bytes: "gdk_pixbuf_new_from_bytes" [
				data 		[handle!]
				colorsp 	[integer!]
				alpha 		[logic!]
				bits 		[integer!]
				width 		[integer!]
				height 		[integer!]
				rowstride	[integer!]
				return: 	[handle!]
			]
			gdk_pixbuf_new_from_file: "gdk_pixbuf_new_from_file" [
				name		[c-string!]
				err 		[handle!]
				return: 	[handle!]
			]
			gdk_pixbuf_copy: "gdk_pixbuf_copy" [
				pixbuf 		[handle!]
				return: 	[handle!]
			]
			gdk_pixbuf_get_byte_length: "gdk_pixbuf_get_byte_length" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_width: "gdk_pixbuf_get_width" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_height: "gdk_pixbuf_get_height" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_pixels: "gdk_pixbuf_get_pixels" [
				pixbuf 		[handle!]
				return: 	[byte-ptr!]
			]
			gdk_pixbuf_read_pixels: "gdk_pixbuf_read_pixels" [
				pixbuf 		[handle!]
				return: 	[byte-ptr!]
			]
			gdk_pixbuf_get_rowstride: "gdk_pixbuf_get_rowstride"  [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_n_channels: "gdk_pixbuf_get_n_channels" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_bits_per_sample: "gdk_pixbuf_get_bits_per_sample" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_has_alpha: "gdk_pixbuf_get_has_alpha" [
				pixbuf 		[handle!]
				return:		[logic!]
			]
			gdk_pixbuf_loader_new: "gdk_pixbuf_loader_new" [
				return: 	[handle!]
			]
			gdk_pixbuf_loader_get_pixbuf: "gdk_pixbuf_loader_get_pixbuf" [
				loader		[handle!]
				return: 	[handle!]
			]
			gdk_pixbuf_loader_write: "gdk_pixbuf_loader_write" [
				loader		[handle!]
				data 		[handle!]
				size 		[integer!]
				err 		[handle!]
				return: 	[logic!]
			]
			gdk_pixbuf_loader_close: "gdk_pixbuf_loader_close" [
				loader		[handle!]
				err 		[handle!]
				return: 	[logic!]
			]
			gdk_pixbuf_save: "gdk_pixbuf_save" [
				[variadic]
				return: 	[logic!]
			]
			gdk_pixbuf_scale_simple: "gdk_pixbuf_scale_simple"  [
				src			[handle!]
				dest_width	[integer!]
				dest_height	[integer!]
				interp_type	[integer!]
				return: 	[handle!]
			]
			g_object_unref: "g_object_unref" [
				obj 	[handle!]
			]
		]
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
		if inode/handle <> null [g_object_unref inode/handle inode/handle: null]
		if inode/buffer <> null [free as byte-ptr! inode/buffer inode/buffer: null]
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
		np: gdk_pixbuf_scale_simple pixbuf width height 2
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
		/local
			width		[integer!]
			height		[integer!]
			channels	[integer!]
			buff		[byte-ptr!]
			p			[byte-ptr!]
	][
		width: gdk_pixbuf_get_width pixbuf
		height: gdk_pixbuf_get_height pixbuf
		channels: gdk_pixbuf_get_n_channels pixbuf
		buff: allocate width * height * 4
		p: gdk_pixbuf_get_pixels pixbuf
		revert p buff width height channels
		as int-ptr! buff
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
		/local
			loader	[handle!]
			h		[handle!]
	][
		loader: gdk_pixbuf_loader_new
		gdk_pixbuf_loader_write loader as int-ptr! data len null
		gdk_pixbuf_loader_close loader null
		h: gdk_pixbuf_loader_get_pixbuf loader
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
	]

	load-pixbuf: func [
		h		[int-ptr!]
		return:	[node!]
	][
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
		/local
			path	[c-string!]
			h		[int-ptr!]
	][
		path: file/to-OS-path src
		h: gdk_pixbuf_new_from_file path null
		if null? h [return null]
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
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
		make-node null scan0 IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED width height
	]

	make-pixbuf: func [
		image	[red-image!]
		return: [int-ptr!]
		/local
			w		[integer!]
			h		[integer!]
			data	[int-ptr!]
			end		[int-ptr!]
			clr		[integer!]
			pixbuf	[int-ptr!]
			buf		[byte-ptr!]
			node	[img-node!]
	][
		node: as img-node! (as series! image/node/value) + 1
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		pixbuf: gdk_pixbuf_new 0 yes 8 w h
		buf: gdk_pixbuf_get_pixels pixbuf
		revert as byte-ptr! node/buffer buf w h 4
		pixbuf
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
		if inode/flags and IMG_NODE_MODIFIED <> 0 [
			pixbuf: make-pixbuf img
			unless null? inode/handle [g_object_unref inode/handle]
			inode/handle: pixbuf
			inode/flags: IMG_NODE_HAS_BUFFER
		]
		inode/handle
	]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
		/local
			type		[c-string!]
			path		[c-string!]
			pixbuf		[handle!]
			err 		[GError!]
			perr		[ptr-value!]
	][
		switch format [
			IMAGE_BMP  [type: "bmp"]
			IMAGE_PNG  [type: "png"]
			;IMAGE_GIF  [type: "gif"]
			IMAGE_JPEG [type: "jpeg"]
			IMAGE_TIFF [type: "tiff"]
			default    [probe "Cannot find image encoder" return null]
		]

		pixbuf: to-pixbuf image
		switch TYPE_OF(slot) [
			TYPE_URL
			TYPE_FILE [
				perr/value: null
				path: file/to-OS-path as red-string! slot
				unless gdk_pixbuf_save [pixbuf path type :perr null] [
					err: as GError! perr/value
					probe ["OS-image/encode error: " err/domain " " err/code " " err/message]
				]
			]
			default [0]
		]
		slot
	]

	copy-rect: func [
		dst		[byte-ptr!]
		dw		[integer!]
		dh		[integer!]
		ds		[integer!]
		src		[byte-ptr!]
		sw		[integer!]
		sh		[integer!]
		ss		[integer!]
		x		[integer!]
		y		[integer!]
		lines	[integer!]
		/local
			offset	[integer!]
			from	[byte-ptr!]
			to		[byte-ptr!]
	][
		offset: y * ss + x * 4
		from: src + offset
		to: dst
		loop lines [
			copy-memory to from ds
			to: to + ds
			from: from + ss
		]
	]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
		/local
			inode0	[img-node!]
			width	[integer!]
			height	[integer!]
			offset	[integer!]
			x		[integer!]
			y		[integer!]
			h		[integer!]
			w		[integer!]
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
		offset: src/head

		if any [
			width <= 0
			height <= 0
		][
			dst/size: 0
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: make-node null null IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED 0 0
			return dst
		]

		if all [zero? offset not part?][
			either null? handle0 [
				scan0: as int-ptr! allocate part * 4
				dst/node: make-node null scan0 IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED width height
				copy-memory as byte-ptr! scan0 as byte-ptr! inode0/buffer part * 4
			][
				handle: gdk_pixbuf_copy handle0
				dst/node: make-node handle null 0 width height
			]
			dst/size: src/size
			dst/header: TYPE_IMAGE
			dst/head: 0
			return dst
		]

		x: offset % width
		y: offset / width
		either all [part? TYPE_OF(size) = TYPE_PAIR][
			w: width - x
			h: height - y
			if size/x < w [w: size/x]
			if size/y < h [h: size/y]
		][
			either zero? part [
				w: 0 h: 0
			][
				either part < width [h: 1 w: part][
					h: part / width
					w: width
				]
			]
		]
		if any [
			w <= 0
			h <= 0
		][
			dst/size: 0
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: make-node null null IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED 0 0
			return dst
		]

		either null? handle0 [
			dst-buf: allocate w * h * 4
			dst/node: make-node null as int-ptr! dst-buf IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED w h
			src-buf: as byte-ptr! inode0/buffer
			copy-rect dst-buf w h w * 4 src-buf width height width * 4 x y h
		][
			handle: gdk_pixbuf_new_subpixbuf gdk_pixbuf_copy handle0 x y w h
			dst/node: make-node handle null 0 w h
		]
		dst/size: h << 16 or w
		dst/header: TYPE_IMAGE
		dst/head: 0
		dst
	]

]


