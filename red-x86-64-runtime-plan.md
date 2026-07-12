# Compile Red Programs To Linux x86-64 Executables

## Objective

Enable `red.r -r -t Linux-X86-64 program.red` to generate and run a 64-bit
Linux SysV PIE executable from ordinary Red source. The first supported product
is a console release executable; development-mode `libRedRT`, GUI targets,
Windows x64, macOS, and other 64-bit targets follow after that path is stable.

The x86-64 Red/System backend is a prerequisite, not the whole feature. A Red
build goes through `encapper/compiler.r`, creates a generated Red/System
program, embeds Redbin boot data, includes `runtime/red.reds`, and then uses the
Red/System compiler/linker. All of those layers must become 64-bit clean.

## Current Status

- `Linux-X86-64` now emits a SysV AMD64 ELF64 PIE release executable from Red
  source with the existing `red.r -r -t Linux-X86-64` command.
- Cells remain 16 bytes. Red series and node references stored in cells use
  32-bit `node-handle!` values; the physical node registry and collector use
  native-width pointers for relocation and free lists.
- The x64 backend, ELF64/RELA/PIC linker, Redbin bootstrap, runtime imports,
  allocator, stack bitmap metadata, GC relocation, hashtable rooting, and core
  interpreter are implemented.
- The release smoke harness in `tests/run-x64-release-tests.ps1` verifies ELF64,
  PIE, no `TEXTREL`, executable-section relocation safety, ASLR, bounded runtime,
  and repeated execution. It passed five runs, then three runs after the final
  source audit.
- The x64 interpreted core aggregate completed 9,011 tests and 16,787
  assertions without a crash across 3,880 GC cycles. The x64 compiled comp2
  aggregate completed 5,143 tests and 9,427 assertions on repeated runs.
- The host regression runner passed all five compiler regression groups (243/243
  assertions). View remains a separate Windows GUI/backend gate; it terminates
  instead of looping, but its image/text alignment checks still fail in the
  current environment.

The remaining work is product hardening: make the x64 aggregate runners part of
CI, finish the platform-specific View/FFI audits, and bring up x64 `libRedRT`
development mode independently of the release path.

## Scope And Non-goals

The first deliverable supports:

- Linux x86-64, SysV ABI, dynamic glibc, PIE executable, console subsystem.
- `-r` release builds of ordinary Red programs, including boot data and the
  full core runtime needed by `print`, evaluation, blocks, strings, words,
  contexts, errors, GC, and Redbin loading.
- ASLR-safe code and data relocation with no text relocations.

It does not initially support:

- `-c` development builds that depend on a 64-bit `libRedRT`.
- View/GTK, image, clipboard, threading, FFI-heavy extensions, or encap mode.
- Windows x64/PE32+ or macOS x86-64 output.
- Changing the Red cell ABI from 16 bytes or widening `node-handle!`.

Every milestone keeps IA-32 and ARM behavior intact. Do not use `integer!` as
an address transport on x86-64; it is intentionally signed 32-bit.

## Work Plan

### 1. Establish A Reproducible x86-64 Red Build Harness

Files: `tests/`, `tests/run-regression-tests.r`, `system/tests/`, CI scripts.

1. Add `tests/source/runtime/x64-red-smoke.red` with `print "OK"` and a small
   script using a block, string, function call, and arithmetic.
2. Add a runner that compiles with `-r -t Linux-X86-64`, runs under WSL/Linux,
   captures stdout/stderr, and treats compiler errors, crashes, hangs, and
   assertion failures as failures.
3. Add binary inspection checks: `readelf -h` reports `ELF64` and `DYN`,
   `readelf -d` has no `TEXTREL`, and `readelf -r` has no relocation against an
   executable section.
4. Run the executable repeatedly with ASLR enabled. Use a bounded timeout for
   each invocation to prevent a recurrence of the self-test looping failure.
5. Keep this runner separate from the existing 32-bit core/view runners until
   it is reliable; then add it to the normal regression entry point.

Exit criterion: the harness produces a precise failure location for every
candidate runtime change and leaves no generated artifacts in the worktree.

### 2. Make Generated Red/System Compile On x86-64

Files: `encapper/compiler.r`, `runtime/definitions.reds`,
`runtime/structures.reds`, `runtime/red.reds`, `system/compiler.r`,
`system/targets/X86-64.r`.

1. Re-run the current `tests/hello.red` probe with verbose generated output and
   identify the unresolved type that causes `type-spec` to throw `false` in
   `system/compiler.r`. Repair the declaration generation or alias resolution;
   do not hide the failure with a catch-all.
2. Add a compiler-only regression for the generated fragment so failures occur
   before compiling the complete runtime.
