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
	
	compact?: yes										;-- format used by `save`: yes = compact, no = default

	encode: function [data [any-type!] where [any-type!]][
		encode* data compact?
	]

	encode*: routine [data [any-type!] compact? [logic!]][
		either compact? [
			stack/set-last as red-value! redbin/encode-cp data
		][
			stack/set-last as red-value! redbin/encode data
		]
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
		if 10 >= binary/rs-length? bin [fire [TO_ERROR(script invalid-data) payload]]	;-- compact header can be as small as 11 bytes
		
		blk: block/push-only* 0
		redbin/codec?: yes
		redbin/decode binary/rs-head bin blk yes binary/rs-length? bin
		if 1 = block/rs-length? blk [blk: as red-block! block/rs-head blk]
		
		SET_RETURN(blk)
	]
]
