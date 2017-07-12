Red [
	Title:   "Red VID simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %vid5.red
	Needs:	 'View
]

system/view/VID/debug?: yes
view [
    across top	  base 1x50 button "OK" field drop-down check return
    across middle base 1x50 button "OK" field drop-down check return
    across bottom base 1x50 button "OK" field drop-down check
]
system/view/VID/debug?: no