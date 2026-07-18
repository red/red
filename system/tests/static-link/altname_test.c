/* Fixture for test-alternatename.reds:
     cl /nologo /c /O2 altname_test.c
   The embedded directive maps the never-defined _alt_entry onto
   _real_entry -- MSVC's /alternatename mechanism, which the CRT relies
   on for its overridable entry points. */

#pragma comment(linker, "/alternatename:_alt_entry=_real_entry")

int real_entry(int x) { return x + 20; }
