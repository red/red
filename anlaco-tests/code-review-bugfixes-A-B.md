# Code Review: Bug A y Bug B Fixes (GTK3 Resize)

**Fecha:** 2026-04-14
**Revisor:** Claude Code
**Commits revisados:** `b381d9d23` (Bug A), `dbcfbe84a` (Bug B)
**Archivos afectados:**
- `modules/view/backends/gtk3/gtk.reds`
- `modules/view/backends/gtk3/handlers.reds`
- `modules/view/backends/gtk3/events.reds`
- `modules/view/backends/gtk3/gui.reds`

---

## 1. BUG FACTUAL: Constantes GDK_WINDOW_STATE_* incorrectas

**Archivo:** `modules/view/backends/gtk3/gtk.reds`, lineas 331-338
**Severidad:** Media (bug latente, sin impacto actual)
**Estado:** CONFIRMADO tras intento de refutacion

### El problema

```reds
;-- GdkWindowState flags (bitmask)
#define GDK_WINDOW_STATE_WITHDRAWN     1
#define GDK_WINDOW_STATE_ICONIFIED     2
#define GDK_WINDOW_STATE_MAXIMIZED     4
#define GDK_WINDOW_STATE_FULLSCREEN   16
#define GDK_WINDOW_STATE_ABOVE         32
#define GDK_WINDOW_STATE_BELOW         64
#define GDK_WINDOW_STATE_STICKY       128    ; ← ERROR: este valor es FOCUSED
```

### Valores reales (GTK3 oficial)

| Constante | Valor en codigo | Valor real GTK3 | Estado |
|-----------|-----------------|-----------------|--------|
| GDK_WINDOW_STATE_WITHDRAWN | 1 | 1 | OK |
| GDK_WINDOW_STATE_ICONIFIED | 2 | 2 | OK |
| GDK_WINDOW_STATE_MAXIMIZED | 4 | 4 | OK |
| **GDK_WINDOW_STATE_STICKY** | **ausente** | **8** | **FALTA** |
| GDK_WINDOW_STATE_FULLSCREEN | 16 | 16 | OK |
| GDK_WINDOW_STATE_ABOVE | 32 | 32 | OK |
| GDK_WINDOW_STATE_BELOW | 64 | 64 | OK |
| **GDK_WINDOW_STATE_FOCUSED** | **ausente** | **128** | **FALTA** |

La secuencia de potencias de 2 salta de 4 a 16, omitiendo el 8 (STICKY).
El valor 128 esta asignado a STICKY cuando en realidad es FOCUSED.

### Fuente

https://docs.gtk.org/gdk3/flags.WindowState.html
GTK3 source: `gdk/gdktypes.h` — enum GdkWindowState con bit shifts (1 << 0 .. 1 << 7)

### Intento de refutacion

Se verifico contra la documentacion oficial de GTK3 y el codigo fuente de
`gdktypes.h`. Los valores son potencias de 2 (1 << N), no hay ambiguedad.
No existen versiones de GTK3 donde STICKY valga 128. El error es factual.

### Impacto actual

Ninguno. Solo se usa `GDK_WINDOW_STATE_MAXIMIZED = 4`, que es correcto.

### Impacto futuro

Si alguien usa `GDK_WINDOW_STATE_STICKY` pensando que vale 128, estara
comprobando el bit de FOCUSED, no el de STICKY. Es una trampa para
desarrolladores futuros.

### Correccion propuesta

```reds
;-- GdkWindowState flags (bitmask)
#define GDK_WINDOW_STATE_WITHDRAWN     1
#define GDK_WINDOW_STATE_ICONIFIED     2
#define GDK_WINDOW_STATE_MAXIMIZED     4
#define GDK_WINDOW_STATE_STICKY        8
#define GDK_WINDOW_STATE_FULLSCREEN   16
#define GDK_WINDOW_STATE_ABOVE        32
#define GDK_WINDOW_STATE_BELOW        64
#define GDK_WINDOW_STATE_FOCUSED     128
```

---

## 2. RIESGO EDGE CASE: Doble EVT_SIZE al final de drag-resize

