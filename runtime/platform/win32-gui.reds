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

;-------------------------------------------
;-- Red/System Unicode replacement printing functions
;-------------------------------------------

sprintf-buf: as byte-ptr! "0000000000000000000000000000000"			;-- 32 bytes wide, big enough.

prin*: func [s [c-string!] return: [c-string!]][
	dyn-print/rs-print as byte-ptr! s -1 Latin1 no
	s
]

prin-int*: func [i [integer!] return: [integer!]][
	sprintf [sprintf-buf "%i" i]
	dyn-print/rs-print sprintf-buf -1 Latin1 no
	i
]

prin-2hex*: func [i [integer!] return: [integer!]][
	sprintf [sprintf-buf "%02X" i]
	dyn-print/rs-print sprintf-buf -1 Latin1 no
	i
]

prin-hex*: func [i [integer!] return: [integer!]][
	sprintf [sprintf-buf "%08X" i]
	dyn-print/rs-print sprintf-buf -1 Latin1 no
	i
]

prin-float*: func [f [float!] return: [float!]][
	sprintf [sprintf-buf "%.16g" f]
	dyn-print/rs-print sprintf-buf -1 Latin1 no
	f
]

prin-float32*: func [f [float32!] return: [float32!]][
	sprintf [sprintf-buf "%.7g" as-float f]
	dyn-print/rs-print sprintf-buf -1 Latin1 no
	f
]