Red/System [
	Title:	"Windows Camera widget"
	Author: "Xie Qingtian"
	File: 	%camera.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
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
CLSID_SampleGrabber:			[C1F400A0h 11D33F08h 60000B9Fh 379E0308h]

IID_ICreateDevEnum:				[29840822h 11D05B84h A0003BBDh 86CE11C9h]
IID_IPropertyBag: 				[55272A00h 11CE42CBh AA003581h 51B84B00h]
IID_IBaseFilter:				[56A86895h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_ICaptureGraphBuilder2:		[93E5A4E0h 11D22D50h A000FAABh 8DE3C6C9h]
IID_IGraphBuilder:				[56A868A9h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_IVideoWindow:				[56A868B4h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_IMediaControl:				[56A868B1h 11CE0AD4h 20003AB0h 70A70BAFh]
IID_ISampleGrabber:				[6B652FFFh 4FCE11FEh 6602AD92h 8FC7D7B5h]

PIN_CATEGORY_PREVIEW:			[FB6C4282h 11D10353h 00005F90h BA16CCC0h]
MEDIATYPE_Video:				[73646976h 00100000h AA000080h 719B3800h]
MEDIATYPE_Interleaved:			[73766169h 00100000h AA000080h 719B3800h]

AM_MEDIA_TYPE: alias struct! [
	majortype				[tagGUID value]
	subtype					[tagGUID value]
	bFixedSizeSamples		[integer!]
	bTemporalCompression	[integer!]
	lSampleSize				[integer!]
	formattype				[tagGUID value]
	pUnk					[int-ptr!]
	cbFormat				[integer!]
	pbFormat				[byte-ptr!]
]

BITMAPINFOHEADER: alias struct! [
	biSize				[integer!]
	biWidth				[integer!]
	biHeight			[integer!]
	biPlanes_BitCount	[integer!]
	biCompression		[integer!]
	biSizeImage			[integer!]
	biXPelsPerMeter		[integer!]
	biYPelsPerMeter		[integer!]
	biClrUsed			[integer!]
	biClrImportant		[integer!]
]

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

ISampleGrabberCB: alias struct! [
	QueryInterface			[int-ptr!]
	AddRef					[int-ptr!]
	Release					[int-ptr!]
	SampleCB				[int-ptr!]
	BufferCB				[int-ptr!]
]

RedGrabberCB: alias struct! [
	vtbl					[int-ptr!]
	width					[integer!]
	height					[integer!]
	hWnd					[handle!]
]

ISampleGrabber: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]	
	SetOneShot				[function! [this [this!] oneshot [integer!] return: [integer!]]]
	SetMediaType			[function! [this [this!] pType [AM_MEDIA_TYPE] return: [integer!]]]
	GetConnectedMediaType	[function! [this [this!] pType [AM_MEDIA_TYPE] return: [integer!]]]
	SetBufferSamples		[int-ptr!]
	GetCurrentBuffer		[int-ptr!]
	GetCurrentSample		[int-ptr!]
	SetCallback				[function! [this [this!] pCallBack [int-ptr!] method [integer!] return: [integer!]]]
]

#define CAM_DEV_OFFSET 7

camera!: alias struct! [
	builder		[this!]
	graph		[this!]
	v-filter	[this!]
	g-filter	[this!]
	grabber		[this!]
	grabber-cb	[int-ptr!]
	window		[this!]
	dev1		[this!]
	dev2		[this!]
	dev3		[this!]
	dev4		[this!]
	dev5		[this!]
	dev6		[this!]
	dev7		[this!]
	dev8		[this!]
	num			[integer!]
]


SampleGrabberCB: declare ISampleGrabberCB

grabber-cb-addref: func [
	[stdcall]
	this	[this!]
	return: [integer!]
][2]

grabber-cb-release: func [
	[stdcall]
	this	[this!]
	return: [integer!]
][1]

grabber-cb-query: func [
	[stdcall]
	this	[this!]
	iid		[tagGUID]
	ppv		[ptr-ptr!]
	return: [integer!]
][
	ppv/value: as int-ptr! this
	0
]

grabber-cb-sample: func [
	[stdcall]
	this	[this!]
	time	[float!]
	pSample	[int-ptr!]
	return: [integer!]
][
	0
]

grabber-cb-buffer: func [
	[stdcall]
	this			[this!]
	dblSampleTime	[float!]
	pBuffer			[byte-ptr!]
	lBufferSize		[integer!]
	return:			[integer!]
	/local
		obj			[RedGrabberCB]
		bmp			[integer!]
		values		[red-value!]
		img			[red-image!]
][
	if collector/running? [return 0]

	obj: as RedGrabberCB this
	values: get-face-values obj/hWnd
	img: as red-image! values + FACE_OBJ_IMAGE
	if TYPE_OF(img) = TYPE_NONE [
		bmp: 0
		OS-image/create-bitmap-from-scan0 obj/width obj/height 0 OS-image/fixed-format pBuffer :bmp
		image/init-image img OS-image/flip as node! bmp
	]
	0
]

camera-get-image: func [img [red-image!] /local timeout [float32!]][
	timeout: as float32! 0.0
	img/header: TYPE_NONE
	until [
		platform/wait 0.01
		timeout: timeout + as float32! 0.01
		any [TYPE_OF(img) = TYPE_IMAGE timeout > as float32! 0.1]
	]
]

init-camera: func [
	hWnd	[handle!]
	data	[red-block!]
	sel		[red-integer!]
	open?	[logic!]
	/local
		cam [camera!]
		val [integer!] 
][
	cam: as camera! allocate size? camera!				;@@ need to be freed
	zero-memory as byte-ptr! cam size? camera!
	val: collect-camera cam data
	if zero? val [
		free as byte-ptr! cam
		SetWindowLong hWnd wc-offset - 4 0
		exit
	]

	SetWindowLong hWnd wc-offset - 4 val
	if TYPE_OF(sel) = TYPE_INTEGER [
		if select-camera hWnd sel/value - 1 [
			toggle-preview hWnd true
		]
	]
]

free-graph: func [cam [camera!] /local interface [IUnknown]][
	COM_SAFE_RELEASE(interface cam/builder)
	COM_SAFE_RELEASE(interface cam/graph)
	COM_SAFE_RELEASE(interface cam/v-filter)
	COM_SAFE_RELEASE(interface cam/grabber)
	COM_SAFE_RELEASE(interface cam/g-filter)
	free as byte-ptr! cam/grabber-cb
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

stop-camera: func [handle [handle!] return: [camera!] /local cam [camera!] ][
	cam: as camera! GetWindowLong handle wc-offset - 4
	unless null? cam [
		teardown-graph cam
		free-graph cam
	]
	cam
]

destroy-camera: func [handle [handle!] /local cam [camera!]][
	cam: stop-camera handle
	if cam <> null [
		SetWindowLong handle wc-offset - 4 0
		free as byte-ptr! cam
	]
]

init-graph: func [
	cam		[camera!]
	idx		[integer!]
	/local
		IB			[interface! value]
		IG			[interface! value]
		ICap		[interface! value]
		graph		[IGraphBuilder]
		moniker 	[IMoniker]
		builder 	[ICaptureGraphBuilder2]
		grabber 	[ISampleGrabber]
		hr			[integer!]
		dev-ptr 	[int-ptr!]
		dev			[this!]
		IGrabFilter	[interface! value]
		IGrab		[interface! value]
		filter		[IUnknown]
		mt			[AM_MEDIA_TYPE value]
][
	hr: CoCreateInstance CLSID_CaptureGraphBuilder2 0 1 IID_ICaptureGraphBuilder2 IB
	builder: as ICaptureGraphBuilder2 IB/ptr/vtbl
	cam/builder: IB/ptr

	hr: CoCreateInstance CLSID_FilterGraph 0 CLSCTX_INPROC IID_IGraphBuilder IG
	graph: as IGraphBuilder IG/ptr/vtbl
	cam/graph: IG/ptr

	hr: builder/SetFiltergraph IB/ptr IG/ptr
	if hr <> 0 [probe "Cannot give graph to builder"]

	dev-ptr: (as int-ptr! cam) + CAM_DEV_OFFSET + idx
	dev: as this! dev-ptr/value
	moniker: as IMoniker dev/vtbl

	hr: moniker/BindToObject dev 0 0 IID_IBaseFilter ICap
	hr: graph/AddFilter IG/ptr ICap/ptr null
	cam/v-filter: either zero? hr [ICap/ptr][
		print-line ["Error " hr ": Cannot add videocap to filtergraph"]
		null
	]

    hr: CoCreateInstance CLSID_SampleGrabber 0 CLSCTX_INPROC_SERVER IID_IBaseFilter IGrabFilter
	filter: as IUnknown IGrabFilter/ptr/vtbl
	hr: filter/QueryInterface IGrabFilter/ptr IID_ISampleGrabber IGrab
	grabber: as ISampleGrabber IGrab/ptr/vtbl
	cam/g-filter: IGrabFilter/ptr
	cam/grabber: IGrab/ptr

	zero-memory as byte-ptr! :mt size? AM_MEDIA_TYPE
	mt/majortype/data1: MEDIATYPE_Video/1
	mt/majortype/data2: MEDIATYPE_Video/2
	mt/majortype/data3: MEDIATYPE_Video/3
	mt/majortype/data4: MEDIATYPE_Video/4

	;-- E436EB7D-524F-11CE-9F53-0020AF0BA770 (rgb24)
	;mt/subtype/data1: E436EB7Dh
	;mt/subtype/data2: 11CE524Fh
	;mt/subtype/data3: 2000539Fh
	;mt/subtype/data4: 70A70BAFh

	;-- 773C9AC0-3274-11D0-B724-00AA006C1A01 (argb)
	mt/subtype/data1: 773C9AC0h
	mt/subtype/data2: 11D03274h
	mt/subtype/data3: AA0024B7h
	mt/subtype/data4: 011A6C00h	

	;-- 05589F80-C356-11CE-BF01-00AA0055595A
	mt/formattype/data1: 05589F80h
	mt/formattype/data2: 11CEC356h
	mt/formattype/data3: AA0001BFh
	mt/formattype/data4: 5A595500h

	hr: grabber/SetMediaType IGrab/ptr :mt
	hr: graph/AddFilter IG/ptr IGrabFilter/ptr null
]

build-preview-graph: func [
	cam 		[camera!]
	hWnd		[handle!]
	return:		[integer!]
	/local
		filter	[this!]
		IVM		[interface! value]
		graph	[IGraphBuilder]
		builder [ICaptureGraphBuilder2]
		video	[IVideoWindow]
		hr		[integer!]
		rect	[RECT_STRUCT value]
		mt		[AM_MEDIA_TYPE value]
		grabber [ISampleGrabber]
		grabber-cb	[RedGrabberCB]
		info	[int-ptr!]
		bmp		[BITMAPINFOHEADER]
][
	builder: as ICaptureGraphBuilder2 cam/builder/vtbl
	graph:   as IGraphBuilder cam/graph/vtbl
	filter:  as this! cam/v-filter

	hr: builder/RenderStream cam/builder PIN_CATEGORY_PREVIEW MEDIATYPE_Interleaved filter cam/g-filter null
	case [
		hr = VFW_S_NOPREVIEWPIN [1]
		hr <> 0 [
			hr: builder/RenderStream cam/builder PIN_CATEGORY_PREVIEW MEDIATYPE_Video filter cam/g-filter null
			case [
				hr = VFW_S_NOPREVIEWPIN [1]
				hr <> 0 [probe "This device cannot preview!" return -1]
				true [1]
			]
		]
		true [1]
	]

	grabber: as ISampleGrabber cam/grabber/vtbl
	zero-memory as byte-ptr! :mt size? AM_MEDIA_TYPE
	hr: grabber/GetConnectedMediaType cam/grabber :mt
	info: as int-ptr! mt/pbFormat
	bmp: as BITMAPINFOHEADER info + 12

	grabber-cb: as RedGrabberCB allocate size? RedGrabberCB
	grabber-cb/width: bmp/biWidth
	grabber-cb/height: bmp/biHeight
	grabber-cb/hWnd: hWnd
	grabber-cb/vtbl: as int-ptr! SampleGrabberCB
	cam/grabber-cb: as int-ptr! grabber-cb

	grabber/SetCallback cam/grabber as int-ptr! grabber-cb 1
	
	hr: graph/QueryInterface cam/graph IID_IVideoWindow IVM
	either zero? hr [
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
	enabled?	[logic!]
	/local
		this	[interface! value]
		cam		[camera!]
		graph	[IGraphBuilder]
		mc		[IMediaControl]
		hr		[integer!]
][
	cam: as camera! GetWindowLong handle wc-offset - 4
	if cam = null [exit]
	graph: as IGraphBuilder cam/graph/vtbl

	hr: graph/QueryInterface cam/graph IID_IMediaControl this
	if hr >= 0 [
		mc: as IMediaControl this/ptr/vtbl
		either enabled? [
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
	return: [logic!]
	/local
		cam [camera!]
][
	cam: as camera! GetWindowLong handle wc-offset - 4
	if any [idx < 0 idx >= cam/num][
		fire [TO_ERROR(access cannot-open) integer/push idx + 1]
	]
	teardown-graph cam
	free-graph cam
	init-graph cam idx
	either zero? build-preview-graph cam handle [true][
		teardown-graph cam
		free-graph cam
		false
	]
]

collect-camera: func [
	cam			[camera!]
	data		[red-block!]
	return:		[integer!]
	/local
		hr		[integer!]
		var		[tagVARIANT value]
		IDev	[interface! value]
		IEnum	[interface! value]
		IM		[interface! value]
		IBag	[interface! value]
		dev		[ICreateDevEnum]
		em		[IEnumMoniker]
		moniker [IMoniker]
		bag		[IPropertyBag]
		str		[red-string!]
		len		[int-ptr!]
		size	[integer!]
		dev-ptr [int-ptr!]
		fetched [integer!]
		cnt		[integer!]
][
	SampleGrabberCB/AddRef: as int-ptr! :grabber-cb-addref
	SampleGrabberCB/Release: as int-ptr! :grabber-cb-release
	SampleGrabberCB/QueryInterface: as int-ptr! :grabber-cb-query
	SampleGrabberCB/SampleCB: as int-ptr! :grabber-cb-sample
	SampleGrabberCB/BufferCB: as int-ptr! :grabber-cb-buffer

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
	var/data1: 8 << 16									;-- var.vt = VT_BSTR
	dev-ptr: (as int-ptr! cam) + CAM_DEV_OFFSET
	fetched: 0
	cnt: 0

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
				cnt: cnt + 1
				moniker/AddRef IM/ptr
			]
			bag/Release IBag/ptr
		]
		moniker/Release IM/ptr
		hr: em/Next IEnum/ptr 1 IM :fetched
		hr <> 0
	]
	cam/num: cnt
	em/Release IEnum/ptr
	as-integer cam
]

CameraWndProc: func [
	[stdcall]
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		cam [camera!]
][
	if msg = WM_DESTROY [destroy-camera hWnd]
	DefWindowProc hWnd msg wParam lParam
]