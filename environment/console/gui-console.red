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
	
	fstk-logo: load/as 64#{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
		 wAAAABJRU5ErkJggg==
	} 'png

	copy-text:   routine [face [object!]][terminal/copy-text   face]
	paste-text:  routine [face [object!]][terminal/paste-text  face]
	select-text: routine [face [object!]][terminal/select-text face]

	set-buffer-lines: routine [n [integer!]][terminal/set-buffer-lines n]
	set-font-color: routine [color [tuple!]][terminal/set-font-color color/array1]
	set-background: routine [color [tuple!]][terminal/set-background color/array1]

	init: func [/local cfg-dir][
		cfg-dir: append to-red-file get-env "ALLUSERSPROFILE" %/Red/
		unless exists? cfg-dir [make-dir cfg-dir]
		cfg-path: append cfg-dir %console-cfg.red
		
		cfg: either exists? cfg-path [skip load cfg-path 2][
			compose [
				win-pos:	  (win/offset)
				win-size:	  (win/size)

				font-name:	  (font-name)
				font-size:	  11
				font-color:	  0.0.0
				background:	  252.252.252

				buffer-lines: 10000
			]
		]
		apply-cfg
		win/selected: console
		win/visible?: yes
	]
	
	display-about: function [][
		lay: layout/tight [
			title "About"
			size 360x320
			backdrop 58.58.60

			style text:  text 360 center 58.58.60 
			style txt:   text font-color white
			style small: txt  font [size: 9 color: white]
			style link:  text cursor 'hand all-over
				on-down [browse face/data]
				on-over [face/font/style: either event/away? [none]['underline]]

			below
			pad 0x15
			txt bold "Red Programming Language" font [size: 15 color: white]
			ver: txt font [size: 9 color: white]
			at 153x86 image fstk-logo
			at 0x160 small 360x20 "Copyright 2011-2017 - Fullstack Technologies"
			at 0x180 small 360x20 "and contributors."
			at 0x230 link "http://red-lang.org" font-size 10 font-color white
			at 0x260 link "http://github.com/red/red" font-size 10 font-color white
			at 154x300 button "Close" [unview win/selected: console]
			do [ver/text: form reduce ["Build" system/version #"-" system/build/date]]
		]
		center-face/with lay win
		view/flags lay [modal no-title]
	]

	apply-cfg: does [
		console/font:	 make font! [name: cfg/font-name size: cfg/font-size anti-alias?: no]
		set-font-color	 cfg/font-color
		set-background	 cfg/background
		set-buffer-lines cfg/buffer-lines
		win/offset:		 cfg/win-pos
		win/size:		 cfg/win-size
	]

	save-cfg: function [][
		offset: win/offset					;-- offset could be negative in some cases
		size: win/size
		scr-sz: system/view/screens/1/size
		if all [offset/x > 0 offset/y > 0 offset < scr-sz][cfg/win-pos: offset]
		if size > 100x20 [cfg/win-size: size]
		cfg/font-name: console/font/name
		cfg/font-size: console/font/size
		save/header cfg-path cfg [Purpose: "Red GUI Console Configuration File"]
	]

	show-cfg-dialog: function [][
		lay: layout [
			title "Settings"
			style bbox: base 20x20 draw [pen gray box 0x0 19x19] on-down [
				set-background cfg-backcolor/data: face/color
			]
			style fbox: bbox on-down [
				set-font-color cfg-forecolor/data: face/color
			]
			style hex-field: field 90 center font [name: font-name]
			
			group-box "Background color" [
				bbox #000000 bbox #002b36 bbox #073642 bbox #293955
				bbox #eee8d5 bbox #fdf6e3 bbox #ffffff
				cfg-backcolor: hex-field
			]
			return
			
			group-box "Font color" [
				fbox #b98000 fbox #cb4b16 fbox #dc322f fbox #d33682
				fbox #6c71c4 fbox #268bd2 fbox #2aa198
				cfg-forecolor: hex-field
				return
				fbox #859900 fbox #82bb82 fbox #000000 fbox #657b83
				fbox #839496 fbox #93a1a1 fbox #ffffff
			]
			return
			
			pad 150x10 text "Buffer Lines" 80 
			pad -17x0 cfg-buffers: hex-field right return
			
			pad 90x20
			button "OK" [
				if cfg/buffer-lines <> cfg-buffers/data [
					cfg/buffer-lines: cfg-buffers/data
					set-buffer-lines cfg/buffer-lines
				]
				set-font-color cfg/font-color: cfg-forecolor/data
				set-background cfg/background: cfg-backcolor/data
				unview
				win/selected: console
			]
			button "Cancel" [unview win/selected: console]
		]
		cfg-buffers/data:	cfg/buffer-lines
		cfg-forecolor/data:	cfg/font-color
		cfg-backcolor/data:	cfg/background
		center-face/with lay win
		view/flags lay [modal]
	]

	font-name: pick ["Fixedsys" "Consolas"] make logic! find [5.1.0 5.0.0] system/view/platform/version

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
				"About"				about-msg
				---
				"Quit"				quit
			]
			"Options" [
				"Choose Font..."	choose-font
				"Settings..."		settings
			]
		]
		actors: object [
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					about-msg		[display-about]
					quit			[self/on-close face event]
					choose-font		[if font: request-font/font/mono console/font [console/font: font]]
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
	]
]

gui-console-ctx/launch

