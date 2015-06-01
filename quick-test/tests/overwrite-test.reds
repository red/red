Red/System [
  Title:   "Tests for overwrite function"
	Author:  "Peter W A Wood"
	File: 	 %overwrite-test.reds
	Tabs:	 4
	Rights:  copyright (c) 2011-2015 Peter W A Wood
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %../quick-test.reds
#include %../overwrite.reds
#include %../prin-int.reds

qt-start-file "overwrite"

ow-s1: "Hello, World"
max-len: length? ow-s1
ow-e1: "Hello, Peter"
overwrite ow-s1 "Hello, Peter" max-len
qt-assert "ow-1" ow-s1 = ow-e1

ow-s2: "short"
max-len: length? ow-s2
ow-e2: "longe"
overwrite ow-s2 "longer" max-len
qt-assert "ow-2" ow-s2 = ow-e2
qt-assert "ow-3" 5 = length? ow-s2

ow-s3: "longer"
max-len: length? ow-s3
ow-e3: "short"
overwrite ow-s3 "short" max-len
qt-assert "ow-4" ow-s3 = ow-e3
qt-assert "ow-5" 5 = length? ow-s3

ow-s4: "longer"
max-len: length? ow-s4
ow-e4: "but no"
overwrite ow-s4 "s" max-len
overwrite ow-s4 "but not this long" max-len
qt-assert "ow-6" ow-s4 = ow-e4
qt-assert "ow-7" 6 = length? ow-s4

qt-end-file

