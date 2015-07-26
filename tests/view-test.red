Red [
	Needs: 'View
]

system/view/debug?: yes

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

win: make face! [type: 'window text: "Red View" offset: 500x500 size: 500x500]

button: make face! [
	type: 'button
	text: "Hello"
	offset: 100x10
	size: 60x40
	actors: object [
		on-click: func [face [object!] event [event!]][
			;face/color: red
			face/size: face/size + (5x5 - random 10x10)
			face/offset: face/offset + (5x5 - random 10x10)
			win/text: "Hello World"
			show win
		]
	]
]

win/pane: reduce [
	make face! [type: 'button text: "Hi" offset: 10x10 size: 60x40]
	button
	make face! [
		type: 'field text: "<type here>" offset: 10x80 size: 80x24
		color: 255.218.18
		actors: object [
			on-change: func [face [object!] event [event!]][
				print ["field changed:" mold face/text]
			]
		]
	]
	simple: make face! [type: 'base offset: 100x80 size: 80x24 visible?: no color: red]
	make face! [
		type: 'button text: "Show/Hide" offset: 200x80 size: 70x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				simple/visible?: not simple/visible?
				show simple
			]
		]
	]
	make face! [
		type: 'drop-down
		text: "type"
		offset: 100x120
		size: 80x24
		color: 240.230.140
		data: [
			"option 1"		11
			"option 2"		22
			"option 3"		33
		]
		actors: object [
			on-select: func [face [object!] event [event!]][
				probe face/text
			]
			on-change: func [face [object!] event [event!]][
				print ["changed:" mold face/text]
			]
		]
	]
	drop-list: make face! [
		type: 'drop-list
		offset: 200x120
		size: 80x24
		data: [
			"option 10"		110
			"option 20"		220
			"option 30"		330
			"option 40"		440
			"option 50"		550
		]
		actors: object [
			on-make: func [face [object!]][
				face/selected: 2
			]
			on-select: func [face [object!] event [event!]][
				print ["selected:" face/selected]
			]
			on-change: func [face [object!] event [event!]][
				print ["changed:" face/selected]
			]
		]
	]
	make face! [
		type: 'button text: "Set option 5" offset: 300x120 size: 80x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				drop-list/selected: 5
				show drop-list
			]
		]
	]
	group: make face! [
		type: 'group-box text: "Group box" offset: 10x150 size: 180x150
		pane: reduce [
			make face! [type: 'button text: "Inside" offset: 20x20 size: 60x40]
			set 'progress make face! [
				type: 'progress offset: 10x80 size: 120x16
			]
			set 'progress-text make face! [
				type: 'text text: "0" offset: 140x80 size: 30x16 color: white
			]
			make face! [
				type: 'slider offset: 10x110 size: 120x24
				data: 50%
				actors: object [
					on-make: func [face [object!]][
						on-change face none
					]
					on-change: func [face [object!] event [event! none!]][
						;print ["slider changed:" face/data]
						progress/data: face/data
						progress-text/text: form 
							to percent! (round face/data * 100) / 100.0
						show progress
						show progress-text
					]
				]
			]
		]
	]
	set 'progress2 make face! [
		type: 'progress offset: 200x170 size: 16x120
	]
	make face! [
		type: 'slider offset: 230x170 size: 24x120
		data: 25%
		actors: object [
			on-make: func [face [object!]][
				on-change face none
			]
			on-change: func [face [object!] event [event! none!]][
				print ["slider changed:" face/data]
				progress2/data: face/data
				show progress2
			]
		]
	]
	
	make face! [
		type: 'check text: "check box" offset: 300x170 size: 90x24
		data: on
		actors: object [
			on-change: func [face [object!] event [event!]][
				probe face/data
			]
		]
	]
	make face! [
		type: 'radio text: "radio 1" offset: 300x200 size: 90x24
		;data: on
		actors: object [
			on-change: func [face [object!] event [event!]][
				print "radio 1 set"
			]
		]
	]
	make face! [
		type: 'radio text: "radio 2" offset: 300x230 size: 90x24
		data: on
		actors: object [
			on-change: func [face [object!] event [event!]][
				print "radio 2 set"
			]
		]
	]
	make face! [
		type: 'image offset: 280x10 size: 100x100
		data: [%..\bridges\android\samples\eval\res\drawable-xxhdpi\ic_launcher.png]
	]
	make face! [
		type: 'tab-panel offset: 10x320 size: 250x130
		data: [
			"tab 1" []
			"tab 2" []
			"tab 3" []
		]
		pane: reduce [
			make face! [
				type: 'panel
				pane: reduce [
					make face! [
						type: 'button text: "Panel 1" offset: 20x20 size: 60x30
					]
				]
			]
			make face! [
				type: 'panel
				pane: reduce [
					make face! [
						type: 'text text: "Panel 2" offset: 80x80 size: 60x30
					]
				]
			]
			make face! [
				type: 'panel
				pane: reduce [
					make face! [
						type: 'text text: "Panel 3" offset: 90x40 size: 60x30
					]
				]
			]
		]
		actors: object [
			on-change: func [face [object!] event [event!]][
				print "radio 2 set"
			]
		]
	]
]
show win

do-events