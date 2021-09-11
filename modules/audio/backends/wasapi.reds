Red/System []

#if dev-mode? = yes [
	#include %../../../runtime/platform/COM.reds
]

#import [
	"ole32.dll" stdcall [
		CoTaskMemFree: "CoTaskMemFree" [
			pv		[integer!]
		]
		PropVariantClear: "PropVariantClear" [
			pvar	[int-ptr!]
			return:	[integer!]
		]
	]
]

OS-audio: context [
	;-- BCDE0395-E52F-467C-8E3D-C4579291692E
	CLSID_MMDeviceEnumerator: [BCDE0395h 467CE52Fh 57C43D8Eh 2E699192h]
	;-- A95664D2-9614-4F35-A746-DE8DB63617E6
	IID_IMMDeviceEnumerator: [A95664D2h 4F359614h 8DDE46A7h E61736B6h]
	;-- 0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0, 14
	PKEY_Device_FriendlyName: [A45C254Eh 4EFDDF1Ch D1672080h E050A846h 14]
	;-- 1CB9AD4C-DBFA-4c32-B178-C2F568A703B2
	IID_IAudioClient: [1CB9AD4Ch 4C32DBFAh F5C278B1h B203A768h]
	;-- F294ACFC-3146-4483-A7BF-ADDCA7C260E2
	IID_IAudioRenderClient: [F294ACFCh 44833146h DCADBFA7h E260C2A7h]
	;-- C8ADBD64-E71E-48a0-A4DE-185C395CD317
	IID_IAudioCaptureClient: [C8ADBD64h 48A0E71Eh 5C18DEA4h 17D35C39h]
	;-- 00000003-0000-0010-8000-00aa00389b71
	KSDATAFORMAT_SUBTYPE_IEEE_FLOAT: [00000003h 00100000h AA000080h 719B3800h]
	;-- 00000001-0000-0010-8000-00aa00389b71
	KSDATAFORMAT_SUBTYPE_PCM: [00000001h 00100000h AA000080h 719B3800h]
	;-- 7991EEC9-7E89-4D85-8390-6C703CEC60C0
	IID_IMMNotificationClient: [7991EEC9h 4D857E89h 706C9083h C060EC3Ch]
	;-- F6E4C0A0-46D9-4FB8-BE21-57A3EF2B626C
	IID_IAudioClockAdjustment: [F6E4C0A0h 4FB846D9h A35721BEh 6C622BEFh]

	DEVICE-MONITOR-NOTIFY!: alias struct! [
		list-notify		[this!]
		input-notify	[this!]
		output-notify	[this!]
	]
	DEVICE-MONITOR!: alias struct! [
		ethis		[this!]
		notifys		[DEVICE-MONITOR-NOTIFY! value]
	]
	;-- instance for device changed
	dev-monitor: declare DEVICE-MONITOR!

	#define DEVICE_STATE_ACTIVE			1
	#define STGM_READ					0
	#define CLSCTX_ALL					17h
	#define WAVE_FORMAT_EXTENSIBLE		FFFEh
	#define AUDCLNT_SHAREMODE_SHARED	0


	;-- channels flag for wasapi
	#define SPEAKER_FRONT_LEFT					00000001h
	#define SPEAKER_FRONT_RIGHT					00000002h
	#define SPEAKER_FRONT_CENTER				00000004h
	#define SPEAKER_LOW_FREQUENCY				00000008h
	#define SPEAKER_BACK_LEFT					00000010h
	#define SPEAKER_BACK_RIGHT					00000020h
	#define SPEAKER_FRONT_LEFT_OF_CENTER		00000040h
	#define SPEAKER_FRONT_RIGHT_OF_CENTER		00000080h
	#define SPEAKER_BACK_CENTER					00000100h
	#define SPEAKER_SIDE_LEFT					00000200h
	#define SPEAKER_SIDE_RIGHT					00000400h
	#define SPEAKER_TOP_CENTER					00000800h
	#define SPEAKER_TOP_FRONT_LEFT				00001000h
	#define SPEAKER_TOP_FRONT_CENTER			00002000h
	#define SPEAKER_TOP_FRONT_RIGHT				00004000h
	#define SPEAKER_TOP_BACK_LEFT				00008000h
	#define SPEAKER_TOP_BACK_CENTER				00010000h
	#define SPEAKER_TOP_BACK_RIGHT				00020000h

	#define KSAUDIO_SPEAKER_MONO				[SPEAKER_FRONT_CENTER]
	#define KSAUDIO_SPEAKER_1POINT1				[SPEAKER_FRONT_CENTER + SPEAKER_LOW_FREQUENCY]
	#define KSAUDIO_SPEAKER_STEREO				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT]
	#define KSAUDIO_SPEAKER_2POINT1				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_LOW_FREQUENCY]
	#define KSAUDIO_SPEAKER_3POINT0				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER]
	#define KSAUDIO_SPEAKER_3POINT1				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_LOW_FREQUENCY]
	#define KSAUDIO_SPEAKER_QUAD				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_BACK_LEFT + SPEAKER_BACK_RIGHT]
	#define KSAUDIO_SPEAKER_SURROUND			[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_BACK_CENTER]
	#define KSAUDIO_SPEAKER_5POINT0				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_SIDE_LEFT + SPEAKER_SIDE_RIGHT]
	#define KSAUDIO_SPEAKER_5POINT1				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_LOW_FREQUENCY + SPEAKER_BACK_LEFT + SPEAKER_BACK_RIGHT]
	#define KSAUDIO_SPEAKER_7POINT0				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_BACK_LEFT + SPEAKER_BACK_RIGHT + SPEAKER_SIDE_LEFT + SPEAKER_SIDE_RIGHT]
	#define KSAUDIO_SPEAKER_7POINT1				[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_LOW_FREQUENCY + SPEAKER_BACK_LEFT + SPEAKER_BACK_RIGHT + SPEAKER_FRONT_LEFT_OF_CENTER + SPEAKER_FRONT_RIGHT_OF_CENTER]
	#define KSAUDIO_SPEAKER_5POINT1_SURROUND	[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_LOW_FREQUENCY + SPEAKER_SIDE_LEFT  + SPEAKER_SIDE_RIGHT]
	#define KSAUDIO_SPEAKER_7POINT1_SURROUND	[SPEAKER_FRONT_LEFT + SPEAKER_FRONT_RIGHT + SPEAKER_FRONT_CENTER + SPEAKER_LOW_FREQUENCY + SPEAKER_BACK_LEFT + SPEAKER_BACK_RIGHT + SPEAKER_SIDE_LEFT + SPEAKER_SIDE_RIGHT]


	SECURITY_ATTRIBUTES!: alias struct! [
		len			[integer!]
		desc		[int-ptr!]
		inherit?	[logic!]
	]

	PROPERTYKEY!: alias struct! [
		fmtid		[GUID! value]
		pid			[integer!]
	]

	WAVEFORMATEXTENSIBLE!: alias struct! [
		TagChannels			[integer!]
		SamplesPerSec		[integer!]
		AvgBytesPerSec		[integer!]
		AlignBits			[integer!]
		SizeSamples			[integer!]
		ChannelMask			[integer!]
		SubFormat			[GUID! value]
	]

	WASAPI-DEVICE!: alias struct! [
		this			[this!]
		type			[AUDIO-DEVICE-TYPE!]
		id				[type-string!]				;-- unicode format
		name			[type-string!]				;-- unicode format
		client			[this!]
		io-cb			[int-ptr!]
		stop-cb			[int-ptr!]
		running?		[logic!]
		stop?			[logic!]
		rate-adjust		[this!]
		event			[int-ptr!]
		service			[this!]
		thread			[int-ptr!]
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
	]

	#import [
		LIBC-file cdecl [
			_beginthreadex: "_beginthreadex" [
				security	[int-ptr!]
				stack_size	[integer!]
				start		[int-ptr!]
				arglist		[int-ptr!]
				initflag	[integer!]
				thread_id	[int-ptr!]
				return:		[int-ptr!]
			]
			_endthreadex: "_endthreadex" [
				retval		[integer!]
			]
		]
		"kernel32.dll" stdcall [
			SwitchToThread: "SwitchToThread" [return: [logic!]]
			CloseHandle: "CloseHandle" [
				hObject		[int-ptr!]
				return:		[logic!]
			]
			WaitForSingleObject: "WaitForSingleObject" [
				hHandle		[int-ptr!]
				dwMillisec	[integer!]
				return:		[integer!]
			]
			TerminateThread: "TerminateThread" [
				hThread		[int-ptr!]
				retcode		[integer!]
				return:		[logic!]
			]
			GetCurrentThreadId: "GetCurrentThreadId" [
				return:		[integer!]
			]
			GetExitCodeThread: "GetExitCodeThread" [
				hThread		[int-ptr!]
				lpExitCode	[int-ptr!]
				return:		[logic!]
			]
			SetThreadPriority: "SetThreadPriority" [
				hThread		[int-ptr!]
				priority	[integer!]
				return:		[logic!]
			]
			CreateEvent: 	 "CreateEventW" [
				attr			[SECURITY_ATTRIBUTES!]
				reset?			[logic!]
				init?			[logic!]
				name			[byte-ptr!]
				return:			[int-ptr!]
			]
			mSleep: "Sleep" [
				dwMilliseconds	[integer!]
			]
		]
	]

	REFERENCE_TIME!: alias struct! [
		low		[integer!]
		high	[integer!]
	]

	IMMDeviceEnumerator: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		EnumAudioEndpoints			[function! [this [this!] dataFlow [integer!] dwStateMask [integer!] ppDevices [com-ptr!] return: [integer!]]]
		GetDefaultAudioEndpoint		[function! [this [this!] dataFlow [integer!] role [integer!] ppEndpoint [com-ptr!] return: [integer!]]]
		GetDevice					[function! [this [this!] pwstrId [byte-ptr!] ppDevice [com-ptr!] return: [integer!]]]
		RegisterEndpointNotificationCallback	[function! [this [this!] pClient [this!] return: [integer!]]]
		UnregisterEndpointNotificationCallback	[function! [this [this!] pClient [this!] return: [integer!]]]
	]

	IMMDeviceCollection: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetCount					[function! [this [this!] pcDevices [int-ptr!] return: [integer!]]]
		Item						[function! [this [this!] nDevice [integer!] ppDevice [com-ptr!] return: [integer!]]]
	]

	IMMDevice: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		Activate					[function! [this [this!] iid [int-ptr!] dwClsCtx [integer!] params [int-ptr!] ppInterface [com-ptr!] return: [integer!]]]
		OpenPropertyStore			[function! [this [this!] stgmAccess [integer!] ppProperties [com-ptr!] return: [integer!]]]
		GetId						[function! [this [this!] ppstrId [int-ptr!] return: [integer!]]]
		GetState					[function! [this [this!] pdwState [int-ptr!] return: [integer!]]]
	]

	IAudioClient: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		Initialize					[function! [this [this!] ShareMode [integer!] StreamFlags [integer!] hnsBufferDuration [REFERENCE_TIME! value] hnsPeriodicity [REFERENCE_TIME! value] pFormat [WAVEFORMATEXTENSIBLE!] AudioSessionGuid [int-ptr!] return: [integer!]]]
		GetBufferSize				[function! [this [this!] pNumBufferFrames [int-ptr!] return: [integer!]]]
		GetStreamLatency			[function! [this [this!] phnsLatency [REFERENCE_TIME!] return: [integer!]]]
		GetCurrentPadding			[function! [this [this!] pNumPaddingFrames [int-ptr!] return: [integer!]]]
		IsFormatSupported			[function! [this [this!] ShareMode [integer!] pFormat [WAVEFORMATEXTENSIBLE!] ppClosestMatch [int-ptr!] return: [integer!]]]
		GetMixFormat				[function! [this [this!] ppDeviceFormat [int-ptr!] return: [integer!]]]
		GetDevicePeriod				[function! [this [this!] phnsDefaultDevicePeriod [REFERENCE_TIME!] phnsMinimumDevicePeriod [REFERENCE_TIME!] return: [integer!]]]
		Start						[function! [this [this!] return: [integer!]]]
		Stop						[function! [this [this!] return: [integer!]]]
		Reset						[function! [this [this!] return: [integer!]]]
		SetEventHandle				[function! [this [this!] eventHandle [int-ptr!] return: [integer!]]]
		GetService					[function! [this [this!] riid [int-ptr!] ppv [com-ptr!] return: [integer!]]]
	]

	IAudioRenderClient: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetBuffer					[function! [this [this!] num [integer!] ppData [int-ptr!] return: [integer!]]]
		ReleaseBuffer				[function! [this [this!] num [integer!] flag [integer!] return: [integer!]]]
	]

	IAudioCaptureClient: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetBuffer					[function! [this [this!] ppData [int-ptr!] num [int-ptr!] flag [int-ptr!] dpos [int-ptr!] qpos [int-ptr!] return: [integer!]]]
		ReleaseBuffer				[function! [this [this!] num [integer!] return: [integer!]]]
		GetNextPacketSize			[function! [this [this!] pnum [int-ptr!] return: [integer!]]]
	]

	IAudioClockAdjustment: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		SetSampleRate				[function! [this [this!] rate [float32!] return: [integer!]]]
	]

	IPropertyStore: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		GetCount					[function! [this [this!] cProps [int-ptr!] return: [integer!]]]
		GetAt						[function! [this [this!] iProp [integer!] pkey [int-ptr!] return: [integer!]]]
		GetValue					[function! [this [this!] key [int-ptr!] pv [int-ptr!] return: [integer!]]]
		SetValue					[function! [this [this!] key [int-ptr!] propvar [int-ptr!] return: [integer!]]]
		Commit						[function! [this [this!] return: [integer!]]]
	]

	IMMNotificationClient: alias struct! [
		QueryInterface				[QueryInterface!]
		AddRef						[AddRef!]
		Release						[Release!]
		OnDeviceStateChanged		[function! [this [this!] id [int-ptr!] state [integer!] return: [integer!]]]
		OnDeviceAdded				[function! [this [this!] id [int-ptr!] return: [integer!]]]
		OnDeviceRemoved				[function! [this [this!] id [int-ptr!] return: [integer!]]]
		OnDefaultDeviceChanged		[function! [this [this!] flow [integer!] role [integer!] id [int-ptr!] return: [integer!]]]
		OnPropertyValueChanged		[function! [this [this!] id [int-ptr!] key [PROPERTYKEY! value] return: [integer!]]]
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

	init: func [return: [logic!]] [
		set-memory as byte-ptr! dev-monitor #"^(00)" size? DEVICE-MONITOR!
		true
	]

	close: does []

	get-device-name: func [
		dthis	[this!]
		pdev	[IMMDevice]
		return:	[type-string!]
		/local
			hr		[integer!]
			prop	[com-ptr! value]
			pthis	[this!]
			pprop	[IPropertyStore]
			buf		[int-ptr!]
			ustr	[type-string!]
	][
		hr: pdev/OpenPropertyStore dthis STGM_READ :prop
		if hr <> 0 [return null]
		pthis: prop/value
		pprop: as IPropertyStore pthis/vtbl
		buf: system/stack/allocate 128
		set-memory as byte-ptr! buf #"^(00)" 128 * 4
		hr: pprop/GetValue pthis PKEY_Device_FriendlyName buf
		if hr <> 0 [
			pprop/Release pthis
			return null
		]
		pprop/Release pthis
		ustr: type-string/load-unicode as byte-ptr! buf/3
		PropVariantClear buf
		ustr
	]

	get-device-id: func [
		dthis	[this!]
		pdev	[IMMDevice]
		return:	[type-string!]
		/local
			id		[integer!]
			hr		[integer!]
			len		[integer!]
			ustr	[type-string!]
	][
		id: 0
		hr: pdev/GetId dthis :id
		if hr <> 0 [return null]
		ustr: type-string/load-unicode as byte-ptr! id
		CoTaskMemFree id
		ustr
	]

	get-client: func [
		dthis	[this!]
		pdev	[IMMDevice]
		return:		[this!]
		/local
			hr		[integer!]
			cli		[com-ptr! value]
	][
		hr: pdev/Activate dthis IID_IAudioClient CLSCTX_ALL null :cli
		if hr <> 0 [return null]
		cli/value
	]

	init-format-with: func [
		fmt			[WAVEFORMATEXTENSIBLE!]
		ctype		[CHANNEL-TYPE!]
		rate		[integer!]
		s-format	[AUDIO-SAMPLE-TYPE!]
		/local
			chs		[integer!]
			mask	[integer!]
			bits	[integer!]
			align	[integer!]
	][
		chs: speaker-channels ctype
		mask: to-channel-mask ctype
		fmt/TagChannels: chs << 16 + WAVE_FORMAT_EXTENSIBLE
		fmt/SamplesPerSec: rate
		case [
			s-format = ASAMPLE-TYPE-I16 [
				copy-memory as byte-ptr! fmt/SubFormat as byte-ptr! KSDATAFORMAT_SUBTYPE_PCM size? GUID!
				bits: 16
			]
			s-format = ASAMPLE-TYPE-I32 [
				copy-memory as byte-ptr! fmt/SubFormat as byte-ptr! KSDATAFORMAT_SUBTYPE_PCM size? GUID!
				bits: 32
			]
			s-format = ASAMPLE-TYPE-F32 [
				copy-memory as byte-ptr! fmt/SubFormat as byte-ptr! KSDATAFORMAT_SUBTYPE_IEEE_FLOAT size? GUID!
				bits: 32
			]
		]
		align: chs * bits / 8
		fmt/AlignBits: bits << 16 + align
		fmt/AvgBytesPerSec: fmt/SamplesPerSec * chs * bits / 8
		fmt/SizeSamples: bits << 16 + 22
		fmt/ChannelMask: mask
	]

	to-channel-type: func [
		mask		[integer!]
		return:		[CHANNEL-TYPE!]
		/local
			temp	[integer!]
	][
		temp: KSAUDIO_SPEAKER_MONO
		if temp = mask [return AUDIO-SPEAKER-MONO]
		temp: KSAUDIO_SPEAKER_1POINT1
		if temp = mask [return AUDIO-SPEAKER-1POINT1]
		temp: KSAUDIO_SPEAKER_STEREO
		if temp = mask [return AUDIO-SPEAKER-STEREO]
		temp: KSAUDIO_SPEAKER_2POINT1
		if temp = mask [return AUDIO-SPEAKER-2POINT1]
		temp: KSAUDIO_SPEAKER_3POINT0
		if temp = mask [return AUDIO-SPEAKER-3POINT0]
		temp: KSAUDIO_SPEAKER_3POINT1
		if temp = mask [return AUDIO-SPEAKER-3POINT1]
		temp: KSAUDIO_SPEAKER_QUAD
		if temp = mask [return AUDIO-SPEAKER-QUAD]
		temp: KSAUDIO_SPEAKER_SURROUND
		if temp = mask [return AUDIO-SPEAKER-SURROUND]
		temp: KSAUDIO_SPEAKER_5POINT0
		if temp = mask [return AUDIO-SPEAKER-5POINT0]
		temp: KSAUDIO_SPEAKER_5POINT1
		if temp = mask [return AUDIO-SPEAKER-5POINT1]
		temp: KSAUDIO_SPEAKER_7POINT0
		if temp = mask [return AUDIO-SPEAKER-7POINT0]
		temp: KSAUDIO_SPEAKER_7POINT1
		if temp = mask [return AUDIO-SPEAKER-7POINT1]
		temp: KSAUDIO_SPEAKER_5POINT1_SURROUND
		if temp = mask [return AUDIO-SPEAKER-5POINT1-SURROUND]
		temp: KSAUDIO_SPEAKER_7POINT1_SURROUND
		if temp = mask [return AUDIO-SPEAKER-7POINT1-SURROUND]
		AUDIO-SPEAKER-LAST
	]

	to-channel-mask: func [
		type		[CHANNEL-TYPE!]
		return:		[integer!]
		/local
			temp	[integer!]
	][
		case [
			type = AUDIO-SPEAKER-MONO [
				temp: KSAUDIO_SPEAKER_MONO
				return temp
			]
			type = AUDIO-SPEAKER-1POINT1 [
				temp: KSAUDIO_SPEAKER_1POINT1
				return temp
			]
			type = AUDIO-SPEAKER-STEREO [
				temp: KSAUDIO_SPEAKER_STEREO
				return temp
			]
			type = AUDIO-SPEAKER-2POINT1 [
				temp: KSAUDIO_SPEAKER_2POINT1
				return temp
			]
			type = AUDIO-SPEAKER-3POINT0 [
				temp: KSAUDIO_SPEAKER_3POINT0
				return temp
			]
			type = AUDIO-SPEAKER-3POINT1 [
				temp: KSAUDIO_SPEAKER_3POINT1
				return temp
			]
			type = AUDIO-SPEAKER-QUAD [
				temp: KSAUDIO_SPEAKER_QUAD
				return temp
			]
			type = AUDIO-SPEAKER-SURROUND [
				temp: KSAUDIO_SPEAKER_SURROUND
				return temp
			]
			type = AUDIO-SPEAKER-5POINT0 [
				temp: KSAUDIO_SPEAKER_5POINT0
				return temp
			]
			type = AUDIO-SPEAKER-5POINT1 [
				temp: KSAUDIO_SPEAKER_5POINT1
				return temp
			]
			type = AUDIO-SPEAKER-7POINT0 [
				temp: KSAUDIO_SPEAKER_7POINT0
				return temp
			]
			type = AUDIO-SPEAKER-7POINT1 [
				temp: KSAUDIO_SPEAKER_7POINT1
				return temp
			]
			type = AUDIO-SPEAKER-5POINT1-SURROUND [
				temp: KSAUDIO_SPEAKER_5POINT1_SURROUND
				return temp
			]
			type = AUDIO-SPEAKER-7POINT1-SURROUND [
				temp: KSAUDIO_SPEAKER_7POINT1_SURROUND
				return temp
			]
		]
	]

	dump-format: func [
		fmt			[WAVEFORMATEXTENSIBLE!]
	][
		print-line ["    tag: " as int-ptr! fmt/TagChannels and FFFFh]
		print-line ["    channels: " as int-ptr! fmt/TagChannels >>> 16]
		print-line ["    rate: " fmt/SamplesPerSec]
		print-line ["    bytes: " as int-ptr! fmt/AvgBytesPerSec]
		print-line ["    bits: " fmt/AlignBits >>> 16]
		print-line ["    align: " fmt/AlignBits and FFFFh]
		print-line ["    cbsize: " fmt/SizeSamples and FFFFh]
		print-line ["    Samples: " fmt/SizeSamples >>> 16]
		print-line ["    mask: " as int-ptr! fmt/ChannelMask]
		print-line ["    guid: " as int-ptr! fmt/SubFormat/guid1 " " as int-ptr! fmt/SubFormat/guid2 " " as int-ptr! fmt/SubFormat/guid3 " " as int-ptr! fmt/SubFormat/guid4]
	]

	#define DURATION-UNIT	10'000'000.0
	;-- set the duration time (0.1us), time per buffer size
	;-- buffer size = frames * count
	init-client-with: func [
		this			[this!]
		client			[IAudioClient]
		buffer-count	[integer!]
		rate			[integer!]
		format			[WAVEFORMATEXTENSIBLE!]
		return:			[logic!]
		/local
			period		[REFERENCE_TIME! value]
			buf-time	[REFERENCE_TIME! value]
			ft			[float!]
			ft2			[float!]
			hr			[integer!]
	][
		period/low: 0
		period/high: 0
		buf-time/low: 0
		buf-time/high: 0
		ft: DURATION-UNIT
		ft: ft * as float! buffer-count
		ft: ft / as float! rate
		buf-time/high: as integer! ft / 4294967296.0
		ft2: (as float! buf-time/high) * 4294967296.0
		buf-time/low: as integer! ft - ft2
		hr: client/Initialize this 0 88140000h buf-time period format null
		if hr <> 0 [return false]
		true
	]

	init-device: func [
		dev				[WASAPI-DEVICE!]
		dthis			[this!]
		type			[AUDIO-DEVICE-TYPE!]
		return:			[logic!]
		/local
			pdev		[IMMDevice]
			client		[IAudioClient]
			hr			[integer!]
			wf			[integer!]
			fmt			[WAVEFORMATEXTENSIBLE!]
			bits		[integer!]
			ext			[WAVEFORMATEXTENSIBLE! value]
			formats		[int-ptr!]
			tf			[integer!]
			count		[integer!]
			channels	[int-ptr!]
			iter		[CHANNEL-TYPE!]
			rates		[int-ptr!]
			num			[integer!]
			frates		[int-ptr!]
			nthis		[this!]
			nclient		[IAudioClient]
	][
		set-memory as byte-ptr! dev #"^(00)" size? WASAPI-DEVICE!
		pdev: as IMMDevice dthis/vtbl
		dev/this: dthis
		dev/type: type
		dev/id: get-device-id dthis pdev
		dev/name: get-device-name dthis pdev
		dev/client: get-client dthis pdev
		dev/running?: no
		if null? dev/client [return false]
		client: as IAudioClient dev/client/vtbl
		wf: 0
		hr: client/GetMixFormat dev/client :wf
		if hr <> 0 [return false]
		fmt: as WAVEFORMATEXTENSIBLE! wf
		dev/channel: to-channel-type fmt/ChannelMask
		dev/rate: fmt/SamplesPerSec
		either 0 = compare-memory as byte-ptr! fmt/SubFormat as byte-ptr! KSDATAFORMAT_SUBTYPE_IEEE_FLOAT size? GUID! [
			dev/format: ASAMPLE-TYPE-F32
		][
			either 0 = compare-memory as byte-ptr! fmt/SubFormat as byte-ptr! KSDATAFORMAT_SUBTYPE_PCM size? GUID! [
				bits: fmt/AlignBits >>> 16
				case [
					bits = 16 [
						dev/format: ASAMPLE-TYPE-I16
					]
					bits = 32 [
						dev/format: ASAMPLE-TYPE-I32
					]
					true [
						dev/format: -1
					]
				]
			][
				dev/format: -1
			]
		]
		CoTaskMemFree wf
		;-- get formats
		count: 0
		formats: as int-ptr! allocate 4 * 4
		set-memory as byte-ptr! formats #"^(00)" 4 * 4
		dev/formats: formats
		tf: 0
		init-format-with ext dev/channel dev/rate ASAMPLE-TYPE-I16
		hr: client/IsFormatSupported dev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
		if hr = 0 [
			formats/1: ASAMPLE-TYPE-I16
			formats: formats + 1
			count: count + 1
		]
		if tf <> 0 [CoTaskMemFree tf]
		tf: 0
		init-format-with ext dev/channel dev/rate ASAMPLE-TYPE-I32
		hr: client/IsFormatSupported dev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
		if hr = 0 [
			formats/1: ASAMPLE-TYPE-I32
			formats: formats + 1
			count: count + 1
		]
		if tf <> 0 [CoTaskMemFree tf]
		tf: 0
		init-format-with ext dev/channel dev/rate ASAMPLE-TYPE-F32
		hr: client/IsFormatSupported dev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
		if hr = 0 [
			formats/1: ASAMPLE-TYPE-F32
			formats: formats + 1
			count: count + 1
		]
		if tf <> 0 [CoTaskMemFree tf]
		if count = 0 [
			free as byte-ptr! dev/formats
			dev/formats: null
			return false
		]
		dev/formats-count: count
		;-- get channels
		count: 0
		channels: as int-ptr! allocate AUDIO-SPEAKER-LAST + 1 * 4
		set-memory as byte-ptr! channels #"^(00)" AUDIO-SPEAKER-LAST + 1 * 4
		dev/channels: channels
		iter: AUDIO-SPEAKER-MONO
		loop AUDIO-SPEAKER-LAST [
			tf: 0
			init-format-with ext iter dev/rate dev/format
			hr: client/IsFormatSupported dev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
			if hr = 0 [
				channels/1: iter
				channels: channels + 1
				count: count + 1
			]
			if tf <> 0 [CoTaskMemFree tf]
			iter: iter + 1
		]
		if count = 0 [
			free as byte-ptr! dev/channels
			dev/channels: null
			return false
		]
		dev/channels-count: count
		;-- get rates
		num: size? rates-filters
		frates: rates-filters
		count: 0
		rates: as int-ptr! allocate num + 1 * 4
		set-memory as byte-ptr! rates #"^(00)" num + 1 * 4
		dev/rates: rates
		loop num [
			tf: 0
			init-format-with ext dev/channel frates/1 dev/format
			hr: client/IsFormatSupported dev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
			if hr = 0 [
				rates/1: frates/1
				rates: rates + 1
				count: count + 1
			]
			if tf <> 0 [CoTaskMemFree tf]
			frates: frates + 1
		]
		if count = 0 [
			free as byte-ptr! dev/rates
			dev/rates: null
			return false
		]
		dev/rates-count: count
		;-- client can only be inited once, so we need a new client to get buffer-size
		nthis: get-client dthis pdev
		nclient: as IAudioClient nthis/vtbl
		init-format-with ext dev/channel dev/rate dev/format
		init-client-with nthis nclient dev/buffer-size dev/rate ext
		hr: nclient/GetBufferSize nthis :dev/buffer-size
		nclient/Release nthis
		true
	]

	dump-device: func [
		dev			[AUDIO-DEVICE!]
		/local
			wdev	[WASAPI-DEVICE!]
			p		[int-ptr!]
	][
		if null? dev [print-line "null device!" exit]
		wdev: as WASAPI-DEVICE! dev
		print-line "================================"
		print-line ["dev: " dev]
		either wdev/type = ADEVICE-TYPE-OUTPUT [
			print-line "    type: speaker"
		][
			print-line "    type: microphone"
		]
		print "    id: "
		type-string/uprint wdev/id
		print "^/    name: "
		type-string/uprint wdev/name
		print "^/    formats: "
		either null? wdev/formats [
			print "none"
		][
			p: wdev/formats
			loop wdev/formats-count [
				sample-type-to-str p/1
				p: p + 1
			]
		]
		print "^/    channels: "
		either null? wdev/channels [
			print "none"
		][
			p: wdev/channels
			loop wdev/channels-count [
				print [p/1 " "]
				p: p + 1
			]
		]
		print "^/    rates: "
		either null? wdev/rates [
			print "none"
		][
			p: wdev/rates
			loop wdev/rates-count [
				print [p/1 " "]
				p: p + 1
			]
		]
		print ["^/    format: "]
		sample-type-to-str wdev/format
		print "^/"

		print-line ["    default channels: " wdev/channel]
		print-line ["    default rate: " wdev/rate]
		print-line ["    default format: " wdev/format]
		print-line ["    buffer frames: " wdev/buffer-size]
		print-line "================================"
	]

	default-device: func [
		type		[AUDIO-DEVICE-TYPE!]
		return:		[AUDIO-DEVICE!]
		/local
			flag	[integer!]
			hr		[integer!]
			enum	[interface! value]
			etor	[IMMDeviceEnumerator]
			ethis	[this!]
			iter	[com-ptr! value]
			device	[com-ptr! value]
			wdev	[WASAPI-DEVICE!]
	][
		flag: either type = ADEVICE-TYPE-OUTPUT [0][1]
		hr: CoCreateInstance CLSID_MMDeviceEnumerator 0 CLSCTX_INPROC_SERVER IID_IMMDeviceEnumerator :enum
		if hr <> 0 [return null]
		ethis: enum/ptr
		etor: as IMMDeviceEnumerator ethis/vtbl
		hr: etor/GetDefaultAudioEndpoint ethis flag 0 :device
		etor/Release ethis
		if hr <> 0 [
			return null
		]
		wdev: as WASAPI-DEVICE! allocate size? WASAPI-DEVICE!
		init-device wdev device/value type
		as AUDIO-DEVICE! wdev
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

	enum-device: func [
		list		[int-ptr!]
		end			[int-ptr!]
		num			[int-ptr!]
		ethis		[this!]
		type		[AUDIO-DEVICE-TYPE!]
		return:		[logic!]
		/local
			flag	[integer!]
			etor	[IMMDeviceEnumerator]
			hr		[integer!]
			cols	[com-ptr! value]
			cthis	[this!]
			pcol	[IMMDeviceCollection]
			count	[integer!]
			i		[integer!]
			device	[com-ptr! value]
			dthis	[this!]
			pdev	[IMMDevice]
			wdev	[WASAPI-DEVICE!]
	][
		flag: either type = ADEVICE-TYPE-OUTPUT [0][1]
		etor: as IMMDeviceEnumerator ethis/vtbl
		hr: etor/EnumAudioEndpoints ethis flag DEVICE_STATE_ACTIVE :cols
		if hr <> 0 [return false]
		cthis: cols/value
		pcol: as IMMDeviceCollection cthis/vtbl
		count: 0
		hr: pcol/GetCount cthis :count
		if hr <> 0 [
			pcol/Release cthis
			return false
		]
		if null? list [
			num/1: count
			pcol/Release cthis
			return true
		]
		num/1: 0
		i: 0
		loop count [
			hr: pcol/Item cthis i :device
			if hr <> 0 [break]
			dthis: device/value
			pdev: as IMMDevice dthis/vtbl
			either list < end [
				wdev: as WASAPI-DEVICE! allocate size? WASAPI-DEVICE!
				init-device wdev dthis type
				list/1: as integer! wdev
				list: list + 1
			][
				pdev/Release dthis
				pcol/Release cthis
				return false
			]
			num/1: num/1 + 1
			i: i + 1
		]
		pcol/Release cthis
		true
	]

	get-devices: func [
		type		[AUDIO-DEVICE-TYPE!]
		count		[int-ptr!]			;-- number of input devices
		return:		[AUDIO-DEVICE!]		;-- an array of AUDIO-DEVICE!
		/local
			hr		[integer!]
			enum	[interface! value]
			ethis	[this!]
			etor	[IMMDeviceEnumerator]
			list	[int-ptr!]
			end		[int-ptr!]
	][
		count/1: 0
		hr: CoCreateInstance CLSID_MMDeviceEnumerator 0 CLSCTX_INPROC_SERVER IID_IMMDeviceEnumerator :enum
		if hr <> 0 [return null]
		ethis: enum/ptr
		etor: as IMMDeviceEnumerator ethis/vtbl
		unless enum-device null null count ethis type [
			etor/Release ethis
			return null
		]
		list: as int-ptr! allocate count/1 + 1 * 4
		end: list + count/1
		end/1: 0
		unless enum-device list end count ethis type [
			etor/Release ethis
			free as byte-ptr! list
			return null
		]
		etor/Release ethis
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

	free-device*: func [
		dev			[AUDIO-DEVICE!]
		/local
			wdev	[WASAPI-DEVICE!]
			unk		[IUnknown]
	][
		if null? dev [exit]
		stop dev
		wdev: as WASAPI-DEVICE! dev
		unless null? wdev/event [
			CloseHandle wdev/event
		]
		unless null? wdev/service [
			unk: as IUnknown wdev/service/vtbl
			unk/Release wdev/service
		]
		unk: as IUnknown wdev/this/vtbl
		unk/Release wdev/this
		unk: as IUnknown wdev/client/vtbl
		unk/Release wdev/client
		type-string/release wdev/id
		type-string/release wdev/name
		unless null? wdev/channels [
			free as byte-ptr! wdev/channels
		]
		unless null? wdev/rates [
			free as byte-ptr! wdev/rates
		]
		unless null? wdev/formats [
			free as byte-ptr! wdev/formats
		]
		free as byte-ptr! wdev
	]

	free-device: func [
		dev			[AUDIO-DEVICE!]
	][
		free-device* dev
	]

	free-devices: func [
		devs		[AUDIO-DEVICE!]			;-- an array of AUDIO-DEVICE!
		count		[integer!]				;-- number of devices
		/local
			p		[byte-ptr!]
			wdev	[WASAPI-DEVICE!]
			otype	[integer!]
	][
		if null? devs [exit]
		p: as byte-ptr! devs
		otype: -1
		loop count [
			wdev: as WASAPI-DEVICE! devs/1
			if wdev/type <> otype [
				otype: wdev/type
			]
			free-device* as AUDIO-DEVICE! devs/1
			devs: devs + 1
		]
		free p
	]

	name: func [
		dev			[AUDIO-DEVICE!]
		return:		[type-string!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/name
	]

	id: func [
		dev			[AUDIO-DEVICE!]
		return:		[type-string!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/id
	]

	channels: func [
		dev			[AUDIO-DEVICE!]
		count		[int-ptr!]
		return:		[int-ptr!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		if null? wdev/channels [return null]
		count/1: wdev/channels-count
		wdev/channels
	]

	rates: func [
		dev			[AUDIO-DEVICE!]
		count		[int-ptr!]
		return:		[int-ptr!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		if null? wdev/rates [return null]
		count/1: wdev/rates-count
		wdev/rates
	]

	sample-formats: func [
		dev			[AUDIO-DEVICE!]
		count		[int-ptr!]
		return:		[int-ptr!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		if null? wdev/formats [return null]
		count/1: wdev/formats-count
		wdev/formats
	]

	channels-type: func [
		dev			[AUDIO-DEVICE!]
		return:		[CHANNEL-TYPE!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/channel
	]

	set-channels-type: func [
		dev			[AUDIO-DEVICE!]
		type		[CHANNEL-TYPE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
			client	[IAudioClient]
			tf		[integer!]
			ext		[WAVEFORMATEXTENSIBLE! value]
			hr		[integer!]
	][
		wdev: as WASAPI-DEVICE! dev
		if wdev/running? [return false]
		client: as IAudioClient wdev/client/vtbl
		tf: 0
		init-format-with ext type wdev/rate wdev/format
		hr: client/IsFormatSupported wdev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
		if tf <> 0 [CoTaskMemFree tf]
		if hr <> 0 [return false]
		wdev/channel: type
		true
	]

	buffer-size: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/buffer-size
	]

	set-buffer-size: func [
		dev			[AUDIO-DEVICE!]
		count		[integer!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		if wdev/running? [return false]
		wdev/buffer-size: count
		true
	]

	sample-rate: func [
		dev			[AUDIO-DEVICE!]
		return:		[integer!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/rate
	]

	set-sample-rate: func [
		dev			[AUDIO-DEVICE!]
		rate		[integer!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
			client	[IAudioClient]
			service	[com-ptr! value]
			this	[this!]
			padjust [IAudioClockAdjustment]
			hr		[integer!]
	][
		wdev: as WASAPI-DEVICE! dev
		if wdev/running? [return false]
		if wdev/rate = rate [return true]

		wdev/rate: rate
		if wdev/service <> null [		;-- already initialized
			if null? wdev/rate-adjust [
				client: as IAudioClient wdev/client/vtbl
				hr: client/GetService wdev/client IID_IAudioClockAdjustment :service
				if hr = 0 [wdev/rate-adjust: service/value]
			]
			this: wdev/rate-adjust
			padjust: as IAudioClockAdjustment this/vtbl
			if 0 <> padjust/SetSampleRate this as float32! rate [return false]
		]
		true
	]

	sample-format: func [
		dev			[AUDIO-DEVICE!]
		return:		[AUDIO-SAMPLE-TYPE!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/format
	]

	set-sample-format: func [
		dev			[AUDIO-DEVICE!]
		type		[AUDIO-SAMPLE-TYPE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
			client	[IAudioClient]
			tf		[integer!]
			ext		[WAVEFORMATEXTENSIBLE! value]
			hr		[integer!]
	][
		wdev: as WASAPI-DEVICE! dev
		if wdev/running? [return false]
		;client: as IAudioClient wdev/client/vtbl
		;tf: 0
		;init-format-with ext wdev/channel wdev/rate type
		;hr: client/IsFormatSupported wdev/client AUDCLNT_SHAREMODE_SHARED :ext :tf
		;if tf <> 0 [CoTaskMemFree tf]
		;if hr <> 0 [return false]
		wdev/format: type
		true
	]

	input?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/type = ADEVICE-TYPE-INPUT
	]

	output?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/type = ADEVICE-TYPE-OUTPUT
	]

	running?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/running?
	]

	has-unprocessed-io?: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
			pad		[integer!]
			pclient	[IAudioClient]
			num		[integer!]
	][
		wdev: as WASAPI-DEVICE! dev
		if null? wdev/client [return false]
		unless wdev/running? [return false]
		pad: 0
		pclient: as IAudioClient wdev/client/vtbl
		pclient/GetCurrentPadding wdev/client :pad
		num: wdev/buffer-size - pad
		num > 0
	]

	connect: func [
		dev			[AUDIO-DEVICE!]
		io-cb		[int-ptr!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
			client	[IAudioClient]
			ext		[WAVEFORMATEXTENSIBLE! value]
	][
		wdev: as WASAPI-DEVICE! dev
		if wdev/running? [probe "connect still running" return false]
		client: as IAudioClient wdev/client/vtbl

		init-format-with ext wdev/channel wdev/rate wdev/format
		unless init-client-with wdev/client client wdev/buffer-size wdev/rate ext [
			return false
		]
		wdev/io-cb: io-cb
		true
	]

	process: func [
		dev				[AUDIO-DEVICE!]
		io-cb			[int-ptr!]
		/local
			wdev		[WASAPI-DEVICE!]
			pclient		[IAudioClient]
			pad			[integer!]
			num			[integer!]
			prender		[IAudioRenderClient]
			data		[integer!]
			pcb			[AUDIO-IO-CALLBACK!]
			next-size	[integer!]
			pcapture	[IAudioCaptureClient]
			flags		[integer!]
			abuff		[AUDIO-DEVICE-IO! value]
			temp		[integer!]
			chs			[int-ptr!]
			size		[integer!]
			step		[integer!]
	][
		wdev: as WASAPI-DEVICE! dev
		if null? wdev/client [exit]
		pclient: as IAudioClient wdev/client/vtbl
		;-- output
		if wdev/type = ADEVICE-TYPE-OUTPUT [
			pad: 0
			pclient/GetCurrentPadding wdev/client :pad
			num: wdev/buffer-size - pad
			if num = 0 [exit]
			prender: as IAudioRenderClient wdev/service/vtbl
			data: 0
			prender/GetBuffer wdev/service num :data
			if data = 0 [exit]
			pcb: as AUDIO-IO-CALLBACK! io-cb
			set-memory as byte-ptr! abuff #"^(00)" size? AUDIO-DEVICE-IO!
			abuff/buffer/sample-type: wdev/format
			abuff/buffer/frames-count: num
			temp: speaker-channels wdev/channel
			abuff/buffer/channels-count: temp
			abuff/buffer/stride: temp
			abuff/buffer/contiguous?: yes
			chs: as int-ptr! abuff/buffer/channels
			size: either wdev/format = ASAMPLE-TYPE-I16 [2][4]
			step: data
			loop temp [
				chs/1: step
				chs: chs + 1
				step: step + size
			]
			pcb dev abuff
			prender/ReleaseBuffer wdev/service num 0
			exit
		]
		;-- input
		if wdev/type = ADEVICE-TYPE-INPUT [
			next-size: 0
			pcapture: as IAudioCaptureClient wdev/service/vtbl
			pcapture/GetNextPacketSize wdev/service :next-size
			if next-size = 0 [exit]
			flags: 0
			data: 0
			pcapture/GetBuffer wdev/service :data :next-size :flags null null
			if data = 0 [exit]
			pcb: as AUDIO-IO-CALLBACK! io-cb
			set-memory as byte-ptr! abuff #"^(00)" size? AUDIO-DEVICE-IO!
			abuff/buffer/sample-type: wdev/format
			abuff/buffer/frames-count: next-size
			temp: speaker-channels wdev/channel
			abuff/buffer/channels-count: temp
			abuff/buffer/stride: temp
			abuff/buffer/contiguous?: yes
			chs: as int-ptr! abuff/buffer/channels
			size: either wdev/format = ASAMPLE-TYPE-I16 [2][4]
			step: data
			loop temp [
				chs/1: step
				chs: chs + 1
				step: step + size
			]
			pcb dev abuff
			pcapture/ReleaseBuffer wdev/service next-size
			exit
		]
	]

	thread-cb: func [
		[stdcall]
		dev				[AUDIO-DEVICE!]
		/local
			wdev		[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		SetThreadPriority wdev/thread 15
		while [wdev/running?][
			if wdev/stop? [
				stop dev
				break
			]
			unless null? wdev/io-cb [
				process dev wdev/io-cb
			]
			WaitForSingleObject wdev/event -1
		]
	]

	start: func [
		dev			[audio-device!]
		start-cb	[int-ptr!]				;-- audio-device-callback!
		stop-cb		[int-ptr!]				;-- audio-device-callback!
		return:		[logic!]
		/local
			wdev		[WASAPI-DEVICE!]
			pclient		[IAudioClient]
			hr			[integer!]
			service		[com-ptr! value]
			p			[int-ptr!]
			start_cb	[AUDIO-DEVICE-CALLBACK!]
	][
		wdev: as WASAPI-DEVICE! dev
		if null? wdev/client [return false]
		if wdev/running? [return true]

		pclient: as IAudioClient wdev/client/vtbl
		if null? wdev/service [
			p: either wdev/type = ADEVICE-TYPE-OUTPUT [IID_IAudioRenderClient][IID_IAudioCaptureClient]
			hr: pclient/GetService wdev/client p :service
			if hr = 0 [wdev/service: service/value]
		]

		hr: pclient/GetBufferSize wdev/client :wdev/buffer-size
		if hr <> 0 [return false]

		if null? wdev/event [
			wdev/event: CreateEvent null no no null
			hr: pclient/SetEventHandle wdev/client wdev/event
			if hr <> 0 [return false]
		]
		hr: pclient/Start wdev/client
		if hr <> 0 [return false]
		wdev/running?: yes
		wdev/stop?: no

		unless null? wdev/io-cb [
			wdev/thread: _beginthreadex null 0 as int-ptr! :thread-cb dev 0 null
		]
		unless null? start-cb [
			start_cb: as AUDIO-DEVICE-CALLBACK! start-cb
			start_cb dev
		]
		wdev/stop-cb: stop-cb
		true
	]

	stop: func [
		dev			[AUDIO-DEVICE!]
		return:		[logic!]
		/local
			wdev	[WASAPI-DEVICE!]
			pclient	[IAudioClient]
			stop_cb	[AUDIO-DEVICE-CALLBACK!]
	][
		wdev: as WASAPI-DEVICE! dev
		if wdev/running? [
			wdev/running?: no
			unless null? wdev/client [
				pclient: as IAudioClient wdev/client/vtbl
				pclient/Stop wdev/client
			]
			unless null? wdev/stop-cb [
				stop_cb: as AUDIO-DEVICE-CALLBACK! wdev/stop-cb
				stop_cb dev
			]
		]
		true
	]

	inner-stop: func [
		dev			[AUDIO-DEVICE!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		wdev/stop?: yes
	]

	wait: func [
		dev			[AUDIO-DEVICE!]
		/local
			wdev	[WASAPI-DEVICE!]
	][
		wdev: as WASAPI-DEVICE! dev
		unless null? wdev/thread [
			WaitForSingleObject wdev/thread -1
		]
	]

	sleep: func [
		ms			[integer!]
	][
		mSleep ms
	]

	init-monitor: func [
		/local
			hr		[integer!]
			enum	[interface! value]
			ethis	[this!]
	][
		if null? dev-monitor/ethis [
			hr: CoCreateInstance CLSID_MMDeviceEnumerator 0 CLSCTX_INPROC_SERVER IID_IMMDeviceEnumerator :enum
			if hr <> 0 [exit]
			dev-monitor/ethis: enum/ptr
		]
	]

	free-monitor: func [
		/local
			unk		[IUnknown]
	][
		unk: as IUnknown dev-monitor/ethis/vtbl
		unk/Release dev-monitor/ethis
		set-memory as byte-ptr! dev-monitor #"^(00)" size? DEVICE-MONITOR!
	]

	IAddRef: func [
		[stdcall]
		this		[this!]
		return:		[integer!]
	][1]

	IRelease: func [
		[stdcall]
		this		[this!]
		return:		[integer!]
	][0]

	IQueryInterface: func [
		[stdcall]
		this		[this!]
		riid		[int-ptr!]
		req			[int-ptr!]
		return:		[integer!]
	][
		if 0 = compare-memory as byte-ptr! IID_IUnknown as byte-ptr! riid size? GUID! [
			req/1: as integer! this
			return 0
		]
		if 0 = compare-memory as byte-ptr! IID_IMMNotificationClient as byte-ptr! riid size? GUID! [
			req/1: as integer! this
			return 0
		]
		req/1: 0
		80004002h
	]

	OnDefaultDeviceChanged: func [
		[stdcall]
		this		[this!]
		flow		[integer!]
		role		[integer!]
		id			[byte-ptr!]
		return:		[integer!]
		/local
			p		[int-ptr!]
			event	[integer!]
			d-cb	[AUDIO-CHANGED-CALLBACK!]
	][
		;-- ERole::eConsole
		if role <> 0 [return 0]
		;-- EDataFlow::eRender
		p: as int-ptr! this
		event: p/2
		if flow = 0 [
			if event <> DEFAULT-OUTPUT-CHANGED [return 0]
		]
		;-- EDataFlow::eCapture
		if flow = 1 [
			if event <> DEFAULT-INPUT-CHANGED [return 0]
		]
		d-cb: as AUDIO-CHANGED-CALLBACK! p/3
		d-cb
		0
	]

	OnDeviceAdded: func [
		[stdcall]
		this		[this!]
		id			[byte-ptr!]
		return:		[integer!]
		/local
			p		[int-ptr!]
			event	[integer!]
			d-cb	[AUDIO-CHANGED-CALLBACK!]
	][
		p: as int-ptr! this
		event: p/2
		if event <> ADEVICE-LIST-CHANGED [return 0]
		d-cb: as AUDIO-CHANGED-CALLBACK! p/3
		d-cb
		0
	]

	OnDeviceRemoved: func [
		[stdcall]
		this		[this!]
		id			[byte-ptr!]
		return:		[integer!]
		/local
			p		[int-ptr!]
			event	[integer!]
			d-cb	[AUDIO-CHANGED-CALLBACK!]
	][
		p: as int-ptr! this
		event: p/2
		if event <> ADEVICE-LIST-CHANGED [return 0]
		d-cb: as AUDIO-CHANGED-CALLBACK! p/3
		d-cb
		0
	]

	OnDeviceStateChanged: func [
		[stdcall]
		this		[this!]
		id			[byte-ptr!]
		state		[integer!]
		return:		[integer!]
		/local
			p		[int-ptr!]
			event	[integer!]
			d-cb	[AUDIO-CHANGED-CALLBACK!]
	][
		p: as int-ptr! this
		event: p/2
		if event <> ADEVICE-LIST-CHANGED [return 0]
		d-cb: as AUDIO-CHANGED-CALLBACK! p/3
		d-cb
		0
	]

	OnPropertyValueChanged: func [
		[stdcall]
		this		[this!]
		id			[byte-ptr!]
		key			[PROPERTYKEY! value]
	][0]

	create-notify-client: func [
		event		[AUDIO-DEVICE-EVENT!]
		cb			[int-ptr!]
		return:		[this!]
		/local
			this	[int-ptr!]
			nclient	[int-ptr!]
	][
		nclient: as int-ptr! allocate size? IMMNotificationClient
		this: as int-ptr! allocate 16
		this/1: as integer! nclient
		this/2: event
		this/3: as integer! cb
		nclient/1: as integer! :IQueryInterface
		nclient/2: as integer! :IAddRef
		nclient/3: as integer! :IRelease
		nclient/4: as integer! :OnDeviceStateChanged
		nclient/5: as integer! :OnDeviceAdded
		nclient/6: as integer! :OnDeviceRemoved
		nclient/7: as integer! :OnDefaultDeviceChanged
		nclient/8: as integer! :OnPropertyValueChanged
		as this! this
	]

	free-notify-client: func [
		this			[this!]
		/local
			etor		[IMMDeviceEnumerator]
			hr			[integer!]
			p			[int-ptr!]
			client		[byte-ptr!]
	][
		etor: as IMMDeviceEnumerator dev-monitor/ethis/vtbl
		hr: etor/UnRegisterEndpointNotificationCallback dev-monitor/ethis this
		p: as int-ptr! this
		client: as byte-ptr! p/1
		free client
		free as byte-ptr! this
	]

	set-device-changed-callback: func [
		event			[AUDIO-DEVICE-EVENT!]
		cb				[int-ptr!]				;-- audio-changed-callback!
		/local
			etor		[IMMDeviceEnumerator]
			this		[this!]
			hr			[integer!]
			notifys		[int-ptr!]
	][
		init-monitor
		etor: as IMMDeviceEnumerator dev-monitor/ethis/vtbl
		this: create-notify-client event cb
		hr: etor/RegisterEndpointNotificationCallback dev-monitor/ethis this
		notifys: as int-ptr! dev-monitor/notifys
		notifys: notifys + event
		if notifys/1 <> 0 [
			free-notify-client as this! notifys/1
		]
		notifys/1: as integer! this
	]

	free-device-changed-callback: func [
		/local
			notifys		[int-ptr!]
	][
		notifys: as int-ptr! dev-monitor/notifys
		loop 3 [
			if notifys/1 <> 0 [
				free-notify-client as this! notifys/1
			]
			notifys: notifys + 1
		]
		free-monitor
	]
]
