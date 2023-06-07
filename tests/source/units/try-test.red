Red [
  Title:   "Red TRY test script"
  Author:  "hiiamboris"
  File:    %try-test.red
  Tabs:    4
  Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
  License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "try"

===start-group=== "try (interpreted)"

	type+id?: func ['type 'id err] [to-logic all [error? :err type = err/type id = err/id]]

	--test-- "tt11" --assert not error? try [0]

	;-- thorough tests of the 'throw' group --

	--test-- "tt21" --assert 1 = catch [try [throw 1] 2]

	; try/all should discard any outer loops here
	--test-- "tt22a" --assert yes = try/all [type+id? throw break do [try [break/return 1]]]
	--test-- "tt22b" --assert yes = try/all [type+id? throw break do [try [break]]]
	--test-- "tt22c" --assert 1 = loop 1 [try [break/return 1] 2]
	--test-- "tt22d" --assert unset? loop 1 [do [try [break] 2]]

	; FIXME: compiled version returns 1 (loop count) instead of unset
	;--test-- "tt22e" --assert unset? loop 1 [try [break] 2]
	
	--test-- "tt23a" --assert type+id? throw return do [try [exit]]
	--test-- "tt23b"
		tt-ret-func1: does [try [return 1]]
		--assert 1 = tt-ret-func1
	--test-- "tt23c"
		tt-ret-func2: does [try [exit]]
		--assert unset? tt-ret-func2
	
	; try/all should discard any outer loops here
	--test-- "tt24a" --assert yes = try/all [type+id? throw continue do [try [continue 1]]]
	--test-- "tt24b" --assert unset? loop 1 [do [try [continue 1] 2]]

	; FIXME: compiled version returns 1 (loop count) instead of unset
	;--test-- "tt24c" --assert unset? loop 1 [try [continue 1] 2]
	
	--test-- "tt25a" --assert type+id? throw while-cond do [try [while [break][]]]
	--test-- "tt25b" --assert type+id? throw while-cond do [loop 1 [try [while [break][]]]]
	--test-- "tt26a" --assert type+id? throw while-cond do [try [while [continue][]]]
	--test-- "tt26b" --assert type+id? throw while-cond do [loop 1 [try [while [continue][]]]]

	;-- minimal tests of other groups --

	--test-- "tt31" --assert type+id? math zero-divide try [1 / 0]
	--test-- "tt41" --assert type+id? access cannot-open try [read %"///^@:<>?*"]
	--test-- "tt51" --assert type+id? user message try [do make error! "error"]
	--test-- "tt61" --assert type+id? script no-arg do [try [try]]
	--test-- "tt71" --assert type+id? syntax missing try [do "["]

===end-group===

===start-group=== "try/all (interpreted)"

	type+id?: func ['type 'id err] [to-logic all [error? :err type = err/type id = err/id]]

	--test-- "tta11" --assert not error? try/all [0]

	;-- thorough tests of the 'throw' group --

	--test-- "tta21" --assert type+id? throw throw try/all [throw 1]

	--test-- "tta22a" --assert type+id? throw break do [try/all [break]]
	--test-- "tta22b" --assert type+id? throw break loop 1 [do [try/all [break]]]
	
	; FIXME: should work + compiler's error message for this is nonsensical:
	; --test-- "tta22c" --assert type+id? throw break loop 1 [try/all [break]]
	; *** Script Error: loop does not allow none! for its count argument

	; FIXME: compiler should not complain about this:
	; --test-- "tta22d" --assert type+id? throw break try/all [break]
	; as `try/all` also must accept `break`
	
	--test-- "tta23a" --assert type+id? throw return do [try/all [exit]]
	--test-- "tta23b"
		tta-ret-func: does [do [try/all [exit]]]
		--assert type+id? throw return tta-ret-func

	; FIXME: should work + compiler's error message for this is nonsensical:
	; --test-- "tta23c"
	;	tta-ret-func: does [try/all [exit]]
	;	--assert type+id? throw return tta-ret-func
	; *** Script Error: body does not allow unset! for its <anon> argument
	
	; FIXME: compiler should not complain about this:
	; --test-- "tta23d" --assert type+id? throw return try/all [exit]
	; as `try/all` also must accept `exit`
	
	--test-- "tta24a" --assert type+id? throw continue do [try/all [continue]]
	--test-- "tta24b" --assert type+id? throw continue loop 1 [do [try/all [continue]]]

	; FIXME: should work + compiler's error message for this is nonsensical:
	; --test-- "tta24c" --assert type+id? throw continue loop 1 [try/all [continue]]
	; *** Script Error: loop does not allow none! for its count argument

	--test-- "tta25a" --assert type+id? throw while-cond do [try/all [while [break][]]]
	--test-- "tta25b" --assert type+id? throw while-cond do [loop 1 [try/all [while [break][]]]]
	--test-- "tta26a" --assert type+id? throw while-cond do [try/all [while [continue][]]]
	--test-- "tta26b" --assert type+id? throw while-cond do [loop 1 [try/all [while [continue][]]]]

	;-- minimal tests of other groups --

	--test-- "tta31" --assert type+id? math zero-divide try/all [1 / 0]
	--test-- "tta41" --assert type+id? access cannot-open try/all [read %"///^@:<>?*"]
	--test-- "tta51" --assert type+id? user message try/all [do make error! "error"]
	--test-- "tta61" --assert type+id? script no-arg do [try/all [try]]
	--test-- "tta71" --assert type+id? syntax missing try/all [do "["]

===end-group===

===start-group=== "attempt"

	--test-- "ttatt-1" --assert none?  attempt [do make error! "abc"]
	--test-- "ttatt-2" --assert error? attempt [make error! "abc"]
		
===end-group===

===start-group=== "try issues"

	--test-- "#4880"
		do [do [do [try/all [1]]]]       ;) depth on which try is invoked is important here
		loop 1 [loop 1 [continue]]
		--assert true
		
		catch [loop 1 [loop 1 [throw 1]]]
		x4880: x4880: loop 1 [
			do [
				foreach x [1 2 3] [
					1 - 2 * 3
					continue
				]
			]
			1
		] 
		--assert true

===end-group===

~~~end-file~~~

