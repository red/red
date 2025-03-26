Red [
	Title:	 "Red GUI Console"
	Author:	 "Qingtian Xie"
	File:	 %gui-console.red
	Tabs:	 4
	Icon:	 %app.ico
	Version: 0.0.1
	Needs:	 [View JSON CSV]
	Config:	 [gui-console?: yes red-help?: yes]
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#if config/debug? [
	debug-print: routine [
		"Output debug info to CLI console only"
		arg [any-type!] /local blk [red-block!]
	][
		#if sub-system = 'console [
			if TYPE_OF(arg) = TYPE_BLOCK [
				block/rs-clear natives/buffer-blk
				stack/push as red-value! natives/buffer-blk
				natives/reduce* no 1
				blk: as red-block! arg
				blk/head: 0						;-- head changed by reduce/into
			]
			actions/form* -1
			dyn-print/red-print-cli as red-string! stack/arguments yes
		]
	]
]

#include %../help.red
#include %../engine.red
#include %../auto-complete.red
#include %highlight.red
#include %tips.red

gui-console-ctx: context [
	cfg-dir:	none
	cfg-path:	none
	cfg:		none
	font:		make font! [name: system/view/fonts/fixed size: 11 color: 0.0.0]
	caret-clr:	0.0.0.1
	caret-rate: 2
	scroller:	make scroller! []
	focused?:	yes

	console-menu: [
		#either config/OS = 'macOS [
			"Copy^-Command+C"	copy
			"Paste^-Command+V"	paste
		][
			"Copy^-Ctrl+C"		copy
			"Paste^-Shift+Ins"	paste
		]
		---
		"Select All"		select-all
	]

	console:	make face! [
		type: 'rich-text color: 0.0.128 offset: 0x0 size: 200x200
		flags:   [scrollable all-over]
		options: [cursor: I-beam]
		menu: console-menu
		actors: object [
			on-time: func [face [object!] event [event!]][
				if all [caret/enabled? none? caret/rate][caret/rate: caret-rate]
				terminal/on-time
				'done
			]
			on-drawing: func [face [object!] event [event!]][
				terminal/paint
			]
			on-scroll: func [face [object!] event [event!]][
				terminal/scroll event
			]
			on-wheel: func [face [object!] event [event!]][
				either event/ctrl? [
					terminal/zoom event
				][
					terminal/scroll event
				]
			]
			on-key: func [face [object!] event [event!]][
				terminal/press-key event
			]
			on-key-down: func [face [object!] event [event!]][
				if all [1 = length? event/flags find event/flags 'alt][
					switch event/key [
						#"A" [terminal/select-all]
						#"O" [show-cfg-dialog]
					]
				]
			]
			on-ime: func [face [object!] event [event!]][
				terminal/process-ime-input event
			]
			on-down: func [face [object!] event [event!]][
				terminal/mouse-down event
			]
			on-up: func [face [object!] event [event!]][
				terminal/mouse-up event
			]
			on-alt-down: func [face [object!] event [event!]][
				if cfg/mouse-paste? = 'true [
					either terminal/text-selected? [
						terminal/copy-selection
						clear terminal/selects
						system/view/platform/redraw face
					][
						terminal/paste
					]
				]
			]
			on-over: func [face [object!] event [event!]][
				terminal/mouse-move to-pair event/offset
			]
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					copy		[terminal/copy-selection]
					paste		[terminal/paste]
					select-all	[terminal/select-all]
				]
				'done
			]
		]

		tabs: none line-spacing: 'default handles: none	;-- extra fields

		init: func [/local box][
			terminal/windows: get in get-current-screen 'pane
			box: terminal/box
			box/data: make block! 200
			scroller: get-scroller self 'horizontal
			scroller/visible?: no						;-- hide horizontal bar
			scroller: get-scroller self 'vertical
			scroller/position: 1
			scroller/max-size: 2
		]
	]

	caret: make face! [
		type: 'base color: caret-clr offset: 0x0 size: 1x17 enabled?: no
		options: compose [caret (console) cursor: I-beam accelerated: yes]
		actors: object [
			on-time: func [face [object!] event [event!]][
				face/color: either face/color = caret-clr [255.255.255.254][caret-clr]
				'done
			]
		]
	]
	tips: make tips! [visible?: no]

	terminal: #include %core.red

	toggle-mouse-mode: does [
		console/menu: either cfg/mouse-paste? = 'true [none][console-menu]
	]

	#include %settings.red

	show-caret: func [][unless caret/enabled? [caret/enabled?: yes]]

	win-menu: [
		"File" [
			"Run..."			run-file
			---
			"Quit"				quit
		]
		"Options" [
			"Choose Font..."	choose-font
			"Settings..."		settings
		]
		;"Plugins" [
		;	"Add..."			add-plugin
		;]
		"Help" [
			"Keyboard Shortcuts" shortcuts
			---
			"About"				 about-msg
		]
	]

	show-shortcuts: does [
		print {
		Ctrl + C       Copy selected text
		Ctrl + V       Paste
		Ctrl + X       Cut selected text
		Ctrl + A       Go to beginning of line
		Ctrl + E       Go to end of line
		Ctrl + H       Backspace
		Ctrl + Z       Undo
		Ctrl + Y       Redo
		Ctrl + L       Clear screen
		Ctrl + K       Delete line
		Alt + A        Select all the text
		Alt + O        Open settings dialog
		F12            Toggle menu bar
		}
		terminal/exit-ask-loop
	]

	toggle-menu-bar: does [
		win/menu: either cfg/menu-bar? = 'true [win-menu][none]
	]

	setup-faces: does [
		;console/pane: reduce [caret]
		append win/pane reduce [console caret tips]
		win/menu: win-menu
		win/actors: object [
			on-menu: func [face [object!] event [event!] /local ft f][
				switch event/picked [
					about-msg		[display-about]
					shortcuts		[show-shortcuts]
					quit			[self/on-close face event]
					run-file		[if f: request-file [terminal/run-file f]]
					choose-font		[
						if ft: request-font/font/mono font [
							font: ft
							console/font: font
							terminal/zoom font
						]
					]
					settings		[show-cfg-dialog]
				]
			]
			on-close: func [face [object!] event [event!]][
				system/view/platform/exit-event-loop
				foreach screen system/view/screens [clear head screen/pane]
				quit
			]
			on-resizing: function [face [object!] event [event!]][
				new-sz: to-pair event/offset + 1x1
				console/size: new-sz
				terminal/resize new-sz
				terminal/adjust-console-size new-sz
				unless system/view/auto-sync? [show face]
			]
			on-resize: :on-resizing
			on-focus: func [face [object!] event [event!]][
				focused?: yes
				caret/color: caret-clr
				unless caret/enabled? [caret/enabled?: yes]
				caret/rate: caret-rate
				terminal/refresh/force
			]
			on-unfocus: func [face [object!] event [event!]][
				focused?: no
				if caret/enabled? [caret/enabled?: no]
				caret/rate: none
			]
			on-key-down: func [face [object!] event [event!]][
				if event/key = 'F12 [
					cfg/menu-bar?: to-word none? face/menu
					toggle-menu-bar
				]
			]
		]
		caret/rate: caret-rate
		tips/parent: win
	]

	win: layout/tight [						;-- main window
		title "Red Console"
		size  200x200
	]
	
	owned-faces: reduce [console win caret]

	add-gui-print: routine [][
		gui-console-buffer: ALLOC_TAIL(root)
		gui-console-buffer/header: TYPE_UNSET
		dyn-print/add as int-ptr! :red-print-gui #either debug? = yes [null][
			as int-ptr! :rs-print-gui
		]
	]

	launch: func [/local svs rate][
		rate: get-caret-blink-time
		caret-rate: case [
			rate > 0 [to-time rate / 1000.0]
			rate < 0 [none]
			rate = 0 [2]
		]

		setup-faces
		win/visible?: no					;-- hide it first to avoid flicker
		load-cfg

		view/flags/no-wait win [resize]		;-- create window instance
		console/init

		apply-cfg
		system/view/auto-sync?: yes
		win/selected: console
		if empty? system/script/args [win/visible?: yes]

		svs: get-current-screen
		svs/pane: next svs/pane				;-- proctect itself from unview/all

		add-gui-print
		console/rate: 10
		system/console/launch
	]
]

