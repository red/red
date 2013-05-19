REBOL [
	Title:   "Red/System PE/COFF format emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %PE.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

context [
	defs: [
		image [
			base-address	#{00400000}
			MSDOS-header #{
				4D5A800001000000 04001000FFFF0000
				4001000000000000 4000000000000000
				0000000000000000 0000000000000000
				0000000000000000 0000000080000000
				0E1FBA0E00B409CD 21B8014CCD215468
				69732070726F6772 616D2063616E6E6F
				742062652072756E 20696E20444F5320
				6D6F64652E0D0D0A 2400000000000000
			}
		]
		extensions [
			exe %.exe
			obj %.obj
			lib %.lib
			dll %.dll
		]
		machine [
		;--  CPU -------- ID ------ Endianness
			unknown		#{0000}			?
			AM33		#{01D3}			?
			AMD64		#{8664}			little
			ARM			#{01C0}			little
			ARMV7		#{01C4}			?		
			EBC			#{0EBC}			?
			IA-32		#{014C}			little
			IA-64		#{0200}			little
			M32R		#{9041}			little
			MIPS16		#{0266}			?
			MIPSFPU		#{0366}			?
			MIPSFPU16	#{0466}			?
			POWERPC		#{01F0}			little
			POWERPCFP	#{01F1}			?
			R4000		#{0166}			?
			SH3			#{01A2}			?
			SH3DSP		#{01A3}			?
			SH4			#{01A6}			?
			SH5			#{01A8}			?
			THUMB		#{01C2}			?
			WCEMIPSV2	#{0169}			little
		]
		c-flags [
			relocs-stripped			#{0001}	;-- (Image) file does not contain base relocations
			executable-image		#{0002}	;-- (Image) image file can be run
			line-nums-stripped		#{0004}	;-- (DEPRECATED) removed COFF line numbers
			local-syms-stripped		#{0008}	;-- (DEPRECATED) COFF symbol table entries removed
			aggressive-ws-trim		#{0010}	;-- (OBSOLETE)
			large-address-aware		#{0020}	;-- application can handle > 2 GB addresses
			reserved				#{0040}
			bytes-reversed-lo		#{0080}	;-- (DEPRECATED) little endian
			machine-32bit			#{0100}	;-- machine is based on a 32-bit-word architecture
			debug-stripped			#{0200}	;-- debugging information is removed 
			removable-run-from-swap	#{0400}	;-- if image on removable media, load it and copy it to the swap file
			net-run-from-swap		#{0800}	;-- if image on network media, load it and copy it to the swap file
			system					#{1000}	;-- image file is a system file, not a user program.
			dll						#{2000}	;-- image file is a dynamic-link library 
			up-system-only			#{4000}	;-- image file should be run only on a uniprocessor machine.
			bytes-reversed-hi		#{8000}	;-- (DEPRECATED) big endian

		]
		s-flags [
			type-no-pad			#{00000008}	;-- (OBJ) (Obsolete) should not be padded to the next boundary
			code				#{00000020}	;-- executable code
			initialized			#{00000040}	;-- initialized data
			uninitialized		#{00000080}	;-- uninitialized data
			link-other			#{00000100}	;-- reserved for future use
			link-info			#{00000200}	;-- (OBJ) contains comments or other information
			link-remove			#{00000800}	;-- (OBJ) section will not become part of the image
			link-comdat			#{00001000}	;-- (OBJ) comdat data
			gptr-rel			#{00008000}	;-- contains data referenced through the global pointer (gp)
			purgeable			#{00020000}	;-- reserved for future use
			mem-16bit			#{00020000}	;-- for ARM machine types, the section contains thumb code
			locked				#{00040000}	;-- reserved for future use
			preload				#{00080000}	;-- reserved for future use
			align [							;-- data alignment
				1				#{00100000}
				2				#{00200000}
				4				#{00300000}
				8				#{00400000}
				16				#{00500000}
				32				#{00600000}
				64				#{00700000}
				128				#{00800000}
				256				#{00900000}
				512				#{00a00000}
				1024			#{00b00000}
				2048			#{00c00000}
				4096			#{00d00000}
				8192			#{00e00000}
			]
			link-nreloc-ovfl	#{01000000}	;-- extended relocations
			discardable			#{02000000}	;-- can be discarded as needed
			not-cached			#{04000000}	;-- cannot be cached
			not-paged			#{08000000}	;-- not pageable
			shared				#{10000000}	;-- can be shared in memory
			execute				#{20000000}	;-- can be executed as code
			read				#{40000000}	;-- can be read
			write				#{80000000}	;-- can be written to
		]
		s-type [
			BSS					#{C0000080}	;-- [read write uninitialized]
			data				#{C0000040}	;-- [read write initialized]
			export				#{40000040}	;-- [read initialized]
			import				#{C0000040}	;-- [read write initialized]
			except				#{40000040}	;-- [read initialized]
			rsrc				#{40000040}	;-- [read initialized]
			code				#{60000020}	;-- [read code execute]
		]
		sub-system [
			unknown				0			;-- unknown subsystem
			driver				1			;-- device drivers and native Windows processes
			GUI					2			;-- Windows GUI
			console				3			;-- Windows character subsystem
			POSIX				7			;-- Posix character subsystem
			CE					9			;-- Windows CE
			EFI-app				10			;-- EFI application
			EFI-boot			11			;-- EFI driver with boot services
			EFI-runtime			12			;-- EFI driver with run-time services
			EFI-ROM				13			;-- EFI ROM image
			XBOX				14			;-- XBOX (great! :-))
		]
		dll-flags [
			dynamic-base		#{0040}		;-- dll can be relocated at load time
			force-integrity		#{0080}		;-- code integrity checks are enforced
			nx-compat			#{0100}		;-- image is nx compatible
			no-isolation		#{0200}		;-- isolation aware, but do not isolate the image
			no-seh				#{0400}		;-- does not use structured exception handling
			no-bind				#{0800}		;-- do not bind the image
			wdm-driver			#{2000}		;-- a wdm driver
			TS-aware			#{8000}		;-- Terminal Server aware
		]
	]

	file-header: make-struct [
		machine				[short]
		sections-nb			[short]
		timestamp			[integer!]		;-- file creation timestamp
		symbols-ptr			[integer!]		;-- OBJ only
		symbols-nb			[integer!]		;-- OBJ only
		opt-headers-size	[short]			;-- zero for OBJ
		flags				[short]			
	] none

	optional-header: make-struct [			;-- optional header for image only
		magic				[short]			;-- different for 32/64-bit
		major-link-version	[char]
		minor-link-version	[char]
		code-size			[integer!]
		initdata-size		[integer!]
		uninitdata-size		[integer!]
		entry-point-addr	[integer!]
		code-base			[integer!]
		data-base			[integer!]		;-- 32-bit only (remove field for 64-bit)
		image-base			[integer!]		;-- 8 bytes for 64-bit
		memory-align		[integer!]
		file-align			[integer!]
		major-OS-version	[short]			;-- should be 4.0
		minor-OS-version	[short]
		major-img-version	[short]
		minor-img-version	[short]
		major-sub-version	[short]
		minor-sub-version	[short]
		win32-ver-value		[integer!]		;-- reserved, must be zero
		image-size			[integer!]
		headers-size		[integer!]
		checksum			[integer!]		;-- for drivers and DLL only
		sub-system			[short]
		dll-flags			[short]			;-- DLL only
		stack-res-size		[integer!]		;-- 8 bytes for 64-bit
		stack-com-size		[integer!]		;-- 8 bytes for 64-bit
		heap-res-size		[integer!]		;-- 8 bytes for 64-bit
		heap-com-size		[integer!]		;-- 8 bytes for 64-bit
		loader-flags		[integer!]		;-- reserved, must be zero
		data-dir-nb			[integer!]
		;-- Data Directory
		export-addr			[integer!]
		export-size			[integer!]
		import-addr			[integer!]
		import-size			[integer!]
		rsrc-addr			[integer!]
		rsrc-size			[integer!]
		except-addr			[integer!]
		except-size			[integer!]
		cert-addr			[integer!]
		cert-size			[integer!]
		reloc-addr			[integer!]
		reloc-size			[integer!]
		debug-addr			[integer!]
		debug-size			[integer!]
		arch-addr			[integer!]		;-- reserved, must be zero
		arch-size			[integer!]		;-- reserved, must be zero
		gptr-addr			[integer!]
		gptr-size			[integer!]
		TLS-addr			[integer!]
		TLS-size			[integer!]
		config-addr			[integer!]
		config-size			[integer!]
		b-import-addr		[integer!]
		b-import-size		[integer!]
		IAT-addr			[integer!]
		IAT-size			[integer!]
		d-import-addr		[integer!]
		d-import-size		[integer!]
		CLR-addr			[integer!]
		CLR-size			[integer!]
		reserved			[integer!]		;-- reserved, must be zero
		reserved2			[integer!]		;-- reserved, must be zero
	] none

	section-header: make-struct [
		name				[decimal!]		;-- placeholder for an 8 bytes string
		virtual-size		[integer!]
		virtual-address		[integer!]
		raw-data-size		[integer!]
		raw-data-ptr		[integer!]
		relocations-ptr		[integer!]
		line-num-ptr		[integer!]
		relocations-nb		[short]
		line-num-nb			[short]
		flags				[integer!]
	] none

	import-directory: make-struct [
		ILT-rva				[integer!]		;-- lookup table RVA
		timestamp			[integer!]
		chain				[integer!]
		name-rva			[integer!]
		IAT-rva				[integer!]		;-- address table RVA
	] none

	ILT: make-struct [
		rva	[integer!]						;-- 32/64-bit
	] none

	pointer: make-struct [
		value [integer!]					;-- 32/64-bit, watch out for endianess!!
	] none

	memory-align:		4096				;-- system page size
	file-align: 		512					;-- better keep it < memory-align
	sect-header-size: 	40
	ILT-size:			4					;-- Import Lookup Table size (8 for 64-bit)
	pointer-size:		4					;-- Pointer size (8 for 64-bit)
	imports-refs:		make block! 10		;-- [ptr [DLL imports] ...]
	initdata-size:      0
	uninitdata-size:    0
	opt-header-size:	length? form-struct optional-header
	opt-header:         none
	
	get-timestamp: has [n t][
		n: now
		t: n/time
		(n - 01/01/1970 * 24 * 3600)
			+ (t/hour * 3600)
			+ (t/minute * 60)
			+ to integer! t/second
	]

	pad-size?: func [buffer [binary!] /local rem][
		either zero? rem: (length? buffer) // file-align [
			0
		][
			file-align - rem
		]
	]

	entry-point-page?: func [job [object!] /memory /local ptr][
		ptr: (length? job/buffer) + opt-header-size
		foreach [name spec] job/sections [
			ptr: ptr + sect-header-size
		]
		round/ceiling ptr / either memory [memory-align][file-align]
	]
	
	entry-point-address?: func [job [object!]][
		(section-addr?/memory job 'code) + to integer! defs/image/base-address
	]

	image-size?: func [job [object!] /local pages][
		pages: entry-point-page?/memory job
		foreach [name section] job/sections [
			pages: pages + round/ceiling (length? section/2)  / memory-align
		]
		pages * memory-align
	]

	import-addr?: func [job [object!] /local pages][
		pages: entry-point-page?/memory job
		foreach [name section] job/sections [
			if name = 'import [
				return pages * memory-align
			]
			pages: pages + round/ceiling (length? section/2)  / memory-align	
		]
		make error! "import section not found!"
	]

	section-addr?: func [job [object!] s-name [word!] /file /memory /local pages align][
		pages: either file [entry-point-page? job][entry-point-page?/memory job]
		align: either file [file-align][memory-align]
		foreach [name section] job/sections [
			if name = s-name [
				return pages * align
			]
			pages: pages + round/ceiling (length? section/2) / align	
		]
		make error! reform [mold s-name "section not found!"]
	]

	resolve-data-refs: func [job [object!] /local cbuf dbuf data code][
		cbuf: job/sections/code/2
		dbuf: job/sections/data/2
		data: (section-addr?/memory job 'data) + to integer! defs/image/base-address
		code: entry-point-address? job

		linker/resolve-symbol-refs job cbuf dbuf code data pointer
	]

	resolve-import-refs: func [job [object!] /local code base][
		code: job/sections/code/2
		base: to integer! defs/image/base-address

		foreach [ptr list] imports-refs [
			ptr: base + ptr		
			foreach [def reloc] list [
				pointer/value: ptr 
				foreach ref reloc [change at code ref form-struct pointer]	;TBD: check endianness + x-compilation
				ptr: ptr + pointer-size
			]
		]
	]
	
	rsrc-directory: make-struct [
		characteristics	[integer!]
		timestamp		[integer!]
		major			[short]
		minor			[short]
		name-entries	[short]
		id-entries		[short]
	] none
	
	rsrc-entry: make-struct [
		name-rva		[integer!]
		id				[integer!]
		data-rva		[integer!]
		sub-rva			[integer!]
	] none
	
	rsrc-data: make-struct [
		data-rva		[integer!]
		size			[integer!]
		codepage		[integer!]
		reserved		[integer!]				;-- must be 0
	] none
	
	
	build-rsrc: func [job [object!] /local buffer ptr table][
		buffer: make binary! 100'000
		;ptr: 	section-addr?/memory job first find/last job/sections word!
		
		table: make-struct rsrc-directory none
		table/characteristics: 0
		table/timestamp: 	   0
		table/major: 		   4
		table/minor:		   0
		table/name-entries:	   0
		table/id-entries:	   0
		append buffer form-struct table
		
		;entry: make-struct rsrc-entry none
		;entry/name-rva

		append job/sections compose/deep [
			rsrc [- (buffer)]
		]
	]

	build-import: func [
		job [object!]
		/local spec IDTs ptr len out ILT-base buffer hints idt hint-ptr hint
	][
		spec:		job/sections/import
		IDTs: 		make block! len: divide length? spec/3 2			;-- list of directory entries
		out:		make binary! 4096		;-- final output buffer
		buffer:		make binary! 256		;-- DLL names + ILTs + IATs + hints/names buffer
		hints:		make binary! 2048		;-- hints/names temporary buffer
		ptr: 		(section-addr?/memory job 'import)
					+ (1 + len * length? form-struct import-directory)		;-- point to end of directory table

		foreach [name list] spec/3 [			;-- collecting DLL names in buffer
			append IDTs idt: make-struct import-directory none
			idt/name-rva: ptr + length? buffer
			repend buffer [uppercase name null]
			if even? length? name [append buffer null]
		]
		ptr: ptr + length? buffer			;-- base address of ILT/IAT/hints entries

		idx: 1
		foreach [name list] spec/3 [
			IDTs/:idx/ILT-rva: ptr
			ILT-base: tail buffer
			clear hints
			hint-ptr: ptr + (ILT-size * 2 * (1 + divide length? list 2))		;-- ILTs + IATs

			foreach [def reloc] list [
				hint: tail hints
				repend hints [#{0000} def null]	;-- Ordinal is zero, not used
				if even? length? def [append hints null]
				ILT/rva: hint-ptr
				append buffer form-struct ILT			;-- ILT instance
				hint-ptr: hint-ptr + length? hint
				ptr: ptr + ILT-size
			]
			append buffer #{00000000}			;-- null entry (8 bytes for 64-bit)
			ptr: ptr + ILT-size		

			repend imports-refs [ptr list]		;-- save IAT base ptr for relocation
			IDTs/:idx/IAT-rva: ptr
			ptr: ptr + offset? ILT-base tail buffer
			append buffer ILT-base				;-- IAT instances (copy of all ILTs)

			ptr: ptr + length? hints
			append buffer hints
			idx: idx + 1
		]
		foreach idt IDTs [append out form-struct idt]
		append out form-struct import-directory		;-- Null directory entry
		change next spec append out buffer
	]

	build-header: func [job [object!] /local fh][
		if job/type = 'exe [append job/buffer "PE^@^@"]	;-- image signature

		fh: make-struct file-header none
		fh/machine: 		 to integer! select defs/machine job/target
		fh/sections-nb: 	 (length? job/sections) / 2
		fh/timestamp: 		 get-timestamp
		fh/symbols-ptr: 	 0
		fh/opt-headers-size: opt-header-size
		fh/flags:			 to integer! defs/c-flags/executable-image 
								or defs/c-flags/relocs-stripped
								or defs/c-flags/machine-32bit
		append job/buffer form-struct fh
	]

	build-opt-header: func [job [object!] /local oh code-page][
		code-page: entry-point-page? job
		oh: make-struct optional-header none

		oh/magic:				to integer! #{010B}			;-- PE32 magic number
		oh/major-link-version:  linker/version/1
		oh/minor-link-version:	linker/version/2
		oh/code-size:			length? job/sections/code/2
		oh/initdata-size:		0
		oh/uninitdata-size:		0			
		oh/entry-point-addr:	code-page * memory-align		;-- entry point is set to beginning of CODE
		oh/code-base:			code-page * memory-align
		oh/data-base:			(code-page + round/ceiling (length? job/sections/code/2) / memory-align) * memory-align
		oh/image-base:			to integer! defs/image/base-address
		oh/memory-align:		memory-align
		oh/file-align:			file-align
		oh/major-OS-version:	4
		oh/minor-OS-version:	0
		oh/major-img-version:	0
		oh/minor-img-version:	0
		oh/major-sub-version:	4
		oh/minor-sub-version:	0
		oh/win32-ver-value:		0						;-- reserved, must be zero
		oh/image-size:			image-size? job
		oh/headers-size:		code-page * file-align
		oh/checksum:			0						;-- for drivers and DLL only
		oh/sub-system:			select defs/sub-system job/sub-system
		oh/dll-flags:			0						;-- DLL only
		oh/stack-res-size:		to integer! #{00100000}
		oh/stack-com-size:		to integer! #{00001000}
		oh/heap-res-size:		to integer! #{00100000}
		oh/heap-com-size:		to integer! #{00001000}
		oh/loader-flags:		0						;-- reserved, must be zero
		oh/data-dir-nb:			16
		;-- data directory
		oh/import-addr:			import-addr? job			
		oh/import-size:			length? job/sections/import/2
		if find job/sections 'rsrc [
			oh/rsrc-addr:			section-addr? job 'rsrc		
			oh/rsrc-size:			length? job/sections/rsrc/2
		]
		oh
	]

	build-section-header: func [job [object!] name [word!] spec [block!] /local sh s][
		sh: make-struct section-header none

		sh/virtual-size: 	length? spec/2
		sh/virtual-address:	section-addr?/memory job name
		sh/raw-data-size: 	file-align * round/ceiling (length? spec/2) / file-align
		sh/raw-data-ptr:	(section-addr?/file job name); - file-align
		sh/relocations-ptr:	0				;-- image or obj with no relocations
		sh/line-num-ptr:	0
		sh/relocations-nb:	0				;-- zero for executable images
		sh/line-num-nb:		0
		sh/flags:			to integer! select defs/s-type name		

		case [
			64 = (sh/flags and 64) [; 64 = #{00000040} = initialized data
				initdata-size: initdata-size + sh/raw-data-size
			]
			128 = (sh/flags and 128) [
				uninitdata-size: uninitdata-size + sh/raw-data-size
			]
		]
		switch name [
			code [opt-header/code-base: sh/virtual-address]
			data [opt-header/data-base: sh/virtual-address]
		]
		change s: form-struct sh append uppercase form name null	
		change spec s	
	]

	build: func [job [object!] /local page out pad code-ptr][
		clear imports-refs
		initdata-size: uninitdata-size: 0
		
		if job/debug? [
			code-ptr: entry-point-address? job
			linker/build-debug-lines job code-ptr pointer
		]
		
		build-import job					;-- populate import section buffer

		;if job/icon-file [
			build-rsrc job
		;]
		
		out: job/buffer
		append out defs/image/MSDOS-header
		build-header job	

		opt-header: build-opt-header job
		
		foreach [name spec] job/sections [
			build-section-header job name spec
		]
		opt-header/initdata-size:	initdata-size
		opt-header/uninitdata-size: uninitdata-size
		opt-header/entry-point-addr: opt-header/code-base

		append job/buffer form-struct opt-header

		foreach [name spec] job/sections [
			append job/buffer spec/1
		]
		
		insert/dup tail job/buffer null pad-size? job/buffer

		resolve-import-refs job				;-- resolve DLL imports references
		resolve-data-refs job				;-- resolve data references

		foreach [name spec] job/sections [
			pad: pad-size? spec/2
			append job/buffer spec/2
			insert/dup tail job/buffer null pad
		]
	]
]