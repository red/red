Red [
	Title:	 "Red Tips Widget"
	Author:	 "Xie Qingtian"
	File:	 %tips.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Xie Qingtian. All rights reserved."
]

tips!: make face! [
	type: 'panel color: 0.0.128 offset: 0x0 size: 150x200

	actors: object [
		on-key-down: func [face [object!] event [event!]][
			probe event/key
		]
	]
]