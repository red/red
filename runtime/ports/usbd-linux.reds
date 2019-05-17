Red/System [
	Title:	"usb port! implementation on Linux"
	Author: "bitbegin"
	File: 	%usbd-linux.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %usbd-common.reds

usb-device: context [

	device-list: declare list-entry!

	#import [
		"libudev.so.1" cdecl [
			udev_new: "udev_new" [
				return:			[int-ptr!]
			]
			udev_ref: "udev_ref" [
				udev			[int-ptr!]
				return:			[int-ptr!]
			]
			udev_unref: "udev_unref" [
				udev			[int-ptr!]
				return:			[int-ptr!]
			]
			udev_enumerate_new: "udev_enumerate_new" [
				udev			[int-ptr!]
				return:			[int-ptr!]
			]
			udev_enumerate_unref: "udev_enumerate_unref" [
				udev_enumerate 	[int-ptr!]
				return:			[int-ptr!]
			]
			udev_enumerate_add_match_subsystem: "udev_enumerate_add_match_subsystem" [
				udev_enumerate 	[int-ptr!]
				subsystem		[c-string!]
				return: 		[integer!]
			]
			udev_enumerate_add_match_property: "udev_enumerate_add_match_property" [
				udev_enumerate 	[int-ptr!]
				property		[c-string!]
				value			[c-string!]
				return: 		[integer!]
			]
			udev_enumerate_scan_devices: "udev_enumerate_scan_devices" [
				udev_enumerate	[int-ptr!]
				return:			[integer!]
			]
			udev_enumerate_get_list_entry: "udev_enumerate_get_list_entry" [
				udev_enumerate 	[int-ptr!]
				return:			[int-ptr!]
			]
			udev_list_entry_get_next: "udev_list_entry_get_next" [
				list_entry		[int-ptr!]
				return: 		[int-ptr!]
			]
			udev_list_entry_get_name: "udev_list_entry_get_name" [
				list_entry		[int-ptr!]
				return:			[c-string!]
			]
			udev_device_new_from_syspath: "udev_device_new_from_syspath" [
				udev 			[int-ptr!]
				syspath 		[c-string!]
				return: 		[int-ptr!]
			]
			udev_device_get_devnode: "udev_device_get_devnode" [
				udev_device 	[int-ptr!]
				return: 		[c-string!]
			]
			udev_device_get_parent_with_subsystem_devtype: "udev_device_get_parent_with_subsystem_devtype" [
				udev_device 	[int-ptr!]
				subsystem 		[c-string!]
				devtype 		[c-string!]
				return: 		[int-ptr!]
			]
			udev_device_unref: "udev_device_unref" [
				udev_device 	[int-ptr!]
				return:			[int-ptr!]
			]
			udev_device_get_sysattr_value: "udev_device_get_sysattr_value" [
				dev 	[int-ptr!]
				sysattr [c-string!]
				return: [c-string!]
			]
		]
	]

	enum-usb-device: func [
		device-list				[list-entry!]
		id?						[logic!]
		_vid					[integer!]
		_pid					[integer!]
		/local
			udev				[int-ptr!]
			enumerate			[int-ptr!]
			result				[integer!]
			devices				[int-ptr!]
			dev_list_entry		[int-ptr!]
			sysfs_path			[c-string!]
			device				[int-ptr!]
			dev_path			[c-string!]
			attr				[c-string!]
			vid					[integer!]
			pid					[integer!]
			serial				[c-string!]
			name				[c-string!]
	][
		udev: udev_new
		if udev = null [exit]
		enumerate: udev_enumerate_new udev
		if enumerate = null [
			udev_unref udev
			exit
		]
		;result: udev_enumerate_add_match_subsystem enumerate "usb"
		result: udev_enumerate_add_match_property enumerate "DEVTYPE" "usb_device"
		if result <> 0 [
			udev_enumerate_unref enumerate
			udev_unref udev
			exit
		]
		udev_enumerate_scan_devices enumerate
		devices: udev_enumerate_get_list_entry enumerate
		dev_list_entry: devices
		while [dev_list_entry <> null] [
			sysfs_path: udev_list_entry_get_name dev_list_entry
			device: udev_device_new_from_syspath udev sysfs_path
			dev_path: udev_device_get_devnode device
			print-line sysfs_path

			attr: udev_device_get_sysattr_value device "idVendor"
			if attr = null [
				udev_device_unref device
				dev_list_entry: udev_list_entry_get_next dev_list_entry
				continue
			]
			;print-line attr
			vid: 65535
			sscanf [attr "%x" :vid]
			attr: udev_device_get_sysattr_value device "idProduct"
			if attr = null [
				udev_device_unref device
				dev_list_entry: udev_list_entry_get_next dev_list_entry
				continue
			]
			;print-line attr
			pid: 65535
			sscanf [attr "%x" :pid]
			if all [
				id?
				any [
					_vid <> vid
					_pid <> pid
				]
			][
				continue
			]
			serial: udev_device_get_sysattr_value device "serial"
			name: udev_device_get_sysattr_value device "product"
			print-line name
			
			udev_device_unref device
			dev_list_entry: udev_list_entry_get_next dev_list_entry
		]


		udev_enumerate_unref enumerate
		udev_unref udev
	]



	enum-all-devices: does [
		enum-usb-device device-list no -1 -1
	]

	init: does [
		dlink/init device-list
	]
]
