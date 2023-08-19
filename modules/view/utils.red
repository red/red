Red [
	Title:	"GUI-related mezzanines"
	Author: "Nenad Rakocevic"
	File: 	%utils.red
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
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
			as-color  11h * str/1  11h * str/2  11h * str/3
		]
		6 [if bin: to binary! hex [as-color bin/1 bin/2 bin/3]]
		8 [if bin: to binary! hex [as-rgba bin/1 bin/2 bin/3 bin/4]]
	]
]

within?: function [
	"Return TRUE if the point is within the rectangle bounds"
	point	[pair! point2D!] "XY position"
	offset  [pair! point2D!] "Offset of area"
	size	[pair! point2D!] "Size of area"
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
	to logic! all [A1/x < B2/x B1/x < A2/x A1/y < B2/y B1/y < A2/y]
]

distance?: function [
	"Returns the distance between 2 points or face centers"
	A		[object! pair! point2D!] "First face or point"
	B		[object! pair! point2D!] "Second face or point"
	return: [float!]  "Distance between them"
][
	A: either object? A [A/offset * 2 + A/size][A * 2]	;-- doubling for odd-sized faces
	B: either object? B [B/offset * 2 + B/size][B * 2]	;-- to compensate for integer pair (im)precision
	d: B - A
	d/x ** 2 + (d/y ** 2) ** 0.5 / 2
]