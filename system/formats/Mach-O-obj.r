REBOL [
	Title:   "Red/System Mach-O object reader"
	Author:  "Nenad Rakocevic"
	File: 	 %Mach-O-obj.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Parses Mach-O i386 relocatable object files (MH_OBJECT, CPU_TYPE_I386)
		for static linking. Exposes the same context interface as COFF.r and
		ELF-obj.r so the static linker drives any format through one `reader`
		handle. Only GENERIC_RELOC_VANILLA relocations are supported; scattered
		relocations raise an "unsupported relocation" link error.
	}
]

macho-obj: context [

	;-- ===== Constants =====

	MH_MAGIC:		to integer! #{FEEDFACE}			;-- 32-bit little-endian magic
	CPU_TYPE_I386:	7
	MH_OBJECT:		1

	LC_SEGMENT:		1
	LC_SYMTAB:		2

	S_ZEROFILL:		1								;-- section type: uninitialized (.bss)
	S_GB_ZEROFILL:	12								;-- section type: large uninitialized
	S_ATTR_PURE_INSTRUCTIONS: to integer! #{80000000}

	N_STAB:			to integer! #{00E0}				;-- debug-symbol mask
	N_TYPE:			to integer! #{000E}				;-- symbol-type mask
	N_EXT:			1								;-- external-linkage bit
	N_UNDF:			0								;-- undefined  (N_TYPE value)
	N_SECT:			to integer! #{000E}				;-- defined in a section (N_TYPE value)

	R_SCATTERED:	to integer! #{80000000}			;-- scattered relocation flag
	GENERIC_RELOC_VANILLA: 0

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

	;-- Read a fixed-width (null-padded) name field — segname / sectname.
	read-fixed-name: func [bin [binary!] pos [integer!] len [integer!] /local out i b][
		out: copy ""
		i: 0
		while [all [i < len  (b: byte-at bin (pos + i)) <> 0]][
			append out to char! b
			i: i + 1
		]
		out
	]

	;-- ===== Classification =====

	;-- Map a Mach-O section to a merge bucket from its segment/section name
	;-- and flags (the low byte of flags is the section type).
	section-kind: func [segname [string!] sectname [string!] flags [integer!] /local stype][
		stype: flags and 255
		case [
			any [stype = S_ZEROFILL  stype = S_GB_ZEROFILL]      ['bss]
			(flags and S_ATTR_PURE_INSTRUCTIONS) <> 0            ['code]
			sectname = "__text"                                  ['code]
			segname = "__TEXT"                                   ['rdata]	;-- __cstring/__const
			segname = "__DATA"                                   ['data]
			true [none]
		]
	]

	;-- Abstract relocation kind. The type slot packs the Mach-O fields as
	;-- (r_type << 4) | (r_length << 2) | (r_pcrel << 1); -1 marks a
	;-- scattered / otherwise-unsupported relocation.
	reloc-kind: func [t [integer!] /local gtype len pcrel][
		if t < 0 [return 'unsupported]
		pcrel: (shift/logical t 1) and 1
		len:   (shift/logical t 2) and 3
		gtype: shift/logical t 4
		case [
			len <> 2                       ['unsupported]	;-- only 4-byte fields
			gtype = GENERIC_RELOC_VANILLA  [either pcrel = 1 ['pc32]['abs32]]
			true                           ['unsupported]	;-- SECTDIFF / PAIR / TLV
		]
	]

	;-- Mach-O i386 stores a pcrel field's displacement relative to the
	;-- containing section's start; the static linker folds r_address back in
	;-- (see linker-static.r/apply-relocs) so the post-adjustment bias is 0.
	pc-bias: 0

	;-- ===== Main entry point =====

	;-- Parse an in-memory buffer as a Mach-O i386 relocatable object.
	;-- Returns an object! with [path sections symbols] or NONE if the buffer
	;-- is not a CPU_TYPE_I386 MH_OBJECT.
	;--
	;-- sections : block of [name kind flags data size relocs base-kind
	;--            base-offset], numbered 1..N to match nlist n_sect.
	;-- symbols  : block of [name value section-idx class] — the nlist
	;--            entries in order, followed by one synthetic section symbol
	;--            ["" 0 k 0] per section so non-extern (section-based)
	;--            relocations can be resolved through the shared accessors.
	load-from-bin: func [
		bin [binary!] path
		/local ncmds sizeofcmds lc-pos i cmd cmdsize sections symbols
			seg-nsects sec-pos j segname sectname flags kind sec-off sec-size
			data symtab-off symtab-cnt str-off n-real k p
			sn nt ns sec relocs r-pos r-i w0 w1 r-extern r-sym
	][
		;-- Mach header (28 bytes)
		if (length? bin) < 28 [return none]
		if (u32-le bin 1) <> MH_MAGIC [return none]
		if (u32-le bin 5) <> CPU_TYPE_I386 [return none]
		if (u32-le bin 13) <> MH_OBJECT [return none]
		ncmds:       u32-le bin 17
		sizeofcmds:  u32-le bin 21

		;-- Pass 1: walk load commands, collecting sections and the symtab.
		sections:   copy []
		symtab-off: 0
		symtab-cnt: 0
		str-off:    0
		lc-pos: 29											;-- first load command (offset 28)
		i: 0
		while [i < ncmds][
			cmd:     u32-le bin lc-pos
			cmdsize: u32-le bin (lc-pos + 4)
			case [
				cmd = LC_SEGMENT [
					seg-nsects: u32-le bin (lc-pos + 48)
					j: 0
					while [j < seg-nsects][
						sec-pos:  lc-pos + 56 + (j * 68)
						sectname: read-fixed-name bin sec-pos 16
						segname:  read-fixed-name bin (sec-pos + 16) 16
						sec-size: u32-le bin (sec-pos + 36)
						sec-off:  u32-le bin (sec-pos + 40)
						flags:    u32-le bin (sec-pos + 56)
						kind:     section-kind segname sectname flags
						data: either all [kind  kind <> 'bss  sec-size > 0][
							copy/part at bin (sec-off + 1) sec-size
						][make binary! 0]
						append/only sections reduce [
							sectname kind
							(shift/left 1 (u32-le bin (sec-pos + 44)))	;-- 3 alignment (bytes)
							data sec-size
							(make block! 4) 'none 0
							;-- reloff/nreloc stashed in slots 9/10 for pass 3
							u32-le bin (sec-pos + 48)
							u32-le bin (sec-pos + 52)
						]
						j: j + 1
					]
				]
				cmd = LC_SYMTAB [
					symtab-off: u32-le bin (lc-pos + 8)
					symtab-cnt: u32-le bin (lc-pos + 12)
					str-off:    u32-le bin (lc-pos + 16)
				]
			]
			lc-pos: lc-pos + cmdsize
			i: i + 1
		]

		;-- Symbol table (nlist, 12 bytes per entry)
		symbols: copy []
		i: 0
		while [i < symtab-cnt][
			p:  symtab-off + (i * 12) + 1
			sn: u32-le bin p							;-- n_strx
			nt: byte-at bin (p + 4)						;-- n_type
			ns: byte-at bin (p + 5)						;-- n_sect
			append/only symbols reduce [
				read-cstring bin (str-off + sn + 1)		;-- name
				u32-le bin (p + 8)						;-- n_value
				ns										;-- section-idx (1-based, 0 = NO_SECT)
				nt										;-- class (n_type)
			]
			i: i + 1
		]
		n-real: symtab-cnt

		;-- One synthetic section symbol per section, so that non-extern
		;-- (section-number) relocations resolve through sym-sect.
		k: 1
		while [k <= length? sections][
			append/only symbols reduce ["" 0 k 0]
			k: k + 1
		]

		;-- Pass 3: read each section's relocations.
		foreach sec sections [
			relocs: sec/6
			r-i: 0
			while [r-i < sec/10][						;-- nreloc
				r-pos: sec/9 + (r-i * 8) + 1			;-- reloff
				w0: u32-le bin r-pos
				either (w0 and R_SCATTERED) <> 0 [
					append/only relocs reduce [(w0 and 16777215) 0 -1]	;-- scattered: unsupported
				][
					w1: u32-le bin (r-pos + 4)
					r-extern: (shift/logical w1 27) and 1
					r-sym: either r-extern = 1 [
						w1 and 16777215						;-- symbol-table index (0-based)
					][
						;-- section number (1-based) -> synthetic symbol index
						n-real + (w1 and 16777215) - 1
					]
					append/only relocs reduce [
						w0									;-- r_address
						r-sym
						;-- pack (r_type << 4) | (r_length << 2) | (r_pcrel << 1)
						(shift/left (shift/logical w1 28) 4)
							or (shift/left ((shift/logical w1 25) and 3) 2)
							or (shift/left ((shift/logical w1 24) and 1) 1)
					]
				]
				r-i: r-i + 1
			]
		]

		make object! compose/only [
			path:     (path)
			sections: (sections)
			symbols:  (symbols)
		]
	]

	;-- Load a Mach-O i386 object file from disk. Halts on invalid input.
	load: func [path [file!] /local bin obj][
		bin: read/binary path
		obj: load-from-bin bin path
		if none? obj [
			print ["*** Linker Error: not a Mach-O i386 object:" path]
			halt
		]
		obj
	]

	;-- ===== Accessors (mirror COFF.r / ELF-obj.r) =====

	sec-name:        func [s [block!]][s/1]
	sec-kind:        func [s [block!]][s/2]
	sec-align:       func [s [block!]][s/3]
	sec-data:        func [s [block!]][s/4]
	sec-size:        func [s [block!]][s/5]
	sec-relocs:      func [s [block!]][s/6]
	sec-base-kind:   func [s [block!]][s/7]
	sec-base-offset: func [s [block!]][s/8]

	set-sec-base: func [s [block!] kind [word!] offset [integer!]][
		poke s 7 kind
		poke s 8 offset
	]

	sym-name:  func [sym [block!]][sym/1]
	sym-value: func [sym [block!]][sym/2]
	sym-sect:  func [sym [block!]][sym/3]
	sym-class: func [sym [block!]][sym/4]

	;-- A defined external: external linkage, N_SECT type, real section.
	is-defined-external?: func [sym [block!]][
		all [
			(sym/4 and N_STAB) = 0
			(sym/4 and N_EXT) <> 0
			(sym/4 and N_TYPE) = N_SECT
			(sym/3) > 0
		]
	]

	;-- An undefined external: external linkage, N_UNDF type.
	is-undefined-external?: func [sym [block!]][
		all [
			(sym/4 and N_STAB) = 0
			(sym/4 and N_EXT) <> 0
			(sym/4 and N_TYPE) = N_UNDF
		]
	]
]
