Red/System [
	Title:  "Red/System call binding"
	Author: "Bruno Anselme"
	EMail:  "be.red@free.fr"
	File:   %call.reds
	Rights: "Copyright (c) 2014 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.4.1
		%ansi.reds
		%linux.reds
		%windows.reds
	}
	Purpose: {
		This binding implements a call function for Red/System (similar to rebol's call function).
		POSIX version uses "wordexp" function to perform word expansion.
	}
	Reference: {
		POSIX wordexp :
		http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html
	}
]

#include %../ansi.reds
#switch OS [
	Windows   [ #include %../windows.reds ]
	#default  [ #include %../linux.reds  ]
]

#define READ-BUFFER-SIZE 4096

p-buffer!: alias struct! [                              ;-- Data buffer struct, pointer and bytes count
	count  [integer!]
	buffer [byte-ptr!]
]

f-desc!: alias struct! [                                ;-- Files descriptors for posix pipe
	reading  [integer!]
	writing  [integer!]
]

system-call: context [
	error-pipe:			"Error Red/System call : pipe creation failed : "
	error-dup2:			"Error Red/System call : calling dup2 : "
	error-sethandle:	"Error Red/System call : SetHandleInformation failed : "
	outputs: declare struct! [                          ;--  Global var to store outputs values before setting call /output and /error refinements
		out    [p-buffer!]
		err    [p-buffer!]
	]

	free-str-array: func [ "Free str-array! created by word-expand"
		args [str-array!]
		/local n
	][
		n: 0
		while [ args/item <> null ][
			free as byte-ptr! args/item
			args: args + 1
			n: n + 1
		]
		args: args  - n
		free as byte-ptr! args
	]
	to-ascii: func [
		buf      [p-buffer!]
		/local pos
	][
		if any [ (buf = null) ( buf/count = 0) ] [ exit ]
		pos: 0
		until [
			if buf/buffer/pos > #"^(7F)" [ buf/buffer/pos: #" " ]
			pos: pos + 1
			pos > buf/count
		]
	]
	resize-buffer: func [   "Reallocate buffer, error check"
		buffer       [byte-ptr!]
		newsize      [integer!]
		return:      [byte-ptr!]
	][
		tmp: resize buffer newsize						;-- Resize output buffer to new size
		either tmp = null [								;-- reallocation failed, uses current output buffer
			print [ "Red/System resize-buffer : Memory allocation failed." lf ]
			halt
		][ buffer: tmp ]
		return buffer
	]

	#switch OS [
	Windows   [											;-- Windows
		read-from-pipe: func [      "Read data from pipe fd into buffer"
			fd           [file!]      "File descriptor"
			data         [p-buffer!]
			/local len size total
		][
			size: READ-BUFFER-SIZE                      ;-- get initial buffer size
			total: 0
			until [
				len: 0
				read-file fd (data/buffer + total) (size - total) :len null
				if len > 0 [
				    total: total + len
				    if total = size [
				        size: 2 * size
				        data/buffer: resize-buffer data/buffer size
				    ]
				]
				get-last-error = ERROR_BROKEN_PIPE      ;-- Pipe done - normal exit
			]
			data/buffer: resize-buffer data/buffer (total + 1)    ;-- Resize output buffer to minimum size
			data/count: total
		] ; read-from-pipe
		call: func [ "Executes a DOS command to run another process."
			cmd           [c-string!]  "The shell command"
			waitend       [logic!]     "Wait for end of command, implicit if any buffer is set"
			console       [logic!]     "Redirect outputs to console"
			in-buf        [p-buffer!]  "Input data buffer or null"
			out-buf       [p-buffer!]  "Output data buffer or null"
			err-buf       [p-buffer!]  "Error data buffer or null"
			return:       [integer!]
			/local
				pid        [integer!]
				inherit    [logic!]
				cmdstr     [c-string!]
				in-read    [opaque!]
				in-write   [opaque!]
				out-read   [opaque!]
				out-write  [opaque!]
				err-read   [opaque!]
				err-write  [opaque!]
				sa p-inf s-inf len success error
		][
			s-inf: declare startup-info!
			p-inf: declare process-info!
			sa: declare security-attributes!
			sa/nLength: size? sa
			sa/lpSecurityDescriptor: 0
			sa/bInheritHandle: true
			out-read:  0
			out-write: 0
			in-read:   0
			in-write:  0
			err-read:  0
			err-write: 0
			inherit: false
			s-inf/cb: size? s-inf
			s-inf/dwFlags: 0
			s-inf/hStdInput:  stdin
			s-inf/hStdOutput: stdout
			s-inf/hStdError:  stderr
			if in-buf <> null [
				if not create-pipe :in-read :in-write sa 0 [ ;-- Create a pipe for child's input
					print [ error-pipe "stdin^/" ]
					return -1
				]
				if not set-handle-information in-write HANDLE_FLAG_INHERIT 0 [
					print [ error-sethandle "stdin^/" ]
					return -1
				]
				waitend: true
				s-inf/hStdInput: in-read
			]
			if out-buf <> null [
				out-buf/count: 0
				out-buf/buffer: allocate READ-BUFFER-SIZE
				if not create-pipe :out-read :out-write sa 0 [ ;-- Create a pipe for child's output
					print [ error-pipe "stdout^/" ]
					return -1
				]
				if not set-handle-information out-read HANDLE_FLAG_INHERIT 0 [
					print [ error-sethandle "stdout^/" ]
					return -1
				]
				waitend: false                          ;-- child's process is completed after end of pipe
				s-inf/hStdOutput: out-write
			]
			if err-buf <> null [
				err-buf/count: 0
				err-buf/buffer: allocate READ-BUFFER-SIZE
				if not create-pipe :err-read :err-write sa 0 [ ;-- Create a pipe for child's error output
					print [ error-pipe "stderr^/" ]
					return -1
				]
				if not set-handle-information err-read HANDLE_FLAG_INHERIT 0 [
					print [ error-sethandle "stderr^/" ]
					return -1
				]
				waitend: false                          ;-- child's process is completed after end of pipe
				s-inf/hStdError:  err-write
			]
			if any [ (in-buf <> null) (out-buf <> null) (err-buf <> null) ] [
				inherit: true
				s-inf/dwFlags: STARTF_USESTDHANDLES
			]
			if not console [
				if in-buf  = null [ s-inf/hStdInput:  0 ]
				if out-buf = null [ s-inf/hStdOutput: 0 ]
				if err-buf = null [ s-inf/hStdError:  0 ]
				inherit: true
				s-inf/dwFlags: STARTF_USESTDHANDLES
			]

			cmdstr: make-c-string (20 + length? cmd)
			copy-string cmdstr "cmd /u /c "		;-- Run command thru cmd.exe
			cmdstr: append-string cmdstr cmd
			if not create-process null cmdstr 0 0 inherit 0 0 null s-inf p-inf [
				print [ "Error Red/System call : CreateProcess : ^"" cmd "^" Error : " get-last-error "^/" ]
				free as byte-ptr! cmdstr
				return -1
			]
			free as byte-ptr! cmdstr

			if in-buf <> null [
				close-handle in-read
				len: in-buf/count
				success: write-file in-write in-buf/buffer len :len null
				if not success [
					print [ "Error Red/System call : write into pipe failed : " get-last-error lf ]
				]
				close-handle in-write
				pid: 0
			]
			either waitend [
				wait-for-single-object p-inf/hProcess INFINITE
				pid: 0
			][
				pid: p-inf/dwProcessId
			]
			if out-buf <> null [
				close-handle out-write
				read-from-pipe out-read out-buf
				close-handle out-read
				pid: 0
			]
			if err-buf <> null [
				close-handle err-write
				read-from-pipe err-read err-buf
				close-handle err-read
				pid: 0
			]
			close-handle p-inf/hProcess
			close-handle p-inf/hThread
			outputs/out: out-buf                        ;-- Store values in global var
			outputs/err: err-buf
			return pid
		] ; call
	] ; Windows
	#default  [                                         ;-- POSIX
		read-from-pipe: func [ "Read data from pipe fd into buffer"
			fd        [f-desc!]   "File descriptor"
			data      [p-buffer!]
			/local len size total
		][
			close fd/writing                            ;-- close unused pipe end
			size: READ-BUFFER-SIZE                      ;-- initial buffer size and grow step
			total: 0
			until [
				len: ioread fd/reading (data/buffer + total) (size - total)    ;-- read pipe, store into buffer
				if len > -1 [                           ;-- FIX: there's something wrong here, need to test errno
					total: total + len
					if total = size [                   ;-- buffer must be expanded
						size: 2 * size
						data/buffer: resize-buffer data/buffer size
					]
				]
				len = 0
			]
			data/buffer: resize-buffer data/buffer (total + 1)  ;-- Resize output buffer to minimum size
			data/count: total
			close fd/reading                            ;-- close other pipe end
		] ; read-from-pipe
		call: func [                   "Executes a shell command, IO redirections to buffers."
			cmd			[c-string!]    "The shell command"
			waitend		[logic!]       "Wait for end of command, implicit if any buffer is set"
			console		[logic!]       "Redirect outputs to console"
			in-buf		[p-buffer!]    "Input data buffer or null"
			out-buf		[p-buffer!]    "Output data buffer or null "
			err-buf		[p-buffer!]    "Error data buffer or null"
			return:		[integer!]
			/local pid status err wexp fd-in fd-out fd-err
		][
			if in-buf <> null [
				fd-in: declare f-desc!
				if (pipe as int-ptr! fd-in) = -1 [     ; Create a pipe for child's input
					print [ error-pipe "stdin^/" ]
					return -1
				]
			]
			if out-buf <> null [
				out-buf/count: 0
				out-buf/buffer: allocate READ-BUFFER-SIZE
				fd-out: declare f-desc!
				if (pipe as int-ptr! fd-out) = -1 [    ; Create a pipe for child's output
					print [ error-pipe "stdout^/" ]
					return -1
				]
			]
			if err-buf <> null [
				err-buf/count: 0
				err-buf/buffer: allocate READ-BUFFER-SIZE
				fd-err: declare f-desc!
				if (pipe as int-ptr! fd-err) = -1 [    ; Create a pipe for child's error
					print [ error-pipe "stderr^/" ]
					return -1
				]
			]

			pid: fork
			either pid = 0 [                            ;-- Child process
				if in-buf <> null [                     ;-- redirect stdin to the pipe
					close fd-in/writing
					err: dup2 fd-in/reading stdin
					if err = -1 [ print [ error-dup2 "stdin^/" ] return -1 ]
					close fd-in/reading
				]
				if out-buf <> null [                    ;-- redirect stdout to the pipe
					close fd-out/reading
					err: dup2 fd-out/writing stdout
					if err = -1 [ print [ error-dup2 "stdout^/" ] return -1 ]
					close fd-out/writing
				]
				if err-buf <> null [                    ;-- redirect stderr to the pipe
					close fd-err/reading
					err: dup2 fd-err/writing stderr
					if err = -1 [ print [ error-dup2 "stderr^/" ] return -1 ]
					close fd-err/writing
				]
				if not console [
					if in-buf  = null [ close stdin ]
					if out-buf = null [ close stdout ]
					if err-buf = null [ close stderr ]
				]
				wexp: declare wordexp-type!             ;-- Create wordexp struct
				status: wordexp cmd wexp WRDE_SHOWERR   ;-- Parse cmd into str-array
				either status = 0 [                     ;-- Parsing ok
					execvp wexp/we_wordv/item wexp/we_wordv ;-- Process is launched here, execvp with str-array parameters
					print [ "Error Red/System call while calling execvp : {" cmd "}" lf ]  ;-- Should never occur
					quit 1
				][                                      ;-- Parsing nok
					print [ "Error Red/System call, wordexp parsing command : " cmd lf ]
					switch status [
						WRDE_NOSPACE [ print [ "Attempt to allocate memory failed" lf ] ]
						WRDE_BADCHAR [ print [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" lf ] ]
						WRDE_BADVAL  [ print [ "Reference to undefined shell variable" lf ] ]
						WRDE_CMDSUB  [ print [ "Command substitution requested" lf ] ]
						WRDE_SYNTAX  [ print [ "Shell syntax error, such as unbalanced parentheses or unterminated string" lf ] ]
					]
					if in-buf  <> null [ free in-buf/buffer  ] ;-- free allocated buffers before exit
					if out-buf <> null [ free out-buf/buffer ]
					if err-buf <> null [ free err-buf/buffer ]
					return -1
				]
			][                                          ;-- Parent process
				if in-buf <> null [                     ;-- write input buffer to child process' stdin
					close fd-in/reading
					iowrite fd-in/writing in-buf/buffer in-buf/count
					close fd-in/writing
					waitend: true
				]
				if out-buf <> null [
					read-from-pipe fd-out out-buf       ;-- read output buffer from child process' stdout
					waitend: false                      ;-- child's process is completed after end of pipe
					pid: 0                              ;-- Process is completed, return 0
				]
				if err-buf <> null [                    ;-- Same with error stream
					read-from-pipe fd-err err-buf
					waitend: false
					pid: 0
				]
				if waitend [
					status: 0
					waitpid pid :status 0               ;-- Wait child process terminate
					pid: 0                              ;-- Process is completed, return 0
				]
				outputs/out: out-buf                    ;-- Store values in global var
				outputs/err: err-buf
			] ; either pid
			return pid
		] ; call
	] ; #default
	] ; #switch
] ; context

