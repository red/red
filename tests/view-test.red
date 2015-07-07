Red [
	Needs: 'View
]

win: make face! [type: 'window text: "Red View" offset: 500x500 size: 400x400]

win/pane: reduce [
	make face! [type: 'button text: "Hi" offset: 10x10 size: 60x40]
	make face! [type: 'button text: "Hello" offset: 100x10 size: 60x40]
	make face! [type: 'field text: "<type here>" offset: 10x80 size: 80x24]
	make face! [type: 'base offset: 100x80 size: 80x24]
]
show win

do-events