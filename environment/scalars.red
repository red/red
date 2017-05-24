Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %scalars.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

yes: on: true
no: off: false

tab:		 #"^-"
cr: 		 #"^M"
newline: lf: #"^/"
escape:      #"^["
slash: 		 #"/"
sp: space: 	 #" "
null: 		 #"^@"
crlf:		 "^M^/"
dot:		 #"."
comma:		 #","
dbl-quote:	 #"^""

pi: 3.141592653589793

Rebol: false											;-- makes loading Rebol scripts easier

;-- warning: following typeset definitions are processed by the compiler, do not change them
;-- unless you know what you are doing!

internal!:		make typeset! [unset!]
external!:		make typeset! [#if find config/modules 'view [event!]]
number!:		make typeset! [integer! float! percent!]
scalar!:		union number! make typeset! [char! pair! tuple! time!]
any-word!:		make typeset! [word! set-word! get-word! lit-word!] ;-- any bindable word
all-word!:		union any-word! make typeset! [refinement! issue!]	;-- all types of word nature
any-list!:		make typeset! [block! paren! hash!]
any-path!:		make typeset! [path! set-path! get-path! lit-path!]
any-block!:		union any-path! any-list!
any-function!:	make typeset! [native! action! op! function! routine!]
any-object!:	make typeset! [object! error!]
any-string!:	make typeset! [string! file! url! tag! email!]
series!:		union make typeset! [binary! image! vector!] union any-block! any-string!
immediate!:		union scalar! union all-word! make typeset! [none! logic! datatype! typeset! handle!]
default!:		union series! union immediate! union any-object! union external! union any-function! make typeset! [map! bitset!]
any-type!:		union default! internal!
