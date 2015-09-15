Red/System [
	Title:   "Image routine functions using GDI+"
	Author:  "Qingtian Xie"
	File: 	 %image-gdiplus.red
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#enum ImageLockMode! [
    ImageLockModeRead:			1
    ImageLockModeWrite:			2
    ImageLockModeUserInputBuf:	4
]

;-- In-memory pixel data formats:
;-- bits 0-7 = format index
;-- bits 8-15 = pixel size (in bits)
;-- bits 16-23 = flags
;-- bits 24-31 = reserved

#define    PixelFormatIndexed         00010000h ;-- Indexes into a palette
#define    PixelFormatGDI             00020000h ;-- Is a GDI-supported format
#define    PixelFormatAlpha           00040000h ;-- Has an alpha component
#define    PixelFormatPAlpha          00080000h ;-- Pre-multiplied alpha
#define    PixelFormatExtended        00100000h ;-- Extended color 16 bits/channel
#define    PixelFormatCanonical       00200000h

#define    PixelFormatUndefined       0
#define    PixelFormatDontCare        0

#define    PixelFormat32bppARGB       [10 or (32 << 8) or PixelFormatAlpha or PixelFormatGDI or PixelFormatCanonical]
#define    PixelFormat32bppPARGB      [11 or (32 << 8) or PixelFormatAlpha or PixelFormatPAlpha or PixelFormatGDI]
#define    PixelFormat32bppCMYK       [15 or (32 << 8)]
#define    PixelFormatMax             16

;-- PixelFormat
#define GL_COLOR_INDEX                    1900h
#define GL_STENCIL_INDEX                  1901h
#define GL_DEPTH_COMPONENT                1902h
#define GL_RED                            1903h
#define GL_GREEN                          1904h
#define GL_BLUE                           1905h
#define GL_ALPHA                          1906h
#define GL_RGB                            1907h
#define GL_RGBA                           1908h
#define GL_LUMINANCE                      1909h
#define GL_LUMINANCE_ALPHA                190Ah

#define GpBitmap!	int-ptr!
#define GpImage!	int-ptr!
#define GpGraphics! int-ptr!

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
			return:		[int-ptr!]
		]
		GlobalFree: "GlobalFree" [
			hMem		[integer!]
			return:		[integer!]
		]
		GlobalLock: "GlobalLock" [
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
		GdipDisposeImage: "GdipDisposeImage" [
			image		[integer!]
			return:		[integer!]
		]
		GdipGetImagePixelFormat: "GdipGetImagePixelFormat" [
			image		[integer!]
			format		[int-ptr!]
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

lock-bitmap: func [
	handle		[integer!]
	return:		[integer!]
	/local
		rect	[RECT!]
		data	[BitmapData!]
][
	rect: declare RECT!
	data: as BitmapData! allocate size? BitmapData!
	rect/left: 0
	rect/top: 0
	rect/right: width? handle
	rect/bottom: height? handle
	GdipBitmapLockBits handle rect ImageLockModeWrite PixelFormat32bppARGB data
	as-integer data
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
		buf		[int-ptr!]
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
		arbg	[integer!]
][
	width: width? bitmap
	GdipBitmapSetPixel bitmap index % width index / width color
]

load-image: func [
	filename	[c-string!]				;-- UTF-16 string
	return:		[integer!]
	/local
		handle	[integer!]
		res		[integer!]
][
	handle: 0
	res: GdipCreateBitmapFromFile filename :handle
	unless zero? res [platform/error-msg res]
	handle
]

make-image: func [
	width	[integer!]
	height	[integer!]
	rgb		[byte-ptr!]
	alpha	[byte-ptr!]
	return: [integer!]
	/local
		a		[integer!]
		r		[integer!]
		b		[integer!]
		g		[integer!]
		x		[integer!]
		y		[integer!]
		data	[BitmapData!]
		scan0	[int-ptr!]
		bitmap	[integer!]
		pos		[integer!]
][
	bitmap: 0
	GdipCreateBitmapFromScan0 width height 0 PixelFormat32bppARGB null :bitmap
	data: as BitmapData! lock-bitmap bitmap
	scan0: as int-ptr! data/scan0

	unless null? rgb [
		y: 0
		while [y < height][
			x: 0
			while [x < width][
				pos: data/stride >> 2 * y + x + 1
				a: either null? alpha [0][as-integer alpha/1]
				r: as-integer rgb/1
				b: as-integer rgb/2
				g: as-integer rgb/3
				scan0/pos: r << 16 or (b << 8) or g or (a << 24)
				rgb: rgb + 3
				alpha: alpha + 1
				x: x + 1
			]
			y: y + 1
		]
	]

	unlock-bitmap bitmap as-integer data
	bitmap
]