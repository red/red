/* tlsdup.hpp -- shared inline thread_local, instantiated by tlsdup_a.cpp
** and tlsdup_b.cpp. Each TU emits the SAME COMDAT .tls$ section for
** t_slot: the linker must fold the duplicate (one template slot), lay the
** kept copy out name-sorted between tlssup.obj's .tls / .tls$ZZZ markers,
** and patch the group's COMDAT anchor AFTER layout -- a pre-layout anchor
** snapshots base-kind 'none, which target-va? mistakes for a code address.
*/
#pragma once

inline thread_local int t_slot = 41;
