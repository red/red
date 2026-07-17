/* fptreloc_test.c -- cafter-section relocation fixture for the -s static
** linker.
**
** Build (VS2022 x86 tools, from a vcvarsall amd64_x86 prompt):
**     cl /nologo /c /MT /O1 /GS- fptreloc_test.c
**
** A .fptable* section routes to the page-isolated cafter bucket; this one
** carries a DIR32 relocation (a statically initialized function pointer).
** The relocation must be applied to the cafter buffer at the cafter base
** -- applied against .data instead, the slot here stays zero (the call
** faults) and an unrelated .data cell gets stomped.
*/

static int forty_two(void) { return 42; }

#pragma section(".fptable$r", read, write)
__declspec(allocate(".fptable$r")) int (*fpt_probe)(void) = forty_two;

int call_probe(void) { return fpt_probe(); }
