Red [
	Title:	"View engine high-level interface"
	Author: "Nenad Rakocevic"
	File: 	%view.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

face!: object [
	type:		none
	offset:		none
	size:		none
	text:		none
	image:		none
	data:		none
	visible?:	none
	parent:		none
	pane:		none
	state:		none		;-- [handle [integer! none!] visible [logic!]]
	;rate:		none		;@@ to be considered
	edge:		none
	actors:		none
	extra:		none		;-- for storing optional user data
]

system/view: context [
	screens: 	none
	event-port: none
	handlers: 	none

	metrics: object [
		screen-size: 	none
		dpi:			none
		;scaling:		1x1
	]

	platform: none	
	VID: none
	
	awake: func [event [event!]][						;@@ temporary until event:// is implemented
		print [
			"event> type:"	event/type
			"offset:"		event/offset
			"key:"			event/key
		]
	]

]

;#include %backends/android.red
#include %backends/windows.red

do-events: func [/no-wait][
	system/view/platform/do-event-loop no
]

show: func [face [object!]][
	system/view/platform/show face
]

system/view/platform/init