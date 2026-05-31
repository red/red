Red [
	Title:	"Headless View test: per-face-type data & selection semantics"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

~~~start-file~~~ "face-types-test"

===start-group=== "boolean widgets hold logic data"
	--test-- "check accepts true and false"
		p: layout [check]
		p/pane/1/data: true
		--assert p/pane/1/data = true
		p/pane/1/data: false
		--assert p/pane/1/data = false
	--test-- "radio data is logic"
		p: layout [radio]
		p/pane/1/data: true
		--assert p/pane/1/data = true
	--test-- "toggle data is logic"
		p: layout [toggle]
		p/pane/1/data: true
		--assert p/pane/1/data = true
===end-group===

===start-group=== "ranged widgets hold percent data"
	--test-- "progress holds a percent"
		p: layout [progress 30%]
		--assert p/pane/1/data = 30%
	--test-- "slider holds a percent"
		p: layout [slider 75%]
		--assert p/pane/1/data = 75%
===end-group===

===start-group=== "calendar holds a date"
	--test-- "calendar data accepts a date value"
		p: layout [calendar]
		p/pane/1/data: 15-Mar-2021
		--assert p/pane/1/data = 15-Mar-2021
===end-group===

===start-group=== "list selection semantics"
	--test-- "text-list selected is 1-based and copies value into text"
		p: layout [text-list data ["a" "b" "c"]]
		p/pane/1/selected: 3
		--assert p/pane/1/selected = 3
		--assert p/pane/1/text = "c"
	--test-- "drop-list selected indexes the displayed list"
		p: layout [drop-list data ["x" "y" "z"]]
		p/pane/1/selected: 2
		--assert p/pane/1/selected = 2
===end-group===

===start-group=== "window selected is the focused child"
	--test-- "focus makes window/selected the face object"
		p: layout [field focus]
		--assert object? p/selected
		--assert same? p/selected p/pane/1
===end-group===

~~~end-file~~~
