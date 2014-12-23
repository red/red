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

if: make native! [[
		"If condition is true, evaluate block; else return NONE"
		cond  	 [any-type!]
		then-blk [block!]
	]
	#get-definition NAT_IF
]

unless: make native! [[
		"If condition is not true, evaluate block; else return NONE"
		cond  	 [any-type!]
		then-blk [block!]
	]
	#get-definition NAT_UNLESS
]

either: make native! [[
		"If condition is true, eval true-block; else eval false-blk"
		cond  	  [any-type!]
		true-blk  [block!]
		false-blk [block!]
	]
	#get-definition NAT_EITHER
]
	
any: make native! [[
		"Evaluates, returning at the first that is true"
		conds [block!]
	]
	#get-definition NAT_ANY
]

all: make native! [[
		"Evaluates, returning at the first that is not true"
		conds [block!]
	]
	#get-definition NAT_ALL
]

while: make native! [[
		"Evaluates body until condition is true"
		cond [block!]
		body [block!]
	]
	#get-definition NAT_WHILE
]
	
until: make native! [[
		"Evaluates body until it is true"
		body [block!]
	]
	#get-definition NAT_UNTIL
]

loop: make native! [[
		"Evaluates body a number of times"
		count [integer!]
		body  [block!]
	]
	#get-definition NAT_LOOP
]

repeat: make native! [[
		"Evaluates body a number of times, tracking iteration count"
		'word [word!]    "Iteration counter; not local to loop"
		value [integer!] "Number of times to evaluate body"
		body  [block!]
	]
	#get-definition NAT_REPEAT
]

foreach: make native! [[
		"Evaluates body for each value in a series"
		'word  [word! block!]   "Word, or words, to set on each iteration"
		series [series!]
		body   [block!]
	]
	#get-definition NAT_FOREACH
]

forall: make native! [[
		"Evaluates body for all values in a series"
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
		"Defines a function with a given spec and body"
		spec [block!]
		body [block!]
	]
	#get-definition NAT_FUNC
]

function: make native! [[
		"Defines a function, making all words found in body local"
		spec [block!]
		body [block!]
		/extern	"Exclude words that follow this refinement"
	]
	#get-definition NAT_FUNCTION
]

does: make native! [[
		"Defines a function with no arguments or local variables"
		body [block!]
	]
	#get-definition NAT_DOES
]

has: make native! [[
		"Defines a function with local variables, but no arguments"
		vars [block!]
		body [block!]
	]
	#get-definition NAT_HAS
]

switch: make native! [[
		"Evaluates the first block following the value found in cases"
		value [any-type!] "The value to match"
		cases [block!]
		/default "Specify a default block, if value is not found in cases"
			case [block!] "Default block to evaluate"
	]
	#get-definition NAT_SWITCH
]

case: make native! [[
		"Evaluates the block following the first true condition"
		cases [block!] "Block of condition-block pairs"
		/all "Test all conditions, evaluating the block following each true condition"
	]
	#get-definition NAT_CASE
]

do: make native! [[
		"Evaluates a value, returning the last evaluation result"
		value [any-type!]
	]
	#get-definition NAT_DO
]

reduce: make native! [[
		"Returns a copy of a block, evaluating all expressions"
		value [any-type!]
		/into "Put results in out block, instead of creating a new block"
			out [any-block!] "Target block for results, when /into is used"
	]
	#get-definition NAT_REDUCE
]

compose: make native! [[
		"Returns a copy of a block, evaluating only parens"
		value [block!]
		/deep "Compose nested blocks"
		/only "Compose nested blocks as blocks containing their values"
		/into "Put results in out block, instead of creating a new block"
			out [any-block!] "Target block for results, when /into is used"
	]
	#get-definition NAT_COMPOSE
]

get: make native! [[
		"Returns the value a word refers to"
		word	[word!]
		/any "If word has no value, return UNSET rather than causing an error"
		return: [any-type!]
	] 
	#get-definition NAT_GET
]

set: make native! [[
		"Sets the value(s) one or more words refer to"
		word	[any-word! block! object!] "Word, object or block of words to set"
		value	[any-type!] "Value or block of values to assign to words"
		/any "Allow UNSET as a value rather than causing an error"
		return: [any-type!]
	]
	#get-definition NAT_SET
]

print: make native! [[
		"Outputs a value followed by a newline"
		value	[any-type!]
	]
	#get-definition NAT_PRINT
]

prin: make native! [[
		"Outputs a value"
		value	[any-type!]
	]
	#get-definition NAT_PRIN
]

