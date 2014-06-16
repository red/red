Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %boot.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

;-- datatype! is not defined here for obvious circular reference issue

unset!:			make datatype! #get-definition TYPE_UNSET
none!:			make datatype! #get-definition TYPE_NONE
logic!:			make datatype! #get-definition TYPE_LOGIC
block!:			make datatype! #get-definition TYPE_BLOCK
string!:		make datatype! #get-definition TYPE_STRING
integer!:		make datatype! #get-definition TYPE_INTEGER
;symbol!:		make datatype! #get-definition TYPE_SYMBOL
;context!:		make datatype! #get-definition TYPE_CONTEXT
word!:			make datatype! #get-definition TYPE_WORD
;error!:		make datatype! #get-definition TYPE_ERROR
;typeset!:		make datatype! #get-definition TYPE_TYPESET
file!:			make datatype! #get-definition TYPE_FILE
url!:			make datatype! #get-definition TYPE_URL

set-word!:		make datatype! #get-definition TYPE_SET_WORD
get-word!:		make datatype! #get-definition TYPE_GET_WORD
lit-word!:		make datatype! #get-definition TYPE_LIT_WORD
refinement!:	make datatype! #get-definition TYPE_REFINEMENT
binary!:		make datatype! #get-definition TYPE_BINARY
paren!:			make datatype! #get-definition TYPE_PAREN
char!:			make datatype! #get-definition TYPE_CHAR
issue!:			make datatype! #get-definition TYPE_ISSUE
path!:			make datatype! #get-definition TYPE_PATH
set-path!:		make datatype! #get-definition TYPE_SET_PATH
get-path!:		make datatype! #get-definition TYPE_GET_PATH
lit-path!:		make datatype! #get-definition TYPE_LIT_PATH
native!:		make datatype! #get-definition TYPE_NATIVE
action!:		make datatype! #get-definition TYPE_ACTION
op!:			make datatype! #get-definition TYPE_OP
function!:		make datatype! #get-definition TYPE_FUNCTION
;closure!:		make datatype! #get-definition TYPE_CLOSURE
routine!:		make datatype! #get-definition TYPE_ROUTINE
object!:		make datatype! #get-definition TYPE_OBJECT
;port!:			make datatype! #get-definition TYPE_PORT
bitset!:		make datatype! #get-definition TYPE_BITSET
;float!:		make datatype! #get-definition TYPE_FLOAT
point!:			make datatype! #get-definition TYPE_POINT

none:  			make none! 0
true:  			make logic! 1
false: 			make logic! 0


;------------------------------------------
;-				Actions					  -
;------------------------------------------

;; Warning: do not define any function of any kind before MAKE definition

make: make action! [[									;--	this one works!	;-)
		"Returns a new value made from a spec for that value's type."
		type	 [any-type!] "The datatype or a prototype value."
		spec	 [any-type!] "The specification	of the new value."
		return:  [any-type!] "Returns the specified datatype."
	]
	#get-definition ACT_MAKE
]

random: make action! [[
		"Returns a random value of the same datatype; or shuffles series."
		value   [any-type!] "Maximum value of result (modified when series)"
		/seed   "Restart or randomize"
		/secure "TBD: Returns a cryptographically secure random number"
		/only	"Pick a random value from a series"
		return:	[any-type!]
	]
	#get-definition ACT_RANDOM
]

reflect: make action! [[
		"Returns internal details about a value via reflection."
		value	[any-type!]
		field 	[word!] "spec, body, words, etc. Each datatype defines its own reflectors"
	]
	#get-definition ACT_REFLECT
]

to: make action! [[
		"Converts to a specified datatype."
		type	[any-type!] "The datatype or example value"
		spec 	[any-type!] "The attributes of the new value"
	]
	#get-definition ACT_TO
]

form: make action! [[
		"Returns a user-friendly string representation of a value."
		value	  [any-type!]
		/part "Limit the length of the result"
			limit [integer!]
		return:	  [string!]
	]
	#get-definition ACT_FORM
]

mold: make action! [[
		"Returns a source format string representation of a value."
		value	  [any-type!]
		/only "Exclude outer brackets if value is a block"
		/all  "TBD: Return value in loadable format"
		/flat "TBD: Exclude all indentation"
		/part "Limit the length of the result"
			limit [integer!]
		return:	  [string!]
	]
	#get-definition ACT_MOLD
]

