/* Fixture for test-crt-init.reds -- see crtinit_a.c. NOTHING references
   this member: it links only because crtinit_a carries /include:_c_forced,
   the mechanism locale facets and the dynamic-TLS initializer rely on. */

typedef void (__cdecl *initfn)(void);

extern int g_order[4];
extern int g_count;

int c_forced = 7;

static void __cdecl init_c(void) { g_order[g_count++] = 3; }

#pragma section(".CRT$XCM3", read)
__declspec(allocate(".CRT$XCM3")) initfn my_c = init_c;
