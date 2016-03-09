REBOL [
	Title:   "Red APK builder script"
	Author:  "Nenad Rakocevic"
	File: 	 %build.r
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

verbose: no

tools-URL: http://static.red-lang.org/droid-tools/
build-root-dir: %builds/
tools-dir: build-root-dir/tools
keystore: %androidtest.keystore

log: :print

copy-file: func [src [file!] dst [file!]][
	if slash = last dst [dst: join dst last split-path src]
	write/binary dst read/binary src
]

run: func [cmd [string!]][
	trim/lines cmd
	either verbose [call/console cmd][call/wait cmd]
]

OS: system/version/4

unless exists? build-root-dir [
	log "Creating building folders..."
	make-dir build-root-dir
	make-dir/deep tools-dir
	make-dir/deep tools-dir/api
	
	log "Downloading Android binary tools..."
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

prj-src-dir: %samples/eval/
prj-name: last split-path prj-src-dir
name: head remove back tail copy prj-name
bin-dir: build-root-dir/:prj-name

make-dir bin-dir
make-dir/deep bin-dir/lib/armeabi
make-dir/deep bin-dir/lib/x86

attempt [delete bin-dir/lib/armeabi/libRed.so]
attempt [delete bin-dir/lib/x86/libRed.so]

res: ask {
Choose CPU target (ENTER = default):
1) ARM (default)
2) x86
3) both
=> }
options: [
	["Android" %armeabi]
	["Android-x86" %x86]
]

opts: switch/default trim/all res [
	"2" [reduce [options/2]]
	"3" [options]
][
	reduce [options/1]
]

;-- compile Red app into a shared library --
foreach job opts [
	set [target dst-dir] job
	do/args %../../red.r reform [
		"-t " target " -dlib"
		"-o " join bin-dir/lib/:dst-dir "/libRed"
		prj-src-dir/eval.red
	]
]
;---

copy-file %dex/classes.dex bin-dir


unless exists? keystore [
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
			-keystore } keystore {
			-storepass android
			-keypass android
			-alias testkey
			-keyalg RSA
			-v
		}
	]
	log "Creating new keystore..."
	run cmd
]

cmd: reform [
	to-local-file tools-dir/aapt {
		 package
		 -v
		 -f
		 -M } to-local-file prj-src-dir/AndroidManifest.xml {
		 -S } to-local-file prj-src-dir/res {
		 -I } to-local-file tools-dir/api/android.jar {
		 -F } to-local-file rejoin [build-root-dir name %-unsigned.apk]
		 to-local-file bin-dir
]
log "Generating apk..."
run cmd

cmd: reform [ {
	 jarsigner
		 -verbose
		 -keystore } keystore {
		 -storepass android
		 -keypass android
		 -sigalg MD5withRSA
		 -digestalg SHA1
		 -signedjar } to-local-file rejoin [build-root-dir name %-signed.apk] 
		 to-local-file rejoin [build-root-dir name %-unsigned.apk] {
	     testkey
	}
]
log "Signing apk..."
run cmd

cmd: reform [
	to-local-file tools-dir/zipalign 
	"-v -f 4"
	to-local-file rejoin [build-root-dir name %-signed.apk] 
	to-local-file rejoin [build-root-dir name %.apk]
]
log "Aligning apk..."
run cmd

attempt [delete rejoin [build-root-dir name %-signed.apk]]
attempt [delete rejoin [build-root-dir name %-unsigned.apk]]

print "...all done!"
halt