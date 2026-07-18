/* tryeh_test.cpp -- Mach-O __eh_frame fixture for the -s static linker.
**
** Build (on the 10.9 VM, clang 3.3):
**     clang++ -arch i386 -c -O1 tryeh_test.cpp -o tryeh_test.o
**
** Carries the full i386 Darwin EH surface: __TEXT,__eh_frame (CIE+FDEs,
** the payload the emitter must actually write), __TEXT,__gcc_except_tab
** (LSDA), a __mod_init_func constructor (walked by the entry stub on a
** 16-byte-aligned stack), and dylib references to libc++abi's
** personality/throw machinery. libunwind locates __eh_frame by NAME in
** the loaded image -- zeros there kill the catch.
*/

static int trace = 0;

struct Boot { Boot() { trace = 7; } };
static Boot boot;                           /* static ctor: sets trace pre-main */

static int inner(int v) {
    if (v > 2) throw v * 5;
    return v;
}

extern "C" int try_eh(int v) {
    try {
        return inner(v) + 1000;
    } catch (int e) {
        return e + trace;                   /* v=3: 15 + 7 = 22 */
    }
}
