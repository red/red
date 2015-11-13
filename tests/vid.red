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
		below
		text "in panel"
		button "A"
		button "B"
		button "C"
	]
	tab-panel [
		"tab1" [at 50x50 button "one"]
		"tab2" [at 80x10 text "two"]
	]
	
	below
	slider 50%
	bar: progress 5%
	across
	return
	
	check "option 1"
	check "option 2"
	radio "option 3"
	radio "option 4"
	return
	
	text-list data ["one" "two" "three" "four"] ;[probe pick face/data event/selected]
	drop-list data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down data ["one" "two" "three" "four"]
	
]
