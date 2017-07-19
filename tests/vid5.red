Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid5.red
	Needs:	 'View
]

system/view/VID/debug?: yes
view [
	at 1x110 base 1100x1 black
    across top	  base 1x60 button 50x50 button "OK" text "text" cyan field drop-down drop-list check yellow radio yellow progress slider return
    across middle base 1x60 button 50x50 button "OK" text "text" cyan field drop-down drop-list check yellow radio yellow progress slider return
    across bottom base 1x60 button 50x50 button "OK" text "text" cyan field drop-down drop-list check yellow radio yellow progress slider 
]
system/view/VID/debug?: no