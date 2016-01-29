Red [
	Title:		"Red GUI Console"
	File:		%gui-console.red
	Tabs:		4
	Icon:		%../../tests/red.ico
	Version:	0.9.0
	Needs:		'View
	Config:		[gui-console?: yes]
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

ask: function [
	question [string!]
	return:  [string!]
][
	buffer: make string! 1
	buffer
]

input: does [ask ""]

system/view/init
font-name: either find [5.1.0 5.0.0] system/view/platform/version ["Fixedsys"]["Consolas"]

console: make face! [
	type: 'console size: 640x400
	font: make font! [name: font-name size: 11]
]

win: make face! [
	type: 'window text: "Red Console" size: 640x400 selected: console
	actors: object [
		on-close: func [face [object!] event [event!]][
			unview/all
		]
		on-resizing: func [face [object!] event [event!]][
			console/size: event/offset
		]
	]
	pane: reduce [console]
]

view/flags/no-wait win [resize]

svs: system/view/screens/1
svs/pane: next svs/pane

do-events