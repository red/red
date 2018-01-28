Red/System [
	Title:   "Red runtime win32 GUI print functions"
	Author:  "Qingtian Xie"
	File: 	 %win32-gui.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

vprint!: alias function! [
	str		[byte-ptr!]
	size	[integer!]
	unit	[integer!]
	nl?		[logic!]
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-UCS4: func [
	str    [int-ptr!]								;-- UCS-4 string
	size   [integer!]
	/local
		vprint [vprint!]
][
	assert str <> null
	vprint: as vprint! gui-print
	vprint as byte-ptr! str size UCS-4 no
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-line-UCS4: func [
	str    [int-ptr!]								;-- UCS-4 string
	size   [integer!]
	/local vprint
][
	assert str <> null
	vprint: as vprint! gui-print
	vprint as byte-ptr! str size UCS-4 yes
]

;-------------------------------------------
;-- Print a UCS-2 string to console
;-------------------------------------------
print-UCS2: func [
	str 	[byte-ptr!]								;-- UCS-2 string
	size	[integer!]
	/local vprint
][
	assert str <> null
	vprint: as vprint! gui-print
	vprint str size UCS-2 no
]

;-------------------------------------------
;-- Print a UCS-2 string with newline to console
;-------------------------------------------
print-line-UCS2: func [
	str 	[byte-ptr!]								;-- UCS-2 string
	size	[integer!]
	/local vprint
][
	assert str <> null
	vprint: as vprint! gui-print
	vprint str size UCS-2 yes
]

;-------------------------------------------
;-- Print a Latin-1 string to console
;-------------------------------------------
print-Latin1: func [
	str 	[c-string!]								;-- Latin-1 string
	size	[integer!]
	/local vprint
][
	assert str <> null
	vprint: as vprint! gui-print
	vprint as byte-ptr! str size Latin1 no
]

;-------------------------------------------
;-- Print a Latin-1 string with newline to console
;-------------------------------------------
print-line-Latin1: func [
	str  [c-string!]								;-- Latin-1 string
	size [integer!]
	/local vprint
][
	assert str <> null
	vprint: as vprint! gui-print
	vprint as byte-ptr! str size Latin1 yes
]


;-------------------------------------------
;-- Red/System Unicode replacement printing functions
;-------------------------------------------

sprintf-buf: as byte-ptr! "0000000000000000000000000000000"			;-- 32 bytes wide, big enough.

prin*: func [s [c-string!] return: [c-string!] /local vprint][
	vprint: as vprint! gui-print
	vprint as byte-ptr! s -1 Latin1 no
	s
]

prin-int*: func [i [integer!] return: [integer!] /local vprint][
	sprintf [sprintf-buf "%i" i]
	vprint: as vprint! gui-print
	vprint sprintf-buf -1 Latin1 no
	i
]

prin-2hex*: func [i [integer!] return: [integer!] /local vprint][
	sprintf [sprintf-buf "%02X" i]
	vprint: as vprint! gui-print
	vprint sprintf-buf -1 Latin1 no
	i
]

prin-hex*: func [i [integer!] return: [integer!] /local vprint][
	sprintf [sprintf-buf "%08X" i]
	vprint: as vprint! gui-print
	vprint sprintf-buf -1 Latin1 no
	i
]

prin-float*: func [f [float!] return: [float!] /local vprint][
	sprintf [sprintf-buf "%.16g" f]
	vprint: as vprint! gui-print
	vprint sprintf-buf -1 Latin1 no
	f
]

prin-float32*: func [f [float32!] return: [float32!] /local vprint][
	sprintf [sprintf-buf "%.7g" as-float f]
	vprint: as vprint! gui-print
	vprint sprintf-buf -1 Latin1 no
	f
]