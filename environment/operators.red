Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %operators.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- #load temporary directive is used to workaround REBOL LOAD limitations on some words

#do keep [to-set-word "+"]		make op! :add
#do keep [to-set-word "-"]		make op! :subtract
#do keep [to-set-word "*"]		make op! :multiply
#do keep [to-set-word "/"]		make op! :divide
#do keep [to-set-word "//"]		make op! :modulo
#do keep [to-set-word "%"]		make op! :remainder
#do keep [to-set-word "="]		make op! :equal?
#do keep [to-set-word "<>"]		make op! :not-equal?
#do keep [to-set-word "=="]		make op! :strict-equal?
#do keep [to-set-word "=?"]		make op! :same?
#do keep [to-set-word "<"] 		make op! :lesser?
#do keep [to-set-word ">"] 		make op! :greater?
#do keep [to-set-word "<="]		make op! :lesser-or-equal?
#do keep [to-set-word ">="]		make op! :greater-or-equal?
#do keep [to-set-word "<<"]		make op! :shift-left
#do keep [to-set-word ">>"]		make op! :shift-right
#do keep [to-set-word ">>>"]	make op! :shift-logical
#do keep [to-set-word "**"]		make op! :power
and:							make op! :and~
or:								make op! :or~
xor:							make op! :xor~