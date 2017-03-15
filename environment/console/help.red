Red [
	Title:	"Console help functions"
	Author:	["Ingo Hohmann" "Nenad Rakocevic"]
	File:	%help.red
	Tabs:	4
	Rights:	"Copyright (C) 2014-2015 Ingo Hohmann, Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

prin-out: function [out data][
	either block? data [
		data: reduce data
		forall data [
			append out data/1
			unless tail? data [append out #" "]
		]
	][
		append out data
	]
]

print-out: function [out data][
	prin-out out data
	append out #"^/"
]

fetch-help: function [
	"Display helping information about words and other values"
	word	[any-type!] "Word you are looking for"
	return: [string!]
	/local info w attributes block ref 
][
	out: make string! 32
	tab: tab4: "    "
	tab8: "        "
	
	case [
		unset? :word [									;-- HELP with no arguments
			return {Use HELP or ? to see built-in info:

    help insert
    ? insert

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
		all [word? :word datatype? get/any :word] [			;-- HELP <datatype!>
			type: get/any :word
			found?: no
			foreach w sort words-of system/words [
				if all [word? w type = type? get/any w][
					found?: yes
					case [
						any-function? get/any w [
							prin-out out [tab pad form w 15]
							spec: spec-of get w

							either any [
								string? desc: spec/1
								string? desc: spec/2	;-- attributes block case
							][
								print-out out ["^-=> " desc]
							][
								prin-out out lf
							]
						]
						datatype? get/any w [
							print-out out [tab pad form :w 15]
						]
						any [object? get/any w map? get/any w] [
							print-out out [tab pad form :w 15 mold words-of get/any w]
						]
						'else [
							print-out out [tab pad form :w 15 ": " mold get/any w]
						]
					]
				]
			]
			unless found? [print-out out "No value of that type found in global space."]
		]
		string? :word [
			foreach w sort words-of system/words [
				if all [word? w any-function? get/any :w][
					spec: spec-of get w
					if any [find form w word find form spec word] [
						prin-out out [tab w]

						either any [
							string? desc: spec/1
							string? desc: spec/2		;-- attributes block case
						][
							print-out out ["^-=> " desc]
						][
							prin-out out lf
						]
					]
				]
			]
			return out
		]
		not any [word? :word path? :word][				;-- all others except word!
			type: type? :word
			print-out out [mold :word "is" a-an form type type]
			return out
		]
	]
	
	func-name: :word

	argument-rule: [
		set word [word! | lit-word! | get-word!]
		(prin-out out [tab mold :word])
		opt [set type block!  (prin-out out [#" " mold type])]
		opt [set info string! (prin-out out [" =>" append form info dot])]
		(prin-out out lf)
	]
	
	case [
		unset? get/any :word [
			print-out out ["Word" :word "is not defined"]
		]
		all [
			any [word? func-name path? func-name]
			fun: get func-name
			any-function? :fun
		][
			prin-out out ["^/USAGE:^/" tab ]
			unless op? :fun [prin-out out func-name prin-out out " "]

			parse spec-of :fun [
				start: [									;-- 1st pass
					any [block! | string! ]
					opt [
						set w [word! | lit-word! | get-word!] (
							either op? :fun [prin-out out [mold w func-name]][prin-out out mold w]
						)
					]
					any [
						/local to end
						| set w [word! | lit-word! | get-word!] (prin-out out " " prin-out out w)
						| set w refinement! (prin-out out " " prin-out out mold w)
						| skip
					]
				]

				:start										;-- 2nd pass
				opt [set attributes block! (prin-out out ["^/^/ATTRIBUTES:^/" tab mold attributes])]
				opt [set info string! (
					print-out out [
						"^/^/DESCRIPTION:^/" tab
						append form info dot lf tab
						func-name "is of type:" mold type? :fun
					]
				)]

				(print-out out "^/ARGUMENTS:")
				any [argument-rule]; (prin-out out lf)]

				(print-out out "^/REFINEMENTS:")
				any [
					/local [
						to ahead set-word! 'return set block block! 
						(print-out out ["^/RETURN:^/" mold block])
						| to end
					]
					| [
						set ref refinement! (prin-out out [tab mold ref])
						opt [set info string! (prin-out out [" =>" append form info dot])]
						(tab: tab8 prin-out out lf)
						any [argument-rule]
						(tab: tab4)
					]
				]
			]
		]
		all [any [word? word path? word] object? get word][
			prin-out out #"`"
			prin-out out form word
			print-out out "` is an object! of value:"

			foreach w words-of get word [
				set/any 'value get/any in get word w

				set/any 'desc case [
					object? :value  [words-of value]
					find [op! action! native! function! routine!] type?/word :value [
						spec: spec-of :value
						if string? spec/1 [spec: spec/1]
						spec
					]
					'else [:value]
				]

				desc: either string? desc [mold/flat copy/part desc 47][mold/part/flat desc 47]

				if 47 = length? desc [					;-- optimized for width = 78
					clear skip tail desc -3
					append desc "..."
				]
				print-out out [
					tab
					pad form/part w 16 16
					pad mold type? get/any w 9
					desc
				]
			]
		]
		'else [
			value: get :word
			print-out out [
				word "is a" 
				mold type? :value
				"of value:"
				mold either path? :value [get :value][:value]
			]
		]
	]
	out
]

help: function [
	"Display helping information about words and other values"
	'word [any-type!] "Word you are looking for"
][
	print fetch-help :word
]

?: :help

a-an: function [s [string!]][
	"Returns the appropriate variant of a or an"
	pick ["an" "a"] make logic! find "aeiou" s/1
]

what: function ["Lists all functions"][
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

source: function [
	"Print the source of a function"
	'func-name [any-word!] "The name of the function"
][
	print either function? get/any func-name [
		[append mold func-name #":" mold get func-name]
	][
		type: mold type? get/any func-name
		["Sorry," func-name "is" a-an type type "so no source is available"]
	]
]

about: function ["Print Red version information"][
	print ["Red" system/version #"-" system/build/date]
]
