Red [
	Title:	"Supporting Red functions for the test GUI backend"
	Author: "Nenad Rakocevic"
	File: 	%gui.red
	Tabs: 	4
	Rights: "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

offset-to-face: function [face [object!] pos [pair!]][
	if block? face/pane [
		extra: either face/type = 'window [0x0][face/offset]
		foreach f face/pane [
			if all [
				object? f
				f/visible?
				within? pos - extra f/offset f/size
			][
				face: offset-to-face f pos - extra
				break
			]
		]
	]
	face
]

make-event-wrapper: routine [
	type	[word!]
	face	[object!]
	args	[integer!]
][
	stack/set-last as red-value! gui/OS-make-event type face args
]

do-event: function [
	evt-name [word!]
	/with args
	/at offset [pair!]
	/flags flag-list [block!]
][
	flags: 0
	window: last system/view/screens/1/pane
	face: any [window/selected window]
	
	if offset [face: offset-to-face window offset]
	
	unless face [print "*** Do-event Error: no face selected!" exit]
	
	;-- event pre-processing --
	if args [
		unless block? args [args: reduce [args]]
		insert args evt-name
		
		parse args [
			'key pos: [char! | word!] (
				if 'enter = char: pos/1 [char: lf]
				flags: flags or to-integer char
			)
			| 'select pos: integer! (flags: flags or pos/1)
			| to end
		]
		remove args
	]
	all [
		find [click dbl-click down up] evt-name
		find [check radio] face/type
		evt-name: 'change
	]

	;-- pass event to View engine --
	state: system/view/awake make-event-wrapper evt-name face flags

	;-- event post-processing --
	switch evt-name [
		key	[
			if all [
				not find [stop done] state
				char >= 32
				find [field area] face/type
			][
				either s: face/text [
					modify s 'owned none				;-- disable object events on face/text
				][
					face/text: s: make string! 8
				]
				append s char
				modify s 'owned face
			]
			do-event 'change
		]
		select [
			set-quiet in face 'selected flags and FFFFh
			do-event/with 'change flags
		]
	]
]

input-string: function [face [object!] text [string!]][
	set-focus face
	foreach c text [do-event/with 'key c]
	do-event/with 'key 'enter
]