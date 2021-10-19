Red []

;#include %../environment/console/CLI/input.red


event-handlers: context [
	fun-stk:  make block! 10
	code-stk: make block! 10
	expr-stk: make block! 10
	base: none
	indent: 0
	active?: no
	
	options: context [
		show-stack?:	yes
		show-parents?:	yes
		show-locals?:	yes
		detailed?:		yes
		flat-trace?:	no
	]

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
	
	show-context: function [ctx [function! object!]][
		foreach w words-of :ctx [
			prin [
				"  >"
				pad mold :w 10
				#":" mold/flat/part try [get/any :w] 60
			]
			either find [none true false unset] :w [print " (word!)"][prin lf]
		]
	]
	
	show-parents: function [event [word!]][
		collect-calls list: make block! 10
		unless empty? fun-stk [
			remove/part list find list first first skip tail fun-stk pick -2x-1 event = 'call
		]
		foreach [w pos] reverse/skip list 2 [
			if all [not unset? get/any w function? get/any w][
				print ["Call:" w]
				if options/show-locals? [show-context get :w]
			]
		]
	]
	
	show-stack: function [][
		;foreach entry fun-stk [print ["Call:" mold/only/flat/part entry 72]]
		unless empty? fun-stk [prin lf]
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
		prin lf
	]

	debugger: function [
		event [word!]
		code  [block! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]				;-- current frame start, top
		/extern base expr-stk active?
		/local out pos len entry
	][
		unless base [base: frame/1]
		
		switch event [
			fetch [
				if :value = @stop [active?: yes]
				if :value = @go   [active?: no]
			]
			enter [
				append/only code-stk split mold/only/flat code space
				unless empty? head expr-stk [
					append expr-stk index? expr-stk
					expr-stk: tail expr-stk
				]
			]
			exit [
				take/last code-stk
				unless head? expr-stk [
					idx: first pos: find/reverse tail expr-stk integer!
					clear pos
					expr-stk: at head expr-stk idx
				]
			]
			open [
				append/only expr-stk reduce [:value]
			]
			push [
				either find [set-word! set-path!] type?/word :value [
					append/only expr-stk reduce [:value]
				][
					unless empty? expr-stk [append/only last expr-stk :value]
				]
			]
			prolog [append/only fun-stk last expr-stk]
			epilog [unless empty? fun-stk [take/last fun-stk]]
			set 
			return [
				set/any 'entry take/last expr-stk
				if all [active? event = 'set][print ["Word:" to lit-word! :entry/1]]
				unless empty? expr-stk [append/only last expr-stk :value]
			]
			error [active?: yes]						;-- force debugger on
			init end  [
				clear fun-stk
				clear code-stk
				clear expr-stk: head expr-stk
				base: none
				indent: 0
			]
		]
		if all [active? not find [init end enter exit fetch prolog epilog] event][
			if any-function? :value [value: type? :value]
			print ["----->" uppercase mold event mold/part/flat :value 60]
			if code [
				print ["Input:" set [out pos len] mold-mapped code out]
				loop 7 + pos [prin space]
				loop len [prin #"^^"]
				prin lf
			]
			if options/show-parents? [show-parents event]
			if options/show-stack? [show-stack]
			if event = 'error [exit]					;-- don't enter console on thrown errors
			until [
				entry: trim ask "debug>"
				if cmd: attempt [to-word entry][
					if cmd = 'q [halt]
				]
				empty? entry
			]
		]
	]
	
	dumper: function [
		event [word!]
		code  [block! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]				;-- current frame start, top
	][
		unless idx [idx: all [code index? code]]
		print [event idx mold/part/flat :value 20 frame]
	]
	
	tracer: function [
		event [word!]
		code  [block! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]				;-- current frame start, top
		/extern indent
	][
		either find [init end] event [indent: 0][		;-- eat END event too
			unless find [enter exit fetch] event [
				if event = 'open [indent: indent + 1]
				if any-function? :value [value: type? :value]
				prin "->"
				loop indent [prin space]
				prin [uppercase mold event mold/part/flat :value 60]
				prin either ref [rejoin ["  (" ref #")" lf]][lf]
				if event = 'return [indent: indent - 1]
			]
		]
	]
]

debug: func [code [any-type!]][do/trace :code :event-handlers/debugger]

;do/trace %demo.red :event-handlers/tracer

;do/trace [print 1 + length? mold 'hello] :event-handlers/debugger
;quit

;do/trace [print 77 88 99] :event-handlers/tracer

;a: 4
;do/trace [either result: odd? a [print "ODD"][print "EVEN"]] :event-handlers/tracer

;fibo: func [n [integer!] return: [integer!]][
;	either n < 1 [0][either n < 2 [1][(fibo n - 2) + (fibo n - 1)]]
;]
;do/trace [print fibo 4] :event-handlers/tracer
;quit

;foo: function [a [integer!]][@stop print either result: odd? a ["ODD"]["EVEN"] @go result]
;bar: function [s [string!]][(length? s) + 'e make integer! foo 4]
;baz: function [][print bar "hello"]
;
;debug [baz]

