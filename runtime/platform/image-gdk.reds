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
; bgra-to-rgba: func [
; 	color		[integer!]
; 	return: 	[integer!]
; 	/local
; 		r			[integer!]
; 		b			[integer!]
; 		g			[integer!]
; 		a			[integer!]
; ][
; 	b: (color >>> 24 and FFh) 
; 	g: (color >> 16 and FFh) 
; 	r: (color >> 8 and FFh) 
; 	a: (color  and FFh)
; 	;color: (r << 24 and FF000000h) or (g << 16  and 00FF0000h) or ( b << 8 and FF00h) or ( a and FFh)
; 	color: (r << 24) or (g << 16) or (b << 8) or a
; 	color
; ]

; bgra-to-argb: func [
; 	color		[integer!]
; 	return: 	[integer!]
; 	/local
; 		r			[integer!]
; 		b			[integer!]
; 		g			[integer!]
; 		a			[integer!]
; ][
; 	b: (color >>> 24 and FFh) 
; 	g: (color >> 16 and FFh) 
; 	r: (color >> 8 and FFh) 
; 	a: (color  and FFh)
; 	;color: (r << 24 and FF000000h) or (g << 16  and 00FF0000h) or ( b << 8 and FF00h) or ( a and FFh)
; 	color: (a << 24) or (r << 16) or (g << 8) or b
; 	color
; ]

; argb-to-rgba: func [
; 	color		[integer!]
; 	return: 	[integer!]
; 	/local
; 		r			[integer!]
; 		b			[integer!]
; 		g			[integer!]
; 		a			[integer!]
; ][
; 	a: (color >>> 24 and FFh) 
; 	r: (color >> 16 and FFh) 
; 	g: (color >> 8 and FFh) 
; 	b: (color  and FFh)
; 	color: (r << 24 and FF000000h) or (g << 16  and 00FF0000h) or ( b << 8 and FF00h) or ( a and FFh)
; 	color
; ]

argb-to-abgr: func [
	color		[integer!]
	return: 	[integer!]
	/local
		r			[integer!]
		b			[integer!]
		g			[integer!]
		a			[integer!]
][
	a: (color >>> 24 and FFh) 
	r: (color >> 16 and FFh) 
	g: (color >> 8 and FFh) 
	b: (color  and FFh)
	color: (a << 24 and FF000000h) or (b << 16  and 00FF0000h) or ( g << 8 and FF00h) or ( r and FFh)
	color
]

