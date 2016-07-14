Red/System [
	Title:   "Red/System lib win32 test script"
	Author:  "Peter W A Wood"
	File: 	 %lib-win32-test-.reds
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

lib-win-int-ptr!: alias struct! [
	int      [integer!]
]

;; library declarations

#import [
	"Kernel32.dll" stdcall [
		get-computer-name: "GetComputerNameA" [
			name        [c-string!]
			len         [lib-win-int-ptr!]
			return:     [logic!]
		]
	]
]

===start-group=== "Win32"

	--test-- "libWin32-1"
		lw1-name: "****************"
		lw1-len: declare lib-win-int-ptr!
		lw1-len/int: 15
		--assert get-computer-name lw1-name lw1-len
		--assert lw1-name/1 <> #"*"
  
===end-group===
