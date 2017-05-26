Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid3.red
	Needs:	 'View
]

view [
	title "VID test 3"
	style vguide: base 1x710 draw [pen red line 0x0 0x710]
	
	at 9x10 b: vguide
	at b/offset + 301x0 vguide
	
	below
	
	panel 300x30 "Panel" green
	group-box "Group-box" 300x30 []
	tab-panel 300 ["tab1" [] "tab2" []]
	slider 5% 300 ;blue
	bar: progress 50% 300
	base 255.0.0.138  300 "Base"
	
	button "Button" 300
	text   "Text"	300 cyan
	check  "Check"  300 yellow
	radio  "Radio"  300 yellow
	field  "Field"  300
	
	camera 300x30
	
	text-list 300 data ["one" "two" "three" "four"]
	drop-list 300 data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down 300 data ["one" "two" "three" "four"]
	
]
