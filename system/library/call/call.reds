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

#switch OS [
	Windows   [ #include %../windows.reds ]
	#default  [ #include %../linux.reds  ]
]

#define READ-BUFFER-SIZE 4096

p-buffer!: alias struct! [								;-- Data buffer struct, pointer and bytes count
	count  [integer!]
	buffer [byte-ptr!]
]

system-call: context [

	str-buffer: as red-value! 0

	#import [
		LIBC-file cdecl [
			realloc: "realloc" [				"Resize and return allocated memory."
				memory			[byte-ptr!]
				size			[integer!]
				return:			[byte-ptr!]
			]
			strstr: "strstr" [					"Search for sub-string."
				string			[c-string!]
				substring		[c-string!]
				return:			[c-string!]
			]
			strcpy: "strcpy" [					"Copy string including tail marker, return target."
				target			[c-string!]
				source			[c-string!]
				return:			[c-string!]
			]
		]
	]

	#either debug? = yes [
		error-pipe:			"Error Red/System call : pipe creation failed : "
		error-dup2:			"Error Red/System call : calling dup2 : "
		error-sethandle:	"Error Red/System call : SetHandleInformation failed : "
		__red-call-print-error: func [ "Format and print on stderr"
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
					type-c-string! [ sprintf [ (str + length? str) "%s" list/value ] ]
					type-integer!  [ sprintf [ (str + length? str) "%d" list/value ] ]
					type-logic!    [ sprintf [ (str + length? str) "%s" either as logic! list/value [ "true" ][ "false" ] ] ]
					default        [ sprintf [ (str + length? str) "%08Xh" list/value ] ]	;-- print as an hex value
				]
				list: list + 1
				count: count - 1
				zero? count
			]
			len: length? str
			len: len + 1
			str/len: #"^/"
			#switch OS [									;-- Write to stderr, no error check
				Windows  [ io-write get-std-handle STD_ERROR_HANDLE as byte-ptr! str len :len null ]
				#default [ io-write stderr as byte-ptr! str len ]
			]
			free as byte-ptr! str
		]
	][
		#define __red-call-print-error [comment]
	]

	f-desc!: alias struct! [								;-- Files descriptors for posix pipe
		reading  [integer!]
		writing  [integer!]
	]

	insert-string: func [
		str		[red-string!]
		data	[p-buffer!]
		shell?	[logic!]
		/local
			temp	[byte-ptr!]
			buffer	[byte-ptr!]
			len		[integer!]
			count	[integer!]
			sout	[red-string!]
			node	[series!]
	][
		if zero? data/count [exit]

		either TYPE_OF(str) = TYPE_BINARY [
			binary/rs-insert as red-binary! str 0 data/buffer data/count
		][
			sout: either null? str-buffer [
				str-buffer: as red-value! allocate size? red-value!
				string/make-at str-buffer 1024 * 100 Latin1
			][as red-string! str-buffer]
			string/rs-reset sout
			node: GET_BUFFER(sout)

			#either OS = 'Windows [
				buffer: data/buffer
				count: data/count
				either shell? [
					len: 0
					len: MultiByteToWideChar 1 0 buffer count null 0		;-- CP_OEMCP
					if len <= 0 [0]											;TBD free resource and throw error
					temp: allocate len * 2
					MultiByteToWideChar 1 0 buffer count temp len
					unicode/load-utf16 as-c-string temp len sout yes
					free temp
				][
					unicode/load-utf8-buffer as-c-string buffer count node null yes
				]
			][
				unicode/load-utf8-buffer as-c-string data/buffer data/count node null yes
			]
			string/concatenate str sout -1 0 yes yes
		]
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
				        data/buffer: realloc data/buffer size
				    ]
				]
				get-last-error = ERROR_BROKEN_PIPE		;-- Pipe done - normal exit
			]
			data/count: total
		] ; read-from-pipe
		open-file-to-write: func [
			pbuf		[p-buffer!]
			sa			[security-attributes!]
			return:		[integer!]
			/local
				file	[integer!]
		][
			file: create-file
				as c-string! pbuf/buffer
				GENERIC_WRITE
				0
				sa
				OPEN_ALWAYS
				FILE_ATTRIBUTE_NORMAL
				null
			either file = -1 [file: 0][SetFilePointer file 0 null SET_FILE_END]
			file
		]
		call: func [ "Executes a DOS command to run another process."
			cmd           [c-string!]  "The shell command"
			waitend?      [logic!]     "Wait for end of command, implicit if any buffer is set"
			console?      [logic!]     "Redirect outputs to console"
			shell?        [logic!]     "Forces command to be run from shell"
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
			sa/lpSecurityDescriptor: 0
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
			dev-null: create-file #u16 "nul:" GENERIC_WRITE FILE_SHARE_WRITE sa OPEN_EXISTING 0 null		;-- Pipe to nul
			if in-buf <> null [
				either in-buf/count = -1 [
					in-read: create-file
						as c-string! in-buf/buffer
						GENERIC_READ
						0
						sa
						OPEN_EXISTING
						FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN
						null
				][
					if not create-pipe :in-read :in-write sa 0 [	;-- Create a pipe for child's input
						__red-call-print-error [ error-pipe "stdin" ]
						return -1
					]
					if not set-handle-information in-write HANDLE_FLAG_INHERIT 0 [
						__red-call-print-error [ error-sethandle "stdin" ]
						return -1
					]
				]
				s-inf/hStdInput: in-read
			]
			either out-buf <> null [
				either out-buf/count = -1 [
					out-write: open-file-to-write out-buf sa
				][
					out-buf/count: 0
					out-buf/buffer: allocate READ-BUFFER-SIZE
					if not create-pipe :out-read :out-write sa 0 [	;-- Create a pipe for child's output
						__red-call-print-error [ error-pipe "stdout" ]
						return -1
					]
					if not set-handle-information out-read HANDLE_FLAG_INHERIT 0 [
						__red-call-print-error [ error-sethandle "stdout" ]
						return -1
					]
				]
				s-inf/hStdOutput: out-write
			][
				if not console? [						;-- output must be redirected to "nul" or process returns an error code
					s-inf/hStdOutput: dev-null
				]
			]
			either err-buf <> null [
				either err-buf/count = -1 [
					err-write: open-file-to-write err-buf sa
				][
					err-buf/count: 0
					err-buf/buffer: allocate READ-BUFFER-SIZE
					if not create-pipe :err-read :err-write sa 0 [	;-- Create a pipe for child's error
						__red-call-print-error [ error-pipe "stderr" ]
						return -1
					]
					if not set-handle-information err-read HANDLE_FLAG_INHERIT 0 [
						__red-call-print-error [ error-sethandle "stderr" ]
						return -1
					]
				]
				s-inf/hStdError: err-write
			][
				if not console? [
					s-inf/hStdError: dev-null
				]
			]
			if any [ (in-buf <> null) (out-buf <> null) (err-buf <> null) ] [
				waitend?: true
				inherit: true
				s-inf/dwFlags: STARTF_USESTDHANDLES
			]
			if not console? [
				if in-buf  = null [ s-inf/hStdInput:  0 ]
				inherit: true
				s-inf/dwFlags: STARTF_USESTDHANDLES
			]

			sa/bInheritHandle: inherit
			either shell? [
				len: (1 + lstrlen cmd) * 2
				cmdstr: make-c-string (14 + len)
				copy-memory as byte-ptr! cmdstr as byte-ptr! #u16 "cmd /c " 14
				copy-memory as byte-ptr! cmdstr + 14 as byte-ptr! cmd len
			][
				cmdstr: cmd
			]
			if not create-process null cmdstr null null inherit 0 null null s-inf p-inf [
				__red-call-print-error [ "Error Red/System call : CreateProcess : ^"" cmd "^" Error : " get-last-error ]
				if shell? [free as byte-ptr! cmdstr]
				return -1
			]
			if shell? [free as byte-ptr! cmdstr]

			pid: 0
			if in-buf <> null [
				close-handle in-read
				len: in-buf/count
				success: io-write in-write in-buf/buffer len :len null
				if not success [
					__red-call-print-error [ "Error Red/System call : write into pipe failed : " get-last-error ]
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
			either any [console? waitend?][
				wait-for-single-object p-inf/hProcess INFINITE
				get-exit-code-process p-inf/hProcess :pid
			][
				pid: p-inf/dwProcessId
			]
			close-handle p-inf/hProcess
			close-handle p-inf/hThread
			close-handle dev-null
			return pid
		] ; call
	] ; Windows
	#default  [                                         ;-- POSIX
		;-- Shell detection
		shell-name: declare c-string!
		until [
			if null <> strstr system/env-vars/item "SHELL=" [
				shell-name: make-c-string length? system/env-vars/item
				strcpy shell-name (system/env-vars/item + 6)
			]
			system/env-vars: system/env-vars + 1
			system/env-vars/item = null
		]

		set-flags-fd: func [
			fd	[integer!]
			/local
				flags [integer!]
		][
			flags: fcntl [fd F_GETFD 0]
			fcntl [fd F_SETFD flags or 1]				;-- FD_CLOEXEC
			flags: fcntl [fd F_GETFL 0]
			fcntl [fd F_SETFL flags or O_NONBLOCK]
		]

		call: func [                   "Executes a shell command, IO redirections to buffers."
			cmd			[c-string!]    "The shell command"
			waitend?	[logic!]       "Wait for end of command, implicit if any buffer is set"
			console?	[logic!]       "Redirect outputs to console"
			shell?		[logic!]       "Forces command to be run from shell"
			in-buf		[p-buffer!]    "Input data buffer or null"
			out-buf		[p-buffer!]    "Output data buffer or null "
			err-buf		[p-buffer!]    "Error data buffer or null"
			return:		[integer!]
			/local
				pid status err wexp fd-in fd-out fd-err args dev-null str
				pfds nfds fds revents n i input-len nbytes offset size to-read
				out-len err-len out-size err-size pbuf in? out? err?
		][
			in?:  all [in-buf <> null in-buf/count <> -1]
			out?: all [out-buf <> null out-buf/count <> -1]
			err?: all [err-buf <> null err-buf/count <> -1]
			if in? [
				input-len: 0
				fd-in: declare f-desc!
				if (pipe as int-ptr! fd-in) = -1 [		;-- Create a pipe for child's input
					__red-call-print-error [ error-pipe "stdin" ]
					return -1
				]
			]
			if out? [									;- Create buffer for output
				out-len: 0
				out-size: READ-BUFFER-SIZE
				fd-out: declare f-desc!
				if (pipe as int-ptr! fd-out) = -1 [		;-- Create a pipe for child's output
					__red-call-print-error [ error-pipe "stdout" ]
					return -1
				]
			]
			if err? [									;- Create buffer for error
				err-len: 0
				err-size: READ-BUFFER-SIZE
				fd-err: declare f-desc!
				if (pipe as int-ptr! fd-err) = -1 [		;-- Create a pipe for child's error
					__red-call-print-error [ error-pipe "stderr" ]
					return -1
				]
			]

			pid: fork
			if pid = 0 [								;-- Child process
				if in-buf <> null [                     ;-- redirect stdin to the pipe
					either in-buf/count = -1 [			;-- file
						nfds: io-open as c-string! in-buf/buffer O_RDONLY
						if nfds < 0 [quit -1]
						dup2 nfds stdin
						io-close nfds
					][
						io-close fd-in/writing
						err: dup2 fd-in/reading stdin
						if err = -1 [ __red-call-print-error [ error-dup2 "stdin" ]]
						io-close fd-in/reading
					]
				]
				either out-buf <> null [				;-- redirect stdout to the pipe
					either out-buf/count = -1 [
						nfds: _open
							as c-string! out-buf/buffer
							O_BINARY or O_WRONLY or O_CREAT or O_APPEND
							438							;-- 0666
						if nfds < 0 [quit -1]
						dup2 nfds stdout
						io-close nfds
					][
						io-close fd-out/reading
						err: dup2 fd-out/writing stdout
						if err = -1 [ __red-call-print-error [ error-dup2 "stdout" ]]
						io-close fd-out/writing
					]
				][
					if not console? [					;-- redirect stdout to /dev/null.
						dev-null: io-open "/dev/null" O_WRONLY
						err: dup2 dev-null stdout
						if err = -1 [ __red-call-print-error [ error-dup2 "stdout to null" ]]
						io-close dev-null
					]
				]
				either err-buf <> null [				;-- redirect stderr to the pipe
					either err-buf/count = -1 [
						nfds: _open
							as c-string! err-buf/buffer
							O_BINARY or O_WRONLY or O_CREAT or O_APPEND
							438							;-- 0666
						if nfds < 0 [quit -1]
						dup2 nfds stderr
						io-close nfds
					][
						io-close fd-err/reading
						err: dup2 fd-err/writing stderr
						if err = -1 [ __red-call-print-error [ error-dup2 "stderr" ]]
						io-close fd-err/writing
					]
				][
					if not console? [					;-- redirect stderr to /dev/null.
						dev-null: io-open "/dev/null" O_WRONLY
						err: dup2 dev-null stderr
						if err = -1 [ __red-call-print-error [ error-dup2 "stderr to null" ]]
						io-close dev-null
					]
				]
				if all [(in-buf = null) (not console?)] [ io-close stdin ]	;-- no redirection, stdin closed
				either shell? [
					args: as str-array! allocate 4 * size? c-string!
					args/item: shell-name	args: args + 1
					args/item: "-c"			args: args + 1
					args/item: cmd			args: args + 1
					args/item: null
					args: args - 3						;-- reset args pointer
					execvp shell-name args				;-- Process is launched here, execvp with str-array parameters
				][
					wexp: declare wordexp-type!				;-- Create wordexp struct
					status: wordexp cmd wexp WRDE_SHOWERR	;-- Parse cmd into str-array
					either status = 0 [						;-- Parsing ok
						execvp wexp/we_wordv/item wexp/we_wordv ;-- Process is launched here, execvp with str-array parameters
					][										;-- Parsing nok
						__red-call-print-error [ "Error Red/System call, wordexp parsing command : " cmd ]

						switch status [
							WRDE_NOSPACE [ __red-call-print-error [ "Attempt to allocate memory failed" ]	 ]
							WRDE_BADCHAR [ __red-call-print-error [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" ]	 ]
							WRDE_BADVAL  [ __red-call-print-error [ "Reference to undefined shell variable" ]	 ]
							WRDE_CMDSUB  [ __red-call-print-error [ "Command substitution requested" ]	 ]
							WRDE_SYNTAX  [ __red-call-print-error [ "Shell syntax error, such as unbalanced parentheses or unterminated string" ]	 ]
						]
					]
				]
				;-- get here only when exec fails
				quit -1
			]
			if pid > 0 [								;-- Parent process
				nfds: 0
				pfds: as pollfd! allocate 3 * size? pollfd!
				if in? [
					waitend?: true
					fds: pfds + nfds
					fds/fd: fd-in/writing
					set-flags-fd fds/fd
					fds/events: POLLOUT
					io-close fd-in/reading
					nfds: nfds + 1
				]
				if out? [								;- Create buffer for output
					waitend?: true
					out-buf/count: 0
					out-buf/buffer: allocate READ-BUFFER-SIZE
					fds: pfds + nfds
					fds/fd: fd-out/reading
					set-flags-fd fds/fd
					fds/events: POLLIN
					io-close fd-out/writing
					nfds: nfds + 1
				]
				if err? [								;- Create buffer for error
					waitend?: true
					err-buf/count: 0
					err-buf/buffer: allocate READ-BUFFER-SIZE
					fds: pfds + nfds
					fds/fd: fd-err/reading
					set-flags-fd fds/fd
					fds/events: POLLIN
					io-close fd-err/writing
					nfds: nfds + 1
				]
				n: nfds
				while [n > 0][
					i: waitpid pid :status 1				;-- WNOHANG: 1
					if i = -1 [break]
					if i = pid [
						if out-buf <> null [
							nbytes: io-read fd-out/reading out-buf/buffer + out-len out-size - out-len
							if nbytes > 0 [out-len: out-len + nbytes]
							io-close fd-out/reading
						]
						if err-buf <> null [
							nbytes: io-read fd-err/reading err-buf/buffer + err-len err-size - err-len
							if nbytes > 0 [err-len: err-len + nbytes]
							io-close fd-err/reading
						]
						break
					]
					if 0 > poll pfds nfds -1 [n: 0]

					i: 0
					while [all [i < nfds n > 0]][
						fds: pfds + i
						i: i + 1
						revents: fds/events >>> 16
						case [
							revents and POLLERR <> 0 [
								io-close fds/fd
								fds/fd: -1
								n: n - 1
							]
							revents and POLLOUT <> 0 [
								nbytes: io-write fds/fd in-buf/buffer + input-len in-buf/count - input-len
								if nbytes <= 0 [n: 0 nbytes: in-buf/count]
								input-len: input-len + nbytes
								if input-len >= in-buf/count [
									io-close fds/fd
									fds/fd: -1
									n: n - 1
								]
							]
							revents and POLLIN <> 0 [
								case [
									fds/fd = fd-out/reading [
										pbuf: out-buf
										offset: :out-len
										size: :out-size
									]
									fds/fd = fd-err/reading [
										pbuf:	err-buf
										offset: :err-len
										size: :err-size
									]
									true [0]
								]
								until [
									to-read: size/value - offset/value
									nbytes: io-read fds/fd pbuf/buffer + offset/value to-read    ;-- read pipe, store into buffer
									if nbytes < 0 [break]
									if nbytes = 0 [
										io-close fds/fd
										fds/fd: -1
										n: n - 1
									]
									offset/value: offset/value + nbytes
									if offset/value >= size/value [
										size/value: size/value + READ-BUFFER-SIZE
										pbuf/buffer: realloc pbuf/buffer size/value 
										if null? pbuf/buffer [n: -1 break]
									]
									nbytes <> to-read
								]
								pbuf/count: offset/value
							]
							revents and POLLHUP <> 0 [io-close fds/fd fds/fd: -1 n: n - 1]
							revents and POLLNVAL <> 0 [n: -1]
							true [0]
						]
					]
				]

				if console? [waitend?: yes]
				if waitend? [
					waitpid pid :status 0				;-- Wait child process terminate
					either (status and 00FFh) <> 0 [	;-- a signal occured. Low byte contains stop code
						pid: -1
					][
						pid: status >> 8				;-- High byte contains exit code
					]
				]
				free as byte-ptr! pfds
			]
			pid
		] ; call
	] ; #default
	] ; #switch
] ; context

