REBOL [
	Title:   "Red/System COFF object reader"
	Author:  "Nenad Rakocevic"
	File: 	 %COFF.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Parses Windows i386 COFF object files for static linking, scoped to
		32-bit (IMAGE_FILE_MACHINE_I386). Exposes the same context interface
		as ELF-obj.r so the static linker can drive either format through one
		`reader` handle. Archive (.lib) splitting lives in linker-static.r.
	}
]

coff: context [

	;-- ===== Constants =====

	IMAGE_FILE_MACHINE_I386:	to integer! #{014C}

	IMAGE_REL_I386_ABSOLUTE:	0
	IMAGE_REL_I386_DIR16:		1
	IMAGE_REL_I386_REL16:		2
	IMAGE_REL_I386_DIR32:		6
	IMAGE_REL_I386_DIR32NB:		7
	IMAGE_REL_I386_SECTION:		10
	IMAGE_REL_I386_SECREL:		11
	IMAGE_REL_I386_TOKEN:		12
	IMAGE_REL_I386_SECREL7:		13
	IMAGE_REL_I386_REL32:		20

	IMAGE_SYM_CLASS_EXTERNAL:	2
	IMAGE_SYM_CLASS_STATIC:		3

	IMAGE_SCN_LNK_INFO:			to integer! #{00000200}
	IMAGE_SCN_LNK_REMOVE:		to integer! #{00000800}

	;-- COFF REL32 displacements are relative to the end of the 4-byte field,
	;-- so the PC-relative result carries an extra -4 bias (see ELF-obj.r,
	;-- whose REL relocations fold the bias into the in-place addend).
	pc-bias: 4

	;-- ===== Low-level binary access =====
	;-- All positions are 1-based, matching Rebol series indexing.

	byte-at: func [bin [binary!] pos [integer!]][
		to integer! pick bin pos
	]

	;-- Read an unsigned 16-bit little-endian value.
	u16-le: func [bin [binary!] pos [integer!]][
		to integer! reverse copy/part at bin pos 2
	]

	;-- Read a 32-bit little-endian value. `to integer!` yields a signed
	;-- 32-bit result, so values with bit 31 set come back negative -- the
	;-- correct two's-complement reading for REL32 addends.
	u32-le: func [bin [binary!] pos [integer!]][
		to integer! reverse copy/part at bin pos 4
	]

	;-- Read a signed 16-bit little-endian value (section number field).
	i16-le: func [bin [binary!] pos [integer!] /local v][
		v: u16-le bin pos
		either v >= 32768 [v - 65536][v]
	]

	i32-le: func [bin [binary!] pos [integer!]][
		u32-le bin pos
	]

	;-- ===== String reading =====

	;-- Read a null-terminated ASCII string starting at a 1-based position.
	read-cstring: func [bin [binary!] pos [integer!] /local out b i][
		out: copy ""
		i: pos
		while [all [i <= length? bin  (b: byte-at bin i) <> 0]][
			append out to char! b
			i: i + 1
		]
		out
	]

	;-- Read a fixed-size (max 8) section-name field. If the first byte is
	;-- '/' and the rest is a decimal offset, the real name lives in the
	;-- string table at that offset; otherwise the name is the inline bytes
	;-- up to the first null (or all 8 bytes).
	read-short-name: func [
		bin [binary!] pos [integer!] string-table [binary!]
		/local b out i off-str off
	][
		b: byte-at bin pos
		either b = 47 [									;-- '/'
			off-str: copy ""
			i: pos + 1
			while [all [i < (pos + 8)  (b: byte-at bin i) <> 0]][
				append off-str to char! b
				i: i + 1
			]
			off: to integer! off-str
			read-cstring string-table (off + 1)
		][
			out: copy ""
			i: pos
			while [all [i < (pos + 8)  (b: byte-at bin i) <> 0]][
				append out to char! b
				i: i + 1
			]
			out
		]
	]

	;-- Read a symbol-table name field (8 bytes). If the first 4 bytes are
	;-- zero, the next 4 bytes are a string-table offset; otherwise the name
	;-- is the inline bytes up to the first null (max 8 chars).
	read-symbol-name: func [
		bin [binary!] pos [integer!] string-table [binary!]
		/local out i b off
	][
		either 0 = u32-le bin pos [
			off: u32-le bin (pos + 4)
			read-cstring string-table (off + 1)
		][
			out: copy ""
			i: pos
			while [all [i < (pos + 8)  (b: byte-at bin i) <> 0]][
				append out to char! b
				i: i + 1
			]
			out
		]
	]

	;-- ===== Classification =====

	;-- Return 'code | 'data | 'rdata | 'bss | none for a section. A section
	;-- is kept when its name begins with .text/.rdata/.data/.bss (covers
	;-- COMDAT variants like .text$mn). Debug/SEH/directive/info sections are
	;-- dropped.
	section-kind: func [name [string!] chars [integer!]][
		if (chars and IMAGE_SCN_LNK_INFO) <> 0 [return none]
		if (chars and IMAGE_SCN_LNK_REMOVE) <> 0 [return none]
		case [
			any [name = ".text"   (parse name [".text" to end])]  ['code]
			any [name = ".rdata"  (parse name [".rdata" to end])] ['rdata]
			any [name = ".data"   (parse name [".data" to end])]  ['data]
			any [name = ".bss"    (parse name [".bss" to end])]   ['bss]
			true [none]
		]
	]

	;-- Abstract relocation kind, shared with the static linker's reader
	;-- interface (see ELF-obj.r/reloc-kind).
	reloc-kind: func [type [integer!]][
		case [
			type = IMAGE_REL_I386_DIR32    ['abs32]
			type = IMAGE_REL_I386_REL32    ['pc32]
			type = IMAGE_REL_I386_DIR32NB  ['rva32]
			type = IMAGE_REL_I386_ABSOLUTE ['none]
			true                           ['unsupported]
		]
	]

	;-- ===== Main entry points =====

	;-- Parse an in-memory buffer as an i386 COFF object. Returns an object!
	;-- with [path machine sections symbols string-table], or NONE if the
	;-- buffer is not an i386 COFF (wrong machine, short import stub, etc.).
	;--
	;-- sections : block of [name kind chars raw-data size relocs base-kind
	;--            base-offset] entries.
	;--   kind        = 'code | 'data | 'rdata | 'bss | none
	;--   base-kind   = 'code | 'data, filled in by the linker ('none here)
	;--   base-offset = position inside the merged bucket (0 here)
	;-- symbols  : block of [name value section-number class] entries, one
	;--   per raw symbol-table slot; aux records are kept as ['aux 0 0 0]
	;--   placeholders so slot indexing stays 1:1 with relocation records.
	;-- string-table : raw binary! including its 4-byte size prefix.
	load-from-bin: func [
		bin [binary!] path
		/local n-sections sym-tbl-off n-symbols sections symbols
			i sec-pos name chars align raw-size raw-ptr reloc-ptr reloc-cnt
			kind raw-data relocs r-pos r-i r-va r-sym r-type
			sym-pos sym-name sym-value sym-sect sym-class sym-aux
			str-tbl-off string-table s-idx machine
	][
		;-- File header (20 bytes)
		if (length? bin) < 20 [return none]
		machine: u16-le bin 1
		if machine <> IMAGE_FILE_MACHINE_I386 [return none]
		n-sections:  u16-le bin 3
		sym-tbl-off: u32-le bin 9
		n-symbols:   u32-le bin 13

		;-- String table sits right after the symbol table.
		str-tbl-off:  sym-tbl-off + (n-symbols * 18)
		string-table: copy at bin (str-tbl-off + 1)

		;-- Section headers (40 bytes each, starting at offset 20)
		sections: copy []
		i: 0
		while [i < n-sections][
			sec-pos:   21 + (i * 40)
			name:      read-short-name bin sec-pos string-table
			raw-size:  u32-le bin (sec-pos + 16)		;-- SizeOfRawData
			raw-ptr:   u32-le bin (sec-pos + 20)		;-- PointerToRawData
			reloc-ptr: u32-le bin (sec-pos + 24)		;-- PointerToRelocations
			reloc-cnt: u16-le bin (sec-pos + 32)		;-- NumberOfRelocations
			chars:     u32-le bin (sec-pos + 36)		;-- Characteristics

			kind: section-kind name chars

			;-- alignment: characteristics bits 20-23 hold log2(align) + 1
			align: (shift/logical chars 20) and 15
			align: either zero? align [4][shift/left 1 (align - 1)]

			either all [kind  raw-ptr > 0  raw-size > 0][
				raw-data: copy/part at bin (raw-ptr + 1) raw-size
			][
				raw-data: make binary! 0				;-- dropped section or BSS
			]

			relocs: copy []
			if all [kind  reloc-cnt > 0  reloc-ptr > 0][
				r-i: 0
				while [r-i < reloc-cnt][
					r-pos:  reloc-ptr + (r-i * 10) + 1
					r-va:   u32-le bin r-pos
					r-sym:  u32-le bin (r-pos + 4)
					r-type: u16-le bin (r-pos + 8)
					append/only relocs reduce [r-va r-sym r-type]
					r-i: r-i + 1
				]
			]

			;-- For BSS, stash VirtualSize so the linker can allocate a
			;-- zero-filled slot.
			if kind = 'bss [raw-size: u32-le bin (sec-pos + 8)]

			append/only sections reduce [
				name									;-- 1 name
				kind									;-- 2 'code|'data|'rdata|'bss|none
				align									;-- 3 section alignment (bytes)
				raw-data								;-- 4 binary! (empty if dropped/BSS)
				raw-size								;-- 5 size (VirtualSize for BSS)
				relocs									;-- 6 [[va sym-idx type] ...]
				'none									;-- 7 base-kind  (linker fills)
				0										;-- 8 base-offset (linker fills)
			]
			i: i + 1
		]

		;-- Symbol table (18 bytes per slot, aux records included)
		symbols: copy []
		s-idx:   0
		sym-aux: 0
		while [s-idx < n-symbols][
			sym-pos: sym-tbl-off + (s-idx * 18) + 1
			either sym-aux > 0 [
				append/only symbols reduce ['aux 0 0 0]	;-- placeholder for index parity
				sym-aux: sym-aux - 1
			][
				sym-name:  read-symbol-name bin sym-pos string-table
				sym-value: u32-le bin (sym-pos + 8)
				sym-sect:  i16-le bin (sym-pos + 12)
				sym-class: byte-at bin (sym-pos + 16)
				sym-aux:   byte-at bin (sym-pos + 17)
				append/only symbols reduce [sym-name sym-value sym-sect sym-class]
			]
			s-idx: s-idx + 1
		]

		make object! compose/only [
			path:         (path)
			machine:      (machine)
			sections:     (sections)
			symbols:      (symbols)
			string-table: (string-table)
		]
	]

	;-- Load an i386 COFF object file from disk. Halts on invalid input.
	load: func [path [file!] /local bin obj][
		bin: read/binary path
		obj: load-from-bin bin path
		if none? obj [
			print ["*** Linker Error: not an i386 (x86) COFF object:" path]
			halt
		]
		obj
	]

	;-- ===== Accessors (mirror ELF-obj.r's interface) =====

	sec-name:		func [s [block!]][s/1]
	sec-kind:		func [s [block!]][s/2]
	sec-align:		func [s [block!]][s/3]
	sec-data:		func [s [block!]][s/4]
	sec-size:		func [s [block!]][s/5]
	sec-relocs:		func [s [block!]][s/6]
	sec-base-kind:	func [s [block!]][s/7]
	sec-base-offset: func [s [block!]][s/8]

	set-sec-base: func [s [block!] kind [word!] offset [integer!]][
		poke s 7 kind
		poke s 8 offset
	]

	sym-name:	func [sym [block!]][sym/1]
	sym-value:	func [sym [block!]][sym/2]
	sym-sect:	func [sym [block!]][sym/3]
	sym-class:	func [sym [block!]][sym/4]

	is-defined-external?: func [sym [block!]][
		all [
			sym/1 <> 'aux
			(sym/3) > 0
			(sym/4) = IMAGE_SYM_CLASS_EXTERNAL
		]
	]

	is-undefined-external?: func [sym [block!]][
		all [
			sym/1 <> 'aux
			(sym/3) = 0
			(sym/4) = IMAGE_SYM_CLASS_EXTERNAL
		]
	]
]
