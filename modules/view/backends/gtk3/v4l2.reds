Red/System [
	Title:	"v4l2 interface"
	Author: "bitbegin"
	File: 	%v4l2.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

pthread_mutex_t: alias struct! [
	__sig 		[integer!]
	opaque1     [integer!]	;opaque size =40
	opaque2		[integer!]
	opaque3     [integer!]
	opaque4		[integer!]
	opaque5     [integer!]
	opaque6		[integer!]
	opaque7     [integer!]
	opaque8		[integer!]
	opaque9     [integer!]
	opaque10	[integer!]
]

pthread_cond_t: alias struct! [
	__sig       [integer!]
	opaque1     [integer!]	;opaque size =24
	opaque2		[integer!]
	opaque3     [integer!]
	opaque4		[integer!]
	opaque5     [integer!]
	opaque6		[integer!]
]

v4l2-config!: alias struct! [
	name		[c-string!]
	fd			[integer!]
	format		[integer!]
	width		[integer!]
	height		[integer!]
	imgsize		[integer!]
	buffer		[byte-ptr!]
	bused		[integer!]
	running?	[logic!]
	thread		[integer!]
	mutex		[pthread_mutex_t value]
	cond		[pthread_cond_t value]
	cb			[int-ptr!]
	widget		[int-ptr!]
]

v4l2: context [

	#import [
		LIBC-file cdecl [
			_open:	"open" [
				filename	[c-string!]
				flags		[integer!]
				return:		[integer!]
			]
			_read:	"read" [
				file		[integer!]
				buffer		[byte-ptr!]
				bytes		[integer!]
				return:		[integer!]
			]
			_write:	"write" [
				file		[integer!]
				buffer		[byte-ptr!]
				bytes		[integer!]
				return:		[integer!]
			]
			_close:	"close" [
				file		[integer!]
				return:		[integer!]
			]
			_ioctl:	"ioctl" [
				fd			[integer!]
				request		[integer!]
				arg			[int-ptr!]
				return:		[integer!]
			]
			_mmap: "mmap" [
				address		[byte-ptr!]
				size		[integer!]
				protection	[integer!]
				flags		[integer!]
				fd			[integer!]
				offset		[integer!]
				return:		[byte-ptr!]
			]
			_munmap: "munmap" [
				address		[byte-ptr!]
				size		[integer!]
				return:		[integer!]
			]
		]
		"libpthread.so.0" cdecl [
			pthread_create: "pthread_create" [
				thread		[int-ptr!]
				attr		[int-ptr!]
				start		[int-ptr!]
				arglist		[int-ptr!]
				return:		[integer!]
			]
			pthread_join: "pthread_join" [
				thread		[integer!]
				retval		[int-ptr!]
				return:		[integer!]
			]
			pthread_cancel: "pthread_cancel" [
				thread		[integer!]
				return:		[integer!]
			]
			pthread_mutex_init: "pthread_mutex_init" [
				mutex		[int-ptr!]
				attr		[int-ptr!]
				return:		[integer!]
			]
			pthread_cond_init: "pthread_cond_init" [
				cond		[int-ptr!]
				attr		[int-ptr!]
				return:		[integer!]
			]
			pthread_mutex_destroy: "pthread_mutex_destroy" [
				mutex		[int-ptr!]
				return:		[integer!]
			]
			pthread_cond_destroy: "pthread_cond_destroy" [
				cond		[int-ptr!]
				return:		[integer!]
			]
			pthread_mutex_lock: "pthread_mutex_lock" [
				mutex		[int-ptr!]
				return:		[integer!]
			]
			pthread_mutex_trylock: "pthread_mutex_trylock" [
				mutex		[int-ptr!]
				return:		[integer!]
			]
			pthread_mutex_unlock: "pthread_mutex_unlock" [
				mutex		[int-ptr!]
				return:		[integer!]
			]
			pthread_cond_wait: "pthread_cond_wait" [
				cond		[int-ptr!]
				mutex		[int-ptr!]
				return:		[integer!]
			]
			pthread_cond_signal: "pthread_cond_signal" [
				cond		[int-ptr!]
				return:		[integer!]
			]
		]
		"libudev.so.1" cdecl [
			udev_new: "udev_new" [
				return:		[int-ptr!]
			]
			udev_unref: "udev_unref" [
				udev		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_monitor_new_from_netlink: "udev_monitor_new_from_netlink" [
				udev		[int-ptr!]
				name		[c-string!]
				return:		[int-ptr!]
			]
			udev_monitor_unref: "udev_monitor_unref" [
				monitor		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_monitor_filter_add_match_subsystem_devtype: "udev_monitor_filter_add_match_subsystem_devtype" [
				monitor		[int-ptr!]
				subsys		[c-string!]
				devtype		[c-string!]
				return:		[integer!]
			]
			udev_monitor_enable_receiving: "udev_monitor_enable_receiving" [
				monitor		[int-ptr!]
				return:		[integer!]
			]
			udev_monitor_receive_device: "udev_monitor_receive_device" [
				monitor		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_device_unref: "udev_device_unref" [
				dev			[int-ptr!]
				return:		[int-ptr!]
			]
			udev_enumerate_new: "udev_enumerate_new" [
				udev		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_enumerate_add_match_subsystem: "udev_enumerate_add_match_subsystem" [
				enum		[int-ptr!]
				sub			[c-string!]
				return:		[integer!]
			]
			udev_enumerate_scan_devices: "udev_enumerate_scan_devices" [
				enum		[int-ptr!]
				return:		[integer!]
			]
			udev_enumerate_get_list_entry: "udev_enumerate_get_list_entry" [
				enum		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_enumerate_unref: "udev_enumerate_unref" [
				enum		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_list_entry_get_next: "udev_list_entry_get_next" [
				list		[int-ptr!]
				return:		[int-ptr!]
			]
			udev_list_entry_get_name: "udev_list_entry_get_name" [
				list		[int-ptr!]
				return:		[c-string!]
			]
			udev_device_new_from_syspath: "udev_device_new_from_syspath" [
				udev		[int-ptr!]
				syspath		[c-string!]
				return:		[int-ptr!]
			]
			udev_device_get_devnode: "udev_device_get_devnode" [
				dev			[int-ptr!]
				return:		[c-string!]
			]
		]
	]

	QBUF-CALLBACK!: alias function! [cfg [integer!]]
	COLLECT-CALLBACK!: alias function! [node [c-string!] name [c-string!]]

	#define _O_RDWR		2

	#define VIDIOC_QUERYCAP					80685600h
	#define VIDIOC_ENUM_FMT					C0405602h
	#define VIDIOC_G_FMT					C0CC5604h
	#define VIDIOC_S_FMT					C0CC5605h
	#define VIDIOC_REQBUFS					C0145608h
	#define VIDIOC_QUERYBUF					C0445609h
	#define VIDIOC_QBUF						C044560Fh
	#define VIDIOC_STREAMON					40045612h
	#define VIDIOC_DQBUF					C0445611h


	#define V4L2_CAP_VIDEO_CAPTURE			00000001h
	#define V4L2_CAP_STREAMING				04000000h
	#define V4L2_CAP_META_CAPTURE			00800000h

	#define V4L2_BUF_TYPE_VIDEO_CAPTURE		1

	#define V4L2_PIX_FMT_MJPEG				47504A4Dh
	#define V4L2_PIX_FMT_YUYV				56595559h

	#define V4L2_MEMORY_MMAP				1
	#define V4L2_MEMORY_USERPTR				2

	filters: [
		V4L2_PIX_FMT_MJPEG
		V4L2_PIX_FMT_YUYV
	]

	v4l2_capability: alias struct! [
		driver1		[integer!]
		driver2		[integer!]
		driver3		[integer!]
		driver4		[integer!]
		card1		[integer!]
		card2		[integer!]
		card3		[integer!]
		card4		[integer!]
		card5		[integer!]
		card6		[integer!]
		card7		[integer!]
		card8		[integer!]
		bus-info1	[integer!]
		bus-info2	[integer!]
		bus-info3	[integer!]
		bus-info4	[integer!]
		bus-info5	[integer!]
		bus-info6	[integer!]
		bus-info7	[integer!]
		bus-info8	[integer!]
		version		[integer!]
		cap			[integer!]
		dev-caps	[integer!]
		reserved1	[integer!]
		reserved2	[integer!]
		reserved3	[integer!]
	]

	v4l2_fmtdesc: alias struct! [
		index		[integer!]
		type		[integer!]
		flags		[integer!]
		desc1		[integer!]
		desc2		[integer!]
		desc3		[integer!]
		desc4		[integer!]
		desc5		[integer!]
		desc6		[integer!]
		desc7		[integer!]
		desc8		[integer!]
		format		[integer!]
		reserved1	[integer!]
		reserved2	[integer!]
		reserved3	[integer!]
		reserved4	[integer!]
	]

	v4l2_pix_format: alias struct! [
		width		[integer!]
		height		[integer!]
		format		[integer!]
		field		[integer!]
		bytes_line	[integer!]
		imgsize		[integer!]
		colorspace	[integer!]
		priv		[integer!]
		flags		[integer!]
		enc			[integer!]
		quatiz		[integer!]
		xfer_func	[integer!]
	]

	;-- v4l2_format: 4 + 200

	v4l2_requestbuffers: alias struct! [
		count		[integer!]
		type		[integer!]
		memory		[integer!]
		caps		[integer!]
		reserved	[integer!]
	]

	timeval: alias struct! [
		tv_sec		[integer!]
		tv_usec		[integer!]
	]

	v4l2_timecode: alias struct! [
		type		[integer!]
		flags		[integer!]
		time		[integer!]
		userbits	[integer!]
	]

	v4l2_buffer: alias struct! [
		index		[integer!]
		type		[integer!]
		used		[integer!]
		flags		[integer!]
		field		[integer!]
		timestamp	[timeval value]
		timecode	[v4l2_timecode value]
		sequence	[integer!]
		memory		[integer!]
		m			[integer!]
		length		[integer!]
		reserved2	[integer!]
		req_fd		[integer!]
	]

	open: func [
		config		[v4l2-config!]
		return:		[integer!]
		/local
			fd		[integer!]
			hr		[integer!]
			cap		[v4l2_capability value]
			fdesc	[v4l2_fmtdesc value]
			len		[integer!]
			i		[integer!]
			found	[logic!]
			fmt		[int-ptr!]
			pfmt	[v4l2_pix_format]
			rbuf	[v4l2_requestbuffers value]
			buf		[v4l2_buffer value]
	][
		config/fd: -1
		fd: _open config/name _O_RDWR
		if fd = -1 [return -1]
		set-memory as byte-ptr! cap null-byte size? v4l2_capability
		hr: _ioctl fd VIDIOC_QUERYCAP as int-ptr! :cap
		if hr <> 0 [
			_close fd
			return -2
		]

		if (cap/cap and V4L2_CAP_VIDEO_CAPTURE) = 0 [
			_close fd
			return -3
		]

		if (cap/cap and V4L2_CAP_STREAMING) = 0 [
			_close fd
			return -4
		]

		config/format: 0

		fdesc/index: 0
		fdesc/type: V4L2_BUF_TYPE_VIDEO_CAPTURE
		while [0 = _ioctl fd VIDIOC_ENUM_FMT as int-ptr! :fdesc][
			either config/format = 0 [
				config/format: fdesc/format
			][
				if fdesc/format = V4L2_PIX_FMT_MJPEG [
					config/format: V4L2_PIX_FMT_MJPEG
				]
			]
			;print-line [fdesc/index ": " as c-string! :fdesc/desc1]
			fdesc/index: fdesc/index + 1
		]

		len: size? filters
		i: 1
		found: no
		loop len [
			if filters/i = config/format [
				found: yes
				i: i + 1
				break
			]
			i: i + 1
		]
		unless found [
			_close fd
			return -5
		]

		fmt: as int-ptr! allocate 256
		set-memory as byte-ptr! fmt null-byte 256

		;-- use VIDIOC_G_FMT to init v4l2_format
		fmt/1: V4L2_BUF_TYPE_VIDEO_CAPTURE
		hr: _ioctl fd VIDIOC_G_FMT fmt
		if hr <> 0 [
			free as byte-ptr! fmt
			_close fd
			return -6
		]

		;-- set v4l2_format
		pfmt: as v4l2_pix_format fmt + 1
		pfmt/format: config/format
		pfmt/width: config/width
		pfmt/height: config/height
		hr: _ioctl fd VIDIOC_S_FMT fmt
		if hr <> 0 [
			free as byte-ptr! fmt
			_close fd
			return -7
		]

		;-- check the v4l2_format result
		hr: _ioctl fd VIDIOC_G_FMT fmt
		if hr <> 0 [
			free as byte-ptr! fmt
			_close fd
			return -8
		]
		config/width: pfmt/width
		config/height: pfmt/height
		config/imgsize: pfmt/imgsize
		free as byte-ptr! fmt

		;-- set buffer count
		set-memory as byte-ptr! rbuf null-byte size? v4l2_requestbuffers
		rbuf/count: 1
		rbuf/type: V4L2_BUF_TYPE_VIDEO_CAPTURE
		rbuf/memory: V4L2_MEMORY_USERPTR
		hr: _ioctl fd VIDIOC_REQBUFS as int-ptr! :rbuf
		if hr <> 0 [
			_close fd
			return -9
		]

		;-- use allocate buffer
		config/buffer: allocate config/imgsize
		set-memory as byte-ptr! buf null-byte size? v4l2_buffer
		buf/type: V4L2_BUF_TYPE_VIDEO_CAPTURE
		buf/memory: V4L2_MEMORY_USERPTR
		buf/index: 0
		buf/m: as integer! config/buffer
		buf/length: config/imgsize
		hr: _ioctl fd VIDIOC_QBUF as int-ptr! :buf
		if hr <> 0 [
			free config/buffer
			_close fd
			return -10
		]
		i: V4L2_BUF_TYPE_VIDEO_CAPTURE
		_ioctl fd VIDIOC_STREAMON :i
		config/running?: no
		config/bused: 0

		config/fd: fd
		0
	]

	close: func [
		config		[v4l2-config!]
	][
		if config/fd <> -1 [
			stop config
			free config/buffer
			_close config/fd
			config/fd: -1
		]
	]

	thread-cb: func [
		[cdecl]
		arg			[integer!]
		return:		[integer!]
		/local
			config	[v4l2-config!]
			buf		[v4l2_buffer value]
			hr		[integer!]
			pcb		[QBUF-CALLBACK!]
	][
		config: as v4l2-config! arg
		while [config/running?][
			pthread_mutex_lock :config/mutex
			set-memory as byte-ptr! buf null-byte size? v4l2_buffer
			buf/type: V4L2_BUF_TYPE_VIDEO_CAPTURE
			buf/memory: V4L2_MEMORY_USERPTR
			hr: _ioctl config/fd VIDIOC_DQBUF as int-ptr! :buf
			if any [
				hr <> 0
				not config/running?
			][
				pthread_mutex_unlock :config/mutex
				return -1
			]
			config/bused: buf/used
			unless null? config/cb [
				pcb: as QBUF-CALLBACK! config/cb
				pcb arg
			]
			pthread_cond_wait :config/cond :config/mutex
			config/bused: 0
			pthread_mutex_unlock :config/mutex
			hr: _ioctl config/fd VIDIOC_QBUF as int-ptr! :buf
			if hr <> 0 [
				return -1
			]
		]
		0
	]

	signal: func [
		config		[v4l2-config!]
	][
		pthread_cond_signal :config/cond
	]

	trylock: func [
		config		[v4l2-config!]
		return:		[integer!]
	][
		pthread_mutex_trylock :config/mutex
	]

	unlock: func [
		config		[v4l2-config!]
	][
		pthread_mutex_unlock :config/mutex
	]

	attach: func [
		config		[v4l2-config!]
		widget		[int-ptr!]
		cb			[int-ptr!]
	][
		config/widget: widget
		config/cb: cb
	]

	start: func [
		config		[v4l2-config!]
		return:		[logic!]
		/local
			hr		[integer!]
	][
		if config/running? [return false]
		hr: pthread_mutex_init :config/mutex null
		if hr < 0 [
			return false
		]
		hr: pthread_cond_init :config/cond null
		if hr < 0 [
			pthread_mutex_destroy :config/mutex
			return false
		]
		hr: pthread_create :config/thread null as int-ptr! :thread-cb as int-ptr! config
		if hr <> 0 [return false]
		config/running?: yes
		true
	]

	stop: func [
		config		[v4l2-config!]
		/local
			val		[integer!]
	][
		config/running?: no
		val: 0
		signal config
		pthread_join config/thread :val
		pthread_cond_destroy :config/cond
		pthread_mutex_destroy :config/mutex
	]


	;-- use udev to collect devices
	collect: func [
		cb			[int-ptr!]
		return:		[integer!]
		/local
			ret		[integer!]
			udev	[int-ptr!]
			enum	[int-ptr!]
			devs	[int-ptr!]
			list	[int-ptr!]
			path	[c-string!]
			dev		[int-ptr!]
			node	[c-string!]
			fd		[integer!]
			hr		[integer!]
			cap		[v4l2_capability value]
			pcb		[COLLECT-CALLBACK!]
	][
		ret: 0
		udev: udev_new
		enum: udev_enumerate_new udev
		udev_enumerate_add_match_subsystem enum "video4linux"
		udev_enumerate_scan_devices enum
		devs: udev_enumerate_get_list_entry enum
		list: devs
		while [list <> null][
			path: udev_list_entry_get_name list
			dev: udev_device_new_from_syspath udev path
			node: udev_device_get_devnode dev
			fd: _open node _O_RDWR
			if fd <> -1 [
				set-memory as byte-ptr! cap null-byte size? v4l2_capability
				hr: _ioctl fd VIDIOC_QUERYCAP as int-ptr! :cap
				if all [
					hr = 0
					cap/cap and V4L2_CAP_VIDEO_CAPTURE <> 0
					cap/cap and V4L2_CAP_STREAMING <> 0
					cap/dev-caps and V4L2_CAP_META_CAPTURE = 0
				][
					pcb: as COLLECT-CALLBACK! cb
					pcb node as c-string! :cap/card1
					ret: ret + 1
				]
				_close fd
			]
			udev_device_unref dev
			list: udev_list_entry_get_next list
		]

		udev_enumerate_unref enum
		udev_unref udev
		ret
	]
]
