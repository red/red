Red [
	Title:	"Headless View test: face! facets & on-change side effects"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

fld: tl: bx: im: none

~~~start-file~~~ "face-facets-test"

===start-group=== "field text <-> data sync"
	--test-- "setting data reformats text"
		p: layout [fld: field]
		fld/data: 99
		--assert fld/text = "99"
	--test-- "setting text loads data"
		p: layout [fld: field]
		fld/text: "42"
		--assert fld/data = 42
===end-group===

===start-group=== "list selected -> text"
	--test-- "selecting an item copies its value into text"
		p: layout [tl: text-list data ["alpha" "beta" "gamma"]]
		tl/selected: 2
		--assert tl/text = "beta"
===end-group===

===start-group=== "defaults"
	--test-- "fresh face is enabled and visible"
		p: layout [bx: base]
		--assert bx/enabled?
		--assert bx/visible?
	--test-- "child parent link points to the window"
		p: layout [bx: base]
		--assert same? bx/parent p
===end-group===

===start-group=== "state after show"
	--test-- "shown face has a 4-slot state with a non-null handle"
		view/no-wait [bx: base 30x30]
		--assert block? bx/state
		--assert 4 = length? bx/state
		--assert not none? bx/state/1
		unview/all
===end-group===

===start-group=== "auto-sync facet change"
	--test-- "changing color under auto-sync applies and does not crash"
		view/no-wait [bx: base 30x30]
		bx/color: 10.20.30
		--assert bx/color = 10.20.30
		unview/all
===end-group===

~~~end-file~~~
