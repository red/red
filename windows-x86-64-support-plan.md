# Windows x86-64 Support Plan

## Objective

Make `red.r -r -t Windows-X86-64 program.red` produce a reliable native
Windows PE32+ console executable, then bring up DLL/development mode and View.
Keep the 16-byte Red cell ABI and 32-bit `node-handle!`; use native-width
pointers for addresses, OS handles, callbacks, allocator state, and GC data.

The first milestone is a console release executable. A valid PE header alone
is insufficient: the program must survive the Windows x64 ABI, imports,
startup, relocation, allocation, GC, and ordinary Red evaluation.

## Current Baseline

Partial support already exists:

- `system/config.r` defines `Windows-X86-64` and `Windows-X86-64-DLL`.
- `system/targets/X86-64.r` has `win64?` branches for arguments, shadow space,
  stack alignment, imports, and calls.
- `system/formats/PE.r` recognizes machine `8664`, emits a PE32+ optional
  header, and switches import lookup/pointer slots to eight bytes.
- Windows runtime sources still mix pointer-sized types with legacy
  `integer!` carriers and require a complete x64 audit.

Current probe:

```text
cmd /c D:\EE\QTool\rebcmdview.exe -cqs .\red.r -r -t Windows-X86-64 -o .\build\windows-x64-probe.exe .\tests\source\runtime\x64-red-smoke.red
```

`dumpbin /headers` reports PE32+ (`20B`), x64 machine `8664`, console
subsystem, and `Dynamic base`/`NX compatible`. `dumpbin /imports` reports
MSVCRT and KERNEL32 imports. Running reaches the Red program but fails at
`FAIL: applied routine call: 5743972`. The image has an empty base-relocation
directory despite the dynamic-base flag, so it is not ASLR-safe yet.

Implementation update: the dynamic integer-only routine bridge and PE32+
executable relocation emission are now fixed. The Windows release smoke passes
three bounded runs, and the focused Windows x64 ABI runner passes nine fixtures
covering function pointers, mixed arguments, floating-point calls, hidden
returns, variadics, register/stack arguments, and aggregate returns. DLL/
development mode, the full core suite, and View remain open milestones.

## Scope And Non-goals

First milestone:

- Windows 10/11 x86-64, PE32+, console subsystem, CRT and Kernel32 imports.
- `-r` single-file release builds with Redbin boot data and core runtime.
- Correct Windows x64 calls, returns, callbacks, variadics, and function pointers.
- ASLR-safe relocation, non-writable code, and NX-compatible data.
- Existing IA-32 and ARM behavior unchanged.

Deferred until console is stable: `-c`/`libRedRT.dll`, View/GUI, WIC/GDI+,
Direct2D, COM, clipboard, camera, and general x64 DLL productization.

Do not widen Red cells or change `node-handle!` to a pointer. Do not use
`integer!` as an address carrier; it remains signed 32-bit.

## Work Plan

### 1. Harness And Reproduction

Files: `tests/`, `system/tests/`, new
`tests/run-windows-x64-release-tests.ps1`.

1. Add a smoke source with a unique success marker. Exercise integer/pointer
   values, strings, block growth, calls, `apply`, routines, float arguments,
   errors, and forced GC.
2. Compile with the existing `red.r` command and run with bounded timeouts.
   Fail on compiler errors, non-zero exit, hangs, missing markers, or runtime
   error text. Clean successful artifacts below `build/windows-x64-tests`.
3. Use these defaults, with explicit overrides for CI:

   ```text
   C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\dumpbin.exe
   C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe
   ```

4. On failure, save the compiler output, `dumpbin` reports, and a CDB log.

Exit criterion: one command reproduces the current `apply` failure without
hanging and identifies whether it is compiler, image, import, or runtime.

### 2. PE32+ Image And Relocation Correctness

Files: `system/formats/PE.r`, `system/linker.r`, `system/emitter.r`,
`system/config.r`.

