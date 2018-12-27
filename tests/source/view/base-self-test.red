Red [
	Title:   "BASE automatic self assessment script"
	Author:  "hiiamboris"
	File:    %base-self-test.red
	Purpose: "Define BASE face behavior and detect future regressions"
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
    License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	; Needs:   'View
]


; TODO: `area` face tests
; TODO: `size-text` tests, for different faces


#include %../../../quick-test/quick-test.red


~~~start-file~~~ "base-self-test"

; relies upon the View subsystem (not yet available on some platforms)
; FIXME: currently these tests are hopeless on MacOS
do [if all [object? :system/view  system/platform = 'Windows] [



;           ====
;       ======
;    =================
;   =======================================  constants
;      ======
;          ====





;-- used to mark the start of system/words pollution
bst-word-count: none
bst-word-count: length? words-of system/words


;-- enable display of failed images?
bst-user-mode: yes
;-- if so, for how long?
bst-show-delay: 0:0:5


;-- capturing framerate
bst-w7?: all ['Windows = system/platform  find/match get bind 'name os-info "Windows 7"]
bst-rate: either bst-w7? [67][2] 	 	;-- works fast w/o bugs on W7 only


;-- colors should include B and R components of different intensities
;  because these two are swapped around between Red/GDI and GDI+
bst-colors: context [bg: yellow fg: red]


;-- it's best to use bold fonts to reduce the effects of cleartype cheating
bst-font1:  make font! [name: system/view/fonts/serif size: 16 style: 'bold color: bst-colors/fg]
bst-font1*: make font! [name: system/view/fonts/serif size: 16 style: 'bold color: bst-colors/fg + 0.0.0.5]
bst-font2:  make font! [name: system/view/fonts/fixed size: 11 style: 'bold color: bst-colors/fg]
bst-font2*: make font! [name: system/view/fonts/fixed size: 11 style: 'bold color: bst-colors/fg + 0.0.0.5]


bst-styles-backup: copy system/view/VID/styles

;-- styles with optional font/background transparency
system/view/VID/styles/text':		[template: [type: 'text  size: 100x25 font: bst-font1  color: bst-colors/bg]]
system/view/VID/styles/text'*:		[template: [type: 'text  size: 100x25 font: bst-font1  color: bst-colors/bg + 0.0.0.5]]
system/view/VID/styles/text'**:		[template: [type: 'text  size: 100x25 font: bst-font1* color: bst-colors/bg]]
system/view/VID/styles/text'***:	[template: [type: 'text  size: 100x25 font: bst-font1* color: bst-colors/bg + 0.0.0.5]]

