Red [
	Title: "x86-64 Red release runtime smoke test"
]

fail: func [message [string!]][
	print rejoin ["FAIL: " message]
	quit/return 1
]

check: func [condition [logic!] message [string!]][
	unless condition [fail message]
]

square: func [value [integer!]][value * value]

values: copy []
repeat i 2000 [append values reduce [i square i form i]]
check 6000 = length? values "block growth"
check 4000000 = pick values 5999 "function result"
unless "2000" = last values [fail rejoin ["string conversion: " mold last values]]

text: copy ""
repeat i 1000 [append text either odd? i ["x"]["yz"]]
check 1500 = length? text "string growth"

record: context [name: "red" count: 64]
check "red" = record/name "object path"
check 4096 = square record/count "object function argument"

sorted-values: sort copy [9 2 7 1 5]
check sorted-values = [1 2 5 7 9] "block sort callback"
sorted-text: sort copy "x64backend"
check sorted-text = "46abcdeknx" "string sort callback"
interpreted-copy: do [copy/part [10 20 30 40] 3]
check interpreted-copy = [10 20 30] "interpreted refined native dispatch"
loaded-token: load "*test12*"
check all [word? loaded-token "*test12*" = form loaded-token] "lexer rebased zero index"
check 3.5 = transcode/one "3.5" "float token transcoding"
roundtrip-path: first [a/1.234/c]
check roundtrip-path == transcode/one mold roundtrip-path "path token round-trip"
case-result-1: select/case "Aabcde" "a"
unless #"b" = case-result-1 [fail rejoin ["select/case first: " mold case-result-1]]
case-result-2: select/case "aAbcde" "A"
unless #"b" = case-result-2 [fail rejoin ["select/case second: " mold case-result-2]]

dynamic-select: func [case [logic!]][select/:case "Aabcde" "a"]
dynamic-case-result: dynamic-select true
unless #"b" = dynamic-case-result [fail rejoin ["dynamic select/case: " mold dynamic-case-result]]
dynamic-do: func [trace [logic!]][do/:trace [] does []]
dynamic-do true

sum-routine: routine [
	a [integer!]
	b [integer!]
	return: [integer!]
][
	a + b
]
check 7 = sum-routine 3 4 "direct routine call"
applied-routine: apply :sum-routine [4 5]
unless 9 = applied-routine [fail rejoin ["applied routine call: " mold applied-routine]]
mixed-routine: routine [
	a [integer!]
	x [float!]
	b [integer!]
	return: [float!]
][
	(as-float a) + x + as-float b
]
applied-mixed-routine: apply :mixed-routine [2 3.5 4]
unless 9.5 = applied-mixed-routine [fail rejoin ["applied mixed routine call: " mold applied-mixed-routine]]

do [
	trace-nested: func [[no-trace] code][do/trace code does []]
	trace-nested [trace-nested []]
]

repeat cycle 20 [
	garbage: make block! 2000
	repeat i 2000 [append garbage reduce [i form i]]
	recycle
	check 6000 = length? values "live block after recycle"
	check 1500 = length? text "live string after recycle"
]

print "X64-RED-OK"
