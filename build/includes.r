REBOL [
	Title:	 "Red source files preprocessor"
	Author:  "Nenad Rakocevic"
	File:	 %includes.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

change-dir %..
do %utils/encap-fs.r

write %build/bin/sources.r set-cache [
	%build/ [
		%git.r
	]
	%encapper/ [
		%version.r
		%usage.txt
		%boot.red
		%compiler.r
		%lexer.r
		%modules.r
	]
	%environment/ [
		%actions.red
		%colors.red
		;%css-colors.red
		%datatypes.red
		%functions.red
		%natives.red
		%networking.red
		%operators.red
		%reactivity.red
		%routines.red
		%scalars.red
		%system.red
		%tools.red
		%codecs/ [
			%BMP.red
			%GIF.red
			%JPEG.red
			%PNG.red
			%CSV.red
			%JSON.red
			%redbin.red
		]
		%console/ [
			%auto-complete.red
			%engine.red
			%help.red
			%CLI/ [
				%console.red
				%input.red
				%POSIX.reds
				%win32.reds
				%settings.red
			]
			%GUI/ [
				%old/ [
					%gui-console.red
					%terminal.reds
					%windows.reds
				]
				%app.ico
				%core.red
				%gui-console.red
				%highlight.red
				%settings.red
				%tips.red
			]
		]
	]
	%runtime/ [
		%actions.reds
		%allocator.reds
		%call.reds
		%case-folding-table.reds
		%case-folding.reds
		%clipboard.reds
		%collector.reds
		%common.reds
		%compress.reds
		%crush.reds
		%crypto.reds
		%debug-tools.reds
		%definitions.reds
		%deflate.reds
		%dtoa.reds
		%externals.reds
		%hashtable.reds
		%image-utils.reds
		%interpreter.reds
		%lexer.reds
		%lexer-transitions.reds
		%macros.reds
		%natives.reds
		%ownership.reds
		%parse.reds
		%print.reds
		%random.reds
		%red.reds
		%redbin.reds
		%references.reds
		%simple-io.reds
		%sort.reds
		%stack.reds
		%structures.reds
		%threads.reds
		%threadpool.reds
		%tokenizer.reds
		%tools.reds
		%unicode.reds
		%utils.reds
		%vector2d.reds
		%wcwidth.reds
		%datatypes/ [
			%action.reds
			%block.reds
			%bitset.reds
			%binary.reds
			%char.reds
			%context.reds
			%datatype.reds
			%date.reds
			%email.reds
			%error.reds
			%event.reds
			%file.reds
			%float.reds
			%function.reds
			%get-path.reds
			%get-word.reds
			%handle.reds
			%hash.reds
			%image.reds
			%integer.reds
			%ipv6.reds
			%issue.reds
			%lit-path.reds
			%lit-word.reds
			%logic.reds
			%map.reds
			%money.reds
			%native.reds
			%none.reds
			%op.reds
			%object.reds
			%paren.reds
			%path.reds
			%pair.reds
			%percent.reds
			%point2D.reds
			%point3D.reds
			%port.reds
			%ref.reds
			%refinement.reds
			%routine.reds
			%series.reds
			%set-path.reds
			%set-word.reds
			%string.reds
			%symbol.reds
			%tag.reds
			%time.reds
			%triple.reds
			%typeset.reds
			%tuple.reds
			%unset.reds
			%url.reds
			%vector.reds
			%word.reds
		]
		%platform/ [
			%definitions/ [
				%COM.reds
				%darwin.reds
				%freebsd.reds
				%netbsd.reds
				%linux.reds
				%POSIX.reds
				%syllable.reds
				%windows.reds
			]
			%definitions.reds
			%image-wic.reds
			%image-gdiplus.reds
			%image-gdk.reds
			%image-quartz.reds
			%android.reds
			%darwin.reds
			%freebsd.reds
			%linux.reds
			%POSIX.reds
			%syllable.reds
			%win32.reds
			%image-stub.reds
			%win32-ansi.reds
			%win32-print.reds
		]
	]
	%modules/ [
		%view/ [
			%view.red
			%draw.red
			%rules.red
			%utils.red
			%RTD.red
			%styles.red
			%VID.red
			%backends/ [
				%keycodes.reds
				%platform.red
				%windows/ [
					%base.reds
					%button.reds
					%camera.reds
					%calendar.reds
					%classes.reds
					%comdlgs.reds
					%direct2d.reds
					%matrix2d.reds
					%draw-gdi.reds
					%draw.reds
					%events.reds
					%font.reds
					%gui.reds
					%menu.reds
					%panel.reds
					%para.reds
					%rules.red
					%styles.red
					%tab-panel.reds
					%text-list.reds
					%text-box.reds
					%win32.reds
				]
				%macOS/ [
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
					%rules.red
					%styles.red
					%selectors.reds
					%tab-panel.reds
					%text-box.reds
				]
				%gtk3/ [
					%camera.reds
					%camera-dev.reds
					%color.reds
					%comdlgs.reds
					%css.reds
					%draw.reds
					%events.reds
					%font.reds
					%gtk.reds
					%gui.reds
					%handlers.reds
					%menu.reds
					%para.reds
					%rules.red
					%styles.red
					%tab-panel.reds
					%text-box.reds
					%text-list.reds
					%v4l2.reds
				]
				%terminal/ [
					%widgets/ [
						%base.reds
						%button.reds
						%checkbox.reds
						%field.reds
						%group-box.reds
						%progress.reds
						%radio.reds
						%rich-text.reds
						%text-list.reds
					]
					%ansi-parser.reds
					%definitions.reds
					%draw.reds
					%events.reds
					%font.reds
					%gui.reds
					%make-ui.red
					%para.reds
					%screen.reds
					%styles.red
					%text-box.reds
					%timer.reds
					%tty.reds
					%utils.reds
					%widget.reds
				]
				%test/ [
					%draw.reds
					%events.reds
					%gui.reds
					%gui.red
					%styles.red
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
			%macOS/ [
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
			%heap.reds
			%freebsd.reds
			%netbsd.reds
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
