Red/System []

#define MAX_NUM_CHANNELS		16

#define AUDIO-DEVICE! int-ptr!

#enum AUDIO-DEVICE-TYPE! [
	ADEVICE-TYPE-OUTPUT
	ADEVICE-TYPE-INPUT
]

#enum AUDIO-SAMPLE-TYPE! [
	ASAMPLE-TYPE-F32
	ASAMPLE-TYPE-I8
	ASAMPLE-TYPE-I16
	ASAMPLE-TYPE-I24
	ASAMPLE-TYPE-I32
]

#enum AUDIO-DEVICE-EVENT! [
	ADEVICE-LIST-CHANGED
	DEFAULT-INPUT-CHANGED
	DEFAULT-OUTPUT-CHANGED
]

#enum CHANNEL-TYPE! [
	AUDIO-SPEAKER-MONO: 0
	AUDIO-SPEAKER-1POINT1
	AUDIO-SPEAKER-STEREO
	AUDIO-SPEAKER-2POINT1
	AUDIO-SPEAKER-3POINT0
	AUDIO-SPEAKER-3POINT1
	AUDIO-SPEAKER-QUAD
	AUDIO-SPEAKER-SURROUND
	AUDIO-SPEAKER-5POINT0
	AUDIO-SPEAKER-5POINT1
	AUDIO-SPEAKER-7POINT0
	AUDIO-SPEAKER-7POINT1
	AUDIO-SPEAKER-5POINT1-SURROUND
	AUDIO-SPEAKER-7POINT1-SURROUND
	AUDIO-SPEAKER-LAST
]

;-- support 16 channels for now
AUDIO-CHANNELS!: alias struct! [
	ch0				[int-ptr!]
	ch1				[int-ptr!]
	ch2				[int-ptr!]
	ch3				[int-ptr!]
	ch4				[int-ptr!]
	ch5				[int-ptr!]
	ch6				[int-ptr!]
	ch7				[int-ptr!]
	ch8				[int-ptr!]
	ch9				[int-ptr!]
	ch10			[int-ptr!]
	ch11			[int-ptr!]
	ch12			[int-ptr!]
	ch13			[int-ptr!]
	ch14			[int-ptr!]
	ch15			[int-ptr!]
]

AUDIO-BUFFER!: alias struct! [
	contiguous?		[logic!]
	frames-count	[integer!]
	channels-count	[integer!]
	sample-type		[AUDIO-SAMPLE-TYPE!]
	stride			[integer!]
	channels		[AUDIO-CHANNELS! value]
]

AUDIO-CLOCK!: alias struct! [
	t1				[integer!]
	t2				[integer!]
	t3				[integer!]
	t4				[integer!]
]

AUDIO-DEVICE-IO!: alias struct! [
	buffer			[AUDIO-BUFFER! value]
	time			[AUDIO-CLOCK!]
]

AUDIO-IO-CALLBACK!: alias function! [
	dev				[AUDIO-DEVICE!]
	io				[AUDIO-DEVICE-IO!]
]

AUDIO-DEVICE-CALLBACK!: alias function! [dev [AUDIO-DEVICE!]]

AUDIO-CHANGED-CALLBACK!: alias function! []

