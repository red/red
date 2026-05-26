Red [
	Title:  "SDL3 View backend event smoke test"
	Needs:  View
	Config: [GUI-engine: 'SDL3]
]

push-sdl-event: function [
	win		[object!]
	type	[integer!]
	x		[integer!]
	y		[integer!]
	key		[integer!]
	extra	[integer!]
][
	system/view/platform/test-push-event win type x y key extra
]

events: copy []

win: layout [
	title "SDL3 events"
	on-resize [append events 'resize]
	on-close [append events 'close 'done]
	fld: field "edit me" on-key [append events 'key] on-enter [append events 'enter] on-change [append events 'change]
	btn: button "Click" on-click [append events 'click]
	chk: check "Change" on-change [append events 'change]
	tgt: base 100x40 on-over [append events 'over] on-wheel [append events 'wheel]
	base 1x1 rate 20 on-time [append events 'time]
]

view/no-wait win
repeat i 5 [do-events/no-wait]

push-sdl-event win 1024 tgt/offset/x + 5 tgt/offset/y + 5 0 0	;-- SDL_EVENT_MOUSE_MOTION
push-sdl-event win 1027 tgt/offset/x + 5 tgt/offset/y + 5 0 1	;-- SDL_EVENT_MOUSE_WHEEL
push-sdl-event win 1025 btn/offset/x + 5 btn/offset/y + 5 0 1	;-- SDL_EVENT_MOUSE_BUTTON_DOWN
push-sdl-event win 1026 btn/offset/x + 5 btn/offset/y + 5 0 1	;-- SDL_EVENT_MOUSE_BUTTON_UP
push-sdl-event win 1025 fld/offset/x + 5 fld/offset/y + 5 0 1	;-- focus field
push-sdl-event win 1026 fld/offset/x + 5 fld/offset/y + 5 0 1
push-sdl-event win 768 0 0 65 4			;-- SDL_EVENT_KEY_DOWN, scancode A
push-sdl-event win 769 0 0 65 4			;-- SDL_EVENT_KEY_UP, scancode A
push-sdl-event win 768 0 0 13 40		;-- SDL_EVENT_KEY_DOWN, enter
push-sdl-event win 1025 chk/offset/x + 5 chk/offset/y + 5 0 1
push-sdl-event win 1026 chk/offset/x + 5 chk/offset/y + 5 0 1
push-sdl-event win 518 240 180 0 0		;-- SDL_EVENT_WINDOW_RESIZED

repeat i 10 [do-events/no-wait]
foreach word [over wheel click key enter change resize] [
	unless find events word [
		print ["missing event:" word "events:" mold events]
		1 / 0
	]
]

repeat i 20 [
	wait 0:0:0.01
	do-events/no-wait
]
unless find events 'time [1 / 0]

push-sdl-event win 528 0 0 0 0			;-- SDL_EVENT_WINDOW_CLOSE_REQUESTED
repeat i 5 [do-events/no-wait]
unless find events 'close [
	print ["missing event: close events:" mold events]
	1 / 0
]

unview/all

events: copy []
view layout [
	title "SDL3 blocking events"
	base 1x1 rate 20 on-time [
		append events 'blocking-time
		unview/all
	]
]
unless find events 'blocking-time [
	print ["missing event: blocking-time events:" mold events]
	1 / 0
]
