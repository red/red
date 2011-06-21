REBOL [
	Title:   "Red/System linker"
	Author:  "Nenad Rakocevic"
	File: 	 %linker.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

linker: context [
	version: 		1.0.0					;-- emitted linker version
	cpu-class: 		'IA32					;-- default target
	file-emitter:	none					;-- file emitter object
	verbose: 		0						;-- logs verbosity level
		
	job-class: context [
		format: 				;-- 'PE | 'ELF | 'Mach-o
		type: 					;-- 'exe | 'obj | 'lib | 'dll
		target:					;-- CPU identifier
		sections:				;-- code/data sections
		flags:					;-- global flags
		sub-system:				;-- target environment (GUI | console)
		symbols:				;-- symbols table
		output:					;-- output file name (without extension)
		buffer: none
	]
	
	resolve-symbol-refs: func [
		job [object!] 
		cbuf [binary!]						;-- code buffer
		dbuf [binary!]						;-- data buffer
		code-ptr [integer!]					;-- code memory address
		data-ptr [integer!]					;-- data memory address
		pointer [struct! [v [integer!]]]
	][
		foreach [name spec] job/symbols [
			unless empty? spec/3 [
				switch spec/1 [
					global [				;-- code to data references
						pointer/value: data-ptr + spec/2
						foreach ref spec/3 [change at cbuf ref third pointer]
					]
					native-ref [			;-- code to code references
						pointer/value: code-ptr + spec/2
						foreach ref spec/3 [change at cbuf ref third pointer]
					]
				]
			]
			if all [	
				spec/1 = 'global
				block? spec/4
			][								;-- data to data references
				pointer/value: data-ptr + spec/2			
				foreach ref spec/4 [change at dbuf ref third pointer]
			]
		]
	]
	
	remove-unused-imports: func [imports [block!]][
		foreach [lib list] imports/3 [
			remove-each [name refs] list [empty? refs]
		]
	]

	make-filename: func [job [object!]][
		rejoin [
			any [job/build-prefix %""]
			job/build-basename
			any [job/build-suffix select file-emitter/defs/extensions job/type]
		]
	]
	
	build: func [job [object!] /local file][
		unless job/target [job/target: cpu-class]
		job/buffer: make binary! 100 * 1024
	
		remove-unused-imports job/sections/import
	
		file-emitter: do rejoin [%formats/ job/format %.r]
		file-emitter/build job

		file: make-filename job
		if verbose >= 1 [print ["output file:" file]]
		write/binary file job/buffer
		
		if find get-modes file 'file-modes 'owner-execute [
			set-modes file [owner-execute: true]
		]
	]

]
