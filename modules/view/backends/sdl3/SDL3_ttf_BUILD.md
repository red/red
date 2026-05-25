# SDL3_ttf Static Library

Generated `SDL3_ttf.lib` and `freetype.lib` are Win32/x86 MSVC static libraries
for the SDL3 View backend. SDL_ttf was built with vendored FreeType enabled and
with HarfBuzz and PlutoSVG disabled. MSVC function-level linking is enabled
through `/Gy`.

Source revisions:

- SDL_ttf: `c4a94c4c5754968396d83b08d1438aea565058a6`
- SDL headers: `29f7f08261e086a6879d7d3cb4ca51195fbfe9f8`

Build commands:

```bat
git clone --depth=1 --recursive https://github.com/libsdl-org/SDL_ttf.git build\deps\SDL_ttf
git clone --depth=1 https://github.com/libsdl-org/SDL.git build\deps\SDL
cmake -S build\deps\sdl_ttf_red_static -B build\sdl_ttf-msvc-x86-min -G "Visual Studio 18 2026" -A Win32 -DBUILD_SHARED_LIBS=OFF -DSDLTTF_VENDORED=ON -DSDLTTF_SAMPLES=OFF -DSDLTTF_INSTALL=OFF -DSDLTTF_HARFBUZZ=OFF -DSDLTTF_PLUTOSVG=OFF
cmake --build build\sdl_ttf-msvc-x86-min --config Release --target SDL3_ttf-static --parallel
copy /Y build\sdl_ttf-msvc-x86-min\SDL_ttf\Release\SDL3_ttf-static.lib modules\view\backends\sdl3\SDL3_ttf.lib
copy /Y build\sdl_ttf-msvc-x86-min\SDL_ttf\external\freetype-build\Release\freetype.lib modules\view\backends\sdl3\freetype.lib
```

The CMake wrapper in `build\deps\sdl_ttf_red_static` defines `SDL3::Headers`
from `build\deps\SDL\include` and `SDL3::SDL3` from this backend's existing
`SDL3.lib`, and injects `/Gy` before adding SDL_ttf and its vendored
dependencies, so SDL_ttf is built against the same backend link target.

Standalone MSVC link smoke passed with:

```bat
SDL3_ttf.lib freetype.lib SDL3.lib msvcrt.lib vcruntime.lib ucrt.lib legacy_stdio_definitions.lib kernel32.lib user32.lib gdi32.lib gdiplus.lib winmm.lib imm32.lib ole32.lib oleaut32.lib version.lib setupapi.lib advapi32.lib shell32.lib uuid.lib rpcrt4.lib usp10.lib
```

The HarfBuzz/Pluto-enabled build was avoided for the backend import because the
Red static linker did not resolve HarfBuzz from a combined archive and the
PlutoVG objects pulled in `__tls_index`.
