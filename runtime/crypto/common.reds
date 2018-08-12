Red/System [
	Title:   "common file for crypto"
	Author:  "bitbegin"
	File: 	 %common.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;-- common functions
#define ROTL32(dword n) [(dword) << (n) xor ((dword) >>> (32 - (n)))]
#define ROTR32(dword n) ((dword) >>> (n) xor ((dword) << (32 - (n))))
; Red/System not support integer64 yet
;#define ROTL64(qword n) ((qword) << (n) xor ((qword) >>> (64 - (n))))
;#define ROTR64(qword n) ((qword) >>> (n) xor ((qword) << (64 - (n))))

get-byte-at: func [arr [byte-ptr!] i [integer!] return: [byte!]
	/local temp [byte-ptr!]
][
	temp: arr + i
	temp/value
]

get-int-at: func [arr [byte-ptr!] i [integer!] return: [integer!]
	/local temp [byte-ptr!] ret [integer!]
][
	temp: arr + (i * 4)
	ret: as-integer temp/value
	temp: temp + 1
	ret: ret + ((as-integer temp/value) << 8)
	temp: temp + 1
	ret: ret + ((as-integer temp/value) << 16)
	temp: temp + 1
	ret: ret + ((as-integer temp/value) << 24)
	ret
]

put-int-at: func [arr [byte-ptr!] i [integer!] value [integer!]
	/local temp [byte-ptr!] b [byte!]
][
	temp: arr + (i * 4)
	temp/value: as byte! value
	temp: temp + 1
	temp/value: as byte! (value >>> 8)
	temp: temp + 1
	temp/value: as byte! (value >>> 16)
	temp: temp + 1
	temp/value: as byte! (value >>> 24)
]
