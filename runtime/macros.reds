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
	TYPE_URL
	TYPE_BITSET
	TYPE_POINT
	TYPE_OBJECT
	TYPE_FLOAT
	TYPE_PAIR
		
	TYPE_BINARY
	
	TYPE_TYPESET
	TYPE_ERROR

	TYPE_CLOSURE

	TYPE_PORT

	
]

#enum actions! [

	;-- General actions --
	ACT_MAKE: 	1										;-- used as index in action-table (one-based)
	ACT_RANDOM
	ACT_REFLECT
	ACT_TO
	ACT_FORM
	ACT_MOLD

	ACT_EVALPATH
	ACT_SETPATH											;@@ Deprecate it?
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

	;ACT_APPLY											;; add it? @@
]

#enum natives! [
	NAT_IF: 	1										;-- one-based index
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
	NAT_REDUCE
	NAT_COMPOSE
	NAT_STATS
	NAT_BIND
	NAT_IN
	NAT_PARSE
	NAT_UNION
	NAT_INTERSECT
	NAT_UNIQUE
	NAT_DIFFERENCE
	NAT_COMPLEMENT?
	NAT_DEHEX
	NAT_NEGATIVE?
	NAT_POSITIVE?
	NAT_MAX
	NAT_MIN
	NAT_SHIFT
	NAT_TO_HEX
	NAT_SINE
	NAT_COSINE
	NAT_TANGENT
	NAT_ARCSINE
	NAT_ARCCOSINE
	NAT_ARCTANGENT
	NAT_NAN?
	NAT_LOG_2
	NAT_LOG_10
	NAT_LOG_E
	NAT_EXP
	NAT_SQUARE_ROOT
]

#enum math-op! [
	OP_ADD
	OP_SUB
	OP_MUL
	OP_DIV
	OP_REM
	;-- bitwise op!
	OP_OR
	OP_AND
	OP_XOR
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

#enum exceptions! [
	NO_EXCEPTION
	THROWN_EXIT
	THROWN_RETURN
]

#define NATIVES_NB		100							;-- max number of natives (arbitrary set)
#define ACTIONS_NB		60							;-- number of actions (exact number)
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
#define TO_CTX(node)		(as red-context! ((as series! node/value) + 1))
#define GET_CTX(obj)		(as red-context! ((as series! obj/ctx/value) + 1))
#define FLAG_NOT?(s)		(s/flags and flag-bitset-not <> 0)
#define SET_RETURN(value)	[stack/set-last as red-value! value]

#define WHITE_CHAR?(char)	[
	any [
		all [0 < char char < 33]			;-- All white chars: NL, CR, BS, etc...
		char = 133							;-- #"^(85)"
		char = 160							;-- #"^(A0)"
		char = 5760							;-- #"^(1680)"
		char = 6158							;-- #"^(180E)"
		all [8192 <= char char <= 8202]		;-- #"^(2000)" - #"^(200A)"
		char = 8232							;-- #"^(2028)"
		char = 8233							;-- #"^(2029)"
		char = 8239							;-- #"^(202F)"
		char = 8287							;-- #"^(205F)"
		char = 12288						;-- #"^(3000)"
	]
]

#define SPACE_CHAR?(char)	[
	any [
		char = 32							;-- #" "
		char = 9							;-- #"^-"
		char = 133							;-- #"^(85)"
		char = 160							;-- #"^(A0)"
		char = 5760							;-- #"^(1680)"
		char = 6158							;-- #"^(180E)"
		all [8192 <= char char <= 8202]		;-- #"^(2000)" - #"^(200A)"
		char = 8232							;-- #"^(2028)"
		char = 8233							;-- #"^(2029)"
		char = 8239							;-- #"^(202F)"
		char = 8287							;-- #"^(205F)"
		char = 12288						;-- #"^(3000)"
	]
]

#define ANY_SERIES?(type)	[
	any [
		type = TYPE_BLOCK
		type = TYPE_PAREN
		type = TYPE_PATH
		type = TYPE_LIT_PATH
		type = TYPE_SET_PATH
		type = TYPE_GET_PATH
		type = TYPE_STRING
		type = TYPE_FILE
		type = TYPE_URL
	]
]

#define BS_SET_BIT(array bit)  [
	pos: array + (bit >> 3)
	pos/value: pos/value or (as-byte 128 >> (bit and 7))
]

#define BS_CLEAR_BIT(array bit)  [
	pos: array + (bit >> 3)
	pos/value: pos/value and (as-byte 128 >> (bit and 7) xor 255)
]

#define BS_TEST_BIT(array bit set?)  [
	pos: array + (bit >> 3)
	set?: pos/value and (as-byte 128 >> (bit and 7)) <> null-byte
]

#define BS_PROCESS_SET_VIRTUAL(bs bit) [
	either not? [
		if virtual-bit? bs bit [return 1]
	][
		pbits: bound-check bs bit
	]
]

#define BS_PROCESS_CLEAR_VIRTUAL(bs bit) [
	either not? [
		pbits: bound-check bs bit
	][
		if virtual-bit? bs bit [return 0]
	]
]


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
			--NOT_IMPLEMENTED--							;@@ add error handling
			false
		]
	]
]

#if debug? = yes [
	#define dump4			[dump-hex4 as int-ptr!]
	#define dump1			[dump-hex  as byte-ptr!]
]
