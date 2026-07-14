# Native-Width Cast Cleanup Plan

## Objective

Remove code whose cast requirements change between IA-32 and x86-64. Target
width differences must be represented by types at the ABI boundary, not by
conditional casts spread through the runtime or View backend.

Both targets must compile without warnings while the compiler continues to
report genuinely redundant casts in user-written Red/System code. The work
must preserve the 16-byte Red cell ABI, signed 32-bit `node-handle!` values,
native-width Windows handles and message parameters, and the same logical
`GetWindowLongPtr`/`SetWindowLongPtr` imports on both Windows targets.

## Problem Statement

The current source has two related problems:

- A cast such as `as integer! GetWindowLongPtr ...` is redundant on IA-32 but
  narrows a native value on x86-64.
- Macros such as `WIN_LONG_PTR(value)` hide whether a value is being widened,
  truncated, or reinterpreted as a pointer-sized integer.
- `SendMessage` results are narrowed before the message-specific return
  contract is considered.
- Runtime code still contains casts left over from the migration from raw node
  pointers to signed 32-bit node handles.
- Generated Red/System emits identity casts such as `as integer! 0`, so fixing
  only hand-written include files cannot produce a clean build.

There are currently 169 `as integer!`/`as pointer!` candidate sites in
`runtime/` and 99 in the Windows View backend. Not every site is wrong, so the
cleanup must be driven by compiler diagnostics and value semantics rather than
a mechanical replacement.

## Design Rules

1. Architecture conditionals are allowed in ABI type definitions, import
   symbol selection, and layout declarations. They are not allowed at ordinary
   runtime or View call sites.
2. Keep values native-width while they are native-width. Do not narrow a
   `WPARAM`, `LPARAM`, `LRESULT`, Windows handle, pointer, or window-long value
   merely to perform a comparison or bit test.
3. Convert fixed-width scalar values at the Windows ABI boundary with named
   semantic operations. The current compiler does not implicitly widen an
   `integer!` argument to a 64-bit parameter, so use operations such as
   `win-wparam-from-low32` and `win-lparam-from-integer`; do not spread
   target-dependent cast macros through call sites.
4. Reinterpretation and narrowing must be named by meaning: reference handle,
   packed coordinate, style bits, pointer, or OS handle. Do not use a generic
   `as integer!` as a conversion policy.
5. Preserve direct calls to the logical import-level `GetWindowLongPtr` and
   `SetWindowLongPtr`. Do not reintroduce legacy API wrappers.
6. Keep `node-handle!` signed 32-bit. Its valid registry range is
   `1..INT32_MAX`, with zero reserved for null.
7. Compiler changes may correct generated output or an incorrectly classified
   type. They must not suppress the redundant-cast warning category.

## Work Plan

### 1. Restore The Warning Baseline

Files: `system/compiler.r`, `system/tests/source/compiler/cast-test.r`, Windows
View test runners.

1. Revert the uncommitted removal of the redundant-cast warning and restore
   the internal `/quiet` behavior used for compiler-controlled conversions.
2. Restore tests that prove a genuinely redundant explicit cast emits the
   warning and an illegal cast remains a compilation error.
3. Keep `Assert-NoCompilerWarnings` in the Windows IA-32/x64 build runners.
4. Compile the same minimal View program for both targets and save a normalized
   warning manifest containing source file, cast source type, cast target type,
   and expression context.
5. Classify every emitted warning as stable identity cast, native-to-32-bit
   narrowing, pointer reinterpretation, generated code, or compiler
   misclassification.

Exit criterion: the warning mechanism is active, the two target manifests are
reproducible, and no warning has been hidden or globally disabled.

### 2. Complete The Windows ABI Type Layer

Files: `modules/view/backends/windows/win32.reds` and focused Red/System tests.

1. Retain the current native types:
   `win-wparam!`, `win-lparam!`, `win-lresult!`, `win-long-ptr!`, and
   `win-ulong-ptr!`.
2. Retain the logical `GetWindowLongPtr`/`SetWindowLongPtr` import names. Map
   them to `GetWindowLongPtrW`/`SetWindowLongPtrW` on x64 and the exported
   `GetWindowLongW`/`SetWindowLongW` aliases on IA-32.
