Red/System []

OS-audio: context [

	dev-monitor: declare integer!

	#import [
		LIBC-file cdecl [
			usleep: "usleep" [
				us			[integer!]
				return:		[integer!]
			]
			sec.sleep: "sleep" [
				s			[integer!]
				return:		[integer!]
			]
		]
	]

	init: func [return: [logic!]] [
		dev-monitor: 0
		true
	]

	close: does [
		0
	]

	dump-device: func [
		dev			[AUDIO-DEVICE!]
	][
		0
	]

	default-input-device: func [
		return: [AUDIO-DEVICE!]
	][
		null
	]

	default-output-device: func [
		return: [AUDIO-DEVICE!]
	][
		null
	]

	input-devices: func [
		count		[int-ptr!]				;-- number of input devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		null
	]

	output-devices: func [
		count		[int-ptr!]				;-- number of output devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		null
	]

	all-devices: func [
		count		[int-ptr!]				;-- number of devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		null
	]

	free-device: func [
		dev			[AUDIO-DEVICE!]
	][
		0
	]

	free-devices: func [
		devs		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
		count		[integer!]				;-- number of devices
	][
		0
	]

	name: func [
		dev			[AUDIO-DEVICE!]
		return:		[type-string!]
	][
		null
	]

	id: func [
		dev			[AUDIO-DEVICE!]
		return:		[int-ptr!]
	][
		null
	]

	channels-count: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
	][
		0
	]

	buffer-size: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
	][
		0
	]

	set-buffer-size: func [
		dev			[AUDIO-DEVICE!]
		count		[integer!]
		return:		[logic!]
	][
		true
	]

	sample-rate: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
	][
		0
	]

	set-sample-rate: func [
		dev			[AUDIO-DEVICE!]
		rate		[integer!]
		return:		[logic!]
	][
		true
	]

	input?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
	][
		false
	]

	output?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
	][
		false
	]

	running?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
	][
		no
	]

	has-unprocessed-io?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
	][
		no
	]

	connect: func [
		dev			[AUDIO-DEVICE!]
		stype		[AUDIO-SAMPLE-TYPE!]
		io-cb		[int-ptr!]
		return:		[logic!]
	][
		true
	]

	start: func [
		dev			[audio-device!]
		start-cb	[int-ptr!]				;-- audio-device-callback!
		stop-cb		[int-ptr!]				;-- audio-device-callback!
		return:		[logic!]
	][
		yes
	]

	stop: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
	][
		true
	]

	wait: func [
		dev			[AUDIO-DEVICE!]
	][
		0
	]

	sleep: func [
		ms			[integer!]
		/local
			s		[integer!]
			r		[integer!]
	][
		s: ms / 1000
		if s <> 0 [
			sec.sleep s
		]
		r: ms - (s * 1000)
		if r <> 0 [
			r: r * 1000
			usleep r
		]
	]

	init-monitor: func [
	][
		0
	]

	free-monitor: func [
	][
		0
	]

	set-device-changed-callback: func [
		event			[AUDIO-DEVICE-EVENT!]
		cb				[int-ptr!]				;-- audio-changed-callback!
	][
		0
	]

	free-device-changed-callback: func [
	][
		0
		free-monitor
	]
]