1. Serialize PE32+ image bases, virtual addresses, stack/heap reserves, and
   pointer fields with explicit 64-bit types. Keep RVAs, section sizes, and
   directory sizes 32-bit as required by PE/COFF.
2. Validate optional-header-64 offsets/size, image base, alignments,
   subsystem, data directories, and `DllCharacteristics` with a binary test.
3. Emit `.reloc` for x64 executables as well as DLLs when dynamic-base is set;
   generate `IMAGE_REL_BASED_DIR64` entries for movable absolute pointers.
   Never claim ASLR with an empty relocation directory.
4. Prefer RIP-relative references and indirect imports in `.text`; use DIR64
   relocations for pointer data only when necessary. Reject unresolved absolute
   text addresses with an actionable linker error.
5. Verify `.text` executable, import/constants read-only, `.data` writable, and
   `.reloc` discardable. Preserve IA-32 PE emission and resources/checksums.

Exit criterion: `dumpbin /headers` shows PE32+ x64 with valid non-empty base
relocations, and a relocated image remains loadable.

### 3. Microsoft x64 ABI

Files: `system/targets/X86-64.r`, `system/emitter.r`, call/return lowering,
`system/tests/source/units/`.

1. Place integer/pointer arguments in RCX/RDX/R8/R9, floats in XMM0-XMM3,
   preserve eight-byte stack slots, and reserve 32-byte caller shadow space.
2. Maintain 16-byte alignment for nested calls, callbacks, imports, errors, and
   variadics. Track shadow space, overflow arguments, and local spills apart.
3. Implement scalar, float/float32, pointer, int64, and aggregate returns;
   hidden structure-return pointers consume RCX.
4. Implement variadic/unprototyped calls, including required float duplication
   into integer registers and exact slot widths.
5. Treat `cdecl`, `stdcall`, and legacy Windows annotations as the same machine
   convention on x64 while preserving source compatibility.
6. Preserve callee-saved RBX/RBP/RSI/RDI/R12-R15 and XMM6-XMM15, and keep
   prologues/epilogues consistent with GC frame metadata.
7. Fix the current `apply` failure, then add direct/indirect calls, callbacks,
   imports, function pointers, aggregate returns, and nested callback tests.

Exit criterion: ABI tests pass for register overflow, shadow space, `apply`,
callbacks, hidden returns, mixed floats, variadics, and function pointers.

### 4. Imports, Exports, And COFF Interop

Files: `system/formats/PE.r`, `system/linker.r`, `system/targets/X86-64.r`,
`runtime/externals.reds`, static-link fixtures, and unit tests.

1. Generate eight-byte import lookup, hint/name, and IAT entries. Use
   undecorated x64 names and RIP-relative indirect calls/loads through the IAT.
2. Separate local `rel32` calls from imported IAT calls. Remove x86 stdcall
   decoration and 32-bit absolute thunks from x64 output.
3. Test pointer-sized imported data, callbacks, handles, and function pointers
   with the correct indirection level.
4. Add MSVC-built x64 `.obj`/`.lib` fixtures for integer, struct, float,
   callback, and exported-data interop.
5. Bring up `Windows-X86-64-DLL` after executables: exports, entry point, IAT,
   `.reloc`, and a client calling one exported function.

Exit criterion: `dumpbin /imports`, `/exports`, and `/relocations` match the
symbol model, and Red/System calls generated and MSVC x64 fixtures.

### 5. Startup, Runtime, And GC

Files: `system/runtime/win32.reds`, `system/runtime/start.reds`,
`runtime/platform/win32.reds`, allocator/collector, `simple-io`, `call`,
`externals`, `redbin`, interpreter, and Windows datatypes.

1. Verify entry order for image base, globals, command line, environment,
   standard handles, error filter, allocator, Redbin, and global context.
2. Convert API handles, callback addresses, LPARAM/WPARAM, pointer results,
   `GetStdHandle`, `WriteFile`, `VirtualAlloc`, thread handles, and environment
   pointers to pointer-sized declarations. Audit every Windows `integer!` field.
