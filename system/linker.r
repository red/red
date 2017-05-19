REBOL [
	Title:   "Red/System linker"
	Author:  "Nenad Rakocevic"
	File: 	 %linker.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
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
		buffer: none								;-- output buffer
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
	
	resolve-symbol-refs: func [
		job 	 [object!] 
		cbuf 	 [binary!]							;-- code buffer
		dbuf 	 [binary!]							;-- data buffer
		code-ptr [integer!]							;-- code memory address
		data-ptr [integer!]							;-- data memory address
		pointer	 [object!]
		/local 
			data-offset
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
					foreach ref spec/3 [
						if integer? ref [change at cbuf ref form-struct pointer]
					]
				]
			]
			if all [	
				spec/1 = 'global
				block? spec/4
			][										;-- data to data references
				pointer/value: data-ptr + spec/2			
				foreach ref spec/4 [change at dbuf ref form-struct pointer]
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
		
		if fun: in file-emitter 'on-file-written [
			do reduce [get fun job file]
		]
		
		if find get-modes file 'file-modes 'owner-execute [
			set-modes file [owner-execute: true]
		]
		file
	]

]
