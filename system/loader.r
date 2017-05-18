REBOL [
	Title:   "Red/System source program loader"
	Author:  "Nenad Rakocevic"
	File: 	 %loader.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

do-cache %lexer.r

loader: make-profilable context [
	verbose: 	  0
	include-list: make hash! 20
	ssp-stack: 	  make block! 5
	defs:		  make block! 100

	hex-chars: 	  charset "0123456789ABCDEF"
	ws-chars: 	  charset " ^M^-"
	ws-all:		  union ws-chars charset "^/"
	hex-delim: 	  charset "[]()/"
	non-cbracket: complement charset "}^/"

	scripts-stk:  make block! 10
	current-script: none
	line: none

	throw-error: func [err [string! block!]][
		print [
			"*** Loading Error:"
			either word? err [
				join uppercase/part mold err 1 " error"
			][reform err]
			"^/*** in file:" mold current-script
			"^/*** at line:" line
		]
		compiler/quit-on-error
	]

	count-slash: func [file /local cnt][
		cnt: 0
		parse file [some [slash (cnt: cnt + 1) | skip]]
		cnt
	]

	pop-encap-path: func [cnt [integer!]][
		path: tail encap-fs/base
		loop cnt + 1 [path: find/reverse path slash]
		clear next path
	]

	init: does [
		clear include-list
		clear defs
		clear ssp-stack
		clear scripts-stk
		current-script: line: none
		insert defs <no-match>					;-- required to avoid empty rule (causes infinite loop)
	]
	
	relative-path?: func [file [file!]][
		not find "/~" first file
	]

	included?: func [file [file!]][
		all [
			encap?
			encap-fs/base
			slash <> first file
			file: join encap-fs/base file
		]
		attempt [file: get-modes file 'full-path]
		either find include-list file [true][
			append include-list file
			false
		]
	]

	push-system-path: func [file [file!] /local path][
		append ssp-stack system/script/path
		if relative-path? file [file: get-modes file 'full-path]
		path: split-path file
		system/script/path: path/1
		path/2
	]
	
	pop-system-path: does [
		system/script/path: take/last ssp-stack
	]
	
	check-macro-parameters: func [args [paren!]][
		unless parse args [some word!][
			throw-error ["only words can be used as macro parameters:" mold args]
		]
		unless empty? intersect to block! args compiler/keywords-list [
			throw-error ["keywords cannot be used as macro parameters:" mold args]
		]
	]

	check-marker: func [src [string!] /local pos][
		unless parse/all src [any ws-all "Red/System" any ws-all #"[" to end][
			throw-error "not a Red/System source program"
		]
	]

	check-condition: func [type [word!] payload [block!]][
		if any [
			not any [word? payload/1 lit-word? payload/1]
			not in job payload/1
			all [type <> 'switch not find [= <> < > <= >= contains] payload/2]
		][
			throw-error rejoin ["invalid #" type " condition"]
		]
		either type = 'switch [
			any [
				select payload/2 job/(payload/1)
				select payload/2 #default
			]
		][
			payload: either payload/2 = 'contains [
				compose/deep [all [(payload/1) find (payload/1) (payload/3)]]
			][
				copy/part payload 3
			]
			do bind payload job
		]
	]
	
	copy-deep: func [s [series!]][
		s: copy/deep s
		forall s [
			case [
				find [path! set-path! lit-path!] type?/word s/1 [
					s/1: copy/deep s/1
				]
				any [block? s/1 paren? s/1][
					s/1: copy-deep s/1
				]
			]
		]
		s
	]

	inject: func [args [block!] 'macro s [block!] e [block!] /local rule pos i type value path][
		unless equal? length? args length? s/2 [
			throw-error ["invalid macro arguments count in:" mold s/2]
		]	
 		macro: copy-deep macro
		parse :macro rule: [
			some [
				pos: set path [path! | set-path!] (
					forall path [
						if i: find args path/1 [
							value: pick s/2 index? :i
							change/part path value 1
						]
					]
				)
				| pos: [
					word! 		(type: word!) 
					| set-word! (type: set-word!)
					| get-word! (type: get-word!)
				] (
					if i: find args to word! pos/1 [
						value: pick s/2 index? :i
						change/only pos either type = word! [
							value						;-- word! => pass-thru value
						][
							all [
								path: find [path! set-path!] type?/word value
								type: find [word! set-word!] to word! type
								type: get pick head path index? type
							]
							to type value				;-- get/set => convert value
						]
					]
				)
				| into rule
				| skip
			]
		]
		either paren? :macro [
			change/part/only s macro e
		][
			change/part s macro e
		]
	]

	expand-string: func [src [string! binary!] /local value s e c lf-count ws i prev ins?][
		if verbose > 0 [print "running string preprocessor..."]

		line: 1										;-- lines counter
		lf-count: [lf s: (
			if prev <> i: index? s [				;-- workaround to avoid writing more complex rules
				prev: i
				line: line + 1
				if ins? [s: insert s rejoin [" #L " line " "]]
			]
		)] 
		ws:	[ws-chars | (ins?: yes) lf-count]
		braces: ["{" any [(ins?: no) lf-count | non-cbracket] "}"]

		parse/all/case src [						;-- non-LOAD-able syntax preprocessing
			any [
				(c: 0)
				#";" to lf
				| {#"^^} skip thru {"}
				| {"} thru {"}
				| "{" any [(ins?: no) lf-count | braces | non-cbracket] "}"
				| ws s: ">>>" e: ws (
					e: change/part s "-**" e		;-- convert >>> to -**
				) :e
				| [hex-delim | ws]
				s: copy value some [hex-chars (c: c + 1)] #"h"	;-- literal hexadecimal support	
				e: [hex-delim | ws-all | #";" to lf | end] (
					either find [2 4 8] c [
						e: change/part s to integer! to issue! value e
					][
						throw-error ["invalid hex literal:" copy/part s 40]
					]
				) :e
				| (ins?: yes) lf-count
				| skip
			]
		]
	]

	expand-block: func [
		src [block!]
		/own
		/local blk rule name value args s e opr then-block else-block cases body p
			saved stack header mark idx prev enum-value enum-name enum-names line-rule recurse
	][
		if verbose > 0 [print "running block preprocessor..."]
		stack: append/only clear [] make block! 100
		append stack/1 1							;-- insert root header starting size
		line: 1

		store-line: [			
			header: last stack				
			idx: index? s
			mark: to pair! reduce [line idx]
			either all [
				prev: pick tail header -1
				pair? prev
				prev/2 = idx 						;-- test if previous marker is at the same series position
			][
				change back tail header mark		;-- replace last marker by a more accurate one
			][			
				append header mark					;-- append line marker to header
			]
		]
		line-rule: [
			s: #L set line integer! e: (
				s: remove/part s 2
				new-line s yes
				do store-line
			) :s
		]
		recurse: [
			saved: reduce [s e]
			parse/case value rule: [
				some [defs | into rule | skip] 		;-- resolve macros recursively
			]
			set [s e] saved
		]
		parse/case src blk: [
			s: (do store-line)
			some [
				defs								;-- resolve definitions in a single pass
				| s: #define set name word! (args: none) [
					set args paren! set value [block! | paren!]
					| set value skip
				  ] e: (
				  	if paren? args [check-macro-parameters args]
					if verbose > 0 [print [mold name #":" mold value]]
					if find compiler/definitions name [
						print ["*** Warning:" name "macro in R/S is redefined"]
					]
					append compiler/definitions name
					case [
						args [
							do recurse
							rule: copy/deep [s: _ paren! e: (e: inject _ _ s e) :s]
							rule/5/3: to block! :args
							rule/5/4: :value
						]
						block? value [
							do recurse
							rule: copy/deep [s: _ e: (e: change/part s copy/deep _ e) :s]
							rule/4/5: :value
						]
						'else [
							if word? value [value: to lit-word! value]
							rule: copy/deep [s: _ e: (e: change/part s _ e) :s]
							rule/4/4: :value
						]
					]
					rule/2: to lit-word! name

					either tag? defs/1 [remove defs][append defs '|]
					append defs rule
					remove/part s e
				) :s
				| s: #enum word! set value skip e: (
					either block? value [
						saved: reduce [s e]
						parse value [
							any [
								any line-rule [
									[word! | some [set-word! any line-rule][integer! | word!]]
									| skip
								]
							]
						]
						set [s e] saved
					][
						throw-error ["invalid enumeration (block required!):" mold value]
					]
					s: e
				) :s
				| s: #include set name file! e: (
					either included? name [
						s: remove/part s e			;-- already included, drop it
					][
						if verbose > 0 [print ["...including file:" mold name]]
						value: either all [encap? own][
							mark: tail encap-fs/base
							process/short/sub/own name
						][
							name: push-system-path name
							process/short/sub name
						]
						e: change/part s skip value 2 e	;-- skip Red/System header

						value: either all [encap? own not empty? mark][
							count-slash mark
						][
							0
						]
						name: system/script/path/:name
						
						insert e reduce [
							#pop-path value
							#script last scripts-stk	;-- put back the parent origin
						]
						insert s reduce [				;-- mark code origin
							#script name
						]
						append scripts-stk name
						current-script: name
					]
				) :s
				| s: #if set name word! set opr skip set value any-type! set then-block block! e: (
					either check-condition 'if reduce [name opr get/any 'value][
						change/part s then-block e
					][
						remove/part s e
					]
				) :s
				| s: #either set name word! set opr skip set value any-type! set then-block block! set else-block block! e: (
					either check-condition 'either reduce [name opr get/any 'value][
						change/part s then-block e
					][
						change/part s else-block e
					]
				) :s
				| s: #switch set name word! set cases block! e: (
					either body: check-condition 'switch reduce [name cases][
						change/part s body e
					][
						remove/part s e
					]
				) :s
				| s: #case set cases block! e: (
					either body: select reduce bind cases job true [
						change/part s body e
					][
						remove/part s e
					]
				) :s
				| s: #pop-path set value integer! e: (
					either all [encap? own][
						unless zero? value [pop-encap-path value]
					][
						pop-system-path
					]
					take/last scripts-stk
					s: remove/part s 2
				) :s
				| line-rule
				| s: issue! (
					if s/1/1 = #"'" [
						value: to integer! debase/base next s/1 16
						either value > 255 [
							throw-error ["unsupported literal byte:" next s/1]
						][
							s/1: to char! value
						]
					]
				)
				| p: [path! | set-path!] :p into [some [defs | skip]]	;-- process macros in paths
				
				| s: (if any [block? s/1 paren? s/1][append/only stack copy [1]])
				  [into blk | block! | paren!]			;-- black magic...
				  s: (
					if any [block? s/-1 paren? s/-1][
						header: last stack
						change header length? header	;-- update header size
						s/-1: insert copy s/-1 header	;-- insert hidden header
						remove back tail stack
					]
				  )
				| skip
			]
		]		
		change stack/1 length? stack/1				;-- update root header size	
		insert src stack/1							;-- return source with hidden root header
	]
	
	prefix-cache: func [file [file!] /local path][
		path: either empty? ssp-stack [system/script/path][first ssp-stack]
		path: skip system/script/path length? path
		secure-clean-path join path file
	]

	process: func [
		input [file! string! block!] /sub /with name [file!] /short /own
		/local src err path ssp pushed? raw cache? new
	][
		if verbose > 0 [print ["processing" mold either file? input [input][any [name 'in-memory]]]]
		
		cache?: all [
			encap?
			file? input
			any [
				exists?-cache input
				exists?-cache new: prefix-cache input
			]
		]
		if any [own cache?][raw: input]
		
		if with [									;-- push alternate filename on stack
			push-system-path join first split-path name %.
			pushed?: yes
		]

		if file? input [
			if find input %/ [ 						;-- is there a path in the filename?
				either encap? [
					raw: split-path input
					if encap-fs/base [append encap-fs/base raw/1]
					raw: raw/2
					push-system-path input
				][
					input: push-system-path input
				]
				pushed?: yes
			]
			
			if error? set/any 'err try [			;-- read source file
				src: as-string either any [cache? all [encap? own]][
					if all [cache? new][raw: new]
					read-binary-cache raw
				][
					read/binary input
				]
			][
				throw-error ["file access error:" mold input]
			]
		]
		unless short [
			current-script: case [
				file? input [input]
				with		[name]
				'else		[any [select input #script 'in-memory]]
			]
			append clear scripts-stk current-script
		]
		src: any [src input]
		if file? input [check-marker src]			;-- look for "Red/System" head marker
		
		unless block? src [
			expand-string src						;-- process string-level compiler directives
			if error? set/any 'err try [src: lexer/process as-binary src][	;-- convert source to blocks
				throw-error ["syntax error during LOAD phase:" mold disarm err]
			]
		]
		unless short [								;-- process block-level compiler directives
			src: either all [encap? own][
				expand-block/own src
			][
				expand-block src
			]
		]
		if pushed? [pop-system-path]
		src
	]
]