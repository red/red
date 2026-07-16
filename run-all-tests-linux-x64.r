REBOL [
	Title:   "Builds and Runs All Linux x86-64 Red and Red/System Tests"
	File:    %run-all-tests-linux-x64.r
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

unless system/version/4 = 4 [
	print "run-all-tests-linux-x64.r requires a Linux host"
	quit/return 1
]

quote-file: func [value [file!]][
	rejoin [{"} to-local-file clean-path value {"}]
]

repo-root: system/script/path
native-runner: join repo-root %tests/run-linux-x64-all-tests.sh
compiler-host: system/options/boot
unless #"/" = first compiler-host [
	compiler-host: clean-path join repo-root compiler-host
]
command-prefix: rejoin [
	"sh " quote-file native-runner " "
]

all-tests-args: any [system/script/args system/options/args]
all-tests-config: make object! [
	root-dir: repo-root
	title: "Complete Linux x86-64 Red Test Suite"
	compile-target: "Linux-X86-64"
	library-target: "Linux-X86-64-SO"
	target-platform: "Linux"
	compile-flag: " -r -d "
	dependency-dir: clean-path join repo-root %build/linux-x64-all-tests/dependencies/
	log-file: clean-path join repo-root %quick-test/quick-test-linux-x64.log
	; The existing Linux-Red-Tests job owns the host compiler regression scripts.
	include-regression?: no
	include-view?: no
	prepare-command: rejoin [command-prefix "prepare " quote-file compiler-host]
	native-command: rejoin [command-prefix "native " quote-file compiler-host]
]

do %tests/run-all-tests-common.r
