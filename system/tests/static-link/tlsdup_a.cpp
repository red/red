/* tlsdup_a.cpp -- see tlsdup.hpp; build (VS2022 x86 tools):
**     cl /nologo /c /MT /O1 /GS- /EHsc /std:c++17 tlsdup_a.cpp tlsdup_b.cpp
*/
#include "tlsdup.hpp"

extern "C" int bump_a(void) { return ++t_slot; }
