Red/System [
	Title:   "Red/System heap memory utilities"
	Author:  "Nenad Rakocevic"
	File: 	 %heap.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- Basically, a thin wrapping layer on top of libC's malloc/free for tracking those buffers.
;-- A custom header (heap-frame!) is inserted in all malloc-ed buffers, forming a double-chained
;-- linked-list. `heap-stats` allows to print them out in the standard output for debugging purposes.
;-- Access to that list is done using `system/heap/head` and `system/heap/tail` pointers.

allocate: func [
	size	[integer!]
	return:	[byte-ptr!]
	/local
		p old [heap-frame!]
][
	size: size + size? heap-frame!
	p: as heap-frame! libC.malloc size
	p/prev: null
	p/next: null
	p/size: size
	either null? system/heap/head [			;-- first allocated frame case
		system/heap/head: p
		system/heap/tail: p
	][
		old: system/heap/tail				;-- appending at list's tail case
		old/next: p							;-- previous tail now points to new frame
		system/heap/tail: p					;-- new tail frame
		p/prev: old							;-- link back new frame to previous tail one
	]
	as byte-ptr! p + 1						;-- return the buffer pointer, skipping the header
]

free: func [p [byte-ptr!] /local frm next [heap-frame!]][
	p: p - size? heap-frame!				;-- point back to frame's header
	frm: system/heap/head
	assert frm <> null
	until [
		next: frm/next
		if (as byte-ptr! frm) = p [			;-- search the linked-list for the right frame
			either null? frm/prev [			;-- frame at head case
				system/heap/head: next		;-- new head is the next frame
				if next <> null [next/prev: null] ;-- if the list was not a singleton, reset head's /prev link
			][
				frm/prev/next: next			;-- link previous frame to next frame, bypassing the removed frame
			]
			either null? next [				;-- frame at tail case
				system/heap/tail: frm/prev  ;-- new tail the the previous frame
				if frm/prev <> null [frm/prev/next: null] ;-- if the list was not a singleton, reset tail's /next link
			][
				next/prev: frm/prev			;-- link back next frame to previous frame, bypassing the removed frame
			]
			libC.free p
			exit
		]
		frm: next
		frm = null
	]
]

realloc: func [
	p		[byte-ptr!]
	size	[integer!]
	return:	[byte-ptr!]
	/local
		old new prev next [heap-frame!]
][
	if null? p    [return allocate size]	;-- implementing the exact behavior of realloc() from libC
	if zero? size [free p return null]		;-- implementing the exact behavior of realloc() from libC
	
	old: (as heap-frame! p) - 1
	prev: old/prev
	next: old/next
	size: size + size? heap-frame!
	new: as heap-frame! libC.realloc as byte-ptr! old size
	new/size: size
	;-- restore only incoming pointers, as only the relocated frame's address changed
	either null? next [system/heap/tail: new][if next <> null [next/prev: new]]
	either null? prev [system/heap/head: new][if prev <> null [prev/next: new]]
	as byte-ptr! new + 1					;-- return the buffer pointer, skipping the header	
]

zero-alloc: func [size [integer!] return: [byte-ptr!]][
	set-memory allocate size null-byte size
]

heap-free-all: func [/local	frame next [heap-frame!]][
	frame: system/heap/head
	while [frame <> null][
		next: frame/next
		libC.free as byte-ptr! frame
		frame: next
	]
]

heap-stats: func [
	/local
		frame [heap-frame!]
		total [integer!]
][
	total: 0
	frame: system/heap/head
	while [frame <> null][
		print-line ["Heap-allocated: " frame/size]
		total: total + frame/size
		frame: frame/next
	]
	print-line ["Total: " total]
	print-line "---"
]