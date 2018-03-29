Red [
	Title:	 "Red Tips Widget"
	Author:	 "Xie Qingtian"
	File:	 %tips.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tips!: make face! [
	type: 'panel color: 0.0.128 offset: 0x0 size: 150x200

	actors: object [
		on-key-down: func [face [object!] event [event!]][
			probe event/key
		]
	]
]