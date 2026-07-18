#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <dirent.h>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <pthread.h>
#include <signal.h>
#include <sys/stat.h>
#include <time.h>

_Static_assert(sizeof(struct sigaction) == 16, "sigaction size");
_Static_assert(offsetof(struct sigaction, sa_mask) == 8, "sigaction mask");
_Static_assert(offsetof(struct sigaction, sa_flags) == 12, "sigaction flags");
_Static_assert(sizeof(ucontext_t) == 56, "ucontext size");
_Static_assert(offsetof(ucontext_t, uc_mcontext) == 48, "ucontext mcontext");
_Static_assert(offsetof(struct __darwin_mcontext64, __ss) == 16, "mcontext thread state");
_Static_assert(offsetof(struct __darwin_mcontext64, __ss.__fp) == 248, "mcontext fp");
_Static_assert(offsetof(struct __darwin_mcontext64, __ss.__sp) == 264, "mcontext sp");
_Static_assert(offsetof(struct __darwin_mcontext64, __ss.__pc) == 272, "mcontext pc");
_Static_assert(sizeof(struct stat) == 144, "stat size");
_Static_assert(offsetof(struct stat, st_mode) == 4, "stat mode");
_Static_assert(offsetof(struct stat, st_mtimespec) == 48, "stat mtime");
_Static_assert(offsetof(struct stat, st_size) == 96, "stat size field");
_Static_assert(offsetof(struct dirent, d_reclen) == 16, "dirent reclen");
_Static_assert(offsetof(struct dirent, d_type) == 20, "dirent type");
_Static_assert(offsetof(struct dirent, d_name) == 21, "dirent name");
_Static_assert(sizeof(pthread_attr_t) == 64, "pthread attr size");
_Static_assert(sizeof(struct timespec) == 16, "timespec size");
_Static_assert(offsetof(struct timespec, tv_nsec) == 8, "timespec nsec");

typedef struct {
	int32_t left;
	int32_t right;
} pair32_t;

typedef struct {
	int32_t a;
	int32_t b;
	int32_t c;
	int32_t d;
	int32_t e;
	int32_t f;
} large_t;

typedef struct {
	double x;
	double y;
} hfa2_t;

typedef struct {
	uint8_t a;
	uint8_t b;
	uint8_t c;
} triple8_t;

int check_narrow_registers(
	int8_t i8, uint8_t u8, int16_t i16, uint16_t u16,
	int32_t i32, uint32_t u32, int64_t i64, uint64_t u64
) {
	return i8 == -2 && u8 == 250 && i16 == -300 && u16 == 60000
		&& i32 == -123456 && u32 == 4000000000U && i64 == -3
		&& u64 == 0x100000004ULL;
}

int check_compact_stack(
	int64_t r0, int64_t r1, int64_t r2, int64_t r3,
	int64_t r4, int64_t r5, int64_t r6, int64_t r7,
	int8_t i8, uint8_t u8, int16_t i16, uint16_t u16,
	int32_t i32, uint32_t u32, int64_t i64, uint64_t u64
) {
	return r0 == 10 && r1 == 11 && r2 == 12 && r3 == 13
		&& r4 == 14 && r5 == 15 && r6 == 16 && r7 == 17
		&& i8 == -2 && u8 == 250 && i16 == -300 && u16 == 60000
		&& i32 == -123456 && u32 == 4000000000U && i64 == -3
		&& u64 == 0x100000004ULL;
}

int check_compact_fp_stack(
	double d0, double d1, double d2, double d3,
	double d4, double d5, double d6, double d7,
	float f0, float f1, double d8
) {
	return d0 == 1.0 && d1 == 2.0 && d2 == 3.0 && d3 == 4.0
		&& d4 == 5.0 && d5 == 6.0 && d6 == 7.0 && d7 == 8.0
		&& f0 == 9.25f && f1 == 10.5f && d8 == 11.75;
}

int check_variadic(int marker, ...) {
	va_list args;
	va_start(args, marker);
	int i0 = va_arg(args, int);
	double d0 = va_arg(args, double);
	int i1 = va_arg(args, int);
	uint64_t u64 = va_arg(args, uint64_t);
	va_end(args);
	return marker == 77 && i0 == -9 && d0 == 2.5 && i1 == 123
		&& u64 == 0x100000004ULL;
}

int check_variadic_after_stack(
	int32_t a0, int32_t a1, int32_t a2, int32_t a3, int32_t a4,
	int32_t a5, int32_t a6, int32_t a7, int32_t a8, ...
) {
	va_list args;
	va_start(args, a8);
	int tail = va_arg(args, int);
	va_end(args);
	return a0 == 10 && a1 == 11 && a2 == 12 && a3 == 13 && a4 == 14
		&& a5 == 15 && a6 == 16 && a7 == 17 && a8 == 18 && tail == 42;
}

