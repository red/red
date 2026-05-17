REBOL [
	Title:   "Red/System static linker for external C objects"
	Author:  "Nenad Rakocevic"
	File: 	 %linker-static.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Statically links external C object files and archives referenced
		through #import "<file>.obj" / "<file>.lib". Phase 0: 32-bit PE/COFF.

		Pipeline:
		  register     -- compiler.r/process-import : records resolved paths
		  merge        -- linker.r/build           : merges sections, resolves
		                                             externals, allocates slots
		  apply-relocs -- formats/PE.r/build        : patches relocations once
		                                             section addresses are fixed
	}
]

do-cache %system/formats/COFF.r

static-link: context [

	;-- ===== Per-build state (populated by `merge`, read by `apply-relocs`) =====

	objects:    make block! 10		;-- [path coff-object ...] every merged object
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
	]

	abort: func [msg [block!]][
		print rejoin ["*** Static linking error: " reform msg]
		system-dialect/compiler/quit-on-error
	]

	;-- ===== Helpers =====

	;-- TRUE when an #import target names a static object/archive.
	library?: func [name [string!] /local s][
		s: lowercase copy name
		any [
			all [(length? s) >= 4  ".obj" = skip tail s -4]
			all [(length? s) >= 4  ".lib" = skip tail s -4]
		]
	]

	archive?: func [name [string!]][
		".lib" = lowercase skip tail copy name -4
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
		/local static-libs lib list info path
	][
		clear objects
		clear sym-addr
		clear call-slots
		clear undef-done

		if any [none? job/static-objs  empty? job/static-objs][exit]

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
			members: coff/parse-lib path
			foreach m members [
				sub: coff/load-from-bin m/2 (rejoin [to-local-file path "(" m/1 ")"])
				if sub [
					merge-sections job sub
					repend objects [sub/path sub]
				]
			]
		][
			obj: coff/load path
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
			kind: coff/sec-kind section
			case [
				kind = 'code [
					base: length? code
					append code coff/sec-data section
					coff/set-sec-base section 'code base
				]
				any [kind = 'data  kind = 'rdata][
					base: length? data
					append data coff/sec-data section
					coff/set-sec-base section 'data base
				]
				kind = 'bss [
					base: length? data
					append/dup data null coff/sec-size section
					coff/set-sec-base section 'data base
				]
			]
		]
		foreach sym obj/symbols [
			if coff/is-defined-external? sym [register-symbol obj sym]
		]
	]

	;-- Record a defined external's final merged address. First definition
	;-- wins (matches COMDAT NODUPLICATES).
	register-symbol: func [obj [object!] sym [block!] /local sect section kind base name][
		sect: coff/sym-sect sym
		if sect <= 0 [exit]
		section: pick obj/sections sect
		kind: coff/sec-base-kind section
		if kind = 'none [exit]						;-- symbol lives in a dropped section
		base: coff/sec-base-offset section
		name: coff/sym-name sym
		unless select sym-addr name [
			repend sym-addr [name reduce [kind base + coff/sym-value sym]]
		]
	]

	;-- Walk every merged object's undefined externals and satisfy them by
	;-- emitting a libc import trampoline or the __chkstk stub.
	resolve-externals: func [job [object!] /local path obj sym name bare code tramp-off disp-ref][
		code: job/sections/code/2
		foreach [path obj] objects [
			foreach sym obj/symbols [
				if coff/is-undefined-external? sym [
					name: coff/sym-name sym
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

	;-- Return the bare libc name for an accepted external, or NONE.
	whitelisted?: func [name [string!] /local bare][
		bare: copy either #"_" = first name [next name][name]
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

	;-- Resolve a user-facing C name to its merged [kind offset], applying
	;-- MSVC i386 name decoration: cdecl => _name, stdcall => _name@N.
	find-static-symbol: func [id [string!] cc [word!] /local want k v][
		either cc = 'stdcall [
			want: rejoin ["_" id "@"]
			foreach [k v] sym-addr [
				if all [
					(length? k) > length? want
					want = copy/part k length? want
				][
					return v
				]
			]
			none
		][
			select sym-addr join "_" id
		]
	]

	;-- ===== formats/PE.r hook : apply relocations once addresses are fixed =====

	apply-relocs: func [
		job [object!] code-base [integer!] data-base [integer!] image-base [integer!]
		/local code data reloc slot info section sec-kind sec-base buf buf-base
			r r-va r-sym r-type sym target-info tkind toff target-va
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
				sec-kind: coff/sec-base-kind section
				unless sec-kind = 'none [
					sec-base: coff/sec-base-offset section
					buf:      either sec-kind = 'code [code][data]
					buf-base: either sec-kind = 'code [code-base][data-base]
					foreach r coff/sec-relocs section [
						r-va:   r/1
						r-sym:  r/2
						r-type: r/3
						sym: pick obj/symbols (r-sym + 1)
						unless sym [abort reduce ["bad relocation symbol index" r-sym "in" path]]

						;-- Resolve the target's final merged address.
						target-info: select sym-addr coff/sym-name sym
						either target-info [
							tkind: target-info/1
							toff:  target-info/2
						][
							;-- Section-local (static, class=3) symbol fallback.
							tsect: coff/sym-sect sym
							either all [tsect > 0  tsect <= length? obj/sections][
								tsection: pick obj/sections tsect
								tkind: coff/sec-base-kind tsection
								if tkind = 'none [
									abort reduce ["relocation targets a dropped section:" coff/sym-name sym "in" path]
								]
								toff: (coff/sec-base-offset tsection) + coff/sym-value sym
							][
								abort reduce ["unresolved symbol" coff/sym-name sym "in" path]
							]
						]
						target-va: case [
							tkind = 'image-base [image-base]
							tkind = 'data      [data-base + toff]
							true               [code-base + toff]
						]
						patch-pos: sec-base + r-va			;-- 0-based offset into buf
						addend:    coff/i32-le buf (patch-pos + 1)

						case [
							r-type = coff/IMAGE_REL_I386_DIR32 [
								change at buf (patch-pos + 1) le32 (target-va + addend)
							]
							r-type = coff/IMAGE_REL_I386_REL32 [
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 ((target-va + addend) - (patch-va + 4))
							]
							r-type = coff/IMAGE_REL_I386_DIR32NB [
								change at buf (patch-pos + 1)
									le32 ((target-va - image-base) + addend)
							]
							r-type = coff/IMAGE_REL_I386_ABSOLUTE []	;-- no-op
							true [
								abort reduce ["unsupported i386 relocation type" r-type "in" path]
							]
						]
					]
				]
			]
		]
	]
]
