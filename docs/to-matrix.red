Red [
	Title:   "Red database to datatype matrix"
	Author:  "Peter W A Wood"
	Tabs:	 4
	Rights:  {Copyright (C) 2011-2014	Nenad Rakocevic,
										Andreas Bolka,
										David Olivia,
										Xie Qing Tian,
									 	Peter W A Wood. All rights reserved.}
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}	
]

to-matrix: [
	
	integer! [
		accessor! 	[throw-error 'script]
		action!		[throw-error 'script]
		actor! 		[throw-error 'script]
		bigint! 	{make bigint! of same magnitude}
		bignum! 	{make bignum! of same magnitude, no decimal places}
		bitset! 	[throw-error 'script]
		binary! 	{R2 - convert to ASCII encoded string}
		block! 		{R2 - create block containing the integer}
		char! ``````{R2 - make char! when integer! in range 0 - 255
						- Other integers - throw-error 'math
					char!is an unsigned byte in Rebol2 but a Unicode codepoint
					with a value range of 00h to 10FFFFFFh in Red}
		closure!	[throw-error 'script]
		context!	[throw-error 'script]
		datatype! 	[throw-error 'script]
		date! 		[throw-error 'script]
		decimal! 	{make decimal! of same magnitude}
		email! 		{R2 - convert the integer to string! and then make email!}
		error!		[throw-error 'script]		
		file! 		{R2 - convert the integer to string! and then make file!}
		float!		{make a float! of the same magnitude}	
		float32! 	{make a float32! of the same magnitude}
		function!	[throw-error 'script]
		get-path! 	[throw-error 'script]
		get-word! 	[throw-error 'script]
		image! 		[throw-error 'script]
		integer! 	{make a new value of the same magnitude}
		ipv6! 		[throw-error 'script]
		issue!		{R2 - convert the integer to string! and then make issue!}
		lit-path! 	[throw-error 'script]
		lit-word! 	[throw-error 'script]
		map! 		[throw-error 'script]
		module! 	[throw-error 'script]
		logic! 		{R2 make false if integer is 0, true for all other integers}
		native! 	[throw-error 'script]
		none!		none
		object! 	[throw-error 'script]
		op! 		[throw-error 'script]
		pair! 		{R2 - make pair! using the integer for both x and y}
		paren! 		{R2 - make paren! enclosing the integer}
		path! 		{R2 - convert the integer! to string!and then make path!}
		percent! 	{Make a percent! of the same magnitude}
		point! 		{R2 - make point! using the integer for both x and y}
		port! 		[throw-error 'script]
		refinement! [throw-error 'script]
		routine! 	[throw-error 'script]
		set! 		{make a set! containing the integer}
		set-path! 	[throw-error 'script]
		set-word! 	[throw-error 'script]
		string! 	[mold integer]
		symbol!	 	[throw-error 'script]
		tag! 		{R2 - convert to string! and then make tag!}
		time! 		{R2 - make time! treating the integer as seconds}
		tuple! 		{R2 - conversion not defined}
		typeset! 	{R2 - makes a block! containing the integer}
		unset! 		[throw-error 'script]
		url! 		{R2 - converts integer to string and then make url!}
		utype! 		{to be provided by user}
		vector! 	{mkae a vector! with a single integer value}
		word! 		[throw-error 'script]
	]
]