_save-cfg: function [][
	gui-console-ctx/save-cfg
]

ask: function [
	"Prompt the user for input"
	question [string!]
	/hide
	/history "specify the history block"
		blk  [block!]
	return:  [string!]
][
	t?: tracing?
	trace off
	if all [
		gui-console-ctx/console/state
		not gui-console-ctx/win/visible?
	][
		gui-console-ctx/win/visible?: yes
	]

	gui-console-ctx/show-caret
	line: gui-console-ctx/terminal/ask question blk hide
	gui-console-ctx/caret/enabled?: no
	unless gui-console-ctx/console/state [line: "quit"]
	trace t?
	line
]

input: function ["Wait for console user input" return: [string!]][ask ""]

get-caret-blink-time: routine [
	return: [integer!]	;-- blink time, in milliseconds, -1: INFINITE
][
	#either OS = 'Windows [
		GetCaretBlinkTime
	][500]
]

#system [

	#if OS = 'Windows [
		#import [
			"user32.dll" stdcall [
				GetCaretBlinkTime: "GetCaretBlinkTime" [
					return:		[uint!]
				]
			]
		]
	]

	gui-console-buffer: as red-value! 0

	red-print-gui: func [
		str		[red-string!]
		lf?		[logic!]
		/local
			t?  [logic!]
	][
		with [red][
			;-- @@ an ugly hacking @@
			;-- part of the internal states of the gui-console may be changed before
			;-- throwing error inside vprint. Incomplete states will make gui-console crazy.
			;-- if it's a stack overflow error, calling any function in Red will make it stack overflow again.
			;-- because of that, we cannot catch the error inside vprint to restore the states.
			;-- also save the states and restore them are not easy in current implementation. (--)!
			;-- so we check it before entering the vprint here
			if any [
				stack/ctop + 60 >= stack/c-end	;-- vprint uses 60 slots on call stk
				stack/top + 80 >= stack/a-end	;-- vprint uses 80 slots on arg stk
			][
				fire [TO_ERROR(internal stack-overflow)]
			]
		]
		t?: interpreter/tracing?
		if t? [interpreter/tracing?: no]
		#call [gui-console-ctx/terminal/vprint str lf?]
		interpreter/tracing?: t?
	]

	rs-print-gui: func [
		cstr	[c-string!]
		size	[integer!]
		lf?		[logic!]
		/local
			str [red-string!]
	][
		str: as red-string! gui-console-buffer
		if negative? size [size: length? cstr]
		either TYPE_OF(str) = TYPE_STRING [
			string/rs-reset str
			unicode/load-utf8-buffer cstr size GET_BUFFER(str) null yes
		][
			str/header: TYPE_UNSET
			str/node: unicode/load-utf8-buffer cstr size null null yes
			str/header: TYPE_STRING
			str/head: 0
			str/cache: null
		]
		red-print-gui str lf?
	]
]

gui-console-ctx/launch