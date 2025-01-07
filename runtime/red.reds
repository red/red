Red/System [
	Title:   "Red runtime wrapper"
	Author:  "Nenad Rakocevic"
	File: 	 %red.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

red: context [
	;-- Runtime sub-system --
	
	#include %definitions.reds
	#include %macros.reds
	#include %tools.reds
	#include %dtoa.reds
	#include %externals.reds
	
	#switch OS [										;-- loading OS-specific bindings
		Windows  [#include %platform/win32.reds]
		Syllable [#include %platform/syllable.reds]
		macOS	 [#include %platform/darwin.reds]
		FreeBSD  [#include %platform/freebsd.reds]
		NetBSD   [#include %platform/netbsd.reds]
		#default [#include %platform/linux.reds]
	]
	
	#include %threads.reds
	#include %allocator.reds
	#include %crush.reds
	
	;-- Datatypes --
	
	#include %structures.reds
	#include %print.reds
	#include %common.reds
	#include %unicode.reds
	#include %case-folding.reds
	#include %sort.reds
	#include %hashtable.reds
	#include %ownership.reds
	#include %references.reds
	
	;--------------------------------------------
	;-- Import OS dependent image functions
	;-- load-image: func [								;-- return handle
	;-- 	filename [c-string!]
	;-- 	return:  [integer!]
	;-- ]
	;--------------------------------------------

	#switch OS [
		Windows  [
			#switch draw-engine [
				GDI+	 [#include %platform/image-gdiplus.reds]
				#default [#include %platform/image-wic.reds]
			]
		]
		Syllable []
		macOS	 [#include %platform/image-quartz.reds]
		Linux	 [
			#either config-name = 'Pico [
				#include %platform/image-stub.reds
			][
				#include %platform/image-gdk.reds
			]
		]
		FreeBSD  [#include %platform/image-gdk.reds]
		NetBSD   [#include %platform/image-gdk.reds]
		#default []
	]
	#include %image-utils.reds
	
	#include %datatypes/datatype.reds
	#include %datatypes/unset.reds
	#include %datatypes/none.reds
	#include %datatypes/logic.reds
	#include %datatypes/series.reds
	#include %datatypes/block.reds
	#include %datatypes/string.reds
	#include %datatypes/time.reds
	#include %datatypes/integer.reds
	#include %datatypes/symbol.reds
	#include %datatypes/context.reds
	#include %datatypes/word.reds
	#include %datatypes/lit-word.reds
	#include %datatypes/set-word.reds
	#include %datatypes/get-word.reds
	#include %datatypes/refinement.reds
	#include %datatypes/char.reds
	#include %datatypes/native.reds
	#include %datatypes/action.reds
	#include %datatypes/op.reds
	#include %datatypes/path.reds
	#include %datatypes/lit-path.reds
	#include %datatypes/set-path.reds
	#include %datatypes/get-path.reds
	#include %datatypes/function.reds
	#include %datatypes/routine.reds
	#include %datatypes/paren.reds
	#include %datatypes/issue.reds
	#include %datatypes/file.reds
	#include %datatypes/url.reds
	#include %datatypes/object.reds
	#include %datatypes/bitset.reds
	#include %datatypes/triple.reds
	#include %datatypes/float.reds
	#include %datatypes/typeset.reds
	#include %datatypes/error.reds
	#include %datatypes/vector.reds
	#include %datatypes/map.reds
	#include %datatypes/hash.reds
	#include %datatypes/pair.reds
	#include %datatypes/percent.reds
	#include %datatypes/tuple.reds
	#include %datatypes/binary.reds
	#include %datatypes/tag.reds
	#include %datatypes/email.reds
	#include %datatypes/handle.reds
	#include %datatypes/date.reds
	#include %datatypes/port.reds
	#include %datatypes/money.reds
	#include %datatypes/ref.reds
	#include %datatypes/point2D.reds
	#include %datatypes/point3D.reds
	#if OS = 'Windows [#include %datatypes/image.reds]	;-- temporary
	#if OS = 'macOS   [#include %datatypes/image.reds]	;-- temporary
	#if OS = 'Linux   [#include %datatypes/image.reds]
	#if OS = 'FreeBSD [#include %datatypes/image.reds]
	#if OS = 'NetBSD  [#include %datatypes/image.reds]

	;-- Debugging helpers --
	
	#include %debug-tools.reds
	
	;-- Core --
	#include %actions.reds
	#include %natives.reds
	#include %parse.reds
	#include %crypto.reds
	#include %random.reds
	#include %stack.reds
	#include %interpreter.reds
	#include %lexer.reds
	#include %tokenizer.reds
	#include %simple-io.reds							;-- temporary file IO support
	#include %clipboard.reds
	#include %redbin.reds
	#include %utils.reds
	#include %call.reds
	#include %compress.reds
	#include %collector.reds
	#include %wcwidth.reds

	_root:	 	declare red-block!						;-- statically alloc root cell for bootstrapping
	root:	 	as red-block! 0							;-- root block
	symbols: 	as red-block! 0 						;-- symbols table
	global-ctx: as node! 0								;-- global context
	arg-stk:	as red-block!	0						;-- argument stack (should never be relocated)
	call-stk:	as red-block!	0						;-- call stack (should never be relocated)
	stk-bottom: system/stack/top

	verbosity:  0
	boot?: 		no

	;-- Booting... --
	
	init: does [
		boot?: yes
		dyn-print/init
		platform/init
		_random/init
		init-mem										;@@ needs a local context
		externals/init
		
		name-table: as names! allocate TYPE_TOTAL_COUNT * size? names!	 ;-- datatype names table
		action-table: as int-ptr! allocate 256 * TYPE_TOTAL_COUNT * size? pointer! ;-- actions jump table	

		datatype/init
		unset/init
		none/init
		logic/init
		_series/init
		block/init
		string/init
		binary/init
		integer/init
		symbol/init
		_context/init
		word/init
		lit-word/init
		set-word/init
		get-word/init
		refinement/init
		char/init
		native/init
		action/init
		op/init
		path/init
		lit-path/init
		set-path/init
		get-path/init
		_function/init
		routine/init
		paren/init
		issue/init
		url/init
		file/init										;-- file! inherits from url!
		object/init
		bitset/init
		triple/init
		float/init
		typeset/init
		error/init
		vector/init
		map/init
		hash/init
		pair/init
		percent/init
		tuple/init
		time/init
		tag/init
		email/init
		handle/init
		date/init
		port/init
		money/init
		ref/init
		point2D/init
		point3D/init
		#if OS = 'Windows [								;-- temporary
			#if draw-engine <> 'GDI+ [OS-image/init]
			image/init
		]
		#if OS = 'macOS   [image/init]					;-- temporary
		#if OS = 'Linux   [image/init]					;-- temporary
		
		actions/init
		
		;-- initialize memory before anything else
		alloc-node-frame nodes-per-frame				;-- 10k nodes
		alloc-series-frame								;-- first frame of 1MB

		root:		block/make-fixed null ***-root-size
		arg-stk:	block/make-fixed root 2000
		call-stk:	block/make-fixed root 2500			;-- 2000 call slots (20b/slot)
		symbols: 	block/make-in root 4000
		global-ctx: _context/create 4000 no no null CONTEXT_GLOBAL

		case-folding/init
		symbol/table: _hashtable/init 4000 symbols HASH_TABLE_SYMBOL HASH_SYMBOL_BLOCK

		datatype/make-words								;-- build datatype names as word! values
		words/build										;-- create symbols used internally
		refinements/build								;-- create refinements used internally
		issues/build									;-- create issues used internally
		natives/init									;-- native specific init code
		parser/init
		ownership/init
		crypto/init
		compressor/init
		ext-process/init
		
		stack/init
		lexer/init
		redbin/boot-load system/boot-data no
		interpreter/init
		references/init
		collector/init
		
		#if debug? = yes [
			datatype/verbose:	verbosity
			unset/verbose:		verbosity
			none/verbose:		verbosity
			logic/verbose:		verbosity
			_series/verbose:	verbosity
			block/verbose:		verbosity
			binary/verbose:		verbosity
			string/verbose:		verbosity
			integer/verbose:	verbosity
			symbol/verbose:		verbosity
			_context/verbose:	verbosity
			word/verbose:		verbosity
			set-word/verbose:	verbosity
			refinement/verbose:	verbosity
			char/verbose:		verbosity
			path/verbose:		verbosity
			lit-path/verbose:	verbosity
			set-path/verbose:	verbosity
			get-path/verbose:	verbosity
			_function/verbose:	verbosity
			routine/verbose:	verbosity
			paren/verbose:		verbosity
			issue/verbose:		verbosity
			file/verbose:		verbosity
			url/verbose:		verbosity
			object/verbose:		verbosity
			bitset/verbose:		verbosity
			float/verbose:		verbosity
			typeset/verbose:	verbosity
			error/verbose:		verbosity
			vector/verbose:		verbosity
			map/verbose:		verbosity
			hash/verbose:		verbosity
			triple/verbose:		verbosity
			pair/verbose:		verbosity
			percent/verbose:	verbosity
			tuple/verbose:		verbosity
			time/verbose:		verbosity
			tag/verbose:		verbosity
			email/verbose:		verbosity
			handle/verbose:		verbosity
			date/verbose:		verbosity
			port/verbose:		verbosity
			money/verbose:		verbosity
			ref/verbose:		verbosity
			point2D/verbose:	verbosity
			point3D/verbose:	verbosity
			#if OS = 'Windows [image/verbose: verbosity]
			#if OS = 'macOS   [image/verbose: verbosity]

			actions/verbose:	verbosity
			natives/verbose:	verbosity
			;parser/verbose:	verbosity

			stack/verbose:		verbosity
			unicode/verbose:	verbosity
		]
	]
	
	cleanup: does [
		#if debug? = yes [references/check-leaks]
		free-all										;-- Red allocator's memory freeing
		heap-free-all									;-- malloc-ed buffers freeing.
	]
	
	#if type = 'dll [
		boot: does [
			***-boot-rs
			red/init
			***-main
		]
	]
]