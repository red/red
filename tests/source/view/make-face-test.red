Red [
	Title:	"Headless View test: make-face"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

~~~start-file~~~ "make-face-test"

===start-group=== "make-face from a style word"
	--test-- "make-face 'button uses the style template"
		f: make-face 'button
		--assert object? f
		--assert f/type = 'button
		--assert f/size = 60x23
	--test-- "make-face/offset/size overrides geometry"
		f: make-face/offset/size 'base 100x50 80x40
		--assert f/offset = 100x50
		--assert f/size = 80x40
===end-group===

===start-group=== "unknown style errors"
	--test-- "make-face on an unknown style raises an error"
		--assert error? try [make-face 'nonsuch]
===end-group===

===start-group=== "instances are independent"
	--test-- "mutating one face does not affect another"
		a: make-face 'base
		b: make-face 'base
		a/color: 1.1.1
		--assert a/color = 1.1.1
		--assert b/color <> 1.1.1
		--assert not same? a b
===end-group===

~~~end-file~~~
