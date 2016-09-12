Red/System [
	Title:	"Windows classes handling"
	Author: "Nenad Rakocevic"
	File: 	%classes.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ext-class!: alias struct! [
	symbol		[integer!]								;-- symbol ID
	class		[c-string!]								;-- UTF-16 encoded
	ex-styles	[integer!]								;-- extended windows styles
	styles		[integer!]								;-- windows styles
	base-ID		[integer!]								;-- base ID for instances (0: no ID)
	new-proc	[integer!]								;-- optional custom event handler
	old-proc	[integer!]								;-- saved old event handler
	parent-proc [integer!]								;-- optional parent event handler
]

max-ext-styles: 	20
ext-classes:		as ext-class! allocate max-ext-styles * size? ext-class!
ext-cls-tail:		ext-classes							;-- tail pointer
ext-parent-proc?:	no
OldFaceWndProc:		0

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

	arg1: list/value									;@@ TBD: allow struct indexing in R/S
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

	either zero? arg2 [
		arg2: arg1
	][
		old-proc: make-super-class
			as-c-string arg2
			as-c-string arg1
			arg7
			yes
	]

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

	if arg8 <> 0 [ext-parent-proc?: yes]				;-- signal custom parent event handler

	old-proc
]

make-super-class: func [
	new		[c-string!]
	base	[c-string!]
	proc	[integer!]
	system?	[logic!]
	return: [integer!]
	/local
		wcex [WNDCLASSEX]
		old	 [integer!]
		inst [handle!]
][
	wcex: declare WNDCLASSEX
	inst: either system? [null][hInstance]

	if 0 = GetClassInfoEx inst base wcex [
		print-line "*** Error in GetClassInfoEx"
	]
	wcex/cbSize: 		size? WNDCLASSEX
	wcex/cbWndExtra:	wc-extra						;-- reserve extra memory for face! slot
	wcex/hInstance:		hInstance
	wcex/lpszClassName: new
	if proc <> 0 [
		old: as-integer :wcex/lpfnWndProc
		wcex/lpfnWndProc: as wndproc-cb! proc
	]
	RegisterClassEx wcex
	old
]

FaceWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
][
	switch msg [
		WM_LBUTTONDOWN	 [SetCapture hWnd return 0]
		WM_LBUTTONUP	 [ReleaseCapture return 0]
		WM_NCHITTEST	 [return 1]						;-- HTCLIENT
		default [0]
	]
	CallWindowProc as wndproc-cb! OldFaceWndProc hWnd msg wParam lParam
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
	wcex/cbWndExtra:	wc-extra						;-- reserve extra memory for face! slot
	wcex/hInstance:		hInstance
	wcex/hIcon:			LoadIcon hInstance as c-string! 1
	wcex/hCursor:		LoadCursor null IDC_ARROW
	wcex/hbrBackground:	COLOR_3DFACE + 1
	wcex/lpszMenuName:	null
	wcex/lpszClassName: #u16 "RedWindow"
	wcex/hIconSm:		0

	RegisterClassEx wcex

	wcex/style:			CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
	wcex/lpfnWndProc:	:BaseWndProc
	wcex/cbClsExtra:	0
	wcex/cbWndExtra:	wc-extra						;-- reserve extra memory for face! slot
	wcex/hInstance:		hInstance
	wcex/hIcon:			null
	wcex/hCursor:		LoadCursor null IDC_ARROW
	wcex/hbrBackground:	COLOR_3DFACE + 1
	wcex/lpszMenuName:	null
	wcex/lpszClassName: #u16 "RedBase"

	RegisterClassEx wcex

	wcex/style:			CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
	wcex/lpfnWndProc:	:BaseInternalWndProc
	wcex/cbClsExtra:	0
	wcex/cbWndExtra:	wc-extra						;-- reserve extra memory for face! slot
	wcex/hInstance:		hInstance
	wcex/hIcon:			null
	wcex/hCursor:		LoadCursor null IDC_ARROW
	wcex/hbrBackground:	COLOR_3DFACE + 1
	wcex/lpszMenuName:	null
	wcex/lpszClassName: #u16 "RedBaseInternal"

	RegisterClassEx wcex

	wcex/style:			CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
	wcex/lpfnWndProc:	:CameraWndProc
	wcex/cbWndExtra:	wc-extra						;-- reserve extra memory for face! slot
	wcex/hInstance:		hInstance
	wcex/hbrBackground:	COLOR_BACKGROUND + 1
	wcex/lpszClassName: #u16 "RedCamera"

	RegisterClassEx wcex

	;-- superclass existing classes to add 16 extra bytes
	make-super-class #u16 "RedButton"	#u16 "BUTTON"			 0 yes
	make-super-class #u16 "RedField"	#u16 "EDIT"				 0 yes
	make-super-class #u16 "RedCombo"	#u16 "ComboBox"			 0 yes
	make-super-class #u16 "RedListBox"	#u16 "ListBox"			 0 yes
	make-super-class #u16 "RedProgress" #u16 "msctls_progress32" 0 yes
	make-super-class #u16 "RedSlider"	#u16 "msctls_trackbar32" 0 yes
	make-super-class #u16 "RedTabpanel"	#u16 "SysTabControl32"	 0 yes
	make-super-class #u16 "RedPanel"	#u16 "RedWindow"		 0 no

	OldFaceWndProc: make-super-class
		#u16 "RedFace"
		#u16 "STATIC"
		as-integer :FaceWndProc
		yes
]
