Red [
	Title:	"GUI-related mezzanines"
	Author: "Nenad Rakocevic"
	File: 	%utils.red
	Tabs: 	4
	Rights: "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

hex-to-rgb: function [
	"Converts a color in hex format to a tuple value; returns NONE if it fails"
	hex		[issue!] "Accepts #rgb, #rrggbb, #rrggbbaa"	 ;-- 3,6,8 nibbles supported
	return: [tuple! none!]								 ;-- 3 or 4 bytes long
][
	switch length? str: form hex [
		3 [
			uppercase str
			forall str [str/1: str/1 - pick "70" str/1 >= #"A"]

			as-color 
				shift/left to integer! str/1 4
				shift/left to integer! str/2 4
				shift/left to integer! str/3 4
		]
		6 [if bin: to binary! hex [as-color bin/1 bin/2 bin/3]]
		8 [if bin: to binary! hex [as-rgba bin/1 bin/2 bin/3 bin/4]]
	]
]

within?: function [
	"Return TRUE if the point is within the rectangle bounds"
	point	[pair!] "XY position"
	offset  [pair!] "Offset of area"
	size	[pair!] "Size of area"
	return: [logic!]
][
	to logic! all [
		point/x >= offset/x
		point/y >= offset/y
		point/x < (offset/x + size/x)
		point/y < (offset/y + size/y)
	]
]

overlap?: function [
	"Return TRUE if the two faces bounding boxes are overlapping"
	A		[object!] "First face"
	B		[object!] "Second face"
	return: [logic!]  "TRUE if overlapping"
][
	A1: A/offset
	B1: B/offset
	A2: A1 + A/size
	B2: B1 + B/size
	make logic! all [A1/x < B2/x B1/x < A2/x A1/y < B2/y B1/y < A2/y]
]

distance?: function [
	"Returns the distance between the center of two faces"
	A		[object!] "First face"
	B		[object!] "Second face"
	return: [float!]  "Distance between them"
][
	square-root
		((A/offset/x - B/offset/x + (A/size/x - B/size/x / 2)) ** 2)
		+ ((A/offset/y - B/offset/y + (A/size/y - B/size/y / 2)) ** 2)
]