Red [
	Purpose: "Test GTK auto change size of widget"
	Needs: 'View
]

system/view/debug?: no



win: make face! [
	type: 'window text: "Red View" size: 600x400
]

field: make face! [
	type: 'field
	para: make para! [align: 'left]
	text: "Font size"
	offset: 10x10 size: 80x20
]

; but1: make face! [type: 'button text: "+" offset: 100x10 size: 40x20]

; but2: make face! [type: 'button text: "-" offset: 150x10 size: 40x20]

; win/pane: reduce [field but1 but2]
; view/flags win [resize]

smiley: make image! 23x24
image: load %../../bridges/android/samples/eval/res/drawable-xxhdpi/ic_launcher.png
