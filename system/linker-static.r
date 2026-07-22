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
do-cache %system/formats/mac-cxx-exports.r
do-cache %system/formats/mac-libsystem.r
do-cache %system/formats/crt-helpers.r

static-link: context [

	;-- ===== Per-build state =====

	reader:     none				;-- coff | elf-obj, chosen from job/format
	obj-format: none				;-- 'PE | 'ELF
	obj-arch:   none				;-- 'IA-32 | 'ARM  (job/target)
	objects:    make block! 10		;-- [path object ...] every merged object
	needed:     make hash!  64		;-- referenced symbol names (drives archive member pulling)
	seed-hash:  make hash!  64		;-- user #import names (+ '_'-decorated forms on PE/Mach-O)
	comdat-keys: make hash!  32		;-- COMDAT / SHT_GROUP key => [kind base size obj name] of the kept copy's primary member
	alias-table: make hash! 32		;-- name => fallback name (weak defaults, /alternatename)
	default-libs: make block! 8		;-- accumulated /defaultlib names (lowercased)
	crt-sections: make block! 16	;-- deferred .CRT$X?? contributions [name section obj ...]
	tls-pe-sections: make block! 8	;-- deferred PE .tls$ contributions [name section obj ...]
	absorbed:   make hash!  64		;-- object paths whose aliases/directives are recorded
	;-- Auto-pulling the MSVC static CRT (P2) is gated off: the CRT hardens
	;-- read-only-after-init data with runtime VirtualProtect, which Red's
	;-- single merged .data section cannot satisfy without page-isolated
	;-- output sections by protection class -- a change to Red's PE model.
	;-- The machinery (defaultlib resolution, entry handover, TLS/guard
	;-- handling) stays in place behind this flag pending that decision.
	crt-link-enabled?: yes

	crt-mode?:  none				;-- MSVC static CRT link engaged (auto: /defaultlib libcmt)
	crt-entry:  none				;-- merged code offset of _mainCRTStartup (PE entry override)
	opened-libs: make hash! 16		;-- /defaultlib names already opened or attempted
	msvc-dirs:  none				;-- located VC-toolset / Windows-SDK lib directories
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
	tls-dir-kind: 'data				;-- section the published directory lives in: data | crodata

	;-- Read-only external data (PE): merged into its own page-aligned .rdata
	;-- output section so the MSVC CRT's read-only-after-init page hardening
	;-- (VirtualProtect) can never catch a writable neighbour. crodata-buf is
	;-- the section content; crodata-base is its image VA, set by PE.r before
	;-- apply-relocs. ELF/Mach-O keep read-only data in .data (no crodata).
	crodata-buf:  none
	crodata-base: none

	;-- Read-only-AFTER-init data (PE): pointers the MSVC CRT initializes at
	;-- startup and then VirtualProtects read-only -- chiefly the Control-Flow
	;-- Guard dispatch pointers. They must be writable at load (the CRT writes
	;-- them) yet page-isolated from ordinary writable globals (the CRT's
	;-- re-protection is page-granular), so they get their own RW section.
	cafter-buf:   none				;-- section content (RW, page-isolated)
	cafter-base:  none				;-- image VA, set by PE.r before apply-relocs
	cafter-fills: make block! 8		;-- [cafter-offset code-tramp-offset ...] filled at apply-relocs

	;-- ELF C++ substrate: .eh_frame runs and .init_array entries are deferred
	;-- (like .CRT$X??) and laid out contiguously once every member is in --
	;-- crtbeginT's frame-registry header must open the .eh_frame run and
	;-- crtend's zero terminator must close it, whatever the pull order was.
	eh-frames:   make block! 64		;-- [seq obj section ...] deferred .eh_frame
	init-arrays: make block! 32		;-- [seq obj section ...] deferred .init_array
	cpp-mode?:   none				;-- ELF C++ runtime archives pulled
	cpp-entry:   none				;-- ctor-walk stub offset in code (ELF.r entry)
	cpp-seq:     0					;-- arrival counter for the deferred lists
	weak-undefs:   make hash! 64	;-- ELF names referenced weak-undefined
	strong-undefs: make hash! 256	;-- ELF names referenced strong-undefined

	;-- ELF thread-local storage: the output is an executable = TLS module 1,
	;-- so the template is laid out at link time and every TLS relocation
	;-- resolves to a constant. GD/LDM GOT pairs get {dtpmod=1, dtpoff};
	;-- IE slots get tpoff; the i386 thread pointer sits at the END of the
	;-- block, so tpoff = offset - align-up(memsz, align).
	tls-sections: make block! 16	;-- [seq obj section ...] deferred .tdata/.tbss
	etls-off:    none				;-- template offset inside .data
	etls-filesz: 0					;-- .tdata bytes
	etls-memsz:  0					;-- .tdata + .tbss
	etls-align:  4

	exidx-range: none				;-- merged EHABI index [.data-offset size], for PT_ARM_EXIDX

	;-- ARM EHABI: .ARM.exidx unwind-index sections are deferred and merged
	;-- as ONE table sorted by covered-function address (the unwinder
	;-- binary-searches [__exidx_start, __exidx_end)). sh_link names each
	;-- index section's text section; merge order of text = address order.
	exidx-sections: make block! 64	;-- [obj section ...] deferred .ARM.exidx

	;-- Mach-O: the merged __eh_frame goes into its OWN section in __TEXT --
	;-- Darwin's libunwind locates unwind data BY SECTION NAME in the image
	;-- (raw DWARF parse; no registry, no terminator).
	ehframe-buf:  none				;-- section content
	ehframe-base: none				;-- image VA, set by Mach-O.r before apply-relocs
	cxx-fn-map:   none				;-- macOS: bare fn name => C++ runtime dylib
	cxx-var-map:  none				;-- macOS: bare data name => C++ runtime dylib
	nlptr-sections: make block! 16	;-- [obj section ...] merged __pointers tables

	;-- libSystem DATA exports the indirect-pointer slots may name -- these
	;-- route through the emitter's own dyld-bound pointer (import-vars)
	macos-data-names: [
		"__stdoutp" "__stderrp" "__stdinp" "__stack_chk_guard"
		"_environ" "___progname" "__DefaultRuneLocale"
	]

	syslib-index: none				;-- symbol => DLL hash, PE __imp_ resolution
	imp-table:  make hash! 64		;-- __imp_<decorated> => [DLL bare-name]
	helper-libs: none				;-- registry-located static helper archives

	;-- 4-byte little-endian serializer (target endianness is set up by the
	;-- time `apply-relocs` runs, during linking).
	ptr-struct: make-struct [value [integer!]] none
	le32: func [n [integer!]][ptr-struct/value: n  form-struct ptr-struct]

	bit31: 0 - 2147483647 - 1		;-- 80000000h (the literal cannot be lexed)

	abort: func [msg [block!]][
		print rejoin ["*** Static linking error: " reform msg]
		system-dialect/compiler/quit-on-error
	]

	;-- ===== Helpers =====

	;-- Append the per-format library extension to an extension-less #import
	;-- name. With static? false (the default) the name resolves to a shared
	;-- library (.dll/.so/.dylib); with static? true (--static), to a static
	;-- archive (.lib/.a). A directory prefix (relative or absolute) is kept
	;-- intact, the extension landing on the trailing filename, so a name such
	;-- as "libs/foo" or "/opt/lib/foo" resolves to "libs/foo.lib", etc.
	;-- Called from compiler.r/process-import before the dispatch checks below.
	resolve-libname: func [name [string!] format [word!] static? [logic!]][
		rejoin [
			name
			case [
				static? [either format = 'PE [".lib"][".a"]]
				format = 'PE     [".dll"]
				format = 'Mach-o [".dylib"]
				true             [".so"]	;-- ELF / default Unix
			]
		]
	]

	;-- TRUE when an #import target names a static object or archive.
	library?: func [name [string!]][
		found? find [%.obj %.lib %.o %.a] suffix? to-file lowercase copy name
	]

	archive?: func [name [string!]][
		found? find [%.lib %.a] suffix? to-file lowercase copy name
	]

	;-- TRUE when an #import target is a macOS framework binary, referenced by
	;-- its extension-less bundle path (".../X.framework/X"). Such a path is a
	;-- complete, dynamic-only reference and must pass through verbatim: append
	;-- a library extension and the framework install name is corrupted, so
	;-- dyld aborts at load. Recognized by the ".framework/" path component.
	framework?: func [name [string!]][
		found? any [find name ".framework/"  find name ".framework\"]
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
	;-- pairs. Three on-disk dialects coexist:
	;--   GNU (.a / Linux):   long names live in a "//" table and are
	;--                       referenced as "/<offset>"; symbol index is "/".
	;--   Microsoft (.lib):   same shape as GNU; long names in "//".
	;--   BSD (.a / macOS):   long names use "#1/<len>" in the name field,
	;--                       with the actual name as the first <len> bytes of
	;--                       the file data (size includes them); symbol
	;--                       table is named "__.SYMDEF" / "__.SYMDEF SORTED".
	;-- The shared symbol-index / longname members are filtered out.
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
			;-- BSD ar leaves trailing NULs in the name field, which trim/tail
			;-- does not strip. Peel them off so short names like "miniz.o" land
			;-- cleanly and the long-name "#1/" prefix check works on the BSD path.
			while [all [(length? name) > 0  #"^@" = last name]][
				remove back tail name
			]
			size-str: to string! copy/part at bin (pos + 48) 10
			size:     to integer! trim size-str
			data:     copy/part at bin (pos + 60) size	;-- 2-byte header magic at +58
			mem-end:  pos + 60 + size
			if ((mem-end - 1) // 2) <> 0 [mem-end: mem-end + 1]	;-- 2-byte alignment
			case [
				name = "/"  []							;-- linker symbol index: skip
				name = "//" [longnames: data]			;-- longname table
				;-- BSD `ar` (macOS) long name: the first <len> bytes of the
				;-- file data are the actual name, NUL-padded; the size field
				;-- includes them. Strip them from data and re-route through
				;-- the symbol-table / regular-member checks on the real name.
				all [(length? name) > 3  "#1/" = copy/part name 3][
					off: to integer! trim copy at name 4
					real-name: to string! copy/part data off
					while [all [(length? real-name) > 0  #"^@" = last real-name]][
						remove back tail real-name
					]
					data: copy at data (off + 1)
					unless any [
						real-name = "__.SYMDEF"
						real-name = "__.SYMDEF SORTED"
					][
						append/only members reduce [real-name data]
					]
				]
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

	;-- ===== Lazy, symbol-index-driven archive access =====

	digits: charset "0123456789"

	;-- Open an archive without parsing its members. The "/" linker member
	;-- (the symbol index both GNU `ar` and Microsoft `lib` write) maps each
	;-- defined symbol to its member's offset, so a member is read and
	;-- parsed only when something actually pulls it -- the difference
	;-- between touching ~1000 members and ~30000 on a large C++ link.
	;-- Archives without the index (BSD `ar`) fall back to eager parsing of
	;-- every member, preserving the previous behavior.
	open-archive: func [
		path [file!]
		/local arc bin pos name size mem-end m obj
	][
		arc: context [
			path: none  bin: none  longnames: none
			index: none								;-- symbol name => [member-offset ...]
			flatname: none							;-- PE: bare stdcall name => [member-offset ...]
			pulled: none							;-- member offset => parsed object (cache)
			eager: none								;-- parsed members (index-less fallback)
			import-lib?: none						;-- dynamic-linking stub archive (kernel32.lib...)
		]
		arc/path: path
		arc/bin: bin: read/binary path
		if (length? bin) < 8 [abort reduce ["archive too small:" path]]
		if (copy/part bin 8) <> to binary! "!<arch>^/" [
			abort reduce ["missing !<arch> magic:" path]
		]
		arc/pulled: make hash! 64
		pos: 9
		while [all [pos < length? bin  (pos + 59) <= length? bin]][
			name: to string! copy/part at bin pos 16
			trim/tail name
			while [all [(length? name) > 0  #"^@" = last name]][
				remove back tail name
			]
			size: to integer! trim to string! copy/part at bin (pos + 48) 10
			case [
				name = "/" [
					;-- keep the first "/" member only: Microsoft archives
					;-- carry a second, differently-encoded one
					unless arc/index [parse-ar-index arc (at bin (pos + 60)) size]
				]
				name = "//" [arc/longnames: copy/part at bin (pos + 60) size]
				true [
					;-- import libraries carry short import descriptors
					;-- (sig 0/FFFF, version < 2) -- one per function; the
					;-- leading members can still be ordinary COFF objects
					;-- (the .idata directory entries), so every member is
					;-- sniffed until a stub turns up
					if all [
						arc/import-lib? <> yes
						size >= 8
						0 = coff/u16-le at bin (pos + 60) 1
						65535 = coff/u16-le at bin (pos + 60) 3
						2 > coff/u16-le at bin (pos + 60) 5
					][arc/import-lib?: yes]
				]
			]
			mem-end: pos + 60 + size
			if ((mem-end - 1) // 2) <> 0 [mem-end: mem-end + 1]
			pos: mem-end
		]
		if none? arc/import-lib? [arc/import-lib?: no]
		if arc/import-lib? = yes [return arc]		;-- caller skips these
		unless arc/index [							;-- BSD ar: no "/" symbol index
			arc/eager: make block! 32
			foreach m read-archive path [
				obj: reader/load-from-bin m/2 (rejoin [to-local-file path "(" m/1 ")"])
				unless obj [
					abort reduce [
						"unsupported archive member" m/1
						"in" to-local-file path "--" reader/reject-reason m/2
					]
				]
				append arc/eager obj
			]
			arc/bin: none							;-- fully parsed; buffer no longer needed
		]
		arc
	]

	;-- Parse the "/" linker member: a big-endian count, as many big-endian
	;-- member-header offsets, then as many NUL-terminated symbol names.
	;-- Duplicate names keep every offset, in member order, so a weak
	;-- definition pulled from one member can still be upgraded by a later
	;-- member's strong one. On PE, stdcall-shaped names (_name@N) are also
	;-- indexed under their bare name -- a user #import knows the name but
	;-- not the argument-bytes suffix.
	parse-ar-index: func [
		arc data [binary!] size [integer!]
		/local count names name entry i off p bare
	][
		count: either size < 4 [0][to integer! copy/part data 4]
		arc/index:    make hash! max 16 (2 * count)
		arc/flatname: all [obj-format = 'PE  make hash! 256]
		if zero? count [exit]
		names: parse/all (
			to string! copy/part at data (5 + (4 * count)) (size - 4 - (4 * count))
		) "^@"
		i: 0
		while [i < count][
			off:  to integer! copy/part at data (5 + (4 * i)) 4
			name: pick names (i + 1)
			if name [
				either entry: select arc/index name [
					append entry off
				][
					repend arc/index [name reduce [off]]
				]
				if all [
					arc/flatname
					#"_" = first name
					p: find/tail at name 2 #"@"
					not tail? p
					parse/all p [some digits]
				][
					bare: copy/part at name 2 ((index? p) - 3)
					either entry: select arc/flatname bare [
						append entry off
					][
						repend arc/flatname [bare reduce [off]]
					]
				]
			]
			i: i + 1
		]
	]

	;-- Decode the member whose header sits at 0-based offset `off`,
	;-- returning [name data]. The member data is copied out only now,
	;-- when the member is actually pulled into the link.
	archive-member: func [
		arc off [integer!]
		/local bin pos name size i b real
	][
		bin:  arc/bin
		pos:  off + 1
		name: to string! copy/part at bin pos 16
		trim/tail name
		size: to integer! trim to string! copy/part at bin (pos + 48) 10
		either #"/" = first name [					;-- "/<offset>" long name
			i: 1 + to integer! trim next name
			real: copy ""
			while [all [
				i <= length? arc/longnames
				(b: to integer! pick arc/longnames i) <> 0	;-- NUL terminates (MS)
				b <> 10										;-- LF terminates (GNU)
			]][
				append real to char! b
				i: i + 1
			]
			if all [not empty? real  #"/" = last real][remove back tail real]
			name: real
		][
			if all [(length? name) > 0  #"/" = last name][
				name: copy/part name ((length? name) - 1)
			]
		]
		reduce [name  copy/part at bin (pos + 60) size]
	]

	;-- TRUE when a defined symbol's name satisfies one of the user's
	;-- #import names. seed-hash carries each id verbatim plus, on PE and
	;-- Mach-O, its '_'-decorated form; a PE stdcall symbol additionally
	;-- carries a '@N' suffix, cut off before the lookup.
	seed-match?: func [name [string!] /local p][
		if empty? name [return false]
		if find seed-hash name [return true]
		either all [obj-format <> 'ELF  p: find name #"@"][
			found? find seed-hash copy/part name p
		][false]
	]

	;-- TRUE when `nm` has a non-weak entry in the merged symbol table.
	strong-defined?: func [nm [string!] /local sel][
		found? all [sel: select sym-addr nm  not sel/3]
	]

	;-- TRUE when `obj` defines `nm`, or strongly defines it while the
	;-- merged definition is still weak.
	obj-defines?: func [obj [object!] nm [string!] /local sym existing][
		foreach sym obj/symbols [
			if all [
				reader/is-defined-external? sym
				nm = reader/sym-name sym
			][
				existing: select sym-addr nm
				either existing [
					if all [existing/3  not reader/sym-weak? sym][return true]
				][return true]
			]
		]
		false
	]

	;-- Parse (once) and merge the archive member at `off`. On a revisit,
	;-- re-mark the cached object: the reference set may have grown a name
	;-- that lights up sections left dark the first time around.
	pull-member: func [job [object!] arc off [integer!] /local obj m][
		either obj: select arc/pulled off [
			mark-live-sections obj
			merge-sections job obj
			note-undefined obj
		][
			m: archive-member arc off
			obj: reader/load-from-bin m/2 (rejoin [to-local-file arc/path "(" m/1 ")"])
			unless obj [
				abort reduce [
					"unsupported archive member" m/1
					"in" to-local-file arc/path "--" reader/reject-reason m/2
				]
			]
			repend arc/pulled [off obj]
			note-merged-object obj
			mark-live-sections obj
			merge-sections job obj
			repend objects [obj/path obj]
			note-undefined obj
		]
		obj
	]

	;-- Pull members of `arc` defining `nm` until a strong definition lands;
	;-- TRUE once `nm` is strongly defined (which ends the archive search).
	;-- A weak definition keeps the scan open -- COMDAT / archive-order
	;-- semantics let a later member upgrade it.
	pull-name: func [job [object!] arc nm [string!] /local entries off obj][
		either arc/index [
			entries: select arc/index nm
			unless entries [return strong-defined? nm]
			foreach off entries [
				pull-member job arc off
				if strong-defined? nm [return true]
			]
		][
			foreach obj arc/eager [
				if obj-defines? obj nm [
					note-merged-object obj
					mark-live-sections obj
					merge-sections job obj
					unless find objects obj/path [repend objects [obj/path obj]]
					note-undefined obj
					if strong-defined? nm [return true]
				]
			]
		]
		strong-defined? nm
	]

	;-- Pull archive members defining user-imported names. An ELF name
	;-- matches verbatim; PE/Mach-O cdecl matches the '_'-decorated form
	;-- (already in seed-hash); a PE stdcall name resolves through the
	;-- archive's bare-name table, since the user cannot know the '@N'.
	pull-seeds: func [job [object!] arc /local id entries off obj sym][
		either arc/index [
			foreach id seed-hash [
				if entries: select arc/index id [
					foreach off entries [
						pull-member job arc off
						if strong-defined? id [break]
					]
				]
				if all [arc/flatname  entries: select arc/flatname id][
					foreach off entries [pull-member job arc off]
				]
			]
		][
			foreach obj arc/eager [
				foreach sym obj/symbols [
					if all [
						reader/is-defined-external? sym
						seed-match? reader/sym-name sym
					][
						note-merged-object obj
						mark-live-sections obj
						merge-sections job obj
						unless find objects obj/path [repend objects [obj/path obj]]
						note-undefined obj
						break
					]
				]
			]
		]
	]

	;-- ===== Weak-external defaults, directives, deferred .CRT layout =====

	space-chars: charset " ^-^/^M"
	non-space:   complement space-chars

	;-- Record every weak external's fallback (the COFF undefined-with-
	;-- default form: ??_E deleting destructors, oldnames aliases). The
	;-- name resolves through alias-table when no strong definition turns
	;-- up; the default itself joins the reference queue so its defining
	;-- section goes live and, when undefined everywhere, still reaches
	;-- resolve-externals. ELF/Mach-O weak symbols are definitions in their
	;-- own right -- sym-weak-default yields none there.
	register-weak-aliases: func [obj [object!] /local sym nm dn][
		foreach sym obj/symbols [
			if all [
				reader/sym-weak? sym
				dn: reader/sym-weak-default sym
			][
				nm: reader/sym-name sym
				unless alias-of nm [
					repend alias-table [copy nm copy dn]
				]
				unless find needed dn [append needed copy dn]
			]
		]
	]

	;-- Apply an object's .drectve linker directives: /INCLUDE seeds the
	;-- reference queue (how forced members arrive: locale facet ids, the
	;-- dynamic-TLS initializer), /ALTERNATENAME feeds the alias table,
	;-- /DEFAULTLIB accumulates for the system-archive search (consumed
	;-- once lookup paths land). Everything else is ignored.
	parse-directives: func [obj [object!] /local text tok low val p][
		unless all [in obj 'directives  text: obj/directives][exit]
		parse/all text [
			any [
				some space-chars
				| copy tok [some [{"} thru {"} | non-space]] (
					replace/all tok {"} ""
					low: lowercase copy/part tok 17
					case [
						parse/all low ["/include:" to end][
							val: copy skip tok 9
							unless any [empty? val  find needed val][
								append needed val
							]
						]
						parse/all low ["/alternatename:" to end][
							val: copy skip tok 15
							if p: find val #"=" [
								unless alias-of copy/part val p [
									repend alias-table [
										copy/part val p  copy next p
									]
								]
							]
						]
						parse/all low ["/defaultlib:" to end][
							val: lowercase copy skip tok 12
							unless any [empty? val  find default-libs val][
								append default-libs val
							]
						]
						true []
					]
				)
			]
		]
	]

	;-- One-time metadata absorption per merged object.
	note-merged-object: func [obj [object!]][
		if find absorbed obj/path [exit]
		append absorbed obj/path
		register-weak-aliases obj
		parse-directives obj
	]

	;-- Merged address of `name`, following alias-table links (weak-external
	;-- defaults, /alternatename) when the name itself has no definition.
	;-- Look up an /alternatename (or weak-default) target by KEY only.
	;-- alias-table is [key value ...]; a plain `select` on it (hash!) would
	;-- also match a search string appearing as a VALUE and return the next
	;-- entry's key -- so chain-following (final-alias) must match keys at
	;-- record boundaries. select/skip 2 does that; `first` unwraps the value.
	alias-of: func [name [string!] /local pos][
		all [pos: select/skip alias-table name 2  first pos]
	]

	resolve-sym-addr: func [name [string!] /local info n guard][
		if info: select sym-addr name [return info]
		n: name
		guard: 0
		while [all [guard < 8  n: alias-of n]][
			if info: select sym-addr n [return info]
			guard: guard + 1
		]
		none
	]

	;-- Follow the /alternatename chain to its last hop (or `name` itself).
	;-- An MSVC alternatename can retarget one __imp_ onto another (e.g.
	;-- __imp____std_init_once_begin_initialize@16 -> __imp__InitOnceBeginInitialize@16),
	;-- so a reference must resolve as its final alias does.
	final-alias: func [name [string!] /local n next guard][
		n: name
		guard: 0
		while [all [guard < 8  next: alias-of n]][
			n: next  guard: guard + 1
		]
		n
	]

	;-- Lay out the collected .CRT$X?? contributions sorted by full section
	;-- name: MSVC's grouped-section rule builds the C/C++ initializer and
	;-- terminator tables positionally, between the CRT's ...$XxA / ...$XxZ
	;-- bound sections. A second merge-sections pass then registers their
	;-- symbols, the base addresses now being known. Alignment padding
	;-- between contributions is benign -- the CRT's table walkers skip
	;-- null entries.
	finalize-crt-sections: func [
		job [object!]
		/local data name section obj a base objs
	][
		if empty? crt-sections [exit]
		sort/skip crt-sections 3
		;-- the .CRT/.rtc initializer tables stay in the writable .data
		;-- section: they are walked (read) at startup and never written, but
		;-- keeping them writable is harmless and the CRT does not re-protect
		;-- them (only .fptable is hardened), so they need no page isolation
		data: job/sections/data/2
		objs: make block! 8
		foreach [name section obj] crt-sections [
			a: reader/sec-align section
			if a > max-align [max-align: a]
			pad-to data a
			base: length? data
			append data reader/sec-data section
			reader/set-sec-base section 'data base
			unless find objs obj [append objs obj]
		]
		foreach obj objs [merge-sections job obj]
	]

	;-- MSVC's grouped-section rule again, for the PE TLS template: tlssup.obj
	;-- brackets user .tls$ data between its bare .tls (__tls_start) and
	;-- .tls$ZZZ (__tls_end) marker sections, so contributions must be laid
	;-- out sorted by full section name for the CRT TLS directory's raw-data
	;-- bounds to enclose the template.
	finalize-pe-tls-sections: func [
		job [object!]
		/local data name section obj a base objs ckey entry
	][
		if empty? tls-pe-sections [exit]
		sort/skip tls-pe-sections 3
		data: job/sections/data/2
		objs: make block! 8
		foreach [name section obj] tls-pe-sections [
			a: reader/sec-align section
			if a > max-align [max-align: a]
			pad-to data a
			base: length? data
			unless tls-start [tls-start: base]
			append data reader/sec-data section
			tls-end: length? data
			reader/set-sec-base section 'data base
			;-- a COMDAT .tls$ contribution was recorded as its group's
			;-- anchor BEFORE layout (duplicate folding needs the key
			;-- registered at merge time): patch the anchor now that the
			;-- base is known -- 'tls matches register-symbol's mapping,
			;-- so redirected relocations get the SECREL treatment
			if all [
				ckey: reader/sec-comdat-key section
				entry: select comdat-keys ckey
				same? obj entry/4
				entry/1 = 'none
			][
				entry/1: 'tls
				entry/2: base
			]
			unless find objs obj [append objs obj]
		]
		foreach obj objs [merge-sections job obj]
	]

	;-- Ordering key for the deferred ELF C++ lists: crtbegin*'s contribution
	;-- opens the run, crtend's closes it, prioritized .init_array.NNNNN
	;-- entries come before plain ones (ld's SORT_BY_INIT_PRIORITY rule),
	;-- everything else keeps arrival order.
	cpp-arrival: func [obj [object!] name [string!] /local p][
		case [
			find obj/path "crtbegin"	[-2000000000]
			find obj/path "crtend"		[ 2000000000]
			all [
				p: find/last name #"."
				p: attempt [to integer! next p]
			][p - 1000000000]
			true [cpp-seq: cpp-seq + 1  cpp-seq]
		]
	]

	;-- Lay out the deferred .eh_frame run, the .init_array function-pointer
	;-- table and the TLS template (all into .data -- ELF output has no
	;-- page-protection concerns), publish the ctor-table bounds for the
	;-- entry stub, then re-merge the touched objects so their symbols are
	;-- recorded against the just-assigned section bases.
	finalize-elf-cpp: func [
		job [object!]
		/local data seq obj section base start objs sorted txt link
	][
		if all [
			empty? init-arrays  empty? eh-frames
			empty? tls-sections  empty? exidx-sections
		][exit]
		data: job/sections/data/2
		objs: make block! 16
		sort/skip eh-frames 3
		foreach [seq obj section] eh-frames [
			either obj-format = 'Mach-o [
				;-- own __TEXT,__eh_frame section (located by name at runtime)
				pad-to ehframe-buf 4
				base: length? ehframe-buf
				append ehframe-buf reader/sec-data section
				reader/set-sec-base section 'eh-frame base
			][
				;-- ELF: contiguous run inside .data, crtbegin registry route
				pad-to data 4
				base: length? data
				append data reader/sec-data section
				reader/set-sec-base section 'data base
			]
			unless find objs obj [append objs obj]
		]
		sort/skip init-arrays 3
		pad-to data 4
		start: length? data
		foreach [seq obj section] init-arrays [
			base: length? data
			append data reader/sec-data section
			reader/set-sec-base section 'data base
			unless find objs obj [append objs obj]
		]
		repend sym-addr ["__red_ctors_start" reduce ['data start false]]
		repend sym-addr ["__red_ctors_end"   reduce ['data length? data false]]
		print [
			"...C++ initializers :" ((length? init-arrays) / 3)
			"entries," ((length? data) - start) "bytes"
		]
		;-- ARM EHABI: one contiguous unwind-index table, entries ordered by
		;-- the covered text section's merged address (binary-search contract)
		unless empty? exidx-sections [
			sorted: make block! (length? exidx-sections) / 2
			foreach [obj section] exidx-sections [
				link: reader/sec-link section
				txt: pick obj/sections (link + 1)
				;-- an index section whose text was dropped never went live;
				;-- guard anyway: unbased text sorts last and is skipped
				either all [txt  'code = reader/sec-base-kind txt][
					repend/only sorted [reader/sec-base-offset txt  obj section]
				][
					poke section 7 'none
				]
			]
			sort sorted
			pad-to data 4
			start: length? data
			repend sym-addr ["__exidx_start" reduce ['data start false]]
			foreach entry sorted [
				section: entry/3
				base: length? data
				append data reader/sec-data section
				reader/set-sec-base section 'data base
				unless find objs entry/2 [append objs entry/2]
			]
			repend sym-addr ["__exidx_end" reduce ['data length? data false]]
			exidx-range: reduce [start  (length? data) - start]
		]
		;-- TLS template: .tdata bytes then .tbss space; section bases are
		;-- TEMPLATE-relative (kind 'tls), turned into GOT-pair constants and
		;-- tpoff immediates by the TLS relocation cases.
		unless empty? tls-sections [
			sort/skip tls-sections 3
			pad-to data etls-align
			etls-off: length? data
			foreach [seq obj section] tls-sections [
				if seq = 0 [
					pad-to data reader/sec-align section
					append data reader/sec-data section
					reader/set-sec-base section 'tls ((length? data) - etls-off - reader/sec-size section)
					unless find objs obj [append objs obj]
				]
			]
			etls-filesz: (length? data) - etls-off
			etls-memsz: etls-filesz
			foreach [seq obj section] tls-sections [
				if seq = 1 [
					base: etls-memsz
					base: base + ((reader/sec-align section) - 1)
					base: base - (base // reader/sec-align section)
					reader/set-sec-base section 'tls base
					etls-memsz: base + reader/sec-size section
					unless find objs obj [append objs obj]
				]
			]
		]
		foreach obj objs [merge-sections job obj]
	]

	;-- Synthesize the C++ entry stub: walk [__red_ctors_start,__red_ctors_end)
	;-- calling each initializer, then fall into Red's own entry (offset 0 of
	;-- the merged code section). ELF.r points e_entry here when cpp-entry is
	;-- set -- the ELF analog of the PE CRT-owned-entry handover.
	build-cpp-entry-stub: func [job [object!] /local code off stub obj relocs rt][
		;-- any merged .init_array needs the walk -- a C++ object can carry
		;-- constructors without ever touching EH/new (no cpp-markers hit)
		unless all [
			not empty? init-arrays
			select sym-addr "__red_ctors_start"
		][exit]
		;-- abs32 in the reader's own encoding: raw ELF type vs Mach-O's
		;-- packed (VANILLA<<4 | len 2<<2 | pcrel 0) form
		rt: either obj-format = 'Mach-o [8][either obj-arch = 'ARM [2][1]]
		code: job/sections/code/2
		pad-to code 16
		off: length? code
		stub: copy #{}
		either obj-arch = 'ARM [
			;-- cursor r4 and end r5 are CALLEE-SAVED -- a constructor may
			;-- freely trash r0-r3/ip (AAPCS), so the loop bounds must not
			;-- live there (the first frame_dummy return proved it).
			;-- r3 rides along as padding: AAPCS demands an 8-byte-aligned SP
			;-- at every call boundary, so the push count must stay EVEN or
			;-- every constructor runs on a misaligned stack (varargs doubles
			;-- and NEON stack spills fault on it).
			append stub #{38402DE9}				;-- push {r3, r4, r5, lr}
			append stub #{20409FE5}				;-- ldr r4, [pc, #32]	-> ctors_start (lit @44)
			append stub #{20509FE5}				;-- ldr r5, [pc, #32]	-> ctors_end   (lit @48)
			append stub #{050054E1}				;-- loop: cmp r4, r5
			append stub #{0300002A}				;-- bcs done
			append stub #{00C094E5}				;-- ldr ip, [r4]
			append stub #{3CFF2FE1}				;-- blx ip (interworking-safe)
			append stub #{044084E2}				;-- add r4, r4, #4
			append stub #{F9FFFFEA}				;-- b loop
			append stub #{3840BDE8}				;-- done: pop {r3, r4, r5, lr}
			;-- b Red entry (code offset 0): imm24 = (0 - (pc = off+48)) / 4
			append stub le32 (
				((0 - (off + 48)) / 4 and 16777215) or -369098752	;-- EAh cond+op
			)
			append stub #{00000000}				;-- lit: __red_ctors_start (abs32 @44)
			append stub #{00000000}				;-- lit: __red_ctors_end   (abs32 @48)
			relocs: reduce [
				reduce [44 0 rt]				;-- [r-va r-sym abs32]
				reduce [48 1 rt]
			]
		][
			;-- ebx (cursor) and esi (saved SP) are CALLEE-SAVED. The SysV
			;-- i386 psABI (GCC >= 4.5) and Darwin both demand a 16-byte-
			;-- aligned SP at every call site -- constructors spilling SSE
			;-- registers to aligned stack slots fault without the AND. The
			;-- process-entry SP is restored before falling into Red's own
			;-- entry, which parses argc/argv straight off it.
			append stub #{53}					;-- push ebx
			append stub #{56}					;-- push esi
			append stub #{89E6}					;-- mov esi, esp
			append stub #{83E4F0}				;-- and esp, -16
			append stub #{BB00000000}			;-- mov ebx, __red_ctors_start	(abs32 @8)
			append stub #{81FB00000000}			;-- cmp ebx, __red_ctors_end	(abs32 @14)
			append stub #{7307}					;-- jae done
			append stub #{FF13}					;-- call [ebx]
			append stub #{83C304}				;-- add ebx, 4
			append stub #{EBF1}					;-- jmp -> cmp
			append stub #{89F4}					;-- done: mov esp, esi
			append stub #{5E}					;-- pop esi
			append stub #{5B}					;-- pop ebx
			append stub #{E9}					;-- jmp rel32 -> Red entry (code offset 0)
			append stub le32 (0 - (off + 36))
			relocs: reduce [
				reduce [8 0 rt]					;-- [r-va r-sym abs32]
				reduce [14 1 rt]
			]
		]
		append code stub
		obj: make object! compose/deep/only [
			path: %red-cpp-ctors
			sections: (reduce [reduce [
				".red.cppinit" 'code 16 stub length? stub
				relocs
				'code off none true true 0
			]])
			symbols: (reduce [
				reduce ["__red_ctors_start" 0 1 16 0]	;-- GLOBAL, SHN_UNDEF (5th = Mach-O n_desc)
				reduce ["__red_ctors_end"   0 1 16 0]
			])
		]
		repend objects [obj/path obj]
		cpp-entry: off
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
		/local static-libs lib list info t0 t entry
	][
		clear objects
		clear needed
		clear seed-hash
		clear comdat-keys
		clear alias-table
		clear default-libs
		clear crt-sections
		clear tls-pe-sections
		clear absorbed
		crt-mode?: none
		crt-entry: none
		clear opened-libs
		msvc-dirs: none
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
		tls-dir-kind: 'data
		crodata-buf: make binary! 4096
		crodata-base: none
		cafter-buf: make binary! 256
		cafter-base: none
		clear cafter-fills
		clear eh-frames
		clear init-arrays
		cpp-mode?: none
		cpp-entry: none
		cpp-seq: 0
		clear weak-undefs
		clear strong-undefs
		clear tls-sections
		etls-off: none
		etls-filesz: 0
		etls-memsz: 0
		etls-align: 4
		clear exidx-sections
		exidx-range: none
		ehframe-buf: make binary! 4096
		ehframe-base: none
		clear nlptr-sections

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
				macOS   [mac-libsystem/functions]		;-- real libSystem export set
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
		;-- macOS C++ runtime binds dynamically (no static libc++ exists);
		;-- functions only for now -- iostream OBJECT imports (cout & co)
		;-- would need indirect-symbol emission (documented gap)
		either job/OS = 'macOS [
			cxx-fn-map:  make hash! mac-cxx-exports/functions
			;-- dylib DATA the __pointers slots may name: libSystem globals
			;-- (each => libSystem.B.dylib) plus libc++/libc++abi data
			cxx-var-map: make hash! collect [
				foreach n mac-libsystem/variables [keep n  keep "/usr/lib/libSystem.B.dylib"]
				foreach [n lib] mac-cxx-exports/variables [keep n  keep lib]
			]
		][
			cxx-fn-map: none
			cxx-var-map: none
		]
		job/static-data: make block! 8				;-- [name data-offset size ...]
		reader: case [
			obj-format = 'PE     [coff]
			obj-format = 'ELF    [elf-obj]
			obj-format = 'Mach-o [macho-obj]
			true [abort reduce ["static linking unsupported for format:" obj-format]]
		]

		;-- Pull static [lib list] pairs out of the dynamic import table.
		static-libs: extract-static-imports job

		print "Static linking..."
		foreach [lib list] static-libs [
			print ["...linking          :" lib]
		]
		t0: now/time/precise

		;-- Pass 1: merge directly-named objects, then pull archive members
		;-- on demand to satisfy referenced symbols.
		merge-objects job static-libs
		;-- Pass 1a: lay out the deferred .CRT$X?? initializer tables.
		finalize-crt-sections job
		;-- Pass 1a2: lay out the deferred PE .tls$ template, name-sorted.
		finalize-pe-tls-sections job
		;-- Pass 1b: lay out the deferred ELF .eh_frame run + .init_array table.
		finalize-elf-cpp job
		job/static-align: max-align					;-- ELF.r aligns .data to this

		;-- Pass 1b2: allocate Mach-O common (tentative) definitions before
		;-- resolution treats them as undefined imports.
		merge-commons job

		;-- Pass 1c: rewire Mach-O dylib-data pointer slots onto the emitter's
		;-- dyld-bound imports before name resolution chases them.
		wire-nlptr-relocs job

		;-- Pass 2: satisfy undefined externals (libc trampolines, stubs).
		resolve-externals job
		;-- Pass 2+: C++ entry stub -- walks the ctor table, then Red's entry.
		build-cpp-entry-stub job
		;-- Pass 2a: allocate synthetic ELF i386 GOT slots before final layout.
		allocate-got-slots job
		;-- Pass 2b: route PE __imp_* import-thunk references to dynamic imports.
		wire-imp-relocs job
		;-- Pass 3: wire each user-imported function to a call slot.
		foreach [lib list] static-libs [
			info: select job/static-objs lowercase copy lib
			wire-imports job lib list info/2
		]

		;-- CRT-owned entry point: PE.r moves AddressOfEntryPoint here.
		if crt-mode? [
			entry: select sym-addr "_mainCRTStartup"
			unless all [entry  entry/1 = 'code][
				abort ["MSVC CRT startup (mainCRTStartup) not found in libcmt.lib"]
			]
			crt-entry: entry/2
		]

		;-- Register the read-only external-data section (PE) so the emitter
		;-- lays it out -- on its own pages, right after .data. Added only
		;-- when there is read-only external data, so pure-C links whose
		;-- external data is all writable stay byte-for-byte unchanged.
		if all [obj-format = 'PE  not empty? crodata-buf][
			insert skip (find job/sections 'data) 2 compose/deep/only [
				crodata [- (crodata-buf)]
			]
		]
		;-- read-only-after-init pointers on their own page(s)
		if all [obj-format = 'PE  not empty? cafter-buf][
			insert skip (find job/sections 'data) 2 compose/deep/only [
				cafter [- (cafter-buf)]
			]
		]
		;-- merged C++ unwind tables: own __TEXT,__eh_frame section (Mach-O).
		;-- NOTE: Darwin 10.9 libunwind needs __unwind_info (compact) for the
		;-- main image's frames -- __eh_frame alone is not consulted, so
		;-- THROWING code needs -fno-exceptions or a future compact-unwind
		;-- generator. Non-throwing C++ (the ImGui demo) links + runs fine.
		if all [obj-format = 'Mach-o  not empty? ehframe-buf][
			repend job/sections ['ehframe reduce ['- ehframe-buf]]
		]

		t: now/time/precise - t0
		print ["...static-link time :" round (t/second * 1000) + (t/minute * 60000) "ms"]
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
	;-- members on demand: a member is linked in only when it defines a
	;-- symbol that something already merged -- or a user #import -- refers
	;-- to. Pulling is driven by the archives' symbol indexes through the
	;-- `needed` reference queue; each pulled member can append fresh
	;-- references, extending the queue until it drains.
	merge-objects: func [
		job [object!] static-libs [block!]
		/local lib list info id reloc obj archives arc hl queue-pos nm sel directs dn progress?
	][
		archives: make block! 8
		directs:  make block! 8

		;-- user-imported names seed section liveness and archive pulling;
		;-- their decorated forms also join the reference queue, so an
		;-- imported name can resolve through an /alternatename alias
		foreach [lib list] static-libs [
			foreach [id reloc] list [
				unless find seed-hash id [
					append seed-hash id
					either obj-format = 'ELF [
						unless find needed id [append needed copy id]
					][
						append seed-hash nm: join "_" id
						unless find needed nm [append needed nm]
					]
				]
			]
		]

		;-- merge each directly-named object; open archives without parsing
		foreach [lib list] static-libs [
			info: select job/static-objs lowercase copy lib
			unless info [abort reduce ["unregistered static import:" lib]]
			either archive? lib [
				arc: open-archive info/1
				if arc/import-lib? = yes [
					abort reduce [
						lib "is an import library (dynamic-linking stubs);"
						"import the DLL directly or provide the static archive"
					]
				]
				append/only archives arc
			][
				obj: reader/load info/1
				note-merged-object obj
				mark-live-sections obj
				merge-sections job obj
				repend objects [obj/path obj]
				note-undefined obj
				append directs obj
			]
		]

		;-- helper archives: selective loading pulls only the compiler / CRT
		;-- objects actually used
		if all [helper-libs  not empty? helper-libs][
			foreach hl helper-libs [
				append/only archives open-archive hl
			]
		]

		;-- pull members defining user-imported names, then drain the
		;-- reference queue -- a name defined only weakly keeps its archive
		;-- search open so a later strong definition can upgrade it. A name
		;-- that stays undefined but carries an alias (/alternatename, weak
		;-- default) makes its target needed in its place. Directly-named
		;-- objects are then revisited: fresh names can light up COMDAT
		;-- sections they held dark, until a full round settles.
		foreach arc archives [pull-seeds job arc]
		queue-pos: 1
		until [
			while [queue-pos <= length? needed][
				nm: pick needed queue-pos
				unless all [sel: select sym-addr nm  not sel/3][
					foreach arc archives [
						if pull-name job arc nm [break]
					]
					unless select sym-addr nm [
						if all [
							dn: alias-of nm
							not find needed dn
						][append needed copy dn]
					]
				]
				queue-pos: queue-pos + 1
			]
			progress?: false
			foreach obj directs [
				mark-live-sections obj
				if merge-sections job obj [progress?: true]
				note-undefined obj
			]
			;-- /defaultlib archives (the MSVC CRT chain) arrive mid-link:
			;-- re-scan the whole queue against the enlarged archive set
			if open-default-libs job archives [
				queue-pos: 1
				progress?: true
			]
			;-- GNU C++ runtime (ELF) arrives the same way on the first
			;-- Itanium-ABI marker among the undefined externals
			if open-cpp-libs job archives directs [
				queue-pos: 1
				progress?: true
			]
			all [not progress?  queue-pos > length? needed]
		]

		;-- every pulled object is merged; release the raw archive buffers
		;-- and indexes before the relocation passes peak
		foreach arc archives [
			arc/bin: none
			arc/longnames: none
			arc/index: none
			arc/flatname: none
			arc/eager: none
		]
	]

	;-- Bare C name used to match a symbol against the embedded system
	;-- export sets (libc, Win32 DLLs): a PE/Mach-O leading '_' and any
	;-- stdcall '@N' suffix are dropped (ELF symbols pass through). Symbol
	;-- resolution across objects and archives compares full names.
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

	;-- Compute the per-object live-section closure. Non-COMDAT keepable
	;-- sections of a merged object are unconditionally live -- that is
	;-- link.exe's rule (reference-driven GC applies to COMDATs only), and
	;-- it is load-bearing: nothing references a .CRT$XCU initializer
	;-- table, yet it must link. COMDAT sections go live when a needed or
	;-- user-imported symbol is defined in them, when a live section's
	;-- relocation reaches them, or -- for ASSOCIATIVE sections -- when
	;-- their parent is live.
	mark-live-sections: func [
		obj [object!]
		/local section sym sect changed? r target target2 idx
	][
		foreach section obj/sections [
			ensure-live-slot section
		]
		idx: 0
		foreach section obj/sections [
			idx: idx + 1
			if all [
				reader/sec-kind section
				any [
					not reader/sec-comdat? section
					;-- Mach-O reports EVERY section comdat (symbol-level weak
					;-- coalescing), which would leave these unreferenced-but-
					;-- keepable kinds dark. They are never weak duplicates, so
					;-- keep them unconditionally (relocs then reach the LSDA /
					;-- static-init code they point at).
					find [init-array eh-frame arm-exidx crt tls-data tls-bss] reader/sec-kind section
				]
			][
				mark-section-live? obj idx
			]
		]
		foreach sym obj/symbols [
			if all [
				reader/is-defined-external? sym
				any [
					find needed reader/sym-name sym
					seed-match? reader/sym-name sym
				]
			][
				mark-section-live? obj reader/sym-sect sym
			]
		]
		until [
			changed?: false
			idx: 0
			foreach section obj/sections [
				idx: idx + 1
				if all [
					not section-live? section
					sect: reader/sec-assoc section
					sect > 0
					sect <= length? obj/sections
					section-live? pick obj/sections sect
				][
					if mark-section-live? obj idx [changed?: true]
				]
			]
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
						;-- Mach-O SECTDIFF carries the subtrahend's synth-sym
						;-- index in r/4 -- keep that section alive too.
						if all [
							(length? r) >= 4
							'sectdiff = reader/reloc-kind r/3
						][
							target2: pick obj/symbols (r/4 + 1)
							if target2 [
								sect: reader/sym-sect target2
								if sect > 0 [
									if mark-section-live? obj sect [changed?: true]
								]
							]
						]
					]
				]
			]
			not changed?
		]
	]

	;-- Add an object's undefined externals to the `needed` reference set.
	;-- Deferred .CRT$X?? sections count too: they are laid out only after
	;-- the pull phase, but the initializer functions their entries point
	;-- at must be pulled DURING it.
	note-undefined: func [obj [object!] /local section sym nm sec-kind][
		foreach section obj/sections [
			sec-kind: reader/sec-base-kind section
			if all [
				sec-kind = 'none
				'crt = reader/sec-kind section
				section-merged? section
			][
				sec-kind: 'crt
			]
			unless sec-kind = 'none [
				foreach r reader/sec-relocs section [
					sym: pick obj/symbols (r/2 + 1)
					if all [sym  reader/is-undefined-external? sym][
						nm: reader/sym-name sym
						unless find needed nm [append needed copy nm]
					]
				]
			]
		]
		;-- Every undefined external in the symbol table is a reference the
		;-- linker must satisfy -- not only those a relocation points at.
		;-- MSVC's force-link anchors work exactly this way: an object lists
		;-- an undefined symbol with no relocation (e.g.
		;-- ___std_init_once_link_alternate_names_and_abort@0) purely to pull
		;-- the member that defines it, whose .drectve then supplies the
		;-- /alternatename mappings the real references need.
		;-- ELF weak-undefined references (STB_WEAK + SHN_UNDEF) resolve to
		;-- address 0 when nothing defines them (crtbegin's _ITM_* TM hooks,
		;-- __gmon_start__ & co) -- track them so only weak-ONLY names get 0.
		foreach sym obj/symbols [
			if all [sym  reader/is-undefined-external? sym][
				nm: reader/sym-name sym
				unless find needed nm [append needed copy nm]
				if obj-format = 'ELF [
					either reader/sym-weak? sym [
						unless find weak-undefs nm [append weak-undefs copy nm]
					][
						unless find strong-undefs nm [append strong-undefs copy nm]
					]
				]
			]
		]
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
		/local code data section kind a base sym sect ckey entry merged? idx common-live? r sec-kind pkey
	][
		code: job/sections/code/2
		data: job/sections/data/2
		merged?: false
		foreach section obj/sections [
			kind: reader/sec-kind section
			;-- ELF: .eh_frame is read-only data with an ORDERING contract
			;-- (crtbeginT's registry header first, crtend's terminator last,
			;-- one contiguous run) -- deferred, not merged in arrival order.
			if all [
				obj-format = 'ELF
				kind = 'rdata
				".eh_frame" = reader/sec-name section
			][
				kind: 'eh-frame
			]
			unless section-live? section [kind: none]
			if section-merged? section [kind: none]
			ckey: none
			;-- An ASSOCIATIVE COMDAT's key is cleared by the reader: it
			;-- follows its PARENT's fate instead of folding by its own key.
			;-- When the parent's key is held by ANOTHER object, that parent
			;-- copy gets folded away -- its children must go with it, or
			;-- every duplicate's .CRT$XCU entry re-runs the initializer and
			;-- .xdata of discarded code leaks into the image.
			if all [
				kind
				sect: reader/sec-assoc section
				sect > 0
				sect <= length? obj/sections
				pkey: reader/sec-comdat-key pick obj/sections sect
				entry: select comdat-keys pkey
				not same? obj entry/4
			][
				kind: none
			]
			if kind [
				;; COMDAT / SHT_GROUP: drop a section whose key was already
				;; pulled FROM ANOTHER OBJECT, leaving base-kind='none --
				;; relocations into the dropped twin get redirected to the
				;; kept copy through comdat-keys (identical content is the
				;; COMDAT contract). An ELF group can span several sections
				;; that go live in DIFFERENT passes: siblings of the object
				;; that owns the kept group are group MEMBERS, not duplicates.
				either all [
					ckey: reader/sec-comdat-key section
					entry: select comdat-keys ckey
					not same? obj entry/4
				][
					;; SELECT_LARGEST asks for the biggest copy; first-wins
					;; is measurably equivalent on real archives (vtables of
					;; uniform size) -- warn loudly on the theoretical case.
					if all [
						6 = reader/sec-selection section
						(reader/sec-size section) > entry/3
					][
						print [
							"*** Warning: (largest) COMDAT" ckey "keeps its first,"
							"smaller copy:" entry/3 "vs" reader/sec-size section "bytes"
						]
					]
					kind: none
					ckey: none
				][
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
				kind = 'data [
					pad-to data a
					base: length? data
					append data reader/sec-data section
					reader/set-sec-base section 'data base
					poke section 11 true
					merged?: true
				]
				kind = 'rdata [
					;-- read-only external data goes to the page-isolated
					;-- crodata section on PE, keeping it off the writable
					;-- .data pages the CRT re-protects; other formats fold
					;-- it into .data as before
					either obj-format = 'PE [
						pad-to crodata-buf a
						base: length? crodata-buf
						append crodata-buf reader/sec-data section
						reader/set-sec-base section 'crodata base
					][
						pad-to data a
						base: length? data
						append data reader/sec-data section
						reader/set-sec-base section 'data base
					]
					poke section 11 true
					merged?: true
				]
				kind = 'cafter [
					;-- read-only-after-init writable data (the winapi-thunk
					;-- function_pointers table): the CRT flips it writable to
					;-- cache resolved APIs, then VirtualProtects it read-only
					;-- again -- page-granular, so it must sit on its own pages
					;-- away from ordinary writable globals (else their page is
					;-- caught). Folded into .data on non-PE (no such hardening).
					either obj-format = 'PE [
						pad-to cafter-buf a
						base: length? cafter-buf
						append cafter-buf reader/sec-data section
						reader/set-sec-base section 'cafter base
					][
						pad-to data a
						base: length? data
						append data reader/sec-data section
						reader/set-sec-base section 'data base
					]
					poke section 11 true
					merged?: true
				]
				kind = 'tls [
					;-- deferred: PE .tls$ contributions are laid out sorted
					;-- by full section name, so that tlssup.obj's bare .tls /
					;-- .tls$ZZZ markers bracket the user template (see
					;-- finalize-pe-tls-sections)
					repend tls-pe-sections [copy reader/sec-name section  section  obj]
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
				kind = 'crt [
					;-- deferred: .CRT$X?? contributions are laid out sorted
					;-- by full section name once every member is in (see
					;-- finalize-crt-sections), building the initializer
					;-- tables between their ...$XxA / ...$XxZ bounds
					repend crt-sections [copy reader/sec-name section  section  obj]
					poke section 11 true
					merged?: true
				]
				kind = 'init-array [
					;-- deferred: laid out as one fn-ptr table (see
					;-- finalize-elf-cpp) between __red_ctors_start/_end
					repend init-arrays [
						cpp-arrival obj reader/sec-name section  obj  section
					]
					poke section 11 true
					merged?: true
				]
				kind = 'eh-frame [
					;-- deferred: contiguous .eh_frame run (see finalize-elf-cpp)
					repend eh-frames [
						cpp-arrival obj reader/sec-name section  obj  section
					]
					poke section 11 true
					merged?: true
				]
				any [kind = 'tls-data  kind = 'tls-bss][
					;-- deferred: the TLS template is laid out whole (tdata
					;-- first, tbss beyond the initialized bytes) once every
					;-- member is in (see finalize-elf-cpp)
					repend tls-sections [
						either kind = 'tls-data [0][1]  obj  section
					]
					a: reader/sec-align section
					if a > etls-align [etls-align: a]
					poke section 11 true
					merged?: true
				]
				kind = 'arm-exidx [
					;-- deferred: sorted EHABI table (see finalize-elf-cpp)
					repend exidx-sections [obj section]
					poke section 11 true
					merged?: true
				]
				kind = 'nl-pointers [
					;-- Mach-O indirect-symbol slots: plain writable data --
					;-- internal targets fill through the reader's synthetic
					;-- abs32s; dylib-data slots are rewired to the emitter's
					;-- own dyld-bound pointers (see wire-nlptr-relocs)
					pad-to data a
					base: length? data
					append data reader/sec-data section
					reader/set-sec-base section 'data base
					poke section 11 true
					merged?: true
					repend nlptr-sections [obj section]
				]
			]
			;; record where the kept COMDAT copy landed, for duplicate folding
			;; (first member section only -- it anchors reloc redirection; the
			;; owner object marks the whole group instance as the kept one)
			if all [
				kind
				not find [crt init-array eh-frame tls-data tls-bss arm-exidx] kind
				ckey
				not select comdat-keys ckey
			][
				repend comdat-keys [
					copy ckey
					reduce [
						reader/sec-base-kind section
						reader/sec-base-offset section
						reader/sec-size section
						obj
						copy reader/sec-name section
					]
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
							find needed reader/sym-name sym
							seed-match? reader/sym-name sym
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
		if 'none = reader/sec-base-kind section [exit]	;-- dropped section, or deferred and not yet laid out
		kind: either (reader/sec-kind section) = 'tls ['tls][reader/sec-base-kind section]
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
		/local path obj section sym name bare code data tramp-off disp-ref sz data-off imp res stub pending sec-kind dn fa
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
						;-- a referenced weak external's fallback must
						;-- resolve too; when it is defined nowhere, it goes
						;-- through this same pipeline (libc trampolines...)
						;-- as a synthetic undefined external
						if all [
							sym
							reader/sym-weak? sym
							dn: reader/sym-weak-default sym
							not select sym-addr dn
						][
							append/only pending reduce [dn 0 0 2 none]
						]
					]
				]
			]
			foreach sym pending [
					name: reader/sym-name sym
					unless any [
						select sym-addr name
						;-- an alternatename that lands on an already-defined
						;-- symbol resolves at reloc time through resolve-sym-addr;
						;-- one that lands on an __imp_/system name still needs the
						;-- resolution cases below (handled via final-alias)
						all [dn: alias-of name  select sym-addr dn]
						find undef-done name
					][
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
							any [
								name = "__ImageBase"
								name = "___ImageBase"		;-- x86-decorated form
							][
								repend sym-addr [name reduce ['image-base 0 false]]
							]
							;-- CRT-owned startup: mainCRTStartup initializes
							;-- the CRT and calls main -- which is Red's
							;-- start, sitting at the beginning of CODE.
							all [crt-mode?  name = "_main"][
								repend sym-addr [name reduce ['code 0 false]]
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
								unless any [tls-start  not empty? tls-pe-sections][
									abort reduce ["TLS runtime symbol without .tls section:" name "(in" path ")"]
								]
							]
							;-- __except_list: the SEH registration-record chain
							;-- lives at the head of the TIB (fs:[0]); the linker
							;-- defines this symbol as the absolute offset 0, which
							;-- setjmp/longjmp and the SEH prologue read as
							;-- `fs:[__except_list]`.
							any [
								name = "__except_list"
								name = "___except_list"
							][
								repend sym-addr [name reduce ['absolute 0 false]]
							]
							all [
								obj-arch = 'ARM
								name = "__aeabi_read_tp"
							][
								;-- read the user-mode thread pointer (TPIDRURO):
								;-- an 8-byte helper beats a dynamic import the
								;-- loader may not expose
								code: job/sections/code/2
								pad-to code 4
								tramp-off: length? code
								append code #{700F1DEE}		;-- mrc p15, 0, r0, c13, c0, 3
								append code #{1EFF2FE1}		;-- bx lr
								repend sym-addr [name reduce ['code tramp-off false]]
							]
							all [
								obj-format = 'Mach-o
								name = "___dso_handle"
							][
								;-- per-image token for __cxa_atexit grouping:
								;-- any unique address serves an executable
								repend sym-addr [name reduce ['data 0 false]]
							]
							all [
								obj-arch = 'ARM
								find [
									"__register_frame_info"
									"__deregister_frame_info"
								] name
							][
								;-- ARM EHABI has no DWARF frame registry: ARM
								;-- glibc does not export these (the x86-derived
								;-- libc set does) -- crtbegin's references are
								;-- weak and null-checked, so bind them to 0
								repend sym-addr [name reduce ['absolute 0 false]]
							]
							;-- Control-Flow-Guard check pointers: link.exe
							;-- always defines them, no archive does. Without
							;-- CFG instrumentation they point at a no-op
							;-- check -- here a RET stub, its address dropped
							;-- into the pointer slot once code layout is
							;-- final (an empty call-slot entry does that).
							any [
								name = "___guard_check_icall_fptr"
								name = "___guard_dispatch_icall_fptr"
							][
								tramp-off: length? code
								append code #{C3}			;-- no-op check: RET
								pad-to cafter-buf 4
								data-off: length? cafter-buf
								append cafter-buf #{00000000}
								repend cafter-fills [data-off tramp-off]
								repend sym-addr [name reduce ['cafter data-off false]]
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
							;-- an /alternatename onto another __imp_ (or a system
							;-- function): resolve as the final alias does, but
							;-- register the result under THIS name so wire-imp-relocs
							;-- / the trampoline serve its reference sites. Common in
							;-- the static UCRT, e.g.
							;-- __imp____std_init_once_begin_initialize@16 ->
							;-- __imp__InitOnceBeginInitialize@16 (kernel32).
							all [
								dn: alias-of name
								fa: final-alias name
								fa <> name
								imp: imp-resolve fa
							][
								repend imp-table [name imp]
							]
							all [
								dn: alias-of name
								fa: final-alias name
								fa <> name
								res: direct-resolve job fa
							][
								tramp-off: length? code
								append code #{FF25}				;-- JMP DWORD PTR [disp32]
								disp-ref: 1 + length? code
								append code #{00000000}
								add-import job res/1 res/2 disp-ref
								repend sym-addr [name reduce ['code tramp-off false]]
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
							all [
								obj-format = 'ELF
								find weak-undefs name
								not find strong-undefs name
							][
								;-- weak-only undefined (crtbegin's _ITM_* TM
								;-- hooks, __gmon_start__): ELF semantics bind
								;-- them to address 0; callers null-check.
								repend sym-addr [name reduce ['absolute 0 false]]
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
	add-import: func [job [object!] dll [string!] bare [string! issue!] offset [integer!] /local imports entry fpos][
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
			macOS   ["/usr/lib/libSystem.B.dylib"]		;-- umbrella re-exporting libc/libm/pthread/unwind
		]["libc.so.6"]
	]

	libm-name: func [job [object!]][
		switch/default job/OS [
			macOS ["/usr/lib/libSystem.B.dylib"]		;-- libm folded into libSystem
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

	;-- Mach-O common (tentative) definitions -- zero-init globals like
	;-- ImGui's `ImGuiContext* GImGui` that the compiler emits as
	;-- (__DATA,__common) external. Coalesce by name across all objects,
	;-- LARGEST size and STRICTEST alignment winning (ld64's rule), then
	;-- allocate one zeroed slot per unique name in .data, defining it so
	;-- references resolve to real writable storage instead of a bogus
	;-- function import. A real definition elsewhere beats every tentative
	;-- one and leaves the commons unallocated.
	merge-commons: func [
		job [object!] /local data path obj sym nm sz a base entry commons
	][
		if obj-format <> 'Mach-o [exit]
		commons: make block! 16						;-- name [size align] pairs
		foreach [path obj] objects [
			foreach sym obj/symbols [
				sz: reader/sym-common-size sym
				if sz > 0 [
					nm: reader/sym-name sym
					a: reader/sym-common-align sym
					if zero? a [					;-- unspecified: ld64 picks a pow2 >= size,
						a: case [					;-- capped at 16 bytes
							sz >= 16 [16]
							sz >= 8  [8]
							true     [4]
						]
					]
					either entry: select commons nm [
						entry/1: max entry/1 sz
						entry/2: max entry/2 a
					][
						repend commons [nm reduce [sz a]]
					]
				]
			]
		]
		data: job/sections/data/2
		foreach [nm entry] commons [
			unless select sym-addr nm [
				pad-to data max 4 entry/2
				base: length? data
				insert/dup tail data null max 4 entry/1
				repend sym-addr [nm reduce ['data base false]]
			]
		]
	]

	;-- Apple assemblers emit __eh_frame with NO relocations on the FDE
	;-- pc-begin and LSDA fields: both are implicit pcrel values, valid only
	;-- in the object's rigid section layout (the scattered-SECTDIFF
	;-- personality slot is the lone relocated field). ld64 re-encodes them
	;-- during layout; so must we, once every image address is final --
	;-- otherwise libunwind computes function ranges off by each section's
	;-- displacement delta and the first throw dies parsing garbage.
	rewrite-macho-ehframe: func [
		job [object!] code-va [integer!] data-va [integer!] rodata-va [integer!]
		/local buf u32at put32 uleb-at enc-size map-va pos
			cb0 sec-va size off0 len id ver aug cies enc pair fpos0 tgt
	][
		if any [obj-format <> 'Mach-o  empty? eh-frames][exit]
		buf: ehframe-buf
		u32at: func [p [integer!]][					;-- LE, sign carried by 32-bit wrap
			(to integer! buf/:p)
				or (shift/left to integer! buf/(p + 1) 8)
				or (shift/left to integer! buf/(p + 2) 16)
				or (shift/left to integer! buf/(p + 3) 24)
		]
		put32: func [p [integer!] v [integer!]][
			change at buf p le32 v
		]
		uleb-at: func [/local v s b][				;-- reads at pos, advances it
			v: 0 s: 0
			until [
				b: to integer! buf/:pos
				pos: pos + 1
				v: v or shift/left (b and 127) s
				s: s + 7
				b < 128
			]
			v
		]
		enc-size: func [e [integer!]][				;-- DW_EH_PE value size in bytes
			switch/default e and 15 [2 [2] 3 [4] 4 [8] 11 [4] 12 [8]][4]
		]
		map-va: func [obj [object!] t [integer!] /local s][
			foreach s obj/sections [
				if all [
					'none <> reader/sec-base-kind s
					t >= reader/sec-vmaddr s
					t < ((reader/sec-vmaddr s) + reader/sec-size s)
				][
					return (reader/sec-base-offset s) + (t - reader/sec-vmaddr s)
						+ switch/default reader/sec-base-kind s [
							code	 [code-va]
							data	 [data-va]
							rodata	 [rodata-va]
							eh-frame [ehframe-base]
						][abort reduce ["eh_frame pcrel target in unsupported section kind:" reader/sec-base-kind s]]
				]
			]
			abort reduce ["eh_frame pcrel target outside every live section:" t]
		]
		foreach [seq obj section] eh-frames [
			cb0:	reader/sec-base-offset section	;-- chunk offset in ehframe-buf
			sec-va:	reader/sec-vmaddr section		;-- chunk address in the OBJECT layout
			size:	reader/sec-size section
			cies:	make block! 8					;-- chunk-relative CIE offset -> [lsda-enc fde-enc]
			off0:	0
			while [off0 < size][
				len: u32at cb0 + off0 + 1
				if zero? len [break]				;-- explicit terminator
				id: u32at cb0 + off0 + 5
				either zero? id [
					;-- CIE: capture the L/R encodings, skip the P field
					pos: cb0 + off0 + 9
					ver: to integer! buf/:pos
					pos: pos + 1
					unless ver = 1 [abort reduce ["unsupported Mach-O eh_frame CIE version:" ver]]
					aug: copy ""
					while [0 <> to integer! buf/:pos][
						append aug to char! buf/:pos
						pos: pos + 1
					]
					pos: pos + 1
					uleb-at								;-- code alignment factor
					uleb-at								;-- data alignment factor (sleb, value unused)
					pos: pos + 1						;-- v1 return-address register (byte)
					pair: reduce [255 0]
					if find aug #"z" [
						uleb-at							;-- augmentation length
						foreach ch aug [
							switch ch [
								#"P" [
									enc: to integer! buf/:pos
									pos: pos + 1 + enc-size enc	;-- personality: own SECTDIFF reloc
								]
								#"L" [
									pair/1: to integer! buf/:pos
									pos: pos + 1
								]
								#"R" [
									pair/2: to integer! buf/:pos
									pos: pos + 1
								]
							]
						]
					]
					append cies off0
					append/only cies pair
				][
					;-- FDE: re-encode pc-begin, then the LSDA augmentation field
					pair: select cies (off0 + 4) - id
					unless pair [abort "Mach-O eh_frame FDE references a CIE outside its chunk"]
					unless find [16 27] pair/2 [		;-- pcrel absptr / pcrel sdata4
						abort reduce ["unsupported Mach-O eh_frame FDE encoding:" pair/2]
					]
					fpos0: off0 + 8
					tgt: map-va obj sec-va + fpos0 + u32at cb0 + fpos0 + 1
					put32 cb0 + fpos0 + 1 tgt - (ehframe-base + cb0 + fpos0)
					if pair/1 <> 255 [
						unless find [16 27] pair/1 [
							abort reduce ["unsupported Mach-O eh_frame LSDA encoding:" pair/1]
						]
						pos: cb0 + off0 + 17			;-- past pc-range: augmentation length
						uleb-at
						fpos0: pos - cb0 - 1			;-- LSDA field (chunk-relative)
						tgt: map-va obj sec-va + fpos0 + u32at cb0 + fpos0 + 1
						put32 cb0 + fpos0 + 1 tgt - (ehframe-base + cb0 + fpos0)
					]
				]
				off0: off0 + 4 + len
			]
		]
	]

	;-- Mach-O: indirect-pointer slots naming DYLIB DATA (__stdoutp & co)
	;-- cannot be filled at link time -- rewire every code reference onto
	;-- the emitter's own dyld-bound pointer (import-vars machinery) and
	;-- drop the dead slot fill. Slots naming in-link symbols keep their
	;-- synthetic abs32 and fill statically.
	wire-nlptr-relocs: func [
		job [object!]
		/local code obj section nl-idx i s fills r sym nm bare dll tinfo
			sec sec-base slot fr keep relocs-blk
	][
		if obj-format <> 'Mach-o [exit]
		if empty? nlptr-sections [exit]
		code: job/sections/code/2
		foreach [obj section] nlptr-sections [
			nl-idx: 0
			i: 1
			foreach s obj/sections [
				if same? s section [nl-idx: i]
				i: i + 1
			]
			;-- dylib-data slots: slot-offset => [bare fill-reloc dylib]
			fills: copy []
			foreach r reader/sec-relocs section [
				if r/3 = 8 [
					sym: pick obj/symbols (r/2 + 1)
					if all [sym  reader/is-undefined-external? sym][
						nm: reader/sym-name sym
						;-- dylib-DATA slots must be rewired in EVERY object that
						;-- owns one, not just the first: the name is parked in
						;-- sym-addr after the first object, so an `unless select
						;-- sym-addr` guard here silently dropped later objects'
						;-- slots (e.g. imgui.o's __stderrp), leaving them a zero
						;-- pointer that crashed on first deref. Gate on the name
						;-- being dylib DATA instead.
						bare: arch-bare nm
						dll: none
						if find macos-data-names bare [dll: "/usr/lib/libSystem.B.dylib"]
						if all [none? dll  cxx-var-map  tinfo: select cxx-var-map bare][
							dll: either slash = first tinfo [copy tinfo][
								join "/usr/lib/" tinfo
							]
						]
						if dll [
							if bare = "__stderrp" [dbg?: true]
							repend/only fills [r/1]
							append/only fills reduce [bare r dll nm]
						]
					]
				]
			]
			unless empty? fills [
				foreach sec obj/sections [
					if 'code = reader/sec-base-kind sec [
						sec-base: reader/sec-base-offset sec
						relocs-blk: reader/sec-relocs sec
						keep: copy []
						foreach r relocs-blk [
							either all [
								r/3 = 8
								sym: pick obj/symbols (r/2 + 1)
								"" = reader/sym-name sym
								nl-idx = reader/sym-sect sym
								fr: select/only fills reduce [
									slot: reader/i32-le code (sec-base + r/1 + 1)
								]
							][
								;-- 1-based code offset: resolve-import-refs
								;-- patches the absolute pointer VA here
								add-import job fr/3 to issue! fr/1 (sec-base + r/1 + 1)
							][
								append/only keep r
							]
						]
						clear relocs-blk
						foreach r keep [append/only relocs-blk r]
					]
				]
				relocs-blk: reader/sec-relocs section
				foreach [slot fr] fills [
					if i: find/only relocs-blk fr/2 [remove i]
					;-- nothing references the name anymore -- park it so
					;-- resolve-externals does not chase it
					unless select sym-addr fr/4 [
						repend sym-addr [fr/4 reduce ['absolute 0 false]]
					]
				]
			]
		]
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
		;-- i386 -fstack-protector emits a hidden, PIC-local wrapper
		;-- __stack_chk_fail_local (normally provided by libc_nonshared.a) that
		;-- merely forwards to __stack_chk_fail. Alias it to the real libc entry
		;-- so stack-protected objects link on any host without that static
		;-- helper archive present -- notably when cross-compiling to Linux.
		if bare = "__stack_chk_fail_local" [bare: "__stack_chk_fail"]
		if all [libc-set  find libc-set bare][return reduce [libc-name job  bare]]
		if all [libm-set  find libm-set bare][return reduce [libm-name job  bare]]
		if all [syslib-index  dll: select syslib-index bare][return reduce [dll bare]]
		;-- macOS: the C++ runtime and frameworks bind dynamically (Apple
		;-- ships no static libc++) -- route to their dylibs like libc;
		;-- framework entries already carry an absolute path
		if all [cxx-fn-map  dll: select cxx-fn-map bare][
			return reduce [
				either slash = first dll [copy dll][join "/usr/lib/" dll]
				bare
			]
		]
		;-- Fallback: any function still undefined on macOS is a libSystem
		;-- export the classic symbol table doesn't list (memcpy/memmove/...
		;-- live only in the export trie, re-exported through libSystem).
		;-- dyld resolves it through the umbrella, or fails cleanly at load.
		if job/OS = 'macOS [return reduce ["/usr/lib/libSystem.B.dylib" bare]]
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

	;-- Run a Windows command capturing stdout. The encapped SDK kernel's
	;-- native CALL leaves the process console broken -- every console
	;-- write from that point on is silently lost, while pipes still work.
	;-- Go through win-call (utils/call.r, loaded by red.r at startup),
	;-- which spawns through CreateProcess instead, exactly as red.r's own
	;-- shell-outs do; from sources the native call keeps serving.
	call-output: func [cmd [string!] buf [string!]][
		either all [encap?  value? 'win-call][
			win-call/output cmd buf
		][
			call/shell/wait/output cmd buf
		]
	]

	;-- Read one HKLM string value through reg.exe, trying the 32- then the
	;-- 64-bit registry view; returns the value string, or none if absent.
	;-- reg.exe is a Windows built-in, so this needs nothing installed.
	reg-read: func [key [string!] value [string!] /local out view line p][
		foreach view ["/reg:32" "/reg:64"][
			out: copy ""
			unless error? try [
				call-output
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

	;-- ===== MSVC toolset / Windows SDK static-library location =====

	;-- vswhere.exe has one fixed, documented install location; it reports
	;-- the newest Visual Studio (or Build Tools) carrying the C++ toolset.
	vswhere-path: %"/C/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"

	;-- Locate the x86 static-library directories: the VC toolset's (libcmt,
	;-- libcpmt, libvcruntime, oldnames, libconcrt, comsuppw...), the SDK's
	;-- ucrt (libucrt) and um (uuid, mfuuid, strmiids...). Returns a block
	;-- of existing directories, possibly empty.
	find-msvc-lib-dirs: func [/local out root ver dir sub][
		out: make block! 3
		if exists? vswhere-path [
			root: copy ""
			unless error? try [
				call-output rejoin [
					{"} to-local-file vswhere-path {"}
					{ -products * -latest}
					{ -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64}
					{ -property installationPath}
				] root
			][
				trim/tail root
				if all [
					not empty? root
					ver: newest-subdir dir: join to-rebol-file root %/VC/Tools/MSVC/
				][
					dir: rejoin [dir ver %lib/x86/]
					if exists? dir [append out dir]
				]
			]
		]
		if root: reg-read "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots" "KitsRoot10" [
			dir: rejoin [to-rebol-file root %Lib/]
			if ver: newest-subdir dir [
				foreach sub [%ucrt/x86/ %um/x86/][
					if exists? rejoin [dir ver sub][append out rejoin [dir ver sub]]
				]
			]
		]
		out
	]

	;-- Open the archives named by accumulated /defaultlib directives,
	;-- resolved against the MSVC toolset and Windows SDK directories --
	;-- link.exe's default-library mechanism, which is how an MSVC object
	;-- chains in the static CRT (libcmt -> libvcruntime/libucrt, libcpmt
	;-- -> libconcrt, ...). Import libraries are skipped: their symbols
	;-- resolve through the embedded export snapshots. The first sight of
	;-- libcmt engages the CRT-owned startup -- mainCRTStartup joins the
	;-- reference queue and the PE entry point moves to it, Red's start
	;-- becoming `_main`. Returns TRUE when a new archive was opened.
	;-- C++ / MSVC-runtime symbols that msvcrt.dll does not export, so their
	;-- presence means the link genuinely needs the static MSVC CRT (rather
	;-- than Red's msvcrt trampolines). A pure-C object that only calls libc
	;-- references none of these, so it keeps the lightweight msvcrt path and
	;-- never drags in the full C++ runtime. Matched against `needed`.
	crt-markers: [
		"___CxxFrameHandler3" "___CxxFrameHandler4" "__CxxThrowException@8"
		"??2@YAPAXI@Z" "??3@YAXPAX@Z" "??_V@YAXPAX@Z" "__purecall"
		"___std_terminate" "__Init_thread_header" "___std_exception_copy"
		"?_Xlength_error@std@@YAXPBD@Z" "??0exception@std@@QAE@ABQBD@Z"
		;-- implicit TLS is CRT-owned: tlssup.obj carries __tls_used/__tls_index,
		;-- tlsdyn.obj the VS2019+ lazy-init guard pair -- an object can demand
		;-- these without touching any other C++ marker (a lone thread_local)
		"___tls_guard" "___dyn_tls_init@12" "___dyn_tls_on_demand_init@0"
		"__tls_index" "__tls_used"
	]

	;-- TRUE when the merged objects reference any C++/MSVC-runtime symbol,
	;-- i.e. the static CRT is actually required for this link.
	needs-crt?: has [m][
		foreach m crt-markers [if find needed m [return true]]
		false
	]

	;-- Itanium-ABI markers: any of these among the undefined externals means
	;-- the merged objects carry g++-compiled C++ and need the GNU C++ runtime
	;-- (static libstdc++/libgcc/libgcc_eh + crtbeginT/crtend frame registry;
	;-- libc itself stays dynamic, per Red's ELF model).
	cpp-markers: [
		"__gxx_personality_v0" "__cxa_throw" "__cxa_begin_catch"
		"__cxa_guard_acquire" "__cxa_pure_virtual" "__cxa_rethrow"
		"_Znwj" "_Znaj" "_ZSt9terminatev" "_ZSt20__throw_length_errorPKc"
		"__aeabi_unwind_cpp_pr0" "__aeabi_unwind_cpp_pr1" "__aeabi_unwind_cpp_pr2"
		"__aeabi_uldivmod" "__aeabi_ldivmod" "__aeabi_uidiv" "__aeabi_idiv"
		"__aeabi_uidivmod" "__aeabi_idivmod"
	]

	needs-cpp?: has [m][
		foreach m cpp-markers [if find needed m [return true]]
		;-- any Itanium-mangled unresolved name means g++-compiled C++ --
		;-- a TU can use libstdc++ without touching new/EH/RTTI markers
		foreach m needed [
			if all [(length? m) > 2  "_Z" = copy/part m 2][return true]
		]
		false
	]

	;-- ELF analog of open-default-libs: on the first C++ marker, open the
	;-- GNU C++ runtime archives (searched next to the user's imported static
	;-- archives) and merge the crtbeginT/crtend frame-registry bookends as
	;-- direct objects. Returns TRUE when anything new joined the link.
	open-cpp-libs: func [
		job [object!] archives [block!] directs [block!]
		/local dirs key info dir file path arc obj found?
	][
		if obj-format <> 'ELF [return false]
		if cpp-mode? [return false]
		if not needs-cpp? [return false]
		dirs: make block! 4
		foreach [key info] job/static-objs [
			dir: first split-path info/1
			unless find dirs dir [append dirs dir]
		]
		found?: false
		;-- libatomic (32-bit 64-bit atomics) and libc_nonshared (atexit &
		;-- co -- glibc never exports those dynamically on every arch) are
		;-- optional pulls; only libstdc++ is mandatory
		foreach file ["libstdc++.a" "libgcc.a" "libgcc_eh.a" "libatomic.a" "libc_nonshared.a"][
			unless find opened-libs file [
				path: none
				foreach dir dirs [
					if all [none? path  exists? join dir file][path: join dir file]
				]
				either path [
					append opened-libs copy file
					append/only archives open-archive path
					found?: true
					print ["...C++ runtime lib  :" file]
				][
					;-- libatomic is optional (32-bit ARM 64-bit atomics)
					if file = "libstdc++.a" [found?: false]
				]
			]
		]
		unless found? [
			abort [
				"C++ objects need the GNU runtime: put libstdc++.a, libgcc.a,"
				"libgcc_eh.a (+ crtbeginT.o/crtend.o) next to the imported archive"
			]
		]
		;-- the static-link crtbegin (frame registry + __dso_handle) and the
		;-- table terminators; plain crtbegin.o serves when the T variant is
		;-- not shipped for the target
		foreach file [["crtbeginT.o" "crtbegin.o"] ["crtend.o"]][
			path: none
			foreach f file [
				foreach dir dirs [
					if all [none? path  exists? join dir f][path: join dir f]
				]
			]
			if path [
				obj: reader/load path
				note-merged-object obj
				mark-live-sections obj
				merge-sections job obj
				repend objects [obj/path obj]
				note-undefined obj
				append directs obj
				print ["...C++ frame registry:" second split-path path]
			]
		]
		cpp-mode?: yes
		true
	]

	open-default-libs: func [
		job [object!] archives [block!]
		/local opened? name file path dir arc
	][
		if obj-format <> 'PE [return false]
		if not crt-link-enabled? [return false]			;-- CRT auto-pull disabled entirely
		if not needs-crt? [return false]				;-- pure-C link: msvcrt trampolines suffice
		opened?: false
		foreach name default-libs [
			file: either find name "." [copy name][join name ".lib"]
			unless find opened-libs file [
				append opened-libs copy file
				unless msvc-dirs [msvc-dirs: find-msvc-lib-dirs]
				path: none
				foreach dir msvc-dirs [
					if all [none? path  exists? join dir file][path: join dir file]
				]
				if path [
					arc: open-archive path
					either arc/import-lib? = yes [
						arc/bin: none				;-- dynamic stubs: not for static linking
					][
						append/only archives arc
						opened?: yes
						print ["...default library :" file]
						if all [not crt-mode?  file = "libcmt.lib"][
							crt-mode?: yes
							unless find needed "_mainCRTStartup" [
								append needed "_mainCRTStartup"
							]
							print "...MSVC static CRT : entry -> mainCRTStartup, Red start -> _main"
						]
					]
				]
			]
		]
		opened?
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
	;-- ELF i386 (SysV) symbols carry no decoration. Alias links
	;-- (/alternatename, weak defaults) are followed.
	find-static-symbol: func [id [string!] cc [word!] /local want k v][
		case [
			obj-format = 'ELF [resolve-sym-addr id]			;-- SysV i386: undecorated
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
			true [resolve-sym-addr join "_" id]				;-- PE cdecl / Mach-O: _name
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
		/local data data-base start-va end-va index-va callbacks-va entry
	][
		if any [obj-format <> 'PE  none? tls-start][exit]
		data: job/sections/data/2
		data-base: image-base + data-rva

		;-- the MSVC CRT provides the real TLS directory (tlssup.obj's
		;-- __tls_used, complete with the $XL callback bounds): point the
		;-- PE data directory at it instead of synthesizing one. It lives
		;-- in .rdata$T, so on PE it lands in the crodata section
		if all [
			none? tls-dir
			entry: select sym-addr "__tls_used"
			find [data crodata] entry/1
		][
			tls-dir: entry/2
			tls-dir-kind: entry/1
			ensure-symbol "___tls_used" entry/1 entry/2
			ensure-symbol "__tls_array" 'absolute 44
			exit
		]

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

	pe-tls-rva?: func [data-rva [integer!] crodata-rva [integer!]][
		either tls-dir [
			tls-dir + either tls-dir-kind = 'crodata [crodata-rva][data-rva]
		][0]
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
		/local target-info tsect tsection tkind toff ckey entry tname twin
	][
		;-- weak externals resolve by name too: a strong definition wins,
		;-- else resolve-sym-addr follows the alias chain to the recorded
		;-- default (??_E -> ??_G, oldnames, /alternatename). Mach-O common
		;-- (tentative) definitions resolve to the slot merge-commons
		;-- allocated -- they are neither defined nor undefined externals
		target-info: either any [
			reader/is-defined-external? sym
			reader/is-undefined-external? sym
			reader/sym-weak? sym
			all [obj-format = 'Mach-o  0 < reader/sym-common-size sym]
		][
			resolve-sym-addr reader/sym-name sym
		][none]
		either target-info [
			target-info
		][
			tsect: reader/sym-sect sym
			either all [tsect > 0  tsect <= length? obj/sections][
				tsection: pick obj/sections tsect
				tkind: reader/sec-base-kind tsection
				if tkind = 'none [
					;-- a duplicate-COMDAT twin: redirect into the kept copy,
					;-- where the symbol's offset transfers unchanged. An ELF
					;-- group can span several sections (function text, its
					;-- LSDA, rodata): members pair BY NAME across the twin
					;-- groups and each lands at its own base -- the recorded
					;-- entry only anchors the group's primary member
					if all [
						ckey: reader/sec-comdat-key tsection
						entry: select comdat-keys ckey
					][
						tname: reader/sec-name tsection
						unless tname = entry/5 [
							foreach twin entry/4/sections [
								if all [
									ckey = reader/sec-comdat-key twin
									tname = reader/sec-name twin
									'none <> reader/sec-base-kind twin
								][
									return reduce [
										reader/sec-base-kind twin
										(reader/sec-base-offset twin) + reader/sym-value sym
										false
									]
								]
							]
							;-- no same-name member in the kept instance: twin
							;-- groups from variant TUs may differ in composition
							;-- (libstdc++'s cow/non-cow locale members share one
							;-- key) -- anchor to the primary member as before;
							;-- only the twin's own dead FDE ever points here
						]
						return reduce [entry/1  entry/2 + reader/sym-value sym  false]
					]
					abort reduce [
							"relocation targets a dropped section:"
							reader/sym-name sym "->" reader/sec-name tsection
							"kind" reader/sec-kind tsection "in" path
						]
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
			tkind = 'crodata	[crodata-base + toff]
			tkind = 'cafter		[cafter-base + toff]
			tkind = 'eh-frame	[ehframe-base + toff]
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
						if find [
							got32 gotoff gotpc got-prel
							tls-gd tls-ldm tls-ie tls-gotie
							tls-gd-prel tls-ldm-prel tls-ie-prel
						] kind [
							ensure-got-base job
						]
						if any [kind = 'got32  kind = 'got-prel][
							sym: pick obj/symbols (r/2 + 1)
							unless sym [abort reduce ["bad relocation symbol index" r/2 "in" path]]
							info: resolve-reloc-target obj sym path
							key: got-key path sym r/2
							ensure-got-slot job key info
						]
						;-- TLS GOT entries hold link-time constants (module 1):
						;-- GD = {dtpmod=1, dtpoff}; LDM = {1, 0}; IE/GOTIE = tpoff
						if find [tls-gd tls-ldm tls-gd-prel tls-ldm-prel] kind [
							sym: pick obj/symbols (r/2 + 1)
							info: either find [tls-ldm tls-ldm-prel] kind [
								reduce ['tls 0]
							][
								resolve-reloc-target obj sym path
							]
							key: rejoin ["tls-pair$" got-key path sym r/2]
							ensure-got-pair job key info
						]
						if find [tls-ie tls-gotie tls-ie-prel] kind [
							sym: pick obj/symbols (r/2 + 1)
							info: resolve-reloc-target obj sym path
							key: rejoin ["tls-ie$" got-key path sym r/2]
							ensure-got-tpoff job key info
						]
					]
				]
			]
		]
	]

	;-- An 8-byte GOT {dtpmod, dtpoff} pair for general/local-dynamic TLS.
	ensure-got-pair: func [
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
		append data #{0000000000000000}
		repend got-slots [copy key reduce [slot 'tls-pair info/2]]
		slot
	]

	;-- A 4-byte GOT slot holding a (negative) thread-pointer offset.
	ensure-got-tpoff: func [
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
		repend got-slots [copy key reduce [slot 'tls-tpoff info/2]]
		slot
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
			case [
				entry/2 = 'tls-pair [
					;-- {dtpmod, dtpoff}: the executable is TLS module 1
					change at data (entry/1 + 1) le32 1
					change at data (entry/1 + 5) le32 entry/3
				]
				entry/2 = 'tls-tpoff [
					;-- i386 (variant 2): TP at the END of the block;
					;-- ARM (variant 1): 8-byte TCB at TP, block after it
					change at data (entry/1 + 1) le32 either obj-arch = 'ARM [
						entry/3 + align-up 8 etls-align
					][
						entry/3 - align-up etls-memsz etls-align
					]
				]
				true [
					target-va: target-va? entry/2 entry/3 code-base data-base image-base
					change at data (entry/1 + 1) le32 target-va
				]
			]
		]
	]

	align-up: func [n [integer!] a [integer!]][
		either a <= 1 [n][n + (a - 1) - ((n + (a - 1)) // a)]
	]

	;-- ===== formats/{PE,ELF}.r hook : apply relocations after layout =====

	apply-relocs: func [
		job [object!] code-base [integer!] data-base [integer!] image-base [integer!]
		/local code data crodata cafter reloc slot info section sec-kind sec-base buf buf-base
			r r-va r-sym r-type sym target-info tkind toff target-va kind
			patch-pos patch-va addend path obj insn a16 got-slot got-base
			sym-name key entry
			sub-sym sub-tinfo sub-tkind sub-toff sub-va
			min-offset sub-offset min-section sub-section orig-diff
	][
		if empty? objects [exit]
		code: job/sections/code/2
		data: job/sections/data/2
		crodata: all [find job/sections 'crodata  job/sections/crodata/2]
		cafter:  all [find job/sections 'cafter   job/sections/cafter/2]
		write-got-slots job code-base data-base image-base

		;-- Fill the read-only-after-init pointer slots with their no-op
		;-- stub's VA (page-isolated cafter section; see cafter-buf).
		if all [cafter-base  not empty? cafter-fills][
			foreach [off tramp] cafter-fills [
				change at cafter (off + 1) le32 (code-base + tramp)
			]
		]

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
					;-- TLS section bases are template-relative; the template
					;-- itself sits at etls-off inside the .data buffer
					if all [sec-kind = 'tls  etls-off][
						sec-base: etls-off + sec-base
					]
					buf: case [
						sec-kind = 'code     [code]
						sec-kind = 'crodata  [crodata]
						sec-kind = 'cafter   [cafter]
						sec-kind = 'eh-frame [ehframe-buf]
						true                 [data]
					]
					buf-base: case [
						sec-kind = 'code     [code-base]
						sec-kind = 'crodata  [crodata-base]
						sec-kind = 'cafter   [cafter-base]
						sec-kind = 'eh-frame [ehframe-base]
						true                 [data-base]
					]
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
						;-- relative to the field's address in the OBJECT's
						;-- scratch layout -- section vmaddr + r-va, NOT the
						;-- section start (they only coincide for __text, whose
						;-- vmaddr is 0 -- a __textcoal_nt call site is short by
						;-- its section's vmaddr otherwise). Fold the full field
						;-- address in so the COFF/ELF "addend at the field"
						;-- model applies uniformly below.
						if all [obj-format = 'Mach-o  kind = 'pc32][
							addend: addend + r-va + reader/sec-vmaddr section
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
							any [kind = 'tls-gd  kind = 'tls-ldm][
								;-- GOT-relative offset of the {dtpmod dtpoff} pair
								key: rejoin ["tls-pair$" got-key path sym r-sym]
								entry: select got-slots key
								unless entry [abort reduce ["missing TLS GOT pair:" sym-name "(in" path ")"]]
								change at buf (patch-pos + 1)
									le32 (((data-base + entry/1) + addend) - got-base)
							]
							kind = 'tls-gotie [
								;-- GOT-relative offset of the tpoff slot
								key: rejoin ["tls-ie$" got-key path sym r-sym]
								entry: select got-slots key
								unless entry [abort reduce ["missing TLS IE slot:" sym-name "(in" path ")"]]
								change at buf (patch-pos + 1)
									le32 (((data-base + entry/1) + addend) - got-base)
							]
							kind = 'tls-ie [
								;-- absolute VA of the tpoff slot
								key: rejoin ["tls-ie$" got-key path sym r-sym]
								entry: select got-slots key
								unless entry [abort reduce ["missing TLS IE slot:" sym-name "(in" path ")"]]
								change at buf (patch-pos + 1)
									le32 ((data-base + entry/1) + addend)
							]
							kind = 'tls-ldo [
								;-- offset within the module's TLS block (dtpoff)
								change at buf (patch-pos + 1) le32 (toff + addend)
							]
							kind = 'tls-le [
								;-- offset from the thread pointer: i386 variant 2
								;-- (negative, TP at block end) vs ARM variant 1
								;-- (positive, past the 8-byte TCB)
								change at buf (patch-pos + 1) le32 either obj-arch = 'ARM [
									(toff + align-up 8 etls-align) + addend
								][
									(toff - align-up etls-memsz etls-align) + addend
								]
							]
							any [kind = 'tls-gd-prel  kind = 'tls-ldm-prel][
								;-- ARM: place-relative address of the {mod off} pair
								key: rejoin ["tls-pair$" got-key path sym r-sym]
								entry: select got-slots key
								unless entry [abort reduce ["missing TLS GOT pair:" sym-name "(in" path ")"]]
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 (((data-base + entry/1) + addend) - patch-va)
							]
							kind = 'tls-ie-prel [
								;-- ARM: place-relative address of the tpoff slot
								key: rejoin ["tls-ie$" got-key path sym r-sym]
								entry: select got-slots key
								unless entry [abort reduce ["missing TLS IE slot:" sym-name "(in" path ")"]]
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 (((data-base + entry/1) + addend) - patch-va)
							]
							kind = 'got-prel [
								;-- ARM TARGET2 (GNU/Linux): place-relative address
								;-- of the symbol's GOT slot (unwinder dereferences)
								key: got-key path sym r-sym
								entry: select got-slots key
								unless entry [abort reduce ["missing GOT slot:" sym-name "(in" path ")"]]
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1)
									le32 (((data-base + entry/1) + addend) - patch-va)
							]
							kind = 'prel31 [
								;-- 31-bit place-relative (EHABI tables); bit 31
								;-- of the field is a flag and must be preserved
								a16: addend and 2147483647
								if 0 <> (a16 and 1073741824)[a16: a16 or bit31]
								patch-va: buf-base + patch-pos
								change at buf (patch-pos + 1) le32 (
									(((target-va + a16) - patch-va) and 2147483647)
									or (addend and bit31)
								)
							]
							kind = 'rva32 [
								change at buf (patch-pos + 1)
									le32 ((target-va - image-base) + addend)
							]
							kind = 'secrel32 [
								change at buf (patch-pos + 1)
									le32 (addend + either tkind = 'tls [toff - tls-start][toff])
							]
							kind = 'sectdiff [
								;-- Mach-O scattered SECTDIFF: the in-section
								;-- bytes encode `min_orig_addr - sub_orig_addr
								;-- + offset`. Re-derive `offset`, then rewrite
								;-- with the new merged-VA difference.
								sub-sym:    pick obj/symbols (r/4 + 1)
								min-offset: r/5
								sub-offset: r/6
								unless sub-sym [
									abort reduce [
										"bad SECTDIFF subtrahend in" path
									]
								]
								sub-tinfo: resolve-reloc-target obj sub-sym path
								sub-tkind: sub-tinfo/1
								sub-toff:  sub-tinfo/2
								sub-va:    target-va? sub-tkind (sub-toff + sub-offset)
									code-base data-base image-base
								min-section: pick obj/sections (reader/sym-sect sym)
								sub-section: pick obj/sections (reader/sym-sect sub-sym)
								orig-diff: ((reader/sec-vmaddr min-section) + min-offset)
									- ((reader/sec-vmaddr sub-section) + sub-offset)
								change at buf (patch-pos + 1)
									le32 (((target-va + min-offset) - sub-va) + (addend - orig-diff))
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
