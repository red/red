#include "red.h"

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
	return 0;
}