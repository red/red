Red/System [
	Title:	"Direct2D structures and functions"
	Author: "Xie Qingtian"
	File: 	%direct2d.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

d3d-device:		as this! 0
d3d-ctx:		as this! 0
d2d-ctx:		as this! 0
d2d-factory:	as this! 0
dwrite-factory: as this! 0
dxgi-device:	as this! 0
dxgi-adapter:	as this! 0
dxgi-factory:	as this! 0
dw-locale-name: as c-string! 0

pfnDCompositionCreateDevice2: as int-ptr! 0

dpi-value:		as float32! 96.0
dpi-x:			as float32! 0.0
dpi-y:			as float32! 0.0
dwrite-str-cache: as node! 0

#define D2D_MAX_BRUSHES 64

#define D2DERR_RECREATE_TARGET 8899000Ch
#define DXGI_ERROR_DEVICE_REMOVED 887A0005h
#define DXGI_ERROR_DEVICE_RESET	887A0007h
#define FLT_MAX	[as float32! 3.402823466e38]

IID_IDXGISurface:		 [CAFCB56Ch 48896AC3h 239E47BFh EC60D2BBh]
IID_IDXGIDevice1:		 [77DB970Fh 48BA6276h 010728BAh 2C39B443h]
;IID_ID2D1Factory:		 [06152247h 465A6F50h 8B114592h 07603BFDh]
IID_ID2D1Factory1:		 [BB12D362h 4B9ADAEEh BA141DAAh 1FFA1C40h]
IID_IDWriteFactory:		 [B859EE5Ah 4B5BD838h DC1AE8A2h 48DB937Dh]
IID_IDXGIFactory2:		 [50C83A1Ch 4C48E072h 3036B087h D0A636FAh]
IID_IDCompositionDevice: [C37EA93Ah 450DE7AAh 46976FB1h F30704CBh]

D2D1_FACTORY_OPTIONS: alias struct! [
	debugLevel	[integer!]
]

D3DCOLORVALUE: alias struct! [
	r			[float32!]
	g			[float32!]
	b			[float32!]
	a			[float32!]
]

RECT_F!: alias struct! [
	left		[float32!]
	top			[float32!]
	right		[float32!]
	bottom		[float32!]
]

SIZE_U!: alias struct! [
	width		[uint32!]
	height		[uint32!]
]

SIZE_F!: alias struct! [
	width		[float32!]
	height		[float32!]
]

D2D_POINT_2F: alias struct! [
	x			[float32!]
	y			[float32!]
]

D2D1_BEZIER_SEGMENT: alias struct! [
	point1		[D2D_POINT_2F value]
	point2		[D2D_POINT_2F value]
	point3		[D2D_POINT_2F value]
]

D2D1_QUADRATIC_BEZIER_SEGMENT: alias struct! [
	point1		[D2D_POINT_2F value]
	point2		[D2D_POINT_2F value]
]

D2D1_ARC_SEGMENT: alias struct! [
	point		[D2D_POINT_2F value]
	size		[SIZE_F! value]
	angle		[float32!]
	direction	[integer!]
	arcSize		[integer!]
]

D2D_MATRIX_3X2_F: alias struct! [
	_11			[float32!]
	_12			[float32!]
	_21			[float32!]
	_22			[float32!]
	_31			[float32!]
	_32			[float32!]
]

D2D1_ELLIPSE: alias struct! [
	x			[float32!]
	y			[float32!]
	radiusX		[float32!]
	radiusY		[float32!]
]

D2D1_GRADIENT_STOP: alias struct! [
	position	[float32!]
	r			[float32!]
	g			[float32!]
	b			[float32!]
	a			[float32!]
]

#enum D2D1_CAP_STYLE [
	D2D1_CAP_STYLE_FLAT
	D2D1_CAP_STYLE_SQUARE
	D2D1_CAP_STYLE_ROUND
	D2D1_CAP_STYLE_TRIANGLE
	D2D1_CAP_STYLE_FORCE_DWORD: -1
]

#enum D2D1_LINE_JOIN [
	D2D1_LINE_JOIN_MITER
	D2D1_LINE_JOIN_BEVEL
	D2D1_LINE_JOIN_ROUND
	D2D1_LINE_JOIN_MITER_OR_BEVEL
	D2D1_LINE_JOIN_FORCE_DWORD: -1
]

D2D1_STROKE_STYLE_PROPERTIES: alias struct! [
	startCap	[integer!]
	endCap		[integer!]
	dashCap		[integer!]
	lineJoin	[integer!]
	miterLimit	[float32!]
	dashStyle	[integer!]
	dashOffset	[float32!]
]

D2D1_RENDER_TARGET_PROPERTIES: alias struct! [
	type		[integer!]
	format		[integer!]
	alphaMode	[integer!]
	dpiX		[float32!]
	dpiY		[float32!]
	usage		[integer!]
	minLevel	[integer!]
]

D2D1_HWND_RENDER_TARGET_PROPERTIES: alias struct! [
	hwnd				[handle!]
	pixelSize.width		[integer!]
	pixelSize.height	[integer!]
	presentOptions		[integer!]
]

D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES: alias struct! [
	center.x			[float32!]
	center.y			[float32!]
	offset.x			[float32!]
	offset.y			[float32!]
	radius.x			[float32!]
	radius.y			[float32!]
]

DXGI_SWAP_CHAIN_DESC1: alias struct! [
    Width			[integer!]
    Height			[integer!]
    Format			[integer!]
    Stereo			[integer!]
    SampleCount		[integer!]
    SampleQuality	[integer!]
    BufferUsage		[integer!]
    BufferCount		[integer!]
    Scaling			[integer!]
    SwapEffect		[integer!]
    AlphaMode		[integer!]
    Flags			[integer!]
]

#enum D2D1_EXTEND_MODE [
	D2D1_EXTEND_MODE_CLAMP
	D2D1_EXTEND_MODE_WRAP
	D2D1_EXTEND_MODE_MIRROR
	D2D1_EXTEND_MODE_FORCE_DWORD: -1
]

D2D1_BITMAP_BRUSH_PROPERTIES1: alias struct! [
	extendModeX		[D2D1_EXTEND_MODE]
	extendModeY		[D2D1_EXTEND_MODE]
	interpolationMode [integer!]
]

D2D1_IMAGE_BRUSH_PROPERTIES: alias struct! [
	;sourceRectangle	[RECT_F! value]
	left			[float32!]
	top				[float32!]
	right			[float32!]
	bottom			[float32!]
	extendModeX		[D2D1_EXTEND_MODE]
	extendModeY		[D2D1_EXTEND_MODE]
	interpolationMode [integer!]
]

D2D1_BRUSH_PROPERTIES: alias struct! [
	opacity			[float32!]
	transform		[D2D_MATRIX_3X2_F value]
]

D2D1_BITMAP_PROPERTIES1: alias struct! [
	format			[integer!]
	alphaMode		[integer!]
	dpiX			[float32!]
	dpiY			[float32!]
	options			[integer!]
	colorContext	[int-ptr!]
]

DXGI_PRESENT_PARAMETERS: alias struct! [
	DirtyRectsCount	[integer!]
	pDirtyRects		[RECT_STRUCT]
	pScrollRect		[RECT_STRUCT]
	pScrollOffset	[tagPOINT]
]

CreateSolidColorBrush*: alias function! [
	this		[this!]
	color		[D3DCOLORVALUE]
	properties	[D2D1_BRUSH_PROPERTIES]
	brush		[ptr-ptr!]
	return:		[integer!]
]

CreateRadialGradientBrush*: alias function! [
	this		[this!]
	gprops		[D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES]
	props		[D2D1_BRUSH_PROPERTIES]
	stops		[integer!]
	brush		[ptr-ptr!]
	return:		[integer!]
]

CreateGradientStopCollection*: alias function! [
	this		[this!]
	stops		[D2D1_GRADIENT_STOP]
	stopsCount	[integer!]
	gamma		[integer!]
	extendMode	[integer!]
	stops-ptr	[int-ptr!]
	return:		[integer!]
]

DrawLine*: alias function! [
	this		[this!]
	pt0.x		[float32!]
	pt0.y		[float32!]
	pt1.x		[float32!]
	pt1.y		[float32!]
	brush		[this!]
	width		[float32!]
	style		[integer!]
]

DrawRectangle*: alias function! [
	this		[this!]
	rect		[RECT_F!]
	brush		[this!]
	strokeWidth [float32!]
	strokeStyle [integer!]
]

