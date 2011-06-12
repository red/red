Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define zero? 		[0 =]
#define positive?	[0 < ]			;-- space required after the lesser-than symbol
#define negative?	[0 > ]
#define negate		[0 -]

#define forever		[while [true]]
#define does		[func []]
#define unless		[if not]

#define as-byte		[as byte!]
#define as-logic	[as logic!]
#define as-integer	[as integer!]
#define as-c-string	[as c-string!]

#define null-char	#"^(00)"

null: 		pointer [integer!]		;-- null pointer declaration
newline: 	"^/"
stdout:		-1						;-- uninitialized default value
stdin:		-1						;-- uninitialized default value
stderr:		-1						;-- uninitialized default value


#switch OS [						;-- loading OS-specific bindings
	Windows  [#include %win32.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]


length?: func [					;; return the number of characters from a c-string value ;;
	s 		[c-string!]			;; c-string value ;;
	return: [integer!]
	/local base
][
	base: s
	while [s/1 <> null-char][s: s + 1]
	as-integer s - base 		;-- do not count the terminal zero
]

***-on-quit: func [status [integer!]][	;-- global exit handler
	;TBD: insert runtime error handler here
	quit status
]