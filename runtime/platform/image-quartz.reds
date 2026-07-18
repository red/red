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

#either ABI = 'apple-aarch64 [
	#define CGFloat! float!
][
	#define CGFloat! float32!
]

OS-image: context [

	img-node!: alias struct! [
		flags	[integer!]	;-- bit 0: if set, has buffer | bit 1: if set, buffer has been modified
		handle	[int-ptr!]
		buffer	[int-ptr!]
		size	[integer!]
		extID	[integer!]								;-- external resources table ID
	]

	NSRect!: alias struct! [
		x		[CGFloat!]
		y		[CGFloat!]
		w		[CGFloat!]
		h		[CGFloat!]
	]

	#import [
		"/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices" cdecl [
			CGImageDestinationCreateWithURL: "CGImageDestinationCreateWithURL" [
				url			[int-ptr!]
				type		[int-ptr!]
				count		[integer!]
				options		[int-ptr!]
				return:		[int-ptr!]
			]
			CGImageDestinationAddImage: "CGImageDestinationAddImage" [
				dst			[int-ptr!]
				image		[int-ptr!]
				properties	[int-ptr!]
			]
			CGImageDestinationFinalize: "CGImageDestinationFinalize" [
				dst			[int-ptr!]
				return:		[logic!]
			]
			CGImageSourceCreateWithURL: "CGImageSourceCreateWithURL" [
				url			[int-ptr!]
				options		[int-ptr!]
				return:		[int-ptr!]
			]
			CGColorSpaceCreateDeviceRGB: "CGColorSpaceCreateDeviceRGB" [
				return:		[int-ptr!]
			]
			CGColorSpaceRelease: "CGColorSpaceRelease" [
				color-space [int-ptr!]
			]
			CGBitmapContextCreateImage: "CGBitmapContextCreateImage" [
				ctx			[int-ptr!]
				return:		[int-ptr!]
			]
			CGBitmapContextCreate: "CGBitmapContextCreate" [
				buffer		[byte-ptr!]
				width		[integer!]
				height		[integer!]
				bits		[integer!]
				bytes-row	[integer!]
				color-space [int-ptr!]
				bmp-info	[integer!]
				return:		[int-ptr!]
			]
			CGBitmapContextGetWidth: "CGBitmapContextGetWidth" [
				ctx			[int-ptr!]
				return:		[integer!]
			]
			CGBitmapContextGetHeight: "CGBitmapContextGetHeight" [
				ctx			[int-ptr!]
				return:		[integer!]
			]
			CGBitmapContextGetData: "CGBitmapContextGetData" [
				ctx			[int-ptr!]
				return:		[byte-ptr!]
			]
			CGContextRelease: "CGContextRelease" [
				ctx			[int-ptr!]
			]
			CGContextDrawImage: "CGContextDrawImage" [
				ctx			[int-ptr!]
				x			[CGFloat!]
				y			[CGFloat!]
				w			[CGFloat!]
				h			[CGFloat!]
				src			[int-ptr!]
			]
			CGContextScaleCTM: "CGContextScaleCTM" [
				c			[int-ptr!]
				sx			[CGFloat!]
				sy			[CGFloat!]
			]
			CGImageSourceCreateWithData: "CGImageSourceCreateWithData" [
				data		[int-ptr!]
				options		[int-ptr!]
				return:		[int-ptr!]
			]
			CGImageSourceCreateImageAtIndex: "CGImageSourceCreateImageAtIndex" [
				src			[int-ptr!]
				index		[integer!]
				options		[int-ptr!]
				return:		[int-ptr!]
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
				image		[int-ptr!]
				return:		[integer!]
			]
			CGImageRelease: "CGImageRelease" [
				image		[int-ptr!]
			]
			CGImageCreate: "CGImageCreate" [
				width		[integer!]
				height		[integer!]
				bits-part	[integer!]
				bits-pixel	[integer!]
				bytes-row	[integer!]
				color-space [int-ptr!]
				bmp-info	[integer!]
				provider	[int-ptr!]
				decode		[float32-ptr!]
				interpolate [logic!]
				intent		[integer!]
				return:		[int-ptr!]
			]
			CGImageCreateCopy: "CGImageCreateCopy" [
				image		[int-ptr!]
				return:		[int-ptr!]
			]
			CGImageCreateWithImageInRect: "CGImageCreateWithImageInRect" [
				image		[int-ptr!]
				x			[CGFloat!]
				y			[CGFloat!]
				w			[CGFloat!]
				h			[CGFloat!]
				return:		[int-ptr!]
			]
			CGDataProviderCreateWithData: "CGDataProviderCreateWithData" [
				info		[int-ptr!]
				data		[int-ptr!]
				size		[integer!]
				releaseData [int-ptr!]
				return:		[int-ptr!]
			]
			CGDataProviderRelease: "CGDataProviderRelease" [
				provider	[int-ptr!]
			]
		]
		"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
			CFDataCreate: "CFDataCreate" [
				allocator	[int-ptr!]
				data		[byte-ptr!]
				length		[integer!]
				return:		[int-ptr!]
			]
			CFDataCreateWithBytesNoCopy: "CFDataCreateWithBytesNoCopy" [
				allocator	[int-ptr!]
				bytes		[byte-ptr!]
				length		[integer!]
				deallocator [int-ptr!]
				return:		[int-ptr!]
			]
			CFRelease: "CFRelease" [
				cf			[int-ptr!]
			]
			kCFAllocatorNull: "kCFAllocatorNull" [int-ptr!]
		]
		"/System/Library/Frameworks/CoreServices.framework/CoreServices" cdecl [
			kUTTypeJPEG: "kUTTypeJPEG" [int-ptr!]
			kUTTypeTIFF: "kUTTypeTIFF" [int-ptr!]
			kUTTypeGIF: "kUTTypeGIF" [int-ptr!]
			kUTTypePNG: "kUTTypePNG" [int-ptr!]
			kUTTypeBMP: "kUTTypeBMP" [int-ptr!]
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
		r/x: as CGFloat! x
		r/y: as CGFloat! y
		r/w: as CGFloat! w
		r/h: as CGFloat! h
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
		return:		[int-ptr!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (resolve-series img/node) + 1
		if zero? inode/flags [
			inode/flags: IMG_NODE_HAS_BUFFER
			inode/buffer: data-to-image inode/handle yes yes
		]
		if write? [inode/flags: inode/flags or IMG_NODE_MODIFIED]
		as int-ptr! inode
	]

	unlock-bitmap: func [					;-- do nothing on Quartz backend
		img			[red-image!]
		data		[int-ptr!]
	][]

	get-data: func [
		handle		[int-ptr!]
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
	
	mark: func [node [node!] /local inode [img-node!]][
		inode: as img-node! (as series! node/value) + 1
		externals/mark inode/extID
	]
	
	delete: func [node [node!] /local inode [img-node!]][
		inode: as img-node! (as series! node/value) + 1
		if inode/handle <> null [
			CGImageRelease inode/handle
			inode/handle: null
		]
		if inode/buffer <> null [
			free as byte-ptr! inode/buffer
			inode/buffer: null
		]
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [node!]
		/local
			old-w		[integer!]
			old-h		[integer!]
			handle		[int-ptr!]
			rect		[NSRect!]
			color-space [int-ptr!]
			ctx			[int-ptr!]
			nhandle		[int-ptr!]
	][
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		handle: to-cgimage img

		rect: make-rect 0 0 width height
		color-space: CGColorSpaceCreateDeviceRGB
		ctx: CGBitmapContextCreate null width height 32 width * 16 color-space 2101h
		CGContextScaleCTM ctx as CGFloat! 1.0 as CGFloat! 1.0
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h handle
		nhandle: CGBitmapContextCreateImage ctx
		CGColorSpaceRelease color-space
		CGContextRelease ctx

		make-node nhandle null 0 width height
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
			stable	[node-handle!]
	][
		node: alloc-bytes size? img-node!
		inode: as img-node! (as series! node/value) + 1
		inode/flags: flags
		inode/handle: handle
		inode/buffer: buffer
		inode/size: height << 16 or width
		stable: node-handle-of node
		inode/extID: externals/store-node stable image/ext-type
		node
	]

	alpha-channel?: func [
		image	[int-ptr!]
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
			color-space [int-ptr!]
			width		[integer!]
			height		[integer!]
			ctx			[int-ptr!]
			rect		[NSRect!]
			bytes-row	[integer!]
			image-data	[int-ptr!]
			image		[int-ptr!]
			n			[integer!]
			info		[integer!]
			alpha?		[logic!]
			buf			[byte-ptr!]
			p			[byte-ptr!]
	][
		either cgimage? [
			image: data
		][
			image-data: CGImageSourceCreateWithData data null
			image: CGImageSourceCreateImageAtIndex image-data 0 null
		]

		unless edit? [return image]

		alpha?: alpha-channel? image
		color-space: CGColorSpaceCreateDeviceRGB
		width: CGImageGetWidth image
		height: CGImageGetHeight image

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
		h: data-to-image CFDataCreateWithBytesNoCopy null data len kCFAllocatorNull no no
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
			img-data [int-ptr!]
			path	 [int-ptr!]
			h		 [int-ptr!]
	][
		path: simple-io/to-NSURL src yes
		img-data: CGImageSourceCreateWithURL path null
		CFRelease path
		if null? img-data [return null]
		h: CGImageSourceCreateImageAtIndex img-data 0 null
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
			data [int-ptr!]
			clr  [int-ptr!]
			img  [int-ptr!]
			node [img-node!]
	][
		node: as img-node! (resolve-series image/node) + 1
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		data: CGDataProviderCreateWithData null node/buffer w * h * 4 null
		clr: CGColorSpaceCreateDeviceRGB
		img: CGImageCreate w h 8 32 w * 4 clr 2004h data null true 0 ;-- kCGRenderingIntentDefault
		CGDataProviderRelease data
		CGColorSpaceRelease clr
		img
	]

	to-cgimage: func [
		img		[red-image!]
		return: [int-ptr!]
		/local
			inode	[img-node!]
			cgimage [int-ptr!]
	][
		inode: as img-node! (resolve-series img/node) + 1
		if inode/flags and IMG_NODE_MODIFIED <> 0 [
			cgimage: make-cgimage img
			if inode/handle <> null [CGImageRelease inode/handle]
			inode/handle: cgimage
			inode/flags: IMG_NODE_HAS_BUFFER
		]
		inode/handle
	]

	to-bitmap-ctx: func [
		img		[int-ptr!]
		return: [int-ptr!]
		/local
			color-space [int-ptr!]
			width		[integer!]
			height		[integer!]
			rect		[NSRect!]
			ctx			[int-ptr!]
	][
		color-space: CGColorSpaceCreateDeviceRGB
		width: CGImageGetWidth img
		height: CGImageGetHeight img

		rect: make-rect 0 0 width height
		ctx: CGBitmapContextCreate null width height 32 width * 16 color-space 2101h
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h img
		CGColorSpaceRelease color-space
		ctx
	]

	ctx-to-image: func [
		img		[red-image!]
		ctx		[int-ptr!]
		/local
			data	[float32-ptr!]
			buf		[int-ptr!]
			inode	[img-node!]
	][
		inode: as img-node! (resolve-series img/node) + 1
		CGImageRelease inode/handle
		inode/handle: CGBitmapContextCreateImage ctx
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
			type		[int-ptr!]
			path		[int-ptr!]
			dst			[int-ptr!]
			img			[int-ptr!]
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
				dst: CGImageDestinationCreateWithURL path type 1 null
				;if zero? dst []				;-- error
				CGImageDestinationAddImage dst img null
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
		img1	[int-ptr!]
		img2	[int-ptr!]
		mode	[integer!]		;-- TBD, default w = max (w1 w2), h = h1 + h2
		return:	[int-ptr!]
		/local
			w1		[integer!]
			h1		[integer!]
			w2		[integer!]
			h2		[integer!]
			w		[integer!]
			h		[integer!]
			cs		[int-ptr!]
			rect	[NSRect!]
			ctx		[int-ptr!]
			handle	[int-ptr!]
	][
		w1: CGImageGetWidth img1
		h1: CGImageGetHeight img1
		w2: CGImageGetWidth img2
		h2: CGImageGetHeight img2

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
		inode0: as img-node! (resolve-series src/node) + 1
		handle0: inode0/handle
		width: IMAGE_WIDTH(inode0/size)
		height: IMAGE_HEIGHT(inode0/size)
		pixels: width * height * 4

		either null? handle0 [
			scan0: as int-ptr! allocate pixels
			dst/node: node-handle-of make-node null scan0 IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED width height
			copy-memory as byte-ptr! scan0 as byte-ptr! inode0/buffer pixels
		][
			handle: CGImageCreateCopy handle0
			dst/node: node-handle-of make-node handle null 0 width height
		]
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
		inode0: as img-node! (resolve-series src/node) + 1
		handle0: inode0/handle
		width: IMAGE_WIDTH(inode0/size)
		height: IMAGE_HEIGHT(inode0/size)

		either null? handle0 [
			dst-buf: allocate w * h * 4
			dst/node: node-handle-of make-node null as int-ptr! dst-buf IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED w h
			src-buf: as byte-ptr! inode0/buffer
			copy-rect dst-buf w * 4 src-buf width * 4 x y h
		][
			handle: CGImageCreateWithImageInRect
				handle0 as CGFloat! x as CGFloat! y as CGFloat! w as CGFloat! h
			dst/node: node-handle-of make-node handle null 0 w h
		]
		dst/size: h << 16 or w
		dst/header: TYPE_IMAGE
		dst/head: 0
		dst
	]
]