3. Enumerate all unsupported x86-64 forms exposed by the generated runtime:
   global/local loads and stores, typed pointers, nested paths, callbacks,
   function pointers, integer carriers for addresses, struct/union fields, and
   system stack/cpu accesses.
4. Implement each missing form in `system/targets/X86-64.r` with focused
   Red/System tests. Use target-specific type assertions where the generated
   runtime must expose a pointer-sized carrier.
5. Add a `--show-expanded`/`--red-only` snapshot test for a minimal Red source
   and an integration test that verifies its generated Red/System compiles for
   both `Linux` and `Linux-X86-64`.

Exit criterion: `tests/hello.red` completes both Red compilation and native
linking for `Linux-X86-64`, even if the executable does not yet start.

### 3. Audit The Runtime Address Model

Files: `runtime/allocator.reds`, `runtime/collector.reds`,
`runtime/common.reds`, `runtime/stack.reds`, `runtime/threads.reds`,
`runtime/redbin.reds`, `runtime/hashtable.reds`, `runtime/externals.reds`, and
the core datatype files.

1. Categorize every `as-integer` usage into:
   - numeric conversion or bounded byte offset, which may remain 32-bit;
   - pointer subtraction, which must use typed pointer subtraction before any
     checked narrowing;
   - pointer storage/retrieval, which must use a pointer type;
   - hash key/identity, which needs an explicit pointer-sized hash or the
     existing 32-bit node handle, depending on semantics.
2. Add named helpers for the permitted conversions, for example a checked
   byte-distance helper and a pointer hash helper. Ban new raw `as-integer`
   conversions of pointer values in code review and with a targeted source scan.
3. Replace physical-node free-list values, node payloads, collector relocation
   tables, stack-reference arrays, frame lists, and callback pointers with
   pointer-typed slots. In particular, `node!` is already pointer-width but its
   `int-ptr!` payload must not carry a truncated next-node or series address.
4. Preserve `node-handle!` exclusively for stable logical references stored in
   Red cells and in handle-indexed tables. Do not turn it back into a raw pointer.
5. Change memory accounting deliberately: retain 32-bit limits only where they
   are language/runtime limits, and otherwise use checked chunks rather than
   silently truncating an allocation size or address difference.
6. Audit C/OS handles separately. `handle!` is pointer-sized, but old fields
   declared as `integer!` for OS handles, callback addresses, or libc return
   values need type-correct declarations.

Exit criterion: the allocator, collector, and Redbin loader compile for
x86-64 with no pointer-to-`integer!` carriers in their control/data structures.
An audit document lists every intentionally retained narrowing conversion.

### 4. Bring Up Core Runtime Initialization And GC

Files: `runtime/red.reds`, `runtime/allocator.reds`, `runtime/collector.reds`,
`runtime/stack.reds`, `runtime/interpreter.reds`, `runtime/redbin.reds`,
`runtime/platform/linux.reds`, `system/runtime/POSIX.reds`.

1. Verify Linux x86-64 startup reaches `red/init`, initializes allocator frames,
   datatype/action tables, root block, global context, stack metadata, and boot
   Redbin data.
2. Make all SysV calls correct for runtime imports: argument registers, stack
   alignment, varargs metadata, pointer returns, callbacks, errno-compatible
   integer returns, and `__libc_start_main` startup behavior.
3. Verify Redbin root offsets remain offsets, not native addresses. Confirm
   `redbin/root-base`, `system/boot-data`, and `get-root` work correctly under
   PIE relocation and that boot loading reconstructs handle-backed references.
4. Port GC stack scanning and relocation tables to pointer-width storage, then
   add a stress mode that forces collection during allocation, string growth,
   block expansion, map/hash growth, and function evaluation.
5. Add a high-address test hook where feasible: allocate memory through the
   normal allocator and assert every stored/recovered physical pointer retains
   its upper 32 bits. The test must not assume a particular ASLR base.
6. Add a runtime startup smoke progression: initialize only; boot-load; print
   an ASCII string; create/evaluate a block; allocate/collect/reuse a series.

Exit criterion: a release x86-64 executable can initialize, load boot data,
evaluate `print "Hello, world!"`, and survive repeated forced GC cycles.

### 5. Enable The Core Red Language Set

Files: `runtime/interpreter.reds`, `runtime/actions.reds`, `runtime/natives.reds`,
`runtime/lexer.reds`, `runtime/tokenizer.reds`, `runtime/parse.reds`,
`runtime/datatypes/*.reds`, `encapper/compiler.r`.

1. Start with execution primitives: literal loading, words/context lookup,
   stack frames, native/action dispatch, functions, errors, and `do`.
2. Enable core values in dependency order: unset/none/logic/integer/char,
   string/binary, block/paren/path, word/context/object, function/routine,
   map/hash, and error/throw/catch.
