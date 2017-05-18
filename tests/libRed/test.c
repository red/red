#include "red.h"
#include <stdio.h>

#ifdef __cplusplus
extern "C" red_integer add(red_integer a, red_integer b) {
#else
red_integer add(red_integer a, red_integer b) {
#endif
	printf("add called! %ld %ld\n", redCInt32(a), redCInt32(b));
	return redInteger(redCInt32(a) + redCInt32(b));
}

int main() {
	red_error err;

	redOpen();
	printf("redOpen done\n");
	int     a = redSymbol("a");
	int o_b_2 = redSymbol("o_b_2");
	int print = redSymbol("print");
	int   o_b = redSymbol("o_b");

	redSet(o_b, redLoadPath("o/b"));
	redDo("?? o_b");
	redSet(o_b_2, redPath(redWord("o"), redWord("b"), redInteger(2), 0));

	redSet(a, (red_value) redBlock(redInteger(42), redString("hello"), 0));
	redDo("?? a foreach v a [probe v]");
	redPrint(redGet(a));

	red_value value = redDo("$%$");
	if (redTypeOf(value) == RED_TYPE_ERROR) redProbe(value);

	redProbe(redCall(redWord("what-dir"), 0));
	redCall(redWord("print"), redDo("system/version"), 0);
	redCall(redGet(print), redFloat(99.0), 0);

	redRoutine(redWord("c-add"), "[a [integer!] b [integer!]]", (void*) &add);
	//if (redTypeOf(value) == RED_TYPE_ERROR) redProbe(value);
	if (err = redHasError())
		redPrint(err);
	else
		redDo("probe c-add 2 3 probe :c-add");

	redDo("o: object [b: {hello}]");
	redDo("?? o_b");
	redProbe(redGet(o_b));

	redProbe(redGet(o_b_2));
	redProbe(redGetPath(redGet(o_b_2)));

	redSetPath(redGet(o_b), redInteger(123));
	redProbe(redGetPath(redGet(o_b)));

	redClose();
	return 0;
}