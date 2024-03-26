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
;-- In debug mode, guard zones are appended to each allocated buffer to detect overflows on freeing.

#define RED_WRITE_GUARD_ZONE [
	g: as alloc-guard! ((as byte-ptr! p) + len - size? alloc-guard!)
	g/guard0: BAD1BAD2h
	g/guard1: BAD3BAD4h
	g/guard2: BAD5BAD6h
	g/guard3: BAD7BAD8h
]

alloc-guard!: alias struct! [				;-- 128-bit guarding barrier
	guard0 [integer!]
	guard1 [integer!]
	guard2 [integer!]
	guard3 [integer!]
]

allocate: func [
	size	[integer!]
	return:	[byte-ptr!]
	/local
		p old [heap-frame!]
		g	  [alloc-guard!]
		len	  [integer!]
][
	len: size + size? heap-frame!
	#if debug? = yes [len: len + size? alloc-guard!] ;-- account for guard tail
	p: as heap-frame! libC.malloc len
	
	p/prev: null
	p/next: null
	p/size: size
	#if debug? = yes [RED_WRITE_GUARD_ZONE]
	
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

free: func [
	p [byte-ptr!]
	/local
		frm next [heap-frame!]
		g [alloc-guard!]
][
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
			#if debug? = yes [
				g: as alloc-guard! p + frm/size + size? heap-frame!
				if any [
					g/guard0 <> BAD1BAD2h
					g/guard1 <> BAD3BAD4h
					g/guard2 <> BAD5BAD6h
					g/guard3 <> BAD7BAD8h
				][
					probe [
						"^/*** Buffer overflow detected at: " frm
						"^/*** Buffer size: " frm/size
					]
					assert false			;-- make it crash!
				]
			
			]
			libC.free p
			exit
		]
		frm: next
		frm = null
	]
]

realloc: func [
	buf		[byte-ptr!]
	size	[integer!]
	return:	[byte-ptr!]
	/local
		p prev next [heap-frame!]
		g	[alloc-guard!]
		len	[integer!]
][
	if null? buf  [return allocate size]	;-- implementing the exact behavior of realloc() from libC
	if zero? size [free buf return null]	;-- implementing the exact behavior of realloc() from libC
	
	p: (as heap-frame! buf) - 1
	prev: p/prev
	next: p/next
	len: size + size? heap-frame!
	#if debug? = yes [len: len + size? alloc-guard!] ;-- account for guard tail
	
	p: as heap-frame! libC.realloc as byte-ptr! p len
	p/size: size
	#if debug? = yes [RED_WRITE_GUARD_ZONE]
	
	;-- restore only inward pointers, as only the relocated frame's address changed
	either null? next [system/heap/tail: p][if next <> null [next/prev: p]]
	either null? prev [system/heap/head: p][if prev <> null [prev/next: p]]
	as byte-ptr! p + 1						;-- return the buffer pointer, skipping the header
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
	system/heap/head: null
	system/heap/tail: null
]

heap-stats: func [
	/local
		frame [heap-frame!]
		total len [integer!]
][
	total: 0
	frame: system/heap/head
	
	print-line "-- Heap-allocations --"
	print-line ["Asked   Real"]
	
	while [frame <> null][
		len: frame/size + size? heap-frame!
		#if debug? = yes [len: len + size? alloc-guard!]
		print-line [frame/size tab len]
		total: total + len
		frame: frame/next
	]
	print-line ["-- Sum: " total " --"]
]