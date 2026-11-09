Red/System [
	Title:   "Red/System ARM instruction encoding test source, software division"
	File: 	 %arm-encoding-div.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Config:  [idiv?: no]
]

;-- Compiled for RPi (cpu-version 7.0) by arm-encoding-test.r, which checks the emitted code; never run.

arm-div-a: 100
arm-div-b: 7
arm-div-q: arm-div-a / arm-div-b					;-- no SDIV: software division
arm-div-m: arm-div-a // arm-div-b
