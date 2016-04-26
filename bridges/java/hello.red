Red [
	Title:   "Red JVM bridge HelloWorld"
	Author:  "Nenad Rakocevic"
	File: 	 %hello.red
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %bridge.red

label.CENTER: 1													;@@ should be fetched

on-java-event: function [id [integer!]][
	switch/default id [
		201 [
			system: java-new [java.lang.System]	
			java-do [system/exit 0]
		]
	][
		print ["java event:" id]
	]
]

main: function [][
	frame: java-new [java.awt.Frame "Red AWT/JNI demo"]
	label: java-new [
		java.awt.Label
		"AWT app built from Red through Java bridge!"
		label.CENTER
	]
	java-do [frame/add label]	
	java-do [frame/setSize 300 100]
	java-do [frame/setVisible yes]
	
	events: java-new [events]	
	java-do [frame/addWindowListener events]
]