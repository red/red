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


platform: context [

	#enum file-descriptors! [
		fd-stdout: 1									;@@ hardcoded, safe?
		fd-stderr: 2									;@@ hardcoded, safe?
	]

	gdiplus-token: 0
	page-size: 4096

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

	wait: func [time [float!]][							;-- seconds
		time: time * 1000.0								;-- milliseconds
		if time < 1.0 [time: 1.0]
		Sleep as-integer time
	]

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
			tm			[tagSYSTEMTIME value]
			ftime		[tagFILETIME value]
			h			[integer!]
			m			[integer!]
			sec			[integer!]
			ms-int 		[integer!]
			bits0-29	[integer!]
			bits30-46	[integer!]
			bits47-63	[integer!]
			nano		[integer!]
			hi			[integer!]
			lo			[integer!]
			t			[float!]
			mi			[float!]
	][
		GetSystemTimeAsFileTime ftime
		FileTimeToSystemTime ftime tm
		h: tm/hour-minute and FFFFh
		m: tm/hour-minute >>> 16
		sec: tm/second and FFFFh
		t: as-float h * 3600 + (m * 60) + sec
		if precise? [
			ms-int: tm/second >>> 16
			;; let x0 = x1 + x2<<30 + x3<<47 (x2-x3 are 17-bit parts, to avoid overflow when multiplied by 1e4)
			;; then x0%n = (x1%n + (x2 * 1<<30%n) + (x3 * 1<<47%n)) % n
			hi: ftime/dwHighDateTime
			lo: ftime/dwLowDateTime
			bits0-29:  lo and 3FFFFFFFh
			bits30-46: hi and 7FFFh << 2 or (lo >>> 30)
			bits47-63: hi >>> 15
			;; overflow check (must stay below sign flip at 8000'0000h):
			;; (131071 * 1824) + (131071 * 5328) + 3FFF'FFFFh = 77DF'E410h 
			nano: (bits30-46 * 1'824) + (bits47-63 * 5'328) + bits0-29 % 10'000	;-- raw part, in 100ns units
			mi: as-float nano * 100 + (ms-int * 1'000'000)
			t: t + (mi / 1e9)
		]
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
	init: func [/local h [int-ptr!]] [
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
	]
]