rgba-to-argb: func [
	color		[integer!]
	return: 	[integer!]
	/local
		r			[integer!]
		b			[integer!]
		g			[integer!]
		a			[integer!]
][
	r: (color >>> 24 and FFh) 
	g: (color >> 16 and FFh) 
	b: (color >> 8 and FFh) 
	a: (color  and FFh)
	color: (a << 24) or (r << 16) or (g << 8) or b
	color
]

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
			gdk_pixbuf_new_subpixbuf: "gdk_pixbuf_new_subpixbuf" [
				pixbuf 		[handle!]
				x 				[integer!]
				y 				[integer!]
				width 		[integer!]
				height 		[integer!]
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

	#enum post-transf! [POST-TRANSF-NONE POST-ARGB-TO-ABGR POST-ARGB-TO-RGBA]
	
	post-transf?: POST-TRANSF-NONE
	
	post-transf: func [ mode [post-transf!]][post-transf?: mode]
	
	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		;; DEBUG: print ["lock-bitmap " img lf]
		inode: as img-node! (as series! img/node/value) + 1
		;; DEBUG: print ["flags: " inode/flags lf]
		if zero? inode/flags [
			;; DEBUG: print ["lock-bitmap: flags" lf]
			inode/flags: IMG_NODE_HAS_BUFFER
			inode/buffer: OS-image/data-to-image inode/handle -1 yes yes
			;; DEBUG: print ["inode/buuufer " inode/buffer " handle " inode/handle lf]
		]
		if write? [inode/flags: inode/flags or IMG_NODE_MODIFIED]
		;; post-transf POST-TRANSF-NONE ; no post-transf to apply before 
		as integer! inode
	]

	unlock-bitmap: func [					;-- do nothing on GDK backend
		image		[red-image!]
		bitmap		[integer!]
		/local
			w	 	[integer!]
			h	 	[integer!]
			node	[img-node!]
	][
		unless post-transf? = POST-TRANSF-NONE [
			;; DEBUG: print ["unlock-bitmap" lf]
			w: IMAGE_WIDTH(image/size)
			h: IMAGE_HEIGHT(image/size)
			node: as img-node! bitmap
			case [
				post-transf? = POST-ARGB-TO-ABGR [buffer-argb-to-abgr node/buffer w h]
				;; post-transf? = POST-ARGB-TO-RGBA [buffer-argb-to-rgba node/buffer w h]
			]
		]
	]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			inode			[img-node!]
	][
		;; DEBUG: print ["OS-image/get-data" lf]
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
			node/buffer: data-to-image node/handle -1 yes yes
		]
		buf: node/buffer + index
		;; DEBUG: print ["get pixel " node/buffer " at " index " is " buf/value lf]
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
			node/buffer: data-to-image node/handle -1 yes yes
		]
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

	buffer-argb-to-abgr: func [
		buf 	[int-ptr!]
		width	[integer!]
		height	[integer!]
		return: [int-ptr!]	; not necessary since buf is already a pointer
		/local
			data-pixbuf 	[int-ptr!]
			end-data-pixbuf	[int-ptr!]
			pixel			[integer!]
			i 				[integer!]
	][
		data-pixbuf:  buf
		end-data-pixbuf: data-pixbuf + (width * height)
		;; DEBUG: print ["buffer-argb -> size: " width "x" height lf]
		while [data-pixbuf < end-data-pixbuf][
			pixel: data-pixbuf/value
			;; DEBUG: print ["pixel:" pixel lf]
			pixel: argb-to-abgr pixel
			data-pixbuf/value: pixel
			data-pixbuf: data-pixbuf + 1
		]
		buf
	]

	buffer-rgba-to-argb: func [
		buf 	[int-ptr!]
		width	[integer!]
		height	[integer!]
		return: [int-ptr!]	; not necessary since buf is already a pointer
		/local
			data-pixbuf 	[int-ptr!]
			end-data-pixbuf	[int-ptr!]
			pixel			[integer!]
			i 				[integer!]
	][
		data-pixbuf:  buf
		end-data-pixbuf: data-pixbuf + (width * height)
		;; DEBUG: print ["buffer-rgba-to-argb -> size: " width "x" height lf]
		while [data-pixbuf < end-data-pixbuf][
			pixel: data-pixbuf/value
			;; DEBUG: print ["pixel:" pixel lf]
			;pixel: (pixel >> 8) or (255 - (pixel >>> 24)) ; RGBA -> ARGB
			pixel: rgba-to-argb pixel
			data-pixbuf/value: pixel
			data-pixbuf: data-pixbuf + 1
		]
		buf
	]

	; buffer-bgra-to-argb: func [
	; 	buf 	[int-ptr!]
	; 	width	[integer!]
	; 	height	[integer!]
	; 	return: [int-ptr!]	; not necessary since buf is already a pointer
	; 	/local
	; 		data-pixbuf 	[int-ptr!]
	; 		end-data-pixbuf	[int-ptr!]
	; 		pixel			[integer!]
	; 		i 				[integer!]
	; ][
	; 	data-pixbuf:  buf
	; 	end-data-pixbuf: data-pixbuf + (width * height)
	; 	;; DEBUG: print ["buffer-argb -> size: " width "x" height lf]
	; 	while [data-pixbuf < end-data-pixbuf][
	; 		pixel: data-pixbuf/value
	; 		;; DEBUG: print ["pixel:" pixel lf]
	; 		pixel: bgra-to-argb pixel
	; 		data-pixbuf/value: pixel
	; 		data-pixbuf: data-pixbuf + 1
	; 	]
	; 	buf
	; ]

	; buffer-bgra-to-rgba: func [
	; 	buf 	[int-ptr!]
	; 	width	[integer!]
	; 	height	[integer!]
	; 	return: [int-ptr!]	; not necessary since buf is already a pointer
	; 	/local
	; 		data-pixbuf 	[int-ptr!]
	; 		end-data-pixbuf	[int-ptr!]
	; 		pixel			[integer!]
	; 		i 				[integer!]
	; ][
	; 	data-pixbuf:  buf
	; 	end-data-pixbuf: data-pixbuf + (width * height)
	; 	;; DEBUG: print ["buffer-argb -> size: " width "x" height lf]
	; 	while [data-pixbuf < end-data-pixbuf][
	; 		pixel: data-pixbuf/value
	; 		;; DEBUG: print ["pixel:" pixel lf]
	; 		pixel: bgra-to-rgba pixel
	; 		data-pixbuf/value: pixel
	; 		data-pixbuf: data-pixbuf + 1
	; 	]
	; 	buf
	; ]

		; buffer-argb-to-rgba: func [
	; 	buf 	[int-ptr!]
	; 	width	[integer!]
	; 	height	[integer!]
	; 	return: [int-ptr!]	; not necessary since buf is already a pointer
	; 	/local
	; 		data-pixbuf 	[int-ptr!]
	; 		end-data-pixbuf	[int-ptr!]
	; 		pixel			[integer!]
	; 		i 				[integer!]
	; ][
	; 	data-pixbuf:  buf
	; 	end-data-pixbuf: data-pixbuf + (width * height)
	; 	;; DEBUG: print ["buffer-argb -> size: " width "x" height lf]
	; 	while [data-pixbuf < end-data-pixbuf][
	; 		pixel: data-pixbuf/value
	; 		;; DEBUG: print ["pixel:" pixel lf]
	; 		pixel: argb-to-rgba pixel
	; 		data-pixbuf/value: pixel
	; 		data-pixbuf: data-pixbuf + 1
	; 	]
	; 	buf
	; ]

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
			i			[integer!]
			bytes-row	[integer!]
			; image-data	[integer!]
			pixbuf		[integer!]
			n			[integer!]
			channels	[integer!]
			alpha?		[logic!]
			buf			[byte-ptr!]
			buf-src		[byte-ptr!]
			loader 		[handle!]
	][
		;; DEBUG: print ["data-to-image data: " data " len: " len  " image?: " image? " edit?: " edit? lf]
		either image? [
			pixbuf: as-integer data
		][
			loader: gdk_pixbuf_loader_new
			gdk_pixbuf_loader_write loader data len null
			gdk_pixbuf_loader_close loader null
			pixbuf: as-integer gdk_pixbuf_loader_get_pixbuf loader
		]

		unless edit? [return as int-ptr! pixbuf]

		alpha?: alpha-channel? pixbuf
		;; DEBUG: print ["alpha?: " alpha? lf]
		; color-space:  ONLY RGB
		width: gdk_pixbuf_get_width as handle! pixbuf
		height: gdk_pixbuf_get_height as handle! pixbuf
		channels: gdk_pixbuf_get_n_channels as handle! pixbuf
		;; DEBUG: print ["size: " width "x" height " row-stride: " gdk_pixbuf_get_rowstride as handle! pixbuf " n_channels: " gdk_pixbuf_get_n_channels as handle! pixbuf " bits-per-sample: " gdk_pixbuf_get_bits_per_sample as handle! pixbuf " byte-length: " gdk_pixbuf_get_byte_length as handle! pixbuf lf]
		if width  * channels <> gdk_pixbuf_get_rowstride as handle! pixbuf  [print ["WARNING rowstride: " gdk_pixbuf_get_rowstride as handle! pixbuf " <> width (" width ") * channels (" channels "): " (width  * channels) lf]]
		; maybe better use other copy
		either channels = 4 [ 
			buf: gdk_pixbuf_get_pixels gdk_pixbuf_copy as handle! pixbuf
		][
			;; Needs to convert in n_channels = 4
			n: height * width * 4 
			buf: allocate n * 4 
			buf-src: gdk_pixbuf_read_pixels  as handle! pixbuf
			i: 1
			while [i <= n][
				either i % 4 = 0 [buf/i: as byte! 255][buf/i: buf-src/value buf-src: buf-src + 1]
				i: i + 1 
			]
		]
		buffer-argb-to-abgr as int-ptr! buf width height
		as int-ptr! buf
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
		/local
			h	[int-ptr!]
	][
		;; DEBUG: print ["load-binary" lf]

		h: data-to-image as int-ptr! data len no no
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
	]

	load-pixbuf: func [
		h		[int-ptr!]
		return:	[node!]
	][
		;; DEBUG: print ["load-pixbuf" lf]
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
		;as node! 0
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
		/local
			path 	[c-string!]
			pixbuf	[int-ptr!]
			h		[integer!]
			w		[integer!]
			buf 	[byte-ptr!]

	][
		path: file/to-OS-path src ; DOES NOT WORK as in macOS: simple-io/to-NSURL src yes
		;; DEBUG: print [ "load-image: " path lf]
		pixbuf: gdk_pixbuf_new_from_file path null
		w: gdk_pixbuf_get_width pixbuf h: gdk_pixbuf_get_height pixbuf
		;; DEBUG: print ["pixbuf: " pixbuf ", wxh: " w "x" h lf]
		;buf: gdk_pixbuf_get_pixels pixbuf
		;buffer-argb-to-abgr as int-ptr! buf w h
		make-node pixbuf null 0 w h
	]

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
		;; DEBUG: print ["make-image" lf]
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
					scan0/pos: b or (g << 8) or (r << 16) or (a << 24) ; In little endian mode: result is BGRA
					x: x + 1
				]
				y: y + 1
			]
		][
			r: color/array1 
			; RGBA array1 reversed with little endian 
			; => [R: r and FFh] [G: r >> 8 and FFh] [B: r >> 16 and FFh] [A: r >> 24  and FFh]
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >> 24  and FFh)]

			;;====== help for little-endian
			;; Ex -> img: make image! [1x1 1.2.3.4] ; == make image! [1x1 #{010203} #{04}]
			;; DEBUG: print ["r -> (1):" (r and FFh)  " g -> (2): " (r >> 8 and FFh) " b -> (3): " (r >> 16 and FFh) " a -> (255-4): " a lf]
			;; b: to-integer img/argb ;= 50463227
			;; print ["r -> (1):" (b and FFh)  " g -> (2): " (b >> 8 and FFh) " b -> (3): " (b >> 16 and FFh) " a -> (255-4): " b >>> 24 lf]
			;; => r -> (1):251 g -> (2): 1 b -> (3): 2 a -> (255-4): 3
			
			r: ((r and FFh) << 16) or ((r >> 8 and FFh) << 8) or (r >> 16 and FFh) or (a << 24) ; In little endian mode: RGBA -> BGRA
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
			w	 	[integer!]
			h	 	[integer!]
			data 	[int-ptr!]
			end  	[int-ptr!]
			clr  	[integer!]
			pixbuf  [int-ptr!]
			buf		[byte-ptr!]
			node 	[img-node!]
	][
		node: as img-node! (as series! image/node/value) + 1
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		pixbuf: gdk_pixbuf_new 0 yes 8 w h;CGImageCreate w h 8 32 w * 4 clr 2004h data null true 0 ;-- kCGRenderingIntentDefault
		copy-memory gdk_pixbuf_get_pixels pixbuf as byte-ptr! node/buffer w * h * 4
		buf: gdk_pixbuf_get_pixels pixbuf
		buffer-argb-to-abgr as int-ptr! buf w h
		;; DEBUG: print ["make-pixbuf " img lf]
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
		;; DEBUG: print ["OS-image/to-pixbuf" lf]
		inode: as img-node! (as series! img/node/value) + 1
		if inode/flags and IMG_NODE_MODIFIED <> 0 [
			;; DEBUG: print ["IMG_NODE_MODIFIED " img lf]
			pixbuf: make-pixbuf img
			unless null? inode/handle [g_object_unref inode/handle]
			inode/handle: pixbuf
			inode/flags: IMG_NODE_MODIFIED
		]
		inode/handle
	]

	;; Better to not use!
	to-argb-pixbuf: func [
		image	[red-image!]
		return: [int-ptr!]
		/local
			w	 	[integer!]
			h	 	[integer!]
			bitmap	[integer!]
			data	[int-ptr!]
			stride	[integer!]
			pixbuf	[int-ptr!]
			buf		[byte-ptr!]
	][
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		stride: 0
		bitmap: OS-image/lock-bitmap image yes
		data: OS-image/get-data bitmap :stride
		pixbuf: gdk_pixbuf_new GDK_COLORSPACE_RGB yes 8 w h
		copy-memory gdk_pixbuf_get_pixels pixbuf as byte-ptr! data w * h * 4
		OS-image/unlock-bitmap image bitmap
		buf: gdk_pixbuf_get_pixels pixbuf
		buffer-argb-to-abgr as int-ptr! buf w h
		pixbuf
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
	][
		err: declare GError!
		switch format [
			IMAGE_BMP  [type: "bmp"]
			IMAGE_PNG  [type: "png"]
			;IMAGE_GIF  [type: "gif"]
			IMAGE_JPEG [type: "jpeg"]
			IMAGE_TIFF [type: "tiff"]
			default    [probe "Cannot find image encoder" return null]
		]

		;; DEBUG: print ["encode: " type lf]
		pixbuf: to-pixbuf image
		switch TYPE_OF(slot) [
			TYPE_URL
			TYPE_FILE [
				path: file/to-OS-path as red-string! slot
				gdk_pixbuf_save [pixbuf path type err null]
			]
			default [0]
		]
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
			inode	[img-node!]
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			offset	[integer!]
			handle	[handle!]
			handle2	[handle!]
			width	[integer!]
			height	[integer!]
			bmp		[integer!]
			format	[integer!]
			src-buf	[byte-ptr!]
			dst-buf	[byte-ptr!]
			buf		[int-ptr!]
	][
		;; DEBUG: print ["image/clone " src " part? " part? lf]
		inode: as img-node! (as series! src/node/value) + 1
		handle: inode/handle
		src-buf: as byte-ptr! inode/buffer
		width: IMAGE_WIDTH(inode/size)
		height: IMAGE_HEIGHT(inode/size)
		offset: src/head
		x: offset % width
		y: offset / width

		;; DEBUG: print ["handle: " handle " src-buf: " src-buf " offset: " x "x" y " size " width "x" height lf]

		dst/node: make-node handle null 0 width height
		inode: as img-node! (as series! dst/node/value) + 1

		either all [zero? offset not part?][
			either null? handle [
				unless null? src-buf [ 
					;; INFO: src-inode/handle null but not src-inode/buffer
					dst-buf: allocate width * height * 4
					copy-memory dst-buf src-buf width * height * 4 0
					;; DEBUG: print ["src-buf " dst-buf " " width "x" height  lf]
					inode/buffer: as int-ptr! dst-buf
					inode/flags: IMG_NODE_MODIFIED or IMG_NODE_HAS_BUFFER
					inode/size: height << 16 or width
					dst/size: inode/size
				]
			][
				;; INFO: src-inode/handle not null?
				inode/handle: gdk_pixbuf_copy handle
				dst/size: src/size
			]
		][
			either all [part? TYPE_OF(size) = TYPE_PAIR][
				w: width - x
				h: height - y
				if size/x < w [w: size/x]
				if size/y < h [h: size/y]
				handle2: gdk_pixbuf_copy gdk_pixbuf_new_subpixbuf handle x y w h
				buf: as int-ptr! allocate w * h * 4
				pixbuf-to-data handle2 buf w h
				g_object_unref handle2
				inode/flags: IMG_NODE_MODIFIED or IMG_NODE_HAS_BUFFER
				inode/buffer: buf
			][
				;; TODO: This part is considered not enough stable!!!!
				;; DEBUG: print ["part: " part " size " w "x" h lf]
				either part < width [h: 1 w: part][
					h: part / width
					w: width
				]
				if zero? part [w: 1 h: 1]
				either zero? part [w: 0 h: 0][
					inode/flags: IMG_NODE_MODIFIED or IMG_NODE_HAS_BUFFER
					src-buf: as byte-ptr! data-to-image handle -1 yes yes
					dst-buf: allocate w * h * 4
					copy-memory dst-buf src-buf w * h * 4 offset * 4
					inode/handle: null
					inode/buffer: as int-ptr! dst-buf
				]
			]
			inode/size: h << 16 or w
			dst/size: inode/size
			;; DEBUG: print ["dst/size " w "x" h lf]
		]
		dst/head: 0
		dst/header: TYPE_IMAGE
		;; DEBUG: print ["dst " dst lf]
		dst
	]

	;; pixbuf utils (since rowstride is not necessary width * channels for a pixbuf)
	pixbuf-read-pixel: func [
		pixbuf 		[handle!]
		x 			[integer!]; 1-based
		y 			[integer!]; 1-based
		return: 	[int-ptr!]
	][
		as int-ptr! (gdk_pixbuf_get_pixels pixbuf) + ((y - 1) * (gdk_pixbuf_get_rowstride pixbuf) + (x - 1) * (gdk_pixbuf_get_n_channels pixbuf))
	]

	pixbuf-to-data: func [
		src-pixbuf 	[handle!]
		dst-data	[int-ptr!]
		width		[integer!]
		height		[integer!]
		/local
			x 			[integer!]
			y 			[integer!]
			pixels		[byte-ptr!]
			pixel		[byte-ptr!]
			stride		[integer!]
			channels	[integer!]
			src-buf		[int-ptr!]
			dst-buf		[int-ptr!]

	][
		pixels: gdk_pixbuf_get_pixels src-pixbuf  
		stride: (gdk_pixbuf_get_rowstride src-pixbuf)
		channels: gdk_pixbuf_get_n_channels src-pixbuf
		if channels <> 4 [print ["ERROR: number of channels is 3 and not 4 ..." lf]]
		dst-buf: dst-data
		y: 0
		while [y < height][
			x: 0
			pixel: pixels + (y * stride)
			while [x < width][
				;; DEBUG: print ["pixbuf-to-data: " x "x" y " size: " width "x" height lf]
				;; BE CAREFUL with rowstride for pixbuf
				src-buf: as int-ptr! pixel
				dst-buf/value: argb-to-abgr src-buf/value
				dst-buf: dst-buf + 1
				pixel: pixel + channels
				x: x + 1
			]
			y: y + 1
		]
	]
]


