Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %functions.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

routine: func ["Defines a function with a given Red spec and Red/System body" spec [block!] body [block!]][
	cause-error 'internal 'routines []
]

also: func [
	"Returns the first value, but also evaluates the second"
	value1 [any-type!]
	value2 [any-type!]
][
	:value1
]

attempt: func [
	"Tries to evaluate a block and returns result or NONE on error"
	code [block!]
	/safer "Capture all possible errors and exceptions"
	/local all result
][
	set 'all safer										;-- `all:` refuses to compile
	try/:all [set/any 'result do code]
	:result
]

comment: func ["Consume but don't evaluate the next value" 'value][]

quit: func [
	"Stops evaluation and exits the program"
	/return status	[integer!] "Return an exit status"
][
	#if all [
		config/OS <> 'Windows
		not config/gui-console?
	][
		if system/console [do [_terminate-console]]
	]
	if system/console [do [_save-cfg]]
	quit-return any [status 0]
]

empty?: func [
	"Returns true if data is a series at its tail or an empty map"
	data	[series! none! map!]
	return:	[logic!]
][
	either data [zero? length? data][true]
]

??: func [
	"Prints a word and the value it refers to (molded)"
	'value [word! path!]
][
	prin mold :value
	prin ": "
	print either any [path? :value value? :value][mold get/any :value]["unset!"]
]

probe: func [
	"Returns a value after printing its molded form"
	value [any-type!]
][
	print mold :value 
	:value
]

quote: func [
	"Return but don't evaluate the next value"
	:value [any-type!]
][
	:value
]

first:	func ["Returns the first value in a series"  s [series! tuple! pair! any-point! date! time!]] [pick s 1]	;@@ temporary definitions, should be natives ?
second:	func ["Returns the second value in a series" s [series! tuple! pair! any-point! date! time!]] [pick s 2]
third:	func ["Returns the third value in a series"  s [series! tuple! date! point3D! time!]] [pick s 3]
fourth:	func ["Returns the fourth value in a series" s [series! tuple! date!]] [pick s 4]
fifth:	func ["Returns the fifth value in a series"  s [series! tuple! date!]] [pick s 5]

last: func ["Returns the last value in a series" s [series! tuple!]] [pick s length? s]

#do keep [
	list: make block! 50
	to-list: [
		bitset! binary! block! char! email! file! float! get-path! get-word! hash!
		integer! issue! lit-path! lit-word! logic! map! none! pair! paren! path!
		percent! refinement! set-path! set-word! string! tag! time! typeset! tuple!
		unset! url! word! image! date! money! ref! point2D! point3D!
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
		series! number! immediate! scalar! all-word! any-point! planar!
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

context: func [
	"Makes a new object from an evaluated spec"
	spec [block!]
][
	make object! spec
]

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
	head either any [only not any-block? series][
		insert/only tail series reduce :value
	][
		reduce/into :value tail series					;-- avoids wasting an intermediary block
	]
]

replace: function [
	"Replaces values in a series, in place"
    series [any-block! any-string! binary! vector!] "The series to be modified"	;-- series! barring image!
    pattern "Specific value or parse rule pattern to match"
    value "New value, replaces pattern in the series" 
    /all  "Replace all occurrences, not just the first"
    /deep "Replace pattern in all sub-lists as well"
    /case "Case-sensitive replacement"
][
	parse?: any [
		system/words/all [deep any-list? series]
		system/words/all [
			any [binary? series any-string? series]
			any [block? :pattern bitset? :pattern]
		]
	]
	form?: system/words/all [
		any-string? series
		any [not any-string? :pattern tag? :pattern]	;-- search for a literal tag, including angle brackets
		not block?  :pattern
		not bitset? :pattern
	]
	quote?: system/words/all [
		not form?
		parse?
		not block?  :pattern
		not bitset? :pattern
	]
	
	pattern: system/words/case [
		form?  [form :pattern]
		quote? [reduce ['quote :pattern]]
		'else  [:pattern]
	]
	
	also series either parse? [
		deep?: system/words/all [						;-- don't match by any-list! datatype in binary!
			deep
			not binary? series
		]
		rule:  [
			any [
				end 
				| change pattern (value) [if (all) | break]
				| if (deep?) ahead any-list! into rule
				| skip
			]
		]
		
		parse series [case case rule]					;-- parse cannot process vector! and image!
	][
		many?: any [
			system/words/all [
				any [binary? series any-string? series]
				series? :pattern
			]
			system/words/all [
				any-list? series
				any-list? :pattern
			]
		]
		size: either many? [length? :pattern][1]
		seek: reduce [pick [find/case find] case 'series quote :pattern]

		active?: any-function? :value
		until [											;-- find does not support image!
			not system/words/all [
				series: do seek
				series: change/part series either active? [do [value]][value] size
				all
			]
		]
	]
]

math: function [
	"Evaluates expression using math precedence rules"
	datum [block! paren!] "Expression to evaluate"
	/safe				  "Returns NONE on error"
	/local match
][
	order: ['** ['* | quote / | quote % | quote //]]	;@@ compiler's lexer chokes on '/, '% and '//
	infix: [skip operator [enter | skip]]
	
	tally: [any [enter [fail] | recur [fail] | count [fail] | skip]]
	enter: [ahead paren! into tally]
	recur: [if (operator = '**) skip operator tally]
	count: [while ahead change only copy match infix (either safe [attempt match][do match])]

	datum: copy/deep datum
	foreach operator order [parse datum tally]
	either safe [attempt datum][do datum]
]

charset: func [
	"Shortcut for `make bitset!`"
	spec [block! integer! char! string! bitset! binary!]
][
	make bitset! spec
]

context [
	p-indent: make string! 30
	
	on-parse-event: func [
		"Standard parse/trace callback used by PARSE-TRACE"
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
					p-indent "input:" mold/flat/part input 50 newline
					p-indent "match:" mold/flat/part rule  50 p-indent
				]
			]
			match [print [p-indent "==>" pick ["matched" "not matched"]  match?]]
			end   [print ["return:" match?]]
		]
		true
	]

	set 'parse-trace func [
		"Wrapper for parse/trace using the default event processor"
		input [series!]
		rules [block!]
		/case "Uses case-sensitive comparison"
		/part "Limit to a length or position"
			limit [integer!]
		return: [logic! block!]
	][
		clear p-indent
		parse/:case/:part/trace input rules limit :on-parse-event
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

scan: func [
	"Returns the guessed type of the first serialized value from the input"
	buffer  [binary! string!] "Input UTF-8 buffer or string"
	/next					  "Returns both the type and the input after the value"
	/fast					  "Fast scanning, returns best guessed type"
	return: [datatype! none!] "Recognized or guessed type, or NONE on empty input"
][
	apply 'transcode/:next/:scan/:prescan [buffer  :next  not fast  fast]
]

load: function [
	"Returns a value or block of values by reading and evaluating a source"
	source [file! url! string! binary!]
	/header "TBD"
	/all    "Load all values, returns a block. TBD: Don't evaluate Red header"
	/trap	"Load all values, returns [[values] position error]"
	/next	"Load the next value only, updates source series word"
		position [word!] "Word updated with new series position"
	/part	"Limit to a length or position"
		length [integer! string!]
	/into "Put results in out block, instead of creating a new block"
		out [block!] "Target block for results"
	/as   "Specify the type of data; use NONE to load as code"
		type [word! none!] "E.g. bmp, gif, jpeg, png, redbin, json, csv"
][
	if as [
		if word? type [
			either codec: select system/codecs type [
				if url? source [source: read/binary source]
				return do [codec/decode source]
			][
				cause-error 'script 'invalid-refine-arg [/as type]
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
	
	switch type?/word source [
		file!	[
			suffix: suffix? source
			foreach [name codec] system/codecs [
				if find codec/suffixes suffix [
					return do [codec/decode source]
				]
			]
			source: read/binary source
		]
		url!	[
			source: read/info/binary source
			either source/1 = 200 [
				foreach [name codec] system/codecs [
					foreach mime codec/mime-type [
						if find source/2/Content-Type mold mime [
							return do [codec/decode source/3]
						]
					]
				]
			][return none]
			source: source/3
		]
	]
	if pre-load: :system/lexer/pre-load [do [pre-load source length]]

	set/any 'out case [
		part  [transcode/part source length]
		into  [transcode/into source out]
		;trap  [system/lexer/transcode to-string source out trap]
		next  [
			set position second set/any 'out transcode/next source
			return either :all [reduce [out/1]][out/1]
		]
		'else [transcode source]
	]
	either trap [:out][
		unless :all [if 1 = length? :out [set/any 'out out/1]]
		:out
	]
]

save: function [
	"Saves a value, block, or other data to a file, URL, binary, or string"
	where [file! url! string! binary! none!] "Where to save"
	value [any-type!] "Value(s) to save"
	/header "Provide a Red header block (or output non-code datatypes)"
		header-data [block! object!]
	/all    "TBD: Save in serialized format"
	/length "Save the length of the script content in the header"
	/as     "Specify the format of data; use NONE to save as plain text"
		format [word! none!] "E.g. bmp, gif, jpeg, png, redbin, json, csv"
][
	dst: either any [file? where url? where][where][none]
	
	either system/words/all [as word? format] [			;-- Be aware of [all as] word shadowing
		either codec: select system/codecs format [
			data: do [codec/encode :value dst]
			if same? data dst [exit]					;-- if encode returns dst back, means it already save :value to dst
		][cause-error 'script 'invalid-refine-arg [/as format]] ;-- throw error if format is not supported
	][
		if length [header: true header-data: any [header-data copy []]]
		if header [
			if object? :header-data [header-data: body-of header-data]
		]
		if find [file! url!] type?/word where [
			suffix: suffix? where
			find-encoder?: no
			foreach [name codec] system/codecs [
				if (find codec/suffixes suffix) [		;@@ temporary required until dyn-stack implemented
					data: do [codec/encode :value dst]
					if same? data dst [exit]
					find-encoder?: yes
				]
			]
		]
		unless find-encoder? [
			only: block? :value
			data: either all [
				append mold/all/:only :value newline
			][
				mold/:only :value
			]
			case/all [
				not binary? data [data: to binary! data]
				length [
					either pos: find/tail header-data 'length [
						insert remove pos length? data	;@@ change pos length? data
					][
						append header-data compose [length: (length? data)]
					]
				]
				header-data [
					header-str: copy "Red [^/"			;@@ mold header, use new-line instead
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

cause-error: func [
	"Causes an immediate error throw, with the provided information"
	err-type [word!] 
	err-id 	 [word!] 
	args 	 [block! string!] 
][
	args: reduce either block? args [args] [[args]]		;-- Blockify string args
	do make error! [
		type: err-type
		id:   err-id
		arg1: first args
		arg2: second args
		arg3: third args
	]
]

pad: func [
	"Pad a FORMed value on right side with spaces"
	str					"Value to pad, FORM it if not a string"
	n		[integer!]	"Total size (in characters) of the new string"
	/left				"Pad the string on left side"
	/with				"Pad with char"
	c		[char!]
	return:	[string!]	"Modified input string at head"
][
	unless string? str [str: form str]
	insert/dup
		any [all [left str] tail str]
		any [c #" "]
		(n - length? str)
	str													;-- returns the string at original offset
]

mod: func [
	"Compute a nonnegative remainder of A divided by B"
	a		[number! money! char! pair! tuple! vector! time!]
	b		[number! money! char! pair! tuple! vector! time!]	"Must be nonzero"
	return: [number! money! char! pair! tuple! vector! time!]
	/local r
][
	if (r: a % b) < 0 [r: r + b]
	a: absolute a
	either all [a + r = (a + b) r + r - b > 0][r - b][r]
]

modulo: func [
	"Wrapper for MOD that handles errors like REMAINDER. Negligible values (compared to A and B) are rounded to zero"
	a		[number! money! char! pair! tuple! vector! time!]
	b		[number! money! char! pair! tuple! vector! time!]
	return: [number! money! char! pair! tuple! vector! time!]
	/local r
][
	r: mod a absolute b
	either any [a - r = a r + b = b][0][r]
]

eval-set-path: func ["Internal Use Only" value1][]

to-red-file: func [
	"Converts a local system file path to a Red file path"
	path	[file! string!]
	return: [file!]
	/local colon? slash? len i c dst
][
	#either config/OS = 'Windows [
		len: length? path
		dst: make file! len
		if zero? len [return dst]
		i: 1
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
		dst
	][
		to file! path
	]
]

dir?: func ["Returns TRUE if the value looks like a directory spec" file [file! url!]][#"/" = last file]

normalize-dir: function [
	"Returns an absolute directory spec"
	dir [file! word! path!]
][
	unless file? dir [dir: to file! mold dir]
	if slash <> first dir [dir: clean-path append copy system/options/path dir]
	if find dir #"\" [dir: to-red-file dir]
	unless dir? dir [dir: append copy dir slash]
	dir
]

what-dir: func [
	"Returns the active directory path"
	/local path
][
	path: copy system/options/path
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

	at-arg2: none

	#either config/OS = 'Windows [
		;-- logic should mirror that of `split-tokens` in `red.r`

		ws: charset " ^-" 								;-- according to MSDN "Parsing C++ Command-Line Arguments" article
		split-mode: yes
		system/options/boot: take system/options/args: collect [
			arg-end: has [s' e'] [
				unless same? s': s e': e [ 				;-- empty argument check
					;-- remove heading and trailing quotes (if any), even if it results in an empty arg
					if s/1 = #"^"" [s': next s]
					if all [e/-1 = #"^""  not same? e s'] [e': back e]
					keep copy/part s' e'
				]
			]
			arg2-update: [if (at-arg2) | at-arg2:]
			parse s: args [
				some [e:
					#"^"" (split-mode: not split-mode)
				|	if (split-mode) some ws (arg-end) arg2-update s:
				|	skip
				] e: (arg-end) arg2-update
			]
		]
	][
		;-- logic should be an inverse of `get-cmdline-args` as it is constructed there from *argv

		ws: charset " ^-^/^M"
		system/options/boot: take system/options/args: parse args [
			collect some [
				end | (buf: make string! 32) collect into buf any [
					not ws [
						#"'" keep to #"'" skip
					|	"\'" keep (#"'")
					|	keep skip
					]
				]
				[some ws | end]
				s: (at-arg2: any [at-arg2 s])
				keep (buf)
			]
		]
	]
	remove/part args at-arg2 						;-- remove the program name

	system/options/args
]

collect: function [
	"Collect in a new block all the values passed to KEEP function from the body block"
	body [block!]		 "Block to evaluate"
	/into 		  		 "Insert into a buffer instead (returns position after insert)"
		collected [series!] "The buffer series (modified)"
][
	keep: func [v /only][append/:only collected v v]
	
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
	parse series [collect any [end keep (make string! 0) | copy s [to [dlm | end]] keep (s) num skip]]
]

dirize: func [
	"Returns a copy of the path turned into a directory"
	path [file! string! url!]
][
	either #"/" <> pick path length? path [append copy path #"/"] [copy path]
]

clean-path: func [
	[no-trace]
	"Cleans-up '.' and '..' in path; returns the cleaned path"
	file [file! url! string!]
	/only "Do not prepend current directory"
	/dir "Add a trailing / if missing"
	/local out cnt f not-file? prot
][
	not-file?: not file? file
	if url? file [parse file [copy prot to #"/"]]
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
	if only [return file]

	out: make type? file length? file
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
	if prot [append out reverse prot]
	if all [dir? out #"/" <> last file][take/last out]
	reverse out
]

split-path: func [
	[no-trace]
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

do-file: function ["Internal Use Only" file [file! url!] callback [function! none!]][
	ws: charset " ^-^M^/"
	saved: system/options/path
	parse/case read file [some [src: "Red" opt "/System" any ws #"[" (found?: yes) break | skip]]
	unless found? [cause-error 'syntax 'no-header reduce [file]]
	
	code: load/all src									;-- don't expand before we check the header
	if code/1 = 'Red/System [cause-error 'internal 'red-system []]
	header?: all [code/1 = 'Red block? header: code/2]
	code: expand-directives next code					;-- skip the Red[/System] value
	system/script/header: construct/with code/1 system/standard/header	;-- load header metadata
	if file? file [
		new-path: first split-path clean-path file
		change-dir new-path
		append system/state/source-files file
	]
	if all [header? list: select header 'currencies][
		foreach c list [append system/locale/currencies/list c]
	]
	if header? [code: next code]
	if :callback [code: compose/only [do/trace (code) :callback]]
	
	set/any 'code try/all/keep [
		set/any 'code catch/name code 'console
		done?: yes
		either 'halt-request = :code [print "(halted)"][:code]
	]
	if file? file [
		change-dir saved
		take/last system/state/source-files
	]
	if all [error? :code not done?][do :code]			;-- rethrow the error
	:code
]

;clear-cache: function [/only url][
;
;]

path-thru: function [
	"Returns the local disk cache path of a remote file"
	url [url!]		"Remote file address"
	return: [file!]
][
	so: system/options
	unless so/thru-cache [make-dir/deep so/thru-cache: append copy so/cache %cache/]

	hash: checksum form url 'MD5
	file: head (remove back tail remove remove (form hash))
	path: dirize append copy so/thru-cache copy/part file 2
	unless exists? path [make-dir path] 
	append path file
]

exists-thru?: function [
	"Returns true if the remote file is present in the local disk cache"
	url [url! file!] "Remote file address"
][
	exists? any [all [file? url url] path-thru url]
]

read-thru: function [
	"Reads a remote file through local disk cache"
	url [url!]	"Remote file address"
	/update		"Force a cache update"
	/binary		"Use binary mode"
][
	path: path-thru url
	either all [not update exists? path] [
		data: read/:binary path
	][
		data: read/:binary url
		attempt [write/binary path data]
	]
	data
]

load-thru: function [
	"Loads a remote file through local disk cache"
	url [url!]	"Remote file address"
	/update		"Force a cache update"
	/as			"Specify the type of data; use NONE to load as code"
		type [word! none!] "E.g. bmp, gif, jpeg, png"
][
	path: path-thru url
	if all [not update exists? path][url: path]
	file: either as [load/as url type][load url]
	if url? url [attempt [save/:as path file type]]
	file
]

do-thru: function [
	"Evaluates a remote Red script through local disk cache"
	url [url!]	"Remote file address"
	/update		"Force a cache update"
][
	do load-thru/:update url
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
	"Returns the trigonometric arccosine in radians in range [0,pi]"
	cosine [float!] "in range [-1,1]"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/arccosine* no 1
	]
]

asin: func [
	"Returns the trigonometric arcsine in radians in range [-pi/2,pi/2])"
	sine [float!] "in range [-1,1]"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/arcsine* no 1
	]
]

atan: func [
	"Returns the trigonometric arctangent in radians in range [-pi/2,+pi/2]"
	tangent [float!] "in range [-inf,+inf]"
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/arctangent* no 1
	]
]

atan2: func [
	"Returns the smallest angle between the vectors (1,0) and (x,y) in range (-pi,pi]"
	y		[float! integer!]
	x		[float! integer!]
	return:	[float!]
][
	#system [
		stack/arguments: stack/arguments - 2
		natives/arctangent2* no 1
	]
]


sqrt: func [
	"Returns the square root of a number"
	number	[float! integer! percent!]
	return:	[float!]
][
	#system [
		stack/arguments: stack/arguments - 1
		natives/square-root* no
	]
]

to-UTC-date: func [
	"Returns the date with UTC zone"
	date [date!]
	return: [date!]
][
	date/timezone: 0
	date
]

to-local-date: func [
	"Returns the date with local zone"
	date [date!]
	return: [date!]
][
	date/timezone: now/zone
	date
]

show-memory-stats: function [data [block!]][
	repeat class 2 [
		print [lf #"[" pad form pick [Nodes Series] class 6 "] -- Free ----- Used ----- Total --"]
		used: total: 0
		either empty? data/:class [
			repeat i 3 [prin pad/left copy "-" pick [16 11 12] i]
			prin lf
		][
			c: 0
			foreach frm data/:class [
				prin ["  " pad append form c: c + 1 #":" 4]
				repeat i 3 [prin pad/left form frm/:i pick [11 11 12] i]
				prin lf
				used: used + frm/2
				total: total + frm/3
			]
		]
		unit: pick ["nodes" "bytes"] class
		print ["  --^/  Used     : " used  unit]
		print ["  Allocated: " total unit]
	]
	c: total: 0
	print "^/[ Big    ]"
	unless empty? data/3 [
		foreach frm data/3 [
			prin ["  " pad append form c: c + 1 #":" 4]
			print pad/left frm 11
			total: total + frm
		]
	]
	print [
		"  --^/  Allocated: " total  "bytes^/"
		"--^/Total allocated from OS:" pad/left form data/4 9 lf
		"Total allocated on heap:" pad/left form data/5 9 lf
	]
]

transcode-trace: func [
	"Shortcut function for transcoding while tracing all lexer events"
	src [binary! string!]
][
	transcode/trace src :system/lexer/tracer
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

sum: func [
	"Returns the sum of all values in a block"
	values [block! vector! paren! hash!]
	/local result value
][
	result: make any [values/1 0] 0
	foreach value values [result: result + value]
	result
]

average: func [
	"Returns the average of all values in a block"
	block [block! vector! paren! hash!]
][
	if empty? block [return none]
	divide sum block length? block
]

last?: func [
	"Returns TRUE if the series length is 1"
	series [series!]
] [
	1 = length? series
]

dt: function [
	"Returns the time required to evaluate a block"
	body	[block!]
	return: [time!]
][
	t0: now/precise/utc
	do body
	difference now/precise/utc t0
]

time-it: :dt

clock: function [
	"Display execution time of code, returning result of it's evaluation"
	code [block!]
	/times n [integer! float!]							;-- float is useful for eg. `1e6` instead of `1'000'000`
		"Repeat N times (default: once); displayed time is per iteration"
	/local result
][
	n:    max 1 any [n 1]
	text: mold/flat/part code 70						;-- mold the code before it mutates
	dt:   time-it [set/any 'result loop n code]
	dt:   1e3 / n * to float! dt						;-- ms per iteration
	unit: either dt < 1 [dt: dt * 1e3 "μs^-"]["ms^-"]
	parse form dt [										;-- save 3 significant digits max
		0 3 [opt #"." skip] opt [to #"."] dt: (dt: head clear dt)
	]
	print [dt unit text]
	:result
]

;------------------------------------------
;-				Aliases					  -
;------------------------------------------

single?:	:last?
keys-of:	:words-of
object:		:context
halt:		:quit										;-- default behavior unless console is loaded
