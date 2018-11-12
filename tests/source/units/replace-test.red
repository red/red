Red [
	Title:   "Red replace test script"
	Author:  "Nenad Rakocevic & Peter W A Wood & Toomas Vooglaid"
	File: 	 %replace-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "replace"

===start-group=== "replace"

	--test-- "replace-1"	--assert [1 2 8 4 5] = replace [1 2 3 4 5] 3 8
	--test-- "replace-2"	--assert [1 2 8 9 4 5] = replace [1 2 3 4 5] 3 [8 9]
	--test-- "replace-3"	--assert [1 2 8 9 5] = replace [1 2 3 4 5] [3 4] [8 9]
	--test-- "replace-4"	--assert [1 2 8 5] = replace [1 2 3 4 5] [3 4] 8
	--test-- "replace-5"	--assert [1 2 a 5] = replace [1 2 3 4 5] [3 4] 'a
	--test-- "replace-6"	--assert [a g c d] = replace [a b c d] 'b 'g
	--test-- "replace-7"	--assert 'a/b/g/d/e = replace 'a/b/c/d/e 'c 'g
	--test-- "replace-8"	--assert 'a/b/g/h/i/d/e = replace 'a/b/c/d/e 'c 'g/h/i
	--test-- "replace-9"	--assert 'a/b/c/h/i/d/e = replace 'a/b/g/h/i/d/e 'g/h/i 'c
	--test-- "replace-10"	--assert #{006400} = replace #{000100} #{01} 100
	--test-- "replace-11"	--assert %file.ext = replace %file.sub.ext ".sub." #"."
	--test-- "replace-12"	--assert "abra-abra" = replace "abracadabra" "cad" #"-"
	--test-- "replace-13"	--assert "abra-c-adabra" = replace "abracadabra" #"c" "-c-"

===end-group===

===start-group=== "replace/deep"

	--test-- "replace/deep-1"	--assert [1 2 3 [8 5]] = replace/deep [1 2 3 [4 5]] [quote 4] 8
	--test-- "replace/deep-2"	--assert [1 2 3 [4 8 9]] = replace/deep [1 2 3 [4 5]] [quote 5] [8 9]
	--test-- "replace/deep-3"	--assert [1 2 3 [8 9]] = replace/deep [1 2 3 [4 5]] [quote 4 quote 5] [8 9]
	--test-- "replace/deep-4"	--assert [1 2 3 [8]] = replace/deep [1 2 3 [4 5]] [quote 4 quote 5] 8
	--test-- "replace/deep-5"	--assert [1 2 a 4 5] = replace/deep [1 2 3 4 5] [quote 8 | quote 4 | quote 3] 'a
	--test-- "replace/deep-6"	--assert [a g h c d] = replace/deep [a b c d] ['b | 'd] [g h]

===end-group===

===start-group=== "replace/all"

	--test-- "replace/all-1"	--assert [1 4 3 4 5] = replace/all [1 2 3 2 5] 2 4
	--test-- "replace/all-2"	--assert [1 4 5 3 4 5] = replace/all [1 2 3 2] 2 [4 5]
	--test-- "replace/all-3"	--assert [1 8 9 8 9] = replace/all [1 2 3 2 3] [2 3] [8 9]
	--test-- "replace/all-4"	--assert [1 8 8] = replace/all [1 2 3 2 3] [2 3] 8
	--test-- "replace/all-5"	--assert 'a/b/g/d/g = replace/all 'a/b/c/d/c 'c 'g
	--test-- "replace/all-6"	--assert 'a/b/g/h/d/g/h = replace/all 'a/b/c/d/c 'c 'g/h
	--test-- "replace/all-7"	--assert #{640164} = replace/all #{000100} #{00} #{64}
	--test-- "replace/all-8"	--assert %file.sub.ext = replace/all %file!sub!ext #"!" #"."
	--test-- "replace/all-9"	--assert <tag body end> = replace/all <tag_body_end> "_" " "

===end-group===

===start-group=== "replace/deep/all"

	--test-- "replace/deep/all-1"	--assert [1 8 3 [4 8]] = replace/deep/all [1 2 3 [4 2]] [quote 2] 8
	--test-- "replace/deep/all-2"	--assert [1 8 9 3 [4 8 9]] = replace/deep/all [1 2 3 [4 5]] [quote 5 | quote 2] [8 9]
	--test-- "replace/deep/all-3"	--assert [i j c [i j]] = replace/deep/all [a b c [d e]] ['d 'e | 'a 'b] [i j]
	--test-- "replace/deep/all-4"	--assert [a [<tag> [<tag>]]] = replace/all/deep [a [b c [d b]]] ['d 'b | 'b 'c] <tag>

===end-group===


===start-group=== "replace in string with rule"

	--test-- "replace-str-rule1"	--assert "!racadabra" = replace "abracadabra" ["ra" | "ab"] #"!"
	--test-- "replace-str-rule2"	--assert "!!cad!!" = replace/all "abracadabra" ["ra" | "ab"] #"!"
	--test-- "replace-str-rule3"	--assert "!!cad!!" = replace/all "abracadabra" ["ra" | "ab"] does ["!"]
	--test-- "replace-str-rule4"	--assert "AbrACAdAbrA" == replace/all "abracadabra" [s: ["a" | "c"]] does [uppercase s/1]

===end-group===

===start-group=== "replace/case"

	--test-- "replace/case-1"	--assert "axbAab" = replace/case "aAbAab" "A" "x"
	--test-- "replace/case-2"	--assert "axbxab" = replace/case/all "aAbAab" "A" "x"
	--test-- "replace/case-3"	--assert "a-babAA-" = replace/case/all "aAbbabAAAa" ["Ab" | "Aa"] "-"
	--test-- "replace/case-4"	--assert "axbAab" = replace/case "aAbAab" ["A"] does ["x"]
	--test-- "replace/case-5"	--assert "axbxab" = replace/case/all "aAbAab" ["A"] does ["x"]
	--test-- "replace/case-6"	--assert %file.txt = replace/case %file.TXT.txt %.TXT ""
	--test-- "replace/case-7"	--assert %file.txt = replace/case/all %file.TXT.txt.TXT %.TXT ""
	--test-- "replace/case-8"	--assert <tag xyXx> = replace/case <tag xXXx> "X" "y"
	--test-- "replace/case-9"	--assert <tag xyyx> = replace/case/all <tag xXXx> "X" "y"
	--test-- "replace/case-10"	--assert 'a/X/o/X = replace/case 'a/X/x/X 'x 'o
	--test-- "replace/case-12"	--assert 'a/o/x/o = replace/case/all 'a/X/x/X 'X 'o
	--test-- "replace/case-13"	--assert ["a" "B" "x"] = replace/case/all ["a" "B" "a" "b"] ["a" "b"] "x"
	--test-- "replace/case-14"	--assert (make hash! [x a b [a B]]) = replace/case make hash! [a B a b [a B]] [a B] 'x
	--test-- "replace/case-15"	--assert (quote :x/b/A/x/B) = replace/case/all quote :a/b/A/a/B [a] 'x
	--test-- "replace/case-16"	--assert (quote (x A x)) = replace/case/all quote (a A a) 'a 'x

===end-group===

===start-group=== "replace/case/deep"

	--test-- "replace/case/deep-1"	--assert [x A x B [x A x B]] = replace/case/deep/all [a A b B [a A b B]] ['a | 'b] 'x
	--test-- "replace/case/deep-2"	--assert (quote (x A x B (x A x B))) = replace/case/deep/all quote (a A b B (a A b B)) ['a | 'b] 'x

===end-group===

~~~end-file~~~