3. Remove generic scalar cast macros. Convert flags, indices, and zero values
   through named low-32-bit or signed-integer operations where the compiler
   requires an explicit native-width conversion.
4. Add a Windows-only native carrier union for the cases that genuinely share
   a representation: signed native value, unsigned native value, pointer or
   handle, low signed 32 bits, and `node-handle!`.
5. Require the full native union field to be initialized before writing or
   reading a narrower field so x64 high bits can never contain uninitialized
   data.
6. Provide small semantic conversion operations for documented Windows
   concepts such as a low 32-bit result and packed `LPARAM` coordinates. Do not
   expose generic native-to-integer conversion helpers.

Exit criterion: ordinary scalar arguments use the same named conversion on
both targets, while pointer reinterpretation and documented narrowing are
explicit and target-independent.

### 3. Give Window-Long Slots Stable Semantics

Files: `modules/view/backends/windows/gui.reds`, `base.reds`, `events.reds`,
`direct2d.reds`, `draw-gdi.reds`, and control backends.

1. Inventory every extra-window slot and record whether it stores a native
   pointer, OS handle, signed 32-bit reference handle, flags, or packed
   coordinates.
2. Split overloaded slots such as capture/font, caret/modal, and owner/border
   where their lifetimes can overlap. Where class-specific reuse is intentional,
   give each use a class-scoped semantic name and test the exclusivity rule.
3. Keep pointer and handle slots native-width from `SetWindowLongPtr` through
   `GetWindowLongPtr`; never route them through `integer!`.
4. Store reference handles and state flags by lossless widening. Recover a
   reference handle through the native carrier's 32-bit semantic field.
5. Keep style and extended-style results as `win-long-ptr!` while applying
   masks. Do not narrow `GWL_STYLE` or `GWL_EXSTYLE` results just to test bits.
6. Keep position data in a named packed-value type and extract coordinates with
   the Windows `LPARAM` operations.
7. Replace every `as integer! GetWindowLongPtr` according to the slot or index
   contract, then add a source guard that rejects this pattern.

Exit criterion: every slot has one documented representation, and there are no
generic integer casts on `GetWindowLongPtr` results.

### 4. Make Message Results Message-Specific

Files: `win32.reds`, `events.reds`, `gui.reds`, control backends.

1. Remove the integer-returning `SendMessage` narrowing workaround.
2. Use `SendMessageNative` and retain `win-lresult!` until the individual
   Windows message contract is known.
3. Keep Boolean, flag, count, comparison, pointer, and handle results in a type
   that matches their documented contract.
4. Use the native carrier only for messages whose documented result is a
   32-bit index or packed value.
5. Audit `BM_GETCHECK`, `BM_GETSTATE`, text length, combo/list indices, edit
   selection, tab selection, and image/control messages independently.
6. Replace every `as integer! SendMessage...` and add a source guard preventing
   that pattern from returning.

Exit criterion: no message result is narrowed before its message-specific
meaning is established.

### 5. Finish The 32-Bit Node-Handle Migration

Files: `runtime/ownership.reds`, `allocator.reds`, `collector.reds`,
`redbin.reds`, datatype implementations, interpreter, lexer, and parse code.

1. Use `node-handle!` for every local, parameter, return type, registry field,
   and cell field that contains a stable node reference.
2. Remove identity casts between `node-handle!` and `integer!`. Function
   signatures and field declarations must express the semantic type.
3. Keep explicit conversions only where a generic integer cell payload is
   deliberately interpreted as a node handle. Express those sites through a
   named node-handle operation rather than a generic integer cast.
4. Keep physical node addresses as `node!`, `series!`, or pointer types and
   cross the handle/address boundary only through `node-handle-of`,
   `resolve-node`, and `set-node-handle`.
5. Re-run forced-GC, Redbin, ownership, map, image, context, and callback tests
   after each runtime group because an apparently redundant cast can conceal a
   stale pointer assumption.

Exit criterion: node handles never carry addresses, addresses never pass
through `integer!`, and handle code emits no identity-cast warnings.

### 6. Fix Generated Red/System At The Generator

Files: Red compiler/encapper generators and templates identified by the warning
manifest.

1. Trace warnings reported in generated Red files back to the template or
   emitter that produced them.
