REBOL [
	Title:   "Red/System x86-64 code emitter"
	Author:  "Red Foundation"
	File: 	 %X86-64.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

make-profilable make target-class [
	target: 'X86-64
	little-endian?: yes
	struct-align-size:	8
	ptr-size:			8
	default-align:		8
	stack-width:		8
	stack-slot-max:		8
	args-offset:		16
	branch-offset-size:	4
	locals-offset:		32
	def-locals-offset:	32
	
	unsupported: does [
		compiler/throw-error "Linux x86-64 backend code generation is not implemented yet"
	]

	on-init: :unsupported
	on-global-prolog: :unsupported
	on-global-epilog: :unsupported
	on-root-level-entry: :unsupported
	on-finalize: :unsupported
	patch-call: :unsupported
	patch-jump-back: :unsupported
	patch-jump-point: :unsupported
	patch-sub-call: :unsupported
	emit-prolog: :unsupported
	emit-epilog: :unsupported
	emit-stack-align-prolog: :unsupported
	emit-stack-align-epilog: :unsupported
	emit-stack-align: :unsupported
	emit-float-trash-last: :unsupported
	emit-casting: :unsupported
	emit-call: :unsupported
	emit-call-syscall: :unsupported
	emit-call-import: :unsupported
	emit-call-native: :unsupported
	emit-not: :unsupported
	emit-push: :unsupported
	emit-pop: :unsupported
	emit-integer-operation: :unsupported
	emit-float-operation: :unsupported
	emit-throw: :unsupported
	emit-alt-last: :unsupported
	emit-log-b: :unsupported
	emit-variable: :unsupported
	emit-argument: :unsupported
	emit-load: :unsupported
	emit-load-literal: :unsupported
	emit-load-literal-ptr: :unsupported
	emit-store: :unsupported
	emit-load-path: :unsupported
	emit-store-path: :unsupported
	emit-init-path: :unsupported
	emit-access-path: :unsupported
	emit-access-register: :unsupported
	emit-move-path-alt: :unsupported
	emit-push-struct: :unsupported
	emit-load-union-tag: :unsupported
	emit-variant-check: :unsupported
	emit-boolean-switch: :unsupported
	emit-branch: :unsupported
	emit-jump-point: :unsupported
	emit-start-loop: :unsupported
	emit-end-loop: :unsupported
	emit-save-last: :unsupported
	emit-restore-last: :unsupported
	emit-get-stack: :unsupported
	emit-set-stack: :unsupported
	emit-get-pc: :unsupported
	emit-get-overflow: :unsupported
	emit-reserve-stack: :unsupported
	emit-release-stack: :unsupported
	emit-alloc-stack: :unsupported
	emit-free-stack: :unsupported
	emit-clear-slot: :unsupported
	emit-open-catch: :unsupported
	emit-close-catch: :unsupported
	emit-read-io: :unsupported
	emit-io-read: :unsupported
	emit-io-write: :unsupported
	emit-fpu-init: :unsupported
	emit-fpu-get: :unsupported
	emit-fpu-set: :unsupported
	emit-fpu-update: :unsupported
	emit-push-all: :unsupported
	emit-pop-all: :unsupported
	emit-atomic-cas: :unsupported
	emit-atomic-load: :unsupported
	emit-atomic-store: :unsupported
	emit-atomic-math: :unsupported
	emit-atomic-fence: :unsupported
	emit-init-sub: :unsupported
	emit-return-sub: :unsupported
	emit-call-sub: :unsupported
]
