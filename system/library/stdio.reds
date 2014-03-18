Red/System [
	Title:   "Red/System stdio Binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %stdio.reds
	Rights:  "Copyright (c) 2013 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Purpose: {
		Stdio binding inspired from Kaj's ANSI.reds.
		Should be replaced by a complete common CLib binding for Red/System.
	}
]

#if target = 'IA-32 [
	system/fpu/mask/overflow: on
	system/fpu/mask/underflow: on
	system/fpu/mask/zero-divide: on
	system/fpu/mask/invalid-op: on
	system/fpu/update
]

stdio: context [
	#define file!     integer!
	#import [ LIBC-file cdecl [
		open-file: "fopen" [ "Open file"
			name        [c-string!]
			mode        [c-string!]
			return:     [file!]
		]
		flush-file: "fflush" [ "Flush file(s)"
			file        [file!] "NULL for all streams"
			return:     [integer!] "0 or EOF"
		]
		close-file: "fclose" [ "Close file"
			file        [file!]
			return:     [integer!] "0 or EOF"
		]
		file-tail:  "feof" [ "End-of-file status"
			file        [file!]
			return:     [integer!]
		]
		file-error: "ferror" [ "File status"
			file        [file!]
			return:     [integer!]
		]
		clear-status: "clearerr" [ "Clear file status"
			file        [file!]
		]
		write-file: "fwrite" [ "Write binary array to file"
			array       [byte-ptr!]
			size        [integer!]
			entries     [integer!]
			file        [file!]
			return:     [integer!] "Chunks written"
		]
		read-file: "fread" [ "Read binary array from file"
			array       [byte-ptr!]
			size        [integer!]
			entries     [integer!]
			file        [file!]
			return:     [integer!] "Chunks read"
		]
	]
	] ; #import

	file-tail?: function [ "End-of-file status"
		file          [file!]
		return:       [logic!]
	][
		as-logic file-tail file
	]

	file-error?: function [ "File status"
		file          [file!]
		return:       [logic!]
	][
		as-logic file-error file
	]
]