**Archivo:** `modules/view/backends/gtk3/handlers.reds`
**Severidad:** Baja (no ocurre en operacion normal)
**Estado:** REFUTADO en operacion normal; riesgo solo en edge cases

### Descripcion original

Se planteo que `focus-in-event` emitiendo `EVT_SIZE` sincrono y luego
`window-size-allocate` programando otro `EVT_SIZE` via `g_idle_add` podria
causar un doble EVT_SIZE al final de drag-resize.

### Resultado de la refutacion

**En operacion normal NO hay doble EVT_SIZE.** La secuencia de senales GTK3
es: `configure-event` → `size-allocate` → `focus-in-event`. Despues de que
`focus-in-event` limpia los flags, no hay mas `size-allocate` con cambio de
tamano, porque la guarda `if any [sz/x <> w sz/y <> h]` impide programar
el idle callback cuando las dimensiones no cambian.

### Edge cases donde podria ocurrir

1. **Si el `on-resize` del usuario modifica el layout** (ej: `face/size: ...`)
   → GTK reasigna → nuevo `size-allocate` con RESIZING=null → segundo EVT_SIZE
2. **Si GTK reasigna tras FocusIn** (raro: temas, accesibilidad) → mismo efecto
3. **Compositor Wayland entrega FocusIn antes del Configure final** (extremadamente
   improbable pero arquitecturalmente no garantizado)

### Conclusion

Reclasificado de "problema latente" a "riesgo edge case". No requiere
correccion inmediata, pero vale la pena documentarlo como limitacion conocida.

---

## 3. GAP DE SCOPE: Fullscreen tiene el mismo bug que maximize

**Archivo:** `modules/view/backends/gtk3/handlers.reds`, linea 1514
**Severidad:** Media (bug real, latente por falta de soporte fullscreen)
**Estado:** CONFIRMADO tras intento de refutacion

### El problema

El handler `window-state-changed` solo comprueba `GDK_WINDOW_STATE_MAXIMIZED`:

```reds
if event/changed_mask and GDK_WINDOW_STATE_MAXIMIZED <> 0 [
    SET-RESIZING(widget null)
    SET-STARTRESIZE(widget null)
]
```

`GDK_WINDOW_STATE_FULLSCREEN` (valor 16) causa el mismo problema: la ventana
cambia de tamano sin perder foco, los flags no se limpian, y `EVT_SIZE`
no se emite.

### Intento de refutacion

Se investigo si fullscreen podria funcionar diferente que maximize en GTK3:

1. **Fullscreen produce la misma secuencia de senales**: `configure-event` (pone
   RESIZING), `window-state-event` (con FULLSCREEN en changed_mask), `size-allocate`
   (sin limpiar RESIZING). `focus-in-event` NO se dispara.
2. **El fix B (g_idle_add) no ayuda**: Cuando RESIZING esta activo, el path es
   `make-event EVT_SIZING` (sincrono), no el idle path. Solo cuando RESIZING
   es null se toma el idle path. Fullscreen no limpia RESIZING, asi que el
   idle path nunca se alcanza.
3. **No hay otro mecanismo que maneje fullscreen**: Busqueda exhaustiva en
   handlers.reds, events.reds, gui.reds — no hay `GDK_WINDOW_STATE_FULLSCREEN`
   en ningun handler, no hay `gtk_window_fullscreen()` ni `unfullscreen()`,
   no hay manejo de `FACET_FLAGS_FULLSCREEN` en creacion ni actualizacion.

No se pudo refutar. Fullscreen tiene el mismo bug que maximize tenia antes
del fix A.

### Atenuante practico

El backend GTK3 de Red **no implementa fullscreen** actualmente. No hay
forma de que una aplicacion Red entre en fullscreen a traves del backend.
El bug se manifestaria si:
- Se anade soporte de fullscreen en el futuro
- Un window manager externo fuerza fullscreen (ej: via EWMH)

### Correccion propuesta

```reds
if any [
    event/changed_mask and GDK_WINDOW_STATE_MAXIMIZED <> 0
    event/changed_mask and GDK_WINDOW_STATE_FULLSCREEN <> 0
][
    SET-RESIZING(widget null)
    SET-STARTRESIZE(widget null)
]
```

