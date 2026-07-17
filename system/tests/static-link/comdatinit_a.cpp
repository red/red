/* comdatinit_a.cpp -- see comdatinit.hpp; build (VS2022 x86 tools):
**     cl /nologo /c /MT /O1 /GS- /EHsc /std:c++17 comdatinit_a.cpp comdatinit_b.cpp
*/
#include "comdatinit.hpp"

extern "C" int g_inits = 0;

int bump(void) {
    int* p = new int(1);                /* CRT marker: pulls libcmt's init walk */
    g_inits += *p;
    delete p;
    return g_inits;
}

extern "C" int side_value_a(void) { return shared_init; }
