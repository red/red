Red/System [
	Title:   "Red native functions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]


natives: context [
	verbose: 0

	print: func [
		/local
			str		[red-string!]
			series	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/print"]]
		
		actions/form off
		str: as red-string! stack/arguments + 1	
		assert TYPE_OF(str) = TYPE_STRING
		
		series: GET_BUFFER(str)

		switch GET_UNIT(series) [
			Latin1 [platform/print-line-Latin1 as c-string! series/offset]
			UCS-2  [platform/print-line-UCS2   as byte-ptr! series/offset]
			UCS-4  [platform/print-line-UCS4   as int-ptr!  series/offset]
			
			default [
				print-line ["Error: unknown string encoding:" GET_UNIT(series)]
			]
		]
		stack/set-last unset-value
	]
	
	compare: func [
		op		   [integer!]
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		args: stack/arguments
		result: as red-logic! args
		res: actions/compare args args + 1 op
		result/value: res
		result/header: TYPE_LOGIC
		result
	]
	
	equal?: func [
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/equal?"]]
		compare COMP_EQUAL
	]
	
	strict-equal?: func [
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/strict-equal?"]]
		compare COMP_STRICT_EQUAL
	]
	
	lesser?: func [
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser?"]]
		compare COMP_LESSER
	]
	
	greater?: func [
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater?"]]
		compare COMP_GREATER
	]
	
	lesser-or-equal?: func [
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lesser-or-equal?"]]
		compare COMP_LESSER_EQUAL
	]	
	
	greater-or-equal?: func [
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "greater-or-equal?"]]
		compare COMP_GREATER_EQUAL
	]
]
