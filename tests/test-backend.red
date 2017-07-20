Red [
	Needs: View
	Config: [GUI-engine: 'test]
]

hello: name: tl: none

win: view/no-wait [
	hello: button "Hello" [print "ok"]
	name: field ;on-key ['done]
	tl: text-list ["a" "b" "c"]
	bb: base white on-down [face/color: red]
]

set-focus hello
do-event 'click

set-focus name
do-event/with 'key #"4"
do-event/with 'key #"2"
do-event/with 'key 'enter

probe name/text
probe name/data

set-focus tl
do-event/with 'select 2
probe tl/selected

probe bb/color
do-event/at 'down bb/offset + 5x5
probe bb/color