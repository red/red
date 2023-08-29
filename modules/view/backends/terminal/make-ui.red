Red [
	Title:	"Make Text UI of faces"
	Author: "Xie Qingtian"
	File: 	%make-ui.red
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-progress-ui: function [
	face	[face!]
][
	proportion: face/data
	case [
		proportion <= 1e-16 [proportion: 0.0]
		proportion >= 1.0 [proportion: 1.0]
	]
	face/text: ""
	ui: clear face/text
	append ui #"["
	bar: face/size/x - 2	;-- exclude [ and ]
	val: to-integer round/ceiling bar * proportion
	append/dup ui #"#" val
	append/dup ui #" " bar - val
	append ui #"]"
]