Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %boot.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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
	
	#register-intrinsics
	#include %environment/functions.red
	#include %environment/system.red
	#include %environment/operators.red

	#include %environment/codecs/PNG.red
	#include %environment/codecs/JPEG.red
	#include %environment/codecs/BMP.red
	#include %environment/codecs/GIF.red
	#include %environment/codecs/redbin.red

	#include %environment/reactivity.red				;-- requires SET intrinsic
	#include %environment/networking.red
	#include %utils/preprocessor.r
	#include %environment/tools.red

	;-- temporary code --
	#if not find [Windows macOS Linux] config/OS [
		unset [event! image!]
		image?: func ["Returns true if the value is this type" value [any-type!]][false]
	]
	
	;-- initialize some system words
	
	system/version: load system/version
	
	system/options/cache: either system/platform = 'Windows [
		append any [attempt [to-red-file get-env "APPDATA"] %./] %/Red/
	][
		append any [attempt [to-red-file get-env "HOME"] %/tmp] %/.red/
	]
]

;-- command-line arguments processing

#if config/dev-mode? [
	system/script/args: #system [
		#either type = 'exe [stack/push get-cmdline-args][none/push]
	]
]
#if config/type = 'exe [extract-boot-args]
