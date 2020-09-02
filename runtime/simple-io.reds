Red/System [
	Title:	"Simple file IO functions (temporary)"
	Author: "Nenad Rakocevic"
	File: 	%simple-io.reds
	Tabs: 	4
	Rights: "Copyright (C) 2012-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

simple-io: context [

	#enum red-io-mode! [
		RIO_READ:	1
		RIO_WRITE:	2
		RIO_APPEND:	4
		RIO_SEEK:	8
		RIO_NEW:	16
	]

	read-buf: as byte-ptr! 0

	strupr: func [
		"ASCII only"
		str		[c-string!]
		return: [c-string!]
		/local
			s	[c-string!]
			c	[byte!]
	][
		s: str
		while [
			c: s/1
			c <> null-byte
		][
			if c >= #"a" [s/1: c - #" "]
			s: s + 1
		]
		str
	]

	make-dir: func [
		path	[c-string!]
		return: [logic!]
	][
		#either OS = 'Windows [
			CreateDirectory path null
		][
			zero? mkdir path 511						;-- 0777
		]
	]

	open-file: func [
		filename [c-string!]
		mode	 [integer!]
		unicode? [logic!]
		return:	 [integer!]
		/local
			file   [integer!]
			modes  [integer!]
			access [integer!]
	][
		#either OS = 'Windows [
			either mode and RIO_READ <> 0 [
				modes: GENERIC_READ
				access: OPEN_EXISTING
			][
				modes: GENERIC_WRITE
				either any [
					mode and RIO_APPEND <> 0
					mode and RIO_SEEK <> 0
				][
					access: OPEN_ALWAYS
				][
					access: CREATE_ALWAYS
				]
				if mode and RIO_APPEND <> 0 [
					modes: FILE_APPEND_DATA
				]
			]
			either unicode? [
				file: CreateFileW
					filename
					modes
					FILE_SHARE_READ or FILE_SHARE_WRITE
					null
					access
					FILE_ATTRIBUTE_NORMAL
					null
			][
				file: CreateFileA
					filename
					modes
					FILE_SHARE_READ or FILE_SHARE_WRITE
					null
					access
					FILE_ATTRIBUTE_NORMAL
					null
			]
		][
			either mode and RIO_READ <> 0 [
				modes: O_BINARY or O_RDONLY
				access: S_IREAD
			][
				modes: O_BINARY or O_WRONLY or O_CREAT
				either mode and RIO_APPEND <> 0 [
					modes: modes or O_APPEND
				][
					if mode and RIO_SEEK = 0 [modes: modes or O_TRUNC]
				]
				access: S_IREAD or S_IWRITE or S_IRGRP or S_IWGRP or S_IROTH
			]
			file: LibC.open filename modes access
		]
		if file = -1 [return -1]
		file
	]
	
	file-size?: func [
		file	 [integer!]
		return:	 [integer!]
		/local
			s	 [stat! value]
	][
		#case [
			OS = 'Windows [
				GetFileSize file null
			]
			any [OS = 'macOS OS = 'FreeBSD OS = 'Android] [
				_stat file s
				s/st_size
			]
			true [ ; else
				_stat 3 file s
				s/st_size
			]
		]
	]

	file-exists?: func [
		path	[c-string!]
		return: [logic!]
	][
		#either OS = 'Windows [
			-1 <> GetFileAttributesW path
		][
			-1 <> libC.access path 0					;-- F_OK: 0
		]
	]

	seek-file: func [
		file	[integer!]
		offset	[integer!]
	][
		#case [
			OS = 'Windows [
				SetFilePointer file offset null SET_FILE_BEGIN
			]
			OS = 'macOS [
				lseek file offset 0 0					;@@ offset is 64bit
			]
			true [
				lseek file offset 0						;-- SEEK_SET
			]
		]
	]

	read-data: func [
		file	[integer!]
		buffer	[byte-ptr!]
		size	[integer!]
		return:	[integer!]
		/local
			len [integer!]
			res [integer!]
	][
		#either OS = 'Windows [
			len: 0
			res: ReadFile file buffer size :len null
			either zero? res [-1][len]
		][
			LibC.read file buffer size
		]
	]

	write-data: func [
		file	[integer!]
		data	[byte-ptr!]
		size	[integer!]
		return:	[integer!]
		/local
			len [integer!]
			ret	[integer!]
	][
		#either OS = 'Windows [
			len: 0
			ret: WriteFile file data size :len null
			ret: either zero? ret [-1][len]
		][
			ret: LibC.write file data size
		]
		ret
	]

	close-file: func [
		file	[integer!]
		return:	[logic!]
	][
		#either OS = 'Windows [
			CloseHandle as handle! file
		][
			zero? LibC.close file
		]
	]

	lines-to-block: func [
		src		[byte-ptr!]								;-- UTF-8 input buffer
		size	[integer!]								;-- size of src in bytes (excluding terminal NUL)
		return: [red-block!]
		/local
			blk		[red-block!]
			start	[byte-ptr!]
			end		[byte-ptr!]
	][
		blk: block/push-only* 1
		if zero? size [return blk]

		start: src
		until [
			if src/1 = lf [
				end: src - 1
				if end/1 <> cr [end: src]
				string/load-in as-c-string start as-integer end - start blk UTF-8
				start: src + 1
			]
			size: size - 1
			src: src + 1
			zero? size
		]
		if start <> src [string/load-in as-c-string start as-integer src - start blk UTF-8]
		blk
	]

	read-file: func [
		filename [c-string!]
		part	 [integer!]
		offset	 [integer!]
		binary?	 [logic!]
		lines?	 [logic!]
		unicode? [logic!]
		return:	 [red-value!]
		/local
			buffer	[byte-ptr!]
			file	[integer!]
			size	[integer!]
			val		[red-value!]
			str		[red-string!]
			len		[integer!]
			type	[integer!]
	][
		unless unicode? [								;-- only command line args need to be checked
			if filename/1 = #"^"" [filename: filename + 1]	;-- FIX: issue #1234
			len: length? filename
			if filename/len = #"^"" [filename/len: null-byte]
		]
		file: open-file filename RIO_READ unicode?
		if file < 0 [return none-value]

		size: file-size? file

		if zero? size [				;-- /proc filesystem give 0 size
			if null? read-buf [read-buf: allocate 65536]
			while [
				len: read-data file read-buf 65536
				len > 0
			][
				size: size + len
			]
			if offset < 0 [seek-file file 0]
		]

		if size <= 0 [
			close-file file
			val: stack/push*
			string/rs-make-at val 1
			type: either binary? [TYPE_BINARY][TYPE_STRING]
			set-type val type
			return val
		]

		if offset >= 0 [
			seek-file file offset
			size: size - offset
		]
		if part > 0 [
			if part < size [size: part]
		]
		buffer: allocate size
		len: read-data file buffer size
		close-file file

		if negative? len [
			free buffer
			return none-value
		]

		val: as red-value! either binary? [
			binary/load buffer size
		][
			either lines? [lines-to-block buffer size][
				str: as red-string! stack/push*
				str/header: TYPE_UNSET
				str/head: 0
				str/node: unicode/load-utf8-buffer as-c-string buffer size null null yes
				str/cache: null							;-- @@ cache small strings?
				str/header: TYPE_STRING					;-- implicit reset of all header flags
				str
			]
		]
		free buffer
		val
	]

	write-file: func [
		filename [c-string!]
		data	 [byte-ptr!]
		size	 [integer!]
		offset	 [integer!]
		binary?	 [logic!]
		append?  [logic!]
		lines?	 [logic!]
		unicode? [logic!]
		block?	 [logic!]
		return:	 [integer!]
		/local
			file	[integer!]
			n		[integer!]
			len		[integer!]
			mode	[integer!]
			ret		[integer!]
			blk		[red-block!]
			value	[red-value!]
			tail	[red-value!]
			buffer	[red-string!]
			lineend [c-string!]
			lf-sz	[integer!]
	][
		either null? filename [
			file: stdout
		][
			unless unicode? [							;-- only command line args need to be checked
				if filename/1 = #"^"" [filename: filename + 1]	;-- FIX: issue #1234
				len: length? filename
				if filename/len = #"^"" [filename/len: null-byte]
			]
			mode: RIO_WRITE
			if append? [mode: mode or RIO_APPEND]
			if offset >= 0 [mode: mode or RIO_SEEK]
			file: open-file filename mode unicode?
			if file < 0 [return file]
		]

		if offset > 0 [seek-file file offset]
		#either OS = 'Windows [
			lineend: "^M^/"
			lf-sz: 2
			if append? [SetFilePointer file 0 null SET_FILE_END]
		][
			lineend: "^/"
			lf-sz: 1
		]
		ret: 1
		either lines? [
			buffer: string/rs-make-at stack/push* 16
			blk: as red-block! data
			value: block/rs-head blk
			tail:  block/rs-tail blk
			while [value < tail][
				data: value-to-buffer value -1 :size binary? buffer
				write-data file data size
				ret: write-data file as byte-ptr! lineend lf-sz
				value: value + 1
			]
		][
			ret: write-data file data size
			if block? [ret: write-data file as byte-ptr! lineend lf-sz]
		]
		if filename <> null [close-file file]
		ret
	]

	dir?: func [
		filename [red-file!]
		return:  [logic!]
		/local
			len  [integer!]
			pos  [integer!]
			cp1  [integer!]
			cp2  [integer!]
			cp3  [integer!]
	][
		len: string/rs-length? as red-string! filename
		if zero? len [return false]
		pos: filename/head + len - 1
		cp1: string/rs-abs-at as red-string! filename pos
		cp2: either len > 1 [string/rs-abs-at as red-string! filename pos - 1][0]
		cp3: either len > 2 [string/rs-abs-at as red-string! filename pos - 2][0]

		any [
			cp1 = 47		;-- #"/"
			cp1 = 92 		;-- #"\"
			all [
				cp1 = 46	;-- #"."
				any [
					len = 1 cp2 = 47 cp2 = 92
					all [cp2 = 46 any [cp3 = 47 cp3 = 92 len = 2]]
				]
			]
		]
	]
	
	delete: func [
		filename [red-file!]
		return:  [logic!]
		/local
			name [c-string!]
			res  [integer!]	
	][
		name: file/to-OS-path filename
		#either OS = 'Windows [
			res: either dir? filename [RemoveDirectory name][DeleteFile name]
			res <> 0
		][
			0 = LibC.remove name
		]
	]

