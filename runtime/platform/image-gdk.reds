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


OS-image: context [

	img-node!: alias struct! [
		flags	[integer!]	;-- bit 0: if set, has buffer | bit 1: if set, buffer has been modified
		handle	[int-ptr!]
		buffer	[int-ptr!]
		size	[integer!]
	]

	#either OS = 'Windows [
		#define LIBGDK-file		"libgtk-3-0.dll" ;or libgdk-3-0.dll
	][
		#define LIBGDK-file		"libgtk-3.so.0" ;or libgdk-3.so.0
	]

	#import [
		LIBGDK-file cdecl [
			gdk_pixbuf_new: "gdk_pixbuf_new" [
				colorsp 	[integer!]
				alpha 		[logic!]
				bits 		[integer!]
				width 		[integer!]
				height 		[integer!]
				return: 	[handle!]
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
			gdk_pixbuf_get_rowstride: "gdk_pixbuf_get_rowstride"  [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_n_channels: "gdk_pixbuf_get_n_channels" [
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

	lock-bitmap: func [						;-- do nothing on Quartz backend
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		if zero? inode/flags [
			inode/flags: IMG_NODE_HAS_BUFFER
			inode/buffer: OS-image/data-to-image inode/handle -1 yes yes
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
			node	[img-node!]
	][
		node: as img-node! handle
		stride/value: IMAGE_WIDTH(node/size) * 4
		node/buffer
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
		node/flags: node/flags or IMG_NODE_MODIFIED
		buf: node/buffer + index
		buf/value: color
		color
	]

	delete: func [img [red-image!]][
		; GdipDisposeImage as-integer img/node
		0
	]

	; copied from quartz but do not think it is finished
	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
		/local
			graphic [integer!]
			old-w	[integer!]
			old-h	[integer!]
			format	[integer!]
			bitmap	[integer!]
	][
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		graphic: 0
		format: 0
		bitmap: 0
		as-integer img/node
	]

	; UNUSED in Quartz ???? Maybe for a future use???? 
	copy: func [
		dst		[integer!]
		src		[integer!]
		bytes	[integer!]
		offset	[integer!]
		/local
			dst-buf [byte-ptr!]
			src-buf [byte-ptr!]
	][
		; dst-buf: CGBitmapContextGetData dst
		; src-buf: CGBitmapContextGetData src
		; copy-memory dst-buf src-buf + offset bytes
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

	alpha-channel?: func [
		pixbuf	[integer!]
		return:	[logic!]
	][
		gdk_pixbuf_get_has_alpha as handle! pixbuf
	]

	; In particular used to query buffer from handle in lock-bitmap
	data-to-image: func [				;-- convert Pixbuf to OS handle or internal buffer
		data		[int-ptr!]
		len 		[integer!] ; @@ added for data length
		image?		[logic!]
		edit?		[logic!]
		return: 	[int-ptr!]
		/local
			; color-space [integer!] ; Only  RGB 
			width		[integer!]
			height		[integer!]
			ctx			[integer!]
			;rect		[NSRect!]
			bytes-row	[integer!]
			image-data	[integer!]
			image		[integer!]
			n			[integer!]
			info		[integer!]
			alpha?		[logic!]
			buf			[byte-ptr!]
			data-pixbuf	[int-ptr!]
			end			[int-ptr!]
			pixel		[integer!]
			loader 		[handle!]
	][
		either image? [
			image: as-integer data
		][
			loader: gdk_pixbuf_loader_new
			gdk_pixbuf_loader_write loader data len null
			gdk_pixbuf_loader_close loader null
			image: as-integer gdk_pixbuf_loader_get_pixbuf loader
		]

		unless edit? [return as int-ptr! image]

		alpha?: alpha-channel? image
		; color-space:  ONLY RGB
		width: gdk_pixbuf_get_width as handle! image
		height: gdk_pixbuf_get_height as handle! image

		bytes-row: width * 4
		; ??? either alpha? [
		; 	info: 2101h		;-- kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents
		; 	n: 4
		; ][
		; 	info: 8198		;-- kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little
		; 	n: 1
		; ]

		; maybe better use other copy
		buf: gdk_pixbuf_get_pixels gdk_pixbuf_copy as handle! image
		data-pixbuf: as int-ptr! buf
		end: data-pixbuf + (width * height)
		;; print ["wxh: " width "x" height lf]
		while [data-pixbuf < end][
			pixel: data-pixbuf/value
			; @@debug: print ["pixel:" pixel lf]
			pixel: (pixel >> 8) or (255 - (pixel << 24)) ; RGBA -> ARGB
			data-pixbuf/value: pixel
			data-pixbuf: data-pixbuf + 1
		]
		as int-ptr! buf
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
		/local
			h	[int-ptr!]
	][
		;; print ["load-binary" lf]

		h: data-to-image as int-ptr! data len no no
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
	]

	load-pixbuf: func [
		h		[int-ptr!]
		return:	[node!]
	][
		;; print ["load-pixbuf" lf]
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
		;as node! 0
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
		/local
			path 	[c-string!]
			h		[int-ptr!]
	][
		path: file/to-OS-path src
		;; print [ "load-image: " path lf]
		h: gdk_pixbuf_new_from_file path null
		;; print ["handle: " h ", wxh: " gdk_pixbuf_get_width h "x" gdk_pixbuf_get_height h]
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
	]

	; DO NOT KNOW IF USEFUL!
	; make-image: func [
	; 	width	[integer!]
	; 	height	[integer!]
	; 	rgb		[byte-ptr!]
	; 	alpha	[byte-ptr!]
	; 	color	[red-tuple!]
	; 	return: [int-ptr!]
	; 	/local
	; 		a		[integer!]
	; 		r		[integer!]
	; 		b		[integer!]
	; 		g		[integer!]
	; 		pixbuf	[handle!]
	; 		pixels	[byte-ptr!]
	; 		channel [integer!]
	; 		cpt 	[integer!]
	; 		end		[integer!]
	; ][
	; 	;print-line "make-image"
	; 	if any [zero? width zero? height][return null]
	; 	pixbuf: gdk_pixbuf_new 0 yes 8 width height
	; 	if null? pixbuf [
	; 	 	fire [TO_ERROR(script invalid-arg) pair/push width height]
	; 	]
	; 	;print-line "ici"
	; 	pixels: gdk_pixbuf_get_pixels pixbuf
	; 	channel: gdk_pixbuf_get_n_channels pixbuf ; = 4 
	; 	end: width * height

	; 	; @@ TO IMPROVE since I mimicked what was in gdiplus (integer!) but gdk is directly in byte! 
	; 	either null? color [
	; 		cpt: 0
	; 		while [cpt < end][
	; 			either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
	; 			either null? rgb [r: 255 g: 255 b: 255][
	; 				r: as-integer rgb/1
	; 				g: as-integer rgb/2
	; 				b: as-integer rgb/3
	; 				rgb: rgb + 3
	; 			]
	; 			pixels/1: as byte! (r << 16)
	; 			pixels/2: as byte! (g << 8)
	; 			pixels/3: as byte! b
	; 			pixels/4: as byte! a << 24
	; 			pixels: pixels + channel
	; 			cpt: cpt + 1
	; 		]
	; 	][
	; 		r: color/array1
	; 		a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
	; 		r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
	; 		cpt: 0
	; 		while [cpt < end][
	; 			pixels/1: as byte! (r >> 16 and FFh)
	; 			pixels/2: as byte! (r and FF00h)
	; 			pixels/3: as byte! (r and FFh << 16)
	; 			pixels/4: as byte! (a << 24)
	; 			pixels: pixels + channel
	; 			cpt: cpt + 1
	; 		]
	; 	]
	; 	pixbuf
	; ]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb		[byte-ptr!]
		alpha	[byte-ptr!]
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
	][
		;; print ["make-image" lf]
		scan0: as int-ptr! allocate width * height * 4
		y: 0
		either null? color [
			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
					either null? rgb [r: 255 g: 255 b: 255][
						r: as-integer rgb/1
						g: as-integer rgb/2
						b: as-integer rgb/3
						rgb: rgb + 3
					]
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
			w	 [integer!]
			h	 [integer!]
			data [int-ptr!]
			end  [int-ptr!]
			clr  [integer!]
			img  [int-ptr!]
			node [img-node!]
	][
		node: as img-node! (as series! image/node/value) + 1
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		;data: CGDataProviderCreateWithData null node/buffer w * h * 4 0
		;clr: CGColorSpaceCreateDeviceRGB
		; need to change rgba en argb
		img: gdk_pixbuf_new 0 yes 8 w h;CGImageCreate w h 8 32 w * 4 clr 2004h data null true 0 ;-- kCGRenderingIntentDefault
		copy-memory  gdk_pixbuf_get_pixels img as byte-ptr! node/buffer w * h * 4
		;CGDataProviderRelease data
		;CGColorSpaceRelease clr
		img
	]

	to-pixbuf: func [
		img		[red-image!]
		return: [integer!]
		/local
			inode	[img-node!]
			pixbuf	[int-ptr!]
	][
		;; print ["to-pixbuf" lf]
		inode: as img-node! (as series! img/node/value) + 1
		if inode/flags and IMG_NODE_MODIFIED <> 0 [
			pixbuf: make-pixbuf img
			unless null? inode/handle [g_object_unref inode/handle]
			inode/handle: pixbuf
			inode/flags: IMG_NODE_HAS_BUFFER
		]
		as-integer inode/handle
	]

	; ; used in OS-image/do-draw -> to adapt to gdk
	; to-bitmap-ctx: func [
	; 	img		[integer!]
	; 	return: [int-ptr!]
	; 	/local
	; 		color-space [integer!]
	; 		width		[integer!]
	; 		height		[integer!]
	; 		;rect		[NSRect!]
	; 		ctx			[integer!]
	; ][
	; 	; color-space: CGColorSpaceCreateDeviceRGB
	; 	; width: CGImageGetWidth as int-ptr! img
	; 	; height: CGImageGetHeight as int-ptr! img

	; 	; rect: make-rect 0 0 width height
	; 	; ctx: CGBitmapContextCreate null width height 32 width * 16 color-space 2101h
	; 	; CGContextDrawImage ctx rect/x rect/y rect/w rect/h img
	; 	; CGColorSpaceRelease color-space
	; 	as int-ptr! 0;ctx
	; ]

	; ; used in OS-image/do-draw -> to adapt to gdk
	; ctx-to-image: func [
	; 	img		[red-image!]
	; 	ctx		[integer!]
	; 	/local
	; 		;data	[float32-ptr!]
	; 		buf		[int-ptr!]
	; 		inode	[img-node!]
	; ][
	; 	; inode: as img-node! (as series! img/node/value) + 1
	; 	; CGImageRelease as-integer inode/handle
	; 	; inode/handle: as int-ptr! CGBitmapContextCreateImage ctx
	; 	; if inode/flags <> 0 [
	; 	; 	data: as float32-ptr! CGBitmapContextGetData ctx
	; 	; 	unpremultiply-data inode/buffer data IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
	; 	; 	inode/flags: IMG_NODE_HAS_BUFFER
	; 	; ]
	; 	; CGContextRelease ctx
	; ]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
		/local
			type		[integer!]
			path		[integer!]
			dst			[integer!]
			img			[integer!]
	][
		print ["encode" lf]
		switch format [
			IMAGE_BMP  [probe "type: kUTTypeBMP"]
			IMAGE_PNG  [probe "type: kUTTypePNG"]
			IMAGE_GIF  [probe "type: kUTTypeGIF"]
			IMAGE_JPEG [probe "type: kUTTypeJPEG"]
			IMAGE_TIFF [probe "type: kUTTypeTIFF"]
			default    [probe "Cannot find image encoder" return null]
		]

		img: to-pixbuf image
		; switch TYPE_OF(slot) [
		; 	TYPE_URL
		; 	TYPE_FILE [
		; 		path: simple-io/to-NSURL as red-string! slot yes
		; 		dst: CGImageDestinationCreateWithURL path type 1 0
		; 		;if zero? dst []				;-- error
		; 		CGImageDestinationAddImage dst img 0
		; 		unless CGImageDestinationFinalize dst [
		; 			0 ;-- error
		; 		]
		; 		CFRelease path
		; 		CFRelease dst
		; 	]
		; 	default [0]
		; ]
		slot
	]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
		/local
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			offset	[integer!]
			handle	[integer!]
			width	[integer!]
			height	[integer!]
			bmp		[integer!]
			format	[integer!]
	][
		width: IMAGE_WIDTH(src/size)
		height: IMAGE_WIDTH(src/size)
		offset: src/head
		x: offset % width
		y: offset / width
		handle: as-integer src/node
		bmp: 0

		dst/header: TYPE_IMAGE
		dst/head: 0
		dst/node: as node! bmp
		dst
	]

]