3. Exercise VirtualAlloc, series/block/string/hash growth, relocation, and
   release at high addresses; verify upper pointer bits survive.
4. Port stack scanning to Windows x64: account for home-space slots and exact
   bitmap counts, distinguish handles from raw pointers, and update native
   stack references during series relocation.
5. Verify Redbin offsets and stable handles remain offsets/handles. Force GC
   around `apply`, callbacks, strings, blocks, maps, errors, and arguments.
6. Audit the exception filter and CONTEXT layout for x64; determine whether
   `.pdata`/`.xdata` unwind metadata is required for reliable stack walking.

Exit criterion: release smoke reaches its marker after repeated GC, command
line parsing, Redbin loading, calls, and error handling.

### 6. Core, DLL Development Mode, And View

1. Run the non-GUI core suite first: lexer, Unicode, strings, blocks, paths,
   objects, maps/hashes, functions, routines, errors, recycle, file I/O, and
   module loading.
2. Audit WIC/GDI+/Direct2D/COM structures, GUIDs, callbacks, and vtables for
   eight-byte fields and x64 conventions. Convert image/clipboard APIs by
   ownership contract.
3. Build a 64-bit `libRedRT.dll` and validate `-c` separately from release;
   add DLL load/export/callback/unload tests before enabling it by default.
4. Start with a minimal View window and bounded teardown, then enable the full
   View suite, camera, Direct3D, shell, and optional FFI modules.

Exit criterion: core, development DLL, and minimal View gates pass without
hanging or restarting test executables.

### 7. Diagnostics, CI, And Documentation

1. Inspect `/headers`, `/dependents`, `/imports`, `/relocations`, and
   `/sections`; check `8664`, `20B`, subsystem, dynamic base, NX, `.reloc`,
   imports, and section permissions.
2. Run repeatedly and record module bases through a diagnostic marker or CDB
   `lm` to prove relocation is exercised.
3. Use bounded CDB scripts capturing `.lastevent`, `.ecxr`, `!analyze -v`,
   `k`, `kv`, registers, and disassembly around `@rip`; retain dumps on failure.
4. Separate compile-only, ABI, release-runtime, DLL, and View gates. Retain
   IA-32, ARM, Linux x86-64, core, and regression gates.
5. Document supported target names and do not advertise DLL, `-c`, or View
   support until their gates are green.

## Acceptance Matrix

| Area | Evidence |
| --- | --- |
| Compiler | Red/Red/System focused suites compile for `Windows-X86-64` |
| PE image | `dumpbin` validates x64 PE32+, sections, imports, relocations |
| ABI | Registers, stack, shadow space, returns, callbacks, variadics, `apply` |
| Runtime | Startup, command line, handles, allocator, Redbin, GC, errors, core |
| ASLR | Repeated launches use relocated images without pointer truncation |
| DLL | x64 export/import fixture passes before development mode |
| Debugging | CDB captures actionable registers, stack, and disassembly |
| Compatibility | IA-32, ARM, Linux x86-64, and regression gates stay green |

## Suggested Order

1. Land the harness and record the current `apply` failure.
2. Fix x64 call lowering, returns, stack metadata, and ABI fixtures.
3. Fix PE32+ serialization and emit real x64 base relocations.
4. Correct imports/COFF fixtures and validate repeated ASLR launches.
5. Port startup, handles, allocator, Redbin, and GC; run non-GUI core tests.
6. Add the DLL fixture and 64-bit `libRedRT` prerequisites.
7. Audit View/GUI modules, CI gates, and release documentation.

## First Release Exit Criteria

`red.r -r -t Windows-X86-64` builds and repeatedly runs a Red smoke program on
Windows x64, including `apply`, function pointers, floating-point calls,
command-line parsing, allocation, and forced GC. `dumpbin` validates a PE32+
x64 image with correct imports, permissions, and relocations. CDB diagnoses an
injected failure without a hang or restart loop. IA-32, ARM, Linux x86-64,
core, regression, and non-Windows View gates remain intact.
