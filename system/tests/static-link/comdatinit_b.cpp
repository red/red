/* comdatinit_b.cpp -- the duplicate-COMDAT twin of comdatinit_a.cpp's
** inline variable (and of its associative .CRT$XCU initializer entry).
*/
#include "comdatinit.hpp"

extern "C" int side_value_b(void) { return shared_init; }

extern "C" int init_count(void) { return g_inits; }
