Red [
	Title:  "Red call binding"
	Author: "Bruno Anselme"
	EMail:  "be.red@free.fr"
	File:   %call.red
	Rights: "Copyright (c) 2014 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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
	redirin    [logic!]   "Input redirection"
	in-str     [string!]  "Input data"
	redirout   [logic!]   "Output redirection"
	redirerr   [logic!]   "Error redirection"
	return:    [integer!]
	/local
	inp out err
][
	either redirin [
		inp: declare p-buffer!
		inp/buffer: string/rs-head in-str
		inp/count:  1 + length? (as-c-string string/rs-head in-str)
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
	system-call/call (as-c-string string/rs-head cmd) waitend console inp out err
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
				sout: string/load as-c-string outputs/out/buffer (1 + outputs/out/count) UTF-8
			][
				sout: string/load as-c-string outputs/out/buffer (1 + (outputs/out/count / 2)) UTF-16LE
			]
		][
			sout: string/load as-c-string outputs/out/buffer (1 + outputs/out/count) UTF-8
		]
		free outputs/out/buffer
		SET_RETURN(sout)
	]
]

get-err: routine [ "Returns redirected stderr"
	/local
		serr  [red-string!]
][
	with system-call [
		#either OS = 'Windows [
			result: IS_TEXT_UNICODE_UNICODE_MASK
			is-text-unicode outputs/err/buffer outputs/err/count :result
			either result = 0 [
				to-ascii outputs/err
				serr: string/load as-c-string outputs/err/buffer (1 + outputs/err/count) UTF-8
			][
				serr: string/load as-c-string outputs/err/buffer (1 + (outputs/err/count / 2)) UTF-16LE
			]
		][
			serr: string/load as-c-string outputs/err/buffer (1 + outputs/err/count) UTF-8
		]
		free outputs/err/buffer
		SET_RETURN(serr)
	]
]

call: func [ "Executes a shell command to run another process."
	cmd            [string!]         "The shell command or file"
	/wait                            "Runs command and waits for exit"
	/console                         "Runs command with I/O redirected to console"
	/input    in   [string!]         "Redirects in to stdin"
	/output   out  [string! block!]  "Redirects stdout to out"
	/error    err  [string! block!]  "Redirects stderr to err"
	return:        [integer!]        "0 if success, -1 if error, or a process ID"
	/local
		pid        [integer!]
		str        [string!]
		do-in do-out do-err
][
	pid: 0
	either input  [ str:    in   ][ str:    ""    ]
	either input  [ do-in:  true ][ do-in:  false ]
	either output [ do-out: true ][ do-out: false ]
	either error  [ do-err: true ][ do-err: false ]
	pid: redsys-call cmd wait console do-in str do-out do-err
	if do-out [
		str: get-out
		insert out str
		out: head out
	]
	if do-err [
		str: get-err
		insert err str
		err: head err
	]
	pid
]

prin "-=== Call added to Red console ===-"