equal?: make native! [[
		"Returns true if two values are equal"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_EQUAL?
]

not-equal?: make native! [[
		"Returns true if two values are not equal"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_NOT_EQUAL?
]

strict-equal?: make native! [[
		"Returns true if two values are equal, and also the same datatype"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_STRICT_EQUAL?
]

lesser?: make native! [[
		"Returns true if the first value is less than the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_LESSER?
]

greater?: make native! [[
		"Returns true if the first value is greater than the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_GREATER?
]

lesser-or-equal?: make native! [[
		"Returns true if the first value is less than or equal to the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_LESSER_OR_EQUAL?
]

greater-or-equal?: make native! [[
		"Returns true if the first value is greater than or equal to the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_GREATER_OR_EQUAL?
]

same?: make native! [[
		"Returns true if two values have the same identity"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_SAME?
]

not: make native! [[
		"Returns the negation (logical complement) of a value"
		value [any-type!]
	]
	#get-definition NAT_NOT
]

halt: make native! [[
		"Stops evaluation"
	]
	#get-definition NAT_HALT
]

type?: make native! [[
		"Returns the datatype of a value"
		value [any-type!]
		/word "Return a word value, rather than a datatype value"
	]
	#get-definition NAT_TYPE?
]

stats: make native! [[
		"Returns interpreter statistics"
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
		"Returns true if the bitset is complemented"
		bits [bitset!]
	]
	#get-definition NAT_COMPLEMENT?
]

dehex: make native! [[
		"Converts URL-style hex encoded (%xx) strings"
		value [string! file!]							;@@ replace with any-string!
	]
	#get-definition NAT_DEHEX
]

negative?: make native! [[
		"Returns TRUE if the number is negative"
		number [number!]
	]
	#get-definition NAT_NEGATIVE?
]

positive?: make native! [[
		"Returns TRUE if the number is positive"
		number [number!]
	]
	#get-definition NAT_POSITIVE?
]

max: make native! [[
		"Returns the greater of the two values"
		value1 [number! series!]
		value2 [number! series!]
	]
	#get-definition NAT_MAX
]

min: make native! [[
		"Returns the lesser of the two values"
		value1 [number! series!]
		value2 [number! series!]
	]
	#get-definition NAT_MIN
]

shift: make native! [[
		"Perform a bit shift operation. Right shift (decreasing) by default"
		data	[integer! binary!]
		bits	[integer!]
		/left	 "Shift bits to the left (increasing)"
		/logical "Use logical shift (unsigned, fill with zero)"
		return: [integer! binary!]
	]
	#get-definition NAT_SHIFT
]

to-hex: make native! [[
		"Converts numeric value to a hex issue! datatype (with leading # and 0's)"
		value	[integer! tuple!]
		/size "Specify number of hex digits in result"
			length [integer!]
		return: [issue!]
	]
	#get-definition NAT_TO_HEX
]

sine: make native! [[
		"Returns the trigonometric sine"
		angle	[number!]
		/radians "Angle is specified in radians"
		return: [float!]
	]
	#get-definition NAT_SINE
]

cosine: make native! [[
		"Returns the trigonometric cosine"
		angle	[number!]
		/radians "Angle is specified in radians"
		return: [float!]
	]
	#get-definition NAT_COSINE
]

tangent: make native! [[
		"Returns the trigonometric tangent"
		angle	[number!]
		/radians "Angle is specified in radians"
		return: [float!]
	]
	#get-definition NAT_TANGENT
]

arcsine: make native! [[
		"Returns the trigonometric arcsine (in degrees by default)"
		angle	[number!]
		/radians "Angle is specified in radians"
		return: [float!]
	]
	#get-definition NAT_ARCSINE
]

arccosine: make native! [[
		"Returns the trigonometric arccosine (in degrees by default)"
		angle	[number!]
		/radians "Angle is specified in radians"
		return: [float!]
	]
	#get-definition NAT_ARCCOSINE
]

arctangent: make native! [[
		"Returns the trigonometric arctangent (in degrees by default)"
		angle	[number!]
		/radians "Angle is specified in radians"
		return: [float!]
	]
	#get-definition NAT_ARCTANGENT
]
arctangent2: make native! [[
		"Returns the angle of the point y/x in radians, when measured counterclockwise from a circle's x axis (where 0x0 represents the center of the circle). The return value is between -pi and +pi."
		y       [number!]
		x       [number!]
		return: [float!]
	]
	#get-definition NAT_ARCTANGENT2
]

NaN?: make native! [[
		"Returns TRUE if the number is Not-a-Number"
		value	[number!]
		return: [logic!]
	]
	#get-definition NAT_NAN?
]

log-2: make native! [[
		"Return the base-2 logarithm"
		value	[number!]
		return: [float!]
	]
	#get-definition NAT_LOG_2
]

log-10: make native! [[
		"Returns the base-10 logarithm"
		value	[number!]
		return: [float!]
	]
	#get-definition NAT_LOG_10
]

log-e: make native! [[
		"Returns the natural (base-E) logarithm of the given value"
		value	[number!]
		return: [float!]
	]
	#get-definition NAT_LOG_E
]

exp: make native! [[
		"Raises E (the base of natural logarithm) to the power specified"
		value	[number!]
		return: [float!]
	]
	#get-definition NAT_EXP
]

square-root: make native! [[
		"Returns the square root of a number"
		value	[number!]
		return: [float!]
	]
	#get-definition NAT_SQUARE_ROOT
]

construct: make native! [[
		block [block!]
		/with
			object [object!]
		/only
	]
	#get-definition NAT_CONSTRUCT
]

value?: make native! [[
		"Returns TRUE if the word has a value"
		value	[word!]
		return: [logic!]
	]
	#get-definition NAT_VALUE?
]
