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
	"Get help for functions"
	'word [any-type!] "Word you are looking for"
	/local func-name desc spec tab tab4 tab8 type start attributes info fun w ref block
][
	tab: tab4: "    "
	tab8: "        "
	
	case [
		unset? :word [								;-- HELP with no arguments
			print {Use HELP or ? to see built-in info:

    help insert
    ? insert

To see all words of a specific datatype:

    ? native!
    ? function!
    ? datatype!

Other debug functions:

    ?? - display a variable and its value
    probe - print a value (molded)
    source func - show source code of func
    what - show a list of known functions
}
		]
		datatype? get :word [						;-- HELP <datatype!>
			type: get :word
			foreach w system/words [
				if type = type? get w [
					either any [function? get w native? get w action? get w][
						prin [tab w]
						spec: spec-of get w

						either any [
							string? desc: spec/1
							string? desc: spec/2					;-- attributes block case
						][
							print ["^-=> " desc]
						][
							prin lf
						]
					][
						print [tab :w "^-: " mold get w]
					]
				]
			]
		]
		'else [
			func-name: :word

			argument-rule: [
				set word [word! | lit-word! | get-word!]
				(prin [tab mold word])
				opt [set type block!  (prin [#" " mold type])]
				opt [set info string! (prin [" =>" append form info dot])]
				(prin lf)
			]

			either all [
				word? func-name
				fun: get func-name
				any [action? :fun function? :fun native? :fun]
			][
		;		print ["^/" func-name "is of type" type? :fun newline]
				prin ["^/USAGE:^/" tab func-name]

				parse spec-of :fun [
					start: any [						;-- 1st pass
						/local to end
						| set w word! (prin [" " w])
						| set w [lit-word! | refinement!] (prin [" " mold w])
						| skip
					]

					:start								;-- 2nd pass
					opt [set attributes block! (prin ["^/^/ATTRIBUTES:^/" tab mold attributes])]
					opt [set info string! (print ["^/^/DESCRIPTION:^/" tab append form info dot])]

					(print "^/ARGUMENTS:")
					any [argument-rule (prin lf)]

					(print "REFINEMENTS:")
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
			][
				print [
					func-name "is of type" 
					mold type? either word? :func-name [:fun][:func-name]
					"^/No more help available."
				]
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
		if any [function? get w native? get w action? get w][
			prin w
			spec: spec-of get w
			
			either any [
				string? desc: spec/1
				string? desc: spec/2					;-- attributes block case
			][
				print [tab "=> " desc]
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
		["Sorry," func-name "is a" type? :func-name "so no source is available"]
	]
]
