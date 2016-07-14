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

help: function [
	"Display helping information about words and other values"
	'word [any-type!] "Word you are looking for"
	/local word type info w attributes block ref
][
	tab: tab4: "    "
	tab8: "        "
	
	case [
		unset? :word [									;-- HELP with no arguments
			print {Use HELP or ? to see built-in info:

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
			exit
		]
		all [word? :word datatype? get/any :word] [			;-- HELP <datatype!>
			type: get/any :word
			found?: no
			foreach w sort words-of system/words [
				if all [word? w type = type? get/any w][
					found?: yes
					case [
						any-function? get/any w [
							prin [tab pad form w 15]
							spec: spec-of get w

							either any [
								string? desc: spec/1
								string? desc: spec/2	;-- attributes block case
							][
								print ["^-=> " desc]
							][
								prin lf
							]
						]
						datatype? get/any w [
							print [tab pad form :w 15]
						]
						'else [
							print [tab pad form :w 15 ": " mold get/any w]
						]
					]
				]
			]
			unless found? [print "No value of that type found in global space."]
			exit
		]
		string? :word [
			foreach w sort words-of system/words [
				if all [word? w any-function? get/any :w][
					spec: spec-of get w
					if any [find form w word find form spec word] [
						prin [tab w]

						either any [
							string? desc: spec/1
							string? desc: spec/2		;-- attributes block case
						][
							print ["^-=> " desc]
						][
							prin lf
						]
					]
				]
			]
			exit
		]
		not any [word? :word path? :word][				;-- all others except word!
			type: type? :word
			print [mold :word "is" a-an form type type]
			exit
		]
	]
	
	func-name: :word

	argument-rule: [
		set word [word! | lit-word! | get-word!]
		(prin [tab mold :word])
		opt [set type block!  (prin [#" " mold type])]
		opt [set info string! (prin [" =>" append form info dot])]
		(prin lf)
	]
	
	case [
		unset? get/any :word [
			print ["Word" :word "is not defined"]
		]
		all [
			any [word? func-name path? func-name]
			fun: get func-name
			any-function? :fun
		][
			prin ["^/USAGE:^/" tab ]
			unless op? :fun [prin func-name prin " "]

			parse spec-of :fun [
				start: [									;-- 1st pass
					any [block! | string! ]
					opt [
						set w [word! | lit-word! | get-word!] (
							either op? :fun [prin [mold w func-name]][prin mold w]
						)
					]
					any [
						/local to end
						| set w [word! | lit-word! | get-word!] (prin " " prin w)
						| set w refinement! (prin " " prin mold w)
						| skip
					]
				]

				:start										;-- 2nd pass
				opt [set attributes block! (prin ["^/^/ATTRIBUTES:^/" tab mold attributes])]
				opt [set info string! (
					print [
						"^/^/DESCRIPTION:^/" tab
						append form info dot lf tab
						func-name "is of type:" mold type? :fun
					]
				)]

				(print "^/ARGUMENTS:")
				any [argument-rule]; (prin lf)]

				(print "^/REFINEMENTS:")
				any [
					/local [
						to ahead set-word! 'return set block block! 
						(print ["^/RETURN:^/" mold block])
						| to end
					]
					| [
						set ref refinement! (prin [tab mold ref])
						opt [set info string! (prin [" =>" append form info dot])]
						(tab: tab8 prin lf)
						any [argument-rule]
						(tab: tab4)
					]
				]
			]
		]
		all [any [word? word path? word] object? get word][
			prin #"`"
			prin form word
			print "` is an object! of value:"

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

				desc: either string? desc [copy/part desc 47][mold/part/flat desc 47]

				if 47 = length? desc [					;-- optimized for width = 78
					clear skip tail desc -3
					append desc "..."
				]
				print [
					tab
					pad form/part w 16 16
					pad mold type? get/any w 9
					desc
				]
			]
		]
		'else [
			value: get :word
			print [
				word "is a" 
				mold type? :value
				"of value:"
				mold either path? :value [get :value][:value]
			]
		]
	]
	exit												;-- return unset value
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
	print ["Red" system/version #"-" system/build]
]
