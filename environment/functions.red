Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %functions.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

attempt: func [
	"Tries to evaluate and returns result or NONE on error"
	value
][
	if not error? set/any 'value try :value [get/any 'value]
]

comment: func [value][]

quit: func [
	"Stops evaluation and exits the program"
	/return status	[integer!] "Return an exit status"
][
	quit-return any [status 0]
]

empty?: func [
	"Returns true if a series is at its tail"
	series	[series! none!]
	return:	[logic!]
][
	either series = none [true][tail? series]
]

??: func [
	"Prints a word and the value it refers to (molded)"
	'value [word!]
][
	prin mold :value
	prin ": "
	either value? :value [
		probe get/any :value
	][
		print "unset!"
	]
]

probe: func [
	"Returns a value after printing its molded form"
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

first:	func ["Returns the first value in a series"  s [series! pair! tuple!]] [pick s 1]	;@@ temporary definitions, should be natives ?
second:	func ["Returns the second value in a series" s [series! pair! tuple!]] [pick s 2]
third:	func ["Returns the third value in a series"  s [series! pair! tuple!]] [pick s 3]
fourth:	func ["Returns the fourth value in a series" s [series! pair! tuple!]] [pick s 4]
fifth:	func ["Returns the fifth value in a series"  s [series! pair! tuple!]] [pick s 5]

last:	func ["Returns the last value in a series"  s [series!]][pick back tail s 1]


action?:	 func ["Returns true if the value is this type" value [any-type!]] [action!		= type? :value]
bitset?:	 func ["Returns true if the value is this type" value [any-type!]] [bitset!		= type? :value]
binary?:	 func ["Returns true if the value is this type" value [any-type!]] [binary!		= type? :value]
block?:		 func ["Returns true if the value is this type" value [any-type!]] [block!		= type? :value]
char?: 		 func ["Returns true if the value is this type" value [any-type!]] [char!		= type? :value]
datatype?:	 func ["Returns true if the value is this type" value [any-type!]] [datatype!	= type? :value]
error?:		 func ["Returns true if the value is this type" value [any-type!]] [error!		= type? :value]
file?:		 func ["Returns true if the value is this type" value [any-type!]] [file!		= type? :value]
float?:		 func ["Returns true if the value is this type" value [any-type!]] [float!		= type? :value]
function?:	 func ["Returns true if the value is this type" value [any-type!]] [function!	= type? :value]
get-path?:	 func ["Returns true if the value is this type" value [any-type!]] [get-path!	= type? :value]
get-word?:	 func ["Returns true if the value is this type" value [any-type!]] [get-word!	= type? :value]
hash?:		 func ["Returns true if the value is this type" value [any-type!]] [hash!		= type? :value]
image?:		 func ["Returns true if the value is this type" value [any-type!]] [image!		= type? :value]
integer?:    func ["Returns true if the value is this type" value [any-type!]] [integer!	= type? :value]
issue?:    	 func ["Returns true if the value is this type" value [any-type!]] [issue!		= type? :value]
lit-path?:	 func ["Returns true if the value is this type" value [any-type!]] [lit-path!	= type? :value]
lit-word?:	 func ["Returns true if the value is this type" value [any-type!]] [lit-word!	= type? :value]
logic?:		 func ["Returns true if the value is this type" value [any-type!]] [logic!		= type? :value]
map?:		 func ["Returns true if the value is this type" value [any-type!]] [map!		= type? :value]
native?:	 func ["Returns true if the value is this type" value [any-type!]] [native!		= type? :value]
none?:		 func ["Returns true if the value is this type" value [any-type!]] [none!		= type? :value]
object?:	 func ["Returns true if the value is this type" value [any-type!]] [object!		= type? :value]
op?:		 func ["Returns true if the value is this type" value [any-type!]] [op!			= type? :value]
pair?:		 func ["Returns true if the value is this type" value [any-type!]] [pair!		= type? :value]
paren?:		 func ["Returns true if the value is this type" value [any-type!]] [paren!		= type? :value]
path?:		 func ["Returns true if the value is this type" value [any-type!]] [path!		= type? :value]
percent?:	 func ["Returns true if the value is this type" value [any-type!]] [percent!	= type? :value]
refinement?: func ["Returns true if the value is this type" value [any-type!]] [refinement! = type? :value]
routine?:	 func ["Returns true if the value is this type" value [any-type!]] [routine!	= type? :value]
set-path?:	 func ["Returns true if the value is this type" value [any-type!]] [set-path!	= type? :value]
set-word?:	 func ["Returns true if the value is this type" value [any-type!]] [set-word!	= type? :value]
string?:	 func ["Returns true if the value is this type" value [any-type!]] [string!		= type? :value]
typeset?:	 func ["Returns true if the value is this type" value [any-type!]] [typeset!	= type? :value]
tuple?:		 func ["Returns true if the value is this type" value [any-type!]] [tuple!		= type? :value]
unset?:		 func ["Returns true if the value is this type" value [any-type!]] [unset!		= type? :value]
url?:		 func ["Returns true if the value is this type" value [any-type!]] [url!		= type? :value]
vector?:	 func ["Returns true if the value is this type" value [any-type!]] [vector!		= type? :value]
word?:		 func ["Returns true if the value is this type" value [any-type!]] [word!		= type? :value]

any-block?:		func ["Returns true if the value is any type of block"	  value [any-type!]][find any-block! 	type? :value]
any-function?:	func ["Returns true if the value is any type of function" value [any-type!]][find any-function! type? :value]
any-object?:	func ["Returns true if the value is any type of object"	  value [any-type!]][find any-object!	type? :value]
any-path?:		func ["Returns true if the value is any type of path"	  value [any-type!]][find any-path!		type? :value]
any-string?:	func ["Returns true if the value is any type of string"	  value [any-type!]][find any-string!	type? :value]
any-word?:		func ["Returns true if the value is any type of word"	  value [any-type!]][find any-word!		type? :value]
series?:		func ["Returns true if the value is any type of series"	  value [any-type!]][find series!		type? :value]

spec-of: func [
	"Returns the spec of a value that supports reflection"
	value
][
	reflect :value 'spec
]

body-of: func [
	"Returns the body of a value that supports reflection"
	value
][
	reflect :value 'body
]

words-of: func [
	"Returns the list of words of a value that supports reflection"
	value
][
	reflect :value 'words
]

values-of: func [
	"Returns the list of values of a value that supports reflection"
	value
][
	reflect :value 'values
]

keys-of: :words-of

context: func [spec [block!]][make object! spec]

replace: func [
	series [series!]
	pattern
	value
	/all
	/local pos len
][
	len: either series? :pattern [length? pattern][1]
	
	either all [
		pos: series
		either series? :pattern [
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
	value [number! pair!]
][
	either pair! = type? value [
		make logic! all [value/1 = 0 value/2 = 0]
	][
		value = 0
	]
]

charset: func [
	spec [block! integer! char! string!]
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

load: function [
	"Returns a value or block of values by reading and evaluating a source"
	source [file! url! string!]
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
	switch/default type?/word source [
		file!	[source: read source]
		url!	[source]
		binary! [source]
	][source]

	either part [
		system/lexer/transcode/part source out length
	][
		system/lexer/transcode source out
	]
	unless :all [if 1 = length? out [out: out/1]]
	out 
]

cause-error: function [
	"Causes an immediate error throw, with the provided information"
	err-type [word!]
	err-id	 [word!]
	args	 [block!]
][
	args: reduce args
	do make error! [
		type: err-type
		id: err-id
		arg1: first args
		arg2: second args
		arg3: third args
	]
]

pad: func [
	"Align a string to a given size prepending whitespaces"
	str [string!]		"String to pad"
	n	[integer!]		"Size (in characters) to align to"
	/left				"Align the string to the left side"
	return: [string!]	"Modified input string at head"
][
	head insert/dup
		any [all [left str] tail str]
		#" "
		(n - length? str)
]

modulo: func [
	"Compute a nonnegative remainder of A divided by B"
	a		[number! char! pair! tuple! vector!]
	b		[number! char! pair! tuple! vector!]
	return: [number! char! pair! tuple! vector!]
	/local r
][
	b: absolute b
    all [0 > r: a % b r: r + b]
    a: absolute a
    either all [a + r = (a + b) 0 < r + r - b] [r - b] [r]
]

eval-set-path: func [value1][]

to-red-file: func [
	path	[file! string!]
	return: [file!]
	/local colon? slash? len i c dst
][
	colon?: slash?: no
	len: length? path
	dst: make file! len
	if zero? len [return dst]
	i: 1
	either system/platform = 'Windows [
		until [
			c: path/(i)
			i: i + 1
			case [
				c = #":" [
					if any [colon? slash?] [return dst]
					colon?: yes
					if i <= len [
						c: path/(i)
						if any [c = #"\" c = #"/"][i: i + 1]	;-- skip / in foo:/file
					]
					c: #"/"
				]
				any [c = #"\" c = #"/"][
					if slash? [continue]
					c: #"/"
					slash?: yes
				]
				true [slash?: no]
			]
			append dst c
			i > len
		]
		if colon? [insert dst #"/"]
	][
		insert dst path
	]
	dst
]

what-dir: does [to-red-file get-current-dir]

;------------------------------------------
;-				Aliases					  -
;------------------------------------------

atan2: :arctangent2
object: :context