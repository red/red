Red/System []

pcm-wav: context [
	WAV-FORMAT!: alias struct! [
		channels			[integer!]
		sample-rate			[integer!]
		sample-bits			[integer!]
		dpos				[integer!]
		size				[integer!]
	]

	read-header: func [
		fdata			[byte-ptr!]
		flen			[integer!]
		format			[WAV-FORMAT!]
		return:			[integer!]
		/local
			src			[byte-ptr!]
			csize		[integer!]
			csize2		[integer!]
			temp		[integer!]
			chs			[integer!]
			rate		[integer!]
			brate		[integer!]
			align		[integer!]
			bits		[integer!]
			dpos		[integer!]
	][
		if flen <= 44 [return -1]
		src: fdata
		unless all [
			fdata/1 = #"R"
			fdata/2 = #"I"
			fdata/3 = #"F"
			fdata/4 = #"F"
		][return -2]
		fdata: fdata + 4
		csize: as integer! fdata/1
		csize: (as integer! fdata/2) << 8 + csize
		csize: (as integer! fdata/3) << 16 + csize
		csize: (as integer! fdata/4) << 24 + csize
		if csize <= 36 [return -3]
		fdata: fdata + 4
		unless all [
			fdata/1 = #"W"
			fdata/2 = #"A"
			fdata/3 = #"V"
			fdata/4 = #"E"
		][return -4]
		fdata: fdata + 4
		unless all [
			fdata/1 = #"f"
			fdata/2 = #"m"
			fdata/3 = #"t"
			fdata/4 = #" "
		][return -5]
		fdata: fdata + 4
		csize2: as integer! fdata/1
		csize2: (as integer! fdata/2) << 8 + csize2
		csize2: (as integer! fdata/3) << 16 + csize2
		csize2: (as integer! fdata/4) << 24 + csize2
		if csize2 < 16 [return -6]
		fdata: fdata + 4
		temp: as integer! fdata/1
		temp: (as integer! fdata/2) << 8 + temp
		if temp <> 1 [return -7]		;-- PCM <> 1, indicate some form of compression
		chs: as integer! fdata/3
		chs: (as integer! fdata/4) << 8 + chs
		format/channels: chs			;- Mono = 1, Stereo = 2, etc.
		rate: as integer! fdata/5
		rate: (as integer! fdata/6) << 8 + rate
		rate: (as integer! fdata/7) << 16 + rate
		rate: (as integer! fdata/8) << 24 + rate
		format/sample-rate: rate
		brate: as integer! fdata/9
		brate: (as integer! fdata/10) << 8 + brate
		brate: (as integer! fdata/11) << 16 + brate
		brate: (as integer! fdata/12) << 24 + brate
		align: as integer! fdata/13
		align: (as integer! fdata/14) << 8 + align
		bits: as integer! fdata/15
		bits: (as integer! fdata/16) << 8 + bits
		format/sample-bits: bits
		if align <> (chs * bits / 8) [return -8]
		if brate <> (rate * chs * bits / 8) [return -9]
		fdata: fdata + csize2
		unless all [
			fdata/1 = #"d"
			fdata/2 = #"a"
			fdata/3 = #"t"
			fdata/4 = #"a"
		][return -10]
		temp: as integer! fdata/5
		temp: (as integer! fdata/6) << 8 + temp
		temp: (as integer! fdata/7) << 16 + temp
		temp: (as integer! fdata/8) << 24 + temp
		format/size: temp
		fdata: fdata + 8
		dpos: as integer! fdata - src
		format/dpos: dpos
		if flen <> (dpos + temp) [return -11]
		if csize <> (flen - 8) [return -12]
		0
	]

	load: func [
		data		[red-binary!]
		obj			[red-object!]
		/local
			bin		[byte-ptr!]
			len		[integer!]
			fmt		[WAV-FORMAT! value]
			vals	[red-value!]
			dt		[red-datatype!]
	][
		bin: binary/rs-head data
		len: binary/rs-length? data
		read-header bin len :fmt

		vals: object/get-values obj
		integer/make-at vals + AUDIO_OBJ_RATE fmt/sample-rate
		integer/make-at vals + AUDIO_OBJ_CHANNELS fmt/channels
		integer/make-at vals + AUDIO_OBJ_BITS fmt/sample-bits
		dt: as red-datatype! vals + AUDIO_OBJ_SAMPLE_TYPE
		dt/header: TYPE_DATATYPE
		dt/value: TYPE_INTEGER
		binary/load-at vals + AUDIO_OBJ_DATA bin + fmt/dpos fmt/size
	]
]