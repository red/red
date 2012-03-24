Red/System [
	Title:   "Red runtime wrapper"
	Author:  "Nenad Rakocevic"
	File: 	 %red.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#enum datatypes! [
	RED_TYPE_DATATYPE
	RED_TYPE_UNSET
	RED_TYPE_NONE
	RED_TYPE_LOGIC
	RED_TYPE_BLOCK
	RED_TYPE_PAREN
	RED_TYPE_INTEGER
	RED_TYPE_CONTEXT
	RED_TYPE_WORD
	RED_TYPE_SET_WORD
	RED_TYPE_GET_WORD
	RED_TYPE_LIT_WORD
	RED_TYPE_REFINEMENT
	RED_TYPE_BINARY
	RED_TYPE_STRING
	RED_TYPE_CHAR
	RED_TYPE_ISSUE
	RED_TYPE_PATH
	RED_TYPE_SET_PATH
	RED_TYPE_LIT_PATH
	RED_TYPE_NATIVE
	RED_TYPE_ACTION
	RED_TYPE_FUNCTION
	RED_TYPE_OBJECT
	RED_TYPE_PORT
	RED_TYPE_BITSET
	RED_TYPE_FLOAT
]

;#include %macro-defs.reds
#include %utils.reds
#include %imports.reds
;#include %threads.reds
#include %allocator.reds
;#include %collector.reds
;#include %tokenizer.reds

#define series!		series-buffer! 

#include %datatypes/value.reds
#include %datatypes/datatype.reds
#include %datatypes/unset.reds
#include %datatypes/none.reds
#include %datatypes/logic.reds
#include %datatypes/block.reds
;#include %datatypes/context.reds
;#include %datatypes/word.reds
#include %datatypes/integer.reds
