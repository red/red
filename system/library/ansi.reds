Red/System [
	Title:   "ANSI C Library Binding"
	Author:  [ "Kaj de Vos" "Bruno Anselme" ]
	EMail:   "be.red@free.fr"
	File:    %ansi.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Purpose: {
		All functions definitions imported from Kaj's ANSI.reds binding for future compliance.
		Should be replaced by a complete CLib binding for Red/System.
		Full updated of this Ansi binding can be found here : http://red.esperconsultancy.nl/Red-C-library/
	}
]

; FPU configuration
; All exceptions need to be disabled when entering C functions

#if target = 'IA-32 [
	system/fpu/mask/overflow: on
	system/fpu/mask/underflow: on
	system/fpu/mask/zero-divide: on
	system/fpu/mask/invalid-op: on
	system/fpu/update
]

;-- snippet from Kaj's ANSI binding

#define variant!				integer!
#define opaque!					[struct! [dummy [variant!]]]
handle!:						alias opaque!
#define as-handle				[as handle! ]
#define binary!					[pointer! [byte!]]
#define as-binary				[as binary! ]

handle-reference!:				alias struct! [value [handle!]]
binary-reference!:				alias struct! [value [binary!]]
string-reference!:				alias struct! [value [c-string!]]

#define none?					[null = ]

#define free-any				[free as-binary ]

#define size!					integer!
file!:							alias opaque!

argument-list!:					alias struct! [item [integer!]]


#import [LIBC-file cdecl [
	; Memory management

	make: "calloc" [						"Allocate and return zero-filled memory."
		chunks			[size!]
		size			[size!]
		return:			[binary!]
	]
	resize: "realloc" [						"Resize and return allocated memory."
		memory			[binary!]
		size			[size!]
		return:			[binary!]
	]

	; File input/output

	open: "fopen" [							"Open file."
		name			[c-string!]
		mode			[c-string!]
		return:			[file!]
	]
	format-any: "sprintf" [					"Format arguments as string."
		[variadic]
		; string		[c-string!]			"WARNING: must be big enough!"
		; format		[c-string!]
		;	value		[variant!]
		;	...
		return:			[integer!]			"Result length or < 0"
	]
	flush-file: "fflush" [					"Flush file(s)."
		file			[file!]				"NULL for all streams"
		return:			[integer!]			"0 or EOF"
	]
	close-file: "fclose" [					"Close file."
		file			[file!]
		return:			[integer!]			"0 or EOF"
	]

	file-tail: "feof" [						"End-of-file status."
		file			[file!]
		return:			[integer!]
	]
	file-error: "ferror" [					"File status."
		file			[file!]
		return:			[integer!]
	]
	clear-status: "clearerr" [				"Clear file status."
		file			[file!]
	]
	_write-array: "fwrite" [				"Write binary array to file."
		array			[handle!]
		size			[size!]
		entries			[size!]
		file			[file!]
		return:			[size!]				"Chunks written"
	]
	read-array: "fread" [					"Read binary array from file."
		array			[handle!]
		size			[size!]
		entries			[size!]
		file			[file!]
		return:			[size!]				"Chunks read"
	]

	; String processing

	append-string: "strcat" [
		target		[c-string!]
		source		[c-string!]
		return:		[c-string!]
	]
	_copy-string: "strcpy" [				"Copy string including tail marker, return target."
		target			[c-string!]
		source			[c-string!]
		return:			[c-string!]
	]
	find-string: "strstr" [					"Search for sub-string."
		string			[c-string!]
		substring		[c-string!]
		return:			[c-string!]
	]
]
]

; Higher level interface

file-tail?: function ["End-of-file status."
	file			[file!]
	return:			[logic!]
][
	as-logic file-tail file
]
file-error?: function ["File status."
	file			[file!]
	return:			[logic!]
][
	as-logic file-error file
]
copy-string: function ["Copy string including tail marker, return target."
	source			[c-string!]
	target			[c-string!]
	return:			[c-string!]
][
	_copy-string target source
]

