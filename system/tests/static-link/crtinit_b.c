/* Fixture for test-crt-init.reds -- see crtinit_a.c. This member is
   pulled through its imported b_ping; its initializer must land between
   crtinit_a's XCM1 and crtinit_c's XCM3. */

typedef void (__cdecl *initfn)(void);

extern int g_order[4];
extern int g_count;

static void __cdecl init_b(void) { g_order[g_count++] = 2; }

#pragma section(".CRT$XCM2", read)
__declspec(allocate(".CRT$XCM2")) initfn my_b = init_b;

int b_ping(void) { return 7; }