FillRectangle*: alias function! [
	this		[this!]
	rect		[RECT_F!]
	brush		[this!]
]

DrawEllipse*: alias function! [
	this		[this!]
	ellipse		[D2D1_ELLIPSE]
	brush		[this!]
	width		[float32!]
	style		[integer!]
]

FillEllipse*: alias function! [
	this		[this!]
	ellipse		[D2D1_ELLIPSE]
	brush		[this!]
]

DrawTextLayout*: alias function! [
	this		[this!]
	x			[float32!]
	y			[float32!]
	layout		[this!]
	brush		[this!]
	options		[integer!]
]

SetTransform*: alias function! [
	this		[this!]
	transform	[D2D_MATRIX_3X2_F]
]

GetTransform*: alias function! [
	this		[this!]
	transform	[D2D_MATRIX_3X2_F]
]

Resize*: alias function! [
	this		[this!]
	pixelSize	[tagSIZE]
	return:		[integer!]
]

CreateSwapChainForHwnd*: alias function! [
	this				[this!]
	pDevice				[this!]
	hwnd				[handle!]
	desc				[DXGI_SWAP_CHAIN_DESC1]
	pFullscreenDesc		[int-ptr!]
	pRestrictToOutput	[int-ptr!]
	ppSwapChain			[int-ptr!]
	return:				[integer!]
]

CreateSwapChainForComposition*: alias function! [
	this				[this!]
	pDevice				[this!]
	desc				[DXGI_SWAP_CHAIN_DESC1]
	pRestrictToOutput	[int-ptr!]
	ppSwapChain			[int-ptr!]
	return:				[integer!]
]

ID2D1SolidColorBrush: alias struct! [
	QueryInterface		[QueryInterface!]
	AddRef				[AddRef!]
	Release				[Release!]
	GetFactory			[integer!]
	SetOpacity			[integer!]
	SetTransform		[SetTransform*]
	GetOpacity			[integer!]
	GetTransform		[GetTransform*]
	SetColor			[function! [this [this!] color [D3DCOLORVALUE]]]
	GetColor			[integer!]
]

ID2D1RadialGradientBrush: alias struct! [
	QueryInterface				[QueryInterface!]
	AddRef						[AddRef!]
	Release						[Release!]
	GetFactory					[integer!]
	SetOpacity					[integer!]
	SetTransform				[SetTransform*]
	GetOpacity					[integer!]
	GetTransform				[GetTransform*]
	SetCenter					[integer!]
	SetGradientOriginOffset		[integer!]
	SetRadiusX					[integer!]
	SetRadiusY					[integer!]
	GetCenter					[integer!]
	GetGradientOriginOffset		[integer!]
	GetRadiusX					[integer!]
	GetRadiusY					[integer!]
	GetGradientStopCollection	[integer!]
]

ID2D1GradientStopCollection: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetFactory						[integer!]
	GetGradientStopCount			[integer!]
	GetGradientStops				[integer!]
	GetColorInterpolationGamma		[integer!]
	GetExtendMode					[integer!]
]

ID2D1Properties: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetPropertyCount				[int-ptr!]
	GetPropertyName					[int-ptr!]
	GetPropertyNameLength			[int-ptr!]
	GetType							[int-ptr!]
	GetPropertyIndex				[int-ptr!]
	SetValueByName					[int-ptr!]
	SetValue						[int-ptr!]
	GetValueByName					[int-ptr!]
	GetValue						[int-ptr!]
	GetValueSize					[int-ptr!]
	GetSubProperties				[int-ptr!]
]

ID2D1Effect: alias struct! [
	Base							[ID2D1Properties value]
	SetInput						[function! [this [this!] idx [uint32!] input [int-ptr!] invalidate [logic!]]]
	SetInputCount					[function! [this [this!] count [uint32!] return: [integer!]]]
	GetInput						[function! [this [this!] idx [uint32!] input [ptr-ptr!]]]
	GetInputCount					[function! [this [this!] return: [integer!]]]
	GetOutput						[function! [this [this!] idx [uint!] output [ptr-ptr!]]]
]

IDXGIDevice1: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetPrivateData					[integer!]
	SetPrivateDataInterface			[integer!]
	GetPrivateData					[integer!]
	GetParent						[function! [this [this!] riid [int-ptr!] parent [int-ptr!] return: [integer!]]]
	GetAdapter						[function! [this [this!] adapter [ptr-ptr!] return: [integer!]]]
	CreateSurface					[integer!]
	QueryResourceResidency			[integer!]
	SetGPUThreadPriority			[integer!]
	GetGPUThreadPriority			[integer!]
	SetMaximumFrameLatency			[integer!]
	GetMaximumFrameLatency			[integer!]
]

IDXGIAdapter: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetPrivateData					[integer!]
	SetPrivateDataInterface			[integer!]
	GetPrivateData					[integer!]
	GetParent						[function! [this [this!] riid [int-ptr!] parent [ptr-ptr!] return: [integer!]]]
	EnumOutputs						[integer!]
	GetDesc							[integer!]
	CheckInterfaceSupport			[integer!]
]

IDXGISwapChain1: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetPrivateData					[int-ptr!]
	SetPrivateDataInterface			[int-ptr!]
	GetPrivateData					[int-ptr!]
	GetParent						[function! [this [this!] riid [int-ptr!] parent [int-ptr!] return: [integer!]]]
	GetDevice						[function! [this [this!] riid [int-ptr!] device [int-ptr!] return: [integer!]]]
	Present							[function! [this [this!] SyncInterval [integer!] PresentFlags [integer!] return: [integer!]]]
	GetBuffer						[function! [this [this!] idx [integer!] riid [int-ptr!] buffer [int-ptr!] return: [integer!]]]
	SetFullscreenState				[int-ptr!]
	GetFullscreenState				[int-ptr!]
	GetDesc							[int-ptr!]
	ResizeBuffers					[function! [this [this!] count [uint!] width [uint!] height [uint!] format [integer!] flags [uint!] return: [integer!]]]
	ResizeTarget					[int-ptr!]
	GetContainingOutput				[int-ptr!]
	GetFrameStatistics				[int-ptr!]
	GetLastPresentCount				[int-ptr!]
	GetDesc1						[int-ptr!]
	GetFullscreenDesc				[int-ptr!]
	GetHwnd							[int-ptr!]
	GetCoreWindow					[int-ptr!]
	Present1						[function! [this [this!] SyncInterval [integer!] PresentFlags [integer!] pPresentParameters [DXGI_PRESENT_PARAMETERS] return: [integer!]]]
	IsTemporaryMonoSupported		[int-ptr!]
	GetRestrictToOutput				[int-ptr!]
	SetBackgroundColor				[int-ptr!]
	GetBackgroundColor				[int-ptr!]
	SetRotation						[int-ptr!]
	GetRotation						[int-ptr!]
]

IDCompositionDevice: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	Commit							[function! [this [this!] return: [integer!]]]
	WaitForCommitCompletion			[integer!]
	GetFrameStatistics				[integer!]
	CreateTargetForHwnd				[function! [this [this!] hwnd [handle!] topmost [logic!] target [int-ptr!] return: [integer!]]]
	CreateVisual					[function! [this [this!] visual [int-ptr!] return: [integer!]]]
	CreateSurface					[integer!]
	CreateVirtualSurface			[integer!]
	CreateSurfaceFromHandle			[integer!]
	CreateSurfaceFromHwnd			[integer!]
	CreateTranslateTransform		[integer!]
	CreateScaleTransform			[integer!]
	CreateRotateTransform			[integer!]
	CreateSkewTransform				[integer!]
	CreateMatrixTransform			[integer!]
	CreateTransformGroup			[integer!]
	CreateTranslateTransform3D		[integer!]
	CreateScaleTransform3D			[integer!]
	CreateRotateTransform3D			[integer!]
	CreateMatrixTransform3D			[integer!]
	CreateTransform3DGroup			[integer!]
	CreateEffectGroup				[integer!]
	CreateRectangleClip				[integer!]
	CreateAnimation					[integer!]
	CreateTransformGroup			[integer!]
	CheckDeviceState				[integer!]
]