;-- Scalar actions --

absolute: make action! [[
		"Returns the non-negative value."
		value	 [number!]
		return:  [number!]
	]
	#get-definition ACT_ABSOLUTE
]

add: make action! [[
		"Returns the sum of the two values."
		value1	 [number! char!]
		value2	 [number! char!]
		return:  [number! char!]
	]
	#get-definition ACT_ADD
]

divide: make action! [[
		"Returns the quotient of two values."
		value1	 [number! char!] "The dividend (numerator)."
		value2	 [number! char!] "The divisor (denominator)."
		return:  [number! char!]
	]
	#get-definition ACT_DIVIDE
]

multiply: make action! [[
		"Returns the product of two values."
		value1	 [number! char!]
		value2	 [number! char!]
		return:  [number! char!]
	]
	#get-definition ACT_MULTIPLY
]

negate: make action! [[
		"Returns the opposite (additive inverse) value."
		number 	 [number!]
		return:  [number!]
	]
	#get-definition ACT_NEGATE
]

power: make action! [[
		"Returns a number raised to a given power (exponent)."
		number	 [number!] "Base value."
		exponent [number!] "The power (index) to raise the base value by."
		return:	 [number!]
	]
	#get-definition ACT_POWER
]

remainder: make action! [[
		"Returns what is left over when one value is divided by another."
		value1 	 [number! char!]
		value2 	 [number! char!]
		return:  [number! char!]
	]
	#get-definition ACT_REMAINDER
]

modulo: func [
	"Compute a nonnegative remainder of A divided by B."
	a		[number!]
	b		[number!]
	return: [number!]
	/local r
][
	b: absolute b
    all [0 > r: a % b r: r + b]
    a: absolute a
    either all [a + r = (a + b) 0 < r + r - b] [r - b] [r]
]

round: make action! [[
		"(not yet implemented)"
		;"Returns the nearest integer. Halves round up (away from zero) by default."
		n		[number!]
		/to		"Return the nearest multiple of the scale parameter"
		scale	[number!] "Must be a non-zero value"
		/even		"Halves round toward even results"
		/down		"Round toward zero, ignoring discarded digits. (truncate)"
		/half-down	"Halves round toward zero"
		/floor		"Round in negative direction"
		/ceiling	"Round in positive direction"
		/half-ceiling "Halves round in positive direction"
	]
	#get-definition ACT_ROUND
]

subtract: make action! [[
		"Returns the difference between two values."
		value1	 [number! char!]
		value2	 [number! char!]
		return:  [number! char!]
	]
	#get-definition ACT_SUBTRACT
]

even?: make action! [[
		"Returns true if the number is evenly divisible by 2."
		number 	 [number! char!]
		return:  [number! char!]
	]
	#get-definition ACT_EVEN?
]

odd?: make action! [[
		"Returns true if the number has a remainder of 1 when divided by 2."
		number 	 [number! char!]
		return:  [number! char!]
	]
	#get-definition ACT_ODD?
]

;-- Bitwise actions --

and~: make action! [[
		"Returns the first value ANDed with the second."
		value1	[logic! integer! char! bitset! typeset!]
		value2	[logic! integer! char! bitset! typeset!]
		return:	[logic! integer! char! bitset! typeset!]
	]
	#get-definition ACT_AND~
]

complement: make action! [[
		"Returns the opposite (complementing) value of the input value."
		value	[logic! integer! bitset! typeset!]
		return: [logic! integer! bitset! typeset!]
	]
	#get-definition ACT_COMPLEMENT
]

or~: make action! [[
		"Returns the first value ORed with the second."
		value1	[logic! integer! char! bitset! typeset!]
		value2	[logic! integer! char! bitset! typeset!]
		return:	[logic! integer! char! bitset! typeset!]
	]
	#get-definition ACT_OR~
]

xor~: make action! [[
		"Returns the first value exclusive ORed with the second."
		value1	[logic! integer! char! bitset! typeset!]
		value2	[logic! integer! char! bitset! typeset!]
		return:	[logic! integer! char! bitset! typeset!]
	]
	#get-definition ACT_XOR~
]

