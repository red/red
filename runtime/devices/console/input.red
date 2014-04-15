Red []

#system [

	terminal: context [
		#define OS_POLLIN 		1

		#define TERM_VTIME		5
		#define TERM_VMIN		6

		#define TERM_BRKINT		00000002h
		#define TERM_INPCK		00000020h
		#define TERM_ISTRIP		00000040h
		#define TERM_ICRNL		00000400h
		#define TERM_IXON		00002000h
		#define TERM_OPOST		00000001h
		#define TERM_CS8		00000060h
		#define TERM_ISIG		00000001h
		#define TERM_ICANON		00000002h
		#define TERM_ECHO		00000010h
		#define TERM_IEXTEN		01000000h
		#define TERM_VOODOO		00000008h					;-- undocumented value...

		#define TERM_TCSADRAIN	1

		#either OS = 'MacOSX [
			#define TIOCGWINSZ	40087468h
		][
			#define TIOCGWINSZ	5413h
		]

		pollfd!: alias struct! [
			fd				[integer!]
			events			[integer!]						;-- high 16-bit: events
		]													;-- low  16-bit: revents

		winsize!: alias struct! [
			rowcol			[integer!]
			xypixel			[integer!]
		]

		termios!: alias struct! [
			c_iflag			[integer!]
			c_oflag			[integer!]
			c_cflag			[integer!]
			c_lflag			[integer!]
			c_line			[byte!]
			c_cc1			[byte!]							;-- c_cc[32]
			c_cc2			[byte!]
			c_cc3			[byte!]
			c_cc4			[integer!]
			c_cc5			[integer!]
			c_cc6			[integer!]
			c_cc7			[integer!]
			c_cc8			[integer!]
			c_cc9			[integer!]
			c_cc10			[integer!]
			pad				[integer!]						;-- for proper alignment
			c_ispeed		[integer!]
			c_ospeed		[integer!]
		]

		#import [
			LIBC-file cdecl [
				tcgetattr: "tcgetattr" [
					fd		[integer!]
					termios [termios!]
					return: [integer!]
				]
				tcsetattr: "tcsetattr" [
					fd			[integer!]
					opt_actions [integer!]
					termios 	[termios!]
					return: 	[integer!]
				]
				read: "read" [
					fd		[integer!]
					buf		[byte-ptr!]
					size	[integer!]
					return: [integer!]
				]
				write: "write" [
					fd		[integer!]
					buf		[byte-ptr!]
					size	[integer!]
					return: [integer!]
				]
				poll: "poll" [
					fds		[pollfd!]
					nfds	[integer!]
					timeout [integer!]
					return: [integer!]
				]
				ioctl: "ioctl" [
					fd		[integer!]
					request	[integer!]
					ws		[winsize!]
					return: [integer!]
				]
			]
		]

		#enum special-key! [
			KEY_UNSET:		 -1
			KEY_NONE:		  0
			KEY_UP:			-20
			KEY_DOWN:		-21
			KEY_RIGHT:		-22
			KEY_LEFT:		-23
			KEY_END:		-24
			KEY_HOME:		-25
			KEY_INSERT:		-26
			KEY_DELETE:		-27
			KEY_PAGE_UP:	-28
			KEY_PAGE_DOWN:	-29
			KEY_ENTER:		-30
			KEY_BACKSPACE:	-31
		]

		#define KEY-CTRL-A	#"^A"
		#define	KEY-CTRL-E	#"^E"

		saved-term: declare termios!
		utf-char:	declare c-string!
		poller: 	declare pollfd!
		input-line: declare red-string!
		saved-line:	declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		columns:	-1
		lines-y:	 0
		caret-y:	 0


		fd-read-char: func [
			timeout [integer!]
			return: [byte!]
			/local
				c [byte!]
		][
			c: as-byte -1
			if any [
				zero? poll poller 1 timeout
				1 <> read stdin :c 1
			][
				return as-byte -1
			]
			c
		]

		fd-read: func [
			return: [integer!]								;-- input codepoint or -1
			/local
				c	[integer!]
				len [integer!]
				i	[integer!]
				p	[byte-ptr!]
		][
			if 1 <> read stdin as byte-ptr! utf-char 1 [return -1]
			c: as-integer utf-char/1
			case [
				c and 80h = 0	[len: 1]
				c and E0h = C0h [len: 2]
				c and F0h = E0h [len: 3]
				c and F8h = F0h [len: 4]
			]
			if any [len < 1 len > 4][return -1]

			i: 1
			while [i < len][
				if all [
					len >= (i + 1)
					1 <> read stdin as byte-ptr! utf-char + i 1
				][
					return -1
				]
				i: i + 1
			]
			c: unicode/decode-utf8-char utf-char :len
			switch c [
				#"^(0A)" [KEY_ENTER]
				#"^(7F)" [KEY_BACKSPACE]
				default  [c]
			]
		]

		check-special: func [
			return: [integer!]
			/local
				c  [byte!]
				c2 [byte!]
		][
			c: fd-read-char 50
			if (as-integer c) < 0 [return 27]

			c2: fd-read-char 50
			if (as-integer c) < 0 [return as-integer c2]

			if any [c = #"[" c = #"O"][
				switch c2 [
					#"A" [return KEY_UP]
					#"B" [return KEY_DOWN]
					#"C" [return KEY_RIGHT]
					#"D" [return KEY_LEFT]
					#"F" [return KEY_END]
					#"H" [return KEY_HOME]
				]
			]
			if all [c = #"[" #"1" <= c2 c2 <= #"8"][
				c: fd-read-char 50
				if c = #"~" [
					switch c2 [
						#"2" [return KEY_INSERT]
						#"3" [return KEY_DELETE]
						#"5" [return KEY_PAGE_UP]
						#"6" [return KEY_PAGE_DOWN]
						#"7" [return KEY_HOME]
						#"8" [return KEY_END]
					]
				]
				while [all [(as-integer c) <> -1 c <> #"~"]][
					c: fd-read-char 50
				]
			]
			KEY_NONE
		]

		emit: func [c [byte!]][
			write stdout :c 1
		]

		emit-string: func [
			s [c-string!]
		][
			write stdout as byte-ptr! s length? s
		]
		
		emit-string-int: func [
			begin [c-string!]
			n	  [integer!]
			end	  [byte!]
		][
			emit-string begin
			emit-string integer/form-signed n
			emit end
		]

		emit-red-string: func [
			str	 [red-string!]
			size [integer!]
			/local
				series	[series!]
				offset	[byte-ptr!]
				tail	[byte-ptr!]
				max		[byte-ptr!]
				unit	[integer!]
				cp		[integer!]
		][
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (unit >> 1))
			tail:   as byte-ptr! series/tail
			max:	offset + (size << (unit >> 1))
			
			if max < tail [tail: max]

			while [offset < tail][
				cp: string/get-char offset unit

				case [
					cp <= 7Fh [
						emit as-byte cp
					]
					cp <= 07FFh [
						emit as-byte cp >> 6 or C0h
						emit as-byte cp and 3Fh or 80h
					]
					cp <= FFFFh [
						emit as-byte cp >> 12 or E0h
						emit as-byte cp >> 6 and 3Fh or 80h
						emit as-byte cp and 3Fh or 80h
					]
					cp <= 001FFFFFh [
						emit as-byte cp >> 18 or F0h
						emit as-byte cp >> 12 and 3Fh or 80h
						emit as-byte cp >>  6 and 3Fh or 80h
						emit as-byte cp and 3Fh or 80h
					]
					true [
						print-line "Error in emit-red-string: codepoint > 1FFFFFh"
					]
				]
				offset: offset + unit
			]
		]

		query-cursor: func [
			return: [logic!]								;-- FALSE: failed to retrieve it
			/local
				c [byte!]
				n [integer!]
		][
			emit-string "^[[6n"								;-- ask for cursor location		
			if all [
				  esc = fd-read-char 100
				 #"[" = fd-read-char 100
			][
				while [true][
					c: fd-read-char 100
					n: 0
					case [
						c = #";" [n: 0]
						all [c = #"R" n <> 0 n < 1000][
							columns: n
							return true
						]
						all [#"0" <= c c <= #"9"][
							n: n * 10 + (c - #"0")
						]
						true [
							columns: n
							return true
						]
					]
				]
			]
			false
		]

		get-window-size: func [
			/local 
				ws	 [winsize!]
				here [integer!]
		][
			ws: declare winsize!

			if zero? ioctl stdout TIOCGWINSZ ws [
				columns: ws/rowcol >> 16
				exit
			]

			if zero? columns [
				columns: 80

				if query-cursor [
					here: columns
					emit-string "^[[999C"

					either query-cursor [
						if columns > here [				;-- reset cursor position
							emit-string-int "^[[" columns - here #"D"
						]
					][
						emit cr
					]
				]
			]
		]

		refresh: func [
			/local
				line   [red-string!]
				offset [integer!]
				x	   [integer!]
				y	   [integer!]
				saved  [integer!]
				psize  [integer!]
		][
			line: 	input-line
			psize: 	string/rs-length? prompt
			offset: psize + line/head
			x: 		offset // columns
			y: 		(offset + string/rs-length? line) / columns
				
			if y > lines-y [emit-string "^[D"]			;-- scroll one line up 
			if y < lines-y [emit-string "^[7^[[H^[M^[8"] ;-- scroll one line down preserving cursor
			lines-y: y
			
			emit-string "^[7"							;-- save cursor position/attributs
			if caret-y > 0 [emit-string-int "^[[" caret-y #"A"]		;-- move cursor up <n> lines
			saved: line/head
			y: 0
			until [
				emit #"^(0D)"							;-- set cursor left
				either zero? y [
					emit-red-string prompt columns
					line/head: 0
					emit-red-string line columns - psize ;-- output from head to EOL
				][
					emit-string "^[E"					;-- move to next line
					line/head: (y - 1) * columns + (columns - psize)
					emit-red-string line columns		;-- output from head to EOL
				]
				y: y + 1
				y = (lines-y + 1)
			]
			line/head: saved
			emit-string "^[[0K^[8"						;-- erase to EOL, restore cursor position/attributs

			y: offset / columns
			if y > caret-y [emit-string "^[[1B"]		;-- move cursor down one line
			if y < caret-y [emit-string "^[[1A"]		;-- move cursor up one line
			caret-y: y

			either zero? x [
				emit #"^(0D)"
			][
				emit-string-int "^(0D)^[[" x #"C"		 ;-- set cursor position
			]
		]
		
		on-resize: does [
			get-window-size
			refresh
		]
		
		fetch-history: does [
			string/rs-reset input-line
			string/concatenate input-line as red-string! block/rs-head history -1 0 yes no
			input-line/head: string/get-length input-line yes
		]

		init: func [
			line 	 [red-string!]
			hist-blk [red-block!]
			/local
				term [termios!]
				cc	 [byte-ptr!]
				so	 [sigaction!]
		][
			utf-char: as-c-string allocate 10
			
			copy-cell as red-value! line as red-value! input-line
			copy-cell as red-value! hist-blk as red-value! history
			
			so: declare sigaction!						;-- install resizing signal trap
			so/sigaction: as-integer :on-resize
			so/flags: 	SA_SIGINFO ;or SA_RESTART
			sigaction SIGWINCH so as sigaction! 0
	
			term: declare termios!
			tcgetattr stdin saved-term					;@@ check returned value

			copy-memory 
				as byte-ptr! term
				as byte-ptr! saved-term
				size? term

			term/c_iflag: term/c_iflag and not (
				TERM_BRKINT or TERM_ICRNL or TERM_INPCK or TERM_ISTRIP or TERM_IXON
			)
			term/c_oflag: term/c_oflag and not TERM_OPOST
			term/c_cflag: term/c_cflag or TERM_CS8
			term/c_lflag: term/c_lflag and not (
				TERM_VOODOO or TERM_ECHO or TERM_ICANON or TERM_IEXTEN or TERM_ISIG
			)
			cc: (as byte-ptr! term) + (4 * size? integer!) + 2
			cc/TERM_VMIN:  as-byte 1
			cc/TERM_VTIME: as-byte 0

			tcsetattr stdin TERM_TCSADRAIN term
			emit-string "^[[?7l"						;-- disable auto-wrap
			
			poller/fd: stdin
			poller/events: OS_POLLIN
		]

		edit: func [
			prompt-str [red-string!]
			/local
				line   [red-string!]
				c	   [integer!]
				offset [integer!]
		][
			line: input-line			
			copy-cell as red-value! prompt-str as red-value! prompt
			history/head: block/rs-length? history		;@@ set history list to tail (temporary)
				
			get-window-size
			emit-red-string prompt columns
			refresh

			while [true][
				c: fd-read
				if c = 27 [c: check-special]

				switch c [
					KEY_ENTER [
						exit
					]
					KEY_BACKSPACE [
						unless zero? line/head [
							line/head: line/head - 1
							string/remove-char line line/head
							refresh
						]
					]
					KEY_LEFT [
						unless zero? line/head [
							line/head: line/head - 1
							refresh
						]
					]
					KEY_RIGHT [
						if 0 < string/rs-length? line [
							line/head: line/head + 1
							refresh
						]
					]
					KEY_UP [
						unless zero? history/head [
							history/head: history/head - 1
							fetch-history
							line/head: string/get-length line yes
							refresh
						]
					]
					KEY_DOWN [
						unless block/rs-tail? history [
							history/head: history/head + 1
							either block/rs-tail? history [
								string/rs-reset line
							][
								fetch-history
							]
							refresh
						]
					]
					KEY_HOME 
					KEY-CTRL-A [
						line/head: 0
						refresh
					]
					KEY_END
					KEY-CTRL-E [
						line/head: string/get-length line yes
						refresh
					]
					KEY_UNSET []						;-- do nothing
					
					default [
						either zero? string/rs-length? line [
							string/append-char GET_BUFFER(line) c
						][
							string/insert-char GET_BUFFER(line) line/head c
						]
						line/head: line/head + 1
						refresh
					]
				]
			]
			line/head: 0
		]

		restore: does [
			emit-string "^[[?7h"						;-- enable auto-wrap
			tcsetattr stdin TERM_TCSADRAIN saved-term			
		]
	]
]

init-console: routine [line [string!] hist [block!]][
	terminal/init line hist
]

input: routine [prompt [string!]][
	terminal/edit prompt
	terminal/restore
]


input-line: make string! 10'000

history: [
	"hello world"
	{print mold [append "hello" [40 + 2] "world"]}
	"mold 2 + 3"
	"1 + 2"
]

init-console input-line history

input "red> "
print lf

print ["input:" mold head input-line]
