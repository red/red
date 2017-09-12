Red [
	Title:	"Red alpha simple ASCII art demo"
	Author: "Nenad Rakocevic"
	File: 	%demo.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

data: [
	[0 7 20]
	[2 2 6 7 20]
	[1 2 6 7 20]
	[0 2 6 7 10 14 17 20 20]
	[2 2 6 7 9 10 13 14 16 17 19]
	[1 7 9 10 13 14 16 17 20]
	[0 2 4 5 9 14 16 17 20]
	[2 2 5 6 9 10 16 17 20]
	[1 2 5 6 9 10 13 14 16 17 19]
	[0 2 6 7 10 14 17 20 20]
]

pattern: "Red"
prin newline

foreach line data [
	cursor: 1 + line/1
	line: next line
	gap-start: line/1
	gap-end: line/2
	prin tab
	prin tab
	
	repeat i 21 [
		prin either all [
			gap-start <= i
			i <= gap-end
		][
			#" "
		][
			pattern/:cursor
		]
		if i > gap-end [
			unless tail? line: skip line 2 [
				gap-start: line/1
				gap-end: line/2
			]
		]
		
		cursor: cursor + 1
		if cursor = 4 [cursor: 1]
	]
	prin newline
]