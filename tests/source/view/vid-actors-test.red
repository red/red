Red [
	Title:	"Headless View test: VID actors (default & named)"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

clicked?: downed?: entered?: changed?: ran?: no
handler: func [face [object!] event [event! none!]][ran?: yes]

~~~start-file~~~ "vid-actors-test"

===start-group=== "trailing block -> default actor"
	--test-- "button trailing block becomes on-click"
		clicked?: no
		p: layout [button "OK" [clicked?: yes]]
		--assert not none? in p/pane/1/actors 'on-click
		do-actor p/pane/1 none 'click
		--assert clicked?
	--test-- "base trailing block becomes on-down"
		downed?: no
		p: layout [base 40x40 [downed?: yes]]
		do-actor p/pane/1 none 'down
		--assert downed?
===end-group===

===start-group=== "named actors"
	--test-- "field on-enter named actor"
		entered?: no
		p: layout [field on-enter [entered?: yes]]
		--assert not none? in p/pane/1/actors 'on-enter
		do-actor p/pane/1 none 'enter
		--assert entered?
	--test-- "check on-change named actor"
		changed?: no
		p: layout [check on-change [changed?: yes]]
		do-actor p/pane/1 none 'change
		--assert changed?
===end-group===

===start-group=== "get-word actor body"
	--test-- "button :handler reuses an existing function"
		ran?: no
		p: layout [button "G" :handler]
		do-actor p/pane/1 none 'click
		--assert ran?
===end-group===

~~~end-file~~~
