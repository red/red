Red [
	Title:   "Redbin codec"
	Author:  "Vladimir Vasilyev"
	File:	 %redbin.red
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

put system/codecs 'redbin context [
	title: "Redbin codec"
	name:  'Redbin
	mime-type: []
	suffixes:  [%.redbin]
	
	encode: routine [data [any-type!] where [any-type!]][
		stack/set-last as red-value! redbin/encode data
	]
	
	decode: routine [
		payload [any-type!]
		/local
			blk [red-block!]
			bin [red-binary!]
	][
		switch TYPE_OF(payload) [
			TYPE_URL
			TYPE_FILE [
				payload: actions/read* -1 -1 1 -1 -1 -1
			]
			TYPE_BINARY [0]
			default [fire [TO_ERROR(script invalid-data) payload]]
		]
		
		bin: as red-binary! payload
		assert TYPE_OF(bin) = TYPE_BINARY
		if 16 >= binary/rs-length? bin [fire [TO_ERROR(script invalid-data) payload]]
		
		blk: block/push-only* 0
		redbin/codec?: yes
		redbin/decode binary/rs-head bin blk yes
		if 1 = block/rs-length? blk [blk: as red-block! block/rs-head blk]
		
		SET_RETURN(blk)
	]
]
