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

select-camera: func [
	widget		[handle!]
	data		[red-block!]
	sel			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		cfg		[integer!]
		cnt		[integer!]
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
	cfg: 0
	if camera-dev/open "/dev/video0" width height :cfg [
		SET-CAMERA-CFG(widget cfg)
		camera-dev/attach cfg widget as int-ptr! :camera-cb
		camera-dev/start cfg
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
		select-camera widget data sel/value - 1 size/x size/y
	]
]

