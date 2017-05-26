Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid4.red
	Needs:	 'View
]

view [
	title "VID test 4"
	style hguide: base 1040x1 draw [pen red line 0x0 1040x0]
	
	at 10x9 b: hguide
	at b/offset + 0x301 hguide
	
	panel 50x300 "Panel" green
	group-box "Group-box" 100x300 []
	tab-panel 100x300 ["tab1" [] "tab2" []]
	slider 5% 50x300 ;blue
	bar: progress 50% 50x300
	base 255.0.0.138  50x300 "Base"
	
	button "Button" 80x300
	text   "Text"	50x300 cyan
	check  "Check"  50x300 yellow
	radio  "Radio"  50x300 yellow
	field  "Field"  50x300
	
	camera 50x300
	
	text-list 50x300 data ["one" "two" "three" "four"]
	drop-list 50x300 data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down 50x300 data ["one" "two" "three" "four"]
	
]
