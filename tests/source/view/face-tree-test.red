Red [
	Title:	"Headless View test: face-tree navigation & geometry helpers"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

b1: b2: win: none

~~~start-file~~~ "face-tree-test"

===start-group=== "pane append / remove"
	--test-- "append adds a child; remove drops it"
		win: view/no-wait [base 20x20]
		--assert 1 = length? win/pane
		append win/pane make-face 'button
		--assert 2 = length? win/pane
		remove back tail win/pane
		--assert 1 = length? win/pane
		unview/all
===end-group===

===start-group=== "foreach-face"
	--test-- "visits all descendant faces"
		p: layout [panel [base base] button]
		n: 0
		foreach-face p [n: n + 1]
		--assert n >= 4
===end-group===

===start-group=== "get-face-pane"
	--test-- "returns a container's children block"
		p: layout [panel [base base]]
		--assert block? get-face-pane p/pane/1
		--assert 2 = length? get-face-pane p/pane/1
===end-group===

===start-group=== "set-focus"
	--test-- "set-focus updates window/selected"
		win: view/no-wait [b1: field  b2: field]
		set-focus b2
		--assert same? win/selected b2
		unview/all
===end-group===

===start-group=== "geometry helpers"
	--test-- "within? point-in-rectangle"
		--assert within? 15x15 10x10 20x20
		--assert not within? 5x5 10x10 20x20
	--test-- "overlap? of two faces"
		a: make-face/offset/size 'base 0x0 20x20
		b: make-face/offset/size 'base 10x10 20x20
		c: make-face/offset/size 'base 100x100 10x10
		--assert overlap? a b
		--assert not overlap? a c
	--test-- "distance? between points"
		--assertf~= 5.0 distance? 0x0 3x4 0.0001
===end-group===

===start-group=== "center-face"
	--test-- "center-face/with centers within the given parent (2000x1000 screen)"
		f: make-face/size 'base 100x100
		center-face/with f system/view/screens/1
		--assert f/offset = 950x450
===end-group===

~~~end-file~~~
