/* groupdup_a.cpp -- see groupdup.hpp; build (WSL g++ 13, 32-bit):
**     g++ -m32 -c -O1 -fno-inline -fexceptions groupdup_a.cpp groupdup_b.cpp
**     ar rcs libgroupdup.a groupdup_a.o groupdup_b.o
*/
#include "groupdup.hpp"

extern "C" int call_a(int v) { return guarded(v); }
