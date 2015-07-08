Red [
	Needs: 'View
]

print [
	"Windows" select [
		10.0.0	"10"
		6.3.0	"8.1"
		6.2.0	"8"
		6.1.0	"7"
		6.0.0	"Vista"
		5.2.0	"Server 2003"
		5.1.0	"XP"
		5.0.0	"2000"
	] system/view/platform/version 
	
	"build" system/view/platform/build
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