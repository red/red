Red/System [
	Title:   "Red/System Win32 runtime for kernel drivers"
	Author:  "Nenad Rakocevic"
	File: 	 %win32-driver.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define OS_TYPE		1

;-- source: http://msdn.microsoft.com/en-us/library/windows/hardware/ff544113(v=vs.85).aspx

driver-object!: alias struct! [
	;@@ To be filled
	dummy [integer!] ;@@ just for the struct to be compilable
]

***-drv-entry-point: func [
	[callback]
	DriverObject [driver-object!]
	RegistryPath [byte-ptr!]					;-- Unicode string (UTF-16LE)
	return: [integer!]
][
	***-boot-rs
	on-load DriverObject RegistryPath			;-- user code, must return a NTSTATUS value!
]