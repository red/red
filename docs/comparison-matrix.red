Red [
	Title:   "Red database comparison matrix"
	Author:  "Peter W A Wood"
	Tabs:	 4
	Rights:  {Copyright (C) 2011-2015	Nenad Rakocevic,
										Andreas Bolka,
										Xie Qing Tian,
									 	Peter W A Wood. All rights reserved.}
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}	
]

comparison-matrix: [
	
	integer! [
		accessor! [
			equal? false
			strict-equal? false
			same? false
			comment "This is a comment"
		]
		action!	[
			equal? false
			strict-equal? false
			same? false
			
		]
		actor! [
			equal? false
			strict-equal? false
			same? false
		]
		bigint! [
			equal? "the integer is converted to bigint!"
			strict-equal? "the integer is converted to big int"
			same? false
		]
		bignum! [
			equal? "the integer is converted to bignum!"
			strict-equal? false
			same? false
		]
		bitset! [
			equal? false
			strict-equal? false
			same? false
		]
		binary! [
			equal? false
			strict-equal? false
			same? false
		]
		block! [
			equal? false
			strict-equal? false
			same? false
		]
		char! [
			equal? "the char is automatically cast to integer"
			strict-equal? false
			same? false
		]
		closure! [
			equal? false
			strict-equal? false
			same? false
		]
		context! [
			equal? false
			strict-equal? false
			same? false
		]
		datatype! [
			equal? false
			strict-equal? false
			same? false
		]
		date! [
			equal? false
			strict-equal? false
			same? false
		]
		decimal! [
			equal? "the integer is converted to decimal!"
			strict-equal? false
			same? false
		]
		email! [
			equal? false
			strict-equal? false
			same? false
		]
		error! [
			equal? false
			strict-equal? false
			same? false
		]
		file! [
			equal? false
			strict-equal? false
			same? false
		]
		float! [
			equal? "the integer is converted to float!"
			strict-equal? false
			same? false
		]
		float32! [
			equal? "the integer is converted to float32!"
			strict-equal? false
			same? false
		]
		function! [
			equal? false
			strict-equal? false
			same? false
		]
		get-path! [
			equal? false
			strict-equal? false
			same? false
		]
		get-word! [
			equal? false
			strict-equal? false
			same? false
		]
		image! [
			equal? false
			strict-equal? false
			same? false
		]
		integer! [
			equal? "direct comparison"
			strict-equal? "direct comparison"
			same? "equal? values and same memory address"
		]
		ipv6! [
			equal? false
			strict-equal? false
			same? false
		]
		issue! [
			equal? false
			strict-equal? false
			same? false
		]
		lit-path! [
			equal? false
			strict-equal? false
			same? false
		]
		lit-word! [
			equal? false
			strict-equal? false
			same? false
		]
		map! [
			equal? false
			strict-equal? false
			same? false
		]
		module! [
			equal? false
			strict-equal? false
			same? false
		]
		logic! [
			equal? false
			strict-equal? false
			same? false
		]
		native! [
			equal? false
			strict-equal? false
			same? false
		]
		none! [
			equal? false
			strict-equal? false
			same? false
		]
		object! [
			equal? false
			strict-equal? false
			same? false
		]
		op! [
			equal? false
			strict-equal? false
			same? false
		]
		pair! [
			equal? false
			strict-equal? false
			same? false
		]
		paren! [
			equal? false
			strict-equal? false
			same? false
		]
		path! [
			equal? false
			strict-equal? false
			same? false
		]
		percent! [
			equal? false
			strict-equal? false
			same? false
		]
		point! [
			equal? false
			strict-equal? false
			same? false
		]
		port! [
			equal? false
			strict-equal? false
			same? false
		]
		refinement! [
			equal? false
			strict-equal? false
			same? false
		]
		routine! [
			equal? false
			strict-equal? false
			same? false
		]
		set! [
			equal? false
			strict-equal? false
			same? false
		]
		set-path! [
			equal? false
			strict-equal? false
			same? false
		]
		set-word! [
			equal? false
			strict-equal? false
			same? false
		]
		string! [
			equal? false
			strict-equal? false
			same? false
		]
		symbol! [
			equal? false
			strict-equal? false
			same? false
		]
		tag! [
			equal? false
			strict-equal? false
			same? false
		]
		time! [
			equal? false
			strict-equal? false
			same? false
		]
		tuple! [
			equal? false
			strict-equal? false
			same? false
		]
		typeset! [
			equal? false
			strict-equal? false
			same? false
		]
		unset! [
			equal? false
			strict-equal? false
			same? false
		]
		url! [
			equal? false
			strict-equal? false
			same? false
		]
		utype! [
			equal? {user supplied direct comparison if of same utype!,
				   otherwise false}
		    strict-equal? "as equal"
		    same? "same memory address"
		]
		vector! [
			equal? false
			strict-equal? false
			same? false
		]
		word! [
			equal? false
			strict-equal? false
			same? false
		]
	]
]