IDCompositionVisual: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetOffsetX						[function! [this [this!] x [float32!] return: [integer!]]]
	SetOffsetX1						[integer!]
	SetOffsetY						[function! [this [this!] y [float32!] return: [integer!]]]
	SetOffsetY1						[integer!]
	SetTransform					[integer!]
	SetTransform1					[integer!]
	SetTransformParent				[integer!]
	SetEffect						[integer!]
	SetBitmapInterpolationMode		[integer!]
	SetBorderMode					[integer!]
	SetClip							[integer!]
	SetClip1						[integer!]
	SetContent						[function! [this [this!] p [this!] return: [integer!]]]
	AddVisual						[function! [this [this!] v [this!] above [logic!] vv [this!] return: [integer!]]]
	RemoveVisual					[integer!]
	RemoveAllVisuals				[integer!]
	SetCompositeMode				[integer!]

]

IDCompositionTarget: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetRoot							[function! [this [this!] visual [this!] return: [integer!]]]
]

ID2D1Factory: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	ReloadSystemMetrics				[Release!]
	GetDesktopDpi					[function! [this [this!] dpiX [float32-ptr!] dpiY [float32-ptr!]]]
	CreateRectangleGeometry			[integer!]
	CreateRoundedRectangleGeometry	[integer!]
	CreateEllipseGeometry			[integer!]
	CreateGeometryGroup				[integer!]
	CreateTransformedGeometry		[integer!]
	CreatePathGeometry				[function! [this [this!] pathGeometry [ptr-ptr!] return: [integer!]]]
	CreateStrokeStyle				[function! [this [this!] props [D2D1_STROKE_STYLE_PROPERTIES] dashes [float32-ptr!] count [integer!] style [ptr-ptr!] return: [integer!]]]
	CreateDrawingStateBlock			[function! [this [this!] desc [this!] param [this!] block [ptr-ptr!] return: [integer!]]]
	CreateWicBitmapRenderTarget		[integer!]
	CreateHwndRenderTarget			[function! [this [this!] properties [D2D1_RENDER_TARGET_PROPERTIES] hwndProperties [D2D1_HWND_RENDER_TARGET_PROPERTIES] target [ptr-ptr!] return: [integer!]]]
	CreateDxgiSurfaceRenderTarget	[integer!]
	CreateDCRenderTarget			[function! [this [this!] properties [D2D1_RENDER_TARGET_PROPERTIES] target [int-ptr!] return: [integer!]]]
	CreateDevice					[function! [this [this!] dxgiDevice [int-ptr!] d2dDevice [ptr-ptr!] return: [integer!]]]
]

IDXGIFactory2: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetPrivateData					[integer!]
	SetPrivateDataInterface			[integer!]
	GetPrivateData					[integer!]
	GetParent						[function! [this [this!] riid [int-ptr!] parent [int-ptr!] return: [integer!]]]
	EnumAdapters					[function! [this [this!] n [integer!] adapter [int-ptr!] return: [integer!]]]
	MakeWindowAssociation			[integer!]
	GetWindowAssociation			[integer!]
	CreateSwapChain					[integer!]
	CreateSoftwareAdapter			[integer!]
	EnumAdapters1					[integer!]
	IsCurrent						[integer!]
	IsWindowedStereoEnabled			[integer!]
	CreateSwapChainForHwnd			[CreateSwapChainForHwnd*]
	CreateSwapChainForCoreWindow	[integer!]
	GetSharedResourceAdapterLuid	[integer!]
	RegisterStereoStatusWindow		[integer!]
	RegisterStereoStatusEvent		[integer!]
	UnregisterStereoStatus			[integer!]
	RegisterOcclusionStatusWindow	[integer!]
	RegisterOcclusionStatusEvent	[integer!]
	UnregisterOcclusionStatus		[integer!]
	CreateSwapChainForComposition	[CreateSwapChainForComposition*]
]

ID2D1Device: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetFactory						[integer!]
	CreateDeviceContext				[function! [this [this!] options [integer!] ctx [ptr-ptr!] return: [integer!]]]
	CreatePrintControl				[integer!]
	SetMaximumTextureMemory			[integer!]
	GetMaximumTextureMemory			[integer!]
	ClearResources					[integer!]
	CreatePrintControl2				[integer!]
]

ID3D11Device: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	CreateBuffer					[integer!]
	CreateTexture1D					[integer!]
	CreateTexture2D					[integer!]
	CreateTexture3D					[integer!]
	CreateShaderResourceView		[integer!]
	CreateUnorderedAccessView		[integer!]
	CreateRenderTargetView			[integer!]
	CreateDepthStencilView			[integer!]
	CreateInputLayout				[integer!]
	CreateVertexShader				[integer!]
	CreateGeometryShader			[integer!]
	CreateGeometryShaderWithStreamOutput [integer!]
	CreatePixelShader				[integer!]
	CreateHullShader				[integer!]
	CreateDomainShader				[integer!]
	CreateComputeShader				[integer!]
	CreateClassLinkage				[integer!]
	CreateBlendState				[integer!]
	CreateDepthStencilState			[integer!]
	CreateRasterizerState			[integer!]
	CreateSamplerState				[integer!]
	CreateQuery						[integer!]
	CreatePredicate					[integer!]
	CreateCounter					[integer!]
	CreateDeferredContext			[integer!]
	OpenSharedResource				[integer!]
	CheckFormatSupport				[integer!]
	CheckMultisampleQualityLevels	[integer!]
	CheckCounterInfo				[integer!]
	CheckCounter					[integer!]
	CheckFeatureSupport				[integer!]
	GetPrivateData					[integer!]
	SetPrivateData					[integer!]
	SetPrivateDataInterface			[integer!]
	GetFeatureLevel					[integer!]
	GetCreationFlags				[integer!]
	GetDeviceRemovedReason			[integer!]
	GetImmediateContext				[integer!]
	SetExceptionMode				[integer!]
	GetExceptionMode				[integer!]
]

CreateSharedBitmap*: alias function! [
	this		[this!]
	riid		[tagGUID]
	data		[byte-ptr!]
	properties	[D2D1_BITMAP_PROPERTIES1]
	bitmap		[ptr-ptr!]
	return:		[integer!]
]

CreateImageBrush*: alias function! [
	this		[this!]
	bitmap		[this!]
	properties	[D2D1_IMAGE_BRUSH_PROPERTIES]
	brushProp	[D2D1_BRUSH_PROPERTIES]
	brush		[ptr-ptr!]
	return:		[integer!]
]

CreateBitmapBrush*: alias function! [
	this		[this!]
	bitmap		[this!]
	properties	[D2D1_BITMAP_BRUSH_PROPERTIES1]
	brushProp	[D2D1_BRUSH_PROPERTIES]
	brush		[ptr-ptr!]
	return:		[integer!]
]

CreateBitmap*: alias function! [
	this		[this!]
	size		[SIZE_U! value]
	sourceData	[int-ptr!]
	pitch		[uint32!]
	properties	[D2D1_BITMAP_PROPERTIES1]
	bitmap		[ptr-ptr!]
	return:		[integer!]
]

CreateBitmapFromWicBitmap*: alias function! [
	this		[this!]
	source		[this!]
	properties	[D2D1_BITMAP_PROPERTIES1]
	bitmap		[ptr-ptr!]
	return:		[integer!]
]

CreateEffect*: alias function! [
	this		[this!]
	effectID	[tagGUID]
	effect		[ptr-ptr!]
	return:		[integer!]
]

DrawImage*: alias function! [
	this		[this!]
	image		[int-ptr!]
	offset		[D2D_POINT_2F]
	rect		[RECT_F!]
	interpola	[integer!]
	composite	[integer!]
]

DrawBitmap*: alias function! [
	this		[this!]
	bmp			[int-ptr!]
	dst			[RECT_F!]
	opacity		[float32!]
	mode		[integer!]
	src			[RECT_F!]
	trans		[int-ptr!]
]

