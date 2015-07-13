Red [
	Needs: 'View
]

workstation?: system/view/platform/product = 1

print [
	"Windows" switch system/view/platform/version [
		10.0.0	[pick ["10"			 "10 Server"	 ] workstation?]
		6.3.0	[pick ["8.1"		 "Server 2012 R2"] workstation?]
		6.2.0	[pick ["8"			 "Server 2012"	 ] workstation?]
		6.1.0	[pick ["7"			 "Server 2008 R1"] workstation?]
		6.0.0	[pick ["Vista"		 "Server 2008"	 ] workstation?]
		5.2.0	[pick ["Server 2003" "Server 2003 R2"] workstation?]
		5.1.0	["XP"]
		5.0.0	["2000"]
	] 
	"build" system/view/platform/build
]

win: make face! [type: 'window text: "Red View" offset: 500x500 size: 400x400]

button: make face! [
	type: 'button
	text: "Hello"
	offset: 100x10
	size: 60x40
	actors: object [
		on-click: func [face [object!] event [event!]][
			face/color: red
			probe face
			print "Hello!"
		]
	]
]

win/pane: reduce [
	make face! [type: 'button text: "Hi" offset: 10x10 size: 60x40]
	button
	make face! [type: 'field text: "<type here>" offset: 10x80 size: 80x24]
	make face! [type: 'base offset: 100x80 size: 80x24]
]
show win

do-events