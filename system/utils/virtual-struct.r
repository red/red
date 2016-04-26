REBOL [
	Title:    "Red/System struct! datatype replacement library"
	Author:   "Nenad Rakocevic"
	File: 	  %virtual-struct.r
	Tabs:	 4
	Rights:   "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License:  "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Requires: %int-to-bin.r
	Purpose:  "Migrate code dependent on struct! native datatype to /Core"
	Usage:	  {
		Replace:
			make struct! [...]	=>	make-struct [...]
			make struct! none	=>	make-struct none
			third <struct!>		=>	form-struct <struct!>
			struct? <struct!>	=>	struct? <struct!>		(no changes)
			
		Members read/write access:
			All members are accessed the same way as with native struct!.
			No changes required.
	}
	Comments: {
		A closer result could be achieved using a port scheme instead of
		an object to encapsulate data.
	}
]

virtual-struct!: context [
	alignment: 4									;-- default struct members alignement in bytes
	
	base-class: context [
		__vs-type: struct!
		__vs-spec: none
	]

	pad: func [buf [any-string!] n [integer!] /local mod][
		unless any [
			empty? buf
			zero? mod: (length? buf) // n
		][	
			head insert/dup tail buf null n - mod
		]
	]
	
	set 'struct? func [
		"Returns TRUE if the argument is a virtual struct!."
		value [any-type!]		"value to test"
		/local type
	][
		to logic! all [
			object? value
			type: in value '__vs-type
			struct! = get type
		]
	]

	set 'make-struct func [
		"Returns a new virtual struct! value built from a spec block."
		spec  [block! object!]	"specification block (same as for struct!)"
		data  [block! none!]	"none or block of initialization values"
		/local action obj specs
	][
		obj: either object? spec [
			make spec []
		][
			specs: copy [__vs-spec: spec]
			foreach [name type] spec [append specs to set-word! name]
			append specs none
			make base-class specs
		]
		
		if data [
			specs: skip first obj 3					;-- skip over: self, __vs-type, __vs-spec
			until [
				set in obj specs/1 data/1
				data: next data
				tail? specs: next specs
			]
		]	
		obj
	]

	set 'form-struct func [
		"Serialize a virtual struct! and returns a binary! value."
		obj [object!]			"virtual struct! value"
		/with					"provide a custom members alignment"
			n [integer!]		"new alignment value in bytes"
		/local out type members value
	][
		unless all [
			type: in obj '__vs-type
			struct! = get type
		][
			make error! "invalid virtual struct! value"
		]
		out: make binary! 4 * length? members: skip first obj 3		;-- raw guess
		n: any [n alignment]
		
		foreach name members [
			type: second find obj/__vs-spec name
			value: get in obj name
			
			append out switch/default type/1 [
				char 	 [to-bin8   any [value 0]]
				short	 [pad out 2 to-bin16  any [value 0]]
				int		 [pad out 4 to-bin32  any [value 0]]
				char!	 [to-bin8   any [value 0]]
				integer! [pad out 4 to-bin32  any [value 0]]
				decimal! [pad out 4 #{0000000000000000}]	;-- placeholder
			][
				make error! join "datatype not supported: " mold type/1
			]
		]	
		out
	]
]