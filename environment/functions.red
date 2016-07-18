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

routine: func [spec [block!] body [block!]][
	cause-error 'internal 'routines []
]

also: func [
	"Returns the first value, but also evaluates the second."
	value1 [any-type!]
	value2 [any-type!]
][
	get/any 'value1
]

attempt: func [
	"Tries to evaluate a block and returns result or NONE on error"
	value [block!]
	/safer "Capture all possible errors and exceptions"
][
	either safer [
		unless error? set/any 'value try/all :value [get/any 'value]
	][
		unless error? set/any 'value try :value [get/any 'value]
	]
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
	print either value? :value [mold get/any :value]["unset!"]
]

probe: func [
	"Returns a value after printing its molded form"
	value [any-type!]
][
	print mold :value 
	:value
]

quote: func [
	:value
][
	:value
]

first:	func ["Returns the first value in a series"  s [series! tuple! pair! time!]] [pick s 1]	;@@ temporary definitions, should be natives ?
second:	func ["Returns the second value in a series" s [series! tuple! pair! time!]] [pick s 2]
third:	func ["Returns the third value in a series"  s [series! tuple! time!]] [pick s 3]
fourth:	func ["Returns the fourth value in a series" s [series! tuple!]] [pick s 4]
fifth:	func ["Returns the fifth value in a series"  s [series! tuple!]] [pick s 5]

last:	func ["Returns the last value in a series"  s [series!]][pick back tail s 1]


action?:	 func ["Returns true if the value is this type" value [any-type!]] [action!		= type? :value]
bitset?:	 func ["Returns true if the value is this type" value [any-type!]] [bitset!		= type? :value]
binary?:	 func ["Returns true if the value is this type" value [any-type!]] [binary!		= type? :value]
block?:		 func ["Returns true if the value is this type" value [any-type!]] [block!		= type? :value]
char?: 		 func ["Returns true if the value is this type" value [any-type!]] [char!		= type? :value]
datatype?:	 func ["Returns true if the value is this type" value [any-type!]] [datatype!	= type? :value]
email?:		 func ["Returns true if the value is this type" value [any-type!]] [email!		= type? :value]
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
tag?:		 func ["Returns true if the value is this type" value [any-type!]] [tag!		= type? :value]
time?:		 func ["Returns true if the value is this type" value [any-type!]] [time!		= type? :value]
typeset?:	 func ["Returns true if the value is this type" value [any-type!]] [typeset!	= type? :value]
tuple?:		 func ["Returns true if the value is this type" value [any-type!]] [tuple!		= type? :value]
unset?:		 func ["Returns true if the value is this type" value [any-type!]] [unset!		= type? :value]
url?:		 func ["Returns true if the value is this type" value [any-type!]] [url!		= type? :value]
vector?:	 func ["Returns true if the value is this type" value [any-type!]] [vector!		= type? :value]
word?:		 func ["Returns true if the value is this type" value [any-type!]] [word!		= type? :value]

any-list?:		func ["Returns true if the value is any type of list"	  value [any-type!]][find any-list! 	type? :value]
any-block?:		func ["Returns true if the value is any type of block"	  value [any-type!]][find any-block! 	type? :value]
any-function?:	func ["Returns true if the value is any type of function" value [any-type!]][find any-function! type? :value]
any-object?:	func ["Returns true if the value is any type of object"	  value [any-type!]][find any-object!	type? :value]
any-path?:		func ["Returns true if the value is any type of path"	  value [any-type!]][find any-path!		type? :value]
any-string?:	func ["Returns true if the value is any type of string"	  value [any-type!]][find any-string!	type? :value]
any-word?:		func ["Returns true if the value is any type of word"	  value [any-type!]][find any-word!		type? :value]
series?:		func ["Returns true if the value is any type of series"	  value [any-type!]][find series!		type? :value]
number?:		func ["Returns true if the value is any type of number"	  value [any-type!]][find number!		type? :value]

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

alter: func [
	"If a value is not found in a series, append it; otherwise, remove it. Returns true if added"
	series [series!]
	value
][
	not none? unless remove find series :value [append series :value]
]

offset?: func [
	"Returns the offset between two series positions"
	series1 [series!]
	series2 [series!]
][
	subtract index? series2 index? series1
]

repend: func [
	"Appends a reduced value to a series and returns the series head"
	series [series!]
	value
	/only "Appends a block value as a block"
][
	head either only [
		insert/only tail series reduce :value
	][
		reduce/into :value tail series					;-- avoids wasting an intermediary block
	]
]

