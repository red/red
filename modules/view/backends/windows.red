Red [
	Title:	"Windows platoform GUI backend"
	Author: "Nenad Rakocevic"
	File: 	%windows.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system/view/platform: context [

	#system [
		gui: context [
			#include %imports/win32.reds
			
			#enum facet! [
				FACE_OBJ_TYPE
				FACE_OBJ_OFFSET
				FACE_OBJ_SIZE
				FACE_OBJ_TEXT
				FACE_OBJ_IMAGE
				FACE_OBJ_COLOR
				FACE_OBJ_DATA
				FACE_OBJ_VISIBLE?
				FACE_OBJ_SELECTED
				FACE_OBJ_PARENT
				FACE_OBJ_PANE
				FACE_OBJ_STATE
				;FACE_OBJ_RATE
				FACE_OBJ_EDGE
				FACE_OBJ_ACTORS
				FACE_OBJ_EXTRA
			]
			
			#enum event-type! [
				EVT_LEFT_DOWN:		1
				EVT_LEFT_UP
				EVT_MIDDLE_DOWN
				EVT_MIDDLE_UP
				EVT_RIGHT_DOWN
				EVT_RIGHT_UP
				EVT_AUX_DOWN
				EVT_AUX_UP
				EVT_CLICK
				EVT_DBL_CLICK
				EVT_MOVE								;-- last mouse event
				
				EVT_KEY
				EVT_KEY_DOWN
				EVT_KEY_UP
				
				EVT_SELECT
				EVT_CHANGE
			]
			
			#enum event-flag! [
				EVT_FLAG_DBL_CLICK:		10000000h
				EVT_FLAG_CTRL_DOWN:		20000000h
				EVT_FLAG_SHIFT_DOWN:	40000000h
				EVT_FLAG_KEY_DOWN:		80000000h
			]
			
			#enum event-action! [
				EVT_NO_PROCESS							;-- no further msg processing allowed
				EVT_DISPATCH							;-- allow DispatchMessage call only
				EVT_DISPATCH_AND_PROCESS				;-- allow full post-processing of the msg
			]
			
			ext-class!: alias struct! [
				symbol		[integer!]					;-- symbol ID
				class		[c-string!]					;-- UTF-16 encoded
				ex-styles	[integer!]					;-- extended windows styles
				styles		[integer!]					;-- windows styles
				base-ID		[integer!]					;-- base ID for instances (0: no ID)
				new-proc	[integer!]					;-- optional custom event handler
				old-proc	[integer!]					;-- saved old event handler
				parent-proc [integer!]					;-- optional parent event handler
			]
			
			gui-evt: declare red-event!					;-- low-level event value slot
			gui-evt/header: TYPE_EVENT
			
			hScreen:		as handle! 0
			hInstance:		as handle! 0
			default-font:	as handle! 0
			version-info: 	declare OSVERSIONINFO
			current-msg: 	as tagMSG 0
			wc-extra:		80							;-- reserve 64 bytes for win32 internal usage (arbitrary)
			wc-offset:		64							;-- offset to our 16 bytes

			oldGroupBoxWndProc: 0
			
			;-- extended classes handling
			max-ext-styles: 20
			ext-classes:	as ext-class! allocate max-ext-styles * size? ext-class!
			ext-cls-tail:	ext-classes					;-- tail pointer
			ext-parent-proc?:	no

			window:			symbol/make "window"
			button:			symbol/make "button"
			check:			symbol/make "check"
			radio:			symbol/make "radio"
			field:			symbol/make "field"
			text:			symbol/make "text"
			progress:		symbol/make "progress"
			slider:			symbol/make "slider"
			dropdown:		symbol/make "dropdown"
			droplist:		symbol/make "droplist"
			_image:			symbol/make "image"
			base:			symbol/make "base"
			panel:			symbol/make "panel"
			
			done:			symbol/make "done"
			stop:			symbol/make "stop"
				
			_down:			word/load "down"
			_up:			word/load "up"
			_middle-down:	word/load "middle-down"
			_middle-up:		word/load "middle-up"
			_alt-down:		word/load "alt-down"
			_alt-up:		word/load "alt-up"
			_aux-down:		word/load "aux-down"
			_aux-up:		word/load "aux-up"
			_click:			word/load "click"
			_double-click:	word/load "double-click"
			_move:			word/load "move"
			_key:			word/load "key"
			;_key-down:		word/load "key-down"
			_key-up:		word/load "key-up"
			_select:		word/load "select"
			_change:		word/load "change"
			
			_page-up:		word/load "page-up"
			_page_down:		word/load "page-down"
			_end:			word/load "end"
			_home:			word/load "home"
			_left:			word/load "left"
			_up:			word/load "up"
			_right:			word/load "right"
			_down:			word/load "down"
			_insert:		word/load "insert"
			_delete:		word/load "delete"
			_F1:			word/load "F1"
			_F2:			word/load "F2"
			_F3:			word/load "F3"
			_F4:			word/load "F4"
			_F5:			word/load "F5"
			_F6:			word/load "F6"
			_F7:			word/load "F7"
			_F8:			word/load "F8"
			_F9:			word/load "F9"
			_F10:			word/load "F10"
			_F11:			word/load "F11"
			_F12:			word/load "F12"
			
			get-node-facet: func [
				node	[node!]
				facet	[integer!]
				return: [red-value!]
				/local
					ctx	 [red-context!]
					s	 [series!]
			][
				ctx: TO_CTX(node)
				s: as series! ctx/values/value
				s/offset + facet
			]
			
			get-facets: func [
				msg		[tagMSG]
				return: [red-value!]
				/local
					ctx	 [red-context!]
					node [node!]
					s	 [series!]
			][
				node: as node! GetWindowLong get-widget-handle msg wc-offset + 4
				ctx: TO_CTX(node)
				s: as series! ctx/values/value
				s/offset
			]
			
			get-facet: func [
				msg		[tagMSG]
				facet	[integer!]
				return: [red-value!]
			][
				get-node-facet 
					as node! GetWindowLong get-widget-handle msg wc-offset + 4
					facet
			]
			
			get-widget-handle: func [
				msg		[tagMSG]
				return: [handle!]
				/local
					hWnd   [handle!]
					header [integer!]
					p	   [int-ptr!]
			][
				hWnd: msg/hWnd
				header: GetWindowLong hWnd wc-offset
			
				if header and get-type-mask <> TYPE_OBJECT [
					hWnd: GetParent hWnd				;-- for composed widgets (try 1)
					header: GetWindowLong hWnd wc-offset

					if header and get-type-mask <> TYPE_OBJECT [
						hWnd: WindowFromPoint msg/x msg/y	;-- try 2
						header: GetWindowLong hWnd wc-offset

						if header and get-type-mask <> TYPE_OBJECT [
							p: as int-ptr! GetWindowLong hWnd 0	;-- try 3
							hWnd: as handle! p/2
							header: GetWindowLong hWnd wc-offset
							
							if header and get-type-mask <> TYPE_OBJECT [
								hWnd: as handle! -1		;-- not found
							]
						]
					]
				]
				hWnd
			]

			get-event-type: func [
				evt		[red-event!]
				return: [red-value!]
			][
				as red-value! switch evt/type [
					EVT_LEFT_DOWN	 [_down]
					EVT_LEFT_UP		 [_up]
					EVT_MIDDLE_DOWN	 [_middle-down]
					EVT_MIDDLE_UP	 [_middle-up]
					EVT_RIGHT_DOWN	 [_alt-down]
					EVT_RIGHT_UP	 [_alt-up]
					EVT_AUX_DOWN	 [_aux-down]
					EVT_AUX_UP		 [_aux-up]
					EVT_CLICK		 [_click]
					EVT_DBL_CLICK	 [_double-click]
					EVT_MOVE		 [_move]
					EVT_KEY			 [_key]
					;EVT_KEY_DOWN	 [_key-down]
					EVT_KEY_UP		 [_key-up]
					EVT_SELECT	 	 [_select]
					EVT_CHANGE		 [_change]
				]
			]
			
			get-event-face: func [
				evt		[red-event!]
				return: [red-value!]
				/local
					handle [handle!]
					face   [red-object!]
					msg    [tagMSG]
			][
				msg: as tagMSG evt/msg
				handle: get-widget-handle msg
				if handle = as handle! -1 [				;-- filter out unwanted events
					return as red-value! none-value
				]
				
				face: as red-object! stack/push*
				face/header:		  GetWindowLong handle wc-offset
				face/ctx:	 as node! GetWindowLong handle wc-offset + 4
				face/class:			  GetWindowLong handle wc-offset + 8
				face/on-set: as node! GetWindowLong handle wc-offset + 12
				as red-value! face
			]
			
			get-event-offset: func [
				evt		[red-event!]
				return: [red-value!]
				/local
					offset [red-pair!]
					value  [integer!]
					msg    [tagMSG]
			][
				either evt/type <= EVT_MOVE [
					msg: as tagMSG evt/msg

					offset: as red-pair! stack/push*
					offset/header: TYPE_PAIR
					value: msg/lParam

					offset/x: WIN32_LOWORD(value)
					offset/y: WIN32_HIWORD(value)
					as red-value! offset
				][
					as red-value! none-value
				]
			]
			
			get-event-key: func [
				evt		[red-event!]
				return: [red-value!]
				/local
					char [red-char!]
			][
				as red-value! switch evt/type [
					EVT_KEY [
						either evt/flags and EVT_FLAG_KEY_DOWN <> 0 [
							switch evt/flags and FFFFh [
								VK_PRIOR	[_page-up]
								VK_NEXT		[_page_down]
								VK_END		[_end]
								VK_HOME		[_home]
								VK_LEFT		[_left]
								VK_UP		[_up]
								VK_RIGHT	[_right]
								VK_DOWN		[_down]
								VK_INSERT	[_insert]
								VK_DELETE	[_delete]
								VK_F1		[_F1]
								VK_F2		[_F2]
								VK_F3		[_F3]
								VK_F4		[_F4]
								VK_F5		[_F5]
								VK_F6		[_F6]
								VK_F7		[_F7]
								VK_F8		[_F8]
								VK_F9		[_F9]
								VK_F10		[_F10]
								VK_F11		[_F11]
								VK_F12		[_F12]
								default		[none-value]
							]
						][
							char: as red-char! stack/push*
							char/header: TYPE_CHAR
							char/value: evt/flags and FFFFh
							as red-value! char
						]
					]
					default [as red-value! none-value]
				]
			]
			
			get-event-picked: func [
				evt		[red-event!]
				return: [red-value!]
			][
				as red-value! integer/push evt/flags and FFFFh
			]
				
			make-event: func [
				msg		[tagMSG]
				flags	[integer!]
				type	[integer!]
				return: [integer!]
				/local
					res	  [red-word!]
					word  [red-word!]
					sym	  [integer!]
					state [integer!]
					key	  [integer!]
			][
				gui-evt/type:  type
				gui-evt/msg:   as byte-ptr! msg
				gui-evt/flags: 0
				
				state: EVT_DISPATCH_AND_PROCESS
				
				switch type [
					EVT_KEY_DOWN [
						key: msg/wParam and FFFFh
						if key = VK_PROCESSKEY [return EVT_DISPATCH]  ;-- IME-friendly exit
						gui-evt/flags: key or EVT_FLAG_KEY_DOWN
						gui-evt/type: EVT_KEY
						state: EVT_DISPATCH
					]
					EVT_KEY [
						gui-evt/flags: msg/wParam and FFFFh
					]
					EVT_SELECT [
						word: as red-word! get-facet msg FACE_OBJ_TYPE
						assert TYPE_OF(word) = TYPE_WORD
						if word/symbol = dropdown [get-text msg flags]
						gui-evt/flags: flags + 1 and FFFFh	;-- index is one-based for string!
					]
					EVT_CHANGE [
						unless zero? flags [get-text msg -1] ;-- get text if not done already
					]
					default [0]
				]
				;@@ set other flags here
				
				#call [system/view/awake gui-evt]
				
				res: as red-word! stack/arguments
				if TYPE_OF(res) = TYPE_WORD [
					sym: symbol/resolve res/symbol
					case [
						sym = done [state: EVT_DISPATCH]	;-- prevent other high-level events
						sym = stop [state: EVT_NO_PROCESS]	;-- prevent all other events
						true 	   [0]						;-- ignore others
					]
				]
				state
			]
			
			init-current-msg: func [
				/local
					pos [integer!]
			][
				current-msg: declare TAGmsg
				pos: GetMessagePos
				current-msg/x: WIN32_LOWORD(pos)
				current-msg/y: WIN32_HIWORD(pos)
			]

			ImageWndProc: func [
				hWnd	[handle!]
				msg		[integer!]
				wParam	[integer!]
				lParam	[integer!]
				return: [integer!]
				/local
					rect	[RECT_STRUCT]
					width	[integer!]
					height	[integer!]
					hBackDC [handle!]
			][
				switch msg [
					WM_ERASEBKGND [
						hBackDC: as handle! GetWindowLong hWnd wc-offset - 4
						rect: declare RECT_STRUCT
						GetClientRect hWnd rect
						width: rect/right - rect/left
						height: rect/bottom - rect/top
						BitBlt as handle! wParam 0 0 width height hBackDC 0 0 SRCCOPY
						return 1
					]
					default [0]
				]
				DefWindowProc hWnd msg wParam lParam
			]

			GroupBoxWndProc: func [
				hWnd	[handle!]
				msg		[integer!]
				wParam	[integer!]
				lParam	[integer!]
				return: [integer!]
			][
				switch msg [
					WM_VSCROLL
					WM_HSCROLL [
						unless zero? lParam [			;-- message from trackbar
							unless null? current-msg [
								current-msg/hWnd: as handle! lParam	;-- trackbar handle
								get-slider-pos current-msg
								make-event current-msg 0 EVT_CHANGE
								return 0
							]
						]
					]
					default [0]
				]
				CallWindowProc as wndproc-cb! oldGroupBoxWndProc hWnd msg wParam lParam
			]
			
			WndProc: func [
				hWnd	[handle!]
				msg		[integer!]
				wParam	[integer!]
				lParam	[integer!]
				return: [integer!]
				/local
					type   [red-word!]
					idx	   [integer!]
					res	   [integer!]
					color  [integer!]
					handle [handle!]
			][
				switch msg [
					WM_DESTROY [PostQuitMessage 0]
					WM_COMMAND [
						switch WIN32_HIWORD(wParam) [
							BN_CLICKED [
								make-event current-msg 0 EVT_CLICK
								type: as red-word! get-facet current-msg FACE_OBJ_TYPE
								if any [
									type/symbol = check
									type/symbol = radio
								][
									if get-logic-state current-msg [
										make-event current-msg 0 EVT_CHANGE
									]
								]
							]
							EN_CHANGE [					;-- sent also by CreateWindow
								unless null? current-msg [
									current-msg/hWnd: as handle! lParam	;-- force Edit handle
									make-event current-msg -1 EVT_CHANGE
								]
								0
							]
							CBN_SELCHANGE [
								current-msg/hWnd: as handle! lParam	;-- force Combobox handle
								idx: as-integer SendMessage as handle! lParam CB_GETCURSEL 0 0
								res: make-event current-msg idx EVT_SELECT
								get-selected current-msg idx + 1
								if res = EVT_DISPATCH_AND_PROCESS [
									make-event current-msg 0 EVT_CHANGE
								]
							]
							CBN_EDITCHANGE [
								current-msg/hWnd: as handle! lParam	;-- force Combobox handle
								make-event current-msg -1 EVT_CHANGE
							]
							default [0]
						]
					]
					WM_VSCROLL
					WM_HSCROLL [
						unless zero? lParam [			;-- message from trackbar
							current-msg/hWnd: as handle! lParam	;-- trackbar handle
							get-slider-pos current-msg
							make-event current-msg 0 EVT_CHANGE
							return 0
						]
					]
					WM_ERASEBKGND [
						if paint-background hWnd as handle! wParam [return 1]
					]
					WM_CTLCOLORBTN
					WM_CTLCOLOREDIT
					WM_CTLCOLORSTATIC 
					WM_CTLCOLORLISTBOX 
					WM_CTLCOLORSCROLLBAR [
						if null? current-msg [init-current-msg]
						current-msg/hWnd: as handle! lParam	;-- force child handle
						handle: get-widget-handle current-msg
						if handle <> as handle! -1 [
							color: to-bgr as node! GetWindowLong handle wc-offset + 4
							if color <> -1 [
								SetBkMode as handle! wParam BK_TRANSPARENT 
								SetDCBrushColor as handle! wParam color
								return as-integer GetStockObject DC_BRUSH
							]
						]
					]
					default [0]
				]
				if ext-parent-proc? [call-custom-proc hWnd msg wParam lParam]
				
				DefWindowProc hWnd msg wParam lParam
			]
			
			pre-process: func [
				msg		[tagMSG]
				return: [integer!]
				/local
					wParam [integer!]
			][
				switch msg/msg [
					WM_LBUTTONDOWN	[make-event msg 0 EVT_LEFT_DOWN]
					WM_LBUTTONUP	[make-event msg 0 EVT_LEFT_UP]
					WM_RBUTTONDOWN	[make-event msg 0 EVT_RIGHT_DOWN]
					WM_RBUTTONUP	[make-event msg 0 EVT_RIGHT_UP]
					WM_MBUTTONDOWN	[make-event msg 0 EVT_MIDDLE_DOWN]
					WM_MBUTTONUP	[make-event msg 0 EVT_MIDDLE_UP]
					WM_HSCROLL [
						get-slider-pos msg
						make-event current-msg 0 EVT_CHANGE
					]
					WM_KEYDOWN		[make-event msg 0 EVT_KEY_DOWN]
					WM_SYSKEYUP
					WM_KEYUP		[make-event msg 0 EVT_KEY_UP]
					WM_SYSKEYDOWN	[
						make-event msg 0 EVT_KEY_DOWN
						EVT_NO_PROCESS
					]
					WM_LBUTTONDBLCLK [
						make-event msg 0 EVT_DBL_CLICK
						EVT_DISPATCH_AND_PROCESS
					]
					;WM_DESTROY []
					default			[EVT_DISPATCH_AND_PROCESS]
				]
			]
			
			post-process: func [
				msg	[tagMSG]
				/local
					wParam [integer!]
			][
				switch msg/msg [
					WM_CHAR [make-event msg 0 EVT_KEY]
					default [0]
				]
			]

			do-events: func [
				no-wait? [logic!]
				/local
					msg	  [tagMSG]
					state [integer!]
			][
				msg: declare tagMSG

				while [0 < GetMessage msg null 0 0][
					TranslateMessage msg
					state: pre-process msg
					if state >= EVT_DISPATCH [
						current-msg: msg
						DispatchMessage msg
						if state = EVT_DISPATCH_AND_PROCESS [
							post-process msg
						]
					]
					if no-wait? [exit]
				]
			]
			
			enable-visual-styles: func [
				return: [byte-ptr!]
				/local
					ctx	   [ACTCTX]
					dir	   [c-string!]
					ret	   [integer!]
					cookie [struct! [ptr [byte-ptr!]]]
			][
				ctx: declare ACTCTX
				cookie: declare struct! [ptr [byte-ptr!]]
				dir: as-c-string allocate 258				;-- 128 UTF-16 codepoints + 2 NUL

				ctx/cbSize:		 size? ACTCTX
				ctx/dwFlags: 	 ACTCTX_FLAG_RESOURCE_NAME_VALID
					or ACTCTX_FLAG_SET_PROCESS_DEFAULT
					or ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID

				ctx/lpSource: 	 #u16 "shell32.dll"
				ctx/wProcLangID: 0
				ctx/lpAssDir: 	 dir
				ctx/lpResource:	 as-c-string 124		;-- Manifest ID in the DLL

				sz: GetSystemDirectory dir 128
				if sz > 128 [probe "*** GetSystemDirectory: buffer overflow"]
				sz: sz + 1
				dir/sz: null-byte

				ActivateActCtx CreateActCtx ctx cookie
				cookie/ptr
			]
			
			to-bgr: func [
				node	[node!]
				return: [integer!]						;-- 00bbggrr format or -1 if not found
			][
				color: as red-tuple! get-node-facet node FACE_OBJ_COLOR
				either TYPE_OF(color) = TYPE_TUPLE [
					color/array1 and 00FFFFFFh
				][
					-1
				]
			]
			
			paint-background: func [
				hWnd	[handle!]
				hDC		[handle!]
				return: [logic!]
				/local
					rect   [RECT_STRUCT]
					hBrush [handle!]
					color  [integer!]
			][
				color: to-bgr as node! GetWindowLong hWnd wc-offset + 4
				if color = -1 [return false]
				
				hBrush: CreateSolidBrush color
				rect: declare RECT_STRUCT
				GetClientRect hWnd rect
				FillRect hDC rect hBrush
				DeleteObject hBrush
				true
			]
			
			call-custom-proc: func [
				hWnd	[handle!]
				msg		[integer!]
				wParam	[integer!]
				lParam	[integer!]
				/local
					p	 [ext-class!]
					proc [wndproc-cb!]
			][
				p: ext-classes
				while [p < ext-cls-tail][
					proc: as wndproc-cb! p/parent-proc
					unless null? :proc [proc hWnd msg wParam lParam]
					p: p + 1
				]
			]
			
			find-class: func [
				name	[red-word!]
				return: [ext-class!]
				/local
					sym [integer!]
					p	[ext-class!]
			][
				sym: symbol/resolve name/symbol
				p: ext-classes
				while [p < ext-cls-tail][
					if p/symbol = sym [return p]
					p: p + 1
				]
				print-line "gui/find-class failed"
				null
			]
			
			register-class: func [
				[typed]
				count	[integer!]
				list	[typed-value!]
				return: [integer!]
				/local
					p		 [ext-class!]
					old-proc [integer!]
					arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8
			][
				if count <> 8 [print-line "gui/register-class error: invalid spec block"]
				
				arg1: list/value						;@@ TBD: allow struct indexing in R/S
				list: list + 1
				arg2: list/value
				list: list + 1
				arg3: list/value
				list: list + 1
				arg4: list/value
				list: list + 1
				arg5: list/value
				list: list + 1
				arg6: list/value
				list: list + 1
				arg7: list/value
				list: list + 1
				arg8: list/value
				
				old-proc: make-super-class
					as-c-string arg2
					as-c-string arg1
					arg7
				
				p: ext-cls-tail
				ext-cls-tail: ext-cls-tail + 1
				assert ext-classes + max-ext-styles > ext-cls-tail

				p/symbol:		arg3
				p/class:		as-c-string arg2
				p/ex-styles:	arg4
				p/styles:		arg5
				p/base-id:		arg6
				p/new-proc:		arg7
				p/old-proc:		old-proc
				p/parent-proc:	arg8
				
				if arg8 <> 0 [ext-parent-proc?: yes]	;-- signal custom parent event handler
				
				old-proc
			]
			
			make-super-class: func [
				new		[c-string!]
				base	[c-string!]
				proc	[integer!]
				return: [integer!]
				/local
					wcex [WNDCLASSEX]
					old	 [integer!]
			][
				wcex: declare WNDCLASSEX
				 
				if 0 = GetClassInfoEx 0 base wcex [
					print-line "*** Error in GetClassInfoEx"
				]
				wcex/cbSize: 		size? WNDCLASSEX
				wcex/cbWndExtra:	wc-extra				;-- reserve extra memory for face! slot
				wcex/hInstance:		hInstance
				wcex/lpszClassName: new
				if proc <> 0 [
					old: as-integer :wcex/lpfnWndProc
					wcex/lpfnWndProc: as wndproc-cb! proc
				]
				RegisterClassEx wcex
				old
			]

			register-classes: func [
				hInstance [handle!]
				/local
					wcex  [WNDCLASSEX]
			][
				wcex: declare WNDCLASSEX

				wcex/cbSize: 		size? WNDCLASSEX
				wcex/style:			CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
				wcex/lpfnWndProc:	:WndProc
				wcex/cbClsExtra:	0
				wcex/cbWndExtra:	wc-extra				;-- reserve extra memory for face! slot
				wcex/hInstance:		hInstance
				wcex/hIcon:			null
				wcex/hCursor:		LoadCursor null IDC_ARROW
				wcex/hbrBackground:	COLOR_WINDOW
				wcex/lpszMenuName:	null
				wcex/lpszClassName: #u16 "RedWindow"
				wcex/hIconSm:		0

				RegisterClassEx wcex
				
				wcex/style:			CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
				;wcex/lpfnWndProc:	:WndProc
				wcex/cbClsExtra:	0
				wcex/cbWndExtra:	wc-extra				;-- reserve extra memory for face! slot
				wcex/hInstance:		hInstance
				wcex/hIcon:			null
				wcex/hCursor:		LoadCursor null IDC_ARROW
				wcex/hbrBackground:	13
				wcex/lpszMenuName:	null
				wcex/lpszClassName: #u16 "Base"
				wcex/hIconSm:		0

				RegisterClassEx wcex

				wcex/style:			CS_DBLCLKS
				wcex/lpfnWndProc:	:ImageWndProc
				wcex/cbWndExtra:	wc-extra				;-- reserve extra memory for face! slot
				wcex/hInstance:		hInstance
				wcex/lpszClassName: #u16 "RedImage"

				RegisterClassEx wcex

				;-- superclass existing classes to add 16 extra bytes
				make-super-class #u16 "RedButton"	#u16 "BUTTON"			 0
				make-super-class #u16 "RedField"	#u16 "EDIT"				 0
				make-super-class #u16 "RedFace"		#u16 "STATIC"			 0
				make-super-class #u16 "RedCombo"	#u16 "ComboBox"			 0
				make-super-class #u16 "RedProgress" #u16 "msctls_progress32" 0
				make-super-class #u16 "RedSlider"	#u16 "msctls_trackbar32" 0
				
				oldGroupBoxWndProc: make-super-class 
					#u16 "RedPanel"
					#u16 "BUTTON"
					as-integer :GroupBoxWndProc
				
			]
			
			init: func [
				/local
					ver  [red-tuple!]
					int	 [red-integer!]
					ctrs [INITCOMMONCONTROLSEX]
			][
				hScreen: GetDC null
				hInstance: GetModuleHandle 0
				default-font: GetStockObject DEFAULT_GUI_FONT
				
				version-info/dwOSVersionInfoSize: size? OSVERSIONINFO
				GetVersionEx version-info
				ver: as red-tuple! #get system/view/platform/version

				ver/header: TYPE_TUPLE or (3 << 19)
				ver/array1: version-info/dwMajorVersion
					or (version-info/dwMinorVersion << 8)
					and 0000FFFFh
				
				unless all [
					version-info/dwMajorVersion = 5
					version-info/dwMinorVersion <= 1
				][
					enable-visual-styles				;-- not called for WinXP and Win2000
				]
				
				ctrls: declare INITCOMMONCONTROLSEX
				ctrls/dwSize: size? INITCOMMONCONTROLSEX
				ctrls/dwICC: ICC_STANDARD_CLASSES
				InitCommonControlsEx ctrls
				
				register-classes hInstance
					
				int: as red-integer! #get system/view/platform/build
				int/header: TYPE_INTEGER
				int/value:  version-info/dwBuildNumber
				
				int: as red-integer! #get system/view/platform/product
				int/header: TYPE_INTEGER
				int/value:  as-integer version-info/wProductType
			]
			
			set-logic-state: func [
				hWnd   [handle!]
				state  [red-logic!]
				check? [logic!]
				/local
					value [integer!]
			][
				value: either TYPE_OF(state) <> TYPE_LOGIC [
					either check? [BST_INDETERMINATE][false]
				][
					as-integer state/value				;-- returns 0/1, matches the messages
				]
				SendMessage hWnd BM_SETCHECK value 0
			]
			
			get-logic-state: func [
				msg		[tagMSG]
				return: [logic!]						;-- TRUE if state has changed
				/local
					bool  [red-logic!]
					state [integer!]
					otype [integer!]
					obool [logic!]
			][
				bool: as red-logic! get-facet msg FACE_OBJ_DATA
				state: as-integer SendMessage msg/hWnd BM_GETCHECK 0 0
				
				either state = BST_INDETERMINATE [
					otype: TYPE_OF(bool)
					bool/header: TYPE_NONE				;-- NONE indicates undeterminate
					bool/header <> otype
				][
					obool: bool/value
					bool/value: state = BST_CHECKED
					bool/value <> obool
				]
			]
			
			get-selected: func [
				msg [tagMSG]
				idx [integer!]
				/local
					int [red-integer!]
			][
				int: as red-integer! get-facet msg FACE_OBJ_SELECTED
				int/value: idx
			]
			
			get-text: func [
				msg	[tagMSG]
				idx	[integer!]
				/local
					size	[integer!]
					str		[red-string!]
					out		[c-string!]
			][
				size: as-integer either idx = -1 [
					SendMessage msg/hWnd WM_GETTEXTLENGTH idx 0
				][
					SendMessage msg/hWnd CB_GETLBTEXTLEN idx 0
				]
				if size >= 0 [
					str: as red-string! get-facet msg FACE_OBJ_TEXT
					if TYPE_OF(str) <> TYPE_STRING [
						string/make-at as red-value! str size UCS-2
					]
					if size = 0 [
						string/rs-reset str
						exit
					]
					out: unicode/get-cache str size + 1 * 4	;-- account for surrogate pairs and terminal NUL
					
					either idx = -1 [
						SendMessage msg/hWnd WM_GETTEXT size + 1 as-integer out  ;-- account for NUL
					][
						SendMessage msg/hWnd CB_GETLBTEXT idx as-integer out
					]
					unicode/load-utf16 null size str
				]
			]

			get-position-value: func [
				pos		[red-float!]
				maximun [integer!]
				return: [integer!]
				/local
					f	[float!]
			][
				f: 0.0
				if any [
					TYPE_OF(pos) = TYPE_FLOAT
					TYPE_OF(pos) = TYPE_PERCENT
				][
					f: pos/value * (integer/to-float maximun)
				]
				float/to-integer f
			]

			get-slider-pos: func [
				msg	[tagMSG]
				/local
					values	[red-value!]
					size	[red-pair!]
					pos		[red-float!]
					int		[integer!]
					divisor [integer!]
			][
				values: get-facets msg
				size:	as red-pair!	values + FACE_OBJ_SIZE
				pos:	as red-float!	values + FACE_OBJ_DATA
				
				if all [
					TYPE_OF(pos) <> TYPE_FLOAT
					TYPE_OF(pos) <> TYPE_PERCENT
				][
					percent/rs-make-at as red-value! pos 0.0
				]
				int: as-integer SendMessage msg/hWnd TBM_GETPOS 0 0
				divisor: size/x
				if size/y > size/x [divisor: size/y int: divisor - int]
				pos/value: (integer/to-float int) / (integer/to-float divisor)
			]

			get-screen-size: func [
				id		[integer!]						;@@ Not used yet
				return: [red-pair!]
			][
				pair/push 
					GetDeviceCaps hScreen HORZRES
					GetDeviceCaps hScreen VERTRES
			]

			make-image-dc: func [
				hWnd		[handle!]
				img			[red-image!]
				return:		[integer!]
				/local
					graphic [integer!]
					rect	[RECT_STRUCT]
					width	[integer!]
					height	[integer!]
					hDC		[handle!]
					hBitmap [handle!]
					hBackDC [handle!]
			][
				graphic: 0
				rect: declare RECT_STRUCT

				GetClientRect hWnd rect
				width: rect/right - rect/left
				height: rect/bottom - rect/top

				hDC: GetDC hWnd
				hBackDC: CreateCompatibleDC hDC
				hBitmap: CreateCompatibleBitmap hDC width height
				SelectObject hBackDC hBitmap
				FillRect hBackDC rect GetSysColorBrush COLOR_MENU
				GdipCreateFromHDC hBackDC :graphic
				GdipDrawImageRectI graphic as-integer img/node 0 0 width height
				ReleaseDC hWnd hDC

				as-integer hBackDC
			]
			OS-show-window: func [
				hWnd [integer!]
			][
				ShowWindow as handle! hWnd SW_SHOWDEFAULT
				UpdateWindow as handle! hWnd
			]

			OS-make-view: func [
				face	[red-object!]
				parent	[integer!]
				return: [integer!]
				/local
					ctx		  [red-context!]
					values	  [red-value!]
					type	  [red-word!]
					str		  [red-string!]
					tail	  [red-string!]
					offset	  [red-pair!]
					size	  [red-pair!]
					data	  [red-block!]
					int		  [red-integer!]
					img		 [red-image!]
					show?	  [red-logic!]
					flags	  [integer!]
					ws-flags  [integer!]
					sym		  [integer!]
					class	  [c-string!]
					caption   [c-string!]
					offx	  [integer!]
					offy	  [integer!]
					value	  [integer!]
					p		  [ext-class!]
					id		  [integer!]
					vertical? [logic!]
			][
				ctx: GET_CTX(face)
				s: as series! ctx/values/value
				values: s/offset
				
				type:	as red-word!	values + FACE_OBJ_TYPE
				str:	as red-string!	values + FACE_OBJ_TEXT
				offset: as red-pair!	values + FACE_OBJ_OFFSET
				size:	as red-pair!	values + FACE_OBJ_SIZE
				show?:	as red-logic!	values + FACE_OBJ_VISIBLE?
				data:	as red-block!	values + FACE_OBJ_DATA
				img:	as red-image!	values + FACE_OBJ_IMAGE
				
				flags: 	  WS_CHILD
				ws-flags: 0
				id:		  0
				sym: 	  symbol/resolve type/symbol
				offx:	  offset/x
				offy:	  offset/y

				if show?/value [flags: flags or WS_VISIBLE]

				case [
					sym = button [
						class: #u16 "RedButton"
						;flags: flags or BS_PUSHBUTTON
					]
					sym = check [
						class: #u16 "RedButton"
						flags: flags or WS_TABSTOP or BS_AUTOCHECKBOX
					]
					sym = radio [
						class: #u16 "RedButton"
						flags: flags or WS_TABSTOP or BS_AUTORADIOBUTTON
					]
					sym = panel [
						class: #u16 "RedPanel"
						flags: flags or WS_GROUP or BS_GROUPBOX
					]
					sym = field [
						class: #u16 "RedField"
						flags: flags or ES_LEFT
						ws-flags: WS_TABSTOP or WS_EX_CLIENTEDGE
					]
					sym = text [
						class: #u16 "RedFace"
						flags: flags or SS_SIMPLE
					]
					sym = dropdown [
						class: #u16 "RedCombo"
						flags: flags or CBS_DROPDOWN or CBS_HASSTRINGS ;or WS_OVERLAPPED
					]
					sym = droplist [
						class: #u16 "RedCombo"
						flags: flags or CBS_DROPDOWNLIST or CBS_HASSTRINGS ;or WS_OVERLAPPED
					]
					sym = progress [
						class: #u16 "RedProgress"
						if size/y > size/x [flags: flags or PBS_VERTICAL]
					]
					sym = slider [
						class: #u16 "RedSlider"
						if size/y > size/x [
							flags: flags or TBS_VERT or TBS_DOWNISLEFT
						]
					]
					sym = _image [
						class: #u16 "RedImage"
					]
					sym = base [
						class: #u16 "Base"
					]
					sym = window [
						class: #u16 "RedWindow"
						flags: WS_OVERLAPPEDWINDOW ;or WS_CLIPCHILDREN
						offx:  CW_USEDEFAULT
						offy:  CW_USEDEFAULT
					]
					true [								;-- search in user-defined classes
						p: find-class type
						class: p/class
						ws-flags: ws-flags or p/ex-styles
						flags: flags or p/styles
						id: p/base-id
					]
				]

				caption: either TYPE_OF(str) = TYPE_STRING [
					unicode/to-utf16 str
				][
					null
				]

				if all [								;-- only for WinXP and Win2000
					version-info/dwMajorVersion = 5
					version-info/dwMinorVersion <= 1
				][
					ws-flags: ws-flags or WS_EX_COMPOSITED		;-- this flag conflicts with DWM
				]

				handle: CreateWindowEx
					ws-flags
					class
					caption
					flags
					offx
					offy
					size/x
					size/y
					as int-ptr! parent
					as handle! id
					hInstance
					null
				
				if null? handle [print-line "*** Error: CreateWindowEx failed!"]
				SendMessage handle WM_SETFONT as-integer default-font 1
				
				;-- extra initialization
				case [
					sym = _image [
						if TYPE_OF(img) <> TYPE_IMAGE [
							if any [
								TYPE_OF(data) = TYPE_BLOCK
								TYPE_OF(data) = TYPE_HASH
								TYPE_OF(data) = TYPE_MAP
							][
								str:  as red-string! block/rs-head as red-block! data
								tail: as red-string! block/rs-tail as red-block! data
								while [str < tail][
									if TYPE_OF(str) = TYPE_FILE [
										image/make-at as red-value! img str
									]
									str: str + 1
								]
							]
						]
						SetWindowLong handle wc-offset - 4 make-image-dc handle img
					]
					sym = slider [
						vertical?: size/y > size/x
						value: either vertical? [size/y][size/x]
						SendMessage handle TBM_SETRANGE 1 value << 16
						value: get-position-value as red-float! data value
						if vertical? [value: size/y - value]
						SendMessage handle TBM_SETPOS 1 value
					]
					sym = progress [
						value: get-position-value as red-float! data 100
						SendMessage handle PBM_SETPOS value 0
					]
					sym = check [set-logic-state handle as red-logic! data yes]
					sym = radio [set-logic-state handle as red-logic! data no]
					any [
						sym = dropdown
						sym = droplist
					][
						if any [
							TYPE_OF(data) = TYPE_BLOCK
							TYPE_OF(data) = TYPE_HASH
							TYPE_OF(data) = TYPE_MAP
						][
							str:  as red-string! block/rs-head as red-block! data
							tail: as red-string! block/rs-tail as red-block! data
							while [str < tail][
								if TYPE_OF(str) = TYPE_STRING [
									SendMessage 
										handle
										CB_ADDSTRING
										0
										as-integer unicode/to-utf16 str
								]
								str: str + 1
							]
						]
						either any [null? caption sym = droplist][
							int: as red-integer! get-node-facet face/ctx FACE_OBJ_SELECTED
							if TYPE_OF(int) = TYPE_INTEGER [
								SendMessage handle CB_SETCURSEL int/value - 1 0
							]
						][
							SetWindowText handle caption
						]
					]
					true [0]
				]
				
				;-- store the face value in the extra space of the window struct
				SetWindowLong handle wc-offset		  		   face/header
				SetWindowLong handle wc-offset + 4  as-integer face/ctx
				SetWindowLong handle wc-offset + 8  		   face/class
				SetWindowLong handle wc-offset + 12 as-integer face/on-set
				
				as-integer handle
			]
		]
	]
	
	get-facet-id: routine [
		facet	[word!]
		return: [integer!]
	][
		assert facet/index <> -1
		1 << facet/index
	]
	
	change-size: routine [
		hWnd [integer!]
		size [pair!]
	][
		gui/SetWindowPos 
			as handle! hWnd
			as handle! 0
			0 0
			size/x size/y 
			SWP_NOMOVE or SWP_NOZORDER
	]
	
	change-offset: routine [
		hWnd [integer!]
		pos  [pair!]
	][
		gui/SetWindowPos 
			as handle! hWnd
			as handle! 0
			pos/x pos/y
			0 0
			SWP_NOSIZE or SWP_NOZORDER
	]
	
	change-text: routine [
		hWnd [integer!]
		str  [string!]
		/local
			text [c-string!]
	][
		text: null
		switch TYPE_OF(str) [
			TYPE_STRING [text: unicode/to-utf16 str]
			TYPE_NONE	[text: #u16 "^@"]
			default		[0]								;@@ Auto-convert?
		]
		unless null? text [gui/SetWindowText as handle! hWnd text]
	]
	
	change-visible: routine [
		hWnd  [integer!]
		show? [logic!]
		/local
			value [integer!]
	][
		value: either show? [SW_SHOW][SW_HIDE]
		gui/ShowWindow as handle! hWnd value
	]
	
	change-selection: routine [
		hWnd [integer!]
		idx  [integer!]
	][
		gui/SendMessage as handle! hWnd CB_SETCURSEL idx - 1 0
	]

	change-data: routine [
		hWnd [integer!]
		data [any-type!]
		type [word!]
		/local
			f [red-float!]
	][
		case [
			all [
				type/symbol = gui/progress
				TYPE_OF(data) = TYPE_PERCENT
			][
				f: as red-float! data
				gui/SendMessage as handle! hWnd PBM_SETPOS float/to-integer f/value * 100.0 0
			]
			type/symbol = gui/check [
				gui/set-logic-state as handle! hWnd as red-logic! data yes
			]
			type/symbol = gui/radio [
				gui/set-logic-state as handle! hWnd as red-logic! data no
			]
			true [0]									;-- default, do nothing
		]
	]

	get-screen-size: routine [
		id		[integer!]
		/local
			pair [red-pair!]
	][
		pair: gui/get-screen-size id
		SET_RETURN(pair)
	]
	
	update-view: routine [
		face [object!]
		/local
			ctx		[red-context!]
			values	[red-value!]
			state	[red-block!]
			int		[red-integer!]
			int2	[red-integer!]
			bool	[red-logic!]
			s		[series!]
			hWnd	[integer!]
			flags	[integer!]
	][
		ctx: GET_CTX(face)
		s: as series! ctx/values/value
		values: s/offset
		
		state: as red-block! values + gui/FACE_OBJ_STATE
		s: GET_BUFFER(state)
		int: as red-integer! s/offset
		hWnd: int/value
		int: int + 1
		flags: int/value
		
		if flags and 00000002h <> 0 [
			change-offset hWnd as red-pair! values + gui/FACE_OBJ_OFFSET
		]
		if flags and 00000004h <> 0 [
			change-size hWnd as red-pair! values + gui/FACE_OBJ_SIZE
		]
		if flags and 00000008h <> 0 [
			change-text hWnd as red-string! values + gui/FACE_OBJ_TEXT
		]
		if flags and 00000080h <> 0 [
			bool: as red-logic! values + gui/FACE_OBJ_VISIBLE?
			change-visible hWnd bool/value
		]
		if flags and 00000100h <> 0 [
			int2: as red-integer! values + gui/FACE_OBJ_SELECTED
			change-selection hWnd int2/value
		]
		if flags and 00000040h <> 0 [
			change-data
				hWnd 
				values + gui/FACE_OBJ_DATA
				as red-word! values + gui/FACE_OBJ_TYPE
		]
		int/value: 0									;-- reset flags
	]
	
	show-window: routine [id [integer!]][gui/OS-show-window id]

	make-view: routine [
		face	[object!]
		parent	[integer!]
		return: [integer!]
	][
		gui/OS-make-view face parent
	]

	do-event-loop: routine [no-wait? [logic!]][
		print-line "do-event-loop"
		gui/do-events no-wait?
	]
	
	init: has [svs][
		#system [gui/init]
		
		system/view/metrics/dpi: 94						;@@ Needs to be calculated
		system/view/screens: svs: make block! 6
		
		append svs make face! [							;-- default screen
			name:	none
			type:	'screen
			offset: 0x0
			size:	get-screen-size 0
			pane:	make block! 4
		]		
	]
	
	version: none
	build:	 none
	product: none
]
