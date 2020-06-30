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

QBUF-CALLBACK!: alias function! [cfg [integer!]]

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
	]

	#define O_RDWR		2

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
		fd: _open config/name O_RDWR
		if fd = -1 [return -1]
		set-memory as byte-ptr! cap null-byte size? v4l2_capability
		hr: _ioctl fd VIDIOC_QUERYCAP as int-ptr! :cap
		if hr = -1 [
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
		while [-1 <> _ioctl fd VIDIOC_ENUM_FMT as int-ptr! :fdesc][
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
		if hr = -1 [
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
		if hr = -1 [
			free as byte-ptr! fmt
			_close fd
			return -7
		]

		;-- check the v4l2_format result
		hr: _ioctl fd VIDIOC_G_FMT fmt
		if hr = -1 [
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
		if hr = -1 [
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
		if hr = -1 [
			free config/buffer
			_close fd
			return -10
		]
		i: V4L2_BUF_TYPE_VIDEO_CAPTURE
		_ioctl fd VIDIOC_STREAMON :i
		config/running?: no

		config/fd: fd
		0
	]

	close: func [
		config		[v4l2-config!]
	][
		if config/fd <> -1 [
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
			if hr < 0 [
				pthread_mutex_unlock :config/mutex
				return -1
			]
			config/bused: buf/used
			unless null? config/cb [
				pcb: as QBUF-CALLBACK! config/cb
				pcb arg
			]
			pthread_cond_wait :config/cond :config/mutex
			pthread_mutex_unlock :config/mutex
			hr: _ioctl config/fd VIDIOC_QBUF as int-ptr! :buf
			if hr < 0 [
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

	start: func [
		config		[v4l2-config!]
		cb			[int-ptr!]
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
		config/cb: cb
		hr: pthread_create :config/thread null as int-ptr! :thread-cb as int-ptr! config
		if hr <> 0 [return false]
		config/running?: yes
		true
	]

]
