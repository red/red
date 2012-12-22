Red/System [
	Title:   "Red runtime wrapper"
	Author:  "Nenad Rakocevic"
	File: 	 %red.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

red: context [

	;-- Runtime sub-system --
	
	#include %macros.reds
	#include %tools.reds
	
	#switch OS [										;-- loading OS-specific bindings
		Windows  [#include %platform/win32.reds]
		Syllable [#include %platform/syllable.reds]
		MacOSX	 [#include %platform/darwin.reds]
		#default [#include %platform/linux.reds]
	]
	platform/init
	
	;#include %threads.reds
	#include %allocator.reds
	;#include %collector.reds
	;#include %tokenizer.reds
	#include %unicode.reds
	
	;-- Datatypes --
	
	#include %datatypes/structures.reds
	#include %datatypes/common.reds
	
	#include %datatypes/datatype.reds
	#include %datatypes/unset.reds
	#include %datatypes/none.reds
	#include %datatypes/logic.reds
	#include %datatypes/block.reds
	#include %datatypes/string.reds
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
	
	;-- Debugging helpers --
	
	#include %debug-tools.reds
	
	;-- Core --
	#include %actions.reds
	#include %natives.reds
	
	;-- Booting... --
	
	;-- initialize memory before anything else
	alloc-node-frame nodes-per-frame					;-- 5k nodes
	alloc-series-frame									;-- first frame of 128KB
	
	_root:	 	declare red-block!						;-- statically alloc root cell for bootstrapping
	root:	 	block/make-in null 2000					;-- root block		
	symbols: 	block/make-in root 1000	 				;-- symbols table
	global-ctx: _context/create root 1000 no			;-- global context
	
	datatype/make-words									;-- build datatype names as word! values
	words/build											;-- create symbols used internally
	
	#include %stack.reds
	
	#if debug? = yes [
		verbosity: 0
		red/datatype/verbose:	verbosity
		red/unset/verbose:		verbosity
		red/none/verbose:		verbosity
		red/logic/verbose:		verbosity
		red/block/verbose:		verbosity
		red/string/verbose:		verbosity
		red/integer/verbose:	verbosity
		red/symbol/verbose:		verbosity
		red/_context/verbose:	verbosity
		red/word/verbose:		verbosity
		red/set-word/verbose:	verbosity
		red/refinement/verbose:	verbosity
		red/char/verbose:		verbosity
		red/path/verbose:		verbosity
		red/lit-path/verbose:	verbosity
		red/set-path/verbose:	verbosity
		red/get-path/verbose:	verbosity
		red/_function/verbose:	verbosity
		red/routine/verbose:	verbosity
		red/paren/verbose:		verbosity
		
		red/actions/verbose:	verbosity
		red/natives/verbose:	verbosity
		
		red/stack/verbose:		verbosity
		red/unicode/verbose:	verbosity
	]

]