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

event?: routine [value [any-type!] return: [logic!]][TYPE_OF(value) = TYPE_EVENT]

size-text: function [
	"Returns the area size of the text in a face"
	face	 [object!]		"Face containing the text to size"
	/with 					"Provide a text string instead of face/text"
		text [string!]		"Text to measure"
	return:  [pair! none!]	"Return the text's size or NONE if failed"
][
	system/view/platform/size-text face text
]

set-flag: function [
	face  [object!]
	facet [word!]
	value [any-type!]
][
	either flags: face/:facet [
		if word? flags [flags: reduce [flags]]
		either block? flags [append flags value][set in face facet value]
	][
		set in face facet value
	]
]

find-flag?: routine [
	facet	[any-type!]
	flag 	[word!]
	/local
		word   [red-word!]
		value  [red-value!]
		tail   [red-value!]
		bool   [red-logic!]
		found? [logic!]
][
	switch TYPE_OF(facet) [
		TYPE_WORD  [
			word: as red-word! facet
			found?: EQUAL_WORDS?(flag word)
		]
		TYPE_BLOCK [
			found?: no
			value: block/rs-head as red-block! facet
			tail:  block/rs-tail as red-block! facet
			
			while [all [not found? value < tail]][
				if TYPE_OF(value) = TYPE_WORD [
					word: as red-word! value
					found?: EQUAL_WORDS?(flag word)
				]
				value: value + 1
			]
		]
		default [found?: no]
	]
	bool: as red-logic! stack/arguments
	bool/header: TYPE_LOGIC
	bool/value:	 found?
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
	if all [state word <> 'state word <> 'extra][
		either any [
			forced?
			system/view/auto-sync?
			owner/type = 'screen						;-- not postponing windows events
		][
			state/2: state/2 or (1 << ((index? in owner word) - 1))
			
			either word = 'pane [
				case [
					action = 'moved [
						nb: part
						faces: skip head target index	;-- zero-based absolute index				
						until [
							faces/1/parent: owner
							faces: next faces
							zero? nb: nb - 1
						]
						;unless forced? [show owner]
						system/view/platform/on-change-facet owner word target action new index part
					]
					find [remove clear take change] action [
						either owner/type = 'screen [
							until [
								face: target/1
								if face/type = 'window [
									modal?: find-flag? face/flags 'modal
									system/view/platform/destroy-view face face/state/4

									if all [modal? not empty? head target][
										pane: target
										until [
											pane: back pane
											pane/1/enable?: yes
											unless system/view/auto-sync? [show pane/1]
											any [head? pane find-flag? pane/1/flags 'modal]
										]
									]
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
					]
					'else [
						if owner/type <> 'screen [
							if all [
								find [tab-panel window panel] owner/type
								not find [cleared removed taken move] action 
							][
								nb: part
								faces: skip head target index	;-- zero-based absolute index
								until [
									face: faces/1
									if owner/type = 'tab-panel [
										face/visible?: no
										face/parent: owner
									]
									if all [owner/type = 'window face/type = 'window][
										cause-error 'script 'bad-window []
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
				]
			][
				if owner/type <> 'screen [
					if all [find [field text] owner/type word = 'text][
						set-quiet in owner 'data any [
							all [not empty? owner/text attempt/safer [load owner/text]]
							all [owner/options owner/options/default]
						]
					]
					system/view/platform/on-change-facet owner word target action new index part
				]
			]
			system/reactivity/check/only owner word
		][
			if any [								;-- drop multiple changes on same facet
				none? state/3
				find [data options pane flags] word
				not find/skip next state/3 word 8
			][
				unless find [cleared removed taken] action [
					if find [clear remove take] action [
						target: copy/part target part
					]
					reduce/into
						[owner word target action new index part state]
						tail any [state/3 state/3: make block! 28] ;-- 8 slots * 4
				]
			]
		]
	]
]

link-tabs-to-parent: function [face [object!]][
	if faces: face/pane [
		visible?: face/visible?
		forall faces [
			faces/1/visible?: make logic! all [visible? face/selected = index? faces]
			faces/1/parent: face
		]
	]
]

link-sub-to-parent: function [face [object!] type [word!] old new][
	if object? new [
		unless all [parent: in new 'parent block? get parent][
			new/parent: make block! 4
		]
		append new/parent face
		all [
			object? old
			parent: in old 'parent
			block? parent: get parent
			remove find parent face
		]
	]
]

