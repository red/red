REBOL [
	Title:   "Red/System static linker for external C objects"
	Author:  "Nenad Rakocevic"
	File: 	 %linker-static.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Statically links external C object files and archives referenced
		through #import "<file>". Supports 32-bit PE/COFF (.obj/.lib) and
		32-bit ELF (.o/.a); the per-format object reader is selected from
		job/format and driven through one `reader` handle.

		Pipeline:
		  register     -- compiler.r/process-import : records resolved paths
		  merge        -- linker.r/build           : merges sections, resolves
		                                             externals, allocates slots
		  apply-relocs -- formats/{PE,ELF}.r/build  : patches relocations once
		                                             section addresses are fixed
	}
]

do-cache %system/formats/COFF.r
do-cache %system/formats/ELF-obj.r
do-cache %system/formats/Mach-O-obj.r
do-cache %system/formats/libc-exports.r
do-cache %system/formats/win32-exports.r
do-cache %system/formats/crt-helpers.r

static-link: context [

	;-- ===== Per-build state =====

	reader:     none				;-- coff | elf-obj, chosen from job/format
	obj-format: none				;-- 'PE | 'ELF
	obj-arch:   none				;-- 'IA-32 | 'ARM  (job/target)
	objects:    make block! 10		;-- [path object ...] every merged object
	needed:     make hash!  64		;-- bare C names still referenced (drives archive selection)
	comdat-keys: make hash!  32		;-- COMDAT / SHT_GROUP keys already pulled (folds duplicates)
	sym-addr:   make hash!  200		;-- C-name => [kind offset weak?]  kind: 'code|'data|'tls|'image-base|'absolute
	call-slots: make block! 40		;-- [reloc-refs slot-offset target-info ...]
	got-slots:  make block! 40		;-- [key [slot kind offset] ...], ELF i386 PIC GOT entries
	got-start:  none				;-- data offset of synthetic ELF i386 GOT base
	undef-done: make block! 20		;-- undefined externals already resolved
	libc-set:   none				;-- this build's C-library export hash (libc-exports.r)
	libm-set:   none				;-- Linux libm export names accepted for static objects
	libc-data-set: none				;-- this build's C-library DATA exports [name size ...]
	max-align:  1					;-- peak alignment among merged static sections
	tls-start:  none				;-- merged .tls RVA-relative offset in data section
	tls-end:    none
	tls-index:  none				;-- data offsets for synthesized PE TLS runtime symbols
	tls-dir:    none

	syslib-index: none				;-- symbol => DLL hash, PE __imp_ resolution
	imp-table:  make hash! 64		;-- __imp_<decorated> => [DLL bare-name]
	helper-libs: none				;-- registry-located static helper archives

	;-- 4-byte little-endian serializer (target endianness is set up by the
	;-- time `apply-relocs` runs, during linking).
	ptr-struct: make-struct [value [integer!]] none
	le32: func [n [integer!]][ptr-struct/value: n  form-struct ptr-struct]

	abort: func [msg [block!]][
		print rejoin ["*** Static linking error: " reform msg]
		system-dialect/compiler/quit-on-error
	]

	;-- ===== Helpers =====

	;-- TRUE when an #import target names a static object or archive.
	library?: func [name [string!]][
		found? find [%.obj %.lib %.o %.a] suffix? to-file lowercase copy name
	]

	archive?: func [name [string!]][
		found? find [%.lib %.a] suffix? to-file lowercase copy name
	]

	;-- Resolve an #import filename relative to the directory of the source
	;-- file that contains the directive.
	resolve-path: func [lib [string!] script /local f dir][
		f: to-rebol-file lib
		either slash = first f [						;-- already absolute (incl. %/C/.. on Windows)
			f
		][
			dir: either all [script  file? script][
				first split-path clean-path script
			][%./]
			clean-path join dir f
		]
	]

	;-- Split an `ar` archive (!<arch>) into [member-name member-binary ...]
	;-- pairs. Shared by Microsoft .lib and Unix .a (GNU variant): the symbol
	;-- index ("/") and longname ("//") members are filtered out.
	read-archive: func [
		path [file!]
		/local bin members longnames pos mem-end size-str size data
			name-bin name off real-name i b
	][
		bin: read/binary path
		if (length? bin) < 8 [abort reduce ["archive too small:" path]]
		if (copy/part bin 8) <> to binary! "!<arch>^/" [
			abort reduce ["missing !<arch> magic:" path]
		]
		members:   copy []
		longnames: make binary! 0
		pos:       9									;-- first member header
		while [pos < length? bin][
			if (pos + 59) > length? bin [break]
			name-bin: copy/part at bin pos 16
			name:     to string! name-bin
			trim/tail name
			size-str: to string! copy/part at bin (pos + 48) 10
			size:     to integer! trim size-str
			data:     copy/part at bin (pos + 60) size	;-- 2-byte header magic at +58
			mem-end:  pos + 60 + size
			if ((mem-end - 1) // 2) <> 0 [mem-end: mem-end + 1]	;-- 2-byte alignment
			case [
				name = "/"  []							;-- linker symbol index: skip
				name = "//" [longnames: data]			;-- longname table
				true [
					either #"/" = first name [
						off: to integer! trim next name
						real-name: copy ""
						i: off + 1
						while [all [
							i <= length? longnames
							(b: to integer! pick longnames i) <> 0	;-- NUL terminates (MS)
							b <> 10									;-- LF terminates (GNU)
						]][
							append real-name to char! b
							i: i + 1
						]
						;-- A GNU `ar` longname entry carries a trailing '/';
						;-- a Microsoft long name does not, and may itself
						;-- contain '/' as a path separator -- so the scan must
						;-- not stop at '/', only strip a single trailing one.
						if all [not empty? real-name  #"/" = last real-name][
							remove back tail real-name
						]
						name: real-name
					][
						if all [(length? name) > 0  (#"/" = last name)][
							name: copy/part name ((length? name) - 1)
						]
					]
					append/only members reduce [name data]
				]
			]
			pos: mem-end
		]
		members
	]

	;-- ===== compiler.r hook : register a static #import =====

	;-- Called from process-import for every object/archive library name.
	;-- Stores [lib-key [resolved-path cc]] on the job; the [lib list]
	;-- function mapping stays in job/sections/import where process-import
	;-- already put it (merge extracts it later).
	register: func [job [object!] lib [string!] script cc [word!] /local key][
		key: lowercase copy lib
		unless job/static-objs [job/static-objs: make block! 8]
		if find job/static-objs key [exit]
		repend job/static-objs reduce [key reduce [resolve-path lib script cc]]
	]

	;-- ===== linker.r hook : merge external objects into the build =====

	merge: func [
		job [object!]
		/local static-libs lib list info
	][
		clear objects
		clear needed
		clear comdat-keys
		clear sym-addr
		clear call-slots
		clear got-slots
		got-start: none
		clear undef-done
		clear imp-table
		libc-set: none
		libm-set: none
		libc-data-set: none
		helper-libs: none
		max-align: 1
		tls-start: none
		tls-end: none
		tls-index: none
		tls-dir: none

		if any [none? job/static-objs  empty? job/static-objs][exit]

		obj-format: job/format
		obj-arch:   job/target
		if obj-format = 'PE [
			build-syslib-index
			helper-libs: find-helper-libs
		]
		if all [obj-format = 'ELF  job/OS = 'Linux][
			helper-libs: find-linux-helper-libs
		]
		libc-set: make hash! any [
			switch job/OS [
				Windows [libc-exports/windows]
				Linux   [libc-exports/linux]
				macOS   [libc-exports/macos]
			]
			[]
		]
		libm-set: either job/OS = 'Linux [
			make hash! libc-exports/linux-libm
		][none]
		;-- libc DATA exports (with sizes) — copy-relocated by ELF.r. The
		;-- generated set covers the glibc/ELF targets only.
		libc-data-set: either job/OS = 'Linux [
			make hash! any [libc-exports/linux-data  []]
		][none]
		job/static-data: make block! 8				;-- [name data-offset size ...]
		reader: case [
			obj-format = 'PE     [coff]
			obj-format = 'ELF    [elf-obj]
			obj-format = 'Mach-o [macho-obj]
			true [abort reduce ["static linking unsupported for format:" obj-format]]
		]

		;-- Pull static [lib list] pairs out of the dynamic import table.
		static-libs: extract-static-imports job

		;-- Pass 1: merge directly-named objects, then pull archive members
		;-- on demand to satisfy referenced symbols.
		merge-objects job static-libs
		job/static-align: max-align					;-- ELF.r aligns .data to this

		;-- Pass 2: satisfy undefined externals (libc trampolines, stubs).
		resolve-externals job
		;-- Pass 2a: allocate synthetic ELF i386 GOT slots before final layout.
		allocate-got-slots job
		;-- Pass 2b: route PE __imp_* import-thunk references to dynamic imports.
		wire-imp-relocs job
		;-- Pass 3: wire each user-imported function to a call slot.
		foreach [lib list] static-libs [
			info: select job/static-objs lowercase copy lib
			wire-imports job lib list info/2
		]
	]

	extract-static-imports: func [job [object!] /local imports out pos][
		imports: job/sections/import/3
		out: make block! 8
		pos: imports
		while [not tail? pos][
			either library? pos/1 [
				repend out [pos/1 pos/2]
				remove/part pos 2
			][
				pos: skip pos 2
			]
		]
		out
	]

	;-- Merge every directly-named object file, then pull archive (.lib/.a)
	;-- members on demand: a member is linked in only if it defines a symbol
	;-- that something already merged — or a user #import — refers to. The
	;-- scan repeats to a fixpoint, since pulling one member can create fresh
	;-- references that another member satisfies.
	merge-objects: func [
		job [object!] static-libs [block!]
		/local lib list info id reloc m obj arch-members progress? hl
	][
		arch-members: make block! 32

		;-- user-imported names are the initial references
		foreach [lib list] static-libs [
			foreach [id reloc] list [
				unless find needed id [append needed id]
			]
		]

		;-- merge each directly-named object; queue every archive member
		foreach [lib list] static-libs [
			info: select job/static-objs lowercase copy lib
			unless info [abort reduce ["unregistered static import:" lib]]
			either archive? lib [
				foreach m read-archive info/1 [
					obj: reader/load-from-bin m/2 (rejoin [to-local-file info/1 "(" m/1 ")"])
					if obj [append/only arch-members reduce [obj false]]
				]
			][
				obj: reader/load info/1
				mark-live-sections obj
				merge-sections job obj
				repend objects [obj/path obj]
				note-undefined obj
			]
		]

		;-- queue helper archives; selective loading below pulls only the
		;-- compiler / CRT objects actually used.
		if all [helper-libs  not empty? helper-libs][
			foreach hl helper-libs [
				foreach m read-archive hl [
					obj: reader/load-from-bin m/2 (rejoin [to-local-file hl "(" m/1 ")"])
					if obj [append/only arch-members reduce [obj false]]
				]
			]
		]

		;-- pull archive members until a full pass satisfies nothing new
		until [
			progress?: false
			foreach m arch-members [
				if member-defines-needed? m/1 [
					mark-live-sections m/1
					if merge-sections job m/1 [progress?: true]
					unless m/2 [
						repend objects [m/1/path m/1]
						poke m 2 true
					]
					note-undefined m/1
				]
			]
			not progress?
		]
	]

	;-- Bare C name used to match references across objects: a PE/Mach-O
	;-- leading '_' and any stdcall '@N' suffix are dropped so user names and
	;-- object symbols compare in one namespace (ELF symbols pass through).
	arch-bare: func [name [string!] /local p][
		name: copy name
		if obj-format <> 'ELF [
			if all [not empty? name  any [#"_" = name/1  #"@" = name/1]][remove name]
			if p: find name #"@" [clear p]
		]
		name
	]

	;-- Slots 10/11 on each parsed section are linker-local flags:
	;-- live? and merged?. Live marking is additive because a later archive
	;-- pass can discover a new symbol defined by an already-pulled member.
	ensure-live-slot: func [section [block!]][
		if (length? section) < 10 [append section false]
		if (length? section) < 11 [append section false]
	]

	section-live?: func [section [block!]][
		all [(length? section) >= 10  true = section/10]
	]

	section-merged?: func [section [block!]][
		all [(length? section) >= 11  true = section/11]
	]

	mark-section-live?: func [obj [object!] sect [integer!] /local section][
		if any [sect <= 0  sect > length? obj/sections][return false]
		section: pick obj/sections sect
		unless reader/sec-kind section [return false]
		ensure-live-slot section
		if section/10 [return false]
		poke section 10 true
		true
	]

	;-- Compute the per-object live-section closure from currently needed
	;-- symbols. Relocations from live sections keep their target sections
	;-- in the same object; undefined targets are handled by note-undefined.
	mark-live-sections: func [
		obj [object!]
		/local section sym sect changed? r target
	][
		foreach section obj/sections [
			ensure-live-slot section
		]
		foreach sym obj/symbols [
			if all [
				reader/is-defined-external? sym
				find needed arch-bare reader/sym-name sym
			][
				mark-section-live? obj reader/sym-sect sym
			]
		]
		until [
			changed?: false
			foreach section obj/sections [
				if section-live? section [
					foreach r reader/sec-relocs section [
						target: pick obj/symbols (r/2 + 1)
						if target [
							sect: reader/sym-sect target
							if sect > 0 [
								if mark-section-live? obj sect [changed?: true]
							]
						]
					]
				]
			]
			not changed?
		]
	]

	;-- Add an object's undefined externals to the `needed` reference set.
	note-undefined: func [obj [object!] /local section sym nm sec-kind][
		foreach section obj/sections [
			sec-kind: reader/sec-base-kind section
			unless sec-kind = 'none [
				foreach r reader/sec-relocs section [
					sym: pick obj/symbols (r/2 + 1)
					if all [sym  reader/is-undefined-external? sym][
						nm: arch-bare reader/sym-name sym
						unless find needed nm [append needed nm]
					]
				]
			]
		]
	]

	;-- TRUE when `obj` defines a referenced symbol that is not yet defined,
	;-- or could upgrade an existing weak definition to a strong one.
	member-defines-needed?: func [obj [object!] /local sym raw existing][
		foreach sym obj/symbols [
			if reader/is-defined-external? sym [
				raw: reader/sym-name sym
				either existing: select sym-addr raw [
					if all [
						existing/3							;-- existing def is weak
						not reader/sym-weak? sym			;-- this one is strong
						find needed arch-bare raw
					][return true]
				][
					if find needed arch-bare raw [return true]
				]
			]
		]
		false
	]

	;-- Pad a buffer with zero bytes up to an `align`-byte boundary so the
	;-- next merged section starts at its required alignment.
	pad-to: func [buf [binary!] align [integer!] /local rem][
		if align > 1 [
			unless zero? rem: (length? buf) // align [
				insert/dup tail buf null (align - rem)
			]
		]
	]

	;-- Append an object's kept sections into the build's code/data buffers,
	;-- each aligned to its required boundary; record each section's merged
	;-- base and the build's peak alignment, then register defined externals.
	merge-sections: func [
		job [object!] obj [object!]
		/local code data section kind a base sym sect ckey merged? idx common-live? r sec-kind
	][
		code: job/sections/code/2
		data: job/sections/data/2
		merged?: false
		foreach section obj/sections [
			kind: reader/sec-kind section
			unless section-live? section [kind: none]
			if section-merged? section [kind: none]
			if kind [
				;; COMDAT / SHT_GROUP: drop a section whose key has already
				;; been pulled. The section keeps base-kind='none, so its
				;; symbols won't register either.
				either all [ckey: reader/sec-comdat-key section  find comdat-keys ckey][
					kind: none
				][
					if ckey [append comdat-keys ckey]
					a: reader/sec-align section
					if a > max-align [max-align: a]
				]
			]
			case [
				kind = 'code [
					pad-to code a
					base: length? code
					append code reader/sec-data section
					reader/set-sec-base section 'code base
					poke section 11 true
					merged?: true
				]
				any [kind = 'data  kind = 'rdata][
					pad-to data a
					base: length? data
					append data reader/sec-data section
					reader/set-sec-base section 'data base
					poke section 11 true
					merged?: true
				]
				kind = 'tls [
					pad-to data a
					base: length? data
					if none? tls-start [tls-start: base]
					append data reader/sec-data section
					tls-end: length? data
					reader/set-sec-base section 'data base
					poke section 11 true
					merged?: true
				]
				kind = 'bss [
					pad-to data a
					base: length? data
					insert/dup tail data null reader/sec-size section
					reader/set-sec-base section 'data base
					poke section 11 true
					merged?: true
				]
			]
		]
		idx: 0
		foreach sym obj/symbols [
			sect: reader/sym-sect sym
			common-live?: false
			if all [
				obj-format = 'PE
				sect = 0
				0 < reader/sym-value sym
			][
				foreach section obj/sections [
					sec-kind: reader/sec-base-kind section
					unless sec-kind = 'none [
						foreach r reader/sec-relocs section [
							if r/2 = idx [common-live?: true]
						]
					]
				]
			]
			if all [
				reader/is-defined-external? sym
				any [
					all [
						0 < sect
						section-live? pick obj/sections sect
					]
					all [
						obj-format = 'PE
						sect = 0
						0 < reader/sym-value sym
						any [
							find needed arch-bare reader/sym-name sym
							common-live?
						]
					]
				]
			][register-symbol job obj sym]
			idx: idx + 1
		]
		merged?
	]

	;-- Record a defined external's final merged address. A later strong
	;-- definition replaces an earlier weak one; otherwise first-wins
	;-- (matches COMDAT NODUPLICATES / archive member order).
	register-symbol: func [
		job [object!] obj [object!] sym [block!]
		/local sect section kind base name new-weak existing data data-off
	][
		sect: reader/sym-sect sym
		if all [
			obj-format = 'PE
			sect = 0
			0 < reader/sym-value sym
		][
			name: reader/sym-name sym
			unless select sym-addr name [
				data: job/sections/data/2
				pad-to data 4
				data-off: length? data
				insert/dup tail data null reader/sym-value sym
				repend sym-addr [name reduce ['data data-off false]]
			]
			exit
		]
		if sect <= 0 [exit]
		section: pick obj/sections sect
		kind: either (reader/sec-kind section) = 'tls ['tls][reader/sec-base-kind section]
		if kind = 'none [exit]							;-- symbol lives in a dropped section
		base: reader/sec-base-offset section
		name: reader/sym-name sym
		new-weak: reader/sym-weak? sym
		either existing: select sym-addr name [
			;; strong def replaces an earlier weak def; same-strength = first-wins
			if all [existing/3  not new-weak][
				existing/1: kind
				existing/2: base + reader/sym-value sym
				existing/3: false
			]
		][
			repend sym-addr [
				name reduce [kind  base + reader/sym-value sym  new-weak]
			]
		]
	]

	;-- Walk every merged object's undefined externals and satisfy them by
	;-- emitting a libc import trampoline or the __chkstk stub.
	resolve-externals: func [
		job [object!]
		/local path obj section sym name bare code data tramp-off disp-ref sz data-off imp res stub pending sec-kind
	][
		code: job/sections/code/2
		data: job/sections/data/2
		foreach [path obj] objects [
			pending: copy []
			foreach section obj/sections [
				sec-kind: reader/sec-base-kind section
				unless sec-kind = 'none [
					foreach r reader/sec-relocs section [
						sym: pick obj/symbols (r/2 + 1)
						if all [sym  reader/is-undefined-external? sym  not find pending sym][
							append/only pending sym
						]
					]
				]
			]
			foreach sym pending [
					name: reader/sym-name sym
					unless any [select sym-addr name  find undef-done name][
						append undef-done name
						case [
							;-- COFF common symbol: an UNDEF external whose value
							;-- field is a byte size. Allocate zero-filled storage
							;-- in .data and resolve every reference to it.
							all [obj-format = 'PE  0 < reader/sym-value sym][
								pad-to data 4
								data-off: length? data
								insert/dup tail data null reader/sym-value sym
								repend sym-addr [name reduce ['data data-off false]]
							]
							;-- Small MSVC/clang-cl compiler runtime helpers:
							;-- drop the embedded machine code into the code
							;-- section on demand (see crt-helpers.r).
							stub: select crt-helpers name [
								tramp-off: length? code
								append code stub
								repend sym-addr [name reduce ['code tramp-off false]]
							]
							name = "__ImageBase" [
								repend sym-addr [name reduce ['image-base 0 false]]
							]
							;-- MSVC /GS support: give CRT marker/runtime state
							;-- symbols data slots; the callable stubs are in
							;-- crt-helpers.r.
							any [
								name = "___security_cookie"
								name = "___security_cookie_complement"
								name = "__fltused"
								name = "___isa_available"
							][
								pad-to data 4
								data-off: length? data
								insert/dup tail data null 4
								repend sym-addr [name reduce ['data data-off false]]
							]
							any [
								name = "__tls_index"
								name = "__tls_array"
								name = "__tls_used"
								name = "___tls_used"
							][
								unless tls-start [
									abort reduce ["TLS runtime symbol without .tls section:" name "(in" path ")"]
								]
							]
							sz: accepted-libc-data? name [
								;-- libc DATA symbol: reserve a copy-relocation
								;-- slot in `.data`. ELF.r emits an R_*_COPY so the
								;-- loader fills it at start-up; every reference
								;-- resolves statically to the slot.
								pad-to data 4
								data-off: length? data
								insert/dup tail data null sz
								repend job/static-data [name data-off sz]
								repend sym-addr [name reduce ['data data-off false]]
							]
							res: direct-resolve job name [
								tramp-off: length? code
								case [
									obj-format = 'Mach-o [
										;-- Mach-O imports resolve to a __jump_table
										;-- code stub: MOV eax,<stub>; JMP eax.
										append code #{B8}				;-- MOV eax, imm32
										disp-ref: 1 + length? code
										append code #{00000000}
										append code #{FFE0}			;-- JMP eax
									]
									obj-arch = 'ARM [
										;-- ARM veneer: load the import slot's
										;-- address, then jump through the slot.
										;-- LDR ip,[pc,#0]; LDR pc,[ip]; .word slot
										pad-to code 4					;-- 4-align the veneer
										tramp-off: length? code
										append code #{00C09FE500F09CE5}
										disp-ref: 1 + length? code
										append code #{00000000}			;-- -> import slot VA
									]
									true [
										;-- PE/ELF i386 imports resolve to a pointer
										;-- slot: JMP DWORD PTR [disp32].
										append code #{FF25}
										disp-ref: 1 + length? code		;-- 1-based offset of disp32
										append code #{00000000}
									]
								]
								add-import job res/1 res/2 disp-ref
								repend sym-addr [name reduce ['code tramp-off false]]
							]
							imp: imp-resolve name [
								;-- PE __imp_<fn>: an import-table indirection
								;-- symbol; wire-imp-relocs routes its reference
								;-- sites to a dynamic import on the resolved DLL.
								repend imp-table [name imp]
							]
							all [obj-format = 'ELF  name = "_GLOBAL_OFFSET_TABLE_"] [
								;-- Defined by allocate-got-slots once all
								;-- undefined externals have been resolved.
								0
							]
							true [
								abort reduce ["unresolved external symbol:" name "(in" path ")"]
							]
						]
					]
			]
		]
	]

	;-- Return the bare libc name for an accepted external, or NONE. The name
	;-- is checked against the target C library's exported-symbol set, which
	;-- is embedded in libc-exports.r (generated from the real libraries).
	accepted-libc?: func [name [string!] /local bare][
		;-- PE (MSVC cdecl) and Mach-O (i386 ABI) prefix C symbols with '_';
		;-- ELF (SysV i386) symbols are undecorated, so no strip there.
		bare: copy either all [obj-format <> 'ELF  #"_" = first name][next name][name]
		either find libc-set bare [bare][none]
	]

	;-- Return the byte size of a libc DATA symbol that must be copy-relocated,
	;-- or NONE. The data-symbol set is generated for ELF (glibc) targets only,
	;-- so this never matches for PE / Mach-O builds.
	accepted-libc-data?: func [name [string!]][
		all [libc-data-set  select libc-data-set name]
	]

	;-- Register a function as a dynamic import on `dll`, recording one code
	;-- offset where the IAT slot address is patched in; reuses an existing
	;-- per-function relocation block when present.
	add-import: func [job [object!] dll [string!] bare [string!] offset [integer!] /local imports entry fpos][
		imports: job/sections/import/3
		entry: find imports dll
		unless entry [
			repend imports reduce [dll make block! 8]
			entry: find imports dll
		]
		fpos: find entry/2 bare
		either fpos [
			append fpos/2 offset
		][
			repend entry/2 reduce [bare reduce [offset]]
		]
	]

	libc-name: func [job [object!]][
		switch/default job/OS [
			Windows ["msvcrt.dll"]
			macOS   ["libc.dylib"]
		]["libc.so.6"]
	]

	libm-name: func [job [object!]][
		switch/default job/OS [
			macOS ["libc.dylib"]
		]["libm.so.6"]
	]

	elf-archive?: func [path [file!] /local members][
		members: attempt [read-archive path]
		if none? members [return false]
		foreach member members [
			if (copy/part member/2 4) = #{7F454C46} [return true]
		]
		false
	]

	append-linux-helper-lib: func [out [block!] path [string!]][
		if all [
			not empty? path
			exists? to-rebol-file path
			elf-archive? to-rebol-file path
		][append out to-rebol-file path]
	]

	find-linux-helper-libs: func [/local path out file][
		out: make block! 3
		if system/version/4 <> 4 [return out]			;-- never probe host GCC while cross-compiling from Windows/macOS
		path: copy ""
		call/output "gcc -m32 -print-libgcc-file-name" path
		trim/tail path
		append-linux-helper-lib out path
		foreach file ["libssp_nonshared.a"] [
			path: copy ""
			call/output rejoin ["gcc -m32 -print-file-name=" file] path
			trim/tail path
			if all [
				not empty? path
				file <> path
			][append-linux-helper-lib out path]
		]
		out
	]

	;-- ===== PE __imp_* import-thunk resolution =====

	;-- Build the symbol => DLL hash from the embedded Win32 export snapshot;
	;-- the first DLL listed wins a name exported by more than one.
	build-syslib-index: does [
		syslib-index: make hash! 24000
		foreach [dll names] win32-exports/libs [
			foreach nm names [
				unless select syslib-index nm [
					repend syslib-index reduce [nm dll]
				]
			]
		]
	]

	;-- For a direct (non-__imp_) undefined external, return [DLL bare-name]
	;-- when the bare name is a libc or other system-DLL export, else NONE;
	;-- the reference is then satisfied by a JMP [IAT] trampoline.
	direct-resolve: func [job [object!] name [string!] /local bare dll][
		bare: arch-bare name
		if empty? bare [return none]
		if all [libc-set  find libc-set bare][return reduce [libc-name job  bare]]
		if all [libm-set  find libm-set bare][return reduce [libm-name job  bare]]
		if all [syslib-index  dll: select syslib-index bare][return reduce [dll bare]]
		none
	]

	;-- For a PE __imp_<decorated> undefined external, return [DLL bare-name]
	;-- when the bare name is a known system export, otherwise NONE. The
	;-- export name is tried both fully bared (Win32 stdcall: _Name@N ->
	;-- Name) and with the leading underscore kept (CRT names like _itoa).
	imp-resolve: func [name [string!] /local rest bare dll p][
		if obj-format <> 'PE [return none]
		if (length? name) <= 6 [return none]
		if "__imp_" <> copy/part name 6 [return none]
		rest: skip name 6
		bare: arch-bare rest
		if all [not empty? bare  dll: select syslib-index bare][return reduce [dll bare]]
		bare: copy rest
		if p: find bare #"@" [clear p]
		if all [not empty? bare  dll: select syslib-index bare][return reduce [dll bare]]
		none
	]

	;-- Scan every merged section's relocations: each one targeting an __imp_*
	;-- symbol becomes a dynamic-import reference site (resolve-import-refs
	;-- patches in the IAT slot VA) and is removed so apply-relocs skips it.
	wire-imp-relocs: func [
		job [object!]
		/local path obj section sec-kind sec-base r sym imp
	][
		foreach [path obj] objects [
			foreach section obj/sections [
				sec-kind: reader/sec-base-kind section
				unless sec-kind = 'none [
					sec-base: reader/sec-base-offset section
					remove-each r reader/sec-relocs section [
						sym: pick obj/symbols (r/2 + 1)
						either all [sym  imp: select imp-table reader/sym-name sym][
							either sec-kind = 'code [
								add-import job imp/1 imp/2 (sec-base + r/1 + 1)
								true
							][
								abort reduce [
									"__imp_ reference in non-code section:"
									reader/sym-name sym "(in" path ")"
								]
							]
						][false]
					]
				]
			]
		]
	]

	;-- ===== Registry-located static helper archives (Windows PE) =====
	;-- A PE archive built by MSVC or clang-cl references GUID data
	;-- constants (uuid.lib, dxguid.lib) that no DLL exports. The Windows
	;-- SDK records its install root in HKLM; the archives are read from
	;-- there through reg.exe -- no hard-coded paths, no Program Files scan.

	;-- A read-result entry is a subdirectory iff it ends with a slash;
	;-- `dir?` is unreliable here -- it stats relative to the working dir.
	subdir?: func [f [file!]][all [not empty? f  #"/" = last f]]

	;-- Newest (lexically greatest) immediate subdirectory of `dir`, or none.
	newest-subdir: func [dir [file!] /local items subs f][
		if error? try [items: read dir][return none]
		subs: make block! 16
		foreach f items [if subdir? f [append subs f]]
		either empty? subs [none][last sort subs]
	]

	;-- Read one HKLM string value through reg.exe, trying the 32- then the
	;-- 64-bit registry view; returns the value string, or none if absent.
	;-- reg.exe is a Windows built-in, so this needs nothing installed.
	reg-read: func [key [string!] value [string!] /local out view line p][
		foreach view ["/reg:32" "/reg:64"][
			out: copy ""
			unless error? try [
				call/shell/wait/output
					rejoin [{reg query "} key {" /v "} value {" } view] out
			][
				foreach line parse/all out "^/" [
					if find line value [
						if p: find line "REG_" [		;-- REG_SZ | REG_EXPAND_SZ
							if p: find p " " [return trim copy p]
						]
					]
				]
			]
		]
		none
	]

	;-- Locate the static helper archives from their registered install
	;-- roots; returns a block of resolved archive paths, possibly empty.
	find-helper-libs: func [/local out root libdir ver p lib][
		out: make block! 3
		;-- Windows SDK (uuid.lib / dxguid.lib): the COM and DirectX GUID
		;-- constants -- pure data, exported by no DLL.
		root: reg-read "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots" "KitsRoot10"
		if root [
			libdir: rejoin [to-rebol-file root %Lib/]
			if ver: newest-subdir libdir [
				foreach lib [%uuid.lib %dxguid.lib][
					p: rejoin [libdir ver %um/x86/ lib]
					if exists? p [append out p]
				]
			]
		]
		out
	]

	;-- For each user-imported function, allocate a 4-byte call slot in the
	;-- data section and record the patch job for `apply-relocs`.
	wire-imports: func [
		job [object!] lib [string!] list [block!] cc [word!]
		/local data id reloc info slot
	][
		data: job/sections/data/2
		foreach [id reloc] list [
			info: find-static-symbol id cc
			unless info [
				abort reduce ["static import" id "not defined in" lib]
			]
			either obj-format = 'Mach-o [
				;-- Mach-O import calls are `MOV eax,<imm>; CALL eax`; the
				;-- call target is patched directly with the function VA.
				append call-slots reduce [reloc none info]
			][
				;-- PE/ELF import calls are indirect through a pointer slot.
				slot: length? data
				append data #{00000000}
				append call-slots reduce [reloc slot info]
			]
		]
	]

	;-- Resolve a user-facing C name to its merged [kind offset]. PE/COFF
	;-- applies MSVC i386 decoration (cdecl => _name, stdcall => _name@N);
	;-- ELF i386 (SysV) symbols carry no decoration.
	find-static-symbol: func [id [string!] cc [word!] /local want k v][
		case [
			obj-format = 'ELF [select sym-addr id]			;-- SysV i386: undecorated
			all [obj-format = 'PE  cc = 'stdcall][			;-- MSVC stdcall: _name@N
				want: rejoin ["_" id "@"]
				foreach [k v] sym-addr [
					if all [
						(length? k) > length? want
						want = copy/part k length? want
					][return v]
				]
				none
			]
			true [select sym-addr join "_" id]				;-- PE cdecl / Mach-O: _name
		]
	]

	;-- ===== PE TLS directory support =====

	ensure-symbol: func [name [string!] kind [word!] offset [integer!]][
		unless select sym-addr name [
			repend sym-addr [name reduce [kind offset false]]
		]
	]

	prepare-pe-tls: func [
		job [object!] data-rva [integer!] image-base [integer!]
		/local data data-base start-va end-va index-va callbacks-va
	][
		if any [obj-format <> 'PE  none? tls-start][exit]
		data: job/sections/data/2
		data-base: image-base + data-rva

		unless tls-index [
			pad-to data 4
			tls-index: length? data
			append data #{00000000}
		]
		ensure-symbol "__tls_index" 'data tls-index
		ensure-symbol "__tls_array" 'absolute 44
		unless tls-dir [
			pad-to data 4
			tls-dir: length? data
			start-va: data-base + tls-start
			end-va: data-base + tls-end
			index-va: data-base + tls-index
			callbacks-va: 0
			append data reduce [
				le32 start-va
				le32 end-va
				le32 index-va
				le32 callbacks-va
				le32 0
				le32 0
			]
		]
		ensure-symbol "__tls_used" 'data tls-dir
		ensure-symbol "___tls_used" 'data tls-dir
	]

	pe-tls-rva?: func [data-rva [integer!]][
		either tls-dir [data-rva + tls-dir][0]
	]

	pe-tls-size?: func [][
		either tls-dir [24][0]
	]

	;-- ===== ARM instruction-field relocation encoders =====

	;-- Re-encode a BL/B 24-bit branch immediate (R_ARM_CALL/JUMP24/PC24) so
	;-- the instruction at `patch-va` reaches `target-va`. The in-place imm24
	;-- field is the addend (sign-extended, <<2 — it already folds in ARM's
	;-- 8-byte pipeline bias).
	arm-encode-call: func [
		insn [integer!] target-va [integer!] patch-va [integer!]
		/local a disp h actual
	][
		a: insn and 16777215							;-- imm24
		if a >= 8388608 [a: a - 16777216]				;-- sign-extend (24-bit)
		;; ARM -> Thumb interworking: a BL whose target carries the T-bit
		;; is rewritten as the unconditional BLX (immediate, A2) so the CPU
		;; switches to Thumb on the jump; the H bit holds disp[1] for
		;; 2-byte-aligned (but not 4-byte-aligned) Thumb destinations.
		either (target-va and 1) <> 0 [
			actual: target-va and -2
			disp: (actual + (a * 4)) - patch-va
			h: (shift/logical disp 1) and 1
			(to integer! #{FA000000})
				or (shift/left h 24)
				or ((shift disp 2) and 16777215)
		][
			disp: (target-va + (a * 4)) - patch-va
			(insn and to integer! #{FF000000})
				or ((shift disp 2) and 16777215)
		]
	]

	;-- Read / write the 16-bit immediate split across a MOVW/MOVT instruction
	;-- (imm4 in bits 19:16, imm12 in bits 11:0).
	arm-movw-get: func [insn [integer!]][
		(shift/left ((shift/logical insn 16) and 15) 12) or (insn and 4095)
	]
	arm-movw-put: func [insn [integer!] imm16 [integer!]][
		(insn and to integer! #{FFF0F000})
			or (shift/left ((shift/logical imm16 12) and 15) 16)
			or (imm16 and 4095)
	]

	;-- Thumb-2 BL/B 25-bit branch immediate (R_ARM_THM_CALL / THM_JUMP24).
	;-- The two halfwords pack S, J1, J2, imm10, imm11 into a signed byte
	;-- displacement (LSB implicit 0). For an ARM target via THM_CALL the
	;-- linker swaps BL -> BLX (clear hw2 bit 12, force imm11 bit 0 = 0).
	arm-encode-thm-call: func [
		insn [integer!] target-va [integer!] patch-va [integer!]
		/local hw1 hw2 S J1 J2 imm10 imm11 I1 I2 addend
			thumb-target? is-bl? disp
			new-S new-I1 new-I2 new-J1 new-J2 new-imm10 new-imm11
			new-hw1 new-hw2
	][
		hw1: insn and 65535
		hw2: (shift/logical insn 16) and 65535
		;; decode in-place addend (signed 25-bit byte displacement)
		S:     (shift/logical hw1 10) and 1
		imm10: hw1 and 1023
		J1:    (shift/logical hw2 13) and 1
		J2:    (shift/logical hw2 11) and 1
		imm11: hw2 and 2047
		I1: 1 xor (J1 xor S)
		I2: 1 xor (J2 xor S)
		addend: (shift/left S 24)
			or (shift/left I1 23)
			or (shift/left I2 22)
			or (shift/left imm10 12)
			or (shift/left imm11 1)
		if S = 1 [addend: addend - 33554432]		;-- sign-extend from bit 24

		thumb-target?: (target-va and 1) <> 0
		is-bl?: ((shift/logical hw2 14) and 1) = 1
		if all [not is-bl?  not thumb-target?][
			abort reduce ["R_ARM_THM_JUMP24 to ARM target -- Thumb B cannot interwork"]
		]

		;; AAELF: result = (S+A)|T - P. target-va already carries the T-bit.
		disp: target-va + addend - patch-va

		new-S:     (shift/logical disp 24) and 1
		new-I1:    (shift/logical disp 23) and 1
		new-I2:    (shift/logical disp 22) and 1
		new-imm10: (shift/logical disp 12) and 1023
		new-imm11: either all [is-bl?  not thumb-target?][
			(shift/logical disp 1) and 2046			;-- BLX: bit 0 = 0 (4-aligned target)
		][
			(shift/logical disp 1) and 2047
		]
		new-J1: 1 xor (new-I1 xor new-S)
		new-J2: 1 xor (new-I2 xor new-S)

		new-hw1: (hw1 and to integer! #{F800})
			or (shift/left new-S 10)
			or new-imm10
		new-hw2: (hw2 and to integer! #{D000})
			or (shift/left new-J1 13)
			or (shift/left new-J2 11)
			or new-imm11
		if is-bl? [
			either thumb-target? [
				new-hw2: new-hw2 or 4096			;-- BL  (hw2 bit 12 = 1)
			][
				new-hw2: new-hw2 and to integer! #{EFFF}	;-- BLX (hw2 bit 12 = 0)
			]
		]
		new-hw1 or (shift/left new-hw2 16)
	]

	;-- Read / write the 16-bit immediate split across a Thumb-2 MOVW/MOVT:
	;-- imm4 in hw1 bits[3:0], i in hw1 bit[10], imm3 in hw2 bits[14:12],
	;-- imm8 in hw2 bits[7:0]. imm16 = (imm4<<12)|(i<<11)|(imm3<<8)|imm8.
	arm-thm-movw-get: func [insn [integer!] /local hw1 hw2 imm4 i imm3 imm8][
		hw1: insn and 65535
		hw2: (shift/logical insn 16) and 65535
		imm4: hw1 and 15
		i:    (shift/logical hw1 10) and 1
		imm3: (shift/logical hw2 12) and 7
		imm8: hw2 and 255
		(shift/left imm4 12)
			or (shift/left i 11)
			or (shift/left imm3 8)
			or imm8
	]
	arm-thm-movw-put: func [
		insn [integer!] imm16 [integer!]
		/local hw1 hw2 imm4 i imm3 imm8 new-hw1 new-hw2
	][
		hw1: insn and 65535
		hw2: (shift/logical insn 16) and 65535
		imm4: (shift/logical imm16 12) and 15
		i:    (shift/logical imm16 11) and 1
		imm3: (shift/logical imm16 8) and 7
		imm8: imm16 and 255
		new-hw1: (hw1 and to integer! #{FBF0}) or imm4 or (shift/left i 10)
		new-hw2: (hw2 and to integer! #{8F00}) or (shift/left imm3 12) or imm8
		new-hw1 or (shift/left new-hw2 16)
	]

	;-- ===== ELF i386 synthetic GOT support =====

	resolve-reloc-target: func [
		obj		[object!]
		sym		[block!]
		path
		/local target-info tsect tsection tkind toff
	][
		target-info: either any [
			reader/is-defined-external? sym
			reader/is-undefined-external? sym
		][
			select sym-addr reader/sym-name sym
		][none]
		either target-info [
			target-info
		][
			tsect: reader/sym-sect sym
			either all [tsect > 0  tsect <= length? obj/sections][
				tsection: pick obj/sections tsect
				tkind: reader/sec-base-kind tsection
				if tkind = 'none [
					abort reduce ["relocation targets a dropped section:" reader/sym-name sym "in" path]
				]
				toff: (reader/sec-base-offset tsection) + reader/sym-value sym
				reduce [tkind toff false]
			][
				abort reduce ["unresolved symbol" reader/sym-name sym "in" path]
			]
		]
	]

	target-va?: func [
		tkind		[word!]
		toff		[integer!]
		code-base	[integer!]
		data-base	[integer!]
		image-base	[integer!]
	][
		case [
			tkind = 'image-base [image-base]
			tkind = 'absolute	[toff]
			tkind = 'tls		[data-base + toff]
			tkind = 'data		[data-base + toff]
			true				[code-base + toff]
		]
	]

	got-key: func [
		path
		sym		[block!]
		index	[integer!]
		/local name
	][
		name: reader/sym-name sym
		either any [
			empty? name
			not any [
				reader/is-defined-external? sym
				reader/is-undefined-external? sym
			]
		][
			rejoin [form path "#" index]
		][
			copy name
		]
	]

	ensure-got-base: func [job [object!] /local data][
		if got-start <> none [exit]
		data: job/sections/data/2
		pad-to data 4
		got-start: length? data
		unless select sym-addr "_GLOBAL_OFFSET_TABLE_" [
			repend sym-addr ["_GLOBAL_OFFSET_TABLE_" reduce ['data got-start false]]
		]
	]

	ensure-got-slot: func [
		job		[object!]
		key		[string!]
		info	[block!]
		/local data entry slot
	][
		if entry: select got-slots key [return entry/1]
		ensure-got-base job
		data: job/sections/data/2
		pad-to data 4
		slot: length? data
		append data #{00000000}
		repend got-slots [copy key reduce [slot info/1 info/2]]
		slot
	]

	allocate-got-slots: func [
		job [object!]
		/local path obj section sec-kind r sym kind info key
	][
		if obj-format <> 'ELF [exit]
		foreach [path obj] objects [
			foreach section obj/sections [
				sec-kind: reader/sec-base-kind section
				unless sec-kind = 'none [
					foreach r reader/sec-relocs section [
						kind: reader/reloc-kind r/3
						if any [kind = 'got32 kind = 'gotoff kind = 'gotpc][
							ensure-got-base job
						]
						if kind = 'got32 [
							sym: pick obj/symbols (r/2 + 1)
							unless sym [abort reduce ["bad relocation symbol index" r/2 "in" path]]
							info: resolve-reloc-target obj sym path
							key: got-key path sym r/2
							ensure-got-slot job key info
						]
					]
				]
			]
		]
	]

	write-got-slots: func [
		job			[object!]
		code-base	[integer!]
		data-base	[integer!]
		image-base	[integer!]
		/local data key entry target-va
	][
		if any [got-start = none  empty? got-slots][exit]
		data: job/sections/data/2
		foreach [key entry] got-slots [
			target-va: target-va? entry/2 entry/3 code-base data-base image-base
			change at data (entry/1 + 1) le32 target-va
		]
	]

	;-- ===== formats/{PE,ELF}.r hook : apply relocations after layout =====

	apply-relocs: func [
		job [object!] code-base [integer!] data-base [integer!] image-base [integer!]
		/local code data reloc slot info section sec-kind sec-base buf buf-base
			r r-va r-sym r-type sym target-info tkind toff target-va kind
			patch-pos patch-va addend path obj insn a16 got-slot got-base
			sym-name key entry
	][
		if empty? objects [exit]
		code: job/sections/code/2
		data: job/sections/data/2
		write-got-slots job code-base data-base image-base

		;-- Wire user-import call sites to their merged functions.
		foreach [reloc slot info] call-slots [
			either none? slot [
				;-- Mach-O: patch the call's immediate with the function VA.
				foreach r reloc [change at code r le32 (code-base + info/2)]
			][
				;-- PE/ELF: fill the pointer slot, patch sites with its VA.
				change at data (slot + 1) le32 (code-base + info/2)
				foreach r reloc [change at code r le32 (data-base + slot)]
			]
		]

		;-- Apply every relocation from every merged section.
		foreach [path obj] objects [
			foreach section obj/sections [
				sec-kind: reader/sec-base-kind section
				unless sec-kind = 'none [
					sec-base: reader/sec-base-offset section
					buf:      either sec-kind = 'code [code][data]
					buf-base: either sec-kind = 'code [code-base][data-base]
					foreach r reader/sec-relocs section [
						r-va:   r/1
						r-sym:  r/2
						r-type: r/3
						sym: pick obj/symbols (r-sym + 1)
						unless sym [abort reduce ["bad relocation symbol index" r-sym "in" path]]

						;-- Resolve the target's final merged address.
						target-info: resolve-reloc-target obj sym path
						tkind: target-info/1
						toff:  target-info/2
						target-va: target-va? tkind toff code-base data-base image-base
						patch-pos: sec-base + r-va			;-- 0-based offset into buf
						addend:    reader/i32-le buf (patch-pos + 1)
						kind:      reader/reloc-kind r-type
						got-base:  either got-start = none [0][data-base + got-start]
						sym-name:  reader/sym-name sym

						;-- Mach-O i386 stores a pcrel field's displacement
						;-- relative to the containing section's start; fold
						;-- r-va in so the COFF/ELF "addend at the field" model
						;-- applies uniformly below.
						if all [obj-format = 'Mach-o  kind = 'pc32][
							addend: addend + r-va
						]

						case [
							kind = 'abs32 [
								change at buf (patch-pos + 1) le32 (target-va + addend)
							]
							kind = 'pc32 [
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 ((target-va + addend) - patch-va - reader/pc-bias)
							]
							kind = 'plt32 [
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 ((target-va + addend) - patch-va - reader/pc-bias)
							]
							kind = 'gotpc [
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 ((got-base + addend) - patch-va - reader/pc-bias)
							]
							kind = 'gotoff [
								change at buf (patch-pos + 1)
									le32 ((target-va + addend) - got-base)
							]
							kind = 'got32 [
								key: got-key path sym r-sym
								entry: select got-slots key
								unless entry [abort reduce ["missing GOT slot:" sym-name "(in" path ")"]]
								got-slot: entry/1
								change at buf (patch-pos + 1)
									le32 (((data-base + got-slot) + addend) - got-base)
							]
							kind = 'rva32 [
								change at buf (patch-pos + 1)
									le32 ((target-va - image-base) + addend)
							]
							kind = 'secrel32 [
								change at buf (patch-pos + 1)
									le32 (addend + either tkind = 'tls [toff - tls-start][toff])
							]
							kind = 'arm-call [
								insn:     reader/u32-le buf (patch-pos + 1)
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 (arm-encode-call insn target-va patch-va)
							]
							kind = 'arm-movw [
								insn: reader/u32-le buf (patch-pos + 1)
								a16:  arm-movw-get insn
								if a16 >= 32768 [a16: a16 - 65536]	;-- sign-extend (16-bit)
								change at buf (patch-pos + 1)
									le32 (arm-movw-put insn ((target-va + a16) and 65535))
							]
							kind = 'arm-movt [
								insn: reader/u32-le buf (patch-pos + 1)
								a16:  arm-movw-get insn
								if a16 >= 32768 [a16: a16 - 65536]	;-- sign-extend (16-bit)
								change at buf (patch-pos + 1)
									le32 (arm-movw-put insn ((shift/logical (target-va + a16) 16) and 65535))
							]
							kind = 'arm-thm-call [
								insn:     reader/u32-le buf (patch-pos + 1)
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 (arm-encode-thm-call insn target-va patch-va)
							]
							kind = 'arm-thm-movw [
								insn: reader/u32-le buf (patch-pos + 1)
								a16:  arm-thm-movw-get insn
								if a16 >= 32768 [a16: a16 - 65536]	;-- sign-extend (16-bit)
								change at buf (patch-pos + 1)
									le32 (arm-thm-movw-put insn ((target-va + a16) and 65535))
							]
							kind = 'arm-thm-movt [
								insn: reader/u32-le buf (patch-pos + 1)
								a16:  arm-thm-movw-get insn
								if a16 >= 32768 [a16: a16 - 65536]	;-- sign-extend (16-bit)
								change at buf (patch-pos + 1)
									le32 (arm-thm-movw-put insn ((shift/logical (target-va + a16) 16) and 65535))
							]
							kind = 'none []						;-- absolute/no-op relocation
							true [
								abort reduce ["unsupported relocation type" r-type "in" path]
							]
						]
					]
				]
			]
		]
	]
]