---

## 4. Observaciones menores (no bugs)

### 4.1 `window-state-changed` no comprueba event = null

```reds
window-state-changed: func [
    [cdecl]
    evbox       [handle!]
    event       [GdkEventWindowState!]    ; ← sin null check
    widget      [handle!]
    ...
][
    ; Accede a event/changed_mask sin verificar null
```

Los otros handlers del archivo tampoco comprueban null, asi que es
consistente. Pero si GTK pasa un event null en alguna circunstancia
especial, se produciria un crash. Riesgo bajo.

### 4.2 Posicion del handler `window-state-changed` al final del archivo

El handler se anadio despues de `calendar-changed` (linea 1499), al final
del archivo. No sigue el agrupamiento logico del resto de handlers de
window (que estan en lineas 659-735). Esto dificulta la navegacion.

No es un bug, pero si un problema de organizacion que se agrava con el
tiempo.

### 4.3 `idle-size-allocate` no verifica widget destruido

```reds
idle-size-allocate: func [
    [cdecl]
    widget      [int-ptr!]
    return:     [logic!]
][
    make-event as handle! widget 0 EVT_SIZE   ; ← widget podria estar destruido
    false
]
```

Si la ventana se destruye entre el `g_idle_add` y la ejecucion del
callback, `make-event` operaria sobre un widget destruido. El informe
B defiende esto como seguro ("GTK marca los widgets destruidos como
no-ops"), pero no hay verificacion de que `make-event` maneje este caso.
Riesgo bajo (ventana cerrada durante resize es raro).

### 4.4 Constantes adicionales de GdkWindowState faltantes

GTK3 3.24+ define constantes adicionales que no estan en el codigo:

- `GDK_WINDOW_STATE_TILED = 256`
- `GDK_WINDOW_STATE_TOP_TILED = 512`
- `GDK_WINDOW_STATE_TOP_RESIZABLE = 1024`
- Y 8 mas (RIGHT, BOTTOM, LEFT tiled/resizable)

No son necesarias para el fix actual, pero si se anaden constantes
deberia anadirse el set completo para evitar mas errores en el futuro.

---

## 5. Evaluacion global del codigo

### Lo que esta bien

- La logica de los fixes es correcta y resuelve los bugs reportados
- El patron `g_idle_add` es el correcto segun la documentacion y practicas de GTK
- Solo `EVT_SIZE` se difiere; `EVT_SIZING` permanece sincrono (decision correcta)
- La extension de `change-size` diferencia correctamente `y` vs `sy` por tipo
- `set-buffer` solo se llama para `base`, y internamente comprueba opacidad
- Los diffs son quirurgicos: cambios minimos, bajo riesgo de regresion
- Consistencia con patrones existentes (`g_timeout_add`, `[cdecl]`, etc.)

### Lo que necesita correccion

| # | Problema | Severidad | Accion recomendada |
|---|----------|-----------|-------------------|
| 1 | Constantes GDK_WINDOW_STATE incorrectas | Media | Corregir inmediatamente (cambio trivial) |
| 2 | Fullscreen sin fix | Media | Anadir FULLSCREEN a la comprobacion |
| 3 | Doble EVT_SIZE en drag-resize | Baja | Vigilar si on-resize modifica layout |
| 4.2 | Handler fuera de seccion | Baja | Reubicar cerca de otros window handlers |
| 4.3 | Widget destruido en idle | Baja | Investigar si make-event es seguro con widgets destruidos |

### Prioridad de correccion

1. **Constantes (seccion 1)** — cambio de 2 lineas, sin riesgo, bug factual
2. **Fullscreen (seccion 3)** — cambio de 1 linea, bajo riesgo, bug real
3. **Doble EVT_SIZE (seccion 2)** — no requiere correccion, solo documentar

---

## 6. Evaluacion de la documentacion generada por IA

### Informes tecnicos (BugA y BugB)

- Investigacion exhaustiva con fuentes primarias (commits GTK, documentacion oficial)
- Justificacion de alternativas descartadas
- Verificacion del struct padding con codigo fuente del compilador
- Los informes **no detectaron los tres problemas de codigo anteriores**
- El informe A acepta los tamanos intermedios como "normales" mientras
  que el informe B demuestra que causan las franjas blancas (contradiccion)
- Verificacion de Xfwm4 y KWin marcada como "pendiente" indefinidamente

### Guia de aprendizaje

- Excelente enfoque pedagogico, desde cero
- Analogias adecuadas sin ser condescendientes
- Numeracion de secciones rota a partir de la seccion 6/7/13

### Documento gtk3-resize-bugs.md

- Desactualizado: el codigo propuesto difiere de la implementacion final
- Deberia marcarse como historico o actualizarse

---

## 7. Auditoria cruzada: Bugs similares en Windows y macOS

### 7.1 Windows: Bug A equivalente (EVT_SIZE en maximize/restore)

**NO EXISTE.** Windows usa `WM_SIZE` con `wParam = SIZE_MAXIMIZED` para detectar
maximizacion directamente. El flujo es:

```
WM_SIZE (wParam=SIZE_MAXIMIZED) → make-event EVT_SIZE (siempre)
if win-state=0 OR wParam=SIZE_MAXIMIZED → make-event EVT_SIZE (segundo)
```

`EVT_SIZE` siempre se emite en maximize/restore. No depende del foco.

### 7.2 Windows: Bug B equivalente (repaint de base/panel)

**NO EXISTE** en la misma forma. Windows usa `InvalidateRect` + `WM_PAINT`
que no se ignora dentro de handlers como GTK ignora `queue_resize`.
El buffer Direct2D se redimensiona en `BaseWndProc` WM_SIZE.

Sin embargo, hay un **edge case**: si el render target Direct2D es null
cuando `WM_SIZE` llega al base face, el repaint se salta completamente
(base.reds lineas 497-520). Esto podria ocurrir si el base face se crea
pero nunca se dibuja antes de un maximize.

### 7.3 Windows: Doble EVT_SIZE en maximize/restore (bug real)

**SI EXISTE.** El codigo en events.reds lineas 1355-1364 emite dos
`EVT_SIZE` por maximize/restore:

1. Linea 1355: `make-event current-msg 0 res` → siempre emite EVT_SIZE para WM_SIZE
2. Lineas 1358-1364: segundo `make-event current-msg 0 EVT_SIZE` si
   `win-state = 0 OR wParam = SIZE_MAXIMIZED`

En maximize/restore, `win-state = 0` (no hay WM_ENTERSIZEMOVE), asi que
la condicion es true y se emite un segundo EVT_SIZE.

Esto es identico a lo que se ve en los logs de Windows del informe Bug A:
```
#5 on-resize win:1920x1009 Δ=1320x609   ← primer EVT_SIZE
#6 on-resize win:1920x1009               ← segundo EVT_SIZE
```

**No es un bug critico** (la app recibe resize events, solo uno de mas),
pero es inconsistente con el comportamiento de macOS (que emite un solo
EVT_SIZE al final).

### 7.4 Windows: Fullscreen

**No hay soporte nativo de fullscreen** en el backend Windows. No hay
manejo de `WM_SYSCOMMAND` con `SC_MAXIMIZE` para fullscreen. Si una app
entra en fullscreen via `SetWindowPos`, Windows enviaria `WM_SIZE` con
`SIZE_MAXIMIZED` o `SIZE_RESTORED`, y el handler existente emitiria EVT_SIZE.
No hay bug equivalente al de GTK3.

### 7.5 macOS: Bug A equivalente (EVT_SIZE en maximize/zoom/restore)

**NO EXISTE.** macOS usa dos delegate methods:
- `windowDidResize:` → emite `EVT_SIZING` (durante resize, en cada paso)
- `windowDidEndLiveResize:` → emite `EVT_SIZE` (al final del resize)

Para zoom (el equivalente de maximize en macOS), AppKit llama
`windowDidEndLiveResize:` automaticamente. El zoom de macOS siempre
termina el ciclo de resize con este delegate, asi que `EVT_SIZE` siempre
se emite.

### 7.6 macOS: Bug B equivalente (repaint de base/panel)

**NO EXISTE.** En `change-size` (gui.reds linea 570-571):

```reds
objc_msgSend [hWnd sel_getUid "setFrameSize:" rc/x rc/y]
objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
```

`setNeedsDisplay:YES` marca la vista como necesitada de repintado.
Cocoa programa un `display` automaticamente en el siguiente ciclo del
run loop. No hay problema de "queue_resize ignorado" como en GTK3.

Ademas, macOS usa Core Graphics layers que se redimensionan
automaticamente con la vista. No hay buffer offscreen estatico como
el cairo surface de GTK3.

### 7.7 macOS: Fullscreen

**No hay soporte de fullscreen** en el backend macOS. No hay delegate
methods para `windowWillEnterFullScreen:` o `windowDidExitFullScreen:`.
Si se anadiera soporte de fullscreen, el delegate `windowDidEndLiveResize:`
probablemente se llamaria (AppKit lo hace para transiciones de fullscreen),
asi que `EVT_SIZE` se emitiria correctamente. Pero no esta verificado.

### 7.8 macOS: Observaciones adicionales

- `win-did-resize` (delegate `windowDidResize:`) emite `EVT_SIZING`, no
  `EVT_SIZE`. Esto es correcto: durante resize, se emite `EVT_SIZING`.
- `win-live-resize` (delegate `windowDidEndLiveResize:`) emite `EVT_SIZE`.
  Esto es correcto: al final del resize, se emite el evento final.
- El delegate `windowWillResize:toSize:` esta comentado (linea 99 de
  classes.reds), lo que significa que macOS no limita el tamano de
  resize programaticamente.
- No hay handler para `windowWillUseStandardFullScreenPresentation:`
  ni ninguna transicion de fullscreen.

### 7.9 Tabla comparativa de los tres backends

| Aspecto | GTK3 (con fixes) | Windows | macOS |
|---------|-------------------|---------|-------|
| EVT_SIZE en maximize | Si (via window-state-event + idle) | Si (WM_SIZE directo) | Si (windowDidEndLiveResize) |
| EVT_SIZE en restore | Si (via window-state-event + idle) | Si (WM_SIZE directo) | Si (windowDidEndLiveResize) |
| EVT_SIZE en fullscreen | **NO** (bug latente) | Si (WM_SIZE directo) | No probado (sin soporte) |
| Repaint base/panel | Si (g_idle_add + set-buffer) | Si (InvalidateRect) | Si (setNeedsDisplay) |
| Doble EVT_SIZE en maximize | No (1 o 2 segun GTK) | **Si** (2 eventos) | No (1 evento) |
| Doble EVT_SIZE en restore | No (1 o 2 segun GTK) | **Si** (2 eventos) | No (1 evento) |
| Buffer offscreen estatico | **Era bug B3** (ya corregido) | Direct2D se redimensiona | CoreGraphics se redimensiona |
| queue_resize ignorado | **Era bug B1** (ya corregido) | N/A (message queue) | N/A (run loop) |
| Dependencia del foco | **Era bug A** (ya corregido) | No (WM_SIZE directo) | No (delegate directo) |

### 7.10 Bugs encontrados en otros backends

| Backend | Bug | Severidad | Descripcion |
|---------|-----|-----------|-------------|
| Windows | Doble EVT_SIZE en maximize/restore | Baja | `WM_SIZE` emite dos EVT_SIZE por transicion (lineas 1355 y 1363 de events.reds). No es critico pero es inconsistente con macOS |
| Windows | Base repaint saltado si render target null | Baja | Si Direct2D target no se ha creado cuando WM_SIZE llega, se salta InvalidateRect y update-base (base.reds lineas 497-520) |
| macOS | Sin soporte de fullscreen | Info | No hay delegates para fullscreen; si se anade, probablemente funcionaria via windowDidEndLiveResize |
| macOS | Sin handler para zoom button | Info | No hay manejo especial del boton verde de zoom; AppKit lo maneja automaticamente via windowDidEndLiveResize |

---

**END OF DOCUMENT**