#define ID2D1RenderTarget [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetFactory						[integer!]
	CreateBitmap					[integer!]
	CreateBitmapFromWicBitmap		[integer!]
	CreateSharedBitmap				[CreateSharedBitmap*]
	CreateBitmapBrush				[CreateBitmapBrush*]
	CreateSolidColorBrush			[CreateSolidColorBrush*]
	CreateGradientStopCollection	[CreateGradientStopCollection*]
	CreateLinearGradientBrush		[integer!]
	CreateRadialGradientBrush		[CreateRadialGradientBrush*]
	CreateCompatibleRenderTarget	[function! [this [this!] size [SIZE_F! value] target [ptr-ptr!] return: [integer!]]]
	CreateLayer						[integer!]
	CreateMesh						[integer!]
	DrawLine						[DrawLine*]
	DrawRectangle					[DrawRectangle*]
	FillRectangle					[FillRectangle*]
	DrawRoundedRectangle			[integer!]
	FillRoundedRectangle			[integer!]
	DrawEllipse						[DrawEllipse*]
	FillEllipse						[FillEllipse*]
	DrawGeometry					[function! [this [this!] geometry [int-ptr!] brush [this!] strokeWidth [float32!] style [integer!] return: [integer!]]]
	FillGeometry					[function! [this [this!] geometry [int-ptr!] brush [this!] opacityBrush [this!] return: [integer!]]]
	FillMesh						[integer!]
	FillOpacityMask					[integer!]
	DrawBitmap						[integer!]
	DrawText						[integer!]
	DrawTextLayout					[DrawTextLayout*]
	DrawGlyphRun					[integer!]
	SetTransform					[SetTransform*]
	GetTransform					[GetTransform*]
	SetAntialiasMode				[function! [this [this!] mode [integer!]]]
	GetAntialiasMode				[integer!]
	SetTextAntialiasMode			[function! [this [this!] mode [integer!]]]
	GetTextAntialiasMode			[integer!]
	SetTextRenderingParams			[integer!]
	GetTextRenderingParams			[integer!]
	SetTags							[integer!]
	GetTags							[integer!]
	PushLayer						[integer!]
	PopLayer						[integer!]
	Flush							[function! [this [this!] tag1 [int-ptr!] tag2 [int-ptr!]]]
	SaveDrawingState				[function! [this [this!] block [this!]]]
	RestoreDrawingState				[function! [this [this!] block [this!]]]
	PushAxisAlignedClip				[function! [this [this!] rc [RECT_F!] mode [integer!]]]
	PopAxisAlignedClip				[function! [this [this!]]]
	Clear							[function! [this [this!] color [D3DCOLORVALUE]]]
	BeginDraw						[function! [this [this!]]]
	EndDraw							[function! [this [this!] tag1 [int-ptr!] tag2 [int-ptr!] return: [integer!]]]
	GetPixelFormat					[integer!]
	SetDpi							[function! [this [this!] x [float32!] y [float32!]]]
	GetDpi							[integer!]
	GetSize							[integer!]
	GetPixelSize					[integer!]
	GetMaximumBitmapSize			[integer!]
	IsSupported						[integer!]
]

ID2D1DeviceContext: alias struct! [
	ID2D1RenderTarget
    CreateBitmap2					[CreateBitmap*]
    CreateBitmapFromWicBitmap2		[CreateBitmapFromWicBitmap*]
    CreateColorContext						[integer!]
    CreateColorContextFromFilename			[integer!]
    CreateColorContextFromWicColorContext	[integer!]
    CreateBitmapFromDxgiSurface		[function! [this [this!] surface [int-ptr!] props [D2D1_BITMAP_PROPERTIES1] bitmap [int-ptr!] return: [integer!]]]
    CreateEffect					[CreateEffect*]
    CreateGradientStopCollection2	[integer!]
    CreateImageBrush				[CreateImageBrush*]
    CreateBitmapBrush2				[CreateBitmapBrush*]
    CreateCommandList				[integer!]
    IsDxgiFormatSupported			[integer!]
    IsBufferPrecisionSupported		[integer!]
    GetImageLocalBounds				[integer!]
    GetImageWorldBounds				[integer!]
    GetGlyphRunWorldBounds			[integer!]
    GetDevice						[function! [this [this!] dev [int-ptr!]]]
    SetTarget						[function! [this [this!] bmp [this!]]]
    GetTarget						[integer!]
    SetRenderingControls			[integer!]
    GetRenderingControls			[integer!]
    SetPrimitiveBlend				[integer!]
    GetPrimitiveBlend				[integer!]
    SetUnitMode						[integer!]
    GetUnitMode						[integer!]
    DrawGlyphRun2					[integer!]
    DrawImage						[DrawImage*]
    DrawGdiMetafile					[integer!]
    DrawBitmap2						[DrawBitmap*]
    PushLayer2						[integer!]
    InvalidateEffectInputRectangle	[integer!]
    GetEffectInvalidRectangleCount	[integer!]
    GetEffectInvalidRectangles		[integer!]
    GetEffectRequiredInputRectangles [integer!]
    FillOpacityMask2				[integer!]
]

ID2D1HwndRenderTarget: alias struct! [
	ID2D1RenderTarget
	CheckWindowState				[function! [this [this!] return: [integer!]]]
	Resize							[Resize*]
	GetHwnd							[integer!]
]

ID2D1DCRenderTarget: alias struct! [
	ID2D1RenderTarget
	BindDC							[function! [this [this!] hDC [handle!] rect [RECT_STRUCT] return: [integer!]]]
]

ID2D1PathGeometry: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetFactory						[integer!]
	GetBounds						[integer!]
	GetWidenedBounds				[integer!]
	StrokeContainsPoint				[integer!]
	FillContainsPoint				[integer!]
	CompareWithGeometry				[integer!]
	Simplify						[integer!]
	Tessellate						[integer!]
	CombineWithGeometry				[integer!]
	Outline							[integer!]
	ComputeArea						[integer!]
	ComputeLength					[integer!]
	ComputePointAtLength			[integer!]
	Widen							[integer!]
	Open							[function! [this [this!] sink [ptr-ptr!] return: [integer!]]]
	Stream							[function! [this [this!] sink [ptr-ptr!] return: [integer!]]]
	GetSegmentCount					[function! [this [this!] count [int-ptr!] return: [integer!]]]
	GetFigureCount					[function! [this [this!] count [int-ptr!] return: [integer!]]]
]

ID2D1GeometrySink: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetFillMode						[function! [this [this!] fill_mode [integer!] return: [integer!]]]
	SetSegmentFlags					[function! [this [this!] vertexFlags [integer!] return: [integer!]]]
	BeginFigure						[function! [this [this!] startPoint [D2D_POINT_2F value] figureBegin [integer!] return: [integer!]]]
	AddLines						[function! [this [this!] points [D2D_POINT_2F] pointsCount [integer!] return: [integer!]]]
	AddBeziers						[function! [this [this!] beziers [D2D1_BEZIER_SEGMENT] beziersCount [integer!] return: [integer!]]]
	EndFigure						[function! [this [this!] figureEnd [integer!] return: [integer!]]]
	Close							[function! [this [this!] return: [integer!]]]
	AddLine							[function! [this [this!] point [D2D_POINT_2F value] return: [integer!]]]
	AddBezier						[function! [this [this!] beziers [D2D1_BEZIER_SEGMENT] return: [integer!]]]
	AddQuadraticBezier				[function! [this [this!] bezier [D2D1_QUADRATIC_BEZIER_SEGMENT] return: [integer!]]]
	AddQuadraticBeziers				[function! [this [this!] beziers [D2D1_QUADRATIC_BEZIER_SEGMENT] beziersCount [integer!] return: [integer!]]]
	AddArc							[function! [this [this!] arc [D2D1_ARC_SEGMENT] return: [integer!]]]
]

ID2D1StrokeStyle: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
]

;-- Direct Write

DWRITE_LINE_METRICS: alias struct! [
	length					 [integer!]
	trailingWhitespaceLength [integer!]
	newlineLength			 [integer!]
	height					 [float32!]
	baseline				 [float32!]
	isTrimmed				 [logic!]
]

DWRITE_TEXT_METRICS: alias struct! [
	left			[float32!]
	top				[float32!]
	width			[float32!]
	widthTrailing	[float32!]
	height			[float32!]
	layoutWidth		[float32!]
	layoutHeight	[float32!]
	maxBidiDepth	[integer!]
	lineCount		[integer!]
]

DWRITE_HIT_TEST_METRICS: alias struct! [
	textPosition	[integer!]
	length			[integer!]
	left			[float32!]
	top				[float32!]
	width			[float32!]
	height			[float32!]
	bidiLevel		[integer!]
	isText			[logic!]
	isTrimmed		[logic!]
]

CreateTextFormat*: alias function! [
	this		[this!]
	fontName	[c-string!]
	fontCollect [integer!]
	fontWeight	[integer!]
	fontStyle	[integer!]
	fontStretch	[integer!]
	fontSize	[float32!]
	localeName	[c-string!]
	textFormat	[int-ptr!]
	return:		[integer!]
]

CreateTextLayout*: alias function! [
	this		[this!]
	string		[c-string!]
	length		[integer!]
	format		[this!]
	maxWidth	[float32!]
	maxHeight	[float32!]
	layout		[int-ptr!]
	return:		[integer!]
]

HitTestPoint*: alias function! [
	this		[this!]
	x			[float32!]
	y			[float32!]
	isTrailing	[int-ptr!]
	isInside	[int-ptr!]
	metrics		[DWRITE_HIT_TEST_METRICS]
	return:		[integer!]
]

