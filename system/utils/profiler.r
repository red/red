REBOL [
	Title:   "REBOL code profiling tool"
	Author:  "Nenad Rakocevic"
	File: 	 %profiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Usage: {
		1) Include it in your existing application:
		
				do %<path-to>/profiler.r
				profiler/set-active yes					;-- switches function patching on/off
		
		2) The profiler needs an object as input to patch all object's functions
		   for profiling using the 'make-profilable function:
		   
		   		my-app: make-profilable context [...]
		   		
		3) Run your application as usual.
		
		4) Print profiling report (from console or included in your app code):
		
				profiler/report
		   
		   You get a table with all profiled functions, calls count and elasped time.
		   By default, only the top 20 functions are reported, to print them all:
		   
		   		profiler/report/all
		   		
		   To sort results by count instead of elapsed time:
		   
		   		profiler/report/count
		   		profiler/report/all/count
		 
		 5) The profiler needs a fresh start for each run (stats clearing
		    has not been implemented yet, any taker?)
		    
		   
		 Hope it will help you improve your apps!
	}
	Example: {
		REBOL []
		
		do %profiler.r
		profiler/set-active yes		;-- just change it to NO for normal execution
		
		a: make-profilable context [
			foo: func [a /ref][wait (random 10) / 100 bar a + 1]
			bar: func [b][wait (random 10) / 100 b * 1 + 1 - 1]
			
			run: has [c][
				c: 0
				foreach i [1 2 3 4 5 6 7 8 9 0][
					c: c + foo i
					c: c + bar i
				]
				print c
			]
		]
		
		a/run
		profiler/report
		
		halt
	}
]

exportable: context [
	export: func [words [block!]][						;-- export argument words to global context
		foreach w words [set bind w system/words get :w]
	]
]