replace: function [
	series [series!]
	pattern
	value
	/all
][
	many?: any [
		system/words/all [series? :pattern any-string? series]
		binary? series
		system/words/all [any-list? series any-list? :pattern]
	]
	len: either many? [length? pattern][1]
	
	either all [
		pos: series
		either many? [
			while [pos: find pos pattern][
				remove/part pos len
				pos: insert pos value
			]
		][
			while [pos: find pos :pattern][pos/1: value]
		]
	][
		if pos: find series :pattern [
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

math: function [
	"Evaluates a block using math precedence rules, returning the last result"
	body [block!] "Block to evaluate"
	/safe		  "Returns NONE on error"
][
	parse body: copy/deep body rule: [
		any [
			pos: ['* (op: 'multiply) | quote / (op: 'divide)] (
				end: skip pos: back pos 3
				pos: change/only/part pos to-paren copy/part pos end end
			) :pos
			| into rule
			| skip
		]
	]
	either safe [attempt body][do body]
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

suffix?: function [
	"Returns the suffix (extension) of a filename or url, or NONE if there is no suffix"
	path [file! url! string! email!]
][
	if all [
		path: find/last path #"."
		not find path #"/"
	][to file! path]
]

load: function [
	"Returns a value or block of values by reading and evaluating a source"
	source [file! url! string! binary!]
	/header "TBD: Include Red header as a loaded value"
	/all    "TBD: Don't evaluate Red header"
	/next	"Load the next value only, updates source series word"
		position [word!] "Word updated with new series position"
	/part
		length [integer! string!]
	/into "Put results in out block, instead of creating a new block"
		out [block!] "Target block for results"
	/as   "Specify the type of data; use NONE to load as code"
		type [word! none!] "E.g. json, html, jpeg, png, etc"
][
	if as [
		if word? type [
			either codec: select system/codecs type [
				if url? source [source: read/binary source]
				return do [codec/decode source]
			][
				return none
			]
		]
	]

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
	unless out [out: make block! 100]
	
	switch/default type?/word source [
		file!	[
			suffix: suffix? source
			foreach [name codec] system/codecs [
				if (find codec/suffixes suffix) [		;@@ temporary required until dyn-stack implemented
					return do [codec/decode source]
				]
			]
			source: read source
		]
		url!	[
			source: read/info/binary source
			either source/1 = 200 [
				foreach [name codec] system/codecs [
					foreach mime codec/mime-type [
						if (find source/2/Content-Type mold mime) [
							return do [codec/decode source/3]
						]
					]
				]
			][return none]
			source: to string! source/3
		]
		binary! [source: to string! source]				;-- For text: UTF-8 encoding TBD: load image in binary form
	][source]

	case [
		part  [system/lexer/transcode/part source out length]
		next  [set position system/lexer/transcode/one source out]
		'else [system/lexer/transcode source out]
	]
	unless :all [if 1 = length? out [out: out/1]]
	out 
]

save: function [
	"Saves a value, block, or other data to a file, URL, binary, or string"
	where [file! url! string! binary! none!] "Where to save"
	value   "Value(s) to save"
	/header "Provide a Red header block (or output non-code datatypes)"
		header-data [block! object!]
	/all    "TBD: Save in serialized format"
	/length "Save the length of the script content in the header"
	/as     "Specify the format of data; use NONE to save as plain text"
		format [word! none!] "E.g. json, html, jpeg, png, redbin etc"
][
	either as [
		if word? format [
			either codec: select system/codecs format [
				data: do [codec/encode value]
			][exit]
		]
	][
		if length [header: true header-data: any [header-data copy []]]
		if header [
			if object? :header-data [header-data: body-of header-data]
		]
		suffix: suffix? where
		find-encoder?: no
		foreach [name codec] system/codecs [
			if (find codec/suffixes suffix) [		;@@ temporary required until dyn-stack implemented
				data: do [codec/encode value]
				find-encoder?: yes
			]
		]
		unless find-encoder? [
			data: either all [
				append mold/all/only :value newline
			][
				trim mold/only :value
			]
			case/all [
				not binary? data [data: to binary! data]
				length [
					either pos: find/tail header-data 'length [
						insert remove pos length? data			;@@ change pos length? data
					][
						append header-data compose [length: (length? data)]
					]
				]
				header-data [
					header-str: copy "Red [^/"					;@@ mold header, use new-line instead
					foreach [k v] header-data [
						append header-str reduce [#"^-" mold k #" " mold v newline]
					]
					append header-str "]^/^/"
					insert data header-str
				]
			]
		]
	]
	case [
		file? where [write where data]
		url?  where [write where data]
		none? where [data]
		'else		[append where data]
	]
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
	"Pad a string on right side with spaces"
	str		[string!]		"String to pad"
	n		[integer!]		"Total size (in characters) of the new string"
	/left					"Pad the string on left side"
	/with c	[char!]			"Pad with char"
	return:	[string!]		"Modified input string at head"
][
	head insert/dup
		any [all [left str] tail str]
		any [c #" "]
		(n - length? str)
]

modulo: func [
	"Compute a nonnegative remainder of A divided by B"
	a		[number! char! pair! tuple! vector! time!]
	b		[number! char! pair! tuple! vector! time!]
	return: [number! char! pair! tuple! vector! time!]
	/local r
][
	b: absolute b
	if (r: a % b) < 0 [r: r + b]
	a: absolute a
	either all [a + r = (a + b) 0 < r + r - b][r - b][r]
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
			c: pick path i
			i: i + 1
			case [
				c = #":" [
					if any [colon? slash?] [return dst]
					colon?: yes
					if i <= len [
						c: pick path i
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

dir?: func [file [file! url!]][#"/" = last file]

normalize-dir: function [
	dir [file! word! path!]
][
	unless file? dir [dir: to file! mold dir]
	if slash <> first dir [dir: clean-path append copy system/options/path dir]
	unless dir? dir [dir: append copy dir slash]
	dir
]

what-dir: func [/local path][
	"Returns the active directory path"
	path: to-red-file get-current-dir
	unless dir? path [append path #"/"]
	path
]

change-dir: function [
	"Changes the active directory path"
	dir [file! word! path!] "New active directory of relative path to the new one"
][
	unless exists? dir: normalize-dir dir [cause-error 'access 'cannot-open [dir]]
	system/options/path: dir
]

list-dir: function [
	"Displays a list of files and directories from given folder or current one"
	dir [any-type!]  "Folder to list"
	/col			 "Forces the display in a given number of columns"
		n [integer!] "Number of columns"
][
	unless value? 'dir [dir: %.]
	
	unless find [file! word! path!] type?/word :dir [
		cause-error 'script 'expect-arg ['list-dir type? :dir 'dir]
	]
	list: read normalize-dir dir
	max-sz: either n [
		system/console/limit / n - n					;-- account for n extra spaces
	][
		n: max 1 system/console/limit / 22				;-- account for n extra spaces
		22 - n
	]

	while [not tail? list][
		loop n [
			if max-sz <= length? name: list/1 [
				name: append copy/part name max-sz - 4 "..."
			]
			prin tab
			prin pad form name max-sz
			prin " "
			if tail? list: next list [exit]
		]
		prin lf
	]
]

make-dir: function [
	"Creates the specified directory. No error if already exists"
	path [file!]
	/deep "Create subdirectories too"
][
	if empty? path [return path]
	if slash <> last path [path: dirize path]
	if exists? path [
		if dir? path [return path]
		cause-error 'access 'cannot-open path
	]
	if any [not deep url? path] [
		create-dir path
		return path
	]
	path: copy path
	dirs: copy []
	while [
		all [
			not empty? path
			not exists? path
			remove back tail path
		]
	][
		end: any [find/last/tail path slash path]
		insert dirs copy end
		clear end
	]
	created: copy []
	foreach dir dirs [
		path: either empty? path [dir] [path/:dir]
		append path slash
		if error? try [make-dir path] [
			foreach dir created [attempt [delete dir]]
			cause-error 'access 'cannot-open path
		]
		insert created path
	]
	path
]

to-image: func [value][
	case [
		binary? value [
			;@@ TBD
		]
		all [											;-- face!
			system/view
			object? value
			do [find words-of value words-of face!]
		][
			system/view/platform/to-image value
		]
	]
]

hex-to-rgb: function [
	"Converts a color in hex format to a tuple value; returns NONE if it fails"
	hex		[issue!] "Accepts #rgb, #rrggbb, #rrggbbaa"	 ;-- 3,6,8 nibbles supported
	return: [tuple! none!]								 ;-- 3 or 4 bytes long
][
	switch length? str: form hex [
		3 [
			uppercase str
			forall str [str/1: str/1 - pick "70" str/1 >= #"A"]

			as-color 
				shift/left to integer! str/1 4
				shift/left to integer! str/2 4
				shift/left to integer! str/3 4
		]
		6 [if bin: to binary! hex [as-color bin/1 bin/2 bin/3]]
		8 [if bin: to binary! hex [as-rgba bin/1 bin/2 bin/3 bin/4]]
	]
]

within?: func [
	"Return TRUE if the point is within the rectangle bounds"
	point	[pair!] "XY position"
	offset  [pair!] "Offset of area"
	size	[pair!] "Size of area"
	return: [logic!]
][
	make logic! all [
		point/x >= offset/x
		point/y >= offset/y
		point/x < (offset/x + size/x)
		point/y < (offset/y + size/y)
	]
]

overlap?: function [
	"Return TRUE if the two faces bounding boxes are overlapping"
	A		[object!] "First face"
	B		[object!] "Second face"
	return: [logic!]  "TRUE if overlapping"
][
	A1: A/offset
	B1: B/offset
	A2: A1 + A/size
	B2: B1 + B/size
	make logic! all [A1/x < B2/x B1/x < A2/x A1/y < B2/y B1/y < A2/y]
]

extract: function [
	"Extracts a value from a series at regular intervals"
	series	[series!]
	width	[integer!]	 "Size of each entry (the skip)"
	/index				 "Extract from an offset position"
		pos [integer!]	 "The position" 
	/into				 "Provide an output series instead of creating a new one"
		output [series!] "Output series"
][
	if pos [series: at series pos]
	unless into [output: make series (length? series) / width]
	
	while [not tail? series][
		append/only output series/1
		series: skip series width
	]
	output
]

extract-boot-args: function [
	"Process command-line arguments and store values in system/options (internal usage)"
][
	args: system/options/args
	pos: find next args get pick [dbl-quote space] args/1 = dbl-quote
	
	either pos [
		system/options/boot: copy/part next args pos
		if pos/1 = dbl-quote [pos: next pos]
		if pos/2 = space [pos: skip pos 2]
		remove/part args pos
		if empty? trim/head args [system/options/args: none]
	][
		system/options/boot: args
		system/options/args: none
	]
]

collect: function [
	"Collect in a new block all the values passed to KEEP function from the body block"
	body [block!]		 "Block to evaluate"
	/into 		  		 "Insert into a buffer instead (returns position after insert)"
		collected [series!] "The buffer series (modified)"
][
	keep: func [v /only][either only [append/only collected v][append collected v] v]
	
	unless collected [collected: make block! 16]
	parse body rule: [									;-- selective binding (needs BIND/ONLY support)
		any [pos: ['keep | 'collected] (pos/1: bind pos/1 'keep) | any-string! | into rule | skip]
	]
	do body
	either into [collected][head collected]
]

flip-exe-flag: function [
	"Flip the sub-system for the red.exe between console and GUI modes (Windows only)"
	path [file!]		"Path to the red.exe"
][
	file: either dir? path [append copy path %red.exe][path]
	buffer: read/binary file
	flag: skip find/tail/case buffer "PE" 90
	flag/1: either flag/1 = 2 [3][2]
	write/binary file buffer
]

split: function [
	"Break a string series into pieces using the provided delimiters"
	series [any-string!] dlm [string! char! bitset!] /local s
][
	num: either string? dlm [length? dlm][1]
	parse series [collect any [copy s [to dlm | to end] keep (s) num skip]]
]

dirize: func [
	"Returns a copy of the path turned into a directory"
	path [file! string! url!]
][
	either #"/" <> pick path length? path [append copy path #"/"] [copy path]
]

clean-path: func [
	"Cleans-up '.' and '..' in path; returns the cleaned path"
	file [file! url! string!]
	/only "Do not prepend current directory"
	/dir "Add a trailing / if missing"
	/local out cnt f
][
	case [
		any [only not file? file] [file: copy file]
		#"/" = first file [
			file: next file
			out: next what-dir
			while [
				all [
					#"/" = first file
					do [f: find/tail out #"/"]
				]
			] [
				file: next file
				out: f
			]
			file: append clear out file
		]
		true [file: append what-dir file]
	]
	if all [dir not dir? file] [append file #"/"]
	out: make file! length? file
	cnt: 0
	parse reverse file [
		some [
			"../" (cnt: cnt + 1)
			| "./"
			| #"/" (if any [not file? file #"/" <> last out] [append out #"/"])
			| copy f [to #"/" | to end skip] (
				either cnt > 0 [
					cnt: cnt - 1
				] [
					unless find ["" "." ".."] to string! f [append out f]
				]
			)
		]
	]
	if all [#"/" = last out #"/" <> last file] [remove back tail out]
	reverse out
]

split-path: func [
	"Splits a file or URL path. Returns a block containing path and target"
	target [file! url!]
	/local dir pos
][
	parse target [
		[#"/" | 1 2 #"." opt #"/"] end (dir: dirize target) |
		pos: any [thru #"/" [end | pos:]] (
			all [empty? dir: copy/part target at head target index? pos dir: %./]
			all [find [%. %..] pos: to file! pos insert tail pos #"/"]
		)
	]
	reduce [dir pos]
]

do-file: func [file [file!] /local saved code new-path][
	saved: system/options/path
	code: load file
	new-path: first split-path clean-path file
	change-dir new-path
	set/any 'code do code
	change-dir saved
	:code
]

;--- Temporary definition, use at your own risks! ---
rejoin: function [
	"Reduces and joins a block of values."
	block [block!] "Values to reduce and join"
][
	if empty? block: reduce block [return block]
	append either series? first block [copy first block] [
		form first block
	] next block
]

;------------------------------------------
;-				Aliases					  -
;------------------------------------------

atan2:		:arctangent2
object:		:context
halt:		:quit										;-- default behavior unless console is loaded
