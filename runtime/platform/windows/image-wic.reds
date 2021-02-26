Red/System [
	Title:   "Image routine functions using wic"
	Author:  "bitbegin"
	File: 	 %image-wic.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define WICBitmapLockRead			00000001h
#define WICBitmapLockWrite			00000002h

#define WICBitmapNoCache			0
#define WICBitmapCacheOnDemand		1
#define WICBitmapCacheOnLoad		2
#define WICBITMAPCREATECACHEOPTION_FORCE_DWORD	7FFFFFFFh

#define GMEM_MOVEABLE	2

#define IMG_NODE_HAS_BUFFER		1
#define IMG_NODE_MODIFIED		2
#define IMG_NODE_GC_MARKED		4
#define IMG_NODE_WICBITMAP		8
#define IMG_NODE_PREMULTIPLIED	16
#define IMG_NODE_UPDATE_BUFFER	32

OS-image: context [

	wic-factory: as this! 0
	GUID_WICPixelFormat32bppBGRA: declare tagGUID
	GUID_WICPixelFormat32bppPBGRA: declare tagGUID
	GUID_ContainerFormatBmp: declare tagGUID
	GUID_ContainerFormatPng: declare tagGUID
	GUID_ContainerFormatJpeg: declare tagGUID
	GUID_ContainerFormatTiff: declare tagGUID
	GUID_ContainerFormatGif: declare tagGUID

	#define PixelFormat32bppARGB		2498570

	RECT!: alias struct! [
		x	[integer!]
		y	[integer!]
		w	[integer!]
		h	[integer!]
	]

	;-- flags bits layout
	;	0: if set, has an editable buffer with unpremultiply data
	;	1: if set, the editable buffer has been modified
	;	2: if set, the image has been marked by the GC
	img-node!: alias struct! [
		flags	[integer!]
		handle	[this!]
		buffer	[this!]
		size	[integer!]
	]

	#import [
		"kernel32.dll" stdcall [
			GlobalAlloc: "GlobalAlloc" [
				flags		[integer!]
				size		[integer!]
				return:		[integer!]
			]
			GlobalFree: "GlobalFree" [
				hMem		[integer!]
				return:		[integer!]
			]
			GlobalLock: "GlobalLock" [
				hMem		[integer!]
				return:		[byte-ptr!]
			]
			GlobalUnlock: "GlobalUnlock" [
				hMem		[integer!]
				return:		[integer!]
			]
		]
		"gdi32.dll" stdcall [
			CreateBitmap: "CreateBitmap" [
				width		[integer!]
				height		[integer!]
				planes		[integer!]
				bitcount	[integer!]
				lpBits		[byte-ptr!]
				return:		[integer!]
			]
		]
		"gdiplus.dll" stdcall [
			GdipCreateBitmapFromScan0: "GdipCreateBitmapFromScan0" [
				width		[integer!]
				height		[integer!]
				stride		[integer!]
				format		[integer!]
				scan0		[byte-ptr!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipDisposeImage: "GdipDisposeImage" [
				image		[integer!]
				return:		[integer!]
			]
		]
	]

	IWICImagingFactory: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		CreateDecoderFromFilename	[function! [this [this!] file [c-string!] vendor [int-ptr!] access [integer!] opts [integer!] dec [com-ptr!] return: [integer!]]]
		CreateDecoderFromStream		[function! [this [this!] pIStread [int-ptr!] vendor [int-ptr!] opts [integer!] dec [com-ptr!] return: [integer!]]]
		CreateDecoderFromFileHandle	[function! [this [this!] hFile [int-ptr!] vendor [int-ptr!] opts [integer!] dec [com-ptr!] return: [integer!]]]
		CreateComponentInfo			[function! [this [this!] clsid [int-ptr!] ppIInfo [com-ptr!] return: [integer!]]]
		CreateDecoder				[function! [this [this!] format [int-ptr!] vendor [int-ptr!] ppIDec [com-ptr!] return: [integer!]]]
		CreateEncoder				[function! [this [this!] format [int-ptr!] vendor [int-ptr!] ppIDec [com-ptr!] return: [integer!]]]
		CreatePalette				[function! [this [this!] ppIPal [com-ptr!] return: [integer!]]]
		CreateFormatConverter		[function! [this [this!] ppIFormat [com-ptr!] return: [integer!]]]
		CreateBitmapScaler			[function! [this [this!] ppIScaler [com-ptr!] return: [integer!]]]
		CreateBitmapClipper			[function! [this [this!] ppIClipper [com-ptr!] return: [integer!]]]
		CreateBitmapFlipRotator		[function! [this [this!] ppIFlip [com-ptr!] return: [integer!]]]
		CreateStream				[function! [this [this!] ppIStream [com-ptr!] return: [integer!]]]
		CreateColorContext			[function! [this [this!] ppIColorCtx [com-ptr!] return: [integer!]]]
		CreateColorTransformer		[function! [this [this!] ppIColorTrans [com-ptr!] return: [integer!]]]
		CreateBitmap				[function! [this [this!] width [integer!] height [integer!] format [int-ptr!] opts [integer!] ppIBitmap [com-ptr!] return: [integer!]]]
		CreateBitmapFromSource		[function! [this [this!] piBitmapSource [this!] opts [integer!] ppIBitmap [com-ptr!] return: [integer!]]]
		CreateBitmapFromSourceRect	[function! [this [this!] piBitmapSource [this!] x [integer!] y [integer!] w [integer!] h [integer!] ppIBitmap [com-ptr!] return: [integer!]]]
		CreateBitmapFromMemory		[function! [this [this!] w [integer!] h [integer!] format [integer!] stride [integer!] buffer-size [integer!] buffer [byte-ptr!] ppIBitmap [com-ptr!] return: [integer!]]]
		CreateBitmapFromHBITMAP		[function! [this [this!] hBitmap [int-ptr!] hPalette [int-ptr!] opts [integer!] ppIBitmap [com-ptr!] return: [integer!]]]
		CreateBitmapFromHICON		[function! [this [this!] hIcon [int-ptr!] ppIBitmap [com-ptr!] return: [integer!]]]
		CreateComponentEnumerator	[function! [this [this!] types [integer!] opts [integer!] ppIEnum [com-ptr!] return: [integer!]]]
		CreateFastMetadataEncoderFromDecoder		[integer!]
		CreateFastMetadataEncoderFromFrameDecode	[integer!]
		CreateQueryWriter			[function! [this [this!] format [int-ptr!] vendor [int-ptr!] ppIQueryWriter [com-ptr!] return: [integer!]]]
		CreateQueryWriterFromReader	[function! [this [this!] pIQueryReader [int-ptr!] vendor [int-ptr!] ppIQueryWriter [com-ptr!] return: [integer!]]]
	]

	IWICBitmapDecoder: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		QueryCapability				[function! [this [this!] pIStream [int-ptr!] pCap [integer!] return: [integer!]]]
		Initialize					[function! [this [this!] opts [integer!] return: [integer!]]]
		GetContainerFormat			[function! [this [this!] format [int-ptr!] return: [integer!]]]
		GetDecoderInfo				[function! [this [this!] ppIDecInfo [ptr-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		GetMetadataQueryReader		[function! [this [this!] ppIMetaReader [ptr-ptr!] return: [integer!]]]
		GetPreview					[function! [this [this!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		GetColorContexts			[function! [this [this!] count [integer!] ppIColorCtx [ptr-ptr!] pCount [int-ptr!] return: [integer!]]]
		GetThumbnail				[function! [this [this!] ppIThumbnail [ptr-ptr!] return: [integer!]]]
		GetFrameCount				[function! [this [this!] pCount [int-ptr!] return: [integer!]]]
		GetFrame					[function! [this [this!] index [integer!] ppIBitmapFrame [com-ptr!] return: [integer!]]]
	]

	IWICBitmapFrameDecode: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pW [int-ptr!] pH [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
		GetResolution				[function! [this [this!] pX [float-ptr!] pY [float-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		CopyPixels					[function! [this [this!] prc [int-ptr!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		GetMetadataQueryReader		[function! [this [this!] ppIMetaReader [com-ptr!] return: [integer!]]]
		GetColorContexts			[function! [this [this!] count [integer!] ppIColorCtx [com-ptr!] pCount [int-ptr!] return: [integer!]]]
		GetThumbnail				[function! [this [this!] ppIThumbnail [com-ptr!] return: [integer!]]]
	]

	IWICBitmapFrameEncode: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		Initialize					[function! [this [this!] pIEncOpts [int-ptr!] return: [integer!]]]
		SetSize						[function! [this [this!] w [integer!] h [integer!] return: [integer!]]]
		SetResolution				[function! [this [this!] x [float!] y [float!] return: [integer!]]]
		SetPixelFormat				[function! [this [this!] format [int-ptr!] return: [integer!]]]
		SetColorContexts			[function! [this [this!] count [integer!] ppIColorCtx [ptr-ptr!] return: [integer!]]]
		SetPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		SetThumbnail				[function! [this [this!] pIThumbnail [int-ptr!] return: [integer!]]]
		WritePixels					[function! [this [this!] count [integer!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		WriteSource					[function! [this [this!] piBitmapSource [this!] prc [RECT!] return: [integer!]]]
		Commit						[function! [this [this!] return: [integer!]]]
		GetMetadataQueryWriter		[function! [this [this!] ppIMetaReader [ptr-ptr!] return: [integer!]]]
	]

	IWICBitmapEncoder: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		Initialize					[function! [this [this!] pIStream [this!] opts [integer!] return: [integer!]]]
		GetContainerFormat			[function! [this [this!] format [int-ptr!] return: [integer!]]]
		GetEncoderInfo				[function! [this [this!] ppIEncInfo [ptr-ptr!] return: [integer!]]]
		SetColorContexts			[function! [this [this!] count [integer!] ppIColorCtx [ptr-ptr!] return: [integer!]]]
		SetPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		SetThumbnail				[function! [this [this!] pIThumbnail [int-ptr!] return: [integer!]]]
		SetPreview					[function! [this [this!] pIPreview [int-ptr!] return: [integer!]]]
		CreateNewFrame				[function! [this [this!] ppIFrameEnc [com-ptr!] ppIEncOpts [int-ptr!] return: [integer!]]]
		Commit						[function! [this [this!] return: [integer!]]]
		GetMetadataQueryWriter		[function! [this [this!] ppIMetaWriter [ptr-ptr!] return: [integer!]]]
	]

	IWICFormatConverter: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pW [int-ptr!] pH [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
		GetResolution				[function! [this [this!] pX [float-ptr!] pY [float-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		CopyPixels					[function! [this [this!] prc [int-ptr!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		Initialize					[function! [this [this!] pISource [this!] format [int-ptr!] dither [integer!] pIPalette [int-ptr!] percent [float!] trans [integer!] return: [integer!]]]
		CanConvert					[function! [this [this!] srcFormat [int-ptr!] dstFormat [int-ptr!] return: [integer!]]]
	]

	IWICBitmapSource: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pWidth [int-ptr!] pHeight [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
		GetResolution				[function! [this [this!] pX [float-ptr!] pY [float-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		CopyPixels					[function! [this [this!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		Initialize					[function! [this [this!] pISource [this!] w [integer!] h [integer!] mode [integer!] return: [integer!]]]
	]

	IWICBitmap: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pWidth [int-ptr!] pHeight [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
		GetResolution				[function! [this [this!] pX [float-ptr!] pY [float-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		CopyPixels					[function! [this [this!] prc [int-ptr!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		Lock						[function! [this [this!] prcLock [RECT!] flags [integer!] ppILock [com-ptr!] return: [integer!]]]
		SetPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		SetResolution				[function! [this [this!] x [float!] y [float!] return: [integer!]]]
	]

	IWICBitmapLock: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pWidth [int-ptr!] pHeight [int-ptr!] return: [integer!]]]
		GetStride					[function! [this [this!] stride [int-ptr!] return: [integer!]]]
		GetDataPointer				[function! [this [this!] size [int-ptr!] data [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
	]

	IWICBitmapScaler: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pWidth [int-ptr!] pHeight [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
		GetResolution				[function! [this [this!] pX [float-ptr!] pY [float-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		CopyPixels					[function! [this [this!] prc [int-ptr!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		Initialize					[function! [this [this!] pISource [this!] w [integer!] h [integer!] mode [integer!] return: [integer!]]]
	]

	IWICBitmapClipper: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetSize						[function! [this [this!] pWidth [int-ptr!] pHeight [int-ptr!] return: [integer!]]]
		GetPixelFormat				[function! [this [this!] pPixelFormat [int-ptr!] return: [integer!]]]
		GetResolution				[function! [this [this!] pX [float-ptr!] pY [float-ptr!] return: [integer!]]]
		CopyPalette					[function! [this [this!] pIPalette [int-ptr!] return: [integer!]]]
		CopyPixels					[function! [this [this!] prc [int-ptr!] stride [integer!] size [integer!] buffer [byte-ptr!] return: [integer!]]]
		Initialize					[function! [this [this!] pISource [this!] rec [RECT!] return: [integer!]]]
	]

	make-node: func [
		handle	[this!]
		buffer	[this!]
		flags	[integer!]
		width	[integer!]
		height	[integer!]
		return: [node!]
		/local
			node	[node!]
			inode	[img-node!]
	][
		node: alloc-cells 1			;-- 16 bytes
		inode: as img-node! (as series! node/value) + 1
		inode/flags: flags
		inode/handle: handle
		inode/buffer: buffer
		inode/size: height << 16 or width
		node
	]

	to-bgra: func [
		image		[this!]
		premul?		[logic!]
		return:		[this!]
		/local
			IFAC	[IWICImagingFactory]
			iconv	[com-ptr! value]
			cthis	[this!]
			conv	[IWICFormatConverter]
			fmt		[int-ptr!]
	][
		fmt: as int-ptr! either premul? [
			GUID_WICPixelFormat32bppPBGRA
		][
			GUID_WICPixelFormat32bppBGRA
		]
		IFAC: as IWICImagingFactory wic-factory/vtbl
		IFAC/CreateFormatConverter wic-factory :iconv
		cthis: iconv/value
		conv: as IWICFormatConverter cthis/vtbl
		conv/Initialize cthis image fmt 0 null 0.0 0
		cthis
	]

	get-handle: func [
		img			[red-image!]
		premul?		[logic!]
		return:		[this!]
		/local
			inode	[img-node!]
			unk		[IUnknown]
			h		[this!]
			new-h	[this!]
			pre?	[logic!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		h: inode/handle
		pre?: inode/flags and IMG_NODE_PREMULTIPLIED <> 0
		if any [
			null? h
			inode/flags and IMG_NODE_MODIFIED <> 0
			premul? <> pre?
		][
			new-h: either null? inode/buffer [
				to-bgra h premul?
			][
				to-bgra inode/buffer premul?
			]
			if h <> null [COM_SAFE_RELEASE(unk h)]
			h: new-h
			inode/handle: new-h
			inode/flags: inode/flags and (not IMG_NODE_WICBITMAP)
			inode/flags: either premul? [
				inode/flags or IMG_NODE_PREMULTIPLIED
			][
				inode/flags and (not IMG_NODE_PREMULTIPLIED)
			]
		]
		h
	]

	get-wicbitmap: func [
		img			[red-image!]
		return:		[this!]
		/local
			inode	[img-node!]
			unk		[IUnknown]
			h		[this!]
			IFAC	[IWICImagingFactory]
			bitmap	[com-ptr! value]
	][
		inode: as img-node! (as series! img/node/value) + 1
		h: get-handle img yes
		either inode/flags and IMG_NODE_WICBITMAP <> 0 [h][
			IFAC: as IWICImagingFactory wic-factory/vtbl
			IFAC/CreateBitmapFromSource wic-factory h WICBitmapCacheOnLoad :bitmap
			inode/handle: bitmap/value
			if inode/buffer <> null [
				COM_SAFE_RELEASE(unk inode/buffer)
				inode/flags: IMG_NODE_WICBITMAP or IMG_NODE_PREMULTIPLIED
			]
			bitmap/value
		]
	]

	get-buffer: func [
		img			[node!]
		return:		[this!]
		/local
			inode	[img-node!]
			unk		[IUnknown]
			IFAC	[IWICImagingFactory]
			h		[this!]
			bitmap	[com-ptr! value]
	][
		inode: as img-node! (as series! img/value) + 1
		h: inode/buffer
		if inode/flags and IMG_NODE_UPDATE_BUFFER <> 0 [
			inode/flags: inode/flags and (not (IMG_NODE_UPDATE_BUFFER or IMG_NODE_HAS_BUFFER))
		]
		if inode/flags and IMG_NODE_HAS_BUFFER = 0 [
			h: to-bgra inode/handle no
			IFAC: as IWICImagingFactory wic-factory/vtbl
			IFAC/CreateBitmapFromSource wic-factory h WICBitmapCacheOnDemand :bitmap
			COM_SAFE_RELEASE(unk h)
			h: bitmap/value
			inode/buffer: h
			inode/flags: inode/flags or IMG_NODE_HAS_BUFFER
		]
		h
	]

	init: func [
		/local
			CLSID_WICImagingFactory	[tagGUID value]
			IID_IWICImagingFactory	[tagGUID value]
			hr	[integer!]
			II	[interface! value]
	][
		CLSID_WICImagingFactory/data1: 0
		IID_IWICImagingFactory/data1: 0
		UuidFromString "CACAF262-9370-4615-A13B-9F5539DA4C0A" :CLSID_WICImagingFactory
		UuidFromString "EC5EC8A9-C395-4314-9C77-54D7A935FF70" :IID_IWICImagingFactory
		UuidFromString "6FDDC324-4E03-4BFE-B185-3D77768DC90F" GUID_WICPixelFormat32bppBGRA
		UuidFromString "6FDDC324-4E03-4BFE-B185-3D77768DC910" GUID_WICPixelFormat32bppPBGRA
		UuidFromString "0AF1D87E-FCFE-4188-BDEB-A7906471CBE3" GUID_ContainerFormatBmp
		UuidFromString "1B7CFAF4-713F-473C-BBCD-6137425FAEAF" GUID_ContainerFormatPng
		UuidFromString "19E4A5AA-5662-4FC5-A0C0-1758028E1057" GUID_ContainerFormatJpeg
		UuidFromString "163BCC30-E2E9-4F0B-961D-A3E9FDB788A3" GUID_ContainerFormatTiff
		UuidFromString "1F8A5601-7D4D-4CBD-9C82-1BC8D4EEB9A5" GUID_ContainerFormatGif

		hr: CoCreateInstance as int-ptr! CLSID_WICImagingFactory 0 CLSCTX_INPROC_SERVER as int-ptr! IID_IWICImagingFactory :II
		if hr = 0 [
			wic-factory: II/ptr
		]
	]

	get-pixel-format: func [
		image		[integer!]
		format		[int-ptr!]
		return:		[integer!]
		/local
			this	[this!]
			IB		[IWICBitmap]
			guid	[tagGUID value]
			ret		[integer!]
	][
		this: as this! image
		IB: as IWICBitmap this/vtbl
		ret: IB/GetPixelFormat this as int-ptr! :guid
		format/value: either all [
			guid/data1 = GUID_WICPixelFormat32bppBGRA/data1
			guid/data2 = GUID_WICPixelFormat32bppBGRA/data2
			guid/data3 = GUID_WICPixelFormat32bppBGRA/data3
			guid/data4 = GUID_WICPixelFormat32bppBGRA/data4
		][1][0]
		ret
	]

	fixed-format?: func [
		format		[integer!]
		return:		[logic!]
	][
		format = 1
	]

	fixed-format: func [
		return:		[integer!]
	][
		1
	]

	create-bitmap-from-scan0: func [
		width		[integer!]
		height		[integer!]
		stride		[integer!]
		format		[integer!]								;-- only support GUID_WICPixelFormat32bppBGRA for now
		scan0		[byte-ptr!]
		bitmap		[int-ptr!]
		return:		[integer!]
		/local
			IFAC	[IWICImagingFactory]
			size	[integer!]
			bmp		[com-ptr! value]
			ret		[integer!]
	][
		IFAC: as IWICImagingFactory wic-factory/vtbl
		if stride = 0 [stride: width * 4]
		size: stride * height
		ret: IFAC/CreateBitmapFromMemory wic-factory width height as integer! GUID_WICPixelFormat32bppBGRA stride size scan0 :bmp
		bitmap/value: as integer! make-node null bmp/value 3 width height
		ret
	]

	create-bitmap-from-gdidib: func [
		bmi			[byte-ptr!]
		data		[byte-ptr!]
		bitmap		[int-ptr!]
		return:		[integer!]
	][
		0
	]

	width?: func [
		handle		[int-ptr!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! handle/value) + 1
		IMAGE_WIDTH(inode/size)
	]

	height?: func [
		handle		[int-ptr!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! handle/value) + 1
		IMAGE_HEIGHT(inode/size)
	]

	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
		/local
			this	[this!]
			IB		[IWICBitmap]
			flag	[integer!]
			rect	[RECT! value]
			ilock	[com-ptr! value]
			inode	[img-node!]
	][
		this: get-buffer img/node
		IB: as IWICBitmap this/vtbl
		flag: either write? [
			inode: as img-node! (as series! img/node/value) + 1
			inode/flags: inode/flags or IMG_NODE_MODIFIED
			WICBitmapLockWrite
		][WICBitmapLockRead]
		rect/x: 0
		rect/y: 0
		rect/w: IMAGE_WIDTH(img/size)
		rect/h: IMAGE_HEIGHT(img/size)
		IB/Lock this rect flag :ilock
		as integer! ilock/value
	]

	unlock-bitmap: func [
		img			[red-image!]
		data		[integer!]
		/local
			this	[this!]
			lock	[IWICBitmapLock]
	][
		this: as this! data
		lock: as IWICBitmapLock this/vtbl
		lock/Release this
	]

	mark-updated: func [
		img			[red-image!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		inode/flags: inode/flags or IMG_NODE_UPDATE_BUFFER
	]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			this	[this!]
			lock	[IWICBitmapLock]
			size	[integer!]
			data	[integer!]
	][
		this: as this! handle
		lock: as IWICBitmapLock this/vtbl
		lock/GetStride this stride
		size: 0 data: 0
		lock/GetDataPointer this :size :data
		as int-ptr! data
	]

	get-data-pixel-format: func [
		handle		[integer!]
		format		[int-ptr!]
		return:		[integer!]
		/local
			this	[this!]
			lock	[IWICBitmapLock]
			guid	[tagGUID value]
			ret		[integer!]
	][
		this: as this! handle
		lock: as IWICBitmapLock this/vtbl
		ret: lock/GetPixelFormat this as int-ptr! :guid
		format/value: either all [
			guid/data1 = GUID_WICPixelFormat32bppBGRA/data1
			guid/data2 = GUID_WICPixelFormat32bppBGRA/data2
			guid/data3 = GUID_WICPixelFormat32bppBGRA/data3
			guid/data4 = GUID_WICPixelFormat32bppBGRA/data4
		][1][0]
		ret
	]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
		/local
			this	[this!]
			IB		[IWICBitmap]
			w		[integer!]
			h		[integer!]
			rect	[RECT! value]
			ilock	[com-ptr! value]
			lthis	[this!]
			lock	[IWICBitmapLock]
			size	[integer!]
			data	[integer!]
			scan0	[int-ptr!]
			ret		[integer!]
	][
		this: get-buffer bitmap
		IB: as IWICBitmap this/vtbl
		w: 0 h: 0
		IB/GetSize this :w :h
		rect/x: 0 rect/y: 0 rect/w: w rect/h: h
		IB/Lock this rect WICBitmapLockRead :ilock
		lthis: ilock/value
		lock: as IWICBitmapLock lthis/vtbl
		size: 0 data: 0
		lock/GetDataPointer lthis :size :data
		scan0: as int-ptr! data
		scan0: scan0 + index
		ret: scan0/1
		lock/Release lthis
		ret
	]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
		/local
			this	[this!]
			IB		[IWICBitmap]
			w		[integer!]
			h		[integer!]
			rect	[RECT! value]
			ilock	[com-ptr! value]
			lthis	[this!]
			lock	[IWICBitmapLock]
			size	[integer!]
			data	[integer!]
			scan0	[int-ptr!]
			inode	[img-node!]
	][
		this: get-buffer bitmap
		IB: as IWICBitmap this/vtbl
		w: 0 h: 0
		IB/GetSize this :w :h
		rect/x: 0 rect/y: 0 rect/w: w rect/h: h
		IB/Lock this rect WICBitmapLockRead :ilock
		lthis: ilock/value
		lock: as IWICBitmapLock lthis/vtbl
		size: 0 data: 0
		lock/GetDataPointer lthis :size :data
		scan0: as int-ptr! data
		scan0: scan0 + index
		scan0/1: color
		lock/Release lthis
		inode: as img-node! (as series! bitmap/value) + 1
		inode/flags: inode/flags or IMG_NODE_MODIFIED
		0
	]

	delete: func [
		img			[red-image!]
		/local
			unk		[IUnknown]
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		COM_SAFE_RELEASE(unk inode/handle)
		COM_SAFE_RELEASE(unk inode/buffer)
	]

	resize: func [
		img			[red-image!]
		width		[integer!]
		height		[integer!]
		return:		[integer!]
		/local
			this	[this!]
			IFAC	[IWICImagingFactory]
			iscale	[com-ptr! value]
			sthis	[this!]
			scale	[IWICBitmapScaler]
			bitmap	[com-ptr! value]
	][
		this: get-handle img no
		IFAC: as IWICImagingFactory wic-factory/vtbl
		IFAC/CreateBitmapScaler wic-factory :iscale
		sthis: iscale/value
		scale: as IWICBitmapScaler sthis/vtbl
		scale/Initialize sthis this width height 0		;-- NearestNeighbor
		as-integer make-node sthis null 0 width height
	]

	get-frame: func [
		IFAC		[IWICImagingFactory]
		idec		[com-ptr!]
		idx			[integer!]
		premul?		[logic!]
		return:		[node!]
		/local
			this	[this!]
			dec		[IWICBitmapDecoder]
			count	[integer!]
			iframe	[com-ptr! value]
			fthis	[this!]
			frame	[IWICBitmapFrameDecode]
			w		[integer!]
			h		[integer!]
			iconv	[com-ptr! value]
			cthis	[this!]
			conv	[IWICFormatConverter]
			fmt		[int-ptr!]
	][
		this: idec/value
		dec: as IWICBitmapDecoder this/vtbl
		count: 0
		dec/GetFrameCount this :count
		if count < 1 [
			dec/Release this
			return null
		]
		dec/GetFrame this idx :iframe
		fthis: iframe/value
		frame: as IWICBitmapFrameDecode fthis/vtbl
		w: 0 h: 0
		frame/GetSize fthis :w :h
		IFAC/CreateFormatConverter wic-factory :iconv
		cthis: iconv/value
		conv: as IWICFormatConverter cthis/vtbl
		fmt: as int-ptr! either premul? [
			GUID_WICPixelFormat32bppPBGRA
		][
			GUID_WICPixelFormat32bppBGRA
		]
		conv/Initialize cthis fthis fmt 0 null 0.0 0
		frame/Release fthis
		dec/Release this
		make-node cthis null 0 w h 
	]

	load-image: func [
		src			[red-string!]
		return:		[int-ptr!]
		/local
			IFAC	[IWICImagingFactory]
			II		[com-ptr! value]
			node	[node!]
			inode	[img-node!]
			bitmap	[com-ptr! value]
			unk		[IUnknown]
			h		[this!]
	][
		IFAC: as IWICImagingFactory wic-factory/vtbl
		if 0 <> IFAC/CreateDecoderFromFilename
			wic-factory
			file/to-OS-path src
			null
			GENERIC_READ
			1	;-- WICDecodeMetadataCacheOnLoad
			:II [return null]
		node: get-frame IFAC as com-ptr! :II 0 no
		if null? node [return null]
		inode: as img-node! (as series! node/value) + 1
		h: as this! inode/handle
		if 0 <> IFAC/CreateBitmapFromSource
			wic-factory h WICBitmapCacheOnLoad :bitmap [return null]
		COM_SAFE_RELEASE(unk h)
		inode/handle: null
		inode/buffer: bitmap/value
		inode/flags: IMG_NODE_HAS_BUFFER
		node
	]

	make-image: func [
		width		[integer!]
		height		[integer!]
		rgb-bin		[red-binary!]
		alpha-bin	[red-binary!]
		color		[red-tuple!]
		return:		[int-ptr!]
		/local
			IFAC	[IWICImagingFactory]
			bitmap	[com-ptr! value]
			bthis	[this!]
			bmp		[IWICBitmap]
			rect	[RECT! value]
			ilock	[com-ptr! value]
			lthis	[this!]
			lock	[IWICBitmapLock]
			size	[integer!]
			data	[integer!]
			scan0	[int-ptr!]
			end		[int-ptr!]
			a		[integer!]
			r		[integer!]
			b		[integer!]
			g		[integer!]
			rgb		[byte-ptr!]
			alpha	[byte-ptr!]
			len		[integer!]
			len2	[integer!]
	][
		if any [zero? width zero? height][return null]
		IFAC: as IWICImagingFactory wic-factory/vtbl
		IFAC/CreateBitmap wic-factory width height as int-ptr! GUID_WICPixelFormat32bppBGRA WICBitmapCacheOnLoad :bitmap
		bthis: bitmap/value
		bmp: as IWICBitmap bthis/vtbl
		rect/x: 0 rect/y: 0 rect/w: width rect/h: height
		bmp/Lock bthis rect WICBitmapLockWrite :ilock
		lthis: ilock/value
		lock: as IWICBitmapLock lthis/vtbl

		size: 0 data: 0
		lock/GetDataPointer lthis :size :data

		scan0: as int-ptr! data
		end: scan0 + (width * height)

		either null? color [
			either rgb-bin <> null [
				len: binary/rs-length? rgb-bin
				len: len / 3 * 3
				rgb: binary/rs-head rgb-bin
			][len: 0]
			either alpha-bin <> null [
				len2: binary/rs-length? alpha-bin
				alpha: binary/rs-head alpha-bin
			][len2: 0]

			while [scan0 < end][
				either len2 > 0 [
					a: 255 - as-integer alpha/1
					alpha: alpha + 1
					len2: len2 - 1
				][a: 255]
				either len > 0 [
					r: as-integer rgb/1
					g: as-integer rgb/2
					b: as-integer rgb/3
					rgb: rgb + 3
					len: len - 3
				][r: 255 g: 255 b: 255]
				scan0/value: r << 16 or (g << 8) or b or (a << 24)
				scan0: scan0 + 1
			]
		][
			r: color/array1
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
			r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
			while [scan0 < end][
				scan0/value: r
				scan0: scan0 + 1
			]
		]

		lock/Release lthis
		make-node null bthis IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED width height
	]

	load-binary: func [
		data		[byte-ptr!]
		len			[integer!]
		return:		[node!]
		/local
			hMem	[integer!]
			p		[byte-ptr!]
			s		[integer!]
			idec	[com-ptr! value]
			IFAC	[IWICImagingFactory]
	][
		hMem: GlobalAlloc GMEM_MOVEABLE len
		p: GlobalLock hMem
		copy-memory p data len
		GlobalUnlock hMem

		s: 0
		CreateStreamOnHGlobal hMem true :s

		IFAC: as IWICImagingFactory wic-factory/vtbl
		if 0 <> IFAC/CreateDecoderFromStream wic-factory as int-ptr! s null 1 :idec [
			return null
		]
		get-frame IFAC as com-ptr! :idec 0 no
	]

	encode: func [
		image		[red-image!]
		slot		[red-value!]
		format		[integer!]
		return:		[red-value!]
		/local
			bin		[red-binary!]
			s		[series!]
			clsid	[tagGUID]
			stream	[IStream]
			storage [IStorage]
			stat	[tagSTATSTG value]
			IStm	[interface! value]
			ISto	[interface! value]
			len		[integer!]
			hr		[integer!]
			IFAC	[IWICImagingFactory]
			ienc	[com-ptr! value]
			ethis	[this!]
			enc		[IWICBitmapEncoder]
			iframe	[com-ptr! value]
			fthis	[this!]
			frame	[IWICBitmapFrameEncode]
			prop	[integer!]
			rect	[RECT! value]
	][
		switch format [
			IMAGE_BMP  [clsid: GUID_ContainerFormatBmp]
			IMAGE_PNG  [clsid: GUID_ContainerFormatPng]
			IMAGE_GIF  [clsid: GUID_ContainerFormatGif]
			IMAGE_JPEG [clsid: GUID_ContainerFormatJpeg]
			IMAGE_TIFF [clsid: GUID_ContainerFormatTiff]
			default    [probe "Cannot find image encoder" return null]
		]

		hr: StgCreateDocfile
			null
			STGM_READWRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE or STGM_DELETEONRELEASE 
			0
			:ISto
		storage: as IStorage ISto/ptr/vtbl
		hr: storage/CreateStream
			ISto/ptr
			#u16 "RedImageStream"
			STGM_READWRITE or STGM_SHARE_EXCLUSIVE
			0
			0
			IStm
		IFAC: as IWICImagingFactory wic-factory/vtbl
		hr: IFAC/CreateEncoder wic-factory as int-ptr! clsid null :ienc
		ethis: ienc/value
		enc: as IWICBitmapEncoder ethis/vtbl
		hr: enc/Initialize ethis IStm/ptr 2
		prop: 0
		hr: enc/CreateNewFrame ethis :iframe :prop
		fthis: iframe/value
		frame: as IWICBitmapFrameEncode fthis/vtbl
		rect/x: 0 rect/y: 0
		rect/w: IMAGE_WIDTH(image/size)
		rect/h: IMAGE_HEIGHT(image/size)
		hr: frame/Initialize fthis null
		hr: frame/WriteSource fthis get-handle image no rect
		hr: frame/Commit fthis
		hr: enc/Commit ethis
		frame/Release fthis
		enc/Release ethis
		stream: as IStream IStm/ptr/vtbl
		stream/Stat IStm/ptr stat 1
		len: stat/cbSize_low

		bin: as red-binary! slot
		bin/header: TYPE_UNSET
		bin/head: 0
		bin/node: alloc-bytes len
		bin/header: TYPE_BINARY
		
		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/tail) + len

		stream/Seek IStm/ptr 0 0 0 0 0
		stream/Read IStm/ptr as byte-ptr! s/offset len :hr
		stream/Release IStm/ptr
		storage/Release ISto/ptr
		as red-value! bin
	]

	clone: func [
		src			[red-image!]
		dst			[red-image!]
		part		[integer!]
		size		[red-pair!]
		part?		[logic!]
		return:		[red-image!]
		/local
			width	[integer!]
			height	[integer!]
			offset	[integer!]
			this	[this!]
			IFAC	[IWICImagingFactory]
			bitmap	[com-ptr! value]
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			handle	[node!]
			iclip	[com-ptr! value]
			cthis	[this!]
			clip	[IWICBitmapClipper]
			rect	[RECT! value]
	][
		width: IMAGE_WIDTH(src/size)
		height: IMAGE_HEIGHT(src/size)

		if any [
			width <= 0
			height <= 0
		][
			dst/size: 0
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: as node! 0
			return dst
		]

		offset: src/head
		this: get-handle src no
		IFAC: as IWICImagingFactory wic-factory/vtbl
		if all [zero? offset not part?][
			IFAC/CreateBitmapFromSource wic-factory this WICBitmapCacheOnDemand :bitmap
			dst/size: src/size
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: make-node null bitmap/value IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED width height
			return dst
		]

		x: offset % width
		y: offset / width
		either all [part? TYPE_OF(size) = TYPE_PAIR][
			w: width - x
			h: height - y
			if size/x < w [w: size/x]
			if size/y < h [h: size/y]
		][
			either zero? part [
				w: 0 h: 0
			][
				either part < width [h: 1 w: part][
					h: part / width
					w: width
				]
			]
		]
		either any [
			w <= 0
			h <= 0
		][
			dst/size: 0
			dst/node: null
		][
			IFAC/CreateBitmapClipper wic-factory :iclip
			cthis: iclip/value
			clip: as IWICBitmapClipper cthis/vtbl
			rect/x: x rect/y: y
			rect/w: w rect/h: h
			clip/Initialize cthis this rect
			IFAC/CreateBitmapFromSource wic-factory cthis WICBitmapCacheOnLoad :bitmap
			clip/Release cthis
			dst/node: make-node null bitmap/value IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED w h
			dst/size: h << 16 or w
		]
		dst/header: TYPE_IMAGE
		dst/head: 0
		dst
	]

	to-HBITMAP: func [
		image		[red-image!]
		return:		[integer!]
		/local
			this	[this!]
			IB		[IWICBitmap]
			w		[integer!]
			h		[integer!]
			rect	[RECT! value]
			ilock	[com-ptr! value]
			lthis	[this!]
			lock	[IWICBitmapLock]
			size	[integer!]
			data	[integer!]
			bitmap	[integer!]
	][
		this: get-buffer image/node
		IB: as IWICBitmap this/vtbl
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		rect/x: 0
		rect/y: 0
		rect/w: w
		rect/h: h
		IB/Lock this rect WICBitmapLockRead :ilock
		lthis: ilock/value
		lock: as IWICBitmapLock lthis/vtbl
		size: 0 data: 0
		lock/GetDataPointer lthis :size :data
		bitmap: CreateBitmap w h 1 32 as byte-ptr! data
		lock/Release lthis
		bitmap
	]

	from-HBITMAP: func [
		hBitmap		[integer!]
		alpha		[integer!]
		return:		[red-image!]
		/local
			IFAC	[IWICImagingFactory]
			bitmap	[com-ptr! value]
			hr		[integer!]
			this	[this!]
			IB		[IWICBitmap]
			w		[integer!]
			h		[integer!]
	][
		IFAC: as IWICImagingFactory wic-factory/vtbl
		either zero? IFAC/CreateBitmapFromHBITMAP wic-factory as int-ptr! hBitmap null alpha :bitmap [
			this: bitmap/value
		][return as red-image! none-value]
		IB: as IWICBitmap this/vtbl
		w: 0 h: 0
		IB/GetSize this :w :h
		image/init-image
			as red-image! stack/push*
			make-node null this 3 w h
	]

	to-gpbitmap: func [
		image		[red-image!]
		ilock		[com-ptr!]
		return:		[integer!]
		/local
			this	[this!]
			IB		[IWICBitmap]
			w		[integer!]
			h		[integer!]
			rect	[RECT! value]
			lthis	[this!]
			lock	[IWICBitmapLock]
			size	[integer!]
			data	[integer!]
			bitmap	[integer!]
			inode	[img-node!]
	][
		inode: as img-node! (as series! image/node/value) + 1
		;-- alpha channel is 0 when image is copied from mspaint
		;-- so we need to regenerate buffer
		get-handle image no
		inode/flags: inode/flags or IMG_NODE_UPDATE_BUFFER
		this: get-buffer image/node
		IB: as IWICBitmap this/vtbl
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		rect/x: 0
		rect/y: 0
		rect/w: w
		rect/h: h
		IB/Lock this rect WICBitmapLockRead ilock
		lthis: ilock/value
		lock: as IWICBitmapLock lthis/vtbl
		size: 0 data: 0
		lock/GetDataPointer lthis :size :data
		bitmap: 0
		;-- GdipCreateBitmapFromScan0 uses data without copying it
		GdipCreateBitmapFromScan0 w h w * 4 PixelFormat32bppARGB as byte-ptr! data :bitmap
		bitmap
	]

	release-gpbitmap: func [
		bitmap		[integer!]
		ilock		[com-ptr!]
		/local
			lthis	[this!]
			lock	[IWICBitmapLock]
	][
		GdipDisposeImage bitmap
		lthis: ilock/value
		lock: as IWICBitmapLock lthis/vtbl
		lock/Release lthis
	]
]
