REBOL [
	Title:   "Red/System ELF object reader"
	Author:  "Nenad Rakocevic"
	File: 	 %ELF-obj.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Parses ELF32 i386 and ARM relocatable object files (ET_REL, EM_386 /
		EM_ARM) for static linking. Exposes the same context interface as
		COFF.r so the static linker can drive either format through one
		`reader` handle.
	}
]

elf-obj: context [

	;-- ===== Constants =====

	ET_REL:			1				;-- relocatable object
	EM_386:			3				;-- Intel 80386
	EM_ARM:			40				;-- ARM (32-bit)

	SHT_PROGBITS:	1				;-- program data (.text/.data/.rodata)
	SHT_SYMTAB:		2				;-- symbol table
	SHT_STRTAB:		3				;-- string table
	SHT_NOBITS:		8				;-- uninitialized data (.bss)
	SHT_REL:		9				;-- relocations without addends
	SHT_GROUP:		17				;-- COMDAT / section group

	GRP_COMDAT:		1				;-- group is a COMDAT (drop duplicates)

	SHF_WRITE:		1
	SHF_ALLOC:		2
	SHF_EXECINSTR:	4

	STB_LOCAL:		0
	STB_GLOBAL:		1
	STB_WEAK:		2

	SHN_LORESERVE:	65280			;-- 0xFF00 — indices >= this are reserved

	R_386_NONE:		0
	R_386_32:		1				;-- direct 32-bit (S + A)
	R_386_PC32:		2				;-- PC-relative 32-bit (S + A - P)

	R_ARM_NONE:			0
	R_ARM_PC24:			1			;-- 24-bit branch immediate (legacy)
	R_ARM_ABS32:		2			;-- direct 32-bit (S + A)
	R_ARM_REL32:		3			;-- PC-relative 32-bit (S + A - P)
	R_ARM_CALL:			28			;-- BL/BLX 24-bit immediate
	R_ARM_JUMP24:		29			;-- B 24-bit immediate
	R_ARM_TARGET1:		38			;-- treated as R_ARM_ABS32 on Linux
	R_ARM_V4BX:			40			;-- ARMv4 BX hint — no-op here
	R_ARM_MOVW_ABS_NC:	43			;-- MOVW: bits[15:0]  of (S + A)
	R_ARM_MOVT_ABS:		44			;-- MOVT: bits[31:16] of (S + A)

	;-- e_machine of the most recently parsed object (EM_386 | EM_ARM). The
	;-- relocation type numbers overlap between the two architectures, so
	;-- reloc-kind dispatches on this.
	machine: 0

	;-- ===== Low-level binary access (1-based positions) =====

	byte-at: func [bin [binary!] pos [integer!]][
		to integer! pick bin pos
	]

	u16-le: func [bin [binary!] pos [integer!]][
		to integer! reverse copy/part at bin pos 2
	]

	u32-le: func [bin [binary!] pos [integer!]][
		to integer! reverse copy/part at bin pos 4
	]

	i32-le: func [bin [binary!] pos [integer!]][
		u32-le bin pos
	]

	read-cstring: func [bin [binary!] pos [integer!] /local out b i][
		out: copy ""
		i: pos
		while [all [i <= length? bin  (b: byte-at bin i) <> 0]][
			append out to char! b
			i: i + 1
		]
		out
	]

	;-- ===== Classification =====

	;-- Map an ELF section's type+flags to a merge bucket.
	section-kind: func [sh-type [integer!] sh-flags [integer!]][
		case [
			sh-type = SHT_NOBITS [
				either (sh-flags and SHF_ALLOC) <> 0 ['bss][none]
			]
			sh-type = SHT_PROGBITS [
				case [
					(sh-flags and SHF_ALLOC) = 0       [none]	;-- .comment, debug, ...
					(sh-flags and SHF_EXECINSTR) <> 0  ['code]
					(sh-flags and SHF_WRITE) <> 0      ['data]
					true                               ['rdata]
				]
			]
			true [none]										;-- symtab/strtab/rel/note/...
		]
	]

	;-- Abstract relocation kind shared with COFF.r's reader interface.
	;-- `arm-call` / `arm-movw` / `arm-movt` are ARM instruction-field
	;-- relocations; the static linker re-encodes them in apply-relocs.
	reloc-kind: func [type [integer!]][
		either machine = EM_ARM [
			case [
				type = R_ARM_ABS32        ['abs32]
				type = R_ARM_TARGET1      ['abs32]
				type = R_ARM_REL32        ['pc32]
				any [
					type = R_ARM_CALL  type = R_ARM_JUMP24  type = R_ARM_PC24
				]                         ['arm-call]
				type = R_ARM_MOVW_ABS_NC  ['arm-movw]
				type = R_ARM_MOVT_ABS     ['arm-movt]
				any [type = R_ARM_NONE  type = R_ARM_V4BX]  ['none]
				true                      ['unsupported]
			]
		][
			case [
				type = R_386_32   ['abs32]
				type = R_386_PC32 ['pc32]
				type = R_386_NONE ['none]
				true              ['unsupported]
			]
		]
	]

	;-- ELF stores REL relocations with the addend in place; the PC-rel
	;-- addend already carries the next-instruction bias, so no extra bias is
	;-- applied to flat fields (unlike COFF's REL32). ARM branch immediates
	;-- carry their own bias inside the instruction field (see apply-relocs).
	pc-bias: 0

	;-- ===== Main entry points =====

	;-- Parse an in-memory buffer as an ELF32 i386 relocatable object.
	;-- Returns an object! with [path sections symbols] or NONE if the buffer
	;-- is not an ELF32/LSB/EM_386/ET_REL object.
	;--
	;-- sections : block of [name kind flags data size relocs base-kind
	;--            base-offset] — index i corresponds to ELF section header
	;--            i-1, so sections/1 is the SHN_UNDEF null header.
	;-- symbols  : block of [name value section-idx class] — one per .symtab
	;--            slot, in order. section-idx is st_shndx + 1 (a 1-based
	;--            index into `sections`); class is the raw st_info byte.
	load-from-bin: func [
		bin [binary!] path
		/local e-type e-machine e-shoff e-shnum e-shstrndx headers i p
			shstr shstrtab sections h name kind data
			symtab-hdr strtab-hdr strtab symbols n-syms st-name st-value
			st-info st-shndx target-sec rel-off n-rel j rp r-offset r-info
			gflag sig-sym key n-grp sec-idx member-sec
	][
		;-- ELF header (52 bytes)
		if (length? bin) < 52 [return none]
		if (copy/part bin 4) <> #{7F454C46} [return none]	;-- \x7F E L F
		if (byte-at bin 5) <> 1 [return none]				;-- ELFCLASS32
		if (byte-at bin 6) <> 1 [return none]				;-- ELFDATA2LSB
		e-type:    u16-le bin 17
		e-machine: u16-le bin 19
		if e-type <> ET_REL [return none]
		if not any [e-machine = EM_386  e-machine = EM_ARM][return none]
		machine: e-machine
		e-shoff:    u32-le bin 33
		e-shnum:    u16-le bin 49
		e-shstrndx: u16-le bin 51

		;-- Section headers (40 bytes each) — raw fields
		headers: copy []
		i: 0
		while [i < e-shnum][
			p: e-shoff + (i * 40) + 1
			append/only headers reduce [
				u32-le bin p					;-- 1 sh_name
				u32-le bin (p + 4)				;-- 2 sh_type
				u32-le bin (p + 8)				;-- 3 sh_flags
				u32-le bin (p + 16)				;-- 4 sh_offset
				u32-le bin (p + 20)				;-- 5 sh_size
				u32-le bin (p + 24)				;-- 6 sh_link
				u32-le bin (p + 28)				;-- 7 sh_info
				u32-le bin (p + 32)				;-- 8 sh_addralign
			]
			i: i + 1
		]

		;-- Section name string table
		shstr:    pick headers (e-shstrndx + 1)
		shstrtab: copy/part at bin (shstr/4 + 1) shstr/5

		;-- Build the section list (index i == ELF header i-1)
		sections: copy []
		foreach h headers [
			name: read-cstring shstrtab (h/1 + 1)
			kind: section-kind h/2 h/3
			data: either all [kind  kind <> 'bss  h/5 > 0][
				copy/part at bin (h/4 + 1) h/5
			][make binary! 0]
			append/only sections reduce [
				name kind (max 1 h/8) data h/5 (make block! 4) 'none 0  none
			]
		]

		;-- Symbol table (16 bytes per Elf32_Sym)
		symtab-hdr: none
		foreach h headers [
			if all [h/2 = SHT_SYMTAB none? symtab-hdr][symtab-hdr: h]
		]
		symbols: copy []
		if symtab-hdr [
			strtab-hdr: pick headers (symtab-hdr/6 + 1)
			strtab:     copy/part at bin (strtab-hdr/4 + 1) strtab-hdr/5
			n-syms:     to integer! symtab-hdr/5 / 16
			i: 0
			while [i < n-syms][
				p: symtab-hdr/4 + (i * 16) + 1
				st-name:  u32-le bin p
				st-value: u32-le bin (p + 4)
				st-info:  byte-at bin (p + 12)
				st-shndx: u16-le bin (p + 14)
				append/only symbols reduce [
					read-cstring strtab (st-name + 1)	;-- name
					st-value							;-- value
					st-shndx + 1						;-- section-idx (1-based pick)
					st-info								;-- class (st_info)
				]
				i: i + 1
			]
		]

		;-- COMDAT groups: an SHT_GROUP section's content is a flag word
		;-- followed by section indices that share a key (the signature
		;-- symbol's name, named by sh_info). The static linker drops a
		;-- group whose key has already been merged.
		foreach h headers [
			if all [h/2 = SHT_GROUP  h/5 >= 4  symtab-hdr][
				gflag: u32-le bin (h/4 + 1)
				if (gflag and GRP_COMDAT) <> 0 [
					sig-sym: pick symbols (h/7 + 1)
					if sig-sym [
						key: first sig-sym
						n-grp: to integer! (h/5 - 4) / 4
						j: 0
						while [j < n-grp][
							sec-idx: u32-le bin (h/4 + (j + 1) * 4 + 1)
							member-sec: pick sections (sec-idx + 1)
							if member-sec [poke member-sec 9 key]
							j: j + 1
						]
					]
				]
			]
		]

		;-- Relocations: attach each .rel.* section's entries to its target.
		foreach h headers [
			if h/2 = SHT_REL [
				target-sec: pick sections (h/7 + 1)		;-- sh_info = target section
				if target-sec [
					rel-off: h/4
					n-rel:   to integer! h/5 / 8
					j: 0
					while [j < n-rel][
						rp: rel-off + (j * 8) + 1
						r-offset: u32-le bin rp
						r-info:   u32-le bin (rp + 4)
						append/only target-sec/6 reduce [
							r-offset						;-- r-va
							shift/logical r-info 8			;-- r-sym (symtab index)
							r-info and 255					;-- r-type
						]
						j: j + 1
					]
				]
			]
		]

		make object! compose/only [
			path:     (path)
			sections: (sections)
			symbols:  (symbols)
		]
	]

	;-- Load an ELF32 i386 object file from disk. Halts on invalid input.
	load: func [path [file!] /local bin obj][
		bin: read/binary path
		obj: load-from-bin bin path
		if none? obj [
			print ["*** Linker Error: not a supported ELF32 object (i386 or ARM):" path]
			halt
		]
		obj
	]

	;-- ===== Accessors (mirror COFF.r's interface) =====

	sec-name:        func [s [block!]][s/1]
	sec-kind:        func [s [block!]][s/2]
	sec-align:       func [s [block!]][s/3]
	sec-data:        func [s [block!]][s/4]
	sec-size:        func [s [block!]][s/5]
	sec-relocs:      func [s [block!]][s/6]
	sec-base-kind:   func [s [block!]][s/7]
	sec-base-offset: func [s [block!]][s/8]
	sec-comdat-key:  func [s [block!]][s/9]		;-- group key (string) or none

	set-sec-base: func [s [block!] kind [word!] offset [integer!]][
		poke s 7 kind
		poke s 8 offset
	]

	sym-name:  func [sym [block!]][sym/1]
	sym-value: func [sym [block!]][sym/2]
	sym-sect:  func [sym [block!]][sym/3]
	sym-class: func [sym [block!]][sym/4]

	;-- st_info binding: STB_GLOBAL / STB_WEAK count as external linkage.
	sym-bind: func [sym [block!]][shift/logical sym/4 4]

	;-- TRUE if the symbol is a weak definition (STB_WEAK).
	sym-weak?: func [sym [block!]][STB_WEAK = shift/logical sym/4 4]

	;-- A defined external: global/weak binding, bound to a real section.
	is-defined-external?: func [sym [block!] /local bind][
		bind: sym-bind sym
		all [
			any [bind = STB_GLOBAL  bind = STB_WEAK]
			(sym/3) > 1										;-- section-idx 1 == SHN_UNDEF
			(sym/3) <= SHN_LORESERVE
		]
	]

	;-- An undefined external: global/weak binding, SHN_UNDEF.
	is-undefined-external?: func [sym [block!] /local bind][
		bind: sym-bind sym
		all [
			any [bind = STB_GLOBAL  bind = STB_WEAK]
			(sym/3) = 1										;-- section-idx 1 == SHN_UNDEF
		]
	]
]
