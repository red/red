Red/System [
	Title:   "Red memory manager"
	Author:  "Nenad Rakocevic"
	File: 	 %allocator.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

;-- New built-in natives worth adding to Red/System??
; get-bit n value
; set-bit n value
; clear-bit n value
; bit-set? n value

;-- cell header bits layout --
;-- 31: mark					; mark as referenced for the GC (mark phase)
;-- 30: lock					; lock slot for current thread access only
;-- 29: immutable				; mark as read-only (series only)
;-- 28: new-line?				; new-line marker (before the slot)
;-- 8-28: <reserved>
;-- 0-7: datatype ID			; datatype number

#define OS-page-size	4096	;@@ target/OS dependent

int-array!: alias struct! [ptr [byte-ptr!]]

cell!: alias struct! [
	header	[integer!]
	value	[integer!]
	ptr		[integer!]
	extra	[integer!]
]

series-frame!: alias struct! [
	next	[series-frame!]
	prev	[series-frame!]
	buffer	[byte-ptr!]
]

node-frame!: alias struct! [
	next	[node-frame!]
	prev	[node-frame!]
	slots	[integer!]
	stack	[int-array!]
	nodes	[int-array!]
	top		[int-ptr!]
]

memory: declare struct! [
	series	[series-frame!]
	nodes	[node-frame!]
]

