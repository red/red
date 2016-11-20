#include "red.h"

int main() {
	redBoot();
	int a = redWord("a");
	redSetGlobalWord(a, (red_value) redBlock(redInteger(42), redString("hello"), 0));
	redDo("?? a foreach v a [probe a]");
	redPrint(redGetGlobalWord(a));
	return 0;
}