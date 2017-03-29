Red [
	Title:	"Console help functions"
	Author:	["Oldes" "Gregg Irwin" "Ingo Hohmann" "Nenad Rakocevic"]
	File:	%help.red
	Tabs:	4
	Rights:	"Copyright (C) 2014-2017 All Mankind. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

help-ctx: context [
	HELP-USAGE: {Use HELP or ? to see built-in info:

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

	buffer: copy ""

	interpunction: charset ";.?!"
	dot: func[value [string!] return: [string!]][
		unless find interpunction last value [append value #"."]
		value
	]

	output: func[value][ buffer: insert buffer form reduce value ]

	pad: func [val [string!] size] [head insert/dup tail val #" " size - length? val]

	clip-str: func [str width [integer!]] [
		if width < length? str [str: append copy/part str width "..."]
		str
	]

	set 'a-an function [
		"Prepends the appropriate variant of a or an into a string"
		s [string!]
	][
		form reduce [pick ["an" "a"] make logic! find "aeiou" s/1 s]
	]

	form-type: func [value] [
		a-an head clear back tail mold type? :value
	]

	form-value: function [value] [
		type: type? :value
		clip-str case [
			unset!    = type [ "" ]
			image!    = type [ form reduce ["size:" value/size] ]
			typeset!  = type [ mold/part to-block value 100]
			;datatype! = type [ uppercase/part any [select datatypes to word! :value ""] 1 ] 
			find any-object! type [ mold/part keys-of value 100]
			find any-block!  type [ trim/lines mold/part :value 100 ]
			find any-function! type [
				spec: copy/deep spec-of :value
				either any [
					string? value: spec/1
					string? value: spec/2	;-- attributes block case
				][	
					dot	value
				][
					clear find spec /local
					value: trim/lines mold spec
				]
				;@@ TODO: wrap long description lines
			]
			'else [mold :value]
		] system/console/limit - 25
	]

	form-obj: function [
		"Outputs information about an object"
		obj [object!]
		/weak "Provides sorting and does not displays unset values"
		/match "Include only those that match a string or datatype"
		 pattern
		return: [string!]
	][
		out: copy ""
		words: words-of obj
		if weak [sort words]
		foreach word words [
			type: type? get/any word
			if type <> unset! [value: get/any word]
			str: form either any-function? :value [ reduce [word mold spec-of :value] ][ word ]
			if any [
				not match
				all [
					type <> unset!
					either string? :pattern [
						find str pattern
					] [
						type = get :pattern
					]
				]
			][
				unless all [weak type = unset!][
					str: pad form word 18
					insert tail out to string! reduce [
						"   " str #" "
						pad mold type 12 - ((length? str) - 18)
						either type = unset! [""][form-value :value]
						newline
					]
				]
			]
		]
		out
	]

	out-description: func [des [block!]][
		foreach line des [
			uppercase/part trim/lines line 1
			dot line
		]
		buffer: insert insert buffer #" " form des
	]

	set 'help function [
		"Provide helping information about words and other values"
		'word [any-type!] "Word you are looking for"
		/into "Help text will be inserted into provided string instead of printed"
			string [string!] "Returned series will be past the insertion"
		/extern buffer ;defined so the buffer from help-ctx is used
		/local desc ;must define it as there is no set word to be collected
	][
		if into [
			_buffer: buffer ;store default help output buffer
			buffer: string
		]

		catch [case/all [
			if unset? :word [									;-- HELP with no arguments
				buffer: insert buffer HELP-USAGE
				throw true
			]

			if word? :word [
				either value? :word [
					value: get :word    ;lookup for word's value if any
				][	word: mold :word ]  ;or use it as a string input
			]

			string? :word  [
				types: form-obj/weak/match system/words :word
				output either empty? types [
					["No information on:" word]
				][	["Found these related words:" newline types]]
				throw true
			]
			
			datatype? :value [
				output [uppercase mold :word "is a datatype of value:" mold :value]
				;if desc: select datatypes to word! :value [
				;	output ["^/It is defined as" a-an desc]
				;]
				tmp: form-obj/match system/words :word
				unless empty? tmp [
					output ["^/^/Found these related words:^/" tmp]
				]
				throw true
			]

			not any [word? :word path? :word] [
				output [mold :word "is" form-type :word]
				throw true
			]

			path? :word [
				if any [
					error? set/any 'value try [get :word]
					not value? :value
				] [
					output ["No information on" word "(path has no value)"]
					throw true
				]
			]

			any-function? :value [
				spec: copy/deep spec-of :value
				args: copy []
				refs: none
				type: type? :value
				
				clear find spec /local
				ret: select/last spec quote return:
				parse spec [
					any block!
					copy desc any string!
					any [
						set arg [word! | lit-word! | get-word!] 
						set def opt block!
						copy des any string! (
							repend args [arg def des]
						)
						opt [set-word! block!]
					]
					opt [refinement! refs:]
					to end
				]
				output "USAGE:^/    "
				either op? :value [
					output [args/1 word args/4]
				] [
					output [uppercase mold word]
					foreach [arg def des] args [
						buffer: insert buffer rejoin [#" " mold arg]
					]
				]

				output "^/^/DESCRIPTION:^/"
				unless empty? desc [
					foreach line desc [
						trim/head/tail line
						unless empty? line [
							output ["   " dot uppercase/part line 1 #"^/"]
						]
					]
				]
				output ["   " uppercase form word "is" a-an mold type "value."]
				if ret [ output  ["^/    Returns value of type:" mold ret] ]

				unless empty? args [
					output "^/^/ARGUMENTS:"
					foreach [arg def des] args [
						output [
							"^/   " pad mold arg 10
							pad either def [mold def]["[any-type!]"] 10
						]
						out-description des
					]
				]

				if refs [
					output "^/^/REFINEMENTS:"
					parse back refs [
						any [
							set tmp refinement! (output ["^/   " pad mold tmp 10])
							opt [set tmp string! (output [" <-" tmp])]
							any [
								set arg [word! | lit-word! | get-word!] 
								set def opt block! 
								copy des any string! (
									output [
										"^/      "
										pad form arg 7 
										pad either def [mold def]["[any-type!]"] 10
									]
									out-description des
								)
							]
						]
					]
				]
				throw true
			]
			'else [
				output [
					uppercase mold word "is" form-type :value "of value:"
					either any [object? value] [rejoin [#"^/" form-obj value]] [mold :value]
				]
			]
		]]
		either into [
			also
				buffer           ;returned value; on the tail!
				buffer: _buffer  ;reverted use of the default buffer
		][
			buffer: head buffer
			also
				print buffer
				clear buffer
		]
	]

	set '? :help

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
		print [
			"Red for" system/platform
			'version system/version
			'built system/build/date
		]
	]
]
