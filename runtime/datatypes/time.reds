Red/System [
	Title:   "Time! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %time.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

time: context [
	verbose: 0
	
	nano: 1E-9
	
	make-at: func [
		time	[float!]								;-- in nanoseconds
		cell	[red-value!]
		return: [red-time!]
		/local
			t [red-time!]
	][
		t: as red-time! cell
		t/header: TYPE_TIME
		t/time:   time
		t
	]
	
	box: func [
		time	[float!]								;-- in nanoseconds
		return: [red-time!]
	][
		make-at time stack/arguments
	]
	
	push: func [
		time	[float!]								;-- in nanoseconds
		return: [red-time!]
		/local
			t [red-time!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/push"]]
		
		make-at time stack/push*
	]
	
	;-- Actions --
	
	mold: func [
		t		[red-time!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
			sec	   [float!]
			rem	   [float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/mold"]]
		
		sec: t/time * nano
		rem: sec // 3600.0
		
		formed: integer/form-signed float/to-integer sec / 3600.0
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?

		string/append-char GET_BUFFER(buffer) as-integer #":"

		formed: integer/form-signed float/to-integer rem / 60.0
		string/concatenate-literal buffer formed
		part - 1 - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #":"
		
		formed: float/form-float rem // 60.0 float/FORM_FLOAT_64
		string/concatenate-literal buffer formed
		part - 1 - length? formed						;@@ optimize by removing length?
		
		part
	]
	
	init: does [
		datatype/register [
			TYPE_TIME
			TYPE_VALUE
			"time!"
			;-- General actions --
			null			;make
			null			;random
			null			;reflect
			null			;to
			null			;form
			:mold
			null			;eval-path
			null			;set-path
			null			;compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]
