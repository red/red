Red [
	Title:	"Headless View test: Draw dialect parse/validation (no pixels)"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

bx: none

~~~start-file~~~ "draw-parse-test"

===start-group=== "draw facet via VID"
	--test-- "a valid draw block is stored on the face"
		p: layout [base 50x50 draw [pen red line 0x0 50x50]]
		--assert block? p/pane/1/draw
	--test-- "well-formed draw does not raise an error"
		--assert not error? try [layout [base 50x50 draw [line 0x0 10x10 circle 25x25 10]]]
===end-group===

===start-group=== "draw into an image"
	--test-- "draw on a pair size returns an image of that size"
		img: draw 40x40 [pen blue line 0x0 40x40]
		--assert image? img
		--assert img/size = 40x40
===end-group===

===start-group=== "invalid draw errors"
	--test-- "an unknown draw command raises an error"
		--assert error? try [draw 10x10 [bogus-draw-command 1 2 3]]
===end-group===

===start-group=== "setting face/draw post-build"
	--test-- "assigning the draw facet under auto-sync does not crash"
		view/no-wait [bx: base 50x50]
		bx/draw: [pen green box 5x5 45x45]
		--assert block? bx/draw
		unview/all
===end-group===

===start-group=== "resolved open question: face/type is mutable"
	--test-- "reassigning type changes it (the immutability check is disabled in source)"
		f: make-face 'base
		f/type: 'button
		--assert f/type = 'button
===end-group===

~~~end-file~~~