audio: context [

	#include %utils/type-string.reds

	sample-type-to-str: func [
		type	[AUDIO-SAMPLE-TYPE!]
	][
		case [
			type = ASAMPLE-TYPE-F32 [print "float32! "]
			type = ASAMPLE-TYPE-I32 [print "integer! "]
			type = ASAMPLE-TYPE-I16 [print "int16! "]
			true [print "unknown "]
		]
	]

	#switch OS [
		Windows  [#include %backends/wasapi.reds]
		macOS	 [#include %backends/core-audio.reds]
		Linux	 [#include %backends/alsa.reds]
		;FreeBSD  [#include %backends/pulse-audio.reds]
		#default [#include %backends/null.reds]
	]

	speaker-channels: func [
		type		[CHANNEL-TYPE!]
		return:		[integer!]
	][
		case [
			type = AUDIO-SPEAKER-MONO					[1]
			type = AUDIO-SPEAKER-1POINT1				[2]
			type = AUDIO-SPEAKER-STEREO					[2]
			type = AUDIO-SPEAKER-2POINT1				[3]
			type = AUDIO-SPEAKER-3POINT0				[3]
			type = AUDIO-SPEAKER-3POINT1				[4]
			type = AUDIO-SPEAKER-QUAD					[4]
			type = AUDIO-SPEAKER-SURROUND				[4]
			type = AUDIO-SPEAKER-5POINT0				[5]
			type = AUDIO-SPEAKER-5POINT1				[6]
			type = AUDIO-SPEAKER-7POINT0				[7]
			type = AUDIO-SPEAKER-7POINT1				[8]
			type = AUDIO-SPEAKER-5POINT1-SURROUND		[6]
			type = AUDIO-SPEAKER-7POINT1-SURROUND		[8]
		]
	]

	to-channel-type: func [
		chs			[integer!]
		return:		[CHANNEL-TYPE!]
	][
		case [
			chs = 1 [AUDIO-SPEAKER-MONO]
			chs = 2 [AUDIO-SPEAKER-STEREO]
			chs = 3 [AUDIO-SPEAKER-2POINT1]
			chs = 4 [AUDIO-SPEAKER-QUAD]
			chs = 5 [AUDIO-SPEAKER-5POINT0]
			chs = 6 [AUDIO-SPEAKER-5POINT1-SURROUND]
			chs = 7 [AUDIO-SPEAKER-7POINT0]
			chs = 8 [AUDIO-SPEAKER-7POINT1-SURROUND]
			true [AUDIO-SPEAKER-LAST]
		]
	]

	init: func [return: [logic!]] [
		OS-audio/init
	]

	close: does [
		OS-audio/close
	]

	default-input-device: func [
		return: [audio-device!]
	][
		OS-audio/default-input-device
	]

	default-output-device: func [
		return: [audio-device!]
	][
		OS-audio/default-output-device
	]

	input-devices: func [
		count		[int-ptr!]				;-- number of input devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		OS-audio/input-devices count
	]

	output-devices: func [
		count		[int-ptr!]				;-- number of output devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		OS-audio/output-devices count
	]

	all-devices: func [
		count		[int-ptr!]				;-- number of devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		OS-audio/all-devices count
	]

	free-devices: func [
		devs		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
		count		[integer!]				;-- number of devices
	][
		OS-audio/free-devices devs count
	]

	set-device-changed-callback: func [
		event		[AUDIO-DEVICE-EVENT!]
		cb			[int-ptr!]				;-- audio-changed-callback!
	][
		OS-audio/set-device-changed-callback event cb
	]

	free-device-changed-callback: does [
		OS-audio/free-device-changed-callback
	]

	sleep: func [ms [integer!]][OS-audio/sleep ms]

	device: context [
		id: func [
			dev			[AUDIO-DEVICE!]
			return:		[type-string!]
		][
			OS-audio/id dev
		]

		name: func [
			dev			[AUDIO-DEVICE!]
			return:		[type-string!]
		][
			OS-audio/name dev
		]

		channels: func [
			dev			[AUDIO-DEVICE!]
			count		[int-ptr!]
			return:		[int-ptr!]
		][
			OS-audio/channels dev count
		]

		rates: func [
			dev			[AUDIO-DEVICE!]
			count		[int-ptr!]
			return:		[int-ptr!]
		][
			OS-audio/rates dev count
		]

		sample-formats: func [
			dev			[AUDIO-DEVICE!]
			count		[int-ptr!]
			return:		[int-ptr!]
		][
			OS-audio/sample-formats dev count
		]

		;-- default channels: 2 > 1 > max
		channels-type: func [
			dev			[AUDIO-DEVICE!]
			return:		[CHANNEL-TYPE!]
		][
			OS-audio/channels-type dev
		]

		set-channels-type: func [
			dev			[AUDIO-DEVICE!]
			type		[CHANNEL-TYPE!]
			return:		[logic!]
		][
			OS-audio/set-channels-type dev type
		]

		buffer-size: func [
			dev			[AUDIO-DEVICE!]
			return:		[integer!]
		][
			OS-audio/buffer-size dev
		]

		set-buffer-size: func [
			dev			[AUDIO-DEVICE!]
			size		[integer!]
			return:		[logic!]
		][
			OS-audio/set-buffer-size dev size
		]

		;-- default rate: 44100 > max
		sample-rate: func [
			dev			[AUDIO-DEVICE!]
			return:		[integer!]
		][
			OS-audio/sample-rate dev
		]

		set-sample-rate: func [
			dev			[AUDIO-DEVICE!]
			rate		[integer!]
			return:		[logic!]
		][
			OS-audio/set-sample-rate dev rate
		]

		;-- default format: f32 > i32 > i16
		sample-format: func [
			dev			[AUDIO-DEVICE!]
			return:		[AUDIO-SAMPLE-TYPE!]
		][
			OS-audio/sample-format dev
		]

		set-sample-format: func [
			dev			[AUDIO-DEVICE!]
			type		[AUDIO-SAMPLE-TYPE!]
			return:		[logic!]
		][
			OS-audio/set-sample-format dev type
		]

		input?: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][
			OS-audio/input? dev
		]

		output?: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][
			OS-audio/output? dev
		]

		running?: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][
			OS-audio/running? dev
		]

		;-- future use
		can-connect?: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][true]

		;-- future use
		can-process?: func [
			dev			[AUDIO-DEVICE!]
			return:	[logic!]
		][true]

		has-unprocessed-io?: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][
			OS-audio/has-unprocessed-io? dev
		]

		connect: func [
			dev			[AUDIO-DEVICE!]
			io-cb		[int-ptr!]				;-- audio-io-callback!
			return:		[logic!]
		][
			OS-audio/connect dev io-cb
		]

		start: func [
			dev			[audio-device!]
			start-cb	[int-ptr!]				;-- audio-device-callback!
			stop-cb		[int-ptr!]				;-- audio-device-callback!
			return:		[logic!]
		][
			OS-audio/start dev start-cb stop-cb
		]

		stop: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][
			OS-audio/stop dev
		]

		free: func [
			dev			[AUDIO-DEVICE!]
		][
			OS-audio/free-device dev
		]

		inner-stop: func [
			dev			[AUDIO-DEVICE!]
			return:		[logic!]
		][
			OS-audio/inner-stop dev
			yes
		]

		wait: func [
			dev			[AUDIO-DEVICE!]
		][
			OS-audio/wait dev
		]

		dump: func [
			dev			[AUDIO-DEVICE!]
		][
			OS-audio/dump-device dev
		]
	]
]