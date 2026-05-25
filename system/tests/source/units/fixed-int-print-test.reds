Red/System [
	Title:   "Red/System fixed-width integer print test script"
	Author:  "Red Foundation"
	File: 	 %fixed-int-print-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#if any [target = 'IA-32 target = 'ARM] [

fi-print-u32-max: as uint32! FFFFFFFFh
fi-print-i64-min: as int64! 8000000000000000h
fi-print-u64-max: FFFFFFFFFFFFFFFFh

print-line as int8! -128
print-line as uint8! 255
print-line as int16! -32768
print-line as uint16! 65535
print-line as int32! -2147483648
print-line fi-print-u32-max
print-line fi-print-i64-min
print-line fi-print-u64-max

print as int8! -7
print "|"
print as uint16! 65535
print "|"
print fi-print-u32-max
print "|"
print-line fi-print-u64-max

]
