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
		machine [
		;--  CPU -------- ID ------ Endianness
			IA32			3			1	; EM_386, ELFDATA2LSB
		]
		class [
			none			0
			c-32-bit		1
			c-64-bit		2
		]
		encoding [
			none			0
			LSB				1				;-- little endian data encoding
			MSB				2				;-- big endian data encoding
		]
		file-type [
			none			0				;-- no file type
			relocatable		1				;-- relocatable file
			executable		2				;-- executable file
			shared			3				;-- shared object file
			core			4				;-- core file
			lo-proc			#{FF00}			;-- processor-specific
			hi-proc			#{FFFF}			;-- processor-specific
		]
		segment-type [
			null			0				;-- ignore entry
			load			1				;-- loadable segment
			dynamic			2				;-- dynamic linking information
			interp			3				;-- interpreter path name
			note			4				;-- notes/comments
			shlib			5				;-- reserved (unused)
			phdr			6				;-- program header table location
			lo-proc			#{70000000}		;-- reserved (proc-specific)
			hi-proc			#{7FFFFFFF}		;-- reserved (proc-specific)
		]
		segment-flags [						;-- @@ missing from official docs ?!? @@
			executable		1
			write			2
			read			4
		]
		segment-access [
			CODE			5				;-- [read executable]	; 1st part of LOAD segment
			DATA			6				;-- [read write]		; 2nd part of LOAD segment
			IMPORT			6				;-- [read write]		; DYNAMIC segment
		]
		section-type [
			null			0				;-- mark inactive section header
			prog-bits		1				;-- flags
			sym-tab			2				;-- symbol table (for link editing)
			str-tab			3				;-- string table
			rela			4				;-- relocations with addends
			hash			5				;-- symbol hash table
			dynamic			6				;-- dynamic linking
			note			7				;-- notes/comments
			no-bits			8				;-- ??
			rel				9				;-- relocations without addends
			shlib			10				;-- reserved (unused)
			dyn-sym			11				;-- symbol table (dynamic linking)
			lo-proc			#{70000000}		;-- reserved (proc-specific)
			hi-proc			#{7FFFFFFF}		;-- reserved (proc-specific)
			lo-user			#{80000000}		;-- reserved (lower bound reserved indexes)
			hi-user			#{8FFFFFFF}		;-- reserved (upper bound reserved indexes)
		]
		s-flags [
			write			1				;-- writable data
			alloc			2				;-- requires memory during program execution
			exec			4				;-- executable code
			mask-proc		#{F0000000}		;-- proc-specific semantics
		]
	]
	
	page-size:	 4096						;-- system page size
	ptr:		 0							;-- virtual address global pointer
	base-ptr:	 defs/image/base-address	;-- base virtual address
	code-ptr:	 0							;-- code entry point
	data-ptr:	 0							;-- data virtual address

	elf-header: make struct! [
		ident-mag0			[char!]			;-- 0x7F
		ident-mag1			[char!]			;-- "E"
		ident-mag2			[char!]			;-- "L"
		ident-mag3			[char!]			;-- "F"
		ident-class			[char!]			;-- file class
		ident-data			[char!]			;-- data encoding
		ident-version		[char!]			;-- file version
		ident-pad0			[char!]
		ident-pad1			[integer!]
		ident-pad2			[integer!]
		type				[short]
		machine				[short]
		version				[integer!]
		entry				[integer!]
		phoff				[integer!]
		shoff				[integer!]
		flags				[integer!]
		ehsize				[short]
		phentsize			[short]
		phnum				[short]
		shentsize			[short]
		shnum				[short]
		shstrndx			[short]
	] none

	program-header: make struct! [
		type				[integer!]
		offset				[integer!]
		vaddr				[integer!]
		paddr				[integer!]
		filesz				[integer!]
		memsz				[integer!]
		flags				[integer!]
		align				[integer!]
	] none

	ehdr-size: length? third elf-header
	phdr-size: length? third program-header
	
	pointer: make struct! [
		value [integer!]							;-- 32/64-bit, watch out for endianess!!
	] none
	
	pad4: func [buffer [any-string!]][
		head insert/dup tail buffer null 3 and negate ((length? buffer) // 4)
	]
	
	calc-global-pointers: func [job][
		code-ptr: base-ptr + ehdr-size + (phdr-size * (length? job/sections) / 2)	
		
		pad4 job/sections/code/2					;-- make sure code section's end is aligned to 4 bytes
		data-ptr: code-ptr + length? job/sections/code/2
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
	
	build-data-header: func [job [object!] /local ph spec] [
		spec: job/sections/data
		ph: make struct! program-header none

		ph/type:	defs/segment-type/load
		ph/offset:  data-ptr - base-ptr
		ph/vaddr:   data-ptr
		ph/paddr:   ph/vaddr
		ph/filesz:  length? spec/2
		ph/memsz:   ph/filesz						;@@ not sure about the alignment requirement?
		ph/flags:	defs/segment-access/data
		ph/align:	page-size

		append job/buffer third ph
	]
	
	build-code-header: func [job [object!] /local ph spec] [
		spec: job/sections/code
		ph: make struct! program-header none
		
		ph/type:	defs/segment-type/load
		ph/offset:  0
		ph/vaddr:   base-ptr
		ph/paddr:   ph/vaddr
		ph/filesz:  code-ptr - base-ptr + length? spec/2
		ph/memsz:   ph/filesz						;@@ not sure about the alignment requirement?
		ph/flags:	defs/segment-access/code
		ph/align:	page-size
		
		append job/buffer third ph
	]
	
	build-elf-header: func [job [object!] /local machine eh][
		machine: find defs/machine job/target

		eh: make struct! elf-header none
		eh/ident-mag0:		#"^(7F)"
		eh/ident-mag1:		#"E"
		eh/ident-mag2:		#"L"
		eh/ident-mag3:		#"F"
		eh/ident-class:		to-char defs/class/c-32-bit
		eh/ident-data:		to-char defs/encoding/LSB	;TBD: make it target-dependent
		eh/ident-version:	to-char 1					;-- 0: invalid, 1: current
		eh/type:			defs/file-type/executable	;TBD: switch on job/type
		eh/machine:			machine/2
		eh/version:			1							; EV_CURRENT
		eh/entry:			code-ptr
		eh/phoff:			ehdr-size
		eh/shoff:			0
		eh/flags:			0
		eh/ehsize:			ehdr-size
		eh/phentsize:		phdr-size
		eh/phnum:			(length? job/sections) / 2	;-- sections are "segments" here
		eh/shentsize:		0
		eh/shnum:			0
		eh/shstrndx:		0

		append job/buffer third eh
	]

	build: func [job [object!]][
	
		remove/part find job/sections 'import 2		;@@ (to be removed once 'import supported)
		
		calc-global-pointers job
		
		build-elf-header job
		build-code-header job
		build-data-header job
		
		resolve-data-refs job						;-- resolve data references
		
		foreach [name spec] job/sections [			;-- concatenate all section contents		
			append job/buffer spec/2
		]
	]
]