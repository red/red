Red [
	Title:	"Headless View test: VID containers (panel/group-box/tab-panel/grid)"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

~~~start-file~~~ "vid-containers-test"

===start-group=== "panel"
	--test-- "panel holds its children with parent links"
		p: layout [panel [base 20x20 base 20x20]]
		pnl: p/pane/1
		--assert pnl/type = 'panel
		--assert 2 = length? pnl/pane
		--assert same? pnl/pane/1/parent pnl
		--assert same? pnl/pane/2/parent pnl
	--test-- "panel children flow with 10px spacing (relative)"
		p: layout [panel [base 20x20 base 20x20]]
		c: p/pane/1/pane
		--assert 30 = (c/2/offset/x - c/1/offset/x)
===end-group===

===start-group=== "group-box"
	--test-- "string option sets title, pair sets size"
		p: layout [group-box "Settings" 200x100 [base]]
		gb: p/pane/1
		--assert gb/type = 'group-box
		--assert gb/text = "Settings"
		--assert gb/size = 200x100
		--assert 1 = length? gb/pane
===end-group===

===start-group=== "tab-panel"
	--test-- "data = tab names, pane = one panel per tab"
		p: layout [tab-panel ["One" [base] "Two" [text "x"]]]
		tp: p/pane/1
		--assert tp/type = 'tab-panel
		--assert tp/data = ["One" "Two"]
		--assert 2 = length? tp/pane
		--assert tp/pane/1/type = 'panel
===end-group===

===start-group=== "grid panel (divides)"
	--test-- "panel 2 lays children in 2 columns"
		p: layout [panel 2 [base 20x20 base 20x20 base 20x20 base 20x20]]
		c: p/pane/1/pane
		--assert 4 = length? c
		--assert c/3/offset/x = c/1/offset/x		;-- column 1 aligned
		--assert c/4/offset/x = c/2/offset/x		;-- column 2 aligned
		--assert c/3/offset/y > c/1/offset/y		;-- row 2 below row 1
===end-group===

===start-group=== "deep nesting"
	--test-- "panel-in-panel structure + foreach-face traversal"
		p: layout [panel [panel [base base]]]
		--assert p/pane/1/type = 'panel
		--assert p/pane/1/pane/1/type = 'panel
		--assert 2 = length? p/pane/1/pane/1/pane
		n: 0
		foreach-face p [n: n + 1]
		--assert n >= 4								;-- 2 panels + 2 bases (at least)
===end-group===

~~~end-file~~~
