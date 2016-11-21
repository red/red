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
	
	redSetGlobalWord(a, (red_value) redBlock(redInteger(42), redString("hello"), 0));
	redDo("?? a foreach v a [probe v]");
	redPrint(redGetGlobalWord(a));

	redProbe(redCall(redWord("what-dir"), 0));
	redCall(redWord("print"), redDo("system/version"), 0);
	redCall(Print, redFloat(99.0), 0);

	int res = redRoutine(redWord("c-add"), "[a [integer!] b [integer!]]", (void*) &add);
	if (res != 0) { printf("Error constructing routine: %d\n", res); }
	redDo("probe c-add 2 3 probe :c-add");

	redProbe((red_value)o_b);
	redDo("o: object [b: {hello}]");
	
	redProbe(redGetPath(o_b));
	redSetPath(o_b, redInteger(123));
	redProbe(redGetPath(o_b));

	redProbe(redPath(redWord("a"), redWord("b"), redInteger(1), 0));

	return 0;
}