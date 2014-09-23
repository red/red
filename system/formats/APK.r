REBOL [
	Title:   "APK packager"
	Author:  "Nenad Rakocevic"
	File: 	 %APK.r
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

packager: context [
	verbose: no

	do %utils/aapt/aapt.r
	do %utils/signapk.r

	tools-URL:		http://static.red-lang.org/droid-tools/
	build-root-dir: join temp-dir %builds/
	tools-dir:		build-root-dir/tools
	keystore:		%androidtest.keystore
	
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
		either verbose [?? cmd call/console cmd][call/wait cmd]
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
		write/binary dst read/binary src
	]
	
	get-tools: has [files sys][
		unless exists? tools-dir [
			log "creating building folders"
			make-dir/deep tools-dir
			make-dir/deep tools-dir/api

			log "downloading Android binary tools"
			system/schemes/default/timeout: 0:05:00					;-- be nice with slow connections

			files: switch OS [
				3 [[%jli.dll %keytool.exe %zipalign.exe]]	;-- Windows
				4 [[%zipalign]]								;-- Linux
				2 [[%zipalign]]								;-- OSX
			]
			sys: select [3 %win/ 4 %linux/ 2 %osx/] OS

			foreach file files [
				prin rejoin [tab file "..."]
				write/binary tools-dir/:file read/binary tools-URL/:sys/:file
				if OS <> 3 [run reform ["chmod +x" tools-dir/:file]]
				print "done"
			]
		]
	]

	process: func [
		opts [object!] src [file!] file [file!]
		/local 
			paths src-dir name bin-dir dst cmd apk entries sign-files
			zip-entries key-alias key-store
	][		
		paths: 	 split-path src
		src-dir: paths/1
		name:	 copy/part paths/2 find/last paths/2 #"."
		bin-dir: build-root-dir/:name
		append bin-dir slash

		make-dir/deep bin-dir

		attempt [delete bin-dir/lib/armeabi/libRed.so]
		attempt [delete bin-dir/lib/x86/libRed.so]

		if system/product = 'Core [get-tools]

		dst: either opts/target = 'ARM [
			make-dir/deep bin-dir/lib/armeabi
			%armeabi/
		][
			make-dir/deep bin-dir/lib/x86
			%x86/
		]
		copy-file file join bin-dir [%lib/ dst %libRed.so]
		delete file

		copy-file %bridges/android/dex/classes.dex bin-dir/classes.dex
		copy-file %bridges/android/AndroidManifest.xml.model build-root-dir/AndroidManifest.xml

		either system/product = 'Core [
			unless exists? build-root-dir/:keystore [
				cmd: reform [
					either OS = 3 [to-OS-file tools-dir/keytool]["keytool"]
					{
						-genkeypair
						-validity 10000
						-dname "CN=Red,
								OU=organisational unit,
								O=organisation,
								L=location,
								S=state,
								C=US"
						-keystore } to-OS-file build-root-dir/:keystore {
						-storepass android
						-keypass android
						-alias testkey
						-keyalg RSA
						-v
					}
				]
				log "creating new keystore"
				run cmd
			]

			log "generating apk"
			aapt/package/to-file 
						 build-root-dir/AndroidManifest.xml
						 %bridges/android/res/
						 bin-dir
						 rejoin [build-root-dir name %-unsigned.apk]

			cmd: reform [ {
				 jarsigner
					 -verbose
					 -keystore } to-OS-file build-root-dir/:keystore {
					 -storepass android
					 -keypass android
					 -sigalg SHA1withRSA
					 -digestalg SHA1
					 -signedjar } to-OS-file rejoin [build-root-dir name %-signed.apk] 
					 to-OS-file rejoin [build-root-dir name %-unsigned.apk] {
					 testkey
				}
			]
			log "signing apk"
			run cmd

			cmd: reform [
				to-OS-file tools-dir/zipalign 
				"-v -f 4"
				to-OS-file rejoin [build-root-dir name %-signed.apk] 
				to-OS-file apk: rejoin [build-root-dir name %.apk]
			]
			log "aligning apk"
			run cmd

			attempt [delete rejoin [build-root-dir name %-signed.apk]]
			attempt [delete rejoin [build-root-dir name %-unsigned.apk]]
		][
			log "generating apk"
			entries: aapt/package/to-entry
						 build-root-dir/AndroidManifest.xml
						 %bridges/android/res/
						 bin-dir

			log "signing apk"
			sign-files: signapk/sign key-store entries

			log "aligning apk"
			zip-entries: make block! 32
			foreach entry entries [
				append/only zip-entries entry/1
			]
			if none? key-store [key-alias: "testkey"]				;-- use test key
			key-alias: uppercase key-alias
			append/only zip-entries zip-entry %META-INF/MANIFEST.MF now sign-files/1
			append/only zip-entries zip-entry join %META-INF/ [key-alias ".SF"] now sign-files/2
			append/only zip-entries zip-entry join %META-INF/ [key-alias ".RSA"] now sign-files/3
			package-all-entries/align apk: rejoin [build-root-dir name %.apk] zip-entries
		]

		copy-file apk join name %.apk
		log "all done!"
	]
]
