# Linux x86-64 Backend For Red/System

## Summary

Add a first x86-64 backend for Red/System targeting Linux SysV AMD64. This includes `Linux-X86-64` target configs, a new `X86-64.r` backend, ELF64 PIE/PIC/shared-library output support, pointer-size-aware compiler/runtime fixes, and unit coverage for 64-bit pointers, ABI calls, structs, unions, and fixed-width integers.

PIE executable and PIC shared-library support are first-milestone requirements, not a later optimization. The default Linux x86-64 executable output should be PIE (`ET_DYN`), and shared-library output should use the same PIC-safe code generation rules. Non-PIE `ET_EXEC` output may exist only as an explicit debug/smoke target.

## Key Changes

- Add target config:
  - `Linux-X86-64` with `target: 'X86-64`, `format: 'ELF`, `type: 'exe`, `ABI: 'sysv`, `PIE?: yes`, `PIC?: yes`, `ptr-size: 8`, 16-byte stack alignment, PIE `ET_DYN` output, and dynamic linker `/lib64/ld-linux-x86-64.so.2`.
  - `Linux-X86-64-SO` with `target: 'X86-64`, `format: 'ELF`, `type: 'dll`, `ABI: 'sysv`, `PIC?: yes`, and shared-object `ET_DYN` output.
  - Optionally add `Linux-X86-64-NoPIE` for non-PIE `ET_EXEC` smoke/debug output, but do not let that path weaken PIE/PIC requirements.
  - Keep `integer!` as 32-bit; use 64-bit only for pointers, `int64!`, `uint64!`, and address arithmetic.

- Add `system/targets/X86-64.r`:
  - Implement x86-64 instruction emission with REX prefixes, `rax/rcx/rdx/rbx/rsp/rbp/rsi/rdi/r8-r15`, RIP-relative internal symbol access, PLT calls for imported/preemptible functions, GOT loads for externally preemptible data, rel32 calls/jumps where legal, and 8-byte pointer loads/stores.
  - Implement SysV AMD64 function ABI: integer/pointer args in `rdi/rsi/rdx/rcx/r8/r9`, float args in `xmm0-xmm7`, stack overflow args, 16-byte call alignment, scalar returns in `rax`/`xmm0`, and correct variadic call metadata.
  - Support Red/System core operations first: locals/globals, path load/store, pointer arithmetic, struct/union field access, fixed-width integers, floats, comparisons, bit ops, function calls, imports, callbacks, stack helpers, and `system/cpu/overflow?`.

- Enforce PIC-safe x86-64 code generation:
  - Internal code/data references use RIP-relative addressing or rel32 branches/calls where the relocation is valid in PIE/shared-library output.
  - Imported or externally preemptible functions are called through PLT entries.
  - Imported or externally preemptible data is loaded through GOT entries.
  - Address materialization for internal symbols uses `lea reg, [rip + symbol]`; do not emit `movabs reg, symbol` in executable text for normal symbol references.
  - Absolute immediates in text are allowed only for true numeric constants, never for relocatable symbol addresses in PIE/PIC output.
  - Any temporary non-PIC helper path must be guarded by an explicit non-PIE target flag.

- Make compiler data model target-sized:
  - Patch emitter type sizes so `pointer!`, `c-string!`, `function!`, `subroutine!`, struct refs, union refs, and arrays use `target/ptr-size`.
  - Add target-aware struct/union alignment: 1/2/4-byte scalar fields, 8-byte pointer/int64/float64 fields on x86-64, and final aggregate padding to max field alignment.
  - Preserve existing IA-32 and ARM behavior.

- Add ELF64 support:
  - Add `Elf64_*` headers, program headers, section headers, symbol entries, dynamic entries, and relocation entries.
  - Add x86-64 constants: `EM_X86_64`, `ELFCLASS64`, `R_X86_64_64`, `R_X86_64_PC32`, `R_X86_64_PLT32`, `R_X86_64_GOTPCREL`, `R_X86_64_GLOB_DAT`, `R_X86_64_JUMP_SLOT`, and `R_X86_64_RELATIVE`.
  - Generate `ET_DYN` for PIE executables and shared libraries, use RELA relocations for dynamic relocation sections, and emit dynamic tags for GOT/PLT, relocation tables, needed libraries, init/fini entries, soname where applicable, and `FLAGS_1 PIE` for PIE executables when supported by the current emitter.
  - Ensure generated PIE/PIC code has no absolute relocations in executable text sections.
  - Emit `.got`, `.got.plt`, `.plt`, `.dynamic`, `.dynsym`, `.dynstr`, `.rela.dyn`, `.rela.plt`, `.gnu.hash` or compatible hash sections as required by the dynamic loader.
  - Separate loadable segment permissions so executable code is not writable and writable data is not executable.
  - Keep ELF32 paths unchanged for IA-32 and ARM.

