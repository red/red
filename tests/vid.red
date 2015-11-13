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
	
	group-box [
		style but: button 25 font [name: "Comic Sans MS" size: 12 color: blue]
		
		below
		base red "ok" 25x25
		text "in panel"
		but "A"
		but "B"
		but "C"
	]
	tab-panel [
		"tab1" [at 50x50 button "one"]
		"tab2" [at 80x10 text "two"]
	]
	
	below
	slider 5%
	pad 10x0 bar: progress 50% 130
	across
	return
	
	check "option 1" font-size 14
	check "option 2" font-color orange
	radio "option 3" font-name "Times New Roman"
	radio "option 4"
	return
	
	text-list data ["one" "two" "three" "four"] ;[probe pick face/data event/selected]
	drop-list data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down data ["one" "two" "three" "four"]
	
]
