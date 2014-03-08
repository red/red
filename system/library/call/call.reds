Red/System [
	Title:   "Red/System call binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %call.reds
	Rights:  "Copyright (c) 2014 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.4.1
		%stdio.reds
		%unistd.reds
		%windows.reds
	}
	Purpose: {
		This binding implements a call function for Red/System (similar to rebol's call function).
		POSIX version uses "wordexp" function to perform word expansion.
		Windows version performs home made string parsing (no expansion nor substitution).
		Any proposal to improve this parsing (with native Windows functions) is welcome.
	}
	Reference: {
		POSIX wordexp :
		http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html
	}
]

#include %../stdio.reds
#switch OS [
	Windows   [ #include %../windows.reds ]
	#default  [ #include %../unistd.reds  ]
]

#define READ-BUFFER-SIZE 4096

; Data buffer struct, pointer and count
p-buffer!: alias struct! [
	count  [integer!]
	buffer [byte-ptr!]
]

; Files descriptors for pipe
f-desc!: alias struct! [
	reading  [integer!]
	writing  [integer!]
]


system-call: context [
with stdcalls [
	; Global var to store outputs values before setting call output and error refinements
	outputs: declare struct! [
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

	print-str-array: func [ "Print str-array, used for debug"
		args [str-array!]
	][
		while [ args/item <> null ][
			print [ "- " args/item lf ]
			args: args + 1
		]
	]

	resize-buffer: func [   "Reallocate buffer, error check"
		buffer       [byte-ptr!]
		newsize      [integer!]
		return:      [byte-ptr!]
	][
	tmp: re-allocate buffer newsize                 ;-- Resize output buffer to new size
	either tmp = null [                             ;-- reallocation failed, uses current output buffer
		print [ "Red/System resize-buffer : Memory allocation failed." lf ]
		halt
	][ buffer: tmp ]                                ; reallocation succeeded, uses reallocated buffer
		return buffer
	]

	#switch OS [
	Windows   [      ; Windows, use minimal home made parsing
		read-from-pipe: func [      "Read data from pipe fd into buffer"
		fd           [opaque!]      "File descriptor"
		data         [p-buffer!]
		/local
		len          [integer!]
		count        [integer!]
		total        [integer!]
		success      [logic!]
		][
		len: READ-BUFFER-SIZE                                              ; initial buffer size and grow step
		count: 0
		total: 0
		success: true
		until [
			len: 0
			success: read-file fd (data/buffer + total) (READ-BUFFER-SIZE - count) :len null
;            print [ "Bytes read : " len " - " success "^/" ]
			if len > 0 [
				total: total + len
				count: count + len
				if count = READ-BUFFER-SIZE [
					data/buffer: resize-buffer data/buffer (total + READ-BUFFER-SIZE)
					count: 0
				]
			]
			any [ (not success) (len = 0) ]
		]
;          if not success [ print [ "Error : " get-last-error lf ] ]
		data/buffer: resize-buffer data/buffer (total + 1)                 ; Resize output buffer to minimum size
		data/count: total
;		data/count/total: null-byte  ; Tests needed ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		print [ "Total bytes read : " total lf ]
		] ; read-from-pipe
		call: func [		"Executes a DOS command to run another process."
			cmd          [c-string!]       "The shell command"
			waitend      [logic!]          "Wait for end of command, implicit if out-buf is set"
			in-buf       [p-buffer!]       "Pointer to input data or null"
			out-buf      [p-buffer!]       "Pointer to output data buffer or null"
			err-buf      [p-buffer!]       "Pointer to error data buffer or null"
			return:      [integer!]
			/local
				pid          [integer!]
				inherit      [logic!]
				in-read      [opaque!]
				in-write     [opaque!]
				out-read     [opaque!]
				out-write    [opaque!]
				sa p-inf s-inf
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
			if out-buf <> null [
				out-buf/count: 0
				out-buf/buffer: allocate READ-BUFFER-SIZE
				if not create-pipe :out-read :out-write sa 0 [    ; Create a pipe for child's output
					print "Error Red/System call : stdou pipe creation failed^/"  halt
				]
				if not set-handle-information out-read HANDLE_FLAG_INHERIT 0 [
					print "Error Red/System call : SetHandleInformation failed^/"  halt
				]
				waitend: false                             ; child's process is completed after end of pipe
				inherit: true
				s-inf/dwFlags: 00000100h                   ; STARTF_USESTDHANDLES
				s-inf/hStdOutput: out-write
			]
			if err-buf <> null [
				err-buf/count: 0
				err-buf/buffer: allocate READ-BUFFER-SIZE
				if not create-pipe :err-read :err-write sa 0 [    ; Create a pipe for child's error output
					print "Error Red/System call : stderr pipe creation failed^/"  halt
				]
				if not set-handle-information err-read HANDLE_FLAG_INHERIT 0 [
					print "Error Red/System call : SetHandleInformation failed^/"  halt
				]
				waitend: false                             ; child's process is completed after end of pipe
				inherit: true
				s-inf/dwFlags: 00000100h                   ; STARTF_USESTDHANDLES
				s-inf/hStdError:  err-write
			]

	;          s-inf/hStdInput:  in-read
			if not create-process null cmd 0 0 inherit 0 0 null s-inf p-inf [
				print "Error Red/System call while calling CreateProcess : {" cmd "}^/"
				quit 1
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
			outputs/out: out-buf                  ; Store values in global var
			outputs/err: err-buf
			return pid
		] ; call
	] ; Windows
	#default  [      ; POSIX
		read-from-pipe: func [      "Read data from pipe fd into buffer"
			fd           [f-desc!]       "File descriptor"
			data         [p-buffer!]
			/local
				cpt          [integer!]
				total        [integer!]
		][
			close fd/writing                                                   ; close unused pipe end
			cpt: READ-BUFFER-SIZE                                              ; initial buffer size and grow step
			total: 0
			while [cpt = READ-BUFFER-SIZE ][                   ; FIX: there's a bug here, need to test errno
				cpt: ioread fd/reading (data/buffer + total) READ-BUFFER-SIZE    ; read pipe, store into buffer
				if cpt > -1 [
					total: total + cpt
					if cpt = READ-BUFFER-SIZE [                                      ; buffer must be expanded
						data/buffer: resize-buffer data/buffer (total + READ-BUFFER-SIZE)
					]
				]
			]
			data/buffer: resize-buffer data/buffer (total + 1)                 ; Resize output buffer to minimum size
			data/count: total
			close fd/reading                                                   ; close other pipe end
		] ; read-from-pipe
		expand-and-exec: func[         "Use wordexp to parse command and run it. Halt if error. Should never return"
			cmd          [c-string!]       "The shell command"
			return:      [integer!]
			/local
			status       [integer!]
			wexp
		][
			wexp: as wordexp-type! allocate size? wordexp-type!      ; Create wordexp struct
			status: wordexp cmd wexp WRDE_SHOWERR                              ; Parse cmd into str-array
			either status = 0 [                           ; Parsing ok
	;          print-str-array wexp/we_wordv                         ; Debug: Print expanded values
				execvp wexp/we_wordv/item wexp/we_wordv                ; Call execvp with str-array parameters
				print [ "Error Red/System call while calling execvp : {" cmd "}" lf ]  ; Should never occur
				quit 1
			][                                            ; Parsing nok
				print [ "Error Red/System call, wordexp parsing command : " cmd lf ]
				switch status [
				WRDE_NOSPACE [ print [ "Attempt to allocate memory failed" lf ] ]
				WRDE_BADCHAR [ print [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" lf ] ]
				WRDE_BADVAL  [ print [ "Reference to undefined shell variable" lf ] ]
				WRDE_CMDSUB  [ print [ "Command substitution requested" lf ] ]
				WRDE_SYNTAX  [ print [ "Shell syntax error, such as unbalanced parentheses or unterminated string" lf ] ]
				]
				quit status
			]
			return -1
		] ; expand-and-exec

		call: func [                   "Executes a shell command, IO redirections to buffers."
			cmd          [c-string!]       "The shell command"
			waitend      [logic!]          "Wait for end of command, implicit if out-buf is set"
			in-buf       [p-buffer!]       "Pointer to input data or null"
			out-buf      [p-buffer!]       "Pointer to output data buffer or null"
			err-buf      [p-buffer!]       "Pointer to error data buffer or null"
			return:      [integer!]
			/local
				pid          [integer!]
				status       [integer!]
				err          [integer!]
				fd-in fd-out fd-err
			][
			if in-buf <> null [
				fd-in: declare f-desc!
				if (pipe as int-ptr! fd-in) = -1 [     ; Create a pipe for child's input
					print "Error Red/System call : Input pipe creation failed^/"  halt
				]
			]
			if out-buf <> null [
				out-buf/count: 0
				out-buf/buffer: allocate READ-BUFFER-SIZE
				fd-out: declare f-desc!
				if (pipe as int-ptr! fd-out) = -1 [    ; Create a pipe for child's output
					print "Error Red/System call : Output pipe creation failed^/"  halt
				]
			]
			if err-buf <> null [
				err-buf/count: 0
				err-buf/buffer: allocate READ-BUFFER-SIZE
				fd-err: declare f-desc!
				if (pipe as int-ptr! fd-err) = -1 [    ; Create a pipe for child's error
					print "Error Red/System call : Error pipe creation failed^/"  halt
				]
			]
			pid: fork
			either pid = 0 [                        ;----- Child process -----
				if in-buf <> null [                   ; redirect stdin to the pipe
				close fd-in/writing
				err: dup2 fd-in/reading stdin
				if err = -1 [ print "Error Red/System call : Error dup2 stdin^/" halt ]
					close fd-in/reading
				]
				if out-buf <> null [                  ; redirect stdout to the pipe
					close fd-out/reading
				err: dup2 fd-out/writing stdout
				if err = -1 [ print "Error Red/System call : Error dup2 stdout^/" halt ]
					close fd-out/writing
				]
				if err-buf <> null [                  ; redirect stderr to the pipe
					close fd-err/reading
				err: dup2 fd-err/writing stderr
				if err = -1 [ print "Error Red/System call : Error dup2 stderr^/" halt ]
					close fd-err/writing
				]
				expand-and-exec cmd
			][                                      ;----- Parent process -----
				if in-buf <> null [                   ; write input buffer to child process' stdin
					close fd-in/reading
					iowrite fd-in/writing in-buf/buffer in-buf/count
					close fd-in/writing
					waitend: true
				]
				if out-buf <> null [                  ; read output from pipe, store in buffer
					read-from-pipe fd-out out-buf       ; read output buffer from child process' stdout
					waitend: false                      ; child's process is completed after end of pipe
					pid: 0                              ; Process is completed, return 0
				]
				if err-buf <> null [                  ; Same with error stream
					read-from-pipe fd-err err-buf
					waitend: false
					pid: 0
				]
				if waitend [
					status: 0
					waitpid pid :status 0               ; Wait child process terminate
					pid: 0                              ; Process is completed, return 0
				]
				outputs/out: out-buf                  ; Store values in global var
				outputs/err: err-buf
			] ; either pid
			return pid
		] ; call

	] ; #default
	] ; #switch
] ; with stdcalls
] ; context