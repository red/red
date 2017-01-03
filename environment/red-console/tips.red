Red [
	Title:	 "Red Tips Widget"
	Author:	 "Xie Qingtian"
	File:	 %tips.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Xie Qingtian. All rights reserved."
]

tips!: make face! [
	type: 'base color: blue offset: 0x0 size: 200x300
	;flags: [scrollable]

	actors: object [
		on-key-down: func [face [object!] event [event!]][
			probe event/key
		]
	]
]