Red [
	Title:	"Headless View test: VID positioning / layout flow"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no			;-- deterministic geometry (no OS button reordering)

~~~start-file~~~ "vid-positioning-test"

===start-group=== "default flow (across)"
	--test-- "across: two bases flow left-to-right, origin 10x10, space 10x10"
		p: layout [base 20x20 base 20x20]
		--assert p/pane/1/offset = 10x10
		--assert p/pane/2/offset = 40x10
===end-group===

===start-group=== "below"
	--test-- "below: faces stack vertically"
		p: layout [below base 20x20 base 20x20]
		--assert p/pane/1/offset = 10x10
		--assert p/pane/2/offset = 10x40
===end-group===

===start-group=== "tight"
	--test-- "/tight zeroes origin and spacing"
		p: layout/tight [base 20x20 base 20x20]
		--assert p/pane/1/offset = 0x0
		--assert p/pane/2/offset = 20x0
===end-group===

===start-group=== "origin"
	--test-- "origin 0x0 re-anchors the cursor"
		p: layout [origin 0x0 base 20x20 base 20x20]
		--assert p/pane/1/offset = 0x0
		--assert p/pane/2/offset = 30x0
===end-group===

===start-group=== "space"
	--test-- "space 0x0 removes the inter-face gap"
		p: layout [space 0x0 base 20x20 base 20x20]
		--assert p/pane/1/offset = 10x10
		--assert p/pane/2/offset = 30x10
===end-group===

===start-group=== "at (absolute placement)"
	--test-- "at sets the next face offset absolutely"
		p: layout [at 100x50 base 20x20]
		--assert p/pane/1/offset = 100x50
===end-group===

===start-group=== "return"
	--test-- "return advances to the next row"
		p: layout [base 20x20 return base 20x20]
		--assert p/pane/1/offset = 10x10
		--assert p/pane/2/offset = 10x40
===end-group===

~~~end-file~~~
