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


;-- Math operations --
	b: #"A"
	a: b + 1
	qt-assert "byte-type-5" a = #"B"

	a: t / 3
	qt-assert "byte-type-6" a = #"B"


;-- Passing byte! as argument and returning a byte! --
	foo: func [v [byte!] return: [byte!]][v]
	b: foo a
	qt-assert "byte-type-7" b = #"B"


;-- Byte as c-string! element --
	str: "Hello World!"
	c: str/1
	qt-assert "byte-cstring-1" c = #"H"

	d: 2
	c: str/d
	qt-assert "byte-cstring-2" c = #"e"
	qt-assert "byte-cstring-3" str/1 = #"H"
	qt-assert "byte-cstring-4" #"H" = foo str/1
	c: foo str/d
	qt-assert "byte-cstring-5" c = #"e"


;-- same tests but with local variables --
	foobar: func [/local str [c-string!] c [byte!] d [byte!]][
		str: "Hello World!"
		c: str/1
		qt-assert "byte-local-1" c = #"H"

		d: 2
		c: str/d
		qt-assert "byte-local-2" c = #"e"
		qt-assert "byte-local-3" str/1 = #"H"
		qt-assert "byte-local-4" #"H" = foo str/1
		c: foo str/d
		qt-assert "byte-local-5" c = #"e"
	]
	foobar


qt-end-file

