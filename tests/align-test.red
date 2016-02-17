Red [
	Title:   "Para/align testing script"
	Author:  "WiseGenius"
	File: 	 %align-test.red
	Needs:	 'View
]

view [
    a: area {Hello, World!}
    return
    f: field {Hello, World!}
    return
    t: text {Hello, World!}
    return
    button {left}   [p/align: 'left]
    button {center} [p/align: 'center]
    button {right}  [p/align: 'right]
    
    do [a/para: f/para: t/para: p: make para! []]
]