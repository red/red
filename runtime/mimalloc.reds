Red/System [
	Title:   "mimalloc memory allocator"
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

#include %tools.reds

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

#define MI_SMALL_OBJ_SIZE_MAX	[(MI_SMALL_PAGE_SIZE / 4)]	;-- 8kb on 32-bit
#define MI_MEDIUM_OBJ_SIZE_MAX	[(MI_MEDIUM_PAGE_SIZE / 4)]	;-- 64kb on 32-bit
#define MI_LARGE_OBJ_SIZE_MAX	[(MI_LARGE_PAGE_SIZE / 2)]	;-- 1mb on 32-bit

#define MI_MEDIUM_OBJ_WSIZE_MAX	[(MI_MEDIUM_OBJ_SIZE_MAX / MI_PTR_SIZE)]  ;-- 16kb on 32-bit
#define MI_LARGE_OBJ_WSIZE_MAX	[(MI_LARGE_OBJ_SIZE_MAX / MI_PTR_SIZE)]

#define MI_MAX_ALIGN_SIZE		16
#define MI_PAGE_HUGE_ALIGN		262144		;-- 256KB

#define MI_MAX_PAGE_OFFSET		[((MI_MEDIUM_PAGE_SIZE / MI_SMALL_PAGE_SIZE) - 1)]

#define MI_BIN_HUGE		70
#define MI_BIN_FULL		71
#define MI_HUGE_SIZE	1835008
#define MI_FULL_SIZE	2097152

#define MI_SMALL_SIZE_MAX		[(128 * size? int-ptr!)]

#define MI_WORD_SIZE?(size) [(size - 1 + size? int-ptr!) / size? int-ptr!]
#define PTR_TO_SEGMENT(p)		[as segment! (as-integer p) and (not MI_SEGMENT_MASK)]
#define GET_SEGMENT_QUEUE(kind tld) [
	switch kind [
		MI_PAGE_SMALL [tld/small-free]
		MI_PAGE_MEDIUM [tld/medium-free]
		default [null]
	]
]

#define MI_THREAD_ID [
	#either OS = 'Windows [
		#inline [
			#{64A118000000}		;-- mov eax, DWORD PTR fs:24 (NtCurrentTeb)
			return: [ulong!]
		]
	][
		#inline [
			#{65A100000000}		;-- mov eax, gs:0x0
			return: [ulong!]
		]
	]
]

#define MI_MAX_CACHE			8

