Red [
	Title:   "Red system object definition"
	Author:  "Nenad Rakocevic"
	File: 	 %system.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

system: context [
	version: #version
	build:	 #build-date
		
	words: func	["Return a block of global words available"][
		#system [_context/get-words]
	]
	
	platform: func ["Return a word identifying the operating system"][
		#system [
			#switch OS [
				Windows  [SET_RETURN(words/_windows)]
				Syllable [SET_RETURN(words/_syllable)]
				MacOSX	 [SET_RETURN(words/_macosx)]
				#default [SET_RETURN(words/_linux)]
			]
		]
	]
	
	catalog: context [
		datatypes:
		actions:
		natives:
		errors: none
	]
	
	state: context [
		interpreted?: func ["Return TRUE if called from the interpreter"][
			#system [logic/box stack/eval?]
		]
		
		last-error: none
	]
	
	modules: make block! 8
	codecs:  context []
	schemes: context []
	ports:	 context []
	
	locale: context [
		language:
		language*:										;-- in locale language
		locale:
		locale*: none									;-- in locale language

		months: [
		  "January" "February" "March" "April" "May" "June"
		  "July" "August" "September" "October" "November" "December"
		]

		days: [
		  "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"
		]
	]
	
	options: context [
		boot: 			none
		home: 			none
		path: 			none
		script: 		none
		args: 			none
		do-arg: 		none
		debug: 			none
		secure: 		none
		quiet: 			false
		binary-base: 	16
		decimal-digits: 15
		module-paths: 	make block! 1
		file-types: 	none
		
		;-- change the way float numbers are processed
		float: context [
			pretty?: false
			full?: 	 false
			
			on-change*: func [word old new][
				switch word [
					pretty? [
						either new [
							#system [float/pretty-print?: yes]
						][
							#system [float/pretty-print?: no]
						]
					]
					full? [
						either new [
							#system [float/full-support?: yes]
						][
							#system [float/full-support?: no]
						]
					]
				]
			]
		]
	]
	
	script: context [
		title: header: parent: path: args: none
	]
	
	standard: context [
		header: context [
			title: name: type: version: date: file: author: needs: none
		]
		error: context [
			code: type: id: arg1: arg2: arg3: near: where: none
		]
	]
	
	view: context [
		screen: 	none
		event-port: none
		
		metrics: context [
			screen-size: 	none
			dpi:			none
			;scaling:		1x1
		]
	]
	
	lexer: none
	console: none
]
