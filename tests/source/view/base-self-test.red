Red [
	Title:   "BASE automatic self assessment script"
	Author:  "hiiamboris"
	File:    %base-self-test.red
	Purpose: "Define BASE face behavior and detect future regressions"
	Rights:  "Copyright (C) 2016-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	; Needs:   'View
]

;@@ TODO: `area` face tests
;@@ TODO: `size-text` tests, for different faces


#include %../../../quick-test/quick-test.red


~~~start-file~~~ "base-self-test"

;-- relies upon the View subsystem (not yet available on some platforms)
;@@ FIXME: currently these tests are hopeless on MacOS
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
;-- because these two are swapped around between Red/GDI and GDI+
bst-colors: context [bg: yellow fg: red]


;-- it's best to use bold fonts to reduce the effects of cleartype cheating
bst-font1:  make font! [name: system/view/fonts/serif size: 16 style: 'bold color: bst-colors/fg]
bst-font1*: make font! [name: system/view/fonts/serif size: 16 style: 'bold color: bst-colors/fg + 0.0.0.5]
bst-font2:  make font! [name: system/view/fonts/fixed size: 11 style: 'bold color: bst-colors/fg]
bst-font2*: make font! [name: system/view/fonts/fixed size: 11 style: 'bold color: bst-colors/fg + 0.0.0.5]


bst-styles-backup: copy system/view/VID/styles

;-- styles with optional font/background transparency
extend system/view/VID/styles [
	text':		[template: [type: 'text  size: 100x25 font: bst-font1  color: bst-colors/bg]]
	text'*:		[template: [type: 'text  size: 100x25 font: bst-font1  color: bst-colors/bg + 0.0.0.5]]
	text'**:	[template: [type: 'text  size: 100x25 font: bst-font1* color: bst-colors/bg]]
	text'***:	[template: [type: 'text  size: 100x25 font: bst-font1* color: bst-colors/bg + 0.0.0.5]]

	base':		[template: [type: 'base  size: 100x100 font: bst-font1  color: bst-colors/bg]]
	base'*:		[template: [type: 'base  size: 100x100 font: bst-font1  color: bst-colors/bg + 0.0.0.5]]
	base'**:	[template: [type: 'base  size: 100x100 font: bst-font1* color: bst-colors/bg]]
	base'***:	[template: [type: 'base  size: 100x100 font: bst-font1* color: bst-colors/bg + 0.0.0.5]]
	base-:		[template: [type: 'base  size: 50x100  font: bst-font2  color: bst-colors/bg]]
	base-*:		[template: [type: 'base  size: 50x100  font: bst-font2  color: bst-colors/bg + 0.0.0.5]]
	base-**:	[template: [type: 'base  size: 50x100  font: bst-font2* color: bst-colors/bg]]
	base-***:	[template: [type: 'base  size: 50x100  font: bst-font2* color: bst-colors/bg + 0.0.0.5]]
	base+:		[template: [type: 'base  size: 50x100  font: bst-font1  color: bst-colors/bg]]
	base+*:		[template: [type: 'base  size: 50x100  font: bst-font1  color: bst-colors/bg + 0.0.0.5]]
	base+**:	[template: [type: 'base  size: 50x100  font: bst-font1* color: bst-colors/bg]]
	base+***:	[template: [type: 'base  size: 50x100  font: bst-font1* color: bst-colors/bg + 0.0.0.5]]
]




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


;-- removes system/words pollution done by base-self-test
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
		set p 1x1 + as-pair i % s/x to integer! i / s/x
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
	max' 	0.0 	;-- in case all amounts are none (c = black), return 0.0
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

assert [50.60.70    = diff3 100.100.100 50.40.30 		'diff3]
assert [100.140.130 = diff3 100.100.100 200.240.230 	'diff3]
assert [100.140.130 = diff3 200.240.230 100.100.100 	'diff3]


contrast: func [
	"contrast (0 to 1) between 2 tuples"
	a [tuple!] b [tuple!]
] [
	a: diff3 a b
	(max a/1 max a/2 a/3) / 255.0
]

assert [0 = contrast black black]
assert [1 = contrast white black]
assert [1 = contrast black white]
assert [1 = contrast black blue]
assert [1 = contrast red   blue]
assert [10.0 / 255 = contrast 10.20.30 20.10.20]


imgdiff: func [
	"subtracts image B from image A in place, returns A"
	a [image!] b [image!]
] [
	assert [a/size = b/size]
	forxy xy a [
		a/:xy: either all [0 < xy/x  xy/x < a/size/x  0 < xy/y  xy/y < a/size/y]
			[ diff3 a/:xy b/:xy ]
			[ 0.0.0 ]		;-- ignore the border
	]
	a
]

assert [(make image! [3x3 0.0.0]) = imgdiff make image! 3x3 make image! 3x3]

;-- return format: [tuple! percent! ...]
;-- removes alpha channel so it won't cause trouble
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


sub-bgnd: func [
	"subtracts background (1st tuple) from the color set (modifies)"
	cs [block!] /local x cs' bg
] [
	unless empty? cs [
		bg: cs/1
		cs': skip cs 2
		while [not tail? cs'][
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



bright: func [
	"returns color c of it's maximum brightness"
	c [tuple!] /local hi i
] [
	if 4 = length? c [c/4: none]
	unless black = c [
		hi: max c/1 max c/2 c/3
		repeat i 3 [c/:i: to integer! c/:i * 255 / hi]
	]
	c
]

assert [white = bright white 		'bright]
assert [white = bright 10.10.10 	'bright]
assert [blue  = bright 0.0.1 		'bright]
assert [black = bright black 		'bright]
assert [yellow = bright 100.100.0 	'bright]


;-- very simple tuples brightness comparison
;-- used to choose a brighter shade when clashing palette
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
	;-- start from index 1, since W8 sometimes returns 2 shades of background color!
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


img-black?: func [
	"checks if image is black or almost black (applies tolerance to each pixel)"
	im [image!] /tol tolrel tolabs /local nonzero
] [
	assert [im/size/x * im/size/y > 0  'im]				;-- shouldn't be empty (`empty?` is bugged)
	any [
		empty? nonzero: trim im/rgb						;-- trivial case - all black
		all [											;-- or try to apply tolerance
			any [all [tolrel tolrel > 0] all [tolabs tolabs > 0]]
			about?/tol to-integer last sort nonzero  0  tolrel tolabs
		]
	]
]

assert [empty? trim #{0000}]
assert [    img-black? make image! [3x3 0.0.0]]
assert [not img-black? make image! [3x3 0.0.1]]
assert [    img-black?/tol make image! [3x3 10.0.0] 0 10]
assert [not img-black?/tol make image! [3x3 11.0.0] 0 10]


text-bounds?: func [
	"calculates the text boundaries on an image [x y dx dy]; returns none if no text!"
	im [image!] "(area covered by the text should be < 50%)"
	/lines
		{return per-line boundaries [x y dx dy ...]
		(characters must be vertically contiguous: "===" is 2 lines, "=I=" is one)}
	/local xy ts box text-before? text-here?
] [
	ts: colorset?/tuples im
	if 2 > length? ts [return none]
	; assert [2 <= length? ts] 		;-- can be > 2 colors for a cleartype render
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
		[scale 0.5 0.5 pen blue line 3x3 9x5 line 3x9 17x11 line 3x15 17x17] 	'text-bounds?]
assert [[0.1 0.1 0.5 0.3  0.1 0.4 0.9 0.6  0.1 0.7 0.9 0.9] =
		text-bounds?/lines draw 10x10
		[scale 0.5 0.5 pen blue line 3x3 9x5 line 3x9 17x11 line 3x15 17x17] 	'text-bounds?]


text-center?: func [
	"locates mean center of non-background (text?) pixels; returns none if no text"
	im [image!] /local xy xsum ysum n ts
][
	ts: colorset?/tuples im
	if 2 > length? ts [return none]
	; assert [2 <= length? ts]
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
	"calculates predominant text orientation; none if no text"
	im [image!] /local x y c
] [
	unless c: text-center? im [return none]
	x: either about? 0.5 c/1 [2][pick [1 3] c/1 < 0.5]
	y: either about? 0.5 c/2 [2][pick [1 3] c/2 < 0.5]
	pick [nw n ne  w c e  sw s se] y - 1 * 3 + x
]


assert ['nw = text-anchor? draw 10x10 [pen blue box 0x0 2x2] 	'text-anchor?]
assert ['ne = text-anchor? draw 10x10 [pen blue box 7x0 9x2] 	'text-anchor?]
assert ['sw = text-anchor? draw 10x10 [pen blue box 0x7 2x9] 	'text-anchor?]
assert ['se = text-anchor? draw 10x10 [pen blue box 7x7 9x9] 	'text-anchor?]
assert ['n  = text-anchor? draw 10x10 [pen blue box 0x0 9x4] 	'text-anchor?]
assert ['s  = text-anchor? draw 10x10 [pen blue box 0x4 9x9] 	'text-anchor?]
assert ['w  = text-anchor? draw 10x10 [pen blue box 0x0 4x9] 	'text-anchor?]
assert ['e  = text-anchor? draw 10x10 [pen blue box 4x0 9x9] 	'text-anchor?]
assert ['c  = text-anchor? draw 10x10 [pen blue box 0x0 9x9] 	'text-anchor?]


text-aligned?: func [
	"checks if all text lines are aligned with al=left or al=right or al=top or al=bottom"
	'al [word! block!] im [image!] /not "passes if none of the provided alignments are true"
	/local _ r ls x dx
] [
	al: compose [(al)]
	r: yes
	not: either not [:system/words/not][:do]
	foreach al al [
		assert [find [right left top bottom] al]
		unless ls: text-bounds?/lines im [return no]
		either find [left right] al [
			foreach [x _ dx _] ls compose [
				r: r and not about?/tol (either 'left = al [[0.07 x]][[0.93 dx]]) 0 0.07
			]
		][
			foreach [_ y _ dy] ls compose [
				r: r and not about?/tol (either 'top  = al [[0.07 y]][[0.93 dy]]) 0 0.07
			]
		]
	]
	r
]

assert [	text-aligned? left  draw 10x10 [pen blue box 1x0 2x5] 	'text-aligned?]
assert [not text-aligned? right draw 10x10 [pen blue box 1x0 2x5] 	'text-aligned?]
assert [	text-aligned? right draw 10x10 [pen blue box 7x0 8x5] 	'text-aligned?]
assert [not text-aligned? left  draw 10x10 [pen blue box 7x0 8x5] 	'text-aligned?]
assert [not text-aligned? left  draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [not text-aligned? right draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [text-aligned?/not left  draw 10x10 [pen blue box 7x0 8x5] 	'text-aligned?]
assert [text-aligned?/not left  draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [text-aligned?/not right draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]

assert [	text-aligned? top    draw 10x10 [pen blue box 0x1 5x2] 	'text-aligned?]
assert [not text-aligned? bottom draw 10x10 [pen blue box 0x1 5x2] 	'text-aligned?]
assert [	text-aligned? bottom draw 10x10 [pen blue box 0x7 5x8] 	'text-aligned?]
assert [not text-aligned? top    draw 10x10 [pen blue box 0x7 5x8] 	'text-aligned?]
assert [not text-aligned? top    draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [not text-aligned? bottom draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [text-aligned?/not [top left]              draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [text-aligned?/not [right bottom]          draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]
assert [text-aligned?/not [top left right bottom] draw 10x10 [pen blue box 4x4 6x6] 	'text-aligned?]


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
		[scale 0.5 0.5 pen blue line 3x3 9x5 line 3x9 17x11 line 3x15 17x17] 	'equally-spaced?]
assert [not equally-spaced? text-bounds?/lines draw 10x10
		[scale 0.5 0.5 pen blue line 3x1 9x3 line 3x9 17x11 line 3x15 17x17] 	'equally-spaced?]


;-- this is not a proper blur, but a little approximate - enough for the task at hand
blur3x3: function [im [image!]] [
	im-1: copy im  im-1/alpha: 255 - 25
	im-2: copy im  im-2/alpha: 255 - 50
	draw copy im [
		image im-2 -1x0
		image im-2  1x0
		image im-2  0x1
		image im-2  0x-1
		image im-1 -1x-1
		image im-1  1x-1
		image im-1 -1x1
		image im-1  1x1
	]
]


;-- took this from https://gitlab.com/hiiamboris/red-view-test-system
;-- sensitive to both changes in overall brightness (1) and individual "outlier" pixels (2):
;-- 1) sum of (normalized) pixel contrasts (PC), checked against (fuzz^2)*area
;-- 2) sum of squares of PC/fuzz, checked against fuzz*area
visually-similar?: function [
	"Loosely compare two images for equality"
	im1 [image!]
	im2 [image!]
	/with fuzz [percent! float!] "Comparison fuzziness (0% = strict, default = 10%)"
][
	assert [im1/size = im2/size]
	fuzz: any [fuzz 10%]
	if fuzz = 0% [fuzz: 0.01%]							;-- no zero division
	assert [all [0 <= fuzz fuzz <= 1] 'fuzz]
	im1: blur3x3 im1									;-- blur images to lessen the effect of image offsets due to possible rounding errors
	im2: blur3x3 im2
	sum1: 0.0 sum2: 0.0 sumcsq: 0.0
	area: im1/size/x * im1/size/y
	max-sumcsq: area * fuzz								;-- sum of squares of pixel contrasts, allowing each pixel to have up to fuzz=contrast
	repeat i length? im1 [
		px1: im1/:i  px2: im2/:i
		sum1: sum1 + px1/1 + px1/2 + px1/3
		sum2: sum2 + px2/1 + px2/2 + px2/3
		c: (contrast px1 px2) / fuzz					;-- normalized to `fuzz`, so peaks when c >> fuzz
		sumcsq: c * c + sumcsq
		if sumcsq > max-sumcsq [return no]
	]
	sum-white: area * 3 * 255.0							;-- 3 for R,G,B, 255 for max brightness
	dif: (absolute sum2 - sum1) / sum-white				;-- relative difference in overall brightness
	dif <= (fuzz ** 2)
]

assert [    visually-similar? draw 1x1 [] draw 1x1 []]
assert [not visually-similar? draw 1x1 [] make image! [1x1 #{000000}]]


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
	loop 10 [do-events/no-wait]		;-- let the last windows actually close
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
;--  1 opaque font, opaque bgnd
;--  2 opaque font, transparent bgnd
;--  3 transparent font, opaque bgnd
;--  4 transparent font, transparent bgnd
;-- modifies the tests names, adding a suffix (from `ss`)
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
			repeat j d: to integer! (length? ws) / 4 [
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
	"when user-mode is on, display an image(s) with a message for review"
	im [image! block!] msg [string!]
] [
	im: compose [(im)]
	if bst-user-mode [
		view compose [
			across
			image (:im/1) rate bst-show-delay on-time [unview] focus on-key-down [unview]
			(collect [foreach im next im [keep 'image keep im]])
			return area 300x200 wrap msg
		]
	]
]


test-dual-chrome?: func [
	"test if colorset `cs` contains at least 2 colors"
	im [image!] cs [block!]
	/strict "exactly 2 colors"
	/local n
] [
	;-- NOTE: cleartype doesn't play by the rules and can produce
	;--  multi-colored rendering out of seemingly monochrome font
	;--  can't use = 2 here!  unless /strict is specified
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


test-images-of-equal-size?: func [
	"test if images A and B are of same size"
	a [image!] b [image!] /local s
] [
	unless a/size = b/size [
		s: form reduce [
			"expected images to of the same size, got" a/size "&" b/size
		]
		maybe-display-shortly [a b] s
		return no
	]
	yes
]

test-images-equal?: func [
	"test if images A and B are equal (excluding the border)"
	a [image!] b [image!] /with fuzz /local s
] [
	test-images-of-equal-size? a b
	fuzz: any [fuzz 10%]
	unless visually-similar?/with a b fuzz [
		s: form reduce [
			"expected images to be equal, but found to be not,"
			"compared with fuzziness=" fuzz
		]
		maybe-display-shortly [a b] s
		return no
	]
	yes
]

test-images-NOT-equal?: func [
	"test if images A and B are NOT equal (excluding the border)"
	a [image!] b [image!] /with fuzz /local s
] [
	test-images-of-equal-size? a b
	fuzz: any [fuzz 10%]
	if visually-similar?/with a b fuzz [
		s: form reduce [
			"expected images to be NOT equal, but they are,"
			"compared with fuzziness=" fuzz
		]
		maybe-display-shortly [a b] s
		return no
	]
	yes
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


test-same-text-size?: func [
	"test if text on 2 images is of equal size"
	im1 [image!] im2 [image!] /local s bs1 bs2 sz1 sz2
] [
	unless all [
		bs1: text-bounds? im1
		bs2: text-bounds? im2
		sz1: as-pair  round im1/size/x * (bs1/3 - bs1/1)  round im1/size/y * (bs1/4 - bs1/2)
		sz2: as-pair  round im2/size/x * (bs2/3 - bs2/1)  round im2/size/y * (bs2/4 - bs2/2)
		about?/tol sz1/x sz2/x 8% 1	;-- allow 8% + 1px of error - W10 has different proofing for unrotated text
		about?/tol sz1/y sz2/y 8% 1
	] [
		s: form reduce [
			"expected text to be of equal size on these images, got" sz1 "vs" sz2
			", compared with tol rel=8% abs=1"
		]
		maybe-display-shortly [im1 im2] s
		return no
	]
	yes
]


test-same-text-origin-and-size?: function [
	"test if text on 2 images is of equal size and origin"
	im1 [image!] im2 [image!]
] [
	unless all [
		bs1: text-bounds? im1
		bs2: text-bounds? im2
		or1: as-pair  round im1/size/x * bs1/1  round im1/size/y * bs1/2
		or2: as-pair  round im2/size/x * bs2/1  round im2/size/y * bs2/2
		sz1: as-pair  round im1/size/x * (bs1/3 - bs1/1)  round im1/size/y * (bs1/4 - bs1/2)
		sz2: as-pair  round im2/size/x * (bs2/3 - bs2/1)  round im2/size/y * (bs2/4 - bs2/2)
		origin-error: 3.0 / 96 * system/view/metrics/dpi		;-- 3px of error, scaled - enough?
		about?/tol or1/x or2/x 0% origin-error
		about?/tol or1/y or2/y 0% origin-error
		about?/tol sz1/x sz2/x 8% 1		;-- allow 8% + 1px of error - W10 has different proofing for unrotated text
		about?/tol sz1/y sz2/y 8% 1
	] [
		s: form reduce [
			"expected text to be of equal origin and size on these images, got"
			"origin=" or1 "vs" or2 "and size=" sz1 "vs" sz2
			", compared with tol rel=8% abs=1 (size), rel=0% abs=3px (origin)"
		]
		maybe-display-shortly [im1 im2] s
		return no
	]
	yes
]


test-match?: func [
	"wrapper around `about?` func (image is used for error display only)"
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
	"test if colors x and y are NOT similar (image is used for error display only)"
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
	"test if image text is right/left/top/bottom aligned"
	'al [word! block!] im [image!] /local m
] [
	unless text-aligned? :al im [
		m: form reduce ["expected text to be" al "- aligned, failed"]
		maybe-display-shortly im m
		return no
	]
	yes
]


test-text-NOT-aligned?: func [
	"test if image text is NOT right/left/top/bottom aligned"
	'al [word! block!] im [image!] /local m
] [
	unless text-aligned?/not :al im [
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
		m: "expected text lines to be equally spaced, got coordinates:"
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
	
	;-- use asserts during development and these - when finished

	--test-- "tut-01"
		--assert [1x1 2x1 1x2 2x2] = collect [forxy xy make image! 2x2 [keep xy]]

	--test-- "tut-02"
		--assert 1 = min' 1 2
		--assert 2 = max' 1 2
		--assert 1 = min' 1 none
		--assert 1 = max' 1 none
		--assert 2 = min' none 2
		--assert 2 = max' none 2
		--assert none = min' none none
		--assert none = max' none none

	--test-- "tut-03"
		--assert 0.5 = amnt? 254 127
		--assert 0.0 = amnt? 254 0
		--assert none = amnt? 0 127

	--test-- "tut-04"
		--assert 0.5 = amnt3? 200.100.50 100.50.25
		--assert 0.5 = amnt3? 200.100.50 100.50.100
		--assert 0.5 = amnt3? 200.100.50 100.255.255
		--assert 0.0 = amnt3? 200.100.50 0.255.255
		--assert 0.0 = amnt3? 200.100.50 255.0.255
		--assert 0.0 = amnt3? 200.100.50 255.255.0
		--assert 1.0 = amnt3? 200.100.50 255.255.255
		--assert 0.0 = amnt3? 0.0.0 100.200.100	

	--test-- "tut-05"
		--assert 10.10.10 = math3 10.10.10 20.10.0 [a] 	
		--assert 20.10.0  = math3 10.10.10 20.10.0 [b] 	
		--assert 30.20.10 = math3 10.10.10 20.10.0 [a + b] 
		--assert 0.20.40  = math3 10.10.10 20.10.0 [a * 2 - b * 2] 
		--assert 100.10.0 = math3 10.1.0 10.10.10 [a * 100.0 + b - b / 10.0]


	--test-- "tut-06"
		--assert 50.60.70 = diff3 100.100.100 50.40.30
		--assert 100.140.130 = diff3 100.100.100 200.240.230
		--assert 100.140.130 = diff3 200.240.230 100.100.100

	--test-- "tut-07"
		--assert (bst-x: 1.2.3.4 bst-x/4: none 3 = length? bst-x)
		--assert [255.255.255 100%] = count-colors make image! 2x2
		--assert [255.255.255 75% 0.0.0 25%] = count-colors make image! [2x2 #{FFFFFF FFFFFF 000000 FFFFFF}]

	--test-- "tut-08"
		--assert [] = sub-bgnd [] 
		--assert [255.255.255 100%] = sub-bgnd count-colors make image! 2x2 
		--assert [255.255.255 75% 0.0.0 25%] = sub-bgnd count-colors make image! [2x2 #{FFFFFF FFFFFF 000000 FFFFFF}]
		--assert [255.255.0 75% 0.0.255 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 808080 FFFF00}]
		--assert [255.255.0 75% 0.0.192 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 404090 FFFF00}]
		--assert [255.255.0 75% 0.64.192 25%] = sub-bgnd count-colors make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]


	--test-- "tut-09"
		--assert about? 0.05 0.02
		--assert about? 0.95 0.9
		--assert not about? 0.2 0.02
		--assert not about? 0.95 0.8
		--assert about? 254.254.0 255.254.0
		--assert about? 254.254.0 255.250.0
		--assert about? 254.254.0 249.254.0
		--assert about? 0.0.0 0.0.1
		--assert about? 0.0.0 0.0.5
		--assert not about? 254.254.0 230.254.0
		--assert not about? 100.100.100 130.70.100
		--assert error? try [about? red none]

	--test-- "tut-10"
		--assert white = bright white 
		--assert white = bright 10.10.10
		--assert blue  = bright 0.0.1 
		--assert black = bright black 
		--assert yellow = bright 100.100.0

	--test-- "tut-11"
		--assert white brighter-than? gray 	
		--assert white brighter-than? blue 	
		--assert white brighter-than? cyan 	
		--assert not (white brighter-than? white)
		--assert not (blue brighter-than? white)
		--assert not (cyan brighter-than? white)
		--assert 0.1.0 brighter-than? black 	
		--assert not (black brighter-than? black)
		--assert not (blue brighter-than? red) 
		--assert yellow brighter-than? red 	

	--test-- "tut-12"
		--assert [0.0.0 70% 100.0.0 30%] = clash [0.0.0 70% 100.0.0 20% 50.0.0 10%] 
		--assert [0.0.0 70% 100.50.0 30%] = clash [0.0.0 70% 100.50.0 20% 51.23.0 10%]

	--test-- "tut-13"
		--assert [255.255.0 75% 0.64.192 25%] = colorset? make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]
		--assert [255.255.0 0.64.192] = colorset?/tuples make image! [2x2 #{FFFF00 FFFF00 407090 FFFF00}]

	--test-- "tut-13a"
		--assert empty? trim #{0000}
		--assert     img-black? make image! [3x3 0.0.0]
		--assert not img-black? make image! [3x3 0.0.1]
		--assert     img-black?/tol make image! [3x3 10.0.0] 0 10
		--assert not img-black?/tol make image! [3x3 11.0.0] 0 10

	--test-- "tut-14"
		--assert [0.0 0.0 1.0 1.0] = text-bounds? draw 10x10 [pen blue box 0x0 9x9]
		--assert [0.0 0.0 1.0 1.0] = text-bounds?/lines draw 10x10 [pen blue box 0x0 9x9]
		--assert [0.1 0.1 0.9 0.9] = text-bounds? draw 10x10
				[scale 0.5 0.5 pen blue line 3x3 9x5 line 3x9 17x11 line 3x15 17x17]
		--assert [0.1 0.1 0.5 0.3  0.1 0.4 0.9 0.6  0.1 0.7 0.9 0.9] =
				text-bounds?/lines draw 10x10
				[scale 0.5 0.5 pen blue line 3x3 9x5 line 3x9 17x11 line 3x15 17x17]

	--test-- "tut-15"
		bst-im: make image! 10x10  bst-im/(2x2): blue
		--assert [0.15 0.15] = text-center? bst-im
		--assert [0.1 0.1] = text-center? draw 10x10 [pen blue box 0x0 1x1]
		--assert [0.5 0.5] = text-center? draw 10x10 [pen blue box 0x0 9x9]


	--test-- "tut-16"
		--assert 'nw = text-anchor? draw 10x10 [pen blue box 0x0 2x2]
		--assert 'ne = text-anchor? draw 10x10 [pen blue box 7x0 9x2]
		--assert 'sw = text-anchor? draw 10x10 [pen blue box 0x7 2x9]
		--assert 'se = text-anchor? draw 10x10 [pen blue box 7x7 9x9]
		--assert 'n  = text-anchor? draw 10x10 [pen blue box 0x0 9x4]
		--assert 's  = text-anchor? draw 10x10 [pen blue box 0x4 9x9]
		--assert 'w  = text-anchor? draw 10x10 [pen blue box 0x0 4x9]
		--assert 'e  = text-anchor? draw 10x10 [pen blue box 4x0 9x9]
		--assert 'c  = text-anchor? draw 10x10 [pen blue box 0x0 9x9]

	--test-- "tut-17"
		--assert     text-aligned? left  draw 10x10 [pen blue box 1x0 2x5]
		--assert not text-aligned? right draw 10x10 [pen blue box 1x0 2x5]
		--assert     text-aligned? right draw 10x10 [pen blue box 7x0 8x5]
		--assert not text-aligned? left  draw 10x10 [pen blue box 7x0 8x5]
		--assert not text-aligned? left  draw 10x10 [pen blue box 4x4 6x6]
		--assert not text-aligned? right draw 10x10 [pen blue box 4x4 6x6]
		--assert text-aligned?/not left  draw 10x10 [pen blue box 7x0 8x5]
		--assert text-aligned?/not left  draw 10x10 [pen blue box 4x4 6x6]
		--assert text-aligned?/not right draw 10x10 [pen blue box 4x4 6x6]

	--test-- "tut-17a"
		--assert     text-aligned? top    draw 10x10 [pen blue box 0x1 5x2]
		--assert not text-aligned? bottom draw 10x10 [pen blue box 0x1 5x2]
		--assert     text-aligned? bottom draw 10x10 [pen blue box 0x7 5x8]
		--assert not text-aligned? top    draw 10x10 [pen blue box 0x7 5x8]
		--assert not text-aligned? top    draw 10x10 [pen blue box 4x4 6x6]
		--assert not text-aligned? bottom draw 10x10 [pen blue box 4x4 6x6]
		--assert text-aligned?/not [top left]              draw 10x10 [pen blue box 4x4 6x6]
		--assert text-aligned?/not [right bottom]          draw 10x10 [pen blue box 4x4 6x6]
		--assert text-aligned?/not [top left right bottom] draw 10x10 [pen blue box 4x4 6x6]

	--test-- "tut-18"
		--assert equally-spaced? text-bounds?/lines draw 10x10
				[scale 0.5 0.5 pen blue line 3x3 9x5 line 3x9 17x11 line 3x15 17x17]
		--assert not equally-spaced? text-bounds?/lines draw 10x10
				[scale 0.5 0.5 pen blue line 3x1 9x3 line 3x9 17x11 line 3x15 17x17]

	--test-- "tut-19"
		--assert 0 = contrast black black
		--assert 1 = contrast white black
		--assert 1 = contrast black white
		--assert 1 = contrast black blue
		--assert 1 = contrast red   blue
		--assert 10.0 / 255 = contrast 10.20.30 20.10.20

	--test-- "tut-20"
		--assert     visually-similar? draw 1x1 [] draw 1x1 []
		--assert not visually-similar? draw 1x1 [] make image! [1x1 #{000000}]

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

	--test-- "tic-4 overlapping bases"
		bst-sz: 100x100 * system/view/metrics/dpi / 96.0
		bst-im: shoot [
			at 0x0 base 100x100 white
			at 10x10 base 80x80 255.0.0.128
		]
		bst-cs: count-colors bst-im
		--assert test-size-match? bst-im bst-sz
		--assert test-dual-chrome?/strict bst-im bst-cs
		--assert test-match? bst-im bst-cs/2 0.64
		--assert test-match? bst-im bst-cs/4 0.36
		--assert test-color-match? bst-im bst-cs/1 255.127.127
		--assert test-color-match? bst-im bst-cs/3 white

	four-ways [
	--test-- "tic-5 to-image of an image"
	 	bst-sz: 100x100 * bst-sc: system/view/metrics/dpi / 96.0
		bst-im: draw 100x100 compose [matrix [-1 0 0 1 100 0] font (copy bst-font1) text 0x0 "TEXT"]
		bst-im1: shoot [image bst-im]
		bst-im2: shoot [base 100x100 draw [image bst-im]]
		bst-im3: draw bst-sz compose [scale (bst-sc) (bst-sc) image bst-im]
		bst-im1': shoot/whole [image bst-im]
		bst-im2': shoot/whole [base' draw [image bst-im]]
		bst-im4: draw bst-sz compose/deep [matrix [-1 0 0 1 (bst-sz/x) 0] scale (bst-sc) (bst-sc) font (copy bst-font1) text 0x0 "TEXT"]
		--assert test-images-equal?/with bst-im1  bst-im2  15%
		--assert test-images-equal?/with bst-im1  bst-im3  15%
		--assert test-images-equal?/with bst-im1' bst-im2' 15%
		--assert test-images-equal?/with bst-im2  bst-im4  15%
	]

===end-group===


===start-group=== "color rendering check"

	four-ways [
	--test-- "crc-11 - base, preset colors"
		;-- checks if text is 1) indeed rendered 2) colors are as requested
		bst-cs: colorset? bst-im: shoot [base' "CAT"]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-color-match? bst-im bst-cs/1 bst-colors/bg
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 95%  0 4.5%
		--assert test-match?/tol bst-im bst-cs/4 5%   0 4.5%
	]

	--test-- "crc-12 - base, system default background"
		;-- checks if box uses the system default background color
		bst-cs: colorset? bst-im: shoot [box "CAT" font bst-font1]
		--assert test-dual-chrome? bst-im bst-cs
		try [	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/panel
		]
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 95%  0 4.5%
		--assert test-match?/tol bst-im bst-cs/4 5%   0 4.5%

	--test-- "crc-13 - base, system default bg+text"
		;-- checks if unspecified font color defaults to the system default text color
		bst-cs: colorset? bst-im: shoot [box "CAT" font-size 16]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-contrast? bst-im bst-cs/1 bst-cs/3
		try [ 	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/panel
		]
		try [ 	;-- colors/text might be undefined
			--assert test-color-match? bst-im bst-cs/3 system/view/metrics/colors/text
		]
		--assert test-match?/tol bst-im bst-cs/2 95%  0 4.5%
		--assert test-match?/tol bst-im bst-cs/4 5%   0 4.5%

	four-ways [
	--test-- "crc-21 - text, preset colors"
		;-- checks if text is 1) indeed rendered 2) colors are as requested
		bst-cs: colorset? bst-im: shoot [text' "CAT"]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-color-match? bst-im bst-cs/1 bst-colors/bg
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 90%  0 9.0%
		--assert test-match?/tol bst-im bst-cs/4 9.5% 0 9.0%
	]

	--test-- "crc-22 - text, system default background"
		;-- checks if box uses the system default background color
		bst-cs: colorset? bst-im: shoot [text 100 "CAT" font bst-font1]
		--assert test-dual-chrome? bst-im bst-cs
		try [	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/panel
		]
		--assert test-color-match? bst-im bst-cs/3 bst-colors/fg
		--assert test-match?/tol bst-im bst-cs/2 90%  0 9.0%
		--assert test-match?/tol bst-im bst-cs/4 9.5% 0 9.0%

	--test-- "crc-23 - text, system default bg+text"
		;-- checks if unspecified font color defaults to the system default text color
		bst-cs: colorset? bst-im: shoot [text bold 100 "CAT" font-size 16]
		--assert test-dual-chrome? bst-im bst-cs
		--assert test-contrast? bst-im bst-cs/1 bst-cs/3
		try [ 	;-- colors/window might be undefined
			--assert test-color-match? bst-im bst-cs/1 system/view/metrics/colors/panel
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
		--assert test-text-anchor? w w: shoot [base+ "C^/A^/T" left]
		--assert test-text-anchor? e e: shoot [base+ "C^/A^/T" right]
		--assert test-text-anchor? n n: shoot [base+ "C^/A^/T" top]
		--assert test-text-anchor? s s: shoot [base+ "C^/A^/T" bottom]

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

	--test-- "#3225"                           ;-- font (..) applies to `draw` as it may not inherit one from the face
		;@@ TODO: test if draw inherits the font?
		bst-im-lt: shoot compose/deep [base' draw [font (copy bst-font1) text 0x0 "CAT"]]
		bst-im-rt: shoot compose/deep [base' draw [font (copy bst-font1) matrix [-1 0 0 1 100 0] text 0x0 "CAT"]]
		bst-im-lb: shoot compose/deep [base' draw [font (copy bst-font1) matrix [1 0 0 -1 0 100] text 0x0 "CAT"]]
		bst-im-rb: shoot compose/deep [base' draw [font (copy bst-font1) matrix [-1 0 0 -1 100 100] text 0x0 "CAT"]]
		bst-im-tr: shoot compose/deep [base' draw [font (copy bst-font1) translate 20x30 text 0x0 "CAT"]]
		bst-im-tx: shoot compose/deep [base' draw [font (copy bst-font1) text 20x30 "CAT"]]
		--assert test-text-aligned? [left  top   ] bst-im-lt
		--assert test-text-aligned? [right top   ] bst-im-rt
		--assert test-text-aligned? [left  bottom] bst-im-lb
		--assert test-text-aligned? [right bottom] bst-im-rb
		--assert test-text-NOT-aligned? [left top right bottom] bst-im-tr
		--assert test-same-text-size? bst-im-lt bst-im-rt
		--assert test-same-text-size? bst-im-lt bst-im-lb
		--assert test-same-text-size? bst-im-lt bst-im-rb
		--assert test-same-text-size? bst-im-lt bst-im-tr
		--assert test-images-equal?/with bst-im-tr bst-im-tx 0%

	--test-- "#4116"
		;-- shoot 2 images with different fonts: the images should be different!
		bst-im1: shoot compose/deep [base' draw [font (make bst-font1 [size: 20]) text 0x0 "CAT"]]
		bst-im2: shoot compose/deep [base' draw [font (make bst-font1 [size: 30]) text 0x0 "CAT"]]
		--assert test-images-NOT-equal? bst-im1 bst-im2

	]	;-- shoot-parallel
	]	;-- four-ways

	;-- not 4-way-scalable this one
	--test-- "#3725 part 1"		;-- parts 2 and 3 were dismissed
		bst-im1: shoot compose/deep [base' "ABC" left top]
		bst-im2: shoot compose/deep [base'       left top draw [font (copy bst-font1) text 0x0 "ABC"]]
		bst-im3: shoot compose/deep [base'*      left top draw [font (copy bst-font1) text 0x0 "ABC"]]	;-- with transparency
		--assert test-same-text-origin-and-size? bst-im1 bst-im2		;-- both draw and base strings do align?
		--assert test-same-text-origin-and-size? bst-im1 bst-im3		;-- no double scaling?

===end-group===



bst-cleanup

]]  ; do [if all [object? :system/view  system/platform = 'Windows] [

~~~end-file~~~



