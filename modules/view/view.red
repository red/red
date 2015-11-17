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
	event/init
]

on-face-deep-change*: function [owner word target action new index part state forced?][
	if system/view/debug? [
		print [
			"-- on-deep-change event --" 		 lf
			tab "owner      :" owner/type		 lf
			tab "action     :" action			 lf
			tab "word       :" word				 lf
			tab "target type:" mold type? target lf
			tab "new value  :" mold type? new	 lf
			tab "index      :" index			 lf
			tab "part       :" part				 lf
			tab "forced?    :" forced?
		]
	]
	if all [state word <> 'state][
		either any [
			forced?
			system/view/auto-sync?
			owner/type = 'screen						;-- not postponing windows events
		][
			state/2: state/2 or (1 << ((index? in owner word) - 1))
			
			either word = 'pane [
				either find [remove clear take] action [
					either owner/type = 'screen [
						until [
							face: target/1
							if face/type = 'window [
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
						if all [
							find [tab-panel window panel] owner/type
							not find [cleared removed taken] action 
						][
							nb: part
							faces: skip head target index	;-- zero-based absolute index
							until [
								face: faces/1
								if owner/type = 'tab-panel [
									face/visible?: no
									face/parent: owner
								]
								show/with face owner
								faces: next faces
								zero? nb: nb - 1
							]
						]
						unless forced? [show owner]
						system/view/platform/on-change-facet owner word target action new index part
					]
				]
			][
				if owner/type <> 'screen [
					system/view/platform/on-change-facet owner word target action new index part
				]
			]
			check-reactions owner 'word
		][
			unless find [cleared removed taken] action [
				if find [clear remove take] action [
					target: copy/part target part
				]
				reduce/into
					[owner word target action new index part state]
					tail any [state/3 state/3: make block! 28] ;-- 7 slots * 4
			]
		]
	]
]

link-tabs-to-parent: function [face [object!]][
	if faces: face/pane [
		forall faces [
			if face/selected <> index? faces [faces/1/visible?: no]
			faces/1/parent: face
		]
	]
]

link-sub-to-parent: function [face [object!] type [word!] old new][
	if all [
		object? new
		parent: in new 'parent
		block? get parent
	][
		append parent face
		all [
			object? old
			parent: in new 'parent
			block? get parent
			remove find parent face
		]
	]
]

update-font-faces: function [parent [block! none!]][
	if block? parent [
		foreach f parent [
			if f/state [
				check-reactions f 'font
				f/state/2: f/state/2 or 00040000h		;-- (1 << ((index? in f 'font) - 1))
				if system/view/auto-sync? [show f]
			]
		]
	]
]

check-all-reactions: function [face [object!]][
	unless empty? pos: system/view/reactors [
		while [pos: find pos face][							;@@ /skip 4 fails
			do pos/3
			pos: skip pos 4
		]
	]
]

check-reactions: function [face [object!] facet [word!]][
	unless empty? pos: system/view/reactors [
		while [
			all [
				pos: find pos face							;@@ /skip 4 fails
				pos/2 = facet
			]
		][
			do pos/3
			pos: skip pos 4
		]
	]
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
	flags:		none
	options:	none
	parent:		none
	pane:		none
	state:		none		;-- [handle [integer! none!] change-array [integer!] deferred [block! none!] drag-offset [pair! none!]]
	;rate:		none		;@@ to be considered
	edge:		none
	para:		none
	font:		none
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
			if word = 'pane [
				if type = 'tab-panel [link-tabs-to-parent self]	;-- needs to be before `clear old`
				if block? old [clear head old]			;-- destroy old faces
			]
			if any [series? old object? old][modify old 'owned none]
			if any [series? new object? new][modify new 'owned reduce [self word]]
			
			if word = 'font [link-sub-to-parent self 'font old new]
			if word = 'para [link-sub-to-parent self 'para old new]

			check-reactions self word
			
			if state [
				;if word = 'type [cause-error 'script 'locked-word [type]]
				state/2: state/2 or (1 << ((index? in self word) - 1))
				if all [state/1 system/view/auto-sync?][show self]
			]
		]
	]
	
	on-deep-change*: function [owner word target action new index part][
		on-face-deep-change* owner word target action new index part state no
	]
]

