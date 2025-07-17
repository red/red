Red/System [
	File: 	 %simple-reg-alloc.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

reg-graph!: alias struct! [
	size		[integer!]
	nodes		[ptr-array!]		;-- array<reg-node!>
	reg-set		[reg-set!]
]

reg-node!: alias struct! [
	id			[integer!]
	block		[basic-block!]
	interfere	[vector!]			;-- vector<int!> sorted
	n-interfere [integer!]
	moves		[vector!]			;-- vector<int!>
	n-moves		[integer!]
	spill-cost	[integer!]
	removed?	[logic!]
	spill?		[logic!]
	use?		[logic!]
	color?		[logic!]
	new-vreg	[vreg!]
	common-dom	[block-info!]
]

reg-graph: context [
	make: func [
		sz		[integer!]
		reg-set [reg-set!]
		return: [reg-graph!]
		/local g [reg-graph!]
	][
		g: xmalloc(reg-graph!)
		g/size: sz
		g/nodes: ptr-array/make sz
		g/reg-set: reg-set
		g
	]

	add-move: func [
		g		[reg-graph!]
		x		[integer!]
		y		[integer!]
		return: [logic!]
	][
		false
	]

	merge-moves: func [
		g		[reg-graph!]
		dst		[integer!]
		src		[integer!]
		/local
			p pp [ptr-ptr!]
			dst-n src-n [reg-node!]
	][
		if dst < 0 [exit]
		p: ARRAY_DATA(g/nodes)
		pp: p + dst
		dst-n: as reg-node! pp/value
		pp: p + src
		src-n: as reg-node! pp/value
		vector/append-v dst-n/moves src-n/moves
		dst-n/n-moves: dst-n/n-moves + src-n/n-moves
	]

	interfere?: func [
		g		[reg-graph!]
		x		[integer!]
		y		[integer!]
		return: [logic!]
		/local
			a b [integer!]
			p	[ptr-ptr!]
			pp	[int-ptr!]
			itf	[vector!]
			node [reg-node!]
			low high mid n [integer!]
	][
		if all [x < 0 y < 0][return true]

		either x < 0 [a: y b: x][a: x b: y]

		p: ARRAY_DATA(g/nodes) + a
		node: as reg-node! p/value
		itf: node/interfere
		low: 0
		high: itf/length - 1
		pp: as int-ptr! itf/data
		while [low <= high][
			mid: low + (high - low / 2) + 1
			n: pp/mid
			case [
				n = b [return true]
				n < b [low: mid]
				true  [high: mid - 2]
			]
		]
		false
	]

	combine-interfere: func [
		g		[reg-graph!]
		x		[integer!]
		y		[integer!]
		return: [vector!]
		/local
			nx ny	[reg-node!]
			p pp	[ptr-ptr!]
			vec		[vector!]
			i j		[integer!]
			px py	[int-ptr!]
			xlen ylen [integer!]
	][
		p: ARRAY_DATA(g/nodes)
		pp: p + x
		nx: as reg-node! pp/value
		pp: p + y
		ny: as reg-node! pp/value

		vec: vector/make size? integer! 4
		i: 1 j: 1
		xlen: nx/interfere/length
		px: as int-ptr! nx/interfere/data
		ylen: ny/interfere/length
		py: as int-ptr! ny/interfere/data
		while [all [i <= xlen j <= ylen]][
			x: px/i
			y: py/j
			case [
				x = y [
					vector/append-int vec x
					i: i + 1
					j: j + 1
				]
				x < y [
					vector/append-int vec x
					i: i + 1
				]
				true [
					vector/append-int vec y
					j: j + 1
				]
			]
		]
		while [i <= xlen][
			vector/append-int vec x
			i: i + 1
		]
		while [j <= ylen][
			vector/append-int vec y
			j: j + 1
		]
		vec
	]
]

reg-node: context [
	make: func [
		id		[integer!]
		blk		[basic-block!]
		return: [reg-node!]
		/local
			n	[reg-node!]
	][
		n: xmalloc(reg-node!)
		n/id: id
		n/block: blk
		n/interfere: vector/make size? integer! 4
		n/moves: vector/make size? integer! 4
		n
	]

	add-interfere: func [
		node		[reg-node!]
		id			[integer!]
		return:		[logic!]
		/local
			p		[int-ptr!]
			len i j n [integer!]
			interfere [vector!]
	][
		interfere: node/interfere
		len: interfere/length
		p: as int-ptr! interfere/data
		i: 0
		loop len [
			n: p/value
			case [
				n = id [return false]
				n > id [
					len: i
					break
				]
				true [0]
			]
			i: i + 1
			p: p + 1
		]
		
		vector/append-int interfere 0
		p: as int-ptr! interfere/data
		i: interfere/length - 1
		while [i > len][
			j: i + 1
			p/j: p/i
			i: i - 1
		]
		len: len + 1
		p/len: id
		node/n-interfere: node/n-interfere + 1
		true
	]
]

global-reg-alloc: context [

	statistic!: alias struct! [
		n-vars		[integer!]
		n-iters		[integer!]
		n-stores	[integer!]
		n-reloads	[integer!]
		n-coalesces [integer!]
		n-moves		[integer!]
	]

	move-set!: alias struct! [
		reg-set		[reg-set!]
		move-idx	[int-array!]
		reg-moves	[vector!]			;-- vector<move-state!>
		saves		[vector!]			;-- vector<move-state!>
		reloads		[vector!]			;-- vector<vreg-reg!>	
	]
	
	allocator!: alias struct! [
		cg				[codegen!]
		reg-set			[reg-set!]
		reg-usage		[int-array!]
		reg-state		[reg-state! value]
		moves-next		[move-set! value]
		moves-prev		[move-set! value]
		statistic		[statistic! value]
		reg-index		[int-array!]
		pmove-dests		[vector!]
		vregs			[vector!]
		liveness		[bit-table!]
		liveout-row		[integer!]
		mask-row		[integer!]
		graph			[reg-graph!]
		coloring		[int-array!]
		n-colors		[integer!]
		simplify-list	[vector!]
		freeze-list		[vector!]
		spill-list		[vector!]
		select-stack	[vector!]
		moves-list		[vector!]		;-- vector<int! int! int!>	var var weight
		temp-list		[vector!]
		spill?			[logic!]
		block-weight	[int-array!]
		cur-weight		[integer!]
		vars-cnt		[integer!]
		blk-reloads		[ptr-array!]
	]

	spiller!: alias struct! [
		cg				[codegen!]
		blocks			[vector!]
		liveness		[bit-table!]
		pass-start		[integer!]
		reload-start	[integer!]
		live-row		[integer!]
		tmp-row			[integer!]
		cur-row			[integer!]
		save-row		[integer!]
		livepoints		[vector!]
	]

	fn-process!: alias function! [a [allocator!] blk [basic-block!] cur-i [mach-instr!]]

	process-instrs-backward: func [
		a			[allocator!]
		blocks		[vector!]
		fn-ptr		[int-ptr!]
		/local
			i prev	[mach-instr!]
			info	[block-info!]
			blk		[basic-block!]
			p		[ptr-ptr!]
			l		[label!]
			process	[fn-process!]
	][
		process: as fn-process! fn-ptr
		i: a/cg/last-i
		info: as block-info! ptr-vector/pick-last blocks
		blk: info/block
		while [i <> null][
			prev: i/prev
			if MACH_OPCODE(i) = I_BLK_END [
				p: INS_OPERANDS(i)
				l: as label! p/value
				blk: l/block
			]
			process a blk i
			i: prev
		]
	]

	alloc: func [
		cg		[codegen!]
		/local
			a	[allocator!]
			lv	[bit-table!]
			p	[int-ptr!]
			arr [int-array!]
			blks [vector!]
	][
		a: xmalloc(allocator!)
		a/cg: cg
		a/vregs: cg/vregs
		a/reg-set: cg/reg-set
		p: cg/reg-set/regs-cls + class_i32
		arr: as int-array! ptr-array/pick cg/reg-set/regs p/value
		a/n-colors: arr/length - 1		;-- minus one temp reg
		lv: cg/liveness
		a/liveness: lv
		a/liveout-row: lv/rows
		a/mask-row: lv/rows + 1
		bit-table/grow-row lv a/mask-row
		bit-table/set-row lv a/mask-row

		blks: cg/blocks
		reset a blks

		compute-dominators blks
		process-instrs-backward a blks as int-ptr! :preprocess

		do-spill a

		a/block-weight: int-array/make blks/length
		compute-block-weight a/block-weight 1 blks 0 blks/length
		build-color-graph a
		while [a/spill?][
			a/statistic/n-iters: a/statistic/n-iters
			a/statistic/n-coalesces: 0
			insert-spills a
			build-color-graph a
		]
		process-instrs-backward a blks as int-ptr! :alloc-after-coloring
	]

	build-color-graph: func [
		a			[allocator!]
		/local
			vregs	[vector!]
			blocks	[vector!]
			g		[reg-graph!]
			info	[block-info!]
			blk		[basic-block!]
			i		[integer!]
			p		[ptr-ptr!]
	][
		blocks: a/cg/blocks
		vregs: a/vregs
		g: reg-graph/make vregs/length a/reg-set
		a/graph: g

		info: as block-info! vector/pick-ptr blocks 0
		blk: info/block
		p: ARRAY_DATA(g/nodes)
		i: 0
		loop vregs/length [
			p/value: as int-ptr! reg-node/make i blk
			p: p + 1
			i: i + 1
		]

		a/cur-weight: 0
		either null? a/moves-list [
			a/moves-list: vector/make 3 * size? integer! 10
			a/temp-list: vector/make 3 * size? integer! 10
		][
			vector/clear a/moves-list
		]
		process-instrs-backward a blocks as int-ptr! :build-graph
		color-graph a
	]

	color-graph: func [
		a			[allocator!]
		/local
			simplify-list	[vector!]
			freeze-list		[vector!]
			spill-list		[vector!]
			moves-list		[vector!]
			select-stack	[vector!]
			vregs			[vector!]
			p pp p1 p2		[ptr-ptr!]
			pint pa pc		[int-ptr!]
			node			[reg-node!]
			vreg			[vreg!]
			i n n-regs hint	[integer!]
			idx				[integer!]
			allocated regs	[int-array!]
			nodes			[ptr-array!]
	][
		simplify-list: a/simplify-list
		either null? simplify-list [
			simplify-list: vector/make size? integer! 100
			freeze-list: vector/make size? integer! 100
			spill-list: vector/make size? integer! 100
			a/select-stack: vector/make size? integer! 100
			a/simplify-list: simplify-list
			a/freeze-list: freeze-list
			a/spill-list: spill-list
		][
			freeze-list: a/freeze-list
			spill-list: a/spill-list
			vector/clear simplify-list
			vector/clear freeze-list
			vector/clear spill-list
		]

		vregs: a/vregs
		nodes: a/graph/nodes
		p: VECTOR_DATA(vregs)
		pp: ARRAY_DATA(nodes)
		i: vregs/length - 1
		while [i > 0][
			p1: p + i
			p2: pp + i
			node: as reg-node! p2/value
			if any [
				null? p1/value
				all [not node/use? not node/color?]
			][
				i: i - 1
				continue
			] 
			case [
				node/n-interfere >= a/n-colors [vector/append-int spill-list i]
				node/n-moves > 0 [probe "wrong moves count" halt]
				true [vector/append-int simplify-list i]
			]
			i: i - 1
		]

		moves-list: a/moves-list
		if moves-list/length > 0 [
			qsort moves-list/data moves-list/length moves-list/obj-sz :compare-moves
		]
		a/statistic/n-moves: moves-list/length

		while [
			any [
				simplify-list/length > 0
				freeze-list/length > 0
				spill-list/length > 0
			]
		][
			either simplify-list/length > 0 [
				do-simplify a
			][
				unless do-coalesce a [
					either freeze-list/length > 0 [
						do-freeze a
					][
						select-spill a
					]
				]
			]
		]

		a/coloring: int-array/make vregs/length
		pc: as int-ptr! a/coloring + 1
		a/spill?: false
		n-regs: a/reg-set/n-regs + 1
		allocated: int-array/make n-regs
		select-stack: a/select-stack
		while [select-stack/length > 0][
			idx: vector/remove-last-int select-stack
			p1: p + idx
			vreg: as vreg! p1/value
			p1: pp + idx
			node: as reg-node! p1/value
			node/removed?: false
			pa: as int-ptr! ARRAY_DATA(allocated)
			i: 0
			while [i < n-regs][
				pa/i: 0
				i: i + 1
			]
			pint: as int-ptr! node/interfere/data
			loop node/interfere/length [
				n: pint/value
				either n < 0 [
					n: 1 - n
					pa/n: 1
				][
					p1: pp + n
					node: as reg-node! p1/value
					unless node/removed? [
						n: n + 1
						n: pc/n + 1
						pa/n: 1
					]
				]
				pint: pint + 1
			]

			idx: idx + 1
			hint: vreg/hint
			pint: pa + hint
			if all [
				hint <> 0
				zero? pint/value		;-- allocated[hint]
			][
				pc/idx: hint
				continue
			]
			pint: a/reg-set/regs-cls + vreg/reg-class
			regs: as int-array! ptr-array/pick a/reg-set/regs pint/value
			pint: as int-ptr! regs + 1
			loop regs/length - 1 [
				n: pint/value + 1
				if zero? pa/n [
					pc/idx: n
					break
				]
				pint: pint + 1
			]
			if pc/idx > 0 [continue]
			unless node/spill? [fail "no regs available"]

			vreg/spillable?: false
			alloc-slot a/cg/frame vreg
			a/spill?: true
		]

		i: vregs/length - 1
		while [i > 0][
			p1: p + i
			p2: pp + i
			node: as reg-node! p2/value
			pint: pc + i
			if any [
				null? p1/value
				all [not node/use? not node/color?]
				pint/value > 0
			][
				i: i - 1
				continue
			]
			n: get-alias-id nodes i
			pint/value: either n > 0 [
				n: n + 1
				pc/n
			][
				0 - n
			]
			i: i - 1
		]
	]

	do-coalesce: func [
		a		[allocator!]
		return: [logic!]
		/local
			coalesced?	[logic!]
			temp-list	[vector!]
			moves-list	[vector!]
			m t			[int-ptr!]
			u v x y		[integer!]
			len			[integer!]
			nodes		[ptr-array!]
			node		[reg-node!]
	][
		coalesced?: false
		nodes: a/graph/nodes
		moves-list: a/moves-list
		temp-list: a/temp-list
		vector/clear temp-list

		m: vector/tail moves-list
		len: moves-list/length
		while [len > 0][
			m: m - 3
			len: len - 1
			u: get-alias-id nodes m/1
			v: get-alias-id nodes m/2
			x: either v < 0 [v][u]
			y: either v < 0 [u][v]
			case [
				y < 0 [0]	;-- do nothing
				x = y [
					coalesced?: true
					node: as reg-node! ptr-array/pick nodes x
					node/n-moves: node/n-moves - 1
					add-to-lists a x
				]
				all [
					not reg-graph/interfere? a/graph x y
					try-coalesce a x y
				][
					coalesced?: true
				]
				true [
					t: vector/new-item temp-list
					t/1: m/1 t/2: m/2 t/3: m/3
				]
			]
		]
		moves-list/length: 0
		a/moves-list: temp-list
		a/temp-list: moves-list
		coalesced?
	]

	do-freeze: func [
		a	[allocator!]
		/local
			n	[integer!]
	][
		n: vector/remove-last-int a/freeze-list
		vector/append-int a/simplify-list n
		freeze-moves a n
	]

	freeze-moves: func [
		a	[allocator!]
		n	[integer!]
		/local
			p pn	[ptr-ptr!]
			pm pp	[int-ptr!]
			pint	[int-ptr!]
			node	[reg-node!]
			nodes	[ptr-array!]
			moves	[vector!]
			v x y	[integer!]
			moves-list [vector!]
	][
		nodes: a/graph/nodes
		moves-list: a/moves-list
		pn: ARRAY_DATA(nodes)
		p: pn + n
		node: as reg-node! p/value
		moves: node/moves
		pm: as int-ptr! moves/data
		loop moves/length [
			v: get-alias-id nodes pm/value
			if all [v > 0 v <> n][
				p: pn + v
				node: as reg-node! p/value
				node/n-moves: node/n-moves - 1
				if all [
					not node/removed?
					zero? node/n-moves
					node/n-interfere < a/n-colors
				][
					vector/append-int a/simplify-list v
					remove-from-list a/freeze-list v
				]
			]
			pp: as int-ptr! moves-list/data
			loop moves-list/length [
				x: get-alias-id nodes pp/1
				y: get-alias-id nodes pp/2
				if any [
					all [x = n y = v]
					all [x = v y = n]
				][
					pint: vector/pop-last moves-list
					if moves-list/length > 0 [
						pp/1: pint/1 pp/2: pint/2 pp/3: pint/3
					]
					break
				]
				pp: pp + 3
			]
			pm: pm + 1
		]
	]

	select-spill: func [
		a	[allocator!]
		/local
			min-cost	[float32!]
			cost f		[float32!]
			idx i len n	[integer!]
			pp pn pv	[ptr-ptr!]
			p pint		[int-ptr!]
			vreg		[vreg!]
			node		[reg-node!]
			spill-list	[vector!]
	][
		min-cost: as float32! 1e12
		idx: -1
		i: 0
		pn: ARRAY_DATA(a/graph/nodes)
		pv: VECTOR_DATA(a/vregs)
		spill-list: a/spill-list
		len: spill-list/length
		p: as int-ptr! spill-list/data
		while [i < len][
			n: p/value
			pp: pn + n
			node: as reg-node! pp/value
			pp: pv + n
			vreg: as vreg! pp/value
			if all [
				not node/removed?
				vreg/spillable?
			][
				cost: as float32! node/spill-cost
				f: as float32! node/n-interfere
				cost: cost / f
				if cost < min-cost [
					idx: i
					min-cost: cost
				]
			]
			i: i + 1
			p: p + 1
		]
		if idx = -1 [fail "fail to spill"]
		p: as int-ptr! spill-list/data
		pint: p + idx
		n: pint/value
		pp: pn + n
		node: as reg-node! pp/value
		node/spill?: true
		vector/append-int a/simplify-list n
		i: vector/remove-last-int spill-list
		if spill-list/length > 0 [pint/value: i]
		freeze-moves a n
	]

	insert-spills: func [
		a		[allocator!]
		/local
			cg		[codegen!]
			id		[integer!]
			p		[ptr-ptr!]
			i next	[mach-instr!]
			info	[block-info!]
			blk		[basic-block!]
			l		[label!]
	][
		cg: a/cg
		a/vars-cnt: cg/fn/mark - cg/mark
		p: ARRAY_DATA(a/blk-reloads)
		loop a/blk-reloads/length [
			vector/clear as vector! p/value
			p: p + 1
		]

		i: a/cg/first-i
		info: as block-info! vector/pick-ptr a/cg/blocks 0
		blk: info/block
		while [i <> null][
			next: i/next
			if MACH_OPCODE(i) = I_BLK_BEG [
				p: INS_OPERANDS(i)
				l: as label! p/value
				blk: l/block
			]
			do-insert-spill a blk i
			i: next
		]
		spill-cleanup a
	]

	spill-cleanup: func [
		a		[allocator!]
		/local
			liveness	[bit-table!]
			vars-cnt	[integer!]
			i j len		[integer!]
			mask-row	[integer!]
			end			[integer!]
			clr			[int-ptr!]
			p pn pp		[ptr-ptr!]
			node		[reg-node!]
			blocks		[vector!]
			blk			[basic-block!]
			info		[block-info!]
			succs		[ptr-array!]
			e			[cf-edge!]
	][
		vars-cnt: a/vars-cnt
		liveness: a/liveness
		mask-row: a/mask-row
		i: vars-cnt
		len: a/vregs/length
		while [i < len][
			bit-table/set liveness mask-row i
			i: i + 1
		]

		clr: as int-ptr! a/coloring + 1
		pn: ARRAY_DATA(a/graph/nodes)
		i: 0		
		while [i < vars-cnt][
			if zero? clr/value [
				bit-table/clear liveness mask-row i
				p: pn + i
				node: as reg-node! p/value
				if node/common-dom <> null [
					;insert-reload
					0
				]
			]
			clr: clr + 1
			i: i + 1
		]

		blocks: a/cg/blocks
		p: VECTOR_DATA(blocks)
		i: blocks/length
		p: p + i
		loop i [
			p: p - 1
			info: as block-info! p/value
			succs: block-successors info/block
			pp: ARRAY_DATA(succs)
			loop succs/length [
				e: as cf-edge! pp/value
				blk: e/dst
				i: blk/info/rpo-num
				j: vars-cnt
				while [j < len][
					if bit-table/pick liveness i j [
						bit-table/set liveness info/rpo-num j
					]
					j: j + 1
				]
				pp: pp + 1
			]
			if info/loop-info <> null [
				end: info/loop-info/end
				i: info/rpo-num
				j: i + 1
				while [j < end][
					bit-table/or-rows liveness j i
					j: j + 1
				]
			]
		]
	]

	do-insert-spill: func [
		a		[allocator!]
		blk		[basic-block!]
		cur-i	[mach-instr!]
		/local
			p		[ptr-ptr!]
			o		[operand!]
			u		[use!]
			w		[overwrite!]
			d		[def!]
			c n		[integer!]
			v v2	[vreg!]
			clr		[int-ptr!]
			pint	[int-ptr!]
			opcode	[integer!]
			nodes	[ptr-array!]
			node	[reg-node!]
	][
		nodes: a/graph/nodes
		opcode: MACH_OPCODE(cur-i)
		clr: as int-ptr! a/coloring + 1
		p: INS_OPERANDS(cur-i)
		p: p + cur-i/num
		loop cur-i/num [
			p: p - 1
			o: as operand! p/value
			switch o/header and FFh [
				OD_USE [
					if opcode = I_RELOAD [continue]
					u: as use! o
					v: u/vreg
					c: u/constraint
					if all [
						v <> null
						not on-stack? a/reg-set c
					][
						pint: clr + v/idx
						if zero? pint/value [
							if opcode = I_PMOVE [
								p/value: as int-ptr! make-use v a/reg-set/spill-start
								continue
							]
							v: process-spill a v c
							p/value: as int-ptr! make-use v c
						]
					]
				]
				OD_OVERWRITE [
					w: as overwrite! o
					v: w/dst
					v2: w/src
					c: w/constraint
					pint: clr + v2/idx
					if all [
						not on-stack? a/reg-set c
						zero? pint/value
					][
						v2: process-spill a v2 c
						p/value: as int-ptr! make-overwrite v v2 c
					]
					if v <> null [
						pint: clr + v/idx
						if zero? pint/value [
							node: as reg-node! ptr-array/pick nodes v/idx
							node/block: blk
						]
					]
				]
				OD_DEF [
					d: as def! o
					v: d/vreg
					c: d/constraint
					if v <> null [
						pint: clr + v/idx
						if zero? pint/value [
							node: as reg-node! ptr-array/pick nodes v/idx
							if node/common-dom <> null [
								;insert-reload
								node/common-dom: null
							]
							node/block: blk
							if opcode = I_RELOAD [
								remove-instr cur-i
								exit
							]
							if opcode = I_PMOVE [
								p/value: as int-ptr! make-def v v/spill
							]
						]
					]
				]
				default [0]		;-- do nothing
			]
		]
	]

	process-spill: func [
		a			[allocator!]
		vreg		[vreg!]
		constraint	[integer!]
		return:		[vreg!]
		/local
			node	[reg-node!]
			new-v	[vreg!]
	][
		node: as reg-node! ptr-array/pick a/graph/nodes vreg/idx
		new-v: dup-vreg a/cg vreg
		new-v/spillable?: false
		new-v/reload-from: vreg
		if constraint <= a/reg-set/n-regs [new-v/hint: constraint]
		node/new-vreg: new-v
		new-v
	]

	do-simplify: func [
		a	[allocator!]
		/local
			n	[integer!]
			p	[int-ptr!]
			node [reg-node!]
	][
		n: vector/pick-last-int a/simplify-list
		node: as reg-node! ptr-array/pick a/graph/nodes n
		node/removed?: yes
		vector/append-int a/select-stack n

		p: as int-ptr! node/interfere/data
		loop node/interfere/length [
			decrement-degree a p/value
			p: p + 1
		]
	]

	check-precolored: func [
		graph		[reg-graph!]
		node		[reg-node!]
		precolored	[integer!]
		n-colors	[integer!]
		return:		[logic!]
		/local
			p		[int-ptr!]
			pn pp	[ptr-ptr!]
			t		[integer!]
			tnode	[reg-node!]
	][
		pn: ARRAY_DATA(graph/nodes)
		p: as int-ptr! node/interfere/data
		loop node/interfere/length [
			if p/value < 0 [p: p + 1 continue]
			t: p/value
			pp: pn + t
			tnode: as reg-node! pn/value
			if any [
				tnode/removed?
				tnode/n-interfere < n-colors
				reg-graph/interfere? graph t precolored
			][
				p: p + 1
				continue
			]
			return false
		]
		true
	]

	try-coalesce: func [
		a		[allocator!]
		x		[integer!]
		y		[integer!]
		return: [logic!]
		/local
			coalesce?	[logic!]
			p pp		[ptr-ptr!]
			pint		[int-ptr!]
			t cnt n-tmp	[integer!]
			nx ny node	[reg-node!]
			combine		[vector!]
			n-colors	[integer!]
			graph		[reg-graph!]
	][
		coalesce?: false
		graph: a/graph
		n-colors: a/n-colors
		p: ARRAY_DATA(graph/nodes)
		pp: p + y
		ny: as reg-node! pp/value
		either x < 0 [
			if check-precolored graph ny 0 - x n-colors [
				coalesce?: true
			]
		][
			pp: p + x
			nx: as reg-node! pp/value
			combine: reg-graph/combine-interfere graph x y
			cnt: 0 n-tmp: 0
			pint: as int-ptr! combine/data
			loop combine/length [
				t: pint/value
				if t < 0 [
					cnt: cnt + 1
					n-tmp: n-tmp + 1
					pint: pint + 1
					continue
				]
				pp: p + t
				node: as reg-node! pp/value
				if node/n-interfere >= n-colors [cnt: cnt + 1]
				unless node/removed? [n-tmp: n-tmp + 1]
				pint: pint + 1
			]
			if cnt < n-colors [
				coalesce?: true
				nx/n-moves: nx/n-moves - 1
				reg-graph/merge-moves graph x y
				either all [
					n-tmp >= n-colors
					nx/n-interfere < n-colors
				][
					remove-from-list a/freeze-list x
					vector/append-int a/spill-list x
				][
					if all [
						n-tmp < n-colors
						zero? nx/n-moves
					][
						remove-from-list a/freeze-list x
						vector/append-int a/simplify-list x
					]
				]
				nx/interfere: combine
				nx/n-interfere: n-tmp
			]
		]
		if coalesce? [
			a/statistic/n-coalesces: a/statistic/n-coalesces + 1
			ny/removed?: yes
			either ny/n-interfere < n-colors [
				remove-from-list a/freeze-list y
			][
				remove-from-list a/spill-list y
			]
			pint: as int-ptr! ny/interfere/data
			loop ny/interfere/length [
				t: pint/value
				if t < 0 [pint: pint + 1 continue]
				pp: p + t
				node: as reg-node! pp/value
				either reg-node/add-interfere node x [
					node/n-interfere: node/n-interfere - 1
				][
					decrement-degree a t
				]
				ny/id: x
				pint: pint + 1
			]
		]
		coalesce?
	]

	get-alias-id: func [
		nodes	[ptr-array!]
		n		[integer!]
		return: [integer!]
		/local
			p pp	[ptr-ptr!]
			node	[reg-node!]
	][
		p: ARRAY_DATA(nodes)
		while [n > 0][
			pp: p + n
			node: as reg-node! pp/value
			either node/id <> n [
				n: node/id
			][
				break
			]
		]
		n
	]

	remove-from-list: func [
		vec		[vector!]
		x		[integer!]
		/local
			p	[int-ptr!]
			y	[integer!]
	][
		p: as int-ptr! vec/data
		loop vec/length [
			if p/value = x [
				y: vector/remove-last-int vec
				if vec/length > 0 [p/value: y]
				exit
			]
			p: p + 1
		]
	]

	add-to-lists: func [
		a		[allocator!]
		n		[integer!]
		/local
			node [reg-node!]
	][
		if n > 0 [
			node: as reg-node! ptr-array/pick a/graph/nodes n
			if all [
				zero? node/n-moves
				node/n-interfere < a/n-colors
			][
				remove-from-list a/freeze-list n
				vector/append-int a/simplify-list n
			]
		]
	]

	decrement-degree: func [
		a		[allocator!]
		n		[integer!]
		/local
			node [reg-node!]
	][
		if n < 0 [exit]
		node: as reg-node! ptr-array/pick a/graph/nodes n
		if all [
			not node/removed?
			node/n-interfere = a/n-colors
		][
			remove-from-list a/spill-list n
			either node/n-moves > 0 [
				vector/append-int a/freeze-list n
			][
				vector/append-int a/simplify-list n
			]
		]
		node/n-interfere: node/n-interfere - 1
	]

	build-graph: func [
		a [allocator!] blk [basic-block!] cur-i [mach-instr!]
		/local
			opcode	[integer!]
			p pp pn	[ptr-ptr!]
			end		[ptr-ptr!]
			pm		[int-ptr!]
			o		[operand!]
			d		[def!]
			u		[use!]
			w		[overwrite!]
			k		[kill!]
			i n		[integer!]
			v		[vreg!]
			vregs	[vector!]
			node	[reg-node!]
			regs	[int-array!]
			pint	[int-ptr!]
			liveness [bit-table!]
			liveout-row dst src weight [integer!]
	][
		liveness: a/liveness
		liveout-row: a/liveout-row
		opcode: MACH_OPCODE(cur-i)
		if opcode = I_BLK_END [
			compute-liveout a blk
			vregs: a/vregs
			p: VECTOR_DATA(vregs)
			i: 0
			loop vregs/length [
				if bit-table/pick liveness liveout-row i [
					add-interference-edges a as vreg! p/value
				]
				i: i + 1
				p: p + 1
			]
			a/cur-weight: int-array/pick a/block-weight blk/info/rpo-num
			exit
		]

		if opcode = I_BLK_BEG [
			bit-table/copy-row liveness blk/info/rpo-num liveout-row
		]
		;if opcode = I_PMOVE [
		;	n: cur-i/num / 2
		;	p: INS_OPERANDS(cur-i)
		;	pp: p + n
		;	loop n [
		;		d: as def! p/value
		;		u: as use! pp/value
		;		dst: d/vreg/idx
		;		src: u/vreg/idx
		;		if all [
		;			zero? d/constraint
		;			zero? u/constraint
		;			dst <> src
		;			reg-graph/add-move 
		;		][
		;			pm: vector/new-item a/moves-list
		;			pm/1: dst
		;			pm/2: src
		;			pm/3: a/cur-weight
		;		]
		;		p: p + 1
		;		pp: pp + 1
		;	]
		;]

		;; 1st pass: mark live def!
		pp: ARRAY_DATA(a/graph/nodes)
		p: INS_OPERANDS(cur-i)
		loop cur-i/num [
			o: as operand! p/value
			switch o/header and FFh [
				OD_DEF [
					d: as def! o
					v: d/vreg
					if null? v [p: p + 1 continue]
					pn: pp + v/idx
					node: as reg-node! pn/value
					if all [
						on-stack? a/reg-set d/constraint
						not node/use?
					][
						p: p + 1
						continue
					]
					mark-live-def a v
				]
				OD_OVERWRITE [
					w: as overwrite! o
					mark-live-def a w/dst
				]
				default [0]		;-- do nothing
			]
			p: p + 1
		]

		;; 2nd pass: process constraints
		p: INS_OPERANDS(cur-i)
		weight: a/cur-weight
		loop cur-i/num [
			o: as operand! p/value
			switch o/header and FFh [
				OD_DEF [
					d: as def! o
					process-constraint a d/vreg d/constraint weight
				]
				OD_OVERWRITE [
					w: as overwrite! o
					process-constraint a w/dst w/constraint weight
				]
				OD_USE [
					u: as use! o
					process-constraint a u/vreg u/constraint weight
				]
				default [0]		;-- do nothing
			]
			p: p + 1
		]

		;; 3rd pass: free defs, mark live use!
		p: INS_OPERANDS(cur-i)
		end: p + cur-i/num
		loop cur-i/num [
			o: as operand! p/value
			switch o/header and FFh [
				OD_DEF [
					d: as def! o
					v: d/vreg
					if null? v [p: p + 1 continue]
					pn: pp + v/idx
					node: as reg-node! pn/value
					if all [
						on-stack? a/reg-set d/constraint
						not node/use?
					][
						p: p + 1
						continue
					]
					mark-dead-def a v
					if opcode = I_RELOAD [break]
				]
				OD_KILL [
					k: as kill! o
					pn: p + 1
					o: as operand! pn/value
					either all [
						pn < end
						o/header and FFh = OD_LIVEPOINT
					][
						bit-table/clear-row liveness liveout-row
					][
						regs: as int-array! ptr-array/pick a/reg-set/regs k/constraint
						pint: as int-ptr! regs + 1
						loop regs/length [
							add-interference-edges-reg a pint/value null
							pint: pint + 1
						]
					]
				]
				OD_OVERWRITE [
					w: as overwrite! o
					mark-dead-def a w/dst
					mark-live-use a w/src
				]
				OD_USE [
					u: as use! o
					v: u/vreg
					if any [
						null? v
						on-stack? a/reg-set u/constraint
					][
						p: p + 1
						continue
					]
					mark-live-use a v
				]
				default [0]		;-- do nothing
			]
			p: p + 1
		]

		;; free uses
		p: INS_OPERANDS(cur-i)
		loop cur-i/num [
			o: as operand! p/value
			switch o/header and FFh [
				OD_OVERWRITE [
					w: as overwrite! o
					v: w/src
					if v/reload-from <> null [
						bit-table/clear liveness liveout-row v/idx
					]
				]
				OD_USE [
					u: as use! o
					v: u/vreg
					if all [
						v <> null
						v/reload-from <> null
					][
						bit-table/clear liveness liveout-row v/idx
					]
				]
				default [0]		;-- do nothing
			]
			p: p + 1
		]
	]

	compare-cb: func [[cdecl] a [int-ptr!] b [int-ptr!] return: [integer!]][
		a/value - b/value
	]

	compare-moves: func [[cdecl] a [int-ptr!] b [int-ptr!] return: [integer!]][
		;; sort moves-list in descending order
		b/3 - a/3
	]

	process-constraint: func [
		a			[allocator!]
		vreg		[vreg!]
		constraint	[integer!]
		weight		[integer!]
		/local
			rset	[reg-set!]
			cset	[int-array!]
			regs	[int-array!]
			p pp	[int-ptr!]
			reg i j	[integer!]
			n		[integer!]
			node	[reg-node!]
			nodes	[ptr-array!]
	][
		rset: a/reg-set
		if any [null? vreg zero? constraint on-stack? rset constraint][exit]
		either is-reg? rset constraint [
			add-interference-edges-reg a constraint vreg
		][
			nodes: a/graph/nodes
			node: as reg-node! ptr-array/pick nodes vreg/idx
			cset: int-array/copy as int-array! ptr-array/pick rset/regs constraint
			qsort as byte-ptr! cset + 1 cset/length 4 :compare-cb
			regs: as int-array! ptr-array/pick rset/regs vreg/reg-class
			p: as int-ptr! regs + 1
			pp: as int-ptr! cset + 1
			i: 1 j: 1
			n: cset/length
			loop regs/length - 1 [
				reg: p/i
				either all [
					j <= n
					reg = pp/j
				][
					j: j + 1
				][
					reg-node/add-interfere node 0 - reg
				]
				i: i + 1
			]
		]
	]

	mark-live-def: func [
		a			[allocator!]
		vreg		[vreg!]
		/local
			p		[ptr-ptr!]
			n		[reg-node!]
	][
		bit-table/set a/liveness a/liveout-row vreg/idx
		add-interference-edges a vreg
		p: ARRAY_DATA(a/graph/nodes) + vreg/idx
		n: as reg-node! p/value
		n/color?: yes
	]

	mark-dead-def: func [
		a			[allocator!]
		vreg		[vreg!]
		/local
			p		[ptr-ptr!]
			n		[reg-node!]
	][
		bit-table/set a/liveness a/liveout-row vreg/idx
		p: ARRAY_DATA(a/graph/nodes) + vreg/idx
		n: as reg-node! p/value
		n/spill-cost: n/spill-cost + a/cur-weight
	]

	mark-live-use: func [
		a			[allocator!]
		vreg		[vreg!]
		/local
			p		[ptr-ptr!]
			n		[reg-node!]
	][
		bit-table/set a/liveness a/liveout-row vreg/idx
		add-interference-edges a vreg
		p: ARRAY_DATA(a/graph/nodes) + vreg/idx
		n: as reg-node! p/value
		n/spill-cost: n/spill-cost + a/cur-weight
		n/use?: yes
	]

	add-interference-edges-reg: func [
		a			[allocator!]
		reg			[integer!]
		filter		[vreg!]
		/local
			len		[integer!]
			i		[integer!]
			p pn	[ptr-ptr!]
	][
		len: a/vregs/length
		pn: ARRAY_DATA(a/graph/nodes)
		i: 0
		while [i < len][
			if all [
				any [null? filter i <> filter/idx]
				bit-table/pick a/liveness a/liveout-row i
			][
				p: pn + i
				reg-node/add-interfere as reg-node! p/value 0 - reg
			]
			i: i + 1
		]
	]

	add-interference-edges: func [
		a			[allocator!]
		vreg		[vreg!]
		/local
			g		[reg-graph!]
			pn p	[ptr-ptr!]
			p-old	[int-ptr!]
			node	[reg-node!]
			len 	[integer!]
			n-vregs	[integer!]
			i ii j	[integer!]
			idx		[integer!]
			liveness [bit-table!]
			interfere old [vector!]
			liveout-row n-interfere [integer!]
	][
		g: a/graph
		pn: ARRAY_DATA(g/nodes)
		idx: vreg/idx
		p: pn + idx
		node: as reg-node! p/value

		old: node/interfere
		p-old: as int-ptr! old/data

		interfere: vector/make size? integer! 1
		node/interfere: interfere
		i: 0
		ii: i + 1
		len: old/length
		while [
			all [
				i < len
				p-old/ii < 0
			]
		][
			vector/append-int interfere p-old/ii
			i: ii
			ii: i + 1
		]

		n-interfere: node/n-interfere
		liveness: a/liveness
		liveout-row: a/liveout-row
		j: 0
		n-vregs: a/vregs/length
		while [
			all [
				i < len
				j < n-vregs
			]
		][
			either p-old/ii = j [
				vector/append-int interfere p-old/ii
				i: ii
				ii: i + 1
			][
				if all [
					j <> idx
					bit-table/pick liveness liveout-row j
				][
					vector/append-int interfere j
					n-interfere: n-interfere + 1
					p: pn + j
					reg-node/add-interfere as reg-node! p/value idx
				]
			]
			j: j + 1
		]

		while [j < n-vregs][
			if all [
				bit-table/pick liveness liveout-row j
				j <> idx
			][
				vector/append-int interfere j
				n-interfere: n-interfere + 1
				p: pn + j
				reg-node/add-interfere as reg-node! p/value idx
			]
			j: j + 1
		]
		node/n-interfere: n-interfere
	]

	compute-liveout: func [
		a			[allocator!]
		blk			[basic-block!]
		/local
			liveness	[bit-table!]
			liveout-row [integer!]
			e			[cf-edge!]
			p			[ptr-ptr!]
			succs		[ptr-array!]
	][
		liveness: a/liveness
		liveout-row: a/liveout-row
		bit-table/clear-row liveness liveout-row

		succs: block-successors blk
		p: ARRAY_DATA(succs)
		loop succs/length [
			e: as cf-edge! p/value
			bit-table/or-rows liveness liveout-row e/dst/info/rpo-num
			p: p + 1
		]
		bit-table/and-rows liveness liveout-row a/mask-row
	]

	compute-block-weight: func [
		weights		[int-array!]
		weight		[integer!]
		blks		[vector!]
		start		[integer!]
		end			[integer!]
		return:		[integer!]
		/local
			p pp	[ptr-ptr!]
			pint pw	[int-ptr!]
			i		[integer!]
			info	[block-info!]
	][
		p: VECTOR_DATA(blks)
		pint: as int-ptr! ARRAY_DATA(weights)
		i: start
		while [i < end][
			pp: p + i
			info: as block-info! pp/value
			pw: pint + i
			either info/loop-info <> null [
				weight: weight * 10
				pw/value: weight
				i: compute-block-weight weights weight blks i + 1 info/loop-info/end
			][
				pw/value: weight
			]
			i: i + 1
		]
		end - 1
	]

	alloc-after-coloring: func [
		a [allocator!] blk [basic-block!] cur-i [mach-instr!]
	][
		
	]

	preprocess: func [
		a [allocator!] blk [basic-block!] cur-i [mach-instr!]
		/local
			p	[ptr-ptr!]
			o	[operand!]
			u	[use!]
			w	[overwrite!]
			k	[kill!]
			c	[integer!]
			v	[vreg!]
			arg	[move-arg! value]
	][
		if MACH_OPCODE(cur-i) = I_BLK_BEG [
			reload-const a cur-i/next
		]
		p: INS_OPERANDS(cur-i)
		loop cur-i/num [
			o: as operand! p/value
			switch o/header and FFh [
				OD_USE [
					u: as use! o
					v: u/vreg
					c: u/constraint
					if on-stack? a/reg-set c [
						arg/src-v: v
						arg/src-reg: 0
						arg/dst-reg: c
						arg/reg-cls: v/reg-class
						either vreg-const?(v) [
							arg/dst-v: v
							insert-move-imm a/cg :arg cur-i
						][
							arg/dst-v: null
							insert-move-loc a/cg :arg cur-i
						]
					]
				]
				OD_OVERWRITE [
					w: as overwrite! o
					v: w/src
					if vreg-const?(v) [
						bit-table/set a/liveness a/liveout-row v/idx
					]
				]
				OD_KILL [reload-const a cur-i/next]
				default [0]		;-- do nothing
			]
			p: p + 1
		]
	]

	reload-const: func [
		a		[allocator!]
		next-i	[mach-instr!]
		/local
			vregs [vector!] liveness [bit-table!] out-row m-row i n [integer!]
			p [ptr-ptr!] args [move-arg! value]
	][
		vregs: a/vregs
		p: VECTOR_DATA(vregs)
		liveness: a/liveness
		out-row: a/liveout-row
		m-row: a/mask-row
		i: 0
		n: vregs/length
		while [i < n][
			if bit-table/pick liveness out-row i [
				args/dst-v: as vreg! p/value
				args/src-v: args/dst-v
				args/dst-reg: 0
				backend/insert-reload a/cg args next-i
				bit-table/clear liveness m-row  i
			]
			p: p + 1
			i: i + 1
		]
		bit-table/clear-row liveness out-row
	]

	reset: func [
		a		[allocator!]
		blks	[vector!]
		/local
			s	[statistic!]
			p	[ptr-ptr!]
	][
		s: as statistic! :a/statistic
		s/n-vars: a/vregs/length
		s/n-iters: 0
		s/n-stores: 0
		s/n-reloads: 0
		a/blk-reloads: ptr-array/make blks/length
		p: ARRAY_DATA(a/blk-reloads)
		loop blks/length [
			p/value: as int-ptr! vector/make size? vreg! 4
			p: p + 1
		]
		init-reg-state as reg-state! :a/reg-state a/cg
		a/reg-usage: int-array/make a/cg/reg-set/n-regs + 1
	]

	restore-args!: alias struct! [
		cg			[codegen!]
		row			[integer!]
		next-i		[mach-instr!]
		block		[basic-block!]
		succs		[ptr-array!]
	]

	insert-restore-idx: func [
		idx			[integer!]
		args		[restore-args!]
		/local
			m		[move-arg! value]
			cg		[codegen!]
			vregs	[vector!]
			vreg	[vreg!]
			p		[ptr-ptr!]
	][
		cg: args/cg
		vregs: cg/vregs
		p: VECTOR_DATA(vregs)
		p: p + idx
		vreg: as vreg! p/value
		m/dst-v: vreg
		m/src-v: null
		m/dst-reg: 0
		m/src-reg: vreg/spill
		insert-restore cg :m args/next-i
		bit-table/clear cg/liveness args/block/info/rpo-num idx
		unless succ-block? args/block args/succs [
			bit-table/clear cg/liveness args/row idx
		]
	]

	succ-block?: func [
		blk		[basic-block!]
		succs	[ptr-array!]
		return: [logic!]
		/local
			p	[ptr-ptr!]
			e	[cf-edge!]
	][
		p: ARRAY_DATA(succs)
		loop succs/length [
			e: as cf-edge! p/value
			if e/dst = blk [return true]
			p: p + 1
		]
		false
	]

	do-spill: func [
		a		[allocator!]
		/local
			spiller		[spiller! value]
			lvps		[vector!]
			liveness	[bit-table!]
			p pp p2		[ptr-ptr!]
			blocks		[vector!]
			loops		[vector!]
			instrs		[vector!]
			v			[vreg!]
			blk-len		[integer!]
			cg			[codegen!]
			frame		[frame!]
			info child	[block-info!]
			blk			[basic-block!]
			l			[label!]
			rpo			[rpo!]
			u			[use!]
			w			[overwrite!]
			o			[operand!]
			e			[cf-edge!]
			lp			[livepoint!]
			loop-info	[loop-info!]
			succs		[ptr-array!]
			args		[restore-args! value]
			cur-i next-i ins [mach-instr!]
			save-row tmp-row live-row cur-row n-slots n-vregs [integer!]
			pass-start reload-start kill-row opcode i row [integer!]
	][
		cg: a/cg
		lvps: cg/livepoints
		if zero? VECTOR_SIZE?(lvps) [exit]

		rpo: cg/rpo
		blocks: cg/blocks
		frame: cg/frame
		liveness: a/liveness
		spiller/cg: cg
		spiller/blocks: blocks
		spiller/liveness: liveness

		i: liveness/rows
		bit-table/grow-row liveness i + 3
		save-row: i
		live-row: i + 1
		tmp-row: i + 2

		bit-table/clear-row liveness live-row

		blk-len: blocks/length
		p: VECTOR_DATA(lvps)
		loop VECTOR_SIZE?(lvps) [
			p: p + 2
			lp: as livepoint! p/value
			bit-table/or-rows liveness live-row blk-len + lp/index
			p: p + 1
		]

		n-vregs: a/vregs/length
		n-slots: 0
		i: 0
		p: VECTOR_DATA(a/vregs)
		while [i < n-vregs][
			if bit-table/pick liveness live-row i [
				pp: p + i
				v: as vreg! pp/value
				if vreg-not-const?(v) [
					alloc-slot frame v
					n-slots: n-slots + 1
					i: i + 1
					continue
				]
			]
			bit-table/clear liveness live-row i
			i: i + 1
		]
		bit-table/copy-row liveness save-row live-row
		if zero? n-slots [exit]

		pass-start: liveness/rows
		reload-start: pass-start + blk-len
		bit-table/grow-row liveness pass-start + (blk-len * 2)

		spiller/live-row: live-row
		spiller/tmp-row: tmp-row
		spiller/save-row: save-row
		spiller/pass-start: pass-start
		spiller/reload-start: reload-start
		instrs: cg/instrs
		cur-i: cg/first-i
		info: as block-info! vector/pick-ptr blocks 0
		blk: info/block
		while [cur-i <> null][
			next-i: cur-i/next
			opcode: MACH_OPCODE(cur-i)
			if opcode = I_BLK_BEG [
				p: INS_OPERANDS(cur-i)
				l: as label! p/value
				blk: l/block
				info: blk/info
				vector/poke-ptr instrs info/rpo-num as int-ptr! cur-i
				kills-pred tmp-row blk spiller
				cur-row: pass-start + info/rpo-num
			]
			if opcode = I_BLK_END [
				bit-table/or-rows liveness cur-row tmp-row
				loops: rpo/loops
				if loops <> null [
					p: VECTOR_DATA(loops)
					loop loops/length [
						loop-info: as loop-info! p/value
						i: loop-info/end - 1
						if info/rpo-num = i [
							spiller/cur-row: cur-row
							process-loop loop-info cur-i spiller
							cur-row: spiller/cur-row
							break
						]
						p: p + 1
					]
				]
			]
			p: INS_OPERANDS(cur-i)
			p: p + cur-i/num - 1
			loop cur-i/num [
				o: as operand! p/value
				switch o/header and FFh [
					OD_USE [
						u: as use! o
						v: u/vreg
						if v <> null [mark-restore info cur-i v spiller]
					]
					OD_OVERWRITE [
						w: as overwrite! o
						mark-restore info cur-i w/src spiller
					]
					OD_LIVEPOINT [
						lp: as livepoint! o
						bit-table/or-rows liveness cur-row blk-len + lp/index
						bit-table/and-rows liveness cur-row live-row
					]
					default [0]		;-- do nothing
				]
			]
			cur-i: next-i
		]

		p: VECTOR_DATA(blocks)
		p: p + blk-len - 1
		loop blk-len [
			info: as block-info! p/value
			blk: info/block
			cur-row: reload-start + info/rpo-num
			succs: block-successors blk
			kill-row: kills-succ blk succs spiller
			child: info/dom-child
			if child <> null [
				either any [
					null? child/dom-sibling
					not bit-table/zero-row? liveness kill-row
				][
					pp: VECTOR_DATA(instrs)
					while [child <> null][
						p2: pp + child/rpo-num
						ins: as mach-instr! p2/value
						row: reload-start + child/rpo-num
						args/cg: cg
						args/next-i: ins/next
						args/block: child/block
						args/succs: succs
						args/row: kill-row
						bit-table/apply liveness row as int-ptr! :insert-restore-idx as int-ptr! :args
						child: child/dom-sibling
					]
				][
					bit-table/set-row liveness tmp-row
					pp: ARRAY_DATA(succs)
					loop succs/length [
						e: as cf-edge! pp/value
						bit-table/and-rows liveness tmp-row reload-start + e/dst/info/rpo-num
						pp: pp + 1
					]
					bit-table/or-rows liveness cur-row tmp-row

					bit-table/clear-row liveness tmp-row
					pp: ARRAY_DATA(succs)
					loop succs/length [
						e: as cf-edge! pp/value
						bit-table/or-rows liveness tmp-row reload-start + e/dst/info/rpo-num
						pp: pp + 1
					]

					while [child <> null][
						unless succ-block? child/block succs [
							bit-table/and-rows liveness tmp-row reload-start + child/rpo-num
							bit-table/or-rows liveness cur-row tmp-row
							break
						]
						child: child/dom-sibling
					]

					child: info/dom-child
					while [child <> null][
						pp: VECTOR_DATA(instrs) + child/rpo-num
						ins: as mach-instr! pp/value
						bit-table/copy-row liveness tmp-row cur-row
						bit-table/flip-row liveness tmp-row
						bit-table/and-rows liveness tmp-row reload-start + child/rpo-num
						args/cg: cg
						args/next-i: ins/next
						args/block: child/block
						args/succs: succs
						args/row: kill-row
						bit-table/apply liveness tmp-row as int-ptr! :insert-restore-idx as int-ptr! :args
						child: child/dom-sibling
					]
					child: info/dom-child
				]
			]
			p: p - 1
		]
	]

	process-loop: func [
		loop-info	[loop-info!]
		end-i		[mach-instr!]
		spiller		[spiller!]
		/local
			instrs	[vector!]
			p		[ptr-ptr!]
			l		[label!]
			v		[vreg!]
			o		[operand!]
			d		[def!]
			u		[use!]
			w		[overwrite!]
			lp		[livepoint!]
			blk		[basic-block!]
			info	[block-info!]
			cur-i	[mach-instr!]
			next-i	[mach-instr!]
			cur-row [integer!]
			lvn		[bit-table!]
	][
		instrs: spiller/cg/instrs
		lvn: spiller/liveness
		cur-row: spiller/cur-row
		p: VECTOR_DATA(instrs)
		p: p + loop-info/start
		cur-i: as mach-instr! p/value
		while [cur-i <> end-i][
			next-i: cur-i/next
			if MACH_OPCODE(cur-i) = I_BLK_BEG [
				p: INS_OPERANDS(cur-i)
				l: as label! p/value
				blk: l/block
				info: blk/info
				cur-row: spiller/pass-start + info/rpo-num
				spiller/cur-row: cur-row
				kills-pred cur-row blk spiller
			]
			p: INS_OPERANDS(cur-i)
			p: p + cur-i/num - 1
			loop cur-i/num [
				o: as operand! p/value
				switch o/header and FFh [
					OD_DEF [
						d: as def! o
						v: d/vreg
						if v <> null [bit-table/clear lvn cur-row v/idx]
					]
					OD_USE [
						u: as use! o
						v: u/vreg
						if v <> null [mark-restore-loop info cur-i v spiller]
					]
					OD_OVERWRITE [
						w: as overwrite! o
						mark-restore-loop info cur-i w/src spiller
					]
					OD_LIVEPOINT [
						lp: as livepoint! o
						bit-table/or-rows lvn cur-row spiller/blocks/length + lp/index
						bit-table/and-rows lvn cur-row spiller/live-row
					]
					default [0]		;-- do nothing
				]
			]
			cur-i: next-i
		]
	]

	mark-restore-loop: func [
		info			[block-info!]
		cur-i			[mach-instr!]
		vreg			[vreg!]
		spiller			[spiller!]
		/local
			cur-row		[integer!]
			liveness	[bit-table!]
			idx			[integer!]
	][
		cur-row: spiller/cur-row
		liveness: spiller/liveness
		idx: vreg/idx
		if bit-table/pick liveness cur-row idx [
			bit-table/set liveness spiller/reload-start + info/rpo-num idx
			bit-table/clear liveness cur-row idx
		]
	]

	mark-restore: func [
		info			[block-info!]
		cur-i			[mach-instr!]
		vreg			[vreg!]
		spiller			[spiller!]
		/local
			cur-row		[integer!]
			tmp-row		[integer!]
			liveness	[bit-table!]
			idx			[integer!]
			args		[move-arg! value]
	][
		cur-row: spiller/cur-row
		tmp-row: spiller/tmp-row
		liveness: spiller/liveness
		idx: vreg/idx
		either bit-table/pick liveness cur-row idx [
			args/dst-v: vreg
			args/src-v: null
			args/dst-reg: 0
			args/src-reg: vreg/spill
			insert-restore spiller/cg :args cur-i
			bit-table/clear liveness tmp-row idx
			bit-table/clear liveness cur-row idx
		][
			if bit-table/pick liveness tmp-row idx [
				bit-table/set liveness spiller/reload-start + info/rpo-num idx
				bit-table/clear liveness tmp-row idx
			]
		]
	]

	kills-pred: func [
		dst-row			[integer!]
		block			[basic-block!]
		spiller			[spiller!]
		/local
			liveness	[bit-table!]
			e			[cf-edge!]
			p			[ptr-ptr!]
			preds		[ptr-array!]
			blk			[basic-block!]
	][
		liveness: spiller/liveness
		bit-table/clear-row liveness dst-row
		preds: block/preds
		p: ARRAY_DATA(preds)
		loop preds/length [
			e: as cf-edge! p/value
			blk: as basic-block! e/src/next
			bit-table/or-rows liveness dst-row spiller/pass-start + blk/info/rpo-num
			p: p + 1
		]
		bit-table/and-rows liveness dst-row spiller/live-row
	]

	kills-succ: func [
		block		[basic-block!]
		succs		[ptr-array!]
		spiller		[spiller!]
		return:		[integer!]
		/local
			p		 [ptr-ptr!]
			liveness [bit-table!]
			lps		 [vector!]
			lp		 [livepoint!]
			e		 [cf-edge!]
			blk		 [basic-block!]
			n-blks	 [integer!]
			kill-row [integer!]
			p-start	 [integer!]
	][
		p-start: spiller/pass-start
		liveness: spiller/liveness
		n-blks: spiller/blocks/length
		kill-row: p-start + block/info/rpo-num
		bit-table/clear-row liveness kill-row
		lps: spiller/livepoints
		p: VECTOR_DATA(lps)
		loop VECTOR_SIZE?(lps) [
			either block = as basic-block! p/value [
				p: p + 2
				lp: as livepoint! p/value
				bit-table/or-rows liveness kill-row n-blks + lp/index
				p: p + 1
			][
				p: p + 3
			]
		]
		p: ARRAY_DATA(succs)
		loop succs/length [
			e: as cf-edge! p/value
			blk: e/dst
			bit-table/or-rows liveness kill-row p-start + blk/info/rpo-num
			p: p + 1
		]
		bit-table/and-rows liveness kill-row spiller/live-row
		kill-row
	]
]