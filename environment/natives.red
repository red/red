Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

if: make native! [[
		"If conditional expression is truthy, evaluate block; else return NONE"
		cond  	 [any-type!]
		then-blk [block!]
	]
	#get-definition NAT_IF
]

unless: make native! [[
		"If conditional expression is falsy, evaluate block; else return NONE"
		cond  	 [any-type!]
		then-blk [block!]
	]
	#get-definition NAT_UNLESS
]

either: make native! [[
		"If conditional expression is truthy, evaluate the first branch; else evaluate the alternative"
		cond  	  [any-type!]
		true-blk  [block!]
		false-blk [block!]
	]
	#get-definition NAT_EITHER
]

any: make native! [[
		"Evaluates and returns the first truthy value, if any; else NONE"
		conds [block!]
	]
	#get-definition NAT_ANY
]

all: make native! [[
		"Evaluates and returns the last value if all are truthy; else NONE"
		conds [block!]
	]
	#get-definition NAT_ALL
]

while: make native! [[
		"Evaluates body as long as condition block evaluates to truthy value"
		cond [block!]	"Condition block to evaluate on each iteration"
		body [block!]	"Block to evaluate on each iteration"
	]
	#get-definition NAT_WHILE
]
	
until: make native! [[
		"Evaluates body until it is truthy"
		body [block!]
	]
	#get-definition NAT_UNTIL
]

loop: make native! [[
		"Evaluates body a number of times"
		count [integer! float!]
		body  [block!]
	]
	#get-definition NAT_LOOP
]

repeat: make native! [[
		"Evaluates body a number of times, tracking iteration count"
		'word [word!]    "Iteration counter; not local to loop"
		value [integer! float!] "Number of times to evaluate body"
		body  [block!]
	]
	#get-definition NAT_REPEAT
]

forever: make native! [[
		"Evaluates body repeatedly forever"
		body   [block!]
	]
	#get-definition NAT_FOREVER
]

