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

#system [ #include %call.reds ]

; Routines definitions
redsys-call: routine [ "Set IO buffers if needed, execute call"
	cmd        [string!]  "Command"
	waitend    [logic!]   "Wait for end of child process"
	console    [logic!]   "Runs command with I/O redirected to console"
	shell      [logic!]   "Forces command to be run from shell"
	in-str     [string!]  "Input data"
	redirout   [string!]  "Output redirection"
	redirerr   [string!]  "Error redirection"
	return:    [integer!]
	/local
		pid		[integer!]
		inp		[p-buffer!]
		out		[p-buffer!]
		err		[p-buffer!]
		pad1	[float!]
		pad2	[float!]
		pad3	[float!]
		len		[integer!]
		cstr	[c-string!]
][
	pad1: 0.0
	pad2: pad1
	pad3: pad1
	inp: null
	out: null
	err: null

	if TYPE_OF(in-str) = TYPE_STRING [
		PLATFORM_TO_CSTR(cstr in-str len)
		inp: as p-buffer! :pad1					;@@ a trick as we cannot declear struct on stack
		inp/buffer: as byte-ptr! cstr
		inp/count: len
	]
	if TYPE_OF(redirout) <> TYPE_NONE [
		out: as p-buffer! :pad2
		out/buffer: null
		out/count:  0
	]
	if TYPE_OF(redirerr) <> TYPE_NONE [
		err: as p-buffer! :pad3
		err/buffer: null
		err/count:  0
	]

	PLATFORM_TO_CSTR(cstr cmd len)
	pid: system-call/call cstr waitend console shell inp out err

	if out <> null [
		system-call/insert-string redirout out shell
		free out/buffer
	]
	if err <> null [
		system-call/insert-string redirerr err shell
		free err/buffer
	]
	pid
]

arg-to-string: func [arg][
	case [
		block? arg [form arg]
		file?  arg [to-local-file arg]
		true	   [arg]
	]
]

call: func [ "Executes a shell command to run another process."
	cmd			[string! file! block!]	"A shell command, an executable file or a block"
	/wait								"Runs command and waits for exit"
	/console							"Runs command with I/O redirected to console (CLI console only at present)"
	/shell								"Forces command to be run from shell"
	/input	in	[string! file! block!]	"Redirects in to stdin"
	/output	out	[any-string! binary!]	"Redirects stdout to out"
	/error	err	[any-string! binary!]	"Redirects stderr to err"
	return:		[integer!]				"0 if success, -1 if error, or a process ID"
][
	if empty? cmd [return 0]

	cmd: arg-to-string cmd
	if input [in: arg-to-string in]

	redsys-call cmd wait console shell in out err
]