HitTestTextPosition*: alias function! [
	this		[this!]
	pos			[integer!]
	trailing?	[logic!]
	x			[float32-ptr!]
	y			[float32-ptr!]
	metrics		[DWRITE_HIT_TEST_METRICS]
	return:		[integer!]
]

HitTestTextRange*: alias function! [
	this		[this!]
	pos			[integer!]
	len			[integer!]
	x			[float32!]
	y			[float32!]
	metrics		[DWRITE_HIT_TEST_METRICS]
	max-cnt		[integer!]
	cnt			[int-ptr!]
	return:		[integer!]
]

SetIncrementalTabStop*: alias function! [
	this		[this!]
	size		[float32!]
	return:		[integer!]
]

SetLineSpacing*: alias function! [
	this		[this!]
	method		[integer!]
	lineSpacing [float32!]
	baseline	[float32!]
	return:		[integer!]
]

GetLineSpacing*: alias function! [
	this		[this!]
	method		[int-ptr!]
	lineSpacing [float32-ptr!]
	baseline	[float32-ptr!]
	return:		[integer!]
]

IDWriteFactory: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetSystemFontCollection			[integer!]
	CreateCustomFontCollection		[integer!]
	RegisterFontCollectionLoader	[integer!]
	UnregisterFontCollectionLoader	[integer!]
	CreateFontFileReference			[integer!]
	CreateCustomFontFileReference	[integer!]
	CreateFontFace					[integer!]
	CreateRenderingParams			[integer!]
	CreateMonitorRenderingParams	[integer!]
	CreateCustomRenderingParams		[integer!]
	RegisterFontFileLoader			[integer!]
	UnregisterFontFileLoader		[integer!]
	CreateTextFormat				[CreateTextFormat*]
	CreateTypography				[integer!]
	GetGdiInterop					[integer!]
	CreateTextLayout				[CreateTextLayout*]
	CreateGdiCompatibleTextLayout	[integer!]
	CreateEllipsisTrimmingSign		[integer!]
	CreateTextAnalyzer				[integer!]
	CreateNumberSubstitution		[integer!]
	CreateGlyphRunAnalysis			[integer!]
]

IDWriteRenderingParams: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetGamma						[integer!]
	GetEnhancedContrast				[integer!]
	GetClearTypeLevel				[integer!]
	GetPixelGeometry				[integer!]
	GetRenderingMode				[integer!]
]

IDWriteTextFormat: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetTextAlignment				[function! [this [this!] align [integer!] return: [integer!]]]
	SetParagraphAlignment			[function! [this [this!] align [integer!] return: [integer!]]]
	SetWordWrapping					[function! [this [this!] mode [integer!] return: [integer!]]]
	SetReadingDirection				[integer!]
	SetFlowDirection				[integer!]
	SetIncrementalTabStop			[SetIncrementalTabStop*]
	SetTrimming						[integer!]
	SetLineSpacing					[SetLineSpacing*]
	GetTextAlignment				[integer!]
	GetParagraphAlignment			[integer!]
	GetWordWrapping					[integer!]
	GetReadingDirection				[integer!]
	GetFlowDirection				[integer!]
	GetIncrementalTabStop			[integer!]
	GetTrimming						[integer!]
	GetLineSpacing					[GetLineSpacing*]
	GetFontCollection				[integer!]
	GetFontFamilyNameLength			[integer!]
	GetFontFamilyName				[integer!]
	GetFontWeight					[integer!]
	GetFontStyle					[integer!]
	GetFontStretch					[integer!]
	GetFontSize						[integer!]
	GetLocaleNameLength				[integer!]
	GetLocaleName					[integer!]
]

IDWriteTextLayout: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	SetTextAlignment				[function! [this [this!] align [integer!] return: [integer!]]]
	SetParagraphAlignment			[function! [this [this!] align [integer!] return: [integer!]]]
	SetWordWrapping					[function! [this [this!] mode [integer!] return: [integer!]]]
	SetReadingDirection				[integer!]
	SetFlowDirection				[integer!]
	SetIncrementalTabStop			[SetIncrementalTabStop*]
	SetTrimming						[integer!]
	SetLineSpacing					[SetLineSpacing*]
	GetTextAlignment				[integer!]
	GetParagraphAlignment			[integer!]
	GetWordWrapping					[integer!]
	GetReadingDirection				[integer!]
	GetFlowDirection				[integer!]
	GetIncrementalTabStop			[integer!]
	GetTrimming						[integer!]
	GetLineSpacing					[GetLineSpacing*]
	GetFontCollection				[integer!]
	GetFontFamilyNameLength			[integer!]
	GetFontFamilyName				[integer!]
	GetFontWeight					[integer!]
	GetFontStyle					[integer!]
	GetFontStretch					[integer!]
	GetFontSize						[integer!]
	GetLocaleNameLength				[integer!]
	GetLocaleName					[integer!]
	SetMaxWidth						[integer!]
	SetMaxHeight					[integer!]
	SetFontCollection				[integer!]
	SetFontFamilyName				[function! [this [this!] name [c-string!] pos [integer!] len [integer!] return: [integer!]]]
	SetFontWeight					[function! [this [this!] weight [integer!] pos [integer!] len [integer!] return: [integer!]]]
	SetFontStyle					[function! [this [this!] style [integer!] pos [integer!] len [integer!] return: [integer!]]]
	SetFontStretch					[integer!]
	SetFontSize						[function! [this [this!] size [float32!] pos [integer!] len [integer!] return: [integer!]]]
	SetUnderline					[function! [this [this!] underline? [logic!] pos [integer!] len [integer!] return: [integer!]]]
	SetStrikethrough				[function! [this [this!] strike? [logic!] pos [integer!] len [integer!] return: [integer!]]]
	SetDrawingEffect				[function! [this [this!] effect [this!] pos [integer!] len [integer!] return: [integer!]]]
	SetInlineObject					[function! [this [this!] obj [this!] pos [integer!] len [integer!] return: [integer!]]]
	SetTypography					[integer!]
	SetLocaleName					[integer!]
	GetMaxWidth						[integer!]
	GetMaxHeight					[integer!]
	GetFontCollection				[integer!]
	GetFontFamilyNameLength			[integer!]
	GetFontFamilyName				[integer!]
	GetFontWeight					[integer!]
	GetFontStyle					[integer!]
	GetFontStretch					[integer!]
	GetFontSize						[integer!]
	GetUnderline					[integer!]
	GetStrikethrough				[integer!]
	GetDrawingEffect				[integer!]
	GetInlineObject					[integer!]
	GetTypography					[integer!]
	GetLocaleNameLength				[integer!]
	GetLocaleName					[integer!]
	Draw							[integer!]
	GetLineMetrics					[function! [this [this!] metrics [DWRITE_LINE_METRICS] count [integer!] actual-count [int-ptr!] return: [integer!]]]
	GetMetrics						[function! [this [this!] metrics [DWRITE_TEXT_METRICS] return: [integer!]]]
	GetOverhangMetrics				[integer!]
	GetClusterMetrics				[integer!]
	DetermineMinWidth				[integer!]
	HitTestPoint					[HitTestPoint*]
	HitTestTextPosition				[HitTestTextPosition*]
	HitTestTextRange				[HitTestTextRange*]
]

IDWriteFontFace: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetType							[integer!]
	GetFiles						[integer!]
	GetIndex						[integer!]
	GetSimulations					[integer!]
	IsSymbolFont					[integer!]
	GetMetrics						[integer!]
	GetGlyphCount					[integer!]
	GetDesignGlyphMetrics			[integer!]
	GetGlyphIndices					[integer!]
	TryGetFontTable					[integer!]
	ReleaseFontTable				[integer!]
	GetGlyphRunOutline				[integer!]
	GetRecommendedRenderingMode		[integer!]
	GetGdiCompatibleMetrics			[integer!]
	GetGdiCompatibleGlyphMetrics	[integer!]
]

DCompositionCreateDevice2!: alias function! [
  	render-dev	[this!]
  	iid			[int-ptr!]
	device		[int-ptr!]
	return:		[integer!]
]

D2D1CreateFactory!: alias function! [
	type		[integer!]
	riid		[int-ptr!]
	options		[int-ptr!]		;-- opt
	factory		[ptr-ptr!]
	return:		[integer!]
]

DWriteCreateFactory!: alias function! [
	type		[integer!]
	iid			[int-ptr!]
	factory		[ptr-ptr!]
	return:		[integer!]
]

