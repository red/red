Red/System [
	Title:   "Image routine functions using GDI+"
	Author:  "Qingtian Xie"
	File: 	 %image-gdiplus.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

;-- In-memory pixel data formats:
;-- bits 0-7 = format index
;-- bits 8-15 = pixel size (in bits)
;-- bits 16-23 = flags
;-- bits 24-31 = reserved

#define PixelFormatIndexed			00010000h ;-- Indexes into a palette
#define PixelFormatGDI				00020000h ;-- Is a GDI-supported format
#define PixelFormatAlpha			00040000h ;-- Has an alpha component
#define PixelFormatPAlpha			00080000h ;-- Pre-multiplied alpha
#define PixelFormatExtended			00100000h ;-- Extended color 16 bits/channel
#define PixelFormatCanonical		00200000h

#define PixelFormatUndefined		0
#define PixelFormatDontCare			0

#define PixelFormat32bppARGB		2498570   ;-- [10 or (32 << 8) or PixelFormatAlpha or PixelFormatGDI or PixelFormatCanonical]
#define PixelFormat32bppPARGB		925707    ;-- [11 or (32 << 8) or PixelFormatAlpha or PixelFormatPAlpha or PixelFormatGDI]
#define PixelFormat32bppCMYK		8207	  ;-- [15 or (32 << 8)]
#define PixelFormatMax				16

;-- PixelFormat
#define GL_COLOR_INDEX				1900h
#define GL_STENCIL_INDEX			1901h
#define GL_DEPTH_COMPONENT			1902h
#define GL_RED						1903h
#define GL_GREEN					1904h
#define GL_BLUE						1905h
#define GL_ALPHA					1906h
#define GL_RGB						1907h
#define GL_RGBA						1908h
#define GL_LUMINANCE				1909h
#define GL_LUMINANCE_ALPHA			190Ah

#define GMEM_MOVEABLE	2

#define GpBitmap!	int-ptr!
#define GpImage!	int-ptr!
#define GpGraphics! int-ptr!

img-node!: alias struct! [								;-- imported by View
	deallocator [integer!]								;-- func to call to free the OS resources
	handle		[integer!]
]

OS-image: context [

	CLSID_BMP_ENCODER:  [557CF400h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_JPEG_ENCODER: [557CF401h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_GIF_ENCODER:  [557CF402h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_TIFF_ENCODER: [557CF405h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_PNG_ENCODER:  [557CF406h 11D31A04h 0000739Ah 2EF31EF8h]

	RECT!: alias struct! [
		left	[integer!]
		top		[integer!]
		right	[integer!]
		bottom	[integer!]
	]

	BitmapData!: alias struct! [
		width		[integer!]
		height		[integer!]
		stride		[integer!]
		pixelFormat	[integer!]
		scan0		[byte-ptr!]
		reserved	[integer!]
	]

	#import [
		"kernel32.dll" stdcall [
			GlobalAlloc: "GlobalAlloc" [
				flags		[integer!]
				size		[integer!]
				return:		[integer!]
			]
			GlobalFree: "GlobalFree" [
				hMem		[integer!]
				return:		[integer!]
			]
			GlobalLock: "GlobalLock" [
				hMem		[integer!]
				return:		[byte-ptr!]
			]
			GlobalUnlock: "GlobalUnlock" [
				hMem		[integer!]
				return:		[integer!]
			]
		]
		"ole32.dll" stdcall [
			CreateStreamOnHGlobal: "CreateStreamOnHGlobal" [
				hMem		[integer!]
				fAutoDel	[logic!]
				ppstm		[int-ptr!]
				return:		[integer!]
			]
		]
		"gdiplus.dll" stdcall [
			GdipCloneImage: "GdipCloneImage" [
				image		[integer!]
				new-image	[int-ptr!]
				return:		[integer!]
			]
			GdipCloneBitmapAreaI: "GdipCloneBitmapAreaI" [
				x			[integer!]
				y			[integer!]
				width		[integer!]
				height		[integer!]
				format		[integer!]
				src			[integer!]
				dst			[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromFile: "GdipCreateBitmapFromFile" [
				filename	[c-string!]
				image		[GpBitmap!]
				return:		[integer!]
			]
			GdipBitmapLockBits: "GdipBitmapLockBits" [
				bitmap		[integer!]
				rect		[RECT!]
				flags		[integer!]
				format		[integer!]
				data		[BitmapData!]
				return:		[integer!]
			]
			GdipBitmapUnlockBits: "GdipBitmapUnlockBits" [
				bitmap		[integer!]
				data		[BitmapData!]
				return:		[integer!]
			]
			GdipBitmapGetPixel: "GdipBitmapGetPixel" [
				bitmap		[integer!]
				x			[integer!]
				y			[integer!]
				argb		[int-ptr!]
				return:		[integer!]
			]
			GdipBitmapSetPixel: "GdipBitmapSetPixel" [
				bitmap		[integer!]
				x			[integer!]
				y			[integer!]
				argb		[integer!]
				return:		[integer!]
			]
			GdipGetImageWidth: "GdipGetImageWidth" [
				image		[integer!]
				width		[int-ptr!]
				return:		[integer!]
			]
			GdipGetImageHeight: "GdipGetImageHeight" [
				image		[integer!]
				height		[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromGdiDib: "GdipCreateBitmapFromGdiDib" [
				bmi			[byte-ptr!]
				data		[byte-ptr!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromScan0: "GdipCreateBitmapFromScan0" [
				width		[integer!]
				height		[integer!]
				stride		[integer!]
				format		[integer!]
				scan0		[byte-ptr!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromStream: "GdipCreateBitmapFromStream" [
				stream		[integer!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipGetImagePixelFormat: "GdipGetImagePixelFormat" [
				image		[integer!]
				format		[int-ptr!]
				return:		[integer!]
			]
			GdipSaveImageToStream: "GdipSaveImageToStream" [
				image		[integer!]
				stream		[this!]
				encoder		[int-ptr!]
				params		[integer!]
				return:		[integer!]
			]
			GdipGetImageGraphicsContext: "GdipGetImageGraphicsContext" [
				image		[integer!]
				graphics	[GpGraphics!]
				return:		[integer!]
			]
			GdipDrawImageRectRectI: "GdipDrawImageRectRectI" [
				graphics	[integer!]
				image		[integer!]
				dstx		[integer!]
				dsty		[integer!]
				dstwidth	[integer!]
				dstheight	[integer!]
				srcx		[integer!]
				srcy		[integer!]
				srcwidth	[integer!]
				srcheight	[integer!]
				srcUnit		[integer!]
				attribute	[integer!]
				callback	[integer!]
				data		[integer!]
				return:		[integer!]
			]
			GdipDeleteGraphics: "GdipDeleteGraphics" [
				graphics	[integer!]
				return:		[integer!]
			]
			GdipDisposeImage: "GdipDisposeImage" [
				image		[integer!]
				return:		[integer!]
			]
			GdipGetImagePaletteSize: "GdipGetImagePaletteSize" [
				image		[integer!]
				size		[int-ptr!]
				return:		[integer!]
			]
			GdipGetImagePalette: "GdipGetImagePalette" [
				image		[integer!]
				palette		[byte-ptr!]
				size		[integer!]
				return:		[integer!]
			]
			GdipSetImagePalette: "GdipSetImagePalette" [
				image		[integer!]
				palette		[byte-ptr!]
				return:		[integer!]
			]
		]
	]

	width?: func [
		node		[int-ptr!]
		return:		[integer!]
		/local
			width	[integer!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! node/value) + 1
		width: 0
		GdipGetImageWidth inode/handle :width
		width
	]

	height?: func [
		node		[int-ptr!]
		return:		[integer!]
		/local
			height	[integer!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! node/value) + 1
		height: 0
		GdipGetImageHeight inode/handle :height
		height
	]

	lock-bitmap-fmt: func [
		handle		[integer!]
		pixelformat [integer!]
		write?		[logic!]
		return:		[integer!]
		/local
			data	[BitmapData!]
			mode	[integer!]
			res		[integer!]
	][
		if zero? handle [return 0]
		data: as BitmapData! allocate size? BitmapData!
		mode: either write? [3][1]
		res: GdipBitmapLockBits handle null mode pixelformat data
		either zero? res [as-integer data][0]
	]

	unlock-bitmap-fmt: func [
		handle		[integer!]
		data		[integer!]
	][
		if zero? handle [exit]
		GdipBitmapUnlockBits handle as BitmapData! data
		free as byte-ptr! data
	]

	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
		/local inode [img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		lock-bitmap-fmt inode/handle PixelFormat32bppARGB write?
	]	

	unlock-bitmap: func [
		img			[red-image!]
		data		[integer!]
		/local inode [img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		if zero? inode/handle [exit]
		GdipBitmapUnlockBits inode/handle as BitmapData! data
		free as byte-ptr! data
	]

	get-data: func [
		bmdata		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			bitmap	[BitmapData!]
	][
		if zero? bmdata [return null]
		bitmap: as BitmapData! bmdata
		stride/value: bitmap/stride
		as int-ptr! bitmap/scan0
	]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
		/local
			width	[integer!]
			arbg	[integer!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! bitmap/value) + 1
		width: width? bitmap
		arbg: 0
		GdipBitmapGetPixel inode/handle index % width index / width :arbg
		arbg
	]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
		/local
			width	[integer!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! bitmap/value) + 1
		width: width? bitmap
		GdipBitmapSetPixel inode/handle index % width index / width color
	]

	delete: func [img [red-image!]][
		free-buffer img/node
	]

	free-buffer: func [
		node [node!]
		/local inode [img-node!]
	][
		unless null? node [
			inode: as img-node! (as series! node/value) + 1
			unless zero? inode/handle [
				GdipDisposeImage inode/handle
				inode/handle: 0
			]
		]
	]

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
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		graphic: 0
		format: 0
		bitmap: 0
		GdipGetImagePixelFormat inode/handle :format
		GdipCreateBitmapFromScan0 width height 0 format null :bitmap
		GdipGetImageGraphicsContext bitmap :graphic
		GdipDrawImageRectRectI
			graphic
			inode/handle
			0 0 width height
			0 0 old-w old-h
			2
			0 0 0
		GdipDeleteGraphics graphic
		as-integer make-node as node! bitmap
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

	copy: func [
		dst		[integer!]
		src		[integer!]
		lines	[integer!]
		x		[integer!]
		y		[integer!]
		format	[integer!]
		/local
			pbytes	[integer!]
			bmp-src [BitmapData!]
			bmp-dst [BitmapData!]
			dw		[integer!]
			dh		[integer!]
			ds		[integer!]
			sw		[integer!]
			sh		[integer!]
			ss		[integer!]
			palette [byte-ptr!]
			bytes	[integer!]
	][
		pbytes: format >> 8 and FFh / 8				;--number of bytes per pixel

		bmp-src: as BitmapData! lock-bitmap-fmt src format no
		bmp-dst: as BitmapData! lock-bitmap-fmt dst format yes
		sw: bmp-src/width sh: bmp-src/height ss: bmp-src/stride
		dw: bmp-dst/width dh: bmp-dst/height ds: bmp-dst/stride
		copy-rect bmp-dst/scan0 dw dh ds bmp-src/scan0 sw sh ss x y lines
		unlock-bitmap-fmt src as-integer bmp-src
		unlock-bitmap-fmt dst as-integer bmp-dst

		if format and PixelFormatIndexed <> 0 [		;-- indexed image, need to set palette
			bytes: 0
			GdipGetImagePaletteSize src :bytes
			palette: allocate bytes
			GdipGetImagePalette src palette bytes
			GdipSetImagePalette dst palette
			free palette
		]
	]

	load-image: func [
		src			[red-string!]
		return:		[int-ptr!]
		/local
			handle	[integer!]
			res		[integer!]
			bitmap	[integer!]
			format	[integer!]
			w		[integer!]
			h		[integer!]
			node	[node!]
	][
		handle: 0
		res: GdipCreateBitmapFromFile file/to-OS-path src :handle
		node: make-node as node! handle
		unless zero? res [return node]

		format: 0
		bitmap: 0
		GdipGetImagePixelFormat handle :format
		w: width?  node
		h: height? node
		GdipCreateBitmapFromScan0 w h 0 format null :bitmap
		copy bitmap handle h 0 0 format

		free-buffer node
		make-node as node! bitmap
	]

	make-node: func [
		handle	[node!]
		return: [node!]
		/local ser [series!] inode [img-node!] node [node!]
	][
		node: alloc-series 8 4 8						;-- make offset point past the internal data (safer)
		ser: as series! node/value
		ser/flags: ser/flags or flag-series-external	;-- let GC know there's an OS buffer to be freed
		inode: as img-node! ser + 1
		inode/deallocator: as-integer :free-buffer
		inode/handle:      as-integer handle
		node
	]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb-bin	[red-binary!]
		alpha-bin [red-binary!]
		color	[red-tuple!]
		return: [int-ptr!]
		/local
			a		[integer!]
			r		[integer!]
			b		[integer!]
			g		[integer!]
			data	[BitmapData!]
			scan0	[int-ptr!]
			bitmap	[integer!]
			end		[int-ptr!]
			rgb		[byte-ptr!]
			alpha	[byte-ptr!]
			len		[integer!]
			len2	[integer!]
	][
		if any [zero? width zero? height][return make-node null]
		bitmap: 0
		if 0 <> GdipCreateBitmapFromScan0 width height 0 PixelFormat32bppARGB null :bitmap [
			fire [TO_ERROR(script invalid-arg) pair/push width height]
		]
		data: as BitmapData! lock-bitmap-fmt bitmap PixelFormat32bppARGB yes
		scan0: as int-ptr! data/scan0
		end: scan0 + (width * height)

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

			while [scan0 < end][
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
				scan0/value: r << 16 or (g << 8) or b or (a << 24)
				scan0: scan0 + 1
			]
		][
			r: color/array1
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
			r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
			while [scan0 < end][
				scan0/value: r
				scan0: scan0 + 1
			]
		]

		unlock-bitmap-fmt bitmap as-integer data
		make-node as node! bitmap
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
		/local
			hMem	[integer!]
			p		[byte-ptr!]
			s		[integer!]
			bmp		[integer!]
			sthis	[this!]
			stream	[IStream]
	][
		hMem: GlobalAlloc GMEM_MOVEABLE len
		p: GlobalLock hMem
		copy-memory p data len
		GlobalUnlock hMem

		s: 0
		bmp: 0
		CreateStreamOnHGlobal hMem true :s
		GdipCreateBitmapFromStream s :bmp
		sthis: as this! s
		stream: as IStream sthis/vtbl
		stream/Release sthis				;-- the hMem will also be released
		make-node as node! bmp
	]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
		/local
			bin		[red-binary!]
			s		[series!]
			clsid	[int-ptr!]
			stream	[IStream]
			storage [IStorage]
			stat	[tagSTATSTG]
			IStm	[interface!]
			ISto	[interface!]
			len		[integer!]
			hr		[integer!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! image/node/value) + 1
		switch format [
			IMAGE_BMP  [clsid: CLSID_BMP_ENCODER]
			IMAGE_PNG  [clsid: CLSID_PNG_ENCODER]
			IMAGE_GIF  [clsid: CLSID_GIF_ENCODER]
			IMAGE_JPEG [clsid: CLSID_JPEG_ENCODER]
			IMAGE_TIFF [clsid: CLSID_TIFF_ENCODER]
			default    [probe "Cannot find image encoder" return null]
		]

		ISto: declare interface!
		IStm: declare interface!
		stat: declare tagSTATSTG
		hr: StgCreateDocfile
			null
			STGM_READWRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE or STGM_DELETEONRELEASE 
			0
			ISto
		storage: as IStorage ISto/ptr/vtbl
		hr: storage/CreateStream
			ISto/ptr
			#u16 "RedImageStream"
			STGM_READWRITE or STGM_SHARE_EXCLUSIVE
			0
			0
			IStm
		hr: GdipSaveImageToStream inode/handle IStm/ptr clsid 0

		stream: as IStream IStm/ptr/vtbl
		stream/Stat IStm/ptr stat 1
		len: stat/cbSize_low

		bin: as red-binary! slot
		bin/header: TYPE_UNSET
		bin/head: 0
		bin/node: alloc-bytes len
		bin/header: TYPE_BINARY
		
		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/tail) + len

		stream/Seek IStm/ptr 0 0 0 0 0
		stream/Read IStm/ptr as byte-ptr! s/offset len :hr
		stream/Release IStm/ptr
		storage/Release ISto/ptr
		as red-value! bin
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
			inode	[img-node!]
	][
		bmp: 0
		width: IMAGE_WIDTH(src/size)
		height: IMAGE_HEIGHT(src/size)
		offset: src/head

		assert not null? src/node
		inode: as img-node! (as series! src/node/value) + 1
		handle: inode/handle

		if any [
			width <= 0
			height <= 0
		][
			dst/size: 0
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: make-node as node! bmp
			return dst
		]

		if all [zero? offset not part?][
			GdipCloneImage handle :bmp
			dst/size: src/size
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: make-node as node! bmp
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
		either any [
			w <= 0
			h <= 0
		][
			dst/size: 0
		][
			format: 0
			GdipGetImagePixelFormat handle :format
			GdipCloneBitmapAreaI x y w h format handle :bmp
			dst/size: h << 16 or w
		]

		dst/header: TYPE_IMAGE
		dst/head: 0
		dst/node: make-node as node! bmp
		dst
	]
]