Red/System [
	Title: "Red/System x86-64 imported data extra test library"
]

x64-flag: yes

x64-add-two: func [value [integer!] return: [integer!]][
	value + 2
]

x64-op: as function! [value [integer!] return: [integer!]] :x64-add-two

#export [x64-flag x64-op]