3. For each datatype, validate 16-byte cell conformance, handle-backed series
   resolution, copy/compare/mold/form behavior, ownership/GC marking, and
   native call boundaries.
4. Replace fixed `>> 4` indexing only where it means `size? red-value!`; retain
   it where the 16-byte cell ABI is an intentional invariant, documenting that
   choice. Do not introduce target-dependent cell size.
5. Add x86-64 filters or targeted runners for existing core tests, initially
   green subsets, then entire units. Expand in a dependency-driven order rather
   than attempting the whole suite after every change.

Exit criterion: the x86-64 runner passes the non-GUI core subset for arithmetic,
strings, blocks, functions, objects, maps, errors, load, parse, and recycle.

### 6. Productize Release Compilation

Files: `red.r`, `encapper/compiler.r`, `system/config.r`, `system/formats/ELF.r`,
`system/linker.r`, docs and test runners.

1. Make `Linux-X86-64` a documented `red.r` target and document the supported
   release-only scope. Do not claim `-c` support until it passes its own suite.
2. Ensure `-r` injects the complete runtime and boot image without relying on a
   host-architecture `libRedRT` artifact.
3. Verify generated ELF64 PIE has correct interpreter, PT_LOAD permissions,
   dynamic imports, RELA entries, exported entry point, and read-only protected
   data. Test on WSL and a native Linux runner if available.
4. Add end-to-end samples: hello, Unicode printing, function/object evaluation,
   collection stress, error handling, and `Needs: [CSV JSON]` where the required
   modules are platform-neutral.
5. Include the x86-64 Red release runner in CI after it is stable; retain
   IA-32/ARM compile and runtime checks for shared compiler/runtime changes.

Exit criterion: documented `red.r -r -t Linux-X86-64` builds pass the selected
core regression suite and all ELF/ASLR inspections in CI.

### 7. Add Development Mode And Optional Subsystems

Files: `red.r`, `system/utils/libRedRT.r`, `runtime/redbin.reds`, platform and
module sources.

1. Build a `Linux-X86-64` `libRedRT.so` using PIC, export the existing runtime
   ABI, and validate the generated include/definition files from
   `system/utils/libRedRT.r`.
2. Enable `-c -t Linux-X86-64` only after a program can load that library,
   resolve its imports, boot through `redbin/boot-load`, and run under ASLR.
3. Add GTK/View, image, clipboard, threads, dynamic extensions, and FFI in
   separate feature gates. Audit every C ABI struct and imported function per
   subsystem; do not inherit 32-bit Linux layouts.
4. Treat Windows x64/PE32+ as a separate backend/runtime target with Win64 ABI,
   LLP64 structures, and independent CI. It must not block Linux completion.

Exit criterion: `-c` development builds and each optional subsystem have a
dedicated integration test and are advertised only after passing it.

## Test Matrix

| Layer | Focus | Required checks |
| --- | --- | --- |
| Generated code | Red-to-Red/System lowering | `--red-only`, generated-source compile test, no unresolved aliases |
| Backend/linker | ELF64 PIE | `readelf -h -d -r`, no `TEXTREL`, repeated ASLR execution |
| Allocator/GC | pointer preservation | forced GC, high-address pointer check, node-handle stability |
| Boot/runtime | initialization | root table, Redbin boot load, stack/context setup |
| Language | Red behavior | targeted core units, then selected `tests/run-core-tests.r` set |
| Regression | cross-target safety | existing IA-32 suite and Linux-ARM smoke after shared edits |
| Development runtime | `libRedRT` | build/load/call x86-64 `.so`, then `-c` end-to-end |

## Milestone Gates

1. Generated `hello.red` links for Linux x86-64.
2. It starts, reaches `red/init`, and exits cleanly.
3. It prints ASCII and Unicode text under PIE/ASLR.
4. It survives forced GC while evaluating core block/string/function programs.
5. It passes the agreed non-GUI core subset from the Red test suite.
6. `-r -t Linux-X86-64` is documented and CI-enforced.
7. `-c`, GUI, and other platforms advance independently from that release gate.

## Risks And Decisions

- The 16-byte cell ABI is an advantage: node handles already avoid widening the
  main Red value structures. Preserve it unless a separate, measured ABI change
  becomes unavoidable.
- The highest-risk work is hidden 32-bit pointer transport in allocator/GC and
  OS/FFI code, not the Red parser or Redbin format. Require typed fixes and
  focused tests instead of broad casts to `uint64!`.
- Release mode should precede `libRedRT`: it removes dynamic runtime loading as
  a variable while validating the compiler, runtime, PIE loader, and boot image.
- Keep Linux SysV as the only active platform until its tests are stable. Shared
  abstractions should be added only after a concrete Linux x86-64 requirement
  and an IA-32/ARM regression check justify them.
