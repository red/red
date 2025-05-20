Red [
	Title:	"View engine high-level interface"
	Author: "Nenad Rakocevic"
	File: 	%view.red
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [
	#include %../../runtime/datatypes/event.reds
	red/boot?: yes
	event/init
	red/boot?: no
]

#include %utils.red

event?: routine ["Returns true if the value is this type" value [any-type!] return: [logic!]][TYPE_OF(value) = TYPE_EVENT]

face?: function [
	"Returns TRUE if the value is a face! object"
	value	"Value to test"
	return:	[logic!]
][
	to logic! all [
		object? :value
		any [
			(class-of value) = class-of face!
			all [										;-- (temporary) fallback heuristic
				in value 'type
				in value 'offset
				in value 'size
				in value 'parent
				in value 'pane
				in value 'state
				in value 'para
				in value 'font
				in value 'actors
			]
		]
	]
]

get-current-screen: function [
	"Returns the screen face of the Display where the mouse cursor is currently located"
	return: [object!]	"Screen face"
][
	handle: system/view/platform/get-current-screen
	foreach screen system/view/screens [if screen/state/1 = handle [return screen]]
]

size-text: function [
	"Returns the area size of the text in a face"
	face	 [object!]		"Face containing the text to size"
	/with 					"Provide a text string instead of face/text"
		text [string!]		"Text to measure"
	return:  [point2D! none!]	"Return the text's size or NONE if failed"
][
	either face/type = 'rich-text [
		if block? h: face/handles [poke h length? h true]
		system/view/platform/text-box-metrics face 0 3
	][
		system/view/platform/size-text face text
	]
]

caret-to-offset: function [
	"Given a text position, returns the corresponding coordinate relative to the top-left of the layout box"
	face	[object!]
	pos		[integer!]
	/lower			"lower end offset of the caret"
	return:	[point2D!]
][
	opt: either lower [6][0]
	system/view/platform/text-box-metrics face pos opt
]

offset-to-caret: function [
	"Given a coordinate, returns the corresponding caret position"
	face	[object!]
	pt		[planar!]
	return:	[integer!]
][
	system/view/platform/text-box-metrics face pt 1
]

offset-to-char: function [
	"Given a coordinate, returns the corresponding character position"
	face	[object!]
	pt		[planar!]
	return:	[integer!]
][
	system/view/platform/text-box-metrics face pt 5
]

rich-text: context [
	rtd: #include %RTD.red
	
	line-height?: function [
		"Given a text position, returns the corresponding line's height"
		face	[object!]
		pos		[integer!]
		return:	[float!]
	][
		system/view/platform/text-box-metrics face pos 2
	]

	line-count?: function [
		"number of lines (> 1 if line wrapped)"
		face	[object!]
		return:	[integer!]
	][
		system/view/platform/text-box-metrics face 0 4
	]
]

metrics?: function [
	"Returns a pair! value in the type metrics for the argument face"
	face [object!]			"Face object to query"
	type [word!]			"Metrics type: 'paddings or 'margins"
	/total					"Return the addition of metrics along an axis"
		axis [word!]		"Axis to use for addition: 'x or 'y"
][
	res: select system/view/metrics/:type face/type
	all [
		face/options
		type: face/options/class
		res: find res type
		res: next res
	]
	either total [
		axis: any [select [x 1 y 2] axis 1]
		res/:axis/x + res/:axis/y
	][res]
]

set-flag: function [
	"Sets (or clears) a flag in a face object; Returns the /flags facet value"
	face  [object!]			"Face where flag to set/clear"
	flag  [any-type!]		"Flag to set/clear"
	/clear					"Clears the flag instead of setting it"
	/toggle					"Set it if unset, clears it otherwise"
][
	flags: face/flags
	case [
		clear [
			either block? flags [if pos: find flags flag [remove pos]][face/flags: none]
		]
		toggle [
			either block? flags [
				either pos: find flags flag [remove pos][append flags flag]
			][
				face/flags: either all [flags flags = flag][none][
					either flags [reduce [flags flag]][reduce [flag]]
				]
			]
		]
		flags [
			if word? flags [face/flags: flags: reduce [flags]]
			either block? flags [append flags flag][face/flags: flag]
		]
		'else [face/flags: flag]
	]
	flags
]