update-font-faces: function [parent [block! none!]][
	if block? parent [
		foreach f parent [
			if f/state [
				system/reactivity/check/only f 'font
				f/state/2: f/state/2 or 00080000h		;-- (1 << ((index? in f 'font) - 1))
				show f
			]
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
	rate:		none
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
		if all [word <> 'state word <> 'extra][
			if word = 'pane [
				if all [type = 'window object? new new/type = 'window][
					cause-error 'script 'bad-window []
				]
				same-pane?: all [block? old block? new same? head old head new]
				if type = 'tab-panel [link-tabs-to-parent self]		;-- needs to be before `clear old`
				if all [not same-pane? block? old not empty? old][clear head old]	;-- destroy old faces
			]
			if all [not same-pane? any [series? old object? old]][modify old 'owned none]
			
			unless any [same-pane? find [font para edge actors extra] word][
				if any [series? new object? new][modify new 'owned reduce [self word]]
			]
			if word = 'font  [link-sub-to-parent self 'font old new]
			if word = 'para  [link-sub-to-parent self 'para old new]
			if find [field text] type [
				if word = 'text [
					set-quiet 'data any [
						all [not empty? new attempt/safer [load new]]
						all [options options/default]
					]
				]
				if 'data = word [
					either data [
						if string? text [modify text 'owned none]
						set-quiet 'text form data		;@@ use form/into (avoids rebinding)
						modify text 'owned reduce [self 'text]
					][
						clear text
					]
					saved: 'data
					word: 'text							;-- force text refresh
				]
			]

			system/reactivity/check/only self any [saved word]
			
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
	color:		 none
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
				system/reactivity/check/only f 'para
				system/view/platform/update-para f (index? in self word) - 1 ;-- sets f/state flag too
				if all [f/state f/state/1][show f]
			]
		]
	]
]

system/view: context [
	screens: 	none
	event-port: none

	metrics: object [
		screen-size: 	none
		dpi:			none
		;scaling:		1x1
	]

	platform: none	
	VID: none
	
	handlers: make block! 10
	
	evt-names: make hash! [
		detect			on-detect
		time			on-time
		down			on-down
		up				on-up
		mid-down		on-mid-down
		mid-up			on-mid-up
		alt-down		on-alt-down
		alt-up			on-alt-up
		aux-down		on-aux-down
		aux-up			on-aux-up
		drag-start		on-drag-start
		drag			on-drag
		drop			on-drop
		click			on-click
		dbl-click		on-dbl-click
		over			on-over
		key				on-key
		key-down		on-key-down
		key-up			on-key-up
		focus			on-focus
		unfocus			on-unfocus
		select			on-select
		change			on-change
		enter			on-enter
		menu			on-menu
		close			on-close
		move			on-move
		resize			on-resize
		moving			on-moving
		resizing		on-resizing
		zoom			on-zoom
		pan				on-pan
		rotate			on-rotate
		two-tap			on-two-tap
		press-tap		on-press-tap
		create			on-create						;-- generated by VID only
	]
	
	capture-events: function [face [object!] event [event!] /local result][
		if face/parent [
			set/any 'result capture-events face/parent event
			if find [stop done] :result [return :result]
		]
		if capturing? [
			set/any 'result do-actor face event 'detect
			if find [stop done] :result [return :result]
		]
	]
	
	awake: function [event [event!] /with face result][	;@@ temporary until event:// is implemented
		unless face [unless face: event/face [exit]]	;-- filter out unbound events
		
		unless with [									;-- protect following code from recursion
			foreach handler handlers [
				set/any 'result do-safe [handler face event]
				either event? :result [event: result][if :result [return :result]]
			]
			set/any 'result capture-events face event	;-- event capturing
			if find [stop done] :result [return :result]
		]
		
		set/any 'result do-actor face event event/type
		
		if all [face/parent :result <> 'done][
			set/any 'result system/view/awake/with event face/parent ;-- event bubbling
			if :result = 'stop [return 'stop]
		]
		
		if all [event/type = 'close :result <> 'continue][
			result: pick [stop done] face/state/4		;-- face/state will be none after remove call
			remove find head system/view/screens/1/pane face
		]	
		:result
	]
	
	capturing?: no
	auto-sync?: yes
	debug?: no
]

#include %backends/platform.red
#include %draw.red
#include %VID.red

do-events: function [
	"Launch the event loop, blocks until all windows are closed"
	/no-wait			   "Process an event in the queue and returns at once"
	return: [logic! word!] "Returned value from last event"
	/local result
][
	win: last system/view/screens/1/pane
	win/state/4: not no-wait							;-- mark the window from which the event loop starts
	set/any 'result system/view/platform/do-event-loop no-wait
	:result
]

do-safe: func [code [block!] /local result][
	if error? set/any 'result try/all code [
		print :result
		result: none
	]
	get/any 'result
]

do-actor: function [face [object!] event [event! none!] type [word!] /local result][
	if all [
		object? face/actors
		act: in face/actors name: select system/view/evt-names type
		act: get act
	][
		if system/view/debug? [print ["calling actor:" name]]
		
		set/any 'result do-safe [do [act face event]]	;-- compiler can't call act, hence DO
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
			if any [series? face/extra object? face/extra][
				modify face/extra 'owned none			;@@ TBD: unflag object's fields (ownership)
			]
			if all [object? face/actors in face/actors 'on-create][
				do-safe [face/actors/on-create face none]
			]
			p: either with [parent/state/1][0]
			obj: system/view/platform/make-view face p
			if with [face/parent: parent]
			
			foreach field [para font][
				if all [field: face/:field p: in field 'parent][
					either block? p: get p [
						unless find p face [append p face]
					][
						field/parent: reduce [face]
					]
				]
			]
			
			switch face/type [
				tab-panel [link-tabs-to-parent face]
				window	  [
					pane: system/view/screens/1/pane
					if find-flag? face/flags 'modal [
						foreach f head pane [
							f/enable?: no
							unless system/view/auto-sync? [show f]
						]
					]
					append pane face
				]
			]
		]
		face/state: reduce [obj 0 none false]
	]

	if face/pane [
		foreach f face/pane [show/with f face]
		system/view/platform/refresh-window face/state/1
	]
	;check-all-reactions face
	
	if all [new? face/type = 'window face/visible?][
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
	svs: system/view/screens/1
	if empty? pane: svs/pane [exit]
	
	case [
		only  [remove find head pane face]
		all?  [while [not tail? pane][remove back tail pane]]
		'else [remove back tail pane]
	]
]

