Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %boot.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
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
error!:			make datatype! #get-definition TYPE_ERROR
typeset!:		make datatype! #get-definition TYPE_TYPESET

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
lit-path!:		make datatype! #get-definition TYPE_LIT_PATH	
native!:		make datatype! #get-definition TYPE_NATIVE
action!:		make datatype! #get-definition TYPE_ACTION
op!:			make datatype! #get-definition TYPE_OP
function!:		make datatype! #get-definition TYPE_FUNCTION
closure!:		make datatype! #get-definition TYPE_CLOSURE
routine!:		make datatype! #get-definition TYPE_ROUTINE
object!:		make datatype! #get-definition TYPE_OBJECT
port!:			make datatype! #get-definition TYPE_PORT
bitset!:		make datatype! #get-definition TYPE_BITSET
float!:			make datatype! #get-definition TYPE_FLOAT

none:  			make none! 0
true:  			make logic! 1
false: 			make logic! 0

;------------------------------------------
;-				Actions					  -
;------------------------------------------

make: make action! [[									;-- this one works! ;-)
		type	 [any-type!]
		spec	 [any-type!]
		return:  [any-type!]
	]
	#get-definition ACT_MAKE
]

;random

reflect: make action! [[
		value	[any-type!]
		field 	[word!]
	]
	#get-definition ACT_REFLECT
]

;to

form: make action! [[
		value	  [any-type!]
		/part
			limit [integer!]
		return:	  [string!]
	]
	#get-definition ACT_FORM
]

mold: make action! [[
		value	  [any-type!]
		/only
		/all
		/flat
		/part
			limit [integer!]
		return:	  [string!]
	]
	#get-definition ACT_MOLD
]

;-- Scalar actions --

absolute: make action! [[
		value	 [number!]
		return:  [number!]
	]
	#get-definition ACT_ABSOLUTE
]

add: make action! [[
		value1	 [number!]
		value2	 [number!]
		return:  [number!]
	]
	#get-definition ACT_ADD
]

divide: make action! [[
		value1	 [number!]
		value2	 [number!]
		return:  [number!]
	]
	#get-definition ACT_DIVIDE
]

multiply: make action! [[
		value1	 [number!]
		value2	 [number!]
		return:  [number!]
	]
	#get-definition ACT_MULTIPLY
]

negate: make action! [[
		number 	 [number!]
		return:  [number!]
	]
	#get-definition ACT_NEGATE
]

power: make action! [[
		number	 [number!]
		exponent [number!]
		return:	 [number!]
	]
	#get-definition ACT_POWER
]

remainder: make action! [[
		value 	 [number!]
		return:  [number!]
	]
	#get-definition ACT_REMAINDER
]

round: make action! [[
		n		[number!]
		/to
		scale	[number!]
		/even
		/down
		/half-down
		/floor
		/ceiling
		/half-ceiling
	]
	#get-definition ACT_ROUND
]

subtract: make action! [[
		value1	 [number!]
		value2	 [number!]
		return:  [number!]
	]
	#get-definition ACT_SUBTRACT
]

even?: make action! [[
		number 	 [number!]
		return:  [number!]
	]
	#get-definition ACT_EVEN?
]

odd?: make action! [[
		number 	 [number!]
		return:  [number!]
	]
	#get-definition ACT_ODD?
]

;-- Bitwise actions --

;and~
;complement
;or~
;xor~

;-- Series actions --

append: make action! [[
		series	   [series!]
		value	   [any-type!]
		/part
			length [number! series!]
		/only
		/dup
			count  [number!]
		return:    [series!]
	]
	#get-definition ACT_APPEND
]

at: make action! [[
		series	 [series!]
		index 	 [integer!]
		return:  [series!]
	]
	#get-definition ACT_AT
]

