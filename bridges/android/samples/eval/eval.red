Red [
	Title:   "Red Android bridge demo"
	Author:  "Nenad Rakocevic"
	File: 	 %eval.red
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %../../../java/bridge.red


on-java-event: function [face [integer!] type [integer!] event [integer!]][
	switch/default type [
		1 [
			seq: java-do [input/getText]
			if code: java-do [seq/toString][		
				set/any 'result do code
				unless unset? :result [
					result: form reduce ["==" mold result lf]
					java-do [output/append result]
				]
			]
		]
	][
		print ["java event:" event]
	]
]

HORIZONTAL: 0
VERTICAL: 	1
BOTTOM:		80

main: function [this [integer!] /extern [input output]][
	this: to-java-object this

	lay: java-new [android.widget.LinearLayout this]
	java-do [lay/setOrientation VERTICAL]

	input: java-new [android.widget.EditText this]
	java-do [input/setText "1 + 3"]
	java-do [input/setId 100]
	java-do [lay/addView input]
	
	btn: java-new [android.widget.Button this]
	java-do [btn/setText "Do"]
	java-do [btn/setId 101]
	btn-click: java-new [org.redlang.eval.ClickEvent]
	java-do [btn/setOnClickListener btn-click]
	java-do [lay/addView btn]
		
	output: java-new [android.widget.TextView this]
	java-do [output/setHeight 600]
	java-do [output/setGravity BOTTOM] 
	java-do [lay/addView output]
	
	java-do [this/setContentView lay]
]