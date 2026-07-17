/* commons_a.c -- Mach-O common (tentative definition) fixture, twin A.
**
** Build (on the 10.9 VM, clang 3.3):
**     clang -arch i386 -fcommon -c -O1 commons_a.c commons_b.c
**
** Declares the SMALL shared_buf twin (commons_b.c holds the 16-int one:
** largest size must win regardless of object order), an 8-byte-aligned
** double common, and tail_guard -- allocated right after them, so an
** under-allocated shared_buf lets fill_buf() stomp it.
*/

int    shared_buf[4];
double dcommon;
long   tail_guard;

int sum_buf(void) {
    int s = 0, i = 0;
    for (; i < 16; i++) s += shared_buf[i];
    return s;
}

long guard_value(void)  { return tail_guard; }
long dcommon_align(void) { return (long)&dcommon & 7; }