view: function [
	"Displays a window view from a layout block or from a window face"
	spec [block! object!]	"Layout block or face object"
	/tight					"Zero offset and origin"
	/options
		opts [block!]		"Optional features in [name: value] format"
	/flags
		flgs [block! word!]	"One or more window flags"
	;/modal					"Display a modal window (pop-up)"
	/no-wait				"Return immediately - do not wait"
][
	unless system/view/screens [system/view/platform/init]
	
	if block? spec [spec: either tight [layout/tight spec][layout spec]]
	if spec/type <> 'window [cause-error 'script 'not-window []]
	if options [set spec make object! opts]
	if flags [spec/flags: either spec/flags [unique union spec/flags flgs][flgs]]
	
	unless spec/text   [spec/text: "Red: untitled"]
	unless spec/offset [center-face spec]
	show spec
	
	either no-wait [spec][do-events ()]					;-- return unset! value by default
	
]

center-face: function [
	"Center a face inside its parent"
	face [object!]		 "Face to center"
	/with				 "Provide a reference face for centering instead of parent face"
		parent [object!] "Reference face"
	return: [object!]	 "Returns the centered face"
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
		if face/type = 'window [face/offset: face/offset + parent/offset]
	][
		print "CENTER-FACE: face has no parent!"		;-- temporary check
	]
	face
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
	append depth "    "
	if block? face/pane [foreach f face/pane [dump-face f]]
	remove/part depth 4
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
	remove find/same system/view/handlers :fun
]

request-font: function [
	"Requests a font object"
	/mono			"Show monospaced font only"
][
	system/view/platform/request-font make font! [] mono
]

;=== Global handlers ===

;-- Dragging face handler --
insert-event-func [
	if all [
		block? event/face/options
		drag-evt: event/face/options/drag-on
	][
		face: event/face
		type: event/type
		either type = drag-evt [
			face/flags: any [
				all [not block? flags: face/flags :flags reduce [:flags 'all-over]] 
				all [flags append flags 'all-over]
				'all-over
			]
			do-actor face event 'drag-start
			face/state/4: event/offset
			unless system/view/auto-sync? [show face]
		][
			if drag-offset: face/state/4 [
				either type = 'over [
					unless event/away? [
						new: face/offset + event/offset - drag-offset
						if face/offset <> new [
							result: none				;-- for local context capturing
							face/offset: new
							set/any 'result do-actor face event 'drag ;-- avoid calling on-over actor
							unless system/view/auto-sync? [show face]
							return :result
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
						if face/state [face/state/4: none]
						face/flags: all [
							block? flags: face/flags
							remove find flags 'all-over
							flags
						]
					]
				]
			]
		]
	]
	none
]

;-- Debug info handler --
insert-event-func [
	if all [
		system/view/debug?
		not all [
			value? 'gui-console-ctx
			any [
				event/face = gui-console-ctx/console
				event/face = gui-console-ctx/win
			]
		]
	][
		print [
			"event> type:"	event/type
			"offset:"		event/offset
			"key:"			mold event/key
			"flags:" 		mold event/flags
		]
	]
	none
]

;-- 'enter event handler --
insert-event-func [
	all [
		event/type = 'key
		find "^M^/" event/key
		find [field drop-down] event/face/type
		event/type: 'enter
	]
	event
]

;-- Radio faces handler --
insert-event-func [
	if all [
		event/type = 'click
		event/face/type = 'radio
	][
		foreach f event/face/parent/pane [if f/type = 'radio [f/data: off show f]]
		event/face/data: on
		event/type: 'change
	]
	event
]

;-- Reactors support handler --
insert-event-func [
	if find [change enter unfocus] event/type [
		face: event/face
		facet: switch/default face/type [
			slider		['data]
			check		['data]
			radio		['data]
			tab-panel	['data]
			field		['text]
			area		['text]
			drop-down	['text]
			text-list	['selected]
			drop-list	['selected]
		][none]
		
		if facet [system/reactivity/check/only face facet]
	]
	none
]

;-- Field's data facet syncing handler
insert-event-func [
	if all [
		find [change] event/type
		event/face/type = 'field
	][
		face: event/face
		set-quiet in face 'data any [
			all [not empty? face/text attempt/safer [load face/text]]
			all [face/options face/options/default]
		]
		system/reactivity/check/only face 'data
	]
]
