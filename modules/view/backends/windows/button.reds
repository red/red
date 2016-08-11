Red/System [
	Title:	"Windows button widget"
	Author: "Qingtian Xie"
	File: 	%button.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-button: func [
	hWnd   [handle!]
	facets [red-value!]
	/local
		imgs	[red-block!]
		img-1	[red-image!]
		img		[red-image!]
		beg		[red-image!]
		size	[red-pair!]
		blk		[red-block!]
		BIL		[BUTTON_IMAGELIST]
		width	[integer!]
		height	[integer!]
		num		[integer!]
		i		[integer!]
		sz		[integer!]
		bitmap	[integer!]
		hlist	[integer!]
][
	BIL:  declare BUTTON_IMAGELIST
	imgs: as red-block! facets + FACE_OBJ_IMAGE
	size: as red-pair! facets + FACE_OBJ_SIZE

	switch TYPE_OF(imgs) [
		TYPE_IMAGE [
			blk: block/push-only* 1
			img: as red-image! imgs
			block/rs-append blk as red-value! imgs
			imgs: blk
			num: 1
			width: IMAGE_WIDTH(img/size)
			height: IMAGE_HEIGHT(img/size)
		]
		TYPE_BLOCK [
			num: block/rs-length? imgs
			beg:  as red-image! block/rs-head imgs
			img:  beg + 1
			if all [num = 2 TYPE_OF(img) = TYPE_PAIR][
				size: as red-pair! img
				num: 1
			]
			width: size/x
			height: size/y
		]
		default [exit]
	]

	sz: either 1 < num [6][1]
	hlist: ImageList_Create width height ILC_COLOR32 sz 0
	beg:  as red-image! block/rs-head imgs
	img-1: image/resize beg width height
	i: 0
	loop sz [
		either i < num [
			img: beg + i
			img: either zero? i [img-1][image/resize img width height]
		][
			img: img-1
		]
		bitmap: 0
		GdipCreateHBITMAPFromBitmap as-integer img/node :bitmap 0
		ImageList_Add hlist bitmap 0
		DeleteObject as handle! bitmap
		if all [i > 0 i < num][image/delete img]
		i: i + 1
	]
	image/delete img-1
	BIL/handle: hlist
	BIL/align: 4
	SendMessage hWnd BM_SETSTYLE BS_BITMAP or GetWindowLong hWnd GWL_STYLE 0
	SendMessage hWnd BCM_SETIMAGELIST 0 0
	SendMessage hWnd BCM_SETIMAGELIST 0 as-integer BIL
]

;update-button: func [				;-- TBD implement it
;	face  [red-object!]
;	value [red-value!]
;	sym   [integer!]
;	index [integer!]
;	part  [integer!]
;	/local
;		hWnd [handle!]
;][
;	hWnd: get-face-handle face
;]