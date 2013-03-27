Red/System [
	Title:   "Red runtime macro definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %macros.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#enum datatypes! [
	TYPE_VALUE
	TYPE_DATATYPE
	TYPE_UNSET
	TYPE_NONE
	TYPE_LOGIC
	TYPE_BLOCK
	TYPE_STRING
	TYPE_INTEGER
	TYPE_SYMBOL
	TYPE_CONTEXT
	TYPE_WORD
	TYPE_SET_WORD
	TYPE_LIT_WORD
	TYPE_GET_WORD
	TYPE_REFINEMENT	
	TYPE_CHAR
	TYPE_NATIVE
	TYPE_ACTION
	TYPE_OP
	TYPE_FUNCTION
	TYPE_PATH
	TYPE_LIT_PATH
	TYPE_SET_PATH
	TYPE_GET_PATH
	TYPE_PAREN
	TYPE_ROUTINE
	TYPE_ISSUE
	TYPE_FILE
	
	TYPE_TYPESET
	TYPE_ERROR

	TYPE_BINARY

	TYPE_CLOSURE
	
	TYPE_OBJECT
	TYPE_PORT
	TYPE_BITSET
	TYPE_FLOAT
]

#enum actions! [

	;-- General actions --
	ACT_MAKE: 	1										;-- used as index in action-table (one-based)
	ACT_RANDOM
	ACT_REFLECT
	ACT_TO
	ACT_FORM
	ACT_MOLD
	ACT_GETPATH
	ACT_SETPATH
	ACT_COMPARE
	
	;-- Scalar actions --
	ACT_ABSOLUTE
	ACT_ADD
	ACT_DIVIDE
	ACT_MULTIPLY
	ACT_NEGATE
	ACT_POWER
	ACT_REMAINDER
	ACT_ROUND
	ACT_SUBTRACT
	ACT_EVEN?
	ACT_ODD?
	
	;-- Bitwise actions --
	ACT_AND~
	ACT_COMPLEMENT
	ACT_OR~
	ACT_XOR~
	
	;-- Series actions --
	ACT_APPEND
	ACT_AT
	ACT_BACK
	ACT_CHANGE
	ACT_CLEAR
	ACT_COPY
	ACT_FIND
	ACT_HEAD
	ACT_HEAD?
	ACT_INDEX?
	ACT_INSERT
	ACT_LENGTH?
	ACT_NEXT
	ACT_PICK
	ACT_POKE
	ACT_REMOVE
	ACT_REVERSE
	ACT_SELECT
	ACT_SORT
	ACT_SKIP
	ACT_SWAP
	ACT_TAIL
	ACT_TAIL?
	ACT_TAKE
	ACT_TRIM
	
	;-- I/O actions --
	ACT_CREATE
	ACT_CLOSE
	ACT_DELETE
	ACT_MODIFY
	ACT_OPEN
	ACT_OPEN?
	ACT_QUERY
	ACT_READ
	ACT_RENAME
	ACT_UPDATE
	ACT_WRITE

	;ACT_APPLY										;; add it? @@
]

#enum natives! [
	NAT_IF
	NAT_UNLESS
	NAT_EITHER
	NAT_ANY
	NAT_ALL
	NAT_WHILE
	NAT_UNTIL
	NAT_LOOP
	NAT_REPEAT
	NAT_FOREACH
	NAT_FORALL
	NAT_FUNC
	NAT_FUNCTION
	NAT_DOES
	NAT_HAS
	NAT_EXIT
	NAT_RETURN
	NAT_SWITCH
	NAT_CASE
	NAT_DO
	NAT_GET
	NAT_SET
	NAT_PRINT
	NAT_PRIN
	NAT_EQUAL?
	NAT_NOT_EQUAL?
	NAT_STRICT_EQUAL?
	NAT_LESSER?
	NAT_GREATER?
	NAT_LESSER_OR_EQUAL?
	NAT_GREATER_OR_EQUAL?
	NAT_SAME?
	NAT_NOT
	NAT_HALT
	NAT_TYPE?
	NAT_LOAD
	NAT_REDUCE
	NAT_COMPOSE
	NAT_STATS
	NAT_SET_ANSI_COLOR
]

#enum math-op! [
	OP_ADD
	OP_SUB
	OP_MUL
	OP_DIV
]

#enum comparison-op! [
	COMP_EQUAL
	COMP_NOT_EQUAL
	COMP_STRICT_EQUAL
	COMP_LESSER
	COMP_LESSER_EQUAL
	COMP_GREATER
	COMP_GREATER_EQUAL
]

#define NATIVES_NB		100							;-- max number of natives (arbitrary set)
#define ACTIONS_NB		60							;-- number of actions
#define INHERIT_ACTION	-1							;-- placeholder for letting parent's action pass through

#either debug? = yes [
	#define ------------| 	print-line
][
	#define ------------| 	comment
]

#define TYPE_OF(value)		(value/header and get-type-mask)
#define GET_BUFFER(series)  (as series! series/node/value)
#define GET_UNIT(series)	(series/flags and get-unit-mask)
#define ALLOC_TAIL(series)	[alloc-at-tail series]
#define FLAG_SET?(flag)		(flags and flag <> 0)
#define OPTION?(ref-ptr)	(ref-ptr > stack/arguments)	;-- a bit inelegant, but saves a lot of code
#define ON_STACK?(ctx)		(ctx/header and flag-series-stk <> 0)
#define EQUAL_SYMBOLS?(a b) ((symbol/resolve a) = (symbol/resolve b))
#define EQUAL_WORDS?(a b) 	((symbol/resolve a/symbol) = (symbol/resolve b/symbol))

#define SET_RETURN(value)	[stack/set-last as red-value! value]

#define --NOT_IMPLEMENTED--	[
	print-line "Error: feature not implemented yet!"
	halt
]

#define RETURN_COMPARE_OTHER [
	return switch op [
			COMP_EQUAL
			COMP_STRICT_EQUAL [false]
			COMP_NOT_EQUAL 	  [true]
			default [
				--NOT_IMPLEMENTED--					;@@ add error handling
				false
			]
		]
]

#if debug? = yes [
	#define dump4			[dump-hex4 as int-ptr!]
	#define dump1			[dump-hex  as byte-ptr!]
]
