REBOL [
	Title:   "Red/System ARM instruction encoding test script"
	File: 	 %arm-encoding-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;; Cross-compiles %arm-encoding.reds for Linux-ARM (cpu-version 5.0) and checks the emitted code.
;; Cores that ignore should-be-zero/one fields run the faulty encodings anyway; QEMU and strict
;; cores raise SIGILL on them, and ARMv5/v6 cores have no MOVW and no DMB. %arm-encoding-div.reds,
;; compiled for RPi with idiv?: no, must not use SDIV (Cortex-A8/A9 have none).

~~~start-file~~~ "ARM encodings"

	arm-enc-flag: qt/compile-flag
	qt/compile-flag: join arm-enc-flag " -t Linux-ARM "
	arm-enc-exe: --compile %source/compiler/arm-encoding.reds
	qt/compile-flag: arm-enc-flag
	arm-enc-bin: either arm-enc-exe [read/binary qt/runnable-dir/:arm-enc-exe][#{}]
	qt/compile-flag: join arm-enc-flag " -t RPi "
	arm-div-exe: --compile %source/compiler/arm-encoding-div.reds
	qt/compile-flag: arm-enc-flag
	arm-div-bin: either arm-div-exe [read/binary qt/runnable-dir/:arm-div-exe][#{}]

	arm-enc-movw?: func [
		"True if a MOVW loads the offset of a SUB/ADD r0|r1, fp, r0|r1 (address of a local)"
		bin [binary!]
		/local pos found
	][
		found: false
		foreach op [#{00004BE0} #{01104BE0} #{00008BE0} #{01108BE0}][
			pos: bin
			while [pos: find/case pos op][
				if all [
					4 < index? pos
					227 = first skip pos -1				;-- E3h: condition AL, data-processing immediate
					16 > first skip pos -2				;-- 0xh: MOVW (MOVS has B0h)
				][found: true]
				pos: next pos
			]
		]
		found
	]

	--test-- "arm-enc-1 compiles for Linux-ARM"
		--assert none <> arm-enc-exe

	--test-- "arm-enc-2 BLX r10 sets bits 19-8"
		--assert none <> find/case arm-enc-bin #{00A0A0E10C00A0E13AFF2FE1}	;-- MOV r10, r0 / MOV r0, r12 / BLX r10
		--assert none =  find/case arm-enc-bin #{00A0A0E10C00A0E13A0020E1}

	--test-- "arm-enc-3 byte! CMP has Rd = 0"
		--assert none <> find/case arm-enc-bin #{003CA0E1010C53E1}			;-- MOV r3, r0, LSL #24 / CMP r3, r1, LSL #24
		--assert none =  find/case arm-enc-bin #{003CA0E1013C53E1}

	--test-- "arm-enc-4 no MOVW below cpu-version 7.0"
		--assert none <> find/case arm-enc-bin #{00004BE0}					;-- SUB r0, fp, r0: a local's address
		--assert not arm-enc-movw? arm-enc-bin

	--test-- "arm-enc-5 memory fence below cpu-version 7.0"
		--assert none <> find/case arm-enc-bin #{0FEAE0E35FE04EE23EFF2FE1}	;-- MVN lr, #F000h / SUB lr, lr, #5Fh / BLX lr
		--assert none =  find/case arm-enc-bin #{5BF07FF5}					;-- DMB ish

	--test-- "arm-enc-6 byte! compared with a literal: low byte only"
		--assert none <> find/case arm-enc-bin #{003CA0E1410453E3}			;-- MOV r3, r0, LSL #24 / CMP r3, #41000000h

	--test-- "arm-enc-7 syscall number above 255"
		--assert none <> find/case arm-enc-bin #{4B7FB0E3}					;-- MOVS r7, #300
		--assert none =  find/case arm-enc-bin #{2C70A0E3}					;-- MOV r7, #44

	--test-- "arm-enc-8 FPU masks and status"
		--assert none <> find/case arm-enc-bin #{020CC0E3}					;-- BIC r0, r0, #200h	; zero-divide masked
		--assert none <> find/case arm-enc-bin #{010B80E3}					;-- ORR r0, r0, #400h	; overflow unmasked
		--assert none <> find/case arm-enc-bin #{9F0000E2}					;-- AND r0, r0, #9Fh	; status bits with IDC

	--test-- "arm-enc-9 push-all and pop-all save r0-r12, lr"
		--assert none <> find/case arm-enc-bin #{FF5F2DE9}					;-- PUSH {r0-r12, lr}
		--assert none <> find/case arm-enc-bin #{FF5FBDE8}					;-- POP {r0-r12, lr}

	--test-- "arm-enc-10 idiv?: no uses software division"
		--assert none <> arm-div-exe
		--assert none =  find/case arm-div-bin #{10F110E7}					;-- SDIV r0, r0, r1
		--assert none =  find/case arm-div-bin #{10F113E7}					;-- SDIV r3, r0, r1

	if arm-enc-exe [attempt [delete qt/runnable-dir/:arm-enc-exe]]
	if arm-div-exe [attempt [delete qt/runnable-dir/:arm-div-exe]]

~~~end-file~~~
