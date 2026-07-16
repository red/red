/* Fixture for test-rdata-sec.reds:
     cl /nologo /c /O2 rdatasec_test.c
   _RDATA is the MSVC CRT's alternate read-only-data section name (no
   leading dot); the static UCRT places hundreds of tables there. */

#pragma section("_RDATA", read)

__declspec(allocate("_RDATA")) const int rd_magic = 42;

int rd_read(void) { return rd_magic; }
