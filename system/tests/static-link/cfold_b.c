/* Fixture for test-comdat-fold.reds -- see cfold_a.c for the build line;
   deliberately the same constants, in a second translation unit. */

int fold_b(int x) { return (int)(x * 1.2345678901234567 + 9007.87654321); }
