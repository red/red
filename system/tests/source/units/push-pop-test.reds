Red/System [
	Title:   "push/pop keywords test"
	File:    %push-pop-test.reds
	Tabs:	 4
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "push-pop"

===start-group=== "Basic push/pop"

	--test-- "pp-1"
	;; push integer literal, pop it back
	foo-pp1: func [return: [integer!] /local n [integer!]][
		push 42
		n: pop
		return n
	]
	--assert 42 = foo-pp1

	--test-- "pp-2"
	;; push two values, pop in LIFO order
	foo-pp2: func [return: [integer!] /local a [integer!] b [integer!]][
		push 10
		push 20
		b: pop
		a: pop
		return (a * 1000) + b
	]
	--assert 10020 = foo-pp2

	--test-- "pp-3"
	;; push expression result
	foo-pp3: func [return: [integer!] /local n [integer!] hi [integer!] lo [integer!]][
		n: 7
		push n * 2
		push n + 1
		lo: pop
		hi: pop
		return (hi * 100) + lo
	]
	--assert 1408 = foo-pp3

	--test-- "pp-4"
	;; push a variable value
	foo-pp4: func [return: [integer!] /local v [integer!]][
		v: 123
		push v
		return pop
	]
	--assert 123 = foo-pp4

	--test-- "pp-5"
	;; pop directly inside an expression
	foo-pp5: func [return: [integer!]][
		push 100
		return pop + 5
	]
	--assert 105 = foo-pp5

===end-group===

===start-group=== "Global (top-level) push/pop"

	;; Push/pop at global scope (Red/System spec section 11 places no
	;; restriction on where these can be used). The program entry
	;; point has its own stack frame so these operate on it.
	gp-val: 0
	push 77
	gp-val: pop
	--test-- "pp-global-1"
		--assert 77 = gp-val

	push 10
	push 20
	gp-b: pop
	gp-a: pop
	--test-- "pp-global-2"
		--assert 10 = gp-a
		--assert 20 = gp-b

===end-group===

~~~end-file~~~
