Red [
	Title:  "Red call binding"
	Author: "Bruno Anselme"
	EMail:  "be.red@free.fr"
	File:   %call.red
	Rights: "Copyright (c) 2014-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.4.1
		%call.reds
	}
]

#system-global [ #include %call.reds ]

; Routines definitions
redsys-call: routine [ "Set IO buffers if needed, execute call"
	cmd        [string!]  "Command"
	waitend    [logic!]   "Wait for end of child process"
	console    [logic!]   "Runs command with I/O redirected to console"
	shell      [logic!]   "Forces command to be run from shell"
	redirin    [logic!]   "Input redirection"
	in-str     [string!]  "Input data"
	redirout   [logic!]   "Output redirection"
	redirerr   [logic!]   "Error redirection"
	return:    [integer!]
	/local
	inp out err s
][
	either redirin [
		inp: declare p-buffer!
		inp/buffer: string/rs-head in-str
		s: GET_BUFFER(in-str)
		inp/count:  GET_UNIT(s) * string/rs-length? in-str
		#if OS = 'Windows [ system-call/to-ascii inp ]
	][
		inp: null
	]
	either redirout [
		out:  declare p-buffer!
		out/buffer: null
		out/count:  0
	][
		out: null
	]
	either redirerr [
		err:  declare p-buffer!
		err/buffer: null
		err/count:  0
	][
		err: null
	]
	system-call/call (as-c-string string/rs-head cmd) waitend console shell inp out err
]

get-out: routine [ "Returns redirected stdout"
	/local
		sout   [red-string!]
		str    [c-string!]
		result [integer!]
][
	with system-call [
		#either OS = 'Windows [
			result: IS_TEXT_UNICODE_UNICODE_MASK
			is-text-unicode outputs/out/buffer outputs/out/count :result
			either result = 0 [
				to-ascii outputs/out
				sout: string/load as-c-string outputs/out/buffer (outputs/out/count) UTF-8
			][
				sout: string/load as-c-string outputs/out/buffer (outputs/out/count / 2) UTF-16LE
			]
		][
			sout: string/load as-c-string outputs/out/buffer (outputs/out/count) UTF-8
		]
		free outputs/out/buffer
		SET_RETURN(sout)
	]
]

get-err: routine [ "Returns redirected stderr"
	/local
		serr	[red-string!]
		result	[integer!]
][
	with system-call [
		#either OS = 'Windows [
			result: IS_TEXT_UNICODE_UNICODE_MASK
			is-text-unicode outputs/err/buffer outputs/err/count :result
			either result = 0 [
				to-ascii outputs/err
				serr: string/load as-c-string outputs/err/buffer (outputs/err/count) UTF-8
			][
				serr: string/load as-c-string outputs/err/buffer (outputs/err/count / 2) UTF-16LE
			]
		][
			serr: string/load as-c-string outputs/err/buffer (outputs/err/count) UTF-8
		]
		free outputs/err/buffer
		SET_RETURN(serr)
	]
]

print-to-stderr: routine [ "Call to low level print to stderr"
	mesg	[string!]
][
	system-call/print-error [ as-c-string string/rs-head mesg ]
]

print-error: func [
	mesg			[string! block!]	"A shell command, an executable file or a block"
][
	if block? mesg [ mesg: form mesg ]
	print-to-stderr mesg
]

call: func [ "Executes a shell command to run another process."
	cmd			[string! block!]	"A shell command, an executable file or a block"
	/wait							"Runs command and waits for exit"
	/console						"Runs command with I/O redirected to console"
	/shell							"Forces command to be run from shell"
	/input	in	[string! block!]	"Redirects in to stdin"
	/output	out	[string! block!]	"Redirects stdout to out"
	/error	err	[string! block!]	"Redirects stderr to err"
	return:		[integer!]			"0 if success, -1 if error, or a process ID"
	/local
		pid		[integer!]
		str		[string!]
		do-in do-out do-err
][
	pid: 0
	if block? cmd [ cmd: form cmd ]
	either input  [
		if block? in [ in: form in ]
		str: in
	][
		str: ""
	]
	pid: redsys-call cmd wait console shell input str output error
	if output [
		str: get-out
		parse str [ while [ ahead crlf remove cr | skip ] ]
		out: head insert out str
	]
	if error [
		str: get-err
		parse str [ while [ ahead crlf remove cr | skip ] ]
		err: head insert err str
	]
	pid
]
