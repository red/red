Red/System [
	Title:	"Windows Camera widget"
	Author: "Xie Qingtian"
	File: 	%camera.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define VFW_S_NOPREVIEWPIN		0004027Eh

CLSID_SystemDeviceEnum:			[62BE5D10h 11D060EBh A0003BBDh 86CE11C9h]
CLSID_VideoInputDeviceCategory: [860BB310h 11D05D01h A0003BBDh 86CE11C9h]
CLSID_CaptureGraphBuilder2:		[BF87B6E1h 11D08C27h AA00F0B3h C5613700h]
CLSID_FilterGraph:				[E436EBB3h 11CE524Fh 2000539Fh 70A70BAFh]

IID_ICreateDevEnum:				[29840822h 11D05B84h A0003BBDh 86CE11C9h]
IID_IPropertyBag: 				[55272A00h 11CE42CBh AA003581h 51B84B00h]
IID_IBaseFilter:				[56A86895h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_ICaptureGraphBuilder2:		[93E5A4E0h 11D22D50h A000FAABh 8DE3C6C9h]
IID_IGraphBuilder:				[56A868A9h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_IVideoWindow:				[56A868B4h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_IMediaControl:				[56A868B1h 11CE0AD4h 20003AB0h 70A70BAFh]

PIN_CATEGORY_PREVIEW:			[FB6C4282h 11D10353h 00005F90h BA16CCC0h]
MEDIATYPE_Video:				[73646976h 00100000h AA000080h 719B3800h]
MEDIATYPE_Interleaved:			[73766169h 00100000h AA000080h 719B3800h]

ICaptureGraphBuilder2: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	SetFiltergraph			[function! [this [this!] pfg [this!] return: [integer!]]]
	GetFiltergraph			[integer!]
	SetOutputFileName		[integer!]
	FindInterface			[integer!]
	RenderStream			[RenderStream!]
	ControlStream			[integer!]
	AllocCapFile			[integer!]
	CopyCaptureFile			[integer!]
	FindPin					[integer!]
]

IGraphBuilder: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	AddFilter				[function! [this [this!] pFilter [this!] pName [c-string!] return: [integer!]]]
]

IMediaControl: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	GetTypeInfoCount		[integer!]
	GetTypeInfo				[integer!]
	GetIDsOfNames			[integer!]
	Invoke					[integer!]
	Run						[function! [this [this!] return: [integer!]]]
	Pause					[function! [this [this!] return: [integer!]]]
	Stop					[function! [this [this!] return: [integer!]]]
	GetState				[integer!]
	RenderFile				[integer!]
	;... other funcs we don't use
]

IVideoWindow: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	GetTypeInfoCount		[integer!]
	GetTypeInfo				[integer!]
	GetIDsOfNames			[integer!]
	Invoke					[integer!]
	put_Caption				[integer!]
	get_Caption				[integer!]
	put_WindowStyle			[function! [this [this!] style [integer!] return: [integer!]]]
	get_WindowStyle			[integer!]
	put_WindowStyleEx		[integer!]
	get_WindowStyleEx		[integer!]
	put_AutoShow			[integer!]
	get_AutoShow			[integer!]
	put_WindowState			[integer!]
	get_WindowState			[integer!]
	put_BackgroundPalette	[integer!]
	get_BackgroundPalette	[integer!]
	put_Visible				[function! [this [this!] show? [integer!] return: [integer!]]]
	get_Visible				[integer!]
	put_Left				[integer!]
	get_Left				[integer!]
	put_Width				[integer!]
	get_Width				[integer!]
	put_Top					[integer!]
	get_Top					[integer!]
	put_Height				[integer!]
	get_Height				[integer!]
	put_Owner				[function! [this [this!] hWnd [int-ptr!] return: [integer!]]]
	get_Owner				[integer!]
	put_MessageDrain		[integer!]
	get_MessageDrain		[integer!]
	get_BorderColor			[integer!]
	put_BorderColor			[integer!]
	get_FullScreenMode		[integer!]
	put_FullScreenMode		[integer!]
	SetWindowForeground		[integer!]
	NotifyOwnerMessage		[integer!]
	SetWindowPosition		[function! [this [this!] left [integer!] top [integer!] width [integer!] height [integer!] return: [integer!]]]
	GetWindowPosition		[integer!]
	GetMinIdealImageSize	[integer!]
	GetMaxIdealImageSize	[integer!]
	GetRestorePosition		[integer!]
	HideCursor				[integer!]
	IsCursorHidden			[integer!]
]

