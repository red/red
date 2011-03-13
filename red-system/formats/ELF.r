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
		s-type [
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
	
	memory-align:		4096				;-- system page size
	;file-align: 		512					;-- better keep it < memory-align

	ehdr: make struct! [
		ident-mag0			[char!]		; 0x7F
		ident-mag1			[char!]		; "E"
		ident-mag2			[char!]		; "L"
		ident-mag3			[char!]		; "F"
		ident-class			[char!]		; file class
		ident-data			[char!]		; data encoding
		ident-version		[char!]		; file version
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

	phdr: make struct! [
		type				[integer!]
		offset				[integer!]
		vaddr				[integer!]
		paddr				[integer!]
		filesz				[integer!]
		memsz				[integer!]
		flags				[integer!]
		align				[integer!]
	] none

	ehdr-size: length? third ehdr
	phdr-size: length? third phdr

	build-elf-header: func [job [object!] /local machine eh][
		machine: find defs/machine job/target

		eh: make struct! ehdr none
		eh/ident-mag0:		#"^(7F)"
		eh/ident-mag1:		#"E"
		eh/ident-mag2:		#"L"
		eh/ident-mag3:		#"F"
		eh/ident-class:		to char! defs/class/c-32-bit
		eh/ident-data:		to char! defs/encoding/LSB	;TBD: make it target-dependent
		eh/ident-version:	to char! 1					;-- 0: invalid, 1: current
		eh/type:			defs/file-type/executable	;TBD: switch on jobs/
		eh/machine:			machine/2
		eh/version:			1							; EV_CURRENT
		eh/entry:			defs/image/base-address + ehdr-size + phdr-size ; @@
		eh/phoff:			ehdr-size
		eh/shoff:			0
		eh/flags:			0
		eh/ehsize:			ehdr-size
		eh/phentsize:		phdr-size
		eh/phnum:			1 ; @@
		eh/shentsize:		0
		eh/shnum:			0
		eh/shstrndx:		0

		append job/buffer third eh
	]

	build-program-header: func [job [object!] /local code-size ph] [
		code-size: length? job/sections/code/2

		ph: make struct! phdr none
		ph/type:			1				; PT_LOAD
		ph/offset:			0
		ph/vaddr:			defs/image/base-address ; @@ $$
		ph/paddr:			defs/image/base-address ; @@ $$
		ph/filesz:			ehdr-size + phdr-size + code-size ; @@
		ph/memsz:			ph/filesz
		ph/flags:			5				; PF_R | PF_X
		ph/align:			4096
		append job/buffer third ph
	]

	build: func [job [object!]][
	
		build-elf-header job
		build-program-header job

		foreach [name spec] job/sections [
			append job/buffer spec/2
		]

		probe job/buffer
	]
]