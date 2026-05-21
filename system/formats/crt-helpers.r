REBOL [
	Title:   "Embedded x86 64-bit integer division / remainder helpers"
	File:	 %crt-helpers.r
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Machine code for the MSVC / clang-cl __int64 '/' and '%' helper
		routines. The compiler emits calls to these for 64-bit integer
		division and remainder; they are defined in no DLL, so the
		static linker embeds them to satisfy a C archive's references
		without needing a CRT library.

		Each routine is an independent shift-subtract re-implementation
		(see system/formats/crt-helpers.s), self-contained and position-
		independent. ABI: two __int64 arguments on the stack, 64-bit
		result in EDX:EAX, callee pops the 16 argument bytes; EBX, ESI,
		EDI and EBP are preserved.

		Generated: assemble crt-helpers.s with clang for the
		i386-pc-windows-msvc target, then extract each routine's bytes.
	}
]

crt-helpers: [
	"__alldiv"	#{
5556575383EC04C70424000000008B54241C85D27917833424018B442418F7DA
F7D883DA00894424188954241C8B54242485D27917833424018B442420F7DAF7
D883DA0089442420895424248B4424188B54241C31DB31F6B940000000D1E0D1
D2D1D3D1D689DF89F52B7C24201B6C2424720789FB89EE83C8014975E0833C24
007407F7DAF7D883DA0083C4045B5F5E5DC21000
}
	"__aulldiv"	#{
555657538B4424148B54241831DB31F6B940000000D1E0D1D2D1D3D1D689DF89
F52B7C241C1B6C2420720789FB89EE83C8014975E05B5F5E5DC21000
}
	"__allrem"	#{
5556575383EC04C70424000000008B54241C85D2791AC70424010000008B4424
18F7DAF7D883DA00894424188954241C8B54242485D279138B442420F7DAF7D8
83DA0089442420895424248B4424188B54241C31DB31F6B940000000D1E0D1D2
D1D3D1D689DF89F52B7C24201B6C2424720789FB89EE83C8014975E089D889F2
833C24007407F7DAF7D883DA0083C4045B5F5E5DC21000
}
	"__aullrem"	#{
555657538B4424148B54241831DB31F6B940000000D1E0D1D2D1D3D1D689DF89
F52B7C241C1B6C2420720789FB89EE83C8014975E089D889F25B5F5E5DC21000
}
]
