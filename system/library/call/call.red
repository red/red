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
		type	[integer!]
][
	pad1: 0.0
	pad2: pad1
	pad3: pad1
	inp: null
	out: null
	err: null

	type: TYPE_OF(in-str)
	case [
		type = TYPE_STRING [
			PLATFORM_TO_CSTR(cstr in-str len)
			inp: as p-buffer! :pad1					;@@ a trick as we cannot declear struct on stack
			inp/buffer: as byte-ptr! cstr
			inp/count: len
		]
		type = TYPE_BINARY [
			inp: as p-buffer! :pad1
			inp/buffer: binary/rs-head as red-binary! in-str
			inp/count: binary/rs-length? as red-binary! in-str
		]
		type = TYPE_FILE [
			inp: as p-buffer! :pad1
			inp/buffer: as byte-ptr! file/to-OS-path as red-file! in-str
			inp/count: -1
		]
		true [0]
	]
	type: TYPE_OF(redirout)
	if type <> TYPE_NONE [
		out: as p-buffer! :pad2
		either type = TYPE_FILE [
			out/buffer: as byte-ptr! file/to-OS-path as red-file! redirout
			out/count: -1
		][
			out/buffer: null
			out/count: 0
		]
	]
	type: TYPE_OF(redirerr)
	if type <> TYPE_NONE [
		err: as p-buffer! :pad3
		either type = TYPE_FILE [
			err/buffer: as byte-ptr! file/to-OS-path as red-file! redirerr
			err/count: -1
		][
			err/buffer: null
			err/count:  0
		]
	]

	PLATFORM_TO_CSTR(cstr cmd len)
	pid: system-call/call cstr waitend console shell inp out err

	if all [out <> null out/count <> -1][
		system-call/insert-string redirout out shell
		free out/buffer
	]
	if all [err <> null err/count <> -1][
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
	/input	in	[string! file! binary! block!]	"Redirects in to stdin"
	/output	out	[string! file! binary!]	"Redirects stdout to out"
	/error	err	[string! file! binary!]	"Redirects stderr to err"
	return:		[integer!]				"0 if success, -1 if error, or a process ID"
][
	if empty? cmd [return 0]

	cmd: arg-to-string cmd
	if input [in: arg-to-string in]

	redsys-call cmd wait console shell in out err
]
