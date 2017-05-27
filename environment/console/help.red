Red [
	Title:   "Red help functions"
	Author:  ["Gregg Irwin" "Oldes"]
	File: 	 %help.red
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2017 All Mankind. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Notes: {
		TBD: Emit to output buffer so help can be returned as a string.
		TBD: Determine what useful funcs to export from help-ctx.
	}
]

help-ctx: context [
	DOC_SEP: copy "=>"		; String separating value from doc string
	DEF_SEP: copy ""		; String separating value from definition string
	NO_DOC:  copy "" 		; What to show if there's no doc string "(undocumented)"
	HELP_ARG_COL_SIZE: 12	; Minimum size of the function arg output column
	HELP_TYPE_COL_SIZE: 12	; Minimum size of the datatype output column. 12 = "refinement!" + 1
	HELP_COL_1_SIZE: 15		; Minimum size of the first output column
	RT_MARGIN: 16			; How close we can get to the right console margin before we trim
	DENT_1: "    "			; So CLI and GUI consoles are consistent, WRT tab size
	DENT_2: "        " 
	
	;---------------------------------------------------------------------------
	;-- Buffered output
	
	output-buffer: clear ""	; Where help-string output goes

	_print: func [value][
		_prin value
		append output-buffer newline
	]
	_prin: func [value][
		append output-buffer case [
			string? :value [value]
			block?  :value [form reduce value]
			char?   :value [form value]
			'else [mold :value]
		]
	]
	
	;---------------------------------------------------------------------------

	; A few of these helper funcs are exported from the context, though may
	; be better housed in a string formatting module at a later date.
	
	;!! This is a very simple function, and not always grammatically correct.
	;   A more correct function would base the result on the vowel or consonant
	;   *sound*, rather than the actual letter.
	set 'a-an function [
		"Returns the appropriate variant of a or an (simple, vs 100% grammatically correct)"
		str [string!]
		/pre "Prepend to str"
	][
		tmp: either find "aeiou" str/1 ["an"] ["a"]
		either pre [rejoin [tmp #" " str]][tmp]
	]

	as-arg-col: func ["Format value as argument column output" value][
		pad form :value HELP_ARG_COL_SIZE
	]

	as-col-1: func ["Format value as first column output" value][
		pad form :value HELP_COL_1_SIZE
	]

	as-type-col: func ["Format value as type column output" value [any-type!]][
		pad mold type? :value HELP_TYPE_COL_SIZE
	]

	set 'ellipsize-at func [
		"Truncate and add ellipsis if str is longer than len"
		str [string!] "(modified)"
		len [integer!] "Max length"
	][
		if (length? str) > len [
			append clear at str (len - 3) "..."
		]
		str
	]
	
	; This can no longer be determined statically. If we pad and align object
	; words, they are no longer limited to HELP_COL_1_SIZE.
	; The `max` check is there because the CLI console size is 0 on startup.
	; It keeps the width from going negative if someone launches the CLI with
	; a `help` call in their script on the command line.
	VAL_FORM_LIMIT: does [max 0 system/console/size/x - HELP_TYPE_COL_SIZE - HELP_COL_1_SIZE - RT_MARGIN]
	;!! This behaves differently when compiled. Interpreted, output for 'system
	;!! is properly formatted and truncated. Compiled, it's very slow to return
	;!! and system/words and system/codecs (e.g.) are emitted full length. The
	;!! issue seems to be using an inner func. If we don't capture that inner
	;!! func, it's fine. For now I'm moving fmt out of form-value, rather than
	;!! just letting it leak out by not capturing it.
	fmt: func [v /molded][
		; Does it help to mold only part? Can't hurt I suppose.
		if any [molded  not string? :v] [v: mold/flat/part :v VAL_FORM_LIMIT + 1]
		ellipsize-at v VAL_FORM_LIMIT
	]
	;!!
	form-value: func [value [any-type!]][
		case [
			unset? :value		 [""]
			any-function? :value [fmt any [doc-string :value  spec-of :value]]
			any-block? value     [
				fmt form reduce [
					"length:" length? value
					; Bolek's idea
					either (index? value) > 1 [form reduce ["index:" index? value]][""]
					mold/flat value
				]
			]
			any-object? value    [fmt words-of value]
			map? value           [fmt keys-of value]
			image? value         [fmt reduce ["size:" value/size]]
			typeset? value       [fmt to block! value]
			string? value        [fmt/molded value]
			'else                [fmt :value]
		]
	]
	
	get-sys-words: func [test [function!]][
		collect [
			foreach word words-of system/words [
				if test get/any word [keep word]
			]
		]
	]

	longest-word: func [words [block! object!]][
		if all [object? words  empty? words: words-of words] [return ""]
		forall words [words/1: form words/1]
		sort/compare words func [a b][(length? a) < (length? b)]
		last words
	]

	set?: func [value [any-type!]][not unset? :value]
	
	value-is-type-str: function [value][
		rejoin [mold :value " is " a-an/pre mold type? :value]
	]

	word-is-value-str: function [
		word [word! path!]
		/only "Don't include value itself"
	][
		value: get/any word
		rejoin [
			uppercase mold :word " is " a-an/pre mold type? :value " value"
			either only [""][append copy ": " mold :value]
		]
	]

	;---------------------------------------------------------------------------
	; In addition to the func spec parser below, there are a few helper funcs
	; here that can be used to easily grab func spec elements. If you don't
	; need a full func spec, but just want to display a doc string, list of
	; args, or info for a given arg (e.g. for popup help tips), use these.
	
	arg-info: function [
		"Returns name, type, and doc-string for the given word in the spec."
		spec [block!]
		word [word!]
		return: [block!] "[name type doc-string]"
	][
		t: d: 0										; index of type and doc string. 0 means none.
		if pos: find spec word [
			set [t d] either block? pos/2 [
				either string? pos/3 [[2 3]][[2 0]]	; type+doc or type+no-doc
			][
				either string? pos/2 [[0 2]][[0 0]]	; no-type+doc or no-type+no-doc
			]
			reduce [word pos/:t pos/:d]
		]
	]

	doc-string: function [
		"Returns the doc string for a function."
		fn [any-function!]
	][
		spec: spec-of :fn
		all [string? spec/1  copy spec/1]
	]

	; These are here because they are not standard in Red yet.
	ext-word!: make typeset! [word! set-word! lit-word! get-word! refinement! issue!]
	ext-word?: func [value [any-type!]][find ext-word! type? :value]

	func-spec-words: function [
		"Returns all words from a function spec."
		fn [any-function!]
		/opt "Include refinements and their arguments"
		/all "Include return:, /local and what follows; implies /opt"
	][
		;!! remove-each doesn't return a result
		;!! Use `copy` on `spec-of` so `remove` doesn't mod it!
		remove-each val blk: copy spec-of :fn [not ext-word? val]	; Remove doc strings and type specs
		if system/words/all [not opt  not all][
			clear find blk refinement!
		]
		if not all [
			remove find blk to set-word! 'return
			clear find blk /local
		]
		blk
	]

	;-------------------------------------------------------------------------------

	func-spec-ctx: context [
		func-spec: context [
			desc: none				; string!							desc
			attr: none				; block!							[attr ...]
			params: copy []			; [word! opt block! opt string!]	[name type desc]
			refinements: copy []	; [word! opt string! [params]]		[name desc [[name type desc] ...]]
			locals: copy []			; [some word!]						[name ...]
			returns: copy []		; [opt [word! string!]]				[type desc]
		]

		param-frame-proto: reduce ['name none 'type none 'desc none]
		refinement-frame-proto: reduce ['name none 'desc none 'params copy []]

		;!! These cause problems if local in parse-func-spec
			stack: copy []
			push: func [val][append/only stack val]
			pop:  does [also  take back tail stack  cur-frame: last stack]
			push-param-frame: does [
				push cur-frame: copy param-frame-proto
			]
			push-refinement-frame: does [
				push cur-frame: copy/deep refinement-frame-proto
			]
			emit: function [key val][
				pos: find/only/skip cur-frame key 2
				head change/only next pos val
			]
		;!!
		
		set 'parse-func-spec function [
			"Parses a function spec and returns an object model of it."
			spec [block! any-function!]
			/local =val		; set with parse, so function won't collect it
		][
			clear stack
			; The = sigils are just to make parse-related vars more obvious
			func-desc=:  [set =val string! (res/desc: =val)]
			attr-val=:   ['catch | 'throw]
			func-attr=:  [into [copy =val some attr-val= (res/attr: =val)]]
			
			param-name=: [
				set =val [word! | get-word! | lit-word!]
				(push-param-frame  emit 'name =val)
			]
			;!! This isn't complete. Under R2 we could parse for datatype! in 
			;	the param type spec, but they are just words in Red func specs.
			param-type=: [
				set =val block! (emit 'type =val) (
					if not any [
						parse reduce =val [some [datatype! | typeset!]]
						parse =val ['function! block!]
					][
						print ["Looks like we have a bad type spec:" mold =val]
					]
				)
			]
			param-desc=: [set =val string! (emit 'desc =val)]
			param-attr=: [opt param-type= opt param-desc=]
			param=:      [param-name= param-attr= (append/only res/params new-line/all pop off)]
			
			ref-name=:   [set =val refinement! (push-refinement-frame  emit 'name =val)]
			ref-desc=:   :param-desc=
			ref-param=:  [param-name= param-attr= (tmp: pop  append/only cur-frame/params tmp)]
			refinement=: [ref-name= opt ref-desc= any ref-param= (append/only res/refinements pop)]
			locals=:     [/local copy =val any word! (res/locals: =val)]
			returns=: [
				quote return: (push-param-frame  emit 'name 'return)
				param-type= opt param-desc=
				(res/returns: pop)
			]
			spec=: [
				opt func-desc=
				opt func-attr=
				any param=
				any [locals= to end | refinement= | returns=]
			]

			if any-function? :spec [spec: spec-of :spec]
			res: make func-spec []
			either parse spec spec= [res] [none]
		]

	]

	;-------------------------------------------------------------------------------

	HELP-USAGE: {
	Use HELP or ? to view built-in docs for functions, values 
	for contexts, or all values of a given datatype:

		help append
		? system
		? function!

	To search for values by name, use a word:

		? pri
		? to-

	To also search in function specs, use a string:

		? "pri"
		? "issue!"

	Other useful functions:

		??     - Display a word and the value it references
		probe  - Print a molded value
		source - Show a function's source code
		what   - Show a list of known functions or words
		about  - Display version number and build date
		quit   - Leave the Red console
	}

	show-datatype-help: function [
		type [datatype!]
		/local val
	][
		DOC_LIMIT: system/console/size/x - HELP_COL_1_SIZE - RT_MARGIN
		fmt-doc: func [str][either str [ellipsize-at str DOC_LIMIT][""]]
		found-at-least-one?: no
		foreach word words-of system/words [
			col-1: rejoin [DENT_1 as-col-1 word]
			; Act only on words that match the datatype spec'd.
			; Unset values make us jump through some /any hoops.
			set/any 'val get/any word
			if all [not unset? :val  type = type? :val  (found-at-least-one?: yes)] [
				_print case [
					;?? What else can we show that is useful for datatypes?
					;	Can't reflect on datatypes, as R3 could to some extent.
					;	We would have to build our own typeset-match funcs to
					;	show the type tree for it.
					datatype? :val [col-1]
					any-function? :val [[col-1 DOC_SEP fmt-doc doc-string :val]]
					'else [[col-1 DEF_SEP form-value :val]]
				]
			]
		]
		if not found-at-least-one? [
			_print ["No" type "values were found in the global context."]
		]
	]

	; I wanted this to be local to show-function-help, but it fails when
	; called with the refinment when compiled under 0.6.2.
	form-param: function [param [block!] /no-name][
		form reduce [
			either no-name [""] [as-arg-col mold param/name]
			either type: select/skip param 'type 2 [mold/flat type][NO_DOC]
			either param/desc [mold param/desc][NO_DOC]
		]
	]
	print-param: func [param [block!] /no-name][
		_print either no-name [form-param/no-name param][form-param param]
	]

	show-function-help: function [
		"Displays help information about a function."
		word [word!]
	][
		fn: either word? :word [get :word][:word]
		if not any-function? :fn [
			print "show-function-help only works on words that refer to functions."
			exit
		]

		; Convert the func to an object with fields for spec values
		fn-as-obj: parse-func-spec :fn
		if not object? fn-as-obj [
			print "Func spec couldn't be parsed, may be malformed."
			print mold :fn
			exit
		]

		_print "USAGE:"
		_print either op? :fn [
			[DENT_1 fn-as-obj/params/1/name word fn-as-obj/params/2/name]
		][
			[DENT_1 uppercase form word  mold/only/flat func-spec-words :fn]
		]

		if fn-as-obj/attr [
			_print [newline "ATTRIBUTES:^/" DENT_1 mold fn-as-obj/attr]
		]
			
		_print [
			newline "DESCRIPTION:" newline
			reduce either fn-as-obj/desc [[DENT_1 any [fn-as-obj/desc NO_DOC] newline]][""]
			DENT_1 word-is-value-str/only word
		]

		if not empty? fn-as-obj/params [
			_print [newline "ARGUMENTS:"] 
			foreach param fn-as-obj/params [_print [DENT_1 form-param param]]
		]
		
		if not empty? fn-as-obj/refinements [
			_print [newline "REFINEMENTS:"] 
			foreach rec fn-as-obj/refinements [
				_print [DENT_1 as-arg-col mold/only rec/name DOC_SEP any [rec/desc NO_DOC]]
				foreach param rec/params [_prin DENT_2 print-param param]
			]
		]

		if not empty? fn-as-obj/returns [
			_print [newline "RETURNS:"]
			if fn-as-obj/returns/desc [_print [DENT_1 fn-as-obj/returns/desc]]
			_print [DENT_1 mold/flat fn-as-obj/returns/type]
		]
				
		exit
	]

	show-object-help: function [
		"Displays help information about an object."
		word [word! path! object!]
		/local value
	][
		if not object? word [
			_print [uppercase form word "is an object! with the following words and values:"]
		]
		obj: either object? word [word][get word]
		if not object? obj [
			_print "show-object-help only works on words that refer to objects."
			exit
		]

		word-col-wd: length? longest-word obj

		foreach obj-word words-of obj [
			set/any 'value get/any obj-word
			_print [
				DENT_1 pad form obj-word word-col-wd DEF_SEP as-type-col :value DEF_SEP
				; Yes, we're checking against our output buffer for every value, even
				; though it will only trigger for this context (help-ctx) and the 
				; output-buffer word in it. If we don't check, the output is messed up.
				; We're in the process of updating output-buffer after all. It's either
				; this or use a separate buffer. The joys of self reflection.
				either same? :value output-buffer [""][form-value :value]
			]
		]
	]

	set 'help function [
		"Displays information about functions, values, objects, and datatypes."
		'word [any-type!]
	][
		;print either unset? :word [help-string][help-string :word]
		print help-string :word
	]
	set '? :help

	set 'help-string function [
		"Returns information about functions, values, objects, and datatypes."
		'word [any-type!]
	][
		clear output-buffer
		case [
			;They just said HELP
			unset? :word [_print HELP-USAGE]

			; They gave us a string to find in func names or specs
			string? :word [what/with/spec/buffer word]
			
			; They said HELP for something that doesn't exist
			all [word? :word  unset? get/any :word] [what/with/buffer word]

			'else [
				; Now we know we're either going to reflect help for a func,
				; find all values of a given datatype, probe a context, or
				; show a value.
				value: either any [word? :word  path? :word] [get/any :word][:word]
				; The order in which we check values is important, to get 
				; the best output for a given type.
				case [
					all [word? :word  any-function? :value] [show-function-help :word]
					any-function? :value [_print mold :value]
					datatype? :value [show-datatype-help :value]
					object? :value [show-object-help :value]
					image? :value [
						either in system 'view [view [image value]][
							_print form-value value
						]
					]
					all [path? :word  object? :value][show-object-help word]
					any [word? :word  path? :word] [_print word-is-value-str word]
					'else [_print value-is-type-str :word]
				]
			]
		]
		output-buffer
	]
	set 'fetch-help :help-string			; alias for VS Code plug while it still uses the old name
	
	set 'source function [
		"Print the source of a function"
		'word [any-word!] "The name of the function"
	][
		print either function? val: get/any word [
			[append mold word #":" mold :val]
		][
			["Sorry," word "is" a-an/pre mold type? :val "so source is not available"]
		]
	]

	set 'what function [
		"Lists all functions, or search for values"
		/with "Search all values that contain text in their name"
			text [word! string!]
		/spec "Search for text in value specs as well"
		/buffer "Buffer and return output, rather than printing results"
	][
		clear output-buffer
		found-at-least-one?: no
		foreach word sort get-sys-words either with [:set?][:any-function?] [
			val: get word
			if any [
				not with
				find form word text
				all [spec  any-function? :val  find mold spec-of :val text]
			][
				found-at-least-one?: yes
				_print [DENT_1 as-col-1 word  as-type-col :val  DEF_SEP  form-value :val]
			]
		]
		if not found-at-least-one? [
			_print "No matching values were found in the global context."
		]
		either buffer [output-buffer][print output-buffer]	; Note ref to output-buffer in context
	]

	set 'about function ["Print Red version information"][
		print [
			"Red for" system/platform
			'version system/version
			'built system/build/date
		]
	]

]

