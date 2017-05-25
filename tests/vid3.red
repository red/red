Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid3.red
	Needs:	 'View
]

view [
	title "VID test 3"
	style vguide: base 1x700 draw [pen red line 0x0 0x700]
	
	at 9x10 b: vguide
	at b/offset + 251x0 vguide
	
	below
	
	panel 250x30 "Panel" green
	group-box "Title" 250 []
	tab-panel 250 ["tab1" [] "tab2" []]
	slider 5% 250 ;blue
	bar: progress 50% 250
	base 255.0.0.138  250
	
	button "Hello"    250
	text   "World"	  250 cyan
	check  "option 1" 250 yellow
	radio  "option 2" 250 yellow
	field  "edit me"  250
	
	camera 250x30
	
	text-list 250 data ["one" "two" "three" "four"]
	drop-list 250 data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down 250 data ["one" "two" "three" "four"]
	
]
