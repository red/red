Red [
	Purpose: "Test the GUI auto-update mode"
	Needs: 'View
]

system/view/debug?: yes
live?: system/view/auto-sync?: no

workstation?: system/view/platform/product = 1
os-version: system/view/platform/version

#switch config/OS [
	Windows [
		print [
			"Windows" switch os-version [
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
	]
	MacOSX [
		print [
			"macOS" switch os-version and 255.255.0 [
				10.11.0	["El Capitan"]
				10.10.0	["Yosemite"]
				10.9.0	["Mavericks"]
				10.8.0	["Mountain Lion"]
				10.7.0	["Lion"]
				10.6.0	["Snow Leopard"]
			] os-version
			"build" system/view/platform/build
		]
	]
]

smiley: make image! [23x24 #{
F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2CCCC
CCCCCCCCDEDEDDF2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2
F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F292908F5C5951
444238615E496965515C594B4B494258554C8F8E8CDEDEDDF2F2F2F2F2F2F2F2
F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2999999312D2788
8462D0CB8DFEF9ACFEF9ACFEF9ACFEF9ACF5F0A6D0CB8D949068646253918F8C
E7E7E7F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2E7E7E76B695F6664
4EE8E39DFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACE1
DC9984805A6B695FE7E7E7F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2E7E7E76B695F
949068F5F0A6FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9
ACFEF9ACFEF9ACFEF9ACA29D6E312D27DEDEDDF2F2F2F2F2F2F2F2F2F2F2F275
736B8A865EFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC
FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACB2AE796B695FE7E7E7F2F2F2F2F2
F2B8B7B65A5743F0ECA3FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFE
F9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC84805A8F8E8C
F2F2F2F2F2F249463ECBC78AFEF9ACFEF9ACFEF9AC6E6A4B1714118A865EFEF9
ACFEF9ACFEF9ACFEF9ACFEF9ACA7A37217141144412FF0ECA3FEF9ACFEF9ACE5
E09B5C594BDEDEDDB8B7B6615E49FEF9ACFEF9ACFEF9ACC2BE84171411171411
171411FEF9ACFEF9ACFEF9ACFEF9ACFEF9AC514D38171411171411999966FEF9
ACFEF9ACFEF9AC84805AA2A1A07E7C78A29D6EFEF9ACFEF9ACFEF9ACF0ECA325
211A171411514D38FEF9ACFEF9ACFEF9ACFEF9ACFEF9AC7C795517141125211A
E1DC99FEF9ACFEF9ACFEF9ACC2BE845C59516B695FD0CB8DFEF9ACFEF9ACFEF9
ACFEF9ACF0ECA3C2BE84FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACD3
CF8FE1DC99FEF9ACFEF9ACFEF9ACFEF9ACF5F0A6312D27444238F0ECA3FEF9AC
FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9
ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC3C393225211AFE
F9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC
FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC4743
3A4B4942E5E09BFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFE
F9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC
FEF9AC312D27636159CBC78AFEF9ACFEF9ACFEF9AC25211ADCD896FEF9ACFEF9
ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC333024F0ECA3FE
F9ACFEF9ACE5E09B47433A888685949068FEF9ACFEF9ACFEF9ACBFBA815A5743
E5E09BFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFAF5AA706C4D8480
5AFEF9ACFEF9ACFEF9ACAFAB7775736BD7D6D63C3932FAF5AAFEF9ACFEF9ACFE
F9AC99996644412FE5E09BFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC949068
514D38FEF9ACFEF9ACFEF9ACFEF9AC54503EBBBAB9F2F2F2636159A29D6EFEF9
ACFEF9ACFEF9ACFEF9ACA7A3724C4935928E64DEDA97F0ECA3E8E39DBDB88069
6648706D4FE5E09BFEF9ACFEF9ACFEF9ACCBC78A3C3932F2F2F2F2F2F2DEDEDD
5A5743DEDA97FEF9ACFEF9ACFEF9ACFEF9ACE5E09B8E8A61615E4356523B5652
3B696648B7B37DFAF5AAFEF9ACFEF9ACFEF9ACEEE9A166644EB8B7B6F2F2F2F2
F2F2F2F2F2A6A5A454503EFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC
FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9AC747051817F79F2F2
F2F2F2F2F2F2F2F2F2F2F2F2F286858154503EDCD896FEF9ACFEF9ACFEF9ACFE
F9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACE8E39D706D4F807E76
F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2ABAAA9646253A29D6EF0EC
A3FEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACFEF9ACF5F0A6ACA87569655188
8685F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2CCCCCC
736B6B514D387A7656AFAB77D3CF8FE1DC99D3CF8FB7B37D837F59312D27615E
56CCCCCCF2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2
F2F2F2F2F2F2F2F2E7E7E7A2A1A06361594B4942403C334B4942636159999999
DEDEDDF2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2F2} #{
FFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000
0000000000000000FFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000
00FFFFFFFFFFFFFF0000000000000000000000000000000000FFFFFFFFFF0000
0000000000000000000000000000000000FFFFFFFF0000000000000000000000
000000000000000000FFFF000000000000000000000000000000000000000000
FFFF000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
00000000000000FF000000000000000000000000000000000000000000FFFF00
0000000000000000000000000000000000000000FFFFFF000000000000000000
00000000000000000000FFFFFFFFFF0000000000000000000000000000000000
FFFFFFFFFFFFFF000000000000000000000000000000FFFFFFFFFFFFFFFFFF00
000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF0000000000000000
00FFFFFFFFFFFFFF
}]

