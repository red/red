Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid.red
	Needs:	 'View
]

view [
	title "VID test"
	;below
	text "Hello"
	button "Hello" 100x40 [bar/data: random 100%]
	button "World"
	return

	button "China"
	text "Red Language" 100 right
	field 120 on-key [
		if event/key = cr [probe do face/text] 	; clear face/text
	]
	return
	
	group-box 3 [
		style but: button 25 font [name: "Comic Sans MS" size: 12 color: blue]
		
		base red "ok" 25x25
		text "in panel"
		but "A" but "B" but "C"
		but "D" but "E"	but "F"
	]
	tab-panel [
		"tab1" [at 50x50 button "one"]
		"tab2" [at 80x10 text "two"]
	]
	
	below
	slider 5%
	pad 10x0 bar: progress 50% 130
	base 50x50 draw [fill-pen blue circle 25x25 15]
	across
	return
	pad 0x-140
	
	check "option 1" font-size 14
	check "option 2" font-color orange
	radio "option 3" font-name "Times New Roman"
	radio "option 4"
	return
	
	list: text-list data ["one" "two" "three" "four"] ;[probe pick face/data event/selected]
	drop-list data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down data ["one" "two" "three" "four"]
	
	do [append list/data "five"]
]
