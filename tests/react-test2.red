Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test2.red
	Needs:	 'View
]

to-integer: function [str [string!]][
	either empty? str [0][to integer! str]
]

view [
	below
	A: field "0" right bold
	B: field "0" right bold
	
	text "0" 75 right bold react [
		face/text: form (to-integer A/text) + (to-integer B/text)
	]
]