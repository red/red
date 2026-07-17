/* Fixture for test-section-split.reds:
     cl /nologo /c /O2 sectsplit_test.c
   A written global and a const array that (in the object) sit in the same
   .data / .rdata classes. After the link the const must land in a read-only
   PE section and the writable global in a writable one -- never sharing a
   page, so the MSVC CRT's read-only-after-init hardening can't catch the
   writable global. */

const int ss_table[64] = {                 /* .rdata -> crodata (read-only) */
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
    17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,
    33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,
    49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64
};

int ss_counter = 7;                        /* .data -> data (writable) */

int ss_read(int i)  { return ss_table[i & 63]; }
int ss_bump(void)   { return ++ss_counter; }
