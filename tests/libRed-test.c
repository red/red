#include "red.h"
#include <stdio.h>

red_integer add(red_integer a, red_integer b) {
	printf("add called! %d %d\n", redCInt32(a), redCInt32(b));
	return redInteger(redCInt32(a) + redCInt32(b));
}

int main() {
	redBoot();
	int a = redSymbol("a");
	red_word Print = redWord("print");
	red_path o_b = redPathFromString("o/b");
	red_path o_b_2 = redPath(redWord("o"), redWord("b"), redInteger(2), 0);
	
	redSetGlobalWord(a, (red_value) redBlock(redInteger(42), redString("hello"), 0));
	redDo("?? a foreach v a [probe v]");
	redPrint(redGetGlobalWord(a));

	red_value value = redDo("$%$");
	if (redTypeOf(value) == RED_TYPE_ERROR) redProbe(value);

	redProbe(redCall(redWord("what-dir"), 0));
	redCall(redWord("print"), redDo("system/version"), 0);
	redCall(Print, redFloat(99.0), 0);

	value = redRoutine(redWord("c-add"), "[a [integer!] b [integer!]]", (void*) &add);
	if (redTypeOf(value) == RED_TYPE_ERROR) redProbe(value);
	redDo("probe c-add 2 3 probe :c-add");

	redProbe((red_value)o_b);
	redDo("o: object [b: {hello}]");
	
	redProbe(redGetPath(o_b));
	redProbe(o_b_2);
	redProbe(redGetPath(o_b_2));
	
	redSetPath(o_b, redInteger(123));
	redProbe(redGetPath(o_b));

	return 0;
}