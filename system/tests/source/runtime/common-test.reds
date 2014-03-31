Red/System [
	Title:   "Red/System runtime common test"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %common-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds


~~~start-file~~~ "common"

===start-group=== "form type"

  --test-- "ft1"
    ft1-result: form-type type-integer!
  --assert #"i" = ft1-result/1
  --assert #"n" = ft1-result/2
  --assert #"t" = ft1-result/3
  --assert #"e" = ft1-result/4
  --assert #"g" = ft1-result/5
  --assert #"e" = ft1-result/6
  --assert #"r" = ft1-result/7
  --assert #"!" = ft1-result/8
  --assert null-byte = ft1-result/9

  --test-- "ft2"
    ft2-result: form-type 10
  --assert 12 = length? ft2-result     ;; "invalid type"

  --test-- "ft3"
    ft3-result: form-type 1001
  --assert #"a" = ft3-result/1
  --assert #"l" = ft3-result/2
  --assert #"i" = ft3-result/3
  --assert #"a" = ft3-result/4
  --assert #"s" = ft3-result/5
  --assert null-byte = ft3-result/6

===end-group===

~~~end-file~~~

