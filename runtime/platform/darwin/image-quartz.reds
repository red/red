Red/System [
	Title:   "Image routine functions using Quartz"
	Author:  "Qingtian Xie"
	File: 	 %image-quartz.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
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

	NSRect!: alias struct! [
		x		[float32!]
		y		[float32!]
		w		[float32!]
		h		[float32!]
	]

	#import [
		"/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices" cdecl [
			CGImageDestinationCreateWithURL: "CGImageDestinationCreateWithURL" [
				url			[integer!]
				type		[integer!]
				count		[integer!]
				options		[integer!]
				return:		[integer!]
			]
			CGImageDestinationAddImage: "CGImageDestinationAddImage" [
				dst			[integer!]
				image		[integer!]
				properties	[integer!]
			]
			CGImageDestinationFinalize: "CGImageDestinationFinalize" [
				dst			[integer!]
				return:		[logic!]
			]
			CGImageSourceCreateWithURL: "CGImageSourceCreateWithURL" [
				url			[integer!]
				options		[integer!]
				return:		[integer!]
			]
			CGColorSpaceCreateDeviceRGB: "CGColorSpaceCreateDeviceRGB" [
				return:		[integer!]
			]
			CGColorSpaceRelease: "CGColorSpaceRelease" [
				color-space [integer!]
			]
			CGBitmapContextCreateImage: "CGBitmapContextCreateImage" [
				ctx			[integer!]
				return:		[integer!]
			]
			CGBitmapContextCreate: "CGBitmapContextCreate" [
				buffer		[byte-ptr!]
				width		[integer!]
				height		[integer!]
				bits		[integer!]
				bytes-row	[integer!]
				color-space [integer!]
				bmp-info	[integer!]
				return:		[integer!]
			]
			CGBitmapContextGetWidth: "CGBitmapContextGetWidth" [
				ctx			[integer!]
				return:		[integer!]
			]
			CGBitmapContextGetHeight: "CGBitmapContextGetHeight" [
				ctx			[integer!]
				return:		[integer!]
			]
			CGBitmapContextGetData: "CGBitmapContextGetData" [
				ctx			[integer!]
				return:		[byte-ptr!]
			]
			CGContextRelease: "CGContextRelease" [
				ctx			[integer!]
			]
			CGContextDrawImage: "CGContextDrawImage" [
				ctx			[integer!]
				x			[float32!]
				y			[float32!]
				w			[float32!]
				h			[float32!]
				src			[integer!]
			]
			CGContextScaleCTM: "CGContextScaleCTM" [
				c			[integer!]
				sx			[float32!]
				sy			[float32!]
			]
			CGImageSourceCreateWithData: "CGImageSourceCreateWithData" [
				data		[int-ptr!]
				options		[integer!]
				return:		[integer!]
			]
			CGImageSourceCreateImageAtIndex: "CGImageSourceCreateImageAtIndex" [
				src			[integer!]
				index		[integer!]
				options		[integer!]
				return:		[integer!]
			]
			CGImageGetWidth: "CGImageGetWidth" [
				image		[int-ptr!]
				return:		[integer!]
			]
			CGImageGetHeight: "CGImageGetHeight" [
				image		[int-ptr!]
				return:		[integer!]
			]
			CGImageGetAlphaInfo: "CGImageGetAlphaInfo" [
				image		[integer!]
				return:		[integer!]
			]
			CGImageRelease: "CGImageRelease" [
				image		[integer!]
			]
			CGImageCreate: "CGImageCreate" [
				width		[integer!]
				height		[integer!]
				bits-part	[integer!]
				bits-pixel	[integer!]
				bytes-row	[integer!]
				color-space [integer!]
				bmp-info	[integer!]
				provider	[integer!]
				decode		[float32-ptr!]
				interpolate [logic!]
				intent		[integer!]
				return:		[integer!]
			]
			CGImageCreateCopy: "CGImageCreateCopy" [
				image		[int-ptr!]
				return:		[int-ptr!]
			]
			CGImageCreateWithImageInRect: "CGImageCreateWithImageInRect" [
				image		[int-ptr!]
				x			[float32!]
				y			[float32!]
				w			[float32!]
				h			[float32!]
				return:		[int-ptr!]
			]
			CGDataProviderCreateWithData: "CGDataProviderCreateWithData" [
				info		[int-ptr!]
				data		[int-ptr!]
				size		[integer!]
				releaseData [integer!]
				return:		[integer!]
			]
			CGDataProviderRelease: "CGDataProviderRelease" [
				provider	[integer!]
			]
		]
		"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
			CFDataCreate: "CFDataCreate" [
				allocator	[integer!]
				data		[byte-ptr!]
				length		[integer!]
				return:		[integer!]
			]
			CFDataCreateWithBytesNoCopy: "CFDataCreateWithBytesNoCopy" [
				allocator	[integer!]
				bytes		[byte-ptr!]
				length		[integer!]
				deallocator [integer!]
				return:		[integer!]
			]
			CFRelease: "CFRelease" [
				cf			[integer!]
			]
			kCFAllocatorNull: "kCFAllocatorNull" [integer!]
		]
		"/System/Library/Frameworks/CoreServices.framework/CoreServices" cdecl [
			kUTTypeJPEG: "kUTTypeJPEG" [integer!]
			kUTTypeTIFF: "kUTTypeTIFF" [integer!]
			kUTTypeGIF: "kUTTypeGIF" [integer!]
			kUTTypePNG: "kUTTypePNG" [integer!]
			kUTTypeBMP: "kUTTypeBMP" [integer!]
		]
	]

	make-rect: func [
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		return: [NSRect!]
		/local
			r	[NSRect!]
	][
		r: declare NSRect!
		r/x: as float32! x
		r/y: as float32! y
		r/w: as float32! w
		r/h: as float32! h
		r
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
			inode/buffer: data-to-image inode/handle yes yes
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
		if zero? node/flags [
			node/flags: IMG_NODE_HAS_BUFFER
			node/buffer: data-to-image node/handle yes yes
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
			node/buffer: data-to-image node/handle yes yes
		]
		node/flags: node/flags or IMG_NODE_MODIFIED
		buf: node/buffer + index
		buf/value: color
		color
	]

	delete: func [img [red-image!] /local inode [img-node!]][
		inode: as img-node! (as series! img/node/value) + 1
		if inode/handle <> null [CGImageRelease as-integer inode/handle]
		if inode/buffer <> null [free as byte-ptr! inode/buffer]
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
		/local
			old-w		[integer!]
			old-h		[integer!]
			handle		[integer!]
			rect		[NSRect!]
			color-space [integer!]
			ctx			[integer!]
			nhandle		[integer!]
	][
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		handle: to-cgimage img

		rect: make-rect 0 0 width height
		color-space: CGColorSpaceCreateDeviceRGB
		ctx: CGBitmapContextCreate null width height 32 width * 16 color-space 2101h
		CGContextScaleCTM ctx as float32! 1.0 as float32! 1.0
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h handle
		nhandle: CGBitmapContextCreateImage ctx
		CGColorSpaceRelease color-space
		CGContextRelease ctx

		as integer! make-node as int-ptr! nhandle null 0 width height
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
		image	[integer!]
		return:	[logic!]
		/local
			info [integer!]
	][
		info: CGImageGetAlphaInfo image
		all [info > 0 info < 5]
	]

	unpremultiply-data: func [
		buf			[int-ptr!]
		data		[float32-ptr!]			;-- pre-multiplied RGBA 128bit float32
		num			[integer!]				;-- number of pixel
		return:		[int-ptr!]
		/local
			p		[int-ptr!]
			clr		[integer!]
			r		[float32!]
			g		[float32!]
			b		[float32!]
			a		[float32!]
			rr		[integer!]
			gg		[integer!]
			bb		[integer!]
			aa		[integer!]
	][
		if null? buf [buf: as int-ptr! allocate num * 4]
		p: buf
		loop num [
			r: data/1
			g: data/2
			b: data/3
			a: data/4
			if all [
				a <> as float32! 0.0
				a <> as float32! 1.0
			][
				r: r / a
				g: g / a
				b: b / a
			]
			aa: (as-integer (a * as float32! 255.0)) << 24
			rr: (as-integer (r * as float32! 255.0)) << 16
			gg: (as-integer (g * as float32! 255.0)) << 8
			bb: as-integer (b * as float32! 255.0)
			p/value: aa or rr or gg or bb
			p: p + 1
			data: data + 4
		]
		buf
	]

	data-to-image: func [				;-- convert CGImage or NSData to OS handle or internal buffer
		data		[int-ptr!]
		cgimage?	[logic!]
		edit?		[logic!]
		return: 	[int-ptr!]
		/local
			color-space [integer!]
			width		[integer!]
			height		[integer!]
			ctx			[integer!]
			rect		[NSRect!]
			bytes-row	[integer!]
			image-data	[integer!]
			image		[integer!]
			n			[integer!]
			info		[integer!]
			alpha?		[logic!]
			buf			[byte-ptr!]
			p			[byte-ptr!]
	][
		either cgimage? [
			image: as-integer data
		][
			image-data: CGImageSourceCreateWithData data 0
			image: CGImageSourceCreateImageAtIndex image-data 0 0
		]

		unless edit? [return as int-ptr! image]

		alpha?: alpha-channel? image
		color-space: CGColorSpaceCreateDeviceRGB
		width: CGImageGetWidth as int-ptr! image
		height: CGImageGetHeight as int-ptr! image

		bytes-row: width * 4
		either alpha? [
			info: 2101h		;-- kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents
			n: 4
		][
			info: 8198		;-- kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little
			n: 1
		]

		rect: make-rect 0 0 width height
		buf: allocate height * bytes-row * n
		ctx: CGBitmapContextCreate buf width height 8 * n bytes-row * n color-space info
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h image

		if alpha? [
			p: buf
			buf: as byte-ptr! unpremultiply-data null as float32-ptr! buf width * height
			free p
		]

		CGColorSpaceRelease color-space
		unless cgimage? [
			CGImageRelease image
			CFRelease image-data
		]
		CGContextRelease ctx
		as int-ptr! buf
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
		/local
			h	[int-ptr!]
	][
		h: data-to-image as int-ptr! CFDataCreateWithBytesNoCopy 0 data len kCFAllocatorNull no no
		make-node h null 0 CGImageGetWidth h CGImageGetHeight h
	]

	load-nsdata: func [
		data	[int-ptr!]
		return: [node!]
		/local
			h	[int-ptr!]
	][
		h: data-to-image data no no
		make-node h null 0 CGImageGetWidth h CGImageGetHeight h
	]

	load-cgimage: func [
		h		[int-ptr!]
		return:	[node!]
	][
		make-node h null 0 CGImageGetWidth h CGImageGetHeight h
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
		/local
			img-data [integer!]
			path	 [integer!]
			h		 [int-ptr!]
	][
		path: simple-io/to-NSURL src yes
		img-data: CGImageSourceCreateWithURL path 0
		CFRelease path
		if zero? img-data [return null]
		h: as int-ptr! CGImageSourceCreateImageAtIndex img-data 0 0
		CFRelease img-data
		either null? h [null][
			make-node h null 0 CGImageGetWidth h CGImageGetHeight h
		]
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
			rgb			[byte-ptr!]
			alpha		[byte-ptr!]
			len			[integer!]
			len2		[integer!]
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

	make-cgimage: func [
		image	[red-image!]
		return: [int-ptr!]
		/local
			w	 [integer!]
			h	 [integer!]
			data [integer!]
			clr  [integer!]
			img  [integer!]
			node [img-node!]
	][
		node: as img-node! (as series! image/node/value) + 1
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		data: CGDataProviderCreateWithData null node/buffer w * h * 4 0
		clr: CGColorSpaceCreateDeviceRGB
		img: CGImageCreate w h 8 32 w * 4 clr 2004h data null true 0 ;-- kCGRenderingIntentDefault
		CGDataProviderRelease data
		CGColorSpaceRelease clr
		as int-ptr! img
	]

	to-cgimage: func [
		img		[red-image!]
		return: [integer!]
		/local
			inode	[img-node!]
			cgimage [int-ptr!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		if inode/flags and IMG_NODE_MODIFIED <> 0 [
			cgimage: make-cgimage img
			if inode/handle <> null [CGImageRelease as-integer inode/handle]
			inode/handle: cgimage
			inode/flags: IMG_NODE_HAS_BUFFER
		]
		as-integer inode/handle
	]

	to-bitmap-ctx: func [
		img		[integer!]
		return: [int-ptr!]
		/local
			color-space [integer!]
			width		[integer!]
			height		[integer!]
			rect		[NSRect!]
			ctx			[integer!]
	][
		color-space: CGColorSpaceCreateDeviceRGB
		width: CGImageGetWidth as int-ptr! img
		height: CGImageGetHeight as int-ptr! img

		rect: make-rect 0 0 width height
		ctx: CGBitmapContextCreate null width height 32 width * 16 color-space 2101h
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h img
		CGColorSpaceRelease color-space
		as int-ptr! ctx
	]

	ctx-to-image: func [
		img		[red-image!]
		ctx		[integer!]
		/local
			data	[float32-ptr!]
			buf		[int-ptr!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		CGImageRelease as-integer inode/handle
		inode/handle: as int-ptr! CGBitmapContextCreateImage ctx
		if inode/flags <> 0 [
			data: as float32-ptr! CGBitmapContextGetData ctx
			unpremultiply-data inode/buffer data IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
			inode/flags: IMG_NODE_HAS_BUFFER
		]
		CGContextRelease ctx
	]

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
		switch format [
			IMAGE_BMP  [type: kUTTypeBMP]
			IMAGE_PNG  [type: kUTTypePNG]
			IMAGE_GIF  [type: kUTTypeGIF]
			IMAGE_JPEG [type: kUTTypeJPEG]
			IMAGE_TIFF [type: kUTTypeTIFF]
			default    [probe "Cannot find image encoder" return null]
		]

		img: to-cgimage image
		switch TYPE_OF(slot) [
			TYPE_URL
			TYPE_FILE [
				path: simple-io/to-NSURL as red-string! slot yes
				dst: CGImageDestinationCreateWithURL path type 1 0
				;if zero? dst []				;-- error
				CGImageDestinationAddImage dst img 0
				unless CGImageDestinationFinalize dst [
					0 ;-- error
				]
				CFRelease path
				CFRelease dst
			]
			default [0]
		]
		slot
	]

	combine-image: func [
		img1	[integer!]
		img2	[integer!]
		mode	[integer!]		;-- TBD, default w = max (w1 w2), h = h1 + h2
		return:	[integer!]
		/local
			w1		[integer!]
			h1		[integer!]
			w2		[integer!]
			h2		[integer!]
			w		[integer!]
			h		[integer!]
			cs		[integer!]
			rect	[NSRect!]
			ctx		[integer!]
			handle	[integer!]
	][
		w1: CGImageGetWidth as int-ptr! img1
		h1: CGImageGetHeight as int-ptr! img1
		w2: CGImageGetWidth as int-ptr! img2
		h2: CGImageGetHeight as int-ptr! img2

		w: w1
		if w1 < w2 [w: w2]
		h: h1 + h2
		cs: CGColorSpaceCreateDeviceRGB
		ctx: CGBitmapContextCreate null w h 32 w * 16 cs 2101h
		rect: make-rect 0 h2 w1 h1
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h img1
		rect: make-rect 0 0 w2 h2
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h img2
		CGColorSpaceRelease cs
		handle: CGBitmapContextCreateImage ctx
		CGContextRelease ctx
		handle
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
				handle: CGImageCreateCopy handle0
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
			handle: CGImageCreateWithImageInRect
				handle0 as float32! x as float32! y as float32! w as float32! h
			dst/node: make-node handle null 0 w h
		]
		dst/size: h << 16 or w
		dst/header: TYPE_IMAGE
		dst/head: 0
		dst
	]
]
