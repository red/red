Red/System [
	Title:  "Red/System call binding"
	Author: "Bruno Anselme"
	EMail:  "be.red@free.fr"
	File:   %call.reds
	Rights: "Copyright (c) 2014-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
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
;#include %../../../../Kaj/C-library/ANSI.reds		;-- Tests with Kaj's ansi binding
#switch OS [
	Windows   [ #include %../windows.reds ]
	#default  [ #include %../linux.reds  ]
]

#define READ-BUFFER-SIZE 4096

p-buffer!: alias struct! [								;-- Data buffer struct, pointer and bytes count
	count  [integer!]
	buffer [byte-ptr!]
]

f-desc!: alias struct! [								;-- Files descriptors for posix pipe
	reading  [integer!]
	writing  [integer!]
]

system-call: context [
	error-pipe:			"Error Red/System call : pipe creation failed : "
	error-dup2:			"Error Red/System call : calling dup2 : "
	error-sethandle:	"Error Red/System call : SetHandleInformation failed : "
	outputs: declare struct! [							;-- Global var to store outputs values before setting call /output and /error refinements
		out			[p-buffer!]
		err			[p-buffer!]
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
		/local
			tmp [binary!]
	][
		tmp: resize buffer newsize						;-- Resize output buffer to new size
		either tmp = null [								;-- reallocation failed, uses current output buffer
			print-error [ "Red/System resize-buffer : Memory allocation failed." ]
			halt
		][ buffer: tmp ]
		return buffer
	]
	print-error: func [ "Format and print on stderr"
		[typed]
		count [integer!] list [typed-value!]
		/local
			str		[c-string!]
			len		[integer!]
	][
		str: make-c-string 1000
		set-memory as byte-ptr! str null-byte 1000
		until [
			switch list/type [
				type-c-string! [ format-any [ (str + length? str) "%s" list/value ] ]
				type-integer!  [ format-any [ (str + length? str) "%d" list/value ] ]
				type-logic!    [ format-any [ (str + length? str) "%s" either as logic! list/value [ "true" ][ "false" ] ] ]
				default        [ format-any [ (str + length? str) "%08Xh" list/value ] ]	;-- print as an hex value
			]
			list: list + 1
			count: count - 1
			zero? count
		]
		append-string str "^/"
		len: length? str
		#switch OS [									;-- Write to stderr, no error check
			Windows  [ io-write get-std-handle STD_ERROR_HANDLE as byte-ptr! str len :len null ]
			#default [ io-write stderr as byte-ptr! str len ]
		]
		free as byte-ptr! str
	]

	#switch OS [
	Windows   [											;-- Windows
		read-from-pipe: func [      "Read data from pipe fd into buffer"
			fd           [integer!]      "File descriptor"
			data         [p-buffer!]
			/local len size total
		][
			size: READ-BUFFER-SIZE						;-- get initial buffer size
			total: 0
			until [
				len: 0
				io-read fd (data/buffer + total) (size - total) :len null
				if len > 0 [
				    total: total + len
				    if total = size [
				        size: 2 * size
				        data/buffer: resize-buffer data/buffer size
				    ]
				]
				get-last-error = ERROR_BROKEN_PIPE		;-- Pipe done - normal exit
			]
			data/buffer: resize-buffer data/buffer (total + 1)	;-- Resize output buffer to minimum size
			data/count: total
		] ; read-from-pipe
		call: func [ "Executes a DOS command to run another process."
			cmd           [c-string!]  "The shell command"
			waitend       [logic!]     "Wait for end of command, implicit if any buffer is set"
			console       [logic!]     "Redirect outputs to console"
			shell		[logic!]       "Forces command to be run from shell"
			in-buf        [p-buffer!]  "Input data buffer or null"
			out-buf       [p-buffer!]  "Output data buffer or null"
			err-buf       [p-buffer!]  "Error data buffer or null"
			return:       [integer!]
			/local
				pid        [integer!]
				inherit    [logic!]
				cmdstr     [c-string!]
				in-read    [integer!]
				in-write   [integer!]
				out-read   [integer!]
				out-write  [integer!]
				err-read   [integer!]
				err-write  [integer!]
				dev-null   [integer!]
				sa p-inf s-inf len success error str
		][
			s-inf: declare startup-info!
			p-inf: declare process-info!
			sa: declare security-attributes!
			sa/nLength: size? sa
			sa/lpSecurityDescriptor: null
			sa/bInheritHandle: true
			out-read:  0								;-- Pipes
			out-write: 0
			in-read:   0
			in-write:  0
			err-read:  0
			err-write: 0
			inherit: false
			s-inf/cb: size? s-inf
			s-inf/dwFlags: 0
			s-inf/hStdInput:  get-std-handle STD_INPUT_HANDLE
			s-inf/hStdOutput: get-std-handle STD_OUTPUT_HANDLE
			s-inf/hStdError:  get-std-handle STD_ERROR_HANDLE
			dev-null: create-file "nul:" GENERIC_WRITE FILE_SHARE_WRITE sa OPEN_EXISTING 0 null		;-- Pipe to nul
			if in-buf <> null [
				if not create-pipe :in-read :in-write sa 0 [	;-- Create a pipe for child's input
					print-error [ error-pipe "stdin" ]
					return -1
				]
				if not set-handle-information in-write HANDLE_FLAG_INHERIT 0 [
					print-error [ error-sethandle "stdin" ]
					return -1
				]
				s-inf/hStdInput: in-read
			]
			either out-buf <> null [
				out-buf/count: 0
				out-buf/buffer: allocate READ-BUFFER-SIZE
				if not create-pipe :out-read :out-write sa 0 [	;-- Create a pipe for child's output
					print-error [ error-pipe "stdout" ]
					return -1
				]
				if not set-handle-information out-read HANDLE_FLAG_INHERIT 0 [
					print-error [ error-sethandle "stdout" ]
					return -1
				]
				s-inf/hStdOutput: out-write
			][
				if not console [						;-- output must be redirected to "nul" or process returns an error code
					s-inf/hStdOutput: dev-null
				]
			]
			either err-buf <> null [
				err-buf/count: 0
				err-buf/buffer: allocate READ-BUFFER-SIZE
				if not create-pipe :err-read :err-write sa 0 [	;-- Create a pipe for child's error
					print-error [ error-pipe "stderr" ]
					return -1
				]
				if not set-handle-information err-read HANDLE_FLAG_INHERIT 0 [
					print-error [ error-sethandle "stderr" ]
					return -1
				]
				s-inf/hStdError: err-write
			][
				if not console [
					s-inf/hStdError: dev-null
				]
			]
			if any [ (in-buf <> null) (out-buf <> null) (err-buf <> null) ] [
				waitend: true
				inherit: true
				s-inf/dwFlags: STARTF_USESTDHANDLES
			]
			if not console [
				if in-buf  = null [ s-inf/hStdInput:  0 ]
				inherit: true
				s-inf/dwFlags: STARTF_USESTDHANDLES
			]

			sa/bInheritHandle: inherit
			cmdstr: make-c-string (20 + length? cmd)
			copy-string "cmd /u /c " cmdstr		;-- Run command thru cmd.exe
			cmdstr: append-string cmdstr cmd
			if not create-process null cmdstr null null inherit 0 null null s-inf p-inf [
				print-error [ "Error Red/System call : CreateProcess : ^"" cmd "^" Error : " get-last-error ]
				free as byte-ptr! cmdstr
				return -1
			]
			free as byte-ptr! cmdstr

			pid: 0
			if in-buf <> null [
				close-handle in-read
				len: in-buf/count
				success: io-write in-write in-buf/buffer len :len null
				if not success [
					print-error [ "Error Red/System call : write into pipe failed : " get-last-error ]
				]
				close-handle in-write
			]
			if out-buf <> null [
				close-handle out-write
				read-from-pipe out-read out-buf
				close-handle out-read
			]
			if err-buf <> null [
				close-handle err-write
				read-from-pipe err-read err-buf
				close-handle err-read
			]
			either waitend [
				wait-for-single-object p-inf/hProcess INFINITE
				get-exit-code-process p-inf/hProcess :pid
			][
				pid: p-inf/dwProcessId
			]
			close-handle p-inf/hProcess
			close-handle p-inf/hThread
			close-handle dev-null
			outputs/out: out-buf						;-- Store values in global var
			outputs/err: err-buf
			return pid
		] ; call
	] ; Windows
	#default  [                                         ;-- POSIX
		;-- Shell detection
		shell-name: declare c-string!
		until [
			if null <> find-string system/env-vars/item "SHELL=" [
				shell-name: make-c-string length? system/env-vars/item
				copy-string (system/env-vars/item + 6) shell-name
			]
			system/env-vars: system/env-vars + 1
			system/env-vars/item = null
		]
		read-from-pipe: func [ "Read data from pipe fd into buffer"
			fd        [f-desc!]   "File descriptor"
			data      [p-buffer!]
			/local len size total
		][
			io-close fd/writing                            ;-- close unused pipe end
			size: READ-BUFFER-SIZE                      ;-- initial buffer size and grow step
			total: 0
			until [
				len: io-read fd/reading (data/buffer + total) (size - total)    ;-- read pipe, store into buffer
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
			io-close fd/reading                            ;-- close other pipe end
		] ; read-from-pipe
		call: func [                   "Executes a shell command, IO redirections to buffers."
			cmd			[c-string!]    "The shell command"
			waitend		[logic!]       "Wait for end of command, implicit if any buffer is set"
			console		[logic!]       "Redirect outputs to console"
			shell		[logic!]       "Forces command to be run from shell"
			in-buf		[p-buffer!]    "Input data buffer or null"
			out-buf		[p-buffer!]    "Output data buffer or null "
			err-buf		[p-buffer!]    "Error data buffer or null"
			return:		[integer!]
			/local pid status err wexp fd-in fd-out fd-err args dev-null str
		][
			if in-buf <> null [
				fd-in: declare f-desc!
				if (pipe as int-ptr! fd-in) = -1 [		;-- Create a pipe for child's input
					print-error [ error-pipe "stdin" ]
					return -1
				]
			]
			if out-buf <> null [						;- Create buffer for output
				out-buf/count: 0
				out-buf/buffer: allocate READ-BUFFER-SIZE
				fd-out: declare f-desc!
				if (pipe as int-ptr! fd-out) = -1 [		;-- Create a pipe for child's output
					print-error [ error-pipe "stdout" ]
					return -1
				]
			]
			if err-buf <> null [						;- Create buffer for error
				err-buf/count: 0
				err-buf/buffer: allocate READ-BUFFER-SIZE
				fd-err: declare f-desc!
				if (pipe as int-ptr! fd-err) = -1 [		;-- Create a pipe for child's error
					print-error [ error-pipe "stderr" ]
					return -1
				]
			]

			pid: fork
			either pid = 0 [                            ;-- Child process
				if in-buf <> null [                     ;-- redirect stdin to the pipe
					io-close fd-in/writing
					err: dup2 fd-in/reading stdin
					if err = -1 [ print-error [ error-dup2 "stdin" ]	 quit -1 ]
					io-close fd-in/reading
				]
				either out-buf <> null [				;-- redirect stdout to the pipe
					io-close fd-out/reading
					err: dup2 fd-out/writing stdout
					if err = -1 [ print-error [ error-dup2 "stdout" ]	 quit -1 ]
					io-close fd-out/writing
				][
					if not console [					;-- redirect stdout to /dev/null.
						dev-null: io-open "/dev/null" O_WRONLY
						err: dup2 dev-null stdout
						if err = -1 [ print-error [ error-dup2 "stdout to null" ]	 quit -1 ]
						io-close dev-null
					]
				]
				either err-buf <> null [				;-- redirect stderr to the pipe
					io-close fd-err/reading
					err: dup2 fd-err/writing stderr
					if err = -1 [ print-error [ error-dup2 "stderr" ]	 quit -1 ]
					io-close fd-err/writing
				][
					if not console [					;-- redirect stderr to /dev/null.
						dev-null: io-open "/dev/null" O_WRONLY
						err: dup2 dev-null stderr
						if err = -1 [ print-error [ error-dup2 "stderr to null" ]	 quit -1 ]
						io-close dev-null
					]
				]
				if all [(in-buf = null) (not console)] [ io-close stdin ]	;-- no redirection, stdin closed
				either shell [
					args: as str-array! allocate 4 * size? c-string!
					args/item: shell-name	args: args + 1
					args/item: "-c"			args: args + 1
					args/item: cmd			args: args + 1
					args/item: null
					args: args - 3						;-- reset args pointer
					execvp shell-name args				;-- Process is launched here, execvp with str-array parameters
					print-error [ "Error Red/System call while calling execvp : " shell-name " -c " cmd ]	  ;-- Should never occur
					quit -1

				][
					wexp: declare wordexp-type!				;-- Create wordexp struct
					status: wordexp cmd wexp WRDE_SHOWERR	;-- Parse cmd into str-array
					either status = 0 [						;-- Parsing ok
						execvp wexp/we_wordv/item wexp/we_wordv ;-- Process is launched here, execvp with str-array parameters
						print-error [ "Error Red/System call while calling execvp : " cmd ]	  ;-- Occurs if command doesn't exist. Should be printed to stderr
						quit -1
					][										;-- Parsing nok
						print-error [ "Error Red/System call, wordexp parsing command : " cmd ]

						switch status [
							WRDE_NOSPACE [ print-error [ "Attempt to allocate memory failed" ]	 ]
							WRDE_BADCHAR [ print-error [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" ]	 ]
							WRDE_BADVAL  [ print-error [ "Reference to undefined shell variable" ]	 ]
							WRDE_CMDSUB  [ print-error [ "Command substitution requested" ]	 ]
							WRDE_SYNTAX  [ print-error [ "Shell syntax error, such as unbalanced parentheses or unterminated string" ]	 ]
						]
						if in-buf  <> null [ free in-buf/buffer  ]	;-- free allocated buffers before exit
						if out-buf <> null [ free out-buf/buffer ]
						if err-buf <> null [ free err-buf/buffer ]
						quit -1
					]
				]
			][											;-- Parent process
				if in-buf <> null [						;-- write input buffer to child process' stdin
					io-close fd-in/reading
					io-write fd-in/writing in-buf/buffer in-buf/count
					io-close fd-in/writing
					waitend: true
				]
				if out-buf <> null [
					read-from-pipe fd-out out-buf		;-- read output buffer from child process' stdout
					waitend: true
				]
				if err-buf <> null [					;-- read error buffer from child process' stderr
					read-from-pipe fd-err err-buf
					waitend: true
				]
				if waitend [
					status: 0
					waitpid pid :status 0				;-- Wait child process terminate
					either (status and 00FFh) <> 0 [	;-- a signal occured. Low  byte contains stop code
						pid: -1
					][
						pid: status >> 8				;-- High byte contains exit code
					]
				]
				outputs/out: out-buf					;-- Store values in global var
				outputs/err: err-buf
			] ; either pid
			return pid
		] ; call
	] ; #default
	] ; #switch
] ; context

