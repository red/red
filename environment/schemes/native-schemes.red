Red [
	Title:   "low-level native schemes"
	Author:  "Xie Qingtian"
	File: 	 %native-schemes.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

actor: #system [handle/push tcp-device/table]

register-scheme/native make system/standard/scheme [
	name: 'TCP
	title: "TCP scheme implementation"
] actor