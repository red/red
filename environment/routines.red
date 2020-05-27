Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %routines.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

quit-return: routine [
	"Stops evaluation and exits the program with a given status"
	status [integer!] "Process termination value to return"
][
	quit status
]

set-quiet: routine [
	"Set an object's field to a value without triggering eventual object's events"
	word  [any-type!]
	value [any-type!]
	/local
		w	 [red-word!]
		type [integer!]
		node [node!]
][
	type: TYPE_OF(word)
	unless ANY_WORD?(type) [ERR_EXPECT_ARGUMENT(TYPE_WORD 0)]
	w: as red-word! word
	node: w/ctx
	_context/set-in w stack/arguments + 1 TO_CTX(node) no
]

set-slot-quiet: routine [
	"Set a value in series without triggering eventual owner's events"
	series	[any-type!]
	value 	[any-type!]
	/local
		blk	 [red-block!]
		type [integer!]
][
	type: TYPE_OF(series)
	unless ANY_BLOCK_STRICT?(type) [ERR_EXPECT_ARGUMENT(TYPE_BLOCK 0)]
	blk: as red-block! series
	unless block/rs-tail? blk [copy-cell value block/rs-head blk]
]

;-- Following definitions are used to create op! corresponding operators
shift-right:   routine ["Shift bits to the right" data [integer!] bits [integer!]][natives/shift* no -1 -1]
shift-left:	   routine ["Shift bits to the left" data [integer!] bits [integer!]][natives/shift* no  1 -1]
shift-logical: routine ["Shift bits to the right (unsigned)" data [integer!] bits [integer!]][natives/shift* no -1  1]

;-- Helping routine for console, returns true if last output character was a LF
last-lf?: routine ["Internal Use Only" /local bool [red-logic!]][
	bool: as red-logic! stack/arguments
	bool/header: TYPE_LOGIC
	bool/value:	 natives/last-lf?
]

get-current-dir: routine ["Returns the platform’s current directory for the process"][
	stack/set-last as red-value! file/get-current-dir
]

set-current-dir: routine ["Sets the platform’s current process directory" path [string!] /local dir [red-file!]][
	dir: as red-file! stack/arguments
	unless platform/set-current-dir file/to-OS-path dir [
		fire [TO_ERROR(access cannot-open) dir]
	]
]

create-dir: routine ["Create the given directory" path [file!]][			;@@ temporary, user should use `make-dir`
	unless simple-io/make-dir file/to-OS-path path [
		fire [TO_ERROR(access no-create) path]
	]
]

exists?: routine ["Returns TRUE if the file exists" path [file!] return: [logic!]][
	simple-io/file-exists? file/to-OS-path path
]

os-info: routine ["Returns detailed operating system version information"][
	__get-OS-info
]

as-color: routine [
	"Combine R, G and B values into a tuple"
	r [integer!]
	g [integer!]
	b [integer!]
	/local
		arr1 [integer!]
		err	 [integer!]
][
	err: case [
		r < 0 [r]
		g < 0 [g]
		b < 0 [b]
		true  [0]
	]
	if err <> 0 [fire [TO_ERROR(script invalid-arg) integer/push err]]
	
	arr1: (b % 256 << 16) or (g % 256 << 8) or (r % 256)
	stack/set-last as red-value! tuple/push 3 arr1 0 0
]

as-ipv4: routine [
	"Combine a, b, c and d values into a tuple"
	a [integer!]
	b [integer!]
	c [integer!]
	d [integer!]
	/local
		arr1 [integer!]
		err	 [integer!]
][
	err: case [
		a < 0 [a]
		b < 0 [b]
		c < 0 [c]
		d < 0 [d]
		true  [0]
	]
	if err <> 0 [fire [TO_ERROR(script invalid-arg) integer/push err]]
	
	arr1: (d << 24) or (c << 16) or (b << 8) or a
	stack/set-last as red-value! tuple/push 4 arr1 0 0
]

as-rgba: :as-ipv4

count-chars: routine [
	"Count UTF-8 encoded characters between two positions in a binary series"
	start   [binary!]
	pos	    [binary!]
	return: [integer!]
	/local
		p tail [byte-ptr!]
		c len  [integer!]
		s	   [series!]
][
	s: GET_BUFFER(start)
	p:    (as byte-ptr! s/offset) + start/head
	tail: (as byte-ptr! s/offset) + pos/head
	c: len: 0
	while [p < tail][
		p: unicode/fast-decode-utf8-char p :len
		c: c + 1
	]
	c
]

;-- Temporary definition --

read-clipboard: routine [
	"Return the contents of the system clipboard"
	return: [any-type!] "false on failure, none if empty, otherwise: string!, block! of files!, or an image!"
][
	stack/set-last clipboard/read
]

write-clipboard: routine [
	"Write content to the system clipboard"
	data [any-type!] "string!, block! of files!, an image! or none!"
	return: [logic!] "indicates success"
][
	clipboard/write as red-value! data
]

write-stdout: routine ["Write data to STDOUT" data [any-type!]][			;-- internal use only
	simple-io/write null as red-value! data null null no no no
]