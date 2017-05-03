Red/System [
	Title:   "Image routine functions using GDI+"
	Author:  "Qingtian Xie"
	File: 	 %image-gdiplus.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
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
		handle		[integer!]
		return:		[integer!]
		/local
			width	[integer!]
	][
		width: 0
		GdipGetImageWidth handle :width
		width
	]

	height?: func [
		handle		[integer!]
		return:		[integer!]
		/local
			height	[integer!]
	][
		height: 0
		GdipGetImageHeight handle :height
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
		data: as BitmapData! allocate size? BitmapData!
		mode: either write? [3][1]
		res: GdipBitmapLockBits handle null mode pixelformat data
		either zero? res [as-integer data][0]
	]

	lock-bitmap: func [
		handle		[integer!]
		write?		[logic!]
		return:		[integer!]
	][
		lock-bitmap-fmt handle PixelFormat32bppARGB write?
	]	

	unlock-bitmap: func [
		handle		[integer!]
		data		[integer!]
	][
		GdipBitmapUnlockBits handle as BitmapData! data
		free as byte-ptr! data
	]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			bitmap	[BitmapData!]
	][
		bitmap: as BitmapData! handle
		stride/value: bitmap/stride
		as int-ptr! bitmap/scan0
	]

	get-pixel: func [
		bitmap		[integer!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
		/local
			width	[integer!]
			arbg	[integer!]
	][
		width: width? bitmap
		arbg: 0
		GdipBitmapGetPixel bitmap index % width index / width :arbg
		arbg
	]

	set-pixel: func [
		bitmap		[integer!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
		/local
			width	[integer!]
	][
		width: width? bitmap
		GdipBitmapSetPixel bitmap index % width index / width color
	]

	delete: func [img [red-image!]][
		GdipDisposeImage as-integer img/node
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
	][
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		graphic: 0
		format: 0
		bitmap: 0
		GdipGetImagePixelFormat as-integer img/node :format
		GdipCreateBitmapFromScan0 width height 0 format null :bitmap
		GdipGetImageGraphicsContext bitmap :graphic
		GdipDrawImageRectRectI
			graphic
			as-integer img/node
			0 0 width height
			0 0 old-w old-h
			2
			0 0 0
		GdipDeleteGraphics graphic
		bitmap
	]

	copy: func [
		dst		[integer!]
		src		[integer!]
		pixels	[integer!]
		lines	[integer!]
		offset	[integer!]
		format	[integer!]
		/local
			bmp-src [BitmapData!]
			bmp-dst [BitmapData!]
			palette [byte-ptr!]
			bytes	[integer!]
			pbytes	[integer!]
			stride	[integer!]
			w		[integer!]
	][
		pbytes: format >> 8 and FFh / 8				;--number of bytes per pixel

		bmp-src: as BitmapData! lock-bitmap-fmt src format no
		bmp-dst: as BitmapData! lock-bitmap-fmt dst format yes
		stride: bmp-src/stride
		w: bmp-src/width
		bytes: stride * lines
		if pixels <> 0 [bytes: stride / pbytes - w + pixels * pbytes + bytes]
		offset: offset / w * stride + (offset % w * pbytes)
		copy-memory bmp-dst/scan0 bmp-src/scan0 + offset bytes
		unlock-bitmap src as-integer bmp-src
		unlock-bitmap dst as-integer bmp-dst

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
		filename	[c-string!]				;-- UTF-16 string
		return:		[integer!]
		/local
			handle	[integer!]
			res		[integer!]
			bitmap	[integer!]
			format	[integer!]
			w		[integer!]
			h		[integer!]
	][
		handle: 0
		res: GdipCreateBitmapFromFile filename :handle
		unless zero? res [return -1]

		format: 0
		bitmap: 0
		GdipGetImagePixelFormat handle :format
		w: width? handle
		h: height? handle
		GdipCreateBitmapFromScan0 w h 0 format null :bitmap

		copy bitmap handle 0 h 0 format

		GdipDisposeImage handle 
		bitmap
	]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb		[byte-ptr!]
		alpha	[byte-ptr!]
		color	[red-tuple!]
		return: [integer!]
		/local
			a		[integer!]
			r		[integer!]
			b		[integer!]
			g		[integer!]
			data	[BitmapData!]
			scan0	[int-ptr!]
			bitmap	[integer!]
			end		[int-ptr!]
	][
		if any [zero? width zero? height][return null]
		bitmap: 0
		if 0 <> GdipCreateBitmapFromScan0 width height 0 PixelFormat32bppARGB null :bitmap [
			fire [TO_ERROR(script invalid-arg) pair/push width height]
		]
		data: as BitmapData! lock-bitmap-fmt bitmap PixelFormat32bppARGB yes
		scan0: as int-ptr! data/scan0
		end: scan0 + (width * height)

		either null? color [
			while [scan0 < end][
				either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
				either null? rgb [r: 255 g: 255 b: 255][
					r: as-integer rgb/1
					g: as-integer rgb/2
					b: as-integer rgb/3
					rgb: rgb + 3
				]
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

		unlock-bitmap bitmap as-integer data
		bitmap
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [integer!]
		/local
			hMem [integer!]
			p	 [byte-ptr!]
			s	 [integer!]
			bmp  [integer!]
	][
		hMem: GlobalAlloc GMEM_MOVEABLE len
		p: GlobalLock hMem
		copy-memory p data len
		GlobalUnlock hMem

		s: 0
		bmp: 0
		CreateStreamOnHGlobal hMem true :s
		GdipCreateBitmapFromStream s :bmp
		bmp
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
	][
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
		hr: GdipSaveImageToStream as-integer image/node IStm/ptr clsid 0

		stream: as IStream IStm/ptr/vtbl
		stream/Stat IStm/ptr stat 1
		len: stat/cbSize_low

		bin: as red-binary! slot
		bin/header: TYPE_BINARY
		bin/head: 0
		bin/node: alloc-bytes len
		
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
	][
		bmp: 0
		if part <> 0 [
			width: IMAGE_WIDTH(src/size)
			height: IMAGE_HEIGHT(src/size)
			offset: src/head
			x: offset % width
			y: offset / width
			handle: as-integer src/node

			either all [zero? offset not part?][
				GdipCloneImage handle :bmp
				dst/size: src/size
			][
				format: 0
				GdipGetImagePixelFormat handle :format
				either all [part? TYPE_OF(size) = TYPE_PAIR][
					w: width - x
					h: height - y
					if size/x < w [w: size/x]
					if size/y < h [h: size/y]
					GdipCloneBitmapAreaI x y w h format handle :bmp
				][
					either part < width [h: 0 w: part][
						h: part / width
						w: part % width
					]
					if zero? part [w: 1]
					GdipCreateBitmapFromScan0 w h 0 format null :bmp
					either zero? part [w: 0 h: 0][
						copy bmp handle w h offset format
					]
				]
				dst/size: h << 16 or w
			]
		]

		dst/header: TYPE_IMAGE
		dst/head: 0
		dst/node: as node! bmp
		dst
	]
]