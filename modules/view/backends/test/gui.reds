Red/System [
	Title:	"Test GUI backend"
	Author: "Nenad Rakocevic"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %text-box.reds
#include %draw.reds
#include %events.reds

handle-counter: as handle! 0

make-handle: func [return: [handle!]][
	handle-counter: handle-counter + 1
	handle-counter
]

get-face-obj: func [
	hWnd	[handle!]
	return: [red-object!]
	/local
		face [red-object!]
][
	;face: declare red-object!
	;face/header: GetWindowLong hWnd wc-offset
	;face/ctx:	 as node! GetWindowLong hWnd wc-offset + 4
	;face/class:  GetWindowLong hWnd wc-offset + 8
	;face/on-set: as node! GetWindowLong hWnd wc-offset + 12
	;face
	null
]

get-face-values: func [
	hWnd	[handle!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		node [node!]
		s	 [series!]
][
	;node: as node! GetWindowLong hWnd wc-offset + 4
	;ctx: TO_CTX(node)
	;s: as series! ctx/values/value
	;s/offset
	null
]

get-node-facet: func [
	node	[node!]
	facet	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset + facet
]

face-handle?: func [
	face	[red-object!]
	return: [handle!]									;-- returns NULL if no handle
	/local
		state  [red-block!]
		handle [red-handle!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: as red-handle! block/rs-head state
		if TYPE_OF(handle) = TYPE_HANDLE [return as handle! handle/value]
	]
	null
]

get-face-handle: func [
	face	[red-object!]
	return: [handle!]
	/local
		state  [red-block!]
		handle [red-handle!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	handle: as red-handle! block/rs-head state
	assert TYPE_OF(handle) = TYPE_HANDLE
	as handle! handle/value
]

free-faces: func [
	face	[red-object!]
	/local
		values	[red-value!]
		type	[red-word!]
		obj		[red-object!]
		tail	[red-object!]
		pane	[red-block!]
		state	[red-value!]
		rate	[red-value!]
		sym		[integer!]
		dc		[integer!]
		flags	[integer!]
		handle	[handle!]
][
	;handle: face-handle? face
	;if null? handle [exit]

	values: object/get-values face
	;type: as red-word! values + FACE_OBJ_TYPE
	;sym: symbol/resolve type/symbol

	;obj: as red-object! values + FACE_OBJ_FONT
	;if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]
	
	;obj: as red-object! values + FACE_OBJ_PARA
	;if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]


init: func [
	/local
		ver   [red-tuple!]
		int   [red-integer!]
][
	ver: as red-tuple! #get system/view/platform/version

	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: 00010000h
	
	int: as red-integer! #get system/view/platform/build
	int/header: TYPE_INTEGER
	int/value:  1

	int: as red-integer! #get system/view/platform/product
	int/header: TYPE_INTEGER
	int/value:  1
]


get-screen-size: func [
	id		[integer!]
	return: [red-pair!]
][
	pair/push 2000 1000
]

get-text-size: func [
	text	[red-string!]
	hFont	[handle!]
	p		[red-pair!]
	return: [red-pair!]
][
	pair/push 80 20
]


make-font: func [
	face [red-object!]
	font [red-object!]
	return: [handle!]
][
	make-handle
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]							;-- 0-based index
	return: [handle!]
	/local
		state  [red-block!]
		handle [red-handle!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: (as red-handle! block/rs-head state) + idx
		if TYPE_OF(handle) = TYPE_HANDLE [
			return as handle! handle/value
		]
	]
	null
]

update-para: func [
	para	[red-object!]
	flags	[integer!]
][

]

update-font: func [
	font	[red-object!]
	flags	[integer!]
][

]

OS-request-font: func [
	font	 [red-object!]
	selected [red-object!]
	mono?	 [logic!]
][

]

OS-request-file: func [
	title	[red-string!]
	name	[red-file!]
	filter	[red-block!]
	save?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	as red-value! none-value
]


OS-request-dir: func [
	title	[red-string!]
	dir		[red-file!]
	filter	[red-block!]
	keep?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	as red-value! none-value
]



update-scroller: func [
	scroller [red-object!]
	flags [integer!]
][

]


OS-redraw: func [hWnd [integer!]][]

OS-refresh-window: func [hWnd [integer!]][]

OS-show-window: func [
	hWnd [integer!]
][

]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
][
	as-integer make-handle
]


unlink-sub-obj: func [
	face  [red-object!]
	obj   [red-object!]
	field [integer!]
	/local
		values [red-value!]
		parent [red-block!]
		res	   [red-value!]
][
	values: object/get-values obj
	parent: as red-block! values + field
	
	;if TYPE_OF(parent) = TYPE_BLOCK [
	;	res: block/find parent as red-value! face null no no yes no null null no no no no
	;	if TYPE_OF(res) <> TYPE_NONE [_series/remove as red-series! res null]
	;	if all [
	;		field = FONT_OBJ_PARENT
	;		block/rs-tail? parent
	;	][
	;		free-font obj
	;	]
	;]
]

OS-update-view: func [
	face [red-object!]
	/local
		ctx		[red-context!]
		state	[red-block!]
		int		[red-integer!]
		s		[series!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	state: as red-block! s/offset + FACE_OBJ_STATE
	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	int: int + 1
	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
][
	free-faces face
]

OS-update-facet: func [
	face   [red-object!]
	facet  [red-word!]
	value  [red-value!]
	action [red-word!]
	new	   [red-value!]
	index  [integer!]
	part   [integer!]
][

]

OS-to-image: func [
	face	[red-object!]
	return: [red-image!]
][
	null
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds no no no no
]

OS-draw-face: func [
	ctx		[draw-ctx!]
	cmds	[red-block!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		catch RED_THROWN_ERROR [parse-draw ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]