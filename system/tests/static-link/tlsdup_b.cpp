/* tlsdup_b.cpp -- the duplicate-COMDAT twin of tlsdup_a.cpp's t_slot,
** plus a worker probe proving the folded slot stays per-thread.
*/
#include <windows.h>
#include "tlsdup.hpp"

extern "C" int bump_b(void) { return ++t_slot; }

static DWORD WINAPI worker(LPVOID out) {
    *(int*)out = ++t_slot;                       /* fresh copy: 41 + 1 */
    return 0;
}

extern "C" int fresh_copy(void) {
    int v = 0;
    HANDLE h = CreateThread(0, 0, worker, &v, 0, 0);
    if (!h) return -1;
    if (WaitForSingleObject(h, 5000) != WAIT_OBJECT_0) { CloseHandle(h); return -3; }
    CloseHandle(h);
    return v;
}