#either OS = 'Windows [
	query: func[
		filename [red-file!]
		return:  [red-value!]
		/local
			name [c-string!]
			dt   [red-date!]
			filedata [WIN32_FIND_DATA value]
			systime	 [tagSYSTEMTIME value]
	][
		name: file/to-OS-path filename
		if any [
			1 <> GetFileAttributesExW name 0 :filedata
			1 <> FileTimeToSystemTime filedata/ftLastWriteTime :systime
		][
			return none/push
		]
		dt: as red-date! stack/push*
		date/set-all dt
			(systime/year-month and FFFFh)	;year
			(systime/year-month >> 16)		;month
			(systime/week-day >> 16)		;day
			(systime/hour-minute and FFFFh)	;hours
			(systime/hour-minute >> 16)		;minutes
			(systime/second and FFFFh)		;seconds
			1000000 * (systime/second >> 16) ;ns - posix is using nanoseconds so lets use it too
		as red-value! dt
	]
][
	query: func[
		filename [red-file!]
		return:  [red-value!]
		/local
			name [c-string!]
			dt   [red-date!]
			s	 [stat! value]
			fd   [integer!]
			tm   [tm!]
	][
		name: file/to-OS-path filename
		fd: open-file file/to-OS-path filename RIO_READ yes
		if fd < 0 [	return none/push ]
		#either any [OS = 'macOS OS = 'FreeBSD OS = 'Android] [
			_stat   fd s
		][	_stat 3 fd s]
		tm: gmtime :s/st_mtime
		dt: as red-date! stack/push*
		date/set-all dt (1900 + tm/year) (1 + tm/mon) tm/mday tm/hour tm/min tm/sec s/st_mtime/nsec
		as red-value! dt
	]
]

	read-dir: func [
		filename	[red-file!]
		return:		[red-block!]
		/local
			info
			buf		[byte-ptr!]
			p		[byte-ptr!]
			name	[byte-ptr!]
			handle	[integer!]
			blk		[red-block!]
			str		[red-string!]
			len		[integer!]
			i		[integer!]
			cp		[byte!]
			s		[series!]
	][
		len: string/rs-length? as red-string! filename
		len: filename/head + len - 1
		cp: as byte! string/rs-abs-at as red-string! filename len
		if cp = #"." [string/append-char GET_BUFFER(filename) as-integer #"/"]

		#either OS = 'Windows [
			blk: block/push-only* 1
			if all [zero? len cp = #"/"][
				len: 1 + GetLogicalDriveStrings 0 null	;-- add NUL terminal
				buf: allocate len << 1
				GetLogicalDriveStrings len buf
				i: 0
				name: buf
				p: name
				len: len - 2
				until [
					if all [name/1 = #"^@" name/2 = #"^@"][
						name: name - 4
						name/1: #"/"
						name/3: #"^@"
						str: string/load-in as-c-string p lstrlen p blk UTF-16LE
						str/header: TYPE_FILE
						name: name + 4
						p: name + 2
					]
					name: name + 2
					i: i + 1
					i = len
				]
				free buf
				return blk
			]

			s: string/append-char GET_BUFFER(filename) as-integer #"*"

			info: as WIN32_FIND_DATA allocate WIN32_FIND_DATA_SIZE
			handle: FindFirstFile file/to-OS-path filename info
			len: either cp = #"." [1][0]
			s/tail: as cell! (as byte-ptr! s/tail) - (GET_UNIT(s) << len)

			if handle = -1 [fire [TO_ERROR(access cannot-open) filename]]

			name: (as byte-ptr! info) + 44
			until [
				unless any [							;-- skip over the . and .. dir case
					name = null
					all [
						(string/get-char name UCS-2) = as-integer #"."
						any [
							zero? string/get-char name + 2 UCS-2
							all [
								(string/get-char name + 2 UCS-2) = as-integer #"."
								zero? string/get-char name + 4 UCS-2
							]
						]
					]
				][
					str: string/load-in as-c-string name lstrlen name blk UTF-16LE
					if info/dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0 [
						string/append-char GET_BUFFER(str) as-integer #"/"
					]
					set-type as red-value! str TYPE_FILE
				]
				zero? FindNextFile handle info
			]
			FindClose handle
			free as byte-ptr! info
			blk
		][
			handle: opendir file/to-OS-path filename
			if zero? handle [fire [TO_ERROR(access cannot-open) filename]]
			blk: block/push-only* 1
			while [
				info: readdir handle
				info <> null
			][
				name: (as byte-ptr! info) + DIRENT_NAME_OFFSET
				unless any [							;-- skip over the . and .. dir case
					name = null
					all [
						name/1 = #"."
						any [
							name/2 = #"^@"
							all [name/2 = #"." name/3 = #"^@"]
						]
					]
				][
					#either OS = 'macOS [
						len: as-integer info/d_namlen
					][
						len: length? as-c-string name
					]
					str: string/load-in as-c-string name len blk UTF-8
					if info/d_type = DT_DIR [
						string/append-char GET_BUFFER(str) as-integer #"/"
					]
					set-type as red-value! str TYPE_FILE
				]
			]
			if cp = #"." [
				s: GET_BUFFER(filename)
				s/tail: as cell! (as byte-ptr! s/tail) - GET_UNIT(s)
			]
			closedir handle
			blk
		]
	]

	read: func [
		filename [red-file!]
		part	 [red-value!]
		seek	 [red-value!]
		binary?	 [logic!]
		lines?	 [logic!]
		return:	 [red-value!]
		/local
			data	[red-value!]
			int		[red-integer!]
			size	[integer!]
			offset	[integer!]
	][
		if dir? filename [
			return as red-value! read-dir filename
		]

		size: -1
		offset: -1
		if OPTION?(part) [
			int: as red-integer! part
			size: int/value
		]
		if OPTION?(seek) [
			int: as red-integer! seek
			offset: int/value
		]
		data: read-file file/to-OS-path filename size offset binary? lines? yes
		if TYPE_OF(data) = TYPE_NONE [
			fire [TO_ERROR(access cannot-open) filename]
		]
		data
	]

	value-to-buffer: func [
		data	[red-value!]
		part	[integer!]
		size	[int-ptr!]
		binary? [logic!]
		buffer	[red-string!]
		return: [byte-ptr!]
		/local
			type	[integer!]
			len		[integer!]
			str  	[red-string!]
			buf		[byte-ptr!]
	][
		type: TYPE_OF(data)
		case [
			type = TYPE_STRING [
				len: part
				str: as red-string! data
				buf: as byte-ptr! unicode/io-to-utf8 str :len not binary?
			]
			type = TYPE_BINARY [
				buf: binary/rs-head as red-binary! data
				len: binary/rs-length? as red-binary! data
				if all [part > 0 len > part][len: part]
			]
			true [
				len: 0
				actions/mold as red-value! data buffer no no no null 0 0
				buf: value-to-buffer as red-value! buffer part :len binary? null
				string/rs-reset buffer
			]
		]
		size/value: len
		buf
	]

	write: func [
		filename [red-file!]
		data	 [red-value!]
		part	 [red-value!]
		seek	 [red-value!]
		binary?	 [logic!]
		append?  [logic!]
		lines?	 [logic!]
		return:  [integer!]
		/local
			len  	[integer!]
			buf  	[byte-ptr!]
			int  	[red-integer!]
			limit	[integer!]
			type	[integer!]
			offset	[integer!]
			buffer	[red-string!]
			name	[c-string!]
			block?	[logic!]
	][
		block?: no
		offset: -1
		limit: -1
		if OPTION?(part) [
			either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if negative? int/value [return -1]		;-- early exit if part <= 0
				limit: int/value
			][
				ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
			]
		]
		if OPTION?(seek) [
			int: as red-integer! seek
			offset: int/value
		]

		either all [lines? TYPE_OF(data) = TYPE_BLOCK][
			buf: as byte-ptr! data
			block?: yes
		][
			if lines? [block?: yes lines?: no]
			len: 0
			buffer: string/rs-make-at stack/push* 16
			buf: value-to-buffer data limit :len binary? buffer
		]

		name: either null? filename [null][file/to-OS-path filename]
		type: write-file name buf len offset binary? append? lines? yes block?
		if negative? type [fire [TO_ERROR(access cannot-open) filename]]
		type
	]

	#either OS = 'Windows [
		IID_IWinHttpRequest:			[06F29373h 4B545C5Ah F16E25B0h 0EBF8ABFh]
		IID_IStream:					[0000000Ch 00000000h 0000000Ch 46000000h]
		
		IWinHttpRequest: alias struct! [
			QueryInterface			[QueryInterface!]
			AddRef					[AddRef!]
			Release					[Release!]
			GetTypeInfoCount		[integer!]
			GetTypeInfo				[integer!]
			GetIDsOfNames			[integer!]
			Invoke					[integer!]
			SetProxy				[function! [this [this!] setting [integer!] server [integer!] server2 [integer!] server3 [integer!] server4 [integer!] bypass [integer!] bypass2 [integer!] bypass3 [integer!] bypass4 [integer!] return: [integer!]]]
			SetCredentials			[integer!]
			Open					[function! [this [this!] method [byte-ptr!] url [byte-ptr!] async1 [integer!] async2 [integer!] async3 [integer!] async4 [integer!] return: [integer!]]]
			SetRequestHeader		[function! [this [this!] header [byte-ptr!] value [byte-ptr!] return: [integer!]]]
			GetResponseHeader		[function! [this [this!] header [byte-ptr!] value [int-ptr!] return: [integer!]]]
			GetAllResponseHeaders	[function! [this [this!] header [int-ptr!] return: [integer!]]]
			Send					[function! [this [this!] body1 [integer!] body2 [integer!] body3 [integer!] body4 [integer!] return: [integer!]]]
			Status					[function! [this [this!] status [int-ptr!] return: [integer!]]]
			StatusText				[integer!]
			ResponseText			[function! [this [this!] body [int-ptr!] return: [integer!]]]
			ResponseBody			[function! [this [this!] body [tagVARIANT] return: [integer!]]]
			ResponseStream			[integer!]
			GetOption				[integer!]
			PutOption				[integer!]
			WaitForResponse			[integer!]
			Abort					[integer!]
			SetTimeouts				[integer!]
			SetClientCertificate	[integer!]
			SetAutoLogonPolicy		[integer!]
		]

		BSTR-length?: func [s [integer!] return: [integer!] /local len [int-ptr!]][
			len: as int-ptr! s - 4
			len/value >> 1
		]

		process-headers: func [
			headers	[c-string!]
			return: [red-hash!]
			/local
				len  [integer!]
				s	 [byte-ptr!]
				ss	 [byte-ptr!]
				p	 [byte-ptr!]
				mp	 [red-hash!]
				w	 [red-value!]
				res  [red-value!]
				val  [red-block!]
				new? [logic!]
		][
			len: WideCharToMultiByte CP_UTF8 0 headers -1 null 0 null 0
			s: allocate len
			ss: s
			WideCharToMultiByte CP_UTF8 0 headers -1 s len null 0

			mp: map/make-at stack/push* null 20
			p: s
			while [s/1 <> null-byte][
				if s/1 = #":" [						;-- key, maybe have duplicated key
					new?: no
					s/1: null-byte
					w: as red-value! word/push* symbol/make as-c-string p
					res: map/eval-path mp w null null no
					either TYPE_OF(res) = TYPE_NONE [
						new?: yes
					][
						if TYPE_OF(res) <> TYPE_BLOCK [
							val: block/push-only* 4
							block/rs-append val res
							copy-cell as cell! val res
							stack/pop 1
						]
						val: as red-block! res
					]

					p: s + 2
					until [
						s: s + 1
						if s/1 = #"^M" [			;-- value
							res: as red-value! string/load as-c-string p as-integer s - p UTF-8
							either new? [
								map/put mp w res no
							][
								block/rs-append val res
							]
							p: s + 2
						]
						s/1 = #"^M"
					]
					stack/pop 2
				]
				s: s + 1
			]
			free ss
			mp
		]

		add-header: func [
			http	[IWinHttpRequest]
			IH		[interface!]
			header	[c-string!]
			data	[c-string!]
			/local
				bstr-u	[byte-ptr!]
				bstr-m	[byte-ptr!]
		][
			bstr-u: SysAllocString header
			bstr-m: SysAllocString data
			http/SetRequestHeader IH/ptr bstr-u bstr-m
			SysFreeString bstr-m
			SysFreeString bstr-u
		]

		request-http: func [
			method	[integer!]
			url		[red-url!]
			header	[red-block!]
			data	[red-value!]
			binary? [logic!]
			lines?	[logic!]
			info?	[logic!]
			return: [red-value!]
			/local
				action	[c-string!]
				hr 		[integer!]
				clsid	[tagGUID value]
				async 	[tagVARIANT value]
				body 	[tagVARIANT value]
				IH		[interface!]
				http	[IWinHttpRequest]
				bstr-d	[byte-ptr!]
				bstr-m	[byte-ptr!]
				bstr-u	[byte-ptr!]
				buf-ptr [integer!]
				s		[series!]
				str1	[red-string! value]
				value	[red-value!]
				tail	[red-value!]
				l-bound [integer!]
				u-bound [integer!]
				array	[integer!]
				res		[red-value!]
				blk		[red-block!]
				len		[integer!]
				proxy	[tagVARIANT value]
				parr	[integer!]
				buf		[byte-ptr!]
				headers [int-ptr!]
		][
			res: as red-value! none-value
			parr: 0
			len: -1
			buf-ptr: 0
			bstr-d: null
			VariantInit :async
			VariantInit :body
			async/data1: VT_BOOL
			async/data3: 0							;-- VARIANT_FALSE

			case [
				method = words/get [
					action: #u16 "GET"
					body/data1: VT_ERROR
				]
				method = words/head [
					action: #u16 "HEAD"
					body/data1: VT_ERROR
				]
				true [
					either method = words/post [action: #u16 "POST"][
						s: GET_BUFFER(symbols)
						copy-cell s/offset + method - 1 as cell! str1
						str1/header: TYPE_STRING
						str1/head: 0
						str1/cache: null
						action: wcsupr unicode/to-utf16 str1
					]
					either null? data [
						body/data1: VT_ERROR
					][
						either TYPE_OF(data) = TYPE_BINARY [
							buf: binary/rs-head as red-binary! data
							len: binary/rs-length? as red-binary! data
							parr: as-integer SafeArrayCreateVector VT_UI1 0 len
							SafeArrayAccessData parr :buf-ptr
							copy-memory as byte-ptr! buf-ptr buf len
							SafeArrayUnaccessData parr
							body/data1: VT_ARRAY or VT_UI1
							body/data3: parr
						][
							body/data1: VT_BSTR
							bstr-d: SysAllocString unicode/to-utf16-len as red-string! data :len no
							body/data3: as-integer bstr-d
						]
					]
				]
			]

			IH: declare interface!
			http: null

			hr: CLSIDFromProgID #u16 "WinHttp.WinHttpRequest.5.1" :clsid

			if hr >= 0 [
				hr: CoCreateInstance as int-ptr! :clsid 0 CLSCTX_INPROC_SERVER IID_IWinHttpRequest IH
			]

			if hr >= 0 [
				http: as IWinHttpRequest IH/ptr/vtbl
				;VariantInit :proxy
				;proxy/data1: VT_BSTR
				;proxy/data3: as-integer SysAllocString #u16 "127.0.0.1:1235"
				;http/SetProxy IH/ptr 2 proxy/data1 proxy/data2 proxy/data3 proxy/data4 0 0 0 0
				bstr-m: SysAllocString action
				bstr-u: SysAllocString unicode/to-utf16 as red-string! url
				hr: http/Open IH/ptr bstr-m bstr-u async/data1 async/data2 async/data3 async/data4
				SysFreeString bstr-m
				SysFreeString bstr-u
			]

			either hr >= 0 [
				either header <> null [
					s: GET_BUFFER(header)
					value: s/offset + header/head
					tail:  s/tail

					while [value < tail][
						bstr-u: SysAllocString unicode/to-utf16 word/as-string as red-word! value
						value: value + 1
						bstr-m: SysAllocString unicode/to-utf16 as red-string! value
						value: value + 1
						http/SetRequestHeader IH/ptr bstr-u bstr-m
						SysFreeString bstr-m
						SysFreeString bstr-u
					]
				][
					add-header http IH #u16 "Content-Type" #u16 "application/x-www-form-urlencoded"
					add-header http IH #u16 "Accept-Charset" #u16 "UTF-8"
					add-header http IH #u16 "User-Agent" #u16 "Mozilla/5.0 (Windows NT 6.1; Win64; x64)"
				]
				hr: http/Send IH/ptr body/data1 body/data2 body/data3 body/data4
			][
				return res
			]

			unless zero? parr [SafeArrayDestroy parr]

			if hr >= 0 [
				if info? [
					blk: block/push-only* 3
					hr: http/Status IH/ptr :len
					if hr >= 0 [
						integer/make-in blk len
						hr: http/GetAllResponseHeaders IH/ptr :buf-ptr
					]
					if hr >= 0 [
						block/rs-append blk as red-value! process-headers as c-string! buf-ptr
						SysFreeString as byte-ptr! buf-ptr
					]
				]
				if bstr-d <> null [SysFreeString bstr-d]
				hr: http/ResponseBody IH/ptr :body
			]

			if hr >= 0 [				
				array: body/data3
				if all [
					VT_ARRAY or VT_UI1 = body/data1
					1 = SafeArrayGetDim array
				][
					l-bound: 0
					u-bound: 0
					SafeArrayGetLBound array 1 :l-bound
					SafeArrayGetUBound array 1 :u-bound
					SafeArrayAccessData array :buf-ptr
					len: u-bound - l-bound + 1
					res: as red-value! either binary? [
						binary/load as byte-ptr! buf-ptr len
					][
						either lines? [
							lines-to-block as byte-ptr! buf-ptr len
						][
							string/load as c-string! buf-ptr len UTF-8
						]
					]
					SafeArrayUnaccessData array
				]
				if body/data1 and VT_ARRAY > 0 [SafeArrayDestroy array]
				if info? [
					block/rs-append blk res
					res: as red-value! blk
				]
			]

			if http <> null [http/Release IH/ptr]
			res
		]
	][
		#either OS = 'macOS [
		#define libcurl-file "libcurl.dylib"
		#import [
			LIBC-file cdecl [
				objc_getClass: "objc_getClass" [
					class		[c-string!]
					return:		[integer!]
				]
				sel_getUid: "sel_getUid" [
					name		[c-string!]
					return:		[integer!]
				]
				objc_msgSend: "objc_msgSend" [[variadic] return: [integer!]]
			]
			"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
				kCFBooleanTrue: "kCFBooleanTrue" [integer!]
				CFStringCreateWithCString: "CFStringCreateWithCString" [
					allocator	[integer!]
					cStr		[c-string!]
					encoding	[integer!]
					return:		[integer!]
				]
				CFURLCreateStringByAddingPercentEscapes: "CFURLCreateStringByAddingPercentEscapes" [
					allocator	[integer!]
					cf-str		[integer!]
					unescaped	[integer!]
					escaped		[integer!]
					encoding	[integer!]
					return:		[integer!]
				]
				CFURLCreateWithFileSystemPath: "CFURLCreateWithFileSystemPath" [
					allocator	[integer!]
					filePath	[integer!]
					pathStyle	[integer!]
					isDir		[logic!]
					return:		[integer!]
				]
				CFURLCreateWithString: "CFURLCreateWithString" [
					allocator	[integer!]
					url			[integer!]
					baseUrl		[integer!]
					return:		[integer!]
				]
				CFRelease: "CFRelease" [
					cf			[integer!]
				]
			]
		]

		#define kCFStringEncodingUTF8		08000100h
		#define kCFStringEncodingMacRoman	0

		#define CFSTR(cStr)		[__CFStringMakeConstantString cStr]
		#define CFString(cStr)	[CFStringCreateWithCString 0 cStr kCFStringEncodingUTF8]

		to-NSString: func [str [red-string!] return: [integer!] /local len][
			len: -1
			objc_msgSend [
				objc_getClass "NSString"
				sel_getUid "stringWithUTF8String:"
				unicode/to-utf8 str :len
			]
		]

		to-NSURL: func [
			str		[red-string!]
			file?	[logic!]						;-- local file path or url?
			return: [integer!]
			/local
				nsstr	[integer!]
				url		[integer!]
				path	[integer!]
		][
			nsstr: to-NSString str
			either file? [
				path: objc_msgSend [nsstr sel_getUid "stringByExpandingTildeInPath"]
				;@@ release path ? Does it already autoreleased?
				path: CFURLCreateWithFileSystemPath 0 path 0 false
			][
				url: CFURLCreateStringByAddingPercentEscapes 0 nsstr 0 0 kCFStringEncodingUTF8
				path: CFURLCreateWithString 0 url 0
				CFRelease url
			]
			path
		]][#define libcurl-file "libcurl.so.4"]

		#define CURLOPT_URL				10002
		#define CURLOPT_HTTPGET			80
		#define CURLOPT_POST			47
		#define CURLOPT_PUT				54
		#define CURLOPT_POSTFIELDSIZE	60
		#define CURLOPT_NOPROGRESS		43
		#define CURLOPT_NOBODY			44
		#define CURLOPT_UPLOAD			46
		#define CURLOPT_FOLLOWLOCATION	52
		#define CURLOPT_POSTFIELDS		10015
		#define CURLOPT_CUSTOMREQUEST	10036
		#define CURLOPT_WRITEDATA		10001
		#define CURLOPT_HEADERDATA		10029
		#define CURLOPT_HTTPHEADER		10023
		#define CURLOPT_WRITEFUNCTION	20011
		#define CURLOPT_HEADERFUNCTION	20079

		#define CURLE_OK				0
		#define CURL_GLOBAL_ALL 		3

		#define CURLINFO_RESPONSE_CODE	00200002h

		;-- use libcurl, may need to install it on some distros
		#import [
			libcurl-file cdecl [
				curl_global_init: "curl_global_init" [
					flags	[integer!]
					return: [integer!]
				]
				curl_easy_init: "curl_easy_init" [
					return: [integer!]
				]
				curl_easy_setopt: "curl_easy_setopt" [
					curl	[integer!]
					option	[integer!]
					param	[integer!]
					return: [integer!]
				]
				curl_easy_getinfo: "curl_easy_getinfo" [
					curl	[integer!]
					option	[integer!]
					param	[int-ptr!]
					return: [integer!]
				]
				curl_slist_append: "curl_slist_append" [
					slist	[integer!]
					pragma	[c-string!]
					return:	[integer!]
				]
				curl_slist_free_all: "curl_slist_free_all" [
					slist	[integer!]
				]
				curl_easy_perform: "curl_easy_perform" [
					handle	[integer!]
					return: [integer!]
				]
				curl_easy_strerror: "curl_easy_strerror" [
					error	[integer!]
					return: [c-string!]
				]
				curl_easy_cleanup: "curl_easy_cleanup" [
					handle	[integer!]
				]
				curl_global_cleanup: "curl_global_cleanup" []
			]
		]

		get-http-response: func [
			[cdecl]
			data	 [byte-ptr!]
			size	 [integer!]
			nmemb	 [integer!]
			userdata [byte-ptr!]
			return:	 [integer!]
			/local
				bin  [red-binary!]
				len  [integer!]
		][
			bin: as red-binary! userdata
			len: size * nmemb
			binary/rs-append bin data len
			len
		]

		get-http-header: func [
			[cdecl]
			s		 [byte-ptr!]
			size	 [integer!]
			nmemb	 [integer!]
			userdata [byte-ptr!]
			return:	 [integer!]
			/local
				p	 [byte-ptr!]
				mp	 [red-hash!]
				len  [integer!]
				w	 [red-value!]
				res  [red-value!]
				val  [red-block!]
				new? [logic!]
		][
			mp: as red-hash! userdata
			len: size * nmemb
			if zero? strncmp as c-string! s "HTTP/1." 7 [return len]

			p: s
			while [s/1 <> null-byte][
				if s/1 = #":" [						;-- key, maybe have duplicated key
					new?: no
					s/1: null-byte
					w: as red-value! word/push* symbol/make as-c-string p
					res: map/eval-path mp w null null no
					either TYPE_OF(res) = TYPE_NONE [
						new?: yes
					][
						if TYPE_OF(res) <> TYPE_BLOCK [
							val: block/push-only* 4
							block/rs-append val res
							copy-cell as cell! val res
							stack/pop 1
						]
						val: as red-block! res
					]

					p: s + 2
					forever [
						s: s + 1
						if any [s/1 = #"^M" s/1 = #"^/"] [	;-- value
							res: as red-value! string/load as-c-string p as-integer s - p UTF-8
							either new? [
								map/put mp w res no
							][
								block/rs-append val res
							]
							p: s + 2
							break
						]
					]
					stack/pop 2
				]
				s: s + 1
			]
			len				
		]

		request-http: func [
			method	[integer!]
			url		[red-url!]
			header	[red-block!]
			data	[red-value!]
			binary? [logic!]
			lines?	[logic!]
			info?	[logic!]
			return: [red-value!]
			/local
				len		[integer!]
				curl	[integer!]
				res		[integer!]
				buf		[byte-ptr!]
				action	[integer!]
				bin		[red-binary!]
				value	[red-value!]
				tail	[red-value!]
				s		[series!]
				str		[red-string!]
				slist	[integer!]
				mp		[red-hash!]
				blk		[red-block!]
				str1	[red-string! value]
				act-str [c-string!]
				saved	[int-ptr!]
		][
			case [
				method = words/get [action: CURLOPT_HTTPGET]
				method = words/post [action: CURLOPT_POST]
				method = words/head [action: CURLOPT_NOBODY]
				true [action: CURLOPT_CUSTOMREQUEST]
			]

			curl_global_init CURL_GLOBAL_ALL
			curl: curl_easy_init

			if zero? curl [
				#if debug? = yes [print-line "ERROR: libcurl init failed."]
				curl_global_cleanup
				return none-value
			]

			slist: 0
			bin: binary/make-at stack/push* 4096

			either action = CURLOPT_CUSTOMREQUEST [
				len: -1
				s: GET_BUFFER(symbols)
				copy-cell s/offset + method - 1 as cell! str1
				str1/header: TYPE_STRING
				str1/head: 0
				str1/cache: null
				act-str: strupr unicode/to-utf8 str1 :len
				curl_easy_setopt curl CURLOPT_CUSTOMREQUEST as-integer act-str
			][
				curl_easy_setopt curl action 1
			]
			len: -1
			curl_easy_setopt curl CURLOPT_URL as-integer unicode/to-utf8 as red-string! url :len
			curl_easy_setopt curl CURLOPT_NOPROGRESS 1
			curl_easy_setopt curl CURLOPT_FOLLOWLOCATION 1
			
			curl_easy_setopt curl CURLOPT_WRITEFUNCTION as-integer :get-http-response
			curl_easy_setopt curl CURLOPT_WRITEDATA as-integer bin

			if info? [
				blk: block/push-only* 3
				mp: map/make-at stack/push* null 20
				curl_easy_setopt curl CURLOPT_HEADERDATA as-integer mp
				curl_easy_setopt curl CURLOPT_HEADERFUNCTION as-integer :get-http-header
			]

			either header <> null [
				s: GET_BUFFER(header)
				value: s/offset + header/head
				tail:  s/tail

				while [value < tail][
					str: word/as-string as red-word! value	;-- cast word! to string!
					_series/copy as red-series! str as red-series! str null yes null
					string/append-char GET_BUFFER(str) as-integer #":"
					string/append-char GET_BUFFER(str) as-integer #" "
					value: value + 1
					string/concatenate str as red-string! value -1 0 yes no
					len: -1
					slist: curl_slist_append slist unicode/to-utf8 str :len
					value: value + 1
				]
				curl_easy_setopt curl CURLOPT_HTTPHEADER slist
			][
				slist: curl_slist_append slist "Accept-Charset: UTF-8"
				slist: curl_slist_append slist "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64)"
				curl_easy_setopt curl CURLOPT_HTTPHEADER slist
			]

			if any [action = CURLOPT_POST action = CURLOPT_CUSTOMREQUEST] [
				if data <> null [
					len: -1
					either TYPE_OF(data) = TYPE_STRING [
						buf: as byte-ptr! unicode/to-utf8 as red-string! data :len
					][
						buf: binary/rs-head as red-binary! data
						len: binary/rs-length? as red-binary! data
					]
					curl_easy_setopt curl CURLOPT_POSTFIELDSIZE len
					curl_easy_setopt curl CURLOPT_POSTFIELDS as-integer buf
				]
			]

			curl_easy_setopt curl 64 0

			saved: system/stack/align
			push 0 push 0 push 0
			res: curl_easy_perform curl
			system/stack/top: saved

			if info? [
				curl_easy_getinfo curl CURLINFO_RESPONSE_CODE :len
				integer/make-in blk len
			]

			unless zero? slist [curl_slist_free_all slist]
			saved: system/stack/align
			push 0 push 0 push 0
			curl_easy_cleanup curl
			system/stack/top: saved
			curl_global_cleanup

			if res <> CURLE_OK [
				#if debug? = yes [print-line ["ERROR: " curl_easy_strerror res]]
				return none-value
			]

			unless binary? [
				buf: binary/rs-head bin
				len: binary/rs-length? bin
				either lines? [
					bin: as red-binary! lines-to-block buf len
				][
					bin/header: TYPE_UNSET
					bin/node: unicode/load-utf8 as c-string! buf len
					bin/_pad: 0
					bin/header: TYPE_STRING
				]
			]

			if info? [
				block/rs-append blk as red-value! mp
				block/rs-append blk as red-value! bin
				bin: as red-binary! blk
			]
			as red-value! bin
		]
	]
]
