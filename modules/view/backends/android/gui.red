Red [
	Title:   "Red VID Android backend"
	Author:  "Nenad Rakocevic"
	File: 	 %android.red
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#include %../../../bridges/java/bridge.red

on-java-event: function [face [integer!] type [integer!] event [integer!]][
	switch/default type [
		1 [
			print "event 1"
			do button-list/1
			
		]
	][
		print ["java event:" event]
	]
]

HORIZONTAL: 0
VERTICAL: 	1
BOTTOM:		80

activity-obj: none
lay: none

main: func [this [integer!]][
	activity-obj: to-java-object this
	on-start

	;java-do [this/setContentView lay]
]


; state: [handle 	dirty?]
;         integer!	logic! 

alert: func [msg /local obj][
	obj: java-new ["android/app/AlertDialog$Builder" activity-obj]
	java-do [obj/create]
	java-do [obj/setTitle msg]
	java-do [obj/show]
]

show: func [face [block!] /with parent [block!] /local obj f params][
	either face/state/1 [
	
	][
		switch face/type [
			screen [
				lay: java-new [android.widget.AbsoluteLayout activity-obj]
			]
			button [
				obj: java-new [android.widget.Button activity-obj]
				;java-do [obj/setId 101]
				;btn-click: java-new [android.view.View.OnClickListener]
				;java-do [btn/setOnClickListener btn-click]
			]
			text [
				obj: java-new [android.widget.TextView activity-obj]
			]
			field [
				obj: java-new [android.widget.EditText activity-obj]
			]
			check [
				obj: java-new [android.widget.CheckBox activity-obj]
			]
			radio [
				obj: java-new [android.widget.RadioButton activity-obj]
			]
			toggle [
				obj: java-new [android.widget.ToggleButton activity-obj]
			]
			clock [
				obj: java-new [android.widget.AnalogClock activity-obj]
			]
			;calendar [
			;	obj: java-new [android.widget.CalendarView activity-obj]
			;]
		]
		if face/type <> 'screen [
			java-do [obj/setText any [face/text ""]]
			
			params: java-new [
				"android/widget/AbsoluteLayout$LayoutParams"
				face/size/x
				face/size/y
				face/offset/x
				face/offset/y
			]
			java-do [lay/addView obj params]
		]
		face/state: obj
	]
	if face/pane [foreach f face/pane [show/with f face]]
	
	unless with [
		java-do [activity-obj/setContentView lay]
	]
]