Red/System [
	Title:   "Red runtime library definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %definitions.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;=== Memory allocator definitions ===

#define _512KB				524288
#define _1MB				1048576
#define _2MB				2097152
#define _16MB				16777216
#define nodes-per-frame		10000
#define node-frame-size		[((nodes-per-frame * 2 * size? pointer!) + size? node-frame!)]

#define series-in-use		80000000h		;-- mark a series as used (not collectable by the GC)
#define flag-ins-both		30000000h		;-- optimize for both head & tail insertions
#define flag-ins-tail		20000000h		;-- optimize for tail insertions
#define flag-ins-head		10000000h		;-- optimize for head insertions
#define flag-series-big		01000000h		;-- 1 = big, 0 = series
#define flag-series-small	00800000h		;-- series <= 16 bytes
#define flag-series-stk		00400000h		;-- values block allocated on stack
#define flag-series-nogc	00200000h		;-- protected from GC (system-critical series)
#define flag-series-fixed	00100000h		;-- series cannot be relocated (system-critical series)
#define flag-bitset-not		00080000h		;-- complement flag for bitsets
#define flag-UTF16-cache	00040000h		;-- UTF-16 encoding for string cache buffer
#define flag-series-owned	00020000h		;-- series is owned by an object
#define flag-owned			00010000h		;-- cell is owned by an object. (for now only image! use it)
#define flag-owner			00010000h		;-- object is an owner (carried by object's context value)
#define flag-native-op		00010000h		;-- operator is made from a native! function
#define flag-extern-code	00008000h		;-- routine's body is from FFI

#define flag-new-line		40000000h		;-- if set, indicates that a new-line preceeds the value
#define flag-nl-mask		BFFFFFFFh		;-- mask for new-line flag
#define flag-arity-mask		C1FFFFFFh		;-- mask for reading routines arity field
#define flag-self-mask		01000000h		;-- mask for self? flag
#define body-flag			00800000h		;-- flag for op! body node
#define tuple-size-mask		00780000h		;-- mask for reading tuple size field
#define flag-unit-mask		FFFFFFE0h		;-- mask for reading unit field in series-buffer!
#define get-unit-mask		0000001Fh		;-- mask for setting unit field in series-buffer!
#define series-free-mask	7FFFFFFFh		;-- mark a series as used (not collectable by the GC)
#define flag-not-mask		FFF7FFFFh		;-- mask for complement flag

#define type-mask			FFFFFF00h		;-- mask for clearing type ID in cell header
#define get-type-mask		000000FFh		;-- mask for reading type ID in cell header
#define node!				int-ptr!
#define default-offset		-1				;-- for offset value in alloc-series calls

#define series!				series-buffer! 
#define handle!				[pointer! [integer!]]


;=== Unicode support definitions ===

#enum encoding! [
	UTF-16LE:	-1
	UTF-8:		 0
	Latin1:		 1
	UCS-2:		 2
	UCS-4:		 4
]

;=== Simple I/O definitions ===

#enum http-verb! [
	HTTP_GET
	HTTP_PUT
	HTTP_POST
	HTTP_DEL
	HTTP_HEAD
]

;== Image definitions ===

#enum extract-type! [
	EXTRACT_ALPHA
	EXTRACT_RGB
	EXTRACT_ARGB
]

