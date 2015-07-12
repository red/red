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
	evt-names: #(
		down			on-down
		up				on-up
		middle-down		on-mid-down
		middle-up		on-mid-up
		alt-down		on-alt-down
		alt-up			on-alt-up
		aux-down		on-aux-down
		aux-up			on-aux-up
		click			on-click
		double-click	on-dbl-click
		move			on-move
		key				on-key
		key-up			on-key-up
	)
	
	awake: function [event [event!]][					;@@ temporary until event:// is implemented
		if debug? [
			print [
				"event> type:"	event/type
				"offset:"		event/offset
				"key:"			mold event/key
				;"face:" 		mold event/face
			]
		]
		face: event/face
		
		if all [
			object? face/actors
			act: in face/actors select evt-names event/type
			act: get act
		][	
			do [act face event]
		]
	]

	debug?: yes
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