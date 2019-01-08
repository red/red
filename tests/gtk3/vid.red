Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid.red
	Needs:	 'View
]
system/view/debug?: no ;yes

view [
	title "VID test"
	;below
	text "Hello" font [name: "Nimbus Sans L" size: 12 color: 112.13.114]
	button "Hello" 100x40 [bar/data: random 100%]
	button "World" underline italic [opt4/data: yes opt1/data: no]
	return

	button "China"
	text "Red Language" 100 right bold font [color: red]
	field 120 on-enter [probe do face/text clear face/text print "ici"] on-key [print [event/type event/key event/shift? event/ctrl? lf] ]
	return
	
	group-box 3 [
		style but: button 25 font [name: "Comic Sans MS" size: 12 color: blue]
		
		base 0.233.1.177 "ok" 25x25
		text "in panel"
		text ""
		
		but "A" but "B" but "C" 
		but "D" but "E"	but "F"
	]
	tab-panel [
	 	"tab1" [at 10x10 base 0.2.233.188 15x15 at 50x50 button "one"]
	 	"tab2" [at 80x10 text "two"]
	] on-change [print ["selected: " face/selected face/text lf]]
	
	below
	slider 5% react [bar/data: face/data]
	pad 10x0 bar: progress 50% 130
	base 255.0.0.138 50x50 draw [fill-pen blue circle 25x25 15]
	across
	return middle
	
	group-box [
		opt1: check "option 1" font-size 14
		check "option 2" font-color orange
		radio "option 3" font-name "Times New Roman"
		opt4: radio "option 4"
	]
	return top
	
	list: text-list data ["one" "two" "three" "four" "one" "two" "three" "four" "one" "two" "three" "four" "one" "two" "three" "four"] [print [pick face/data face/selected lf face/selected face/text lf] ]
	drop-list data ["one" 4 "two" 5 "three" 6 "four" 7] 
	drop-down data ["one" "two" "three" "four"]
	
	return
	
	style but1:  button
	style txt1:  text 30
	style base1: base 10x10
	
	but1 "1" txt1 "1" base1 "1"
	return
	group-box [
		style but1:  but1 font-color red
		style txt1:  txt1 red center
		style base1: base1 red
		
		but1 "1" txt1 "1" base1 "1"
	] return
	but1 "1" txt1 "1" base1 "1"
	
	at (list/offset + 130x50) base 5x5 red
	
	do [append list/data "three" win: self]
]