system/view/VID/styles/base':		[template: [type: 'base  size: 100x100 font: bst-font1  color: bst-colors/bg]]
system/view/VID/styles/base'*:		[template: [type: 'base  size: 100x100 font: bst-font1  color: bst-colors/bg + 0.0.0.5]]
system/view/VID/styles/base'**:		[template: [type: 'base  size: 100x100 font: bst-font1* color: bst-colors/bg]]
system/view/VID/styles/base'***:	[template: [type: 'base  size: 100x100 font: bst-font1* color: bst-colors/bg + 0.0.0.5]]
system/view/VID/styles/base-:		[template: [type: 'base  size: 50x100  font: bst-font2  color: bst-colors/bg]]
system/view/VID/styles/base-*:		[template: [type: 'base  size: 50x100  font: bst-font2  color: bst-colors/bg + 0.0.0.5]]
system/view/VID/styles/base-**:		[template: [type: 'base  size: 50x100  font: bst-font2* color: bst-colors/bg]]
system/view/VID/styles/base-***:	[template: [type: 'base  size: 50x100  font: bst-font2* color: bst-colors/bg + 0.0.0.5]]
system/view/VID/styles/base+:		[template: [type: 'base  size: 50x100  font: bst-font1  color: bst-colors/bg]]
system/view/VID/styles/base+*:		[template: [type: 'base  size: 50x100  font: bst-font1  color: bst-colors/bg + 0.0.0.5]]
system/view/VID/styles/base+**:		[template: [type: 'base  size: 50x100  font: bst-font1* color: bst-colors/bg]]
system/view/VID/styles/base+***:	[template: [type: 'base  size: 50x100  font: bst-font1* color: bst-colors/bg + 0.0.0.5]]





;           ====
;       ======
;    =================
;   =======================================  utility funcs
;      ======
;          ====





set/any 'bst-assert-backup get/any 'assert

;-- skip the assertions and let quick-test do its thing
assert: func [c [block!]] []

;-- assertion func used during the development stage
; assert: function [contract [block!]][
; 	set [cond msg] reduce contract
; 	unless cond [
; 		print ["ASSERTION FAILURE:" mold contract]
; 		if none? msg [msg: last contract]
; 		if any-word? msg [
; 			msg: either function? get msg
; 			[ rejoin ["" msg " result is unexpected"] ]
; 			[ rejoin ["" msg " is " mold/part/flat get msg 1024] ]
; 		]
; 		do make error! form msg
; 	]
; ]


bst-cleanup: does [
	system/view/VID/styles: bst-styles-backup
	set/any 'assert get/any 'bst-assert-backup
	unset at words-of system/words bst-word-count
]


;-- foreach is buggy yet, plus it doesn't track the offset
forxy: func ["loop thru a 2D area" 'p s c /local i] [
	any [pair? s  s: s/size]
	i: 0
	loop s/x * s/y [
		set p 1x1 + as-pair i % s/x i / s/x
		do c
		i: i + 1
	]
]

assert [[1x1 2x1 1x2 2x2] = collect [forxy xy make image! 2x2 [keep xy]]  'forxy]


;-- min/max funcs that silently avoid `none` arguments
min': func [x y] [any [all [x y min x y] x y]]
max': func [x y] [any [all [x y max x y] x y]]

assert [1 = min' 1 2  'min']
assert [2 = max' 1 2  'max']
assert [1 = min' 1 none  'min']
assert [1 = max' 1 none  'max']
assert [2 = min' none 2  'min']
assert [2 = max' none 2  'max']
assert [none = min' none none  'min']
assert [none = max' none none  'max']


amnt3?: func [
	"calculates the amount of `color` in a mix"
	c [tuple!] b [tuple!]
] [
	max' 	0.0 	; in case all amounts are none (c = black), return 0.0
	min'	amnt? c/1 b/1
	min'	amnt? c/2 b/2
			amnt? c/3 b/3
]

amnt?: func [
	"calculates the amount of `color` in a mix (single-channel)"
	color [integer!] blend [integer!]
] [
	either color = 0 [none][min 1.0 1.0 * blend / color]
]

assert [0.5 = amnt? 254 127	'amnt?]
assert [0.0 = amnt? 254 0	'amnt?]
assert [none = amnt? 0 127	'amnt?]

assert [0.5 = amnt3? 200.100.50 100.50.25	'amnt3?]
assert [0.5 = amnt3? 200.100.50 100.50.100	'amnt3?]
assert [0.5 = amnt3? 200.100.50 100.255.255	'amnt3?]
assert [0.0 = amnt3? 200.100.50 0.255.255	'amnt3?]
assert [0.0 = amnt3? 200.100.50 255.0.255	'amnt3?]
assert [0.0 = amnt3? 200.100.50 255.255.0	'amnt3?]
assert [1.0 = amnt3? 200.100.50 255.255.255	'amnt3?]
assert [0.0 = amnt3? 0.0.0 100.200.100		'amnt3?]


math3: func [
	"tuple arithmetic with better precision (no intermediary rounding)"
	a* [tuple!] b* [tuple!] cmds* [block!] /local a b r* i
] [
	bind cmds* context? 'a
	r*: 0.0.0
	repeat i 3 [a: a*/:i  b: b*/:i  r*/:i: to-integer do cmds*]
	r*
]

assert [10.10.10 = math3 10.10.10 20.10.0 [a] 		'math3]
assert [20.10.0  = math3 10.10.10 20.10.0 [b] 		'math3]
assert [30.20.10 = math3 10.10.10 20.10.0 [a + b] 	'math3]
assert [0.20.40  = math3 10.10.10 20.10.0 [a * 2 - b * 2] 	'math3]
assert [100.10.0 = math3 10.1.0 10.10.10 [a * 100.0 + b - b / 10.0]	'math3]

diff3: func [
	"absolute difference of 2 tuples"
	a [tuple!] b [tuple!] /local i
] [
	repeat i 3 [a/:i: absolute a/:i - b/:i]
	a
]

assert [50.60.70 = diff3 100.100.100 50.40.30 	'diff3]
assert [100.140.130 = diff3 100.100.100 200.240.230 	'diff3]
assert [100.140.130 = diff3 200.240.230 100.100.100 	'diff3]


; return format: [tuple! percent! ...]
; removes alpha channel so it won't cause trouble
count-colors: func [
	"returns colors used in the image, sorted by frequency (0-100%)"
	im [image!] return: [block!] /local m c n tot xy
] [
	m: copy #()
	tot: im/size/x * im/size/y
	forxy xy im [
		c: im/:xy  if 4 = length? c [c/4: none]
		m/:c: 1 + any [m/:c 0]
	]
	m: sort/reverse/skip/compare to-block m 2 2
	forall m [m: next m  m/1: 100% * m/1 / tot]
	m
]

assert [bst-x: 1.2.3.4 bst-x/4: none 3 = length? bst-x]
assert [[255.255.255 100%] = count-colors make image! 2x2  'count-colors]
assert [[255.255.255 75% 0.0.0 25%] = count-colors make image! [2x2 #{FFFFFF FFFFFF 000000 FFFFFF}]  'count-colors]


sub-bgnd: func [
	"subtracts background (1st tuple) from the color set (modifies)"
	cs [block!] /local x cs' bg
] [
	unless empty? cs [
		bg: cs/1
		cs': skip cs 2
		until [
			;-- W8 bugfix: may return background differing by 5.5.5 or so
			either about?/tol bg cs'/1 0.0 7 [
				cs/2: cs/2 + cs'/2
				remove/part cs' 2
			][
				x: any [amnt3? bg cs'/1 0]
				cs'/1: math3 cs'/1 bg [1.0 * a - (b * x) / (1.0 - x)]
				cs': skip cs' 2
			]
			empty? cs'
		]
	]
	cs
]

assert [[] = sub-bgnd [] 	'sub-bgnd]
assert [[255.255.255 100%] = sub-bgnd count-colors make image! 2x2 	'sub-bgnd]
assert [[255.255.255 75% 0.0.0 25%] = sub-bgnd count-colors make image! [2x2 #{FFFFFF FFFFFF 000000 FFFFFF}]	'sub-bgnd]
assert [[255.255.0 75% 0.0.255 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 808080 FFFF00}]	'sub-bgnd]
assert [[255.255.0 75% 0.0.192 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 404090 FFFF00}]	'sub-bgnd]
assert [[255.255.0 75% 0.64.192 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]	'sub-bgnd]


about?: func [
	"loose comparison of 2 values, x,y are supposed to be 0..1 or color tuples"
	x [number! tuple!] y [number! tuple!] /tol "tolerance" tolrel tolabs
] [
	tolrel: any [tolrel 5%]
	true = either number? x [
		tolabs: any [tolabs 0.05]
		tolabs + (tolrel * max x y) >= absolute x - y
	][
		tolabs: any [tolabs 7]
		all [
			about?/tol x/1 y/1 tolrel tolabs
			about?/tol x/2 y/2 tolrel tolabs
			about?/tol x/3 y/3 tolrel tolabs
		]
	]
]

assert [about? 0.05 0.02 'about?]
assert [about? 0.95 0.9 'about?]
assert [not about? 0.2 0.02 'about?]
assert [not about? 0.95 0.8 'about?]
assert [about? 254.254.0 255.254.0 'about?]
assert [about? 254.254.0 255.250.0 'about?]
assert [about? 254.254.0 249.254.0 'about?]
assert [about? 0.0.0 0.0.1 'about?]
assert [about? 0.0.0 0.0.5 'about?]
assert [not about? 254.254.0 230.254.0 'about?]
assert [not about? 100.100.100 130.70.100 'about?]
assert [error? try [about? red none] 'about?]


bright: func [
	"returns color c of it's maximum brightness"
	c [tuple!] /local hi i
] [
	if 4 = length? c [c/4: none]
	unless black = c [
		hi: max c/1 max c/2 c/3
		repeat i 3 [c/:i: c/:i * 255 / hi]
	]
	c
]

assert [white = bright white 		'bright]
assert [white = bright 10.10.10 	'bright]
assert [blue  = bright 0.0.1 		'bright]
assert [black = bright black 		'bright]
assert [yellow = bright 100.100.0 	'bright]


;-- very simple tuples brightness comparison
;  used to choose a brighter shade when clashing palette
brighter-than?: make op! func [a [tuple!] b [tuple!]] [
	all [a <> b  a/1 >= b/1  a/2 >= b/2  a/3 >= b/3]
]

assert [white brighter-than? gray 			'brighter-than?]
assert [white brighter-than? blue 			'brighter-than?]
assert [white brighter-than? cyan 			'brighter-than?]
assert [not (white brighter-than? white) 	'brighter-than?]
assert [not (blue brighter-than? white) 	'brighter-than?]
assert [not (cyan brighter-than? white) 	'brighter-than?]
assert [0.1.0 brighter-than? black 			'brighter-than?]
assert [not (black brighter-than? black) 	'brighter-than?]
assert [not (blue brighter-than? red) 		'brighter-than?]
assert [yellow brighter-than? red 			'brighter-than?]


clash: func [
	"joins similar colors in the color set, of count-colors' format (modifies)"
	cs [block!] /local cs'
] [
	if 4 >= length? cs [return cs] 		;-- nothing to join
	; start from index 1, since W8 sometimes returns 2 shades of background color!
	; cs: skip cs 2
	until [
		cs': skip cs 2
		while [not empty? cs'] [
			either about?  bright cs/1  bright cs'/1 [		;-- same color?
				;-- choose the brighter shade
				if cs'/1 brighter-than? cs/1 [ cs/1: cs'/1 ]
				;-- sum the area covered
				cs/2: cs/2 + cs'/2
				;-- leave only one shade
				remove/part cs' 2
			][cs': skip cs' 2]
		]
		empty? cs: skip cs 2
	]
	sort/reverse/skip/compare head cs 2 2
]

assert [[0.0.0 70% 100.0.0 30%] = clash [0.0.0 70% 100.0.0 20% 50.0.0 10%] 		'clash]
assert [[0.0.0 70% 100.50.0 30%] = clash [0.0.0 70% 100.50.0 20% 51.23.0 10%] 	'clash]


colorset?: func [
	"returns the palette used in the image, merging similar shades [color area% ...]"
	im [image!] /tuples "include colors only"
] [
	extract clash sub-bgnd count-colors im either tuples [2][1]
]

assert [[255.255.0 75% 0.64.192 25%] = colorset? make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]	'colorset?]
assert [[255.255.0 0.64.192] = colorset?/tuples make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]	'colorset?]


text-bounds?: func [
	"calculates the text boundaries on an image [x y dx dy]"
	im [image!] "(area covered by the text should be < 50%)"
	/lines
		{return per-line boundaries [x y dx dy ...]
		(characters must be vertically contiguous: "===" is 2 lines, "=I=" is one)}
	/local xy ts box text-before? text-here?
] [
	ts: colorset?/tuples im
	assert [2 <= length? ts] 		;-- can be > 2 colors for a cleartype render
	box: reduce [im/size/x im/size/y 0 0]
	text-before?: text-here?: no
	forxy xy im [
		unless about? im/:xy ts/1 [			;-- not a background pixel?
			text-here?: yes
			box/1: min box/1 xy/x
			box/2: min box/2 xy/y
			box/3: max box/3 xy/x
			box/4: max box/4 xy/y
		]
		if all [lines  im/size/x = xy/x] [		;-- end of the text line?
			if all [text-before?  not text-here?] [
				;-- start a new bounding box
				repend box: skip box 4 [im/size/x im/size/y 0 0]
			]
			text-before?: text-here?
			text-here?: no
		]
	]
	box: head box
	until [
		box/1: box/1 - 1 * 1.0 / im/size/x
		box/3: box/3     * 1.0 / im/size/x
		box/2: box/2 - 1 * 1.0 / im/size/y
		box/4: box/4     * 1.0 / im/size/y
		;-- remove possible trailing invalid box:
		either any [box/3 <= box/1  box/4 <= box/2]
			[remove/part box 4]
			[box: skip box 4]
		empty? box
	]
	head box
]

assert [[0.0 0.0 1.0 1.0] = text-bounds? draw 10x10
		[pen blue box 0x0 9x9] 	'text-bounds?]
assert [[0.0 0.0 1.0 1.0] = text-bounds?/lines draw 10x10
		[pen blue box 0x0 9x9] 	'text-bounds?]
assert [[0.1 0.1 0.9 0.9] = text-bounds? draw 10x10
		[pen blue line 1x1 4x2 line 1x4 8x5 line 1x7 8x8] 	'text-bounds?]
assert [[0.1 0.1 0.5 0.3  0.1 0.4 0.9 0.6  0.1 0.7 0.9 0.9] =
		text-bounds?/lines draw 10x10
		[pen blue line 1x1 4x2 line 1x4 8x5 line 1x7 8x8] 	'text-bounds?]


text-center?: func [
	"locates mean center of non-background (text?) pixels"
	im [image!] /local xy xsum ysum n ts
][
	ts: colorset?/tuples im
	assert [2 <= length? ts]
	xsum: ysum: n: 0
	forxy xy im [
		unless about? im/:xy ts/1 [
			n: n + 1
			xsum: xsum + xy/x
			ysum: ysum + xy/y
		]
	]
	reduce [
		xsum * 1.0 / n - 0.5 / im/size/x
		ysum * 1.0 / n - 0.5 / im/size/y
	]
]

assert [[0.15 0.15] = text-center?
		also bst-im: make image! 10x10 bst-im/(2x2): blue 	'text-center?]
assert [[0.1 0.1] = text-center? draw 10x10
		[pen blue box 0x0 1x1] 	'text-center?]
assert [[0.5 0.5] = text-center? draw 10x10
		[pen blue box 0x0 9x9] 	'text-center?]


;-- returns one of:
; [nw n ne
;  w  c  e
;  sw s se]
text-anchor?: func [
	"calculates predominant text orientation"
	im [image!] /local x y c
] [
	c: text-center? im
	x: either about? 0.5 c/1 [2][pick [1 3] c/1 < 0.5]
	y: either about? 0.5 c/2 [2][pick [1 3] c/2 < 0.5]
	pick [nw n ne  w c e  sw s se] y - 1 * 3 + x
]


assert ['nw = text-anchor? draw 10x10
		[pen blue box 0x0 2x2] 	'text-anchor?]
assert ['ne = text-anchor? draw 10x10
		[pen blue box 7x0 9x2] 	'text-anchor?]
assert ['sw = text-anchor? draw 10x10
		[pen blue box 0x7 2x9] 	'text-anchor?]
assert ['se = text-anchor? draw 10x10
		[pen blue box 7x7 9x9] 	'text-anchor?]
assert ['n  = text-anchor? draw 10x10
		[pen blue box 0x0 9x4] 	'text-anchor?]
assert ['s  = text-anchor? draw 10x10
		[pen blue box 0x4 9x9] 	'text-anchor?]
assert ['w  = text-anchor? draw 10x10
		[pen blue box 0x0 4x9] 	'text-anchor?]
assert ['e  = text-anchor? draw 10x10
		[pen blue box 4x0 9x9] 	'text-anchor?]
assert ['c  = text-anchor? draw 10x10
		[pen blue box 0x0 9x9] 	'text-anchor?]


text-aligned?: func [
	"checks if all text lines are aligned with al=left or al=right"
	'al [word!] im [image!] /local _ r ls x dx
] [
	assert [find [right left] al]
	ls: text-bounds?/lines im
	r: yes
	foreach [x _ dx _] ls compose [
		r: r and about?/tol (either 'left = al [[0.08 x]][[0.92 dx]]) 0 0.06
	]
	r
]

assert [text-aligned? left draw 10x10
		[pen blue box 1x0 2x5] 	'text-aligned?]
assert [not text-aligned? right draw 10x10
		[pen blue box 1x0 2x5] 	'text-aligned?]
assert [text-aligned? right draw 10x10
		[pen blue box 7x0 8x5] 	'text-aligned?]
assert [not text-aligned? left draw 10x10
		[pen blue box 7x0 8x5] 	'text-aligned?]
assert [not text-aligned? left draw 10x10
		[pen blue box 4x4 6x6] 	'text-aligned?]
assert [not text-aligned? right draw 10x10
		[pen blue box 4x4 6x6] 	'text-aligned?]


equally-spaced?: func [
	"checks if all vertical intervals between text lines are about equal"
	ls [block!] /local ys ys' gap r
] [
	assert [12 <= length? ls  "requires 3+ lines"]
	ys:  extract/index ls 4 2
	ys': extract/index ls 4 4
	assert [equal? length? ys length? ys']
	take ys  take/last ys'
	gap: subtract average ys average ys'
	r: yes
	forall ys [
		r: r and about?/tol gap ys/1 - ys'/1 0.0 0.05
		ys': next ys'
	]
	r
]

assert [equally-spaced? text-bounds?/lines draw 10x10
		[pen blue line 1x1 4x2 line 1x4 8x5 line 1x7 8x8] 	'equally-spaced?]
assert [not equally-spaced? text-bounds?/lines draw 10x10
		[pen blue line 1x0 4x1 line 1x4 8x5 line 1x7 8x8] 	'equally-spaced?]


shoot: func [
	"returns a snapshot of a face, given by `vid` block"
	vid [block!] "face layout"
	/whole "capture the whole window"
	/backdrop "specify non-standard background"
		bd [tuple!]
	/async "return immediately, execute the provided callback upon finish"
		on-finish [function!]
	/local r
] [
	do compose/deep [
		(either async ['view/tight/no-wait/options]['view/tight/options]) [
			panel [(either backdrop [reduce ['backdrop bd]][[]]) origin 0x0 space 0x0 (vid)]
			rate (bst-rate)
			on-time [
				face/rate: none 		;-- ensure it won't trigger twice
				event: to-image (either whole ['face/parent]['face])
				unview/only face/parent
				(either async [reduce [:on-finish 'event]][[r: event]])
			]
		][
			; FIXME: on W8 the capture is often partial when goes off screen
			; offset: random system/view/screens/1/size - 50x50
			offset: random system/view/screens/1/size - 300x300
		]
	]
	r
]


shoot-parallel: func [
	"used to obtain lots of snapshots in parallel"
	code [block!] "should contain some `shoot` calls"
	/local cmd vid i started finished snaps rule
] [
	if empty? code [exit]
	started: 0  finished: 0		;-- these has to be different counters for async logic to work
	snaps: copy []
	parse code: copy/deep code rule: [any [
		set cmd ['shoot | 'shoot/whole] set vid block! (
			cmd: either 'shoot = cmd ['shoot/async]['shoot/whole/async]
			started: started + 1
			append snaps none
			do compose/deep [(cmd) [(vid)]
				func [i] [
					poke snaps (started) i
					finished: finished + 1
				]
			]
		)
	|	ahead any-block! into rule
	|	skip
	]]
	view [
		text "waiting for snapshots to complete" rate 5
		on-time [if started = finished [unview/only face/parent]]
	]
	i: 0
	parse code rule: [any [
		change [['shoot | 'shoot/whole] block!] (reduce [to-paren compose [pick snaps (i: i + 1)]])
		; change [['shoot | 'shoot/whole] block!] (take snaps) 		;-- inline the image code, may be slow
	|	ahead [block! | paren!] into rule
	|	skip
	]]
	do code
]


;-- does the same TESTS code with all of the following:
;  1 opaque font, opaque bgnd
;  2 opaque font, transparent bgnd
;  3 transparent font, opaque bgnd
;  4 transparent font, transparent bgnd
; modifies the tests names, adding a suffix (from `ss`)
four-ways: func [code [block!] /local ws ss i j d code' rule s full] [
	if empty? code [exit]
	ws: [
		base'    base-    base+    text'
		base'*   base-*   base+*   text'*
		base'**  base-**  base+**  text'**
		base'*** base-*** base+*** text'***
	]
	ss: ["no alpha" "bgnd alpha" "font alpha" "both alpha"]
	full: copy []
	repeat i 4 [
		code': copy/deep code
		unless 1 = i [
			repeat j d: (length? ws) / 4 [
				replace/all/deep code' ws/:j ws/(i - 1 * d + j)
			]
		]
		parse code' rule: [any [
			'--test-- change [set s string!] (rejoin [s " " ss/:i])
		|	ahead [block! | paren!] into rule
		|	skip
		]]
		append full code'
	]
	do full
]






;           ====
;       ======
;    =================
;   =======================================  higher-level testing funcs
;      ======
;          ====






maybe-display-shortly: func [
	"when user-mode is on, display an image with a message for review"
	im [image!] msg [string!]
] [
	if bst-user-mode [
		view [
			below
			image im rate bst-show-delay on-time [unview] focus on-key-down [unview]
			area 300x200 wrap msg
		]
	]
]


test-dual-chrome?: func [
	"test if colorset `cs` contains at least 2 colors"
	im [image!] cs [block!]
	/strict "exactly 2 colors"
	/local n
] [
	; NOTE: cleartype doesn't play by the rules and can produce
	;  multi-colored rendering out of seemingly monochrome font
	;  can't use = 2 here!  unless /strict is specified
	n: length? collect [forall cs [if tuple? cs/1 [keep cs/1]]]
	unless any [n = 2  all [not strict  n >= 2] ] [
		maybe-display-shortly im form reduce [
			"expected" pick ["=" ">="] true = strict "2 colors, got" n "from" mold cs
		]
		return no
	]
	yes
]


test-color-match?: func [
	"test if colors x and y are similar"
	im [image!] x [tuple!] y [tuple!] /tol tolrel tolabs
] [
	test-match?/tol im x y tolrel tolabs
]


test-size-match?: func [
	"test if image `im` size is equal to `sz` (save for a possible rounding error)"
	im [image!] sz [pair!] /local s
] [
	unless all [
		about?/tol sz/x im/size/x 0 1	;-- allow 1px of error max
		about?/tol sz/y im/size/y 0 1
	] [
		s: form reduce [
			"expected image of size" sz ", got" im/size
			", compared with tol rel=0 abs=1"
		]
		maybe-display-shortly im s
		return no
	]
	yes
]


test-match?: func [
	"wrapper around `about?` func"
	im [image!] x [number! tuple!] y [number! tuple!] /tol tolrel tolabs /local s
] [
	unless about?/tol x y tolrel tolabs [
		s: form reduce [
			"expected similarity between" x "and" y
			", failed with tol rel=" tolrel "abs=" tolabs
		]
		maybe-display-shortly im s
		return no
	]
	yes
]


test-contrast?: func [
	"test if colors x and y are NOT similar"
	im [image!] x [tuple!] y [tuple!] /tol tolrel tolabs /local s
] [
	if about?/tol x y tolrel tolabs [
		s: form reduce [
			"expected contrast text/bgnd combo, got" x "and" y
			", compared with tol rel=" tolrel "abs=" tolabs
		]
		maybe-display-shortly im s
		return no
	]
	yes
]


test-text-anchor?: func [
	"wrapper around `text-anchor?` func"
	'an [word!] im [image!] /local m als an'
] [
	unless an = an': text-anchor? im [
		als: [
			c ">center<" n "^^north^^" s "_south_" e "east>>" w "<<west"
			ne "^^northeast>>" nw "<<^^northwest" se "__southeast>>" sw "<<__southwest"
		]
		m: form reduce ["expected" select als an "(" an ") alignment, got" an']
		maybe-display-shortly im m
		return no
	]
	yes
]


test-text-aligned?: func [
	"test if image text is right/left aligned"
	'al [word!] im [image!] /local m
] [
	unless text-aligned? :al im [
		m: form reduce ["expected text to be" al "- aligned, failed"]
		maybe-display-shortly im m
		return no
	]
	yes
]


test-text-NOT-aligned?: func [
	"test if image text is NOT right/left aligned"
	'al [word!] im [image!] /local m
] [
	if text-aligned? :al im [
		m: form reduce ["expected text to be NOT" al "- aligned, but it is"]
		maybe-display-shortly im m
		return no
	]
	yes
]


test-equally-spaced?: func [
	"test if image contains 3+ equidistant text lines"
	im [image!] /local m ls x y dx dy
] [
	ls: text-bounds?/lines im
	unless 12 <= length? ls [
		m: form reduce ["expected at least 3 lines of text, got" (length? ls) / 4 "from" mold ls]
		maybe-display-shortly im m
		return no
	]
	unless equally-spaced? ls [
		m: form reduce ["expected text lines to be equally spaced, got coordinates:"]
		foreach [x y dx dy] ls [append m form reduce ["^/" x y dx dy]]
		maybe-display-shortly im m
		return no
	]
	yes
]


test-NOT-equally-spaced?: func [
	"test if image contains 3+ NOT equidistant text lines"
	im [image!] /local m ls x y dx dy
] [
	ls: text-bounds?/lines im
	unless 12 <= length? ls [
		m: form reduce ["expected at least 3 lines of text, got" (length? ls) / 4 "from" mold ls]
		maybe-display-shortly im m
		return no
	]
	if equally-spaced? ls [
		m: form reduce ["expected text lines to be UN-equally spaced, got coordinates:"]
		foreach [x y dx dy] ls [append m form reduce ["^/" x y dx dy]]
		maybe-display-shortly im m
		return no
	]
	yes
]








;           ====
;       ======
;    =================
;   =======================================  self-tests
;      ======
;          ====







===start-group=== "testing utilities test"

	; --test-- "tut-01"
	; 	--assert [1x1 2x1 1x2 2x2] = collect [forxy xy make image! 2x2 [keep xy]]

	; --test-- "tut-02"
	; 	--assert 1 = min' 1 2
	; 	--assert 2 = max' 1 2
	; 	--assert 1 = min' 1 none
	; 	--assert 1 = max' 1 none
	; 	--assert 2 = min' none 2
	; 	--assert 2 = max' none 2
	; 	--assert none = min' none none
	; 	--assert none = max' none none

	; --test-- "tut-03"
	; 	--assert 0.5 = amnt? 254 127
	; 	--assert 0.0 = amnt? 254 0
	; 	--assert none = amnt? 0 127

	; --test-- "tut-04"
	; 	--assert 0.5 = amnt3? 200.100.50 100.50.25
	; 	--assert 0.5 = amnt3? 200.100.50 100.50.100
	; 	--assert 0.5 = amnt3? 200.100.50 100.255.255
	; 	--assert 0.0 = amnt3? 200.100.50 0.255.255
	; 	--assert 0.0 = amnt3? 200.100.50 255.0.255
	; 	--assert 0.0 = amnt3? 200.100.50 255.255.0
	; 	--assert 1.0 = amnt3? 200.100.50 255.255.255
	; 	--assert 0.0 = amnt3? 0.0.0 100.200.100	

	; --test-- "tut-05"
	; 	--assert 10.10.10 = math3 10.10.10 20.10.0 [a] 	
	; 	--assert 20.10.0  = math3 10.10.10 20.10.0 [b] 	
	; 	--assert 30.20.10 = math3 10.10.10 20.10.0 [a + b] 
	; 	--assert 0.20.40  = math3 10.10.10 20.10.0 [a * 2 - b * 2] 
	; 	--assert 100.10.0 = math3 10.1.0 10.10.10 [a * 100.0 + b - b / 10.0]


	; --test-- "tut-06"
	; 	--assert 50.60.70 = diff3 100.100.100 50.40.30
	; 	--assert 100.140.130 = diff3 100.100.100 200.240.230
	; 	--assert 100.140.130 = diff3 200.240.230 100.100.100

	; --test-- "tut-07"
	; 	--assert (bst-x: 1.2.3.4 bst-x/4: none 3 = length? bst-x)
	; 	--assert [255.255.255 100%] = count-colors make image! 2x2
	; 	--assert [255.255.255 75% 0.0.0 25%] = count-colors make image! [2x2 #{FFFFFF FFFFFF 000000 FFFFFF}]

	; --test-- "tut-08"
	; 	--assert [] = sub-bgnd [] 
	; 	--assert [255.255.255 100%] = sub-bgnd count-colors make image! 2x2 
	; 	--assert [255.255.255 75% 0.0.0 25%] = sub-bgnd count-colors make image! [2x2 #{FFFFFF FFFFFF 000000 FFFFFF}]
	; 	--assert [255.255.0 75% 0.0.255 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 808080 FFFF00}]
	; 	--assert [255.255.0 75% 0.0.192 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 404090 FFFF00}]
	; 	--assert [255.255.0 75% 0.64.192 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]


	; --test-- "tut-09"
	; 	--assert about? 0.05 0.02
	; 	--assert about? 0.95 0.9
	; 	--assert not about? 0.2 0.02
	; 	--assert not about? 0.95 0.8
	; 	--assert about? 254.254.0 255.254.0
	; 	--assert about? 254.254.0 255.250.0
	; 	--assert about? 254.254.0 249.254.0
	; 	--assert about? 0.0.0 0.0.1
	; 	--assert about? 0.0.0 0.0.5
	; 	--assert not about? 254.254.0 230.254.0
	; 	--assert not about? 100.100.100 130.70.100
	; 	--assert error? try [about? red none]

	; --test-- "tut-10"
	; 	--assert white = bright white 
	; 	--assert white = bright 10.10.10
	; 	--assert blue  = bright 0.0.1 
	; 	--assert black = bright black 
	; 	--assert yellow = bright 100.100.0

	; --test-- "tut-11"
	; 	--assert white brighter-than? gray 	
	; 	--assert white brighter-than? blue 	
	; 	--assert white brighter-than? cyan 	
	; 	--assert not (white brighter-than? white)
	; 	--assert not (blue brighter-than? white)
	; 	--assert not (cyan brighter-than? white)
	; 	--assert 0.1.0 brighter-than? black 	
	; 	--assert not (black brighter-than? black)
	; 	--assert not (blue brighter-than? red) 
	; 	--assert yellow brighter-than? red 	

	; --test-- "tut-12"
	; 	--assert [0.0.0 70% 100.0.0 30%] = clash [0.0.0 70% 100.0.0 20% 50.0.0 10%] 
	; 	--assert [0.0.0 70% 100.50.0 30%] = clash [0.0.0 70% 100.50.0 20% 51.23.0 10%]

	; --test-- "tut-13"
	; 	--assert [255.255.0 75% 0.64.192 25%] = colorset? make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]
	; 	--assert [255.255.0 0.64.192] = colorset?/tuples make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]

	; --test-- "tut-14"
	; 	--assert [0.0 0.0 1.0 1.0] = text-bounds? draw 10x10 [pen blue box 0x0 9x9]
	; 	--assert [0.0 0.0 1.0 1.0] = text-bounds?/lines draw 10x10 [pen blue box 0x0 9x9]
	; 	--assert [0.1 0.1 0.9 0.9] = text-bounds? draw 10x10
	; 			[pen blue line 1x1 4x2 line 1x4 8x5 line 1x7 8x8]
	; 	--assert [0.1 0.1 0.5 0.3  0.1 0.4 0.9 0.6  0.1 0.7 0.9 0.9] =
	; 			text-bounds?/lines draw 10x10
	; 			[pen blue line 1x1 4x2 line 1x4 8x5 line 1x7 8x8]

	; --test-- "tut-15"
	; 	bst-im: make image! 10x10  bst-im/(2x2): blue
	; 	--assert [0.15 0.15] = text-center? bst-im
	; 	--assert [0.1 0.1] = text-center? draw 10x10 [pen blue box 0x0 1x1]
	; 	--assert [0.5 0.5] = text-center? draw 10x10 [pen blue box 0x0 9x9]


	; --test-- "tut-16"
	; 	--assert 'nw = text-anchor? draw 10x10 [pen blue box 0x0 2x2]
	; 	--assert 'ne = text-anchor? draw 10x10 [pen blue box 7x0 9x2]
	; 	--assert 'sw = text-anchor? draw 10x10 [pen blue box 0x7 2x9]
	; 	--assert 'se = text-anchor? draw 10x10 [pen blue box 7x7 9x9]
	; 	--assert 'n  = text-anchor? draw 10x10 [pen blue box 0x0 9x4]
	; 	--assert 's  = text-anchor? draw 10x10 [pen blue box 0x4 9x9]
	; 	--assert 'w  = text-anchor? draw 10x10 [pen blue box 0x0 4x9]
	; 	--assert 'e  = text-anchor? draw 10x10 [pen blue box 4x0 9x9]
	; 	--assert 'c  = text-anchor? draw 10x10 [pen blue box 0x0 9x9]

	; --test-- "tut-17"
	; 	--assert text-aligned? left draw 10x10 [pen blue box 1x0 2x5]
	; 	--assert not text-aligned? right draw 10x10 [pen blue box 1x0 2x5]
	; 	--assert text-aligned? right draw 10x10 [pen blue box 7x0 8x5]
	; 	--assert not text-aligned? left draw 10x10 [pen blue box 7x0 8x5]
	; 	--assert not text-aligned? left draw 10x10 [pen blue box 4x4 6x6]
	; 	--assert not text-aligned? right draw 10x10 [pen blue box 4x4 6x6]

	; --test-- "tut-18"
	; 	--assert equally-spaced? text-bounds?/lines draw 10x10
	; 			[pen blue line 1x1 4x2 line 1x4 8x5 line 1x7 8x8]
	; 	--assert not equally-spaced? text-bounds?/lines draw 10x10
	; 			[pen blue line 1x0 4x1 line 1x4 8x5 line 1x7 8x8]

===end-group===










;           ====
;       ======
;    =================
;   =======================================  main tests
;      ======
;          ====







===start-group=== "to-image check"

	--test-- "tic-1 size adequacy"
		bst-im: shoot [base 100x100]
		bst-sz: 100x100 * system/view/metrics/dpi / 96.0
		--assert test-size-match? bst-im bst-sz

	--test-- "tic-2 presence of non-client area"
		bst-im: shoot/whole [base 200x200]
		bst-sz: 200x200 * system/view/metrics/dpi / 96.0
		;-- non-client area should be bigger than the base:
		--assert within? bst-sz + 0x10 0x0 bst-im/size

	--test-- "tic-3 capture of color blending"
		bst-sz: 200x200 * system/view/metrics/dpi / 96.0
		bst-clr: blue + 0.0.0.128
		bst-clr1: blue / 2
		bst-clr2: blue - (blue / 4)
		bst-im: shoot/backdrop [
			at 60x0 base 140x140 bst-clr
			at 0x60 base 140x140 bst-clr
		] black
		bst-cs: count-colors bst-im
		bst-area0: 200 ** 2.0 					;-- full
		bst-area1: 80 ** 2.0 / bst-area0		;-- bright center
		bst-area2: 60 ** 2.0 * 2 / bst-area0	;-- black corners
		bst-area3: 1.0 - bst-area1 - bst-area2	;-- rest
		--assert test-size-match? bst-im bst-sz
		--assert 6 <= length? bst-cs
		--assert test-match? bst-im bst-cs/2 bst-area3
		--assert test-match? bst-im bst-cs/4 bst-area2
		--assert test-match? bst-im bst-cs/6 bst-area1
		--assert test-color-match? bst-im bst-cs/1 bst-clr1
		--assert test-color-match? bst-im bst-cs/3 black
		--assert test-color-match? bst-im bst-cs/5 bst-clr2

	; FIXME: this doesn't work yet on W7...
	; --test-- "tic-4 overlapping bases"
	; 	bst-sz: 100x100 * system/view/metrics/dpi / 96.0
	; 	bst-im: shoot [
	; 		at 0x0 base 100x100 white
	; 		at 10x10 base 80x80 255.0.0.128
	; 	]
	; 	bst-cs: count-colors bst-im
	; 	--assert test-size-match? bst-im bst-sz
	; 	--assert test-dual-chrome?/strict bst-im bst-cs
	; 	--assert test-match? bst-im bst-cs/2 0.64
	; 	--assert test-match? bst-im bst-cs/4 0.36
	; 	--assert test-color-match? bst-im bst-cs/1 255.127.127
	; 	--assert test-color-match? bst-im bst-cs/3 white

===end-group===


===start-group=== "color rendering check"

	four-ways [
	--test-- "crc-11 - base, preset colors"
		; checks if text is 1) indeed rendered 2) colors are as requested
		bst-cs: colorset? bst-im: shoot [base' "CAT"]
		; ? bst-im
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-color-match? bst-im bst-cs/1 bst-colors/bg
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 95%  0 4.5%
		--assert test-match?/tol bst-im bst-cs/4 5%   0 4.5%
	]

	--test-- "crc-12 - base, system default background"
		; checks if box uses the system default background color
		bst-cs: colorset? bst-im: shoot [box "CAT" font bst-font1]
		--assert test-dual-chrome? bst-im bst-cs
		try [	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/window
		]
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 95%  0 4.5%
		--assert test-match?/tol bst-im bst-cs/4 5%   0 4.5%

	--test-- "crc-13 - base, system default bg+text"
		; checks if unspecified font color defaults to the system default text color
		bst-cs: colorset? bst-im: shoot [box "CAT" font-size 16]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-contrast? bst-im bst-cs/1 bst-cs/3
		try [ 	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/window
		]
		try [ 	;-- colors/text might be undefined
			--assert test-color-match? bst-im bst-cs/3 system/view/metrics/colors/text
		]
		--assert test-match?/tol bst-im bst-cs/2 95%  0 4.5%
		--assert test-match?/tol bst-im bst-cs/4 5%   0 4.5%

	four-ways [
	--test-- "crc-21 - text, preset colors"
		; checks if text is 1) indeed rendered 2) colors are as requested
		bst-cs: colorset? bst-im: shoot [text' "CAT"]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-color-match? bst-im bst-cs/1 bst-colors/bg
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 90%  0 9.0%
		--assert test-match?/tol bst-im bst-cs/4 9.5% 0 9.0%
	]

	--test-- "crc-22 - text, system default background"
		; checks if box uses the system default background color
		bst-cs: colorset? bst-im: shoot [text 100 "CAT" font bst-font1]
		--assert test-dual-chrome? bst-im bst-cs
		try [	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/window
		]
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 90%  0 9.0%
		--assert test-match?/tol bst-im bst-cs/4 9.5% 0 9.0%

	--test-- "crc-23 - text, system default bg+text"
		; checks if unspecified font color defaults to the system default text color
		bst-cs: colorset? bst-im: shoot [text bold 100 "CAT" font-size 16]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-contrast? bst-im bst-cs/1 bst-cs/3
		try [ 	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/window
		]
		try [ 	;-- colors/text might be undefined
			--assert test-color-match? bst-im bst-cs/3 system/view/metrics/colors/text
		]
		--assert test-match?/tol bst-im bst-cs/2 90%  0 9.0%
		--assert test-match?/tol bst-im bst-cs/4 9.5% 0 9.0%

===end-group===


===start-group=== "text alignment check"

	four-ways [
	shoot-parallel [

	--test-- "tac-11"
		--assert test-text-anchor? c shoot [base' "CAT"]
		--assert test-text-anchor? c shoot [base' "CAT" middle]
		--assert test-text-anchor? c shoot [base' "CAT" center]
		--assert test-text-anchor? c shoot [base' "CAT" middle center]

	--test-- "tac-12"
		--assert test-text-anchor? w shoot [base' "CAT" left]
		--assert test-text-anchor? e shoot [base' "CAT" right]
		--assert test-text-anchor? n shoot [base' "CAT" top]
		--assert test-text-anchor? s shoot [base' "CAT" bottom]

	--test-- "tac-13"
		--assert test-text-anchor? nw shoot [base' "CAT" left top]
		--assert test-text-anchor? ne shoot [base' "CAT" right top]
		--assert test-text-anchor? sw shoot [base' "CAT" left bottom]
		--assert test-text-anchor? se shoot [base' "CAT" right bottom]

	--test-- "tac-21"
		--assert test-text-anchor? c shoot [base' "C A T"]
		--assert test-text-anchor? c shoot [base' "C A T" middle]
		--assert test-text-anchor? c shoot [base' "C A T" center]
		--assert test-text-anchor? c shoot [base' "C A T" middle center]

	--test-- "tac-22"
		--assert test-text-anchor? w shoot [base' "C A T" left]
		--assert test-text-anchor? e shoot [base' "C A T" right]
		--assert test-text-anchor? n shoot [base' "C A T" top]
		--assert test-text-anchor? s shoot [base' "C A T" bottom]

	--test-- "tac-23"
		--assert test-text-anchor? nw shoot [base' "C A T" left top]
		--assert test-text-anchor? ne shoot [base' "C A T" right top]
		--assert test-text-anchor? sw shoot [base' "C A T" left bottom]
		--assert test-text-anchor? se shoot [base' "C A T" right bottom]

	--test-- "tac-31"
		--assert test-text-anchor? c shoot [base+ "C^/A^/T"]
		--assert test-text-anchor? c shoot [base+ "C^/A^/T" middle]
		--assert test-text-anchor? c shoot [base+ "C^/A^/T" center]
		--assert test-text-anchor? c shoot [base+ "C^/A^/T" middle center]

	--test-- "tac-32"
		--assert test-text-anchor? w shoot [base+ "C^/A^/T" left]
		--assert test-text-anchor? e shoot [base+ "C^/A^/T" right]
		--assert test-text-anchor? n shoot [base+ "C^/A^/T" top]
		--assert test-text-anchor? s shoot [base+ "C^/A^/T" bottom]

	--test-- "tac-33"
		--assert test-text-anchor? nw shoot [base+ "C^/A^/T" left top]
		--assert test-text-anchor? ne shoot [base+ "C^/A^/T" right top]
		--assert test-text-anchor? sw shoot [base+ "C^/A^/T" left bottom]
		--assert test-text-anchor? se shoot [base+ "C^/A^/T" right bottom]

	--test-- "tac-41"
		--assert test-text-anchor? c shoot [base- 50x100 "cat auto test" wrap]
		--assert test-text-anchor? c shoot [base- 50x100 "cat auto test" wrap middle]
		--assert test-text-anchor? c shoot [base- 50x100 "cat auto test" wrap center]
		--assert test-text-anchor? c shoot [base- 50x100 "cat auto test" wrap middle center]

	--test-- "tac-42"
		--assert test-text-anchor? w shoot [base- 50x100 "cat auto test" wrap left]
		--assert test-text-anchor? e shoot [base- 50x100 "cat auto test" wrap right]
		--assert test-text-anchor? n shoot [base- 50x100 "cat auto test" wrap top]
		--assert test-text-anchor? s shoot [base- 50x100 "cat auto test" wrap bottom]

	--test-- "tac-43"
		--assert test-text-anchor? nw shoot [base- 50x100 "cat auto test" wrap left top]
		--assert test-text-anchor? ne shoot [base- 50x100 "cat auto test" wrap right top]
		--assert test-text-anchor? sw shoot [base- 50x100 "cat auto test" wrap left bottom]
		--assert test-text-anchor? se shoot [base- 50x100 "cat auto test" wrap right bottom]

	--test-- "tac-51"
		--assert test-text-aligned?     left  shoot [base- 50x100 "cat boot test" wrap left]
		--assert test-text-aligned?     left  shoot [base- 50x100 "cat boot test" wrap left top]
		--assert test-text-aligned?     left  shoot [base- 50x100 "cat boot test" wrap left bottom]
		--assert test-text-aligned?     right shoot [base- 50x100 "cat boot test" wrap right]
		--assert test-text-aligned?     right shoot [base- 50x100 "cat boot test" wrap right top]
		--assert test-text-aligned?     right shoot [base- 50x100 "cat boot test" wrap right bottom]
		--assert test-text-NOT-aligned? right shoot [base- 50x100 "cat boot test" wrap left]
		--assert test-text-NOT-aligned? left  shoot [base- 50x100 "cat boot test" wrap right]
		--assert test-text-NOT-aligned? left  shoot [base- 50x100 "cat boot test" wrap]
		--assert test-text-NOT-aligned? right shoot [base- 50x100 "cat boot test" wrap]

	--test-- "tac-52"
		--assert test-equally-spaced? shoot [base- 50x100 "cat auto test" wrap]
		--assert test-equally-spaced? shoot [base- 50x100 "cat auto test" wrap left]
		--assert test-equally-spaced? shoot [base- 50x100 "cat auto test" wrap right]
		--assert test-NOT-equally-spaced? shoot [base- 50x100 "cat auto^/^/test" wrap]

	]	;-- shoot-parallel
	]	;-- four-ways

===end-group===



bst-cleanup

]]  ; do [if all [object? :system/view  system/platform = 'Windows] [

~~~end-file~~~



