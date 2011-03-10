REBOL [
	Title:   "Red/System linker"
	Author:  "Nenad Rakocevic"
	File: 	 %linker.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

linker: context [
	verbose: 0					;-- logs verbosity level
	version: 1.0.0
	cpu-class: 'IA32			;-- default target
	
	job-class: context [
		format: 				;-- 'PE | 'ELF | 'Mach-o
		type: 					;-- 'exe | 'obj | 'lib | 'dll
		target:					;-- CPU identifier
		sections:				;-- code/data sections
		flags:					;-- global flags
		sub-system:				;-- target environment (GUI | console)
		symbols:				;-- symbols table
		buffer: none
	]
	
	PE:		 do %formats/PE.r
	;ELF:	 do %formats/ELF.r				; TBD
	;Mach-o: do %formats/mach-o.r			; TBD

	make-filename: func [job /local obj][
		obj: get in self job/format
		join job/output select obj/defs/extensions job/type
	]
	
	build: func [job [object!] /in path /local file][
		unless job/target [job/target: cpu-class]
		job/buffer: make binary! 100 * 1024
		
		switch job/format [
			PE     [PE/build 	 job]
			ELF    [ELF/build 	 job]
			Mach-o [Mach-o/build job]
		]
		file: make-filename job
		if in [file: path/:file]

		if verbose >= 1 [print ["output file:" file]]	
		write/binary file job/buffer
	]

]