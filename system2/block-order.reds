Red/System [
	File: 	 %block-order.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;-- reverse post-order of basic blocks
rpo!: alias struct! [
	blocks		 [vector!]		;-- vector<block-info!>
	n-blocks	 [integer!]
	loops		 [vector!]		;-- vector<loop-info!>
	blk-list	 [list!]
	loop-edges	 [list!]
	loop-headers [ptr-array!]
	bitmap		 [bit-table!]
	start-bb	 [basic-block!]
]

make-label: func [
	blk		[basic-block!]
	return: [label!]
	/local
		l	[label!]
][
	l: xmalloc(label!)
	l/header: od_label
	l/block: blk
	l/pos: -1
	l
]

rpo: context [
	#define RPO_NUMBERING -2
	#define RPO_DONE -3

	#define IN_LOOP?(blk loop-info) [
		bit-table/pick bitmap loop-info/index + 1 blk/mark
	]

	#define MARK_IN_LOOP(blk loop-info) [
		bit-table/set bitmap loop-info/index + 1 blk/mark
	]

	loop-block!: alias struct! [
		loop-info	[loop-info!]
		start		[list!]		;-- list<loop-block!>
		end			[list!]		;-- list<loop-block!>
		block		[basic-block!]
	]

	make-block-info: func [
		bb		[basic-block!]
		num		[integer!]
		return:	[block-info!]
		/local
			b	[block-info!]
	][
		b: as block-info! malloc size? block-info!
		b/block: bb
		b/rpo-num: num
		b/start: -1
		b/end: -1
		b/label: make-label bb
		bb/info: b
		b
	]

	number-blocks: func [
		bb			[basic-block!]
		r			[rpo!]
		/local
			n		[integer!]
			succs	[ptr-array!]
			p		[ptr-ptr!]
			e		[cf-edge!]
			blk		[basic-block!]
	][
		bb/mark: RPO_NUMBERING
		succs: block-successors bb
		if succs <> null [
			p: ARRAY_DATA(succs) + succs/length
			loop succs/length [
				p: p - 1
				e: as cf-edge! p/value
				blk: e/dst
				either blk/mark = RPO_NUMBERING [
					LIST_INSERT(r/loop-edges e)
				][
					if blk/mark >= -1 [number-blocks blk r]
				]
			]
		]
		r/n-blocks: r/n-blocks + 1
		bb/mark: RPO_DONE
		LIST_INSERT(r/blk-list bb)
	]

	mark-blocks-loop: func [
		"mark all blocks inside a loop"
		bitmap			[bit-table!]
		loop-info		[loop-info!]
		header			[basic-block!]
		end				[basic-block!]
		/local
			p			[ptr-ptr!]
			e			[cf-edge!]
	][
		if IN_LOOP?(end loop-info) [exit]
		if end = header [exit]
		MARK_IN_LOOP(end loop-info)
		p: ARRAY_DATA(end/preds)
		loop end/preds/length [
			e: as cf-edge! p/value
			mark-blocks-loop bitmap loop-info header as basic-block! e/src/next
			p: p + 1
		]
	]

	make-loop-block: func [
		loop-info	[loop-info!]
		start		[list!]		;-- list<loop-block!>
		end			[list!]		;-- list<loop-block!>
		blk			[basic-block!]
		return:		[loop-block!]
		/local
			l		[loop-block!]
	][
		l: as loop-block! malloc size? loop-block!
		l/loop-info: loop-info
		l/start: start
		l/end: end
		l/block: blk
		l
	]

	number-succs: func [
		r		[rpo!]
		blk		[basic-block!]
		lp		[loop-info!]
		/local
			succs	[ptr-array!]
			p		[ptr-ptr!]
			e		[cf-edge!]
			l-blk	[loop-block!]
			bitmap	[bit-table!]
	][
		succs: block-successors blk
		if succs <> null [
			p: ARRAY_DATA(succs) + succs/length
			either null? lp [
				loop succs/length [
					p: p - 1
					e: as cf-edge! p/value
					number-block-loop r e/dst lp
				]
			][
				bitmap: r/bitmap
				loop succs/length [
					p: p - 1
					e: as cf-edge! p/value
					either IN_LOOP?(e/dst lp) [number-block-loop r e/dst lp][
						LIST_INSERT(lp/out-edges e)
					]
				]
			]
		]
		l-blk: make-loop-block null null null blk
		LIST_INSERT(r/blk-list l-blk)
	]

	number-loop: func [
		r		[rpo!]
		blk		[basic-block!]
		new-lp	[loop-info!]
		lp		[loop-info!]
		/local
			old-list [list!]
			new-list [list!]
			l		 [list!]
			e		 [cf-edge!]
			l-blk	 [loop-block!]
			bitmap	 [bit-table!]
	][
		old-list: r/blk-list
		number-succs r blk new-lp
		new-list: r/blk-list

		r/blk-list: old-list	;-- `pop` all the loop nodes
		l: new-lp/out-edges
		either null? lp [
			while [l <> null][
				e: as cf-edge! l/head
				number-block-loop r e/dst null
				l: l/tail
			]
		][	;-- process out edges in outer loop
			bitmap: r/bitmap
			while [l <> null][
				e: as cf-edge! l/head
				either IN_LOOP?(e/dst lp) [
					number-block-loop r e/dst lp
				][
					LIST_INSERT(lp/out-edges e)
				]
				l: l/tail
			]
		]
		l-blk: make-loop-block new-lp new-list old-list null
		LIST_INSERT(r/blk-list l-blk)
	]

	number-block-loop: func [
		r		[rpo!]
		blk		[basic-block!]
		lp		[loop-info!]
		/local
			new-lp [loop-info!]
	][
		if bit-table/set r/bitmap 0 blk/mark [exit]
		new-lp: as loop-info! ptr-array/pick r/loop-headers blk/mark
		either new-lp <> null [number-loop r blk new-lp lp][
			number-succs r blk lp
		]
	]

	extract-loop-block: func [
		vec			[vector!]
		l-blk		[loop-block!]
		depth		[integer!]
		/local
			bb		[basic-block!]
			lp		[loop-info!]
			blk		[block-info!]
			s e		[list!]
	][
		bb: l-blk/block
		either bb <> null [
			bb/mark: vec/length
			vector/append-ptr vec as byte-ptr! make-block-info bb bb/mark
		][
			lp: l-blk/loop-info
			lp/start: vec/length
			lp/depth: depth

			s: l-blk/start
			e: l-blk/end
			while [s <> e][
				extract-loop-block vec as loop-block! s/head depth + 1
				s: s/tail
			]
			lp/end: vec/length

			blk: as block-info! vector/pick-ptr vec lp/start
			blk/loop-info: lp
		]
	]

	build-with-loops: func [
		r		[rpo!]
		/local
			bitmap		 [bit-table!]
			loop-headers [ptr-array!]
			loops		 [vector!]
			n-blks		 [integer!]
			list		 [list!]
			l-blk		 [loop-block!]
			vec			 [vector!]
			e			 [cf-edge!]
			d			 [basic-block!]
			s			 [instr-end!]
			lp			 [loop-info!]
	][
		n-blks: r/n-blocks
		bitmap: bit-table/make 1 n-blks
		loop-headers: ptr-array/make n-blks
		loops: vector/make size? int-ptr! 4
		r/loops: loops
		r/bitmap: bitmap
		r/loop-headers: loop-headers

		;-- mark all blocks in all loops
		list: r/loop-edges
		while [list <> null][
			e: as cf-edge! list/head
			s: e/src
			d: e/dst

			;-- get loop info
			lp: as loop-info! ptr-array/pick loop-headers d/mark
			if null? lp [
				lp: as loop-info! malloc size? loop-info!
				lp/index: loops/length
				bit-table/grow-row bitmap lp/index + 2
				vector/append-ptr loops as byte-ptr! lp
				ptr-array/poke loop-headers d/mark as int-ptr! lp
			]

			;-- mark all blocks in this loop
			MARK_IN_LOOP(d lp)
			mark-blocks-loop bitmap lp d as basic-block! s/next

			list: list/tail
		]

		;-- number blocks, loop-aware depth first
		number-block-loop r r/start-bb null
		vec: vector/make size? int-ptr! n-blks
		list: r/blk-list
		while [list <> null][
			l-blk: as loop-block! list/head
			extract-loop-block vec l-blk 1
			list: list/tail
		]
		r/blocks: vec
	]

	build: func [
		ir		[ir-fn!]
		return: [rpo!]
		/local
			r		[rpo!]
			bb		[basic-block!]
			succs	[ptr-array!]
			vec		[vector!]
			list	[list!]
			i		[integer!]
	][
		r: as rpo! malloc size? rpo!
		bb: ir/start-bb
		r/start-bb: bb

		succs: block-successors bb
		either any [null? succs zero? succs/length][
			bb/mark: 0
			vec: vector/make size? int-ptr! 1
			vector/append-ptr vec as byte-ptr! make-block-info bb 0
			r/blocks: vec
		][
			number-blocks bb r
			either r/loop-edges <> null [
				i: 0
				list: r/blk-list
				while [list <> null][
					bb: as basic-block! list/head
					bb/mark: i
					i: i + 1
					list: list/tail
				]
				r/blk-list: null
				build-with-loops r
			][
				vec: vector/make size? int-ptr! r/n-blocks
				i: 0
				list: r/blk-list
				while [list <> null][
					bb: as basic-block! list/head
					bb/mark: i
					vector/append-ptr vec as byte-ptr! make-block-info bb i
					i: i + 1
					list: list/tail
				]
				r/blocks: vec
			]
		]
		r
	]
]

