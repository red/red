/* groupdup_b.cpp -- the duplicate-group twin of groupdup_a.cpp (its whole
** COMDAT group gets discarded; its .eh_frame FDE must survive correctly).
*/
#include "groupdup.hpp"

extern "C" int call_b(int v) { return guarded(v + 1); }
