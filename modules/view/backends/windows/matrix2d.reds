Red/System [
	Title:	"matrix for direct2d"
	Author: "bitbegin"
	File: 	%matrix2d.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- matrix layout:
;-- _11 _12 0.0
;-- _21 _22 0.0
;-- _31 _32 1.0

;-- vector:
;-- i = [_11 _12 0.0]T
;-- j = [_21 _22 0.0]T
;-- j = [_31 _32 1.0]T

;-- base fomula:
;-- p1 = p * M

;-- compose transform
;-- 1. translate M1
;-- 2. rotate M2
;-- 3. translate M3
;-- result:
;-- M = M1 * M2 * M3

matrix2d: context [
	identity: func [
		m		[D2D_MATRIX_3X2_F]
	][
		m/_11: as float32! 1.0
		m/_12: as float32! 0.0
		m/_21: as float32! 0.0
		m/_22: as float32! 1.0
		m/_31: as float32! 0.0
		m/_32: as float32! 0.0
	]

	;-- Mc = Ml * Mr for pre? = false
	;-- Mc = Mr * Ml for pre? = true
	;-- this lib use row-major order, so the default flag pre? = false
	mul: func [
		_l		[D2D_MATRIX_3X2_F]
		_r		[D2D_MATRIX_3X2_F]
		c		[D2D_MATRIX_3X2_F]
		pre?	[logic!]
		/local
			l	[D2D_MATRIX_3X2_F]
			r	[D2D_MATRIX_3X2_F]
	][
		either pre? [
			l: _r r: _l
		][
			l: _l r: _r
		]
		c/_11: l/_11 * r/_11 + (l/_12 * r/_21)
		c/_12: l/_11 * r/_12 + (l/_12 * r/_22)
		c/_21: l/_21 * r/_11 + (l/_22 * r/_21)
		c/_22: l/_21 * r/_12 + (l/_22 * r/_22)
		c/_31: l/_31 * r/_11 + (l/_32 * r/_21) + r/_31
		c/_32: l/_31 * r/_12 + (l/_32 * r/_22) + r/_32
	]

	translate: func [
		m		[D2D_MATRIX_3X2_F]
		x		[float32!]
		y		[float32!]
		r		[D2D_MATRIX_3X2_F]
		pre?	[logic!]
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		identity t
		t/_31: x
		t/_32: y
		mul m t r pre?
	]

	scale: func [
		m		[D2D_MATRIX_3X2_F]
		x		[float32!]
		y		[float32!]
		cx		[float32!]
		cy		[float32!]
		r		[D2D_MATRIX_3X2_F]
		pre?	[logic!]
		/local
			t	[D2D_MATRIX_3X2_F value]
			t2	[D2D_MATRIX_3X2_F value]
	][
		identity t
		t/_11: x
		t/_22: y
		if any [cx <> F32_0 cy <> F32_0][translate m cx cy t2 pre? m: t2]
		mul m t r pre?
		if any [cx <> F32_0 cy <> F32_0][translate r cx cy r pre?]
	]

	rotate: func [
		m		[D2D_MATRIX_3X2_F]
		angle	[float32!]	;-- The clockwise rotation angle, in degrees
		cx		[float32!]	;-- center x
		cy		[float32!]	;-- center y
		r		[D2D_MATRIX_3X2_F]
		pre?	[logic!]
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		D2D1MakeRotateMatrix angle cx cy :t
		mul m t r pre?
	]

	skew: func [
		m		[D2D_MATRIX_3X2_F]
		x		[float32!]	;-- measured in degrees counterclockwise from the y-axis.
		y		[float32!]	;-- measured in degrees counterclockwise from the x-axis.
		cx		[float32!]	;-- center x
		cy		[float32!]	;-- center y
		r		[D2D_MATRIX_3X2_F]
		pre?	[logic!]
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		D2D1MakeSkewMatrix x y cx cy :t
		mul m t r pre?
	]


	;-- Assuming row vectors, this is equivalent to `p * M`
	transform-point: func [
		m		[D2D_MATRIX_3X2_F]
		x		[float32!]
		y		[float32!]
		px		[float32-ptr!]
		py		[float32-ptr!]
	][
		px/value: (x * m/_11) + (y * m/_21) + m/_31
		py/value: (x * m/_12) + (y * m/_22) + m/_32
	]

	invert: func [
		m		[D2D_MATRIX_3X2_F]
		r		[D2D_MATRIX_3X2_F]
		return:	[logic!]
	][
		copy-memory as byte-ptr! r as byte-ptr! m size? D2D_MATRIX_3X2_F
		D2D1InvertMatrix r
	]
]

MATRIX_4x4_F!: alias struct! [
	_11		[float32!]
	_12		[float32!]
	_13		[float32!]
	_14		[float32!]
	_21		[float32!]
	_22		[float32!]
	_23		[float32!]
	_24		[float32!]
	_31		[float32!]
	_32		[float32!]
	_33		[float32!]
	_34		[float32!]
	_41		[float32!]
	_42		[float32!]
	_43		[float32!]
	_44		[float32!]
]

matrix4x4: context [
	identity: func [
		m		[MATRIX_4x4_F!]
	][
		m/_11: as float32! 1.0
		m/_12: as float32! 0.0
		m/_13: as float32! 0.0
		m/_14: as float32! 0.0
		m/_21: as float32! 0.0
		m/_22: as float32! 1.0
		m/_23: as float32! 0.0
		m/_24: as float32! 0.0
		m/_31: as float32! 0.0
		m/_32: as float32! 0.0
		m/_33: as float32! 1.0
		m/_34: as float32! 0.0
		m/_41: as float32! 0.0
		m/_42: as float32! 0.0
		m/_43: as float32! 0.0
		m/_44: as float32! 1.0
	]

	mul: func [
		l		[MATRIX_4x4_F!]
		r		[MATRIX_4x4_F!]
		c		[MATRIX_4x4_F!]
	][
		c/_11: l/_11 * r/_11 + (l/_12 * r/_21) + (l/_13 * r/_31) + (l/_14 * r/_41)
		c/_12: l/_11 * r/_12 + (l/_12 * r/_22) + (l/_13 * r/_32) + (l/_14 * r/_42)
		c/_13: l/_11 * r/_13 + (l/_12 * r/_23) + (l/_13 * r/_33) + (l/_14 * r/_43)
		c/_14: l/_11 * r/_14 + (l/_12 * r/_24) + (l/_13 * r/_34) + (l/_14 * r/_44)

		c/_21: l/_21 * r/_11 + (l/_22 * r/_21) + (l/_23 * r/_31) + (l/_24 * r/_41)
		c/_22: l/_21 * r/_12 + (l/_22 * r/_22) + (l/_23 * r/_32) + (l/_24 * r/_42)
		c/_23: l/_21 * r/_13 + (l/_22 * r/_23) + (l/_23 * r/_33) + (l/_24 * r/_43)
		c/_24: l/_21 * r/_14 + (l/_22 * r/_24) + (l/_23 * r/_34) + (l/_24 * r/_44)

		c/_31: l/_31 * r/_11 + (l/_32 * r/_21) + (l/_33 * r/_31) + (l/_34 * r/_41)
		c/_32: l/_31 * r/_12 + (l/_32 * r/_22) + (l/_33 * r/_32) + (l/_34 * r/_42)
		c/_33: l/_31 * r/_13 + (l/_32 * r/_23) + (l/_33 * r/_33) + (l/_34 * r/_43)
		c/_34: l/_31 * r/_14 + (l/_32 * r/_24) + (l/_33 * r/_34) + (l/_34 * r/_44)

		c/_41: l/_41 * r/_11 + (l/_42 * r/_21) + (l/_43 * r/_31) + (l/_44 * r/_41)
		c/_42: l/_41 * r/_12 + (l/_42 * r/_22) + (l/_43 * r/_32) + (l/_44 * r/_42)
		c/_43: l/_41 * r/_13 + (l/_42 * r/_23) + (l/_43 * r/_33) + (l/_44 * r/_43)
		c/_44: l/_41 * r/_14 + (l/_42 * r/_24) + (l/_43 * r/_34) + (l/_44 * r/_44)
	]
]
