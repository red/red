REBOL [
	Title:   "Mac OSX Bundle packager"
	Author:  "Xie Qingtian"
	File: 	 %Mach-APP.r
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

packager: context [
	verbose: no

	;do-cache %utils/sign-bundle.r

	log: func [msg][prin "..." print msg]
	
	OS: system/version/4
	Windows?: OS = 3
	
	to-OS-file: func [file [file!]][
		either Windows? [
			rejoin [{"} to-local-file file {"}]
		][
			to-local-file file
		]
	]
	
	run: func [cmd [string!]][
		trim/lines cmd
		either verbose [call/console cmd][call/wait cmd]
	]
	
	copy-files: func [src [file!] dst [file!]][	
		run reform [
			either Windows? ["xcopy"]["cp -R"]
			to-OS-file src
			to-OS-file dst
			either Windows? ["/Y /E /I"][""]
		]
	]
	
	copy-file: func [src [file!] dst [file!]][
		if slash = last dst [dst: join dst last split-path src]
		write/binary dst read-binary-cache src
	]

	process: func [
		opts [object!] src [file!] file [file!]
		/local 
			paths src-dir name app-dir contents-dir bin-dir raw-dir res-dir
			plist
	][		
		paths: 	 split-path src
		src-dir: paths/1
		name:	 copy/part paths/2 find/last paths/2 #"."

		app-dir: rejoin [src-dir name %.app]
		log ["generating bundle:" app-dir]

		append app-dir slash
		contents-dir: join app-dir "Contents/"
		bin-dir: join contents-dir "MacOS/"
		res-dir: join contents-dir "Resources/"
		make-dir/deep bin-dir
		make-dir/deep res-dir

		copy-files file bin-dir/:name
		delete file
		copy-file %system/assets/osx/Resources/AppIcon.icns res-dir/AppIcon.icns

		plist: read %system/assets/osx/Info.plist
		replace/all/case plist "$Red-App-Name$" name
		write/binary contents-dir/Info.plist plist

		log "all done!"
	]
]
