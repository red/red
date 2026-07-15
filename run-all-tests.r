REBOL [
	Title:   "Builds and Runs All Red and Red/System Tests"
	File:    %run-all-tests.r
	Author:  "Peter W A Wood"
	Version: 0.6.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

all-tests-args: any [system/script/args system/options/args]
all-tests-config: make object! [
	root-dir: system/script/path
	title: "Complete Red Test Suite"
	compile-target: none
	library-target: none
	target-platform: none
	dependency-dir: none
	log-file: none
	include-regression?: no
	include-view?: yes
	prepare-command: none
	native-command: none
]

do %tests/run-all-tests-common.r
