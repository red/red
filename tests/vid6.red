Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid6.red
	Needs:	 'View
]

system/view/VID/debug?: yes
view [
    below left	 button "OK" field drop-down check yellow return
    below center button "OK" field drop-down check yellow return
    below right  button "OK" field drop-down check yellow
]
system/view/VID/debug?: no