/* comdatinit.hpp -- shared C++17 inline variable with a dynamically
** counted initializer, instantiated by comdatinit_a.cpp and
** comdatinit_b.cpp. Each TU emits the SAME COMDAT set: the variable's
** slot, the ??__E initializer text, and a .CRT$XCU entry that is
** SELECT_ASSOCIATIVE to the variable. Associative children carry NO key
** (the reader clears it): they must follow their PARENT's fate at
** duplicate folding, or every duplicate's XCU entry survives and the
** kept initializer runs once per TU. bump() allocates so the fixture
** trips a CRT marker -- the libcmt merge is what walks XCA..XCZ.
*/
#pragma once

extern "C" int g_inits;
int bump(void);

inline int shared_init = bump();
