#include <dlfcn.h>
#include <stdio.h>

typedef int (*unary_int_fn)(int);

int main(int argc, char **argv) {
	if (argc != 2) {
		return 10;
	}

	void *library = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
	if (library == NULL) {
		fprintf(stderr, "%s\n", dlerror());
		return 11;
	}

	unary_int_fn foo = (unary_int_fn)dlsym(library, "foo");
	int *value = (int *)dlsym(library, "i");
	if (foo == NULL || value == NULL) {
		fprintf(stderr, "%s\n", dlerror());
		return 12;
	}
	if (*value != 56 || foo(41) != 42) {
		return 13;
	}

	dlclose(library);
	return 0;
}
