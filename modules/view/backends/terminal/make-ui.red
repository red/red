Red [
	Title:	"Make Text UI of faces"
	Author: "Xie Qingtian"
	File: 	%make-ui.red
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

TUI-helpers: context [

	check-color-support: function [][
		color-term: get-env "COLORTERM"
		term: get-env "TERM"
		if any [
			find color-term "24bit"
			find color-term "truecolor"
		][return 4]

		either any [
			find color-term "256"
			find term "256"
		][2][4]
	]

	focused?: routine [
		face	[object!]
		/local
			widget	[int-ptr!]
			bool	[red-logic!]
	][
		widget: gui/face-handle? face
		logic/box either null? widget [false][gui/has-focus? widget]
	]

	widget-data: routine [
		face	[object!]
		/local
			widget	[int-ptr!]
	][
		widget: gui/face-handle? face
		integer/box as-integer gui/widget-data widget
	]

	set-face-ui: routine [
		face	[object!]
		ui		[string!]
		/local
			widget	[int-ptr!]
	][
		widget: gui/face-handle? face
		if widget <> null [gui/set-widget-ui widget ui/node]
	]

	make-progress-ui: function [
		face	[face!]
	][
		proportion: face/data
		case [
			proportion <= 1e-16 [proportion: 0.0]
			proportion >= 1.0 [proportion: 1.0]
		]
		ui: make string! 50
		append ui #"["
		bar: face/size/x - 2	;-- exclude [ and ]
		val: to-integer round/ceiling bar * proportion
		append/dup ui #"#" val
		append/dup ui #" " bar - val
		append ui #"]"
		face/text: ui
	]

	make-text-list-ui: function [
		face	[face!]
	][
		data: face/data
		unless any [block? data map? data hash? data][exit]

		idx: face/selected
		unless integer? idx [
			idx: 1
			if focused? face [face/selected: 1]
		]
		unless focused? face [idx: -1]

		if idx > length? data [
			idx: length? data
			face/selected: idx
		]

		head: widget-data face		;-- we use widget/data to save the idx of the first entry
		data: skip face/data head
		i: head + 1
		ui: make string! 200
		foreach s data [
			if i = idx [
				append ui "^[[7m"	;-- highlight selected item
			]
			append ui s
			append ui lf
			if i = idx [
				append ui "^[[27m"	;-- reset highlight for next items
			]
			i: i + 1
		]
		face/text: ui
	]

	make-checkbox-ui: function [
		face	[face!]
		return: [string!]
	][
		ui: repend copy pick ["🞕 " "☐ "] to logic! face/data face/text
		set-face-ui face ui
		ui
	]

	make-radio-ui: function [
		face	[face!]
		return: [string!]
		/local
			p	[face!]
			f	[face!]
			set? [logic!]
	][
		set?: to logic! face/data
		if set? [		;-- unset other radios in parent
			if p: face/parent [
				foreach f p/pane [
					if all [f/type = 'radio not same? f face][f/data: no]
				]
			]
		]
		ui: repend copy pick ["◉ " "○ "] set? face/text
		set-face-ui face ui
		ui
	]

	;=== Requesters ===

	get-files: function [root [file!] filters [block! none!] /dir /local f][
		files: read root
		either dir [
			remove-each f files [not dir? f]
			head insert files %../
		][
			remove-each f files [any [dir? f all [filters not find filters suffix? f]]]
			files
		]
	]

	request-file: function [
		title	[string! none!]
		name	[string! file! none!]
		filter	[block! none!]
		save?	[logic!]
		multi?	[logic!]									;-- N/A
	][
		picked: none
		msg: pick [" Save " " Open "] save?
		title: any [title "Please choose a file:"]
		name:  any [name ""]
		if filter [filter: extract next filter 2]
		root: what-dir

		view [
			style spacer: base transparent
			style frame: group-box options [border-corners: round border-color: 64.64.64]
				on-focus   [face/options/border-color: white]
				on-unfocus [face/options/border-color: coal]

			text title return
			path: text 60 with [text: to-local-file root] return
			frame " Folders " [
				dirs: text-list 20x20 data (get-files/dir root none) on-key [
					if all [event/key = enter dirs/selected][
						new: pick dirs/data dirs/selected
						root: either new = %../ [first split-path root][append root new]
						path/text: to-local-file root
						append clear dirs/data get-files/dir root none
						dirs/selected: 1
						append clear files/data get-files root filter
						files/selected: 1
					]
				]
			]
			frame " Files " [
				files: text-list 35x20 data (get-files root filter) on-key [
					if all [event/key = enter files/selected][
						sfile/text: to-string pick files/data files/selected
					]
				]
			] return pad 0x-1

			frame 60x3 [text "Selected:" sfile: field 45 name] return pad 20x0
			button msg [unless empty? f: sfile/text [picked: root/(to-file f)] unview] pad 3x0
			button " Cancel " [unview] return
			spacer 1x1
		]
		picked
	]

	request-dir: function [
		title	[string! none!]
		dir		[string! file! none!]
		filter	[block! none!]
		keep?	[logic!]
		multi?	[logic!]									;-- N/A
	][
		picked: none
		title: any [title ""]
		if filter [filter: extract next filter 2]
		if string? dir [dir: to-red-file dir]
		root: any [dir what-dir]

		view [
			style spacer: base transparent
			style frame: group-box options [border-corners: round border-color: 64.64.64]
				on-focus   [face/options/border-color: white]
				on-unfocus [face/options/border-color: coal]

			text title return
			path: text 60 with [text: to-local-file root] return
			frame " Folders " [
				dirs: text-list 58x20 data (get-files/dir root none) on-key [
					if event/key = enter [
						new: pick dirs/data dirs/selected
						root: either new = %../ [first split-path root][append root new]
						sfile/text: copy path/text: to-local-file root
						append clear dirs/data get-files/dir root none
						dirs/selected: 1
					]
				]
			] return
			frame 60x3 [text "Selected:" sfile: field 45 ""] return pad 20x0
			button " OK " [unless empty? f: sfile/text [picked: root] unview] pad 3x0
			button " Cancel " [unview] return
			spacer 1x1
		]
		picked
	]
]