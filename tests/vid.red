Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid.red
	Needs:	 'View
]

view [
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
	
	slider 50%
	bar: progress 5%
	return
	
	check "option 1"
	check "option 2"
	radio "option 3"
	radio "option 4"
	return
	
	text-list data ["one" "two" "three" "four"] ;[probe pick face/data event/selected]
	drop-list data ["one" "two" "three" "four"] 
	drop-down data ["one" "two" "three" "four"]
]
