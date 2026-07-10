Red [
	Title: "Red/System node handle runtime test"
	File:  %node-handle-test.red
]

#system [
	#include %../../../quick-test/quick-test.reds

	node-handle-delete-seen?: no
	node-handle-delete-expected: 0

	node-handle-delete-probe: func [
		encoded [int-ptr!]
		/local
			stable [node-handle!]
			node [node!]
			s [series!]
	][
		stable: as node-handle! as-integer encoded
		node: resolve-node stable
		s: as series! node/value
		node-handle-delete-seen?: all [
			stable = node-handle-delete-expected
			s/node = stable
		]
	]

	~~~start-file~~~ "node handles"

	===start-group=== "registry"

	--test-- "node-handle-resolve"
		node: alloc-bytes 8
		handle: node-handle-of node
		--assert handle > 0
		--assert (as-integer resolve-node handle) = as-integer node

	--test-- "node-handle-series-backref"
		node: alloc-cells 2
		handle: node-handle-of node
		series: as series! node/value
		--assert series/node = handle
		--assert (as-integer resolve-series handle) = as-integer series

	--test-- "node-handle-cell-layout"
		--assert (size? node-handle!) = 4
		--assert (size? red-series!) = 16
		--assert (size? red-string!) = 16
		--assert (size? red-file!) = 16
		--assert (size? red-url!) = 16
		--assert (size? red-tag!) = 16
		--assert (size? red-email!) = 16
		--assert (size? red-ref!) = 16
		--assert (size? red-binary!) = 16
		--assert (size? red-bitset!) = 16
		--assert (size? red-symbol!) = 16
		--assert (size? red-block!) = 16
		--assert (size? red-paren!) = 16
		--assert (size? red-path!) = 16
		--assert (size? red-lit-path!) = 16
		--assert (size? red-set-path!) = 16
		--assert (size? red-get-path!) = 16
		--assert (size? red-context!) = 16
		--assert (size? red-object!) = 16
		--assert (size? red-word!) = 16
		--assert (size? red-refinement!) = 16
		--assert (size? red-action!) = 16
		--assert (size? red-native!) = 16
		--assert (size? red-op!) = 16
		--assert (size? red-function!) = 16
		--assert (size? red-routine!) = 16
		--assert (size? red-vector!) = 16
		--assert (size? red-hash!) = 16
		--assert (size? red-image!) = 16
		--assert (size? red-slice!) = 16

	--test-- "node-handle-stack-context-offset"
		--assert (stack/store-values stack/bottom) = 1
		stack-slot: stack/bottom + 3
		stack-offset: stack/store-values stack-slot
		--assert stack-offset = 4
		--assert (as-integer stack/get-values stack-offset) = as-integer stack-slot
		--assert null? stack/get-values 0

	--test-- "node-handle-compaction-and-reuse"
		relocations: _hashtable/rs-init 16
		destination-frame: alloc-node-frame nodes-per-frame
		source-frame: alloc-node-frame nodes-per-frame
		memory/n-active: source-frame

		old-node: alloc-bytes 8
		stable-handle: node-handle-of old-node
		holder: as red-binary! stack/push*
		holder/header: TYPE_BINARY
		holder/head: 0
		holder/node: stable-handle
		node-handle-delete-expected: stable-handle
		node-handle-delete-seen?: no
		external-type: externals/register "node-handle-test" as-integer :node-handle-delete-probe
		external-id: externals/store as int-ptr! stable-handle external-type
		external-record: externals/list + external-id
		--assert external-record/handle = stable-handle
		memory/n-active: destination-frame
		collector/compact-node source-frame relocations

		moved-node: resolve-node stable-handle
		moved-series: as series! moved-node/value
		--assert moved-node <> old-node
		--assert holder/node = stable-handle
		--assert moved-series/node = stable-handle
		--assert (as-integer resolve-node stable-handle) = as-integer moved-node

		_hashtable/rs-destroy relocations
		holder/header: TYPE_UNSET
		stack/pop 1
		relocations: null
		old-node: null
		moved-node: null
		moved-series: null
		source-frame: null
		destination-frame: null
		external-record: null
		collector/do-cycle

		--assert node-handle-delete-seen?
		registry-entry: node-registry/entries + (stable-handle - 1)
		--assert registry-entry/value = null

		reused-node: alloc-bytes 8
		reused-handle: node-handle-of reused-node
		--assert reused-handle = stable-handle
		--assert (as-integer resolve-node reused-handle) = as-integer reused-node

	===end-group===

	~~~end-file~~~
]
