/*
	Shared library for testing
*/

#include <stdint.h>

#ifdef _MSC_VER
	#define EXPORT __declspec(dllexport)
#else
	#define EXPORT extern
#endif

typedef struct tiny {
	char b1;
} tiny;

typedef struct small {
	int32_t one;
	int32_t two;
} small;

typedef struct big {
	int32_t one;
	int32_t two;
	double three;
} big;

typedef struct huge {
	int32_t one;
	int32_t two;
	double three;
	int32_t four;
	int32_t five;
	double six;
} huge;

typedef struct huge3 {
	int32_t one;
	int32_t two;
	int32_t three;
	int32_t four;
	int32_t five;
	int32_t six;
} huge3;

typedef struct bigf32 {
	int32_t one;
	int32_t two;
	float three;
} bigf32;

typedef struct hugef32 {
	float one;
	int32_t two;
	float three;
	int32_t four;
	int32_t five;
	float six;
} hugef32;

typedef struct triple8 {
	uint8_t one;
	uint8_t two;
	uint8_t three;
} triple8;

typedef struct paird {
	double one;
	double two;
} paird;

typedef struct quadf32 {
	float one;
	float two;
	float three;
	float four;
} quadf32;



EXPORT tiny returnTiny(void) {
	tiny t = { 'z' };
	return t;
}

EXPORT small returnSmall(void) {
	small t = { 111,222 };
	return t;
}

EXPORT big returnBig(void) {
	big t = { 111,222,3.14159 };
	return t;
}

EXPORT huge returnHuge(int a, int b) {
	huge t = { 111,222,3.5,444,555,6.789 };
	t.one = a;
	t.two = b;
	return t;
}

EXPORT huge returnHuge2(huge h, int a, int b) {
	huge t = { 111,222,3.5,444,555,6.789 };
	h.four = 0xBAD0CAFE;	/* try to corrupt h buffer to test for unwanted side-effects */
	t.one = a;
	t.two = b;
	t.six = h.six;
	return t;
}

EXPORT huge3 returnHuge3(huge3 h, int a, int b) {
	huge3 t = { 111,222,3,444,555,789 };
	h.four = 0xBAD0CAFE;	/* try to corrupt h buffer to test for unwanted side-effects */
	t.one = a;
	t.two = b;
	t.six = h.six;
	return t;
}

EXPORT hugef32 returnHugef32(hugef32 h, int a, int b) {
	hugef32 t = { 1.11f,222,3.5f,444,555,6.789f };
	h.four = 0xBAD0CAFE;	/* try to corrupt h buffer to test for unwanted side-effects */
	t.one = 1.23f;
	t.two = b;
	t.six = h.six;
	return t;
}

EXPORT triple8 returnTriple8(void) {
	triple8 t = { 11, 22, 33 };
	return t;
}

EXPORT triple8 returnTriple8Std(void) {
	triple8 t = { 44, 55, 66 };
	return t;
}

EXPORT paird returnPairD(void) {
	paird p = { 12.5, 29.5 };
	return p;
}

EXPORT quadf32 returnQuadF32(void) {
	quadf32 q = { 1.25f, 2.5f, 3.75f, 4.5f };
	return q;
}

EXPORT int checkTriple8(triple8 t, int bias) {
	return t.one + t.two + t.three + bias;
}

EXPORT int checkTriple8Std(triple8 t, int bias) {
	return t.one + t.two + t.three + bias;
}

EXPORT int checkBig(big b) {
	return b.one == 123 && b.two == 456 && b.three == 3.14;
}

EXPORT int checkPairD(paird p) {
	return p.one == 12.5 && p.two == 29.5;
}

EXPORT int checkQuadF32(quadf32 q) {
	return q.one == 1.25f && q.two == 2.5f && q.three == 3.75f && q.four == 4.5f;
}

EXPORT int callTriple8Callback(int (*callback)(triple8, int)) {
	triple8 t = { 1, 2, 3 };
	return callback(t, 7);
}

EXPORT int callPairDCallback(int (*callback)(paird, int)) {
	paird p = { 10.5, 20.5 };
	return callback(p, 11);
}

EXPORT int callBigReturnCallback(big (*callback)(int32_t)) {
	big b = callback(5);
	return b.one == 123 && b.two == 456 && b.three == 3.14;
}

EXPORT int checkNineDoubles(
	int marker,
	double d1, double d2, double d3, double d4, double d5,
	double d6, double d7, double d8, double d9
) {
	return marker == 42 &&
		d1 == 1.0 && d2 == 2.0 && d3 == 3.0 && d4 == 4.0 && d5 == 5.0 &&
		d6 == 6.0 && d7 == 7.0 && d8 == 8.0 && d9 == 9.0;
}

EXPORT int checkPairDOverflow(
	double d1, double d2, double d3, double d4, double d5, double d6, double d7,
	paird p, double tail, int marker
) {
	return d1 == 1.0 && d2 == 2.0 && d3 == 3.0 && d4 == 4.0 &&
		d5 == 5.0 && d6 == 6.0 && d7 == 7.0 &&
		p.one == 12.5 && p.two == 29.5 && tail == 8.0 && marker == 42;
}

