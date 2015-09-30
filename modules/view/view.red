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

#system [
	#include %../../runtime/datatypes/event.reds
]

face!: object [				;-- keep in sync with facet! enum
	type:		'face
	offset:		none
	size:		none
	text:		none
	image:		none
	color:		none
	menu:		none
	data:		none
	enable?:	yes
	visible?:	yes
	selected:	none
	parent:		none
	pane:		none
	state:		none		;-- [handle [integer! none!] change-array [integer!]]
	;rate:		none		;@@ to be considered
	edge:		none
	actors:		none
	extra:		none		;-- for storing optional user data
	draw:		none
	
	on-change*: function [word old new][
		if system/view/debug? [
			print [
				"-- on-change event --" lf
				tab "word :" word		lf
				tab "old  :" type? old	lf
				tab "new  :" type? new
			]
		]
		if word <> 'state [
			if system/view/auto-update? [
				if any [series? old object? old][modify old 'owned none]
				if any [series? new object? new][modify new 'owned reduce [self word]]
			]

			if state [
				;if word = 'type [cause-error 'script 'locked-word [type]]
				state/2: state/2 or probe system/view/platform/get-facet-id in self word
				if all [state/1 system/view/auto-update?][show self]
			]
		]
	]
	
	on-deep-change*: function [owner word target action index part][
		if system/view/debug? [
			print [
				"-- on-deep-change event --" 		 lf
				tab "owner      :" owner/type		 lf
				tab "action     :" action			 lf
				tab "word       :" word				 lf
				tab "target type:" mold type? target lf
				tab "index      :" index			 lf
				tab "part       :" part
			]
		]
		if all [state word <> 'state][
			state/2: state/2 or system/view/platform/get-facet-id word
			
			if system/view/auto-update? [
				either word = 'pane [
					either find [remove clear take] action [
						either owner/type = 'screen [
							until [
								face: target/1
								if face/type = 'window [
									if all [object? face/actors in face/actors 'on-close][
										do [face/actors/on-close face]
									]
									system/view/platform/destroy-view face tail? skip head target part
								]
								target: next target
								zero? part: part - 1
							]
						][
							until [
								face: target/1
								face/parent: none
								system/view/platform/destroy-view face no
								target: next target
								zero? part: part - 1
							]
						]
					][
						if owner/type <> 'screen [
							show owner
							system/view/platform/on-change-facet owner word target action index part
						]
					]
				][
					if owner/type <> 'screen [
						system/view/platform/on-change-facet owner word target action index part
					]
				]
			]
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
		select			on-select
		change			on-change
		menu			on-menu
		close			on-close
	)
	
	awake: function [event [event!]][					;@@ temporary until event:// is implemented
		unless face: event/face [exit]					;-- filter out unbound events
		type: event/type
		
		if all [										;-- radio styles handler
			type = 'click
			face/type = 'radio
		][
			foreach f face/parent/pane [
				if f/type = 'radio [f/data: off show f]
			]
			face/data: on
			type: 'change
			show face
		]

		if debug? [
			print [
				"event> type:"	event/type
				"offset:"		event/offset
				"key:"			mold event/key
				;"face:" 		mold event/face
			]
		]

		if all [
			object? face/actors
			act: in face/actors select evt-names type
			act: get act
		][
			if error? set/any 'result try/all [do [act face event]][ ;-- compiler can't call act, hence DO			
				print :result
				result: none
			]
		]
		
		if all [type = 'close :result <> 'continue][
			windows: head remove find system/view/screens/1/pane face
			result: pick [stop done] tail? windows
		]	
		:result
	]
	
	auto-update?: no
	debug?: yes
]

#include %backends/platform.red
#include %draw.red
#include %VID.red

do-events: func [/no-wait][
	system/view/platform/do-event-loop no
]

show: function [
	"Display a new face or update it"
	face [object!]		 "Face object to display"
	/with				 "Link the face to a parent face"
		parent [object!] "Parent face to link to"
][
	;if system/view/debug? [print ["show:" face/type " with?:" with]]
	
	either all [face/state face/state/1][
		if face/state/2 <> 0 [system/view/platform/update-view face]
	][
		new?: yes
		if face/type <> 'screen [
			if all [object? face/actors in face/actors 'on-make][
				do [face/actors/on-make face none]
			]
			p: either with [parent/state/1][0]
			obj: system/view/platform/make-view face p

			switch face/type [
				tab-panel [
					if faces: face/pane [
						forall faces [
							if face/selected <> index? faces [
								faces/1/visible?: no
							]
							faces/1/parent: face
						]
					]
				]
				radio	[if with [face/parent: parent]]
				window	[append system/view/screens/1/pane face]
			]
		]
		face/state: reduce [obj 0 0]
	]

	if face/pane [foreach f face/pane [show/with f face]]
	
	if all [new? face/type = 'window][
		system/view/platform/show-window obj
	]
]

unview: function [
	"Close last opened window view"
	/all  "Close all views"
	/only "Close a given view"
		face [object!] "Window view to close"
][
	if system/view/debug? [print ["unview: all:" :all "only:" only]]
	
	all?: :all											;-- compiler does not support redefining ALL
	if empty? pane: system/view/screens/1/pane [exit]
	
	case [
		only  [remove find pane face]
		all?  [while [not tail? pane][remove pane]]
		'else [remove back tail pane]
	]
]

#system [event/init]
system/view/platform/init