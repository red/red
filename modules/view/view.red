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

face!: object [				;-- keep in sync with facet! enum
	type:		none
	offset:		none
	size:		none
	text:		none
	image:		none
	color:		none
	data:		none
	visible?:	none
	parent:		none
	pane:		none
	state:		none		;-- [handle [integer! none!] visible [logic!]]
	;rate:		none		;@@ to be considered
	edge:		none
	actors:		none
	extra:		none		;-- for storing optional user data
	
	on-change*: func [w o n][
		if all [state w <> 'state][
			state/2: state/2 or select [
				type		80000000h
				offset		40000000h
				size		20000000h
				text		10000000h
				image		08000000h
				color		04000000h
				data		02000000h
				visible?	01000000h
				parent		00800000h
				pane		00400000h
				rate		00200000h
				edge		00100000h
				actors		00080000h
				extra		00040000h
			] w
		]
	]
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
#include %VID.red

do-events: func [/no-wait][
	system/view/platform/do-event-loop no
]

show: function [face [object!] /with parent [object!]][
	either all [face/state face/state/1][
		if face/state/2 <> 0 [system/view/platform/update-view face]
	][
		new?: yes
		if face/type <> 'screen [
			p: either with [parent/state/1][0]
			obj: system/view/platform/make-view face face/type face/text face/offset face/size p

			if face/type = 'window [
				append system/view/screens/1/pane face
			]
		]
		face/state: reduce [obj 0 0]
	]

	if face/pane [foreach f face/pane [show/with f face]]
	
	if all [new? face/type = 'window][
		system/view/platform/show-window obj
	]
]

system/view/platform/init