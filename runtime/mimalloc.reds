Red/System [
	Title:   "Red fixed memory allocator"
	Author:  "Xie Qingtian"
	File: 	 %mimalloc.reds
	Tabs:	 4
	Notes:   {
		A mimalloc implementation in R/S
		https://www.microsoft.com/en-us/research/uploads/prod/2019/06/mimalloc-tr-v1.pdf
	}
	Rights:  "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define MI_PTR_SHIFT	2										;-- 32 bits system
#define MI_PTR_SIZE		[(1 << MI_PTR_SHIFT)]

;-- Tuning parameters for page sizes and segment size
;-- sizes for 32-bit, multiply by two for 64-bit
#define MI_SMALL_PAGE_SHIFT		[(13 + MI_PTR_SHIFT)]			;-- 32kb
#define MI_MEDIUM_PAGE_SHIFT	[(3 + MI_SMALL_PAGE_SHIFT)]		;-- 256kb
#define MI_LARGE_PAGE_SHIFT		[(3 + MI_MEDIUM_PAGE_SHIFT)]	;-- 2MB
#define MI_SEGMENT_SHIFT		MI_LARGE_PAGE_SHIFT				;-- 2MB

;-- Derived constants
#define MI_SEGMENT_SIZE			[(1 << MI_SEGMENT_SHIFT)]
#define MI_SEGMENT_MASK			[(MI_SEGMENT_SIZE - 1)]

#define MI_SMALL_PAGE_SIZE		[(1 << MI_SMALL_PAGE_SHIFT)]
#define MI_MEDIUM_PAGE_SIZE		[(1 << MI_MEDIUM_PAGE_SHIFT)]
#define MI_LARGE_PAGE_SIZE		[(1 << MI_LARGE_PAGE_SHIFT)]

#define MI_SMALL_OBJ_SIZE_MAX	[(MI_SMALL_PAGE_SIZE / 4)]	;-- 4kb on 32-bit

#define MI_MEDIUM_OBJ_SIZE_MAX	[(MI_MEDIUM_PAGE_SIZE / 4)]	;-- 64kb on 32-bit
#define MI_MEDIUM_OBJ_WSIZE_MAX	[(MI_MEDIUM_OBJ_SIZE_MAX / MI_PTR_SIZE)]  ;-- 32kb on 32-bit

#define MI_LARGE_OBJ_SIZE_MAX	[(MI_SEGMENT_SIZE / 4)]
#define MI_LARGE_OBJ_WSIZE_MAX	[(MI_LARGE_OBJ_SIZE_MAX / MI_PTR_SIZE)]

#define MI_MAX_ALIGN_SIZE  16
#define MI_MAX_PAGE_OFFSET		[((MI_MEDIUM_PAGE_SIZE / MI_SMALL_PAGE_SIZE) - 1)]

#define MI_PAGE_FLAG_FULL		1
#define MI_PAGE_FLAG_ALIGNED	2

mimalloc: context [

	#enum delayed-free! [
		NO_DELAYED_FREE
		USE_DELAYED_FREE
		DELAYED_FREEING
		NEVER_DELAYED_FREE
	]

	#enum page-kind! [
		MI_PAGE_SMALL	;-- small blocks go into 32kb pages inside a segment
		MI_PAGE_MEDIUM	;-- medium blocks go into 256kb pages inside a segment
		MI_PAGE_LARGE	;-- larger blocks go into a page of just one block
	]

	block!: alias struct! [		;-- free lists contains blocks
		next [block!]
	]

	page!: alias struct! [
		idx				[integer!]
		flags			[integer!]
		capacity		[integer!]
		reserved		[integer!]
		free-blocks		[block!]
		used			[integer!]
		local-free		[block!]
		;thread-freed	[integer!]
		;thread-free	[block!]
		block-size		[integer!]
		heap			[heap!]
		next			[page!]
		prev			[page!]
	]

	segment!: alias struct! [
		id				[integer!]
		next			[segment!]
		abandoned_next	[segment!]
		abandoned		[integer!]
		used			[integer!]
		capacity		[integer!]
		info-size		[integer!]
		page-shift		[integer!]
		thread-id		[int-ptr!]
		page-kind		[integer!]
		pages			[page!]
	]

	page-queue!: alias struct! [
		first			[page!]
		last			[page!]
		block-size		[integer!]
	]

	pages-direct!: alias struct! [
		p1   [page!] p2   [page!] p3   [page!] p4   [page!] p5   [page!] p6   [page!] p7   [page!] p8   [page!]
		p9   [page!] p10  [page!] p11  [page!] p12  [page!] p13  [page!] p14  [page!] p15  [page!] p16  [page!]
		p17  [page!] p18  [page!] p19  [page!] p20  [page!] p21  [page!] p22  [page!] p23  [page!] p24  [page!]
		p25  [page!] p26  [page!] p27  [page!] p28  [page!] p29  [page!] p30  [page!] p31  [page!] p32  [page!]
		p33  [page!] p34  [page!] p35  [page!] p36  [page!] p37  [page!] p38  [page!] p39  [page!] p40  [page!]
		p41  [page!] p42  [page!] p43  [page!] p44  [page!] p45  [page!] p46  [page!] p47  [page!] p48  [page!]
		p49  [page!] p50  [page!] p51  [page!] p52  [page!] p53  [page!] p54  [page!] p55  [page!] p56  [page!]
		p57  [page!] p58  [page!] p59  [page!] p60  [page!] p61  [page!] p62  [page!] p63  [page!] p64  [page!]
		p65  [page!] p66  [page!] p67  [page!] p68  [page!] p69  [page!] p70  [page!] p71  [page!] p72  [page!]
		p73  [page!] p74  [page!] p75  [page!] p76  [page!] p77  [page!] p78  [page!] p79  [page!] p80  [page!]
		p81  [page!] p82  [page!] p83  [page!] p84  [page!] p85  [page!] p86  [page!] p87  [page!] p88  [page!]
		p89  [page!] p90  [page!] p91  [page!] p92  [page!] p93  [page!] p94  [page!] p95  [page!] p96  [page!]
		p97  [page!] p98  [page!] p99  [page!] p100 [page!] p101 [page!] p102 [page!] p103 [page!] p104 [page!]
		p105 [page!] p106 [page!] p107 [page!] p108 [page!] p109 [page!] p110 [page!] p111 [page!] p112 [page!]
		p113 [page!] p114 [page!] p115 [page!] p116 [page!] p117 [page!] p118 [page!] p119 [page!] p120 [page!]
		p121 [page!] p122 [page!] p123 [page!] p124 [page!] p125 [page!] p126 [page!] p127 [page!] p128 [page!]
		p129 [page!] p130 [page!]
	]

	pages-array!: alias struct! [
		p1   [page-queue! value] p2   [page-queue! value] p3   [page-queue! value] p4   [page-queue! value] p5   [page-queue! value] p6   [page-queue! value] p7   [page-queue! value] p8   [page-queue! value]
		p9   [page-queue! value] p10  [page-queue! value] p11  [page-queue! value] p12  [page-queue! value] p13  [page-queue! value] p14  [page-queue! value] p15  [page-queue! value] p16  [page-queue! value]
		p17  [page-queue! value] p18  [page-queue! value] p19  [page-queue! value] p20  [page-queue! value] p21  [page-queue! value] p22  [page-queue! value] p23  [page-queue! value] p24  [page-queue! value]
		p25  [page-queue! value] p26  [page-queue! value] p27  [page-queue! value] p28  [page-queue! value] p29  [page-queue! value] p30  [page-queue! value] p31  [page-queue! value] p32  [page-queue! value]
		p33  [page-queue! value] p34  [page-queue! value] p35  [page-queue! value] p36  [page-queue! value] p37  [page-queue! value] p38  [page-queue! value] p39  [page-queue! value] p40  [page-queue! value]
		p41  [page-queue! value] p42  [page-queue! value] p43  [page-queue! value] p44  [page-queue! value] p45  [page-queue! value] p46  [page-queue! value] p47  [page-queue! value] p48  [page-queue! value]
		p49  [page-queue! value] p50  [page-queue! value] p51  [page-queue! value] p52  [page-queue! value] p53  [page-queue! value] p54  [page-queue! value] p55  [page-queue! value] p56  [page-queue! value]
		p57  [page-queue! value] p58  [page-queue! value] p59  [page-queue! value] p60  [page-queue! value] p61  [page-queue! value] p62  [page-queue! value] p63  [page-queue! value] p64  [page-queue! value]
		p65  [page-queue! value] p66  [page-queue! value] p67  [page-queue! value] p68  [page-queue! value] p69  [page-queue! value] p70  [page-queue! value] p71  [page-queue! value] p72  [page-queue! value]
		p73  [page-queue! value] p74  [page-queue! value]
	]

	segment-queue!: alias struct! [
		first		[segment!]
		last		[segment!]
	]

	stat-info!: alias struct! [
		allocated	[integer!]
		freed		[integer!]
		peak		[integer!]
		current		[integer!]
	]

	stats!: alias struct! [
		segments	[stat-info! value]
		pages		[stat-info! value]
	]

	segments-tld!: alias struct! [
		small-free	[segment-queue!]
		medium-free	[segment-queue!]
		count		[integer!]
		peak-count	[integer!]
		current-size [integer!]
		peak-size	[integer!]
		cache-count [integer!]
		cache-size	[integer!]
		cache		[segment!]
		stats		[stats!]
	]

	tld!: alias struct! [	;-- Thread local data
		heap-backing	[heap!]
		segments		[segments-tld! value]
		idx				[integer!]
		stats			[stats! value]
	]

	heap!: alias struct! [
		tld				[tld!]
		pages-direct	[pages-direct! value]
		pages			[pages-array! value]
		delayed-free	[block!]
		thread-id		[int-ptr!]
		page-count		[integer!]
		reclaim?		[logic!]
	]

	thread-data!: alias struct! [
		heap			[heap! value]
		tld				[tld! value]
	]

	tagSYSTEM_INFO: alias struct! [
		wProcessorArchitecture		[integer!]
		dwPageSize					[integer!]
		lpMinimumApplicationAddress	[int-ptr!]
		lpMaximumApplicationAddress	[int-ptr!]
		dwActiveProcessorMask		[int-ptr!]
		dwNumberOfProcessors		[integer!]
		dwProcessorType				[integer!]
		dwAllocationGranularity		[integer!]
		wProcessor					[integer!]
			;wProcessorLevel		[uint16!]
			;wProcessorRevision		[uint16!]
	]

	thread-callback!: alias function! [lpData [int-ptr!]]

	#import [
		"kernel32.dll" stdcall [
			FlsAlloc: "FlsAlloc" [
				lpCallback	[int-ptr!]
				return:		[integer!]
			]
			FlsSetValue: "FlsSetValue" [
				dwFlsIndex	[integer!]
				lpFlsData	[int-ptr!]
				return:		[logic!]
			]
			GetSystemInfo: "GetSystemInfo" [
				si			[tagSYSTEM_INFO]
			]
			VirtualAlloc: "VirtualAlloc" [
				address		[byte-ptr!]
				size		[integer!]
				type		[integer!]
				protection	[integer!]
				return:		[int-ptr!]
			]
			VirtualFree: "VirtualFree" [
				address 	[int-ptr!]
				size		[integer!]
				type		[integer!]
				return:		[integer!]
			]
		]
	]

	#define WORD_SIZE?(size) [(size - 1 + size? int-ptr!) / size? int-ptr!]

	page-size: 4096
	alloc-granularity: 4096

	empty-page: declare page!
	stats-main: declare stats!
	heap-main: declare heap!
	tld-main: declare tld!
	heap-default: as heap! 0

	zero-memory: func [
		dest	[byte-ptr!]
		size	[integer!]
	][
		loop size [dest/value: #"^@" dest: dest + 1]
	]

	;== OS memory APIs

	OS-mem-alloc: func [
		size	[integer!]
		commit?	[logic!]
		stats	[stats!]
		return: [int-ptr!]
		/local
			flags [integer!]
	][
		flags: 2000h							;-- MEM_RESERVE
		if commit? [flags: 3000h]				;-- MEM_RESERVE or MEM_COMMIT
		VirtualAlloc null size flags 4			;-- PAGE_READWRITE
	]

	OS-mem-free: func [
		addr	[int-ptr!]
		size	[integer!]
		stats	[stats!]
	][
		if zero? VirtualFree addr 0 8000h [		;-- MEM_RELEASE: 0x8000
			throw 7FFFFFF6h
		]
	]

	thread-id-cnt: 0 ;func [return: [int-ptr!]][as int-ptr! heap-default]

	init-thread: func [][
		init-heap
	]

	init-process: func [
		/local
			h	[heap!]
	][
		h: heap-main
		zero-memory as byte-ptr! h size? heap!
		init-thread
	]

	init-heap: func [
		/local
			hp	[heap!]
			tld	[tld!]
			td	[thread-data!]
	][
		hp: heap-main
		either null? hp/thread-id [
			heap-default: heap-main
		][
			thread-id-cnt: thread-id-cnt + 1
			td: as thread-data! OS-mem-alloc size? thread-data! yes stats-main
			tld: td/tld
			hp: td/heap
			hp/thread-id: as int-ptr! thread-id-cnt
			hp/tld: tld
			tld/heap-backing: hp
			tld/segments/stats: tld/stats
		]
	]

	init: func [/local si [tagSYSTEM_INFO value]][
		GetSystemInfo :si
		if si/dwPageSize > 0 [page-size: si/dwPageSize]
		if si/dwAllocationGranularity > 0 [
			alloc-granularity: si/dwAllocationGranularity
		]
		init-process
	]

	create-heap: func [
		return: [heap!]
		/local
			h	[heap!]
	][
		null
	]

	segment-alloc: func [
		required	[ulong!]
		kind		[page-kind!]
		page-shift	[integer!]
		tld			[segments-tld!]
		return:		[segment!]
		/local
			page-sz		[integer!]
			capacity	[integer!]
	][
		page-sz: 1 << page-shift
		capacity: MI_SEGMENT_SIZE
	]

	segment-page-alloc: func [
		kind	[page-kind!]
		shift	[integer!]
		tld		[segments-tld!]
		/local
			qe	[segment-queue!]
			seg [segment!]
	][
		qe: either kind = MI_PAGE_SMALL [tld/small-free][tld/medium-free]
		if null? qe/first [
			seg: 
		]
	]

	queue-find-page: func [
		heap	[heap!]
		qe		[page-queue!]
		return: [page!]
	][
		;-- TBD search in page queue

		;-- get a fresh page
		
	]

	;== allocation functions

	page-alloc: func [
		heap	[heap!]
		page	[page!]
		size	[ulong!]
		return:	[byte-ptr!]
		/local
			blk	[block!]
	][
		blk: page/free-blocks
		either blk <> null [
			page/free-blocks: blk/next		;-- pop from the free list
			page/used: page/used + 1
			as byte-ptr! blk
		][
			heap-alloc-generic heap size
		]
	]

	heap-alloc: func [
		heap	[heap!]
		size	[integer!]	;-- bytes
		return: [byte-ptr!]
	][
		assert heap <> null
		either size <= (128 * size? int-ptr!) [	;-- fast path
			heap-alloc-small heap size
		][
			heap-alloc-generic heap size
		]
	]

	heap-alloc-small: func [
		heap	[heap!]
		size	[integer!]
		return: [byte-ptr!]
		/local
			idx	[integer!]
			p	[ptr-ptr!]
	][
		idx: WORD_SIZE?(size)
		p: (as ptr-ptr! :heap/pages-direct) + idx
		page-alloc heap as page! p/value size
	]

	heap-alloc-generic: func [
		heap		[heap!]
		size		[integer!]
		return:		[byte-ptr!]
		/local
			page	[page!]
			wsize	[integer!]
			idx		[integer!]
			qe		[page-queue!]
	][
		;-- try to find a free page in page queue
		wsize: WORD_SIZE?(size)
		case [
			wsize <= 1 [idx: 1]
			wsize <= 4 [idx: wsize + 1 and FFFEh]
			true [
				if wsize <= 16 [wsize: wsize + 3 and FFFCh]
				wsize: wsize - 1
				idx: log-b wsize
				idx: idx << 2 + (wsize >> (idx - 2) and 3) - 3
			]
		]
		qe: (as page-queue! :heap/pages) + idx
		page: qe/first
		if page <> null [
			;-- TBD collect page

			if null? page/free-blocks [
				page: queue-find-page qe
			]
		][
			page: queue-find-page heap qe
		]
		page-alloc heap page size		
	]

	malloc: func [
		size	[ulong!]
		return: [byte-ptr!]
	][
		heap-alloc heap-default size
	]
]