Red [
	Title:	"Headless View test: VID actors (default & named)"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

;-- VID-named faces must be pre-declared in compiled code
b: bs: f: bk: bg: ba: none
clicked?: downed?: entered?: ran?: no
got: none
handler: func [face [object!] event [event! none!]][ran?: yes]

~~~start-file~~~ "vid-actors-test"

===start-group=== "trailing block -> default actor"
	--test-- "button trailing block becomes on-click"
		clicked?: no
		view/no-wait [b: button "OK" [clicked?: yes]]
		--assert not none? in b/actors 'on-click
		set-focus b
		do-event 'click
		--assert clicked?
		unview/all
	--test-- "base trailing block becomes on-down"
		downed?: no
		view/no-wait [bs: base 40x40 [downed?: yes]]
		do-event/at 'down bs/offset + 5x5
		--assert downed?
		unview/all
===end-group===

===start-group=== "named actors"
	--test-- "field on-enter named actor"
		entered?: no
		view/no-wait [f: field on-enter [entered?: yes]]
		--assert not none? in f/actors 'on-enter
		set-focus f
		do-event 'enter
		--assert entered?
		unview/all
	--test-- "base on-key named actor receives event/key"
		got: none
		view/no-wait [bk: base 40x40 on-key [got: event/key]]
		set-focus bk
		do-event/with 'key #"A"
		--assert got = #"A"
		unview/all
===end-group===

===start-group=== "get-word actor body"
	--test-- "button :handler reuses an existing function"
		ran?: no
		view/no-wait [bg: button "G" :handler]
		set-focus bg
		do-event 'click
		--assert ran?
		unview/all
===end-group===

===start-group=== "event-less actor dispatch"
	--test-- "do-actor face none 'click fires actor reading only face"
		ran?: no
		view/no-wait [ba: button "A" [ran?: yes]]
		do-actor ba none 'click
		--assert ran?
		unview/all
===end-group===

~~~end-file~~~
