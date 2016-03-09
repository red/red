Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %operators.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- #load temporary directive is used to workaround REBOL LOAD limitations on some words

#load set-word! "+"		make op! :add
#load set-word! "-"		make op! :subtract
#load set-word! "*"		make op! :multiply
#load set-word! "/"		make op! :divide
#load set-word! "//"	make op! :modulo
#load set-word! "%"		make op! :remainder
#load set-word! "="		make op! :equal?
#load set-word! "<>"	make op! :not-equal?
#load set-word! "=="	make op! :strict-equal?
#load set-word! "=?"	make op! :same?
#load set-word! "<" 	make op! :lesser?
#load set-word! ">" 	make op! :greater?
#load set-word! "<="	make op! :lesser-or-equal?
#load set-word! ">="	make op! :greater-or-equal?
#load set-word! "<<"	make op! :shift-left
#load set-word! ">>"	make op! :shift-right
#load set-word! ">>>"	make op! :shift-logical
#load set-word! "**"	make op! :power
and:					make op! :and~
or:						make op! :or~
xor:					make op! :xor~