font!: object [											;-- keep in sync with font-facet! enum
	name:		 none
	size:		 none
	style:		 none
	angle:		 0
	color:		 black
	anti-alias?: none
	shadow:		 none
	state:		 none
	parent:		 none
	
	on-change*: function [word old new][
		if system/view/debug? [
			print [
				"-- font on-change event --" lf
				tab "word :" word			 lf
				tab "old  :" type? old		 lf
				tab "new  :" type? new
			]
		]
		if word <> 'state [
			if any [series? old object? old][modify old 'owned none]
			if any [series? new object? new][modify new 'owned reduce [self word]]

			if all [block? state integer? state/1][ 
				system/view/platform/update-font self (index? in self word) - 1
				update-font-faces parent
			]
		]
	]
	
	on-deep-change*: function [owner word target action new index part][
		if all [
			state
			word <> 'state
			not find [remove clear take] action
		][
			system/view/platform/update-font self (index? in self word) - 1
			update-font-faces parent
		]
	]	
]

para!: object [
	origin: 	none
	padding:	none
	scroll:		none
	align:		none
	v-align:	none
	wrap?:		no
	parent:		none
	
	on-change*: function [word old new][
		if system/view/debug? [
			print [
				"-- para on-change event --" lf
				tab "word :" word			 lf
				tab "old  :" type? old		 lf
				tab "new  :" type? new
			]
		]
		if all [
			not find [state parent] word
			block? parent
		][
			foreach f parent [
				check-reactions f 'para
				system/view/platform/update-para f (index? in self word) - 1 ;-- sets f/state flag too
				if all [f/state f/state/1 system/view/auto-sync?][show f]
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
	
	handlers: make block! 10
	reactors: make block! 100
	
	evt-names: make hash! [
		down			on-down
		up				on-up
		middle-down		on-mid-down
		middle-up		on-mid-up
		alt-down		on-alt-down
		alt-up			on-alt-up
		aux-down		on-aux-down
		aux-up			on-aux-up
		drag-start		on-drag-start
		drag			on-drag
		drop			on-drop
		click			on-click
		double-click	on-dbl-click
		over			on-over
		key				on-key
		key-up			on-key-up
		select			on-select
		change			on-change
		menu			on-menu
		close			on-close
		move			on-move
		resize			on-size
		moving			on-moving
		resizing		on-resizing
		zoom			on-zoom
		pan				on-pan
		rotate			on-rotate
		two-tap			on-two-tap
		press-tap		on-press-tap
	]
	
	awake: function [event [event!] /with face][		;@@ temporary until event:// is implemented
		unless face [unless face: event/face [exit]]	;-- filter out unbound events
		
		if face/parent [
			set/any 'result system/view/awake/with event face/parent ;-- event bubbling
			if :result = 'stop [return 'stop]
		]
		type: event/type
		
		foreach handler handlers [
			set/any 'result do [handler face event]
			if :result [return :result]
		]
		
		set/any 'result do-actor face event type
		
		if all [type = 'close :result <> 'continue][
			windows: head remove find system/view/screens/1/pane face
			result: pick [stop done] tail? windows
		]	
		:result
	]
	
	auto-sync?: yes
	debug?: no
]

#include %backends/platform.red
#include %draw.red
#include %VID.red

do-events: func [/no-wait][
	system/view/platform/do-event-loop no
]

do-actor: function [face [object!] event [event! none!] type [word!]][
	if all [
		object? face/actors
		act: in face/actors name: select system/view/evt-names type
		act: get act
	][
		if system/view/debug? [print ["calling actor:" name]]
		
		if error? set/any 'result try/all [do [act face event]][ ;-- compiler can't call act, hence DO			
			print :result
			result: none
		]
	]
	:result
]

show: function [
	"Display a new face or update it"
	face [object! block!] "Face object to display"
	/with				  "Link the face to a parent face"
		parent [object!]  "Parent face to link to"
][
	if block? face [
		foreach f face [
			if word? f [f: get f]
			if object? f [show f]
		]
		exit
	]
	if system/view/debug? [print ["show:" face/type " with?:" with]]
	
	either all [face/state face/state/1][
		pending: face/state/3
		
		if all [pending not empty? pending][
			foreach [owner word target action new index part state] pending [
				on-face-deep-change* owner word target action new index part state yes
			]
			clear pending
		]
		if face/state/2 <> 0 [system/view/platform/update-view face]
	][
		new?: yes
		
		if face/type <> 'screen [
			if all [not parent not object? face/parent face/type <> 'window][
				cause-error 'script 'not-linked []
			]
			if all [object? face/actors in face/actors 'on-create][
				do [face/actors/on-create face none]
			]
			p: either with [parent/state/1][0]
			obj: system/view/platform/make-view face p
			if with [face/parent: parent]
			
			if all [
				para: face/para
				p: in face/para parent
			][
				either block? p [append p face][face/para/parent: reduce [face]]
			]
			
			switch face/type [
				tab-panel [link-tabs-to-parent face]
				window	  [append system/view/screens/1/pane face]
			]
		]
		face/state: reduce [obj 0 none none]
	]

	if face/pane [foreach f face/pane [show/with f face]]
	check-all-reactions face
	
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

view: function [
	"Displays a window view from a layout block or from a window face"
	spec [block! object!]	"Layout block or face object"
	/options
		opts [block!]		"Optional features"
	;/modal					"Display a modal window (pop-up)"
	/no-wait				"Return immediately - do not wait"
][
	unless system/view/screens [system/view/platform/init]
	
	if block? spec [spec: layout spec]
	if spec/type <> 'window [cause-error 'script 'not-window []]
	
	unless spec/text   [spec/text: "Red: untitled"]
	unless spec/offset [center-face spec]
	show spec
	
	unless no-wait [do-events]
]

center-face: function [
	"Center a face inside its parent"
	face [object!]		 "Face to center"
	/with				 "Provide a reference face for centering instead of parent face"
		parent [object!] "Reference face"
][
	unless parent [
		parent: either face/type = 'window [
			system/view/screens/1						;@@ to be improved for multi-display support
		][
			face/parent
		]
	]
	either parent [
		face/offset: parent/size - face/size / 2
	][
		print "CENTER-FACE: face has no parent!"		;-- temporary check
	]
]

dump-face: function [
	"Display debugging info about a face and its children"
	face [object!] "Face to analyze"
][
	depth: ""
	print [
		depth "Style:" face/type "Offset:" face/offset "Size:" face/size
		"Text:" if face/text [mold/part face/text 20]
	]
	append depth tab
	if block? face/pane [foreach f face/pane [dump-face f]]
	remove depth
	face
]

insert-event-func: function [
	"Add a function to monitor global events. Return the function"
	fun [block! function!] "A function or a function body block"
][
	if block? :fun [fun: do [function [face event] fun]]	;@@ compiler chokes on 'function call
	insert system/view/handlers :fun
	:fun
]

remove-event-func: function [
	"Remove an event function previously added"
	fun [function!]
][
	remove find system/view/handlers :fun
]

;=== Global handlers ===

;-- Dragging face handler --
insert-event-func [
	if all [
		block? face/options
		drag-evt: face/options/drag-on
	][
		type: event/type
		either type = drag-evt [
			either block? flags: face/flags [
				unless find flags 'all-over [append flags 'all-over]
			][
				if flags <> 'all-over [
					face/flags: either flags [reduce [flags 'all-over]]['all-over]
				]
			]
			face/state/4: event/offset
			do-actor face event 'drag-start
		][
			if drag-offset: face/state/4 [
				either type = 'over [
					unless event/away? [
						new: face/offset + event/offset - drag-offset
						if face/offset <> new [
							face/offset: new
							return do-actor face event 'drag ;-- avoid calling on-over actor
						]
					]
				][
					if drag-evt = select [
						up		down
						mid-up	mid-down
						alt-up	alt-down
						aux-up	aux-down
					] type [
						do-actor face event 'drop
						face/state/4: none
					]
				]
			]
		]
	]
	none
]

;-- Debug info handler --
insert-event-func [
	if all [system/view/debug? face = event/face][
		print [
			"event> type:"	event/type
			"offset:"		event/offset
			"key:"			mold event/key
			either find [key key-up] event/type [reduce ["flags:" mold event/flags]][""]
		]
	]
	none
]

;-- Radio faces handler --
insert-event-func [
	if all [
		event/type = 'click
		face/type = 'radio
	][
		foreach f face/parent/pane [if f/type = 'radio [f/data: off show f]]
		face/data: on
		event/type: 'change
		show face
	]
	none
]

;-- Reactors support handler --
insert-event-func [
	if all [
		event/type = 'change
		face/type = 'slider
	][
		check-reactions face 'data
	]
]