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

#define float32-ptr! [pointer! [float32!]]

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
	return:		[integer!]
]

DrawEllipse*: alias function! [
	this		[this!]
	ellipse		[D2D1_ELLIPSE]
	brush		[integer!]
	width		[float32!]
	style		[integer!]
	return:		[integer!]
]

FillEllipse*: alias function! [
	this		[this!]
	ellipse		[D2D1_ELLIPSE]
	brush		[integer!]
	return:		[integer!]
]

DrawTextLayout*: alias function! [
	this		[this!]
	x			[float32!]
	y			[float32!]
	layout		[integer!]
	brush		[integer!]
	options		[integer!]
]


ID2D1SolidColorBrush: alias struct! [
	QueryInterface		[QueryInterface!]
	AddRef				[AddRef!]
	Release				[Release!]
	GetFactory			[integer!]
	SetOpacity			[integer!]
	SetTransform		[integer!]
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
	SetTransform				[integer!]
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
	FillRectangle					[integer!]
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
	SetTransform					[integer!]
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
	RestoreDrawingState				[integer!]
	PushAxisAlignedClip				[integer!]
	SaveDrawingState				[integer!]
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
	CheckWindowState				[integer!]
	Resize							[integer!]
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
	FillRectangle					[integer!]
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
	SetTransform					[integer!]
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
	RestoreDrawingState				[integer!]
	PushAxisAlignedClip				[integer!]
	SaveDrawingState				[integer!]
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
	format		[integer!]
	maxWidth	[float32!]
	maxHeight	[float32!]
	layout		[int-ptr!]
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
	SetLineSpacing					[integer!]
	GetTextAlignment				[integer!]
	GetParagraphAlignment			[integer!]
	GetWordWrapping					[integer!]
	GetReadingDirection				[integer!]
	GetFlowDirection				[integer!]
	GetIncrementalTabStop			[integer!]
	GetTrimming						[integer!]
	GetLineSpacing					[integer!]
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
	options		[D2D1_FACTORY_OPTIONS]		;-- opt
	factory		[int-ptr!]
	return:		[integer!]
]

DWriteCreateFactory!: alias function! [
	type		[integer!]
	iid			[int-ptr!]
	factory		[int-ptr!]
	return:		[integer!]
]

#define ConvertPointSizeToDIP(size)		(as float32! size / 72.0  * 94.0)

DX-init: func [
	/local
		hr					[integer!]
		factory 			[integer!]
		dll					[handle!]
		D2D1CreateFactory	[D2D1CreateFactory!]
		DWriteCreateFactory [DWriteCreateFactory!]
][
	dll: LoadLibraryEx #u16 "d2d1.dll" 0 0
	if null? dll [winxp?: yes exit]
	D2D1CreateFactory: as D2D1CreateFactory! GetProcAddress dll "D2D1CreateFactory"
	dll: LoadLibraryEx #u16 "DWrite.dll" 0 0
	if null? dll [winxp?: yes exit]
	DWriteCreateFactory: as DWriteCreateFactory! GetProcAddress dll "DWriteCreateFactory"

	factory: 0
	hr: D2D1CreateFactory 0 IID_ID2D1Factory null :factory		;-- D2D1_FACTORY_TYPE_SINGLE_THREADED: 0
	assert zero? hr
	d2d-factory: as this! factory
	hr: DWriteCreateFactory 0 IID_IDWriteFactory :factory		;-- DWRITE_FACTORY_TYPE_SHARED: 0
	assert zero? hr
	dwrite-factory: as this! factory
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

create-hwnd-render-target: func [
	hwnd	[handle!]
	return: [this!]
	/local
		props	[D2D1_RENDER_TARGET_PROPERTIES]
		hprops	[D2D1_HWND_RENDER_TARGET_PROPERTIES]
		rc		[RECT_STRUCT]
		factory [ID2D1Factory]
		rt		[ID2D1HwndRenderTarget]
		target	[integer!]
		hr		[integer!]
][
	rc: declare RECT_STRUCT
	GetClientRect hwnd rc
	hprops: declare D2D1_HWND_RENDER_TARGET_PROPERTIES
	hprops/hwnd: hwnd
	hprops/pixelSize.width: rc/right - rc/left
	hprops/pixelSize.height: rc/bottom - rc/top
	hprops/presentOptions: 1						;-- D2D1_PRESENT_OPTIONS_RETAIN_CONTENTS

	props: as D2D1_RENDER_TARGET_PROPERTIES allocate size? D2D1_RENDER_TARGET_PROPERTIES
	zero-memory as byte-ptr! props size? D2D1_RENDER_TARGET_PROPERTIES

	target: 0
	factory: as ID2D1Factory d2d-factory/vtbl
	hr: factory/CreateHwndRenderTarget d2d-factory props hprops :target
	free as byte-ptr! props
	if hr <> 0 [return null]
	as this! target
]

create-dc-render-target: func [
	dc		[handle!]
	rc		[RECT_STRUCT]
	return: [this!]
	/local
		props	[D2D1_RENDER_TARGET_PROPERTIES]
		factory [ID2D1Factory]
		rt		[ID2D1DCRenderTarget]
		IRT		[this!]
		target	[integer!]
		hr		[integer!]
][
	props: as D2D1_RENDER_TARGET_PROPERTIES allocate size? D2D1_RENDER_TARGET_PROPERTIES
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
	free as byte-ptr! props
	IRT
]

create-text-format: func [
	font	[red-object!]
	return: [integer!]
	/local
		values	[red-value!]
		h-font	[red-integer!]
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
		assert TYPE_OF(blk) = TYPE_BLOCK

		h-font: (as red-integer! block/rs-head blk) + 1
		if TYPE_OF(h-font) = TYPE_INTEGER [
			return h-font/value
		]

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
	factory/CreateTextFormat dwrite-factory name 0 weight style 5 size #u16 "" :format
	if save? [integer/make-at as red-value! h-font format]
	format
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
		obj		[IUnknown]
		rt		[ID2D1DCRenderTarget]
		dwrite	[IDWriteFactory]
		str		[c-string!]
		len		[integer!]
		brush	[integer!]
		layout	[integer!]
		color	[red-tuple!]
		clr		[integer!]
		w		[float32!]
		h		[float32!]
		format	[IDWriteTextFormat]
		flags	[integer!]
		h-align [integer!]
		v-align [integer!]
][
	flags: either TYPE_OF(para) = TYPE_OBJECT [
		get-para-flags base para
	][
		1 or 4
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
	this: as this! create-text-format font
	format: as IDWriteTextFormat this/vtbl
	format/SetTextAlignment this h-align
	format/SetParagraphAlignment this v-align
	format/SetWordWrapping this 1					;-- no wrapping

	w: as float32! rc/right
	h: as float32! rc/bottom
	len: -1
	str: unicode/to-utf16-len text :len yes
	layout: 0
	dwrite: as IDWriteFactory dwrite-factory/vtbl
	dwrite/CreateTextLayout dwrite-factory str len as-integer this w h :layout

	this: create-dc-render-target dc rc

	rt: as ID2D1DCRenderTarget this/vtbl
	rt/SetTextAntialiasMode this 1					;-- ClearType

	rt/BeginDraw this
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
	rt/Release this
	this: as this! layout
	COM_SAFE_RELEASE(obj this)
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