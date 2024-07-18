Red [
	Title:   "Red/System compiler"
	File: 	 %compiler.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %utils/helper.red
#include %utils/secure-clean-path.red

print-value: func [val][
	probe val
]

#system [
	#include %compiler.reds
]

system-dialect: context [
	verbose:  	  0										;-- logs verbosity level
	runtime-path: %runtime/
	nl: 		  newline
	
	loader: #include %loader.red

	job!: make object! [
		format: 			none						;-- 'PE | 'ELF | 'Mach-o
		type: 				none						;-- 'exe | 'obj | 'lib | 'dll | 'drv
		target:				none						;-- CPU identifier
		sections:			none						;-- code/data sections
		flags:				none						;-- global flags
		sub-system:			none						;-- target environment (GUI | console)
		symbols:			none						;-- symbols table
		output:				none						;-- output file name (without extension)
		debug-info:			none						;-- debugging informations
		base-address:		none						;-- base address
		buffer: 			none						;-- output buffer
	]
	
	options-class: make object! [
		config-name:		none						;-- Preconfigured compilation target ID
		OS:					none						;-- Operating System
		OS-version:			0							;-- OS version
		ABI:				none						;-- optional ABI flags (word! or block!)
		link?:				no							;-- yes = invoke the linker and finalize the job
		encap?:				no							;-- yes = use encapping instead of compilation
		build-prefix:		%builds/					;-- prefix to use for output file name (none: no prefix)
		build-basename:		none						;-- base name to use for output file name (none: derive from input name)
		build-suffix:		none						;-- suffix to use for output file name (none: derive from output type)
		format:				none						;-- file format
		type:				'exe						;-- file type ('exe | 'dll | 'lib | 'obj | 'drv)
		target:				'IA-32						;-- CPU target
		cpu-version:		6.0							;-- CPU version (default for IA-32: 6.0, Pentium Pro, for ARM: 5.0)
		verbosity:			0							;-- logs verbosity level
		sub-system:			'console					;-- 'GUI | 'console
		runtime?:			yes							;-- include Red/System runtime
		use-natives?:		no							;-- force use of native functions instead of C bindings
		debug?:				no							;-- emit debug information into binary
		debug-safe?:		yes							;-- try to avoid over-crashing on runtime debug reports
		dev-mode?:		 	none						;-- yes => turn on developer mode (pre-build runtime, default), no => build a single binary
		need-main?:			no							;-- yes => emit a function prolog/epilog around global code
		PIC?:				no							;-- generate Position Independent Code
		base-address:		none						;-- base image memory address
		dynamic-linker: 	none						;-- ELF dynamic linker ("interpreter")
		syscall:			'Linux						;-- syscalls convention: 'Linux | 'BSD
		export-ABI:			none						;-- force a calling convention for exports
		stack-align-16?:	no							;-- yes => align stack to 16 bytes
		literal-pool?:		no							;-- yes => use pools to store literals, no => store them inlined (default: no)
		unicode?:			no							;-- yes => use Red Unicode API for printing on screen
		red-pass?:			no							;-- yes => Red compiler was invoked
		red-only?:			no							;-- yes => stop compilation at Red/System level and display output
		red-store-bodies?:	yes							;-- no => do not store function! value bodies (body-of will return none)
		red-strict-check?:	yes							;-- no => defers undefined word errors reporting at run-time
		red-tracing?:		yes							;-- no => do not compile tracing code
		red-help?:			no							;-- yes => keep doc-strings from boot.red
		redbin-compress?:	yes							;-- yes => compress Redbin payload using custom CRUSH algorithm
		legacy:				none						;-- block of optional OS legacy features flags
		gui-console?:		no							;-- yes => redirect printing to gui console (temporary)
		libRed?: 			no
		libRedRT?: 			no
		libRedRT-update?:	no
		GUI-engine:			'native						;-- native | test | GTK | ...
		draw-engine:		none						;-- none | GDI+ | ...
		modules:			none
		show:				none
		command-line:		none
		show-func-map?:		no							;-- yes => output the functions address/name map
	]

	compiler: context [
		job:			make job! []					;-- shortcut for job object
		script:			none							;-- source script file name
		pc:				none							;-- source code input cursor

		quit-on-error: does [
			if system/options/args [quit/return 1]
			halt
		]

		process-config: func [header [block!] /local spec old-PIC?][
			if spec: select header first [config:][
				do bind spec job
				if job/command-line [do bind job/command-line job]		;-- ensures cmd-line options have priority
			]
		]

		comp-header: has [pos][
			unless pc/1 = 'Red/System [
				throw-error "source is not a Red/System program"
			]
			pc: next pc
			unless block? pc/1 [
				throw-error "missing Red/System program header"
			]
			unless parse pc/1 [any [pos: set-word! skip]][
				throw-error ["invalid program header at:" mold pos]
			]
			pc: next pc
		]

		comp-dialect: routine [src [block!] job [object!]][
			compiler/init
			compiler/comp-dialect src job

			compiler/clean
		]

		run: func [
			obj [object!] src [block!] file [file!]
			/no-header /runtime /no-events
			/locals allow-runtime?
		][
			job: obj
			pc: src
			script: secure-clean-path file
			runtime: to logic! runtime
			allow-runtime?: all [not no-events job/runtime?]
			
			unless job/red-pass? [process-config pc/2]
			unless no-header [comp-header]

			recycle
			recycle/off
			comp-dialect pc job
			recycle/on
		]

		
		finalize: has [tmpl words][
			if verbose >= 2 [print "^/---^/Compiling native functions^/---"]
			
			;comp-natives
		]
	]

	set-verbose-level: func [level [integer!]][
		foreach ctx reduce [
			self
			loader
		][
			ctx/verbose: level
		]
	]
	
	output-logs: does []

	comp-start: has [script][
		script:	secure-clean-path runtime-path/start.reds
 		compiler/run/no-events job loader/process/own script script
	]
	
	comp-runtime-prolog: func [red? [logic!] payload [binary! none!] /local script ext][
		script: secure-clean-path runtime-path/common.reds
 		compiler/run/runtime job loader/process/own script script
	]
	
	comp-runtime-epilog: does []
	
	make-job: func [
		opts	[object!]
		file	[file!]
		/local job [job!] blk [block!]
	][
		blk: body-of opts
		forall blk [
			if lit-word? blk/1 [blk/1: to-word blk/1]
		]
		job: construct/with blk job!	
		file: last split-path file					;-- remove path
		file: to-file first split file "."			;-- remove extension
		case [
			none? job/build-basename [
				job/build-basename: file
			]
			slash = last job/build-basename [
				append job/build-basename file
			]
		]
		job
	]

	dt: func [code [block!] /local t0][
		t0: now/time/precise
		do code
		now/time/precise - t0
	]

	collect-resources: func [
		header	[block!]
		res		[block!]
		file	[file!]
		/local icon name value info main-path version-info-key base
	][
		info: make block! 8
		main-path: first split-path file
		base: %assets/
		
		either icon: select header first [Icon:][
			append res 'icon
			either any [word? :icon any-word? :icon][
				repend/only res [
					join base select [
						default %red.ico
						flat 	%red.ico
						old		%red-3D.ico
						mono	%red-mono.ico
					] :icon
				]
			][
				icon: either file? icon [reduce [icon]][icon]
				foreach file icon [
					append info either loader/relative-path? file [
						join main-path file
					][file]
					unless exists? last info [
						red/throw-error ["cannot find icon:" last info]
					]
				]
				append/only res copy info
			]
		][
			append res compose/deep [icon [(base/red.ico)]]
		]

		clear info
		append res 'version

		version-info-key: [
			Title: Version: Company: Comments: Notes:
			Rights: Trademarks: ProductName: ProductVersion:
		]
		foreach name version-info-key [
			if value: select header name [
				append info reduce [to word! name value]
			]
		]
		append/only res info
	]
	
	compile: func [
		files [file! block!]							;-- source file or block of source files
		/options
			opts [object!]
		/loaded 										;-- source code is already in LOADed format
			job-data [block!]
		/local
			job [job!]
			comp-time link-time err output src resources icon
	][
		comp-time: dt [
			unless block? files [files: reduce [files]]
			
			unless opts [opts: make options-class []]
			job: make-job opts last files				;-- last input filename is retained for output name

			job/need-main?: to logic! any [
				job/need-main?							;-- pass-thru if set in config file
				all [
					job/type = 'exe
					not find [Windows macOS] job/OS
				]
			]

			set-verbose-level opts/verbosity
			loader/init
			
			if all [
				job/need-main?
				not opts/use-natives?
				opts/runtime?
			][
				;comp-start								;-- init libC properly
			]		

			if opts/runtime? [
				;comp-runtime-prolog to logic! loaded all [loaded job-data/3]
			]
			
			resources: either loaded [job-data/4][make block! 8]
			foreach file files [
				either loaded [
					src: loader/process/with job-data/1 file
				][
					src: loader/process file
					if job/OS = 'Windows [collect-resources src/2 resources file]
				]
				compiler/run job src file
			]
			if opts/runtime? [comp-runtime-epilog]

			compiler/finalize							;-- compile all functions
			set-verbose-level 0
		]
		reduce [
			comp-time
			link-time
			any [all [job/buffer length? job/buffer] 0]
			output
		]
	]
]
