Red [
	Title:	"Headless View test: VID error handling"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

~~~start-file~~~ "vid-errors-test"

===start-group=== "malformed VID raises vid-invalid-syntax"
	--test-- "unknown style word"
		--assert error? try [layout [foobar]]
	--test-- "return inside a grid panel"
		--assert error? try [layout [panel 2 [button return]]]
	--test-- "malformed tab-panel data (not string/block pairs)"
		--assert error? try [layout [tab-panel ["a" "b"]]]
	--test-- "style without a set-word"
		--assert error? try [layout [style foo base]]
	--test-- "window used as a child face"
		--assert error? try [layout [window]]
	--test-- "indent is not a VID keyword"
		--assert error? try [layout [indent base]]
===end-group===

===start-group=== "well-formed VID does not error"
	--test-- "valid multi-widget layout"
		--assert not error? try [layout [button "go" field area text "x"]]
	--test-- "empty layout is valid"
		--assert not error? try [layout []]
===end-group===

===start-group=== "silent? suppresses VID errors"
	--test-- "silent? mode swallows the invalid-syntax error"
		system/view/silent?: yes
		r: try [layout [foobar]]
		system/view/silent?: no
		--assert not error? r
===end-group===

~~~end-file~~~
