Rebol [
	Title:   "Red binary build script"
	Author:  "Xie Qingtian"
	File: 	 %build-red.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

comment {
1. Open a Rebol console, and CD to the **%build/** folder.

        >> change-dir %<path-to-Red>/build/

2. Run the build script from the console:
		; do/args %build-red.r "path-to-rebol" [target] [noview|GUI]	;-- args order matters
		
        >> do/args %build-red.r "path-to-rebol"			;-- generate for the current OS
        >> do/args %build-red.r "path-to-rebol" Linux	;-- generate for Linux OS
        >> do/args %build-red.r "path-to-rebol" Linux noview  ;-- for Linux OS without view module
        
3. After a few seconds, a new **red** binary will be available in the **build/bin/** folder.

4. Enjoy!
}

git-file:		%git.r

args: parse/all system/script/args " "
noview?: args/3 = "noview"
GUI?: args/3 = "GUI"
target: args/2
Windows?: any [
	all [none? target system/version/4 = 3]
	target = "windows"
]
if all [Windows? none? target][target: "Windows"]

rebol-bin: read/binary to-rebol-file args/1
src-files: pick load %includes.r 8

;-- Try to get version data from git repository
save git-file do %git-version.r

;-- save source files
red-repo: make block! 20
save-files: func [out src-files /local f][
	foreach f src-files [
		either block? f [
			change-dir last out
			append/only out make block! 20
			save-files last out f
			change-dir %..
		][
			append out f
			unless dir? f [append out read/binary f]
		]
	]
]
change-dir %..		;-- change to the root directory of red repo
save-files red-repo src-files

script: [Red [
	Title: "Red Programming Language"
	Version: 0.6.4
	Rights:  "Copyright (C) 2014-2020 Red Foundation. All rights reserved."
	Config: [gui-console?: no unicode?: yes red-help?: yes toolchain?: yes]
	Needs: view
	]
	red-toolchain: none
	#include %toolchain.red
	#include
]
poke script 4 reduce [rebol-bin red-repo]

either noview? [
	clear skip tail script/2 -2
	append script %../environment/console/CLI/console.red
][
	append script either any [GUI? Windows?][
		poke script/2/8 2 'yes
		%../environment/console/GUI/gui-console.red	
	][
		%../environment/console/CLI/console.red
	]
]

new-line/all skip tail script -1 no

change-dir %build/
red-src: %red.red
save red-src script

print "Encapping..."
system/options/args: none
cmd: either target [
	rejoin ["-r -t " target " " red-src]
][
	join "-r " red-src
]

do/args %../red.r cmd

if all [not Windows? target <> "MSDOS"] [	;-- Unix OSes
	print "chmod 755 ./red"
	call/wait "chmod 755 ./red"
]