mimalloc: context [

	#enum page-flags! [
		PAGE_FLAG_IN_USE:		1
		PAGE_FLAG_RESET:		2
		PAGE_FLAG_COMMITED:		4
		PAGE_FLAG_USED:			8
		PAGE_FLAG_IN_FULL:		10h
	]

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
		MI_PAGE_HUGE	;-- blocks more than 1MB
	]

	block!: alias struct! [		;-- free lists contains blocks
		next [block!]
	]

	page!: alias struct! [
		idx				[integer!]
		flags			[integer!]
		capacity		[integer!]	;-- number of blocks committed
		reserved		[integer!]	;-- number of blocks reserved in memory
		free-blocks		[block!]
		used			[integer!]
		local-free		[block!]
		thread-freed	[integer!]
		thread-free		[block!]
		block-size		[integer!]
		heap			[heap!]
		next			[page!]
		prev			[page!]
	]

	segment!: alias struct! [
		id				[integer!]
		next			[segment!]
		prev			[segment!]
		abandoned_next	[segment!]
		abandoned		[integer!]
		used			[integer!]
		capacity		[integer!]
		size			[integer!]
		info-size		[integer!]
		page-shift		[integer!]
		thread-id		[ulong!]
		page-kind		[integer!]
		pages			[page! value]
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
		small-free	[segment-queue! value]
		medium-free	[segment-queue! value]
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
		heartbeat		[ulong!]
		recurse?		[logic!]
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
		thread-id		[ulong!]
		page-count		[integer!]
		reclaim?		[logic!]
	]

	thread-data!: alias struct! [
		heap			[heap! value]
		tld				[tld! value]
	]

	#either OS = 'Windows [
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
					return:		[byte-ptr!]
				]
				VirtualFree: "VirtualFree" [
					address 	[byte-ptr!]
					size		[integer!]
					type		[integer!]
					return:		[integer!]
				]
			]
		]
	][
		#import [
			LIBPTHREAD-file cdecl [
				pthread_key_create: "pthread_key_create" [
					key			[ulong!]
					destructor	[int-ptr!]
					return:		[integer!]
				]
				pthread_setspecific: "pthread_setspecific" [
					key			[ulong!]
					value		[int-ptr!]
					return:		[integer!]
				]
			]
		]
	]

	os-page-size: 4096
	alloc-granularity: 4096

	empty-page: declare page!
	stats-main: declare stats!
	heap-main: declare heap!
	tld-main: declare tld!
	heap-default: as heap! 0

	FLS-key: 0

	zero-memory: func [
		dest	[byte-ptr!]
		size	[integer!]
	][
		loop size [dest/value: #"^@" dest: dest + 1]
	]

	;== OS memory APIs

	OS-alloc: func [
		size	[integer!]
		commit?	[logic!]
		stats	[stats!]
		return: [byte-ptr!]
		/local
			flags [integer!]
	][
		flags: 2000h							;-- MEM_RESERVE
		if commit? [flags: 3000h]				;-- MEM_RESERVE or MEM_COMMIT
		VirtualAlloc null size flags 4			;-- PAGE_READWRITE
	]

	OS-alloc-at: func [
		addr	[byte-ptr!]
		size	[integer!]
		commit?	[logic!]
		stats	[stats!]
		return: [byte-ptr!]
		/local
			flags [integer!]
	][
		flags: 2000h							;-- MEM_RESERVE
		if commit? [flags: 3000h]				;-- MEM_RESERVE or MEM_COMMIT
		VirtualAlloc addr size flags 4			;-- PAGE_READWRITE
	]

	OS-free: func [
		addr	[byte-ptr!]
		size	[integer!]
		stats	[stats!]
	][
		if zero? VirtualFree addr 0 8000h [		;-- MEM_RELEASE: 0x8000
			throw 7FFFFFF6h
		]
	]

	OS-decommit: func [
		addr	[byte-ptr!]
		size	[integer!]
		stats	[stats!]
		return: [logic!]
		/local
			s	[byte-ptr!]
			e	[byte-ptr!]
			sz	[integer!]
	][
		s: as byte-ptr! round-to as-integer addr os-page-size
		e: as byte-ptr! (as-integer addr) + size / os-page-size * os-page-size
		sz: as-integer e - s
		either sz > 0 [
			0 <> VirtualFree s sz 4000h			;-- MEM_DECOMMIT: 0x4000
		][true]
	]

	OS-alloc-aligned: func [
		size	[integer!]
		align	[integer!]
		commit?	[logic!]
		stats	[stats!]
		return: [byte-ptr!]
		/local
			p	[byte-ptr!]
			p2	[byte-ptr!]
			sz	[integer!]
	][
		size: round-to size os-page-size
		p: OS-alloc size commit? stats
		if null? p [return null]

		if (as-integer p) % align <> 0 [		;-- not aligned
			OS-free p size stats
			sz: size + align
			loop 3 [
				p: OS-alloc sz commit? stats
				if null? p [return null]
				if (as-integer p) % align = 0 [
					OS-decommit p + size align stats
					break
				]
				OS-free p sz stats
				p2: as byte-ptr! round-to as-integer p align
				p: OS-alloc-at p2 size commit? stats
				if p = p2 [break]
				if p <> null [
					OS-free p size stats
					p: null
				]
			]
		]
		p
	]

	thread-done-func: func [
		#if OS <> 'Windows [[cdecl]]
		value	[int-ptr!]
		/local
			id	[ulong!]
	][
		if null? value [exit]

		;TBD Free the thread local default heap
		;id: MI_THREAD_ID
		;heap-default: either id = heap-main/thread-id [heap-main][0]
	]

	;== Init functions

	init-thread: func [/local id [ulong!]][
		init-default-heap

		;-- set hooks for our `thread-done-func`
		id: MI_THREAD_ID
		id: id or 1
		#either OS = 'Windows [
			FlsSetValue FLS-key as int-ptr! id
		][
			pthread_setspecific FLS-key as int-ptr! id
		]
	]

	init-process: func [
		/local
			h	[heap!]
	][
		h: heap-main
		zero-memory as byte-ptr! empty-page size? page!
		zero-memory as byte-ptr! tld-main size? tld!
		h/tld: tld-main
		heap-default: h

		#either OS = 'Windows [
			FLS-key: FlsAlloc as int-ptr! :thread-done-func
		][
			pthread_key_create :FLS-key as int-ptr! :thread-done-func
		]

		init-thread
	]

	init-default-heap: func [
		/local
			hp	[heap!]
			tld	[tld!]
			id	[ulong!]
	][
		hp: heap-main
		id: MI_THREAD_ID
		either hp/thread-id = id [		;-- main thread
			0 ;heap-default: heap-main	;-- uncomment it once we have thread local variable support
		][
			0
		]

		init-heap hp
	]

	init: func [/local si [tagSYSTEM_INFO value]][
		GetSystemInfo :si
		if si/dwPageSize > 0 [os-page-size: si/dwPageSize]
		if si/dwAllocationGranularity > 0 [
			alloc-granularity: si/dwAllocationGranularity
		]
		init-process
	]

	init-heap: func [
		hp		[heap!]
		/local
			p	[int-ptr!]
			pp	[ptr-ptr!]
	][
		pp: as ptr-ptr! :hp/pages-direct
		loop 130 [
			pp/value: as int-ptr! empty-page
			pp: pp + 1
		]

		p: :hp/pages
		p/3:   4
		p/6:   4       p/9:   8      p/12:  12     p/15:  16      p/18:  20
		p/21:  24      p/24:  28     p/27:  32 
		p/30:  40      p/33:  48     p/36:  56     p/39:  64      p/42:  80
		p/45:  96      p/48:  112    p/51:  128 
		p/54:  160     p/57:  192    p/60:  224    p/63:  256     p/66:  320
		p/69:  384     p/72:  448    p/75:  512 
		p/78:  640     p/81:  768    p/84:  896    p/87:  1024    p/90:  1280
		p/93:  1536    p/96:  1792   p/99:  2048 
		p/102: 2560    p/105: 3072   p/108: 3584   p/111: 4096    p/114: 5120
		p/117: 6144    p/120: 7168   p/123: 8192 
		p/126: 10240   p/129: 12288  p/132: 14336  p/135: 16384   p/138: 20480
		p/141: 24576   p/144: 28672  p/147: 32768 
		p/150: 40960   p/153: 49152  p/156: 57344  p/159: 65536   p/162: 81920
		p/165: 98304   p/168: 114688 p/171: 131072 
		p/174: 163840  p/177: 196608 p/180: 229376 p/183: 262144  p/186: 327680
		p/189: 393216  p/192: 458752 p/195: 524288 
		p/198: 655360  p/201: 786432 p/204: 917504 p/207: 1048576 p/210: 1310720
		p/213: MI_HUGE_SIZE p/216: MI_FULL_SIZE

		hp/thread-id: MI_THREAD_ID
		hp/delayed-free: null
		hp/page-count: 0
		hp/reclaim?: no
	]

	create-heap: func [
		return: [heap!]
		/local
			hb	[heap!]
			h	[heap!]
	][
		hb: heap-default/tld/heap-backing
		h: as heap! heap-alloc hb size? heap!
		if h = null [return null]

		init-heap h
		h/tld: hb/tld
		h
	]

	page-init: func [
		page		[page!]
		blk-sz		[integer!]
		/local
			seg		[segment!]
			p		[byte-ptr!]
			psize	[integer!]
			n		[integer!]
			blk		[block!]
			last	[block!]
			nxt		[block!]
	][
		seg: PTR_TO_SEGMENT(page)
		psize: page/reserved
		p: (as byte-ptr! seg) + (page/idx * psize)
		if zero? page/idx [
			p: p + seg/info-size
			psize: psize - seg/info-size
		]
		page/block-size: blk-sz
		n: psize / blk-sz

		blk: as block! p
		last: as block! p + (n - 1 * blk-sz)
		loop n [
			nxt: as block! (as byte-ptr! blk) + blk-sz
			blk/next: nxt
			blk: nxt
		]
		last/next: null
		page/reserved: n
		page/capacity: n
		page/free-blocks: as block! p
	]

	page-alloc-in: func [
		seg			[segment!]
		tld			[segments-tld!]
		return:		[page!]
		/local
			page	[page!]
			i		[integer!]
			n		[integer!]
			psize	[integer!]
			p		[byte-ptr!]
			blk-sz	[integer!]
			adjust	[integer!]
	][
		n: seg/capacity
		i: 0
		until [
			page: (as page! :seg/pages) + i
			if page/flags and PAGE_FLAG_IN_USE = 0 [
				psize: either seg/page-kind = MI_PAGE_HUGE [
					seg/size
				][
					1 << seg/page-shift
				]
				page/reserved: psize
				p: (as byte-ptr! seg) + (page/idx * psize)
				if zero? page/idx [		;-- the first page starts after the segment info
					p: p + seg/info-size
					psize: psize - seg/info-size
					blk-sz: page/block-size
					if all [blk-sz > 0 seg/page-kind <= MI_PAGE_MEDIUM] [
						;adjust: blk-sz - (p % blk-sz)
						0
					]
				]
				break
			]
			i: i + 1
			i = n
		]
		assert i <> n
		page
	]

	segment-cache-pop: func [
		size		[ulong!]
		tld			[segments-tld!]
		return:		[segment!]
		/local
			seg		[segment!]
	][
		if all [size <> 0 size <> MI_SEGMENT_SIZE][return null]
		seg: tld/cache
		if null? seg [return null]
		tld/cache-count: tld/cache-count - 1
		tld/cache: seg/next
		seg/next: null
		seg
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
			mini-sz		[integer!]
			isize		[integer!]
			segment-sz	[integer!]
			segment		[segment!]
			page		[page!]
			i			[integer!]
	][
		either kind < MI_PAGE_LARGE [
			page-sz: 1 << page-shift
			capacity: MI_SEGMENT_SIZE / page-sz
		][
			capacity: 1
		]
		mini-sz: capacity - 1 * (size? page!) + (size? segment!) + 16	;-- padding
		isize: round-to mini-sz 16 * MI_MAX_ALIGN_SIZE
		segment-sz: either zero? required [MI_SEGMENT_SIZE][
			round-to required + isize MI_PAGE_HUGE_ALIGN
		]

		segment: segment-cache-pop segment-sz tld

		either segment <> null [
			0 ;TBD: commit if segment is uncommited
		][
			segment: as segment! OS-alloc-aligned segment-sz MI_SEGMENT_SIZE yes tld/stats
		]

		;-- initialize segment
		zero-memory (as byte-ptr! segment) + 4 (size? segment!) - 4		;-- skip id

		segment/page-kind: kind
		segment/capacity: capacity
		segment/page-shift: page-shift
		segment/size: segment-sz
		segment/info-size: isize
		i: 0
		until [
			page: (as page! :segment/pages) + i
			page/idx: i
			page/flags: 0
			i: i + 1
			i = capacity
		]
		segment
	]

	segment-page-alloc: func [
		kind		[page-kind!]
		shift		[integer!]
		tld			[segments-tld!]
		return: 	[page!]
		/local
			sq		[segment-queue!]
			seg		[segment!]
			sz		[integer!]
			page	[page!]
	][
		sq: either kind = MI_PAGE_SMALL [tld/small-free][tld/medium-free]
		if null? sq/first [
			seg: segment-alloc 0 kind shift tld
			seg/next: null
			seg/prev: sq/last
			either sq/last <> null [
				sq/last/next seg
			][
				sq/first: seg
			]
			sq/last: seg
		]
		page: page-alloc-in seg tld
		page/flags: page/flags or PAGE_FLAG_IN_USE
		seg/used: seg/used + 1
		if seg/used = seg/capacity [	;-- no more free pages, remove from the queue
			segment-queue-remove seg tld
		]
		page
	]

	big-page-alloc: func [
		size		[integer!]
		kind		[page-kind!]
		shift		[integer!]
		tld			[segments-tld!]
		return:		[page!]
		/local
			seg		[segment!]
			page	[page!]
	][
		seg: segment-alloc size kind shift tld
		if null? seg [return null]

		if kind = MI_PAGE_HUGE [seg/thread-id: 0]
		seg/used: 1
		page: as page! :seg/pages
		page/reserved: seg/size
		page/flags: PAGE_FLAG_IN_USE
		page
	]

	update-pages-direct: func [
		heap		[heap!]
		queue		[page-queue!]
		/local
			size	[integer!]
			page	[page!]
			start	[integer!]
			idx		[integer!]
			i		[integer!]
			pp		[ptr-ptr!]
			p-page	[ptr-ptr!]
			bin		[integer!]
			prev	[page-queue!]
			pages	[page-queue!]
	][
		size: queue/block-size
		if size > MI_SMALL_SIZE_MAX [exit]

		page: queue/first
		if null? page [page: empty-page]

		idx: MI_WORD_SIZE?(size)
		pp: as ptr-ptr! :heap/pages-direct
		p-page: pp + idx
		if p-page/value = (as int-ptr! page) [exit]

		either idx <= 1 [
			start: 0
		][
			pages: as page-queue! :heap/pages
			bin: slot-idx? size
			prev: queue - 1
			while [
				all [
					prev > pages
					bin = slot-idx? prev/block-size
				]
			][
				prev: prev - 1
			]
			start: MI_WORD_SIZE?(prev/block-size)
			start: start + 1
			if start > idx [start: idx]
		]

		i: start
		while [i <= idx][
			p-page: pp + i
			p-page/value: as int-ptr! page
			i: i + 1
		]
	]

	segment-queue-remove: func [
		seg			[segment!]
		tld			[segments-tld!]
		/local
			qe		[segment-queue!]
	][
		qe: GET_SEGMENT_QUEUE(seg/page-kind tld)
		if all [
			qe <> null
			any [seg/next <> null seg/prev <> null qe/first = seg]
		][
			if seg/prev <> null [seg/prev/next: seg/next]
			if seg/next <> null [seg/next/prev: seg/prev]
			if seg = qe/first [qe/first: seg/next]
			if seg = qe/last [qe/last: seg/prev]
			seg/next: null
			seg/prev: null
		]
	]

	page-queue-remove: func [
		queue		[page-queue!]
		page		[page!]
	][
		if page/prev <> null [page/prev/next: page/next]
		if page/next <> null [page/next/prev: page/prev]
		if page = queue/last [queue/last: page/prev]
		if page = queue/first [
			queue/first: page/next
			update-pages-direct page/heap queue
		]
		page/heap/page-count: page/heap/page-count - 1
		page/next: null
		page/prev: null
		page/heap: null
		page/flags: page/flags and (not PAGE_FLAG_IN_FULL)
	]

	page-queue-add-from: func [
		to		[page-queue!]
		from	[page-queue!]
		page	[page!]
	][
		;-- remove the page from the `from` queue
		if page/prev <> null [page/prev/next: page/next]
		if page/next <> null [page/next/prev: page/prev]
		if page = from/last [from/last: page/prev]
		if page = from/first [
			from/first: page/next
			update-pages-direct page/heap from
		]

		;-- add the page to the `to` queue
		page/prev: to/last
		page/next: null
		either to/last <> null [
			to/last/next: page
		][
			to/first: page
			update-pages-direct page/heap to
		]
		to/last: page
		either to/block-size <> MI_FULL_SIZE [
			page/flags: page/flags and (not PAGE_FLAG_IN_FULL)
		][
			page/flags: page/flags or PAGE_FLAG_IN_FULL
		]
	]

	cache-segment: func [		;-- cache some segments
		segment		[segment!]
		tld			[segments-tld!]
		return:		[logic!]	;-- YES: cached, NO: cache is full
	][
		if any [
			segment/size <> MI_SEGMENT_SIZE
			tld/cache-count = MI_MAX_CACHE
		][return no]

		segment/next: tld/cache
		tld/cache: segment
		tld/cache-count: tld/cache-count + 1
		true
	]

	segment-page-free: func [
		page		[page!]
		force?		[logic!]
		tld			[segments-tld!]
		/local
			seg		[segment!]
			qe		[segment-queue!]
	][
		seg: PTR_TO_SEGMENT(page)
		zero-memory (as byte-ptr! page) + 8 (size? page!) - 8
		seg/used: seg/used - 1

		either zero? seg/used [
			segment-queue-remove seg tld
			if any [
				force?
				not cache-segment seg tld
			][	;-- return it to the OS
				seg/thread-id: 0
				OS-free as byte-ptr! seg seg/size tld/stats
			]
		][
			if seg/used + 1 = seg/capacity [	;-- move back to free lists
				qe: GET_SEGMENT_QUEUE(seg/page-kind tld)
				seg/next: null
				seg/prev: qe/last
				either qe/last <> null [
					qe/last/next seg
				][
					qe/first: seg
				]
				qe/last: seg
			]
		]
	]

	page-free: func [		;-- free a page with no more free blocks
		page		[page!]
		queue		[page-queue!]
		force?		[logic!]
		/local
			heap	[heap!]
	][
		heap: page/heap
		page-queue-remove queue page
		segment-page-free page force? heap/tld/segments
	]

	queue-find-page: func [
		heap		[heap!]
		pq			[page-queue!]
		size		[integer!]
		return:		[page!]
		/local
			page	[page!]
			next	[page!]
			rpage	[page!]
			free-n	[integer!]
			count	[integer!]
			blk-sz	[integer!]
			kind	[page-kind!]
			shift	[integer!]
			seg-tld	[segments-tld!]
			qfull	[page-queue!]
	][
		;-- search in page queue
		rpage: null
		count: 0
		free-n: 0
		page: pq/first
		while [page <> null][
			next: page/next
			count: count + 1

			;; 1. collect freed blocks by us and other threads
			page-collect page false

			;; 2. if the page contains free blocks
			if page/free-blocks <> null [
				;-- If all blocks are free, we might retire this page instead.
				;-- do this at most 8 times to bound allocation time.
				;-- (note: this can happen if a page was earlier not retired due
				;-- to having neighbours that were mostly full or due to concurrent frees)
				either all [free-n < 8 page/used = page/thread-freed][
					free-n: free-n + 1
					if rpage <> null [page-free rpage pq false]
					rpage: page
					page: next
					continue
				][
					break
				]
			]

			;; 3. if the page is completely full, move it to the `pages-full` queue
			;;    so we don't visit long-lived pages too often
			if page/flags and PAGE_FLAG_IN_FULL = 0 [
				qfull: (as page-queue! :heap/pages) + MI_BIN_FULL
				page-queue-add-from qfull pq page
			]

			page: next
		]

		if null? page [
			page: rpage
			rpage: null
		]

		if rpage <> null [page-free rpage pq false]

		;-- get a fresh page
		if null? page [
			blk-sz: pq/block-size
			seg-tld: heap/tld/segments
			page: case [
				blk-sz <= MI_SMALL_OBJ_SIZE_MAX [
					segment-page-alloc MI_PAGE_SMALL MI_SMALL_PAGE_SHIFT seg-tld
				]
				blk-sz <= MI_MEDIUM_OBJ_SIZE_MAX [
					segment-page-alloc MI_PAGE_MEDIUM MI_MEDIUM_PAGE_SHIFT seg-tld
				]
				blk-sz <= MI_LARGE_OBJ_SIZE_MAX [
					big-page-alloc 0 MI_PAGE_LARGE MI_LARGE_PAGE_SHIFT seg-tld
				]
				true [
					big-page-alloc size MI_PAGE_HUGE MI_SEGMENT_SHIFT seg-tld
				]
			]
			page-init page blk-sz
			page/heap: heap
			page/next: pq/first
			page/prev: null
			either pq/first <> null [
				pq/first/prev: page
			][
				pq/last: page
			]
			pq/first: page

			update-pages-direct heap pq
			heap/page-count: heap/page-count + 1
		]
		page
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
		either size <= MI_SMALL_SIZE_MAX [	;-- fast path
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
		idx: MI_WORD_SIZE?(size)
		p: (as ptr-ptr! :heap/pages-direct) + idx
		page-alloc heap as page! p/value size
	]

	deferred-free: func [
		heap		[heap!]
		force?		[logic!]
		/local
			tld		[tld!]
	][
		tld: heap/tld
		tld/heartbeat: tld/heartbeat + 1
		unless tld/recurse? [
			tld/recurse?: yes
			;TBD do GC
			tld/recurse?: no
		]
	]

	heap-delayed-free: func [
		heap		[heap!]
		/local
			blk		[block!]
			next	[block!]
			dfree	[block!]
			df		[int-ptr!]
			blk2	[integer!]
			seg		[segment!]
			page	[page!]
			diff	[integer!]
			idx		[integer!]
	][
		df: :heap/delayed-free
		until [				;-- take over the list
			blk: heap/delayed-free
			blk2: as-integer blk
			any [
				null? blk
				system/atomic/cas df blk2 0
			]
		]

		while [blk <> null][
			next: blk/next
			free as byte-ptr! blk		;@@
			blk: next
		]
	]

	slot-idx?: func [
		size		[integer!]
		return:		[integer!]
		/local
			wsize	[integer!]
			idx		[integer!]
	][
		wsize: MI_WORD_SIZE?(size)
		case [
			wsize <= 1 [idx: 1]
			wsize <= 4 [idx: wsize + 1 and FFFEh]
			wsize > MI_LARGE_OBJ_WSIZE_MAX [idx: MI_BIN_HUGE]
			true [
				if wsize <= 16 [wsize: wsize + 3 and FFFCh]
				wsize: wsize - 1
				idx: log-b wsize
				idx: idx << 2 + (wsize >> (idx - 2) and 3) - 3
			]
		]
		idx
	]

	page-collect: func [
		page		[page!]
		force?		[logic!]
		/local
			b		[block!]
			next	[block!]
	][
		;-- TBD collect the thread free list

		;-- collect the local free list
		if page/local-free <> null [
			either null? page/free-blocks [
				page/free-blocks: page/local-free
				page/local-free: null
				page/flags: page/flags or PAGE_FLAG_USED
			][
				if force? [
					b: page/local-free
					while [
						next: b/next
						next <> null
					][
						b: next
					]
					b/next: page/free-blocks
					page/free-blocks: page/local-free
					page/local-free: null
					page/flags: page/flags or PAGE_FLAG_USED
				]
			]
		]
	]

	heap-alloc-generic: func [
		heap		[heap!]
		size		[integer!]
		return:		[byte-ptr!]
		/local
			page	[page!] 
			idx		[integer!]
			qe		[page-queue!]
	][
		deferred-free heap false	;-- call potential deferred free routine
		heap-delayed-free heap		;-- free pages from other threads

		either size <= MI_LARGE_OBJ_SIZE_MAX [
			idx: slot-idx? size
			qe: (as page-queue! :heap/pages) + idx
			page: qe/first
			either page <> null [	;-- try to find a free page in page queue
				page-collect page false

				if null? page/free-blocks [
					page: queue-find-page heap qe size
				]
			][
				page: queue-find-page heap qe size
			]			
		][
			size: round-to size 64 * 1024		;-- round to 64kb aligned
			page: big-page-alloc size MI_PAGE_HUGE MI_SEGMENT_SHIFT heap/tld/segments
			page-init page size
		]

		page-alloc heap page size		
	]

	page-unfull: func [				;-- move it from the full list back to regular list
		page		[page!]
		/local
			heap	[heap!]
			qfull	[page-queue!]
			qe		[page-queue!]
			idx		[integer!]
	][
		heap: page/heap
		qfull: (as page-queue! :heap/pages) + MI_BIN_FULL
		idx: slot-idx? page/block-size
		qe: (as page-queue! :heap/pages) + idx
		page-queue-add-from qe qfull page
	]

	free: func [
		p		[byte-ptr!]
		/local
			seg		[segment!]
			tid		[ulong!]
			page	[page!]
			diff	[integer!]
			idx		[integer!]
			blk		[block!]
			i		[integer!]
			pq		[page-queue!]
			heap	[heap!]
	][
		seg: PTR_TO_SEGMENT(p)
		if null? seg [exit]

		;tid: MI_THREAD_ID
		diff: as-integer p - (as byte-ptr! seg)
		idx: diff >> seg/page-shift
		page: (as page! :seg/pages) + idx

		blk: as block! p
		blk/next: page/local-free
		page/local-free: blk
		page/used: page/used - 1

		case [
			page/used = page/thread-freed [			;-- the page is empty
				;-- TBD: don't retire too often..
				;-- (or we end up retiring and re-allocating most of the time)

				either seg/page-kind <> MI_PAGE_HUGE [
					idx: either page/flags and PAGE_FLAG_IN_FULL <> 0 [MI_BIN_FULL][
						slot-idx? page/block-size
					]
					heap: page/heap
					pq: (as page-queue! :heap/pages) + idx
					page-free page pq false
				][
					heap: heap-default
					segment-page-free page true heap/tld/segments
				]
			]
			page/flags and PAGE_FLAG_IN_FULL <> 0 [	;-- page in pages-full queue
				page-unfull page
			]
			true [0]
		]
	]

	malloc: func [
		size	[ulong!]
		return: [byte-ptr!]
	][
		heap-alloc heap-default size
	]
]

test: func [/local p [byte-ptr!]][
	mimalloc/init
	p: mimalloc/malloc 1
	?? p
	mimalloc/free p
	?? p
	probe 2222
	p: mimalloc/malloc 1
	?? p
	mimalloc/free p
	?? p

	probe 444444
	p: mimalloc/malloc 1024 * 1024
	?? p
	mimalloc/free p
	?? p

	probe 555555
	p: mimalloc/malloc 1024 * 1100
	?? p
	mimalloc/free p
	?? p
]

test