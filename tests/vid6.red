Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid6.red
	Needs:	 'View
]

system/view/VID/debug?: yes
view [
	at 320x1 base 1x400 black
    below left	 base 200x1 button 50x50 button "OK" text "text" cyan field drop-down check yellow radio yellow drop-list progress slider return
    below center base 200x1 button 50x50 button "OK" text "text" cyan field drop-down check yellow radio yellow drop-list progress slider return
    below right  base 200x1 button 50x50 button "OK" text "text" cyan field drop-down check yellow radio yellow drop-list progress slider
]
system/view/VID/debug?: no