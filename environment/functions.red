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
	#if config/OS <> 'Windows [
		if system/console [system/console/terminate]
	]
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

#do keep [
	list: make block! 50
	to-list: [
		bitset! binary! block! char! email! file! float! get-path! get-word! hash!
		integer! issue! lit-path! lit-word! logic! map! none! pair! paren! path!
		percent! refinement! set-path! set-word! string! tag! time! typeset! tuple!
		unset! url! word! image!
	]
	test-list: union to-list [
		handle! error! action! native! datatype! function! image! object! op! routine! vector!
	]
	
	;-- Generates all accessor functions (spec-of, body-of, words-of,...)
	
	foreach [name desc][
		spec   "Returns the spec of a value that supports reflection"
		body   "Returns the body of a value that supports reflection"
		words  "Returns the list of words of a value that supports reflection"
		class  "Returns the class ID of an object"
		values "Returns the list of values of a value that supports reflection"
	][
		repend list [
			load join form name "-of:" 'func reduce [desc 'value] new-line/all compose [
				reflect :value (to lit-word! name)
			] off
		]
	]
	
	;-- Generates all type testing functions (action?, bitset?, binary?,...)
	
	foreach name test-list [
		repend list [
			load head change back tail form name "?:" 'func
			["Returns true if the value is this type" value [any-type!]]
			compose [(name) = type? :value]
		]
	]
	
	;-- Generates all typesets testing functions (any-list?, any-block?,...)
	
	docstring: "Returns true if the value is any type of "
	foreach name [
		any-list! any-block! any-function! any-object! any-path! any-string! any-word!
		series! number! immediate! scalar! all-word!
	][
		repend list [
			load head change back tail form name "?:" 'func
			compose [(join docstring head clear back tail form name) value [any-type!]]
			compose [find (name) type? :value]
		]
	]
	
	;-- Generates all conversion wrapper functions (to-bitset, to-binary, to-block,...)

	foreach name to-list [
		repend list [
			to set-word! join "to-" head remove back tail form name 'func
			reduce [reform ["Convert to" name "value"] 'value]
			compose [to (name) :value]
		]
	]
	list
]

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
			while [pos: find pos :pattern][
				pos: change pos value
			]
		]
	][
		if pos: find series :pattern [
			remove/part pos len
			insert pos value
		]
	]
	series
]