#if OS = 'MacOSX [
	CGAffineTransform!: alias struct! [
		a		[float32!]
		b		[float32!]
		c		[float32!]
		d		[float32!]
		tx		[float32!]
		ty		[float32!]
	]

	draw-ctx!: alias struct! [
		raw				[int-ptr!]					;-- OS drawing object: CGContext
		matrix          [CGAffineTransform! value]
		pen-join		[integer!]
		pen-cap			[integer!]
		pen-width		[float32!]
		pen-style		[integer!]
		pen-color		[integer!]					;-- 00bbggrr format
		brush-color		[integer!]					;-- 00bbggrr format
		font-attrs		[integer!]
		colorspace		[integer!]
		grad-pen		[integer!]
		grad-type		[integer!]
		grad-spread		[integer!]
		grad-x1			[float32!]
		grad-y1			[float32!]
		grad-x2			[float32!]
		grad-y2			[float32!]
		grad-radius		[float32!]
		grad-angle		[float32!]
		grad-sx			[float32!]
		grad-sy			[float32!]
		grad-pos?		[logic!]
		grad-rotate?	[logic!]
		grad-scale?		[logic!]
		grad-pen?		[logic!]
		grad-brush?		[logic!]
		pen?			[logic!]
		brush?			[logic!]
		on-image?		[logic!]					;-- drawing on image?
		pattern-blk		[int-ptr!]
		pattern-mode	[integer!]
		pattern-ver		[integer!]
		pattern-draw	[integer!]
		pattern-release [integer!]
		pattern-w		[float32!]
		pattern-h		[float32!]
		last-pt-x		[float32!]					;-- below used by shape
		last-pt-y		[float32!]
		control-x		[float32!]
		control-y		[float32!]
		shape-curve?	[logic!]
	]
]

