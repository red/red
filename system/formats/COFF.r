REBOL [
	Title:   "Red/System COFF object reader"
	Author:  "Nenad Rakocevic"
	File: 	 %COFF.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Parses Windows i386 COFF object files for static linking -- both the
		classic layout and the /bigobj variant (ANON_OBJECT_HEADER_BIGOBJ,
		which raises the 65,535-section limit and is what MSVC emits for
		large C++ builds) -- scoped to 32-bit (IMAGE_FILE_MACHINE_I386, plus
		machine-0 data/alias-only members). Exposes the same context
		interface as ELF-obj.r so the static linker can drive either format
		through one `reader` handle. Archive (.lib) splitting lives in
		linker-static.r.
	}
]

coff: context [

	;-- ===== Constants =====

	IMAGE_FILE_MACHINE_I386:	to integer! #{014C}
	IMAGE_FILE_MACHINE_UNKNOWN:	0					;-- data/alias-only members (oldnames.lib)

	;-- ANON_OBJECT_HEADER_BIGOBJ class id {D1BAA1C7-BAEE-4BA9-AF20-FAF66AA4DCB8}
	;-- as stored on disk (little-endian GUID fields); the discriminant between
	;-- a /bigobj member and the other anonymous-header formats (import-library
	;-- stubs, /GL LTCG payloads) that share the machine-0/FFFFh signature.
	bigobj-classid: #{C7A1BAD1EEBAA94BAF20FAF66AA4DCB8}

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
	IMAGE_SYM_CLASS_WEAK_EXTERNAL: 105

	IMAGE_SCN_LNK_INFO:			to integer! #{00000200}
	IMAGE_SCN_LNK_REMOVE:		to integer! #{00000800}
	IMAGE_SCN_LNK_COMDAT:		to integer! #{00001000}
	IMAGE_SCN_CNT_CODE:			to integer! #{00000020}
	IMAGE_SCN_CNT_INIT_DATA:	to integer! #{00000040}
	IMAGE_SCN_CNT_UNINIT_DATA:	to integer! #{00000080}
	IMAGE_SCN_MEM_WRITE:		to integer! #{80000000}

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

	;-- Return 'code | 'data | 'rdata | 'tls | 'bss | 'crt | 'cafter | none
	;-- for a section. A section is kept when its name begins with a known prefix
	;-- (covering COMDAT variants like .text$mn). .xdata holds the FH3 C++
	;-- exception-handling tables and _RDATA is the MSVC CRT's alternate
	;-- read-only-data name -- both are plain initialized data. .fptable holds
	;-- the winapi-thunk `function_pointers` array, which the UCRT flips
	;-- writable to cache lazily-resolved API addresses and then VirtualProtects
	;-- read-only again; that page-granular re-protection would catch any
	;-- writable global sharing its page, so it gets the isolated 'cafter kind.
	;-- (.data$r -- RTTI descriptors -- stays writable: type_info::name caches
	;-- the demangled name into the descriptor at runtime.) .CRT$X??
	;-- sections carry the C/C++ initializer and terminator pointer tables;
	;-- they get their own kind because the linker must lay them out sorted
	;-- by full section name, between the CRT's ...$XxA / ...$XxZ bounds.
	;-- Debug/SEH/directive/info sections are dropped.
	section-kind: func [name [string!] chars [integer!]][
		if (chars and IMAGE_SCN_LNK_INFO) <> 0 [return none]
		if (chars and IMAGE_SCN_LNK_REMOVE) <> 0 [return none]
		case [
			any [name = ".text"   (parse name [".text" to end])]  ['code]
			any [name = ".rdata"  (parse name [".rdata" to end])] ['rdata]
			parse name [".xdata" to end]                          ['rdata]
			parse name [".fptable" to end]                        ['cafter]	;-- winapi-thunk table: RW then CRT-protected
			parse name [".CRT$" to end]                           ['crt]
			parse name [".rtc$" to end]                           ['crt]
			any [name = ".data"   (parse name [".data" to end])]  ['data]
			any [name = ".tls"    (parse name [".tls" to end])]   ['tls]
			any [name = ".bss"    (parse name [".bss" to end])]   ['bss]
			;-- tool/linker metadata carried as plain data: not for the image
			parse name [".debug" to end]                          [none]
			parse name [".chks64" to end]                         [none]
			parse name [".voltbl" to end]                         [none]
			parse name [".sxdata" to end]                         [none]
			parse name [".gfids" to end]                          [none]
			parse name [".gehcont" to end]                        [none]
			parse name [".gljmp" to end]                          [none]
			parse name [".00cfg" to end]                          [none]
			parse name [".msvcjmc" to end]                        [none]
			;-- anything else merges by its content flags, the way link.exe
			;-- treats custom-named sections (the CRT's _RDATA and .fptable,
			;-- user #pragma section data, ...)
			(chars and IMAGE_SCN_CNT_CODE) <> 0                   ['code]
			(chars and IMAGE_SCN_CNT_UNINIT_DATA) <> 0            ['bss]
			all [
				(chars and IMAGE_SCN_CNT_INIT_DATA) <> 0
				zero? (chars and IMAGE_SCN_MEM_WRITE)
			]                                                     ['rdata]
			(chars and IMAGE_SCN_CNT_INIT_DATA) <> 0              ['data]
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
			type = IMAGE_REL_I386_SECREL   ['secrel32]
			type = IMAGE_REL_I386_ABSOLUTE ['none]
			true                           ['unsupported]
		]
	]

	;-- ===== Main entry points =====

	;-- Parse an in-memory buffer as an i386 COFF object. Returns an object!
	;-- with [path machine sections symbols string-table], or NONE if the
	;-- buffer is not an i386 COFF (wrong machine, short import stub, etc.).
	;--
	;-- sections : block of [name kind align raw-data size relocs base-kind
	;--            base-offset comdat-key live? merged? selection assoc]
	;--   kind        = 'code | 'data | 'rdata | 'tls | 'bss | 'crt | none
	;--   base-kind   = 'code | 'data, filled in by the linker ('none here)
	;--   base-offset = position inside the merged bucket (0 here)
	;--   live?/merged? are linker-local flags (pre-set false here)
	;--   selection   = COMDAT selection type (integer) or none
	;--   assoc       = ASSOCIATIVE parent section index (1-based) or none
	;-- symbols  : block of [name value section-number class weak-default]
	;--   entries, one per raw symbol-table slot; aux records are kept as
	;--   ['aux 0 0 0] placeholders so slot indexing stays 1:1 with
	;--   relocation records. weak-default is the aux-designated fallback
	;--   symbol's name for IMAGE_SYM_CLASS_WEAK_EXTERNAL entries, else none.
	;-- directives : accumulated .drectve text (linker command fragments:
	;--   /DEFAULTLIB, /INCLUDE, /ALTERNATENAME, ...) or none.
	;-- string-table : raw binary! including its 4-byte size prefix.
	load-from-bin: func [
		bin [binary!] path
		/local n-sections sym-tbl-off n-symbols sections symbols
			i sec-pos name chars align raw-size raw-ptr reloc-ptr reloc-cnt
			kind raw-data relocs r-pos r-i r-va r-sym r-type
			sym-pos sym-name sym-value sym-sect sym-class sym-aux
			str-tbl-off string-table s-idx machine sec-comdat
			sig2 version big? sec-base sym-size directives aux-pos sel tag
	][
		;-- File header: classic COFF (20 bytes) or bigobj (56 bytes). An
		;-- anonymous header (machine 0, section count FFFFh) is a bigobj
		;-- only at version >= 2 with the matching class id; the other
		;-- anonymous formats (import-library stubs, /GL LTCG payloads) and
		;-- non-COFF buffers return NONE -- reject-reason then names the
		;-- offending format for the error message.
		if (length? bin) < 20 [return none]
		machine: u16-le bin 1
		sig2:    u16-le bin 3
		either all [machine = 0  sig2 = 65535][
			version: u16-le bin 5
			unless all [
				version >= 2
				bigobj-classid = copy/part at bin 13 16
			][return none]
			big?:        yes
			machine:     u16-le bin 7
			n-sections:  u32-le bin 45
			sym-tbl-off: u32-le bin 49
			n-symbols:   u32-le bin 53
			sec-base:    57							;-- section table at offset 56
			sym-size:    20
		][
			big?:        no
			n-sections:  sig2
			sym-tbl-off: u32-le bin 9
			n-symbols:   u32-le bin 13
			sec-base:    21 + u16-le bin 17			;-- optional header: always 0 in objects
			sym-size:    18
		]
		unless any [
			machine = IMAGE_FILE_MACHINE_I386
			machine = IMAGE_FILE_MACHINE_UNKNOWN
		][return none]

		;-- String table sits right after the symbol table.
		str-tbl-off:  sym-tbl-off + (n-symbols * sym-size)
		string-table: copy at bin (str-tbl-off + 1)

		;-- Section headers (40 bytes each)
		sections: copy []
		i: 0
		while [i < n-sections][
			sec-pos:   sec-base + (i * 40)
			name:      read-short-name bin sec-pos string-table
			raw-size:  u32-le bin (sec-pos + 16)		;-- SizeOfRawData
			raw-ptr:   u32-le bin (sec-pos + 20)		;-- PointerToRawData
			reloc-ptr: u32-le bin (sec-pos + 24)		;-- PointerToRelocations
			reloc-cnt: u16-le bin (sec-pos + 32)		;-- NumberOfRelocations
			chars:     u32-le bin (sec-pos + 36)		;-- Characteristics

			kind: section-kind name chars

			;-- .drectve carries linker command fragments (/DEFAULTLIB,
			;-- /INCLUDE, /ALTERNATENAME, ...); the section itself is
			;-- dropped, its text kept for the static linker. A UTF-8 BOM
			;-- prefix (some producers emit one) is stripped.
			if all [name = ".drectve"  raw-size > 0  raw-ptr > 0][
				raw-data: copy/part at bin (raw-ptr + 1) raw-size
				if #{EFBBBF} = copy/part raw-data 3 [raw-data: skip raw-data 3]
				directives: rejoin [any [directives ""] " " to string! raw-data]
			]

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

			;-- BSS carries no raw data; the linker must still reserve a
			;-- zero-filled slot of the right size. clang-cl records that
			;-- size in SizeOfRawData, other producers in VirtualSize, so
			;-- take whichever field is set (exclusive in object files).
			if kind = 'bss [
				raw-size: max raw-size  u32-le bin (sec-pos + 8)
			]

			append/only sections reduce [
				name									;-- 1 name
				kind									;-- 2 'code|'data|'rdata|'tls|'bss|'crt|none
				align									;-- 3 section alignment (bytes)
				raw-data								;-- 4 binary! (empty if dropped/BSS)
				raw-size								;-- 5 size (VirtualSize for BSS)
				relocs									;-- 6 [[va sym-idx type] ...]
				'none									;-- 7 base-kind  (linker fills)
				0										;-- 8 base-offset (linker fills)
				;-- 9 COMDAT key: starts as TRUE for LNK_COMDAT sections so
				;-- the symbol pass can swap in the COMDAT symbol's name,
				;-- ending as a string for COMDAT-tracked sections or none.
				either zero? (chars and IMAGE_SCN_LNK_COMDAT) [none][true]
				false									;-- 10 live?   (linker fills)
				false									;-- 11 merged? (linker fills)
				none									;-- 12 COMDAT selection type
				none									;-- 13 ASSOCIATIVE parent index
			]
			i: i + 1
		]

		;-- Symbol table (18-byte slots; 20-byte in bigobj, whose section
		;-- number field widens to a signed 32-bit), aux records included
		symbols: copy []
		s-idx:   0
		sym-aux: 0
		while [s-idx < n-symbols][
			sym-pos: sym-tbl-off + (s-idx * sym-size) + 1
			either sym-aux > 0 [
				append/only symbols reduce ['aux 0 0 0]	;-- placeholder for index parity
				sym-aux: sym-aux - 1
			][
				sym-name:  read-symbol-name bin sym-pos string-table
				sym-value: u32-le bin (sym-pos + 8)
				either big? [
					sym-sect:  i32-le bin (sym-pos + 12)
					sym-class: byte-at bin (sym-pos + 18)
					sym-aux:   byte-at bin (sym-pos + 19)
				][
					sym-sect:  i16-le bin (sym-pos + 12)
					sym-class: byte-at bin (sym-pos + 16)
					sym-aux:   byte-at bin (sym-pos + 17)
				]
				append/only symbols reduce [sym-name sym-value sym-sect sym-class none]
				aux-pos: sym-pos + sym-size
				case [
					;-- section-definition aux (on the section's own name
					;-- symbol): carries the COMDAT selection type and, for
					;-- SELECT_ASSOCIATIVE, the parent section's index. An
					;-- associative section follows its parent's fate instead
					;-- of folding by key, so its key slot is cleared.
					all [
						sym-class = IMAGE_SYM_CLASS_STATIC
						sym-aux >= 1
						sym-value = 0
						sym-sect > 0
						sym-sect <= length? sections
						sym-name = first sec-comdat: pick sections sym-sect
					][
						if sec-comdat/9 [
							sel: byte-at bin (aux-pos + 14)
							poke sec-comdat 12 sel
							if sel = 5 [
								tag: u16-le bin (aux-pos + 12)
								if big? [
									tag: tag or shift/left (u16-le bin (aux-pos + 16)) 16
								]
								poke sec-comdat 13 tag
								poke sec-comdat 9 none
							]
						]
					]
					;-- weak external: the aux record designates the default
					;-- (fallback) symbol by slot index, resolved to a name in
					;-- a post-pass -- the tag may point forward.
					all [
						sym-class = IMAGE_SYM_CLASS_WEAK_EXTERNAL
						sym-aux >= 1
					][
						poke last symbols 5 u32-le bin aux-pos
					]
				]
				;-- A COMDAT section's key is the symbol following its section
				;-- symbol: the first external or static symbol bound to the
				;-- section under a different name, at any offset (a vtable's
				;-- ??_7 symbol sits at +4, past the RTTI locator slot).
				if all [
					any [
						sym-class = IMAGE_SYM_CLASS_EXTERNAL
						sym-class = IMAGE_SYM_CLASS_STATIC
					]
					sym-sect > 0
					sym-sect <= length? sections
				][
					sec-comdat: pick sections sym-sect
					if all [true = sec-comdat/9  sym-name <> sec-comdat/1][
						poke sec-comdat 9 sym-name
					]
				]
			]
			s-idx: s-idx + 1
		]

		;-- resolve weak-external default tags (slot indexes) to names
		foreach sym-comdat symbols [
			if all [
				IMAGE_SYM_CLASS_WEAK_EXTERNAL = pick sym-comdat 4
				integer? pick sym-comdat 5
			][
				tag: pick symbols (1 + pick sym-comdat 5)
				poke sym-comdat 5 all [tag  string? first tag  first tag]
			]
		]

		make object! compose/only [
			path:         (path)
			machine:      (machine)
			sections:     (sections)
			symbols:      (symbols)
			string-table: (string-table)
			directives:   (directives)
		]
	]

	;-- Explain why load-from-bin returned NONE for a buffer. The static
	;-- linker aborts with this diagnosis -- an unlinkable object names its
	;-- actual format instead of surfacing later as missing symbols.
	reject-reason: func [bin [binary!] /local machine sig2 version][
		if (length? bin) < 20 [return "truncated or empty object"]
		if #{4243C0DE} = copy/part bin 4 [
			return "LLVM bitcode (compiled with -flto); rebuild without link-time optimization"
		]
		if #{7F454C46} = copy/part bin 4 [
			return "ELF object; this build links Windows PE/COFF objects"
		]
		machine: u16-le bin 1
		sig2:    u16-le bin 3
		if all [machine = 0  sig2 = 65535][
			version: u16-le bin 5
			if version = 0 [
				return "import-library member (dynamic-linking stub, not static code)"
			]
			if bigobj-classid <> copy/part at bin 13 16 [
				return "anonymous LTCG object (compiled with /GL); rebuild without /GL"
			]
			machine: u16-le bin 7					;-- a bigobj with a foreign machine
		]
		case [
			machine = 34404 ["x86-64 (64-bit) object; this build targets 32-bit x86"]
			machine = 43620 ["ARM64 object; this build targets 32-bit x86"]
			any [machine = 448  machine = 452]["ARM object; this build targets 32-bit x86"]
			true [rejoin ["unsupported COFF machine type: " machine]]
		]
	]

	;-- Load an i386 COFF object file from disk. Halts on invalid input.
	load: func [path [file!] /local bin obj][
		bin: read/binary path
		obj: load-from-bin bin path
		if none? obj [
			print ["*** Linker Error: cannot link" path "--" reject-reason bin]
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
	;-- COMDAT key (string) or none. Sections still tagged TRUE here have the
	;-- LNK_COMDAT flag but no matching name symbol -- treat as not folded.
	sec-comdat-key: func [s [block!]][either string? s/9 [s/9][none]]

	;-- COMDAT selection type (integer) or none; SELECT_ASSOCIATIVE parent
	;-- section index (1-based) or none.
	sec-selection:	func [s [block!]][all [(length? s) >= 12  s/12]]
	sec-assoc:		func [s [block!]][all [(length? s) >= 13  s/13]]

	;-- TRUE for any section carrying the LNK_COMDAT flag, keyed or not.
	;-- Non-COMDAT sections of a pulled member are unconditionally live
	;-- (link.exe keeps them; only COMDATs are reference-driven).
	sec-comdat?: func [s [block!]][
		found? any [s/9  all [(length? s) >= 12  s/12]]
	]

	set-sec-base: func [s [block!] kind [word!] offset [integer!]][
		poke s 7 kind
		poke s 8 offset
	]

	sym-name:	func [sym [block!]][sym/1]
	sym-value:	func [sym [block!]][sym/2]
	sym-sect:	func [sym [block!]][sym/3]
	sym-class:	func [sym [block!]][sym/4]

	;-- TRUE if the symbol's storage class is IMAGE_SYM_CLASS_WEAK_EXTERNAL.
	sym-weak?: func [sym [block!]][sym/4 = IMAGE_SYM_CLASS_WEAK_EXTERNAL]

	;-- A weak external's default (fallback) symbol name, or none.
	sym-weak-default: func [sym [block!]][
		all [(length? sym) >= 5  string? sym/5  sym/5]
	]

	;-- COFF common symbol: external UNDEF with non-zero size in Value.
	sym-common?: func [sym [block!]][
		all [
			sym/1 <> 'aux
			(sym/2) > 0
			(sym/3) = 0
			(sym/4) = IMAGE_SYM_CLASS_EXTERNAL
		]
	]

	is-defined-external?: func [sym [block!]][
		any [
			all [
				sym/1 <> 'aux
				(sym/3) > 0
				(sym/4) = IMAGE_SYM_CLASS_EXTERNAL
			]
			sym-common? sym
		]
	]

	is-undefined-external?: func [sym [block!]][
		all [
			sym/1 <> 'aux
			zero? sym/2
			(sym/3) = 0
			(sym/4) = IMAGE_SYM_CLASS_EXTERNAL
		]
	]
]
