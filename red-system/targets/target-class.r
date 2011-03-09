REBOL [
	Title:   "Red/System code emitter base object"
	Author:  "Nenad Rakocevic"
	File: 	 %target-class.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
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

	to-bin8: func [value [integer!]][
		to char! either negative? value [256 + value][value]
	]

	to-bin16: func [value [integer!] /local byte][		;TBD: add big-endian support
		value: skip debase/base to-hex value 16 2
		byte: value/1
		value/1: to char! value/2
		value/2: to char! byte
		value
	]

	to-bin32: func [value [integer!] /local new][		;TBD: add big-endian support
		value: debase/base to-hex value 16
		new: copy #{00000000}
		new/1: to char! value/4
		new/2: to char! value/3
		new/3: to char! value/2
		new/4: to char! value/1
		new
	]
	
	power-of-2?: func [n /local p][
		either n = shift/left 1 p: to integer! log-2 n [p][none]
	]

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