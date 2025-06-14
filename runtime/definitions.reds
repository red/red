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
	CONTEXT_CLASS
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

#enum extract-type! [						;-- image! buffer encodings
	EXTRACT_ALPHA
	EXTRACT_RGB
	EXTRACT_ARGB
]

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
	#define OFN_NOCHANGEDIR			0008h
	#define OFN_EXPLORER			00080000h
	#define OFN_ALLOWMULTISELECT	00000200h

	#define WIN32_FIND_DATA_SIZE	592

	#define BIF_RETURNONLYFSDIRS	1
	#define BIF_USENEWUI			50h
	#define BIF_SHAREABLE			8000h

	#define BFFM_INITIALIZED		1
	#define BFFM_SELCHANGED			2
	#define BFFM_SETSELECTION		1127

	#define KEY_EVENT 				 			01h
	#define MOUSE_EVENT 			 			02h
	#define WINDOW_BUFFER_SIZE_EVENT 			04h
	#define MENU_EVENT 				 			08h
	#define FOCUS_EVENT 			 			10h
	#define ENHANCED_KEY 			 			0100h
	#define ENABLE_PROCESSED_INPUT				01h
	#define ENABLE_LINE_INPUT 					02h
	#define ENABLE_ECHO_INPUT 					04h
	#define ENABLE_WINDOW_INPUT         		08h
	#define ENABLE_QUICK_EDIT_MODE				40h
	#define ENABLE_VIRTUAL_TERMINAL_INPUT		0200h
	#define ENABLE_VIRTUAL_TERMINAL_PROCESSING	04h
	#define DISABLE_NEWLINE_AUTO_RETURN 		08h

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
	#define S_IFDIR		4000h
	#define S_IFREG		8000h
	
	#case [
		any [OS = 'FreeBSD OS = 'macOS OS = 'NetBSD] [
			#define O_CREAT		0200h
			#define O_TRUNC		0400h
			#define O_EXCL		0800h
			#define O_APPEND	8
			#define	O_NONBLOCK	4
			#define	O_CLOEXEC	01000000h
			
			#define DIRENT_NAME_OFFSET 8
		]
		true [	;-- Linux
			#define O_CREAT		64
			#define O_EXCL		128
			#define O_TRUNC		512
			#define O_APPEND	1024
			#define	O_NONBLOCK	2048
			#define	O_CLOEXEC	524288
			#either target = 'ARM [
				#define O_DIRECTORY 4000h
			][
				#define O_DIRECTORY 00010000h
			]
		]
	]
	
	#define BFFM_SETEXPANDED		1130

	#define OS_POLLIN 		1

	#case [
		any [OS = 'macOS OS = 'FreeBSD OS = 'NetBSD] [
			#define TIOCGWINSZ		40087468h
			#define TERM_TCSADRAIN	1
			#define TERM_VTIME		18
			#define TERM_VMIN		17

			#define TERM_BRKINT		02h
			#define TERM_INPCK		10h
			#define TERM_ISTRIP		20h
			#define TERM_ICRNL		0100h
			#define TERM_IXON		0200h
			#define TERM_OPOST		01h
			#define TERM_CS8		0300h
			#define TERM_ISIG		80h
			#define TERM_ICANON		0100h
			#define TERM_ECHO		08h	
			#define TERM_IEXTEN		4000h

			termios!: alias struct! [
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				c_cc1			[integer!]						;-- c_cc[20]
				c_cc2			[integer!]
				c_cc3			[integer!]
				c_cc4			[integer!]
				c_cc5			[integer!]
				c_ispeed		[integer!]
				c_ospeed		[integer!]
			]
		]
		true [													;-- Linux
			#define TIOCGWINSZ		5413h
			#define TERM_VTIME		6
			#define TERM_VMIN		7

			#define TERM_BRKINT		2
			#define TERM_INPCK		20
			#define TERM_ISTRIP		40
			#define TERM_ICRNL		400
			#define TERM_IXON		2000
			#define TERM_OPOST		1
			#define TERM_CS8		60
			#define TERM_ISIG		1
			#define TERM_ICANON		2
			#define TERM_ECHO		10
			#define TERM_IEXTEN		100000

			#either OS = 'Android [
				#define TERM_TCSADRAIN	5403h

				termios!: alias struct! [
					c_iflag			[integer!]
					c_oflag			[integer!]
					c_cflag			[integer!]
					c_lflag			[integer!]
					;c_line			[byte!]
					c_cc1			[integer!]					;-- c_cc[19]
					c_cc2			[integer!]
					c_cc3			[integer!]
					c_cc4			[integer!]
					c_cc5			[integer!]
				]
			][
				#define TERM_TCSADRAIN	1

				termios!: alias struct! [						;-- sizeof(termios) = 60
					c_iflag			[integer!]
					c_oflag			[integer!]
					c_cflag			[integer!]
					c_lflag			[integer!]
					c_line			[byte!]
					c_cc1			[byte!]						;-- c_cc[32]
					c_cc2			[byte!]
					c_cc3			[byte!]
					c_cc4			[integer!]
					c_cc5			[integer!]
					c_cc6			[integer!]
					c_cc7			[integer!]
					c_cc8			[integer!]
					c_cc9			[integer!]
					c_cc10			[integer!]
					pad				[integer!]					;-- for proper alignment
					c_ispeed		[integer!]
					c_ospeed		[integer!]
				]
			]
		]
	]

	pollfd!: alias struct! [
		fd				[integer!]
		events			[integer!]						;-- high 16-bit: events
	]													;-- low  16-bit: revents

	winsize!: alias struct! [
		rowcol			[integer!]
		xypixel			[integer!]
	]

	#either OS = 'Android [
		tcgetattr: func [
			fd		[integer!]
			termios [termios!]
			return: [integer!]
		][
			ioctl fd 5401h as winsize! termios
		]
		tcsetattr: func [
			fd			[integer!]
			opt_actions [integer!]
			termios 	[termios!]
			return: 	[integer!]
		][
			ioctl fd opt_actions as winsize! termios
		]
	][
		#import [
		LIBC-file cdecl [
			tcgetattr: "tcgetattr" [
				fd		[integer!]
				termios [termios!]
				return: [integer!]
			]
			tcsetattr: "tcsetattr" [
				fd			[integer!]
				opt_actions [integer!]
				termios 	[termios!]
				return: 	[integer!]
			]
		]]
	]

	#import [
		LIBC-file cdecl [
			_dup: "dup" [
				fd		[integer!]
				return: [integer!]
			]
			isatty: "isatty" [
				fd		[integer!]
				return:	[integer!]
			]
			read: "read" [
				fd		[integer!]
				buf		[byte-ptr!]
				size	[integer!]
				return: [integer!]
			]
			write: "write" [
				fd		[integer!]
				buf		[byte-ptr!]
				size	[integer!]
				return: [integer!]
			]
			poll: "poll" [
				fds		[pollfd!]
				nfds	[integer!]
				timeout [integer!]
				return: [integer!]
			]
			ioctl: "ioctl" [
				fd		[integer!]
				request	[integer!]
				ws		[winsize!]
				return: [integer!]
			]
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