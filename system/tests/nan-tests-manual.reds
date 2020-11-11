Red/System [
	Title:   "Red/System manual test of IEEE-754 compliance of NaN comparison"
	Author:  "@hiiamboris"
	File: 	 %float-matrix-manual.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;; these tests are included into the float-test.reds
;; but due to limitations of quick-test framework
;; their coverage there is narrower and readability lower

;; to be compiled with `-d` flag to merge assertions in!
;; tests succeed if they don't print a single "FAILED:" line

nan:   0.0 / 0.0
+inf:  1.0 / 0.0
-inf: -1.0 / 0.0
zero:  0.0
one:   1.0
two:   2.0

;; check point 1 - assertions
assert nan <> one
assert nan <> nan
assert not (nan = nan)
assert not (nan < one)
assert not (nan > one)
assert not (nan = one)
assert one < two
assert not (one > two)
assert one = one
assert not (one <> one)

;; check point 2 - if's
if nan = nan [print-line ["FAILED: if nan = nan test"]]
if nan = one [print-line ["FAILED: if nan = one test"]]
if nan < nan [print-line ["FAILED: if nan < nan test"]]
if nan < one [print-line ["FAILED: if nan < one test"]]
if one < nan [print-line ["FAILED: if one < nan test"]]
if two < one [print-line ["FAILED: if two < one test"]]
if one < nan [print-line ["FAILED: if one < one test"]]

if one = one [print-line ["OK: if one = one"]]
if one < two [print-line ["OK: if one < two"]]
if nan <> nan [print-line ["OK: if nan <> nan"]]

if not (one = one)  [print-line ["FAILED: if not one = one test"]]
if not (one <> nan) [print-line ["FAILED: if not one <> nan test"]]
if not (nan <> nan) [print-line ["FAILED: if not nan <> nan test"]]

;; ... unless's
unless one = one  [print-line ["FAILED: unless one = one test"]]
unless one <> nan [print-line ["FAILED: unless one <> nan test"]]
unless nan <> nan [print-line ["FAILED: unless nan <> nan test"]]

;; check point 3 - either's
either one = one [print-line "OK: either one = one"][print-line "FAILED: either one = one"]
either one < two [print-line "OK: either one < two"][print-line "FAILED: either one < two"]
either two > one [print-line "OK: either two > one"][print-line "FAILED: either two > one"]
either nan = nan [print-line "FAILED: either nan = nan"][print-line "OK: either nan = nan"]
either nan = one [print-line "FAILED: either nan = one"][print-line "OK: either nan = one"]
either one = nan [print-line "FAILED: either one = nan"][print-line "OK: either one = nan"]
either one < one [print-line "FAILED: either one < one"][print-line "OK: either one < one"]
either one < nan [print-line "FAILED: either one < nan"][print-line "OK: either one < nan"]
either nan < one [print-line "FAILED: either nan < one"][print-line "OK: either nan < one"]
either one > one [print-line "FAILED: either one > one"][print-line "OK: either one > one"]
either one > nan [print-line "FAILED: either one > nan"][print-line "OK: either one > nan"]
either nan > one [print-line "FAILED: either nan > one"][print-line "OK: either nan > one"]
either one <> one [print-line "FAILED: either one <> one"][print-line "OK: either one <> one"]
either nan <> nan [print-line "OK: either nan <> nan"][print-line "FAILED: either nan <> nan"]
either one <> nan [print-line "OK: either one <> nan"][print-line "FAILED: either one <> nan"]
either nan <> one [print-line "OK: either nan <> one"][print-line "FAILED: either nan <> one"]
either one <> two [print-line "OK: either one <> two"][print-line "FAILED: either one <> two"]

;; check point 4 - case's
case [one = one [print-line "OK: case one = one"] true [print-line "FAILED: case one = one"]]
case [one < two [print-line "OK: case one < two"] true [print-line "FAILED: case one < two"]]
case [two > one [print-line "OK: case two > one"] true [print-line "FAILED: case two > one"]]
case [nan = nan [print-line "FAILED: case nan = nan"] true [print-line "OK: case nan = nan"]]
case [nan = one [print-line "FAILED: case nan = one"] true [print-line "OK: case nan = one"]]
case [one = nan [print-line "FAILED: case one = nan"] true [print-line "OK: case one = nan"]]
case [one < one [print-line "FAILED: case one < one"] true [print-line "OK: case one < one"]]
case [one < nan [print-line "FAILED: case one < nan"] true [print-line "OK: case one < nan"]]
case [nan < one [print-line "FAILED: case nan < one"] true [print-line "OK: case nan < one"]]
case [one > one [print-line "FAILED: case one > one"] true [print-line "OK: case one > one"]]
case [one > nan [print-line "FAILED: case one > nan"] true [print-line "OK: case one > nan"]]
case [nan > one [print-line "FAILED: case nan > one"] true [print-line "OK: case nan > one"]]
case [one <> one [print-line "FAILED: case one <> one"] true [print-line "OK: case one <> one"]]
case [nan <> nan [print-line "OK: case nan <> nan"] true [print-line "FAILED: case nan <> nan"]]
case [one <> nan [print-line "OK: case one <> nan"] true [print-line "FAILED: case one <> nan"]]
case [nan <> one [print-line "OK: case nan <> one"] true [print-line "FAILED: case nan <> one"]]
case [one <> two [print-line "OK: case one <> two"] true [print-line "FAILED: case one <> two"]]
case [
	nan = nan [print-line "FAILED: case nan = nan 2"]
	nan > one [print-line "FAILED: case nan = one 2"]
	one > nan [print-line "FAILED: case one = nan 2"]
	one = one [print-line "OK: case complex"]
]

;; check point 5 - until's end-condition
i: 0  f: 5.0  g: 0.0
until [
	i: i + 1
	f: f - 1.0
	g: 0.0 / f
	g <> zero
]
unless i = 5 [print-line ["FAILED: until g <> zero with i=" i " f=" f]]

i: 0  f: 5.0
until [
	i: i + 1
	f: f - 1.0
	0.0 / f <> 0.0
]
unless i = 5 [print-line ["FAILED: until 0.0 / f <> 0.0 with i=" i " f=" f]]

i: 0  f: 5.0
until [
	i: i + 1
	f: f - 1.0
	not (0.0 / f <= +inf)
]
unless i = 5 [print-line ["FAILED: until not (0.0 / f <= +inf) with i=" i " f=" f]]

i: 0  f: 5.0
until [
	i: i + 1
	f: f - 1.0
	not (f * +inf <= +inf)
]
unless i = 5 [print-line ["FAILED: until not (f * +inf <= +inf) with i=" i " f=" f]]

;; check point 6 - while's enter-condition
i: 0  f: 5.0  g: 0.0
while [g =  0.0] [i: i + 1  f: f - 1.0  g: 0.0 / f]
unless i = 5 [print-line ["FAILED: while g = zero with i=" i " f=" f]]

i: 0  f: 5.0  g: 0.0
while [g <= +inf] [i: i + 1  f: f - 1.0  g: 0.0 / f]
unless i = 5 [print-line ["FAILED: while g <= +inf with i=" i " f=" f]]

i: 0  f: 5.0  g: 0.0
while [g >= -inf] [i: i + 1  f: f - 1.0  g: 0.0 / f]
unless i = 5 [print-line ["FAILED: while g >= -inf with i=" i " f=" f]]

i: 0  f: 5.0  g: 0.0
while [-inf <= g] [i: i + 1  f: f - 1.0  g: 0.0 / f]
unless i = 5 [print-line ["FAILED: while -inf <= g with i=" i " f=" f]]

i: 0  f: 5.0  g: 0.0
while [+inf >= g] [i: i + 1  f: f - 1.0  g: 0.0 / f]
unless i = 5 [print-line ["FAILED: while +inf >= g with i=" i " f=" f]]

;; check point 7 - all's
       all [0.0 = 0.0  zero < one  one < two  one <> nan  nan <> nan  nan = nan  print-line "FAILED: all ... nan = nan 1"]
if     all [0.0 = 0.0  zero < one  one < two  one <> nan  nan <> nan  nan = nan][print-line "FAILED: all ... nan = nan 2"]
unless all [0.0 = 0.0  zero < one  one < two  one <> nan  nan <> nan][print-line "FAILED: unless all ..."]

either all [one = one] [print-line "OK: either all [one = one]"][print-line "FAILED: either all [one = one]"]
either all [one < two] [print-line "OK: either all [one < two]"][print-line "FAILED: either all [one < two]"]
either all [two > one] [print-line "OK: either all [two > one]"][print-line "FAILED: either all [two > one]"]
either all [nan = nan] [print-line "FAILED: either all [nan = nan]"][print-line "OK: either all [nan = nan]"]
either all [nan = one] [print-line "FAILED: either all [nan = one]"][print-line "OK: either all [nan = one]"]
either all [one = nan] [print-line "FAILED: either all [one = nan]"][print-line "OK: either all [one = nan]"]
either all [one < one] [print-line "FAILED: either all [one < one]"][print-line "OK: either all [one < one]"]
either all [one < nan] [print-line "FAILED: either all [one < nan]"][print-line "OK: either all [one < nan]"]
either all [nan < one] [print-line "FAILED: either all [nan < one]"][print-line "OK: either all [nan < one]"]
either all [one > one] [print-line "FAILED: either all [one > one]"][print-line "OK: either all [one > one]"]
either all [one > nan] [print-line "FAILED: either all [one > nan]"][print-line "OK: either all [one > nan]"]
either all [nan > one] [print-line "FAILED: either all [nan > one]"][print-line "OK: either all [nan > one]"]
either all [one <> one] [print-line "FAILED: either all [one <> one]"][print-line "OK: either all [one <> one]"]
either all [nan <> nan] [print-line "OK: either all [nan <> nan]"][print-line "FAILED: either all [nan <> nan]"]
either all [one <> nan] [print-line "OK: either all [one <> nan]"][print-line "FAILED: either all [one <> nan]"]
either all [nan <> one] [print-line "OK: either all [nan <> one]"][print-line "FAILED: either all [nan <> one]"]
either all [one <> two] [print-line "OK: either all [one <> two]"][print-line "FAILED: either all [one <> two]"]

b: all [nan = nan]      if b [print-line "FAILED: b: all [nan = nan]"]
b: all [one < nan]      if b [print-line "FAILED: b: all [nan = nan]"]
b: all [one > nan]      if b [print-line "FAILED: b: all [nan = nan]"]
b: all [one = one]  unless b [print-line "FAILED: b: all [nan = nan]"]

;; ... any's
       any [0.0 <> 0.0  zero > one  one > two  one = nan  nan = nan  nan <> nan  print-line "FAILED: any ... nan <> nan 1"]
unless any [0.0 <> 0.0  zero > one  one > two  one = nan  nan = nan  nan <> nan][print-line "FAILED: any ... nan <> nan 2"]
either any [0.0 <> 0.0  zero > one  one > two  one = nan  nan = nan] [print-line "FAILED: either any ..."] [print-line "OK: either any ..."]

either any [one = one] [print-line "OK: either any [one = one]"][print-line "FAILED: either any [one = one]"]
either any [one < two] [print-line "OK: either any [one < two]"][print-line "FAILED: either any [one < two]"]
either any [two > one] [print-line "OK: either any [two > one]"][print-line "FAILED: either any [two > one]"]
either any [nan = nan] [print-line "FAILED: either any [nan = nan]"][print-line "OK: either any [nan = nan]"]
either any [nan = one] [print-line "FAILED: either any [nan = one]"][print-line "OK: either any [nan = one]"]
either any [one = nan] [print-line "FAILED: either any [one = nan]"][print-line "OK: either any [one = nan]"]
either any [one < one] [print-line "FAILED: either any [one < one]"][print-line "OK: either any [one < one]"]
either any [one < nan] [print-line "FAILED: either any [one < nan]"][print-line "OK: either any [one < nan]"]
either any [nan < one] [print-line "FAILED: either any [nan < one]"][print-line "OK: either any [nan < one]"]
either any [one > one] [print-line "FAILED: either any [one > one]"][print-line "OK: either any [one > one]"]
either any [one > nan] [print-line "FAILED: either any [one > nan]"][print-line "OK: either any [one > nan]"]
either any [nan > one] [print-line "FAILED: either any [nan > one]"][print-line "OK: either any [nan > one]"]
either any [one <> one] [print-line "FAILED: either any [one <> one]"][print-line "OK: either any [one <> one]"]
either any [nan <> nan] [print-line "OK: either any [nan <> nan]"][print-line "FAILED: either any [nan <> nan]"]
either any [one <> nan] [print-line "OK: either any [one <> nan]"][print-line "FAILED: either any [one <> nan]"]
either any [nan <> one] [print-line "OK: either any [nan <> one]"][print-line "FAILED: either any [nan <> one]"]
either any [one <> two] [print-line "OK: either any [one <> two]"][print-line "FAILED: either any [one <> two]"]

b: any [nan = nan]      if b [print-line "FAILED: b: any [nan = nan]"]
b: any [one < nan]      if b [print-line "FAILED: b: any [one < nan]"]
b: any [one > nan]      if b [print-line "FAILED: b: any [one > nan]"]
b: any [one = one]  unless b [print-line "FAILED: b: any [one = one]"]
b: any [nan = nan one = one] unless b [print-line "FAILED: b: any [nan = nan one = one]"]


;; check point 8 - functions with logic arguments from nan comparison
f-yes: func [cond [logic!] msg [c-string!]] [unless cond [print-line ["FAILED: " msg]]]
f-not: func [cond [logic!] msg [c-string!]] [    if cond [print-line ["FAILED: " msg]]]

f-yes nan <> nan "nan <> nan"
f-yes one <> nan "one <> nan"
f-yes not (nan = nan) "not nan = nan"
f-yes not (one = nan) "not one = nan"

f-not nan = nan "nan = nan"
f-not nan = one "nan = one"
f-not one = nan "one = nan"
f-not nan < one "nan < one"
f-not one < nan "one < nan"
f-not nan > one "nan > one"
f-not one > nan "one > nan"

;; ... functions with integer arguments from nan comparison
fi-yes: func [i [integer!] msg [c-string!]] [if i <> 1 [print-line ["FAILED: " msg]]]
fi-not: func [i [integer!] msg [c-string!]] [if i <> 0 [print-line ["FAILED: " msg]]]

fi-yes as-integer nan <> nan "nan <> nan"
fi-yes as-integer one <> nan "one <> nan"
fi-yes as-integer not (nan = nan) "not nan = nan"
fi-yes as-integer not (one = nan) "not one = nan"

fi-not as-integer nan = nan "nan = nan"
fi-not as-integer nan = one "nan = one"
fi-not as-integer one = nan "one = nan"
fi-not as-integer nan < one "nan < one"
fi-not as-integer one < nan "one < nan"
fi-not as-integer nan > one "nan > one"
fi-not as-integer one > nan "one > nan"

;; check point 9 - logic return values from nan comparison
cmp=: func [a [float!] b [float!] return: [logic!]] [a = b]
cmp<: func [a [float!] b [float!] return: [logic!]] [a < b]
cmp>: func [a [float!] b [float!] return: [logic!]] [a > b]

if cmp= nan nan [print-line "FAILED: cmp= nan nan"]
if cmp= one nan [print-line "FAILED: cmp= one nan"]
if cmp< one nan [print-line "FAILED: cmp< one nan"]
if cmp< nan one [print-line "FAILED: cmp< nan one"]
if cmp> one nan [print-line "FAILED: cmp> one nan"]
if cmp> nan one [print-line "FAILED: cmp> nan one"]
unless cmp= one one [print-line "FAILED: cmp= one one"]
unless cmp< one two [print-line "FAILED: cmp< one two"]
unless cmp> two one [print-line "FAILED: cmp> two one"]

;; ... integer return values from nan comparison
icmp=: func [a [float!] b [float!] return: [integer!]] [as integer! a = b]
icmp<: func [a [float!] b [float!] return: [integer!]] [as integer! a < b]
icmp>: func [a [float!] b [float!] return: [integer!]] [as integer! a > b]

if 0 <> icmp= nan nan [print-line "FAILED: icmp= nan nan"]
if 0 <> icmp= one nan [print-line "FAILED: icmp= one nan"]
if 0 <> icmp< one nan [print-line "FAILED: icmp< one nan"]
if 0 <> icmp< nan one [print-line "FAILED: icmp< nan one"]
if 0 <> icmp> one nan [print-line "FAILED: icmp> one nan"]
if 0 <> icmp> nan one [print-line "FAILED: icmp> nan one"]
if 1 <> icmp= one one [print-line "FAILED: icmp= one one"]
if 1 <> icmp< one two [print-line "FAILED: icmp< one two"]
if 1 <> icmp> two one [print-line "FAILED: icmp> two one"]

;; check point 10 - assignment to logic/integer variables
b: nan = nan      if b [print-line "FAILED: b: nan = nan"]
b: one < nan      if b [print-line "FAILED: b: one < nan"]
b: one > nan      if b [print-line "FAILED: b: one > nan"]
b: nan < one      if b [print-line "FAILED: b: nan < one"]
b: nan > one      if b [print-line "FAILED: b: nan > one"]
b: one = one  unless b [print-line "FAILED: b: one = one"]
b: nan <> nan unless b [print-line "FAILED: b: nan <> nan"]

i: as integer! nan = nan   if i <> 0 [print-line "FAILED: i: as int! nan = nan"]
i: as integer! one < nan   if i <> 0 [print-line "FAILED: i: as int! one < nan"]
i: as integer! one > nan   if i <> 0 [print-line "FAILED: i: as int! one > nan"]
i: as integer! nan < one   if i <> 0 [print-line "FAILED: i: as int! nan < one"]
i: as integer! nan > one   if i <> 0 [print-line "FAILED: i: as int! nan > one"]
i: as integer! one = one   if i = 0  [print-line "FAILED: i: as int! one = one"]
i: as integer! nan <> nan  if i = 0  [print-line "FAILED: i: as int! nan <> nan"]

;; ... also assignment from inside a chunked expression
i: as integer! (nan = nan)  if i <> 0 [print-line "FAILED: i: as int! nan = nan 2"]
i: as integer! (one < nan)  if i <> 0 [print-line "FAILED: i: as int! one < nan 2"]
i: as integer! (one > nan)  if i <> 0 [print-line "FAILED: i: as int! one > nan 2"]
i: as integer! (nan < one)  if i <> 0 [print-line "FAILED: i: as int! nan < one 2"]
i: as integer! (nan > one)  if i <> 0 [print-line "FAILED: i: as int! nan > one 2"]
i: as integer! (one = one)  if i = 0  [print-line "FAILED: i: as int! one = one 2"]
i: as integer! (nan <> nan) if i = 0  [print-line "FAILED: i: as int! nan <> nan 2"]

;; check point 11 - case & switch logic return values from nan comparison
b: case [true [one <> nan]]  unless b [print-line "FAILED: case return one <> nan"]
b: case [true [nan <> nan]]  unless b [print-line "FAILED: case return nan <> nan"]
b: case [true [nan =  nan]]      if b [print-line "FAILED: case return nan =  nan"]
b: case [true [one <= nan]]      if b [print-line "FAILED: case return one <= nan"]
b: case [true [one >= nan]]      if b [print-line "FAILED: case return one >= nan"]
b: case [true [nan <= one]]      if b [print-line "FAILED: case return nan <= one"]
b: case [true [nan >= one]]      if b [print-line "FAILED: case return nan >= one"]

b: switch 1 [1 [one <> nan]]  unless b [print-line "FAILED: switch return one <> nan"]
b: switch 1 [1 [nan <> nan]]  unless b [print-line "FAILED: switch return nan <> nan"]
b: switch 1 [1 [nan =  nan]]      if b [print-line "FAILED: switch return nan =  nan"]
b: switch 1 [1 [one <= nan]]      if b [print-line "FAILED: switch return one <= nan"]
b: switch 1 [1 [one >= nan]]      if b [print-line "FAILED: switch return one >= nan"]
b: switch 1 [1 [nan <= one]]      if b [print-line "FAILED: switch return nan <= one"]
b: switch 1 [1 [nan >= one]]      if b [print-line "FAILED: switch return nan >= one"]

;; check point 12 - inlined nans in any/all
if all [0.0 / 0.0 <= +inf]      [print-line "FAILED: if all [0.0 / 0.0 <= +inf] 1"]
if all [true 0.0 / 0.0 <= +inf] [print-line "FAILED: if all [0.0 / 0.0 <= +inf] 2"]
if all [0.0 / 0.0 <= +inf true] [print-line "FAILED: if all [0.0 / 0.0 <= +inf] 3"]

if     any [0.0 / 0.0 <= +inf]       [print-line "FAILED: if any [0.0 / 0.0 <= +inf] 1"]
if     any [0.0 / 0.0 <= +inf 1 = 2] [print-line "FAILED: if any [0.0 / 0.0 <= +inf] 2"]
unless any [true 0.0 / 0.0 <= +inf]  [print-line "FAILED: if any [0.0 / 0.0 <= +inf] 3"]
unless any [0.0 / 0.0 <= +inf true]  [print-line "FAILED: if any [0.0 / 0.0 <= +inf] 4"]

;; check point 13 - funcs ending in either returning logic, passed out of the func
ecmp=: func [c [logic!] a [float!] b [float!] return: [logic!]] [either c [a = b][a <> b]]
ecmp<: func [c [logic!] a [float!] b [float!] return: [logic!]] [either c [a < b][a >= b]]
ecmp>: func [c [logic!] a [float!] b [float!] return: [logic!]] [either c [a > b][a <= b]]

if     ecmp= yes nan nan [print-line "FAILED: ecmp= yes nan nan"]
unless ecmp=  no nan nan [print-line "FAILED: ecmp=  no nan nan"]
if     ecmp= yes one nan [print-line "FAILED: ecmp= yes one nan"]
unless ecmp=  no one nan [print-line "FAILED: ecmp=  no one nan"]
if     ecmp< yes two one [print-line "FAILED: ecmp< yes two one"]
if     ecmp<  no one two [print-line "FAILED: ecmp<  no one two"]
if     ecmp< yes one nan [print-line "FAILED: ecmp< yes one nan"]
if     ecmp<  no one nan [print-line "FAILED: ecmp<  no one nan"]
if     ecmp< yes nan one [print-line "FAILED: ecmp< yes nan one"]
if     ecmp<  no nan one [print-line "FAILED: ecmp<  no nan one"]
if     ecmp> yes one nan [print-line "FAILED: ecmp> yes one nan"]
if     ecmp>  no one nan [print-line "FAILED: ecmp>  no one nan"]
if     ecmp> yes nan one [print-line "FAILED: ecmp> yes nan one"]
if     ecmp>  no nan one [print-line "FAILED: ecmp>  no nan one"]










