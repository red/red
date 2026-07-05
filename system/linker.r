REBOL [
	Title:   "Red/System linker"
	Author:  "Nenad Rakocevic"
	File: 	 %linker.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

linker: context [
	version: 		1.0.0							;-- emitted linker version
	cpu-class: 		'IA-32							;-- default target
	file-emitter:	none							;-- file emitter object
	verbose: 		0								;-- logs verbosity level
	
	line-record!: make-struct [
		ptr		[integer!]							;-- code pointer
		line	[integer!]							;-- line number
		file	[integer!]							;-- filename string offset
	] none
	
	func-record!: make-struct 	[					;-- debug lines records associating code addresses and source lines
		address [integer!]							;-- entry point of the funcion
		name	[integer!]							;-- function's name c-string offset (from first record)
		arity	[integer!]							;-- function's arity
		args	[integer!]							;-- array of arguments types pointer
	] none
	
	job-class: context [
		format: 									;-- 'PE | 'ELF | 'Mach-o
		type: 										;-- 'exe | 'obj | 'lib | 'dll | 'drv
		target:										;-- CPU identifier
		sections:									;-- code/data sections
		flags:										;-- global flags
		sub-system:									;-- target environment (GUI | console)
		symbols:									;-- symbols table
		output:										;-- output file name (without extension)
		debug-info:									;-- debugging informations
		base-address:								;-- base address
		static-objs:								;-- external C objects for static linking
		static-data:								;-- libc data-symbol imports [name offset size ...]
		ida-image-base:								;-- preferred image base for IDA names sidecar
		ida-func-map:								;-- [address name ...] function map for IDA names sidecar
		buffer: none								;-- output buffer
		static-align: 1								;-- peak alignment of merged static sections
	]
	
	throw-error: func [err [word! string! block!] /warn][
		print [
			"*** Linker" pick ["Warning:" "Error:"] to-logic warn
			either word? err [
				join uppercase/part mold err 1 " error"
			][reform err]
			lf
		]
		unless warn [system-dialect/compiler/quit-on-error]
	]
	
	set-ptr: func [job [object!] name [word!] value [integer!] /local spec][
		spec: find job/symbols name
		spec/<data>/2: value
	]
	
	set-integer-at: func [job [object!] pos [integer!] value [integer!] /local spec][
		change/part at job/sections/data/2 pos + 1 to-bin32 value 4
	]
	
	set-integer: func [job [object!] name [word!] value [integer!] /local spec][
		spec: find job/symbols name
		change/part at job/sections/data/2 spec/2/2 + 1 to-bin32 value 4
	]
	
	check-dup-symbols: func [job [object!] imports [block!] /local exports dup][
		all [
			exports: select job/sections 'export
			not empty? dup: intersect imports exports/3
			throw-error/warn [
				"possibly conflicting import and export symbols:" dup
			]
		]
	]
	
	set-image-info: func [
		job			 [object!]
		base-address [integer!]
		code-offset	 [integer!]
		code-size	 [integer!]
		data-offset	 [integer!]
		data-size	 [integer!]
		/local
			spec bits-offset
	][
		unless job/runtime? [exit]
		bits-offset: second second find job/symbols '***-ptr-bitmaps
		spec: find job/symbols '***-exec-image
		set-integer-at job spec/2/2 + 4  base-address	;-- + 4 => skip the struct pointer slot
		set-integer-at job spec/2/2 + 8  code-offset
		set-integer-at job spec/2/2 + 12 code-size
		set-integer-at job spec/2/2 + 16 data-offset
		set-integer-at job spec/2/2 + 20 data-size
		set-integer-at job spec/2/2 + 24 data-offset + bits-offset
	]
	
	resolve-symbol-refs: func [
		job 	 [object!] 
		cbuf 	 [binary!]							;-- code buffer
		dbuf 	 [binary!]							;-- data buffer
		code-ptr [integer!]							;-- code memory address
		data-ptr [integer!]							;-- data memory address
		pointer	 [object!]
		/local 
			data-offset ptr
	][
		data-offset: either job/PIC? [data-ptr - code-ptr][data-ptr]
		foreach [name spec] job/symbols [
			unless empty? spec/3 [
				all [
					any [
						all [
							spec/1 = 'global		;-- code to data references
							pointer/value: data-offset + spec/2
						]
						all [
							spec/1 = 'native-ref	;-- code to code references
							pointer/value: either job/PIC? [spec/2][code-ptr + spec/2]
						]
					]
					ptr: form-struct pointer
					parse spec/3 [any [ref: integer! (change at cbuf ref/1 ptr) | skip]]
				]
			]
			if block? spec/4 [
				pointer/value: either spec/1 = 'global [
					data-ptr + spec/2				;-- data to data references
				][
					either job/PIC? [spec/2 - 1][code-ptr + spec/2 - 1]	;-- data to code references
				]
				ptr: form-struct pointer
				foreach ref spec/4 [change at dbuf ref ptr]
			]
		]
	]
	
	get-debug-lines-size: func [job [object!] /local size][
		size: 12 * (length? job/debug-info/lines/records) / 3
		foreach file job/debug-info/lines/files [
			size: size + 1 + length? file			;-- file is supposed to be FORMed not MOLDed
		]
		size
	]
	
	build-debug-lines: func [
		job 	 [object!]
		code-ptr [integer!]							;-- code memory address
		/local	records files rec-size buffer table strings record data-buf spec
	][
		records: job/debug-info/lines/records
		files: job/debug-info/lines/files
		
		rec-size: 12 * (length? records) / 3 		;-- 12 = pointer! + integer! + integer!
											 		;--  3 = nb of elements in records (flat structure)
		buffer:  make binary! rec-size		 		;-- main buffer
		table:   make block! length? files	 		;-- intermediary file strings offsets table
		strings: make binary! 32 * length? files	;-- file strings buffer
		
		foreach file files [
			append table length? strings			;-- save file string offsets
			append strings form file
			append strings null
		]
		
		record: make-struct line-record! none
		forskip records 3 [
			record/ptr:  code-ptr + records/1 - 1
			record/line: records/2
			record/file: rec-size + pick table records/3	;-- store file offsets
			append buffer form-struct record
		]
		
		data-buf: job/sections/data/2
		set-ptr job '__debug-lines length? data-buf	;-- patch __debug-lines symbol to point to 1st record
		set-integer job '__debug-lines-nb (length? records) / 3
		
		repend data-buf [buffer strings]
	]
	
	undecorate: func [name [word!]][
		name: form name
		if find/match name "exec/" [name: skip name 5]
		if find/match name "f_" [name: skip name 2]
		name
	]
	
	is-native?: func [name [word! tag!] spec [block!]][
		all [spec/1 = 'native name <> '_div_]
	]
	
	get-debug-funcs-size: func [job [object!] /local size sc][
		sc: system-dialect/compiler
		size: 0
		foreach [name spec] job/symbols [
			if is-native? name spec [
				size: size + 1 + (length? undecorate name) 
					+ 16							;-- size of a record
					+ sc/get-arity sc/functions/:name/4
			]
		]
		size
	]
	
	build-debug-func-names: func [
		job 	 [object!]
		code-ptr [integer!]							;-- code memory address
		/local buffer specs args arity sc list rec-size record name-ptr args-ptr data-buf spec nb
	][
		sc: system-dialect/compiler
		list: make block! 4000
		
		foreach [name spec] job/symbols [
			if is-native? name spec [
				append list name
				append list spec/2
			]
		]
		nb:	(length? list) / 2
		rec-size: 16 * nb
		buffer:	make binary! rec-size		 		;-- main buffer
		specs:  make binary! rec-size + 10'000		;-- funcs name + args spec
		
		foreach [name entry-ptr] list [
			set [arity args] sc/get-args-array name
			name-ptr: rec-size + length? specs
			append specs undecorate name
			append specs null
			
			either arity > 0 [
				args-ptr: rec-size + length? specs
				append specs args
			][
				args-ptr: 0
			]
			if name = '***_start [args-ptr: -1]	;-- set a barrier for call stack reporting

			record: make-struct func-record! none
			record/address: code-ptr + entry-ptr - 1
			record/name:	name-ptr
			record/arity:	arity
			record/args:	args-ptr
			append buffer form-struct record
			if job/verbosity >= 3 [print [to-hex record/address #":" name]]
		]
		data-buf: job/sections/data/2
		set-ptr job '__debug-funcs length? data-buf		;-- patch __debug-funcs symbol to point to 1st record
		set-integer job '__debug-funcs-nb nb

		repend data-buf [buffer specs]
	]
	
	show-funcs-map: func [
		job 	 [object!]
		code-ptr [integer!]							;-- code memory address
		/local map
	][
		print "^/--- Functions entry points ---"
		map: collect-funcs-map job code-ptr
		foreach [address name] map [print [to-hex address #":" name]]
		print "--- end ---^/"
	]

	collect-funcs-map: func [
		job 	 [object!]
		code-ptr [integer!]							;-- code memory address
		/undecorated
		/local map label
	][
		map: make block! 4000
		foreach [name spec] job/symbols [
			if is-native? name spec [
				label: either undecorated [undecorate name][form name]
				repend map [code-ptr + spec/2 - 1 label]
			]
		]
		map
	]

	emit-funcs-map: func [
		job 	   [object!]
		code-ptr   [integer!]						;-- code memory address
		image-base [integer!]						;-- preferred image base
		/local map
	][
		if any [job/show-func-map? job/emit-ida-script?][
			map: collect-funcs-map job code-ptr
			print "^/--- Functions entry points ---"
			foreach [address name] map [print [to-hex address #":" name]]
			print "--- end ---^/"
		]
		if job/emit-ida-script? [
			map: collect-funcs-map/undecorated job code-ptr
			job/ida-image-base: image-base
			job/ida-func-map: map
		]
	]

	py-quote: func [value [string!] /local out ch][
		out: copy {"}
		foreach ch value [
			switch/default ch [
				#"\"  [append out {\\}]
				#"^"" [append out {\"}]
				#"^/" [append out {\n}]
				#"^M" [append out {\r}]
				#"^-" [append out {\t}]
			][
				either all [ch >= #" " ch <= #"~"] [
					append out ch
				][
					append out #"_"
				]
			]
		]
		append out {"}
	]

	write-ida-script: func [
		job  [object!]
		file [file!]
		/local script pos out rva
	][
		unless job/emit-ida-script? [exit]
		unless all [integer? job/ida-image-base block? job/ida-func-map][
			throw-error "--emit-ida-script is not supported by this target"
		]

		script: copy file
		if pos: find/reverse tail script #"." [clear pos]
		append script %.ida.py

		out: make string! 8192
		append out {# Generated by Red/System --emit-ida-script.
try:
    import idaapi
except Exception:
    idaapi = None
try:
    import ida_name
except Exception:
    ida_name = None
try:
    import ida_bytes
except Exception:
    ida_bytes = None
try:
    import idc
except Exception:
    idc = None

}
		repend out ["PREFERRED_BASE = 0x" to-hex job/ida-image-base "^/"]
		append out "NAMES = [^/"
		foreach [address name] job/ida-func-map [
			rva: address - job/ida-image-base
			repend out [
				"    (0x" to-hex rva ", 0x" to-hex address ", "
				py-quote name "),^/"
			]
		]
		append out {]

def current_imagebase():
    if idaapi is not None:
        try:
            return idaapi.get_imagebase()
        except Exception:
            pass
    return PREFERRED_BASE

def has_segment(ea):
    if idaapi is not None and hasattr(idaapi, "getseg"):
        try:
            return idaapi.getseg(ea) is not None
        except Exception:
            pass
    if idc is not None and hasattr(idc, "get_segm_start"):
        try:
            badaddr = getattr(idc, "BADADDR", -1)
            return idc.get_segm_start(ea) != badaddr
        except Exception:
            pass
    return True

def resolve_ea(rva, preferred):
    if has_segment(preferred):
        return preferred
    ea = current_imagebase() + rva
    if has_segment(ea):
        return ea
    return ea

def safe_name(name, used):
    chars = []
    for ch in name:
        if ch.isalnum() or ch == "_":
            chars.append(ch)
        else:
            chars.append("_")
    base = "".join(chars)
    if not base.strip("_"):
        base = "red"
    if base[0].isdigit():
        base = "red_" + base
    candidate = base
    suffix = 2
    while candidate in used:
        candidate = "%s_%d" % (base, suffix)
        suffix += 1
    used.add(candidate)
    return candidate

def set_name_at(ea, name):
    if ida_name is not None:
        flags = getattr(ida_name, "SN_FORCE", 0) | getattr(ida_name, "SN_NOWARN", 0)
        try:
            if ida_name.set_name(ea, name, flags):
                return True
        except Exception:
            pass
    if idc is not None and hasattr(idc, "set_name"):
        try:
            return bool(idc.set_name(ea, name, 0))
        except Exception:
            pass
    return False

def set_comment(ea, text):
    if ida_bytes is not None:
        try:
            ida_bytes.set_cmt(ea, text, 0)
            return
        except Exception:
            pass
    if idc is not None and hasattr(idc, "set_cmt"):
        try:
            idc.set_cmt(ea, text, 0)
        except Exception:
            pass

used = set()
applied = 0
for rva, preferred, original in NAMES:
    ea = resolve_ea(rva, preferred)
    label = safe_name(original, used)
    if set_name_at(ea, label):
        set_comment(ea, "Red/System name: " + original)
        applied += 1

print("Applied %d Red/System function names." % applied)
}
		write script out
		if verbose >= 1 [print ["IDA script:" script]]
	]
	
	clean-imports: func [imports [block!]][			;-- remove unused imports
		foreach [lib list] imports/3 [
			remove-each [name refs] list [empty? refs]
		]
	]

	make-filename: func [job [object!] /local base provided suffix][
		provided: suffix? base: job/build-basename
		suffix: any [
			job/build-suffix
			select file-emitter/defs/extensions job/type
		]
		if any [none? suffix suffix <> provided][
			base: join base suffix
		]
		join any [job/build-prefix %""] base
	]
	
	build: func [job [object!] /local file fun][
		unless job/target [job/target: cpu-class]
		job/buffer: make binary! 512 * 1024
	
		static-link/merge job						;-- merge statically-linked external C objects

		clean-imports job/sections/import
	
		file-emitter: either encap? [
			do-cache rejoin [%system/formats/ job/format %.r]
		][
			do rejoin [%formats/ job/format %.r]
		]
		file-emitter/build job

		file: make-filename job
		if verbose >= 1 [print ["output file:" file]]
		
		if error? try [write/binary/direct file job/buffer][
			throw-error ["locked or unreachable file:" to-local-file file]
		]
		
		;-- must run before on-file-written hooks that move/delete the output file
		write-ida-script job file

		if fun: in file-emitter 'on-file-written [
			do reduce [get fun job file]
		]
		
		if find get-modes file 'file-modes 'owner-execute [
			set-modes file [owner-execute: true]
		]
		file
	]

]
