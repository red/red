REBOL [
	Title:   "Red/System ARM64 Mach-O format emitter"
	File:    %Mach-O-ARM64.r
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [
	defs: context [
		extensions: [
			exe %""
			obj %.o
			lib %.a
			dll %.dylib
		]
		page-size: 16384
	]
	pointer: make-struct [value [uint64]] none

	append-u32: func [out [binary!] value [integer! char!]][
		append out to-bin32 value
	]

	append-u16: func [out [binary!] value [integer! char!]][
		append out to-bin16 value
	]

	append-u8: func [out [binary!] value [integer! char!]][
		append out to-bin8 value
	]

	append-u64: func [out [binary!] value [integer! char! block!]][
		append out to-bin64 value
	]

	append-name: func [out [binary!] name [string!]][
		append out to binary! name
		if 16 < length? name [make error! [script invalid-arg name]]
		insert/dup tail out #{00} 16 - length? name
	]

	append-command-string: func [out [binary!] value [string!] size [integer!] /local start][
		start: length? out
		append out to binary! value
		append out #{00}
		insert/dup tail out #{00} size - (length? out) + start
	]

	align-buffer: func [out [binary!] alignment [integer!] /local rem][
		unless zero? rem: (length? out) // alignment [
			insert/dup tail out #{00} alignment - rem
		]
	]

	build-segment: func [
		name [string!]
		vmaddr vmsize fileoff filesize [integer! block!]
		max-prot init-prot section-count flags [integer!]
		/local out
	][
		out: make binary! 72
		append-u32 out 25                                      ; LC_SEGMENT_64
		append-u32 out 72 + (80 * section-count)
		append-name out name
		append-u64 out vmaddr
		append-u64 out vmsize
		append-u64 out fileoff
		append-u64 out filesize
		append-u32 out max-prot
		append-u32 out init-prot
		append-u32 out section-count
		append-u32 out flags
		out
	]

	build-section: func [
		name segment [string!]
		address size [integer! block!]
		offset alignment flags reserved1 reserved2 [integer!]
		/local out
	][
		out: make binary! 80
		append-name out name
		append-name out segment
		append-u64 out address
		append-u64 out size
		append-u32 out offset
		append-u32 out alignment
		append-u32 out 0                                      ; reloff
		append-u32 out 0                                      ; nreloc
		append-u32 out flags
		append-u32 out reserved1
		append-u32 out reserved2
		append-u32 out 0                                      ; reserved3
		out
	]

	append-uleb128: func [out [binary!] value [integer!] /local byte][
		while [value >= 128][
			byte: ((value and 127) or 128)
			append-u8 out byte
			value: shift/logical value 7
		]
		append-u8 out value
	]

	normalize-library: func [name /local value][
		value: form name
		case [
			find ["libc.dylib" "libm.dylib" "libpthread.dylib" "libSystem.dylib"] value [
				"/usr/lib/libSystem.B.dylib"
			]
			value/1 = #"/" [value]
			find value ".framework/" [value]
			true [rejoin ["@loader_path/" value]]
		]
	]

	objc-runtime-symbol?: func [symbol /local name][
		name: form symbol
		to logic! any [
			find/match name "objc_"
			find/match name "sel_"
			find/match name "class_"
			find/match name "object_"
			find/match name "protocol_"
			find/match name "method_"
			find/match name "ivar_"
		]
	]

	collect-imports: func [job [object!] /local libraries imports library symbol-library ordinal index][
		libraries: reduce ["/usr/lib/libSystem.B.dylib"]
		imports: make block! 64
		foreach [name uses] job/sections/import/3 [
			library: normalize-library name
			foreach [symbol refs] uses [
				symbol-library: either objc-runtime-symbol? symbol [
					"/usr/lib/libobjc.A.dylib"
				][library]
				unless find libraries symbol-library [append libraries symbol-library]
				ordinal: index? find libraries symbol-library
				index: length? imports
				append/only imports reduce [symbol ordinal refs index index 0]
			]
		]
		reduce [libraries imports]
	]

	import-functions: func [imports [block!] /local out index][
		out: make block! length? imports
		index: 0
		foreach record imports [
			unless issue? record/1 [
				record/6: index
				append/only out record
				index: index + 1
			]
		]
		out
	]

	build-dylib: func [name [string!] /id /local out size][
		size: round/to/ceiling (24 + 1 + length? name) 8
		out: make binary! size
		append-u32 out either id [13][12]                     ; LC_ID_DYLIB / LC_LOAD_DYLIB
		append-u32 out size
		append-u32 out 24
		append-u32 out 2
		append-u32 out 0
		append-u32 out 0
		append-command-string out name size - 24
		out
	]

	build-dyld-info: func [
		rebase-offset rebase-size bind-offset bind-size
		export-offset export-size [integer!]
		/local out
	][
		out: make binary! 48
		append-u32 out to integer! #{80000022}                ; LC_DYLD_INFO_ONLY
		append-u32 out 48
		append-u32 out rebase-offset
		append-u32 out rebase-size
		append-u32 out bind-offset
		append-u32 out bind-size
		repeat i 4 [append-u32 out 0]                          ; weak/lazy offsets and sizes
		append-u32 out export-offset
		append-u32 out export-size
		out
	]

	build-symtab-command: func [
		symbol-offset symbol-count string-offset string-size [integer!]
		/local out
	][
		out: make binary! 24
		append-u32 out 2                                      ; LC_SYMTAB
		append-u32 out 24
		append-u32 out symbol-offset
		append-u32 out symbol-count
		append-u32 out string-offset
		append-u32 out string-size
		out
	]

	build-dysymtab-command: func [
		export-count undefined-count indirect-offset indirect-count [integer!]
		/local out
	][
		out: make binary! 80
		append-u32 out 11                                     ; LC_DYSYMTAB
		append-u32 out 80
		append-u32 out 0                                      ; ilocalsym
		append-u32 out 0                                      ; nlocalsym
		append-u32 out 0                                      ; iextdefsym
		append-u32 out export-count
		append-u32 out export-count                           ; iundefsym
		append-u32 out undefined-count
		repeat i 6 [append-u32 out 0]
		append-u32 out indirect-offset
		append-u32 out indirect-count
		repeat i 4 [append-u32 out 0]
		out
	]

	collect-exports: func [job [object!] /local out section symbol external spec][
		out: make block! 16
		if section: select job/sections 'export [
			foreach [symbol external] section/3 [
				if spec: select job/symbols symbol [
					append/only out reduce [external spec 0 0]
				]
			]
		]
		out
	]

	build-symbol-tables: func [
		imports functions exports [block!]
		data-section-index [integer!]
		/local symbols strings indirect name spec
	][
		symbols: make binary! 16 * ((length? exports) + length? imports)
		strings: copy #{00000000}
		foreach record exports [
			append-u32 symbols length? strings
			append-u8 symbols 15                                 ; N_SECT | N_EXT
			spec: record/2
			append-u8 symbols either spec/1 = 'global [data-section-index][1]
			append-u16 symbols 0
			append-u64 symbols reduce [record/4 1]
			name: rejoin ["_" form record/1]
			append strings to binary! name
			append strings #{00}
		]
		foreach record imports [
			append-u32 symbols length? strings
			append-u8 symbols 1                                  ; N_UNDF | N_EXT
			append-u8 symbols 0
			append-u16 symbols record/2 * 256                    ; two-level library ordinal
			append-u64 symbols 0
			name: rejoin ["_" form record/1]
			append strings to binary! name
			append strings #{00}
		]
		align-buffer strings 4
		indirect: make binary! 4 * ((length? functions) + length? imports)
		foreach record functions [append-u32 indirect (length? exports) + record/4]
		foreach record imports [append-u32 indirect (length? exports) + record/4]
		reduce [symbols indirect strings]
	]

	make-export-node: does [
		make object! [
			terminal: none
			children: make block! 4
			offset: 0
			encoding: make binary! 16
		]
	]

	insert-export-node: func [root [object!] record [block!] /local node child name byte][
		node: root
		name: to binary! rejoin ["_" form record/1]
		foreach byte name [
			unless child: select node/children byte [
				child: make-export-node
				repend node/children [byte child]
			]
			node: child
		]
		if node/terminal [linker/throw-error "duplicate ARM64 Mach-O export"]
		node/terminal: record
	]

	collect-export-nodes: func [node [object!] nodes [block!] /local byte child][
		append/only nodes node
		foreach [byte child] node/children [collect-export-nodes child nodes]
	]

	encode-export-node: func [node [object!] /local out payload record count byte child][
		out: make binary! 32
		either record: node/terminal [
			payload: make binary! 16
			append-uleb128 payload 0                              ; EXPORT_SYMBOL_FLAGS_KIND_REGULAR
			append-uleb128 payload record/3                       ; image-relative address
			append-uleb128 out length? payload
			append out payload
		][
			append-u8 out 0
		]
		count: (length? node/children) / 2
		if count > 255 [linker/throw-error "too many ARM64 Mach-O export trie edges"]
		append-u8 out count
		foreach [byte child] node/children [
			append-u8 out byte
			append-u8 out 0
			append-uleb128 out child/offset
		]
		out
	]

	build-export-trie: func [exports [block!] /local root nodes node record offset out previous pass][
		if empty? exports [return #{}]
		root: make-export-node
		foreach record exports [insert-export-node root record]
		nodes: make block! 32
		collect-export-nodes root nodes
		previous: none
		repeat pass 64 [
			offset: 0
			foreach node nodes [
				node/offset: offset
				offset: offset + length? node/encoding
			]
			out: make binary! offset
			foreach node nodes [
				node/encoding: encode-export-node node
				append out node/encoding
			]
			if all [previous out = previous][return out]
			previous: copy out
		]
		linker/throw-error "ARM64 Mach-O export trie offsets did not converge"
	]

	build-bind-info: func [imports [block!] segment-index got-relative [integer!] /local out name][
		out: make binary! 128
		foreach record imports [
			either record/2 <= 15 [
				append-u8 out 16 or record/2                       ; SET_DYLIB_ORDINAL_IMM
			][
				append-u8 out 32                                   ; SET_DYLIB_ORDINAL_ULEB
				append-uleb128 out record/2
			]
			append-u8 out 64                                    ; SET_SYMBOL_TRAILING_FLAGS_IMM
			name: rejoin ["_" form record/1]
			append out to binary! name
			append out #{00}
			append-u8 out 81                                    ; SET_TYPE_IMM(pointer)
			append-u8 out 112 or segment-index                  ; SET_SEGMENT_AND_OFFSET_ULEB
			append-uleb128 out got-relative + (record/5 * 8)
			append-u8 out 144                                   ; DO_BIND
		]
		append-u8 out 0                                      ; DONE
		out
	]

	build-rebase-info: func [
		data-relocs rodata-relocs [block!]
		segment-index data-relative rodata-relative [integer!]
		/local out
	][
		out: make binary! 64
		append-u8 out 17                                     ; SET_TYPE_IMM(pointer)
		foreach offset data-relocs [
			append-u8 out 32 or segment-index                   ; SET_SEGMENT_AND_OFFSET_ULEB
			append-uleb128 out data-relative + offset
			append-u8 out 81                                    ; DO_REBASE_IMM_TIMES(1)
		]
		foreach offset rodata-relocs [
			append-u8 out 32 or segment-index
			append-uleb128 out rodata-relative + offset
			append-u8 out 81
		]
		append-u8 out 0
		out
	]

	collect-data-relocs: func [job [object!] /local list name spec ref offset][
		list: make block! 100
		foreach [name spec] job/symbols [
			if block? spec/4 [
				foreach ref spec/4 [
					if positive? ref [
						offset: ref - 1
						unless find list offset [append list offset]
					]
				]
			]
		]
		list
	]

	collect-rodata-relocs: func [job [object!] /local list name spec ref offset][
		list: make block! 100
		foreach [name spec] job/symbols [
			if block? spec/4 [
				foreach ref spec/4 [
					if negative? ref [
						offset: (negate ref) - 1
						unless find list offset [append list offset]
					]
				]
			]
		]
		list
	]

	set-preferred-pointer-high: func [buffer [binary!] relocs [block!]][
		foreach offset relocs [change/part at buffer offset + 5 to-bin32 1 4]
	]

	encode-adrp: func [target source reg [integer!] /local pages encoded][
		pages: ((target and -4096) - (source and -4096)) / 4096
		if any [pages < -1048576 pages > 1048575][
			linker/throw-error "ARM64 Mach-O stub ADRP target is out of range"
		]
		encoded: pages and 2097151
		(to integer! #{90000000})
			or ((encoded and 3) * 536870912)
			or ((shift/logical (encoded and 2097148) 2) * 32)
			or reg
	]

	build-stubs: func [functions [block!] stub-offset got-offset [integer!] /local out target source low][
		out: make binary! 12 * length? functions
		foreach record functions [
			target: got-offset + (record/5 * 8)
			source: stub-offset + (record/6 * 12)
			append-u32 out encode-adrp target source 16
			low: target and 4095
			append-u32 out (to integer! #{F9400210}) or (low * 128)
			append-u32 out to integer! #{D61F0200}              ; BR x16
		]
		out
	]

	patch-imports: func [
		imports [block!] code [binary!]
		text-offset stub-offset got-offset [integer!]
		/local target source delta opcode
	][
		foreach record imports [
			target: either issue? record/1 [
				got-offset + (record/5 * 8)
			][stub-offset + (record/6 * 12)]
			foreach ref record/3 [
				either issue? record/1 [
					linker/patch-arm64-page-ref code ref/1
						(text-offset + ref/1 - 1) target ref/2
				][
					source: text-offset + ref - 1
					delta: target - source
					if any [not zero? delta // 4 delta < -134217728 delta > 134217724][
						linker/throw-error "ARM64 Mach-O import branch is out of range"
					]
					opcode: (to integer! #{94000000}) or (((delta / 4) and 67108863))
					change/part at code ref to-bin32 opcode 4
				]
			]
		]
	]

	build-dylinker: func [/local out][
		out: make binary! 32
		append-u32 out 14                                     ; LC_LOAD_DYLINKER
		append-u32 out 32
		append-u32 out 12
		append-command-string out "/usr/lib/dyld" 20
		out
	]

	build-main: func [entry [integer!] /local out][
		out: make binary! 24
		append-u32 out to integer! #{80000028}                ; LC_MAIN | LC_REQ_DYLD
		append-u32 out 24
		append-u64 out entry
		append-u64 out 0
		out
	]

	build-libsystem: func [/local out][
		out: make binary! 56
		append-u32 out 12                                     ; LC_LOAD_DYLIB
		append-u32 out 56
		append-u32 out 24
		append-u32 out 2
		append-u32 out 0
		append-u32 out 0
		append-command-string out "/usr/lib/libSystem.B.dylib" 32
		out
	]

	build-header: func [commands [binary!] count file-type flags [integer!] /local out][
		out: make binary! 32
		append-u32 out to integer! #{FEEDFACF}                ; MH_MAGIC_64
		append-u32 out 16777228                               ; CPU_TYPE_ARM64
		append-u32 out 0                                      ; CPU_SUBTYPE_ARM64_ALL
		append-u32 out file-type
		append-u32 out count
		append-u32 out length? commands
		append-u32 out flags
		append-u32 out 0
		out
	]

	build: func [
		job [object!]
		/local code data rodata commands out text-section-count data-section-count
			text-command-size data-command-size command-size command-count header-size
			text-offset stub-offset text-file-size data-offset got-offset got-size
			data-section-offset init-offset term-offset const-offset data-file-size data-end
			linkedit-offset entry-spec entry-offset import-info libraries imports functions
			exports tables symbols indirect strings stubs bind-info rebase-info export-trie linkedit
			data-relocs rodata-relocs rebase-offset bind-offset symbol-offset
			export-offset indirect-offset string-offset dylib-size id-file id-name id-size linkedit-size
			dll? lifecycle init-spec term-spec data-segment-index data-section-index
			file-type header-flags
	][
		unless find [exe dll] job/type [
			linker/throw-error "ARM64 Mach-O object output is not implemented yet"
		]
		dll?: job/type = 'dll

		code: job/sections/code/2
		data: job/sections/data/2
		rodata: any [attempt [job/sections/rodata/2] #{}]
		import-info: collect-imports job
		libraries: import-info/1
		imports: import-info/2
		functions: import-functions imports
		exports: either dll? [collect-exports job][make block! 0]
		text-section-count: 1 + either empty? functions [0][1]
		data-section-count: 1
		if not empty? imports [data-section-count: data-section-count + 1]
		if dll? [data-section-count: data-section-count + 2]
		if not empty? rodata [data-section-count: data-section-count + 1]
		text-command-size: 72 + (80 * text-section-count)
		data-command-size: 72 + (80 * data-section-count)
		dylib-size: 0
		foreach library libraries [
			dylib-size: dylib-size + round/to/ceiling (24 + 1 + length? library) 8
		]
		id-name: either dll? [
			id-file: copy last split-path job/build-basename
			unless (suffix? id-file) = defs/extensions/dll [append id-file defs/extensions/dll]
			rejoin ["@rpath/" form id-file]
		][""]
		id-size: either dll? [round/to/ceiling (24 + 1 + length? id-name) 8][0]
		command-count: (either dll? [7][9]) + length? libraries
		command-size: text-command-size + data-command-size + 72
			+ 48 + 24 + 80 + dylib-size + either dll? [id-size][128]
		header-size: 32 + command-size
		text-offset: round/to/ceiling (header-size + 64) 16
		stub-offset: round/to/ceiling (text-offset + length? code) 4
		text-file-size: round/to/ceiling
			(stub-offset + (12 * length? functions)) defs/page-size
		data-offset: text-file-size
		got-offset: data-offset
		got-size: 8 * length? imports
		data-section-offset: round/to/ceiling (got-offset + got-size) 8
		data-end: data-section-offset + length? data
		init-offset: term-offset: data-end
		if dll? [
			init-offset: round/to/ceiling data-end 8
			term-offset: init-offset + 8
			data-end: term-offset + 8
		]
		const-offset: either empty? rodata [data-end][
			round/to/ceiling data-end defs/page-size
		]
		data-end: const-offset + length? rodata
		data-file-size: round/to/ceiling (max 1 data-end - data-offset) defs/page-size
		linkedit-offset: data-offset + data-file-size
		entry-offset: text-offset
		unless dll? [
			entry-spec: select job/symbols '***_start
			entry-offset: either entry-spec [text-offset + entry-spec/2 - 1][text-offset]
		]
		foreach record exports [
			record/3: record/4: either record/2/1 = 'global [
				data-section-offset + record/2/2
			][text-offset + record/2/2 - 1]
		]

		linker/resolve-symbol-refs job code data rodata
			text-offset data-section-offset const-offset pointer
		patch-imports imports code text-offset stub-offset got-offset
		linker/set-image-info job 0 text-offset length? code data-section-offset length? data
			const-offset length? rodata
		data-relocs: collect-data-relocs job
		rodata-relocs: collect-rodata-relocs job
		set-preferred-pointer-high data data-relocs
		set-preferred-pointer-high rodata rodata-relocs
		lifecycle: make binary! 16
		if dll? [
			init-spec: select job/symbols '***-dll-entry-point
			term-spec: select job/symbols 'on-unload
			unless all [init-spec term-spec][
				linker/throw-error "missing ARM64 Mach-O dylib lifecycle function"
			]
			append-u64 lifecycle reduce [text-offset + init-spec/2 - 1 1]
			append-u64 lifecycle reduce [text-offset + term-spec/2 - 1 1]
			append data-relocs init-offset - data-section-offset
			append data-relocs term-offset - data-section-offset
		]

		stubs: build-stubs functions stub-offset got-offset
		data-segment-index: either dll? [1][2]
		data-section-index: 2 + either empty? functions [0][1]
		if not empty? imports [data-section-index: data-section-index + 1]
		bind-info: build-bind-info imports data-segment-index 0
		rebase-info: build-rebase-info data-relocs rodata-relocs data-segment-index
			(data-section-offset - data-offset) (const-offset - data-offset)
		export-trie: build-export-trie exports
		tables: build-symbol-tables imports functions exports data-section-index
		symbols: tables/1
		indirect: tables/2
		strings: tables/3
		linkedit: make binary! 1024
		rebase-offset: linkedit-offset
		append linkedit rebase-info
		align-buffer linkedit 8
		bind-offset: linkedit-offset + length? linkedit
		append linkedit bind-info
		align-buffer linkedit 8
		export-offset: either empty? export-trie [0][linkedit-offset + length? linkedit]
		append linkedit export-trie
		align-buffer linkedit 8
		symbol-offset: linkedit-offset + length? linkedit
		append linkedit symbols
		align-buffer linkedit 4
		indirect-offset: linkedit-offset + length? linkedit
		append linkedit indirect
		align-buffer linkedit 4
		string-offset: linkedit-offset + length? linkedit
		append linkedit strings
		linkedit-size: length? linkedit

		commands: make binary! command-size
		unless dll? [append commands build-segment "__PAGEZERO" 0 reduce [0 1] 0 0 0 0 0 0]
		append commands build-segment "__TEXT" reduce [0 1] text-file-size 0 text-file-size
			5 5 text-section-count 0
		append commands build-section "__text" "__TEXT" reduce [text-offset 1]
			length? code text-offset 2 to integer! #{80000400} 0 0
		unless empty? functions [
			append commands build-section "__stubs" "__TEXT" reduce [stub-offset 1]
				length? stubs stub-offset 2 to integer! #{80000408} 0 12
		]
		append commands build-segment "__DATA" reduce [data-offset 1] data-file-size
			data-offset data-file-size 3 3 data-section-count 0
		unless empty? imports [
			append commands build-section "__got" "__DATA" reduce [got-offset 1]
				got-size got-offset 3 6 length? functions 0
		]
		append commands build-section "__data" "__DATA" reduce [data-section-offset 1]
			length? data data-section-offset 3 0 0 0
		if dll? [
			append commands build-section "__mod_init_func" "__DATA" reduce [init-offset 1]
				8 init-offset 3 9 0 0
			append commands build-section "__mod_term_func" "__DATA" reduce [term-offset 1]
				8 term-offset 3 10 0 0
		]
		unless empty? rodata [
			append commands build-section "__const" "__DATA" reduce [const-offset 1]
				length? rodata const-offset 14 0 0 0
		]
		append commands build-segment "__LINKEDIT" reduce [linkedit-offset 1]
			(round/to/ceiling linkedit-size defs/page-size) linkedit-offset linkedit-size 1 1 0 0
		append commands build-dyld-info rebase-offset length? rebase-info
			bind-offset length? bind-info export-offset length? export-trie
		append commands build-symtab-command symbol-offset ((length? exports) + length? imports)
			string-offset length? strings
		append commands build-dysymtab-command length? exports length? imports indirect-offset
			((length? functions) + length? imports)
		either dll? [
			append commands build-dylib/id id-name
		][
			append commands build-dylinker
			append commands build-main entry-offset
		]
		foreach library libraries [append commands build-dylib library]
		if (length? commands) <> command-size [
			linker/throw-error "invalid ARM64 Mach-O load command layout"
		]
		if job/show-func-map? [linker/show-funcs-map job text-offset]

		out: job/buffer
		file-type: either dll? [6][2]
		header-flags: either dll? [133][to integer! #{00200085}]
		append out build-header commands command-count file-type header-flags
		append out commands
		insert/dup tail out #{00} text-offset - length? out
		if (length? out) <> text-offset [
			linker/throw-error "invalid ARM64 Mach-O text layout"
		]
		append out code
		insert/dup tail out #{00} stub-offset - length? out
		append out stubs
		insert/dup tail out #{00} text-file-size - length? out
		insert/dup tail out #{00} got-size
		insert/dup tail out #{00} data-section-offset - length? out
		append out data
		if dll? [
			insert/dup tail out #{00} init-offset - length? out
			append out lifecycle
		]
		insert/dup tail out #{00} const-offset - length? out
		append out rodata
		insert/dup tail out #{00} linkedit-offset - length? out
		append out linkedit
	]
]