find-flag?: routine [
	"Checks a flag in a face object"
	facet	[any-type!]
	flag 	[word!]
	/local
		word   [red-word!]
		value  [red-value!]
		tail   [red-value!]
		bool   [red-logic!]
		type   [integer!]
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
				type: TYPE_OF(value)
				if any [type = TYPE_WORD type = TYPE_LIT_WORD][
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

debug-info?: func ["Internal use only" face [object!] return: [logic!]][
	all [
		system/view/debug?
		not all [
			value? 'gui-console-ctx
			any [
				same? face gui-console-ctx/terminal/box
				same? face gui-console-ctx/console
				same? face gui-console-ctx/win
				same? face gui-console-ctx/caret
			]
		]
	]
]

on-face-deep-change*: function ["Internal use only" owner word target action new index part state forced?][
	if debug-info? owner [
		print [
			"-- on-deep-change event --" 		 lf
			tab "owner      :" owner/type		 lf
			tab "action     :" action			 lf
			tab "word       :" word				 lf
			tab "target type:" mold type? target lf
			tab "new value  :" mold type? new	 lf
			tab "index      :" index			 lf		;-- zero-based absolute index
			tab "part       :" part				 lf
			tab "auto-sync? :" system/view/auto-sync? lf
			tab "forced?    :" forced?
		]
	]
	if all [state word <> 'state word <> 'extra][
		either any [
			forced?
			system/view/auto-sync?
			owner/type = 'screen						;-- not postponing windows events
		][
			unless w: in owner word [exit]
			state/2: state/2 or (1 << ((index? w) - 1))
			
			either word = 'pane [
				case [
					action = 'moved [
						diff?: yes
						faces: skip head target index	;-- zero-based absolute index
						loop part [
							either same? faces/1/parent owner [diff?: no][faces/1/parent: owner]
							faces: next faces
						]
						;unless forced? [show owner]
						if diff? [system/view/platform/on-change-facet owner word target action new index part]
					]
					find [remove clear take change] action [
						either owner/type = 'screen [
							loop part [
								face: target/1
								if face/type = 'window [
									stop-reactor/deep face
									modal?: find-flag? face/flags 'modal
									system/view/platform/destroy-view face face/state/4
									if modal? [
										either 1 = length? head target [ ;-- if only target window is present in the pane
											foreach screen system/view/screens [
												unless empty? head screen/pane [
													face: last head screen/pane	;-- select the last opened window
													face/enabled?: yes
													unless system/view/auto-sync? [show face]
													break
												]
											]
										][
											pane: target
											until [
												pane: back pane
												pane/1/enabled?: yes
												unless system/view/auto-sync? [show pane/1]
												any [head? pane find-flag? pane/1/flags 'modal]
											]
										]
									]
								]
								target: next target
							]
						][
							loop part [
								face: target/1
								face/parent: none
								stop-reactor/deep face
								system/view/platform/destroy-view face no
								target: next target
							]
						]
					]
					'else [
						if owner/type <> 'screen [
							if all [
								find [tab-panel window panel] owner/type
								find [inserted appended poked changed moved] action 
							][
								faces: skip head target index	;-- zero-based absolute index
								loop part [
									face: faces/1
									unless all [
										object? face
										in face 'type
										word? face/type
									][
										cause-error 'script 'face-type reduce [face]
									]
									if owner/type = 'tab-panel [
										face/visible?: no
										face/parent: owner
									]
									if all [owner/type = 'window face/type = 'window][
										cause-error 'script 'bad-window []
									]
									show/with face owner
									faces: next faces
								]
							]
							;unless forced? [show owner]
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
					either all [word = 'data find [text-list drop-list drop-down] owner/type][
						if string? target [
							target: head target
							index: (index? find/same owner/data target) - 1
							part: 1
						]
						if any [
							string? target
							all [
								block? target
								same? (head owner/data) (head target)
								not find [insert append cleared removed taken] action
							]
						][
							system/view/platform/on-change-facet owner word target action new index part
						]	
					][
						system/view/platform/on-change-facet owner word target action new index part
					]
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
					if all [
						find [clear remove take] action
						word <> 'draw
					][
						index: 0
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

link-tabs-to-parent: function [
	"Internal Use Only"
	face	[object!]
	/init	"Force /show of first tab"
][
	if faces: face/pane [
		visible?: face/visible?
		forall faces [
			#if config/OS = 'Windows [				;@@ remove this system specific code
				faces/1/visible?: make logic! all [visible? face/selected = index? faces]
			]
			faces/1/parent: face
			if init [show/with faces/1 face]
		]
	]
]

link-sub-to-parent: function ["Internal Use Only" face [object!] type [word!] old new][
	if object? new [
		unless all [parent: in new 'parent block? get parent][
			new/parent: make block! 4
		]
		new/parent: insert tail new/parent face
		all [
			object? old
			parent: in old 'parent
			block? parent: get parent
			remove find/same head parent face
		]
	]
]

update-font-faces: function ["Internal Use Only" parent [block! none!]][
	if block? parent [
		foreach f head parent [
			if f/state [
				system/reactivity/check/only f 'font
				f/state/2: f/state/2 or 00080000h		;-- (1 << ((index? in f 'font) - 1))
				if block? f/draw [						;-- force a redraw in case the font in draw block
					f/state/2: f/state/2 or 00400000h	;-- (1 << ((index? in f 'draw) - 1))
				]
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
	enabled?:	yes
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
		if debug-info? self [
			print [
				"-- on-change event --" lf
				tab "face :" type		lf
				tab "word :" word		lf
				tab "old  :" either find immediate! type? :old [mold :old][type? :old]	lf
				tab "new  :" either find immediate! type? :new [mold :new][type? :new]
			]
		]

		if all [word <> 'state word <> 'extra][
			if all [any [word = 'size word = 'offset] old = new][exit]

			same-pane?: all [block? :old block? :new same? head :old head :new]
			if word = 'pane [
				if all [type = 'window object? :new new/type = 'window][
					cause-error 'script 'bad-window []
				]
				if all [not same-pane? block? :old not empty? old][
					modify old 'owned none				;-- stop object events
					foreach f head old [
						f/parent: none
						stop-reactor/deep f
						if all [block? f/state handle? f/state/1][
							system/view/platform/destroy-view f no
						]
					]
				]
				if all [not same-pane? type = 'tab-panel self/state][
					link-tabs-to-parent/init self
				]
			]
			if all [not same-pane? any [series? :old object? :old]][modify old 'owned none]
			
			unless any [same-pane? find [font para edge actors extra] word][
				if any [series? :new object? :new][
					modify new 'owned none				;@@ `new` may be owned by another container
					modify new 'owned reduce [self word]
				]
			]
			if word = 'font  [link-sub-to-parent self 'font old new]
			if word = 'para  [link-sub-to-parent self 'para old new]
			
			if find [field text] type [
				if all [word = 'text any [not options not find options 'sync options/sync]][
					set-quiet 'data any [
						all [
							not empty? new 
							new-type: scan new
							find any [all [options options/sync] scalar!] new-type
							attempt/safer [load new]
						]
						all [options options/default]
					]
				]
				if word = 'data [
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
			
			all [
				word = 'selected
				selected
				block? data
				find [drop-list drop-down text-list field area] type
				value: pick data selected
				set-quiet 'text copy value
			]
			
			if all [not same? :old :new image? :old][system/view/platform/detach-image old]

			system/reactivity/check/only self any [saved word]

			either state [
				;if word = 'type [cause-error 'script 'locked-word [type]]
				state/2: state/2 or (1 << ((index? word) - 1))
				if all [state/1 system/view/auto-sync?][show self]
			][
				if type = 'rich-text [system/view/platform/update-view self]
			]
		]
	]
	
	on-deep-change*: function [owner word target action new index part][
		if unset? :new [new: none]
		on-face-deep-change* owner word target action new index part state no
	]
]

font!: object [											;-- keep in sync with font-facet! enum
	name:		 none
	size:		 none
	style:		 none
	angle:		 0
	color:		 none
	anti-alias?: no
	shadow:		 none
	state:		 none
	parent:		 none
	
	on-change*: function [word old new][
		if system/view/debug? [
			print [
				"-- font on-change event --" lf
				tab "word :" word			 lf
				tab "old  :" type? :old		 lf
				tab "new  :" type? :new
			]
		]
		if word <> 'state [
			if any [series? :old object? :old][modify old 'owned none]
			if any [series? :new object? :new][modify new 'owned reduce [self word]]

			if all [block? state handle? state/1][ 
				system/view/platform/update-font self (index? word) - 1
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
			system/view/platform/update-font self (index? word) - 1
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
				tab "old  :" type? :old		 lf
				tab "new  :" type? :new
			]
		]
		if all [
			not find [state parent] word
			block? parent
		][
			foreach f head parent [
				system/reactivity/check/only f 'para
				system/view/platform/update-para f (index? word) - 1 ;-- sets f/state flag too
				if all [f/state f/state/1][show f]
			]
		]
	]
]

scroller!: object [
	position:	none			;-- knob position
	page-size:	none			;-- page size
	min-size:	1				;-- minimum value
	max-size:	none			;-- maximum value
	visible?:	yes
	vertical?:	yes				;-- read only. YES: vertical NO: horizontal
	parent:		none

	on-change*: function [word old new][
		if all [parent block? parent/state handle? parent/state/1][
			system/view/platform/update-scroller self (index? word) - 1
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
		paddings:		make map! 32
		margins:		make map! 32
		def-heights:	make map! 32
		fixed-heights:	make map! 32
		misc:			make map! 32
		colors:			make map! 10
	]
	
	fonts: object [
		system:
		fixed:
		sans-serif:
		serif:
		size:			none
	]

	platform: none
	VID: none
	
	handlers: make block! 20
	
	evt-names: make hash! [
		detect			on-detect
		time			on-time
		drawing			on-drawing
		scroll			on-scroll
		down			on-down
		up				on-up
		mid-down		on-mid-down
		mid-up			on-mid-up
		alt-down		on-alt-down
		alt-up			on-alt-up
		aux-down		on-aux-down
		aux-up			on-aux-up
		wheel			on-wheel
		drag-start		on-drag-start
		drag			on-drag
		drop			on-drop
		click			on-click
		dbl-click		on-dbl-click
		over			on-over
		key				on-key
		key-down		on-key-down
		key-up			on-key-up
		ime				on-ime
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
		create			on-create						;-- View-level event
		created			on-created						;-- View-level event
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
	
	awake: function [event [event!] /with face /local result][	;@@ temporary until event:// is implemented
		unless face [unless face: event/face [exit]]	;-- filter out unbound events
		
		unless with [									;-- protect following code from recursion
			foreach [name handler] handlers [
				set/any 'result do-safe [handler face event]
				either event? :result [event: result][if :result [return :result]]
			]
			set/any 'result capture-events face event	;-- event capturing
			if find [stop done] :result [return :result]
		]
		
		set/any 'result do-actor face event event/type
		
		if all [face/parent not find [done continue] :result][
			set/any 'result system/view/awake/with event face/parent ;-- event bubbling
			if :result = 'stop [return 'stop]
		]
		
		if all [event/type = 'close :result <> 'continue][
			result: pick [stop done] face/state/4		;-- face/state will be none after remove call
			foreach screen system/view/screens [
				if pos: find/same head screen/pane face [remove pos break]
			]
		]
		:result
	]
	
	capturing?: no										;-- enable capturing events (on-detect)
	auto-sync?: yes										;-- refresh faces on changes automatically
	debug?: 	no										;-- output verbose logs
	silent?:	no										;-- do not report errors (livecoding)
]

#include %backends/platform.red
#include %draw.red
#include %VID.red

do-events: func [
	"Launch the event loop, blocks until all windows are closed"
	/no-wait			   "Process an event in the queue and returns at once"
	return: [logic! word!] "Returned value from last event"
	/local result screen win
][
	foreach screen system/view/screens [
		if all [win: last head screen/pane win/state][
			unless win/state/4 [win/state/4: not no-wait]	;-- mark the window from which the event loop starts
			set/any 'result system/view/platform/do-event-loop no-wait
			break
		]
	]
	:result
]

stop-events: function [
	"Stop the last opened event loop"
][
	system/view/platform/exit-event-loop
]

do-safe: func ["Internal Use Only" code [block!] /local result error][
	unset 'result
	if error? error: try/all [
		if 'halt-request = catch/name [
			set/any 'result do code
			none										;-- catch/name shouldn't be triggered by a word returned
		] 'console [stop-events]
		none											;-- try/all shouldn't be triggered by whatever stop-events returns
	][print :error]
	:result												;-- unset or result of actor evaluation
]

do-actor: function ["Internal Use Only" face [object!] event [event! none!] type [word!] /local result][
	if all [
		object? face/actors
		act: in face/actors name: select system/view/evt-names type
		act: get act
	][
		if debug-info? face [print ["calling actor:" name]]
		set/any 'result do-safe [act face event]	;-- compiler can't call act, hence DO
	]
	:result
]

show: function [
	"Display a new face or update it"
	face [object! block!] "Face object to display"
	/with				  "Link the face to a parent face"
		parent [object!]  "Parent face to link to"
	/force				  "For internal use only!"
	return: [logic!]	  "true if success"
][
	show?: yes
	if block? face [
		foreach f face [
			if word? :f [f: get f]
			either object? :f [show?: show f][cause-error 'script 'face-type [:f]]
		]
		return show?
	]
	if debug-info? face [print ["show:" face/type " with?:" with]]
	
	either all [face/state face/state/1][
		pending: face/state/3

		if all [pending not empty? pending][
			pending: copy pending
			clear face/state/3
			foreach [owner word target action new index part state] pending [
				on-face-deep-change* owner word target action new index part state yes
			]
			clear pending
		]
		if face/state/2 <> 0 [system/view/platform/update-view face]
		handle: face/state/1
	][
		new?: yes
		
		either face/type <> 'screen [
			if all [not force face/type <> 'window][
				unless parent [cause-error 'script 'not-linked []]
				if all [object? face/parent face/parent/type <> 'tab-panel not with][face/parent: none]
			]
			if any [series? face/extra object? face/extra][
				modify face/extra 'owned none			;@@ TBD: unflag object's fields (ownership)
			]
			if all [object? face/actors in face/actors 'on-create][
				do-safe [face/actors/on-create face none]
			]
			p: either with [parent/state/1][null-handle]

			#if config/OS = 'macOS [					;@@ remove this system specific code
				if all [face/type = 'tab-panel face/pane][
					link-tabs-to-parent face
					foreach f face/pane [show/force f]
				]
			]

			handle: system/view/platform/make-view face p
			if with [face/parent: parent]

			face/state: reduce [handle 0 none false]

			foreach field [para font][
				if all [field: face/:field p: in field 'parent][
					field/parent: tail either block? p: get p [
						unless find/same head p face [append p face]
						p
					][
						reduce [face]
					]
				]
			]
			
			switch face/type [
				#if config/OS <> 'macOS [				;@@ remove this system specific code
					tab-panel [link-tabs-to-parent face]
				]
				window	  [
					face/parent: get-current-screen
					if find-flag? face/flags 'modal [
						pane: face/parent/pane
						foreach f head pane [
							f/enabled?: no
							unless system/view/auto-sync? [show f]
						]
					]
					append face/parent/pane face
				]
			]
		][face/state: reduce [handle 0 none false]]
	]

	if face/pane [
		foreach f face/pane [
			unless face? :f [cause-error 'script 'face-type [:f]]
			show/with f face
			unless face/state [return false]			;-- unviewed in child event handler
		]
		if face/type <> 'screen [system/view/platform/refresh-window face/state/1]
	]
	if all [new? object? face/actors in face/actors 'on-created][
		do-safe [face/actors/on-created face none]		;@@ only called once
	]
	if all [face/type = 'window face/visible?][system/view/platform/show-window handle]
	show?
]

unview: function [
	"Close last opened window view"
	/all  "Close all views"
	/only "Close a given view"
		face [object!] "Window view to close"
][
	if system/view/debug? [print ["unview: all:" :all "only:" only]]
	
	all?: :all											;-- compiler does not support redefining ALL
	svs: either system/words/all [only face/type = 'window][face/parent][get-current-screen]
	if empty? pane: svs/pane [exit]
	
	case [
		only  [remove find/same head pane face]
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
	/no-sync				"Requires `show` calls to refresh faces"
	/local sync? result
][
	unless system/view/screens [system/view/platform/init]
	
	sync?: system/view/auto-sync?
	if no-sync [system/view/auto-sync?: no]
	if block? spec [spec: either tight [layout/tight spec][layout spec]]
	if spec/type <> 'window [cause-error 'script 'not-window []]
	if options [set/any spec make object! opts]
	if flags [spec/flags: either spec/flags [unique union to-block spec/flags to-block flgs][flgs]]
	
	unless spec/text   [spec/text: "Red: untitled"]
	unless spec/offset [center-face/with spec get-current-screen]
	unless show spec [exit]

	set/any 'result either no-wait [
		do-events/no-wait
		spec							;-- return root face
	][
		do-events ()					;-- return unset! value by default
	]
	system/view/auto-sync?: sync?
	:result
]

center-face: function [
	"Center a face inside its parent"
	face [object!]		 "Face to center"
	/x					 "Center horizontally only"
	/y					 "Center vertically only"
	/with				 "Provide a reference face for centering instead of parent face"
		parent [object!] "Reference face"
	return: [object!]	 "Returns the centered face"
][
	unless parent [parent: face/parent]
	either parent [
		pos: parent/size - face/size / 2
		case [
			x	  [face/offset/x: pos/x]
			y	  [face/offset/x: pos/y]
			'else [face/offset: pos]
		]
		if face/type = 'window [face/offset: face/offset + parent/offset]
	][
		print "CENTER-FACE: face has no parent!"		;-- temporary check
	]
	face
]

make-face: func [
	"Make a face from a given style name or example face"
	style   [word!]  "A face type"
	/spec 
		blk [block!] "Spec block of face options expressed in VID"
	/offset
		xy  [pair!]  "Offset of the face"
	/size
		wh	[pair!]  "Size of the face"
	/local 
		svv face styles model opts css
][
	svv: system/view/VID
	styles: svv/styles
	unless model: select styles style [
		cause-error 'script 'face-type reduce [style]
	]
	face: make face! copy/deep model/template
	
	unless spec [blk: []]
	opts: svv/opts-proto
	css: make block! 2
	reactors: make block! 4
	spec: svv/fetch-options/no-skip face opts model blk css reactors no
	if model/init [do bind model/init face]
	svv/process-reactors reactors

	face/offset: any [xy face/offset 0x0]
	if size [face/size: wh]
	face
]

dump-face: function [
	"Display debugging info about a face and its children"
	face [object!] "Face to analyze"
][
	depth: ""
	print [
		depth "Type:" face/type "Style:" if face/options [face/options/style]
		"Offset:" face/offset "Size:" face/size "Color:" face/color
		"Text:" if face/text [mold/part face/text 20]
	]
	append depth "    "
	if block? face/pane [foreach f face/pane [dump-face f]]
	remove/part depth 4
	face
]

;-- Temporary helper function, original code: https://codeberg.org/hiiamboris/red-common/src/branch/master/do-unseen.red
do-no-sync: func [
	"Evaluate CODE with view/auto-sync?: off"
	code [block!]
	/local r e old
][
	old: system/view/auto-sync?
	system/view/auto-sync?: no
	e: try/all [set/any 'r do code  'ok]
	system/view/auto-sync?: old
	if error? e [do :e]								;-- rethrow the error AFTER restoring auto-sync
	:r
]

get-scroller: func [
	"return a scroller object from a face"
	face		[object!]
	orientation [word!]
	return:		[object!]
][
	make scroller! [
		position:	1
		page:		1
		min-size:	1								;-- minimum value
		max-size:	1								;-- maximum value
		parent:		face
		vertical?:	orientation = 'vertical
	]
]

get-face-pane: func [
	"Returns the list of a container children or none"
	face [object!] "Face container"
	return: [block! none!]
][
	either face/type = 'tab-panel [select pick face/pane face/selected 'pane][face/pane]
]

get-focusable: function [
	"Returns the next focusable face from a face tree"
	faces [block!]	"Position to start from in a face's pane"
	/back			"Search backward"
][
	origin: faces
	checks: [
		f/visible?
		f/enabled?
		flags: f/flags
		any [
			flags = 'focusable
			all [block? flags find flags 'focusable]
		]
	]
	either back [										;-- search backward
		unless empty? head faces [
			while [not head? faces][
				f: first faces: skip faces -1
				all [									;-- try face's children first
					block? pane: get-face-pane f
					not empty? pane
					return get-focusable/back tail pane	;-- search downward and exit
				]
				if all checks [return f]				;-- check if face is focusable
			]
		]
	][													;-- search forward
		while [not tail? faces][
			f: faces/1
			if all checks [return f]					;-- first check if the face is focusable
			all [										;-- if failed, try face's children
				block? pane: get-face-pane f
				not empty? pane
				return get-focusable pane			 	;-- search downward and exit
			]
			faces: next faces
		]
	]
	p: select first head faces 'parent					;-- search upward
	faces: find/same p/parent/pane p
	p: faces/1
	either p/type = 'window [
		if same? p/pane origin [return origin/1]
		get-focusable/:back either back [tail p/pane][p/pane] ;-- bounce down from window face
	][
		if p/parent/type = 'tab-panel [
			p: p/parent									;-- skip the panels level in tab-panels
			if back [return p]							;-- shortcut to return the tab header when going back up
			faces: find/same p/parent/pane p
		]
		unless back [faces: next faces]					;-- skip the currently visited container if moving forward
		get-focusable/:back faces
	]
]

insert-event-func: function [
	"Adds a function to monitor global events. Returns the function"
	name [word!]
	fun  [block! function!] "A function or a function body block"
][
	if block? :fun [fun: apply :function [copy [face event] fun]]	;@@ compiler chokes on 'function call
	if any [
		find svh: system/view/handlers name
		find/same svh :fun
	][
		return none
	]
	insert svh reduce [name :fun]
	:fun
]

remove-event-func: function [
	"Removes an event function previously added"
	id [word! function!] "Handler name or function reference"
][
	svh: system/view/handlers
	pos: either word? :id [find svh id][back find svh :id]
	remove/part pos 2
]

request-font: function [
	"Requests a font object"
	/font	"Sets the selected font"
		ft	[object!]
	/mono	"Show monospaced font only"
][
	system/view/platform/request-font make font! [] ft mono
]

request-file: function [
	"Asks user to select a file and returns full file path (or block of paths)"
	/title	"Window title"
		text [string!]
	/file	"Default file name or directory"
		name [string! file!]
	/filter	"Block of filters (filter-name filter)"
		list [block!]
	/save	"File save mode"
	/multi	"Allows multiple file selection, returned as a block"
][
	system/view/platform/request-file text name list save multi
]

request-dir: function [
	"Asks user to select a directory and returns full directory path (or block of paths)"
	/title	"Window title"
		text [string!]
	/dir	"Set starting directory"
		name [string! file!]
	/filter	"TBD: Block of filters (filter-name filter)"
		list [block!]
	/keep	"Keep previous directory path"
	/multi	"TBD: Allows multiple file selection, returned as a block"
][
	system/view/platform/request-dir text name list keep multi
]

set-focus: function [
	"Sets the focus on the argument face"
	face [object!]
][
	p: face/parent
	while [p/type <> 'window][p: p/parent]
	p/selected: face
]

foreach-face: function [
	"Evaluates body for each face in a face tree matching the condition"
	face [object!]	"Root face of the face tree"
	body [block! function!] "Body block (`face` object) or function `func [face [object!]]`"
	/with			"Filter faces according to a condition"
		spec [block! none!] "Condition applied to face object"
	/post 			"Evaluates body for current face after processing its children"
	/sub post?		"Do not rebind body and spec, internal use only"
][
	unless block? face/pane [exit]
	unless sub [
		all [spec bind spec 'face]
		if block? :body [bind body 'face]
	]
	if post [post?: yes]
	exec: [either block? :body [do body][body face]]
	
	foreach face face/pane [
		unless post? [either spec [all [do spec try exec]][try exec]]
		if block? face/pane [foreach-face/with/sub face :body spec post?]
		if post? [either spec [all [do spec try exec]][try exec]]
	]
]

alert: func [
	"Displays an alert message in a pop-up modal window"
	msg [string! block!] "Message to display"
][
	view/flags compose [
		title "Message"
		below center
		text 200 (form reduce msg) center
		button focus "OK" [unview] on-key [
			switch event/key [
				#"^M" #"^[" #" " #"^O" [unview]
			]
		]
	] 'modal
]

;=== Global handlers ===

;-- Dragging face handler --
insert-event-func 'dragging function [face event][
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
			set/any 'result do-actor face event 'drag-start
			unless all [
				object? :result
				[min max] = words-of result
				planar? result/min
				planar? result/max
			][
				result: none
			]
			face/state/4: reduce [event/offset any [result face/options/bounds]]
			unless system/view/auto-sync? [show face]
		][
			if drag-info: face/state/4 [
				either type = 'over [
					unless event/away? [
						new: (any [face/offset 0x0]) + event/offset - drag-info/1
						if face/offset <> new [
							if box: drag-info/2 [new: min box/max max box/min new]
							if face/offset <> new [face/offset: new]
							set/any 'result do-actor face event 'drag ;-- avoid calling on-over actor
							show face/parent
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
insert-event-func 'debug [
	if all [
		system/view/debug?
		not all [
			value? 'gui-console-ctx
			find/same gui-console-ctx/owned-faces event/face
		]
	][
		print [
			"face> type:"	event/face/type
			"event> type:"	event/type
			"offset:"		event/offset
			"key:"			mold event/key
			"flags:" 		mold event/flags
		]
	]
	none
]

;-- 'enter event handler --
insert-event-func 'enter [
	all [
		event/type = 'key
		find "^M^/" event/key
		switch event/face/type [ 
			field 
			drop-down [event/type: 'enter]
			button	  [event/type: 'click]
		]
	]
	event
]

;-- Radio faces handler --
insert-event-func 'radio [
	if all [
		event/type = 'click
		event/face/type = 'radio
	][
		face: event/face								;-- save face reference to avoid single-event corruption (#5278)
		foreach f face/parent/pane [
			if all [f/type = 'radio f/data][f/data: off show f]
		]
		face/data: on
		show face
		event/type: 'change
	]
	event
]

;-- Reactors support handler --
insert-event-func 'reactors [
	if find [change enter unfocus] event/type [
		face: event/face
		facet: switch/default face/type [
			scroller	['data]
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
	if all [event/window event/type = 'focus][system/reactivity/check/only event/window 'selected]
	
	if event/face/type = 'window [
		switch event/type [
			move moving 	[system/reactivity/check/only event/face 'offset]
			resize resizing [system/reactivity/check/only event/face 'size]
		]
	]
	if event/type = 'select [
		face: event/face
		if find [field area] face/type [
			system/reactivity/check/only face 'selected
		]
	]
	none
]

;-- Field's data facet syncing handler
insert-event-func 'field-sync [
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

;-- TAB key navigation handler
insert-event-func 'tab function [face event][
	if all [
		event/type = 'key-down
		event/key = #"^-"
		any [
			face/type <> 'area							;-- if area is not focusable, let it handle TAB key
			all [
				not find event/flags 'control
				flags: face/flags
				any [flags = 'focusable all [block? flags find flags 'focusable]]
			]
		]
		not all [
			value? 'gui-console-ctx
			find/same gui-console-ctx/owned-faces face
		]
	][
		faces: either face/type = 'window [face/pane][find/same face/parent/pane face]
		unless back?: to-logic find event/flags 'SHIFT [
			faces: either all [pane: get-face-pane face not empty? pane][pane][next faces]
		]
		new: any [
			all [
				opt: face/options
				any [
					all [back? opt/prev]
					all [not back? opt/next]
				]
			]
			apply :get-focusable [faces /back back?]
		]
		unless same? new face [set-focus new]
		return 'stop
	]
	event
]

#if config/GUI-engine = 'terminal [
	;-- ESC key handler
	insert-event-func 'esc function [face event][
		if all [
			event/type = 'key
			event/key = #"^["
		][
			unview/all
			'stop
		]
	]
]
