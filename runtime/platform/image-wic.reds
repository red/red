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


#define PixelFormatIndexed			00010000h ;-- Indexes into a palette
#define PixelFormatGDI				00020000h ;-- Is a GDI-supported format
#define PixelFormatAlpha			00040000h ;-- Has an alpha component
#define PixelFormatPAlpha			00080000h ;-- Pre-multiplied alpha
#define PixelFormatExtended			00100000h ;-- Extended color 16 bits/channel
#define PixelFormatCanonical		00200000h

#define PixelFormatUndefined		0
#define PixelFormatDontCare			0

#define PixelFormat32bppARGB		2498570   ;-- [10 or (32 << 8) or PixelFormatAlpha or PixelFormatGDI or PixelFormatCanonical]
#define PixelFormat32bppPARGB		925707    ;-- [11 or (32 << 8) or PixelFormatAlpha or PixelFormatPAlpha or PixelFormatGDI]
#define PixelFormat32bppCMYK		8207	  ;-- [15 or (32 << 8)]
#define PixelFormatMax				16

OS-image: context [

	IWICImagingFactory: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		CreateDecoderFromFilename	[function! [this [this!] file [c-string!] vendor [int-ptr!] access [integer!] opts [integer!] dec [ptr-ptr!] return: [integer!]]]
		CreateDecoderFromStream		[function! [this [this!] pIStread [int-ptr!] vendor [int-ptr!] opts [integer!] dec [ptr-ptr!] return: [integer!]]]
		CreateDecoderFromFileHandle	[function! [this [this!] hFile [int-ptr!] vendor [int-ptr!] opts [integer!] dec [ptr-ptr!] return: [integer!]]]
		CreateComponentInfo			[function! [this [this!] clsid [int-ptr!] ppIInfo [ptr-ptr!] return: [integer!]]]
		CreateDecoder				[function! [this [this!] format [int-ptr!] vendor [int-ptr!] ppIDec [ptr-ptr!] return: [integer!]]]
		CreateEncoder				[function! [this [this!] format [int-ptr!] vendor [int-ptr!] ppIDec [ptr-ptr!] return: [integer!]]]
		CreatePalette				[function! [this [this!] ppIPal [ptr-ptr!] return: [integer!]]]
		CreateFormatConverter		[function! [this [this!] ppIFormat [ptr-ptr!] return: [integer!]]]
		CreateBitmapScaler			[function! [this [this!] ppIScaler [ptr-ptr!] return: [integer!]]]
		CreateBitmapClipper			[function! [this [this!] ppIClipper [ptr-ptr!] return: [integer!]]]
		CreateBitmapFlipRotator		[function! [this [this!] ppIFlip [ptr-ptr!] return: [integer!]]]
		CreateStream				[function! [this [this!] ppIStream [ptr-ptr!] return: [integer!]]]
		CreateColorContext			[function! [this [this!] ppIColorCtx [ptr-ptr!] return: [integer!]]]
		CreateColorTransformer		[function! [this [this!] ppIColorTrans [ptr-ptr!] return: [integer!]]]
		CreateBitmap				[function! [this [this!] width [integer!] height [integer!] format [integer!] opts [integer!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		CreateBitmapFromSource		[function! [this [this!] piBitmapSource [int-ptr!] opts [integer!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		CreateBitmapFromSourceRect	[function! [this [this!] piBitmapSource [int-ptr!] x [integer!] y [integer!] w [integer!] h [integer!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		CreateBitmapFromMemory		[function! [this [this!] w [integer!] h [integer!] format [integer!] stride [integer!] buffer-size [integer!] buffer [byte-ptr!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		CreateBitmapFromHBITMAP		[function! [this [this!] hBitmap [int-ptr!] hPalette [int-ptr!] opts [integer!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		CreateBitmapFromHICON		[function! [this [this!] hIcon [int-ptr!] ppIBitmap [ptr-ptr!] return: [integer!]]]
		CreateComponentEnumerator	[function! [this [this!] types [integer!] opts [integer!] ppIEnum [ptr-ptr!] return: [integer!]]]
		CreateFastMetadataEncoderFromDecoder		[integer!]
		CreateFastMetadataEncoderFromFrameDecode	[integer!]
		CreateQueryWriter			[function! [this [this!] format [int-ptr!] vendor [int-ptr!] ppIQueryWriter [ptr-ptr!] return: [integer!]]]
		CreateQueryWriterFromReader	[function! [this [this!] pIQueryReader [int-ptr!] vendor [int-ptr!] ppIQueryWriter	[ptr-ptr!] return: [integer!]]]
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
		hr: CoCreateInstance as int-ptr! CLSID_WICImagingFactory 0 CLSCTX_INPROC_SERVER as int-ptr! IID_IWICImagingFactory :II
		if hr <> 0 [0]
	]

	get-pixel-format: func [
		image		[integer!]
		format		[int-ptr!]
		return:		[integer!]
	][
		0
	]

	create-bitmap-from-scan0: func [
		width		[integer!]
		height		[integer!]
		stride		[integer!]
		format		[integer!]
		scan0		[byte-ptr!]
		bitmap		[int-ptr!]
		return:		[integer!]
	][
		0
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
	][0]

	height?: func [
		handle		[int-ptr!]
		return:		[integer!]
	][0]

	lock-bitmap-fmt: func [
		handle		[integer!]
		pixelformat [integer!]
		write?		[logic!]
		return:		[integer!]
	][0]

	unlock-bitmap-fmt: func [
		img			[integer!]
		data		[integer!]
	][]

	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
	][0]

	unlock-bitmap: func [
		img			[red-image!]
		data		[integer!]
	][]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
	][null]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
	][0]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
	][0]

	delete: func [img [red-image!]][]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
	][0]

	load-image: func [
		src			[red-string!]
		return:		[int-ptr!]
	][null]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb		[byte-ptr!]
		alpha	[byte-ptr!]
		color	[red-tuple!]
		return: [int-ptr!]
	][null]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
	][null]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
	][null]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
	][null]
]