profiler: make exportable [

	;-- storage place for proxified functions
	store: make block! 400

	;-- property use to enable/disable the profiler without changing anything else
	active?: yes
	
	;-- temporary stack for nested objects used by 'make-profilable
	obj-stack: make block! 1
	
	;-- in order to avoid collision with function's arguments and refinements, only
	;-- non-typable words are used as local variables in the proxy function. The 
	;-- following definitions are just handy shortcuts
	
	_stat: to word! "<s>"								;-- superman's logo ;)
	_arg:  to word! "<a>"
	_cmd:  to word! "<c>"
	_fun:  to word! "<f>"
	_path: to word! "<p>"
	_time: to word! "<t>"
	_ret:  to word! "<r>"
	
	set_stat: to set-word! _stat
	set_arg:  to set-word! _arg
	set_cmd:  to set-word! _cmd
	set_fun:  to set-word! _fun
	set_path: to set-word! _path
	get_path: to get-word! _path
	_arg1:	  to path! reduce [_arg 1]


	clean: func [spec [block!]][
		;-- remove everything we don't need in function's spec block
		remove-each item spec [
			not find [word! refinement! get-word! lit-word!] type?/word item
		]
		;-- remove all local variables
		clear find spec /local
		
		;-- duplicate all refinements in spec, by adding a word! version 
		;-- just after the refinement! value (refinements have no binding)
		forall spec [
			if refinement? spec/1 [
				insert at spec 2 to word! spec/1
				spec: next spec
			]
		]
		spec
	]

	proxify: func [fun [function!] /local spec][
		;-- replace all original function local variables by the ones for the proxy
		spec: copy first :fun
		clear find spec /local
		append spec /local
		repend spec [_stat _arg _cmd _fun _path _time _ret]
				
		;-- build and return the new proxy function
		make function! spec compose/deep [
		
			;-- store stats in literal local block (call depth, calls count, time)
			(set_stat) [(copy [0 0 0:0])]
			
			;-- increment calls count
			(to set-path! reduce [_stat 2]) (to path! reduce [_stat 2]) + 1		
			
			;-- init command block used to rebuild the called function (args + refinements)
			(set_cmd) head clear next ([copy [_]])		;-- place-holder for the function name (word! or path!)
			
			;-- get a reference on proxified function, to be able to call it
			(set_fun) first [(:fun)]
			
			;-- get a cleaned up copy of origin function (no local variables)
			(set_arg) copy [(clean copy spec)]

			;-- collect the mandatory function arguments in command block
			while [system/words/all [not tail? (_arg) not refinement? (_arg1)]][
				append (_cmd) to-get-word (_arg1)
				(set_arg) next (_arg)
			]
			
			;-- collect the optional function arguments and refinements (if any)
			unless tail? (_arg) [
				until [
					either refinement? (_arg1) [
						;-- skip refinement! value and use the duplicate word! value (avoids binding issues)
						(set_arg) next (_arg)
						
						;-- test if refinement has been invoked by the caller
						either system/words/get (_arg1) [
						
							;-- if first refinement, prepare a path for command block
							unless (get_path) [(set_path) to path! (to lit-word! _fun)]
							
							;-- collect refinement in command block
							append (get_path) (_arg1)
							(set_arg) next (_arg)
						][
							;-- refinement not invoked, fast forward to next refinement
							;-- (skipping dependent arguments) or to end
							(set_arg) system/words/any [
								find (_arg) refinement!
								tail (_arg)
							]
						]
					][
						;-- collect optional argument in command block
						append (_cmd) to-get-word (_arg1)
						(set_arg) next (_arg)
					]
					tail? (_arg)
				]
			]
			
			;-- set first value of command block to either a path (with refinements)
			;-- or a word (no refinements)
			(to set-path! reduce [_cmd 1]) system/words/any [(get_path) (to lit-word! _fun)]

			;-- increase depth counter before the function call
			(to set-path! reduce [_stat 1]) (to path! reduce [_stat 1]) + 1
			
			;-- mark start time
			(to set-word! _time) now/time/precise
			
			;-- invoke the original function, passing all required arguments and refinements
			system/words/set/any (to lit-word! _ret) do (_cmd)
			
			;-- if recursive call (depth > 1), don't add the time
			if (to path! reduce [_stat 1]) = 1 [
				(to set-path! reduce [_stat 3])
					(to path! reduce [_stat 3]) + now/time/precise - (_time)
			]
			;-- function call done so decrease depth counter
			(to set-path! reduce [_stat 1]) (to path! reduce [_stat 1])  - 1
			
			;-- return invoked function last value
			system/words/get/any (to lit-word! _ret)
		]
	]
		
	set-active: func [
		"Enable or disable the patching of functions"
		mode [logic!]
	][
		active?: mode
	]
	
	make-profilable: func [
		"Make all functions in a given object usable for profiling"
		obj [object!]
		/all "Apply to nested objects too (use with caution)"
		/local
			value new
	][
		unless active? [return obj]
		
		foreach word next first obj [
			if function? value: get in obj word [
				unless find store :value [
					set in obj word new: proxify :value	;-- install profiler proxy function			
					repend store [:value word obj second :new]
				]
			]
			if system/words/all [
				all
				object? :value
				not find obj-stack :value
			][
				append obj-stack :value
				make-profilable :value
				remove back tail obj-stack
			]
		]
		obj												;-- just a pass-thru
	]
	
	align: func [str [string!] cols [integer!]][
		head insert/dup tail str #" " cols - length? str
	]
	
	truncate: func [value [number!]][
		if integer? value [return value]
		value: mold value
		head clear skip find value #"." 3
	]
	
	print-table: func [data [block!] root [function! none!] /local ET line][
		ET: any [all [:root third second second :root ] data/3]
		ET: ET/second
		
		print [
			newline
			align "Function" 	 30
			align "Count" 		 10
			align "Elapsed Time" 20
			align "% of ET" 	 10
			newline
			line: head insert/dup make string! 72 #"-" 72
		]
		foreach [name cnt time] data [
			print [
				align mold name 30
				align mold cnt 10
				align mold time 20
				align truncate (time/second / ET * 100) 10
			]
		]
		print [line newline]
	]
	
	report: func [
		"Print a full pretty-printed report in console"
		/only "Report only for selected object"
			object [object!]
		/all  "Print report for all functions"
		/with "Provide a root function for % of ET calculation"
			root [function!]
		/count "Sort report table by calls count"
	][
		unless active? [exit]
		
		data: make block! 100
		foreach [old name obj body] store [
			if any [not only obj = object][
				repend data [name body/2/2 body/2/3]
			]
		]
		data: sort/skip/compare/reverse data 3 pick [2 3] to logic! count
		unless all [data: copy/part data 3 * 20]		;-- top 20 only by default
		
		print-table data :root
	]
	
	export [make-profilable]
]

; profiler: make-profilable profiler					;-- include profiler's code in profiling