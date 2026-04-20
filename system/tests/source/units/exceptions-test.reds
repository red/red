Red/System [
	Title:   "Red/System execeptions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exceptions-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "break/continue"

	--test-- "break-1"
		until [break true]
		--assert true
	
	--test-- "break-2"
		i: 5
		until [
			break
			i: i - 1
			i = 0
		]
		--assert i = 5
	  
	--test-- "break-3"
		i: 5
		until [
			i: i - 1
			break
			i = 0
		]
		--assert i = 4
	
	--test-- "break-4"
		i: 5
		until [
		  if i = 3 [break]
		  i: i - 1
		  i = 0
		]
		--assert i = 3
	
	--test-- "continue"
		i: 5
		until [
			i: i - 1
			if i > 2 [continue]
			if i > 2 [--assert false]     ;-- make it fail here
			i = 0
		]
		--assert i = 0
	
	--test-- "nested-1"
		levelA: 0
		levelB: 0
		i: 3
		j: 5
		until [
			levelA: levelA + 1
			i: i - 1
			j: 5
			until [
				levelB: levelB + 1
				j: j - 1
				either j = 4 [continue][break]
				j = 0
			]
			either i = 2 [continue][break]
			i = 0
		]
		--assert levelA = 2
		--assert levelB = 4
	
	--test-- "nested-2"
		levelA: 0
		levelB: 0
		i: 3
		j: 5
		while [i > 0][
			levelA: levelA + 1
			i: i - 1
			j: 5
			until [
				levelB: levelB + 1
				j: j - 1
				either j = 4 [continue][break]
				j = 0
			]
			either i = 2 [continue][break]
		]
		--assert levelA = 2
		--assert levelB = 4
		
	--test-- "nested-3"
		levelA: 0
		levelB: 0
		i: 3
		j: 5
		while [i > 0][
			levelA: levelA + 1
			i: i - 1
			j: 5
			while [j > 0][
				levelB: levelB + 1
				j: j - 1
				either j = 4 [continue][break]
			]
			either i = 2 [continue][break]
		]
		--assert levelA = 2
		--assert levelB = 4

	--test-- "throw-1"
		--assert system/thrown = 0
		catch 1 [throw 1]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-2"
		--assert system/thrown = 0
		catch 123 [
			--assert true
			throw 10
			--assert false
		]
		--assert true
		--assert system/thrown = 10
		system/thrown: 0
		
	--test-- "throw-3"
		foo-trw3: func [][
			--assert system/thrown = 0
			catch 1 [throw 1]
			--assert system/thrown = 1
			
			system/thrown: 0
			catch 1 [throw 2]
			--assert false
		]
		--assert system/thrown = 0
		catch 2 [foo-trw3]
		--assert system/thrown = 2
		system/thrown: 0
	
	--test-- "throw-4"
		--assert system/thrown = 0
		catch 1 [if true [throw 1 --assert false] --assert false]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-5"
		--assert system/thrown = 0
		catch 1 [either true [throw 1 --assert false][--assert false] --assert false]
		--assert system/thrown = 1
		system/thrown: 0
		
	--test-- "throw-6"
		--assert system/thrown = 0
		catch 1 [loop 10 [throw 1 --assert false] --assert false]
		--assert system/thrown = 1
		system/thrown: 0
	
	--test-- "throw-7"
		--assert system/thrown = 0
		catch 1 [until [throw 1 --assert false true] --assert false]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-8"
		--assert system/thrown = 0
		catch 1 [while [throw 1 --assert false true][--assert false] --assert false]
		--assert system/thrown = 1
		system/thrown: 0
		
	--test-- "throw-9"
		--assert system/thrown = 0
		catch 1 [switch 1 [1 [throw 1 --assert false] default [0]] --assert false]
		--assert system/thrown = 1
		system/thrown: 0
		
	--test-- "throw-10"
		--assert system/thrown = 0
		catch 1 [switch 1 [2 [0] default [throw 1 --assert false]] --assert false]
		--assert system/thrown = 1
		system/thrown: 0
		
	--test-- "throw-11"
		--assert system/thrown = 0
		catch 1 [case [false [0] true [throw 1 --assert false] true [--assert false]] --assert false]
		--assert system/thrown = 1
		system/thrown: 0


	loc-fun-throws: func [][
		--test-- "throw-4.1"
			--assert system/thrown = 0
			catch 1 [if true [throw 1 --assert false]]
			--assert system/thrown = 1
			system/thrown: 0

		--test-- "throw-5.1"
			--assert system/thrown = 0
			catch 1 [either true [throw 1 --assert false][--assert false]]
			--assert system/thrown = 1
			system/thrown: 0

		--test-- "throw-6.1"
			--assert system/thrown = 0
			catch 1 [loop 10 [throw 1 --assert false]]
			--assert system/thrown = 1
			system/thrown: 0

		--test-- "throw-7.1"
			--assert system/thrown = 0
			catch 1 [until [throw 1 --assert false true]]
			--assert system/thrown = 1
			system/thrown: 0

		--test-- "throw-8.1"
			--assert system/thrown = 0
			catch 1 [while [throw 1 --assert false true][--assert false]]
			--assert system/thrown = 1
			system/thrown: 0
	]
	loc-fun-throws
	
	--test-- "throw-4.2"
		loc-fun-throws-deep1: func [][if true [throw 1 --assert false]]
		foo-trw-4.2: func [][loc-fun-throws-deep1]
		--assert system/thrown = 0
		catch 1 [foo-trw-4.2]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-5.2"
		loc-fun-throws-deep2: func [][either true [throw 1 --assert false][--assert false]]
		foo-trw-5.2: func [][loc-fun-throws-deep2]
		--assert system/thrown = 0
		catch 1 [foo-trw-5.2]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-6.2"
		loc-fun-throws-deep3: func [][loop 10 [throw 1 --assert false]]
		foo-trw-6.2: func [][loc-fun-throws-deep3]
		--assert system/thrown = 0
		catch 1 [foo-trw-6.2]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-7.2"
		loc-fun-throws-deep4: func [][until [throw 1 --assert false true]]
		foo-trw-7.2: func [][loc-fun-throws-deep4]
		--assert system/thrown = 0
		catch 1 [foo-trw-7.2]
		--assert system/thrown = 1
		system/thrown: 0

	--test-- "throw-8.2"
		loc-fun-throws-deep5: func [][while [throw 1 --assert false true][--assert false]]
		foo-trw-8.2: func [][loc-fun-throws-deep5]
		--assert system/thrown = 0
		catch 1 [foo-trw-8.2]
		--assert system/thrown = 1
		system/thrown: 0
		
	
	--test-- "throw-20"
		--assert system/thrown = 0
		catch 100 [
			until [
				while [1 < 2][
					loop 5 [
						either false [0][
							if 1 < 2 [
								case [
									1 > 3 [0]
									2 < 4 [
										switch 2 [
											1 [0]
											2 [throw 7]
											default [0]
										]
									]
								]
							]
						]
					]
				]
				true
			]
		]
		--assert system/thrown = 7
		system/thrown: 0

	--test-- "throw-21"
		--assert system/thrown = 0
		loc-fun-deep-nested21: func [][
			until [
				while [1 < 2][
					loop 5 [
						either false [0][
							if 1 < 2 [
								case [
									1 > 3 [0]
									2 < 4 [
										switch 2 [
											1 [0]
											2 [throw 8]
											default [0]
										]
									]
								]
							]
						]
					]
				]
				true
			]
		]
		catch 100 [loc-fun-deep-nested21]
		--assert system/thrown = 8
		system/thrown: 0

comment {
;; Non-passing test yet, needs small patch in IA-32, but more serious work in ARM backend.

	--test-- "throw-22"
		--assert system/thrown = 0
		loc-fun-deep-nested22: func [][
			until [
				while [1 < 2][
					loop 5 [
						catch 20 [
							either false [0][
								if 1 < 2 [
									case [
										1 > 3 [0]
										2 < 4 [
											catch 10 [
												switch 2 [
													1 [0]
													2 [throw 9]
													default [0]
												]
											]
											probe ["9, " system/thrown]
											--assert system/thrown = 9
											throw 3
										]
									]
								]
							]
						]
						probe ["3, " system/thrown]
						--assert system/thrown = 3
						throw 11
					]
				]
				true
			]
		]
		catch 100 [loc-fun-deep-nested22]
		probe ["11, " system/thrown]
		--assert system/thrown = 11
		system/thrown: 0
}
	--test-- "throw-23"
		fun-nest-3: func [][
			catch 5 [
				catch 4 [
					catch 2 [throw 1]
					--assert system/thrown = 1
					system/thrown: 0
					throw 6
				]
			]
		]
		fun-nest-2: func [][catch 10 [fun-nest-3]]
		fun-nest-1: func [][catch 20 [fun-nest-2]]
		fun-nest-1
		--assert system/thrown = 6


~~~end-file~~~

