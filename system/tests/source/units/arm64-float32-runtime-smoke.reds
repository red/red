Red/System [
	Title: "Red/System ARM64 float32 runtime smoke test"
]

#if target = 'ARM64 [
	local-float: func [n [float32!] return: [float32!] /local p [float32!]][p: n p]
	one: func [return: [float32!]][as float32! 1.0]
	add-two: func [a [float!] b [float!] return: [float32!]][
		(as float32! a) + (as float32! b)
	]

	pi64: 3.141592653589793
	print-line [
		"cast=" as float32! -1.0
		" cos=" as-float32 cos pi64
		" local=" local-float as float32! 3.1415927
		" one=" one
		" eq-cos=" (as float32! -1.0) = as-float32 cos pi64
		" left=" one * as float32! 1.0
		" right=" (as float32! 1.0) * one
		" div=" one / (local-float as float32! 2.0)
		" add=" add-two 1.0 2.0
	]
]
