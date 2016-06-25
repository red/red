Red [
	Title:		"Red GUI Console"
	File:		%gui-console.red
	Tabs:		4
	Icon:		default
	Version:	0.9.0
	Needs:		View
	Config:		[
		gui-console?: yes
		red-help?: yes
	]
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %help.red
#include %engine.red
#include %auto-complete.red

#system [
	#include %terminal.reds
]

ask: routine [
	question [string!]
	return:  [string!]
][
	as red-string! _series/copy
		as red-series! terminal/ask question
		as red-series! stack/arguments
		null
		yes
		null
]

input: does [ask ""]

gui-console-ctx: context [
	cfg-path:	 none
	cfg:		 none
	
	copy-text:   routine [face [object!]][terminal/copy-text   face]
	paste-text:  routine [face [object!]][terminal/paste-text  face]
	select-text: routine [face [object!]][terminal/select-text face]

	set-buffer-lines: routine [n [integer!]][terminal/set-buffer-lines n]
	set-font-color: routine [color [tuple!]][terminal/set-font-color color/array1]
	set-background: routine [color [tuple!]][terminal/set-background color/array1]

	init: func [/local cfg-dir][
		system/view/auto-sync?: no
		cfg-dir: append to-red-file get-env "ALLUSERSPROFILE" %/Red/
		unless exists? cfg-dir [make-dir cfg-dir]
		cfg-path: append cfg-dir %console-cfg.red
		cfg: either exists? cfg-path [skip load cfg-path 2][
			compose [
				win-pos:		(win/offset)
				win-size:		(win/size)

				font-name:		(font-name)
				font-size:		11
				font-color:		0.0.0
				background:		252.252.252

				buffer-lines:	10000
			]
		]
		apply-cfg
		win/selected: console
		system/view/auto-sync?: yes
		win/visible?: yes
	]

	apply-cfg: does [
		win/offset:		 cfg/win-pos
		win/size:		 cfg/win-size
		console/font:	 make font! [name: cfg/font-name size: cfg/font-size]
		set-font-color	 cfg/font-color
		set-background	 cfg/background
		set-buffer-lines cfg/buffer-lines
	]

	save-cfg: function [][
		offset: win/offset					;-- offset could be negative in some cases
		if offset/x < 0 [offset/x: 0]
		if offset/y < 0 [offset/y: 0]
		cfg/win-pos:  offset
		cfg/win-size: win/size
		cfg/font-name: console/font/name
		cfg/font-size: console/font/size
		save/header cfg-path cfg [Purpose: "Red GUI Console Configuration File"]
	]

	show-cfg-dialog: does [
		cfg-buffers/data: cfg/buffer-lines
		cfg-forecolor/data: cfg/font-color
		cfg-backcolor/data: cfg/background
		view/flags cfg-dialog [modal]
	]

	font-name: pick ["Fixedsys" "Consolas"] make logic! find [5.1.0 5.0.0] system/view/platform/version

	cfg-dialog: layout [
		text "Buffer Lines:" cfg-buffers:	field return
		text "ForeColor:"	 cfg-forecolor: field return
		text "BackColor:"	 cfg-backcolor: field return
		button "OK" [
			if cfg/buffer-lines <> cfg-buffers/data [
				cfg/buffer-lines: cfg-buffers/data
				set-buffer-lines cfg/buffer-lines
			]
			cfg/font-color:   cfg-forecolor/data
			cfg/background:   cfg-backcolor/data
			set-font-color    cfg-forecolor/data
			set-background    cfg-backcolor/data
			unview
			win/selected: console
		]
		button "Cancel" [unview win/selected: console]
	]

	console: make face! [
		type: 'console offset: 0x0 size: 640x400
		menu: [
			"Copy^-Ctrl+C"		 copy
			"Paste^-Ctrl+V"		 paste
			"Select All^-Ctrl+A" select-all
		]
		actors: object [
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					copy		[copy-text   face]
					paste		[paste-text  face]
					select-all	[select-text face]
				]
			]
		]
	]

	win: make face! [
		type: 'window offset: 640x400 size: 640x400 visible?: no
		text: "Red Console"
		menu: [
			"File" [
				"Exit"				exit-console
			]
			"Options" [
				"Choose Font..."	choose-font
				"Settings..."		settings
			]
		]
		actors: object [
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					exit-console	[self/on-close face event]
					choose-font		[if font: request-font [console/font: font]]
					settings		[show-cfg-dialog]
				]
			]
			on-close: func [face [object!] event [event!]][
				save-cfg
				clear head system/view/screens/1/pane
			]
			on-resizing: func [face [object!] event [event!]][
				console/size: event/offset
				unless system/view/auto-sync? [show face]
			]
		]
		pane: reduce [console]
	]
	
	launch: does [
		view/flags/no-wait win [resize]
		init

		svs: system/view/screens/1
		svs/pane: next svs/pane

		system/console/launch
		do-events
	]
]

gui-console-ctx/launch

