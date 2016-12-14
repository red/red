REBOL [
	Title:	 "Red/System ELF format emitter"
	Author:  "Andreas Bolka, Nenad Rakocevic"
	File:	 %ELF.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Andreas Bolka, Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
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
		rpath			"$ORIGIN"

		;; ELF Constants

		elfclass32		1			;; 32-bit object

		elfdata2lsb		1			;; 2's-complement, little endian

		ev-current		1			;; the "current" version we're adhering to

		et-exec			2			;; executable file
		et-dyn			3			;; shared object file

		em-386			3			;; intel 80386
		em-arm			40			;; ARM

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

		;; Processor-specific section type
		sht-arm-exidx			1879048193		;; ARM unwind section
		sht-arm-preemption		1879048194		;; Preempton details
		sht-arm-attributes		1879048195		;; ARM attributes section

		shf-write		1			;; dynamically writable section
		shf-alloc		2			;; dynamically allocated section
		shf-execinstr	4			;; dynamically executable section

		stn-undef		0			;; end of a hash chain (undef symtab nr)

		stb-global		1			;; global symbol

		stt-object		1			;; symbol is a data object
		stt-func		2			;; symbol is a code object

		stv-default		0			;; default symbol visibility

		dt-null			0			;; marks the end of the _DYNAMIC array
		dt-needed		1			;; strtable offset of the name of a library
		dt-hash			4			;; address of the symbol hash table
		dt-strtab		5			;; address of the string table
		dt-symtab		6			;; address of the symbol table
		dt-strsz		10			;; total size of the string table (in bytes)
		dt-syment		11			;; size of one symbol table entry (in bytes)
		dt-init			12			;; address of the initialization function
		dt-fini			13			;; address of the termination function
		dt-rpath		15			;; library search path (deprecated)
		dt-rel			17			;; address of the relocation table
		dt-relsz		18			;; total size of the relocation table
		dt-relent		19			;; size of one reloc table entry (in bytes)
		dt-runpath		29			;; library search path

		r-386-32		1			;; direct 32-bit relocation
		r-386-copy		5			;; copy symbol at runtime
		r-386-rel		8			;; relocation relative to image's base

		r-arm-abs32		2			;; direct 32-bit relocation
		r-arm-rel		23			;; relocation relative to image's base

		stabs-n-undf	0			;; undefined stabs entry
		stabs-n-fun		36			;; function name
		stabs-n-so		100			;; source file name

		arm [
			attributes [
				cpu-raw-name			#{04}
				cpu-name				#{05}
				cpu-arch				#{06}
				cpu-arch-profile		#{07}
				arm-isa-use				#{08}
				thumb-isa-use			#{09}
				fp-arch					#{0A}
				wmmx-arch				#{0B}
				advanced-simd-arch		#{0C}
				abi-pcs-wchar_t			#{12}
				abi-fp-rounding			#{13}
				abi-fp-denormal			#{14}
				abi-fp-exceptions		#{15}
				abi-fp-user-exceptions	#{16}
				abi-fp-number-model		#{17}
				abi-align-needed		#{18}
				abi-align-preserved		#{19}
				abi-enum-size			#{1A}
				abi-hardfp-use			#{1B}
				abi-vfp-args			#{1C}
				abi-wmmx-args			#{1D}
				div-use					#{2C}
			]

			cpu-arch [
				pre-v4				#{00}
				v4					#{01}			;; e.g. SA110
				v4T					#{02}           ;; e.g. ARM7TDMI
				v5T					#{03}           ;; e.g. ARM9TDMI
				v5TE				#{04}           ;; e.g. ARM946E_S
				v5TEJ				#{05}           ;; e.g. ARM926EJ_S
				v6					#{06}           ;; e.g. ARM1136J_S
				v6KZ				#{07}           ;; e.g. ARM1176JZ_S
				v6T2				#{08}           ;; e.g. ARM1156T2F_S
				v6K					#{09}           ;; e.g. ARM1136J_S
				v7					#{0A}          ;; e.g. Cortex A8, Cortex M3
				v6-M				#{0B}          ;; e.g. Cortex M1
				v6S-M				#{0C}          ;; v6_M with the System extensions
				v7E-M				#{0D}          ;; v7_M with DSP extensions
				v8					#{0E}          ;; v8, AArch32
			]

			cpu-arch-profile [
				not-applicable		#{00}		;; pre v7, or cross-profile code
				application			#{41}       ;; 'A' (e.g. for Cortex A8)
				realtime			#{52}       ;; 'R' (e.g. for Cortex R4)
				micro-controller	#{4D}       ;; 'M' (e.g. for Cortex M3)
				system				#{53}       ;; 'S' Application or real-time profile
			]
		]
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
		ident-osabi		[char!]
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
		info-addend		[short]
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
		section ".ARM.attributes"	[arm-attributes []				byte]
		struct "shdr"
	]

	;; The main entry point called from the linker.
	build: func [
		job [object!]
		/local
			base-address dynamic-linker
			libraries imports exports natives
			structure segments sections commands layout
			data-size data-reloc
			get-address get-offset get-size get-meta get-data set-data
			relro-offset pos list
	] [
		base-address: case [
			job/type = 'dll [0]
			true			[any [job/base-address defs/base-address]]
		]
		dynamic-linker: any [job/dynamic-linker ""]

		;-- (hack) Move libRedRT in first position to avoid "system" symbol
		;-- to be bound to libC instead! (TBD: find a cleaner way)
		if pos: find list: job/sections/import/3 "libRedRT.so" [
			insert list take/part pos 2
		]
		
		set [libraries imports] collect-import-names job
		exports: collect-exports job
		natives: collect-natives job
		data-reloc: collect-data-reloc job

		structure: copy default-structure

		if job/target <> 'ARM [
			remove-elements structure [".ARM.attributes"]
		]

		if empty? dynamic-linker [
			remove-elements structure [".interp"]
		]

		if empty? imports [
			remove-elements structure [
				".interp"
			]
		]

		if all [empty? imports empty? exports] [
			remove-elements structure [
				".hash"
				".dynstr"
				".dynsym"
				".dynamic"
			]
		]

		unless job/debug? [
			remove-elements structure [".stab" ".stabstr"]
		]

		data-size: size-of job/sections/data/2
		if job/debug? [
			data-size: data-size 
				+ (linker/get-debug-lines-size job)
				+  linker/get-debug-funcs-size job
		]
		if zero? data-size [
			remove-elements structure [".data"]
		]
		
		dynamic-size: calc-dynamic-size job/type job/symbols

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
			".hash"			size [machine-word		2 + 2 + (length? imports) + ((length? exports) / 2)]
			".dynsym"		size [elf-symbol		1 + (length? imports) + ((length? exports) / 2)]
			".rel.text"		size [elf-relocation	(length? imports) + (length? data-reloc)]
			".data"			size (data-size)
			".data.rel.ro"	size [machine-word		length? imports]
			".dynamic"		size [elf-dynamic		dynamic-size + length? libraries]
			".stab"			size [stab-entry		2 + ((length? natives) / 2)]
			"shdr"			size [section-header	length? sections]

			".interp"		data (to-c-string dynamic-linker)
			".dynstr"		data (to-elf-strtab compose [(libraries) (imports) (extract exports 2) (defs/rpath)])
			".text"			data (job/sections/code/2)
			".stabstr"		data (to-elf-strtab join ["%_"] extract natives 2)
			".shstrtab"		data (to-elf-strtab sections)
			".ARM.attributes" data (build-arm-attributes job/ABI)
		]

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
				job/os
				job/target
				job/type
				get-offset "phdr"
				get-offset "shdr"
				get-address ".text"
				segments
				sections
		]

		set-data "phdr"
			[build-phdr map-each segment segments [layout/:segment]]

		set-data ".hash"
			[build-hash compose [(imports) (extract exports 2)]]

		set-data ".dynsym" [
			build-dynsym
				imports
				exports
				get-data ".dynstr"
				get-address ".text"
				section-index-of sections ".text"
				get-address ".data"
				section-index-of sections ".data"
		]

		set-data ".rel.text" [
			build-reltext
				job/target
				imports
				get-address ".data.rel.ro"
				data-reloc
				any [attempt [get-address ".data"] 0]	;-- in case .data segment is absent
				get-address ".text"
		]

		set-data ".data" [
			if job/debug? [
				linker/build-debug-lines job get-address ".text"
				linker/build-debug-func-names job get-address ".text"
			]
			job/sections/data/2
		]

		set-data ".data.rel.ro"
			[build-relro imports]
		
		set-data ".dynamic" [
			build-dynamic
				job/type
				job/symbols
				get-address ".text"
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
			relro-offset: get-address ".data.rel.ro"
			if job/PIC? [relro-offset: relro-offset - get-address ".text"]
			resolve-import-refs
				job
				imports
				get-data ".text"
				relro-offset
		]

		;; Concatenate the layout data into the output binary.
		job/buffer: copy #{}
		foreach [name values] layout [
			append job/buffer serialize-data values/data			;; Data
			append job/buffer rejoin array/initial values/pad #{00} ;; Padding
		]
		job/buffer
	]

	;; -- ELF structure builders --

	build-ehdr: func [
		target-os [word!]
		target-arch [word!]
		target-type [word!]
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

		;; Target-specific header fields.

		eh/ident-osabi: switch/default target-os [
			FreeBSD      [9]
			Linux        [3]
		]	             [0]

		eh/type: select reduce [
			'exe defs/et-exec
			'dll defs/et-dyn
		] target-type

		switch target-arch [
			ia-32	[
				eh/machine: defs/em-386
			]
			arm		[
				eh/machine: defs/em-arm
				eh/flags: to-integer #{05000002} ;; EABI v5
			]
		]

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

	build-dynsym: func [
		imports [block!]
		exports [block!]
		dynstr [binary!]
		text-address [integer!]
		text-index [integer!]
		data-address [integer!]
		data-index [integer!]
		/local result entry export-base export-type export-index
	] [
		result: copy []

		;; Symbol #0: undefined symbol
		append result make-struct elf-symbol none

		foreach symbol imports [
			entry: make-struct elf-symbol none
			entry/name: strtab-index-of dynstr symbol
			entry/value: 0 ;; Unknown, for imported symbols.
			entry/info: to-elf-symbol-info defs/stb-global defs/stt-func
			entry/other: defs/stv-default
			entry/shndx: defs/shn-undef
			append result entry
		]

		foreach [symbol meta] exports [
			set [export-base export-type export-index] case [
				meta/type = 'global [
					reduce [data-address defs/stt-object data-index]
				]
				true [
					reduce [text-address defs/stt-func text-index]
				]
			]
			entry: make-struct elf-symbol none
			entry/name: strtab-index-of dynstr symbol
			entry/value: export-base + meta/offset
			entry/info: to-elf-symbol-info defs/stb-global export-type
			entry/size: meta/size
			entry/other: defs/stv-default
			entry/shndx: export-index
			append result entry
		]

		result
	]

	build-reltext: func [
		target-arch [word!]
		symbols [block!]
		relro-address [integer!]
		relocs [block!]
		data-address [integer!]
		code-address [integer!]
		/local rel-type result entry len
	] [
		rel-type: select reduce [
			'IA-32	defs/r-386-32
			'ARM	defs/r-arm-abs32
		] target-arch
		result: make block! (length? relocs) + len: length? symbols
		
		repeat i len [ 									;-- 1..n, 0 is undef
			entry: make-struct elf-relocation none
			entry/offset:		rel-address-of/index relro-address (i - 1)
			entry/info-sym:		rel-type
			entry/info-type:	i // 256
			entry/info-addend:	shift/logical i 8
			append result entry
		]
		
		rel-type: select reduce [
			'IA-32	defs/r-386-rel
			'ARM	defs/r-arm-rel
		] target-arch
		
		foreach ptr relocs [
			entry: make-struct elf-relocation none
			entry/offset:		data-address + ptr
			entry/info-sym:		rel-type
			entry/info-type:	0
			entry/info-addend:	0
			append result entry
		]
		result
	]
	
	build-reldata: func [
		target-arch [word!]
		relocs [block!]
		data-address [integer!]
		/local rel-type result entry len
	][
		result: make block! (length? relocs) / 2
		
		foreach [name spec] relocs [
			entry: make-struct elf-relocation none
			entry/offset: spec/2
			entry/info-sym: defs/stn-undef
			entry/info-type: 0
			entry/info-addend: 0
			append result entry
		]
		result
	]

	build-relro: func [symbols [block!]] [
		;; @@ Use NOBITS section (filesize 0, memsize n) instead?
		array/initial length? symbols make-struct machine-word none
	]

	build-dynamic: func [
		job-type [word!]
		symbols [hash!]
		text-address [integer!]
		hash-address [integer!]
		dynstr-address [integer!]
		dynstr-size [integer!]
		dynsym-address [integer!]
		reltext-address [integer!]
		reltext-size [integer!]
		dynstr [binary!]
		libraries [block!]
		/local entries spec
	] [
		entries: copy []

		;; One DT_NEEDED for each dynamic library:
		foreach library libraries [
			repend entries ['needed strtab-index-of dynstr library]
		]
		repend entries ['rpath strtab-index-of dynstr defs/rpath]

		if job-type = 'dll [
			if spec: select symbols '***-dll-entry-point [
				repend entries ['init text-address + spec/2 - 1]
			]
			if spec: select symbols 'on-unload [
				repend entries ['fini text-address + spec/2 - 1]
			]
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

	build-arm-attributes: func [
		ABI			[word! none!]
		/local section sub-section attributes attrs
	][
		attrs: defs/arm/attributes
		attributes: rejoin [
			attrs/cpu-arch				defs/arm/cpu-arch/v5T
			attrs/arm-isa-use			#{01}			;; yes
			attrs/abi-pcs-wchar_t		#{04}			;; 4 bytes
			attrs/abi-fp-denormal		#{01}			;; needed
			attrs/abi-fp-exceptions		#{01}			;; needed
			attrs/abi-fp-number-model	#{03}			;; IEEE-754
			attrs/abi-align-needed		#{01}			;; 8-byte
			attrs/abi-align-preserved	#{01}			;; 8-byte, except leaf SP
			attrs/abi-enum-size			#{02}			;; at least 32 bits
			attrs/div-use				#{01}			;; not allowed
		]
		if ABI = 'hard-float [
			append attributes rejoin [
				attrs/abi-hardfp-use	#{03}
				attrs/abi-vfp-args		#{01}
			]
		]
		sub-section: rejoin [
			#{01}					;; file tag
			to-bin32 5 + length? attributes
			attributes
		]
		section: rejoin [
			to-binary "aeabi^@"		;; vendor-name
			sub-section
		]
		rejoin [
			#{41}					;; version A
			to-bin32 4 + length? section
			section
		]
	]

	;; -- Job helpers --
	
	collect-data-reloc: func [job [object!] /local list syms spec][
		list: make block! 100
		syms: job/symbols
		
		while [not tail? syms][
			spec: syms/2
			syms: skip syms 2
			if all [
				not tail? syms
				syms/1 = <data>	
				block? syms/2/4
				syms/2/4/1 - 1 = spec/2
			][
				append list spec/2
			]
		]
		list
	]

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

	collect-exports: func [
		{Collect a list of exported objects: symbol, type, offset and size. As
		the object size is not yet stored in the symbol or exports table, we
		have to compute it here.}
		job [object!]
		/local current-tail code-tail data-tail symbol-offset symbol-size ext-name
	] [
		unless find job/sections 'export [return make block! 0]

		code-tail: length? job/sections/code/2
		data-tail: length? job/sections/data/2
		collect [
			foreach [meta symbol] reverse copy job/symbols [
				catch [
					case [
						find [import import-var native-ref] meta/1 [
							throw 'continue
						]
						'global = meta/1 [
							symbol-offset: meta/2
							symbol-size: data-tail - symbol-offset
							data-tail: symbol-offset
						]
						'native = meta/1 [
							;; Code symbols have 1-based offsets, data symbols
							;; have 0-based offsets in job/symbols ...
							symbol-offset: meta/2 - 1
							symbol-size: code-tail - symbol-offset
							code-tail: symbol-offset
						]
						true [
							make error! reform ["Unhandled symbol type:" meta/1]
						]
					]
					if ext-name: select job/sections/export/3 symbol [
						keep compose/deep [
							(ext-name) [
								type	(meta/1)
								offset	(symbol-offset)
								size	(symbol-size)
							]
						]
					]
				]
			]
		]
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
		job [object!] symbols [block!] code [binary!] relro-offset [integer!]
		/local rel
	] [
		rel: make-struct machine-word none
		foreach [libname libimports] job/sections/import/3 [
			linker/check-dup-symbols job libimports
			foreach [symbol callsites] libimports [
				rel/value: rel-address-of/symbol relro-offset symbols symbol
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

	calc-dynamic-size: func [job-type [word!] symbols [hash!] /local size] [
		size: 10
		if job-type = 'dll [
			if find symbols '***-dll-entry-point [
				size: size + 1
			]
			if find symbols 'on-unload [
				size: size + 1
			]
		]
		size
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
						size: find-size commands name
						;; Ensure all leaf nodes are padded to 32-bit multiples.
						if not zero? pad: (4 - (size // 4)) // 4 [ ;; @@ Make alignment target-specific.
							repend commands [name 'pad pad]
						]
						total: total + size + pad
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

		emit: func [n t o a s m d /local p] [
			p: any [select commands reduce [name 'pad] 0]
			repend layout [
				n reduce [
					'type t 'offset o 'address a 'size s 'pad p 'meta m 'data d
				]
			]
			p
		]

		offset: 0
		address: 0

		complete-sizes structure commands

		parse structure elements-rule: [
			any [
				(meta: copy [])
				set type word!
				set name string!
				opt [set meta block!]
				(
					address: address + find-skip commands name
					size: find-size commands name
					meta: merge-meta commands name meta
					data: select commands reduce [name 'data]
				)
				[
					into [
						(emit name type offset address size meta data)
						elements-rule
					]
				|
					(
						padding: emit name type offset address size meta data
						address: address + size + padding
						offset: offset + size + padding
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

	strtab-index-of: func [strtab [binary!] string [string! issue!]] [
		-1 + index? find strtab to-c-string string
	]

	section-index-of: func [
		sections [block!] section [string! none!] /local pos
	] [
		either pos: find sections section [index? pos] [0]
	]

	rel-address-of: func [
		base [integer!]
		/symbol syms [block!] sym [string! issue!]
		/index ind [integer!]
	] [
		base + ((size-of machine-word) * any [ind (-1 + index? find syms sym)])
	]

	to-c-string: func [data [string! binary! issue!]] [join as-binary data #{00}]

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
