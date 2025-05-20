Red/System [
	Title:   "Red runtime library definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %definitions.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
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
#define series-in-use		80000000h		;-- mark a series as used (not collectable by the GC)
#define flag-ins-both		30000000h		;-- optimize for both head & tail insertions
#define flag-ins-tail		20000000h		;-- optimize for tail insertions
#define flag-ins-head		10000000h		;-- optimize for head insertions
#define flag-gc-mark		08000000h		;-- mark as referenced for the GC (mark phase)
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
#define flag-extern-code	00008000h		;-- routine's body is from FFI
#define flag-word-dirty		00002000h		;-- word flag indicating if value has been modified
#define flag-force-trace	00000400h		;-- tracing mode is forced (function attribut)
#define flag-no-trace		00000200h		;-- tracing mode is disabled (function attribut)

#define flag-fetch-mode		00300000h		;-- flags for arguments fetching mode (typeset! header only)
#define flag-fetch-mask		FFDFFFFFh		;-- mask for arguments fetching mode (typeset! header only)
#define flag-subtype-mask	FF00FFFFh		;-- mask for encoding the underlying function type (op! header only)
#define flag-subtype-select	00FF0000h		;-- mask for selecting the underlying function type (op! header only)
#define flag-new-line		40000000h		;-- if set, indicates that a new-line preceeds the value
#define flag-nl-mask		BFFFFFFFh		;-- mask for new-line flag
#define flag-arity-mask		C1FFFFFFh		;-- mask for reading routines arity field
#define flag-self-mask		01000000h		;-- mask for self? flag
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

#define max-char-codepoint	0010FFFFh		;-- upper limit for a codepoint value.

;== platform-specific definitions ==

#include %platform/definitions.reds

;=== Unicode support definitions ===

#enum encoding! [							;-- various string encodings
	UTF-16LE:	-1
	UTF-8:		 0
	Latin1:		 1
	UCS-1:		 1
	UCS-2:		 2
	UCS-4:		 4
]

#enum context-type! [
	CONTEXT_GLOBAL							;-- global context value is 0 (no need to set it then)
	CONTEXT_FUNCTION						;-- do not change those values! (used in %utils/redbin.r)
	CONTEXT_OBJECT
]

#enum cb-class! [							;-- internal callbacks classes used by _function/call
	CB_INTERPRETER:	0
	CB_LEXER:		1
	CB_PARSE:		2
	CB_SORT:		4
	CB_OBJ_CHANGE:	8
	CB_OBJ_DEEP:	16
	CB_PORT:		32
]

;== Image definitions ===

#enum extract-type! [						;-- image! buffer encodings
	EXTRACT_ALPHA
	EXTRACT_RGB
	EXTRACT_ARGB
]

;== Draw Context definitions ==

#define F32_0	[as float32! 0.0]
#define F32_1	[as float32! 1.0]

#define ANY_COORD?(value) [any [TYPE_OF(value) = TYPE_PAIR TYPE_OF(value) = TYPE_POINT2D]]
#define PAIR_TYPE?(value) [TYPE_OF(value) = TYPE_PAIR]
#define GET_PAIR_XY(_pair fx fy) [
	either PAIR_TYPE?(_pair) [
		fx: as float32! _pair/x
		fy: as float32! _pair/y
	][
		pt: as red-point2D! _pair
		fx: pt/x
		fy: pt/y
	]
]
#define GET_PAIR_XY_INT(_pair fx fy) [
	either PAIR_TYPE?(_pair) [
		fx: _pair/x
		fy: _pair/y
	][
		pt: as red-point2D! _pair
		fx: as-integer pt/x
		fy: as-integer pt/y
	]
]
#define GET_PAIR_XY_F(_pair fx fy) [
	either PAIR_TYPE?(_pair) [
		fx: as float! _pair/x
		fy: as float! _pair/y
	][
		pt: as red-point2D! _pair
		fx: as float! pt/x
		fy: as float! pt/y
	]
]

