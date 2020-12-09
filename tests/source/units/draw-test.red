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

;-- TODO: test more commands once the coordinate system mess is dealt with

]]

~~~end-file~~~
