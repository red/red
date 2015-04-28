Red [
	Title:	"Console help functions"
	Author:	["Ingo Hohmann" "Nenad Rakocevic"]
	File:	%help.red
	Tabs:	4
	Rights:	"Copyright (C) 2014 Ingo Hohmann, Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

help: func [
	"Display helping information about words and other values"
	'word [any-type!] "Word you are looking for"
	/local func-name desc spec tab tab4 tab8 type start attributes info fun w ref block w1 w2 value
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
		all [word? word datatype? get :word] [			;-- HELP <datatype!>
			type: get :word
			foreach w system/words [
				if type = type? get w [
					case [
						any [function? get w native? get w action? get w op? get w routine? get w][
							prin [tab w]
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
						datatype? get w [
							print [tab :w]
						]
						'else [
							print [tab :w "^-: " mold get w]
						]
					]
				]
			]
			exit
		]
		string? word [
			foreach w system/words [
				if any [function? get w native? get w action? get w op? get w routine? get w][
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
			any [action? :fun function? :fun native? :fun op? :fun routine? :fun]
		][
			prin ["^/USAGE:^/" tab ]

			parse spec-of :fun [
				start: [									;-- 1st pass
					any [block! | string! ]
					opt [set w [word! | lit-word! | get-word!] (either op? :fun [prin [mold w func-name]][prin [func-name mold w]])]
					any [
						/local to end
						| set w [word! | lit-word! | get-word!] (prin [" " w])
						| set w refinement! (prin [" " mold w])
						| skip
					]
				]

				:start										;-- 2nd pass
				opt [set attributes block! (prin ["^/^/ATTRIBUTES:^/" tab mold attributes])]
				opt [set info string! (print ["^/^/DESCRIPTION:^/" tab append form info dot lf tab func-name "is of type:" mold type? :fun])]

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
				value: get/any in get word w

				desc: case [
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

what: function [
	"Lists all functions, or words of a given type"
][
	foreach w system/words [
		if any [function? get w native? get w action? get w op? get w routine? get w][
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
	print either function? get func-name [
		[append mold func-name #":" mold get func-name]
	][
		type: mold type? get func-name
		a: pick ["an" "a"] make logic! find "aeiou" type/1
		["Sorry," func-name "is" a type "so no source is available"]
	]
]

about: function [
	"Print Red version information"
][
	print ["Red" system/version #"-" system/build]
]
