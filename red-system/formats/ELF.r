REBOL [
	Title:	 "Red/System ELF format emitter"
	Author:  "Andreas Bolka, Nenad Rakocevic"
	File:	 %ELF.r
	Rights:  "Copyright (C) 2011 Andreas Bolka, Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

context [
	defs: [
		image [
			base-address	134512640	; #{08048000}
		]
		extensions [
			exe %""
			obj %.o
			lib %.a
			dll %.so
		]
		target [
		;-- Red Target ---- Machine --- Data Encoding
			IA32			m-386		two-lsb
		]
		machine [
			m-386			3				;-- intel 80386 (EM_386)
		]
		class [								;-- (EI_CLASS)
			none			0				;-- invalid class (ELFCLASSNONE)
			c-32-bit		1				;-- 32-bit objects (ELFCLASS32)
			c-64-bit		2				;-- 64-bit objects (ELFCLASS64)
		]
		encoding [							;-- (EI_DATA)
			none			0				;-- unknown data format (ELFDATANONE)
			two-lsb			1				;-- two's complement, little endian (ELFDATA2LSB)
			two-msb			2				;-- two's complement, big endian (ELFDATA2MSB)
		]
		version [							;-- (EI_VERSION)
			none			0				;-- invalid version (EV_NONE)
			current			1				;-- current version (EV_CURRENT)
		]
		file-type [
			none			0				;-- unknown type (ET_NONE)
			relocatable		1				;-- relocatable file (ET_REL)
			executable		2				;-- executable file (ET_EXEC)
			shared			3				;-- shared object file (ET_DYN)
			core			4				;-- core file (ET_CORE)
			lo-proc			#{FF00}			;-- processor-specific
			hi-proc			#{FFFF}			;-- processor-specific
		]
		segment-type [
			null			0				;-- ignore entry (PT_NULL)
			load			1				;-- loadable segment (PT_LOAD)
			dynamic			2				;-- dynamic linking information (PT_DYNAMIC)
			interp			3				;-- interpreter path name (PT_INTERP)
			note			4				;-- notes/comments (PT_NOTE)
			shlib			5				;-- reserved (unused) (PT_SHLIB)
			phdr			6				;-- program header table location (PT_PHDR)
			lo-proc			#{70000000}		;-- reserved (proc-specific)
			hi-proc			#{7FFFFFFF}		;-- reserved (proc-specific)
		]
		segment-flags [						;-- (proc-specific)
			executable		1				;-- (PF_X)
			write			2				;-- (PF_W)
			read			4				;-- (PF_R)
		]
		segment-access [
			code			5				;-- [read executable]	; 1st part of LOAD segment
			data			6				;-- [read write]		; 2nd part of LOAD segment
			import			6				;-- [read write]		; DYNAMIC segment
		]
		section-type [
			null			0				;-- mark inactive section header (SHT_NULL)
			prog-bits		1				;-- program-specific data (SHT_PROGBITS)
			sym-tab			2				;-- symbol table (for link editing) (SHT_SYMTAB)
			str-tab			3				;-- string table (SHT_STRTAB)
			rela			4				;-- relocations with addends (SHT_RELA)
			hash			5				;-- symbol hash table (SHT_HASH)
			dynamic			6				;-- dynamic linking (SHT_DYNAMIC)
			note			7				;-- notes/comments (SHT_NOTE)
			no-bits			8				;-- program-specific data (SHT_NOBITS)
			rel				9				;-- relocations without addends (SHT_REL)
			shlib			10				;-- reserved (unused) (SHT_SHLIB)
			dyn-sym			11				;-- symbol table (dynamic linking) (SHT_DYNSYM)
			lo-proc			#{70000000}		;-- reserved (proc-specific)
			hi-proc			#{7FFFFFFF}		;-- reserved (proc-specific)
			lo-user			#{80000000}		;-- reserved (lower bound reserved indexes)
			hi-user			#{8FFFFFFF}		;-- reserved (upper bound reserved indexes)
		]
		section-flags [
			write			1				;-- writable during program execution (SHF_WRITE)
			alloc			2				;-- in memory during program execution (SHF_ALLOC)
			exec			4				;-- executable code (SHF_EXECINSTR)
			mask-proc		#{F0000000}		;-- mask bits for proc-specific semantics
		]
		sections-table [
		; -- Name --------- Type ------ Attributes
			".text"			prog-bits	6	;-- [alloc exec]
			".data"			prog-bits	3	;-- [alloc write]
		;	".rodata"		prog-bits	2	;-- [alloc]
			".shstrtab"		str-tab		0	;-- []
		]
	]

	page-size:		4096					;-- system page size
	base-ptr:		defs/image/base-address	;-- base virtual address
	code-ptr:		0						;-- code virtual address (entry point)
	data-ptr:		0						;-- data virtual address
	headers-size:	none					;-- size of all leading ELF headers (ehdr + phdrs)
	code-size:		none					;-- size of the code segment (code section)
	data-size:		none					;-- size of the data segment (all non-code sections)
	shdr-offset:	0						;-- section header table file offset

	elf-header: make struct! [				;-- (Elf32_Ehdr)
		ident-mag0			[char!]			;-- 0x7F (EI_MAG0)
		ident-mag1			[char!]			;-- "E" (EI_MAG1)
		ident-mag2			[char!]			;-- "L" (EI_MAG2)
		ident-mag3			[char!]			;-- "F" (EI_MAG3)
		ident-class			[char!]			;-- file class (see DEFS/class)
		ident-data			[char!]			;-- data encoding (see DEFS/encoding)
		ident-version		[char!]			;-- file version (see DEFS/version)
		ident-pad0			[char!]
		ident-pad1			[integer!]
		ident-pad2			[integer!]
		type				[short]
		machine				[short]
		version				[integer!]
		entry				[integer!]
		phoff				[integer!]
		shoff				[integer!]		;-- offset from the beginning of the file to the shdr table
		flags				[integer!]
		ehsize				[short]
		phentsize			[short]
		phnum				[short]
		shentsize			[short]			;-- the size in bytes of a shdr table entry (== shdr-size)
		shnum				[short]			;-- how many entries the shdr table contains
		shstrndx			[short]			;-- shdr table entry index for the section name string table (shstrtab)
	] none

	program-header: make struct! [			;-- (Elf32_Phdr)
		type				[integer!]
		offset				[integer!]
		vaddr				[integer!]
		paddr				[integer!]
		filesz				[integer!]
		memsz				[integer!]
		flags				[integer!]
		align				[integer!]
	] none

	section-header: make struct! [			;-- (Elf32_Shdr)
		name				[integer!]		;-- index into the section header string table section
		type				[integer!]		;-- (see DEFS/section-type)
		flags				[integer!]
		addr				[integer!]
		offset				[integer!]
		size				[integer!]
		link				[integer!]
		info				[integer!]
		addralign			[integer!]
		entsize				[integer!]
	] none

	ehdr-size: length? third elf-header
	phdr-size: length? third program-header
	shdr-size: length? third section-header

	pointer: make struct! [
		value [integer!]							;-- 32/64-bit, watch out for endianess!!
	] none

	pad4: func [buffer [any-string!]][
		head insert/dup tail buffer null 3 and negate ((length? buffer) // 4)
	]

	calculate-offsets: func [job][
		pad4 job/sections/code/2					;-- make sure code section's end is aligned to 4 bytes

		headers-size: ehdr-size + (2 * phdr-size)  ; @@ FIX_SEGMENTS currently we always use 2 segments

		code-ptr: base-ptr + headers-size
		code-size: length? job/sections/code/2

		data-ptr: code-ptr + code-size
		data-size: 0
		foreach [name spec] job/sections [
			if name <> 'code [
				data-size: data-size + length? spec/2
			]
		]

		shdr-offset: headers-size + code-size + data-size
	]

	resolve-data-refs: func [job /local code][
		code: job/sections/code/2

		foreach [name spec] job/symbols [
			if all [spec/1 = 'global not empty? spec/3][
				pointer/value: data-ptr + spec/2
				foreach ref spec/3 [change at code ref third pointer]
			]
		]
	]

	build-data-header: func [job [object!] /local ph][
		ph: make struct! program-header none

		ph/type:	defs/segment-type/load
		ph/offset:	data-ptr - base-ptr
		ph/vaddr:	data-ptr
		ph/paddr:	ph/vaddr
		ph/filesz:	data-size
		ph/memsz:	ph/filesz						;@@ not sure about the alignment requirement?
		ph/flags:	defs/segment-access/data
		ph/align:	page-size

		append job/buffer third ph
	]

	build-code-header: func [job [object!] /local ph][
		ph: make struct! program-header none

		ph/type:	defs/segment-type/load
		ph/offset:	0
		ph/vaddr:	base-ptr
		ph/paddr:	ph/vaddr
		ph/filesz:	code-ptr - base-ptr + code-size
		ph/memsz:	ph/filesz						;@@ not sure about the alignment requirement?
		ph/flags:	defs/segment-access/code
		ph/align:	page-size

		append job/buffer third ph
	]

	build-elf-header: func [job [object!] /local target-def target-machine target-encoding eh][
		target-def: find defs/target job/target
		target-machine: select defs/machine target-def/2
		target-encoding: select defs/encoding target-def/3

		eh: make struct! elf-header none
		eh/ident-mag0:		#"^(7F)"
		eh/ident-mag1:		#"E"
		eh/ident-mag2:		#"L"
		eh/ident-mag3:		#"F"
		eh/ident-class:		to-char defs/class/c-32-bit
		eh/ident-data:		to-char target-encoding
		eh/ident-version:	to-char 1					;-- 0: invalid, 1: current
		eh/type:			defs/file-type/executable	;TBD: switch on job/type
		eh/machine:			target-machine
		eh/version:			1							; EV_CURRENT
		eh/entry:			code-ptr
		eh/phoff:			ehdr-size
		eh/shoff:			shdr-offset
		eh/flags:			0
		eh/ehsize:			ehdr-size
		eh/phentsize:		phdr-size
		eh/phnum:			2 ; @@ FIX_SEGMENTS currently we always use 2 segments
		eh/shentsize:		shdr-size
		eh/shnum:			4 ; (length? job/sections) / 2
		eh/shstrndx:		3 ; @@ compute!

		append job/buffer third eh
	]

	build: func [job [object!]][

		remove/part find job/sections 'import 2		;@@ (to be removed once 'import supported)

		generate-shstrtab job

		calculate-offsets job						;-- calculate section offsets/vaddrs
		print code-size

		resolve-data-refs job						;-- resolve data references

		build-elf-header job						;-- emit elf headers
		build-code-header job
		build-data-header job

		foreach [name spec] job/sections [			;-- emit all section contents
			append job/buffer spec/2
		]

		build-section-headers job
	]

	generate-shstrtab: func [job [object!] /local data][
		; The "shstrtab" is a section holding section names in an ELF string
		; table. String tables start with a null character and then hold
		; null-terminated character sequences.
		data: copy #{00}
		foreach name extract defs/sections-table 3 [
			repend data [name #{00}]
		]
		append job/sections compose/deep [shstrtab [- (data)]]
	]

	build-section-headers: func [job [object!] /local sh shstrtab-section-size data-section-size][
		data-section-size: length? job/sections/data/2
		shstrtab-section-size: length? job/sections/shstrtab/2
		; @@ assumes:
		; - DATA segment is right before shdr table, and
		; - shstrtab section is last in DATA segment
		shstrtab-section-offset: shdr-offset - shstrtab-section-size

		sh: make struct! section-header none		;-- NULL section (mandatory)
		sh/type: defs/section-type/null
		append job/buffer third sh

		sh: make struct! section-header none		;-- .text
		sh/name:		1 ; @@ offset into shrstab (compute from sections-table)
		sh/type:		defs/section-type/prog-bits ; @@ lookup in sections-table
		sh/flags:		6 ; @@ lookup in sections-table
		sh/addr:		code-ptr
		sh/offset:		code-ptr - base-ptr
		sh/size:		code-size
		sh/link:		0 ; not used for SHT_PROGBITS
		sh/info:		0 ; not used for SHT_PROGBITS
		sh/addralign:	4
		sh/entsize:		0 ; not used for .text
		append job/buffer third sh

		sh: make struct! section-header none		;-- .data
		sh/name:		7 ; @@ offset into shrstab (compute from sections-table)
		sh/type:		defs/section-type/prog-bits ; @@ lookup in sections-table
		sh/flags:		3 ; @@ lookup in sections-table
		sh/addr:		data-ptr
		sh/offset:		data-ptr - base-ptr
		sh/size:		data-size
		sh/link:		0 ; not used for SHT_PROGBITS
		sh/info:		0 ; not used for SHT_PROGBITS
		sh/addralign:	4
		sh/entsize:		0 ; not used for .data
		append job/buffer third sh

		sh: make struct! section-header none		;-- .shstrtab
		sh/name:		13 ; @@ offset into shrstab (compute from sections-table)
		sh/type:		defs/section-type/str-tab ; @@ lookup in sections-table
		sh/flags:		0 ; @@ lookup in sections-table
		sh/addr:		0 ; won't appear in the memory image
		sh/offset:		shstrtab-section-offset
		sh/size:		shstrtab-section-size
		sh/link:		0 ; not used for SHT_STRTAB
		sh/info:		0 ; not used for SHT_STRTAB
		sh/addralign:	1 ; no alignment constraints
		sh/entsize:		0 ; not used for .shstrtab
		append job/buffer third sh
	]
]
