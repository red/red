REBOL [
	Title:   "Red APK builder script"
	Author:  "Nenad Rakocevic"
	File: 	 %build.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

verbose: yes

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

unless exists? build-root-dir [
	log "Creating building folders..."
	make-dir build-root-dir
	make-dir/deep tools-dir
	make-dir/deep tools-dir/api
	log "Downloading Android binary tools..."
	log "^- jli.dll..."
	write/binary tools-dir/jli.dll read/binary tools-URL/jli.dll
	log "^- aapt..."
	write/binary tools-dir/aapt.exe read/binary tools-URL/aapt.exe
	;log "^- jarsigner..."
	;write/binary tools-dir/jarsigner.exe read/binary tools-URL/jarsigner.exe
	log "^- keytool..."
	write/binary tools-dir/keytool.exe read/binary tools-URL/keytool.exe
	log "^- zipalign..."
	write/binary tools-dir/zipalign.exe read/binary tools-URL/zipalign.exe
	log "^- android.jar..."
	write/binary tools-dir/api/android.jar read/binary tools-URL/api/android.jar
]

prj-src-dir: %samples/eval/
prj-name: last split-path prj-src-dir
name: head remove back tail copy prj-name
bin-dir: build-root-dir/:prj-name

make-dir bin-dir
make-dir/deep bin-dir/lib/armeabi

;-- compile Red app --
do/args %../../../red.r reform [
	"-t Android -dlib" prj-src-dir/eval.red
	"-o " rejoin [%../red/bridges/android/ bin-dir/lib/armeabi "/libRed"]
]

;---

copy-file %dex/classes.dex bin-dir


unless exists? keystore [
	cmd: reform [
		tools-dir/keytool {
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
	tools-dir/aapt {
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
	tools-dir/zipalign 
	"-v -f 4"
	to-local-file rejoin [build-root-dir name %-signed.apk] 
	to-local-file rejoin [build-root-dir name %.apk]
]
log "Aligning apk..."
run cmd

attempt [delete rejoin [build-root-dir name %-signed.apk]]
attempt [delete rejoin [build-root-dir name %-unsigned.apk]]

halt