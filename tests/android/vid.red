Red [
	Title:   "Red Android VID sample"
	Author:  "Nenad Rakocevic"
	File: 	 %vid.red
	Needs:	 'View
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

on-start: does [
	view [
		across
		text "Hello"
		button "Hello" 180x40
		button "World"
		at 400x400 button "Hi..."
		button "Jerry"
		text "Red Language"
		field 200
		return

		check "option 1"
		check "option 2"
		radio
		radio
		clock
		toggle
	]
]