#switch GUI-engine [
	native [
		#switch OS [
			Windows  [
				#enum brush-type! [
					BRUSH_TYPE_NORMAL
					BRUSH_TYPE_TEXTURE
				]

				this!: alias struct! [vtbl [int-ptr!]]
				com-ptr!: alias struct! [value [this!]]

				POINT_2F: alias struct! [
					x		[float32!]
					y		[float32!]
				]

				tagPOINT: alias struct! [
					x		[integer!]
					y		[integer!]	
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

				PATHDATA: alias struct! [
					count       [integer!]
					points      [POINT_2F]
					types       [byte-ptr!]
				]

				gradient!: alias struct! [
					extra           [integer!]          		;-- used when pen width > 1
					path-data       [PATHDATA]          		;-- preallocated for performance reasons
					points-data     [tagPOINT]          		;-- preallocated for performance reasons
					matrix			[integer!]
					colors			[int-ptr!]
					colors-pos		[float32-ptr!]
					spread			[integer!]
					type            [integer!]          		;-- gradient on fly (just before drawing figure)
					count           [integer!]          		;-- gradient stops count
					data            [tagPOINT]          		;-- figure coordinates
					positions?      [logic!]            		;-- true if positions are defined, false otherwise
					created?        [logic!]            		;-- true if gradient brush created, false otherwise
					transformed?	[logic!]					;-- true if transformation applied
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
					edges					[tagPOINT]			;-- polygone edges buffer
					types					[byte-ptr!]			;-- point type buffer
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

			#either draw-engine = none [
					sub-path!: alias struct! [
						path			[integer!]
						sink			[integer!]
						last-pt-x		[float32!]
						last-pt-y		[float32!]
						shape-curve?	[logic!]
						control-x		[float32!]
						control-y		[float32!]
					]

					shadow!: alias struct! [
						offset-x		[float32!]
						offset-y		[float32!]
						blur			[float32!]
						spread			[float32!]
						color			[integer!]
						inset?			[logic!]
						next			[shadow!]
					]
					matrix3x2!: alias struct! [
						_11				[float32!]
						_12				[float32!]
						_21				[float32!]
						_22				[float32!]
						_31				[float32!]
						_32				[float32!]
					]

					#define DRAW_STATE_DATA [
						state			[this!]
						pen				[this!]
						brush			[this!]
						pen-style		[this!]
						text-format		[this!]
						pen-type		[integer!]
						brush-type		[integer!]
						pen-color		[integer!]
						brush-color		[integer!]
						font-color		[integer!]
						pen-join		[integer!]
						pen-cap			[integer!]
						pen-pattern		[float32-ptr!]
						pen-pattern-cnt [integer!]
						pen-grad-type	[integer!]
						brush-grad-type	[integer!]
						prev-pen-type	[integer!]
						pen-width		[float32!]
						pen-offset		[POINT_2F value]
						brush-offset	[POINT_2F value]
						clip-cnt		[integer!]
						font-color?		[logic!]
						font?			[logic!]
						shadow?			[logic!]
					]

					draw-state!: alias struct! [
						DRAW_STATE_DATA
					]

					draw-ctx!: alias struct! [
						dc				[ptr-ptr!]
						DRAW_STATE_DATA
						target			[int-ptr!]
						hwnd			[int-ptr!]			;-- Window's handle
						image			[int-ptr!]			;-- original image handle
						pre-order?		[logic!]			;-- matrix order, default pre-order for row-major vector
						draw-shape?		[logic!]
						sub				[sub-path! value]
						shadows			[shadow! value]
					]
				][
					draw-ctx!: alias struct! [
						dc				[int-ptr!]			;-- OS drawing object
						hwnd			[int-ptr!]			;-- Window's handle
						pen				[integer!]
						brush			[integer!]
						pen-join		[integer!]
						pen-cap			[integer!]
						pen-width		[float32!]
						pen-style		[integer!]
						pen-color		[integer!]			;-- 00bbggrr format
						brush-color		[integer!]			;-- 00bbggrr format
						font-color		[integer!]
						bitmap			[int-ptr!]
						brushes			[int-ptr!]
						graphics		[integer!]			;-- gdiplus graphics
						gp-state		[integer!]
						gp-pen			[integer!]			;-- gdiplus pen
						gp-pen-type 	[brush-type!]		;-- gdiplus pen type (for texture, another set of transformation functions must be applied)
						gp-pen-saved	[integer!]
						gp-brush		[integer!]			;-- gdiplus brush
						gp-brush-type 	[brush-type!]		;-- gdiplus brush type (for texture, another set of transformation functions must be applied)
						gp-font			[integer!]			;-- gdiplus font
						gp-font-brush	[integer!]
						gp-matrix		[integer!]
						gp-path			[integer!]
						image-attr		[integer!]			;-- gdiplus image attributes
						scale-ratio		[float32!]
						pen?			[logic!]
						brush?			[logic!]
						on-image?		[logic!]			;-- drawing on image?
						alpha-pen?		[logic!]
						alpha-brush?	[logic!]
						font-color?		[logic!]
						other 			[other!]
					]
				]
			]
			macOS    [
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
					ctx-matrix      [CGAffineTransform! value]
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
					grad-pos?		[logic!]
					grad-pen?		[logic!]
					grad-brush?		[logic!]
					pen?			[logic!]
					brush?			[logic!]
					on-image?		[logic!]					;-- drawing on image?
					rect-y			[float32!]
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
					path			[integer!]
					shape-curve?	[logic!]
				]
			]
			RPi
			RPI-GTK
			Linux    [
				point2f!: alias struct! [
					x		[float!]
					y		[float!]
				]

				tagMATRIX: alias struct! [
					xx		[float!]
					yx		[float!]
					xy		[float!]
					yy		[float!]
					x0		[float!]
					y0		[float!]
				]

				gradient!: alias struct! [
					on?				[logic!]
					spread			[integer!]
					type			[integer!]					;-- gradient on fly (just before drawing figure)
					matrix-on?		[logic!]
					matrix			[tagMATRIX value]
					colors			[int-ptr!]					;-- always on
					colors-pos		[float32-ptr!]				;-- always on
					count			[integer!]					;-- gradient stops count
					zero-base?		[logic!]
					offset-on?		[logic!]
					offset			[point2f! value]			;-- figure coordinates
					offset2			[point2f! value]
					focal-on?		[logic!]
					focal			[point2f! value]
					pattern-on?		[logic!]
					pattern			[int-ptr!]
				]

				#define DRAW_STATE_DATA [
					matrix-order	[integer!]
					device-matrix	[tagMATRIX value]
					pattern?		[logic!]
					line-width?		[logic!]
					pen-width		[float!]
					pen-pattern		[float-ptr!]
					pen-color		[integer!]					;-- 00bbggrr format
					brush-color		[integer!]					;-- 00bbggrr format
					font-color		[integer!]
					font-attrs		[handle!]					;-- pango attrs for fonts
					font-antialias  [integer!]					;-- cairo fonts antialias
					grad-pen		[gradient! value]
					grad-brush		[gradient! value]
					pen?			[logic!]
					brush?			[logic!]
					on-image?		[logic!]
				]

				draw-state!: alias struct! [
					DRAW_STATE_DATA
				]

				draw-ctx!: alias struct! [
					cr				[handle!]
					DRAW_STATE_DATA
					font-opts		[handle!]
					control-x		[float32!]
					control-y		[float32!]
					shape-curve?	[logic!]
				]

				layout-ctx!: alias struct! [
					layout			[handle!]					;-- Only for rich-text
					text			[c-string!]
					attrs			[handle!]
				]
			]
			#default [0]
		]
	]
	test 	 []
	GTK 	 [
		point2f!: alias struct! [
			x		[float!]
			y		[float!]
		]

		tagMATRIX: alias struct! [
			xx		[float!]
			yx		[float!]
			xy		[float!]
			yy		[float!]
			x0		[float!]
			y0		[float!]
		]

		gradient!: alias struct! [
			on?				[logic!]
			spread			[integer!]
			type			[integer!]					;-- gradient on fly (just before drawing figure)
			matrix-on?		[logic!]
			matrix			[tagMATRIX value]
			colors			[int-ptr!]					;-- always on
			colors-pos		[float32-ptr!]				;-- always on
			count			[integer!]					;-- gradient stops count
			zero-base?		[logic!]
			offset-on?		[logic!]
			offset			[point2f! value]			;-- figure coordinates
			offset2			[point2f! value]
			focal-on?		[logic!]
			focal			[point2f! value]
			pattern-on?		[logic!]
			pattern			[int-ptr!]
		]

		#define DRAW_STATE_DATA [
			matrix-order	[integer!]
			device-matrix	[tagMATRIX value]
			pattern?		[logic!]
			line-width?		[logic!]
			pen-width		[float!]
			pen-pattern		[float-ptr!]
			pen-color		[integer!]					;-- 00bbggrr format
			brush-color		[integer!]					;-- 00bbggrr format
			font-color		[integer!]
			font-attrs		[handle!]					;-- pango attrs for fonts
			font-antialias  [integer!]					;-- cairo fonts antialias
			grad-pen		[gradient! value]
			grad-brush		[gradient! value]
			pen?			[logic!]
			brush?			[logic!]
			on-image?		[logic!]
		]
		
		draw-state!: alias struct! [
			DRAW_STATE_DATA
		]

		draw-ctx!: alias struct! [
			cr				[handle!]
			DRAW_STATE_DATA
			font-opts		[handle!]
			control-x		[float32!]
			control-y		[float32!]
			shape-curve?	[logic!]
		]

		layout-ctx!: alias struct! [
			layout			[handle!]					;-- Only for rich-text
			text			[c-string!]
			attrs			[handle!]
		]
	]
	terminal [
		draw-state!: alias struct! [unused [integer!]]
		draw-ctx!: alias struct! [
			dc			[handle!]
			x			[integer!]
			y			[integer!]
			left		[integer!]
			top			[integer!]
			right		[integer!]
			bottom		[integer!]
			pen-type	[integer!]
			pen-color	[integer!]
			brush-color	[integer!]
			brush-type	[integer!]
			font-color	[integer!]
			font-color? [logic!]
			flags		[integer!]
		]
	]
]

;=== Image definitions ===

#enum image-format! [
	IMAGE_BMP
	IMAGE_PNG
	IMAGE_GIF
	IMAGE_JPEG
	IMAGE_TIFF
]

#define IMAGE_WIDTH(size)  (size and FFFFh) 
#define IMAGE_HEIGHT(size) (size >>> 16)

;=== Misc definitions ===

lexer-dt-array!: alias struct! [
	year		[integer!]
	month		[integer!]
	day			[integer!]
	hour		[integer!]
	min			[integer!]
	sec			[integer!]
	nsec		[integer!]
	tz-h		[integer!]
	tz-m		[integer!]
	week		[integer!]
	wday		[integer!]
	yday		[integer!]
	month-begin	[integer!]
	month-end	[integer!]
	sep2		[integer!]
	TZ-sign		[integer!]
]