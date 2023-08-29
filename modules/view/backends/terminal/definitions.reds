Red/System [
	Title:	"Windows platform GUI imports"
	Author: "Nenad Rakocevic"
	File: 	%win32.red
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tiny-str!: alias struct! [	;-- 32 bytes
	pad1	[float!]
	pad2	[float!]
	pad3	[float!]
	pad4	[float!]
]
	
;=== widget definitions ===

#define WIDGET_FLAG_PAIR_SIZE	00010000h
#define WIDGET_FLAG_HIDDEN		00020000h
#define WIDGET_FLAG_DISABLE		00040000h
#define WIDGET_FLAG_DRAG		00080000h
#define WIDGET_FLAG_ALL_OVER	00100000h
#define WIDGET_FLAG_EDITABLE	00200000h
#define WIDGET_FLAG_FOCUSABLE	00400000h
#define WIDGET_FLAG_TOP			00800000h
#define WIDGET_FLAG_AWAY		01000000h
#define WIDGET_FLAG_FOCUS		02000000h
#define WIDGET_FLAG_POPUP		04000000h
#define WIDGET_FLAG_MODAL		08000000h
#define WIDGET_FLAG_LAYER		10000000h
#define WIDGET_FLAG_RESIZE		20000000h

#define WIDGET_TYPE(widget)				[widget/type]
#define WIDGET_SET_FLAG(widget flag)	[widget/flags: widget/flags or flag]
#define WIDGET_UNSET_FLAG(widget flag)	[widget/flags: widget/flags and (not flag)]
#define WIDGET_FOCUSED?(widget)			[all [widget <> null widget/flags and WIDGET_FLAG_FOCUS <> 0]]
#define WIDGET_EDITABLE?(widget)		[widget/flags and WIDGET_FLAG_EDITABLE <> 0]
#define WIDGET_FOCUSABLE?(widget)		[widget/flags and WIDGET_FLAG_FOCUSABLE <> 0]

point!: alias struct! [
	x	[float32!]
	y	[float32!]
]

RECT_F!: alias struct! [
	left		[float32!]
	top			[float32!]
	right		[float32!]
	bottom		[float32!]
]

ROUNDED_RECT_F!: alias struct! [
	left		[float32!]
	top			[float32!]
	right		[float32!]
	bottom		[float32!]
	radiusX		[float32!]
	radiusY		[float32!]
]

#enum font-style! [
	FONT_STYLE_NORMAL:		0
	FONT_STYLE_ITALIC:		1
	FONT_STYLE_BOLD:		2
	FONT_STYLE_UNDERLINE:	4
	FONT_STYLE_STRIKE:		8
]

#define TEXT_ALIGN_LEFT 		0
#define TEXT_ALIGN_RIGHT 		1
#define TEXT_ALIGN_CENTER 		2
#define TEXT_ALIGN_TOP 			0
#define TEXT_ALIGN_VCENTER		4
#define TEXT_ALIGN_BOTTOM 		8
#define TEXT_WRAP_FLAG	 		20h

update-func!: alias function! [
	widget	[widget!]
]

render-func!: alias function! [
	x		[integer!]
	y		[integer!]
	widget	[widget!]
]

event-handler!: alias function! [
	type	[event-type!]
	event	[widget-event!]
	return: [integer!]
]

widget!: alias struct! [
	type		[integer!]
	flags		[integer!]
	box			[RECT_F! value]
	parent		[widget!]			;-- parent widget
	data		[int-ptr!]			;-- extra data for each type
	update		[update-func!]
	render		[render-func!]
	on-event	[event-handler!]
	;-- face object
	face		[integer!]
	obj-ctx		[node!]
	obj-class	[integer!]
	obj-cb		[node!]
]

widget-event!: alias struct! [
	widget	[widget!]
	pt		[point! value]
	data	[integer!]
	fdata	[float32!]
]
	
window-manager!: alias struct! [
	flags		[integer!]
	box			[RECT_F! value]		;-- bounding box
	window		[widget!]
	focused		[widget!]
	editable	[integer!]			;-- number of editable widget
]

#enum pixel-flags! [
	PIXEL_BLINK:		1
	PIXEL_BOLD:			2
	PIXEL_FAINT:		4
	PIXEL_INVERTED: 	8
	PIXEL_UNDERLINE:	10h
	PIXEL_UNDERLINE_2:	20h
	PIXEL_STRIKE:		40h
	PIXEL_AUTOMERGE:	80h
	PIXEL_SKIP:			0100h
]

#define DRAW_PIXEL?(p) [p/flags and PIXEL_SKIP = 0]

#enum color-type! [
    default-color:	0
    palette-16:		1
    palette-256:	2
    true-color:		4
]

color!: alias struct! [
	type		[byte!]
	red			[byte!]
	green		[byte!]
	blue		[byte!]
]

pixel!: alias struct! [
	code-point	[integer!]
	bg-color	[integer!]
	fg-color	[integer!]
	flags		[integer!]
]