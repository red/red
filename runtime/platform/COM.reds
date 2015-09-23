Red/System [
	Title:	"Windows platform COM imports"
	Author: "Qingtian Xie"
	File: 	%COM.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define COM_SAFE_RELEASE(interface this) [
	if this <> null [
		interface: as IUnknown this/vtbl
		interface/Release this
		this: null
	]
]

#define COM_SUCCEEDED(hr)		[hr >= 0]
#define COM_FAILED(hr)			[hr < 0]

#define COINIT_APARTMENTTHREADED	2

#define CLSCTX_INPROC_SERVER 	1
#define CLSCTX_INPROC_HANDLER	2
#define CLSCTX_INPROC           3						;-- CLSCTX_INPROC_SERVER or CLSCTX_INPROC_HANDLER

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
IID_IWinHttpRequest:			[06F29373h 4B545C5Ah F16E25B0h 0EBF8ABFh]

PIN_CATEGORY_PREVIEW:			[FB6C4282h 11D10353h 00005F90h BA16CCC0h]
MEDIATYPE_Video:				[73646976h 00100000h AA000080h 719B3800h]
MEDIATYPE_Interleaved:			[73766169h 00100000h AA000080h 719B3800h]

#define VT_EMPTY		0
#define VT_NULL			1
#define VT_BSTR			8
#define VT_ERROR		10
#define VT_BOOL			11
#define VT_UI1			17
#define VT_ARRAY		2000h

tagVARIANT: alias struct! [
	data1		[integer!]
	data2		[integer!]
	data3		[integer!]
	data4		[integer!]
]

tagGUID: alias struct! [
	data1		[integer!]
	data2		[integer!]
	data3		[integer!]
	data4		[integer!]
]

this!: alias struct! [vtbl [integer!]]

interface!: alias struct! [
	ptr [this!]
]

QueryInterface!: alias function! [
	this		[this!]
	riid		[int-ptr!]
	ppvObject	[interface!]
	return:		[integer!]
]

AddRef!: alias function! [
	this		[this!]
	return:		[integer!]
]

Release!: alias function! [
	this		[this!]
	return:		[integer!]
]

CreateClassEnumerator!: alias function! [
	this		[this!]
	clsid		[int-ptr!]
	ppMoniker	[interface!]
	flags		[integer!]
	return:		[integer!]
]

Next!: alias function! [
	this		[this!]
	celt		[integer!]
	reglt		[interface!]
	celtFetched [int-ptr!]
	return:		[integer!]
]

BindToStorage!: alias function! [
	this		[this!]
	pbc			[integer!]
	pmkToLeft	[integer!]
	riid		[int-ptr!]
	ppvObj		[interface!]
	return:		[integer!]
]

Read!: alias function! [
	this		[this!]
	name		[c-string!]
	pVar		[tagVARIANT]
	errorlog	[integer!]
	return:		[integer!]
]

RenderStream!: alias function! [
	this		[this!]
	pCategory	[int-ptr!]
	pType		[int-ptr!]
	pSource		[this!]
	pfCompressor [this!]
	pfRenderer	[this!]
	return:		[integer!]
]

IUnknown: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
]

ICreateDevEnum: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	CreateClassEnumerator	[CreateClassEnumerator!]
]

IEnumMoniker: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	Next					[Next!]
	Skip					[integer!]
	Reset					[Release!]
	Clone					[integer!]
]

IMoniker: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	GetClassID				[integer!]
	IsDirty					[integer!]
	Load					[integer!]
	Save					[integer!]
	GetSizeMax				[integer!]
	BindToObject			[BindToStorage!]
	BindToStorage			[BindToStorage!]
	;... other funcs we don't use
]

IPropertyBag: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	Read					[Read!]
	Write					[integer!]
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

IWinHttpRequest: alias struct! [
	QueryInterface			[QueryInterface!]
	AddRef					[AddRef!]
	Release					[Release!]
	GetTypeInfoCount		[integer!]
	GetTypeInfo				[integer!]
	GetIDsOfNames			[integer!]
	Invoke					[integer!]
	SetProxy				[integer!]
	SetCredentials			[integer!]
	Open					[function! [this [this!] method [byte-ptr!] url [byte-ptr!] async1 [integer!] async2 [integer!] async3 [integer!] async4 [integer!] return: [integer!]]]
	SetRequestHeader		[function! [this [this!] header [byte-ptr!] value [byte-ptr!] return: [integer!]]]
	GetResponseHeader		[function! [this [this!] header [byte-ptr!] value [int-ptr!] return: [integer!]]]
	GetAllResponseHeaders	[function! [this [this!] header [int-ptr!] return: [integer!]]]
	Send					[function! [this [this!] body1 [integer!] body2 [integer!] body3 [integer!] body4 [integer!] return: [integer!]]]
	Status					[function! [this [this!] status [int-ptr!] return: [integer!]]]
	StatusText				[integer!]
	ResponseText			[function! [this [this!] body [int-ptr!] return: [integer!]]]
	ResponseBody			[function! [this [this!] body [tagVARIANT] return: [integer!]]]
	ResponseStream			[integer!]
	GetOption				[integer!]
	PutOption				[integer!]
	WaitForResponse			[integer!]
	Abort					[integer!]
	SetTimeouts				[integer!]
	SetClientCertificate	[integer!]
	SetAutoLogonPolicy		[integer!]
]

#import [
	"ole32.dll" stdcall [
		CoInitializeEx: "CoInitializeEx" [
			reserved	[integer!]
			dwCoInit	[integer!]
			return:		[integer!]
		]
		CoUninitialize: "CoUninitialize" []
		CoCreateInstance: "CoCreateInstance" [
			rclsid		 [int-ptr!]
			pUnkOuter	 [integer!]
			dwClsContext [integer!]
			riid		 [int-ptr!]
			ppv			 [interface!]
			return:		 [integer!]
		]
		CLSIDFromProgID: "CLSIDFromProgID" [
			lpszProgID	[c-string!]
			lpclsid		[tagGUID]
			return:		[integer!]
		]
	]
	"oleaut32.dll" stdcall [
		SysAllocString: "SysAllocString" [
			psz		[c-string!]
			return:	[byte-ptr!]
		]
		SysFreeString: "SysFreeString" [
			bstr	[byte-ptr!]
		]
		VariantInit: "VariantInit" [
			pvarg	[tagVARIANT]
		]
		SafeArrayGetDim: "SafeArrayGetDim" [
			psa		[integer!]
			return: [integer!]
		]
		SafeArrayGetLBound: "SafeArrayGetLBound" [
			psa		[integer!]
			nDim	[integer!]
			bound	[int-ptr!]
			return: [integer!]
		]
		SafeArrayGetUBound: "SafeArrayGetUBound" [
			psa		[integer!]
			nDim	[integer!]
			bound	[int-ptr!]
			return: [integer!]
		]
		SafeArrayAccessData: "SafeArrayAccessData" [
			psa		[integer!]
			ppvData [int-ptr!]
			return: [integer!]
		]
		SafeArrayUnaccessData: "SafeArrayUnaccessData" [
			psa		[integer!]
			return: [integer!]
		]
		SafeArrayDestroy: "SafeArrayDestroy" [
			psa		[integer!]
			return:	[integer!]
		]
	]
]