GetUserDefaultLocaleName!: alias function! [
	lpLocaleName	[c-string!]
	cchLocaleName	[integer!]
	return:			[integer!]
]

render-target!: alias struct! [
	dc				[this!]
	brushes			[int-ptr!]
	brushes-cnt		[uint!]
	styles			[red-vector!]
	bitmap			[this!]
	swapchain		[this!]
	dcomp-device	[this!]
	dcomp-target	[this!]
	dcomp-visual	[this!]
]

#import [
	"d2d1.dll" stdcall [
		D2D1CreateFactory: "D2D1CreateFactory" [
			type		[integer!]
			riid		[int-ptr!]
			options		[int-ptr!]		;-- opt
			factory		[ptr-ptr!]
			return:		[integer!]
		]
		D2D1InvertMatrix: "D2D1InvertMatrix" [
			matrix		[D2D_MATRIX_3X2_F]
			return:		[logic!]
		]
	]
]

#define ConvertPointSizeToDIP(size)		(as float32! 96 * size / 72)

select-brush: func [
	target		[int-ptr!]
	color		[integer!]
	return: 	[integer!]
	/local
		brushes [int-ptr!]
		cnt		[integer!]
][
	brushes: as int-ptr! target/1
	cnt: target/2
	loop cnt [
		either brushes/value = color [
			return brushes/2
		][
			brushes: brushes + 2
		]
	]
	0
]

put-brush: func [
	target		[int-ptr!]
	color		[integer!]
	brush		[integer!]
	/local
		brushes [int-ptr!]
		cnt		[integer!]
][
	cnt: target/2
	if cnt < D2D_MAX_BRUSHES [
		brushes: (as int-ptr! target/1) + (cnt * 2)
		brushes/1: color
		brushes/2: brush
		target/2: cnt + 1
	]
]

DX-init: func [
	/local
		str					[red-string!]
		hr					[integer!]
		factory 			[ptr-value!]
		dll					[handle!]
		options				[integer!]
		DWriteCreateFactory [DWriteCreateFactory!]
		GetUserDefaultLocaleName [GetUserDefaultLocaleName!]
][
	dll: LoadLibraryA "DWrite.dll"
	if null? dll [winxp?: yes exit]
	DWriteCreateFactory: as DWriteCreateFactory! GetProcAddress dll "DWriteCreateFactory"
	dll: LoadLibraryA "kernel32.dll"
	GetUserDefaultLocaleName: as GetUserDefaultLocaleName! GetProcAddress dll "GetUserDefaultLocaleName"
	dw-locale-name: as c-string! allocate 85
	GetUserDefaultLocaleName dw-locale-name 85

	;-- create D2D factory
	options: 0													;-- debugLevel
	hr: D2D1CreateFactory 0 IID_ID2D1Factory1 :options :factory	;-- D2D1_FACTORY_TYPE_SINGLE_THREADED: 0
	assert zero? hr
	d2d-factory: as this! factory/value

	;-- create DWrite factory
	hr: DWriteCreateFactory 0 IID_IDWriteFactory :factory		;-- DWRITE_FACTORY_TYPE_SHARED: 0
	assert zero? hr
	dwrite-factory: as this! factory/value
	str: string/rs-make-at ALLOC_TAIL(root) 1024
	dwrite-str-cache: str/node

	DX-create-dev
]

DX-create-buffer: func [
	rt			[render-target!]
	swapchain	[this!]
	/local
		sc		[IDXGISwapChain1]
		this	[this!]
		hr		[integer!]
		buf		[integer!]
		props	[D2D1_BITMAP_PROPERTIES1 value]
		bmp		[integer!]
		d2d		[ID2D1DeviceContext]
		unk		[IUnknown]
][
	;-- get back buffer from the swap chain
	this: as this! swapchain
	sc: as IDXGISwapChain1 this/vtbl
	buf: 0
	hr: sc/GetBuffer this 0 IID_IDXGISurface :buf
	assert zero? hr

	;-- create a bitmap from the buffer
	props/format: 87		;-- DXGI_FORMAT_B8G8R8A8_UNORM
	props/alphaMode: 1		;-- D2D1_ALPHA_MODE_PREMULTIPLIED
	props/dpiX: dpi-x
	props/dpiY: dpi-y
	props/options: 3		;-- D2D1_BITMAP_OPTIONS_TARGET or D2D1_BITMAP_OPTIONS_CANNOT_DRAW
	props/colorContext: null
	bmp: 0
	d2d: as ID2D1DeviceContext d2d-ctx/vtbl
	d2d/setDpi d2d-ctx dpi-x dpi-y
	hr: d2d/CreateBitmapFromDxgiSurface d2d-ctx as int-ptr! buf props :bmp
	assert hr = 0
	
	rt/dc: d2d-ctx
	rt/swapchain: swapchain
	rt/bitmap: as this! bmp

	COM_SAFE_RELEASE_OBJ(unk buf)
]

DX-resize-buffer: func [
	rt				[render-target!]
	width			[uint!]
	height			[uint!]
	/local
		unk			[IUnknown]
		this		[this!]
		sc			[IDXGISwapChain1]
		hr			[integer!]
][
	COM_SAFE_RELEASE(unk rt/bitmap)

	this: rt/swapchain
	sc: as IDXGISwapChain1 this/vtbl
	hr: sc/ResizeBuffers this 0 width height 87 0
	if hr <> 0 [probe "resizing failed" exit]

	DX-create-buffer rt this
]

DX-create-dev: func [
	/local
		factory 			[ptr-value!]
		d2d					[ID2D1Factory]
		d3d					[ID3D11Device]
		d2d-dev				[ID2D1Device]
		dxgi				[IDXGIDevice1]
		adapter				[IDXGIAdapter]
		ctx					[ptr-value!]
		unk					[IUnknown]
		d2d-device			[this!]
		hr					[integer!]
		dll					[handle!]
][
	if win8+? [
		dll: LoadLibraryA "dcomp.dll"
		pfnDCompositionCreateDevice2: GetProcAddress dll "DCompositionCreateDevice2"
	]

	hr: D3D11CreateDevice
		null
		1		;-- D3D_DRIVER_TYPE_HARDWARE
		null
		33		;-- D3D11_CREATE_DEVICE_BGRA_SUPPORT or D3D11_CREATE_DEVICE_SINGLETHREADED
		null
		0
		7		;-- D3D11_SDK_VERSION
		:factory
		null
		:ctx
	assert zero? hr

	d3d-device: as this! factory/value
	d3d-ctx: as this! ctx/value

	d3d: as ID3D11Device d3d-device/vtbl
	;-- create DXGI device
	hr: d3d/QueryInterface d3d-device IID_IDXGIDevice1 as interface! :factory	
	assert zero? hr
	dxgi-device: as this! factory/value

	;-- get system DPI
	d2d: as ID2D1Factory d2d-factory/vtbl
	;d2d/GetDesktopDpi d2d-factory :dpi-x :dpi-y

	dpi-x: as float32! log-pixels-x
	dpi-y: as float32! log-pixels-y
	dpi-value: dpi-y

	;-- create D2D Device
	hr: d2d/CreateDevice d2d-factory as int-ptr! dxgi-device :factory
	d2d-device: as this! factory/value
	assert zero? hr

	;-- create D2D context
	d2d-dev: as ID2D1Device d2d-device/vtbl
	hr: d2d-dev/CreateDeviceContext d2d-device 0 :factory
	assert zero? hr
	d2d-ctx: as this! factory/value

	;-- get dxgi adapter
	dxgi: as IDXGIDevice1 dxgi-device/vtbl
	hr: dxgi/GetAdapter dxgi-device :factory
	assert zero? hr

	;-- get Dxgi factory
	dxgi-adapter: as this! factory/value
	adapter: as IDXGIAdapter dxgi-adapter/vtbl
	hr: adapter/GetParent dxgi-adapter IID_IDXGIFactory2 :factory
	assert zero? hr
	dxgi-factory: as this! factory/value

	COM_SAFE_RELEASE(unk dxgi-device)
	COM_SAFE_RELEASE(unk d2d-device)
	COM_SAFE_RELEASE(unk dxgi-adapter)	
]

DX-release-dev: func [
	/local
		unk		[IUnknown]
][
	COM_SAFE_RELEASE(unk d2d-ctx)
	COM_SAFE_RELEASE(unk d3d-ctx)
	COM_SAFE_RELEASE(unk d3d-device)
	COM_SAFE_RELEASE(unk dxgi-factory)
]