math: function [
	"Evaluates a block using math precedence rules, returning the last result"
	body [block!] "Block to evaluate"
	/safe		  "Returns NONE on error"
][
	parse body: copy/deep body rule: [
		any [
			pos: ['* (op: 'multiply) | quote / (op: 'divide)] 
			[ahead sub: paren! (sub/1: math as block! sub/1) | skip] (
				end: skip pos: back pos 3
				pos: change/only/part pos as paren! copy/part pos end end
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
				p-indent "match:" mold/flat/part rule 50 newline
				p-indent "input:" mold/flat/part input 50 p-indent
			]
		]
		match [print [p-indent "==>" pick ["matched" "not matched"]  match?]]
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
	/header "TBD"
	/all    "Load all values, returns a block. TBD: Don't evaluate Red header"
	/trap	"Load all values, returns [[values] position error]"
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
	unless out [out: make block! 10]
	
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

	result: case [
		part  [system/lexer/transcode/part source out trap length]
		next  [set position system/lexer/transcode/one source out trap]
		'else [system/lexer/transcode source out trap]
	]
	either trap [result][
		unless :all [if 1 = length? out [out: out/1]]
		out
	]
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
	dst: either any [file? where url? where][where][none]
	either as [
		if word? format [
			either codec: select system/codecs format [
				data: do [codec/encode value dst]
				if same? data dst [exit]	;-- if encode returns dst back, means it already save value to dst
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
				data: do [codec/encode value dst]
				if same? data dst [exit]
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

mod: func [
	"Compute a nonnegative remainder of A divided by B"
	a		[number! char! pair! tuple! vector! time!]
	b		[number! char! pair! tuple! vector! time!]	"Must be nonzero"
	return: [number! char! pair! tuple! vector! time!]
	/local r
][
	if (r: a % b) < 0 [r: r + b]
	a: absolute a
	either all [a + r = (a + b) r + r - b > 0][r - b][r]
]

modulo: func [
	"{Wrapper for MOD that handles errors like REMAINDER. Negligible values (compared to A and B) are rounded to zero"
	a		[number! char! pair! tuple! vector! time!]
	b		[number! char! pair! tuple! vector! time!]
	return: [number! char! pair! tuple! vector! time!]
	/local r
][
	r: mod a absolute b
	either any [a - r = a r + b = b][0][r]
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
	limit: system/console/size/x - 13
	max-sz: either n [
		limit / n - n					;-- account for n extra spaces
	][
		n: max 1 limit / 22				;-- account for n extra spaces
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
	()
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

extract: function [
	"Extracts a value from a series at regular intervals"
	series	[series!]
	width	[integer!]	 "Size of each entry (the skip)"
	/index				 "Extract from an offset position"
		pos [integer!]	 "The position" 
	/into				 "Provide an output series instead of creating a new one"
		output [series!] "Output series"
][
	width: max 1 width
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
	unless args: system/script/args [exit]				;-- non-executable case

	;-- extract system/options/boot
	either args/1 = dbl-quote [
		until [args: next args args/1 <> dbl-quote]
		system/options/boot: copy/part args pos: find args dbl-quote
		until [pos: next pos pos/1 <> dbl-quote]
	][
		pos: either pos: find/tail args space [back pos][tail args]
		system/options/boot: copy/part args pos
	]
	;-- clean-up system/script/args
	remove/part args: head args pos
	
	;-- set system/options/args
	either empty? trim/head args [system/script/args: none][
		unescape: quote (
			if odd? len: offset? s e [len: len - 1]
			e: skip e negate len / 2
			e: remove/part s e
		)
		parse args: copy args [							;-- preprocess escape chars
			any [
				s: {'"} thru {"'} e: (s/1: #"{" e/-1: #"}")
				| s: #"'" [to #"'" e: (s/1: #"{" e/1: #"}") | to end]
				| s: some #"\" e: {"} unescape :e
				  thru [s: some #"\" e: {"}] unescape :e
				| skip
			]
		]
		system/options/args: parse head args [			;-- tokenize and collect
			collect some [[
				some #"^"" keep copy s to #"^"" some #"^""
				| #"{" keep copy s to #"}" skip
				| keep copy s [to #" " | to end]] any #" "
			]
		]
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
		any [pos: ['keep | 'collected] (pos/1: bind pos/1 'keep) | any-string! | binary! | into rule | skip]
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
	/local out cnt f not-file?
][
	not-file?: not file? file
	
	file: case [
		any [only not-file?][
			copy file
		]
		#"/" = first file [
			file: next file
			out: next what-dir
			while [
				all [
					#"/" = first file
					do [f: find/tail out #"/"]
				]
			][
				file: next file
				out: f
			]
			 append clear out file
		]
		'else [append what-dir file]
	]
	if all [dir not dir? file][append file #"/"]
	
	out: make file! length? file
	cnt: 0
	
	parse reverse file [
		some [
			"../" (cnt: cnt + 1)
			| "./"
			| #"/" (if any [not-file? not dir? out][append out #"/"])
			| copy f thru #"/" (
				either cnt > 0 [cnt: cnt - 1][
					unless find ["" "." ".."] as string! f [append out f]
				]
			)
		]
	]
	if all [dir? out #"/" <> last file][take/last out]
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

do-file: func [file [file! url!] /local saved code new-path src][
	saved: system/options/path
	unless src: find/case read file "Red" [
		cause-error 'syntax 'no-header reduce [file]
	]
	code: expand-directives load/all src
	if code/1 = 'Red/System [cause-error 'internal 'red-system []]
	if file? file [
		new-path: first split-path clean-path file
		change-dir new-path
	]
	set/any 'code do code
	if file? file [change-dir saved]
	:code
]

cos: func [
	"Returns the trigonometric cosine"
	angle [float!] "Angle in radians"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/cosine* no 1
	]
]

sin: func [
	"Returns the trigonometric sine"
	angle [float!] "Angle in radians"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/sine* no 1
	]
]

tan: func [
	"Returns the trigonometric tangent"
	angle [float!] "Angle in radians"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/tangent* no 1
	]
]

acos: func [
	"Returns the trigonometric arccosine"
	angle [float!] "Angle in radians"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/arccosine* no 1
	]
]

asin: func [
	"Returns the trigonometric arcsine"
	angle [float!] "Angle in radians"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/arcsine* no 1
	]
]

atan: func [
	"Returns the trigonometric arctangent"
	angle [float!] "Angle in radians"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/arctangent* no 1
	]
]

atan2: func [
	"Returns the angle of the point y/x in radians"
	y		[number!]
	x		[number!]
	return:	[float!]
][
	#system [
		stack/arguments: stack/arguments - 2
		natives/arctangent2* no 1
	]
]


sqrt: func [
	"Returns the square root of a number"
	number	[number!]
	return:	[float!]
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/square-root* no
	]
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

keys-of:	:words-of
object:		:context
halt:		:quit										;-- default behavior unless console is loaded
