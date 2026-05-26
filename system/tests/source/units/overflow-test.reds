Red/System []

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "overflow?"

	;-- For each --test--, the assertions use direct `--assert <expr>` form,
	;-- not `--assert true = <expr>` (the compiler's reduce-logic-tests doesn't
	;-- handle a bare <last> tag on the RHS of `true =`).

	n:   declare integer!
	x:   declare integer!
	a:   declare integer!
	b:   declare integer!
	q:   declare integer!
	bx:  declare byte!
	by:  declare byte!
	lf?: declare logic!				;-- scratch logic for nested cases

	overflows-internally: func [return: [integer!] /local v [integer!]][
		v: 2147483647
		v + 1
	]

	;-- Basic ------------------------------------------------------------
	--test-- "no math body returns false"
		--assert not overflow? [print ""]

	--test-- "non-overflowing math returns false"
		--assert not overflow? [n: 1 + 1]
		--assert not overflow? [n: 100 * 200]
		--assert not overflow? [n: 1000 - 500]
		--assert not overflow? [n: 1000 / 5]

	;-- Signed integer! overflow -----------------------------------------
	--test-- "signed + overflow"
		x: 2147483647
		--assert overflow? [n: x + 1]
		--assert overflow? [n: x + x]
		--assert not overflow? [n: x + 0]

	--test-- "signed - overflow"
		x: -2147483648
		--assert overflow? [n: x - 1]
		--assert overflow? [n: x - 2147483647]
		--assert not overflow? [n: x - 0]

	--test-- "signed * overflow"
		--assert overflow? [n: 65536 * 65536]
		--assert overflow? [n: 46341 * 46341]
		--assert not overflow? [n: 46340 * 46340]
		--assert not overflow? [n: -1000 * 1000]
		x: -2147483648
		--assert overflow? [n: x * -1]

	;-- Unsigned byte! ---------------------------------------------------
	--test-- "unsigned byte + overflow"
		bx: #"^(FF)"  by: #"^(01)"
		--assert overflow? [bx: bx + by]
		bx: #"^(7F)"  by: #"^(01)"
		--assert not overflow? [bx: bx + by]
		bx: #"^(FE)"  by: #"^(01)"
		--assert not overflow? [bx: bx + by]

	--test-- "unsigned byte - underflow"
		bx: #"^(00)"  by: #"^(01)"
		--assert overflow? [bx: bx - by]
		bx: #"^(0A)"  by: #"^(05)"
		--assert not overflow? [bx: bx - by]

	;-- Shift ------------------------------------------------------------
	--test-- "signed << within range"
		--assert not overflow? [n: 1 << 30]
		n: 1073741823
		--assert not overflow? [n: n << 1]
		n: -1
		--assert not overflow? [n: n << 31]
		n: -1073741824
		--assert not overflow? [n: n << 1]

	--test-- "signed << overflow"
		--assert overflow? [n: 1 << 31]
		n: 1073741824
		--assert overflow? [n: n << 1]
		n: -2
		--assert overflow? [n: n << 31]
		n: -1073741825
		--assert overflow? [n: n << 1]

	--test-- "byte << within range"
		bx: #"^(01)"
		--assert not overflow? [bx: bx << 7]
		bx: #"^(0F)"
		--assert not overflow? [bx: bx << 4]

	--test-- "byte << overflow"
		bx: #"^(02)"
		--assert overflow? [bx: bx << 7]
		bx: #"^(10)"
		--assert overflow? [bx: bx << 4]

	;-- Division INT_MIN / -1 (would trap without pre-check) -------------
	--test-- "signed division INT_MIN / -1"
		a: -2147483648
		b: -1
		--assert overflow? [q: a / b]
		--assert overflow? [q: a // b]
		--assert overflow? [q: a % b]

	--test-- "signed division no-overflow"
		--assert not overflow? [q: 100 / 5]
		--assert not overflow? [q: -100 / 5]
		--assert not overflow? [q: 100 / -5]
		a: -2147483647 b: -1
		--assert not overflow? [q: a / b]

	;-- Early-out: body must short-circuit on first overflow -------------
	--test-- "early-out side-effect (mid-body overflow)"
		n: 0
		--assert overflow? [
			n: n + 1                                ;-- runs (no overflow)
			q: 2147483647 + 1                       ;-- overflows here
			n: n + 100                              ;-- must NOT run
		]
		--assert n = 1

	--test-- "early-out side-effect (first-op overflow)"
		n: 0
		--assert overflow? [
			q: 65536 * 65536                        ;-- overflows immediately
			n: n + 1                                ;-- must NOT run
			n: n + 1
		]
		--assert n = 0

	;-- Nesting ----------------------------------------------------------
	--test-- "nested: inner true, outer false"
		--assert overflow? [n: 2147483647 + 1]      ;-- inner-only baseline
		--assert not overflow? [
			lf?: overflow? [n: 2147483647 + 1]        ;-- inner overflows
			false                                    ;-- outer body has no math op
		]

	--test-- "nested: outer overflow independent of inner"
		x: 2147483647
		--assert overflow? [
			lf?: overflow? [n: 1 + 1]                 ;-- inner safe
			n: x + 1                                ;-- outer math op overflows
		]

	;-- Lexical scope: callee overflows don't count ----------------------
	--test-- "callee overflow not visible to caller"
		--assert not overflow? [n: overflows-internally]

~~~end-file~~~
