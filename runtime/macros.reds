Red/System [
	Title:   "Red runtime macro definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %macros.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum datatypes! [										;-- Order must not be changed!
	TYPE_VALUE											;-- 00		00
	TYPE_DATATYPE										;-- 01		01
	TYPE_UNSET											;-- 02		02
	TYPE_NONE											;-- 03		03
	TYPE_LOGIC											;-- 04		04
	TYPE_BLOCK											;-- 05		05
	TYPE_PAREN											;-- 06		06
	TYPE_STRING											;-- 07		07
	TYPE_FILE											;-- 08		08
	TYPE_URL											;-- 09		09
	TYPE_CHAR											;-- 0A		10
	TYPE_INTEGER										;-- 0B		11
	TYPE_FLOAT											;-- 0C		12
	TYPE_SYMBOL											;-- 0D		13
	TYPE_CONTEXT										;-- 0E		14
	TYPE_WORD											;-- 0F		15
	TYPE_SET_WORD										;-- 10		16
	TYPE_LIT_WORD										;-- 11		17
	TYPE_GET_WORD										;-- 12		18
	TYPE_REFINEMENT										;-- 13		19
	TYPE_ISSUE											;-- 14		20
	TYPE_NATIVE											;-- 15		21
	TYPE_ACTION											;-- 16		22
	TYPE_OP												;-- 17		23
	TYPE_FUNCTION										;-- 18		24
	TYPE_PATH											;-- 19		25
	TYPE_LIT_PATH										;-- 1A		26
	TYPE_SET_PATH										;-- 1B		27
	TYPE_GET_PATH										;-- 1C		28
	TYPE_ROUTINE										;-- 1D		29
	TYPE_BITSET											;-- 1E		30
	TYPE_POINT											;-- 1F		31
	TYPE_OBJECT											;-- 20		32
	TYPE_TYPESET										;-- 21		33
	TYPE_ERROR											;-- 22		34
	TYPE_VECTOR											;-- 23		35
	TYPE_HASH											;-- 24		36
	TYPE_PAIR											;-- 25		37
	TYPE_PERCENT										;-- 26		38
	TYPE_TUPLE											;-- 27		39
	TYPE_MAP											;-- 28		40
	TYPE_BINARY											;-- 29		41
	TYPE_SERIES											;-- 2A		42
	TYPE_TIME											;-- 2B		43
	TYPE_TAG											;-- 2C		44
	TYPE_EMAIL											;-- 2D		45
	TYPE_HANDLE											;-- 2E		46
	TYPE_IMAGE											;-- 2F		47
	TYPE_EVENT											
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
	ACT_MOVE
	ACT_NEXT
	ACT_PICK
	ACT_POKE
	ACT_PUT
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
	NAT_FOREVER
	NAT_FOREACH
	NAT_FORALL
	NAT_REMOVE_EACH
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
	NAT_EXCLUDE
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
	NAT_ARCTANGENT2
	NAT_NAN?
	NAT_LOG_2
	NAT_LOG_10
	NAT_LOG_E
	NAT_EXP
	NAT_SQUARE_ROOT
	NAT_CONSTRUCT
	NAT_VALUE?
	NAT_TRY
	NAT_UPPERCASE
	NAT_LOWERCASE
	NAT_AS_PAIR
	NAT_BREAK
	NAT_CONTINUE
	NAT_EXIT
	NAT_RETURN
	NAT_THROW
	NAT_CATCH
	NAT_EXTEND
	NAT_DEBASE
	NAT_TO_LOCAL_FILE
	NAT_WAIT
	NAT_CHECKSUM
	NAT_UNSET
	NAT_NEW_LINE
	NAT_NEW_LINE?
	NAT_ENBASE
	NAT_CONTEXT?
	NAT_SET_ENV
	NAT_GET_ENV
	NAT_LIST_ENV
	NAT_NOW
	NAT_SIGN?
	NAT_AS
	NAT_CALL
	NAT_ZERO?
	NAT_SIZE?
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
	;-- set op!
	OP_UNIQUE
	OP_UNION
	OP_INTERSECT
	OP_EXCLUDE
	OP_DIFFERENCE
]

#enum comparison-op! [
	COMP_EQUAL
	COMP_NOT_EQUAL
	COMP_STRICT_EQUAL
	COMP_LESSER
	COMP_LESSER_EQUAL
	COMP_GREATER
	COMP_GREATER_EQUAL
	COMP_SORT
	COMP_CASE_SORT
	COMP_SAME
]

#enum exceptions! [
	RED_NO_EXCEPTION
	OS_ERROR_VMEM:					100000000
	OS_ERROR_VMEM_RELEASE_FAILED:	100000001
	OS_ERROR_VMEM_OUT_OF_MEMORY:	100000002
	OS_ERROR_VMEM_ALL:				100000010
	RED_INT_OVERFLOW:				190000000
	RED_THROWN_THROW:				195939000
	RED_THROWN_EXIT
	RED_THROWN_RETURN
	RED_THROWN_CONTINUE
	RED_THROWN_BREAK
	RED_THROWN_ERROR:				195939070		;-- #0BADCAFE (keep it positive)
]

#define NATIVES_NB		110							;-- max number of natives (arbitrary set)
#define ACTIONS_NB		62							;-- number of actions (exact number)
#define INHERIT_ACTION	-1							;-- placeholder for letting parent's action pass through

