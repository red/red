Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

AcceptEx-func:				0
ConnectEx-func:				0
DisconnectEx-func:			0
TransmitFile-func:			0
GetAcceptExSockaddrs-func:	0

platform: context [

	#enum file-descriptors! [
		fd-stdout: 1									;@@ hardcoded, safe?
		fd-stderr: 2									;@@ hardcoded, safe?
	]

	gdiplus-token: 0
	page-size: 4096
	SSPI: as SecurityFunctionTableW 0

	#include %win32-print.reds

	;-------------------------------------------
	;-- Allocate paged virtual memory region from OS
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]								;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]								;-- TRUE => executable region
		return: [int-ptr!]								;-- allocated memory region pointer
		/local ptr prot
	][
		prot: either exec? [VA_PAGE_RWX][VA_PAGE_RW]

		ptr: VirtualAlloc null size VA_COMMIT_RESERVE prot
		if ptr = null [throw OS_ERROR_VMEM_OUT_OF_MEMORY]
		ptr
	]

	;-------------------------------------------
	;-- Free paged virtual memory region from OS
	;-------------------------------------------
	free-virtual: func [
		ptr [int-ptr!]									;-- address of memory region to release
	][
		if zero? VirtualFree ptr 0 8000h [				;-- MEM_RELEASE: 0x8000
			 throw OS_ERROR_VMEM_RELEASE_FAILED
		]
	]

	init-gdiplus: func [/local startup-input][
		startup-input: declare GdiplusStartupInput!
		startup-input/GdiplusVersion: 1
		startup-input/DebugEventCallback: 0
		startup-input/SuppressBackgroundThread: 0
		startup-input/SuppressExternalCodecs: 0
		GdiplusStartup :gdiplus-token as-integer startup-input 0
	]

	shutdown-gdiplus: does [
		GdiplusShutdown gdiplus-token 
	]

	get-current-dir: func [
		len		[int-ptr!]
		return: [c-string!]
		/local
			size [integer!]
			path [byte-ptr!]
	][
		size: GetCurrentDirectory 0 null				;-- include NUL terminator
		path: allocate size << 1
		GetCurrentDirectory size path
		len/value: size - 1
		as c-string! path
	]

	wait: func [time [integer!]][Sleep time]

	set-current-dir: func [
		path	[c-string!]
		return: [logic!]
	][
		SetCurrentDirectory path
	]

	set-env: func [
		name	[c-string!]
		value	[c-string!]
		return: [logic!]								;-- true for success
	][
		SetEnvironmentVariable name value
	]

	get-env: func [
		;; Returns size of retrieved value for success or zero if missing
		;; If return size is greater than valsize then value contents are undefined
		name	[c-string!]
		value	[c-string!]
		valsize [integer!]								;-- includes null terminator
		return: [integer!]
	][
		GetEnvironmentVariable name value valsize
	]

	get-time: func [
		utc?	 [logic!]
		precise? [logic!]
		return:  [float!]
		/local
			tm	[tagSYSTEMTIME value]
			ftime	[tagFILETIME value]
			h		[integer!]
			m		[integer!]
			sec		[integer!]
			ms-int 	[integer!]
			bits0-31 	[integer!]
			bits32-47 	[integer!]
			bits48-63 	[integer!]
			nano	[integer!]
			hi		[integer!]
			n 		[integer!]
			t		[float!]
			mi		[float!]
	][
		GetSystemTimeAsFileTime ftime
		FileTimeToSystemTime ftime tm
		h: tm/hour-minute and FFFFh
		m: tm/hour-minute >>> 16
		sec: tm/second and FFFFh
		nano: either precise? [
			ms-int: tm/second >>> 16
			; let x0 = x1 + x2<<32 + x3<<48 (x2-x3 are 2-byte parts, to avoid overflow when multiplied by 1e4)
			; then x0%n = (x1%n + (x2 * 1<<32%n) + (x3 * 1<<48%n)) % n
			hi: ftime/dwHighDateTime
			bits0-31: ftime/dwLowDateTime
			if bits0-31 < 0 [hi: hi + 1] 		;-- `%` treats bits0-31 as signed, while it is really not, have to work around
			bits32-47: hi and FFFFh
			bits48-63: hi >>> 16 and FFFFh
			n: 10'000
			; overflow check: 9999 + (65535 * 8000) = 524'289'999
			nano: (bits32-47 * 7'296) + (bits48-63 * 0'656) // n + (bits0-31 % n) 	;-- raw part, in 100ns units
			nano * 100 + (ms-int * 1'000'000)
		][0]
		mi: as-float nano
		mi: mi / 1e+9
		t: as-float h * 3600 + (m * 60) + sec
		t: t + mi
		t
	]

	get-date: func [
		utc?	[logic!]
		return:	[integer!]
		/local
			tm		[tagSYSTEMTIME value]
			tzone	[tagTIME_ZONE_INFORMATION value]
			bias	[integer!]
			res		[integer!]
			y		[integer!]
			m		[integer!]
			d		[integer!]
			h		[integer!]
	][
		either utc? [GetSystemTime tm][GetLocalTime tm]
		y: tm/year-month and FFFFh
		m: tm/year-month >>> 16
		d: tm/week-day >>> 16

		either utc? [h: 0][
			res: GetTimeZoneInformation tzone
			bias: tzone/Bias
			if res = 2 [bias: bias + tzone/DaylightBias] ;-- TIME_ZONE_ID_DAYLIGHT: 2
			bias: 0 - bias
			h: bias / 60
			if h < 0 [h: 0 - h and 0Fh or 10h]			;-- properly set the sign bit
			h: h << 2 or (bias // 60 / 15 and 03h)
		]
		y << 17 or (m << 12) or (d << 7) or h
	]

	open-console: func [return: [logic!]][
		either AllocConsole [
			stdin:  win32-startup-ctx/GetStdHandle WIN_STD_INPUT_HANDLE
			stdout: win32-startup-ctx/GetStdHandle WIN_STD_OUTPUT_HANDLE
			stderr: win32-startup-ctx/GetStdHandle WIN_STD_ERROR_HANDLE
			yes
		][
			no
		]
	]

	close-console: func [return: [logic!]][
		FreeConsole
	]

	;-------------------------------------------
	;-- Do platform-specific initialization tasks
	;-------------------------------------------
	init: func [
		/local
			h	[int-ptr!]
			wsa	[int-ptr!]
			fd	[integer!]
			n	[integer!]
	][
		init-gdiplus
		#either libRed? = no [
			CoInitializeEx 0 COINIT_APARTMENTTHREADED
		][
			#if export-ABI <> 'stdcall [
				CoInitializeEx 0 COINIT_APARTMENTTHREADED
			]
		]
		crypto/init-provider
		init-output-buffer
		#if unicode? = yes [
			h: __iob_func
			_setmode _fileno h + 8 _O_U16TEXT				;@@ stdout, throw an error on failure
			_setmode _fileno h + 16 _O_U16TEXT				;@@ stderr, throw an error on failure
		]

		wsa: system/stack/allocate 100			;-- 400 bytes for 32bit System
		WSAStartup 2 << 8 or 2 wsa

		fd: WSASocketW 2 1 6 null 0 1

		n: 0
		h: [B5367DF1h 11CFCBACh 8000CA95h 92A1485Fh]
		WSAIoctl fd C8000006h h 16 :AcceptEx-func size? int-ptr! :n null null

		h: [B5367DF0h 11CFCBACh 8000CA95h 92A1485Fh]
		WSAIoctl fd C8000006h h 16 :TransmitFile-func size? int-ptr! :n null null

		h: [B5367DF2h 11CFCBACh 8000CA95h 92A1485Fh]
		WSAIoctl fd C8000006h h 16 :GetAcceptExSockaddrs-func size? int-ptr! :n null null

		h: [25A207B9h 4660DDF3h E576E98Eh 3E06748Ch]
		WSAIoctl fd C8000006h h 16 :ConnectEx-func size? int-ptr! :n null null

		h: [7FDA2E11h 436F8630h 36F531A0h 57C1EEA6h]
		WSAIoctl fd C8000006h h 16 :DisconnectEx-func size? int-ptr! :n null null

		closesocket fd

		SSPI: InitSecurityInterfaceW
		assert SSPI <> null
	]
]