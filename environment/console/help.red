Red [
	Title:	"Console help functions"
	Author:	["Oldes" "Ingo Hohmann" "Nenad Rakocevic"]
	File:	%help.red
	Tabs:	4
	Rights:	"Copyright (C) 2014-2017 Oldes, Ingo Hohmann, Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ctx-help: context [
	datatypes: [
		action!     "datatype native function (standard polymorphic)."
		binary!     "string series of bytes."
		bitset!     "set of bit flags."
		block!      "series of values."
		char!       "8bit and 16bit character."
		datatype!   "type of datatype."
		date!       "day, month, year, time of day, and timezone."
		float!      "64bit floating point number (IEEE standard)."
		email!      "email address."
		error!      "errors and throws."
		event!      "user interface event (efficiently sized)."
		file!       "file name or path."
		function!   "interpreted function (user-defined or mezzanine)."
		get-path!   "the value of a path."
		get-word!   "the value of a word (variable)."
		handle!     "arbitrary internal object or value."
		hash!       "."
		image!      "RGB image with alpha channel."
		integer!    "32 bit integer."
		issue!      "identifying marker word."
		library!    "external library reference."
		lit-path!   "literal path value."
		lit-word!   "literal word value."
		logic!      "boolean true or false."
		map!        "name-value pairs (hash associative)."
		money!      "high precision decimals with denomination (opt)."
		native!     "direct CPU evaluated function."
		none!       "no value represented."
		object!     "context of names with values."
		op!         "infix operator (special evaluation exception)."
		pair!       "two dimensional point or size."
		paren!      "automatically evaluating block."
		path!       "refinements to functions, objects, files."
		percent!    "special form of decimals (used mainly for layout)."
		pair!       "two dimensional point or size."
		port!       "external series, an I/O channel."
		refinement! "variation of meaning or location."
		routine!    "native function."
		set-path!   "definition of a path's value."
		set-word!   "definition of a word's value."
		string!     "string series of characters."
		struct!     "native structure definition."
		tag!        "markup string (HTML or XML)."
		time!       "time of day or duration."
		tuple!      "sequence of small integers (colors, versions, IP)."
		typeset!    "set of datatypes."
		unset!      "no value returned or set."
		url!        "uniform resource locator or identifier."
		vector!     "high performance arrays (single datatype)."
		word!       "word (symbol or variable)."
	]

	clip-str: func [str] [
		if (length? str) > 80 [str: append copy/part str 80 "..."]
		str
	]

	form-val: func [val] [
		val: case [
			any-function? :val [
				spec: spec-of :val
				either any [
					string? val: spec/1
					string? val: spec/2	;-- attributes block case
				][	
					if #"." <> last val [append val #"."]
					val
				][
					clear find spec /local
					val: trim/lines mold spec
				]
				;@@ TODO: wrap long description lines
			]
			any-block? :val [ form reduce ["length:" length? val] ]
			image?     :val [ form reduce ["size:" val/size] ]
			object?    :val [val: mold keys-of val]
			typeset?   :val [val: mold to-block val]
			datatype?  :val [val: uppercase/part any [select datatypes to word! :val ""] 1] 
			'else [mold :val]
		]
		clip-str :val
	]

	pad: func [val [string!] size] [
		insert/dup tail val #" " size - length? val
		val
	]

	set 'a-an function [s [string!]][
		"Returns the appropriate variant of a or an"
		form reduce [pick ["an" "a"] make logic! find "aeiou" s/1 s]
	]

	type-name: func [value] [
		value: mold type? :value
		clear back tail value
		a-an value
	]


	set 'dump-obj function [
		"Returns a block of information about an object or port"
		obj [object!]
		/weak "Provides sorting and does not displays unset values"
		/match "Include only those that match a string or datatype" pat
	][
		out: copy []
		wild: all [string? pat find pat "*"]
		if wild [
			;@@ find/any is not supported yet
			trim/all/with pat "*"
			wild: false
		]
		words: words-of obj
		if weak [sort words]
		foreach word words [
			;probe word
			type: type?/word get/any word
			if type <> 'unset! [val: get/any word]
			str: either find [function! routine! native! action! op! ] type [
				form reduce [word mold spec-of :val ]
			] [
				form word
			]
			if any [
				not match
				all [
					type <> 'unset!
					either string? :pat [
						either wild [
							tail? any [find/any/match str pat pat]
						] [
							find str pat
						]
					] [
						all [
							datatype? get :pat
							type = :pat
						]
					]
				]
			] [
				unless all [
					weak type = 'unset!
				] [
					str: pad form word 18
					append str #" "
					append str pad mold type 12 - ((length? str) - 18)
					append out form reduce [
						"   " str
						either type = 'unset! [""][form-val :val]
						newline
					]
				]
			]
		]
		out
	]

	into: func[out value][ insert tail out form reduce value ]

	fetch-help: function [
		"Display helping information about words and other values"
		word	[any-type!] "Word you are looking for"
		return: [string!]
	][
		out: make string! 32

		if unset? :word [									;-- HELP with no arguments
			return {Use HELP or ? to see built-in info:

    help insert
    ? insert

To see all functions containing a specific substring:

    ? "file"
    ? to-

To see all words of a specific datatype:

    ? native!
    ? function!
    ? datatype!

Other useful functions:

    ?? - display a variable and its value
    probe - print a value (molded)
    source func - show source code of func
    what - show a list of known functions
    about - display version number and build date
    q or quit - leave the Red console
}
		]

		if word? :word [
			either value? :word [
				value: get :word
			][	word: mold :word ]
		]
		case [
			datatype? :value [
				into out [uppercase mold :word "is a datatype."]
				if desc: select datatypes to word! :value [
					into out ["^/It is defined as" a-an desc]
				]
				tmp: sort dump-obj/match system/words :word
				unless empty? tmp [
					into out ["^/^/Found these related words:^/" tmp]
				]
			]
			any [string? :word all [word? :word datatype? :word]] [
				if all [word? :word datatype? :word] [
					into out dump-obj/match system/words :word
					into out [mold :word "is a datatype^/"]
				]
				if any [:word = 'unset! not value? :word] [return head out]
				types: dump-obj/weak/match system/words :word
				into out case [
					not empty? types [
						["Found these related words:" newline types]
					]
					all [word? :word datatype? :word] [
						["No values defined for:" word]
					]
					'else [["No information on:" word]]
				]
			]

			not any [word? :word path? :word] [
				into out [mold :word "is" type-name :word]
			]

			'else [
				if path? :word [
					if any [
						error? set/any 'value try [get :word]
						not value? value
					] [
						into out ["No information on" word "(path has no value)"]
						return out
					]
				] 
				either any-function? :value [
					spec: spec-of :value
					args: copy []
					refs: none
					type: type? :value
					parse spec [
						any block!
						copy desc any string!
						any [
							set arg [word! | lit-word! | get-word!] 
							set def block!
							set des opt [string!] (
								repend args [arg def des]
							)
						]
						opt [refinement! refs:]
					]
					clear find spec /local
					into out "USAGE:^/    "
					either op? :value [
						into out [args/1 word args/4]
					] [
						into out [uppercase mold word]
						foreach [arg def des] args [
							out: insert out rejoin [#" " mold arg]
						]
					]

					into out "^/^/DESCRIPTION:^/"
					unless empty? desc [
						foreach line desc [
							trim/head/tail line
							unless empty? line [
								uppercase/part line 1
								if #"." <> last line [append line #"."]
								into out ["   " line #"^/"]
							]
							
						]
					]
					into out ["   " uppercase form word "is" a-an mold type "value."]

					unless empty? args [
						into out "^/^/ARGUMENTS:"
						foreach [arg def des] args [
							if des [des: trim/head/tail des]
							into out [
								"^/   " pad mold arg 10 "->"
								mold def
							]
							if des [into out ["" uppercase/part des 1]]
						]
					]

					if refs [
						into out "^/^/REFINEMENTS:"
						parse back refs [
							any [
								set tmp refinement! (into out ["^/   " pad mold tmp 10])
								opt [set tmp string! (into out [" --" tmp])]
								any [
									set arg [word! | lit-word! | get-word!] 
									set def block!
									set des opt [string!] (
										into out ["^/      " pad form arg 7 "->" mold def]
										if des [into out ["" uppercase/part des 1]]
									)
								]
							]
						]
					]
					out: insert out #"^/"
				][
					into out [
						uppercase mold word "is" type-name :value "of value:"
						either any [object? value] [rejoin [#"^/" dump-obj value]] [mold :value]
					]
				]
			]
		]

		out
	]

	set 'help function [
		"Display helping information about words and other values"
		'word [any-type!] "Word you are looking for"
	][
		print fetch-help :word
	]

	set 'what function ["Lists all functions"][
		foreach w sort words-of system/words [
			if all [word? w any-function? get/any :w][
				prin pad form w 15
				spec: spec-of get w
				
				either any [
					string? desc: spec/1
					string? desc: spec/2					;-- attributes block case
				][
					print [#":" desc]
				][
					prin lf
				]
			]
		]
		exit												;-- return unset value
	]

	set 'source function [
		"Print the source of a function"
		'func-name [any-word!] "The name of the function"
	][
		print either function? get/any func-name [
			[append mold func-name #":" mold get func-name]
		][
			type: mold type? get/any func-name
			["Sorry," func-name "is" a-an type "so no source is available"]
		]
	]

	set 'about function ["Print Red version information"][
		print ["Red" system/version #"-" system/build/date]
	]
]

?: :help
