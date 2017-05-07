Red/System [
	Title:	"Windows Common Dialogs"
	Author: "Xie Qingtian"
	File: 	%comdlgs.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

dir-keep: 0
dir-inited: false

file-filter-to-str: func [
	filter	[red-block!]
	return: [c-string!]
	/local
		s	[series!]
		val [red-value!]
		end [red-value!]
		str [red-string!]
][
	s: GET_BUFFER(filter)
	val: s/offset + filter/head
	end:  s/tail
	if val = end [return null]

	str: string/make-at stack/push* 16 UCS-2
	while [val < end][
		string/concatenate str as red-string! val -1 0 yes no
		string/append-char GET_BUFFER(str) 0
		val: val + 1
	]
	unicode/to-utf16 str
]

file-list-to-block: func [
	blk		[red-block!]
	path	[red-string!]
	buffer	[byte-ptr!]
	/local
		dir [red-string!]
		name [red-string!]
		len [integer!]
][
	until [
		dir: as red-string! ALLOC_TAIL(blk)
		_series/copy as red-series! path as red-series! dir null yes null
		len: lstrlen buffer
		name: string/load as-c-string buffer len UTF-16LE
		string/concatenate dir name -1 0 yes no
		buffer: buffer + (len + 1 * 2)
		all [buffer/1 = #"^@" buffer/2 = #"^@"]
	]
]

req-dir-callback: func [
	hwnd	[handle!]
	msg		[integer!]
	lParam	[integer!]
	lpData	[integer!]
	return:	[integer!]
	/local
		method [integer!]
][
	method: either lpData = dir-keep [0][1]
	switch msg [
		BFFM_INITIALIZED [
			unless zero? lpData [
				dir-inited: yes
				SendMessage hwnd BFFM_SETSELECTION method lpData
			]
		]
		BFFM_SELCHANGED [			;-- located to folder
			if all [dir-inited not zero? lpData][
				dir-inited: no
				SendMessage hwnd BFFM_SETSELECTION method lpData
			]
		]
		default [0]
	]
	0
]
		
OS-request-dir: func [
	title	[red-string!]
	dir		[red-file!]
	filter	[red-block!]
	keep?	[logic!]
	multi?	[logic!]
	return: [red-value!]
	/local
		buffer	[byte-ptr!]
		ret		[integer!]
		len		[integer!]
		path	[red-value!]
		str		[red-string!]
		pbuf	[byte-ptr!]
		bInfo	[tagBROWSEINFO]
][
	bInfo: declare tagBROWSEINFO
	pbuf: null
	buffer: allocate 520

	if TYPE_OF(dir) = TYPE_FILE [
		pbuf: as byte-ptr! file/to-OS-path as red-file! dir
		copy-memory buffer pbuf (lstrlen pbuf) << 1 + 2
	]

	bInfo/hwndOwner: GetForegroundWindow
	bInfo/lpszTitle: either TYPE_OF(title) = TYPE_STRING [unicode/to-utf16 title][null]
	bInfo/ulFlags: BIF_RETURNONLYFSDIRS or BIF_USENEWUI
	bInfo/lpfn: as-integer :req-dir-callback
	bInfo/lParam: either keep? [dir-keep][as-integer pbuf]

	ret: SHBrowseForFolder bInfo
	path: as red-value! either zero? ret [none-value][
		if keep? [
			unless zero? dir-keep [CoTaskMemFree dir-keep]
			dir-keep: ret
		]
		SHGetPathFromIDList ret buffer
		len: lstrlen buffer
		str: string/load as-c-string buffer len UTF-16LE
		if (string/rs-abs-at str len - 1) <> as-integer #"\" [
			string/append-char GET_BUFFER(str) as-integer #"\"
		]
		str/header: TYPE_FILE
		#call [to-red-file str]
		stack/arguments
	]
	free buffer
	path
]

OS-request-file: func [
	title	[red-string!]
	name	[red-file!]
	filter	[red-block!]
	save?	[logic!]
	multi?	[logic!]
	return: [red-value!]
	/local
		filters [c-string!]
		buffer	[byte-ptr!]
		ret		[integer!]
		len		[integer!]
		files	[red-value!]
		str		[red-string!]
		blk		[red-block!]
		pbuf	[byte-ptr!]
		ofn		[tagOFNW]
][
	ofn: declare tagOFNW
	filters: #u16 "All files^@*.*^@Red scripts^@*.red;*.reds^@REBOL scripts^@*.r^@Text files^@*.txt^@"
	buffer: allocate MAX_FILE_REQ_BUF
	either TYPE_OF(name) = TYPE_FILE [
		pbuf: as byte-ptr! file/to-OS-path as red-file! name
		len: lstrlen pbuf
		len: len << 1 - 1
		while [all [len > 0 pbuf/len <> #"\"]][len: len - 2]
		if len > 0 [
			pbuf/len: #"^@"
			ofn/lpstrInitialDir: as-c-string pbuf
			pbuf: pbuf + len + 1
		]
		copy-memory buffer pbuf (lstrlen pbuf) << 1 + 2
	][
		buffer/1: #"^@"
		buffer/2: #"^@"
	]

	ofn/lStructSize: size? tagOFNW
	ofn/hwndOwner: GetForegroundWindow
	ofn/lpstrTitle: either TYPE_OF(title) = TYPE_STRING [unicode/to-utf16 title][null]
	ofn/lpstrFile: buffer
	ofn/lpstrFilter: either TYPE_OF(filter) = TYPE_BLOCK [file-filter-to-str filter][filters]
	ofn/nMaxFile: MAX_FILE_REQ_BUF
	ofn/lpstrFileTitle: null
	ofn/nMaxFileTitle: 0

	ofn/Flags: OFN_HIDEREADONLY or OFN_EXPLORER
	if multi? [ofn/Flags: ofn/Flags or OFN_ALLOWMULTISELECT]

	ret: either save? [GetSaveFileName ofn][GetOpenFileName ofn]
	files: as red-value! either zero? ret [none-value][
		len: lstrlen buffer
		str: string/load as-c-string buffer len UTF-16LE
		#call [to-red-file str]
		str: as red-string! stack/arguments
		as red-value! either multi? [
			pbuf: buffer + (len + 1 * 2)
			stack/push*							;@@ stack/arguments is already used after #call [...]
			blk: block/push-only* 1
			either all [pbuf/1 = #"^@" pbuf/2 = #"^@"][
				block/rs-append blk as red-value! str
			][
				string/append-char GET_BUFFER(str) as-integer #"/"
				file-list-to-block blk str pbuf
			]
			blk
		][
			str
		]
	]
	free buffer
	files
]