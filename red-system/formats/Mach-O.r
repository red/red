REBOL [
	Title:	 "Red/System Mach-O format emitter"
	Author:  "Nenad Rakocevic"
	File:	 %Mach-O.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; Reference doc: http://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/MachORuntime/Reference/reference.html

context [
	defs: compose [
		extensions [
			exe %""
			obj %.o
			lib %.a
			dll %.dylib
		]

		base-address	0
		page-size		4096		;-- target-dependent
		
		file-type [					;-- Constants for the filetype field of the mach_header
			object   		1     	; relocatable object file
			execute  		2     	; demand paged executable file
			fvmlib   		3		; fixed VM shared library file
			core     		4		; core file
			preload  		5		; preloaded executable file
			dylib    		6		; dynamically bound shared library
			dylinker 		7		; dynamic link editor
			bundle   		8		; dynamically bound bundle file
			dylib_stub  	9		; shared library stub for static
		]
		flags [					 	;-- Constants for the flags field of the mach_header
			noundefs 		1     	; no undefined references
			incrlink 	 	2     	; output of an incremental link against a base file
			dyldlink 	 	4     	; input for the dynamic linker
			bindatload   	8    	; undefined references are bound by the dynamic linker when loaded
			prebound 	 	16      ; dynamic undefined references prebound
			split_segs   	32      ; read-only and read-write segments split
			lazy_init    	64      ; (obsolete) shared library init routine run lazily
			twolevel 	 	128     ; the image is using two-level name space bindings
			force_flat   	256     ; forcing all images to use flat name space bindings
			nomultidefs  	512     ; no multiple defintions of symbols in its sub-images
			nofixprebinding	1024    ; do not have dyld notify the prebinding agent about this executable
			prebindable  	2048    ; not prebound but can have its prebinding redone
			allmodsbound 	4096    ; binds to all two-level namespace modules of its dependent libraries
			canonical    	8192    ; canonicalized via the unprebind operation
		]
		load-type [					;-- Constants for the cmd field of all load commands
			req_dyld 		-2147483648
			segment 		1 		; segment of this file to be mapped
			symtab   		2 		; link-edit stab symbol table info
			symseg   		3 		; link-edit gdb symbol table info (obsolete)
			thread   		4 		; thread
			unixthread   	5 		; unix thread (includes a stack)
			loadfvmlib   	6 		; load a specified fixed VM shared library
			idfvmlib 		7 		; fixed VM shared library identification
			ident    		8 		; (obsolete) object identification info 
			fvmfile  		9 		; (internal use) fixed VM file inclusion
			prepage      	10     	; (internal use) prepage command
			dysymtab 		11 		; dynamic link-edit symbol table info
			load_dylib   	12 		; load a dynamically linked shared library
			id_dylib 		13 		; dynamically linked shared lib ident
			load_dylinker 	14    	; load a dynamic linker
			id_dylinker  	15 		; dynamic linker identification
			prebound_dylib 	16  	; modules prebound for a dynamically linked shared library
			routines 		17    	; image routines
			sub_framework 	18   	; sub framework
			sub_umbrella 	19    	; sub umbrella
			sub_client   	20   	; sub client
			sub_library  	21    	; sub library
			twolevel_hints 	22  	; two-level namespace lookup hints
			prebind_cksum  	23  	; prebind checksum
			uuid			27
			load_weak_dylib -2147483624	; (0x18 | REQ_DYLD)
		]
		rights [
			none			0
			read			1
			write			2
			execute			4
		]
		sect-type [								 ;-- Constants for the type of a section
			regular       			 #{00000000} ; regular section
			zerofill     	 	 	 #{00000001} ; zero fill on demand section
			cstring_literals  		 #{00000002} ; section with only literal C strings
			_4byte_literals    		 #{00000003} ; section with only 4 byte literals
			_8byte_literals    		 #{00000004} ; section with only 8 byte literals
			literal_pointers  		 #{00000005} ; section with only pointers to
			non_lazy_symbol_pointers #{00000006} ; section with only non-lazy
			lazy_symbol_pointers     #{00000007} ; section with only lazy symbol
			symbol_stubs        	 #{00000008} ; section with only symbol
			mod_init_func_pointers   #{00000009} ; section with only function
			mod_term_func_pointers   #{0000000a} ; section with only function
			coalesced        		 #{0000000b} ; section contains symbols that
			section_attributes_usr   #{ff000000} ; User setable attributes
			attr_pure_instructions 	 #{80000000} ; section contains only true
			attr_no_toc        	  	 #{40000000} ; section contains coalesced
			attr_strip_static_syms   #{20000000} ; ok to strip static symbols
			section_attributes_sys   #{00ffff00} ; system setable attributes
			attr_some_instructions   #{00000400} ; section contains some machine instructions
			attr_ext_reloc     		 #{00000200} ; section has external relocation entries
			attr_loc_reloc     		 #{00000100} ; section has local relocation entries
		]
	]

	;; Mach-O Structures

	mach-header: make-struct [
		magic			[integer!]	;; 0xfeedface
		cpu-type		[integer!]	;; CPU_TYPE_I386 = 7
		cpu-sub-type	[integer!]	;; CPU_SUBTYPE_I386_ALL = 3
		file-type		[integer!]
		nb-cmds			[integer!]	;; number of load commands
		sz-cmds			[integer!]
		flags			[integer!]
	] none
		
	segment-command: make-struct [
		cmd				[integer!]	; load-type/segment
		size			[integer!]	; sizeof(segment_command + (sizeof(section) * segment->nsect))
		segname1		[decimal!]	; char segname[16]
		segname2		[decimal!]
		vmaddr			[integer!]	; starting virtual memory address of this segment
		vmsize			[integer!]	; number of bytes of virtual memory occupied by this segment
		fileoff			[integer!]	; offset in this file of the data to be mapped at vmaddr
		filesize		[integer!]	; number of bytes occupied by this segment on disk
		maxprot			[integer!]	; maximum permitted virtual memory protections of this segment
		initprot		[integer!]	; initial virtual memory protections of this segment
		nsects			[integer!]  ; number of section data structures following this load command
		flags			[integer!]	;
	] none
	
	unix-thread-cmd: make-struct [
		cmd				[integer!]	; load-type/segment
		size			[integer!]	; sizeof(segment_command + (sizeof(section) * segment->nsect))
		flavor			[integer!]	; x86_THREAD_STATE32 = 1
		count			[integer!]	; nb of thread state 32-bit entries (16)
		eax				[integer!]
		ebx				[integer!]
		ecx				[integer!]
		edx				[integer!]
		edi				[integer!]
		esi				[integer!]
		ebp				[integer!]
		esp				[integer!]
		ss				[integer!]
		eflags			[integer!]
		eip				[integer!]
		cs				[integer!]
		ds				[integer!]
		es				[integer!]
		fs				[integer!]
		gs				[integer!]
	] none
	
	dylinker-cmd: make-struct [
		cmd				[integer!]	; load-type/segment
		size			[integer!]	; sizeof(segment_command + (sizeof(section) * segment->nsect))
		offset			[integer!]	; = 12 (from the start of the load cmd)
		name1			[decimal!]	; /usr/lib/dylib\0
		name2			[decimal!]
	] none
	
	section-header: make-struct [
		sectname1		[decimal!]	; char sectname[16]
		sectname2		[decimal!]
		segname1		[decimal!]	; char segname[16]
		segname2		[decimal!]
		addr			[integer!]	; virtual memory address of this section
		size			[integer!]	; size in bytes of the virtual memory occupied by this section
		offset			[integer!]	; offset to this section in the file
		align			[integer!]	; section’s byte alignment as power of two
		reloff			[integer!]	; file offset of the first relocation entry for this section.
		nreloc			[integer!]	; number of relocation entries located at reloff for this section.
		flags			[integer!]
		reserved1		[integer!]
		reserved2		[integer!]
	] none
	
	pointer: make-struct [
		value [integer!]			;-- 32/64-bit, watch out for endianess!!
	] none

	;-- Globals --
	
	segments: [
	;-- class ------ name ------ mem --- file - rights - payload - memalign
	;						   - off sz  off sz	-
	  segment		__PAGEZERO   0	page 0 	 0	[]		  - 	   page []
	  segment 		__TEXT	 	 ?	 ? 	 ?	 ?	[r x]	  -		   page [
		section		__text	 	 ?	 ?	 ?	 ?	 -		  code	   word
	  ]
	  segment 		__DATA	 	 ?	 ?	 ?	 ?	[r w]	  -		   page [
		section		__data	 	 ?	 ?	 ?	 ?	 -		  data	   word
	  ]
;	  dylinker		-			 -	 -   -	 -   - 		  -		   -	[]
	  uthread		-			 -	 -   -	 -   - 		  -		   -	[]
	]
	
	segment-sz:			length? form-struct segment-command
	section-sz:			length? form-struct section-header
	load-cmds-nb:		0
	load-cmds-sz:		0

	;-- Mach-O structure builders --
	
	to-c-string: func [value][join value null]
	
	get-ceiling: func [type [word!]][
		switch/default type [
			page [defs/page-size]
			word [4]						;-- 4 => 32-bit, 8 => 64-bit @@
		][4]								;-- 4 => 32-bit, 8 => 64-bit @@								
	]
	
	sections?: func [list [block!]][(length? list) / 9]
	
	get-struct-size: func [type [word!]][
		switch type [
			segment  [segment-sz]
			uthread  [length? form-struct unix-thread-cmd]
			dylinker [length? form-struct dylinker-cmd]
		]
	]
	
	get-rights?: func [spec [block!] /local flags][
		flags: 0
		foreach flag spec [
			flags: flags + defs/rights/(select [r read w write x execute] flag)
		]
		flags
	]
	
	get-flags: func [type [word!]][
		to integer! switch/default type [
			code [
				defs/sect-type/attr_pure_instructions
				or defs/sect-type/attr_some_instructions
			]
		][defs/sect-type/regular]
	]
	
	get-section-addr: func [name [word!] /local addr][
		parse segments [some [into [thru name set addr skip | none] | skip]]	
		addr
	]
		
	prepare-headers: func [
		job [object!]
		/local seg sec addr fpos get-value size sz header-sz hd-sz
	][
		get-value: func [n value][
			switch/default seg/:n [? [value] page [defs/page-size]][seg/:n]
		]
		
		load-cmds-sz: 0
		seg: segments
		until [
			load-cmds-sz: load-cmds-sz + get-struct-size seg/1
			load-cmds-nb: load-cmds-nb + 1
			unless empty? seg/10 [
				load-cmds-sz: load-cmds-sz + (section-sz * sections? seg/10)
			]
			tail? seg: skip seg 10
		]
		
		header-sz: load-cmds-sz + length? form-struct mach-header
		addr: 0
		fpos: header-sz
		
		seg: segments
		until [
			if seg/1 = 'segment [
				hd-sz: either seg/2 = '__TEXT [header-sz][0]	;-- account for headers
				seg/3: addr: round/ceiling/to get-value 3 addr get-ceiling seg/9 ;-- offset in memory (segment)
				seg/5: fpos: round/ceiling/to get-value 5 fpos get-ceiling seg/9 ;-- offset in file (segment)
				sec: seg/10
				size: 0
				while [not tail? sec][			
					sz: length? job/sections/(sec/8)/2
					sec/3: addr: hd-sz + round/ceiling/to addr get-ceiling sec/9 ;-- offset in memory (section)
					sec/4: sz							;-- size in memory (section)
					sec/5: fpos: round/ceiling/to fpos + hd-sz get-ceiling sec/9 ;-- offset in file (section)
					sec/6: sz							;-- size in file (section)
					size:  size + sz + hd-sz
					addr:  addr + sz
					fpos:  fpos + sz
					sec: skip sec 9
				]
				size: round/ceiling/to size defs/page-size
				seg/4: get-value 4 size 				;-- size in memory (segment)
				seg/6: get-value 6 size					;-- size in file (segment)
				if zero? size [
					addr:  addr + seg/4
					fpos:  fpos + seg/6
				]
			]
			tail? seg: skip seg 10
		]	
	]
	
	resolve-data-refs: func [job [object!] /local cbuf dbuf data code][
		cbuf: job/sections/code/2
		dbuf: job/sections/data/2
		forskip segments 10 [
			switch segments/2 [
				__TEXT [code: segments/3]
				__DATA [data: segments/3]
			]
		]
		linker/resolve-symbol-refs job cbuf dbuf code data pointer
	]
	
	build-dylinker-command: func [spec [block!] /local dl][
		dl: make-struct dylinker-cmd none
		dl/cmd:			defs/load-type/load_dylinker
		dl/size:		get-struct-size 'dylinker
		dl/offset:		12
		dl: form-struct dl
		change at dl 13 join "/usr/lib/dyld" null	
		dl
	]
	
	build-uthread-command: func [spec [block!] /local ut][
		ut: make-struct unix-thread-cmd none
		ut/cmd:			defs/load-type/unixthread
		ut/size:		get-struct-size 'uthread
		ut/flavor:		1							;-- x86_THREAD_STATE32
		ut/count:		16
		ut/eip:			get-section-addr '__text
		form-struct ut
	]
	
	build-section-header: func [spec [block!] seg-name [word!] /local sh][
		sh: make-struct section-header none
		sh/addr:		spec/3
		sh/size:		spec/6
		sh/offset:		spec/5
		sh/align:		to integer! log-2 select [byte 1 word 4 dword 8] spec/9	;-- 32/64-bit @@
		sh/reloff:		0
		sh/nreloc:		0
		sh/flags:		get-flags spec/8
		sh/reserved1:	0
		sh/reserved2:	0
		sh: form-struct sh
		change sh to-c-string spec/2
		change at sh 17 to-c-string seg-name
		sh
	]
	
	build-segment-command: func [spec [block!] /local sc][
		sc: make-struct segment-command none
		sc/cmd:			defs/load-type/segment
		sc/size:		segment-sz + (section-sz * sections? spec/10)
		sc/vmaddr:		spec/3
		sc/vmsize:		spec/4
		sc/fileoff:		spec/5
		sc/filesize:	spec/6
		sc/maxprot:		either empty? spec/7 [0][get-rights? [r w x]]
		sc/initprot:	get-rights? spec/7
		sc/nsects:		sections? spec/10
		sc: form-struct sc
		change at sc 9 to-c-string spec/2
		sc
	]
		
	build-mach-header: has [mh][
		mh: make-struct mach-header none
		mh/magic:			to integer! #{FEEDFACE}
		mh/cpu-type:		7					;-- CPU_TYPE_I386
		mh/cpu-sub-type:	3					;-- CPU_SUBTYPE_I386_ALL
		mh/file-type:		defs/file-type/execute
		mh/nb-cmds:			load-cmds-nb
		mh/sz-cmds:			load-cmds-sz
		mh/flags:			defs/flags/noundefs
		form-struct mh
	]

	build: func [
		job [object!]
		/local
			base-address dynamic-linker out sections

	] [
		base-address: any [job/base-address defs/base-address]
		dynamic-linker: any [job/dynamic-linker ""]
		
		prepare-headers job
		
		out: job/buffer
		append out build-mach-header
		seg: segments
		forskip seg 10 [
			append out switch seg/1 [
				segment  [build-segment-command seg]
				uthread  [build-uthread-command seg]
				dylinker [build-dylinker-command seg]
			]
			unless empty? sections: seg/10 [
				forskip sections 9 [
					append out build-section-header sections seg/2
				]
			]
		]
		
		resolve-data-refs job
		append out job/sections/code/2
		
		page: defs/page-size
		insert/dup tail out null page - ((length? out) // page)		;@@ temporary
		
		append out job/sections/data/2
		insert/dup tail out null page - ((length? out) // page)		;@@ temporary	
	]
]