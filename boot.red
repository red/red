Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %boot.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#if any [not config/dev-mode? config/libRedRT?][

	#include %environment/datatypes.red
	#include %environment/actions.red
	#include %environment/natives.red
	#include %environment/routines.red
	#include %environment/scalars.red
	#include %environment/colors.red
	#include %environment/functions.red
	#include %environment/system.red
	#include %environment/lexer.red
	#include %environment/operators.red

	#register-intrinsics

	#include %environment/codecs/png.red
	#include %environment/codecs/jpeg.red
	#include %environment/codecs/bmp.red
	#include %environment/codecs/gif.red

	#include %environment/reactivity.red				;-- requires SET intrinsic
	#include %utils/preprocessor.r

	;-- temporary code --
	#if not find [Windows MacOSX] config/OS [
		unset [event! image!]
		image?: func ["Returns true if the value is this type" value [any-type!]][false]
	]
]

;-- command-line arguments processing

#if config/dev-mode? [
	system/script/args: #system [
		#either type = 'exe [stack/push get-cmdline-args][none/push]
	]
]
#if config/type = 'exe [extract-boot-args]

