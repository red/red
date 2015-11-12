Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid.red
	Needs:	 'View
]

view [
	;below
	text "Hello"
	button "Hello" 100x40 on-click [bar/data: random 100%]
	button "World"
	return

	button "China"
	text "Red Language" 100 right
	field 120
	return
	
	slider 50%
	bar: progress 5%
	return
	
	check "option 1"
	check "option 2"
	radio "option 3"
	radio "option 4"
	return
]

