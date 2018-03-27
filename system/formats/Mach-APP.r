REBOL [
	Title:   "macOS Bundle packager"
	Author:  "Xie Qingtian"
	File: 	 %Mach-APP.r
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2018 Red Foundation. All rights reserved."
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
	
	copy-file: func [src [file!] dst [file!] /keep "keep file attributes"][
		if slash = last dst [dst: join dst last split-path src]
		either keep [
			run reform [
				either Windows? ["copy"]["cp"]
				to-OS-file src
				to-OS-file dst
			]
		][
			write/binary dst read-binary-cache src
		]
	]

	process: func [
		opts [object!] src [file!] file [file!]
		/local 
			paths src-dir name app-dir contents-dir bin-dir raw-dir res-dir
			plist
	][		
		paths: 	 split-path file
		src-dir: paths/1
		name:	 paths/2

		app-dir: rejoin [src-dir name %.app]
		if exists? app-dir [delete-dir app-dir]

		log ["generating bundle:" app-dir]

		append app-dir slash
		contents-dir: join app-dir "Contents/"
		bin-dir: join contents-dir "MacOS/"
		res-dir: join contents-dir "Resources/"
		make-dir/deep bin-dir
		make-dir/deep res-dir

		copy-file/keep file bin-dir/:name
		delete file
		copy-file %system/assets/macOS/Resources/AppIcon.icns res-dir/AppIcon.icns

		plist: read-cache %system/assets/macOS/Info.plist
		replace/all/case plist "$Red-App-Name$" name
		write/binary contents-dir/Info.plist plist

		log "all done!"
	]
]
