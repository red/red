Red [Needs: 'View]

#include %../environment/console/help.red

console: make face! [
	type: 'console size: 640x400
	font: make font! [name: "Consolas" size: 11]
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

view/flags win [resize]