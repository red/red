Red [
	Title:	"Headless View test: text input & selection semantics"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

changed?: no

~~~start-file~~~ "input-test"

===start-group=== "field text <-> data"
	--test-- "setting field text loads the data facet"
		p: layout [field]
		p/pane/1/text: "42"
		--assert p/pane/1/data = 42
	--test-- "setting field data reformats text"
		p: layout [field]
		p/pane/1/data: 7
		--assert p/pane/1/text = "7"
===end-group===

===start-group=== "area text"
	--test-- "area holds its text content"
		p: layout [area]
		p/pane/1/text: "notes"
		--assert p/pane/1/text = "notes"
===end-group===

===start-group=== "list selection"
	--test-- "setting selected copies the value into text"
		p: layout [text-list data ["a" "b" "c"]]
		p/pane/1/selected: 2
		--assert p/pane/1/selected = 2
		--assert p/pane/1/text = "b"
===end-group===

===start-group=== "on-change via a synthetic change event"
	--test-- "field on-change actor fires"
		changed?: no
		p: layout [field on-change [changed?: yes]]
		do-actor p/pane/1 make event! [type: 'change] 'change
		--assert changed?
===end-group===

~~~end-file~~~