camera!: alias struct! [
	builder		[this!]
	graph		[this!]
	v-filter	[this!]
	window		[this!]
	dev1		[this!]
	dev2		[this!]
	dev3		[this!]
	dev4		[this!]
	dev5		[this!]
	dev6		[this!]
	dev7		[this!]
	dev8		[this!]
]

init-camera: func [
	hWnd	[handle!]
	data	[red-block!]
	open?	[logic!]
	/local
		cam [camera!]
		val [integer!] 
][
	cam: as camera! allocate size? camera!				;@@ need to be freed
	val: collect-camera cam data
	either zero? val [free as byte-ptr! cam][
		init-graph cam 0
		build-preview-graph cam hWnd
		toggle-preview hWnd open?
	]
	SetWindowLong hWnd wc-offset - 4 val
]

free-graph: func [cam [camera!] /local interface [IUnknown]][
	COM_SAFE_RELEASE(interface cam/builder)
	COM_SAFE_RELEASE(interface cam/graph)
	COM_SAFE_RELEASE(interface cam/v-filter)
]

teardown-graph: func [cam [camera!] /local w [IVideoWindow]][
	unless cam/window = null [
		w: as IVideoWindow cam/window/vtbl
		w/put_Owner cam/window null
		w/put_Visible cam/window 0
		w/Release cam/window
		cam/window: null
	]
]

stop-camera: func [handle [handle!] /local cam [camera!]][
	cam: as camera! GetWindowLong handle wc-offset - 4
	unless null? cam [
		teardown-graph cam
		free-graph cam
	]
]

init-graph: func [
	cam		[camera!]
	idx		[integer!]
	/local
		IB		[interface!]
		IG		[interface!]
		ICap	[interface!]
		graph	[IGraphBuilder]
		moniker [IMoniker]
		builder [ICaptureGraphBuilder2]
		hr		[integer!]
		dev-ptr [int-ptr!]
		dev		[this!]
][
	IB:   declare interface!
	IG:   declare interface!
	ICap: declare interface!

	hr: CoCreateInstance CLSID_CaptureGraphBuilder2 0 1 IID_ICaptureGraphBuilder2 IB
	builder: as ICaptureGraphBuilder2 IB/ptr/vtbl
	cam/builder: IB/ptr

	hr: CoCreateInstance CLSID_FilterGraph 0 CLSCTX_INPROC IID_IGraphBuilder IG
	graph: as IGraphBuilder IG/ptr/vtbl
	cam/graph: IG/ptr

	hr: builder/SetFiltergraph IB/ptr IG/ptr
	if hr <> 0 [probe "Cannot give graph to builder"]

	dev-ptr: (as int-ptr! cam) + 4 + idx
	dev: as this! dev-ptr/value
	moniker: as IMoniker dev/vtbl

	hr: moniker/BindToObject dev 0 0 IID_IBaseFilter ICap
	hr: graph/AddFilter IG/ptr ICap/ptr null
	cam/v-filter: either zero? hr [ICap/ptr][
		print-line ["Error " hr ": Cannot add videocap to filtergraph"]
		null
	]
]

build-preview-graph: func [
	cam 		[camera!]
	hWnd		[handle!]
	return:		[integer!]
	/local
		filter	[this!]
		IVM		[interface!]
		graph	[IGraphBuilder]
		builder [ICaptureGraphBuilder2]
		video	[IVideoWindow]
		hr		[integer!]
		rect	[RECT_STRUCT]
][
	builder: as ICaptureGraphBuilder2 cam/builder/vtbl
	graph:   as IGraphBuilder cam/graph/vtbl
	filter:  as this! cam/v-filter
	IVM:	 declare interface!

	hr: builder/RenderStream cam/builder PIN_CATEGORY_PREVIEW MEDIATYPE_Interleaved filter null null
	case [
		hr = VFW_S_NOPREVIEWPIN [1]
		hr <> 0 [
			hr: builder/RenderStream cam/builder PIN_CATEGORY_PREVIEW MEDIATYPE_Video filter null null
			case [
				hr = VFW_S_NOPREVIEWPIN [1]
				hr <> 0 [probe "This device cannot preview!" return -1]
				true [1]
			]
		]
		true [1]
	]
	hr: graph/QueryInterface cam/graph IID_IVideoWindow IVM
	either zero? hr [
		rect: declare RECT_STRUCT
		GetClientRect hWnd rect
		video: as IVideoWindow IVM/ptr/vtbl
		video/put_Owner IVM/ptr hWnd
		video/put_WindowStyle IVM/ptr WS_CHILD
		video/SetWindowPosition IVM/ptr 0 0 rect/right rect/bottom
		video/put_Visible IVM/ptr -1
		cam/window: IVM/ptr
	][
		cam/window: null
		probe "This graph cannot preview"
		return -1
	]
	0
]