foreach: make native! [[
		"Evaluates body for each value in a series"
		'word  [word! block!]   "Word, or words, to set on each iteration"
		series [series! map!]
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

remove-each: make native! [[
		"Removes values for each block that returns truthy value"
		'word [word! block!] "Word or block of words to set each time"
		data [series!] "The series to traverse (modified)"
		body [block!] "Block to evaluate (return truthy value to remove)"
	]
	#get-definition NAT_REMOVE_EACH
]

func: make native! [[
		"Defines a function with a given spec and body"
		spec [block!]
		body [block!]
	]
	#get-definition NAT_FUNC
]

function: make native! [[
		"Defines a function, making all set-words found in body, local"
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
		"Evaluates the block following the first truthy condition"
		cases [block!] "Block of condition-block pairs"
		/all "Test all conditions, evaluating the block following each truthy condition"
	]
	#get-definition NAT_CASE
]

do: make native! [[
		"Evaluates a value, returning the last evaluation result"
		value [any-type!]
		/expand "Expand directives before evaluation"
		/args	"If value is a script, this will set its system/script/args"
			arg "Args passed to a script (normally a string)"
		/next	"Do next expression only, return it, update block word"
			position [word!] "Word updated with new block position"
		/trace
			callback [function! [
				event	[word!]
				code	[any-block! none!]
				offset	[integer!]
				value	[any-type!]
				ref		[any-type!]
				frame	[pair!]
			]]
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
		word	[any-word! any-path! object!]
		/any  "If word has no value, return UNSET rather than causing an error"
		/case "Use case-sensitive comparison (path only)"
		return: [any-type!]
	] 
	#get-definition NAT_GET
]

set: make native! [[
		"Sets the value(s) one or more words refer to"
		word	[any-word! block! object! any-path!] "Word, object, map path or block of words to set"
		value	[any-type!] "Value or block of values to assign to words"
		/any  "Allow UNSET as a value rather than causing an error"
		/case "Use case-sensitive comparison (path only)"
		/only "Block or object value argument is set as a single value"
		/some "None values in a block or object value argument, are not set"
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
		"Returns TRUE if two values are equal"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_EQUAL?
]

not-equal?: make native! [[
		"Returns TRUE if two values are not equal"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_NOT_EQUAL?
]

strict-equal?: make native! [[
		"Returns TRUE if two values are equal, and also the same datatype"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_STRICT_EQUAL?
]

lesser?: make native! [[
		"Returns TRUE if the first value is less than the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_LESSER?
]

greater?: make native! [[
		"Returns TRUE if the first value is greater than the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_GREATER?
]

lesser-or-equal?: make native! [[
		"Returns TRUE if the first value is less than or equal to the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_LESSER_OR_EQUAL?
]

greater-or-equal?: make native! [[
		"Returns TRUE if the first value is greater than or equal to the second"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_GREATER_OR_EQUAL?
]

same?: make native! [[
		"Returns TRUE if two values have the same identity"
		value1 [any-type!]
		value2 [any-type!]
	]
	#get-definition NAT_SAME?
]

not: make native! [[
		"Returns the logical complement of a value (truthy or falsy)"
		value [any-type!]
	]
	#get-definition NAT_NOT
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
		"Bind words to a context; returns rebound words"
		word 	[block! any-word!]
		context [any-word! any-object! function!]
		/copy	"Deep copy blocks before binding"
		return: [block! any-word!]
	]
	#get-definition NAT_BIND
]

in: make native! [[
		"Returns the given word bound to the object's context"
		object [any-object! any-function!]
		word   [any-word! refinement!]
	]
	#get-definition NAT_IN
]

parse: make native! [[
		"Process a series using dialected grammar rules"
		input [binary! any-block! any-string!]
		rules [block!]
		/case "Uses case-sensitive comparison"
		;/strict
		/part "Limit to a length or position"
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
		"Returns the union of two data sets"
		set1 [block! hash! string! bitset! typeset!]
		set2 [block! hash! string! bitset! typeset!]
		/case "Use case-sensitive comparison"
		/skip "Treat the series as fixed size records"
			size [integer!]
		return: [block! hash! string! bitset! typeset!]
	]
	#get-definition NAT_UNION
]

unique: make native! [[
		"Returns the data set with duplicates removed"
		set [block! hash! string!]
		/case "Use case-sensitive comparison"
		/skip "Treat the series as fixed size records"
			size [integer!]
		return: [block! hash! string!]
	]
	#get-definition NAT_UNIQUE
]

intersect: make native! [[
		"Returns the intersection of two data sets"
		set1 [block! hash! string! bitset! typeset!]
		set2 [block! hash! string! bitset! typeset!]
		/case "Use case-sensitive comparison"
		/skip "Treat the series as fixed size records"
			size [integer!]
		return: [block! hash! string! bitset! typeset!]
	]
	#get-definition NAT_INTERSECT
]

difference: make native! [[
		"Returns the special difference of two data sets"
		set1 [block! hash! string! bitset! typeset! date!]
		set2 [block! hash! string! bitset! typeset! date!]
		/case "Use case-sensitive comparison"
		/skip "Treat the series as fixed size records"
			size [integer!]
		return: [block! hash! string! bitset! typeset! time!]
	]
	#get-definition NAT_DIFFERENCE
]

exclude: make native! [[
		"Returns the first data set less the second data set"
		set1 [block! hash! string! bitset! typeset!]
		set2 [block! hash! string! bitset! typeset!]
		/case "Use case-sensitive comparison"
		/skip "Treat the series as fixed size records"
			size [integer!]
		return: [block! hash! string! bitset! typeset!]
	]
	#get-definition NAT_EXCLUDE
]

complement?: make native! [[
		"Returns TRUE if the bitset is complemented"
		bits [bitset!]
	]
	#get-definition NAT_COMPLEMENT?
]

dehex: make native! [[
		"Converts URL-style hex encoded (%xx) strings"
		value [any-string!]
		return:	[string!] "Always return a string"
	]
	#get-definition NAT_DEHEX
]

enhex: make native! [[
		"Encode URL-style hex encoded (%xx) strings"
		value [any-string!]
		return:	[string!] "Always return a string"
	]
	#get-definition NAT_ENHEX
]

negative?: make native! [[
		"Returns TRUE if the number is negative"
		number [number! money! time!]
		return: [logic!]
	]
	#get-definition NAT_NEGATIVE?
]

positive?: make native! [[
		"Returns TRUE if the number is positive"
		number [number! money! time!]
		return: [logic!]
	]
	#get-definition NAT_POSITIVE?
]

max: make native! [[
		"Returns the greater of the two values"
		value1 [scalar! series!]
		value2 [scalar! series!]
	]
	#get-definition NAT_MAX
]

min: make native! [[
		"Returns the lesser of the two values"
		value1 [scalar! series!]
		value2 [scalar! series!]
	]
	#get-definition NAT_MIN
]

shift: make native! [[
		"Perform a bit shift operation. Right shift (decreasing) by default"
		data	[integer!]
		bits	[integer!]
		/left	 "Shift bits to the left (increasing)"
		/logical "Use logical shift (unsigned, fill with zero)"
		return: [integer!]
	]
	#get-definition NAT_SHIFT
]

to-hex: make native! [[
		"Converts numeric value to a hex issue! datatype (with leading # and 0's)"
		value	[integer!]
		/size "Specify number of hex digits in result"
			length [integer!]
		return: [issue!]
	]
	#get-definition NAT_TO_HEX
]

sine: make native! [[
		"Returns the trigonometric sine"
		angle	[float! integer!]
		/radians "DEPRECATED: use `sin` native instead"
		return: [float!]
	]
	#get-definition NAT_SINE
]

cosine: make native! [[
		"Returns the trigonometric cosine"
		angle	[float! integer!]
		/radians "DEPRECATED: use `cos` native instead"
		return: [float!]
	]
	#get-definition NAT_COSINE
]

tangent: make native! [[
		"Returns the trigonometric tangent"
		angle	[float! integer!]
		/radians "DEPRECATED: use `tan` native instead"
		return: [float!]
	]
	#get-definition NAT_TANGENT
]

arcsine: make native! [[
		"Returns the trigonometric arcsine in degrees in range [-90,90]"
		sine	[float! integer!] "in range [-1,1]"
		/radians "DEPRECATED: use `asin` native instead"
		return: [float!]
	]
	#get-definition NAT_ARCSINE
]

arccosine: make native! [[
		"Returns the trigonometric arccosine in degrees in range [0,180]"
		cosine	[float! integer!] "in range [-1,1]"
		/radians "DEPRECATED: use `acos` native instead"
		return: [float!]
	]
	#get-definition NAT_ARCCOSINE
]

arctangent: make native! [[
		"Returns the trigonometric arctangent in degrees in range [-90,90]"
		tangent	[float! integer!] "in range [-inf,+inf]"
		/radians "DEPRECATED: use `atan` native instead"
		return: [float!]
	]
	#get-definition NAT_ARCTANGENT
]
arctangent2: make native! [[
		"Returns the smallest angle between the vectors (1,0) and (x,y) in degrees (-180,180]"
		y       [float! integer!]
		x       [float! integer!]
		/radians "DEPRECATED: use `atan2` native instead"
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

zero?: make native! [[
		"Returns TRUE if the value is zero"
		value	[number! money! pair! time! char! tuple! any-point!]
		return: [logic!]
	]
	#get-definition NAT_ZERO?
]

log-2: make native! [[
		"Return the base-2 logarithm"
		value	[float! integer! percent!]
		return: [float!]
	]
	#get-definition NAT_LOG_2
]

log-10: make native! [[
		"Returns the base-10 logarithm"
		value	[float! integer! percent!]
		return: [float!]
	]
	#get-definition NAT_LOG_10
]

log-e: make native! [[
		"Returns the natural (base-E) logarithm of the given value"
		value	[float! integer! percent!]
		return: [float!]
	]
	#get-definition NAT_LOG_E
]

exp: make native! [[
		"Raises E (the base of natural logarithm) to the power specified"
		value	[float! integer! percent!]
		return: [float!]
	]
	#get-definition NAT_EXP
]

square-root: make native! [[
		"Returns the square root of a number"
		value	[float! integer! percent!]
		return: [float!]
	]
	#get-definition NAT_SQUARE_ROOT
]

construct: make native! [[
		"Makes a new object from an unevaluated spec; standard logic words are evaluated"
		block [block!]
		/with "Use a prototype object"
			object [object!] "Prototype object"
		/only "Don't evaluate standard logic words"
	]
	#get-definition NAT_CONSTRUCT
]

value?: make native! [[
		"Returns TRUE if the word has a value"
		value   [word!]
		return: [logic!]
	]
	#get-definition NAT_VALUE?
]

try: make native! [[
		"Tries to DO a block and returns its value or an error"
		block	[block!]
		/all  "Catch also BREAK, CONTINUE, RETURN, EXIT and THROW exceptions"
		/keep "Capture and save the call stack in the error object"
	]
	#get-definition NAT_TRY
]

uppercase: make native! [[
		"Converts string of characters to uppercase"
		string		[any-string! char!] "Value to convert (modified when series)"
		/part "Limits to a given length or position"
			limit	[number! any-string!]
		return: 	[any-string! char!]
	]
	#get-definition NAT_UPPERCASE
]

lowercase: make native! [[
		"Converts string of characters to lowercase"
		string		[any-string! char!] "Value to convert (modified when series)"
		/part "Limits to a given length or position"
			limit	[number! any-string!]
		return:		[any-string! char!]
	]
	#get-definition NAT_LOWERCASE
]

as-pair: make native! [[
		"Combine X and Y values into a pair"
		x [integer! float!]
		y [integer! float!]
	]
	#get-definition NAT_AS_PAIR
]

as-point2D: make native! [[
		"Combine X and Y values into a 2D point"
		x [integer! float!]
		y [integer! float!]
	]
	#get-definition NAT_AS_POINT2D
]

as-point3D: make native! [[
		"Combine X, Y and Z values into a 3D point"
		x [integer! float!]
		y [integer! float!]
		z [integer! float!]
	]
	#get-definition NAT_AS_POINT3D
]

as-money: make native! [[
		"Combine currency code and amount into a monetary value"
		currency [word!]
		amount   [integer! float!]
		return:  [money!]
	]
	#get-definition NAT_AS_MONEY
]

break: make native! [[
		"Breaks out of a loop, while, until, repeat, foreach, etc"
		/return "Forces the loop function to return a value"
			value [any-type!]
	]
	#get-definition NAT_BREAK
]

continue: make native! [[
		"Throws control back to top of loop"
	]
	#get-definition NAT_CONTINUE
]

exit: make native! [[
		"Exits a function, returning no value"
	]
	#get-definition NAT_EXIT
]

return: make native! [[
		"Returns a value from a function"
		value [any-type!]
	]
	#get-definition NAT_RETURN
]

throw: make native! [[
		"Throws control back to a previous catch"
		value [any-type!] "Value returned from catch"
		/name "Throws to a named catch"
			word [word!]
	]
	#get-definition NAT_THROW
]

catch: make native! [[
		"Catches a throw from a block and returns its value"
		block [block!] "Block to evaluate"
		/name "Catches a named throw"
			word [word! block!] "One or more names"
	]
	#get-definition NAT_CATCH
]

extend: make native! [[
		"Extend an object or map value with list of key and value pairs"
		obj  [object! map!]
		spec [block! hash! map!]
		/case "Use case-sensitive comparison"
	]
	#get-definition NAT_EXTEND
]

debase: make native! [[
		"Decodes binary-coded string (BASE-64 default) to binary value"
		value [string!] "The string to decode"
		/base "Binary base to use"
			base-value [integer!] "The base to convert from: 64, 58, 16, or 2"
	]
	#get-definition NAT_DEBASE
]

enbase: make native! [[
		"Encodes a string into a binary-coded string (BASE-64 default)"
		value [binary! string!] "If string, will be UTF8 encoded"
		/base "Binary base to use"
			base-value [integer!] "The base to convert from: 64, 58, 16, or 2"
	]
	#get-definition NAT_ENBASE
]

to-local-file: make native! [[
		"Converts a Red file path to the local system file path"
		path  [file! string!]
		/full "Prepends current dir for full path (for relative paths only)"
		return: [string!]
	]
	#get-definition NAT_TO_LOCAL_FILE
]

wait: make native! [[
		"Waits for a duration in seconds or specified time"
		value [number! time! block! none!]
		/all "Returns all events in a block"
		;/only "Only check for ports given in the block to this function"
	]
	#get-definition NAT_WAIT
]

checksum: make native! [[
		"Computes a checksum, CRC, hash, or HMAC"
		data 	[binary! string! file!]
		method	[word!]	"MD5 SHA1 SHA256 SHA384 SHA512 CRC32 TCP ADLER32 hash"
		/with	"Extra value for HMAC key or hash table size; not compatible with TCP/CRC32/ADLER32 methods"
			spec [any-string! binary! integer!] "String or binary for MD5/SHA* HMAC key, integer for hash table size"
		return: [integer! binary!]
	]
	#get-definition NAT_CHECKSUM
]

unset: make native! [[
		"Unsets the value of a word in its current context"
		word [word! block!]  "Word or block of words"
	]
	#get-definition NAT_UNSET
]

new-line: make native! [[
		"Sets or clears the new-line marker within a list series"
		position [any-list!] "Position to change marker (modified)"
		value	 [logic!]	 "Set TRUE for newline"
		/all				 "Set/clear marker to end of series"
		/skip				 "Set/clear marker periodically to the end of the series"
			size [integer!]
		return:  [any-list!]
	]
	#get-definition NAT_NEW_LINE
]

new-line?: make native! [[
		"Returns the state of the new-line marker within a list series"
		position [any-list!] "Position to check marker"
		return:  [logic!]
	]
	#get-definition NAT_NEW_LINE?
]

context?: make native! [[
		"Returns the context to which a word is bound"
		word	[any-word!]		"Word to check"
		return: [object! function! none!]
	]
	#get-definition NAT_CONTEXT?
]

set-env: make native! [[
		"Sets the value of an operating system environment variable (for current process)"
		var   [any-string! any-word!] "Variable to set"
		value [string! none!] "Value to set, or NONE to unset it"
	]
	#get-definition NAT_SET_ENV
]

get-env: make native! [[
		"Returns the value of an OS environment variable (for current process)"
		var		[any-string! any-word!] "Variable to get"
		return: [string! none!]
	]
	#get-definition NAT_GET_ENV
]

list-env: make native! [[
		"Returns a map of OS environment variables (for current process)"
		return: [map!]
	]
	#get-definition NAT_LIST_ENV
]

now: make native! [[
		"Returns date and time"
		/year		"Returns year only"
		/month		"Returns month only"
		/day		"Returns day of the month only"
		/time		"Returns time only"
		/zone		"Returns time zone offset from UTC (GMT) only"
		/date		"Returns date only"
		/weekday	"Returns day of the week as integer (Monday is day 1)"
		/yearday	"Returns day of the year (Julian)"
		/precise	"High precision time"
		/utc		"Universal time (no zone)"
		return: [date! time! integer!]
	]
	#get-definition NAT_NOW
]

sign?: make native! [[
		"Returns sign of N as 1, 0, or -1 (to use as a multiplier)"
		number [number! money! time!]
		return: [integer!]
	]
	#get-definition NAT_SIGN?
]

as: make native! [[
		"Coerce a series into a compatible datatype without copying it"
		type	[datatype! block! paren! any-path! any-string!] "The datatype or example value"
		spec	[block! paren! any-path! any-string!] "The series to coerce"
	]
	#get-definition NAT_AS
]

call: make native! [[
		"Executes a shell command to run another process"
		cmd			[string! file!]			"A shell command or an executable file"
		/wait								"Runs command and waits for exit"
		/show								"Force the display of system's shell window (Windows only)"
		/console							"Runs command with I/O redirected to console (CLI console only at present)"
		/shell								"Forces command to be run from shell"
		/input	in	[string! file! binary!]	"Redirects in to stdin"
		/output	out	[string! file! binary!]	"Redirects stdout to out"
		/error	err	[string! file! binary!]	"Redirects stderr to err"
		return:		[integer!]				"0 if success, -1 if error, or a process ID"
	]
	#get-definition NAT_CALL
]

size?: make native! [[
		"Returns the size of a file content"
		file 	[file!]
		return: [integer! none!]
	]
	#get-definition NAT_SIZE?
]

browse: make native! [[
		"Opens the URL in a web browser or the file in the associated application"
		url		[url! file!]
	]
	#get-definition NAT_BROWSE
]

compress: make native! [[
		"Compresses data"
		data	[any-string! binary!]
		method	[word!]	"zlib deflate gzip"
		return: [binary!]
	]
	#get-definition NAT_COMPRESS
]

decompress: make native! [[
		"Decompresses data"
		data	[binary!]
		method	[word!]	"zlib deflate gzip"
		/size "Specify an uncompressed data size (ignored for GZIP)"
			sz [integer!] "Uncompressed data size; must not be negative"
		return: [binary!]
	]
	#get-definition NAT_DECOMPRESS
]

recycle: make native! [[
		"Recycles unused memory and returns memory amount still in use"
		/on		"Turns on garbage collector; returns nothing"
		/off	"Turns off garbage collector; returns nothing"
		return: [integer! unset!]
	]
	#get-definition NAT_RECYCLE
]

transcode: make native! [[
		"Translates UTF-8 binary source to values. Returns one or several values in a block"
		src	 [binary! string!]	"UTF-8 input buffer; string argument will be UTF-8 encoded"
		/next			"Translate next complete value (blocks as single value)"
		/one			"Translate next complete value, returns the value only"
		/prescan		"Prescans only, do not load values. Returns guessed type."
		/scan			"Scans only, do not load values. Returns recognized type."
		/part			"Translates only part of the input buffer"
			length [integer! binary!] "Length in bytes or tail position"
		/into			"Optionally provides an output block"
			dst	[block!]
		/trace
			callback [function! [
				event	[word!]
				input	[binary! string!]
				type	[word! datatype!]
				line	[integer!]
				token
				return: [logic!]
			]]
		return: [block!]
	]
	#get-definition NAT_TRANSCODE
]

apply: make native! [[
		"Apply a function to a reduced block of arguments"
		func	[word! path! any-function!] "Function to apply, with eventual refinements"
		args	[block!]  "Block of args, reduced first"
		/all			  "Provide every argument in the function spec, in order, tail-completed with false/none."
		/safer			  "Forces single refinement arguments, skip them when inactive instead of evaluating"
	]
	#get-definition NAT_APPLY
]