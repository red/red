Red/System [
	Title:   "Red runtime Android additional bindings"
	Author:  "Nenad Rakocevic"
	File: 	 %android.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#enum android-log-priority! [
    ANDROID_LOG_UNKNOWN
    ANDROID_LOG_DEFAULT
    ANDROID_LOG_VERBOSE
    ANDROID_LOG_DEBUG
    ANDROID_LOG_INFO
    ANDROID_LOG_WARN
    ANDROID_LOG_ERROR
    ANDROID_LOG_FATAL
    ANDROID_LOG_SILENT
]

#import [
	"libcutils.so" cdecl [
		android_log_write: "__android_log_write" [
			priority [integer!]
			tag		 [c-string!]
			text	 [c-string!]
			return:	 [integer!]
		]
		
		android_log_print: "__android_log_print" [[variadic]]
	]
	LIBC-file cdecl [
		snprintf: "snprintf" [[variadic] return: [integer!]]
	]
]

android-log-write: func [msg [c-string!]][
	android_log_write ANDROID_LOG_DEBUG "Red" msg
]

;--- Red printing backend ---

prin-unicode-msg: does [
	print-line "*** Error: logcat does not support Unicode!"
]

print-UCS4: func [str [int-ptr!] size [integer!]][						;-- UCS-4 string
	prin-unicode-msg
]

print-line-UCS4: func [str [int-ptr!] size [integer!]][					;-- UCS-4 string
	prin-unicode-msg
]

print-UCS2: func [str [byte-ptr!] size [integer!]][						;-- UCS-2 string
	prin-unicode-msg
]

print-line-UCS2: func [str [byte-ptr!] size [integer!]][				;-- UCS-2 string
	prin-unicode-msg
]

print-Latin1: func [str [c-string!] size [integer!]][					;-- Latin-1 string
	assert str <> null
	until [
		either s/1 = #"^/" [
			buffer/tail: null-byte
			android-log-write buffer
			tail: 1
		][
			buffer/tail: s/1
			tail: tail + 1
		]
		s: s + 1
		size: size - 1
		any [
			zero? size
			tail >= OUTPUT_BUF_SIZE 
		]
	]
]

print-line-Latin1: func [str [c-string!] size [integer!]][				;-- Latin-1 string
	assert str <> null
	print-Latin1 str size
	prin* "^/"
]

;--- Red/System printing API ---

#define OUTPUT_BUF_SIZE 10000

buffer:  as-c-string allocate OUTPUT_BUF_SIZE
spf-buf: as-c-string allocate 15 						;-- 14 + one for NUL
tail: 1

prin-buffered: func [s [c-string!]][
	until [
		either s/1 = #"^/" [
			buffer/tail: null-byte
			android-log-write buffer
			tail: 1
		][
			buffer/tail: s/1
			tail: tail + 1
		]
		s: s + 1
		any [
			s/1 = null-byte
			tail >= OUTPUT_BUF_SIZE 
		]
	]
]

prin*: func [s [c-string!] return: [c-string!]][
	prin-buffered s
	s
]

prin-int*: func [i [integer!] return: [integer!]][
	snprintf [spf-buf OUTPUT_BUF_SIZE - tail "%i" i]
	prin* spf-buf
	i
]

prin-hex*: func [i [integer!] return: [integer!]][
	snprintf [spf-buf OUTPUT_BUF_SIZE - tail "%08X" i]
	prin* spf-buf
	i
]

prin-float*: func [f [float!] return: [float!]][
	snprintf [spf-buf OUTPUT_BUF_SIZE - tail "%.16g" f]
	prin* spf-buf
	f
]

prin-float32*: func [f [float32!] return: [float32!]][
	snprintf [spf-buf OUTPUT_BUF_SIZE - tail "%.7g" as-float f]
	prin* spf-buf
	f
]
