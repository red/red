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
	
	redSetGlobalWord(a, (red_value) redBlock(redInteger(42), redString("hello"), 0));
	redDo("?? a foreach v a [probe v]");
	redPrint(redGetGlobalWord(a));

	redProbe(redCall(redWord("what-dir"), 0));
	redCall(redWord("print"), redDo("system/version"), 0);
	redCall(Print, redFloat(99.0), 0);

	int res = redRoutine(redWord("c-add"), "[a [integer!] b [integer!]]", (void*) &add);
	if (res != 0) { printf("Error constructing routine: %d\n", res); }
	redDo("probe c-add 2 3 probe :c-add");

	return 0;
}