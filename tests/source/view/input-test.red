Red [
	Title:	"Headless View test: text input & selection events"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

fld: ar: tl: none

~~~start-file~~~ "input-test"

===start-group=== "field input"
	--test-- "input-string types a string into a field"
		view/no-wait [fld: field]
		input-string fld "hello"
		--assert fld/text = "hello"
		unview/all
	--test-- "key events accumulate character by character"
		view/no-wait [fld: field]
		set-focus fld
		do-event/with 'key #"a"
		do-event/with 'key #"b"
		do-event/with 'key #"c"
		--assert fld/text = "abc"
		unview/all
	--test-- "typing syncs the field's data facet"
		view/no-wait [fld: field]
		input-string fld "42"
		--assert fld/data = 42
		unview/all
===end-group===

===start-group=== "area input"
	--test-- "input-string types into an area"
		view/no-wait [ar: area]
		input-string ar "note"
		--assert ar/text = "note"
		unview/all
===end-group===

===start-group=== "text-list selection event"
	--test-- "do-event 'select sets the selected index"
		view/no-wait [tl: text-list data ["x" "y" "z"]]
		set-focus tl
		do-event/with 'select 3
		--assert tl/selected = 3
		unview/all
===end-group===

~~~end-file~~~
