Red/System [
	Title:	"camera device"
	Author: "bitbegin"
	File: 	%camera-dev.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

camera-dev: context [
	#include %v4l2.reds

	open: func [
		name		[c-string!]
		w			[integer!]
		h			[integer!]
		cfg			[int-ptr!]
		return:		[logic!]
		/local
			config	[v4l2-config!]
			hr		[integer!]
	][
		config: as v4l2-config! allocate size? v4l2-config!
		cfg/1: as integer! config
		config/name: name
		config/width: w
		config/height: h
		hr: v4l2/open config
		if hr = 0 [return true]
		free as byte-ptr! config
		cfg/1: 0
		false
	]

	close: func [
		cfg			[integer!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		v4l2/close config
		free as byte-ptr! cfg
	]

	attach: func [
		cfg			[integer!]
		widget		[int-ptr!]
		cb			[int-ptr!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		v4l2/attach config widget cb
	]

	start: func [
		cfg			[integer!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		v4l2/start config
	]

	get-data: func [
		cfg			[integer!]
		data		[int-ptr!]
		dlen		[int-ptr!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		data/1: as integer! config/buffer
		dlen/1: config/bused
	]

	get-widget: func [
		cfg			[integer!]
		return:		[int-ptr!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		config/widget
	]

	signal: func [
		cfg			[integer!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		v4l2/signal config
	]

	trylock: func [
		cfg			[integer!]
		return:		[integer!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		v4l2/trylock config
	]

	unlock: func [
		cfg			[integer!]
		/local
			config	[v4l2-config!]
	][
		config: as v4l2-config! cfg
		v4l2/unlock config
	]

	collect: func [
		cb			[int-ptr!]
		return:		[integer!]
	][
		v4l2/collect cb
	]

	get-size: func [
		cfg		[integer!]
		w		[int-ptr!]
		h		[int-ptr!]
		/local
			config [v4l2-config!]
	][
		config: as v4l2-config! cfg
		w/value: config/width
		h/value: config/height
	]

	get-pixbuf: func [
		cfg		[integer!]
		return: [int-ptr!]
		/local
			config [v4l2-config!]
			pixbuf [int-ptr!]
			input	[handle!]
			w h	   [integer!]
	][
		config: as v4l2-config! cfg

		pixbuf: either config/format = V4L2_PIX_FMT_MJPEG [
			input: g_memory_input_stream_new_from_data config/buffer config/bused null
			gdk_pixbuf_new_from_stream input null null
		][
			w: config/width
			h: config/height
			gdk_pixbuf_new 0 yes 8 w h
		]
		image-utils/YUYV-to-RGB32 w h config/buffer as int-ptr! gdk_pixbuf_get_pixels pixbuf
		pixbuf
	]
]
