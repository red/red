Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw-d2d.reds
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

OS-text-box-color: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		dl		[IDWriteTextLayout]
		brush	[integer!]
][
	brush: select-brush color
	if zero? brush [
		this: as this! dc
		rt: as ID2D1HwndRenderTarget this/vtbl
		rt/CreateSolidColorBrush this to-dx-color color null null :brush
		put-brush color brush
	]

	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetDrawingEffect this as this! brush pos len
]

OS-text-box-background: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
][
	0
]

OS-text-box-weight: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
][
	0
]


OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
][
	0
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	0
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	0
]

OS-text-box-border: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	0
]

OS-text-box-metrics: func [
	layout	[handle!]
	return: [red-block!]
	/local
		this			[this!]
		dl				[IDWriteTextLayout]
		lineCount		[integer!]
		maxBidiDepth	[integer!]
		layoutHeight	[float32!]
		layoutWidth		[float32!]
		height			[float32!]
		widthTrailing	[float32!]
		width			[float32!]
		top				[float32!]
		left			[integer!]
		metrics			[DWRITE_TEXT_METRICS]
		blk				[red-block!]
		int				[red-value!]
		hr				[integer!]
][
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl

	left: 0
	metrics: as DWRITE_TEXT_METRICS :left
	hr: dl/GetMetrics this metrics
	#if debug? = yes [if hr <> 0 [log-error hr]]

	blk: block/push-only* 3
	if zero? hr [
		integer/make-in blk as-integer metrics/width
		integer/make-in blk as-integer metrics/height
		integer/make-in blk metrics/lineCount
	]
	blk
]