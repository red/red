Red [
	Title:   "Map and construction syntax literal syntax migration script"
	Author:  "Nenad Rakocevic"
	File: 	 %map-conv.red
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Usage:   {
		map-conv %<root-path>/
		map-conv %<file>.red
		
		By default, `map-conv` will only display information about file(s) where map and/or 
		construction syntax literals are found. No change will be done. Use /save option to
		force changes on disk, a copy of each changed file will be made by default (can be disabled).
		
		Use `help map-conv` for more info about all options.
		
		Notes: 
		    * This script only works on Red interpreter versions before the lexer changes where
		      map and construction syntaxes are swapped!
		    * Only files with `.red` extension will be processed. Call `map-conv` directly with
		      a file name to workaround that limitation if needed.
	}
]

context [
	excluded:	make block! 1
	maps:		make block! 1000
	cs:			make block! 1000
	
	prefs: object [save?: copy?: detail?: no]
	stats: object [read: found: changed: 0]

	locate: function [event [word!] input [string!] type [datatype!] line [integer!] token return: [logic!]][
		[prescan close error]
		switch event [
			prescan [if type = datatype! [repend cs   [line token + 0x1]]]
			close   [if type = map!      [repend maps [line token + 0x1]]]
			error   [input: next input  return no]
		]
		yes
	]

	process: function [file [file!]][
		unless attempt [src: read file][print ["Error: cannot read file:" mold file]  exit]
		if prefs/copy? [original: copy src]
		stats/read: stats/read + 1
		clear maps
		clear cs
		
		transcode/trace src :locate
		
		if any [not empty? maps  not empty? cs][
			print ["--" file "| maps:" length? maps "| cs:" length? cs]
			stats/found: stats/found + 1
			
			foreach [line slice] maps [
				if prefs/detail? [print ["  line" line ": " mold/part copy/part src slice 50]]
				change at src slice/1 + 1 #"["
				change at src slice/2 - 1 #"]"
			]
			foreach [line slice] cs [
				if prefs/detail? [print ["  line" line ": " mold/part copy/part src slice 50]]
				change at src slice/1 + 1 #"("
				change at src slice/2 - 1 #")"
			]
			if prefs/save? [
				if prefs/copy? [write append copy file %.saved original]
				write file src
				stats/changed: stats/changed + 1
			]
		]
	]

	dive: function [path [file!]][
		foreach file read path [
			if dir? file [dive path/:file]
			all [
				any [empty? excluded  not find excluded second split-path file]
				%.red = suffix? file
				process path/:file
			]
		]
	]

	set 'map-conv function [
		"Swaps map! and construction syntax in argument file(s); only preview by default"
		root [file!]	"Folder or individual file to process (recursively)"
		/save			"Proceed with files conversion; original files are preserved as copies"
		/no-copy		"Do not make a file copy when committing changes"
		/no-detail		"Do not display details for each file"
		/ignore			"Exclude file(s) from processing"
			d-files [file! block!] "File(s) to exclude"
	][
		if system/build/date >= 9-Feb-2024 [print "Error: use a Red version before 9-Feb-2024!" exit]
		
		set prefs reduce [save  not no-copy  not no-detail]
		set stats 0
		
		clear excluded
		if ignore [append excluded d-files]
		
		either dir? root [dive root][process root]
		print stats
	]
]
