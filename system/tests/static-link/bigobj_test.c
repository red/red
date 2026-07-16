/* Fixture for test-bigobj.reds -- compiled with the bigobj object layout:
     cl /nologo /c /bigobj /O2 bigobj_test.c
   /bigobj switches the container format unconditionally (ANON_OBJECT_HEADER
   -- 32-bit section numbers, 20-byte symbol entries), no matter how few
   sections the object actually has. */

int bo_add(int a, int b) { return a + b; }

int bo_scale(int x)      { return x * 7; }