compute-dominators: func [
	blocks		[vector!]
	/local
		bi pi	[block-info!]
		pi2		[block-info!]
		b pb	[basic-block!]
		pb2		[basic-block!]
		preds	[ptr-array!]
		p pp	[ptr-ptr!]
		e		[cf-edge!]
		i len max [integer!]
][
	p: VECTOR_DATA(blocks)
	len: VECTOR_SIZE?(blocks)
	loop len [
		bi: as block-info! p/value
		b: bi/block
		preds: b/preds
		if zero? preds/length [
			p: p + 1
			continue
		]
		pp: ARRAY_DATA(preds)
		e: as cf-edge! pp/value
		pb: as basic-block! e/src/next
		pi: pb/info
		loop preds/length - 1 [
			pp: pp + 1
			e: as cf-edge! pp/value
			pb2: as basic-block! e/src/next
			pi2: pb2/info
			if pi2/rpo-num >= bi/rpo-num [pp: pp + 1 continue]
			pi: common-dominator pi pi2
		]
		bi/dom-parent: pi
		bi/dom-sibling: pi/dom-child
		bi/dom-depth: pi/dom-depth + 1
		pi/dom-child: bi
		p: p + 1
	]
	p: p - 1
	i: len
	while [i >= 1][
		bi: as block-info! p/value
		b: bi/block
		max: i
		if max > bi/dom-max [bi/dom-max: max]
		max: bi/dom-max
		pi: bi/dom-parent
		if all [
			pi <> null
			max > pi/dom-max
		][
			pi/dom-max: max
		]
		i: i - 1
		p: p - 1
	]
]

common-dominator: func [
	a		[block-info!]
	b		[block-info!]
	return: [block-info!]
][
	while [a/dom-depth < b/dom-depth][b: b/dom-parent]
	while [a/dom-depth > b/dom-depth][a: a/dom-parent]
	while [a <> b][
		a: a/dom-parent
		b: b/dom-parent
	]
	a
]