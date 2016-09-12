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