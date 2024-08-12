Red/System [
	File: 	 %ir-printer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

ir-printer: context [
	blocks: as vector! 0

	indent: func [
		i	[integer!]
	][
		loop i [prin "    "]
	]

	print-block: func [
		bb			[basic-block!]
	][
		indent 1
		print-line ["block " bb]
	]
	
	print-blocks: func [
		start-bb	[basic-block!]
		/local
			p		[ptr-ptr!]
	][
		ir-graph/bfs-blocks start-bb blocks
		p: as ptr-ptr! blocks/data
		loop blocks/length [
			print-block as basic-block! p/value
			p: p + 1
		]
	]

	print-graph: func [
		ir		[ir-fn!]
	][
		if null? blocks [blocks: vector/make size? int-ptr! 100]
		
		print-line "SSA IR:"
		print-blocks ir/start-bb
	]
]