#either OS = 'Windows [

	#define GENERIC_WRITE			40000000h
	#define GENERIC_READ 			80000000h
	#define FILE_SHARE_READ			00000001h
	#define FILE_SHARE_WRITE		00000002h
	#define FILE_SHARE_DELETE		00000004h
	#define CREATE_NEW				00000001h
	#define CREATE_ALWAYS			00000002h
	#define OPEN_EXISTING			00000003h
	#define OPEN_ALWAYS				00000004h
	#define TRUNCATE_EXISTING		00000005h
	#define FILE_ATTRIBUTE_NORMAL	00000080h
	#define FILE_ATTRIBUTE_DIRECTORY  00000010h
	#define FILE_FLAG_SEQUENTIAL_SCAN 08000000h
	
	#define STD_INPUT_HANDLE		-10
	#define STD_OUTPUT_HANDLE		-11
	#define STD_ERROR_HANDLE		-12

	#define SET_FILE_BEGIN			0
	#define SET_FILE_CURRENT		1
	#define SET_FILE_END			2

	#define MAX_FILE_REQ_BUF		4000h			;-- 16 KB
	#define OFN_HIDEREADONLY		0004h
	#define OFN_EXPLORER			00080000h
	#define OFN_ALLOWMULTISELECT	00000200h

	#define WIN32_FIND_DATA_SIZE	592

	#define BIF_RETURNONLYFSDIRS	1
	#define BIF_USENEWUI			50h
	#define BIF_SHAREABLE			8000h

	#define BFFM_INITIALIZED		1
	#define BFFM_SELCHANGED			2
	#define BFFM_SETSELECTION		1127

	#enum brush-type! [
		BRUSH_TYPE_NORMAL
		BRUSH_TYPE_TEXTURE
	]

	tagPAINTSTRUCT: alias struct! [
		hdc			 [handle!]
		fErase		 [integer!]
		left		 [integer!]
		top			 [integer!]
		right		 [integer!]
		bottom		 [integer!]
		fRestore	 [integer!]
		fIncUpdate	 [integer!]
		rgbReserved1 [integer!]
		rgbReserved2 [integer!]
		rgbReserved3 [integer!]
		rgbReserved4 [integer!]
		rgbReserved5 [integer!]
		rgbReserved6 [integer!]
		rgbReserved7 [integer!]
		rgbReserved8 [integer!]
	]
	
	POINT_2F: alias struct! [
		x		[float32!]
		y		[float32!]
	]

	PATHDATA: alias struct! [
		count       [integer!]
		points      [POINT_2F]
		types       [byte-ptr!]
	]

	tagPOINT: alias struct! [
		x		[integer!]
		y		[integer!]	
	]

	gradient!: alias struct! [
		extra           [integer!]                              ;-- used when pen width > 1
		path-data       [PATHDATA]                              ;-- preallocated for performance reasons
		points-data     [tagPOINT]                              ;-- preallocated for performance reasons
		matrix			[integer!]
		colors			[int-ptr!]
		colors-pos		[float32-ptr!]
		spread			[integer!]
		type            [integer!]                              ;-- gradient on fly (just before drawing figure)
		count           [integer!]                              ;-- gradient stops count
		data            [tagPOINT]                              ;-- figure coordinates
		positions?      [logic!]                                ;-- true if positions are defined, false otherwise
		created?        [logic!]                                ;-- true if gradient brush created, false otherwise
		transformed?	[logic!]								;-- true if transformation applied
	]

	curve-info!: alias struct! [
		type    [integer!]
		control [tagPOINT]
	]

	arcPOINTS!: alias struct! [
		start-x     [float!]
		start-y     [float!]
		end-x       [float!]
		end-y       [float!]
	]

	other!: alias struct! [
		gradient-pen			[gradient!]
		gradient-fill			[gradient!]
		gradient-pen?			[logic!]
		gradient-fill?			[logic!]
		matrix-elems			[float32-ptr!]		;-- elements of matrix allocated in draw-begin for performance reason
		paint					[tagPAINTSTRUCT]
		edges					[tagPOINT]					;-- polygone edges buffer
		types					[byte-ptr!]					;-- point type buffer
		last-point?				[logic!]
		path-last-point			[tagPOINT]
		prev-shape				[curve-info!]
		connect-subpath			[integer!]
		matrix-order			[integer!]
		anti-alias?				[logic!]
		GDI+?					[logic!]
		D2D?					[logic!]
		pattern-image-fill		[integer!]
		pattern-image-pen		[integer!]
	]

	draw-ctx!: alias struct! [
		dc				[int-ptr!]								;-- OS drawing object
		hwnd			[int-ptr!]								;-- Window's handle
		pen				[integer!]
		brush			[integer!]
		pen-join		[integer!]
		pen-cap			[integer!]
		pen-width		[float32!]
		pen-style		[integer!]
		pen-color		[integer!]								;-- 00bbggrr format
		brush-color		[integer!]								;-- 00bbggrr format
		font-color		[integer!]
		bitmap			[int-ptr!]
		brushes			[int-ptr!]
		graphics		[integer!]								;-- gdiplus graphics
		gp-state		[integer!]
		gp-pen			[integer!]								;-- gdiplus pen
		gp-pen-type 	[brush-type!]							;-- gdiplus pen type (for texture, another set of transformation functions must be applied)
		gp-pen-saved	[integer!]
		gp-brush		[integer!]								;-- gdiplus brush
		gp-brush-type 	[brush-type!]							;-- gdiplus brush type (for texture, another set of transformation functions must be applied)
		gp-font			[integer!]								;-- gdiplus font
		gp-font-brush	[integer!]
		gp-matrix		[integer!]
		gp-path			[integer!]
		image-attr		[integer!]								;-- gdiplus image attributes
		pen?			[logic!]
		brush?			[logic!]
		on-image?		[logic!]								;-- drawing on image?
		alpha-pen?		[logic!]
		alpha-brush?	[logic!]
		font-color?		[logic!]
		other 			[other!]
	]
][
	#define O_RDONLY	0
	#define O_WRONLY	1
	#define O_RDWR		2
	#define O_BINARY	0

	#define S_IREAD		256
	#define S_IWRITE    128
	#define S_IRGRP		32
	#define S_IWGRP		16
	#define S_IROTH		4

	#define	DT_DIR		#"^(04)"
	
	#case [
		any [OS = 'FreeBSD OS = 'MacOSX] [
			#define O_CREAT		0200h
			#define O_TRUNC		0400h
			#define O_EXCL		0800h
			#define O_APPEND	8
			#define	O_NONBLOCK	4
			#define	O_CLOEXEC	01000000h
			
			#define DIRENT_NAME_OFFSET 8
		]
		true [
			#define O_CREAT		64
			#define O_EXCL		128
			#define O_TRUNC		512
			#define O_APPEND	1024
			#define	O_NONBLOCK	2048
			#define	O_CLOEXEC	524288
		]
	]
	
	#define BFFM_SETEXPANDED		1130
]

;=== Image definitions ===

#enum image-format! [
	IMAGE_BMP
	IMAGE_PNG
	IMAGE_GIF
	IMAGE_JPEG
	IMAGE_TIFF
]