#either verbosity >= 1 [
	#define ------------| 	print-line
][
	#define ------------| 	comment
]

#define TYPE_OF(value)		(value/header and get-type-mask)
#define TUPLE_SIZE?(value)	(value/header >> 19 and 15)
#define GET_TUPLE_ARRAY(tp) [(as byte-ptr! tp) + 4]
#define SET_TUPLE_SIZE(t n) [t/header: t/header and FF87FFFFh or (n << 19)]
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
#define TO_ERROR(cat id)	[#in system/catalog/errors cat #in system/catalog/errors/cat id]

#define PLATFORM_TO_CSTR(cstr str len) [	;-- len in bytes
	len: -1
	#either OS = 'Windows [
		cstr: unicode/to-utf16-len str :len yes
		len: len * 2
	][
		cstr: unicode/to-utf8 str :len
	]
]

#define PLATFORM_LOAD_STR(str cstr len) [
	#either OS = 'Windows [
		str: string/load cstr len UTF-16LE
	][
		str: string/load cstr len UTF-8
	]
]

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
		type = TYPE_HASH
		type = TYPE_PAREN
		type = TYPE_PATH
		type = TYPE_LIT_PATH
		type = TYPE_SET_PATH
		type = TYPE_GET_PATH
		type = TYPE_STRING
		type = TYPE_FILE
		type = TYPE_URL
		type = TYPE_BINARY
		type = TYPE_IMAGE
		type = TYPE_TAG
		type = TYPE_EMAIL
	]
]

#define ANY_BLOCK_STRICT?(type)	[
	any [
		type = TYPE_BLOCK
		type = TYPE_PAREN
		type = TYPE_PATH
		type = TYPE_GET_PATH
		type = TYPE_SET_PATH
		type = TYPE_LIT_PATH
	]
]

#define ANY_BLOCK?(type)	[
	any [
		type = TYPE_BLOCK
		type = TYPE_PAREN
		type = TYPE_HASH
		type = TYPE_PATH
		type = TYPE_GET_PATH
		type = TYPE_SET_PATH
		type = TYPE_LIT_PATH
	]
]

#define ANY_PATH?(type)	[
	any [
		type = TYPE_PATH
		type = TYPE_GET_PATH
		type = TYPE_SET_PATH
		type = TYPE_LIT_PATH
	]
]

#define ANY_STRING?(type)	[
	any [
		type = TYPE_STRING
		type = TYPE_FILE
		type = TYPE_URL
		type = TYPE_TAG
		type = TYPE_EMAIL
	]
]

#define TYPE_ANY_STRING [					;-- To be used in SWITCH cases
	TYPE_STRING
	TYPE_FILE
	TYPE_URL
	TYPE_TAG
	TYPE_EMAIL	
]

#define TYPE_ANY_BLOCK [					;-- To be used in SWITCH cases
	TYPE_BLOCK
	TYPE_PAREN
	TYPE_HASH
	TYPE_PATH
	TYPE_GET_PATH
	TYPE_SET_PATH
	TYPE_LIT_PATH
]

#define TYPE_ANY_LIST [						;-- To be used in SWITCH cases
	TYPE_BLOCK
	TYPE_HASH
	TYPE_PAREN
]

#define TYPE_ANY_PATH [						;-- To be used in SWITCH cases
	TYPE_PATH
	TYPE_GET_PATH
	TYPE_SET_PATH
	TYPE_LIT_PATH
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

#define BS_TEST_BIT_ALT(ts bit) [
	pos: ((as byte-ptr! ts) + 4) + (bit >> 3)
	pos/value and (as-byte 128 >> (bit and 7)) <> null-byte
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

#define GET_SIZE_FROM(spec) [
	either TYPE_OF(spec) = TYPE_FLOAT [
		fl: as red-float! spec
		as-integer fl/value
	][
		int: as red-integer! spec
		int/value
	]
]

#define ERR_INVALID_REFINEMENT_ARG(refine arg) [
	fire [
		TO_ERROR(script invalid-refine-arg)
		refine
		arg
	]
]

#define ERR_EXPECT_ARGUMENT(type arg-idx) [
	fire [
		TO_ERROR(script expect-arg)
		stack/get-call
		datatype/push type
		error/get-call-argument arg-idx
	]
]

#define --NOT_IMPLEMENTED--	[
	fire [TO_ERROR(internal not-done)]
]

#define RETURN_COMPARE_OTHER [
	return -2
]

#define CHECK_COMPARE_OTHER(type) [
	if all [
		TYPE_OF(str2) <> type
		any [
			all [
				op <> COMP_EQUAL
				op <> COMP_NOT_EQUAL
			]
			all [
				TYPE_OF(str2) <> TYPE_STRING		;@@ use ANY_STRING?
				TYPE_OF(str2) <> TYPE_FILE
				TYPE_OF(str2) <> TYPE_URL
				TYPE_OF(str2) <> TYPE_TAG
				TYPE_OF(str2) <> TYPE_EMAIL
			]
		]
	][RETURN_COMPARE_OTHER]
]

#define SIGN_COMPARE_RESULT(a b) [
	either a < b [-1][either a > b [1][0]]
]

#define IMAGE_WIDTH(size)  (size and FFFFh) 
#define IMAGE_HEIGHT(size) (size >> 16)

#if debug? = yes [
	#define dump4	[dump-hex4 as int-ptr!]
	#define dump1	[dump-hex  as byte-ptr!]
]
