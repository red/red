/* groupdup.hpp -- shared inline with EH, instantiated by groupdup_a.cpp
** and groupdup_b.cpp. Each TU emits the SAME multi-member COMDAT group:
** .text._Z7guardedi + .group + its LSDA in .gcc_except_table._Z7guardedi.
** The duplicate group is discarded at link time, but the duplicate's
** .eh_frame (outside the group) still carries an FDE whose pc-begin and
** LSDA pointer relocate against the DROPPED members -- the linker must
** redirect each into the kept group's member of the same name, NOT into
** the primary (text) member at a foreign offset.
*/

inline int guarded(int v) {
    try {
        if (v > 0) throw v * 3;
        return -1;
    } catch (int e) {
        return e + 4;
    }
}
