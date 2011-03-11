REBOL [
	Title:   "Red/System code emitter base object"
	Author:  "Nenad Rakocevic"
	File: 	 %target-class.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

target-class: context [
	target: little-endian?: struct-align: ptr-size: void-ptr: none
	compiler: none									;-- just a short-cut
	verbose:  0										;-- logs verbosity level
	
	comparison-op: [= <> < > <= >=]
	
	opp-conditions: [
	;-- condition ------ opposite condition --
		overflow?		 not-overflow?
		not-overflow?	 overflow?			
		=				 <>
		<>				 =
		even?			 odd?
		odd?			 even?
		<				 >=
		>=				 <
		<=				 >
		>				 <=
	]
	
	opposite?: func [cond [word!]][
		first select/skip opp-conditions cond 2
	]

	align-to: func [value [integer!] size [integer!]][
		either zero? value // size [value][
			and value + size negate size
		]
	]

	to-bin8: func [v [integer!]][to char! 256 + v and 255]

	to-bin16: func [v [integer!]][reverse skip debase/base to-hex v 16 2]	;TBD: add big-endian support

	to-bin32: func [v [integer!]][reverse debase/base to-hex v 16]	;TBD: add big-endian support
	
	power-of-2?: func [n [integer!]][if zero? n - 1 and n [log-2 n]]

	emit: func [bin [binary! char! block!]][
		append emitter/code-buf bin
	]
	
	emit-reloc-addr: func [spec [block!]][
		append spec/3 emitter/tail-ptr					;-- save reloc position
		emit void-ptr									;-- emit void addr, reloc later		
		unless empty? emitter/chunks/queue [				
			append/only 								;-- record reloc reference
				second last emitter/chunks/queue
				back tail spec/3					
		]
	]

	emit-variable: func [
		name [word!] gcode [binary!] lcode [binary! block!] 
		/local offset
	][
		either offset: select emitter/stack name [
			if any [								;-- local variable case
				offset < -128
				offset > 127
			][
				print "#code generation error: overflow in emit-variable"
			]
			offset: skip debase/base to-hex offset 16 3
			either block? lcode [
				emit reduce bind lcode 'offset
			][
				emit lcode
				emit offset
			]
		][											;-- global variable case
			emit gcode
			emit-reloc-addr emitter/symbols/:name
		]
	]
]