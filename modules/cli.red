Red [
	Title:		"Simple & powerful command line argument validation system"
	Author: 	@hiiamboris
	Version:	22/12/2021
	Tabs:		4
	Rights:		"Copyright (C) 2021 Red Foundation. All rights reserved."
	Homepage:	https://gitlab.com/hiiamboris/red-cli
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Bugs: {
		- Red supports system/script/header but only in a very limited fashion,
		  so you may have to explicitly set header fields after all #includes
		- When compiled, words lose their case info, so
		  if program name is generated from a word, it will always be in lower case
	}
	Usage: {
		my-program: function [operands .. /switches /options arguments] [code]
		cli/process-into my-program
	}
]


cli: context [
	comment {
		References:
		[1] "Program Argument Syntax Conventions"
			https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html
		[2] "POSIX Utility Syntax Guidelines"
			https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02
		[3] "Portable character set"
			https://en.wikipedia.org/wiki/Portable_character_set
		[4] "Learning the Bash. Special Characters and Quoting"
			https://www.oreilly.com/library/view/learning-the-bash/1565923472/ch01s09.html
	}

	;-- ERROR CODES refer to themselves, in case one wants to print them
	ER_FEW:    'ER_FEW			;-- not enough operands
	ER_MUCH:   'ER_MUCH			;-- too many operands
	ER_LOAD:   'ER_LOAD			;-- provided value is invalid
	ER_TYPE:   'ER_TYPE			;-- provided valus is of wrong type
	ER_EMPTY:  'ER_EMPTY		;-- no value provided
	ER_VAL:    'ER_VAL			;-- value provided where no value expected
	ER_CMD:    'ER_CMD			;-- unknown command (during dispatching)
	ER_OPT:    'ER_OPT			;-- unknown option
	ER_FORMAT: 'ER_FORMAT		;-- unknown option format
	ER_CHAR:   'ER_CHAR			;-- unsupported char in option name

	;-- supported argument FORMAT TYPES
	loadable-set: make typeset! [integer! float! percent! logic! url! email! tag! issue! time! date! pair!]
	supported-set: union loadable-set make typeset! [string! file! block!]


	;-- used to signal an error in supplied command line
	complain: func [about [block!]] [
		;@@ TODO: print to stderr instead (not supported by Red yet)
		#assert [word? first about]
		throw/name reduce about 'complaint
	]

	else: make op! func [truth e [string!]] [unless truth [do make error! e]]


	option?: func [
		"Check if ARG is an option name"
		arg			[string!]
		/options				"(placeholder for future expansion)"
			opts	[block! map! none!]
	][
		all [
			#"-" = first arg	;-- [1] Arguments are options if they begin with a hyphen delimiter (‘-’)
			arg <> "-"			;-- [1] A token consisting of a single hyphen character is interpreted as an ordinary non-option argument
			arg <> "--"			;-- [1] The argument ‘--’ terminates all options
		]
	]
	

	;; ████████████  SPEC ANALYSIS  ████████████

	str-to-ref: func [
		{Convert "string" into /refinement}
		s [string!]
	][
		if any [
			error? try [s: load s]						;-- unloadable?
			not word? :s								;-- unsupported spelling?
			; all [not integer? s not word? s]			;@@ TODO: integer options?
		][
			complain [ER_OPT "Unsupported option:" :s]	;-- using get-word for security (one day `load` may support serialized funcs)
		]
		; if integer? s [s: to word! rejoin ["_" s]]
		#assert [word? s]
		to refinement! s
	]

	find-refinement: function [
		"Return internal SPEC at block containing /ref, or none if not found"
		spec [block!]
		ref [refinement!]
	][
		until [
			names: first spec
			if all [block? names  find names ref][return spec]
			empty? spec: skip spec 3
		]
		none
	]


	default: func [:w [set-word!] v] [any [get/any :w  set :w v]]

	;-- internal spec format is a block of triplets:
	;; [      name-word          "docstring"  typeset! ]  for operands and option arguments
	;; [ [ /option /alias ... ]  "docstring"  none     ]  for --options themselves
	SPEC-PERIOD:    3
	SPEC-TYPESET:   3
	SPEC-DOCSTRING: 2
	SPEC-NAMES:     1

	prep-spec: function [
		"Converts a function SPEC into internal format used for easier argument processing"
		spec [block! function!]
		/local name target
	][
		if function? :spec [spec: spec-of :spec]
		=arg=: [									;-- operand / argument (word)
			set name      word!
			set types opt block!  (default types: [string!])
			set doc   opt string! (default doc: copy "")
			(
				(not force-nullary?) else {alias refinements cannot have arguments}
				if types = [block!] [append types 'string!]
				repend r [name  doc  make typeset! types]
			)
		]
		=local=: [/local to [refinement! | end]]	;-- skip /locals (/externs are never present in the spec)
		=ref=: [									;-- option (refinement)
			set name    refinement!
			set doc opt string!     (default doc: copy "")
			(										;-- check the docstring for an alias definition
				either force-nullary?: target: find/match/tail doc "alias "	;-- alias? allow no arguments to it
					[ repend aliases [name target] ]
					[ repend r [to block! name  doc  none] ]
			)
		]
		=fail=: [end | p: (do make error! rejoin ["Unsupported token " mold p/1 " in CLI function spec"])]
		force-nullary?: no  aliases: copy []  r: copy []
		parse spec [any string! any [=arg= | =local= | =ref= | =fail=]]
		r: new-line/skip r yes SPEC-PERIOD
		foreach [alias target] aliases [
			(all [
				attempt [target: load target]
				find [word! refinement!] type?/word :target		;-- using get-word for security (one day `load` may support serialized funcs)
			]) else rejoin ["Target "target" must be a word or refinement"]
			pos: find-refinement r to refinement! target
			pos else rejoin ["Target "target" of alias "alias" is not defined"]
			append pos/1 alias
		]
		r
	]

	supported?: function [
		"Check if option R is supported by F"
		f [function!] r [string!]
	][
		not none? find-refinement prep-spec :f str-to-ref r
	]

	unary?: function [
		"Check if option R is unary in F's spec"
		f [function!] r [string!]
	][
		r: str-to-ref r
		spec: find-refinement prep-spec :f r
		all [
			word?     pick spec     SPEC-PERIOD + SPEC-NAMES
			not word? pick spec 2 * SPEC-PERIOD + SPEC-NAMES
		]
	]

	check-value: function [
		"Typecheck value V against a set of TYPES"
		v			[string!]
		types		[typeset! block!]
		/options				"(placeholder for future expansion)"
			opts	[block! map! none!]
	][
		if block? types [types: make typeset! types]
		#assert [not empty? to block! types]

		unsupp: to block! exclude types supported-set
		(empty? unsupp) else form reduce ["Unsupported types in" types "typeset:" unsupp]
		
		loadable: intersect types loadable-set
		case/all [
			loadable <> make typeset! [] [				;-- contains a loadable type?
				set/any 'x try [load v]
			]
			all [										;-- try type conversion
				not error? :x								;-- loaded at all?
				not block? :x								;-- single value?
				any [
					find loadable type? :x					;-- accepted?
					any [									;-- automatic promotion when required
						all [									;-- integer to float
							integer? :x
							find loadable float!
							x: 1.0 * x
						]
						all [									;-- word to logic
							word? :x
							find loadable logic!
							logic? x: get x
						]
					]
				]
			][return x]

			find types file! [return to-red-file v]		;-- try fallbacks: file or string is accepted?
			find types string! [return v]

			error? :x [									;-- load has failed and fallbacks are not applicable
				complain [ER_LOAD "Invalid value format:" v]
			]
		]
														;-- loaded but didn't pass the type check...
		types: to block! exclude types make typeset! [block!]
		a-an: either find "aeiou" first form types/1 ["an"] ["a"]	;-- `a-an` undefined outside of console
		complain compose [								;-- tell which types are accepted
			ER_TYPE
			v "should be" (pick [
				[ a-an types/1 "value"]
				["one of these types:" mold types]
			] last? types)
		]
	]


	;; ████████████  /OPTIONS BLOCK SUPPORT  ████████████

	;@@ TODO: rework this when we get `apply`
	;-- NOTE: refinements and their argument names should be consistent across all CLI funcs to work properly
	;--       otherwise one option will do different things in different funcs that use `sync-arguments`


	arguments-from-block: function [
		"Turn a block (e.g. [args: args]) into an arguments map (e.g. #(arg-blk: [args block]))"
		block [block!] "Non-setwords get reduced and refinements mapped to their respective arguments"
		spec  [block!]
	][
		map: make map! block
		foreach [k v] map [
			if all [
				refinement? first pos: find spec k		;-- if value is assigned to a refinement
				pos: find next pos all-word!			;-- reassign it to it's argument instead
				any-word? first pos
			][
				map/:k: true
				k: to word! pos/1
			]
			map/:k: either any-word? :v [get :v][:v]	;-- reduce words
		]
		map
	]

	sync-arguments: function [
		"Populate OPTS with arguments provided to the function, then back"
		'opts [word!] "A map, block or none"
	][
		spec: spec-of fun: context? opts
		case [
			none? map: get opts [map: copy #()]
			block? map [map: arguments-from-block map spec]	;-- block interpretation is smarter for convenience
		]
		#assert [map? :map]
		set opts map
		parse/case spec [any [
			/local to end
		|	not all-word! skip
		|	set ref opt refinement! set name opt any-word! (
				if name [			;-- get name from arguments, then from map, otherwise set to none
					name: bind to word! name :fun
					set/any 'map/:name
						set/any name
							any [get/any name  :map/:name]
				]
				if ref [			;-- same here but also set to 'true' if name is provided
					ref: bind to word! ref  :fun
					set 'map/:ref
						set ref
							to logic! any [get/any ref  :map/:ref  all [name get/any name]]
				]
			)
		]]
		map
	]

	;; ████████████  INTERNAL CALL BUILDUP  ████████████

	comment {
		Internal call format is used so:
		- we can distinguish between parts of function path and already added refinements
		- we are able to locate every refinement's block of arguments, to add to it

		Format is:
		[
			object/func								-- word or path to function
			[mandatory args ...]					-- block of found operands values, should not contain blocks
			[/ref1 /ref2 [] /ref3 [args] /ref4...]	-- block with so far found options and their arguments
		]
	}
	
	CALL-PATH: 1
	CALL-ARGS: 2
	CALL-REFS: 3

	add-refinements: function [
		"Append to internal CALL block option NAME=VALUE as refinement with all it's aliases"
		call [block!]
		prog [function!]
		name [string!]
		value [string! none!]	;-- none allowed if argument is nullary
		/options				"(placeholder for future expansion)"
			opts	[block! map! none!]
	][
		ref: str-to-ref name
		spec: find-refinement prep-spec :prog ref
		refs: first spec
		#assert [not empty? refs]
		
		either pos: find/tail call/:CALL-REFS ref [		;-- are refinements already added?
			pos: find pos block!							;-- jump to values
		][												;-- otherwise
			append call/:CALL-REFS refs						;-- list all aliases
			pos: tail call/:CALL-REFS
			append/only call/:CALL-REFS copy []				;-- create a block to hold values
		]
		#assert [(unary? :prog name) <> (none? value)]	;-- match provided arity with expected one

		if unary? :prog name [							;-- check & add the value
			types: pick spec SPEC-PERIOD + SPEC-TYPESET		;-- 3rd is none, 6th is argument's typeset
			value: check-value/options value types opts
			append pos/1 value
		]
		call
	]


	add-operand: function [
		"Append an operand's VALUE to the internal CALL block"
		call		[block!]
		prog		[function!]
		value		[string!]
		/options				"(placeholder for future expansion)"
			opts	[block! map! none!]
	][
		arity: preprocessor/func-arity? spec-of :prog
		n-args: min arity length? call/:CALL-ARGS
		spec: skip prep-spec :prog (n-args * SPEC-PERIOD)
														;-- find the accepted types
		if not word? first spec [						;-- past the arguments already
			if head? spec [									;-- no operands expected at all?
				complain [ER_MUCH "Extra operands given"]	;-- then there's no type to check against
			]
			spec: skip spec negate SPEC-PERIOD				;-- use the last argument's typeset
		]
		#assert [word? first spec]
		#assert [typeset? third spec]
		value: check-value/options value third spec opts
		append call/:CALL-ARGS value
		call
	]

	prep-call: function [
		"Convert internal CALL block into a PROGRAM Red function call"
		call		[block!]
		program		[function!]
		/options				"(placeholder for future expansion)"
			opts	[block! map! none!]
		/local ref
	][
		spec: prep-spec :program
		r: reduce [call/:CALL-PATH]
														;-- add mandatory arguments
		foreach arg call/:CALL-ARGS [
			either word? spec/:SPEC-NAMES [					;-- pass single argument normally
				#assert [typeset? spec/:SPEC-TYPESET]
				if find spec/:SPEC-TYPESET block! [arg: reduce [arg]]
				append/only r arg
				spec: skip spec SPEC-PERIOD
			][												;-- collect all other arguments into the last block
				unless block? last r [complain [ER_MUCH "Extra operands given"]]
				#assert [block? last r]
				append last r arg
			]
		]

		if find spec/:SPEC-TYPESET block! [append/only r []]	;-- if block is accepted, provide an empty one in absence of arguments

		arity: preprocessor/func-arity? spec-of :program
		need-more: 1 + arity - length? r
		if need-more > 0 [
			present-options: collect [parse call/3 [	;-- find out if a shortcut option is present
				any [set ref refinement! (keep to word! ref) | skip]	;@@ should be `keep-type` here
			]]
			present-shortcuts: intersect present-options opts/s-cuts
			either empty? present-shortcuts [			;-- no shortcuts: fail
				complain [ER_FEW "Not enough operands given"]
			][											;-- shortcut found: provide defaults
				repeat i need-more [
					spec: find/skip spec word! SPEC-PERIOD
					type: first reduce to [] spec/:SPEC-TYPESET		;@@ how else to get a type from typeset?
					append/only r any [					;-- create an argument out of thin air to finish the call
						attempt [make type 0]			;-- for most types
						attempt [make type ""]			;-- for issues
						attempt [make type []]			;-- for dates
					]
					spec: skip spec 3
				] 
			]
		]

		spec: head spec
		unless empty? call/:CALL-REFS [					;-- add options as refinements
			if word? r/1 [ change/only r make path! reduce [r/1] ]	;-- convert word to path
			types: none
			foreach x call/:CALL-REFS [					;-- call/3 is refinements block
				either refinement? x [					;-- /ref
					append r/1 to word! x					;-- add ref to path
					types: pick find-refinement spec x
						SPEC-PERIOD + SPEC-TYPESET			;-- 3rd is none, 6th is argument's typeset (or none if no argument)
				][										;-- [values...]
					if typeset? types [						;-- none if refinement is nullary
						either find types block! [
							append/only r x					;-- add as block of collected values
						][
							#assert [not empty? x]
							append r last x					;-- last value replaces prior ones
						]
						types: none
					]
				]
			]
		]
		r
	]


	;; ████████████  ARGUMENTS PARSER  ████████████


	default-exename: function ["Returns the executable/script name without path"] [
		do [											;@@ DO for compiler
			basename?: func [x] [							;-- filename from path w/o extension
				also x: last split-path to-red-file x
					clear find/last x #"."
			]
			any [
				attempt [basename? system/options/script]	;-- when run as `red script.red`
				attempt [basename? system/options/boot]		;-- when run as a compiled exe (options/script = none)
			]
		]
	]


	extract-args: function [
		"Convert CLI args into a block of [name value] according to PROGRAM's spec (name = none for operands)"
		args		[block!]		"block of arguments to process"
		'program	[word! path!]	"function which spec defines the acceptable set of arguments"
		/no-version					"Suppress automatic creation of --version argument"
		/no-help					"Suppress automatic creation of --help and -h arguments"
		/options					"Specify all the above options as a block"
			opts	[block! map! none!]
		/local arg-name
	][
		;-- [1]: Long options consist of ‘--’ followed by a name made of ALPHANUMERIC characters and DASHES
		;-- [2]: Each option name should be a single ALPHANUMERIC character from the PORTABLE character set
		; =optchar=: charset [#"a" - #"z"  #"A" - #"Z"  #"0" - #"9"  "-"]

		;-- relaxed charset on par with Red words
		=optchar=: charset [
			not
			{/\^^,[](){}"#%$@:;}						;-- non-word chars
			" "											;-- whitespace
			#"^(00)" - #"^(1F)"							;-- C0 control codes
			#"^(80)" - #"^(9F)"							;-- C1 control codes
			"="											;-- option/argument delimiter
			"&`'|?*~!<>"								;-- special chars in shell
		]

		is-help-version?: [								;-- use default -h / --version when allowed
			case [
				find ["h" "help"] arg-name [
					unless no-help [arg-name: "help"]	;-- expand -h into --help
				]
				arg-name = "version" [not no-version]
			]
			;; returns none when doesn't handle the argument
		]

		allow-options?: yes								;-- will be switched off by `--`
		r: make block! 20
		forall args [
			arg: :args/1
			unless string? :arg [arg: form :arg]		;-- should never happen?

			got-operand?: any [not allow-options?  not option?/options arg opts]
			default?: no
			either got-operand? [
				;; "-" and "--" go here, since `option?` is false for them
				either all [arg == "--" allow-options?]	;-- subsequent "--"s are operands
					[ allow-options?: no ]				;-- no options after "--"
					[ repend r [none arg] ]
			][
				;-- possible scenarios:
				;; -opqrs (multiple options, not supported by default)
				;; -ofile (not supported by default)
				;; -o file
				;; -o file1 file2 (multi-arg, not supported by default)
				;; -o[file] (optional argument, not supported by default)
				;; /o:file (not supported by default)
				;; /o file (not supported by default)
				;; /o file1 file2 (multi-arg, not supported by default)
				;; -out=file (not supported by default)
				;; -out file (not supported by default)
				;; -out file1 file2 (multi-arg, not supported by default)
				;; --out=file
				;; --out file
				;; --out file1 file2 (multi-arg, not supported by default)
				parse arg [
					[													;-- long or short option?
						"--" copy arg-name [=optchar= some =optchar=]		;-- require 2+ optchars for long names
						(dlms: ["=" | some [#" " | #"^-"] | end])				;-- "=" is allowed to delimit a long option
					|	"-"
						copy arg-name =optchar=
						(dlms: [      some [#" " | #"^-"] | end])				;-- no "=" allowed
						ahead dlms											;-- forbid multiple chars after a single hyphen
					]
					(unless supported? get/any program arg-name [		;-- check the option name
						any [
							default?: do is-help-version?					;-- try default arguments too
							complain [ER_OPT "Unsupported option:" arg]
						]
					])
					[	if (all [
							not default?								;-- disable unary clause for internal help/version
							unary? get/any program arg-name				;-- read the value (if required)
						])
						[	dlms											;-- require a delimiter
						|	pos: (complain [ER_CHAR "Unsupported option character at" pos])
						]
						[	end (											;-- consume the next argument when needed
								args: next args
								if empty? args [complain [ER_EMPTY arg "needs a value"]]
								arg: :args/1
								unless string? :arg [arg: form :arg]		;-- should never happen?
								arg-value: copy arg
							)
						|	copy arg-value [to end]							;-- consume the rest of the same argument
						]
					|													;-- nullary refinement - should end right here
						[ end | (complain [ER_VAL "Option" arg "does not accept a value"]) ]
						(arg-value: none)
					]

					(repend r [arg-name arg-value])

				|	(complain [ER_FORMAT "Unsupported option format:" arg])
				];; parse arg
			];; else: either not all [allow-options?  option?/options arg opts]
		];; forall args
		r
	];; extract-args: function


	;; ████████████  DEFAULT FORMATTERS  ████████████

	dehyphenize: func [x] [replace/all form x #"-" #" "]

	version-for: function [
		"Returns version text for the PROGRAM"
		'program	[word! path!] "May refer to a function or context"
		/name					"Overrides program name"
			pname	[string!]
		/version				"Overrides version"
			ver		[tuple! string!]
		/brief					"Include only the essential info"
		/options				"Specify all the above options as a block"
			opts	[block! map! none!]
	][
		sync-arguments opts

		r: make string! 100

		standalone?: none? system/options/script		;@@ is there a better way to check?

		pname: form any [
			pname										;-- when explicitly provided
			attempt [system/script/title]
			attempt [system/script/header/title]
			attempt [dehyphenize first program]			;-- first item in the path: program/command/...
			dehyphenize program							;-- the word itself
			;-- reminder: do not use exe name as program name (it can be renamed easily by the user)
		]

		ver: form any [
			ver											;-- explicitly provided
			attempt [system/script/header/version]		;-- from the header
			attempt [first query system/options/script]	;-- script modification date if interpreted
			#do keep [now/date]							;-- compilation date otherwise
		]

		desc: all [
			function? get/any program
			s: first spec-of get/any program
			string? s
			trim s
		]

		author:  attempt [system/script/header/author]	;@@ TODO: join multiple authors with comma or ampersand?
		rights:  attempt [trim system/script/header/rights]
		license: attempt [trim system/script/header/license]

		append r form compose [
			(pname) (ver)								;-- "Program 1.2.3"
			(any [desc ()])								;-- "long description ..."
			(either author [rejoin ["by "author]][()])	;-- "by Yours Truly"
			#"^/"
		]
		if rights  [repend r [rights #"^/"]]			;-- "(C) Copyrights..."

		unless brief [									;-- add detailed info
			commit: attempt [mold/part system/build/git/commit 8]
			#assert [system/version]
			#assert [system/platform]
			repend r [									;-- Red version
				pick ["Built with" "Using"] standalone?
				" Red " system/version
				either commit [ rejoin [" (" commit ")"] ][ "" ]
				" for " system/platform
				#"^/"
			]
			if standalone? [repend r ["Build timestamp: " #do keep [now]]]

			if license [repend r [license #"^/"]]		;-- "License text..."
		]

		r
	]

	decorate-operand: func [name types] [				;-- x -> "<x>" or "[x]"
		mold/flat to either find types block! [block!][tag!] name
	]
			
	synopsis-for: function [
		"Returns short synopsis line for the PROGRAM"
		'program	[word! path!] "Must refer to a function"
		/exename				"Overrides executable name"
			xname	[string!]
		/options				"Specify all the above options as a block"
			opts	[block! map! none!]
	][
		sync-arguments opts
		
		(function? get/any program) else rejoin [""program" must refer to a function"]
		spec: prep-spec get/any program
		
		r: make string! 80
		xname: form default xname: default-exename
		append r xname
		if path? program [append r rejoin [" " as [] next program]]	;-- list currently applied commands
		
		options?: any [not opts/no-help  not opts/no-version  find spec none]
		if options? [append r " [options]"]
		
		foreach [name doc types] spec [					;-- list operands:
			if none? types [break]							;-- stop right after the last operand
			repend r [" " decorate-operand name types]		;-- append every operand as "<name>"
		]
		append r "^/"
	]
	
	syntax-for: function [
		"Returns usage text for the PROGRAM"
		'program	[word! path!] "May refer to a function or context"
		/no-version				"Suppress automatic creation of --version argument"
		/no-help				"Suppress automatic creation of --help and -h arguments"
		/columns				"Specify widths of columns: indent, short option, long option, argument, description"
			cols	[block!]
		/exename				"Overrides executable name"
			xname	[string!]
		/post-scriptum			"Add custom explanation after the syntax"
			pstext	[string!]
		/options				"Specify all the above options as a block"
			opts	[block! map! none!]
	][
		sync-arguments opts
		
		r: make string! 500

		;; given context, just list possible commands
		if object? get/any program [
			list-commands: func [program [word! path!]] [
				foreach word words-of get program [
					path: append to path! program word
					either object? get/any path [
						list-commands path
					][
						repend r ["  " synopsis-for/options (path) opts]
					]
				]
			]
			append r "^/Supported commands:^/"
			list-commands program
			return append r "^/"
		]
		
		spec: prep-spec get/any program
		unless any [no-version  find-refinement spec /version] [
			repend spec [ [/version] "Display program version and exit" none ]
		]
		unless any [no-help     find-refinement spec /help] [
			repend spec [ [/h /help] "Display this help text and exit"  none ]
		]

		repend r ["^/Syntax: " synopsis-for/options (program) opts "^/"]

		;-- OPERANDS & OPTIONS

		;-- "  -o, --long-option  <argument>    Docstring..."
		;;   0 2   6   10   15   20    26  30  34
		;; default paddings:
		;; options: 2 on the left, 20 total
		;; argument: 1 on the left, 14 total
		;; docstring: 1 on the left
		cols: any [cols [2 4 14 14 44]]
		unless all [
			5 = length? cols
			integer? attempt [sum cols]					;-- block of integers only?
		][ cause-error 'script 'expect-val ['five-integers cols] ]
		if cols/5 <= 0 [cols/5: 1'000'000]

		committed?: yes
		header?: no
		commit: [										;-- commits current s-arg, s-opts, s-doc into `r`, forming a column ;@@ as a block for compiler
			unless header? [append r "Options:^/"  header?: yes]

			pad  append cols1-4: s-opts #" "  sum copy/part cols 3
			pad  repend cols1-4 [s-arg #" "]  sum copy/part cols 4
			s-doc: split s-doc #"^/"					;-- split into lines (if any)
			forall s-doc [
				trim/tail s-doc/1
				while [cols/5 < length? s-doc/1] [		;-- split by column width parts
					s-doc: insert  s-doc  take/part s-doc/1 any [
						; find/part/last/tail s-doc/1 #" " cols/5		;@@ find is buggy - #4204
						attempt [-1 + index? find/last/tail copy/part s-doc/1 cols/5 #" "]
						cols/5
					]
				]
			]
			foreach ln s-doc [							;-- output all lines
				repend r [cols1-4 ln #"^/"]
				replace/all cols1-4 [skip] #" "
			]
			committed?: yes
		]

		foreach [names doc types] spec [
			#assert [string? doc]
			either none? types [						;-- options
				#assert [not empty? names]

				unless committed? [do commit]

				short: copy ""  long: copy ""
				foreach name names [					;-- form short & long options strings
					either single? form to word! name 
						[ repend short ["-" name ", "] ]
						[ repend long ["--" name ", "] ]
				]
				if empty? take/last/part long 2 [
					take/last/part short 2				;-- leave comma after short part if long one isn't empty
				]

				s-opts: pad copy "" cols/1
				repend s-opts [pad short cols/2  long]

				s-arg: copy ""
				s-doc: copy doc
				committed?: no
			][											;-- operands or option arguments
				#assert [word? names]
				either committed? [						;-- an operand?
					if empty? doc [continue]				;-- skip operands without description
					s-opts: copy ""							;-- leave "--flag" column empty
					s-arg: decorate-operand names types		;-- "<name>" or "[name]"
				][										;-- an option then ("--flag" part was filled above)
					s-arg: decorate-operand names none		;-- always as "<name>"
				]
				s-doc: case [							;-- combine `doc` with that of `--option` (if any)
					committed? [copy doc]					;-- "      <arg> Arg description"
					empty? doc [s-doc]						;-- "--opt <arg> Opt description"
					empty? s-doc [copy doc]					;-- "--opt <arg> Arg description"
					'else [ rejoin [s-doc "; " doc] ]		;-- "--opt <arg> Opt description; Arg description"
				]
				do commit
			]
		]
		unless committed? [do commit]
		append r "^/"
		if pstext [append r pstext]
		r
	];; syntax-for: function


	help-for: function [
		"Returns help text (version and syntax) for the PROGRAM"
		'program	[word! path!] "May refer to a function or context"
		/no-version				"Suppress automatic creation of --version argument"
		/no-help				"Suppress automatic creation of --help and -h arguments"
		/name					"Overrides program name"
			pname	[string!]
		/exename				"Overrides executable name"
			xname	[string!]
		/version				"Overrides version"
			ver		[tuple! string!]					;@@ TODO: add float? for 1.0 etc
		/post-scriptum			"Add custom explanation after the syntax"
			pstext	[string!]
		/columns				"Specify widths of columns: indent, short option, long option, argument, description"
			cols	[block!]
		/options				"Specify all the above options as a block"
			opts	[block! map! none!]
	][
		sync-arguments opts
		rejoin [
			version-for/brief/options (program) opts
			syntax-for/options (program) opts
		]
	]


	;; when program does not support --help or --version but they are allowed
	;; this handler is fired instead of the program
	handle-special-arg: function [
		"Default special option handler"
		program [word! path!]
		name [string!] "help or version"
		/options opts [block! map! none!]
	][
		switch name [
			"help"    [print help-for/options    (program) opts]
			"version" [print version-for/options (program) opts]
		]
	]

	;; ████████████  MAIN INTEFACE TO CLI ;)  ████████████


	process-into: function [
		"Calls PROGRAM with arguments read from the command line. Passes through the returned value"
		;; can't support `function!` here cause can't add refinements to a function! literal
		'program	[word! path!] "Name of a function, or of a context with functions to dispatch against"
		/no-version				"Suppress automatic creation of --version argument"
		/no-help				"Suppress automatic creation of --help and -h arguments"
		/name					"Overrides program name"
			pname	[string!]
		/exename				"Overrides executable name"
			xname	[string!]
		/version				"Overrides version"
			ver		[tuple! string!]
		/post-scriptum			"Add custom explanation after the syntax in help output"
			pstext	[string!]
		/args					"Overrides system/options/args"
			arg-blk	[block!]
		/on-error				"Custom error handler: func [error [block!]] [...]"
			handler [function!]
			;-- handler should accept a block: [error-code reduced values that constitute the error message]
			;;  error-codes are words: ER_FEW ER_MUCH ER_LOAD ER_TYPE ER_OPT ER_CHAR ER_EMPTY ER_VAL ER_FORMAT
			;;  value returned by handler on error is passed through by process-into
		/shortcuts				"Options (as words) that allow operands to be absent; default: [help h version]"
			s-cuts	[block!]
		/options				"Specify all the above options as a block"
			opts	[block! map! none!]
		/local opt val r ok?
	][
		err: catch/name [								;-- catch processing errors only
			sync-arguments opts											;-- syncs /options with function arguments
			s-cuts: opts/s-cuts: any [									;-- init default shortcuts
				s-cuts
				compose [(pick [[] [help h]] no-help) (pick [[] [version]] no-version)]
			]
			arg-blk: opts/arg-blk: any [arg-blk system/options/args]	;-- args priority: (1) `args` (2) `options/args` (3) `system/options/args`

			while [object? get/any program] [ 							;-- dispatch objects further
				words: words-of get program
				if all [											;-- unsupported command?
					not empty? arg-blk
					word? word: attempt [load :arg-blk/1]
					find words word
				][
					append program: to path! program word
					arg-blk: next arg-blk
					continue
				]
				if any [
					empty? arg-blk
					all [
						not no-help 
						any [
							find arg-blk "--help"
							find arg-blk "-h"
						]
					]
				][
					print help-for/options (program) opts
					throw/name ok?: yes 'complaint
				]
				if all [not no-version  find arg-blk "--version"] [
					print version-for/options (program) opts
					throw/name ok?: yes 'complaint
				]
				complain [ER_CMD "Unknown command:" form word]
			]
			(function? get/any program) else rejoin [
				""program" must refer to a function, not " type? get/any program
			]

			call: compose/deep [ (program) [] [] ]						;-- where to collect processed args: [path operands options]
			arg-blk: extract-args/options arg-blk (program) opts		;-- turn command line into a block of known format
			foreach [name value] arg-blk [								;-- add options and operands to the `call`
				either name [											;-- name = none if operand, string if option
					unless supported? get/any program name [				;-- help & version special cases
						handle-special-arg/options program name opts
						;; exits as if called the program so it can continue and can control the quit value:
						throw/name ok?: yes 'complaint
					]
					add-refinements/options call get/any program name value opts
				][
					add-operand/options     call get/any program value opts
				]
			]
			call: prep-call/options call get/any program opts			;-- turn `call` block into an actual function call
			set/any 'r do call											;-- call the function
			ok?: yes													;@@ can't `return :r` here, compiler bug #4202
		] 'complaint
		if ok? [return :r]								;-- normal execution ends here
														;-- otherwise, there was a processing error!
		if :handler [return do [handler err]]			;-- pass handler's return through, if any ;@@ DO for compiler
														;-- if no handler, display the error (err = [code message])
		print next err									;@@ TODO: output to stderr (not yet in Red)
		quit/return 1									;-- nonzero code signals failure to scripts running this program
	]


];; cli: context

