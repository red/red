REBOL [
	Title:   "Builds and Runs All Windows x86-64 Red and Red/System Tests"
	File:    %run-all-tests-x64.r
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

unless system/version/4 = 3 [
	print "run-all-tests-x64.r requires a Windows host"
	quit/return 1
]

quote-file: func [value [file!]][
	rejoin [{"} to-local-file clean-path value {"}]
]

repo-root: system/script/path
native-runner: join repo-root %tests/run-windows-x64-all-tests.ps1
compiler-host: system/options/boot
command-prefix: rejoin [
	"pwsh.exe -NoProfile -File " quote-file native-runner
	" -Compiler " quote-file compiler-host
]

all-tests-args: any [system/script/args system/options/args]
all-tests-config: make object! [
	root-dir: repo-root
	title: "Complete Windows x86-64 Red Test Suite"
	compile-target: "Windows-X86-64"
	library-target: "Windows-X86-64-DLL"
	target-platform: "Windows"
	dependency-dir: clean-path join repo-root %build/windows-x64-all-tests/dependencies/
	log-file: clean-path join repo-root %quick-test/quick-test-x64.log
	include-regression?: yes
	include-view?: no
	prepare-command: rejoin [command-prefix " -Phase Prepare -KeepArtifactsOnFailure"]
	native-command: rejoin [command-prefix " -Phase Native -KeepArtifactsOnFailure"]
]

do %tests/run-all-tests-common.r
