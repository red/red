Red [
	Title:	"Headless View test: reactivity (react / relate / reactor)"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

src: tgt: s: t: r: none

~~~start-file~~~ "reactivity-test"

===start-group=== "react: immediate run + update on change"
	--test-- "react initializes the target, then updates on source change"
		src: make reactor! [v: 10]
		tgt: object [w: 0]
		react [tgt/w: src/v * 2]
		--assert tgt/w = 20
		src/v: 100
		--assert tgt/w = 200
===end-group===

===start-group=== "react/later skips the initial run"
	--test-- "react/later defers the first evaluation"
		src: make reactor! [v: 5]
		tgt: object [w: -1]
		react/later [tgt/w: src/v]
		--assert tgt/w = -1
		src/v: 7
		--assert tgt/w = 7
===end-group===

===start-group=== "face facets are reactive sources"
	--test-- "slider data drives a text face via a VID react clause"
		view/no-wait [
			s: slider
			t: text "x" react [face/text: form s/data]
		]
		s/data: 50%
		--assert t/text = form 50%
		unview/all
===end-group===

===start-group=== "relate (reactor field relation)"
	--test-- "relate assigns the reaction result to a field"
		r: make reactor! [x: 1 y: 2 relate total: [x + y]]
		--assert r/total = 3
		r/x: 100
		--assert r/total = 102
===end-group===

===start-group=== "is is deprecated"
	--test-- "the old reactive 'is' operator now raises a deprecation error"
		--assert error? try [is]
===end-group===

===start-group=== "react? and clear-reactions"
	--test-- "react? finds a source reaction; clear-reactions removes them"
		src: make reactor! [v: 1]
		tgt: object [w: 0]
		react [tgt/w: src/v]
		--assert not none? react? src 'v
		clear-reactions
		src/v: 999
		--assert tgt/w = 1
===end-group===

~~~end-file~~~
