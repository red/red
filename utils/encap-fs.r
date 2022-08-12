REBOL [
	Title: "Encap virtual filesystem"
	Date: 21/09/2009
]

encap-fs: context [
	verbose: 0
	cache: none
	root: system/script/path
	base: none
	text-files: [%.r %.red %.reds %.txt]

	get-cache: func [file][
		if verbose > 0 [print ["[encap-fs] cache read :" mold file]]
		if verbose > 1 [print ["[encap-fs] translated :" mold join root file]]
		all [
			verbose > 0
			none? select cache file
			print ["not in cache: " mold file]
		]
		if base [file: base/:file]
		
		either file [
			select cache file
		][
			make error! join "Cannot access : " file
		]
	]
	
	set 'encap? to-logic select system/components 'decap

	either encap? [
		set 'set-cache 	none
		set 'set-cache-base func [path [file! none!]][base: path]
		set 'do-cache	func [file [file!]][do any [get-cache file file]]
		set 'load-cache func [file [file!]][
			either block? file: any [get-cache file file][
				file
			][
				load as-string file
			]
		]
		set 'load-cache-binary func [file [file!]][
			load any [get-cache file file]
		]
		set 'read-cache func [file [file!]][any [get-cache file read file]]
		set 'read-binary-cache func [file [file!]][any [get-cache file read/binary file]]
		set 'exists?-cache func [file [file!]][to logic! find cache file]
	][
		set 'set-cache func [list [block!] /local out cdir emit rule name stk][
			out: copy "REBOL []^/encap-fs/cache: ["
			cdir: %""
			stk: reduce [copy cdir]
			emit: func [file /local filename][
				file: mold filename: file
				insert tail out "^/^-"
				insert tail out file
				insert tail out #" "
				either find/only text-files suffix? file [
					insert tail out "^-^-"
					insert tail out mold read filename
				][
					insert tail out mold read/binary filename
				]
				
			]
			rule: [
				some [
					set name [file! | path! | word!] (
						if not file? :name [name: do reduce [:name]]
						either slash = last name [
							append stk copy append cdir name
						][
							emit join cdir name
						]
					)[
						into rule (
							remove back tail stk
							cdir: copy last stk
						) | none
					]
				]
			]
			parse list rule
			append out "^/]"
			out
		]
		set 'exists?-cache :exists?
		set 'set-cache-base none
		set 'do-cache func [file][do load file]
		set 'load-cache set 'load-cache-binary :load
		set 'read-cache :read
		set 'read-binary-cache func [file [file!]][read/binary file]
	]
]