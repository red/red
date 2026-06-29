REBOL [
	Title:   "Red/System system C library export-set generator"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-exports.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Offline generator for %system/formats/libc-exports.r. Parses the
		export tables of the host's system C libraries -- a PE DLL's export
		directory (msvcrt.dll) and an ELF32 shared object's .dynsym
		(libc.so.6) -- and emits their exported-name sets as an embedded
		data file the static linker consults at link time.

		This script is NOT loaded by the toolchain; it is run by hand when
		the embedded sets need refreshing:

		    rebpro -qws lib-exports.r <msvcrt.dll path> <libc.so.6 path>

		macOS: libSystem cannot be read off a non-macOS host, so the macOS
		set is aliased to the Linux set (the C/POSIX names overlap heavily).
	}
]

lib-exports: context [

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

	read-cstring: func [bin [binary!] pos [integer!] /local out b i][
		out: copy ""
		i: pos
		while [all [i <= length? bin  (b: byte-at bin i) <> 0]][
			append out to char! b
			i: i + 1
		]
		out
	]

	;-- ===== PE export directory (msvcrt.dll) =====

	;-- Return a block of every name exported by a PE DLL, or NONE.
	pe-exports: func [
		path [file!]
		/local bin pe-off n-secs opt-size opt-off magic dd-off exp-rva
			exp-off sec-base n-names np-off result i rva rva-to-off
	][
		bin: read/binary path
		if (length? bin) < 64 [return none]
		pe-off: u32-le bin 61							;-- e_lfanew @ 0x3C
		if (pe-off + 248) > length? bin [return none]
		if (copy/part at bin (pe-off + 1) 4) <> #{50450000} [return none]
		n-secs:   u16-le bin (pe-off + 4 + 2 + 1)
		opt-size: u16-le bin (pe-off + 4 + 16 + 1)
		opt-off:  pe-off + 4 + 20
		magic:    u16-le bin (opt-off + 1)				;-- 267 = PE32, 523 = PE32+
		dd-off:   opt-off + either magic = 523 [112][96]
		exp-rva:  u32-le bin (dd-off + 1)				;-- data directory 0 = export table
		if zero? exp-rva [return none]
		sec-base: opt-off + opt-size

		rva-to-off: func [rva [integer!] /local j p va sz][
			j: 0
			while [j < n-secs][
				p:  sec-base + (j * 40)
				va: u32-le bin (p + 12 + 1)
				sz: u32-le bin (p + 16 + 1)
				if all [rva >= va  rva < (va + sz)][
					return rva - va + (u32-le bin (p + 20 + 1))
				]
				j: j + 1
			]
			none
		]

		exp-off: rva-to-off exp-rva
		if none? exp-off [return none]
		n-names: u32-le bin (exp-off + 24 + 1)
		np-off:  rva-to-off (u32-le bin (exp-off + 32 + 1))
		if none? np-off [return none]

		result: make block! (1 + n-names)
		i: 0
		while [i < n-names][
			rva: u32-le bin (np-off + (i * 4) + 1)
			append result read-cstring bin (1 + rva-to-off rva)
			i: i + 1
		]
		result
	]

	;-- ===== ELF dynamic symbol table (libc.so.6) =====

	;-- Parse an ELF32 shared object's .dynsym. Returns a two-item block:
	;--   1. every name a defined global/weak symbol exports;
	;--   2. the data symbols only, as [name size ...] pairs (STT_OBJECT) --
	;--      used by the static linker to copy-relocate data-symbol imports.
	;-- Returns NONE if the file is not a readable ELF32 shared object.
	elf-exports: func [
		path [file!]
		/local bin e-shoff e-shnum hdrs i p dynsym-hdr strtab-hdr dynstr
			n-syms result sp st-name st-info st-shndx sym-bind name h
			st-size data-result
	][
		bin: read/binary path
		if (length? bin) < 52 [return none]
		if (copy/part bin 4) <> #{7F454C46} [return none]
		if (byte-at bin 5) <> 1 [return none]			;-- ELFCLASS32 only
		e-shoff: u32-le bin 33
		e-shnum: u16-le bin 49

		hdrs: copy []
		i: 0
		while [i < e-shnum][
			p: e-shoff + (i * 40) + 1
			append/only hdrs reduce [
				u32-le bin (p + 4)						;-- 1 sh_type
				u32-le bin (p + 16)						;-- 2 sh_offset
				u32-le bin (p + 20)						;-- 3 sh_size
				u32-le bin (p + 24)						;-- 4 sh_link
			]
			i: i + 1
		]

		dynsym-hdr: none
		foreach h hdrs [if all [h/1 = 11  none? dynsym-hdr][dynsym-hdr: h]]	;-- SHT_DYNSYM
		if none? dynsym-hdr [return none]
		strtab-hdr: pick hdrs (dynsym-hdr/4 + 1)
		if none? strtab-hdr [return none]
		dynstr: copy/part at bin (strtab-hdr/2 + 1) strtab-hdr/3
		n-syms: to integer! dynsym-hdr/3 / 16

		result:      make block! (1 + n-syms)
		data-result: make block! 256
		i: 0
		while [i < n-syms][
			sp:       dynsym-hdr/2 + (i * 16) + 1
			st-name:  u32-le bin sp
			st-size:  u32-le bin (sp + 8)
			st-info:  byte-at bin (sp + 12)
			st-shndx: u16-le bin (sp + 14)
			sym-bind: shift/logical st-info 4
			if all [
				any [sym-bind = 1  sym-bind = 2]		;-- STB_GLOBAL / STB_WEAK
				st-shndx <> 0							;-- defined (not SHN_UNDEF)
				st-shndx < 65280						;-- not a reserved index
			][
				name: read-cstring dynstr (st-name + 1)
				unless empty? name [
					append result name
					if all [
						1 = (st-info and 15)			;-- STT_OBJECT (data)
						st-size > 0
						not find data-result name
					][
						repend data-result [name st-size]
					]
				]
			]
			i: i + 1
		]
		reduce [result data-result]
	]

	;-- ===== Data-file generation =====

	generate: func [
		msvcrt [file!] libc [file!] out [file!]
		/local win lin lin-data txt emit n
	][
		win: sort unique to block! any [pe-exports msvcrt  []]
		set [lin lin-data] any [elf-exports libc  reduce [copy [] copy []]]
		lin: sort unique lin

		emit: func [label set /local i][
			append txt reduce ["^/^-" label ": ["]
			i: 0
			foreach s set [
				append txt either zero? (i // 8) ["^/^-^-"][" "]
				append txt mold s
				i: i + 1
			]
			append txt "^/^-]^/"
		]

		txt: copy {REBOL [^/}
		append txt {^-Title:   "Generated system C library export sets"^/}
		append txt {^-Note:    "Generated by lib-exports.r -- do not edit by hand."^/}
		append txt {]^/^/}
		append txt "libc-exports: context [^/"
		emit "windows" win
		emit "linux"   lin
		emit "linux-data" lin-data
		append txt "^-macos: linux^-^-;-- libSystem approximated by the glibc set^/"
		append txt "]^/"
		write out txt
		reduce [length? win length? lin (length? lin-data) / 2]
	]
]

;-- ===== Generator entry point =====

either 2 <= length? exp-args: parse any [system/script/args ""] none [
	exp-counts: lib-exports/generate
		to-rebol-file exp-args/1
		to-rebol-file exp-args/2
		%libc-exports.r								;-- written next to this script
	print ["libc-exports.r generated:" exp-counts/1 "Windows," exp-counts/2 "Linux names," exp-counts/3 "Linux data"]
][
	print "Usage: rebpro -qws lib-exports.r <msvcrt.dll path> <libc.so.6 path>"
]
