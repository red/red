/* Fixture for test-comdat-fold.reds (with cfold_b.c):
     cl /nologo /c /O2 cfold_a.c cfold_b.c
     llvm-lib /out:cfold_test.lib cfold_a.obj cfold_b.obj
   Both objects pool the same double constants as STATIC-keyed COMDAT
   sections (__real@...). Whichever member merges second gets its pool
   folded onto the first's -- its relocations must then redirect into the
   kept twin, at the same in-section offsets. */

int fold_a(int x) { return (int)(x * 1.2345678901234567 + 9007.87654321); }
