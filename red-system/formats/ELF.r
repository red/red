REBOL [
	Title:	 "Red/System ELF format emitter"
	Author:  "Andreas Bolka, Nenad Rakocevic"
	File:	 %ELF.r
	Rights:  "Copyright (C) 2011 Andreas Bolka, Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; NOTE: all "offsets" are offsets into the file (as stored on disk),
;; all "addresses" are virtual addresses (of the process in memory).

context [
	defs: compose [
		;; Required by the linker.
		extensions [
			exe %""
			obj %.o
			lib %.a
			dll %.so
		]

		;; Target-specific Defaults (job-overridable)

		base-address	(to-integer #{08048000})
		page-size		4096

		;; ELF Constants

		elfclass32		1			;; 32-bit object

		elfdata2lsb		1			;; 2's-complement, little endian

		ev-current		1			;; the "current" version we're adhering to

		et-exec			2			;; executable file

		em-386			3			;; intel 80386

		pt-load			1			;; loadable segment
		pt-dynamic		2			;; dynamic linking information
		pt-interp		3			;; dynamic linker ("interpreter") path name
		pt-phdr			6			;; program header table

		pf-x			1			;; executable segment
		pf-w			2			;; writable segment
		pf-r			4			;; readable wegment

		shn-undef		0			;; undefined section

		sht-null		0			;; inactive section header
		sht-progbits	1			;; program-specific data (w/ file extent)
		sht-symtab		2			;; symbol table (for link editing)
		sht-strtab		3			;; string table
		sht-hash		5			;; symbol hash table
		sht-dynamic		6			;; dynamic linking
		sht-nobits		8			;; program-specific data (w/o file extend)
		sht-rel			9			;; relocations (w/o addends)
		sht-dynsym		11			;; symbol table (dynamic linking)

		shf-write		1			;; dynamically writable section
		shf-alloc		2			;; dynamically allocated section
		shf-execinstr	4			;; dynamically executable section

		stn-undef		0			;; end of a hash chain (undef symtab nr)

		stb-global		1			;; global symbol

		stt-func		2			;; symbol is a code object

		stv-default		0			;; default symbol visibility

		dt-null			0			;; marks the end of the _DYNAMIC array
		dt-needed		1			;; strtable offset of the name of a library
		dt-hash			4			;; address of the symbol hash table
		dt-strtab		5			;; address of the string table
		dt-symtab		6			;; address of the symbol table
		dt-strsz		10			;; total size of the string table (in bytes)
		dt-syment		11			;; size of one symbol table entry (in bytes)
		dt-rel			17			;; address of the relocation table
		dt-relsz		18			;; total size of the relocation table
		dt-relent		19			;; size of one reloc table entry (in bytes)

		r-386-32		1			;; direct 32-bit relocation
		r-386-copy		5			;; copy symbol at runtime

		stabs-n-undf	0			;; undefined stabs entry
		stabs-n-fun		36			;; function name
		stabs-n-so		100			;; source file name
	]

	;; ELF Structures

	elf-header: make-struct [		;; (Elf32_Ehdr)
		ident-mag0		[char!]		;; 0x7F (EI_MAG0)
		ident-mag1		[char!]		;; "E" (EI_MAG1)
		ident-mag2		[char!]		;; "L" (EI_MAG2)
		ident-mag3		[char!]		;; "F" (EI_MAG3)
		ident-class		[char!]		;; file class
		ident-data		[char!]		;; data encoding
		ident-version	[char!]		;; file version
		ident-pad0		[char!]
		ident-pad1		[integer!]
		ident-pad2		[integer!]
		type			[short]
		machine			[short]
		version			[integer!]
		entry			[integer!]	;; virtual address of program entry point
		phoff			[integer!]	;; file offset to phdr table
		shoff			[integer!]	;; file offset to shdr table
		flags			[integer!]
		ehsize			[short]		;; size-of elf-header
		phentsize		[short]		;; size-of program-header
		phnum			[short]		;; num of "segments" (entries in phdr tab)
		shentsize		[short]		;; size-of section-header
		shnum			[short]		;; num of "sections" (entries in shdr tab)
		shstrndx		[short]		;; shdr table index of .shstrtab section
	] none

	program-header: make-struct [	;; (Elf32_Phdr)
		type			[integer!]
		offset			[integer!]
		vaddr			[integer!]
		paddr			[integer!]
		filesz			[integer!]
		memsz			[integer!]
		flags			[integer!]
		align			[integer!]
	] none

	section-header: make-struct [	;; (Elf32_Shdr)
		name			[integer!]	;; index into .shstrtab
		type			[integer!]
		flags			[integer!]
		addr			[integer!]
		offset			[integer!]
		size			[integer!]
		link			[integer!]
		info			[integer!]
		addralign		[integer!]
		entsize			[integer!]
	] none

	elf-dynamic: make-struct [		;; (Elf32_Dyn)
		tag				[integer!]
		val				[integer!]
	] none

	elf-symbol: make-struct [		;; (Elf32_Sym)
		name			[integer!]	;; symbol strtab index (zero: unnamed sym)
		value			[integer!]	;; absolute value, address, ...
		size			[integer!]	;; associated symbol size (if any)
		info			[char!]		;; symbol type and binding attributes
		other			[char!]		;; symbol visibility
		shndx			[short]		;; section this symbol is associated with
	] none

	elf-relocation: make-struct [	;; (Elf32_Rel)
		offset			[integer!]
		info-sym		[char!]
		info-type		[char!]
		info-unused		[short]
	] none

	stab-entry: make-struct [
		strx			[integer!]
		type			[char!]
		other			[char!]
		desc			[short]
		value			[integer!]
	] none

	machine-word: make-struct [
		value			[integer!]
	] none

	;; ------------------------------------------------------------------------

	;; The macro structure of our generated ELF binaries.
	default-structure: [
		;; Standard metadata:		[type		flags				align]
		segment "rx"				[load		[r x]				page] [
			struct "ehdr"
			segment "phdr"			[phdr	  	[r]					byte]
			segment "interp"		[interp	  	[r]					byte] [
				section ".interp"	[progbits 	[alloc]				byte]
			]
			section ".hash"			[hash	  	[alloc]				word]
			section ".dynstr"		[strtab	  	[alloc]				byte]
			section ".dynsym"		[dynsym	  	[alloc]				word]
			section ".rel.text"		[rel	  	[alloc]				word]
			section ".text"			[progbits 	[alloc execinstr]	word]
		]

		segment "rw"				[load	  	[r w]				page] [
			section ".data"			[progbits 	[write alloc]		word]
			section ".data.rel.ro"	[progbits 	[write alloc]		word]
			segment "dynamic"		[dynamic  	[r w]				word] [
				section ".dynamic"	[dynamic  	[write alloc]		word]
			]
		]

		section ".stab"				[progbits	[]					word]
		section ".stabstr"			[strtab		[]					byte]

		section ".shstrtab"			[strtab	  	[]					byte]
		struct "shdr"
	]

	;; The main entry point called from the linker.
	build: func [
		job [object!]
		/local
			base-address dynamic-linker
			libraries symbols natives
			structure segments sections commands layout
			get-address get-offset get-size get-meta get-data set-data
	] [
		base-address: any [job/base-address defs/base-address]
		dynamic-linker: any [job/dynamic-linker ""]

		set [libraries symbols] collect-import-names job
		natives: collect-natives job

		structure: copy default-structure

		if empty? dynamic-linker [
			remove-elements structure [".interp"]
		]

		if empty? symbols [
			remove-elements structure [
				".interp"
				".hash"
				".dynstr"
				".dynsym"
				".rel.text"
				".data.rel.ro"
				".dynamic"
			]
		]

		unless job/debug? [
			remove-elements structure [".stab" ".stabstr"]
		]

		if empty? job/sections/data/2 [
			remove-elements structure [".data"]
		]

		segments: collect-structure-names structure 'segment
		sections: collect-structure-names structure 'section

		commands: compose/deep [
			"rx"			skip (base-address)
			"rw"			skip (defs/page-size)

			".hash"			meta [link ".dynsym"]
			".dynsym"		meta [link ".dynstr" info ".interp"]
			".rel.text"		meta [link ".dynsym" info ".text"]
			".dynamic"		meta [link ".dynstr"]
			".stab"			meta [link ".stabstr"]

			"ehdr"			size elf-header
			"phdr"			size [program-header	length? segments]
			".hash"			size [machine-word		2 + 2 + length? symbols]
			".dynsym"		size [elf-symbol		1 + length? symbols]
			".rel.text"		size [elf-relocation	length? symbols]
			".data.rel.ro"	size [machine-word		length? symbols]
			".dynamic"		size [elf-dynamic		9 + length? libraries]
			".stab"			size [stab-entry		2 + ((length? natives) / 2)]
			"shdr"			size [section-header	length? sections]

			".interp"		data (to-c-string dynamic-linker)
			".dynstr"		data (to-elf-strtab join libraries symbols)
			".text"			data (job/sections/code/2)
			".data"			data (job/sections/data/2)
			".stabstr"		data (to-elf-strtab join ["%_"] extract natives 2)
			".shstrtab"		data (to-elf-strtab sections)
		]

		complete-sizes structure commands
		layout: layout-binary structure commands

		;; In the following section, we try to minimize the global state passed
		;; around. Instead of just passing LAYOUT to all build-* functions, we
		;; try to pass the minimum amount of information necessary. This makes
		;; the dependencies between those builders more explicit.

		get-address: func [name] [layout/:name/address]
		get-offset: func [name] [layout/:name/offset]
		get-size: func [name] [layout/:name/size]
		get-meta: func [name] [layout/:name/meta]
		get-data: func [name] [layout/:name/data]

		has-element: func [name] [found? find/skip layout name 2]

		set-data: func [name builder] [
			if has-element name [
				layout/:name/data: do builder
			]
		]

		set-data "ehdr" [
			build-ehdr
				get-offset "phdr"
				get-offset "shdr"
				get-address ".text"
				segments
				sections
		]

		set-data "phdr"
			[build-phdr map-each segment segments [layout/:segment]]

		set-data ".hash"
			[build-hash symbols]

		set-data ".dynsym"
			[build-dynsym symbols get-data ".dynstr"]

		set-data ".rel.text"
			[build-reltext symbols get-address ".data.rel.ro"]

		set-data ".data.rel.ro"
			[build-relro symbols]

		set-data ".dynamic" [
			build-dynamic
				get-address ".hash"
				get-address ".dynstr" get-size ".dynstr"
				get-address ".dynsym"
				get-address ".rel.text" get-size ".rel.text"
				get-data ".dynstr"
				libraries
		]

		set-data ".stab" [
			build-stab
				get-address ".text"
				get-data ".stabstr"
				natives
		]

		set-data "shdr" [
			build-shdr
				flatten map-each name sections [reduce [name layout/:name]]
				commands
				get-data ".shstrtab"
		]

		;; Resolve data references.
		if has-element ".data" [
			linker/resolve-symbol-refs
				job
				get-data ".text"
				get-data ".data"
				get-address ".text"
				get-address ".data"
				machine-word
		]

		;; Resolve import (library function) references.
		if has-element ".data.rel.ro" [
			resolve-import-refs
				job
				symbols
				get-data ".text"
				get-address ".data.rel.ro"
		]

		;; Concatenate the layout data into the output binary.
		job/buffer: serialize-data map-each [name values] layout [values/data]
	]

	;; -- ELF structure builders --

	build-ehdr: func [
		phdr-offset [integer!]
		shdr-offset [integer!]
		text-address [integer!]
		segment-names [block!]
		section-names [block!]
		/local eh
	] [
		eh: make-struct elf-header none
		eh/ident-mag0:		#"^(7F)"
		eh/ident-mag1:		#"E"
		eh/ident-mag2:		#"L"
		eh/ident-mag3:		#"F"
		eh/ident-class:		defs/elfclass32
		eh/ident-data:		defs/elfdata2lsb
		eh/ident-version:	defs/ev-current
		eh/type:			defs/et-exec
		eh/machine:			defs/em-386
		eh/version:			defs/ev-current
		eh/entry:			text-address
		eh/phoff:			phdr-offset
		eh/shoff:			shdr-offset
		eh/flags:			0
		eh/ehsize:			size-of elf-header
		eh/phentsize:		size-of program-header
		eh/phnum:			length? segment-names
		eh/shentsize:		size-of section-header
		eh/shnum:			1 + length? section-names
		eh/shstrndx:		index? find section-names ".shstrtab"
		eh
	]

	build-phdr: func [segments [block!] /local ph] [
		map-each segment segments [
			ph: make-struct program-header none
			ph/type:		lookup-def "pt-" segment/meta/type
			ph/offset:		segment/offset
			ph/vaddr:		segment/address
			ph/paddr:		segment/address
			ph/filesz:		segment/size
			ph/memsz:		segment/size
			ph/flags:		lookup-flags "pf-" segment/meta/flags
			ph/align:		lookup-align segment/meta/align
			ph
		]
	]

	build-hash: func [symbols [block!] /local nsymbols] [
		;; @@ Document lookup algorithm?
		nsymbols: length? symbols
		map-each value collect [
			;; nbucket
			keep 1
			;; nchain
			keep nsymbols + 1
			;; bucket[0] = 1 if nsymbols>0 else 0
			keep min nsymbols 1
			;; chain[0] = undef
			keep defs/stn-undef
			;; chain[i:1..nsymbols-1] = i+1
			for i 2 nsymbols 1 [
				keep i
			]
			;; chain[nsymbols] = undef if nsymbols>0 (else omit)
			if nsymbols > 0 [
				keep defs/stn-undef
			]
		] [
			make-struct machine-word reduce [value]
		]
	]

	build-dynsym: func [symbols [block!] dynstr [binary!] /local result entry] [
		result: copy []

		;; Symbol #0: undefined symbol
		append result make-struct elf-symbol none

		foreach symbol symbols [
			entry: make-struct elf-symbol none
			entry/name: strtab-index-of dynstr symbol
			entry/value: 0 ;; Unknown, for imported symbols.
			entry/info: to-elf-symbol-info defs/stb-global defs/stt-func
			entry/other: defs/stv-default
			entry/shndx: defs/shn-undef
			append result entry
		]

		result
	]

	build-reltext: func [
		symbols [block!] relro-address [integer!] /local result entry
	] [
		result: copy []
		repeat i length? symbols [ ;; 1..n, 0 is undef
			entry: make-struct elf-relocation none
			entry/offset: rel-address-of/index relro-address (i - 1)
			entry/info-sym: defs/r-386-32
			entry/info-type: i
			append result entry
		]
		result
	]

	build-relro: func [symbols [block!]] [
		;; @@ Use NOBITS section (filesize 0, memsize n) instead?
		array/initial length? symbols make-struct machine-word none
	]

	build-dynamic: func [
		hash-address [integer!]
		dynstr-address [integer!]
		dynstr-size [integer!]
		dynsym-address [integer!]
		reltext-address [integer!]
		reltext-size [integer!]
		dynstr [binary!]
		libraries [block!]
		/local entries
	] [
		entries: copy []

		;; One DT_NEEDED for each dynamic library:
		foreach library libraries [
			repend entries ['needed strtab-index-of dynstr library]
		]
		;; Static _DYNAMIC entries:
		append entries reduce [
			'hash	hash-address
			'strtab	dynstr-address
			'symtab	dynsym-address
			'strsz	dynstr-size
			'syment	size-of elf-symbol
			'rel	reltext-address
			'relsz	reltext-size
			'relent	size-of elf-relocation
			'null	0
		]

		map-each [tag value] entries [
			make-struct elf-dynamic reduce [lookup-def "dt-" tag value]
		]
	]

	build-stab: func [
		text-address [integer!] stabstr [binary!] natives [block!]
		/local r s
	] [
		collect [
			;; The first synthetic entry (required) holds the number of
			;; non-synthetic entries as well as the size of the string table.
			s: make-struct stab-entry none
			s/type: defs/stabs-n-undf
			s/desc: 1 + ((length? natives) / 2)
			s/value: size-of stabstr
			keep s

			;; One source file stab (N_SO) is required before any other stabs.
			s: make-struct stab-entry none
			s/type: defs/stabs-n-so
			s/value: text-address
			s/strx: 1 ;; @@ Use a real source name (instead of "%_")
			keep s

			foreach [name offset] natives [
				s: make-struct stab-entry none
				s/type: defs/stabs-n-fun
				s/value: text-address + offset
				s/strx: strtab-index-of stabstr name
				keep s
			]
		]
	]

	build-shdr: func [
		sections [block!] commands [block!] shstrtab [binary!]
		/local names sh name section
	] [
		names: extract sections 2
		join reduce [
			make-struct section-header none
		] map-each [name section] sections [
			sh: make-struct section-header none
			sh/name:		strtab-index-of shstrtab name
			sh/type:		lookup-def "sht-" section/meta/type
			sh/flags:		lookup-flags "shf-" section/meta/flags
			sh/addr:		section/address
			sh/offset:		section/offset
			sh/size:		section/size
			sh/link:		section-index-of names select section/meta 'link
			sh/info:		section-index-of names select section/meta 'info
			sh/addralign:	lookup-align section/meta/align
			sh/entsize:		find-entry-size commands name
			sh
		]
	]

	;; -- Job helpers --

	collect-import-names: func [job [object!] /local libraries symbols] [
		libraries: copy []
		symbols: copy []
		foreach [libname libuses] job/sections/import/3 [
			append libraries libname
			foreach [symbol callsites] libuses [
				append symbols symbol
			]
		]
		reduce [libraries symbols]
	]

	collect-natives: func [job [object!]] [
		collect [
			foreach [name meta] job/symbols [
				if meta/1 = 'native [
					keep reduce [(join name ":F") (meta/2 - 1)]
				]
			]
		]
	]

	resolve-import-refs: func [
		job [object!] symbols [block!] code [binary!] relro-address [integer!]
		/local rel
	] [
		rel: make-struct machine-word none
		foreach [libname libimports] job/sections/import/3 [
			foreach [symbol callsites] libimports [
				rel/value: rel-address-of/symbol relro-address symbols symbol
				foreach callsite callsites [
					change/part at code callsite serialize-data rel size-of rel
				]
			]
		]
	]

	;; -- File structure/file commands helpers --

	remove-elements: func [structure elements /local begin mark name children] [
		parse structure [
			any [
				begin: (children: none)
				word! ;; type
				set name string!
				opt [block!] ;; meta
				opt [set children block!]
				mark: (
					if children [remove-elements children elements]
					if any [find elements name  attempt [empty? children]] [
						mark: remove/part begin mark
					]
				) :mark
			]
		]
	]

	collect-structure-names: func [
		structure [block!] filter [word! block!] /local result type name
	] [
		result: copy []
		parse structure elements-rule: [
			any [
				set type word!
				set name string!
				opt [block!] ;; meta
				(if filter = type [append result name])
				opt [into [elements-rule]]
			]
		]
		result
	]

	find-skip: func [commands [block!] name [string!]] [
		any [select commands reduce [name 'skip] 0]
	]

	find-size: func [commands [block!] name [string!] /local data spec] [
		if data: select commands reduce [name 'data] [
			return size-of data
		]

		if spec: select commands reduce [name 'size] [
			;; size spec variant 1: `value`
			if integer? spec [return spec]

			;; size spec variant 2: `word` (bound)
			if word? spec [return size-of get spec]

			;; size spec variant 3: `[element num-elements]` (bound, unreduced)
			set [element num-elements] reduce spec
			return num-elements * size-of element
		]

		make error! reform ["Unknown node size:" name]
	]

	find-entry-size: func [commands [block!] name [string!] /local spec] [
		;; Items with a `[element num-elements]` size command have an entry
		;; size, everything else does not.
		either block? spec: select commands reduce [name 'size] [
			size-of first reduce spec
		] [
			0
		]
	]

	merge-meta: func [
		commands [block!] name [string!] meta [block!] /local result
	] [
		append
			reduce ['type meta/1 'flags meta/2 'align meta/3]
			any [select commands reduce [name 'meta] []]
	]

	complete-sizes: func [
		structure [block!] commands [block!] /local total size name children
	] [
		;; This could be inlined into LAYOUT-BINARY, but having it explicit as
		;; a second pass makes makes things more clear.
		total: 0
		parse structure [
			any [
				word! ;; type
				set name string!
				opt [block!] ;; meta
				[
					set children block!
					(
						total: total + size: complete-sizes children commands
						repend commands [name 'size size]
					)
				|
					(
						total: total + find-size commands name
					)
				]
			]
		]
		total
	]

	layout-binary: func [
		{Given a file structure and file layout commands, generate a full file
		"layout". A file layout collects the type, offset, address, size,
		metadata and data for each element in the file's structure.}
		structure [block!] commands [block!]
		/local layout emit offset address elements-rule name type meta size
	] [
		layout: copy []

		emit: func [n t o a m /local s d] [
			s: find-size commands n
			m: merge-meta commands n m
			d: select commands reduce [name 'data]
			repend layout [
				n reduce ['type t 'offset o 'address a 'size s 'meta m 'data d]
			]
		]

		offset: 0
		address: 0

		parse structure elements-rule: [
			any [
				(meta: copy [])
				set type word!
				set name string!
				opt [set meta block!]
				(address: address + find-skip commands name)
				[
					into [
						(emit name type offset address meta)
						elements-rule
					]
				|
					(
						emit name type offset address meta
						size: find-size commands name
						address: address + size
						offset: offset + size
					)
				]
			]
		]

		layout
	]

	;; -- Definitions lookup --

	lookup-def: func [prefix [string! word!] suffix [string! word!]] [
		defs/(to-word join prefix suffix)
	]

	lookup-flags: func [prefix [string! word!] flags [block!] /local value] [
		value: 0
		foreach flag flags [
			value: value or lookup-def prefix flag
		]
		value
	]

	lookup-align: func [align [word!]] [
		select reduce [
			'byte 1
			'word size-of machine-word
			'page defs/page-size
		] align
	]

	;; -- Helpers for creating/using ELF structures --

	strtab-index-of: func [strtab [binary!] string [string!]] [
		-1 + index? find strtab to-c-string string
	]

	section-index-of: func [
		sections [block!] section [string! none!] /local pos
	] [
		either pos: find sections section [index? pos] [0]
	]

	rel-address-of: func [
		base [integer!]
		/symbol syms [block!] sym [string!]
		/index ind [integer!]
	] [
		base + ((size-of machine-word) * any [ind (-1 + index? find syms sym)])
	]

	to-c-string: func [data [string! binary!]] [join as-binary data #{00}]

	to-elf-strtab: func [items [block!]] [
		join #{00} map-each item items [to-c-string form item]
	]

	to-elf-symbol-info: func [binding [integer!] type [integer!]] [
		(shift/left binding 4) + (type and 15)
	]

	;; -- Helpers for working with various binary data intermediaries --

	serialize-data: func [data [block! object! binary! none!]] [
		case [
			block? data		[rejoin map-each item data [serialize-data item]]
			struct? data	[form-struct data]
			binary? data	[data]
			none? data		[#{}]
		]
	]

	size-of: func [data [block! object! binary! none!]] [
		length? serialize-data data
	]

	;; -- Misc helpers --

	flatten: func [items] [collect [foreach item items [keep item]]]
]
