Red [
	Title:   "POSIX call command substitution security test"
	File: 	 %call-posix-nocmd-test.red
]

nocmd-marker: %/tmp/red-call-nocmd-marker
shell-marker: %/tmp/red-call-shell-marker

if exists? nocmd-marker [delete nocmd-marker]
if exists? shell-marker [delete shell-marker]

call/wait rejoin [
	"printf red-call-ok $(touch "
	to-local-file nocmd-marker
	")"
]

if exists? nocmd-marker [
	delete nocmd-marker
	print "FAIL: call without /shell executed command substitution"
	quit/return 1
]

call/wait/shell rejoin [
	"touch "
	to-local-file shell-marker
]

unless exists? shell-marker [
	print "FAIL: call/shell did not execute the shell command"
	quit/return 1
]

delete shell-marker
print "PASS: call without /shell rejects command substitution"
