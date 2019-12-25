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
		m/_31: as float32! 1.0
		m/_32: as float32! 0.0
	]

	mul: func [
		l		[D2D_MATRIX_3X2_F]
		r		[D2D_MATRIX_3X2_F]
		c		[D2D_MATRIX_3X2_F]
	][
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
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		identity t
		t/_31: x
		t/_32: y
		mul m t r
	]

	scale: func [
		m		[D2D_MATRIX_3X2_F]
		x		[float32!]
		y		[float32!]
		r		[D2D_MATRIX_3X2_F]
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		identity t
		t/_11: x
		t/_22: y
		mul m t r
	]

	rotate: func [
		m		[D2D_MATRIX_3X2_F]
		angle	[float32!]
		r		[D2D_MATRIX_3X2_F]
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		identity t
		t/_11: as float32! cos as float! angle
		t/_12: as float32! sin as float! angle
		t/_21: (as float32! 0.0) - t/_12
		t/_22: t/_11
		mul m t r
	]

	skew: func [
		m		[D2D_MATRIX_3X2_F]
		x		[float32!]						;-- x-axis rotate angle
		y		[float32!]						;-- y-axis rotate angle, but with negative direction
		r		[D2D_MATRIX_3X2_F]
		/local
			t	[D2D_MATRIX_3X2_F value]
	][
		identity t
		t/_12: as float32! tan as float! x
		t/_21: as float32! tan as float! y
		mul m t r
	]

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