- Add linker/symbol model support for PIC:
  - Track symbol binding and preemptibility so internal symbols use RIP-relative rel32 addressing, imported functions use PLT, imported data uses GOT, and dynamic relocations are emitted only where legal.
  - Support local relative relocations for image data containing pointers, using `R_X86_64_RELATIVE` in PIE/shared-library output.
  - Support exported symbols from shared libraries with correct dynamic-symbol table entries and version-neutral default visibility.
  - Keep copy relocations unsupported for compiler-generated shared libraries; require GOT access for imported data.
  - Fail compilation with a clear internal error if a requested relocation cannot be represented safely in PIE/PIC output.
  - Keep existing non-PIC IA-32/ARM relocation behavior unchanged.

- Update Red/System runtime pieces:
  - Add x86-64 `system/cpu` register view and `system/stack` support.
  - Update Linux startup for AMD64 stack layout, PIE-safe image base discovery when needed, and `__libc_start_main`.
  - Add Linux x86-64 syscall convention if `#syscall` is used.
  - Audit only `system/runtime/*` needed by Red/System first; full Red runtime cell-layout migration is out of scope for this first backend pass.

## PIE/PIC Acceptance Criteria

- `Linux-X86-64` default executable output is a loadable PIE:
  - `readelf -h` reports `Type: DYN`.
  - The binary runs under WSL with ASLR enabled across repeated launches.
  - `readelf -d` has no `TEXTREL`.
  - `readelf -r` has no absolute relocations against executable text.

- `Linux-X86-64-SO` shared-library output is loadable by the system dynamic loader:
  - It exports Red/System functions intended for import.
  - A separate x86-64 Red/System executable can import and call one of those functions.
  - `readelf -d -r` shows only valid dynamic relocations for PIC output.

- Generated instruction forms are PIC-safe:
  - Internal global reads/writes use RIP-relative memory operands.
  - Internal global addresses use RIP-relative `lea`.
  - Imported calls go through PLT.
  - Imported data goes through GOT.
  - Pointer constants stored in writable image data use dynamic RELA relocations, not text relocations.

## Implementation Order

1. Keep the current no-runtime x86-64 smoke path working while adding missing instruction forms.
2. Make internal globals, functions, and static data consistently RIP-relative.
3. Add ELF64 dynamic sections, RELA relocation emission, GOT, and PLT.
4. Switch `Linux-X86-64` executable output to PIE `ET_DYN` by default.
5. Add `Linux-X86-64-SO` shared-library output and exported/imported symbol handling.
6. Bring up runtime startup and libc imports on top of the PIE/PIC relocation model.
7. Expand full Red/System unit coverage once the dynamic loader path is stable.

## Test Plan

- Add or adjust unit tests for `Linux-X86-64`:
  - `size-test.reds`: `size? pointer! = 8`, pointer fields/layout, function pointer size.
  - `pointer-test.reds`, `get-pointer-test.reds`: 64-bit pointer load/store, arithmetic, pointer returns.
  - `struct-test.reds`, `union-test.reds`, `fixed-int-test.reds`: x86-64 layout, nested aggregates, by-value/by-ref structs/unions, `int64!/uint64!`.
  - `function-test.reds`, `cast-test.reds`, `float-test.reds`, `float32-test.reds`, `system-test.reds`: SysV register args, stack overflow args, float args/returns, callbacks/imports, overflow flag capture.

- Build any needed x86-64 test support libraries from existing C fixtures under WSL.

- Verify with:
  - `red.r -cqs -t Linux-X86-64 ...` for focused Red/System unit tests.
  - Run PIE binaries directly in WSL with ASLR enabled.
  - Confirm generated executables are PIE `ET_DYN` using `readelf -h`, and confirm no `TEXTREL` dynamic tag and no absolute text relocations using `readelf -d -r`.
  - Build and run at least one x86-64 shared library via `-dlib`/`Linux-X86-64-SO`, then compile a small Red/System executable that imports and calls it.
  - Verify imported libc calls go through PLT, imported data uses GOT, and pointer-containing global data uses valid dynamic RELA relocations.
  - Disassemble focused samples with `objdump -drwC` and check that symbol addresses in text are RIP-relative, PLT-relative, or GOT-relative.
  - Regression compile/run on IA-32 for `size-test.reds`, `struct-test.reds`, `union-test.reds`, `fixed-int-test.reds`, `int64-test.reds`.
  - Linux-ARM/RPi smoke for fixed-int, struct, union after shared emitter/layout changes.

## Assumptions

- First milestone is Linux SysV x86-64, not Windows x64/PE32+.
- First milestone includes PIE executable output, PIC code generation, and shared-library output.
- PIE/PIC support should be designed as the normal x86-64 path; a non-PIE path is optional and must not become the main implementation shortcut.
- Public `integer!` remains 32-bit and compatible with existing Red/System semantics.
- Red/System runtime support is required; full Red language runtime 64-bit cell/node migration is deferred unless explicitly requested.
- Existing IA-32 and ARM targets must remain behavior-compatible.
