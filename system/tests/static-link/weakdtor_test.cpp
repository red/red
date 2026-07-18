/* Fixture for test-weak-default.reds -- the MSVC weak-external idiom:
     cl /nologo /c /MT /O2 /EHs- /GR- weakdtor_test.cpp
   A virtual destructor makes the vtable reference the vector deleting
   destructor ??_E as an IMAGE_SYM_CLASS_WEAK_EXTERNAL whose aux record
   designates the scalar ??_G (defined in this same object) as default.
   The fixture is CRT-free: it supplies its own operator delete (which
   the deleting destructor calls) and a placement operator new. */

static void* g_freed = 0;

void __cdecl operator delete(void* p)                   { g_freed = p; }
void __cdecl operator delete(void* p, unsigned int)     { g_freed = p; }
inline void* __cdecl operator new(unsigned int, void* p) { return p; }

struct Base {
    virtual ~Base() {}
    virtual int f() const { return 1; }
};

struct Derived : Base {
    int f() const override { return 41; }
};

extern "C" int wd_call(void) {
    Derived d;
    Base* b = &d;
    return b->f() + 1;                      /* 42, through the vtable */
}

extern "C" int wd_del(void) {
    static char buf[sizeof(Derived)];
    Derived* d = new(buf) Derived;
    Base* b = d;
    delete b;           /* virtual deleting destructor: the ??_E vtable
                           slot resolves through its weak default ??_G */
    return g_freed == buf ? 42 : 0;
}
