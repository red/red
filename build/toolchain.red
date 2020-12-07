Red [
	Title:   "Functions to run the Red toolchain"
	Author:  "Xie Qingtian"
	File: 	 %toolchain.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

system/toolchain: context [
	write-srcs: function [blk][
		foreach [f b] blk [
			either block? b [
				make-dir f
				change-dir f
				write-srcs b
				change-dir %..
			][
				write/binary f b
			]
		]
	]

	run: function [cmd][
		args: split cmd #" "
		switch?: all [1 = length? args #"-" = first args/1]
		if all [	;-- file pathname
			1 = length? args
			#"-" <> first args/1
		][return false]

		extract?: no
		tool-dir: append copy system/options/cache
				#either config/OS = 'Windows [%RedToolChain/][%.RedToolChain/]

		ts-file: tool-dir/timestamp.red
		if all [	;-- delete the older version
			exists? ts-file
			system/build/date > load ts-file
		][
			delete-dir tool-dir
		]
		unless exists? tool-dir [
			extract?: yes
			make-dir/deep tool-dir
		]

		rebol: append copy tool-dir #either config/OS = 'Windows [%rebol.exe][%rebol]
		cwd: what-dir
		change-dir tool-dir
		if all [extract? value? 'red-toolchain][	;-- extract toolchain
			write/binary rebol red-toolchain/1
			write-srcs red-toolchain/2
			#if config/OS <> 'Windows [
				call/wait append "chmod +x " rebol
			]
			write ts-file system/build/date
			unset red-toolchain
		]

		change-dir cwd
		unless switch? [
			print "Compiling, please wait a while..."
			#if config/gui-console? [
				vt: gui-console-ctx/terminal
				loop 50 [vt/do-ask-loop/no-wait]
			]
		]
		out: make string! 1000
		err: make string! 1000
		call/output/error rejoin [
			#"^"" to-local-file rebol #"^""
			" -cqs "
			to-local-file tool-dir/red.r " "
			cmd
		] out err
		unless empty? out [print out]
		unless empty? err [print err]
		true
	]
]