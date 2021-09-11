Red/System []

OS-audio: context [

	DEVICE-MONITOR-NOTIFY!: alias struct! [
		list-notify		[int-ptr!]
		input-notify	[int-ptr!]
		output-notify	[int-ptr!]
	]
	DEVICE-MONITOR!: alias struct! [
		enable?		[integer!]
		notifys		[DEVICE-MONITOR-NOTIFY! value]
	]
	dev-monitor: declare DEVICE-MONITOR!

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

	#define kAudioObjectSystemObject					1
	#define kAudioHardwarePropertyDevices				"dev#"
	#define kAudioHardwarePropertyDefaultInputDevice	"dIn "
	#define kAudioHardwarePropertyDefaultOutputDevice	"dOut"
	#define kAudioObjectPropertyScopeGlobal				"glob"
	#define kAudioObjectPropertyElementMaster			0
	#define kAudioDevicePropertyDeviceName				"name"
	#define kAudioObjectPropertyScopeInput				"inpt"
	#define kAudioDevicePropertyScopeInput				kAudioObjectPropertyScopeInput
	#define kAudioObjectPropertyScopeOutput				"outp"
	#define kAudioDevicePropertyScopeOutput				kAudioObjectPropertyScopeOutput
	#define kAudioDevicePropertyStreamConfiguration		"slay"
	#define kAudioDevicePropertyNominalSampleRate		"nsrt"
	#define kAudioDevicePropertyBufferFrameSize			"fsiz"
	#define kAudioDevicePropertyPreferredChannelLayout	"srnd"
	#define kAudioDevicePropertyAvailableNominalSampleRates		"nsr#"

	#define AudioObjectID					integer!
	#define AudioDeviceID					AudioObjectID
	#define AudioObjectPropertySelector		integer!
	#define AudioObjectPropertyScope		integer!
	#define AudioObjectPropertyElement		integer!

	AudioBuffer: alias struct! [
		mNumberChannels		[integer!]
		mDataByteSize		[integer!]
		mData				[byte-ptr!]
	]

	AudioBufferList: alias struct! [
		mNumberBuffers		[integer!]
		mBuffers			[AudioBuffer value]
	]

	AudioChannelDescription: alias struct! [
		mChannelLabel		[integer!]
		mChannelFlags		[integer!]
		mCoordinates1		[float32!]
		mCoordinates2		[float32!]
		mCoordinates3		[float32!]
	]

	AudioChannelLayout: alias struct! [
		mChannelLayoutTag		[integer!]
		mChannelBitmap			[integer!]
		mNumberDesc				[integer!]
		mChannelDescriptions	[AudioChannelDescription value]
	]

	AudioValueRange: alias struct! [
		mMinimum		[float!]
		mMaximum		[float!]
	]

	COREAUDIO-DEVICE!: alias struct! [
		type			[AUDIO-DEVICE-TYPE!]
		id				[AudioObjectID]
		id-str			[type-string!]
		name			[type-string!]				;-- unicode format
		sample-type		[AUDIO-SAMPLE-TYPE!]
		io-cb			[int-ptr!]
		stop-cb			[int-ptr!]
		running?		[logic!]
		stop?			[logic!]
		buffer-size		[integer!]
		channels		[int-ptr!]						;-- support channels list
		channels-count	[integer!]
		rates			[int-ptr!]						;-- support rates list
		rates-count		[integer!]
		formats			[int-ptr!]						;-- support formats list
		formats-count	[integer!]
		channel			[CHANNEL-TYPE!]					;-- default channels
		rate			[integer!]						;-- default rate
		format			[AUDIO-SAMPLE-TYPE!]			;-- default format
		proc-id			[integer!]
	]

	AudioObjectPropertyAddress: alias struct! [
		mSelector			[AudioObjectPropertySelector]
		mScope				[AudioObjectPropertyScope]
		mElement			[AudioObjectPropertyElement]
	]

	rates-filters: [
		5512
		8000
		11025
		16000
		22050
		32000
		44100
		48000
		64000
		88200
		96000
		176400
		192000
	]

	#import [
		"/System/Library/Frameworks/CoreAudio.framework/CoreAudio" cdecl [
			AudioObjectGetPropertyDataSize: "AudioObjectGetPropertyDataSize" [
				inObjectID				[AudioObjectID]
				inAddress				[AudioObjectPropertyAddress]
				inQualifierDataSize		[integer!]
				inQualifierData			[int-ptr!]
				outData					[int-ptr!]
				return:					[integer!]
			]
			AudioObjectGetPropertyData: "AudioObjectGetPropertyData" [
				inObjectID				[AudioObjectID]
				inAddress				[AudioObjectPropertyAddress]
				inQualifierDataSize		[integer!]
				inQualifierData			[int-ptr!]
				ioDataSize				[int-ptr!]
				outData					[int-ptr!]
				return:					[integer!]
			]
			AudioObjectSetPropertyData: "AudioObjectSetPropertyData" [
				inObjectID				[AudioObjectID]
				inAddress				[AudioObjectPropertyAddress]
				inQualifierDataSize		[integer!]
				inQualifierData			[int-ptr!]
				ioDataSize				[integer!]
				inData					[int-ptr!]
				return:					[integer!]
			]
			AudioDeviceCreateIOProcID: "AudioDeviceCreateIOProcID" [
				inDevice				[AudioObjectID]
				inProc					[int-ptr!]
				inClientData			[int-ptr!]
				outIOProcID				[int-ptr!]
				return:					[integer!]
			]
			AudioDeviceStart: "AudioDeviceStart" [
				inDevice				[AudioObjectID]
				inProcID				[int-ptr!]
				return:					[integer!]
			]
			AudioDeviceDestroyIOProcID: "AudioDeviceDestroyIOProcID" [
				inDevice				[AudioObjectID]
				inProcID				[integer!]
				return:					[integer!]
			]
			AudioDeviceStop: "AudioDeviceStop" [
				inDevice				[AudioObjectID]
				inProcID				[int-ptr!]
				return:					[integer!]
			]
			AudioObjectAddPropertyListener: "AudioObjectAddPropertyListener" [
				inObjectID				[AudioObjectID]
				inAddress				[AudioObjectPropertyAddress]
				inListener				[int-ptr!]
				inClientData			[int-ptr!]
				return:					[integer!]
			]
			AudioObjectRemovePropertyListener: "AudioObjectRemovePropertyListener" [
				inObjectID				[AudioObjectID]
				inAddress				[AudioObjectPropertyAddress]
				inListener				[int-ptr!]
				inClientData			[int-ptr!]
				return:					[integer!]
			]
		]
	]

	cf-enum: func [
		str			[c-string!]
		return:		[integer!]
		/local
			ret		[integer!]
			pb		[byte-ptr!]
	][
		ret: 0
		pb: as byte-ptr! :ret
		pb/1: str/4
		pb/2: str/3
		pb/3: str/2
		pb/4: str/1
		ret
	]

	init: func [return: [logic!]] [
		set-memory as byte-ptr! dev-monitor #"^(00)" size? DEVICE-MONITOR!
		true
	]

	close: does [
		0
	]

	get-device-name: func [
		id			[AudioDeviceID]
		return:		[type-string!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			dsize	[integer!]
			buff	[byte-ptr!]
			ustr	[type-string!]
	][
		addr/mSelector: cf-enum kAudioDevicePropertyDeviceName
		addr/mScope: cf-enum kAudioObjectPropertyScopeGlobal
		addr/mElement: kAudioObjectPropertyElementMaster
		dsize: 0
		hr: AudioObjectGetPropertyDataSize id addr 0 null :dsize
		if hr <> 0 [return null]
		buff: allocate dsize
		hr: AudioObjectGetPropertyData id addr 0 null :dsize as int-ptr! buff
		if hr <> 0 [free buff return null]
		ustr: type-string/load-utf8 buff
		free buff
		ustr
	]

	get-buffer-list: func [
		id			[AudioDeviceID]
		type		[AUDIO-DEVICE-TYPE!]
		buff-list	[AudioBufferList]
		return:		[logic!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			dsize	[integer!]
	][
		addr/mSelector: cf-enum kAudioDevicePropertyStreamConfiguration
		addr/mScope: cf-enum either type = ADEVICE-TYPE-OUTPUT [
			kAudioDevicePropertyScopeOutput
		][
			kAudioDevicePropertyScopeInput
		]
		addr/mElement: kAudioObjectPropertyElementMaster
		dsize: 0
		hr: AudioObjectGetPropertyDataSize id addr 0 null :dsize
		if hr <> 0 [return false]
		if dsize <> size? AudioBufferList [return false]
		hr: AudioObjectGetPropertyData id addr 0 null :dsize as int-ptr! buff-list
		if hr <> 0 [return false]
		true
	]

	core-get-rate: func [
		id			[integer!]
		type		[AUDIO-DEVICE-TYPE!]
		rate		[int-ptr!]
		return:		[logic!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			dsize	[integer!]
	][
		addr/mSelector: cf-enum kAudioDevicePropertyNominalSampleRate
		addr/mScope: cf-enum either type = ADEVICE-TYPE-OUTPUT [
			kAudioDevicePropertyScopeOutput
		][
			kAudioDevicePropertyScopeInput
		]
		addr/mElement: kAudioObjectPropertyElementMaster
		dsize: 0
		hr: AudioObjectGetPropertyDataSize id addr 0 null :dsize
		if hr <> 0 [return false]
		if dsize <> 4 [return false]
		hr: AudioObjectGetPropertyData id addr 0 null :dsize rate
		if hr <> 0 [return false]
		true
	]

	core-set-rate: func [
		id			[integer!]
		type		[AUDIO-DEVICE-TYPE!]
		rate		[integer!]
		return:		[logic!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			frate	[float!]
	][
		addr/mSelector: cf-enum kAudioDevicePropertyNominalSampleRate
		addr/mScope: cf-enum either type = ADEVICE-TYPE-OUTPUT [
			kAudioDevicePropertyScopeOutput
		][
			kAudioDevicePropertyScopeInput
		]
		addr/mElement: kAudioObjectPropertyElementMaster
		frate: as float! rate
		hr: AudioObjectSetPropertyData id addr 0 null size? float! as int-ptr! :frate
		if hr <> 0 [return false]
		true
	]

	core-get-buffer-size: func [
		id			[integer!]
		type		[AUDIO-DEVICE-TYPE!]
		buffer-size	[int-ptr!]
		return:		[logic!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			dsize	[integer!]
	][
		addr/mSelector: cf-enum kAudioDevicePropertyBufferFrameSize
		addr/mScope: cf-enum either type = ADEVICE-TYPE-OUTPUT [
			kAudioDevicePropertyScopeOutput
		][
			kAudioDevicePropertyScopeInput
		]
		addr/mElement: kAudioObjectPropertyElementMaster
		dsize: 0
		hr: AudioObjectGetPropertyDataSize id addr 0 null :dsize
		if hr <> 0 [return false]
		if dsize <> 4 [return false]
		hr: AudioObjectGetPropertyData id addr 0 null :dsize buffer-size
		if hr <> 0 [return false]
		true
	]

	core-set-buffer-size: func [
		id			[integer!]
		type		[AUDIO-DEVICE-TYPE!]
		buffer-size	[integer!]
		return:		[logic!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			frames	[integer!]
	][
		addr/mSelector: cf-enum kAudioDevicePropertyBufferFrameSize
		addr/mScope: cf-enum either type = ADEVICE-TYPE-OUTPUT [
			kAudioDevicePropertyScopeOutput
		][
			kAudioDevicePropertyScopeInput
		]
		addr/mElement: kAudioObjectPropertyElementMaster
		frames: buffer-size
		hr: AudioObjectSetPropertyData id addr 0 null size? integer! :frames
		if hr <> 0 [return false]
		true
	]

	init-device: func [
		cdev		[COREAUDIO-DEVICE!]
		id			[AudioDeviceID]
		type		[integer!]
		chs			[integer!]					;-- TBD: only support default channels for now
		return:		[logic!]
		/local
			buff	[byte-ptr!]
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			dsize	[integer!]
			num		[integer!]
			rbuff	[byte-ptr!]
			ranges	[AudioValueRange]
			rates	[int-ptr!]
			count	[integer!]
			n		[integer!]
			filters	[int-ptr!]
			f		[float!]
	][
		set-memory as byte-ptr! cdev #"^(00)" size? COREAUDIO-DEVICE!
		cdev/running?: no
		cdev/format: -1
		cdev/channel: AUDIO-SPEAKER-LAST
		cdev/rate: 0
		buff: as byte-ptr! system/stack/allocate 4
		sprintf [buff "%04X" id]
		cdev/id: id
		cdev/id-str: type-string/load-utf8 buff
		cdev/type: type
		cdev/name: get-device-name id
		;-- get formats
		cdev/formats: as int-ptr! allocate 2 * 4
		cdev/formats/1: ASAMPLE-TYPE-F32
		cdev/formats/1: 0
		cdev/formats-count: 1
		cdev/format: ASAMPLE-TYPE-F32
		;-- get channels
		cdev/channel: to-channel-type chs
		cdev/channels: as int-ptr! allocate 2 * 4
		cdev/channels/1: cdev/channel
		cdev/channels/2: 0
		cdev/channels-count: 1
		;-- get rates
		addr/mSelector: cf-enum kAudioDevicePropertyAvailableNominalSampleRates
		addr/mScope: cf-enum kAudioObjectPropertyScopeGlobal
		addr/mElement: kAudioObjectPropertyElementMaster
		dsize: 0
		hr: AudioObjectGetPropertyDataSize id addr 0 null :dsize
		if hr <> 0 [return false]
		rbuff: allocate dsize
		hr: AudioObjectGetPropertyData id addr 0 null :dsize as int-ptr! rbuff
		if hr <> 0 [return false]
		num: dsize / size? AudioValueRange
		n: size? rates-filters
		rates: as int-ptr! allocate n + 1 * 4
		set-memory as byte-ptr! rates #"^(00)" n + 1 * 4
		cdev/rates: rates
		count: 0
		filters: rates-filters
		loop n [
			ranges: as AudioValueRange rbuff
			loop num [
				f: as float! filters/1
				if all [
					f >= ranges/mMinimum
					f <= ranges/mMaximum
				][
					rates/1: filters/1
					rates: rates + 1
					count: count + 1
					if cdev/rate <> 44100 [
						cdev/rate: filters/1
					]
				]
				ranges: ranges + 1
			]
			filters: filters + 1
		]
		free rbuff
		if count = 0 [
			free as byte-ptr! cdev/rates
			cdev/rates: null
			return false
		]
		cdev/rates-count: count
		;-- get frames
		unless core-get-buffer-size id type :cdev/buffer-size [return false]
		;-- use select rate
		unless core-set-rate id type cdev/rate [return false]
		true
	]

	dump-device: func [
		dev			[AUDIO-DEVICE!]
		/local
			cdev	[COREAUDIO-DEVICE!]
			p		[int-ptr!]
	][
		if null? dev [print-line "null device!" exit]
		cdev: as COREAUDIO-DEVICE! dev
		print-line "================================"
		print-line ["dev: " dev]
		either cdev/type = ADEVICE-TYPE-OUTPUT [
			print-line "    type: speaker"
		][
			print-line "    type: microphone"
		]
		print-line ["    id: " cdev/id]
		print "    name: "
		type-string/uprint cdev/name
		print "^/    formats: "
		either null? cdev/formats [
			print "none"
		][
			p: cdev/formats
			loop cdev/formats-count [
				sample-type-to-str p/1
				p: p + 1
			]
		]
		print "^/    channels: "
		either null? cdev/channels [
			print "none"
		][
			p: cdev/channels
			loop cdev/channels-count [
				print [p/1 " "]
				p: p + 1
			]
		]
		print "^/    rates: "
		either null? cdev/rates [
			print "none"
		][
			p: cdev/rates
			loop cdev/rates-count [
				print [p/1 " "]
				p: p + 1
			]
		]
		print ["^/    format: "]
		sample-type-to-str cdev/format

		print-line ["    default channels: " cdev/channel]
		print-line ["    default rate: " cdev/rate]
		print-line ["    default format: " cdev/format]
		print-line ["    buffer frames: " cdev/buffer-size]
		print-line "================================"
	]

	default-device: func [
		type		[AUDIO-DEVICE-TYPE!]
		return:		[AUDIO-DEVICE!]
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			id		[AudioDeviceID]
			dsize	[integer!]
			blist	[AudioBufferList value]
			cdev	[COREAUDIO-DEVICE!]
	][
		addr/mSelector: cf-enum either type = ADEVICE-TYPE-OUTPUT [
			kAudioHardwarePropertyDefaultOutputDevice
		][
			kAudioHardwarePropertyDefaultInputDevice
		]
		addr/mScope: cf-enum kAudioObjectPropertyScopeGlobal
		addr/mElement: kAudioObjectPropertyElementMaster
		id: 0
		dsize: size? AudioDeviceID
		hr: AudioObjectGetPropertyData kAudioObjectSystemObject addr 0 null :dsize :id
		if hr <> 0 [return null]
		unless get-buffer-list id type blist [return null]
		unless blist/mNumberBuffers >= 1 [return null]
		cdev: as COREAUDIO-DEVICE! allocate size? COREAUDIO-DEVICE!
		init-device cdev id type blist/mBuffers/mNumberChannels
		as AUDIO-DEVICE! cdev
	]

	default-input-device: func [
		return: [AUDIO-DEVICE!]
	][
		default-device ADEVICE-TYPE-INPUT
	]

	default-output-device: func [
		return: [AUDIO-DEVICE!]
	][
		default-device ADEVICE-TYPE-OUTPUT
	]

	get-devices: func [
		type		[AUDIO-DEVICE-TYPE!]
		count		[int-ptr!]			;-- number of input devices
		return:		[AUDIO-DEVICE!]		;-- an array of AUDIO-DEVICE!
		/local
			addr	[AudioObjectPropertyAddress value]
			hr		[integer!]
			dsize	[integer!]
			c		[integer!]
			ids		[int-ptr!]
			ids2	[int-ptr!]
			list	[int-ptr!]
			itor	[int-ptr!]
			num		[integer!]
			blist	[AudioBufferList value]
			cdev	[COREAUDIO-DEVICE!]
	][
		count/1: 0
		addr/mSelector: cf-enum kAudioHardwarePropertyDevices
		addr/mScope: cf-enum either type = ADEVICE-TYPE-OUTPUT [kAudioObjectPropertyScopeOutput][kAudioObjectPropertyScopeInput]
		addr/mElement: kAudioObjectPropertyElementMaster
		dsize: 0
		hr: AudioObjectGetPropertyDataSize kAudioObjectSystemObject addr 0 null :dsize
		if hr <> 0 [return null]
		c: dsize / size? AudioDeviceID
		if c = 0 [return null]
		ids: as int-ptr! allocate dsize
		ids2: ids
		hr: AudioObjectGetPropertyData kAudioObjectSystemObject addr 0 null :dsize ids
		if hr <> 0 [free as byte-ptr! ids return null]
		list: as int-ptr! allocate c + 1 * 4
		set-memory as byte-ptr! list #"^@" c + 1 * 4
		itor: list
		num: 0
		loop c [
			if all [
				get-buffer-list ids2/1 type blist
				blist/mNumberBuffers >= 1
			][
				cdev: as COREAUDIO-DEVICE! allocate size? COREAUDIO-DEVICE!
				init-device cdev ids2/1 type blist/mBuffers/mNumberChannels
				itor/1: as integer! cdev
				itor: itor + 1
				num: num + 1
			]
			ids2: ids2 + 1
		]
		count/1: num
		free as byte-ptr! ids
		list
	]

	input-devices: func [
		count		[int-ptr!]				;-- number of input devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		get-devices ADEVICE-TYPE-INPUT count
	]

	output-devices: func [
		count		[int-ptr!]				;-- number of output devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
	][
		get-devices ADEVICE-TYPE-OUTPUT count
	]

	all-devices: func [
		count		[int-ptr!]				;-- number of devices
		return:		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
		/local
			count1	[integer!]
			list1	[int-ptr!]
			count2	[integer!]
			list2	[int-ptr!]
			total	[integer!]
			list	[int-ptr!]
			end		[int-ptr!]
	][
		count/1: 0
		count1: 0
		list1: output-devices :count1
		if null? list1 [count1: 0]
		count2: 0
		list2: input-devices :count2
		if null? list2 [count2: 0]
		if all [count1 = 0 count2 = 0][return null]
		total: count1 + count2
		list: as int-ptr! allocate total + 1 * 4
		end: list + count/1
		end/1: 0
		if count1 <> 0 [
			copy-memory as byte-ptr! list as byte-ptr! list1 count1 * 4
			free as byte-ptr! list1
		]
		if count2 <> 0 [
			copy-memory as byte-ptr! list + count1 as byte-ptr! list2 count2 * 4
			free as byte-ptr! list2
		]
		count/1: total
		list
	]

	free-device: func [
		dev			[AUDIO-DEVICE!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		if null? dev [exit]
		stop dev
		cdev: as COREAUDIO-DEVICE! dev
		type-string/release cdev/id-str
		type-string/release cdev/name
		unless null? cdev/channels [
			free as byte-ptr! cdev/channels
		]
		unless null? cdev/rates [
			free as byte-ptr! cdev/rates
		]
		unless null? cdev/formats [
			free as byte-ptr! cdev/formats
		]
		free as byte-ptr! cdev
	]

	free-devices: func [
		devs		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
		count		[integer!]				;-- number of devices
		/local
			p		[byte-ptr!]
			cdev	[COREAUDIO-DEVICE!]
	][
		if null? devs [exit]
		p: as byte-ptr! devs
		loop count [
			cdev: as COREAUDIO-DEVICE! devs/1
			free-device as AUDIO-DEVICE! devs/1
			devs: devs + 1
		]
		free p
	]

	name: func [
		dev			[AUDIO-DEVICE!]
		return:		[type-string!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/name
	]

	id: func [
		dev			[AUDIO-DEVICE!]
		return:		[type-string!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/id-str
	]

	channels: func [
		dev			[AUDIO-DEVICE!]
		count		[int-ptr!]
		return:		[int-ptr!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if null? cdev/channels [return null]
		count/1: cdev/channels-count
		cdev/channels
	]

	rates: func [
		dev			[AUDIO-DEVICE!]
		count		[int-ptr!]
		return:		[int-ptr!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if null? cdev/rates [return null]
		count/1: cdev/rates-count
		cdev/rates
	]

	sample-formats: func [
		dev			[AUDIO-DEVICE!]
		count		[int-ptr!]
		return:		[int-ptr!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if null? cdev/formats [return null]
		count/1: cdev/formats-count
		cdev/formats
	]

	channels-type: func [
		dev			[AUDIO-DEVICE!]
		return:		[CHANNEL-TYPE!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/channel
	]

	set-channels-type: func [
		dev			[AUDIO-DEVICE!]
		type		[CHANNEL-TYPE!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
			chs		[integer!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if cdev/running? [return false]
		if cdev/channel <> AUDIO-SPEAKER-STEREO [return false]
		true
	]

	buffer-size: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/buffer-size
	]

	set-buffer-size: func [
		dev			[AUDIO-DEVICE!]
		count		[integer!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/buffer-size: count
		core-set-buffer-size cdev/id cdev/type count
	]

	sample-rate: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/rate
	]

	set-sample-rate: func [
		dev			[AUDIO-DEVICE!]
		rate		[integer!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/rate: rate
		core-set-rate cdev/id cdev/type rate
	]

	sample-format: func [
		dev			[AUDIO-DEVICE!]
		return:		[AUDIO-SAMPLE-TYPE!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/format
	]

	set-sample-format: func [
		dev			[AUDIO-DEVICE!]
		type		[AUDIO-SAMPLE-TYPE!]
		return:		[logic!]
	][
		if type = ASAMPLE-TYPE-F32 [return true]		;-- always float! for macOS
		false
	]

	input?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/type = ADEVICE-TYPE-INPUT
	]

	output?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/type = ADEVICE-TYPE-OUTPUT
	]

	running?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/running?
	]

	has-unprocessed-io?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
	][
		no
	]

	connect: func [
		dev			[AUDIO-DEVICE!]
		io-cb		[int-ptr!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if cdev/running? [return false]
		cdev/io-cb: io-cb
		true
	]

	_device-callback: func [
		[cdecl]
		id			[AudioObjectID]
		now			[int-ptr!]
		input_data	[AudioBufferList]
		input_time	[int-ptr!]
		output_data	[AudioBufferList]
		output_time	[int-ptr!]
		ptr-to-this	[int-ptr!]
		return:		[integer!]
		/local
			cdev		[COREAUDIO-DEVICE!]
			abuff		[AUDIO-DEVICE-IO! value]
			pcb			[AUDIO-IO-CALLBACK!]
			ch-count	[integer!]
			bytes		[integer!]
			size		[integer!]
			chs			[int-ptr!]
			step		[integer!]
	][
		if null? ptr-to-this [return -1]
		cdev: as COREAUDIO-DEVICE! ptr-to-this
		if cdev/stop? [
			stop ptr-to-this
			return 0
		]
		if cdev/type = ADEVICE-TYPE-OUTPUT [
			set-memory as byte-ptr! abuff #"^(00)" size? AUDIO-DEVICE-IO!
			if output_data/mNumberBuffers <> 1 [return 1]
			abuff/buffer/sample-type: cdev/format
			ch-count: output_data/mBuffers/mNumberChannels
			bytes: output_data/mBuffers/mDataByteSize
			size: either cdev/format = ASAMPLE-TYPE-I16 [2][4]
			abuff/buffer/channels-count: ch-count
			abuff/buffer/frames-count: bytes / size / ch-count
			abuff/buffer/stride: ch-count
			abuff/buffer/contiguous?: yes
			chs: as int-ptr! abuff/buffer/channels
			step: as integer! output_data/mBuffers/mData
			loop ch-count [
				chs/1: step
				chs: chs + 1
				step: step + size
			]
			pcb: as AUDIO-IO-CALLBACK! cdev/io-cb
			pcb ptr-to-this abuff
			return 0
		]
		if cdev/type = ADEVICE-TYPE-INPUT [
			set-memory as byte-ptr! abuff #"^(00)" size? AUDIO-DEVICE-IO!
			if input_data/mNumberBuffers <> 1 [return 1]
			abuff/buffer/sample-type: cdev/format
			ch-count: input_data/mBuffers/mNumberChannels
			bytes: input_data/mBuffers/mDataByteSize
			size: either cdev/format = ASAMPLE-TYPE-I16 [2][4]
			abuff/buffer/channels-count: ch-count
			abuff/buffer/frames-count: bytes / size / ch-count
			abuff/buffer/stride: ch-count
			abuff/buffer/contiguous?: yes
			chs: as int-ptr! abuff/buffer/channels
			step: as integer! input_data/mBuffers/mData
			loop ch-count [
				chs/1: step
				chs: chs + 1
				step: step + size
			]
			pcb: as AUDIO-IO-CALLBACK! cdev/io-cb
			pcb ptr-to-this abuff
			return 0
		]
		0
	]

	start: func [
		dev			[audio-device!]
		start-cb	[int-ptr!]				;-- audio-device-callback!
		stop-cb		[int-ptr!]				;-- audio-device-callback!
		return:		[logic!]
		/local
			cdev		[COREAUDIO-DEVICE!]
			hr			[integer!]
			start_cb	[AUDIO-DEVICE-CALLBACK!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if cdev/running? [return true]
		unless null? cdev/io-cb [
			hr: AudioDeviceCreateIOProcID cdev/id as int-ptr! :_device-callback dev :cdev/proc-id
			if hr <> 0 [
				return false
			]
			hr: AudioDeviceStart cdev/id as int-ptr! :_device-callback
			if hr <> 0 [
				AudioDeviceDestroyIOProcID cdev/id cdev/proc-id
				cdev/proc-id: 0
				return false
			]
		]
		cdev/running?: yes
		cdev/stop?: no

		unless null? start-cb [
			start_cb: as AUDIO-DEVICE-CALLBACK! start-cb
			start_cb dev
		]
		cdev/stop-cb: stop-cb
		true
	]

	stop: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			cdev	[COREAUDIO-DEVICE!]
			hr		[integer!]
			stop_cb	[AUDIO-DEVICE-CALLBACK!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		if cdev/running? [
			hr: AudioDeviceStop cdev/id as int-ptr! :_device-callback
			if hr <> 0 [return false]
			hr: AudioDeviceDestroyIOProcID cdev/id cdev/proc-id
			if hr <> 0 [return false]
			unless null? cdev/stop-cb [
				stop_cb: as AUDIO-DEVICE-CALLBACK! cdev/stop-cb
				stop_cb dev
			]
			cdev/proc-id: 0
			cdev/running?: no
		]
		true
	]

	inner-stop: func [
		dev			[AUDIO-DEVICE!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		cdev/stop?: yes
	]

	wait: func [
		dev			[AUDIO-DEVICE!]
		/local
			cdev	[COREAUDIO-DEVICE!]
	][
		cdev: as COREAUDIO-DEVICE! dev
		while [cdev/running?][						;-- simulate `wait event`
			usleep 10000
		]
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
		if dev-monitor/enable? = 0 [
			dev-monitor/enable?: 1
		]
	]

	free-monitor: func [
	][
		set-memory as byte-ptr! dev-monitor #"^(00)" size? DEVICE-MONITOR!
	]

	monitor-cb: func [
		[cdecl]
		id				[AudioObjectID]
		NumAddr			[integer!]
		addr			[AudioObjectPropertyAddress]
		ptr-to-this		[int-ptr!]
		return:			[integer!]
		/local
			notifys		[int-ptr!]
			d-cb		[AUDIO-CHANGED-CALLBACK!]
	][
		notifys: as int-ptr! dev-monitor/notifys
		case [
			addr/mSelector = cf-enum kAudioHardwarePropertyDevices [
				d-cb: as AUDIO-CHANGED-CALLBACK! notifys/1
			]
			addr/mSelector = cf-enum kAudioHardwarePropertyDefaultInputDevice [
				d-cb: as AUDIO-CHANGED-CALLBACK! notifys/2
			]
			addr/mSelector = cf-enum kAudioHardwarePropertyDefaultOutputDevice [
				d-cb: as AUDIO-CHANGED-CALLBACK! notifys/3
			]
			true [
				return 0
			]
		]
		d-cb
		0
	]

	set-device-changed-callback: func [
		event			[AUDIO-DEVICE-EVENT!]
		cb				[int-ptr!]				;-- audio-changed-callback!
		/local
			addr		[AudioObjectPropertyAddress value]
			hr			[integer!]
			notifys		[int-ptr!]
	][
		init-monitor
		addr/mSelector: cf-enum case [
			event = ADEVICE-LIST-CHANGED [
				kAudioHardwarePropertyDevices
			]
			event = DEFAULT-INPUT-CHANGED [
				kAudioHardwarePropertyDefaultInputDevice
			]
			event = DEFAULT-OUTPUT-CHANGED [
				kAudioHardwarePropertyDefaultOutputDevice
			]
		]
		addr/mScope: cf-enum kAudioObjectPropertyScopeGlobal
		addr/mElement: kAudioObjectPropertyElementMaster
		hr: AudioObjectAddPropertyListener kAudioObjectSystemObject addr as int-ptr! :monitor-cb as int-ptr! dev-monitor
		notifys: as int-ptr! dev-monitor/notifys
		notifys: notifys + event
		if notifys/1 <> 0 [
			hr: AudioObjectRemovePropertyListener kAudioObjectSystemObject addr as int-ptr! :monitor-cb as int-ptr! dev-monitor
		]
		notifys/1: as integer! cb
	]

	free-device-changed-callback: func [
		/local
			notifys		[int-ptr!]
			i			[integer!]
			addr		[AudioObjectPropertyAddress value]
			hr			[integer!]
	][
		notifys: as int-ptr! dev-monitor/notifys
		i: 0
		loop 3 [
			if notifys/1 <> 0 [
				addr/mSelector: cf-enum case [
					i = 0 [
						kAudioHardwarePropertyDevices
					]
					i = 1 [
						kAudioHardwarePropertyDefaultInputDevice
					]
					i = 2 [
						kAudioHardwarePropertyDefaultOutputDevice
					]
				]
				i: i + 1
				addr/mScope: cf-enum kAudioObjectPropertyScopeGlobal
				addr/mElement: kAudioObjectPropertyElementMaster
				hr: AudioObjectRemovePropertyListener kAudioObjectSystemObject addr as int-ptr! :monitor-cb as int-ptr! dev-monitor
			]
			notifys: notifys + 1
		]
		free-monitor
	]
]

