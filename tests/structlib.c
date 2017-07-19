/*
	Shared library for testing
*/

#ifdef _MSC_VER
	#define EXPORT __declspec(dllexport)
#else
	#define EXPORT extern
#endif

typedef struct tiny {
	char b1;
} tiny;

typedef struct small {
	long one;
	long two;
} small;

typedef struct big {
	long one;
	long two;
	double three;
} big;

typedef struct huge {
	long one;
	long two;
	double three;
	long four;
	long five;
	double six;
} huge;

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
	huge t = { 111,222,3.5,444,555,6.789};
	t.one = a;
	t.two = b;
	return t;
}

EXPORT huge returnHuge2(huge h, int a, int b) {
	huge t = { 111,222,3.5,444,555,6.789};
	t.one = a;
	t.two = b;
	t.six = h.six;
	return t;
}