int check_objc_dispatch(
	uint64_t receiver, uint64_t selector, float f0, double d0,
	uint8_t u8, int16_t i16, uint64_t u64
) {
	return receiver == 0x100000001ULL && selector == 0x100000002ULL
		&& f0 == 1.25f && d0 == 2.5 && u8 == 250 && i16 == -300
		&& u64 == 0x100000004ULL;
}

int check_objc_compact_stack(
	uint64_t receiver, uint64_t selector,
	int32_t a0, int32_t a1, int32_t a2, int32_t a3, int32_t a4, int32_t a5,
	int8_t i8, uint8_t u8, int16_t i16, uint16_t u16, int32_t i32
) {
	return receiver == 0x100000001ULL && selector == 0x100000002ULL
		&& a0 == 10 && a1 == 11 && a2 == 12 && a3 == 13 && a4 == 14 && a5 == 15
		&& i8 == -2 && u8 == 250 && i16 == -300 && u16 == 60000
		&& i32 == -123456;
}

int check_readonly(const void *address) {
	mach_vm_address_t region = (mach_vm_address_t)(uintptr_t)address;
	mach_vm_size_t size = 0;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
	mach_port_t object = MACH_PORT_NULL;
	kern_return_t result = mach_vm_region(
		mach_task_self(), &region, &size, VM_REGION_BASIC_INFO_64,
		(vm_region_info_t)&info, &count, &object
	);
	if (MACH_PORT_VALID(object)) mach_port_deallocate(mach_task_self(), object);
	return result == KERN_SUCCESS && (info.protection & VM_PROT_WRITE) == 0;
}

int check_pair(pair32_t value, int marker) {
	return value.left == 20 && value.right == 22 && marker == 7;
}

int check_large(large_t value, int marker) {
	return value.a == 1 && value.b == 2 && value.c == 3
		&& value.d == 4 && value.e == 5 && value.f == 6 && marker == 8;
}

int check_hfa(hfa2_t value, int marker) {
	return value.x == 1.25 && value.y == 2.75 && marker == 9;
}

int check_triple_stack(
	int64_t r0, int64_t r1, int64_t r2, int64_t r3,
	int64_t r4, int64_t r5, int64_t r6, int64_t r7,
	triple8_t value, uint16_t tail
) {
	return r0 == 10 && r1 == 11 && r2 == 12 && r3 == 13
		&& r4 == 14 && r5 == 15 && r6 == 16 && r7 == 17
		&& value.a == 1 && value.b == 2 && value.c == 3 && tail == 60000;
}

int check_hfa_stack(
	double d0, double d1, double d2, double d3,
	double d4, double d5, double d6, double d7,
	hfa2_t value, float tail
) {
	return d0 == 1.0 && d1 == 2.0 && d2 == 3.0 && d3 == 4.0
		&& d4 == 5.0 && d5 == 6.0 && d6 == 7.0 && d7 == 8.0
		&& value.x == 1.25 && value.y == 2.75 && tail == 9.5f;
}

typedef int (*compact_callback_t)(
	int64_t, int64_t, int64_t, int64_t,
	int64_t, int64_t, int64_t, int64_t,
	int8_t, uint8_t, int16_t, uint16_t,
	int32_t, uint32_t, int64_t, uint64_t
);

int invoke_compact_callback(compact_callback_t callback) {
	return callback(
		10, 11, 12, 13, 14, 15, 16, 17,
		-2, 250, -300, 60000, -123456, 4000000000U,
		-3, 0x100000004ULL
	);
}

typedef int (*pair_callback_t)(pair32_t, int);

int invoke_pair_callback(pair_callback_t callback) {
	pair32_t value = {20, 22};
	return callback(value, 7);
}

typedef int (*triple_stack_callback_t)(
	int64_t, int64_t, int64_t, int64_t,
	int64_t, int64_t, int64_t, int64_t,
	triple8_t, uint16_t
);

int invoke_triple_stack_callback(triple_stack_callback_t callback) {
	triple8_t value = {1, 2, 3};
	return callback(10, 11, 12, 13, 14, 15, 16, 17, value, 60000);
}

typedef int (*hfa_stack_callback_t)(
	double, double, double, double, double, double, double, double,
	hfa2_t, float
);

int invoke_hfa_stack_callback(hfa_stack_callback_t callback) {
	hfa2_t value = {1.25, 2.75};
	return callback(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, value, 9.5f);
}
