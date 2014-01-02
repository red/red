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
	
	tools-URL:		http://static.red-lang.org/droid-tools/
	build-root-dir: join temp-dir %builds/
	tools-dir:		build-root-dir/tools
	keystore:		%androidtest.keystore
	
	log: func [msg][prin "..." print msg]
	
	OS: system/version/4
	Windows?: OS = 3
	
	
	run: func [cmd [string!]][
		trim/lines cmd
		either verbose [call/console cmd][call/wait cmd]
	]
	
	copy-files: func [src [file!] dst [file!]][	
		run reform [
			either Windows? ["xcopy"]["cp -R"]
			to-local-file src
			to-local-file dst
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
				3 [[%jli.dll %aapt.exe %keytool.exe %zipalign.exe]]	;-- Windows
				4 [[%aapt %zipalign]]								;-- Linux
				2 [[%aapt %zipalign]]								;-- OSX
			]
			sys: select [3 %win/ 4 %linux/ 2 %osx/] OS

			foreach file files [
				prin rejoin [tab file "..."]
				write/binary tools-dir/:file read/binary tools-URL/:sys/:file
				if OS <> 3 [run reform ["chmod +x" tools-dir/:file]]
				print "done"
			]
			prin "^-android.jar(18MB)..."
			write/binary tools-dir/api/android.jar read/binary tools-URL/api/android.jar
			print "done"
		]
	]

	process: func [
		opts [object!] src [file!] file [file!]
		/local paths src-dir name bin-dir dst cmd apk
	][		
		paths: 	 split-path src
		src-dir: paths/1
		name:	 copy/part paths/2 find/last paths/2 #"."
		bin-dir: build-root-dir/:name
		append bin-dir slash

		make-dir/deep bin-dir
		make-dir/deep bin-dir/lib/armeabi
		make-dir/deep bin-dir/lib/x86

		attempt [delete bin-dir/lib/armeabi/libRed.so]
		attempt [delete bin-dir/lib/x86/libRed.so]
		
		get-tools

		dst: either opts/target = 'ARM [%armeabi/][%x86/]
		copy-file file join bin-dir [%lib/ dst %libRed.so]
		delete file
		
		copy-file  %bridges/android/dex/classes.dex bin-dir/classes.dex
		copy-files %bridges/android/res/drawable-hdpi bin-dir/res/drawable-hdpi
		copy-files %bridges/android/res/drawable-mdpi bin-dir/res/drawable-mdpi
		copy-files %bridges/android/res/drawable-xhdpi bin-dir/res/drawable-xhdpi
		copy-files %bridges/android/res/drawable-xxhdpi bin-dir/res/drawable-xxhdpi
		
		copy-file %bridges/android/AndroidManifest.xml.model build-root-dir/AndroidManifest.xml

		unless exists? build-root-dir/:keystore [
			cmd: reform [
				either OS = 3 [to-local-file tools-dir/keytool]["keytool"]
				{
					-genkeypair
					-validity 10000
					-dname "CN=Red,
							OU=organisational unit,
							O=organisation,
							L=location,
							S=state,
							C=US"
					-keystore } to-local-file build-root-dir/:keystore {
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

		cmd: reform [
			to-local-file tools-dir/aapt {
				 package
				 -v
				 -f
				 -M } to-local-file build-root-dir/AndroidManifest.xml {
				 -S } to-local-file %bridges/android/res {
				 -I } to-local-file tools-dir/api/android.jar {
				 -F } to-local-file rejoin [build-root-dir name %-unsigned.apk]
				 to-local-file bin-dir
		]
		log "generating apk"
		run cmd

		cmd: reform [ {
			 jarsigner
				 -verbose
				 -keystore } to-local-file build-root-dir/:keystore {
				 -storepass android
				 -keypass android
				 -sigalg MD5withRSA
				 -digestalg SHA1
				 -signedjar } to-local-file rejoin [build-root-dir name %-signed.apk] 
				 to-local-file rejoin [build-root-dir name %-unsigned.apk] {
				 testkey
			}
		]
		log "signing apk"
		run cmd

		cmd: reform [
			to-local-file tools-dir/zipalign 
			"-v -f 4"
			to-local-file rejoin [build-root-dir name %-signed.apk] 
			to-local-file apk: rejoin [build-root-dir name %.apk]
		]
		log "aligning apk"
		run cmd

		attempt [delete rejoin [build-root-dir name %-signed.apk]]
		attempt [delete rejoin [build-root-dir name %-unsigned.apk]]
		
		copy-file apk join name %.apk

		log "all done!"
		
	]
]
