/* tls_test.cpp -- PE implicit-TLS fixture for the -s static linker.
**
** Build (VS2022 x86 tools, from a vcvarsall amd64_x86 prompt):
**     cl /nologo /c /MT /O1 /GS- /EHsc /TP tls_test.cpp
**
** Exercises both Windows TLS flavors end to end:
**   - __declspec(thread) with static initialization: the .tls$ template,
**     the IMAGE_TLS_DIRECTORY the linker publishes (tlssup.obj's __tls_used
**     when the CRT is merged, the synthesized one otherwise) and the
**     __tls_index / FS:[2Ch] access path.
**   - C++ thread_local with DYNAMIC initialization: the .CRT$XD* initializer
**     table walked per thread by libcmt's ___dyn_tls_init, registered
**     through the $XL callback range of the TLS directory.
**
** tls_check() returns 127 when every per-thread invariant holds: fresh
** copies with correct initial values in a second thread, and no bleed of
** that thread's writes into the first thread's slots.
*/

#include <windows.h>

static int seed(void) {                     /* opaque: defeats constant folding */
    return GetCurrentThreadId() != 0 ? 25 : 26;
}

__declspec(thread) int t_static = 41;       /* static-init TLS slot  */
thread_local int      t_dyn    = seed() + 75;   /* dynamic-init, = 100 */

static DWORD WINAPI worker(LPVOID out) {
    int ok = (t_static == 41) && (t_dyn == 100);    /* fresh per-thread copies */
    t_static = 7;                                    /* mutate OUR copies only  */
    t_dyn    = 8;
    *(int*)out = ok;
    return 0;
}

extern "C" int tls_check(void) {
    int wok = 0;
    HANDLE h;

    int ok = (t_static == 41) && (t_dyn == 100);    /* this thread's copies */
    t_static = 1000;
    t_dyn    = 2000;

    h = CreateThread(0, 0, worker, &wok, 0, 0);
    if (!h) return -1;
    if (WaitForSingleObject(h, 5000) != WAIT_OBJECT_0) { CloseHandle(h); return -3; }
    CloseHandle(h);

    if (!ok)  return -4;                             /* main-thread init wrong  */
    if (!wok) return -5;                             /* worker-thread init wrong */
    if (t_static != 1000 || t_dyn != 2000) return -6;   /* worker bled through */
    return 127;
}
