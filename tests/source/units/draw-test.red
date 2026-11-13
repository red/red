Red [
	Title:   "Red draw commands test script"
	Author:  "hiiamboris"
	File: 	 %draw-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "draw"

; relies upon the View subsystem (not yet available on some platforms)
; and the image! datatype currently provided by the View
; FIXME: linux compiler can't swallow this, using `do`
do [if all [system/view value? 'image! datatype? get 'image!] [

===start-group=== "draw image (#3607)"

	i: make image! [4x4 #{
		FF0000 FF0000 FF0000 0000FF
		FF0000 FFFFFF FFFFFF 0000FF
		FF0000 FFFFFF FFFFFF 0000FF
		FF0000 FF0000 FF0000 0000FF
	}]
	i': make image! [4x4 #{
		FF0000 FF0000 FF0000 FF0000
		FF0000 FFFFFF FFFFFF FF0000
		FF0000 FFFFFF FFFFFF FF0000
		0000FF 0000FF 0000FF 0000FF
	}]
	i'': make image! [4x4 #{
		FFFFFF FFFFFF FFFFFF FFFFFF
		FFFFFF FFFFFF FFFFFF FF0000
		FFFFFF FFFFFF FFFFFF FF0000
		FFFFFF 0000FF 0000FF 0000FF
	}]

	--test-- "dwim1" --assert i = draw i/size [image i]
	--test-- "dwim2" --assert i = draw i/size [matrix [1 0 0 1 0 0] image i]
	
	if  system/platform <> 'macOS [
		--test-- "dwim3" --assert i' = draw i/size [matrix [0 1 -1 0 4 0] image i]	; clockwise rot 90
		--test-- "dwim5" --assert i' = draw i/size [reset-matrix matrix [0 1 -1 0 4 0] image i]
	]
	--test-- "dwim4" --assert i = draw i/size [matrix [0 -1 1 0 0 4] image i']	; counter-clockwise

	--test-- "dwim6" --assert i = draw i/size [reset-matrix matrix [0 -1 1 0 0 4] image i']
	
	--test-- "dwim7" --assert i'' = draw i/size [clip 1x1 4x4 image i']
	--test-- "dwim8" --assert i'' = draw i/size [clip 1x1 4x4 matrix [0 1 -1 0 4 0] image i]
	--test-- "dwim9" --assert i'' = draw i/size [matrix [0 1 -1 0 4 0] clip 1x0 4x3 image i]

===end-group===

===start-group=== "draw text decorations"
	td-plain:  make font! [name: "Arial" size: 20]
	td-under:  make td-plain [style: 'underline]
	td-strike: make td-plain [style: [strike]]
	td-both:   make td-plain [style: [underline strike]]

	td-scan: function [								;-- rows of img holding a dark run of 30+ pixels
		img [image!]
	][
		rows: make block! 4
		repeat y img/size/y [
			run: 0
			repeat x img/size/x [
				p: img/(as-pair x y)
				run: either 510 > (p/1 + p/2 + p/3) [run + 1][0]
				if run = 30 [append rows y]
			]
		]
		rows
	]
	td-rows: func [cmds [block!]][					;-- td-scan of a text drawn after cmds
		td-scan draw 160x60 compose [pen black (cmds) text 10x5 "llllllllllll"]
	]
	td-rt: rtd-layout ["llllllllllll"]
	td-rt/color: none
	td-rt-rows: func [font [object!]][				;-- td-scan of the td-rt rich-text drawn with font
		td-rt/font: font
		td-scan draw 160x60 compose [pen black text 10x5 (td-rt)]
	]
	td-under-rows:  td-rows [font td-under]
	td-strike-rows: td-rows [font td-strike]

	--test-- "text-deco-1" --assert empty? td-rows [font td-plain]
	--test-- "text-deco-2" --assert not empty? td-under-rows
	--test-- "text-deco-3" --assert not empty? td-strike-rows
	--test-- "text-deco-4"
		--assert to logic! all [					;-- the underline is below the strike line
			not empty? td-under-rows
			not empty? td-strike-rows
			td-under-rows/1 > last td-strike-rows
		]
	--test-- "text-deco-5" --assert equal? td-rows [font td-both] sort union td-under-rows td-strike-rows
	--test-- "text-deco-6" --assert empty? td-rows [font td-under font td-plain]
	--test-- "text-deco-7" --assert empty? td-rows [push [font td-under]]
	if image? try [draw 1x1 compose [text 0x0 (td-rt)]][	;-- GDI+ draws no rich-text on images
		--test-- "text-deco-8" --assert empty? td-rt-rows td-plain
		--test-- "text-deco-9"
			td-rt-under:  td-rt-rows td-under
			td-rt-strike: td-rt-rows td-strike
			--assert to logic! all [				;-- a rich-text face's own font
				not empty? td-rt-under
				not empty? td-rt-strike
				td-rt-under/1 > last td-rt-strike
			]
	]
===end-group===

===start-group=== "draw empty images"
	e: make image! 0x0
	--test-- "empty4" --assert image? draw copy i [fill-pen bitmap e box 0x0 2x2]
	--test-- "empty5" --assert image? draw copy i [pen bitmap e box 0x0 2x2]
===end-group===

===start-group=== "draw errors"
	--test-- "pattern-error1" --assert error? try [draw copy i [fill-pen pattern 2x2 [box 0x0] box 0x0 2x2]]
===end-group===

;-- TODO: test more commands once the coordinate system mess is dealt with

]]

~~~end-file~~~
