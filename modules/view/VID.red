Red [
	Title:   "Red View Interface Dialect"
	Author:  "Nenad Rakocevic"
	File: 	 %VID.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

;#include %backends/android.red
#include %backends/windows.red

at-offset: pad-offset: none

button-list: make block! 4

cursor: 	  [0 0 0x0]									;-- max-x|y, current-x|y, next-face-coordinates
direction: 	  'across
origin:	  	  10x10
spacing:	  10x10

face!: object [
	type:	 none
	offset:	 none
	size: 	 none
	text:	 none
	image:	 none
	parent:	 none
	pane:	 none
	state:	 none
	edge:	 none
	actors:  none
]

reset-cursor: does [
	either direction = 'across [
		cursor/3/x: origin/x
		cursor/3/y: cursor/3/y + cursor/1 + spacing/y
	][
		cursor/3/x: cursor/3/x + cursor/1 + spacing/x
		cursor/3/y: origin/y
	]
	cursor/2: cursor/1
	cursor/1: 0
]

make-face: func [
	parent [object! none!]
	type   [word!]
	opts   [block! none!]
	/local face value list offset
][
	face: make face! []
	face/type: type

	if opts [
		face/offset: any [opts/offset 0x0]
		face/size:   any [opts/size 100x80]
		face/text:	 opts/text
		
		if find opts 'action [
			face/actions: opts/action
		]
	]
	face/state: copy [#[none] #[false]]
	
	if parent [
		unless list: parent/pane [parent/pane: list: make block! 8]
		;face/parent: parent
		
		either at-offset [
			face/offset: at-offset
		][
			offset: either empty? list [origin][cursor/3]
			if pad-offset [offset: offset + pad-offset]
			face/offset: spacing
			
			either direction = 'across [
				face/offset/x: face/offset/x + offset/x + spacing/x
				face/offset/y: cursor/2 + spacing/y
				if face/size/y > cursor/1 [cursor/1: face/size/y]
			][
				face/offset/x: cursor/2 + spacing/x
				face/offset/y: face/offset/y + offset/y + spacing/y
				if face/size/x > cursor/1 [cursor/1: face/size/x]
			]
			cursor/3: offset + face/size + spacing
		]
		append/only list face
	]
	
	if type = 'button [append/only button-list opts/action]
	
	at-offset: pad-offset: none							;-- reset global flags
	face
]

root-face: make-face none 'screen none

view: func [
	spec [block!]
	/local pos arg arg2 options-rule opts value value2 current type action
][
	opts: []
	current: root-face
	
	options-rule: [
		(clear opts)
		any [
			(value2: none)
			set value [integer! | pair!] (
				append opts [size:]
				append/only opts either pair? value [value][
					make pair! probe reduce [value 80]
				]
			)
			| set value string! (
				append opts [text:]
				append opts value
			)
			| set action block! (
				append opts [action:]
				append/only opts action
			)
		]
	]
	
	parse spec [
		pos: any [
			;------ Positioning ------
			  'title	set arg string!
			| 'space	set arg pair!
			| 'origin	set arg pair!
			| 'across	(direction: 'across)
			| 'below	(direction: 'below)
			| 'return	(reset-cursor)
			| 'at		set at-offset pair!
			| 'pad 		set pad-offset pair!
			
			;------ Widgets ------
			| set type 'button options-rule (make-face current type opts)
			| set type 'text   options-rule (make-face current type opts)
			| set type 'field  options-rule (make-face current type opts)
			| set type 'check  options-rule (make-face current type opts)
			| set type 'radio  options-rule (make-face current type opts)
			| set type 'toggle options-rule (make-face current type opts)
			| set type 'clock  options-rule (make-face current type opts)
			;| set type 'calendar  options-rule (make-face current type opts)
		]
	]
	show root-face
	print "entering loop..."
	do-events
]

