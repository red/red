Red [
	Title:   "SDL3 VID rules"
	File: 	 %rules.red
	Tabs:	 4
]

color-backgrounds: function [
	root [object!]
][
	foreach-face/with root [face/color: face/parent/color][
		all [
			none? face/color
			face/parent
			find [window panel] face/parent/type
			find [text slider radio check panel] face/type
		]
	]
]

color-tabpanel-children: function [
	root [object!]
][
	none
]

OK-Cancel: function [
	root [object!]
][
	none
]
