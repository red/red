Red/System [
	Title:	"camera"
	Author: "bitbegin"
	File: 	%camera.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %camera-dev.reds

cb-data: as red-block! 0

collect-cb: func [
	node		[c-string!]
	name		[c-string!]
	/local
		len1	[integer!]
		len2	[integer!]
		buf		[byte-ptr!]
		pos		[integer!]
		str		[red-string!]
][
	len1: length? node
	len2: length? name
	buf: allocate len1 + len2 + 3
	copy-memory buf as byte-ptr! node len1
	pos: len1 + 1
	buf/pos: #":"
	pos: pos + 1
	buf/pos: #" "
	copy-memory buf + pos as byte-ptr! name len2
	pos: len1 + len2 + 3
	buf/pos: null-byte
	str: string/load as-c-string buf pos - 1 UTF-8
	free buf
	block/rs-append cb-data as red-value! str
]

collect-camera: func [
	data		[red-block!]
	return:		[integer!]
][
	;-- clear data
	data/header: TYPE_NONE
	block/make-at data 2
	cb-data: data
	camera-dev/collect as int-ptr! :collect-cb
]

select-camera*: func [
	widget		[handle!]
	data		[red-block!]
	sel			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		cfg		[integer!]
		cnt		[integer!]
		str		[red-string!]
		s		[series!]
		unit	[integer!]
		head	[byte-ptr!]
		tail	[byte-ptr!]
		p		[byte-ptr!]
		len		[integer!]
		node	[byte-ptr!]
][
	cfg: as integer! GET-CAMERA-CFG(widget)
	if cfg <> 0 [
		camera-dev/close cfg
		SET-CAMERA-CFG(widget 0)
	]
	cnt: block/rs-length? data
	unless all [
		cnt > 0
		sel >= 0
		sel < cnt
	][exit]
	str: as red-string! block/rs-abs-at data sel
	if TYPE_OF(str) <> TYPE_STRING [exit]
	s:    GET_BUFFER(str)
	unit: GET_UNIT(s)
	if unit <> Latin1 [exit]
	head: as byte-ptr! s/offset
	tail: as byte-ptr! s/tail
	p: head
	while [p < tail][
		if p/1 = #":" [break]
		p: p + 1
	]
	len: as integer! p - head
	node: allocate len + 1
	copy-memory node head len
	p: node + len
	p/1: null-byte

	cfg: 0
	if camera-dev/open as c-string! node width height :cfg [
		SET-CAMERA-CFG(widget cfg)
		camera-dev/attach cfg widget as int-ptr! :camera-cb
		camera-dev/start cfg
	]
	free node
]

camera-get-image: func [
	widget	[handle!]
	img		[red-image!]
	/local
		cfg [integer!]
		data	[integer!]
		dlen	[integer!]
		pixbuf	[handle!]
][
	cfg: as integer! GET-CAMERA-CFG(widget)
	pixbuf: GET-CAMERA-IMG(widget)
	if pixbuf <> null [pixbuf: gdk_pixbuf_copy pixbuf]

	if all [
		cfg <> 0
		null? pixbuf
		0 = camera-dev/trylock cfg
	][
		data: 0
		dlen: 0
		pixbuf: null
		camera-dev/get-data cfg :data :dlen
		if dlen <> 0 [
			pixbuf: camera-dev/get-pixbuf cfg
			camera-dev/signal cfg
		]
		camera-dev/unlock cfg
	]
	if pixbuf <> null [
		image/init-image img OS-image/load-pixbuf pixbuf
	]
]

init-camera: func [
	widget		[handle!]
	data		[red-block!]
	sel			[red-integer!]
	size		[red-pair!]
	/local
		cnt		[integer!]
][
	cnt: collect-camera data
	if TYPE_OF(sel) = TYPE_INTEGER [
		select-camera* widget data sel/value - 1 size/x size/y
	]
]

select-camera: func [
	widget		[handle!]
	sel			[integer!]
	/local
		values	[red-value!]
		data	[red-block!]
		size	[red-pair!]
][
	values: get-face-values widget
	data: as red-block! values + FACE_OBJ_DATA
	size: as red-pair! values + FACE_OBJ_SIZE
	select-camera* widget data sel size/x size/y
]

stop-camera: func [
	widget		[handle!]
	/local
		cfg		[integer!]
][
	cfg: as integer! GET-CAMERA-CFG(widget)
	if cfg <> 0 [
		camera-dev/close cfg
		SET-CAMERA-CFG(widget 0)
	]
]