Red []

#include %random.red

;; Seed
random-seed 310952

print ["------test 1------" lf]
print ["Random dice throw (1 - 6) (100x)" lf]
i: 1 
until [
    j: 1
	until [
	    prin [random 6 " "]
        j: j + 1
		j > 10
	]
	print newline
	i: i + 1
    i > 10
]

print ["------test 2------" lf]
print ["Random true/false (100x)" lf]

logval: true
i: 1
until [
    j: 1
	until [
	    prin [random logval " "]	
        j: j + 1
		j > 10
	]
	print newline
    i: i + 1
    i > 10
]

print ["------test 3------" lf]
print ["Randomize string "abcdef" (100x)" lf]

strval: random "abcdef"
i: 1
until [
    print [random strval]
    i: i + 1
    i > 99
]

print ["------test 4------" lf]
print [{Return single element of block input [1 "abcdef" 3 4] (10x)} lf]

blockval: [1 "abcdef" 3 4]
i: 1
until [
    print [random/only blockval]
    i: i + 1
    i > 10
]

random-free

print [lf "---------" lf "End of program." lf]
