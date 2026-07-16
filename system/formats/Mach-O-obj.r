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

	N_WEAK_DEF:		to integer! #{0080}				;-- n_desc bit: weak definition

	R_SCATTERED:	to integer! #{80000000}			;-- scattered relocation flag
	GENERIC_RELOC_VANILLA:        0
	GENERIC_RELOC_PAIR:           1
	GENERIC_RELOC_SECTDIFF:       2
	GENERIC_RELOC_LOCAL_SECTDIFF: 4

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

	;-- Serialize a 32-bit value as 4 little-endian bytes.
	le32-struct: make-struct [value [integer!]] none
	to-le32: func [n [integer!]][
		le32-struct/value: n
		form-struct le32-struct
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
		;-- NAME wins over the section-type byte: __eh_frame's type (9) and
		;-- __compact_unwind's (6) collide with S_MOD_INIT/S_*_POINTERS.
		case [
			sectname = "__eh_frame"        ['eh-frame]			;-- raw DWARF, found by name at runtime
			sectname = "__compact_unwind"  [none]				;-- Darwin compact unwind: we use DWARF
			sectname = "__gcc_except_tab"  ['rdata]				;-- LSDA (read-only)
			any [stype = S_ZEROFILL  stype = S_GB_ZEROFILL]      ['bss]
			stype = 9                                            ['init-array]	;-- S_MOD_INIT_FUNC_POINTERS
			stype = 10                                           [none]		;-- dtors-at-exit: not run (parity)
			any [stype = 6  stype = 7]                           ['nl-pointers]	;-- indirect symbol slots
			(flags and S_ATTR_PURE_INSTRUCTIONS) <> 0            ['code]
			sectname = "__text"                                  ['code]
			segname = "__TEXT"                                   ['rdata]	;-- __cstring/__const
			segname = "__DATA"                                   ['data]
			true [none]
		]
	]

	;-- Abstract relocation kind. The type slot packs the Mach-O fields as
	;-- (r_type << 4) | (r_length << 2) | (r_pcrel << 1); -1 marks a
	;-- scattered / otherwise-unsupported relocation. SECTDIFF and
	;-- LOCAL_SECTDIFF (always scattered, always followed by a PAIR entry
	;-- carrying the subtrahend) collapse to one `sectdiff` reloc that the
	;-- linker patches as a target-relative difference.
	reloc-kind: func [t [integer!] /local gtype len pcrel][
		if t < 0 [return 'unsupported]
		pcrel: (shift/logical t 1) and 1
		len:   (shift/logical t 2) and 3
		gtype: shift/logical t 4
		case [
			len <> 2                       ['unsupported]	;-- only 4-byte fields
			gtype = GENERIC_RELOC_VANILLA  [either pcrel = 1 ['pc32]['abs32]]
			any [
				gtype = GENERIC_RELOC_SECTDIFF
				gtype = GENERIC_RELOC_LOCAL_SECTDIFF
			]                              ['sectdiff]
			true                           ['unsupported]	;-- PAIR / TLV
		]
	]

	;-- Return the 1-based index of the section whose vmaddr range covers
	;-- `addr` (the absolute address from the .o's scratch layout), or NONE.
	sec-of-addr: func [obj [object!] addr [integer!] /local i va sz][
		i: 1
		foreach sec obj/sections [
			va: sec/9									;-- vmaddr
			sz: sec/5									;-- size
			if all [addr >= va  addr < (va + sz)][return i]
			i: i + 1
		]
		none
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
			sec-bases v
			s-type s-length s-pcrel r-va w0-p w1-p min-sect sub-sect sec-x
			min-off sub-off
			sec-stypes sec-res1 dysym-off dysym-cnt n-slots ent-pos
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
		;-- Parallel to `sections`: each section's vmaddr from its Mach-O
		;-- header. nlist n_value fields are absolute addresses within the
		;-- object's section layout, so we subtract the section base to
		;-- recover the section-relative offset COFF/ELF readers report.
		sec-bases:  copy []
		sec-stypes: copy []		;-- parallel: section type (low flag byte)
		sec-res1:   copy []		;-- parallel: reserved1 (indirect-table start)
		symtab-off: 0
		symtab-cnt: 0
		str-off:    0
		dysym-off:  0			;-- LC_DYSYMTAB indirect-symbol table
		dysym-cnt:  0
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
						append sec-bases (u32-le bin (sec-pos + 32))	;-- vmaddr
						sec-size: u32-le bin (sec-pos + 36)
						sec-off:  u32-le bin (sec-pos + 40)
						flags:    u32-le bin (sec-pos + 56)
						append sec-stypes (flags and 255)
						append sec-res1 (u32-le bin (sec-pos + 60))		;-- reserved1
						kind:     section-kind segname sectname flags
						data: either all [kind  kind <> 'bss  sec-size > 0][
							copy/part at bin (sec-off + 1) sec-size
						][make binary! 0]
						append/only sections reduce [
							sectname kind
							(shift/left 1 (u32-le bin (sec-pos + 44)))	;-- 3 alignment (bytes)
							data sec-size
							(make block! 4) 'none 0
							;-- 9 vmaddr -- the section's address in the .o's
							;-- scratch layout. Used to translate scattered-
							;-- relocation r_value fields and to recover the
							;-- section-relative offset of any defined symbol.
							;-- Mach-O coalesces weak defs at the symbol level
							;-- (no group key), so sec-comdat-key returns NONE
							;-- regardless of what lives here.
							u32-le bin (sec-pos + 32)
							;-- 10/11 reloff/nreloc scratch, dropped after Pass 3
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
				cmd = 11 [									;-- LC_DYSYMTAB
					dysym-off: u32-le bin (lc-pos + 56)		;-- indirectsymoff
					dysym-cnt: u32-le bin (lc-pos + 60)		;-- nindirectsyms
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
			v:  u32-le bin (p + 8)						;-- n_value (absolute)
			;-- Recover section-relative offset for defined symbols.
			if all [ns > 0  ns <= length? sec-bases][
				v: v - pick sec-bases ns
			]
			append/only symbols reduce [
				read-cstring bin (str-off + sn + 1)		;-- name
				v										;-- value (section-relative)
				ns										;-- section-idx (1-based, 0 = NO_SECT)
				nt										;-- class (n_type)
				u16-le bin (p + 6)						;-- n_desc (carries N_WEAK_DEF)
			]
			i: i + 1
		]
		n-real: symtab-cnt

		;-- One synthetic section symbol per section, so that non-extern
		;-- (section-number) relocations resolve through sym-sect.
		k: 1
		while [k <= length? sections][
			append/only symbols reduce ["" 0 k 0 0]
			k: k + 1
		]

		;-- Pass 3: read each section's relocations.
		foreach sec sections [
			relocs: sec/6
			r-i: 0
			while [r-i < sec/11][						;-- nreloc
				r-pos: sec/10 + (r-i * 8) + 1			;-- reloff
				w0: u32-le bin r-pos
				either (w0 and R_SCATTERED) <> 0 [
					;-- Scattered: layout is r_address(24) | r_type(4) |
					;-- r_length(2) | r_pcrel(1) | r_scattered(1) in w0,
					;-- with w1 = r_value.
					w1:       u32-le bin (r-pos + 4)
					s-type:   (shift/logical w0 24) and 15
					s-length: (shift/logical w0 28) and 3
					s-pcrel:  (shift/logical w0 30) and 1
					r-va:     w0 and 16777215
					either all [
						any [
							s-type = GENERIC_RELOC_SECTDIFF
							s-type = GENERIC_RELOC_LOCAL_SECTDIFF
						]
						s-length = 2
						s-pcrel = 0
					][
						;-- SECTDIFF: the next entry must be PAIR carrying
						;-- the subtrahend address. Encode the difference
						;-- as one 6-field reloc and let the linker patch
						;-- it once both sections have final VAs.
						r-i: r-i + 1
						r-pos: sec/10 + (r-i * 8) + 1
						w0-p: u32-le bin r-pos
						w1-p: u32-le bin (r-pos + 4)
						either all [
							(w0-p and R_SCATTERED) <> 0
							((shift/logical w0-p 24) and 15) = GENERIC_RELOC_PAIR
						][
							;-- Map both endpoints to (section, offset).
							min-sect: none
							sub-sect: none
							k: 1
							foreach sec-x sections [
								if all [w1   >= sec-x/9  w1   < (sec-x/9 + sec-x/5)][min-sect: k]
								if all [w1-p >= sec-x/9  w1-p < (sec-x/9 + sec-x/5)][sub-sect: k]
								k: k + 1
							]
							either all [min-sect  sub-sect][
								sec-x: pick sections min-sect
								min-off: w1   - sec-x/9
								sec-x: pick sections sub-sect
								sub-off: w1-p - sec-x/9
								append/only relocs reduce [
									r-va
									n-real + min-sect - 1			;-- min synth sym
									;-- pack (r_type << 4) | (r_length << 2) | (r_pcrel << 1)
									(shift/left s-type 4)
										or (shift/left s-length 2)
										or (shift/left s-pcrel 1)
									n-real + sub-sect - 1			;-- sub synth sym
									min-off
									sub-off
								]
							][
								append/only relocs reduce [r-va 0 -1]
							]
						][
							;-- SECTDIFF without a following PAIR is malformed.
							append/only relocs reduce [r-va 0 -1]
						]
					][
						;-- Scattered VANILLA: a reference to a local address
						;-- (r_value) carrying an addend -- the field holds
						;-- r_value + addend. Map r_value to its section and
						;-- rebase the field so the generic `target-va + addend`
						;-- path applies (same normalization as a non-extern
						;-- VANILLA). Any other scattered kind stays unsupported.
						either all [s-type = GENERIC_RELOC_VANILLA  s-length = 2][
							min-sect: none
							k: 1
							foreach sec-x sections [
								if all [w1 >= sec-x/9  w1 < (sec-x/9 + sec-x/5)][min-sect: k]
								k: k + 1
							]
							either min-sect [
								append/only relocs reduce [
									r-va
									n-real + min-sect - 1				;-- synth section sym
									(shift/left GENERIC_RELOC_VANILLA 4)
										or (shift/left s-length 2)
										or (shift/left s-pcrel 1)
								]
								sec-x: pick sections min-sect
								v: i32-le sec/4 (r-va + 1)
								change at sec/4 (r-va + 1) to-le32 (v - sec-x/9)
							][
								append/only relocs reduce [r-va 0 -1]
							]
						][
							append/only relocs reduce [r-va 0 -1]
						]
					]
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
					;-- Mach-O non-extern relocations store the TARGET's absolute
					;-- object-layout address in the section data (abs32: the
					;-- address itself; pcrel: folded into the displacement).
					;-- Normalize to a target-section-relative offset so the
					;-- linker's generic `target-va + addend` works the same way
					;-- it does for COFF/ELF (the scattered-VANILLA path below
					;-- performs the same rebase for its own entries).
					if all [
						r-extern = 0
						(shift/logical w1 28) = GENERIC_RELOC_VANILLA
						((shift/logical w1 25) and 3) = 2		;-- 4-byte field
					][
						v: i32-le sec/4 ((w0 and 16777215) + 1)
						change at sec/4 ((w0 and 16777215) + 1)
							to-le32 (v - pick sec-bases (w1 and 16777215))
					]
				]
				r-i: r-i + 1
			]
			;-- Drop the reloff/nreloc scratch so the section block ends at
			;-- slot 9 (vmaddr). The static linker claims slots 10/11 for its
			;-- live?/merged? flags.
			clear at sec 10
		]

		;-- Non-lazy symbol-pointer slots (__IMPORT,__pointers) bind through
		;-- the LC_DYSYMTAB indirect table, not relocations: synthesize one
		;-- abs32 per slot so the merged section's pointers fill exactly like
		;-- ordinary data relocations. INDIRECT_SYMBOL_LOCAL/ABS entries
		;-- (high bits set -- checked bytewise, the value overflows Rebol's
		;-- 32-bit integers) keep their own local relocations and are skipped.
		if dysym-cnt > 0 [
			k: 1
			foreach sec sections [
				if find [6 7] pick sec-stypes k [			;-- (non-)lazy pointers
					n-slots: to integer! sec/5 / 4
					j: 0
					while [j < n-slots][
						ent-pos: dysym-off + (((pick sec-res1 k) + j) * 4) + 1
						unless 64 <= byte-at bin (ent-pos + 3) [	;-- LOCAL/ABS flags
							append/only sec/6 reduce [j * 4  u32-le bin ent-pos  8]
						]
						j: j + 1
					]
				]
				k: k + 1
			]
		]

		make object! compose/only [
			path:     (path)
			sections: (sections)
			symbols:  (symbols)
		]
	]

	;-- Explain why load-from-bin returned NONE for a buffer. The static
	;-- linker aborts with this diagnosis -- an unlinkable object names its
	;-- actual format instead of surfacing later as missing symbols.
	reject-reason: func [bin [binary!]][
		if (length? bin) < 28 [return "truncated or empty object"]
		if #{4243C0DE} = copy/part bin 4 [
			return "LLVM bitcode (compiled with -flto); rebuild without link-time optimization"
		]
		if MH_MAGIC + 1 = u32-le bin 1 [
			return "64-bit Mach-O object; this build targets 32-bit x86"
		]
		unless MH_MAGIC = u32-le bin 1 [
			return "not a Mach-O object; this build links Mach-O objects"
		]
		unless CPU_TYPE_I386 = u32-le bin 5 [
			return "Mach-O object for a foreign CPU; this build targets i386"
		]
		"not a relocatable Mach-O object (MH_OBJECT expected)"
	]

	;-- Load a Mach-O i386 object file from disk. Halts on invalid input.
	load: func [path [file!] /local bin obj][
		bin: read/binary path
		obj: load-from-bin bin path
		if none? obj [
			print ["*** Linker Error: cannot link" path "--" reject-reason bin]
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
	sec-selection: func [s [block!]][none]			;-- COFF-only concepts
	sec-assoc:     func [s [block!]][none]

	;-- Only the COALESCED sections (__textcoal_nt, __datacoal_nt,
	;-- __const_coal -- weak template/vtable duplicates) are treated as
	;-- comdat/first-wins. Regular sections (__text/__data/__const/__common/
	;-- __bss) are NOT: they must go unconditionally live like ELF/PE keepable
	;-- sections, else a definition-holding section (e.g. GImGui in __common)
	;-- referenced only cross-TU can be left dark by pull order.
	sec-comdat?:   func [s [block!]][to logic! find s/1 "coal"]

	;-- No COFF-style undefined-with-default weak externals in Mach-O.
	sym-weak-default: func [sym [block!]][none]

	;-- Mach-O coalesces weak definitions at the SYMBOL level (N_WEAK_DEF),
	;-- not via per-section group keys, so there is no section-level key.
	sec-comdat-key:  func [s [block!]][none]

	;-- Mach-O i386 keeps each section's scratch-layout vmaddr in slot 9,
	;-- so the linker can recover the original difference between two
	;-- sections for SECTDIFF / LOCAL_SECTDIFF relocations.
	sec-vmaddr:      func [s [block!]][s/9]

	set-sec-base: func [s [block!] kind [word!] offset [integer!]][
		poke s 7 kind
		poke s 8 offset
	]

	sym-name:  func [sym [block!]][sym/1]
	sym-value: func [sym [block!]][sym/2]
	sym-sect:  func [sym [block!]][sym/3]
	sym-class: func [sym [block!]][sym/4]

	;-- TRUE if the symbol's n_desc carries the N_WEAK_DEF bit.
	sym-weak?: func [sym [block!]][(sym/5 and N_WEAK_DEF) <> 0]

	;-- A defined external: external linkage, N_SECT type, real section.
	is-defined-external?: func [sym [block!]][
		all [
			(sym/4 and N_STAB) = 0
			(sym/4 and N_EXT) <> 0
			(sym/4 and N_TYPE) = N_SECT
			(sym/3) > 0
		]
	]

	;-- An undefined external: external linkage, N_UNDF type, and NO size --
	;-- a non-zero n_value marks a common (tentative) definition instead,
	;-- which the linker allocates rather than imports.
	is-undefined-external?: func [sym [block!]][
		all [
			(sym/4 and N_STAB) = 0
			(sym/4 and N_EXT) <> 0
			(sym/4 and N_TYPE) = N_UNDF
			(sym/2) = 0
		]
	]

	;-- A common (tentative) definition -- (__DATA,__common) external, N_UNDF
	;-- with n_value carrying the byte size. Returns the size (0 if not a
	;-- common). The linker zero-allocates one slot per unique name.
	sym-common-size: func [sym [block!]][
		either all [
			(sym/4 and N_STAB) = 0
			(sym/4 and N_EXT) <> 0
			(sym/4 and N_TYPE) = N_UNDF
			(sym/2) > 0
		][sym/2][0]
	]
]
