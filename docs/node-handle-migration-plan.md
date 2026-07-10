# 32-bit Node Handle Migration Plan

## Objective

Replace every GC node pointer stored in a 16-byte Red value cell with a stable,
signed 32-bit handle. Physical `node!` pointers remain an allocator and collector
implementation detail. This preserves the value-cell ABI when Red/System gains
64-bit targets: cells stay unchanged while the handle registry stores
pointer-width physical addresses.

## Invariants

1. `node-handle!` is an `integer!`; `node!` is a physical, pointer-width node
   address. Code must not use the names interchangeably.
2. Handle `0` is null. Live handles are positive and index the process-local
   node registry.
3. A handle is stable for the lifetime of its node. GC compaction retargets the
   registry entry instead of rewriting value cells.
4. A series buffer stores its own handle in `series-buffer!/node`, not its
   current physical node address.
5. Raw node pointers are resolved at narrow runtime or platform boundaries and
   must not be retained across an allocation or GC point unless that subsystem
   already pins or roots them.
6. Handles are process-local identities. Redbin and other persistence formats
   reconstruct handles and never serialize registry indices as durable data.
7. Handle release happens with physical node reclamation. A released slot may
   be reused only after the collector has proved the old node unreachable.
8. `red-context!/values` is a tagged exception for stack-resident function
   contexts. When `ON_STACK?` is true it stores a positive 32-bit stack offset,
   not a registry handle, and must be decoded with `stack/get-values`. Heap
   contexts continue to store ordinary node handles.

## Representation

- Define `node-handle!` as `integer!` and keep `node!` as the physical pointer
  alias.
- Add a registry with pointer-width entries, capacity, the next unused positive
  handle, and a free-list of reusable handles.
- Provide these boundary helpers:
  - `resolve-node`: handle to physical node.
  - `resolve-series`: handle to series buffer.
  - `node-handle-of`: physical node to its stable handle.
  - `alloc-node-handle`: allocate and bind a registry slot.
  - `set-node-handle`: retarget a handle after node movement.
  - `free-node-handle`: release a registry slot with node reclamation.
- Keep the registry's physical entries pointer-width (`ptr-ptr!`). Only the
  index stored in cells is fixed at 32 bits.
- Keep the existing stack-context representation within the same 32-bit field:
  `stack/store-values` encodes the offset and `stack/get-values` decodes it.
  The context's stack flag, rather than the integer value itself, determines
  whether the field is a stack offset or a registry handle.

## Migration Sequence

### 1. Inventory and type split

- Inventory `node`, `ctx`, `spec`, `more`, `cache`, `symbols`, `values`,
  `on-set`, image, hash-table, and ownership fields in value-cell layouts.
- Convert cell-resident node references in `runtime/structures.reds` and copied
  ABI definitions to `node-handle!`.
- Classify every remaining `node!` use as allocator state, collector state,
  transient resolved access, native resource state, or a defect.

### 2. Allocation and resolution

- Bind a handle whenever a physical node is allocated.
- Store the handle in both the value cell and the series back-reference.
- Replace direct cell casts and dereferences with `resolve-node` or
  `resolve-series` at the point of use.
- Store `0`, not pointer `null`, in handle fields and use `HANDLE?` or
  `NULL_HANDLE?` for tests.

### 3. Collector integration

- Mark through handles for all cell-owned references.
- Retain a separate raw-node marking path for allocator stacks and internal
  tables that intentionally contain physical nodes.
- During compaction, update the registry entry and leave all cells untouched.
- During sweep, retain both physical node and handle until reclamation so the
  handle can be released without reading already-freed series memory.
- Keep ownership-table handle keys distinct from Redbin or refresh tables whose
  keys are intentionally raw physical nodes.

### 4. Runtime subsystems

- Migrate series datatypes, contexts, objects, functions, routines, words,
  maps, hashes, ownership, lexer buffers, interpreter state, and global roots.
- Update Redbin load/save and encapper paths so newly materialized nodes receive
  handles and relocation maps continue to use explicit raw-node keys where
  required.
- Update copied runtime definitions in libRedRT and external bridges.

### 5. Platform resources

- Store a node handle in `red-image!` on every backend.
- Wrap WIC, GDK, Quartz, and GDI+ resources in collector-managed image nodes.
- Resolve the node only when calling native graphics APIs; keep native handles
  inside the platform node payload.
- Store the stable node handle, not its physical node pointer, in image
  external-resource records; resolve it before running the image destructor.
- Mark and destroy native resources through the external-resource table.
- Apply the same boundary rule to GUI caches, event blocks, widgets, clipboard,
  and bridge code.

### 6. Verification

- Add a focused runtime test for allocation, handle lookup, series
  back-references, collection, compaction, and handle-slot reuse.
- Run the high-frequency recycle/GC regression and require zero failed
  assertions.
- Compile at least one runtime target and one GUI/platform target so conditional
  backends and copied definitions are type-checked.
- Audit assignments and casts to ensure no physical node is stored in a value
  cell.
- Run `git diff --check` and the relevant runtime test suites.

## 64-bit Enablement Follow-up

When Red/System supports 64-bit targets:

1. Keep `node-handle!`, value-cell layouts, serialized values, and handle APIs
   unchanged.
2. Validate `node!`, registry entries, collector temporary records, native image
   payloads, and external-resource storage at pointer width.
3. Replace remaining pre-existing pointer arrays or pointer-to-`integer!` casts
   outside value cells with pointer-width representations.
4. Add compile-time size assertions for value cells, handles, physical pointers,
   registry entries, and collector records on both 32-bit and 64-bit targets.
5. Run the same GC stress tests on both architectures and compare serialized
   Redbin output for architecture-independent behavior.

## Completion Gates

- All value-cell node-reference fields are `node-handle!` and remain 32 bits.
- All cell reads resolve explicitly before physical dereference.
- Stack-context `values` reads branch on `ON_STACK?` and decode their 32-bit
  stack offset instead of consulting the node registry.
- GC marking, compaction, sweep, and handle reuse pass stress testing.
- Conditional image and GUI backends compile with the uniform representation.
- Redbin, libRedRT, and bridge definitions agree with the runtime ABI.
- The raw-pointer audit reports only documented internal or transient uses.
