REBOL [
	Title:   "Red/System PE/COFF format emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %PE.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [
	manifest-template: {
		<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
			<dependency>
				<dependentAssembly>
					<assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="x86" publicKeyToken="6595b64144ccf1df" language="*"/>
				</dependentAssembly>
			</dependency>
			<trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
				<security>
					<requestedPrivileges>
						<requestedExecutionLevel level="asInvoker" uiAccess="false"/>
					</requestedPrivileges>
				</security>
			</trustInfo>
			<compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
				<application>
					<supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
					<supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}"/>
					<supportedOS Id="{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}"/>
					<supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>
				</application>
			</compatibility>
		</assembly>
	}
	if all [
		system/version/4 = 3
		find system/components 'Library 
	][
		path: to-rebol-file get-env "SystemRoot"		;-- workaround issues on 64-bit editions
		Imagehlplib: load/library path/System32/Imagehlp.dll

		int-ptr!: make struct! [n [integer!]] none

		MapFileAndCheckSum: make routine! [
			Filename	[string!]
			HeaderSum	[struct! [n [integer!]]]
			CheckSum	[struct! [n [integer!]]]
			return:		[integer!]
		] Imagehlplib "MapFileAndCheckSumA" 
	]
	
	defs: [
		image [
			exe-base-address	#{00400000}
			dll-base-address	#{10000000}
			drv-base-address	#{00010000}
			
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
			drv %.sys
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
			idata				#{C0000040}	;-- [read write initialized]
			reloc				#{42000040} ;-- [read discardable initialized]
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
		resource-type [
			cursor				1
			bitmap				2
			icon				3
			menu				4
			dialog				5
			string				6
			font-dir			7
			font				8
			accelerator			9
			rc-data				10
			message-table		11
			group-cursor		12
			group-icon			14
			version				16
			manifest			24
		]
		resource-version-info [
			comments			"Comments"
			notes				"Comments"
			company				"CompanyName"
			title				"FileDescription"
			version				"FileVersion"
			rights				"LegalCopyright"
			trademarks			"LegalTrademarks"
			Author				"PrivateBuild"
			ProductName			"ProductName"
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

	ILT-struct: make-struct [
		rva	[integer!]						;-- 32/64-bit
	] none
	
	export-directory: make-struct [
		flags				[integer!]
		timestamp			[integer!]
		major-version		[short]
		minor-version		[short]
		name-rva			[integer!]
		ordinal-base		[integer!]
		addr-table-entries 	[integer!]
		nb-name-ptr			[integer!]
		addr-table-rva		[integer!]
		name-ptr-rva		[integer!]
		ordinals-rva		[integer!]
	] none

	resource-directory: make-struct [
		character			[integer!]
		timestamp			[integer!]
		major-version		[short]
		minor-verion		[short]
		name-entry-nb		[short]
		id-entry-nb			[short]
	] none

	resource-directory-entry: make-struct [
		name				[integer!]
		offset				[integer!]
	] none

	resource-data-entry: make-struct [
		offset				[integer!]
		size				[integer!]
		code-page			[integer!]
		reserved			[integer!]
	] none

	group-icon-directory: make-struct [
		reserved			[short]
		type				[short]
		count				[short]
	] none

	vs-version-info: make-struct [
		length				[short]
		value-length		[short]
		type				[short]
	] none

	vs-fixed-fileinfo: make-struct [
		signature			[integer!]
		struct-version		[integer!]
		file-version-ms		[integer!]
		file-version-ls		[integer!]
		product-version-ms	[integer!]
		product-version-ls	[integer!]
		flags-mask			[integer!]
		flags				[integer!]
		OS					[integer!]
		type				[integer!]
		subtype				[integer!]
		date-ms				[integer!]
		date-ls				[integer!]
	] none

	pointer: make-struct [
		value [integer!]					;-- 32/64-bit, watch out for endianess!!
	] none

	base-address:		none
	memory-align:		4096				;-- system page size
	file-align: 		512					;-- better keep it < memory-align
	sect-header-size: 	40
	ILT-size:			4					;-- Import Lookup Table size (8 for 64-bit)
	pointer-size:		4					;-- Pointer size (8 for 64-bit)
	imports-refs:		make block! 10		;-- [ptr [DLL imports] ...]
	opt-header-size:	length? form-struct optional-header
	ep-mem-page: 		none
	ep-file-page:		none

	get-timestamp: has [n t][
		n: now
		t: n/time
		(n - 01/01/1970 * 86400)			;-- 24 * 3600
			+ (t/hour * 3600)
			+ (t/minute * 60)
			+ to integer! t/second
	]
	
	pad4: func [s [binary!] /local rem][
		unless zero? rem: (length? s) // 4 [
			insert/dup tail s #{00} 4 - rem
		]
		s
	]

	pad-size?: func [buffer [binary!] /local rem][
		either zero? rem: (length? buffer) // file-align [
			0
		][
			file-align - rem
		]
	]
	
	precalc-entry-point: func [job [object!] /local ptr][
		ptr: (length? defs/image/MSDOS-header)
			+ (length? form-struct file-header)
			+ (opt-header-size)
			+ (sect-header-size * divide length? job/sections 2)
			
		ep-mem-page:  round/ceiling ptr / memory-align
		ep-file-page: round/ceiling ptr / file-align
	]
	
	entry-point-address?: func [job [object!]][
		base-address + section-addr?/memory job 'code
	]

	image-size?: func [job [object!] /local pages][
		pages: ep-mem-page
		foreach [name section] job/sections [
			pages: pages + round/ceiling (length? section/2)  / memory-align
		]
		pages * memory-align
	]

	named-sect-addr?: func [job [object!] s-name [word!] /local pages][
		pages: ep-mem-page
		
		foreach [name section] job/sections [
			if name = s-name [return pages * memory-align]
			pages: pages + round/ceiling (length? section/2) / memory-align	
		]
		make error! join section " section not found!"
	]

	section-addr?: func [job [object!] s-name [word!] /file /memory /local pages align][
		pages: either file [ep-file-page][ep-mem-page]
		align: either file [file-align][memory-align]
		
		foreach [name section] job/sections [
			if name = s-name [return pages * align]
			pages: pages + round/ceiling (length? section/2) / align	
		]
		make error! reform [mold s-name "section not found!"]
	]

	resolve-data-refs: func [job [object!] /local cbuf dbuf data code][
		cbuf: job/sections/code/2
		dbuf: job/sections/data/2
		data: (section-addr?/memory job 'data) + base-address
		code: entry-point-address? job

		linker/resolve-symbol-refs job cbuf dbuf code data pointer
	]

	resolve-import-refs: func [job [object!] /local code code-base][
		code: job/sections/code/2
		code-base: section-addr?/memory job 'code
		
		foreach [ptr list] imports-refs [
			ptr: either job/PIC? [ptr - code-base][base-address + ptr]
			
			foreach [def reloc] list [
				pointer/value: ptr 
				foreach ref reloc [change at code ref form-struct pointer]	;TBD: check endianness + x-compilation
				ptr: ptr + pointer-size
			]
		]
	]
	
	build-import: func [
		job [object!]
		/local spec IDTs ILTs out dlls hints idt ilt ptr ILTs-base hints-base
			dlls-base IAT-base ILT-size idx IAT-buffer len offset list idata
	][
		spec:		job/sections/import
		IDTs: 		make block! len: divide length? spec/3 2	;-- list of directory entries
		ILTs:		make block!  500
		out:		make binary! 50000					;-- final output buffer
		dlls:		make binary! 200					;-- DLL names
		hints:		make binary! 10000					;-- hints/names temporary buffer

		if pos: find spec/3 "libRedRT.dll" [
			append spec/3 take/part pos 2				;-- ensures libRedRT is loaded last
		]												;-- to allow VisualStyles to work properly
		
		foreach [name list] spec/3 [					;-- collecting DLL names in buffer
			append IDTs idt: make-struct import-directory none
			idt/name-rva: length? dlls
			repend dlls [uppercase name null]
			if even? length? name [append dlls null]
		]
		pad4 dlls
		
		len: 0
		foreach [name list] spec/3 [					;-- collecting function names in buffer
			append/only ILTs make block! 50
			linker/check-dup-symbols job list
			foreach [def reloc] list [
				append last ILTs ilt: make-struct ILT-struct none
				ilt/rva: length? hints
				repend hints [#{0000} form def null]	;-- Ordinal is zero, not used
				if even? length? def [append hints null]
				len: len + 1
			]
			len: len + 1								;-- account for null entry
		]

		ptr:		section-addr?/memory job 'import
		ILTs-base:  ptr + (1 + (length? IDTs) * length? form-struct import-directory)
		hints-base: ILTs-base + (len *  ILT-size: length? form-struct ILT-struct)
		dlls-base:	hints-base + length? hints

		idx: 0
		offset: 0
		foreach idt IDTs [
			if idx > 0 [offset: offset + (ILT-size * (1 + length? ILTs/:idx))]
			idt/ILT-rva:  ILTs-base + offset
			idt/name-rva: idt/name-rva + dlls-base
			append out form-struct idt
			idx: idx + 1
			IDTs/:idx: offset
		]
		append out form-struct import-directory			;-- Ending null directory entry
		
		IAT-buffer: tail out
		foreach dll ILTs [
			foreach ilt dll [
				ilt/rva: ilt/rva + hints-base
				append out form-struct ilt
			]
			append out form-struct ILT-struct			;-- Ending null ILT entry
		]
		IAT-buffer: copy IAT-buffer
		repend out [hints dlls]
		change next spec out
	
		idata: compose/deep [idata [- (IAT-buffer) -]]	;-- inject IAT section
		insert skip find job/sections 'import 2 idata
		
		ptr: section-addr?/memory job 'idata
		idx: 1		
		foreach offset IDTs [
			change skip out (idx * 20) - 4 to-bin32 IAT-base: ptr + offset
			list: pick spec/3 idx * 2
			repend imports-refs [IAT-base list]			;-- save IAT base ptr for relocation
			idx: idx + 1
		]	
	]
	
	build-export: func [
		job [object!]
		/local
			spec NPT out names ptr EAT-len sym-nb dll-name-offset ordinal ed
			code-base data-base	buffer names-ptr
	][
		spec: 		job/sections/export
		NPT: 		make block! 32
		out:		make binary! 4096					;-- final output buffer
		names:		make binary! 4096
		EAT-len:	4
		ptr: 		(section-addr?/memory job 'export)
						+ length? form-struct export-directory
		
		sym-nb: 0
		sort/case/skip/compare spec/3 2 2				;-- sort all symbols lexicographically
		foreach [name exp-name] spec/3 [				;-- Export Name Table
			repend NPT [name length? names]
			repend names [exp-name null]
			sym-nb: sym-nb + 1
		]
		
		dll-name-offset: length? names
		append names rejoin [							;-- store DLL name
			last split-path job/build-basename
			select defs/extensions job/type
			null
		]
		
		ed: make-struct export-directory none			;-- Export Directory Table
		ed/flags:				0						;-- reserved
		ed/timestamp:			get-timestamp			;-- epoch format
		ed/major-version:		1						;TBD: retrieve it from script header
		ed/minor-version:		0						;TBD: retrieve it from script header
		ed/name-rva:			ptr + ((EAT-len + 4 + 2) * sym-nb) + dll-name-offset
		ed/ordinal-base:		1
		ed/addr-table-entries:	sym-nb
		ed/nb-name-ptr:			sym-nb
		ed/addr-table-rva:		ptr
		ed/name-ptr-rva:		ptr + (EAT-len * sym-nb)
		ed/ordinals-rva:		ptr + ((EAT-len + 4) * sym-nb)
		append out form-struct ed
		
		code-base: section-addr?/memory job 'code
		data-base: section-addr?/memory job 'data
	
		buffer: make binary! 1024
		names-ptr: ed/ordinals-rva + (2 * sym-nb)
			
		foreach [name offset] NPT [						;-- Export Address Table
			entry: select job/symbols name
			pointer/value: entry/2 + either entry/1 = 'global [data-base][code-base - 1]
			append out form-struct pointer				;-- Export RVA
			
			pointer/value: names-ptr + offset
			append buffer form-struct pointer			;-- Export Name Pointer Table entry
		]
		append out buffer								;-- Export Name Pointer Table
		
		ordinal: 0										;-- Ordinal Table
		loop sym-nb [
			append out to-bin16 ordinal
			ordinal: ordinal + 1
		]
		
		append out names
		change next spec out
		buffer: names: out: none
	]
	
	build-section-reloc: func [
		job [object!] name [word!] refs [block!]
		/local _4K block buffer base type offset factor header open-block close-block
	][
		_4K: 4096
		buffer: make binary! _4K
		base: section-addr?/memory job name
		type: to integer! #{3000}						;-- IMAGE_REL_BASED_HIGHLOW		
		block: 0
		
		open-block: [
			header: tail buffer
			append buffer #{0000000000000000}			;-- reserve 64-bit for the header
		]
		close-block: [
			change header to-bin32 base
			change at header 5 to-bin32 length? header	;-- store header + buffer size
		]
		
		do open-block
		foreach offset refs [
			offset: offset - 1
			if offset - block >= _4K [
				pad4 buffer
				do close-block
				do open-block
				factor: offset - block / _4K
				base: base + factor: (_4K * to integer! factor)
				block: block + factor
			]
			append buffer to-bin16 (offset - block) or type
		]
		do close-block
		
		buffer
	]
	
	build-reloc: func [job [object!] /local out code-refs data-refs][
		out: make binary! 4096
			
		code-refs: make block! 1000
		data-refs: make block! 100
		foreach [name spec] job/symbols [
			either all [spec/1 = 'global block? spec/4][
				foreach ref spec/4 [append data-refs ref]
			][
				foreach ref spec/3 [append code-refs ref]
			]
		]
		code-refs: unique sort code-refs
		data-refs: unique sort data-refs
			
		unless empty? code-refs [append out build-section-reloc job 'code code-refs]
		unless empty? data-refs [append out build-section-reloc job 'data data-refs]
		
		job/sections/reloc/2: out
	]

	build-header: func [job [object!] /local fh][
		if find [exe dll drv] job/type [append job/buffer "PE^@^@"]	;-- image signature

		fh: make-struct file-header none
		fh/machine: 		 to integer! select defs/machine job/target
		fh/sections-nb: 	 (length? job/sections) / 2
		fh/timestamp: 		 get-timestamp
		fh/symbols-ptr: 	 0
		fh/opt-headers-size: opt-header-size
		fh/flags:			 to integer! defs/c-flags/executable-image
									  or defs/c-flags/machine-32bit
		
		unless find job/sections 'reloc	[
			fh/flags: fh/flags or to integer! defs/c-flags/relocs-stripped
		]
		
		switch job/type [
			dll [fh/flags: fh/flags or to integer! defs/c-flags/dll]
			;drv [fh/flags: fh/flags or to integer! defs/c-flags/system]
		]
		append job/buffer form-struct fh
	]

	initdata-size?: func [sections [block!] /local n flag][
		n: 0
		foreach [name spec] sections [
			flag: select defs/s-type name
			unless zero? to integer! flag and #{00000040} [
				n: n + (length? spec/2) + (pad-size? spec/2)
			]
		]
		n
	]

	build-opt-header: func [job [object!] /local oh code-page code-base ep entry flags][
		code-page: ep-mem-page
		code-base: code-page * memory-align
		
		flags: to integer! defs/dll-flags/nx-compat
		case/all [
			job/type = 'dll	[flags: flags or to integer! defs/dll-flags/dynamic-base]
			job/type = 'drv [flags: flags or to integer! defs/dll-flags/wdm-driver]
		]
		
		if job/type = 'drv [flags: 0]						;@@temporary flags disabling
		
		ep: switch/default job/type [
			dll [
				either entry: select job/symbols '***-dll-entry-point [
					code-base + entry/2 - 1					;-- dll: entry point provided
				][0]										;-- dll: no entry-point
			]
			drv [
				entry: select job/symbols '***-drv-entry-point
				code-base + entry/2 - 1
			]
		][
			code-base									;-- exe: entry point
		]
		oh: make-struct optional-header none

		oh/magic:				to integer! #{010B}		;-- PE32 magic number
		oh/major-link-version:  linker/version/1
		oh/minor-link-version:	linker/version/2
		oh/code-size:			length? job/sections/code/2
		oh/initdata-size:		initdata-size? job/sections
		oh/uninitdata-size:		0			
		oh/entry-point-addr:	ep						;-- entry point is set to beginning of CODE
		oh/code-base:			code-base
		oh/data-base:			(code-page + round/ceiling (length? job/sections/code/2) / memory-align) * memory-align
		oh/image-base:			base-address
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
		oh/checksum:			either job/type = 'drv [123456][0]	;-- for drivers and DLL only (dummy default)
		oh/sub-system:			select defs/sub-system job/sub-system
		oh/dll-flags:			flags
		oh/stack-res-size:		to integer! #{00100000}
		oh/stack-com-size:		to integer! #{00001000}
		oh/heap-res-size:		to integer! #{00100000}
		oh/heap-com-size:		to integer! #{00001000}
		oh/loader-flags:		0						;-- reserved, must be zero
		oh/data-dir-nb:			16
		;-- data directory
		oh/import-addr:			named-sect-addr? job 'import
		oh/import-size:			length? job/sections/import/2
		oh/IAT-addr:			named-sect-addr? job 'idata
		oh/IAT-size:			length? job/sections/idata/2
		
		if job/type = 'dll [
			oh/export-addr:		named-sect-addr? job 'export
			oh/export-size:		length? job/sections/export/2
		]
		if find [dll drv] job/type [
			oh/reloc-addr:		named-sect-addr? job 'reloc
			oh/reloc-size:		length? job/sections/reloc/2
		]
		if find job/sections 'rsrc [
			oh/rsrc-addr: 		named-sect-addr? job 'rsrc
			oh/rsrc-size:		length? job/sections/rsrc/2
		]
		append job/buffer form-struct oh
	]

	build-section-header: func [job [object!] name [word!] spec [block!] /local sh s][
		sh: make-struct section-header none

		sh/virtual-size: 	length? spec/2
		sh/virtual-address:	section-addr?/memory job name
		sh/raw-data-size: 	file-align * round/ceiling (length? spec/2) / file-align
		sh/raw-data-ptr:	section-addr?/file job name
		sh/relocations-ptr:	0							;-- @@ relevant only for OBJ files
		sh/line-num-ptr:	0
		sh/relocations-nb:	0							;-- @@ relevant only for OBJ files
		sh/line-num-nb:		0
		sh/flags:			to integer! select defs/s-type name		

		change s: form-struct sh append uppercase form name null	
		change spec s	
	]

	icon-number?: func [icons [block!] /local data num][
		num: 0
		foreach icon icons [
			data: read-binary-cache icon
			num: num + to-integer reverse copy/part skip data 4 2
		]
		num
	]

	build-res-directory: func [
		resource [block!]
		/local out dir entry nb sz dir-mask dir-sz entry-sz
	][
		dir-mask: to-integer #{80000000}
		dir-sz: 16
		entry-sz: 8
		out: make binary! 4096
		dir: make-struct resource-directory none
		entry: make-struct resource-directory-entry none

		nb: (length? resource) / 2
		sz: dir-sz + (nb * entry-sz)

		dir/id-entry-nb: nb
		append out form-struct dir

		foreach [name info] resource [					;-- root level - type
			entry/name: select defs/resource-type name
			entry/offset: sz or dir-mask
			nb: case [
				name = 'icon [icon-number? info]
				name = 'group-icon [length? info]
				true [1]
			]
			sz: dir-sz + (nb * entry-sz) + sz
			append out form-struct entry
		]

		foreach [name info] resource [					;-- second level - name
			nb: case [
				name = 'icon [icon-number? info]
				name = 'group-icon [length? info]
				true [1]
			]
			dir/id-entry-nb: nb
			append out form-struct dir
			for n 1 nb 1 [
				entry/name: n
				entry/offset: sz or dir-mask
				append out form-struct entry
				sz: dir-sz + entry-sz + sz
			]
		]

		foreach [name info] resource [					;-- third level - language
			nb: case [
				name = 'icon [icon-number? info]
				name = 'group-icon [length? info]
				true [1]
			]
			dir/id-entry-nb: 1
			for n 1 nb 1 [
				append out form-struct dir
				entry/name: 1033						;-- english default
				entry/offset: sz
				append out form-struct entry
				sz: sz + 16								;-- res-data-entry size: 16
			]
		]
		reduce [out sz]
	]

	build-res-icon: func [
		out		[binary!]
		buf		[binary!]
		icons	[block!]
		base	[integer!]
		/local data p entry nb img-off img-sz
	][
		entry: make-struct resource-data-entry none
		foreach icon icons [
			data: read-binary-cache icon
			nb: to-integer reverse copy/part skip data 4 2
			p: skip data 6
			for i 1 nb 1 [
				entry/offset: base + length? buf
				img-sz: to-integer reverse copy/part skip p 8 4
				img-off: to-integer reverse copy/part skip p 12 4
				p: skip p 16
				insert/part tail buf skip data img-off img-sz
				entry/size: img-sz
				append out form-struct entry
			]
		]
	]

	build-res-group-icon: func [
		out		[binary!]
		buf		[binary!]
		icons	[block!]
		base	[integer!]
		/local data p entry nb icon-dir n data-buf
	][
		entry: make-struct resource-data-entry none
		icon-dir: make-struct group-icon-directory none
		n: 1
		foreach icon icons [
			entry/offset: base + length? buf
			data-buf: tail buf

			data: read-binary-cache icon
			nb: to-integer reverse copy/part skip data 4 2

			icon-dir/type: 1
			icon-dir/count: nb
			append buf form-struct icon-dir

			p: skip data 6
			for i 1 nb 1 [
				insert/part tail buf p 14
				change skip tail buf -2 to-bin16 n
				n: n + 1
				p: skip p 16
			]

			entry/size: length? data-buf
			append out form-struct entry
		]
	]

	build-res-string: func [buf [binary!] key [string!] value [string!] /local str][
		str: make-struct vs-version-info none
		str/value-length: 1 + length? value					;-- added NUL byte
		str/type: 1
		append buf form-struct str
		append buf reduce [utf8-to-utf16 key #{0000}]
		pad4 buf
		append buf reduce [utf8-to-utf16 value #{0000}]
		change buf to-bin16 length? buf
		pad4 buf
	]

	build-res-str-table: func [buf [binary!] info [block!] /local table value][
		table: make-struct vs-version-info none
		table/type: 1
		append buf form-struct table
		append buf #{300034003000390030003400620030000000}	;-- hard-coded language/codepage
		pad4 buf

		foreach [key key-str] defs/resource-version-info [
			if value: select info key [
				build-res-string tail buf key-str to string! value
			]
		]
		change buf to-bin16 length? buf
	]

	build-res-str-info: func [buf [binary!] info [block!] /local str-info][
		str-info: make-struct vs-version-info none
		str-info/type: 1
		append buf form-struct str-info
		append buf utf8-to-utf16 "StringFileInfo^@"
		pad4 buf

		build-res-str-table tail buf info
		change buf to-bin16 length? buf
	]

	build-res-var: func [buf [binary!] info [block!] /local var][
		var: make-struct vs-version-info none
		var/value-length: 4
		var/type: 0
		append buf form-struct var
		append buf utf8-to-utf16 "Translation^@"
		pad4 buf

		append buf #{0904B004}
		change buf to-bin16 length? buf
	]

	build-res-var-info: func [buf [binary!] info [block!] /local var-info][
		var-info: make-struct vs-version-info none
		var-info/type: 1
		append buf form-struct var-info
		append buf utf8-to-utf16 "VarFileInfo^@"
		pad4 buf

		build-res-var tail buf info
		change buf to-bin16 length? buf
	]

	build-res-file-info: func [info [block!] type [word!] /local f ver][
		either all [
			ver: select info 'version
			issue? ver
		][
			ver: 0.0.0.0 or to tuple! debase/base next ver 16
		][
			ver: 0.0.0.0
		]
		
		f: make-struct vs-fixed-fileinfo none
		f/signature:			to-integer #{FEEF04BD}
		f/struct-version:		to-integer #{00010000}
		f/file-version-ms: 		ver/2 or shift/left ver/1 16
		f/file-version-ls: 		ver/4 or shift/left ver/3 16
		f/product-version-ms:	ver/2 or shift/left ver/1 16
		f/product-version-ls:	ver/4 or shift/left ver/3 16
		f/OS: 					to-integer #{00040004}	;-- VOS_NT_WINDOWS32
		f/type:					switch/default type [
									dll	[2]
									drv [3]
								][1]					;-- exe
		form-struct f
	]

	build-res-version: func [
		out		[binary!]
		buf		[binary!]
		info	[block!]
		base	[integer!]
		type	[word!]
		/local entry ver-info file-info data-buf
	][
		entry: make-struct resource-data-entry none
		entry/offset: base + length? buf
		data-buf: tail buf

		ver-info: make-struct vs-version-info none
		file-info: make-struct vs-fixed-fileinfo none
		
		ver-info/value-length: length? form-struct file-info
		ver-info/type: 0
		append buf form-struct ver-info
		append buf utf8-to-utf16 "VS_VERSION_INFO^@"
		pad4 buf

		append buf build-res-file-info info type
		pad4 buf

		build-res-str-info tail buf info
		build-res-var-info tail buf info

		entry/size: length? data-buf
		change data-buf to-bin16 length? data-buf
		append out form-struct entry
	]

	build-res-manifest: func [
		out		[binary!]
		buf		[binary!]
		info	[string! none!]
		base	[integer!]
		/local entry data-buf
	][
		entry: make-struct resource-data-entry none
		entry/offset: base + length? buf
		data-buf: tail buf

		append buf trim/with either info [info][manifest-template] "^M^/^-"

		entry/size: length? data-buf
		append out form-struct entry
	]

	build-resource: func [job [object!] /local resource out buf dir offset][
		resource: job/sections/rsrc
		set [out offset] build-res-directory resource/3
		offset: offset + section-addr?/memory job 'rsrc	;-- virtual address offset
		buf: make binary! 4096

		foreach [name info] resource/3 [
			switch name [
				icon		[build-res-icon out buf info offset]
				group-icon	[build-res-group-icon out buf info offset]
				version		[build-res-version out buf info offset job/type]
				manifest	[build-res-manifest out buf info offset]
			]
			pad4 buf
		]
		change next resource append out buf
	]

	build: func [job [object!] /local page out pad code-ptr][
		clear imports-refs
		
		if find [dll drv] job/type [
			append job/sections [reloc [- - -]]			;-- inject reloc section
		]
		
		base-address: any [
			job/base-address
			to integer! switch/default job/type [
				exe	[defs/image/exe-base-address]
				drv [defs/image/drv-base-address]
			][
				defs/image/dll-base-address
			]
		]
		precalc-entry-point job

		if job/debug? [
			code-ptr: entry-point-address? job
			linker/build-debug-lines job code-ptr
			linker/build-debug-func-names job code-ptr
		]
		
		build-import job								;-- populate import section buffer

		if job/type = 'dll [build-export job]			;-- populate export section buffer

		if find job/sections 'rsrc	[build-resource job]
		
		if find [dll drv] job/type [build-reloc job]

		out: job/buffer
		append out defs/image/MSDOS-header
		build-header job	
		build-opt-header job

		foreach [name spec] job/sections [
			build-section-header job name spec
			append job/buffer spec/1
		]
		insert/dup tail job/buffer null pad-size? job/buffer

		resolve-import-refs job							;-- resolve DLL imports references
		resolve-data-refs job							;-- resolve data references

		foreach [name spec] job/sections [
			pad: pad-size? spec/2
			append job/buffer spec/2
			insert/dup tail job/buffer null pad
		]
	]
	
	on-file-written: func [job [object!] file [file!] /local file-sum chk-sum offset buffer res][
		if job/type = 'drv [
			file-sum: make struct! int-ptr! [0]
			chk-sum:  make struct! int-ptr! [0]

			res: MapFileAndCheckSum
				to-local-file get-modes file 'full-path
				file-sum
				chk-sum

			if res <> 0 [
				print [
					"*** Linker Error: checksum calculation failed^/"
					"*** Reason: " select res [
						1 "Could not open the file."
						2 "Could not map the file."
						3 "Could not map a view of the file."
						4 "Could not convert the file name to Unicode."
					]
				]
			]

			offset: (length? defs/image/MSDOS-header) + ((5 + 17) * 4) + 1

			buffer: read/binary file
			pointer/value: chk-sum/n
			change/part at buffer offset form-struct pointer 4
			write/binary file buffer
		]
	]
]