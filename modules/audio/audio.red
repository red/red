Red [
	Title:	"Audio high-level interface"
	Author: "Xie Qingtian"
	File: 	%audio.red
	Tabs: 	4
	Rights: "Copyright (C) 2015-2021 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

audio-codecs: context [
	#system [

		#enum audio-fields! [
			AUDIO_OBJ_TYPE
			AUDIO_OBJ_RATE
			AUDIO_OBJ_CHANNELS
			AUDIO_OBJ_BITS
			AUDIO_OBJ_SAMPLE_TYPE
			AUDIO_OBJ_DATA
		]

		#include %codecs/pcm-wav.reds
	]

	audio!: object [
		type:		 'audio
		rate:		 44100
		channels:	 1
		bits:		 16
		sample-type: integer!		;-- integer! or float!
		data:		 none			;-- vector!
	]

	decode-wav: routine [
		data	[any-type!]
		obj		[object!]
		/local
			bin [red-binary!]
	][
		switch TYPE_OF(data) [
			TYPE_FILE [bin: as red-binary! simple-io/read as red-file! data null null yes no]
			TYPE_BINARY [bin: as red-binary! data]
			default [exit]
		]

		if TYPE_OF(bin) = TYPE_BINARY [
			pcm-wav/load bin obj
		]
	]
]

put system/codecs 'wav context [
	title: "Waveform Audio"
	name: 'WAV
	mime-type: [audio/wav]
	suffixes: [%.wav]
	
	encode: routine [img [image!] where [any-type!]][]

	decode: function [data][
		obj: make audio-codecs/audio! []
		audio-codecs/decode-wav data obj
		obj
	]
]