DX-cleanup: func [/local unk [IUnknown]][
	COM_SAFE_RELEASE(unk dwrite-factory)
	COM_SAFE_RELEASE(unk d2d-factory)
	free as byte-ptr! dw-locale-name
]

logical-to-pixel: func [
	num		[float32!]
	return: [integer!]
][
	as-integer (num * dpi-value / as-float32 96.0)
]

pixel-to-logical: func [
	num		[integer!]
	return: [float32!]
][
	(as-float32 num * 96) / dpi-value
]

create-dcomp: func [
	target			[render-target!]
	hWnd			[handle!]
	/local
		dev			[integer!]
		d2d-device	[this!]
		hr			[integer!]
		unk			[IUnknown]
		dcomp-dev	[IDCompositionDevice]
		dcomp		[IDCompositionTarget]
		this		[this!]
		tg			[this!]
		visual		[IDCompositionVisual]
		d2d-dc		[ID2D1DeviceContext]
		DCompositionCreateDevice2 [DCompositionCreateDevice2!]
][
	dev: 0
	d2d-dc: as ID2D1DeviceContext d2d-ctx/vtbl
	d2d-dc/GetDevice d2d-ctx :dev
	d2d-device: as this! dev
	DCompositionCreateDevice2: as DCompositionCreateDevice2! pfnDCompositionCreateDevice2
	hr: DCompositionCreateDevice2 d2d-device IID_IDCompositionDevice :dev
	COM_SAFE_RELEASE(unk d2d-device)
	assert hr = 0

	this: as this! dev
	target/dcomp-device: this

	dcomp-dev: as IDCompositionDevice this/vtbl
	hr: dcomp-dev/CreateTargetForHwnd this hWnd yes :dev
	assert zero? hr
	tg: as this! dev
	target/dcomp-target: tg

	hr: dcomp-dev/CreateVisual this :dev
	assert zero? hr
	this: as this! dev
	target/dcomp-visual: this

	visual: as IDCompositionVisual this/vtbl
	visual/SetContent this target/swapchain

	dcomp: as IDCompositionTarget tg/vtbl
	hr: dcomp/SetRoot tg this
	assert zero? hr
	hr: dcomp-dev/Commit target/dcomp-device
	assert zero? hr
]

create-render-target: func [
	hWnd		[handle!]
	rt			[render-target!]
	/local
		rc		[RECT_STRUCT value]
		desc	[DXGI_SWAP_CHAIN_DESC1 value]
		dxgi	[IDXGIFactory2]
		int		[integer!]
		sc		[IDXGISwapChain1]
		this	[this!]
		hr		[integer!]
		buf		[integer!]
		props	[D2D1_BITMAP_PROPERTIES1 value]
		bmp		[integer!]
		unk		[IUnknown]
][
	GetClientRect hWnd :rc
	zero-memory as byte-ptr! :desc size? DXGI_SWAP_CHAIN_DESC1

	desc/Width: rc/right - rc/left
	desc/Height: rc/bottom - rc/top
	desc/Format: 87			;-- DXGI_FORMAT_B8G8R8A8_UNORM
	desc/SampleCount: 1
	desc/BufferUsage: 20h	;-- DXGI_USAGE_RENDER_TARGET_OUTPUT
	desc/BufferCount: 2
	desc/AlphaMode: 1		;-- DXGI_ALPHA_MODE_PREMULTIPLIED
	desc/SwapEffect: 3		;-- DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL

	int: 0
	buf: 0
	dxgi: as IDXGIFactory2 dxgi-factory/vtbl
	either win8+? [			;-- use direct composition
		hr: dxgi/CreateSwapChainForComposition dxgi-factory d3d-device desc null :int
	][
		desc/AlphaMode: 0
		hr: dxgi/CreateSwapChainForHwnd dxgi-factory d3d-device hWnd desc null null :int
	]
	assert zero? hr

	DX-create-buffer rt as this! int

	if win8+? [create-dcomp rt hWnd]
	rt
]

to-dx-color: func [
	color	[integer!]
	clr-ptr [D3DCOLORVALUE]
	return: [D3DCOLORVALUE]
	/local
		c	[D3DCOLORVALUE]
][
	either null? clr-ptr [
		c: declare D3DCOLORVALUE
	][
		c: clr-ptr
	]
	c/r: (as float32! color and FFh) / 255.0
	c/g: (as float32! color >> 8 and FFh) / 255.0
	c/b: (as float32! color >> 16 and FFh) / 255.0
	c/a: (as float32! 255 - (color >>> 24)) / 255.0
	c
]

d2d-release-target: func [
	target	[render-target!]
	/local
		rt		[ID2D1HwndRenderTarget]
		brushes [int-ptr!]
		cnt		[integer!]
		this	[this!]
		obj		[IUnknown]
][
	brushes: target/brushes
	cnt: target/brushes-cnt
	target/brushes-cnt: 0
	loop cnt [
		COM_SAFE_RELEASE_OBJ(obj brushes/2)
		brushes: brushes + 2
	]
	COM_SAFE_RELEASE(obj target/bitmap)
	COM_SAFE_RELEASE(obj target/swapchain)
	COM_SAFE_RELEASE(obj target/dcomp-visual)
	COM_SAFE_RELEASE(obj target/dcomp-target)
	COM_SAFE_RELEASE(obj target/dcomp-device)
	free as byte-ptr! target
]

create-hwnd-render-target: func [
	hwnd	[handle!]
	return: [this!]
	/local
		props		[D2D1_RENDER_TARGET_PROPERTIES value]
		options		[integer!]
		height		[integer!]
		width		[integer!]
		wnd			[integer!]
		hprops		[D2D1_HWND_RENDER_TARGET_PROPERTIES]
		bottom		[integer!]
		right		[integer!]
		top			[integer!]
		left		[integer!]
		factory		[ID2D1Factory]
		rt			[ID2D1HwndRenderTarget]
		target		[ptr-value!]
		hr			[integer!]
][
	left: 0 top: 0 right: 0 bottom: 0
	GetClientRect hwnd as RECT_STRUCT :left
	wnd: as-integer hwnd
	width: right - left
	height: bottom - top
	options: 1						;-- D2D1_PRESENT_OPTIONS_RETAIN_CONTENTS: 1
	hprops: as D2D1_HWND_RENDER_TARGET_PROPERTIES :wnd

	zero-memory as byte-ptr! :props size? D2D1_RENDER_TARGET_PROPERTIES
	props/dpiX: as float32! log-pixels-x
	props/dpiY: as float32! log-pixels-y

	factory: as ID2D1Factory d2d-factory/vtbl
	hr: factory/CreateHwndRenderTarget d2d-factory :props hprops :target
	if hr <> 0 [return null]
	as this! target/value
]

get-hwnd-render-target: func [
	hWnd	[handle!]
	return:	[render-target!]
	/local
		target	[render-target!]
][
	target: as render-target! GetWindowLong hWnd wc-offset - 24
	if null? target [
		target: as render-target! alloc0 size? render-target!
		create-render-target hWnd target
		target/brushes: as int-ptr! allocate D2D_MAX_BRUSHES * 2 * size? int-ptr!
		SetWindowLong hWnd wc-offset - 24 as-integer target
	]
	target
]

create-dc-render-target: func [
	dc		[handle!]
	rc		[RECT_STRUCT]
	return: [this!]
	/local
		props		[D2D1_RENDER_TARGET_PROPERTIES value]
		factory		[ID2D1Factory]
		rt			[ID2D1DCRenderTarget]
		IRT			[this!]
		target		[integer!]
		hr			[integer!]
][
	props/type: 0									;-- D2D1_RENDER_TARGET_TYPE_DEFAULT
	props/format: 87								;-- DXGI_FORMAT_B8G8R8A8_UNORM
	props/alphaMode: 1								;-- D2D1_ALPHA_MODE_PREMULTIPLIED
	props/dpiX: as float32! log-pixels-x
	props/dpiY: as float32! log-pixels-y
	props/usage: 2									;-- D2D1_RENDER_TARGET_USAGE_GDI_COMPATIBLE
	props/minLevel: 0								;-- D2D1_FEATURE_LEVEL_DEFAULT

	target: 0
	factory: as ID2D1Factory d2d-factory/vtbl
	hr: factory/CreateDCRenderTarget d2d-factory :props :target
	if hr <> 0 [return null]

	IRT: as this! target
	rt: as ID2D1DCRenderTarget IRT/vtbl
	hr: rt/BindDC IRT dc rc
	if hr <> 0 [rt/Release IRT return null]
	IRT
]