EXPORT int checkQuadF32Overflow(
	float f1, float f2, float f3, float f4, float f5, float f6, float f7,
	quadf32 q, float tail, int marker
) {
	return f1 == 1.0f && f2 == 2.0f && f3 == 3.0f && f4 == 4.0f &&
		f5 == 5.0f && f6 == 6.0f && f7 == 7.0f &&
		q.one == 1.25f && q.two == 2.5f && q.three == 3.75f && q.four == 4.5f &&
		tail == 8.0f && marker == 42;
}

EXPORT int callQuadF32OverflowCallback(
	int (*callback)(float, float, float, float, float, float, float, quadf32, float, int)
) {
	quadf32 q = { 1.25f, 2.5f, 3.75f, 4.5f };
	return callback(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, q, 8.0f, 42);
}

EXPORT int checkBigOverflow(
	int a1, int a2, int a3, int a4, int a5, int a6, int a7,
	big b, int tail, int marker
) {
	return a1 == 1 && a2 == 2 && a3 == 3 && a4 == 4 &&
		a5 == 5 && a6 == 6 && a7 == 7 &&
		b.one == 123 && b.two == 456 && b.three == 3.14 &&
		tail == 8 && marker == 42;
}

EXPORT int callBigOverflowCallback(
	int (*callback)(int, int, int, int, int, int, int, big, int, int)
) {
	big b = { 123, 456, 3.14 };
	return callback(1, 2, 3, 4, 5, 6, 7, b, 8, 42);
}

EXPORT huge returnHugeBoundary(
	int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8,
	huge h, int tail
) {
	huge result = h;
	result.one = a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8;
	result.two = tail;
	return result;
}

EXPORT int callHugeBoundaryCallback(
	huge (*callback)(int, int, int, int, int, int, int, int, huge, int)
) {
	huge h = { 1, 2, 3.5, 4, 5, 6.5 };
	huge result = callback(1, 2, 3, 4, 5, 6, 7, 8, h, 9);
	return result.one == 36 && result.two == 9 && result.three == 3.5 &&
		result.four == 4 && result.five == 5 && result.six == 6.5;
}

EXPORT int checkMixedExhaustion(
	int i1, double d1, int i2, double d2, int i3, double d3,
	int i4, double d4, int i5, double d5, int i6, double d6,
	int i7, double d7, int i8, double d8, int i9, double d9
) {
	return i1 == 1 && i2 == 2 && i3 == 3 && i4 == 4 && i5 == 5 &&
		i6 == 6 && i7 == 7 && i8 == 8 && i9 == 9 &&
		d1 == 1.5 && d2 == 2.5 && d3 == 3.5 && d4 == 4.5 && d5 == 5.5 &&
		d6 == 6.5 && d7 == 7.5 && d8 == 8.5 && d9 == 9.5;
}

EXPORT int callMixedExhaustionCallback(
	int (*callback)(
		int, double, int, double, int, double, int, double, int, double,
		int, double, int, double, int, double, int, double
	)
) {
	return callback(
		1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5,
		6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5
	);
}

/* Regression test on issue #3999 */

typedef struct {
    float x;
    float y;
    float w;
    float h;
} MyRect;

static int* callback_func;

EXPORT void set_callback(int* ptr) {
    callback_func = ptr;
}

EXPORT float test_callback() {
    MyRect (*p)() = (MyRect (*)())callback_func;
    MyRect rc = p();
    return rc.x;
}

/* variant with doubles */

typedef struct {
    double x;
    double y;
    double w;
    double h;
} MyRectB;

EXPORT double test_callbackB() {
    MyRectB (*p)() = (MyRectB (*)())callback_func;
    MyRectB rc = p();
    return rc.x;
}

/* variant with 5 float fields */

typedef struct {
    float x;
    float y;
    float w;
    float h;
    float g;
} MyRectC;

EXPORT float test_callbackC() {
    MyRectC (*p)() = (MyRectC (*)())callback_func;
    MyRectC rc = p();
    return rc.x;
}

/* variant with 1 float field */

typedef struct {
    float x;
} MyRectD;

EXPORT float test_callbackD() {
    MyRectD (*p)() = (MyRectD (*)())callback_func;
    MyRectD rc = p();
    return rc.x;
}

/* variant with 2 float fields */

typedef struct {
    float x;
    float y;
} MyRectE;

EXPORT float test_callbackE() {
    MyRectE (*p)() = (MyRectE (*)())callback_func;
    MyRectE rc = p();
    return rc.x;
}

/* variant with 1 double field */

typedef struct {
    double x;
} MyRectF;

EXPORT double test_callbackF() {
    MyRectF (*p)() = (MyRectF (*)())callback_func;
    MyRectF rc = p();
    return rc.x;
}

/* variant with 2 double fields */

typedef struct {
    double x;
    double y;
} MyRectG;

EXPORT double test_callbackG() {
    MyRectG (*p)() = (MyRectG (*)())callback_func;
    MyRectG rc = p();
    return rc.x;
}
