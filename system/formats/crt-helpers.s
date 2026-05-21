// ===================================================================
// x86 (i386) 64-bit integer division / remainder helper routines.
//
// MSVC and clang-cl emit calls to these for __int64 '/' and '%'.
// They live in no DLL -- normally pulled from the CRT static archive.
// These are independent re-implementations for embedding into the Red
// static linker, so a statically linked C archive needs no CRT lib.
//
// ABI (matches the MSVC __a* helpers):
//   - two __int64 arguments passed on the stack, low dword first:
//       [ret][n_lo][n_hi][d_lo][d_hi]
//   - 64-bit result returned in EDX:EAX (EDX = high)
//   - the routine pops its 16 bytes of arguments  ->  'ret 16'
//   - EBX, ESI, EDI, EBP are preserved; EAX, ECX, EDX may be clobbered
//
// Algorithm: plain unsigned shift-subtract long division, 64 iterations
// (correctness over speed), with sign handling around it for the
// signed variants. Each routine is self-contained and position-
// independent (no relocations), so its assembled bytes embed directly.
// ===================================================================

    .intel_syntax noprefix
    .text

// -------------------------------------------------------------------
// unsigned __int64 __aulldiv(unsigned __int64 n, unsigned __int64 d)
// -------------------------------------------------------------------
    .globl  __aulldiv
__aulldiv:
    push    ebp
    push    esi
    push    edi
    push    ebx
    // 4 pushes -> n_lo=[esp+20] n_hi=[esp+24] d_lo=[esp+28] d_hi=[esp+32]
    mov     eax, [esp+20]          // EDX:EAX = dividend (becomes quotient)
    mov     edx, [esp+24]
    xor     ebx, ebx               // ESI:EBX = remainder = 0
    xor     esi, esi
    mov     ecx, 64
1:
    shl     eax, 1                 // [rem:dividend] <<= 1  (128-bit shift)
    rcl     edx, 1
    rcl     ebx, 1
    rcl     esi, 1
    mov     edi, ebx               // trial subtract: (ESI:EBX) - divisor
    mov     ebp, esi
    sub     edi, [esp+28]
    sbb     ebp, [esp+32]
    jc      2f                     // borrow => remainder < divisor
    mov     ebx, edi               // commit remainder -= divisor
    mov     esi, ebp
    or      eax, 1                 // and set the quotient bit
2:
    dec     ecx
    jnz     1b
    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret     16

// -------------------------------------------------------------------
// unsigned __int64 __aullrem(unsigned __int64 n, unsigned __int64 d)
// -------------------------------------------------------------------
    .globl  __aullrem
__aullrem:
    push    ebp
    push    esi
    push    edi
    push    ebx
    mov     eax, [esp+20]
    mov     edx, [esp+24]
    xor     ebx, ebx
    xor     esi, esi
    mov     ecx, 64
1:
    shl     eax, 1
    rcl     edx, 1
    rcl     ebx, 1
    rcl     esi, 1
    mov     edi, ebx
    mov     ebp, esi
    sub     edi, [esp+28]
    sbb     ebp, [esp+32]
    jc      2f
    mov     ebx, edi
    mov     esi, ebp
    or      eax, 1
2:
    dec     ecx
    jnz     1b
    mov     eax, ebx               // result = remainder (ESI:EBX)
    mov     edx, esi
    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret     16

// -------------------------------------------------------------------
// __int64 __alldiv(__int64 n, __int64 d)   -- signed division
//   result sign = sign(n) XOR sign(d)
// -------------------------------------------------------------------
    .globl  __alldiv
__alldiv:
    push    ebp
    push    esi
    push    edi
    push    ebx
    sub     esp, 4                 // local [esp] = result-sign flag
    // 4 pushes + local -> n_lo=[esp+24] n_hi=[esp+28] d_lo=[esp+32] d_hi=[esp+36]
    mov     dword ptr [esp], 0
    mov     edx, [esp+28]          // absolutize n
    test    edx, edx
    jns     1f
    xor     dword ptr [esp], 1
    mov     eax, [esp+24]
    neg     edx
    neg     eax
    sbb     edx, 0
    mov     [esp+24], eax
    mov     [esp+28], edx
1:
    mov     edx, [esp+36]          // absolutize d
    test    edx, edx
    jns     2f
    xor     dword ptr [esp], 1
    mov     eax, [esp+32]
    neg     edx
    neg     eax
    sbb     edx, 0
    mov     [esp+32], eax
    mov     [esp+36], edx
2:
    mov     eax, [esp+24]          // unsigned divide |n| / |d|
    mov     edx, [esp+28]
    xor     ebx, ebx
    xor     esi, esi
    mov     ecx, 64
3:
    shl     eax, 1
    rcl     edx, 1
    rcl     ebx, 1
    rcl     esi, 1
    mov     edi, ebx
    mov     ebp, esi
    sub     edi, [esp+32]
    sbb     ebp, [esp+36]
    jc      4f
    mov     ebx, edi
    mov     esi, ebp
    or      eax, 1
4:
    dec     ecx
    jnz     3b
    cmp     dword ptr [esp], 0     // negate quotient if signs differed
    je      5f
    neg     edx
    neg     eax
    sbb     edx, 0
5:
    add     esp, 4
    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret     16

// -------------------------------------------------------------------
// __int64 __allrem(__int64 n, __int64 d)   -- signed remainder
//   result sign = sign(n)  (the dividend)
// -------------------------------------------------------------------
    .globl  __allrem
__allrem:
    push    ebp
    push    esi
    push    edi
    push    ebx
    sub     esp, 4                 // local [esp] = dividend-sign flag
    mov     dword ptr [esp], 0
    mov     edx, [esp+28]          // absolutize n, remember its sign
    test    edx, edx
    jns     1f
    mov     dword ptr [esp], 1
    mov     eax, [esp+24]
    neg     edx
    neg     eax
    sbb     edx, 0
    mov     [esp+24], eax
    mov     [esp+28], edx
1:
    mov     edx, [esp+36]          // absolutize d (its sign is irrelevant)
    test    edx, edx
    jns     2f
    mov     eax, [esp+32]
    neg     edx
    neg     eax
    sbb     edx, 0
    mov     [esp+32], eax
    mov     [esp+36], edx
2:
    mov     eax, [esp+24]          // unsigned divide |n| / |d|
    mov     edx, [esp+28]
    xor     ebx, ebx
    xor     esi, esi
    mov     ecx, 64
3:
    shl     eax, 1
    rcl     edx, 1
    rcl     ebx, 1
    rcl     esi, 1
    mov     edi, ebx
    mov     ebp, esi
    sub     edi, [esp+32]
    sbb     ebp, [esp+36]
    jc      4f
    mov     ebx, edi
    mov     esi, ebp
    or      eax, 1
4:
    dec     ecx
    jnz     3b
    mov     eax, ebx               // result = remainder (ESI:EBX)
    mov     edx, esi
    cmp     dword ptr [esp], 0     // negate it if the dividend was negative
    je      5f
    neg     edx
    neg     eax
    sbb     edx, 0
5:
    add     esp, 4
    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret     16