audio-scheme: context [

	#system [
		#include %audio.reds

		#define M1FLOAT32 [as float32! 32768.0]
		#define M2FLOAT32 [as float32! 2.147483648E9]

		dev-sample-type: 0
		audio-sample-type: 0
		audio-buffer: as byte-ptr! 0
		audio-buffer-end: as byte-ptr! 0
		opened?: no
		connected?: no

		wave-cb: func [
			dev				[AUDIO-DEVICE!]
			io				[AUDIO-DEVICE-IO!]
			/local
				out			[AUDIO-BUFFER!]
				frame		[integer!]
				count		[integer!]
				sw			[integer!]
				rw			[integer!]
				soff		[integer!]
				roff		[integer!]
				charr		[int-ptr!]
				rch			[int-ptr!]
				rbuf		[byte-ptr!]
				rfp			[pointer! [float32!]]
				rip			[int-ptr!]
				sch			[byte-ptr!]
				sbuf		[byte-ptr!]
				itemp		[integer!]
				ftemp		[float32!]
				bp			[byte-ptr!]
		][
			if null? io/buffer [exit]
			out: io/buffer
			frame: 0
			sw: either audio-sample-type = ASAMPLE-TYPE-I16 [2][4]
			rw: either dev-sample-type = ASAMPLE-TYPE-I16 [2][4]
			charr: as int-ptr! out/channels
			loop out/frames-count [
				count: 0
				soff: frame * out/stride * sw
				roff: frame * out/stride * rw
				loop out/channels-count [
					rch: charr + count
					rbuf: as byte-ptr! rch/1
					rbuf: rbuf + roff
					rfp: as pointer! [float32!] rbuf
					rip: as int-ptr! rbuf
					sch: audio-buffer + (count * sw)
					sbuf: sch + soff
					case [
						dev-sample-type = ASAMPLE-TYPE-F32 [
							case [
								audio-sample-type = ASAMPLE-TYPE-I16 [
									itemp: as integer! sbuf/1
									itemp: (as integer! sbuf/2) << 8 + itemp
									if itemp >= 32768 [
										bp: as byte-ptr! :itemp
										bp/3: #"^(FF)"
										bp/4: #"^(FF)"
									]
									rfp/1: as float32! itemp
									rfp/1: rfp/1 / M1FLOAT32
								]
								audio-sample-type = ASAMPLE-TYPE-I32 [
									itemp: as integer! sbuf/1
									itemp: (as integer! sbuf/2) << 8 + itemp
									itemp: (as integer! sbuf/3) << 16 + itemp
									itemp: (as integer! sbuf/4) << 24 + itemp
									rfp/1: as float32! itemp
									rfp/1: rfp/1 / M2FLOAT32
								]
								audio-sample-type = ASAMPLE-TYPE-F32 [
									ftemp: as float32! 0.0
									bp: as byte-ptr! :ftemp
									bp/1: sbuf/1
									bp/2: sbuf/2
									bp/3: sbuf/3
									bp/4: sbuf/4
									rfp/1: ftemp
								]
							]
						]
						dev-sample-type = ASAMPLE-TYPE-I32 [
							case [
								audio-sample-type = ASAMPLE-TYPE-I16 [
									rbuf/1: #"^(00)"
									rbuf/2: #"^(00)"
									rbuf/3: sbuf/1
									rbuf/4: sbuf/2
								]
								audio-sample-type = ASAMPLE-TYPE-I32 [
									rbuf/1: sbuf/1
									rbuf/2: sbuf/2
									rbuf/3: sbuf/3
									rbuf/4: sbuf/4
								]
								audio-sample-type = ASAMPLE-TYPE-F32 [
									ftemp: as float32! 0.0
									bp: as byte-ptr! :ftemp
									bp/1: sbuf/1
									bp/2: sbuf/2
									bp/3: sbuf/3
									bp/4: sbuf/4
									rip/1: as integer! ftemp
								]
							]
						]
						dev-sample-type = ASAMPLE-TYPE-I16 [
							case [
								audio-sample-type = ASAMPLE-TYPE-I16 [
									rbuf/1: sbuf/1
									rbuf/2: sbuf/2
								]
								audio-sample-type = ASAMPLE-TYPE-I32 [
									rbuf/1: sbuf/3
									rbuf/2: sbuf/4
								]
								audio-sample-type = ASAMPLE-TYPE-F32 [
									ftemp: as float32! 0.0
									bp: as byte-ptr! :ftemp
									bp/1: sbuf/1
									bp/2: sbuf/2
									bp/3: sbuf/3
									bp/4: sbuf/4
									rbuf/1: as byte! ((as integer! ftemp) >> 16)
									rbuf/2: as byte! ((as integer! ftemp) >> 24)
								]
							]
						]
					]
					count: count + 1
				]
				frame: frame + 1
			]
			audio-buffer: audio-buffer + (out/frames-count * out/stride * sw)
			if audio-buffer >= audio-buffer-end [
				audio/device/inner-stop dev
			]
		]
	]

	audio.open: routine [
		state		[block!]
		/local
			dev		[int-ptr!]
			handle	[red-handle!]
	][
		if opened? [
			stack/set-last none-value
			exit
		]
		audio/init
		dev: audio/default-output-device
		#if debug? = yes [audio/device/dump dev]

		handle: as red-handle! block/rs-head state
		handle/header: TYPE_HANDLE
		handle/value: as-integer dev
		opened?: yes
	]

	audio.close: routine [
		handle	[any-type!]
		/local
			h	[red-handle!]
	][
		connected?: no
		opened?: no
		if TYPE_OF(handle) <> TYPE_HANDLE [exit]
		h: as red-handle! handle
		audio/device/free as int-ptr! h/value
		audio/close
	]

	audio.wait: routine [
		handle	[any-type!]
		/local
			h	[red-handle!]
	][
		if TYPE_OF(handle) <> TYPE_HANDLE [exit]
		h: as red-handle! handle
		audio/device/wait as int-ptr! h/value
	]

	audio.play: routine [
		handle		[any-type!]
		bits		[integer!]
		bin			[binary!]
		/local
			h		[red-handle!]
			dev 	[int-ptr!]
			vals	[red-value!]
			stype	[integer!]
			data	[byte-ptr!]
			len		[integer!]
	][
		if TYPE_OF(handle) <> TYPE_HANDLE [exit]
		h: as red-handle! handle
		dev: as int-ptr! h/value

		audio/device/inner-stop dev
		audio/device/wait dev

		;-- setting the device
		case [
			bits = 16 [stype: ASAMPLE-TYPE-I16]
			bits = 32 [stype: ASAMPLE-TYPE-I32]
			true [stype: ASAMPLE-TYPE-F32]
		]
		audio-sample-type: stype
		dev-sample-type: stype
		unless audio/device/set-sample-format dev stype [
			unless audio/device/set-sample-format dev ASAMPLE-TYPE-F32 [
				print-line "no support sample format"
				exit
			]
			dev-sample-type: ASAMPLE-TYPE-F32
			print-line "warning: using float32! sample format"
		]

		;-- send data to the audio port
		audio-buffer: binary/rs-head bin
		audio-buffer-end: binary/rs-tail bin
		unless connected? [
			audio/device/connect dev as int-ptr! :wave-cb
			connected?: yes
		]
		unless audio/device/start dev null null [
			print-line "can't start device"
			exit
		]
	]

	;--- Port actions ---

	open: func [port /local state][
		;-- default-output-dev (handle!), default-input-dev (handle!), other devices
		if block? port/state [exit]
		state: port/state: copy [none none]
		if none? audio.open state [cause-error 'access 'cannot-open ["Port is already opened"]]
		port
	]
	
	insert: func [port data [object!] /local state][
		unless all [block? state: port/state handle? first state][
			cause-error 'access 'not-open ["port/state is invalid"]
		]
		audio.play state/1 data/bits data/data
	]

	close: func [port /local handle][
		unless block? port/state [exit]
		foreach handle port/state [
			audio.close handle
		]
		port/state: none
	]

	wait: func [port /local handle][
		unless block? port/state [exit]
		audio.wait first port/state
	]
]

register-scheme make system/standard/scheme [
	name: 'audio
	title: "Audio Port"
	actor: audio-scheme
]