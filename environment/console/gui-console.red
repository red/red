Red [
	Title:		"Red GUI Console"
	File:		%gui-console.red
	Tabs:		4
	Icon:		default
	Version:	0.9.0
	Needs:		View
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

context [
	font-name: pick ["Fixedsys" "Consolas"] make logic! find [5.1.0 5.0.0] system/view/platform/version

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
				unless system/view/auto-sync? [show face]
			]
		]
		pane: reduce [console]
	]
	
	view/flags/no-wait win [resize]
	
	svs: system/view/screens/1
	svs/pane: next svs/pane
	
	system/console/launch
	
	do-events
]