create-text-format: func [
	font	[red-object!]
	face	[red-object!]
	return: [integer!]
	/local
		values	[red-value!]
		h-font	[red-handle!]
		int		[red-integer!]
		value	[red-value!]
		w		[red-word!]
		str		[red-string!]
		blk		[red-block!]
		weight	[integer!]
		style	[integer!]
		size	[float32!]
		len		[integer!]
		sym		[integer!]
		name	[c-string!]
		format	[integer!]
		factory [IDWriteFactory]
		save?	[logic!]
][
	weight:	400
	style:  0
	either TYPE_OF(font) = TYPE_OBJECT [
		save?: yes
		values: object/get-values font
		blk: as red-block! values + FONT_OBJ_STATE
		if TYPE_OF(blk) <> TYPE_BLOCK [
			block/make-at blk 2
			none/make-in blk
			none/make-in blk
		]

		value: block/rs-head blk
		h-font: (as red-handle! value) + 1
		if TYPE_OF(h-font) = TYPE_HANDLE [
			return h-font/value
		]

		if TYPE_OF(value) = TYPE_NONE [make-font face font]	;-- make a GDI font

		int: as red-integer! values + FONT_OBJ_SIZE
		len: either TYPE_OF(int) <> TYPE_INTEGER [10][int/value]
		size: ConvertPointSizeToDIP(len)

		str: as red-string! values + FONT_OBJ_NAME
		name: either TYPE_OF(str) = TYPE_STRING [
			len: string/rs-length? str
			if len > 31 [len: 31]
			unicode/to-utf16-len str :len yes
		][null]
		
		w: as red-word! values + FONT_OBJ_STYLE
		len: switch TYPE_OF(w) [
			TYPE_BLOCK [
				blk: as red-block! w
				w: as red-word! block/rs-head blk
				len: block/rs-length? blk
			]
			TYPE_WORD  [1]
			default	   [0]
		]

		unless zero? len [
			loop len [
				sym: symbol/resolve w/symbol
				case [
					sym = _bold	 	 [weight:  700]
					sym = _italic	 [style:	 2]
					true			 [0]
				]
				w: w + 1
			]
		]
	][
		save?: no
		int: as red-integer! #get system/view/fonts/size
		str: as red-string!  #get system/view/fonts/system
		size: ConvertPointSizeToDIP(int/value)
		name: unicode/to-utf16 str
	]

	format: 0
	factory: as IDWriteFactory dwrite-factory/vtbl
	factory/CreateTextFormat dwrite-factory name 0 weight style 5 size dw-locale-name :format
	if save? [handle/make-at as red-value! h-font format]
	format
]

set-text-format: func [
	fmt		[this!]
	para	[red-object!]
	/local
		flags	[integer!]
		h-align [integer!]
		v-align [integer!]
		wrap	[integer!]
		format	[IDWriteTextFormat]
][
	flags: either TYPE_OF(para) = TYPE_OBJECT [
		get-para-flags base para
	][
		0
	]
	case [
		flags and 1 <> 0 [h-align: 2]
		flags and 2 <> 0 [h-align: 1]
		true			 [h-align: 0]
	]
	case [
		flags and 4 <> 0 [v-align: 2]
		flags and 8 <> 0 [v-align: 1]
		true			 [v-align: 0]
	]
	wrap: either flags and 20h = 0 [0][1]

	format: as IDWriteTextFormat fmt/vtbl
	format/SetTextAlignment fmt h-align
	format/SetParagraphAlignment fmt v-align
	format/SetWordWrapping fmt wrap
]

set-tab-size: func [
	fmt		[this!]
	size	[red-integer!]
	/local
		t	[integer!]
		tf	[IDWriteTextFormat]
][
	t: TYPE_OF(size)
	if any [t = TYPE_INTEGER t = TYPE_FLOAT][
		tf: as IDWriteTextFormat fmt/vtbl
		tf/SetIncrementalTabStop fmt get-float32 size
	]
]

set-line-spacing: func [
	fmt		[this!]
	int		[red-integer!]
	/local
		IUnk			[IUnknown]
		dw				[IDWriteFactory]
		lay				[integer!]
		layout			[this!]
		lineCount		[integer!]
		maxBidiDepth	[integer!]
		baseline		[float32!]
		height			[float32!]
		width			[float32!]
		top				[float32!]
		left			[integer!]
		tf				[IDWriteTextFormat]
		dl				[IDWriteTextLayout]
		lm				[DWRITE_LINE_METRICS]
		type			[integer!]
][
	type: TYPE_OF(int)
	if all [type <> TYPE_INTEGER type <> TYPE_FLOAT][exit]

	left: 73 lineCount: 0 lay: 0 
	dw: as IDWriteFactory dwrite-factory/vtbl
	dw/CreateTextLayout dwrite-factory as c-string! :left 1 fmt FLT_MAX FLT_MAX :lay
	layout: as this! lay
	dl: as IDWriteTextLayout layout/vtbl
	lm: as DWRITE_LINE_METRICS :left
	dl/GetLineMetrics layout lm 1 :lineCount
	tf: as IDWriteTextFormat fmt/vtbl
	tf/SetLineSpacing fmt 1 get-float32 int lm/baseline
	COM_SAFE_RELEASE(IUnk layout)
]

create-text-layout: func [
	text	[red-string!]
	fmt		[this!]
	width	[integer!]
	height	[integer!]
	return: [this!]
	/local
		str	[c-string!]
		len	[integer!]
		dw	[IDWriteFactory]
		w	[float32!]
		h	[float32!]
		lay	[integer!]
][
	len: -1
	either TYPE_OF(text) = TYPE_STRING [
		if null? text/cache [text/cache: dwrite-str-cache]
		str: unicode/to-utf16-len text :len no
	][
		str: ""
		len: 0
	]
	lay: 0
	w: either zero? width  [FLT_MAX][as float32! width]
	h: either zero? height [FLT_MAX][as float32! height]

	dw: as IDWriteFactory dwrite-factory/vtbl
	dw/CreateTextLayout dwrite-factory str len fmt w h :lay
	as this! lay
]

draw-text-d2d: func [
	dc		[handle!]
	text	[red-string!]
	font	[red-object!]
	para	[red-object!]
	rc		[RECT_STRUCT]
	/local
		this	[this!]
		this2	[this!]
		fmt		[this!]
		layout	[this!]
		obj		[IUnknown]
		rt		[ID2D1DCRenderTarget]
		dwrite	[IDWriteFactory]
		brush	[ptr-value!]
		color	[red-tuple!]
		clr		[integer!]
		m		[D2D_MATRIX_3X2_F value]
][
	fmt: as this! create-text-format font null
	set-text-format fmt para

	layout: create-text-layout text fmt rc/right rc/bottom

	this: create-dc-render-target dc rc
	rt: as ID2D1DCRenderTarget this/vtbl
	rt/SetTextAntialiasMode this 1					;-- ClearType

	rt/BeginDraw this
	matrix2d/identity m
	rt/SetTransform this :m							;-- set to identity matrix

	clr: either TYPE_OF(font) = TYPE_OBJECT [
		color: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
		color/array1
	][
		0											;-- black
	]
	rt/CreateSolidColorBrush this to-dx-color clr null null :brush
	rt/DrawTextLayout this as float32! 0.0 as float32! 0.0 layout as this! brush/value 0
	rt/EndDraw this null null

	this2: as this! brush/value
	COM_SAFE_RELEASE(obj this2)
	COM_SAFE_RELEASE(obj layout)
	COM_SAFE_RELEASE(obj fmt)
	rt/Release this
]

render-text-d2d: func [
	values	[red-value!]				;-- face! values
	hDC		[handle!]
	rc		[RECT_STRUCT]
	return: [logic!]
	/local
		font	[red-object!]
		para	[red-object!]
		text	[red-string!]
][
	text: as red-string! values + FACE_OBJ_TEXT
	either TYPE_OF(text) = TYPE_STRING [
		font: as red-object! values + FACE_OBJ_FONT
		para: as red-object! values + FACE_OBJ_PARA
		draw-text-d2d hDC text font para rc
		true
	][
		false
	]
]

render-target-lost?: func [
	target	[this!]
	return: [logic!]
	/local
		rt	 [ID2D1HwndRenderTarget]
		hr	 [integer!]
][
	rt: as ID2D1HwndRenderTarget target/vtbl
	rt/BeginDraw target
	rt/Clear target to-dx-color 0 null
	0 <> rt/EndDraw target null null
]