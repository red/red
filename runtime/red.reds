Red/System [
	Title:   "Red runtime wrapper"
	Author:  "Nenad Rakocevic"
	File: 	 %red.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
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
	
	#switch OS [										;-- loading OS-specific bindings
		Windows  [#include %platform/win32.reds]
		Syllable [#include %platform/syllable.reds]
		MacOSX	 [#include %platform/darwin.reds]
		FreeBSD  [#include %platform/freebsd.reds]
		#default [#include %platform/linux.reds]
	]
	
	;#include %threads.reds
	#include %allocator.reds
	;#include %collector.reds
	#include %crush.reds
	
	;-- Datatypes --
	
	#include %datatypes/structures.reds
	#include %datatypes/common.reds
	#include %unicode.reds
	#include %case-folding.reds
	#include %sort.reds
	#include %hashtable.reds
	#include %ownership.reds
	
	;--------------------------------------------
	;-- Import OS dependent image functions
	;-- load-image: func [								;-- return handle
	;-- 	filename [c-string!]
	;-- 	return:  [integer!]
	;-- ]
	;--------------------------------------------
	#switch OS [
		Windows  [#include %platform/image-gdiplus.reds]
		Syllable []
		MacOSX	 [#include %platform/image-quartz.reds]
		FreeBSD  []
		#default []
	]
	
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
	#include %datatypes/point.reds
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
	#if OS = 'Windows [#include %datatypes/image.reds]	;-- temporary
	#if OS = 'MacOSX  [#include %datatypes/image.reds]	;-- temporary

	;-- Debugging helpers --
	
	#include %debug-tools.reds
	
	;-- Core --
	#include %actions.reds
	#include %natives.reds
	#include %parse.reds
	#include %random.reds
	#include %crypto.reds
	#include %stack.reds
	#include %interpreter.reds
	#include %simple-io.reds							;-- temporary file IO support
	#include %clipboard.reds
	#include %redbin.reds
	#include %utils.reds
	#include %call.reds

	_root:	 	declare red-block!						;-- statically alloc root cell for bootstrapping
	root:	 	as red-block! 0							;-- root block
	symbols: 	as red-block! 0 						;-- symbols table
	global-ctx: as node! 0								;-- global context
	verbosity:  0

	;-- Booting... --
	
	init: does [
		platform/init
		_random/init
		init-mem										;@@ needs a local context
		
		name-table: as names! allocate 50 * size? names!	 ;-- datatype names table
		action-table: as int-ptr! allocate 256 * 50 * size? pointer! ;-- actions jump table	

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
		point/init
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
		#if OS = 'Windows [image/init]					;-- temporary
		#if OS = 'MacOSX [image/init]					;-- temporary
		
		actions/init
		
		;-- initialize memory before anything else
		alloc-node-frame nodes-per-frame				;-- 10k nodes
		alloc-series-frame								;-- first frame of 1MB

		root:	 	block/make-in null 2000	
		symbols: 	block/make-in root 1000
		global-ctx: _context/create 1000 no no

		case-folding/init
		symbol/table: _hashtable/init 1000 symbols HASH_TABLE_SYMBOL 1

		datatype/make-words								;-- build datatype names as word! values
		words/build										;-- create symbols used internally
		refinements/build								;-- create refinements used internally
		issues/build									;-- create issues used internally
		natives/init									;-- native specific init code
		parser/init
		ownership/init
		crypto/init
		ext-process/init
		
		stack/init
		redbin/boot-load system/boot-data no
		
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
			point/verbose:		verbosity
			pair/verbose:		verbosity
			percent/verbose:	verbosity
			tuple/verbose:		verbosity
			time/verbose:		verbosity
			tag/verbose:		verbosity
			email/verbose:		verbosity
			handle/verbose:		verbosity
			#if OS = 'Windows [image/verbose: verbosity]
			#if OS = 'MacOSX [image/verbose: verbosity]

			actions/verbose:	verbosity
			natives/verbose:	verbosity
			;parser/verbose:	verbosity

			stack/verbose:		verbosity
			unicode/verbose:	verbosity
		]
	]
	
	cleanup: does [
		free-all										;-- Allocator's memory freeing
		free as byte-ptr! natives/table
		free as byte-ptr! actions/table
		free as byte-ptr! _random/table
		free as byte-ptr! name-table
		free as byte-ptr! action-table
		free as byte-ptr! cycles/stack
		free as byte-ptr! crypto/crc32-table
	]
	
	#if type = 'dll [
		boot: does [
			***-boot-rs
			red/init
			***-main
		]
	]
]