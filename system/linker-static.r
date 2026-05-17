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

static-link: context [

	;-- ===== Per-build state =====

	reader:     none				;-- coff | elf-obj, chosen from job/format
	obj-format: none				;-- 'PE | 'ELF
	objects:    make block! 10		;-- [path object ...] every merged object
	sym-addr:   make hash!  200		;-- C-name => [kind offset]  kind: 'code|'data|'image-base
	call-slots: make block! 40		;-- [reloc-refs slot-offset target-info ...]
	undef-done: make block! 20		;-- undefined externals already resolved

	;-- 4-byte little-endian serializer (target endianness is set up by the
	;-- time `apply-relocs` runs, during linking).
	ptr-struct: make-struct [value [integer!]] none
	le32: func [n [integer!]][ptr-struct/value: n  form-struct ptr-struct]

	;-- x86 __chkstk stub: receives total frame size in EAX, returns with
	;-- ESP decremented by EAX (MSVC contract). 18 bytes.
	chkstk-stub: #{518D4C24082BC88BC48BE18B088B400450C3}

	;-- Undefined externals accepted as C-runtime imports. Anything outside
	;-- this set raises a link error rather than silently binding to libc.
	libc-whitelist: [
		"memcpy" "memmove" "memset" "memcmp" "memchr"
		"malloc" "calloc" "realloc" "free"
		"strlen" "strcmp" "strncmp" "strcpy" "strncpy" "strcat" "strchr" "strstr"
		"abort" "exit" "atoi" "atol" "qsort" "bsearch"
		"printf" "sprintf" "snprintf" "fprintf" "puts" "putchar" "fputs"
		"fopen" "fclose" "fread" "fwrite" "fseek" "ftell" "fflush"
		"pow" "sqrt" "exp" "log" "sin" "cos" "tan" "floor" "ceil" "fabs"
		;-- glibc fortified-source and protector helpers
		"__memcpy_chk" "__memmove_chk" "__memset_chk" "__strcpy_chk"
		"__strcat_chk" "__sprintf_chk" "__snprintf_chk" "__printf_chk"
		"__fprintf_chk" "__assert_fail" "__stack_chk_fail"
	]

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
							(b: to integer! pick longnames i) <> 0
							b <> 47						;-- '/' also terminates
						]][
							append real-name to char! b
							i: i + 1
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
		clear sym-addr
		clear call-slots
		clear undef-done

		if any [none? job/static-objs  empty? job/static-objs][exit]

		obj-format: job/format
		reader: case [
			obj-format = 'PE  [coff]
			obj-format = 'ELF [elf-obj]
			true [abort reduce ["static linking unsupported for format:" obj-format]]
		]

		;-- Pull static [lib list] pairs out of the dynamic import table.
		static-libs: extract-static-imports job

		;-- Pass 1: load every object, merge its sections, register symbols.
		foreach [lib list] static-libs [
			info: select job/static-objs lowercase copy lib
			unless info [abort reduce ["unregistered static import:" lib]]
			load-and-merge job lib info/1
		]
		;-- Pass 2: satisfy undefined externals (libc trampolines, stubs).
		resolve-externals job
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

	load-and-merge: func [job [object!] lib [string!] path [file!] /local obj members m sub][
		either archive? lib [
			members: read-archive path
			foreach m members [
				sub: reader/load-from-bin m/2 (rejoin [to-local-file path "(" m/1 ")"])
				if sub [
					merge-sections job sub
					repend objects [sub/path sub]
				]
			]
		][
			obj: reader/load path
			merge-sections job obj
			repend objects [obj/path obj]
		]
	]

	;-- Append an object's kept sections into the build's code/data buffers,
	;-- record each section's merged base, then register defined externals.
	merge-sections: func [job [object!] obj [object!] /local code data section kind base sym][
		code: job/sections/code/2
		data: job/sections/data/2
		foreach section obj/sections [
			kind: reader/sec-kind section
			case [
				kind = 'code [
					base: length? code
					append code reader/sec-data section
					reader/set-sec-base section 'code base
				]
				any [kind = 'data  kind = 'rdata][
					base: length? data
					append data reader/sec-data section
					reader/set-sec-base section 'data base
				]
				kind = 'bss [
					base: length? data
					insert/dup tail data null reader/sec-size section
					reader/set-sec-base section 'data base
				]
			]
		]
		foreach sym obj/symbols [
			if reader/is-defined-external? sym [register-symbol obj sym]
		]
	]

	;-- Record a defined external's final merged address. First definition
	;-- wins (matches COMDAT NODUPLICATES / archive member order).
	register-symbol: func [obj [object!] sym [block!] /local sect section kind base name][
		sect: reader/sym-sect sym
		if sect <= 0 [exit]
		section: pick obj/sections sect
		kind: reader/sec-base-kind section
		if kind = 'none [exit]							;-- symbol lives in a dropped section
		base: reader/sec-base-offset section
		name: reader/sym-name sym
		unless select sym-addr name [
			repend sym-addr [name reduce [kind base + reader/sym-value sym]]
		]
	]

	;-- Walk every merged object's undefined externals and satisfy them by
	;-- emitting a libc import trampoline or the __chkstk stub.
	resolve-externals: func [job [object!] /local path obj sym name bare code tramp-off disp-ref][
		code: job/sections/code/2
		foreach [path obj] objects [
			foreach sym obj/symbols [
				if reader/is-undefined-external? sym [
					name: reader/sym-name sym
					unless any [select sym-addr name  find undef-done name][
						append undef-done name
						case [
							name = "__chkstk" [
								tramp-off: length? code
								append code chkstk-stub
								repend sym-addr [name reduce ['code tramp-off]]
							]
							name = "__ImageBase" [
								repend sym-addr [name reduce ['image-base 0]]
							]
							bare: whitelisted? name [
								tramp-off: length? code
								append code #{FF25}				;-- JMP DWORD PTR [disp32]
								disp-ref: 1 + length? code			;-- 1-based offset of disp32
								append code #{00000000}
								add-libc-import job bare disp-ref
								repend sym-addr [name reduce ['code tramp-off]]
							]
							true [
								abort reduce ["unresolved external symbol:" name "(in" path ")"]
							]
						]
					]
				]
			]
		]
	]

	;-- Return the bare libc name for an accepted external, or NONE. The
	;-- leading-underscore strip is a no-op on ELF (SysV i386 has no prefix).
	whitelisted?: func [name [string!] /local bare][
		;-- The leading-underscore strip removes MSVC i386 cdecl decoration;
		;-- ELF (SysV i386) symbols are undecorated, so no strip there.
		bare: copy either all [obj-format = 'PE  #"_" = first name][next name][name]
		either find libc-whitelist bare [bare][none]
	]

	;-- Register a libc import on the system C library's dynamic-import entry,
	;-- reusing an existing per-function relocation block when present.
	add-libc-import: func [job [object!] bare [string!] offset [integer!] /local imports dll entry fpos][
		dll: libc-name job
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
			macOS   ["libSystem.B.dylib"]
		]["libc.so.6"]
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
			slot: length? data
			append data #{00000000}
			append call-slots reduce [reloc slot info]
		]
	]

	;-- Resolve a user-facing C name to its merged [kind offset]. PE/COFF
	;-- applies MSVC i386 decoration (cdecl => _name, stdcall => _name@N);
	;-- ELF i386 (SysV) symbols carry no decoration.
	find-static-symbol: func [id [string!] cc [word!] /local want k v][
		either obj-format = 'PE [
			either cc = 'stdcall [
				want: rejoin ["_" id "@"]
				foreach [k v] sym-addr [
					if all [
						(length? k) > length? want
						want = copy/part k length? want
					][return v]
				]
				none
			][
				select sym-addr join "_" id
			]
		][
			select sym-addr id
		]
	]

	;-- ===== formats/{PE,ELF}.r hook : apply relocations after layout =====

	apply-relocs: func [
		job [object!] code-base [integer!] data-base [integer!] image-base [integer!]
		/local code data reloc slot info section sec-kind sec-base buf buf-base
			r r-va r-sym r-type sym target-info tkind toff target-va kind
			patch-pos patch-va addend path obj tsect tsection
	][
		if empty? objects [exit]
		code: job/sections/code/2
		data: job/sections/data/2

		;-- Fill user-import call slots and patch their call sites.
		foreach [reloc slot info] call-slots [
			change at data (slot + 1) le32 (code-base + info/2)
			foreach r reloc [change at code r le32 (data-base + slot)]
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
						target-info: select sym-addr reader/sym-name sym
						either target-info [
							tkind: target-info/1
							toff:  target-info/2
						][
							;-- Section symbol / local symbol fallback.
							tsect: reader/sym-sect sym
							either all [tsect > 0  tsect <= length? obj/sections][
								tsection: pick obj/sections tsect
								tkind: reader/sec-base-kind tsection
								if tkind = 'none [
									abort reduce ["relocation targets a dropped section:" reader/sym-name sym "in" path]
								]
								toff: (reader/sec-base-offset tsection) + reader/sym-value sym
							][
								abort reduce ["unresolved symbol" reader/sym-name sym "in" path]
							]
						]
						target-va: case [
							tkind = 'image-base [image-base]
							tkind = 'data      [data-base + toff]
							true               [code-base + toff]
						]
						patch-pos: sec-base + r-va			;-- 0-based offset into buf
						addend:    reader/i32-le buf (patch-pos + 1)

						kind: reader/reloc-kind r-type
						case [
							kind = 'abs32 [
								change at buf (patch-pos + 1) le32 (target-va + addend)
							]
							kind = 'pc32 [
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 ((target-va + addend) - patch-va - reader/pc-bias)
							]
							kind = 'rva32 [
								change at buf (patch-pos + 1)
									le32 ((target-va - image-base) + addend)
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
