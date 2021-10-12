Red []

;#include %../environment/console/CLI/input.red


debugger: context [
	fun-stk:  make block! 10
	code-stk: make block! 10
	expr-stk: make block! 10
	base: none

	mold-mapped: function [code [block! paren!]][
		out: clear ""
		pos: 1
		len: 0
		idx: index? code

		code: head last code-stk
		append out #"["
		forall code [
			append out value: code/1
			unless tail? next code [append out space]
			if 60 < length? out [
				append clear at out 57 "..."
				break
			]
			if idx = index? code [len: length? value]
			if idx > index? code [pos: pos + 1 + length? value]
		]
		append out #"]"
		reduce [out pos len]
	]
	
	show-stack: function [][
		foreach entry fun-stk [print ["Calls:" mold/only/flat/part entry 72]]
		prin lf
		indent: 0
		foreach frame head expr-stk [
			unless integer? frame [
				forall frame [
					prin "Stack: "
					loop indent [prin "  "]
					print mold/part/flat first frame 50
					if head? frame [indent: indent + 1]
				]
			]
		]
	]

	tracer: function [
		event [word!]
		code  [block! none!]
		value [any-type!]
		frame [pair!]				;-- current frame start, top
		name  [word! none!]
		/extern expr-stk
		/local out pos len entry
	][
		unless base [base: frame/1]
		print ["Event:" uppercase mold event]
		
		switch event [
			enter	[
				append/only code-stk split mold/only/flat code space
				unless empty? expr-stk [
					append expr-stk length? expr-stk
					expr-stk: tail expr-stk
				]
			]
			exit	[
				if all [function? :value not empty? fun-stk][take/last fun-stk]
				take/last code-stk
				unless head? expr-stk [expr-stk: at head expr-stk take/last back expr-stk]
			]
			call	[
				append/only expr-stk reduce [:value]
			]
			push	[
				either find [set-word! set-path!] type?/word :value [
					append/only expr-stk reduce [:value]
				][
					unless empty? expr-stk [append/only last expr-stk :value]
				]
			]
			exec [
				if function? :value [append/only fun-stk last expr-stk]
			]
			set 
			return	[
				set/any 'entry take/last expr-stk
				if event = 'set [print ["Word:" to lit-word! :entry/1]]
				unless empty? expr-stk [append/only last expr-stk :value]
			]
		]
		unless find [enter exit] event [
			print ["Value:" mold/part/flat :value 40]
			;?? expr-stk
			;?? fun-stk
			print ["Input:" either code [set [out pos len] mold-mapped code out]["..."]]
			loop 7 + pos [prin space]
			loop len [prin #"^^"]
			prin lf
			show-stack
			until [
				entry: trim ask "^/debug>"
				if cmd: attempt [to-word entry][
					if cmd = 'q [halt]
				]
				empty? entry
			]
		]
	]
	
	logger: function [
		event [word!]
		code  [block! none!]
		value [any-type!]
		frame [pair!]				;-- current frame start, top
	][
		switch event [
			enter	[append/only code-stk split mold/only code space]
			exit	[take/last code-stk]
			call	[append/only expr-stk idx: index? code]
			return	[idx: take/last expr-stk]
		]
		unless idx [idx: all [code index? code]]
		print [event idx mold/part/flat :value 20 frame]
	]
]

;do/trace %demo.red :debugger/tracer

;do/trace [print 1 + length? mold 'hello] :debugger/tracer


;do/trace [print 77 88 99] :debugger/tracer

;a: 4
;do/trace [either result: odd? a [print "ODD"][print "EVEN"]] :debugger/tracer

foo: function [a [integer!]][print either result: odd? a ["ODD"]["EVEN"] result]
bar: function [s [string!]][(length? s) + to-integer foo 4]
baz: function [][print bar "hello"]
do/trace [baz] :debugger/tracer

