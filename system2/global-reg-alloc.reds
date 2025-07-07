Red/System [
	File: 	 %simple-reg-alloc.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
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
		move-idx	[int-array!]
		reg-moves	[vector!]		;-- vector<move-state!>
		saves		[vector!]		;-- vector<move-state!>
		reloads		[vector!]		;-- vector<vreg-reg!>	
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
		live-row		[integer!]
		mask-row		[integer!]
		fn				[ir-fn!]
		coloring		[int-array!]
		n-colors		[integer!]
		simplify-list	[vector!]
		freeze-list		[vector!]
		spill-list		[vector!]
		select-stack	[vector!]
		moves-list		[vector!]
		spill?			[logic!]
		block-weight	[int-array!]
		cur-weight		[integer!]
		old-var-cnt		[integer!]
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
	][
		a: xmalloc(allocator!)
		a/vregs: cg/vregs
		a/reg-set: cg/reg-set
		lv: cg/liveness
		a/liveness: lv
		a/live-row: lv/rows
		a/mask-row: lv/rows + 1
		bit-table/grow-row lv a/mask-row
		bit-table/set-row lv a/mask-row
		reset a

		compute-dominators cg/blocks
		process-instrs-backward a cg/blocks as int-ptr! :preprocess
		do-spill a
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
						bit-table/set a/liveness a/live-row v/idx
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
			vregs [vector!] liveness [bit-table!] row m-row i n [integer!]
			p [ptr-ptr!] args [move-arg! value]
	][
		vregs: a/vregs
		p: VECTOR_DATA(vregs)
		liveness: a/liveness
		row: a/live-row
		m-row: a/mask-row
		i: 0
		n: vregs/length
		while [i < n][
			if bit-table/pick liveness row i [
				args/dst-v: as vreg! p/value
				args/src-v: args/dst-v
				args/dst-reg: 0
				insert-reload a/cg args next-i
				bit-table/clear liveness m-row  i
			]
			p: p + 1
			i: i + 1
		]
		bit-table/clear-row liveness row
	]

	reset: func [
		a		[allocator!]
		/local
			s	[statistic!]
	][
		s: as statistic! :a/statistic
		s/n-vars: a/vregs/length
		s/n-iters: 0
		s/n-stores: 0
		s/n-reloads: 0
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