sub-win: make face! [
	type: 'window text: "Sub 1-View" offset: 200x200 size: 200x100
	pane: reduce [
		make face! [type: 'text text: "New window" offset: 10x10 size: 80x20 color: white]
		make face! [
			type: 'button text: "Close" offset: 120x10 size: 60x20
			actors: object [
				on-click: func [face [object!] event [event!]][unview/all]
			]
		]
	]
]

sub-win2: make face! [
	type: 'window text: "Sub 2-Show" offset: 200x200 size: 200x100
	pane: reduce [
		make face! [type: 'text text: "New window" offset: 10x10 size: 80x20 color: white]
		make face! [
			type: 'button text: "Close" offset: 120x10 size: 60x20
			actors: object [
				on-click: func [face [object!] event [event!]][unview]
			]
		]
	]
]
	
;; requires pane cursor to be moved back in closing event handler

win: make face! [
	type: 'window text: "Red View" size: 1100x800
	menu: [
		;popup						;-- forces context menu for window
		"File" [
			"New"				new
			"Open...	F1" 	open
			"Close	F2"			close 
			---
			"Save..."			save
			"Save as..."		save-as
			"Save All"			save-all
			---
			"Print..."			print
			"Preview"			preview
			"Page Setup..."		page-setup
			---
			"Exit"				exit
		]
		"Edit" [
			"Undo"				undo
			"Redo"				redo
			---
			"Copy	Ctrl+C"		copy
			"Cut	Ctrl+X"		cut
			"Paste	Ctrl+V"		paste
			---
			"Sub1" [
				"Sub-menu1"		sub-m1
			]
			"Sub2" [
				"Sub-menu2"		sub-m2
			]
		]
		"Search" [
			"Find..."			find
			"Find Next"			find-next
			"Find Previous"		find-prev
			---
			"Replace..."		replace
			"Replace Next"		replace-next
		]
		"Deep" [
			"Item 2"			item2
			"Deep 2" [
				"Item 3"		item3
				"Deep 3" [
					"End"		end
				]
			]
		]
	]
	actors: object [
		on-menu: func [face [object!] event [event!]][
			print ["menu selected:" event/picked]
			switch event/picked [
				exit [
					print "calling unview"
					unview/all
				]
				sub-m1 [
					;just to test change of a button's text..
					win/pane/1/text: "Hello"
					show win/pane/1
				]
			]
		]
		on-close: func [face [object!] event [event!]][
			print "closing window"
		]
		on-key: func [face [object!] event [event!]][
			if event/key = 'F5 [
				print "F5 key caught by window face!" 
				'stop
			]
		]
	]
]

canvas: make face! [
	type: 'base offset: 0x0 size: 300x200 color: silver
	draw: [
		image smiley 10x30

		line-cap round
		pen red
		line 10x10 130x190 80x40 150x100
		
		pen blue
		line-width 4
		line-join round
		line 15x190 50x50 190x180
		
		pen green
		line-join miter
		box 10x120 70x160
		
		line-width 1
		pen maroon
		fill-pen orange
		box 150x80 180x120
		
		fill-pen off
		pen red
		triangle 170x10 170x50 195x50
		
		pen yellow fill-pen orange
		line-width 5
		line-join bevel
		polygon 120x130 120x190 180x130 180x190

		line-width 1
		pen purple
		fill-pen purple
		box 220x10 280x70 10
		pen gray
		fill-pen white
		ellipse 240x20 20x40
		
		fill-pen red
		circle 250x150 49.5
		pen gray
		fill-pen white
		circle 250x150 40
		fill-pen red
		circle 250x150 30
		fill-pen blue
		circle 250x150 20
		pen blue
		fill-pen white
		polygon 232x144 245x144 250x130 255x144 268x144
			257x153 260x166 250x158 239x166 243x153

		font font-A
		text 40x6 "Scroll Me with mouse wheel :-)"
		
		arc 100x25 80x80 0 90 closed
		pen red
		arc 100x25 50x80 30 90

		curve 20x150 60x250 200x50
		curve 224x14 220x40 280x40 276x66
	]
]

but-extra: make face! [
	type: 'button text: "Extra" offset: 400x500 size: 40x25
	actors: object [
		on-click: func [face [object!] event [event!]][		;-- `function` would prevent compilation here
			tab-panel/data: ["file1" "file2"]
			tab-panel/pane: reduce [
				make face! [
					type: 'panel
					pane: reduce [
						make face! [
							type: 'text text: "Panel File 1" offset: 90x40 size: 60x30
						]
					]
				]
				make face! [
					type: 'panel
					pane: reduce [
						make face! [
							type: 'text text: "Panel File 2" offset: 80x80 size: 60x30
						]
					]
				]
			]
			drop-down/data: ["1" 1 "2" 2 "3" 3 "4" 4]
			unless live? [show [tab-panel drop-down]]
		]
	]
]

panel-extra: make face! [
	type: 'panel
	pane: reduce [
		make face! [
			type: 'text text: "Panel 4" offset: 20x80 size: 60x30
		]
	]
]

button: make face! [
	type: 'button
	text: "Hello"
	offset: 100x10
	size: 60x40
	actors: object [
		on-click: function [face [object!] event [event!]][
			;face/color: red
			face/size: face/size + (5x5 - random 10x10)
			face/offset: face/offset + (5x5 - random 10x10)
			win/text: "Hello World"
			probe type? reflect win/pane 'owned

			either pos: find win/pane but-extra [
				remove pos
				remove skip tail win/menu/4 -2
			][
				append win/pane but-extra
				append win/menu/4 ["Inserted" inserted]
			]
			unless live? [show win]
		]
	]
]

button/font: make font! [
	name: "Comic Sans MS"
	size: 16
	style: [bold italic underline strike]
	anti-alias?: yes
	color: red
]

font-A: make font! [
	name: "Comic Sans MS"
	size: 10
	color: blue
	style: [bold italic underline]
	anti-alias?: yes
]

h-modes: [left center right center]
v-modes: [middle top middle bottom]

win/pane: reduce [
	hi: make face! [
		type: 'button text: "Hi" offset: 10x10 size: 60x40
		para: make para! [align: 'left]
		actors: object [
			on-click: func [face [object!] event [event!]][
				print "Testing error handling in awake event: 1 / 0"
				probe 1 / 0
			]
		]
	]
	button
	make face! [
		type: 'button text: "Change" offset: 180x10 size: 60x40
		actors: object [
			on-click: func [face [object!] event [event!]][
				clear back back tail drop-list/data
				check-face/data: not check-face/data
				remove at text-list/data 4
				insert at text-list/data 2 random "helloworld"
				insert text-list/data/1 #"o"
				unless "tab 4" = last tab-panel/data [
					append tab-panel/data "tab 4"
					append tab-panel/pane panel-extra
				]
				button/size/x: button/size/x - 1
				simple/color/2: random 255
				simple/color/3: random 255

				if tail? h-modes: next h-modes [h-modes: head h-modes]
				hi/para/align: h-modes/1

				if tail? v-modes: next v-modes [v-modes: head v-modes]
				hi/para/v-align: v-modes/1

				unless live? [
					show [drop-list check-face text-list button simple tab-panel hi]
				]
				print [{"Hello" size:} size-text button]
				print [{"Base" size:} size-text base-face]
			]
		]
	]
	make face! [
		type: 'check text: "Debug?" offset: 300x270 size: 80x24
		font: font-A
		data: system/view/debug?
		actors: object [
			on-change: func [face [object!] event [event!]][
				system/view/debug?: face/data
			]
		]
	]
	make face! [
		type: 'check text: "Big/small font" offset: 300x300 size: 80x24
		data: yes
		para: make para! [wrap?: yes]
		actors: object [
			on-change: func [face [object!] event [event!]][
				button/font/size: pick [12 20] face/data
				unless live? [show button]
			]
		]
	]
	make face! [
		type: 'check text: "Italic?" offset: 300x330 size: 80x24
		data: yes
		actors: object [
			on-change: function [face [object!] event [event!]][
				alter button/font/style 'italic
				unless live? [show button]
			]
		]
	]
	edit: make face! [
		type: 'field text: {unicode supported: $€𐐷𤭢} offset: 10x80 size: 160x24
		color: 255.218.18
		para: make para! [align: 'left]
		actors: object [
			on-change: func [face [object!] event [event!]][
				print ["field changed:" mold face/text]
			]
		]
	]
	make face! [
		type: 'area text: {Multiline area widget} offset: 580x24 size: 160x100
		font: font-A
		actors: object [
			on-change: func [face [object!] event [event!]][
				print ["field changed:" mold face/text]
			]
		]
	]
	simple: make face! [type: 'base offset: 200x50 size: 80x24 visible?: no color: red]
	make face! [
		type: 'button text: "Show/Hide" offset: 200x80 size: 70x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				simple/visible?: not simple/visible?
				unless live? [show simple]
			]
		]
	]
	drop-down: make face! [
		type: 'drop-down
		text: "type"
		offset: 100x120
		size: 80x24
		font: font-A
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
			on-create: func [face [object!]][
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
				unless live? [show drop-list]
			]
		]
	]
	group: make face! [
		type: 'group-box text: "Group box" offset: 10x150 size: 180x150
		pane: reduce [
			make face! [type: 'button text: "Inside" offset: 20x20 size: 60x40]
			set 'progress make face! [
				type: 'progress offset: 10x80 size: 120x16
				menu: [
					"Set to 0%"		s0
					"Set to 25%"	s25
					"Set to 50%"	s50
					"Set to 100%"	s100
				]
				actors: object [
					on-menu: func [face [object!] event [event!]][
						print ["context menu selected:" event/picked]
						face/data: load append next form event/picked #"%"
						unless live? [show face]
					]
				]
			]
			set 'progress-text make face! [
				type: 'text text: "0" offset: 140x80 size: 30x16 color: white
			]
			make face! [
				type: 'slider offset: 10x110 size: 120x24
				data: 50%
				actors: object [
					on-create: func [face [object!]][
						on-change face none
					]
					on-change: func [face [object!] event [event! none!]][
						;print ["slider changed:" face/data]
						progress/data: face/data
						progress-text/text: form round to-percent face/data
						unless live? [show [progress progress-text]]
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
			on-create: func [face [object!]][
				on-change face none
			]
			on-change: func [face [object!] event [event! none!]][
				print ["slider changed:" face/data]
				progress2/data: face/data
				unless live? [show progress2]
			]
		]
	]
	
	check-face: make face! [
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
		font: font-A
		options: [drag-on: 'down]
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
		type: 'base offset: 280x10 size: 100x100
		options: [drag-on: 'down]
		image: load %../bridges/android/samples/eval/res/drawable-xxhdpi/ic_launcher.png
	]
	tab-panel: make face! [
		type: 'tab-panel offset: 10x320 size: 250x130
		data: [
			"tab 1"
			"tab 2"
			"tab 3"
		]
		pane: reduce [
			make face! [
				type: 'panel
				pane: reduce [
					make face! [
						type: 'button text: "Panel 1" offset: 20x20 size: 60x30
					]
				]
				menu: [
					"Context menu 1"	menu1
					"Context menu 2"	menu2
					"Context menu 3"	[
						"sub 1"		sub1
						"sub 2"		sub2
					]
				]
				actors: object [
					on-menu: func [face [object!] event [event!]][
						print ["context menu selected:" event/picked]
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
				print ["Switched to:" pick face/data event/picked]
			]
		]
	]
	text-list: make face! [
		type: 'text-list offset: 400x20 size: 165x100
		font: font-A
		data: [
			"Book 1"
			"Book 2"
			"Book 3"
			"Book 4"
			"Book 5"
			"Red Programming Language"
			"Red编程语言"
			"FullStack Programming Language"
			"全栈编程语言"
			"hahahaha~"
			"哈哈哈哈~"
		]
		actors: object [
			on-select: func [face [object!] event [event!]][
				print ["text-list selected:" face/selected]
				face/text: pick face/data face/selected
				print ["text-list selected:" mold face/text]
			]
			on-change: func [face [object!] event [event!]][
				print ["text-list changed:" face/selected]
				face/text: pick face/data face/selected
				print ["text-list changed:" mold face/text]
			]
		]
	]
	set 'cam make face! [
		type: 'camera offset: 400x140 size: 320x240
	]
	cam-list: make face! [
		type: 'drop-list offset: 480x402 size: 160x32
		actors: object [
			on-create: func [face [object!]][
				face/data: cam/data
			]
			on-change: func [face [object!] event [event!]][
				print ["changed:" face/selected]
				unless cam/selected = face/selected [
					cam/selected: face/selected
				]
				unless live? [show cam]
			]
		]
	]
	make face! [
		type: 'button text: "Start/Stop" offset: 400x400 size: 70x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				either cam/selected [
					cam/selected: none
				][
					cam/selected: cam-list/selected
				]
				unless live? [show cam]
			]
		]
	]
	make face! [
		type: 'button text: "Sub-window" offset: 400x440 size: 70x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				view sub-win
			]
		]
	]
	make face! [
		type: 'button text: "Sub-window 2" offset: 400x470 size: 70x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				show sub-win2
			]
		]
	]
	make face! [
		type: 'button text: "Quit" offset: 500x440 size: 60x24
		actors: object [
			on-click: func [face [object!] event [event!]][
				print "calling unview"
				unview/all
			]
		]
	]
	make face! [
		type: 'button offset: 570x440 size: 38x38
		image: smiley
	]
	make face! [										;-- clip view for canvas
		type: 'panel offset: 10x460 size: 300x200
		pane: reduce [canvas]
		actors: object [
			on-wheel: func [face [object!] event [event!]][
				print [face/type event/picked]
				canvas/offset/y: canvas/offset/y + event/picked
				unless live? [show canvas]
			]
		]
	]
	make face! [
		type: 'check text: "anti alias" offset: 265x430 size: 90x24
		data: on
		actors: object [
			on-change: func [face [object!] event [event!]][
				either face/data = off [
					insert canvas/draw [anti-alias off]
				][
					remove/part canvas/draw 2
				]
				unless live? [show canvas]
			]
		]
	]
	font-test: make face! [
		type: 'text text: "The quick brown fox jumps." offset: 500x500 size: 300x25
		font: make font! [
			name: "Times New Roman"
			size: 16
			style: 'italic
			anti-alias?: yes
		]
		actors: object [
			on-over: func [face [object!] event [event!]][
				face/font/style: pick [italic bold] event/away?
				tab-panel/selected: pick [1 2] event/away?
				unless live? [show [face tab-panel]]
			]
		]
	]
	dropped: make face! [
		type: 'base text: "Drop here" offset: 630x540 size: 80x80
		color: silver
		draw: [font font-A text 35x30 "0"]
		para: make para! [v-align: 'top]
	]
	base-face: make face! [
		type: 'base text: "Base face" offset: 630x630 size: 80x80
		color: beige
		font: make font! [
			name: "Times New Roman"
			size: 16
			style: 'italic
			anti-alias?: yes
		]
	]
	make face! [
		type: 'button text: "Drag me" offset: 550x540 size: 70x24
		options: [drag-on: 'down]
		actors: object [
			on-drag-start: func [face [object!] event [event!]][
				print "drag starts"
				;face/state/4: face/state/4 + 4x4
				;face/offset: face/offset - 4x4
				;unless live? [show face]
			]
			on-drag: func [face [object!] event [event!]][
				prin dot
			]
			on-drop: function [face [object!] event [event!]][
				print "dropping"
				;face/offset: face/offset + 4x4

				pos: face/offset + face/state/4 	;-- calculate mouse position
				if within? pos dropped/offset dropped/size [
					face/offset: 550x540
					dropped/draw/5: form 1 + to integer! dropped/draw/5
					unless live? [show [face dropped]]
				]
			]
		]
	]
	make face! [
		type: 'base offset: 750x140 size: 300x300 color: silver
		text: "Pinch me"
		draw: [fill-pen red polygon 100x100 250x100 250x250 100x250]
		actors: object [
			angle: 0
			center: 175x175
			sz: 75

			on-zoom: func [face [object!] event [event!] /local factor new][
				if factor: event/picked [
					new: to integer! sz * factor
					if new > 10 [
						sz: new	
						draw/4: center - as-pair sz sz
						draw/5: center + (1x-1 * sz)
						draw/6: center + as-pair sz sz
						draw/7: center + (-1x1 * sz)
						unless live? [show face]
					]
				]
			]
			on-rotate: func [face [object!] event [event!]][
				probe "rotating"
			]
		]
	]
]

append win/pane panel: make face! [
	type:	'panel
	offset: 400x550
	size:	80x80
	pane:	make block! 3
]
repeat i 3 [
	append panel/pane make face! [
		type:	'base
		size:	40x40
		offset: 10x10 * i
		text:	form i
		color:	red + (i * 50)
	]
]

append win/pane make face! [
	type: 'button
	text: "Reverse"
	offset: 400x640
	size: 60x24
	actors: object [
		on-click: func [face [object!] event [event!]][
			reverse panel/pane
			unless live? [show panel]
		]
	]
]

dump-face win
view/flags win [resize]
system/view/debug?: no
system/view/auto-sync?: yes