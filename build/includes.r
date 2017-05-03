REBOL [
	Title:   "Red source files preprocessor"
	Author:  "Nenad Rakocevic"
	File: 	 %includes.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

change-dir %..
do %system/utils/encap-fs.r

write %build/bin/sources.r set-cache [
	%version.r
	%usage.txt
	%boot.red
	%compiler.r
	%lexer.r
	%environment/ [
		%actions.red
		%colors.red
		;%css-colors.red
		%datatypes.red
		%functions.red
		%lexer.red
		%natives.red
		%operators.red
		%reactivity.red
		%routines.red
		%scalars.red
		%system.red
		%codecs/ [
			%bmp.red
			%gif.red
			%jpeg.red
			%png.red
		]
		%console/ [
			%auto-complete.red
			%console.red
			%engine.red
			%gui-console.red
			%help.red
			%input.red
			%wcwidth.reds
			%POSIX.reds
			%terminal.reds
			%windows.reds
			%win32.reds
		]
	]
	%runtime/ [
		%actions.reds
		%allocator.reds
		%debug-tools.reds
		%definitions.reds
		%case-folding.reds
		%interpreter.reds
		%macros.reds
		%natives.reds
		%parse.reds
		%random.reds
		%crypto.reds
		%red.reds
		%redbin.reds
		%sort.reds
		%hashtable.reds
		%ownership.reds
		%stack.reds
		%tools.reds
		%unicode.reds
		%simple-io.reds
		%clipboard.reds
		%crush.reds
		%utils.reds
		%call.reds
		%datatypes/ [
			%action.reds
			%block.reds
			%bitset.reds
			%binary.reds
			%char.reds
			%common.reds
			%context.reds
			%datatype.reds
			%email.reds
			%error.reds
			%event.reds
			%file.reds
			%float.reds
			%function.reds
			%get-path.reds
			%get-word.reds
			%hash.reds
			%image.reds
			%integer.reds
			%issue.reds
			%lit-path.reds
			%lit-word.reds
			%logic.reds
			%map.reds
			%native.reds
			%none.reds
			%op.reds
			%object.reds
			%paren.reds
			%path.reds
			%pair.reds
			%percent.reds
			%point.reds
			%refinement.reds
			%routine.reds
			%series.reds
			%set-path.reds
			%set-word.reds
			%string.reds
			%structures.reds
			%symbol.reds
			%tag.reds
			%time.reds
			%typeset.reds
			%tuple.reds
			%unset.reds
			%url.reds
			%vector.reds
			%word.reds
			%handle.reds
		]
		%platform/ [
			%android.reds
			%darwin.reds
			%linux.reds
			%POSIX.reds
			%syllable.reds
			%win32.reds
			%COM.reds
			%image-gdiplus.reds
			%image-quartz.reds
			%win32-cli.reds
			%win32-gui.reds
			%win32-ansi.reds
		]
	]
	%modules/ [
		%view/ [
			%view.red
			%draw.red
			%styles.red
			%utils.red
			%VID.red
			%backends/ [
				%keycodes.reds
				%platform.red
				%windows/ [
					%base.reds
					%button.reds
					%camera.reds
					%classes.reds
					%comdlgs.reds
					%direct2d.reds
					%draw-d2d.reds
					%draw.reds
					%events.reds
					%font.reds
					%gui.reds
					%menu.reds
					%panel.reds
					%para.reds
					%tab-panel.reds
					%text-list.reds
					%text-box.reds
					%win32.reds
				]
				%osx/ [
					%camera.reds
					%classes.reds
					%cocoa.reds
					%comdlgs.reds
					%delegates.reds
					%draw.reds
					%events.reds
					%font.reds
					%gui.reds
					%menu.reds
					%para.reds
					%selectors.reds
					%tab-panel.reds
					%text-box.reds
				]
			]
		]
	]
	%libRed/ [
		%libRed.def
		%libRed.lib
		%libRed.red
		%red.h
	]
	%utils/ [
		%extractor.r
		%redbin.r
		%call.r
		%preprocessor.r
	]
	%system/ [
		%compiler.r
		%config.r
		%emitter.r
		%linker.r
		%loader.r
		%assets/ [
			%red.ico
			%red-3D.ico
			%red-mono.ico
			%osx/ [
				%Info.plist
				%Resources/ [
					%AppIcon.icns
				]
			]
		]
		%runtime/ [
			%android.reds
			%common.reds
			%darwin.reds
			%debug.reds
			%freebsd.reds
			%libc.reds
			%lib-names.reds
			%lib-natives.reds
			%linux.reds
			%linux-sigaction.reds
			%POSIX.reds
			%POSIX-signals.reds
			%start.reds
			%syllable.reds
			%system.reds
			%utils.reds
			%win32.reds
			%win32-driver.reds
		]
		%formats/ [
			%ELF.r
			%Mach-APP.r
			%Mach-O.r
			%PE.r
		]
		%targets/ [
			%ARM.r
			%IA-32.r
			%target-class.r
		]
		%utils/ [
			%IEEE-754.r
			%int-to-bin.r
			%libRedRT.r
			%libRedRT-exports.r
			%r2-forward.r
			%secure-clean-path.r
			%virtual-struct.r
			%profiler.r
			%unicode.r
		]
	]
]

change-dir %build/
