Red/System [
	Title:	"Direct2D structures and functions"
	Author: "Xie Qingtian"
	File: 	%direct2d.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

d2d-factory:	as this! 0
dwrite-factory: as this! 0
dw-locale-name: as c-string! 0

dwrite-str-cache: as c-string! 0

#define D2D_MAX_BRUSHES 64

#define D2DERR_RECREATE_TARGET 8899000Ch
#define FLT_MAX	[as float32! 3.402823466e38]

IID_ID2D1Factory:		[06152247h 465A6F50h 8B114592h 07603BFDh]
IID_IDWriteFactory:		[B859EE5Ah 4B5BD838h DC1AE8A2h 48DB937Dh]

D2D1_FACTORY_OPTIONS: alias struct! [
	debugLevel	[integer!]
]

D3DCOLORVALUE: alias struct! [
	r			[float32!]
	g			[float32!]
	b			[float32!]
	a			[float32!]
]

D2D_RECT_F: alias struct! [
	left		[float32!]
	top			[float32!]
	right		[float32!]
	bottom		[float32!]
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

D2D1_BRUSH_PROPERTIES: alias struct! [
	opacity				[float32!]
	transform._11		[float32!]
	transform._12		[float32!]
	transform._21		[float32!]
	transform._22		[float32!]
	transform._31		[float32!]
	transform._32		[float32!]
]

D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES: alias struct! [
	center.x			[float32!]
	center.y			[float32!]
	offset.x			[float32!]
	offset.y			[float32!]
	radius.x			[float32!]
	radius.y			[float32!]
]

CreateSolidColorBrush*: alias function! [
	this		[this!]
	color		[D3DCOLORVALUE]
	properties	[D2D1_BRUSH_PROPERTIES]
	brush		[int-ptr!]
	return:		[integer!]
]

CreateRadialGradientBrush*: alias function! [
	this		[this!]
	gprops		[D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES]
	props		[D2D1_BRUSH_PROPERTIES]
	stops		[integer!]
	brush		[int-ptr!]
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
	brush		[integer!]
	width		[float32!]
	style		[integer!]
]

FillRectangle*: alias function! [
	this		[this!]
	rect		[D2D_RECT_F]
	brush		[integer!]
]

DrawEllipse*: alias function! [
	this		[this!]
	ellipse		[D2D1_ELLIPSE]
	brush		[integer!]
	width		[float32!]
	style		[integer!]
]

FillEllipse*: alias function! [
	this		[this!]
	ellipse		[D2D1_ELLIPSE]
	brush		[integer!]
]

DrawTextLayout*: alias function! [
	this		[this!]
	x			[float32!]
	y			[float32!]
	layout		[this!]
	brush		[integer!]
	options		[integer!]
]

SetTransform*: alias function! [
	this		[this!]
	transform	[D2D_MATRIX_3X2_F]
]

Resize*: alias function! [
	this		[this!]
	pixelSize	[tagSIZE]
	return:		[integer!]
]

ID2D1SolidColorBrush: alias struct! [
	QueryInterface		[QueryInterface!]
	AddRef				[AddRef!]
	Release				[Release!]
	GetFactory			[integer!]
	SetOpacity			[integer!]
	SetTransform		[SetTransform*]
	GetOpacity			[integer!]
	GetTransform		[integer!]
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
	GetTransform				[integer!]
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
	CreatePathGeometry				[integer!]
	CreateStrokeStyle				[integer!]
	CreateDrawingStateBlock			[integer!]
	CreateWicBitmapRenderTarget		[integer!]
	CreateHwndRenderTarget			[function! [this [this!] properties [D2D1_RENDER_TARGET_PROPERTIES] hwndProperties [D2D1_HWND_RENDER_TARGET_PROPERTIES] target [int-ptr!] return: [integer!]]]
	CreateDxgiSurfaceRenderTarget	[integer!]
	CreateDCRenderTarget			[function! [this [this!] properties [D2D1_RENDER_TARGET_PROPERTIES] target [int-ptr!] return: [integer!]]]
]

ID2D1HwndRenderTarget: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetFactory						[integer!]
	CreateBitmap					[integer!]
	CreateBitmapFromWicBitmap		[integer!]
	CreateSharedBitmap				[integer!]
	CreateBitmapBrush				[integer!]
	CreateSolidColorBrush			[CreateSolidColorBrush*]
	CreateGradientStopCollection	[CreateGradientStopCollection*]
	CreateLinearGradientBrush		[integer!]
	CreateRadialGradientBrush		[CreateRadialGradientBrush*]
	CreateCompatibleRenderTarget	[integer!]
	CreateLayer						[integer!]
	CreateMesh						[integer!]
	DrawLine						[DrawLine*]
	DrawRectangle					[integer!]
	FillRectangle					[FillRectangle*]
	DrawRoundedRectangle			[integer!]
	FillRoundedRectangle			[integer!]
	DrawEllipse						[DrawEllipse*]
	FillEllipse						[FillEllipse*]
	DrawGeometry					[integer!]
	FillGeometry					[integer!]
	FillMesh						[integer!]
	FillOpacityMask					[integer!]
	DrawBitmap						[integer!]
	DrawText						[integer!]
	DrawTextLayout					[DrawTextLayout*]
	DrawGlyphRun					[integer!]
	SetTransform					[SetTransform*]
	GetTransform					[integer!]
	SetAntialiasMode				[integer!]
	GetAntialiasMode				[integer!]
	SetTextAntialiasMode			[function! [this [this!] mode [integer!]]]
	GetTextAntialiasMode			[integer!]
	SetTextRenderingParams			[integer!]
	GetTextRenderingParams			[integer!]
	SetTags							[integer!]
	GetTags							[integer!]
	PushLayer						[integer!]
	PopLayer						[integer!]
	Flush							[integer!]
	SaveDrawingState				[integer!]
	RestoreDrawingState				[integer!]
	PushAxisAlignedClip				[integer!]
	PopAxisAlignedClip				[integer!]
	Clear							[function! [this [this!] color [D3DCOLORVALUE]]]
	BeginDraw						[function! [this [this!]]]
	EndDraw							[function! [this [this!] tag1 [int-ptr!] tag2 [int-ptr!] return: [integer!]]]
	GetPixelFormat					[integer!]
	SetDpi							[integer!]
	GetDpi							[integer!]
	GetSize							[integer!]
	GetPixelSize					[integer!]
	GetMaximumBitmapSize			[integer!]
	IsSupported						[integer!]
	CheckWindowState				[function! [this [this!] return: [integer!]]]
	Resize							[Resize*]
	GetHwnd							[integer!]
]

ID2D1DCRenderTarget: alias struct! [
	QueryInterface					[QueryInterface!]
	AddRef							[AddRef!]
	Release							[Release!]
	GetFactory						[integer!]
	CreateBitmap					[integer!]
	CreateBitmapFromWicBitmap		[integer!]
	CreateSharedBitmap				[integer!]
	CreateBitmapBrush				[integer!]
	CreateSolidColorBrush			[CreateSolidColorBrush*]
	CreateGradientStopCollection	[CreateGradientStopCollection*]
	CreateLinearGradientBrush		[integer!]
	CreateRadialGradientBrush		[CreateRadialGradientBrush*]
	CreateCompatibleRenderTarget	[integer!]
	CreateLayer						[integer!]
	CreateMesh						[integer!]
	DrawLine						[DrawLine*]
	DrawRectangle					[integer!]
	FillRectangle					[FillRectangle*]
	DrawRoundedRectangle			[integer!]
	FillRoundedRectangle			[integer!]
	DrawEllipse						[DrawEllipse*]
	FillEllipse						[FillEllipse*]
	DrawGeometry					[integer!]
	FillGeometry					[integer!]
	FillMesh						[integer!]
	FillOpacityMask					[integer!]
	DrawBitmap						[integer!]
	DrawText						[integer!]
	DrawTextLayout					[DrawTextLayout*]
	DrawGlyphRun					[integer!]
	SetTransform					[SetTransform*]
	GetTransform					[integer!]
	SetAntialiasMode				[integer!]
	GetAntialiasMode				[integer!]
	SetTextAntialiasMode			[function! [this [this!] mode [integer!]]]
	GetTextAntialiasMode			[integer!]
	SetTextRenderingParams			[integer!]
	GetTextRenderingParams			[integer!]
	SetTags							[integer!]
	GetTags							[integer!]
	PushLayer						[integer!]
	PopLayer						[integer!]
	Flush							[integer!]
	SaveDrawingState				[integer!]
	RestoreDrawingState				[integer!]
	PushAxisAlignedClip				[integer!]
	PopAxisAlignedClip				[integer!]
	Clear							[function! [this [this!] color [D3DCOLORVALUE]]]
	BeginDraw						[function! [this [this!]]]
	EndDraw							[function! [this [this!] tag1 [int-ptr!] tag2 [int-ptr!] return: [integer!]]]
	GetPixelFormat					[integer!]
	SetDpi							[integer!]
	GetDpi							[integer!]
	GetSize							[integer!]
	GetPixelSize					[integer!]
	GetMaximumBitmapSize			[integer!]
	IsSupported						[integer!]
	BindDC							[function! [this [this!] hDC [handle!] rect [RECT_STRUCT] return: [integer!]]]
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
	SetIncrementalTabStop			[integer!]
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
	SetIncrementalTabStop			[integer!]
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

D2D1CreateFactory!: alias function! [
	type		[integer!]
	riid		[int-ptr!]
	options		[int-ptr!]		;-- opt
	factory		[int-ptr!]
	return:		[integer!]
]

DWriteCreateFactory!: alias function! [
	type		[integer!]
	iid			[int-ptr!]
	factory		[int-ptr!]
	return:		[integer!]
]

GetUserDefaultLocaleName!: alias function! [
	lpLocaleName	[c-string!]
	cchLocaleName	[integer!]
	return:			[integer!]
]

#define ConvertPointSizeToDIP(size)		(as float32! 96.0 / 72.0 * size)

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
	brushes: (as int-ptr! target/1) + (cnt * 2)
	brushes/1: color
	brushes/2: brush
	target/2: cnt + 1 % D2D_MAX_BRUSHES
]

DX-init: func [
	/local
		node				[node!]
		s					[series!]
		hr					[integer!]
		factory 			[integer!]
		dll					[handle!]
		options				[integer!]
		D2D1CreateFactory	[D2D1CreateFactory!]
		DWriteCreateFactory [DWriteCreateFactory!]
		GetUserDefaultLocaleName [GetUserDefaultLocaleName!]
][
	dll: LoadLibraryA "d2d1.dll"
	if null? dll [winxp?: yes exit]
	D2D1CreateFactory: as D2D1CreateFactory! GetProcAddress dll "D2D1CreateFactory"
	dll: LoadLibraryA "DWrite.dll"
	if null? dll [winxp?: yes exit]
	DWriteCreateFactory: as DWriteCreateFactory! GetProcAddress dll "DWriteCreateFactory"
	dll: LoadLibraryA "kernel32.dll"
	GetUserDefaultLocaleName: as GetUserDefaultLocaleName! GetProcAddress dll "GetUserDefaultLocaleName"
	dw-locale-name: as c-string! allocate 85
	GetUserDefaultLocaleName dw-locale-name 85

	factory: 0
	options: 0													;-- debugLevel
	hr: D2D1CreateFactory 0 IID_ID2D1Factory :options :factory	;-- D2D1_FACTORY_TYPE_SINGLE_THREADED: 0
	assert zero? hr
	d2d-factory: as this! factory
	hr: DWriteCreateFactory 0 IID_IDWriteFactory :factory		;-- DWRITE_FACTORY_TYPE_SHARED: 0
	assert zero? hr
	dwrite-factory: as this! factory
	node: alloc-bytes 1024
	s: as series! node/value
	dwrite-str-cache: as-c-string s/offset
]

DX-cleanup: func [/local unk [IUnknown]][
	COM_SAFE_RELEASE(unk dwrite-factory)
	COM_SAFE_RELEASE(unk d2d-factory)
	free as byte-ptr! dw-locale-name
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
	target	[int-ptr!]
	/local
		rt		[ID2D1HwndRenderTarget]
		brushes [int-ptr!]
		cnt		[integer!]
		this	[this!]
		obj		[IUnknown]
][
	brushes: as int-ptr! target/2
	cnt: target/3
	loop cnt [
		COM_SAFE_RELEASE_OBJ(obj brushes/2)
		brushes: brushes + 2
	]
	this: as this! target/1
	rt: as ID2D1HwndRenderTarget this/vtbl
	rt/Release this
	free as byte-ptr! target
]

create-hwnd-render-target: func [
	hwnd	[handle!]
	return: [this!]
	/local
		type		[integer!]
		format		[integer!]
		alphaMode	[integer!]
		dpiX		[integer!]
		dpiY		[integer!]
		usage		[integer!]
		minLevel	[integer!]
		props		[D2D1_RENDER_TARGET_PROPERTIES]
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
		target		[integer!]
		hr			[integer!]
][
	left: 0 top: 0 right: 0 bottom: 0
	GetClientRect hwnd as RECT_STRUCT :left
	wnd: as-integer hwnd
	width: right - left
	height: bottom - top
	options: 1						;-- D2D1_PRESENT_OPTIONS_RETAIN_CONTENTS: 1
	hprops: as D2D1_HWND_RENDER_TARGET_PROPERTIES :wnd

	minLevel: 0
	props: as D2D1_RENDER_TARGET_PROPERTIES :minLevel
	zero-memory as byte-ptr! props size? D2D1_RENDER_TARGET_PROPERTIES

	target: 0
	factory: as ID2D1Factory d2d-factory/vtbl
	hr: factory/CreateHwndRenderTarget d2d-factory props hprops :target
	if hr <> 0 [return null]
	as this! target
]

get-hwnd-render-target: func [
	hWnd	[handle!]
	return:	[int-ptr!]
	/local
		target	[int-ptr!]
][
	target: as int-ptr! GetWindowLong hWnd wc-offset - 24
	if null? target [
		target: as int-ptr! allocate 8 * size? int-ptr!
		target/1: as-integer create-hwnd-render-target hWnd
		target/2: as-integer allocate D2D_MAX_BRUSHES * 2 * size? int-ptr!
		target/3: 0
		target/4: 0			;-- for text-box! background color
		SetWindowLong hWnd wc-offset - 24 as-integer target
	]
	target
]

create-dc-render-target: func [
	dc		[handle!]
	rc		[RECT_STRUCT]
	return: [this!]
	/local
		type		[integer!]
		format		[integer!]
		alphaMode	[integer!]
		dpiX		[integer!]
		dpiY		[integer!]
		usage		[integer!]
		minLevel	[integer!]
		props		[D2D1_RENDER_TARGET_PROPERTIES]
		factory		[ID2D1Factory]
		rt			[ID2D1DCRenderTarget]
		IRT			[this!]
		target		[integer!]
		hr			[integer!]
][
	minLevel: 0
	props: as D2D1_RENDER_TARGET_PROPERTIES :minLevel
	props/type: 0									;-- D2D1_RENDER_TARGET_TYPE_DEFAULT
	props/format: 87								;-- DXGI_FORMAT_B8G8R8A8_UNORM
	props/alphaMode: 1								;-- D2D1_ALPHA_MODE_PREMULTIPLIED
	props/dpiX: as float32! log-pixels-x
	props/dpiY: as float32! log-pixels-y
	props/usage: 2									;-- D2D1_RENDER_TARGET_USAGE_GDI_COMPATIBLE
	props/minLevel: 0								;-- D2D1_FEATURE_LEVEL_DEFAULT

	target: 0
	factory: as ID2D1Factory d2d-factory/vtbl
	hr: factory/CreateDCRenderTarget d2d-factory props :target
	if hr <> 0 [return null]

	IRT: as this! target
	rt: as ID2D1DCRenderTarget IRT/vtbl
	hr: rt/BindDC IRT dc rc
	if hr <> 0 [rt/Release IRT return null]
	IRT
]

create-text-format: func [
	font	[red-object!]
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
		f		[float!]
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

		h-font: (as red-handle! block/rs-head blk) + 1
		if TYPE_OF(h-font) = TYPE_HANDLE [
			return h-font/value
		]

		make-font null font				;-- always make a GDI font

		int: as red-integer! values + FONT_OBJ_SIZE
		len: either TYPE_OF(int) <> TYPE_INTEGER [10][int/value]
		f: as-float len
		size: ConvertPointSizeToDIP(f)

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
		f: as-float int/value
		size: ConvertPointSizeToDIP(f)
		name: unicode/to-utf16 str
	]

	format: 0
	factory: as IDWriteFactory dwrite-factory/vtbl
	factory/CreateTextFormat dwrite-factory name 0 weight style 5 size dw-locale-name :format
	if save? [integer/make-at as red-value! h-font format]
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

set-line-spacing: func [
	fmt		[this!]
	/local
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
][
	left: 73 lineCount: 0 lay: 0 
	dw: as IDWriteFactory dwrite-factory/vtbl
	dw/CreateTextLayout dwrite-factory as c-string! :left 1 fmt FLT_MAX FLT_MAX :lay

	layout: as this! lay
	dl: as IDWriteTextLayout layout/vtbl
	lm: as DWRITE_LINE_METRICS :left
	dl/GetLineMetrics layout lm 1 :lineCount
	tf: as IDWriteTextFormat fmt/vtbl
	tf/SetLineSpacing fmt 1 lm/height lm/baseline
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
	text/cache: dwrite-str-cache
	str: unicode/to-utf16-len text :len yes
	dwrite-str-cache: text/cache
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
		brush	[integer!]
		color	[red-tuple!]
		clr		[integer!]
		_11		[integer!]
		_12		[integer!]
		_21		[integer!]
		_22		[integer!]
		_31		[integer!]
		_32		[integer!]
		m		[D2D_MATRIX_3X2_F]
][
	fmt: as this! create-text-format font
	set-text-format fmt para

	layout: create-text-layout text fmt rc/right rc/bottom

	this: create-dc-render-target dc rc
	rt: as ID2D1DCRenderTarget this/vtbl
	rt/SetTextAntialiasMode this 1					;-- ClearType

	rt/BeginDraw this
	_11: 0 _12: 0 _21: 0 _22: 0 _31: 0 _32: 0
	m: as D2D_MATRIX_3X2_F :_32
	m/_11: as float32! 1.0
	m/_22: as float32! 1.0
	rt/SetTransform this m							;-- set to identity matrix

	clr: either TYPE_OF(font) = TYPE_OBJECT [
		color: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
		color/array1
	][
		0											;-- black
	]
	brush: 0
	rt/CreateSolidColorBrush this to-dx-color clr null null :brush
	rt/DrawTextLayout this as float32! 0.0 as float32! 0.0 layout brush 0
	rt/EndDraw this null null

	this2: as this! brush
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