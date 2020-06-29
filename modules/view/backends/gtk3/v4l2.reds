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

v4l2: context [
	#define QUEUE_NUM		4

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

	frame-buffer!: alias struct! [
		start		[byte-ptr!]
		length		[integer!]
	]

	v4l2-config!: alias struct! [
		name		[c-string!]
		fd			[integer!]
		format		[integer!]
		width		[integer!]
		height		[integer!]
		imgsize		[integer!]
		buffers		[frame-buffer!]
		bufcount	[integer!]
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
			fbuf	[frame-buffer!]
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

		;-- use mmap buffers
		set-memory as byte-ptr! rbuf null-byte size? v4l2_requestbuffers
		rbuf/count: QUEUE_NUM
		rbuf/type: V4L2_BUF_TYPE_VIDEO_CAPTURE
		rbuf/memory: V4L2_MEMORY_MMAP
		hr: _ioctl fd VIDIOC_REQBUFS as int-ptr! :rbuf
		if hr = -1 [
			_close fd
			return -9
		]

		config/bufcount: rbuf/count
		fbuf: as frame-buffer! allocate rbuf/count * size? frame-buffer!
		config/buffers: fbuf
		i: 0
		loop rbuf/count [
			buf/type: V4L2_BUF_TYPE_VIDEO_CAPTURE
			buf/memory: V4L2_MEMORY_MMAP
			buf/index: i
			hr: _ioctl fd VIDIOC_QUERYBUF as int-ptr! :buf
			if hr = -1 [
				_close fd
				return -10
			]
			fbuf/length: buf/length
			fbuf/start: _mmap null buf/length 3 1 fd buf/m
			fbuf: fbuf + 1
			i: i + 1
		]

		;-- add buffers to queue
		fbuf: config/buffers
		i: 0
		loop rbuf/count [
			buf/index: i
			_ioctl fd VIDIOC_QBUF as int-ptr! :buf
			i: i + 1
		]

		;-- open stream
		i: V4L2_BUF_TYPE_VIDEO_CAPTURE
		_ioctl fd VIDIOC_STREAMON :i

		config/fd: fd
		0
	]

	close: func [
		config		[v4l2-config!]
		/local
			fbuf	[frame-buffer!]
	][
		if config/fd <> -1 [
			fbuf: config/buffers
			loop config/bufcount [
				if fbuf/start <> as byte-ptr! -1 [
					_munmap fbuf/start fbuf/length
				]
				fbuf: fbuf + 1
			]
			free as byte-ptr! config/buffers
			_close config/fd
			config/fd: -1
		]
	]

]