2. Replace generated `as integer! 0` with a correctly typed zero or `null`
   expression determined by the destination declaration.
3. Generate root-context and reference variables as `node-handle!` instead of
   generating an integer cast at each initialization or assignment.
4. Preserve pointer types in generated stack, argument, context, and callback
   declarations so downstream code does not need to recover pointer semantics.
5. Add source-level compiler fixtures that compare generated IA-32 and x64 type
   declarations and require both outputs to compile without warnings.

Exit criterion: a compiled Red script contributes no redundant-cast warnings,
including code attributed to the input `.red` file or generated `red.reds`.

### 7. Remove Remaining Stable Identity Casts

Files: remaining runtime and Windows backend files from the warning manifest.

1. Remove casts where the declared source and destination types are stable and
   identical on every supported target.
2. Change declarations to the correct pointer element type instead of casting
   a pointer back to the type it already has.
3. Preserve casts that genuinely change signedness, width, pointer element
   type, or representation.
4. If a valid pointer-element conversion is reported as an identity cast, fix
   the compiler's full-type comparison and add a narrow compiler regression
   test. Do not weaken warnings for scalar casts.
5. Repeat the warning manifest after each group until both target manifests are
   empty.

Exit criterion: zero compiler warnings are achieved through correct source and
generated types, not diagnostic suppression.

## Verification Matrix

Run all commands with bounded process timeouts and confirm that no child test
process remains active afterward.

1. Compile the minimal Windows View source for IA-32 and Windows x86-64 and
   require zero warnings.
2. Run `tests/run-windows-window-long-ptr-tests.ps1`; verify x64 Ptr imports,
   IA-32 Long aliases, slot canaries, and warning-free compilation.
3. Run `tests/run-windows-x64-view-tests.ps1`; require all 107 tests and 507
   assertions to pass with no compiler warnings.
4. Rebuild the IA-32 development runtime and run `tests/run-view-tests.r
   --batch`; require the same 107 tests and 507 assertions.
5. Run `system/tests/run-all.r --batch`; require all Red/System compiler,
   fixed-integer, pointer, union, and runtime assertions to pass.
6. Run `tests/run-core-tests.r --batch` and `tests/run-regression-tests.r` for
   IA-32 compatibility.
7. Run the Windows x64 ABI, release, DLL, development-mode, core, and View
   runners.
8. Use the x64 high-bit canaries for adjacent window slots, `WPARAM`, `LPARAM`,
   `LRESULT`, callbacks, OS handles, and pointers. A test must fail if any high
   bits are accidentally truncated.

## Source Guards

The final test harness should reject these patterns in the Windows backend:

```text
as integer! GetWindowLongPtr
as integer! SendMessage
as-integer hWnd
get-window-long-ptr
set-window-long-ptr
GetWindowLong(
SetWindowLong(
```

The import declarations containing the IA-32 export strings `GetWindowLongW`
and `SetWindowLongW` are the only legacy-name exceptions.

## Commit Sequence

1. Restore cast diagnostics and add warning manifests/guards.
2. Add native Windows carrier types and remove scalar cast macros.
3. Type window-long slots and message results by semantics.
4. Complete runtime node-handle and generated-code cleanup.
5. Remove remaining identity casts and add compiler precision tests if needed.
6. Run the full verification matrix and update the x86-64 support status.

Keep the target-aware protected pointer-table test correction separate from the
warning cleanup so an unrelated test-suite fix does not obscure the cast
refactor.

## Completion Criteria

- The compiler's redundant-cast warning remains enabled and tested.
- IA-32 and Windows x86-64 View builds emit zero warnings.
- No ordinary call site contains a cast required on only one target.
- No `GetWindowLongPtr` or `SendMessage` result is generically narrowed to
  `integer!`.
- Native pointers, OS handles, `WPARAM`, `LPARAM`, and `LRESULT` preserve high
  bits on x64.
- `node-handle!` remains signed 32-bit and never transports a raw address.
- Direct logical `GetWindowLongPtr`/`SetWindowLongPtr` imports remain in use on
  both Windows targets.
- Red/System, core, regression, IA-32 View, and Windows x64 suites pass without
  compilation warnings, crashes, hangs, or leftover test processes.