back: make action! [[
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_BACK
]

;change

clear: make action! [[
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_CLEAR
]

copy: make action! [[
		value	 [series!]
		/part
			length [number! series!]
		/deep
		/types
			kind [datatype!]
		return:  [series!]
	]
	#get-definition ACT_COPY
]

find: make action! [[
		series	 [series! none!]
		value 	 [any-type!]
		/part
			length [number! series!]
		/only
		/case
		/any
		/with
			wild [string!]
		/skip
			size [integer!]
		/last
		/reverse
		/tail
		/match
	]
	#get-definition ACT_FIND
]

head: make action! [[
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_HEAD
]

head?: make action! [[
		series	 [series!]
		return:  [logic!]
	]
	#get-definition ACT_HEAD?
]

index?: make action! [[
		series	 [series!]
		return:  [integer!]
	]
	#get-definition ACT_INDEX?
]

;insert

length?: make action! [[
		series	 [series!]
		return:  [integer!]
	]
	#get-definition ACT_LENGTH?
]


next: make action! [[
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_NEXT
]

pick: make action! [[
		series	 [series!]
		index 	 [integer! logic!]
		return:  [any-type!]
	]
	#get-definition ACT_PICK
]

poke: make action! [[
		series	 [series!]
		index 	 [integer! logic!]
		value 	 [any-type!]
		return:  [series!]
	]
	#get-definition ACT_POKE
]

;remove
;reverse

select: make action! [[
		series	 [series! none!]
		value 	 [any-type!]
		/part
			length [number! series!]
		/only
		/case
		/any
		/with
			wild [string!]
		/skip
			size [integer!]
		/last
		/reverse
	]
	#get-definition ACT_SELECT
]


;sort

skip: make action! [[
		series	 [series!]
		offset 	 [integer!]
		return:  [series!]
	]
	#get-definition ACT_SKIP
]

;swap

tail: make action! [[
		series	 [series!]
		return:  [series!]
	]
	#get-definition ACT_TAIL
]

tail?: make action! [[
		series	 [series!]
		return:  [logic!]
	]
	#get-definition ACT_TAIL?
]

;take
;trim

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
		cond  	 [any-type!]
		true-blk [block!]
	]
	none
]

unless: make native! [[
		cond  	 [any-type!]
		true-blk [block!]
	]
	none
]

either: make native! [[
		cond  	  [any-type!]
		true-blk  [block!]
		false-blk [block!]
	]
	none
]
	
any: make native! [[
		conds [block!]
	]
	none
]

all: make native! [[
		conds [block!]
	]
	none
]

while: make native! [[
		cond [block!]
		body [block!]
	]
	none
]
	
until: make native! [[
		body [block!]
	]
	none
]

loop: make native! [[
		body [block!]
	]
	none
]

repeat: make native! [[
		'word [word!]
		value [integer! series!]
		body  [block!]
	]
	none
]

foreach: make native! [[
		'word  [word!]
		series [series!]
		body   [block!]
	]
]

forall: make native! [[
		'word [word!]
		body  [block!]
	]
	none
]

;break: make native! [
;	[]													;@@ add /return option
;	none
;]

func: make native! [[
		spec [block!]
		body [block!]
	]
	none
]

function: make native! [[
		spec [block!]
		body [block!]
	]
	none
]

does: make native! [[
		body [block!]
	]
	none
]

has: make native! [[
		vars [block!]
		body [block!]
	]
	none
]

exit: make native! [[] none]

return: make native! [[
		value [any-type!]
	]
	none
]

switch: make native! [[
		value [any-type!]
		cases [block!]
		/default
			case [block!]
	]
	none
]

case: make native! [[
		cases [block!]
		/all
	]
	none
]

get: make native! [[
		word	[word!]
		/any
		return: [any-type!]
	] 
	none
]

set: make native! [[
		word	[lit-word!]
		value	[any-type!]
		/any		
		return: [any-type!]
	]
	none
]

print: make native! [[
		value	[any-type!]
	]
	none
]

prin: make native! [[
		value	[any-type!]
	]
	none
]

equal?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

not-equal?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

strict-equal?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

same?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

lesser?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

greater?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

lesser-or-equal?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

greater-or-equal?: make native! [[
		value1 [any-type!]
		value2 [any-type!]
	]
	none
]

not: make native! [[
		value [any-type!]
	]
	none
]

halt: make native! [
	[]
	none
]

type?: make native! [[
		value [any-type!]
		/word
	]
	none
]

;------------------------------------------
;-			   Operators				  -
;------------------------------------------

;-- #load temporary directive is used to workaround REBOL LOAD limitations on some words

#load set-word! "+"  make op! :add
#load set-word! "-"  make op! :subtract
#load set-word! "*"  make op! :multiply
#load set-word! "/"  make op! :divide
#load set-word! "="  make op! :equal?
#load set-word! "<>" make op! :not-equal?
#load set-word! "==" make op! :strict-equal?
#load set-word! "=?" make op! :same?
#load set-word! "<"  make op! :lesser?
#load set-word! ">"  make op! :greater?
#load set-word! "<=" make op! :lesser-or-equal?
#load set-word! ">=" make op! :greater-or-equal?


;------------------------------------------
;-				Scalars					  -
;------------------------------------------

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

;------------------------------------------
;-			   Mezzanines				  -
;------------------------------------------

probe: func [value][
	print mold value 
	value
]

first:	func [s [series!]][pick s 1]					;-- temporary definitions, should be natives
second:	func [s [series!]][pick s 2]
third:	func [s [series!]][pick s 3]
fourth:	func [s [series!]][pick s 4]
fifth:	func [s [series!]][pick s 5]

last:	func [s [series!]][pick back tail s 1]


action?:	 func [value [any-type!]][action!	= type? value]
block?:		 func [value [any-type!]][block!	= type? value]
char?: 		 func [value [any-type!]][char!		= type? value]
datatype?:	 func [value [any-type!]][datatype!	= type? value]
function?:	 func [value [any-type!]][function!	= type? value]
get-path?:	 func [value [any-type!]][get-path!	= type? value]
get-word?:	 func [value [any-type!]][get-word!	= type? value]
integer?:    func [value [any-type!]][integer!	= type? value]
lit-path?:	 func [value [any-type!]][lit-path!	= type? value]
lit-word?:	 func [value [any-type!]][lit-word!	= type? value]
logic?:		 func [value [any-type!]][logic!	= type? value]
native?:	 func [value [any-type!]][native!	= type? value]
none?:		 func [value [any-type!]][none!		= type? value]
op?:		 func [value [any-type!]][op!		= type? value]
paren?:		 func [value [any-type!]][paren!	= type? value]
path?:		 func [value [any-type!]][path!		= type? value]
refinement?: func [value [any-type!]][refinement! = type? value]
set-path?:	 func [value [any-type!]][set-path!	= type? value]
set-word?:	 func [value [any-type!]][set-word!	= type? value]
string?:	 func [value [any-type!]][string!	= type? value]
unset?:		 func [value [any-type!]][unset!	= type? value]
word?:		 func [value [any-type!]][word!		= type? value]

spec-of: func [value][reflect :value 'spec]
body-of: func [value][reflect :value 'body]