toggle-preview: func [
	handle		[handle!]
	enable?		[logic!]
	/local
		this	[interface!]
		cam		[camera!]
		graph	[IGraphBuilder]
		mc		[IMediaControl]
		hr		[integer!]
][
	this: declare interface!
	cam: as camera! GetWindowLong handle wc-offset - 4
	if cam = null [exit]
	graph: as IGraphBuilder cam/graph/vtbl

	hr: graph/QueryInterface cam/graph IID_IMediaControl this
	if hr >= 0 [
		mc: as IMediaControl this/ptr/vtbl
		either enable? [
			hr: mc/Run this/ptr
			if hr < 0 [mc/Stop this/ptr]
		][
			mc/Stop this/ptr
		]
		mc/Release this/ptr
	]
]

select-camera: func [
	handle	[handle!]
	idx		[integer!]
	/local
		cam [camera!]
][
	cam: as camera! GetWindowLong handle wc-offset - 4
	teardown-graph cam
	free-graph cam
	init-graph cam idx
	build-preview-graph cam handle
]

collect-camera: func [
	cam			[camera!]
	data		[red-block!]
	return:		[integer!]
	/local
		hr		[integer!]
		var		[tagVARIANT]
		IDev	[interface!]
		IEnum	[interface!]
		IM		[interface!]
		IBag	[interface!]
		dev		[ICreateDevEnum]
		em		[IEnumMoniker]
		moniker [IMoniker]
		bag		[IPropertyBag]
		str		[red-string!]
		len		[int-ptr!]
		size	[integer!]
		dev-ptr [int-ptr!]
		fetched [integer!]
][
	IDev:  declare interface!
	IEnum: declare interface!
	IM:    declare interface!
	IBag:  declare interface!

	hr: CoCreateInstance CLSID_SystemDeviceEnum 0 1 IID_ICreateDevEnum IDev
	if hr <> 0 [probe "Error Creating Device Enumerator" return 0]

	dev: as ICreateDevEnum IDev/ptr/vtbl
	hr: dev/CreateClassEnumerator IDev/ptr CLSID_VideoInputDeviceCategory IEnum 0
	if hr <> 0 [
		probe "No video capture hardware"
		dev/Release IDev/ptr
		return 0
	]
	dev/Release IDev/ptr

	em: as IEnumMoniker IEnum/ptr/vtbl
	var: declare tagVARIANT
	var/data1: 8 << 16									;-- var.vt = VT_BSTR
	dev-ptr: (as int-ptr! cam) + 4
	fetched: 0

	hr: em/Next IEnum/ptr 1 IM :fetched
	either zero? hr [block/make-at data 2][return 0]
	until [
		moniker: as IMoniker IM/ptr/vtbl
		hr: moniker/BindToStorage IM/ptr 0 0 IID_IPropertyBag IBag
		if hr >= 0 [
			bag: as IPropertyBag IBag/ptr/vtbl
			hr: bag/Read IBag/ptr #u16 "FriendlyName" var 0
			if zero? hr [
				len: as int-ptr! var/data3 - 4
				size: len/value >> 1
				str: string/make-at ALLOC_TAIL(data) size 2
				unicode/load-utf16 as c-string! var/data3 size str no
				dev-ptr/value: as-integer IM/ptr
				dev-ptr: dev-ptr + 1
				moniker/AddRef IM/ptr
			]
			bag/Release IBag/ptr
		]
		moniker/Release IM/ptr
		hr: em/Next IEnum/ptr 1 IM :fetched
		hr <> 0
	]
	em/Release IEnum/ptr
	as-integer cam
]

CameraWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
][
	DefWindowProc hWnd msg wParam lParam
]