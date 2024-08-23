Red/System [
	File: 	 %config.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;-- config for the machine
config: context [
	int-width: 32
	int-mask: 1 << int-width - 1
	int-type: as int-type! 0
	int32-arith?: yes		;-- native support for int32 arithmetic
	int64-arith?: no		;-- native support for int64 arithmetic
	big-endian?: no
]