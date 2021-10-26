Red [
	Title:	 "Red run-time debugging and helping tools"
	Author:	 "Nenad Rakocevic"
	File:	 %tools.red
	Tabs:	 4
	Rights:	 "Copyright (C) 2021 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system/tools: context [
	fun-stk:   make block! 10
	code-stk:  make block! 10
	expr-stk:  make block! 10
	watching:  make block! 10
	profiling: make block! 10
	
	base: none
	indent: 0
	active?: no
	
	options: context [
		show-stack?:	no
		show-parents?:	no
		show-locals?:	no
		stack-indent?:	no
		detailed?:		yes
		count-types:	make typeset! [function! action! native! op!]
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
		unless empty? fun-stk [prin lf]
		indent: 0
		foreach frame head expr-stk [
			unless integer? frame [
				forall frame [
					prin "Stack: "
					if options/stack-indent? [loop indent [prin "  "]]
					print mold/part/flat first frame 50
					if head? frame [indent: indent + 1]
				]
			]
		]
		prin lf
	]
	
	show-watching: function [][
		foreach w watching [print ["Watch:" mold w ":" mold/flat/part get/any w 60]]
		unless empty? watching [print lf]
	]
	
	do-command: function [event [word!] /extern active?][
		if value? 'ask [								;-- `ask` needs a console sub-system
			do [										;-- prevents `ask` from being compiled
				until [
					cmd: trim ask "debug> "
					case [
						cmd = #":" [
							print ["==" mold get/any load next cmd]
						]
						find "+-" cmd/1 [
							mode?: cmd/1 = #"+"
							switch first list: load/all next cmd [
								watch w [
									list: next list
									either mode? [append watching list][
										foreach w list [try [remove find watching to-word w]]
									]
								]
								parents p [options/show-parents?: mode?]
								stack   s [options/show-stack?:   mode?]
								locals  l [options/show-locals?:  mode?]
								indent  i [options/stack-indent?: mode?]
							]
						]
						'else [
							unless empty? list: load/all cmd [
								switch list/1 [
									parents p	[show-parents event]
									stack s		[show-stack]
									next n		[]
									continue c  [active?: no cmd: ""]
									q			[halt]
								]
							]
						]
					]
					empty? cmd
				]
			]
		]
	]

	debugger: function [
		event [word!]
		code  [block! paren! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]									;-- current frame start, top
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
			error [active?: yes]						;-- forces debug console activation
			init end  [
				clear fun-stk
				clear code-stk
				clear expr-stk: head expr-stk
				base: none
				indent: 0
				if event = 'end [active?: no]
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
			show-watching
			if options/show-parents? [show-parents event]
			if options/show-stack? [show-stack]
			do-command event
			if event = 'error [active?: no]
		]
	]
	
	dumper: function [
		event [word!]
		code  [block! paren! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]									;-- current frame start, top
	][
		unless idx [idx: all [code index? code]]
		print [event idx mold/part/flat :value 20 frame]
	]
	
	tracer: function [
		event [word!]
		code  [block! paren! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]									;-- current frame start, top
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
	
	profiler: function [
		event [word!]
		code  [block! paren! none!]
		value [any-type!]
		ref	  [any-type!]
		frame [pair!]									;-- current frame start, top
		/extern profiling
	][
		switch event [
			call   [
				if all [options/count-types find options/count-types type? :value][
					repend fun-stk [ref now/precise]
					either pos: find/only/skip profiling ref 3 [
						pos/2: pos/2 + 1
					][
						repend profiling [ref 1 0]
					]
				]
			]
			return [
				unless empty? fun-stk [
					entry: skip tail fun-stk -2
					pos: find/only/skip profiling first entry 3
					pos/3: pos/3 + difference now/precise entry/2
					clear entry
				]
			]
			init [
				clear profiling
				clear fun-stk
			]
			end [
				sort/skip/reverse/compare profiling 3 2
				rank: 1
				foreach [name cnt duration] profiling [
					print [pad append copy "#" rank 4 pad name 16 #"|" pad cnt 10 #"|" pad duration 10]
					rank: rank + 1
				]
			]
		]
	]
	
	set 'trace   func [code [any-type!]][do/trace :code :tracer]
	set 'debug   func [code [any-type!]][do/trace :code :debugger]
	set 'profile func [code [any-type!]][do/trace :code :profiler]
]
