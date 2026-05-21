# Linux x86-64 Backend For Red/System

## Summary

Add a first x86-64 backend for Red/System targeting Linux SysV AMD64. This includes a new `Linux-X86-64` target config, a new `X86-64.r` backend, ELF64 output support, pointer-size-aware compiler/runtime fixes, and unit coverage for 64-bit pointers, ABI calls, structs, unions, and fixed-width integers.

The first milestone is a non-PIE executable backend. Instruction emission should use RIP-relative addressing where practical so PIE/PIC can be added later without a backend rewrite, but full PIE/shared-library support is explicitly deferred.

## Key Changes

- Add target config:
  - `Linux-X86-64` with `target: 'X86-64`, `format: 'ELF`, `type: 'exe`, `ABI: 'sysv`, `ptr-size: 8`, 16-byte stack alignment, non-PIE `ET_EXEC` output, and dynamic linker `/lib64/ld-linux-x86-64.so.2`.
  - Keep `integer!` as 32-bit; use 64-bit only for pointers, `int64!`, `uint64!`, and address arithmetic.

- Add `system/targets/X86-64.r`:
  - Implement x86-64 instruction emission with REX prefixes, `rax/rcx/rdx/rbx/rsp/rbp/rsi/rdi/r8-r15`, RIP-relative symbol access, rel32 calls/jumps, and 8-byte pointer loads/stores.
  - Implement SysV AMD64 function ABI: integer/pointer args in `rdi/rsi/rdx/rcx/r8/r9`, float args in `xmm0-xmm7`, stack overflow args, 16-byte call alignment, scalar returns in `rax`/`xmm0`, and correct variadic call metadata.
  - Support Red/System core operations first: locals/globals, path load/store, pointer arithmetic, struct/union field access, fixed-width integers, floats, comparisons, bit ops, function calls, imports, callbacks, stack helpers, and `system/cpu/overflow?`.

- Make compiler data model target-sized:
  - Patch emitter type sizes so `pointer!`, `c-string!`, `function!`, `subroutine!`, struct refs, union refs, and arrays use `target/ptr-size`.
  - Add target-aware struct/union alignment: 1/2/4-byte scalar fields, 8-byte pointer/int64/float64 fields on x86-64, and final aggregate padding to max field alignment.
  - Preserve existing IA-32 and ARM behavior.

- Add ELF64 support:
  - Add `Elf64_*` headers, program headers, section headers, symbol entries, dynamic entries, and relocation entries.
  - Add x86-64 constants: `EM_X86_64`, `ELFCLASS64`, `R_X86_64_64`, `R_X86_64_PC32`, `R_X86_64_RELATIVE`, and dynamic relocation handling using RELA where required.
  - For the first milestone, generate non-PIE `ET_EXEC` binaries and reject or defer `PIC?`/DLL output for `X86-64` with a clear compiler error.
  - Keep ELF32 paths unchanged for IA-32 and ARM.

- Leave PIE/PIC for a later milestone:
  - Add future targets such as `Linux-X86-64-PIE` for `ET_DYN` PIE executables and `Linux-X86-64-SO` for shared libraries.
  - Future PIE/PIC work must add GOT/PLT import handling, `R_X86_64_GLOB_DAT`, `R_X86_64_JUMP_SLOT`, `R_X86_64_RELATIVE`, base-address-independent startup, no absolute text relocations, and ASLR verification.

- Update Red/System runtime pieces:
  - Add x86-64 `system/cpu` register view and `system/stack` support.
  - Update Linux startup for AMD64 stack layout and `__libc_start_main`.
  - Add Linux x86-64 syscall convention if `#syscall` is used.
  - Audit only `system/runtime/*` needed by Red/System first; full Red runtime cell-layout migration is out of scope for this first backend pass.

## Test Plan

- Add or adjust unit tests for `Linux-X86-64`:
  - `size-test.reds`: `size? pointer! = 8`, pointer fields/layout, function pointer size.
  - `pointer-test.reds`, `get-pointer-test.reds`: 64-bit pointer load/store, arithmetic, pointer returns.
  - `struct-test.reds`, `union-test.reds`, `fixed-int-test.reds`: x86-64 layout, nested aggregates, by-value/by-ref structs/unions, `int64!/uint64!`.
  - `function-test.reds`, `cast-test.reds`, `float-test.reds`, `float32-test.reds`, `system-test.reds`: SysV register args, stack overflow args, float args/returns, callbacks/imports, overflow flag capture.

- Build any needed x86-64 test support libraries from existing C fixtures under WSL.

- Verify with:
  - `red.r -cqs -t Linux-X86-64 ...` for focused Red/System unit tests.
  - Run binaries directly in WSL.
  - Confirm generated binaries are non-PIE `ET_EXEC` using `readelf -h`, and that `-dlib`/`PIC?` for `Linux-X86-64` fails with the intended diagnostic until PIE/PIC is implemented.
  - Regression compile/run on IA-32 for `size-test.reds`, `struct-test.reds`, `union-test.reds`, `fixed-int-test.reds`, `int64-test.reds`.
  - Linux-ARM/RPi smoke for fixed-int, struct, union after shared emitter/layout changes.

## Assumptions

- First milestone is Linux SysV x86-64, not Windows x64/PE32+.
- First milestone is non-PIE executable output; PIE/PIC/shared-library support is deferred.
- Public `integer!` remains 32-bit and compatible with existing Red/System semantics.
- Red/System runtime support is required; full Red language runtime 64-bit cell/node migration is deferred unless explicitly requested.
- Existing IA-32 and ARM targets must remain behavior-compatible.
