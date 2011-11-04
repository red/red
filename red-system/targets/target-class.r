REBOL [
	Title:   "Red/System code emitter base object"
	Author:  "Nenad Rakocevic"
	File: 	 %target-class.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

target-class: context [
	target: little-endian?: struct-align: ptr-size: void-ptr: none ; TBD: document once stabilized
	default-align: stack-width: branch-offset-size: none		   ; TBD: document once stabilized
	
	on-global-prolog: none							;-- called at start of global code section
	on-global-epilog: none							;-- called at end of global code section
	on-finalize:	  none							;-- called after all sources are compiled
	
	compiler: 	none								;-- just a short-cut
	width: 		none								;-- current operand width in bytes
	signed?: 	none								;-- TRUE => signed op, FALSE => unsigned op
	last-saved?: no									;-- TRUE => operand saved in another register
	verbose:  	0									;-- logs verbosity level
	
	emit-casting: none								;-- just pre-bind word to avoid contexts issue
	
	comparison-op: [= <> < > <= >=]
	math-op:	   [+ - * / // ///]
	bitwise-op:	   [and or xor]
	bitshift-op:   [>> << -**]
	
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
	
	power-of-2?: func [n [integer! char!]][
		if all [
			n: to integer! n
			positive? n
			zero? n - 1 and n
		][
			to integer! log-2 n
		]
	]

	emit: func [bin [binary! char! block!]][
		if verbose >= 4 [print [">>>emitting code:" mold bin]]
		append emitter/code-buf bin
	]
	
	emit-reloc-addr: func [spec [block!]][
		append spec/3 emitter/tail-ptr				;-- save reloc position
		emit void-ptr								;-- emit void addr, reloc later		
		unless empty? emitter/chunks/queue [				
			append/only 							;-- record reloc reference
				second last emitter/chunks/queue
				back tail spec/3					
		]
	]

	emit-variable: func [
		name [word! object!] gcode [binary!] lcode [binary! block!] 
		/local offset
	][
		if object? name [name: compiler/unbox name]
		
		either offset: select emitter/stack name [
			if any [								;-- local variable case
				offset < -128
				offset > 127
			][
				compiler/throw-error "#code generation error: overflow in emit-variable"
			]
			offset: skip debase/base to-hex offset 16 3	; @@ just to-char ??
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
	
	get-width: func [operand type /local value][
		reduce [
			emitter/size-of? value: case [
				type 	[operand]
				'else 	[			
					value: first compiler/get-type operand
					either value = 'any-pointer! ['pointer!][value]
				]
			]
			value
		]
	]
	
	set-width: func [operand /type /local value][
		value: get-width operand type
		width: value/1
		signed?: emitter/signed? value/2
	]
	
	with-width-of: func [value body [block!] /alt /local old][
		old: width
		set-width compiler/unbox value
		do body
		width: old
		if all [alt object? value][emit-casting value yes]	;-- casting for right operand
	]
	
	implicit-cast: func [arg /local right-width][
		right-width: first get-width arg none
		
		if all [width = 4 right-width = 1][			;-- detect byte! -> integer! implicit casting
			arg: make object! [action: 'type-cast type: [integer!] data: arg]
			emit-casting arg yes					;-- type cast right argument
		]
	]
]