Red/System [
	Title:   "Red/System byte! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %byte-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

qt-start-file "byte!"


;-- Byte literals & operators test --
	qt-assert "byte-type-1" #"A" = #"A"
	qt-assert "byte-type-2" #"A" <> #"B"
	qt-assert "byte-type-3" #"A" < #"B"


;-- Byte literals assignment --
	t: #"^(C6)"
	qt-assert "byte-type-4" t = #"^(C6)"
	u: #"^(C6)"
	qt-assert "byte-type-5" t = u

;-- Math operations --
	b: #"A"
	a: b + 1
	qt-assert "byte-type-6" a = #"B"

	a: t / 3
	qt-assert "byte-type-7" a = #"B"


;-- Passing byte! as argument and returning a byte! --
	foo: func [v [byte!] return: [byte!]][v]
	b: foo a
	qt-assert "byte-type-8" b = #"B"


;-- Byte as c-string! element (READ access)--
	str: "Hello World!"
	c: str/1
	qt-assert "byte-read-1" c = #"H"
	qt-assert "byte-read-2" c = str/1
	qt-assert "byte-read-3" str/1 = c

	d: 2
	c: str/d
	qt-assert "byte-read-4" c = #"e"
	qt-assert "byte-read-5" str/1 = #"H"
	qt-assert "byte-read-6" #"H" = foo str/1
	c: foo str/d
	qt-assert "byte-read-7" c = #"e"


;-- same tests but with local variables --
	byte-read: func [/local str [c-string!] c [byte!] d [byte!]][
		str: "Hello World!"
		c: str/1
		qt-assert "byte-read-1" c = #"H"
		qt-assert "byte-read-2" c = str/1
		qt-assert "byte-read-3" str/1 = c

		d: 2
		c: str/d
		qt-assert "byte-read-4" c = #"e"
		qt-assert "byte-read-5" str/1 = #"H"
		qt-assert "byte-read-6" #"H" = foo str/1
		c: foo str/d
		qt-assert "byte-read-7" c = #"e"
	]
	byte-read


;-- Byte as c-string! element (WRITE access)--
	strw: "Hello "
	strw/1: #"y"
	qt-assert "byte-write-1" strw/1 = #"y"
	
	c: 6
	strw/c: #"w"
	qt-assert "byte-write-2"  strw/c = #"w"
	;print str
	
	byte-write: func [/local str [c-string!] c [integer!]][
		str: "Hello "
		str/1: #"y"
		qt-assert "byte-write-3"  str/1 = #"y"
	
		c: 6
		str/c: #"w"
		qt-assert "byte-write-4"  str/c = #"w"
		;print str
	]
	byte-write


qt-end-file

