/* Fixture for test-crt-init.reds (with crtinit_b.c / crtinit_c.c):
     cl /nologo /c /O2 crtinit_a.c crtinit_b.c crtinit_c.c
     llvm-lib /out:crtinit_bc.lib crtinit_b.obj crtinit_c.obj
   Recreates the CRT's initializer-table pattern with fixture-own bounds:
   .CRT$X?? contributions from every object must be laid out sorted by
   full section name, so the walk from the ...A bound to the ...Z bound
   visits XCM1 (here), XCM2 (crtinit_b) and XCM3 (crtinit_c) in order --
   crtinit_c being pulled by the /include directive below, since nothing
   references it. Null entries (alignment padding, the bounds themselves)
   are skipped, exactly like the CRT's _initterm. */

#pragma comment(linker, "/include:_c_forced")

typedef void (__cdecl *initfn)(void);

int g_order[4];
int g_count = 0;

static void __cdecl init_a(void) { g_order[g_count++] = 1; }

#pragma section(".CRT$XCA", read)
#pragma section(".CRT$XCM1", read)
#pragma section(".CRT$XCZ", read)

__declspec(allocate(".CRT$XCA"))  initfn my_xca = 0;
__declspec(allocate(".CRT$XCM1")) initfn my_a   = init_a;
__declspec(allocate(".CRT$XCZ"))  initfn my_xcz = 0;

int run_inits(void) {
    initfn* p = &my_xca;
    while (p < &my_xcz) {
        if (*p) (*p)();
        p++;
    }
    return g_count;
}

int order_at(int i) { return g_order[i]; }
