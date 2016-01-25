Red [
	Title:   "GUI event flows testing script"
	Author:  "Nenad Rakocevic"
	File: 	 %events-flow.red
	Needs:	 'View
]

view/options [
	panel 200x200 blue [
		panel 150x150 green [
			base 50x50 red 
				on-down [print "5"]
				on-detect [if event/type = 'down [print "4"]]
		]
		on-down [print "6"]
		on-detect [if event/type = 'down [print "3"]]
	]
	on-down [print "7"]
	on-detect [if event/type = 'down [print "2"]]
][
	actors: object [
		on-down: func [f e][print "8"]
		on-detect: func [f e][if e/type = 'down [print "----^/1"]]
	]
]