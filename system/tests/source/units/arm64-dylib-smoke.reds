Red/System [
	Title: "Red/System ARM64 shared-library smoke test"
]

#include %../../../../quick-test/quick-test.reds

#if target = 'ARM64 [
	#import [
		"libtest-dll1.so" cdecl [
			dll1-add-one: "add-one" [
				value   [integer!]
				return: [integer!]
			]
		]
		"libtest-dll2.so" cdecl [
			dll2-negate: "neg" [
				value   [integer!]
				return: [integer!]
			]
			dll2-negatef: "negf" [
				value   [float!]
				return: [float!]
			]
			dll2-negatef32: "negf32" [
				value   [float32!]
				return: [float32!]
			]
			dll2-true-false: "true-false" [
				value   [logic!]
				return: [logic!]
			]
		]
	]

	~~~start-file~~~ "arm64-dylib"

	--test-- "dylib-add"
		--assert 2 = dll1-add-one 1
	--test-- "dylib-add-overflow-positive"
		--assert -2147483648 = dll1-add-one 2147483647
	--test-- "dylib-add-overflow-negative"
		--assert -2147483647 = dll1-add-one -2147483648
	--test-- "dylib-negate"
		--assert -1 = dll2-negate 1
	--test-- "dylib-negate-float"
		--assert -1.0 = dll2-negatef 1.0
	--test-- "dylib-negate-float32"
		--assert (as float32! -1.0) = dll2-negatef32 as float32! 1.0
	--test-- "dylib-logic"
		--assert false = dll2-true-false true

	~~~end-file~~~
]
