Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid.red
	Needs:	 'View
]

view [
	below
	text "Hello"
	button "Hello" 100x40 ;on-click [sld/data: random 100%]
	button "World"
	return

	button "China"
	text "Red Language" 100 right
	field 120
	return
	
	sld: slider 50%
	progress 25%
	return
	
	check "option 1"
	check "option 2"
	radio "option 3"
	radio "option 4"
	return
]