;-- Series actions --

append: make action! [[
		"Inserts value(s) at series tail; returns series head."
		series	   [series!]
		value	   [any-type!]
		/part "Limit the number of values inserted"
			length [number! series!]
		/only "Insert block types as single values (overrides /part)"
		/dup  "Duplicate the inserted values"
			count  [number!]
		return:    [series!]
	]
	#get-definition ACT_APPEND
]

at: make action! [[
		"Returns a series at a given index."
		series	 [series!]
		index 	 [integer!]
		return:  [series!]
	]
	#get-definition ACT_AT
]

back: make action! [[
		"Returns a series at the previous index."
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_BACK
]

;change

clear: make action! [[
		"Removes series values from current index to tail; returns new tail."
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_CLEAR
]

copy: make action! [[
		"Returns a copy of a non-scalar value."
		value	 [series!]
		/part	 "Limit the length of the result"
			length [number! series!]
		/deep	 "Copy nested values"
		/types	 "Copy only specific types of non-scalar values"
			kind [datatype!]
		return:  [series!]
	]
	#get-definition ACT_COPY
]

find: make action! [[
		"Returns the series where a value is found, or NONE."
		series	 [series! none!]
		value 	 [any-type!]
		/part "Limit the length of the search"
			length [number! series!]
		/only "Treat a series search value as a single value"
		/case "Perform a case-sensitive search"
		/any  "TBD: Use * and ? wildcards in string searches"
		/with "TBD: Use custom wildcards in place of * and ?"
			wild [string!]
		/skip "Treat the series as fixed size records"
			size [integer!]
		/last "Find the last occurrence of value, from the tail"
		/reverse "Find the last occurrence of value, from the current index"
		/tail "Return the tail of the match found, rather than the head"
		/match "Match at current index only and return tail of match"
	]
	#get-definition ACT_FIND
]

head: make action! [[
		"Returns a series at its first index."
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_HEAD
]

head?: make action! [[
		"Returns true if a series is at its first index."
		series	 [series!]
		return:  [logic!]
	]
	#get-definition ACT_HEAD?
]

index?: make action! [[
		"Returns the current series index, relative to the head."
		series	 [series!]
		return:  [integer!]
	]
	#get-definition ACT_INDEX?
]

insert: make action! [[
		"Inserts value(s) at series index; returns series head."
		series	   [series!]
		value	   [any-type!]
		/part "Limit the number of values inserted"
			length [number! series!]
		/only "Insert block types as single values (overrides /part)"
		/dup  "Duplicate the inserted values"
			count  [number!]
		return:    [series!]
	]
	#get-definition ACT_INSERT
]

length?: make action! [[
		"Returns the number of values in the series, from the current index to the tail."
		series	 [series!]
		return:  [integer!]
	]
	#get-definition ACT_LENGTH?
]


next: make action! [[
		"Returns a series at the next index."
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_NEXT
]

pick: make action! [[
		"Returns the series value at a given index."
		series	 [series!]
		index 	 [integer! logic!]
		return:  [any-type!]
	]
	#get-definition ACT_PICK
]

poke: make action! [[
		"Replaces the series value at a given index, and returns the new value."
		series	 [series!]
		index 	 [integer! logic!]
		value 	 [any-type!]
		return:  [series!]
	]
	#get-definition ACT_POKE
]

remove: make action! [[
		"Returns the series at the same index after removing a value."
		series	 [series! none!]
		/part "Removes a number of values, or values up to the given series index"
			length [number! series!]
		return:  [series! none!]
	]
	#get-definition ACT_REMOVE
]

reverse: make action! [[
		"Reverses the order of elements; returns at same position."
		series	 [series! gob! tuple! pair!]
		/part "Limits to a given length or position"
			length [number! series!]
		return:  [series! gob! tuple! pair!]
	]
	#get-definition ACT_REVERSE
]

select: make action! [[
		"Find a value in a series and return the next value, or NONE."
		series	 [series! none!]
		value 	 [any-type!]
		/part "Limit the length of the search"
			length [number! series!]
		/only "Treat a series search value as a single value"
		/case "Perform a case-sensitive search"
		/any  "TBD: Use * and ? wildcards in string searches"
		/with "TBD: Use custom wildcards in place of * and ?"
			wild [string!]
		/skip "Treat the series as fixed size records"
			size [integer!]
		/last "Find the last occurrence of value, from the tail"
		/reverse "Find the last occurrence of value, from the current index"
		return:  [any-type!]
	]
	#get-definition ACT_SELECT
]


;sort

skip: make action! [[
		"Returns the series relative to the current index."
		series	 [series!]
		offset 	 [integer!]
		return:  [series!]
	]
	#get-definition ACT_SKIP
]

swap: make action! [[
		"Swaps elements between two series or the same series."
		series1  [series!]
		series2  [series!]
		return:  [series!]
	]
	#get-definition ACT_SWAP
]

tail: make action! [[
		"Returns a series at the index after its last value."
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_TAIL
]

tail?: make action! [[
		"Returns true if a series is past its last value."
		series	 [series!]
		return:  [logic!]
	]
	#get-definition ACT_TAIL?
]

take: make action! [[
		"Removes and returns one or more elements."
		series	 [series!]
		/part	 "Specifies a length or end position"
			length [number! series! pair!]
		/deep	 "Copy nested values"
		/last	 "Take it from the tail end"
	]
	#get-definition ACT_TAKE
]

trim: make action! [[
		"Removes space from a string or NONE from a block or object."
		series	[series! object! error! module!]
		/head	"Removes only from the head"
		/tail	"Removes only from the tail"
		/auto	"Auto indents lines relative to first line"
		/lines	"Removes all line breaks and extra spaces"
		/all	"Removes all whitespace"
		/with	"Same as /all, but removes characters in 'str'"
			str [char! string! binary! integer!]
	]
	#get-definition ACT_TRIM
]

;-- I/O actions --

;create
;close
;delete
;modify
;open
;open?
;query
;read
;rename
;update
;write
		

;------------------------------------------
;-				Natives					  -
;------------------------------------------

if: make native! [[
		"If condition is true, evaluate block; else return NONE."
		cond  	 [any-type!]
		then-blk [block!]
	]
	#get-definition NAT_IF
]

unless: make native! [[
		"If condition is not true, evaluate block; else return NONE."
		cond  	 [any-type!]
		then-blk [block!]
	]
	#get-definition NAT_UNLESS
]

either: make native! [[
		"If condition is true, eval true-block; else eval false-blk."
		cond  	  [any-type!]
		true-blk  [block!]
		false-blk [block!]
	]
	#get-definition NAT_EITHER
]
	
any: make native! [[
		"Evaluates, returning at the first that is true."
		conds [block!]
	]
	#get-definition NAT_ANY
]

all: make native! [[
		"Evaluates, returning at the first that is not true."
		conds [block!]
	]
	#get-definition NAT_ALL
]

while: make native! [[
		"Evaluates body until condition is true."
		cond [block!]
		body [block!]
	]
	#get-definition NAT_WHILE
]
	
until: make native! [[
		"Evaluates body until it is true."
		body [block!]
	]
	#get-definition NAT_UNTIL
]

loop: make native! [[
		"Evaluates body a number of times."
		count [integer!]
		body  [block!]
	]
	#get-definition NAT_LOOP
]

repeat: make native! [[
		"Evaluates body a number of times, tracking iteration count."
		'word [word!]    "Iteration counter; not local to loop"
		value [integer!] "Number of times to evaluate body"
		body  [block!]
	]
	#get-definition NAT_REPEAT
]

foreach: make native! [[
		"Evaluates body for each value in a series."
		'word  [word! block!]   "Word, or words, to set on each iteration"
		series [series!]
		body   [block!]
	]
	#get-definition NAT_FOREACH
]

forall: make native! [[
		"Evaluates body for all values in a series."
		'word [word!]   "Word referring to series to iterate over"
		body  [block!]
	]
	#get-definition NAT_FORALL
]

;break: make native! [
;	[]													;@@ add /return option
;	none
;]

func: make native! [[
		"Defines a function with a given spec and body."
		spec [block!]
		body [block!]
	]
	#get-definition NAT_FUNC
]

function: make native! [[
		"Defines a function, making all words found in body local."
		spec [block!]
		body [block!]
		/extern	"Exclude words that follow this refinement"
	]
	#get-definition NAT_FUNCTION
]

does: make native! [[
		"Defines a function with no arguments or local variables."
		body [block!]
	]
	#get-definition NAT_DOES
]

has: make native! [[
		"Defines a function with local variables, but no arguments."
		vars [block!]
		body [block!]
	]
	#get-definition NAT_HAS
]

switch: make native! [[
		"Evaluates the first block following the value found in cases."
		value [any-type!] "The value to match"
		cases [block!]
		/default "Specify a default block, if value is not found in cases"
			case [block!] "Default block to evaluate"
	]
	#get-definition NAT_SWITCH
]

case: make native! [[
		"Evaluates the block following the first true condition."
		cases [block!] "Block of condition-block pairs"
		/all "Test all conditions, evaluating the block following each true condition"
	]
	#get-definition NAT_CASE
]

do: make native! [[
		"Evaluates a value, returning the last evaluation result."
		value [any-type!]
	]
	#get-definition NAT_DO
]

reduce: make native! [[
		"Returns a copy of a block, evaluating all expressions."
		value [any-type!]
		/into "Put results in out block, instead of creating a new block"
			out [any-block!] "Target block for results, when /into is used"
	]
	#get-definition NAT_REDUCE
]

compose: make native! [[
		"Returns a copy of a block, evaluating only parens."
		value [block!]
		/deep "Compose nested blocks"
		/only "Compose nested blocks as blocks containing their values"
		/into "Put results in out block, instead of creating a new block"
			out [any-block!] "Target block for results, when /into is used"
	]
	#get-definition NAT_COMPOSE
]

get: make native! [[
		"Returns the value a word refers to."
		word	[word!]
		/any "If word has no value, return UNSET rather than causing an error"
		return: [any-type!]
	] 
	#get-definition NAT_GET
]

set: make native! [[
		"Sets the value(s) one or more words refer to."
		word	[any-word! block!] "Word or block of words to set"
		value	[any-type!] "Value or block of values to assign to words"
		/any "Allow UNSET as a value rather than causing an error"
		return: [any-type!]
	]
	#get-definition NAT_SET
]

print: make native! [[
		"Outputs a value followed by a newline."
		value	[any-type!]
	]
	#get-definition NAT_PRINT
]

prin: make native! [[
		"Outputs a value."
		value	[any-type!]
	]
	#get-definition NAT_PRIN
]

equal?: make native! [[
		"Returns true if two values are equal."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_EQUAL?
]

not-equal?: make native! [[
		"Returns true if two values are not equal."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_NOT_EQUAL?
]

strict-equal?: make native! [[
		"Returns true if two values are equal, and also the same datatype."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_STRICT_EQUAL?
]

lesser?: make native! [[
		"Returns true if the first value is less than the second."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_LESSER?
]

greater?: make native! [[
		"Returns true if the first value is greater than the second."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_GREATER?
]

lesser-or-equal?: make native! [[
		"Returns true if the first value is less than or equal to the second."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_LESSER_OR_EQUAL?
]

greater-or-equal?: make native! [[
		"Returns true if the first value is greater than or equal to the second."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_GREATER_OR_EQUAL?
]

same?: make native! [[
		"Returns true if two values have the same identity."
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_SAME?
]

not: make native! [[
		"Returns the negation (logical complement) of a value."
		value [any-type!]
	]
	#get-definition NAT_NOT
]

halt: make native! [[
		"Stops evaluation."
	]
	#get-definition NAT_HALT
]

type?: make native! [[
		"Returns the datatype of a value."
		value [any-type!]
		/word "Return a word value, rather than a datatype value"
	]
	#get-definition NAT_TYPE?
]

stats: make native! [[
		"Returns interpreter statistics."
		/show "TBD:"
		/info "Output formatted results"
		return: [integer! block!]
	]
	#get-definition NAT_STATS
]

bind: make native! [[
		word 	[block! any-word!]
		context [any-word! any-object!]
		/copy
		return: [block! any-word!]
	]
	#get-definition NAT_BIND
]

in: make native! [[
		object [any-object!]
		word   [any-word! block! paren!]
	]
	#get-definition NAT_IN
]

parse: make native! [[
		input [series!]
		rules [block!]
		/case
		;/strict
		/part
			length [number! series!]
		/trace
			callback [function! [
				event	[word!]
				match?	[logic!]
				rule	[block!]
				input	[series!]
				stack	[block!]
				return: [logic!]
			]]
		return: [logic! block!]
	]
	#get-definition NAT_PARSE
]

union: make native! [[
		set1 [block! string! bitset! typeset!]
		set2 [block! string! bitset! typeset!]
		/case
		/skip "Treat the series as fixed size records"
			size [integer!]
		return: [block! string! bitset! typeset!]
	]
	#get-definition NAT_UNION
]

complement?: make native! [[
		"Returns true if the bitset is complemented."
		bits [bitset!]
	]
	#get-definition NAT_COMPLEMENT?
]

dehex: make native! [[
		"Converts URL-style hex encoded (%xx) strings."
		value [string! file!]							;@@ replace with any-string!
	]
	#get-definition NAT_DEHEX
]

negative?: make native! [[
		"Returns TRUE if the number is negative."
		number [number!]
	]
	#get-definition NAT_NEGATIVE?
]

positive?: make native! [[
		"Returns TRUE if the number is positive."
		number [number!]
	]
	#get-definition NAT_POSITIVE?
]

max: make native! [[
		"Returns the greater of the two values."
		value1 [number! series!]
		value2 [number! series!]
	]
	#get-definition NAT_MAX
]

min: make native! [[
		"Returns the lesser of the two values."
		value1 [number! series!]
		value2 [number! series!]
	]
	#get-definition NAT_MIN
]

shift: make native! [[
		"Perform a bit shift operation. Right shift (decreasing) by default."
		data	[integer! binary!]
		bits	[integer!]
		/left	 "Shift bits to the left (increasing)"
		/logical "Use logical shift (unsigned, fill with zero)"
		return: [integer! binary!]
	]
	#get-definition NAT_SHIFT
]

shift-right:   routine [][natives/shift* -1 -1]
shift-left:	   routine [][natives/shift* 1 -1]
shift-logical: routine [][natives/shift* -1 1]

to-hex: make native! [[
		"Converts numeric value to a hex issue! datatype (with leading # and 0's)."
		value	[integer! tuple!]
		/size "Specify number of hex digits in result"
			length [integer!]
		return: [issue!]
	]
	#get-definition NAT_TO_HEX
]

debase: make native! [[
		"Converts a string to binary"
		value [string! file!]							;@@ replace with any-string!
	]
	#get-definition NAT_DEBASE
]

enbase: make native! [[
		"Converts a string to binary"
		value [string! file!]							;@@ replace with any-string!
	]
	#get-definition NAT_ENBASE
]

;------------------------------------------
;-			   Operators				  -
;------------------------------------------

;-- #load temporary directive is used to workaround REBOL LOAD limitations on some words

#load set-word! "+"		make op! :add
#load set-word! "-"		make op! :subtract
#load set-word! "*"		make op! :multiply
#load set-word! "/"		make op! :divide
#load set-word! "//"	make op! :modulo
#load set-word! "%"		make op! :remainder
#load set-word! "="		make op! :equal?
#load set-word! "<>"	make op! :not-equal?
#load set-word! "=="	make op! :strict-equal?
#load set-word! "=?"	make op! :same?
#load set-word! "<" 	make op! :lesser?
#load set-word! ">" 	make op! :greater?
#load set-word! "<="	make op! :lesser-or-equal?
#load set-word! ">="	make op! :greater-or-equal?
#load set-word! "<<"	make op! :shift-left
#load set-word! ">>"	make op! :shift-right
#load set-word! ">>>"	make op! :shift-logical
and:					make op! :and~
or:						make op! :or~
xor:					make op! :xor~


;------------------------------------------
;-				Scalars					  -
;------------------------------------------
Red: true												;-- ultimate Truth ;-) (pre-defines Red word)

yes: on: true
no: off: false
;empty?: :tail?

tab:		 #"^-"
cr: 		 #"^M"
newline: lf: #"^/"
escape:      #"^["
slash: 		 #"/"
sp: space: 	 #" "
null: 		 #"^@"
crlf:		 "^M^/"
dot:		 #"."

;------------------------------------------
;-			   Mezzanines				  -
;------------------------------------------

comment: func [value][]

quit-return: routine [
	"Stops evaluation and exits the program with a given status."
	status			[integer!] "Process termination value to return"
][
	quit status
]
quit: func [
	"Stops evaluation and exits the program."
	/return status	[integer!] "Return an exit status"
][
	quit-return any [status 0]
]

empty?: func [
	"Returns true if a series is at its tail."
	series	[series!]
	return:	[logic!]
][
	tail? series
]

??: func [
	"Prints a word and the value it refers to (molded)."
	'value [word!]
][
	prin mold :value
	prin ": "
	probe get/any :value
]

probe: func [
	"Returns a value after printing its molded form."
	value
][
	print mold value 
	value
]

quote: func [
	:value
][
	:value
]

first:	func ["Returns the first value in a series."  s [series!]] [pick s 1]	;@@ temporary definitions, should be natives ?
second:	func ["Returns the second value in a series." s [series!]] [pick s 2]
third:	func ["Returns the third value in a series."  s [series!]] [pick s 3]
fourth:	func ["Returns the fourth value in a series." s [series!]] [pick s 4]
fifth:	func ["Returns the fifth value in a series."  s [series!]] [pick s 5]

last:	func ["Returns the last value in a series."  s [series!]][pick back tail s 1]


action?:	 func ["Returns true if the value is this type." value [any-type!]] [action!	= type? :value]
bitset?:	 func ["Returns true if the value is this type." value [any-type!]] [bitset!	= type? :value]
block?:		 func ["Returns true if the value is this type." value [any-type!]] [block!		= type? :value]
char?: 		 func ["Returns true if the value is this type." value [any-type!]] [char!		= type? :value]
datatype?:	 func ["Returns true if the value is this type." value [any-type!]] [datatype!	= type? :value]
file?:		 func ["Returns true if the value is this type." value [any-type!]] [file!		= type? :value]
url?:		 func ["Returns true if the value is this type." value [any-type!]] [url!		= type? :value]
function?:	 func ["Returns true if the value is this type." value [any-type!]] [function!	= type? :value]
get-path?:	 func ["Returns true if the value is this type." value [any-type!]] [get-path!	= type? :value]
get-word?:	 func ["Returns true if the value is this type." value [any-type!]] [get-word!	= type? :value]
integer?:    func ["Returns true if the value is this type." value [any-type!]] [integer!	= type? :value]
issue?:    	 func ["Returns true if the value is this type." value [any-type!]] [issue!		= type? :value]
lit-path?:	 func ["Returns true if the value is this type." value [any-type!]] [lit-path!	= type? :value]
lit-word?:	 func ["Returns true if the value is this type." value [any-type!]] [lit-word!	= type? :value]
logic?:		 func ["Returns true if the value is this type." value [any-type!]] [logic!		= type? :value]
native?:	 func ["Returns true if the value is this type." value [any-type!]] [native!	= type? :value]
none?:		 func ["Returns true if the value is this type." value [any-type!]] [none!		= type? :value]
object?:	 func ["Returns true if the value is this type." value [any-type!]] [object!	= type? :value]
op?:		 func ["Returns true if the value is this type." value [any-type!]] [op!		= type? :value]
paren?:		 func ["Returns true if the value is this type." value [any-type!]] [paren!		= type? :value]
path?:		 func ["Returns true if the value is this type." value [any-type!]] [path!		= type? :value]
refinement?: func ["Returns true if the value is this type." value [any-type!]] [refinement! = type? :value]
set-path?:	 func ["Returns true if the value is this type." value [any-type!]] [set-path!	= type? :value]
set-word?:	 func ["Returns true if the value is this type." value [any-type!]] [set-word!	= type? :value]
string?:	 func ["Returns true if the value is this type." value [any-type!]] [string!	= type? :value]
unset?:		 func ["Returns true if the value is this type." value [any-type!]] [unset!		= type? :value]
word?:		 func ["Returns true if the value is this type." value [any-type!]] [word!		= type? :value]

any-series?: func [value][
	find [												;@@ To be replaced with a typeset check
		block! paren! path! lit-path! set-path!
		get-path! string! file! binary!
	] type?/word :value
]

spec-of: func [
	"Returns the spec of a value that supports reflection."
	value
][
	reflect :value 'spec
]

body-of: func [
	"Returns the body of a value that supports reflection."
	value
][
	reflect :value 'body
]

words-of: func [
	"Returns the list of words of a value that supports reflection."
	value
][
	reflect :value 'words
]

values-of: func [
	"Returns the list of values of a value that supports reflection."
	value
][
	reflect :value 'values
]

context: func [spec [block!]][make object! spec]

system: function [
	"Returns information about the interpreter."
	/version	  "Return the system version"
	/words		  "Return a block of global words available"
	/platform	  "Return a word identifying the operating system"
	/interpreted? "Return TRUE if called from the interpreter"
][
	case [
		version [#version]
		words	[#system [_context/get-words]]
		platform [
			#system [
				#switch OS [
					Windows  [SET_RETURN(words/_windows)]
					Syllable [SET_RETURN(words/_syllable)]
					MacOSX	 [SET_RETURN(words/_macosx)]
					#default [SET_RETURN(words/_linux)]
				]
			]
		]
		interpreted? [#system [logic/box stack/eval?]]
		'else [
			print "Please specify a system refinement value (/version, /words, or /platform)."
		]
	]
]

replace: func [
	series [series!]
	pattern
	value
	/all
	/local pos len
][
	len: either any-series? :pattern [length? pattern][1]
	
	either all [
		pos: series
		either any-series? :pattern [
			while [pos: find pos pattern][
				remove/part pos len
				pos: insert pos value
			]
		][
			while [pos: find pos pattern][pos/1: value]
		]
	][
		if pos: find series pattern [
			remove/part pos len
			insert pos value
		]
	]
	series
]

zero?: func [
	value [number!]
][
	value = 0
]

charset: func [
	spec [block! integer! char! string! binary!]
][
	make bitset! spec
]

p-indent: make string! 30								;@@ to be put in an local context

on-parse-event: func [
	event	[word!]   "Trace events: push, pop, fetch, match, iterate, paren, end"
	match?	[logic!]  "Result of last matching operation"
	rule	[block!]  "Current rule at current position"
	input	[series!] "Input series at next position to match"
	stack	[block!]  "Internal parse rules stack"
	return: [logic!]  "TRUE: continue parsing, FALSE: stop and exit parsing"
][
	switch event [
		push  [
			print [p-indent "-->"]
			append p-indent "  "
		]
		pop	  [
			clear back back tail p-indent
			print [p-indent "<--"]
		]
		fetch [
			print [
				p-indent "match:" mold/part rule  50 newline
				p-indent "input:" mold/part input 50 p-indent
			]
		]
		match [print [p-indent "==>" either match? ["matched"]["not matched"]]]
		end   [print ["return:" match?]]
	]
	true
]

parse-trace: func [
	"Wrapper for parse/trace using the default event processor"
	input [series!]
	rules [block!]
	/case
	/part
		limit [integer!]
	return: [logic! block!]
][
	either case [
		parse/case/trace input rules :on-parse-event
	][
		either part [
			parse/part/trace input rules limit :on-parse-event
		][
			parse/trace input rules :on-parse-event
		]
	]
]

#include %lexer.red

load: function [
	"Returns a value or block of values by reading and evaluating a source."
	source [file! url! string! binary!]
	/header "TBD: Include Red header as a loaded value"
	/all    "TBD: Don't evaluate Red header"
	/type	"TBD:"
	/part
		length [integer! string!]
	/into "Put results in out block, instead of creating a new block"
		out [block!] "Target block for results"
][
	if part [
		case [
			zero? length [return make block! 1]
			string? length [
				if (index? length) = index? source [
					return make block! 1
				]
			]
		]
	]
	
	unless out [out: make block! 4]
	;switch type?/word [
	;	file!	[]
	;	url!	[]
	;	binary! []
	;]
	either part [transcode/part source out length][transcode source out]
	unless :all [if 1 = length? out [out: out/1]]
	out 
]
