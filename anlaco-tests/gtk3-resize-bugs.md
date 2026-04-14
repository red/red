# GTK3 Resize Bugs — Documentación

Fecha: 2026-04-13
Estado: Documentado, pendiente de corrección

## Contexto general

El backend GTK3 de Red/View tiene defectos en la gestión de resize que
impiden que los widgets `base` con bloques `draw` se repinten correctamente
al maximizar/restaurar la ventana.

Se han identificado 4 bugs interrelacionados (A, B1, B2, B3). Los bugs
B2 y B3 son los más probables de ser la causa raíz visual (franjas blancas),
mientras que el bug A impide que `on-resize` se dispare correctamente.

---

## Bug A: EVT_SIZE no se dispara al maximizar/restaurar

**Síntoma**: `on-resize` solo se dispara tras un cambio de foco (Alt+Tab),
no directamente al maximizar/restaurar la ventana.

**Causa**: El backend GTK3 usa `window-configure-event` para marcar el
flag `RESIZING` y `window-size-allocate` para disparar `EVT_SIZING` mientras
el flag esté activo. El flag solo se limpia en `focus-in-event`. Al
maximizar/restaurar, la ventana no pierde el foco, así que `focus-in-event`
no se dispara y el flag `RESIZING` nunca se limpia.

**Flujo actual (buggy)**:
```
configure-event → SET-RESIZING
size-allocate → GET-RESIZING != null → EVT_SIZING (no EVT_SIZE)
[...no focus change...]
→ on-resize NUNCA se ejecuta hasta Alt+Tab
```

**Flujo correcto (Windows y macOS)**:
- Windows: `WM_SIZE` con `wParam = SIZE_MAXIMIZED` dispara `EVT_SIZE`
  inmediatamente. También `WM_EXITSIZEMOVE` para drag-resize.
- macOS: `windowDidResize:` se dispara en cada paso (incluido maximize),
  y AppKit redibuja automáticamente via `drawRect:`.

**Log de Windows (referencia)** — maximize/restaura sin eventos de foco:
```
#5 on-resize win:1920x1009 Δ=1320x609   ← maximizar: EVT_SIZE directo
#6 on-resize win:1920x1009
#7 on-resize win:600x400 Δ=-1320x-609   ← restaurar: EVT_SIZE directo
#8 on-resize win:600x400
```

**Log de Linux (buggy)** — maximize/restaura SIN nuestros fixes:
```
#5 on-resize win:1464x804 Δ=864x404     ← EVT_SIZING (no EVT_SIZE)
#6 on-resize win:1366x706 Δ=-98x-98
#7 on-resize win:502x302 Δ=-864x-404    ← tamaño intermedio incorrecto
#8 on-resize win:600x400 Δ=98x98
#9 on-unfocus win:600x400                 ← necesita cambio de foco
...
```

**Log de Linux (con fix Bug A, fix v1)** — EVT_SIZE Correcto, PERO sin repintado:
```
#5 on-resize win:1464x804 Δ=864x404     ← on-resize se dispara correctamente
#6 on-resize win:1366x706 Δ=-98x-98
#7 on-resize win:502x302 Δ=-864x-404    ← tamaño intermedio
#8 on-resize win:600x400 Δ=98x98        ← tamaño final correcto
```

**Solución**: Conectar la señal `"window-state-event"` de GTK3 con un handler
que detecte `GDK_WINDOW_STATE_MAXIMIZED` o `GDK_WINDOW_STATE_FULLSCREEN` y limpie los flags `RESIZING` y
`STARTRESIZE`, permitiendo que el siguiente `size-allocate` dispare `EVT_SIZE`.

**Handler propuesto** (`handlers.reds`):
```reds
window-state-changed: func [
    [cdecl]
    evbox       [handle!]
    event       [GdkEventWindowState!]
    widget      [handle!]
    return:     [integer!]
][
    if any [
        event/changed_mask and GDK_WINDOW_STATE_MAXIMIZED <> 0
        event/changed_mask and GDK_WINDOW_STATE_FULLSCREEN <> 0
    ][
        SET-RESIZING(widget null)
        SET-STARTRESIZE(widget null)
    ]
    EVT_DISPATCH
]
```

**Conexión de señal** (`events.reds`):
```reds
gobj_signal_connect(widget "window-state-event" :window-state-changed widget)
```

**Bindings necesarios** (`gtk.reds`):
```reds
GdkEventWindowState!: alias struct! [
    type            [integer!]
    window          [handle!]
    send_event      [byte!]
    changed_mask    [integer!]
    new_window_state [integer!]
]

GDK_WINDOW_STATE_MAXIMIZED: 4
GDK_WINDOW_STATE_FULLSCREEN: 16
```

**Archivos afectados**:
- `modules/view/backends/gtk3/events.reds` — conectar señal
- `modules/view/backends/gtk3/handlers.reds` — handler `window-state-changed`
- `modules/view/backends/gtk3/gtk.reds` — struct + constante

---

## Bug B1: `gtk_widget_queue_resize()` se ignora dentro de `size-allocate`

**Síntoma**: Tras `on-resize`, el hijo `base` no se realoca al nuevo tamaño.

**Causa**: La [documentación de GTK3](https://docs.gtk.org/gtk3/method.Widget.queue_resize.html)
indica que las llamadas a `gtk_widget_queue_resize()` desde dentro de un
handler `size-allocate` se **ignoran silenciosamente**.

Cuando `on-resize` del usuario ejecuta `canvas/size: ...` → `change-size` →
`gtk_widget_set_size_request()` + `gtk_widget_queue_resize()`, la llamada a
`queue_resize` cae dentro del handler `window-size-allocate` (ya que
`make-event` es síncrono). GTK ignora la petición de resize.

**Flujo actual (buggy)**:
```
window-size-allocate (GTK signal handler activo)
  └─ make-event EVT_SIZE (síncrono)
       └─ on-resize del usuario
            └─ canvas/size: ...
                 └─ change-size
                      └─ gtk_widget_set_size_request() ← OK
                      └─ gtk_widget_queue_resize()     ← IGNORADO
  └─gtk_widget_queue_draw(cont)          ← el hijo sigue al tamaño viejo
  └─ gdk_window_process_all_updates()    ← no sirve, hijo no realocado
```

**Posible solución**: Diferir el `make-event EVT_SIZE` fuera del handler
`size-allocate`, usando un mecanismo como `g_idle_add` o similar.

**NOTA**: Este bug puede no necesitar solución directa si los bugs B2 y B3
se corrigen, ya que el repintado no dependería del realoque del hijo por
parte de GTK.

**Archivos afectados**:
- `modules/view/backends/gtk3/handlers.reds` — `window-size-allocate`

---

## Bug B2: `gtk_layout_set_size()` nunca se llama para `base` en `change-size`

**Síntoma**: Tras resize, el área de dibujo del `base` se queda con
tamaño stale. Aparecen franjas blancas en los bordes derecho e inferior.

**Causa**: El widget `base` es un `GtkLayout`. En la creación se llama
`gtk_layout_set_size widget sx sy` (gui.reds:1918), pero en `change-size`
solo se llama para `rich-text` (gui.reds:1036-1037) — **NO para `base`**.

`GtkLayout` tiene un tamaño lógico interno (el área de desplazamiento)
independiente del tamaño asignado. Si no se actualiza, el layout interno
se queda al tamaño viejo y el draw signal puede no emitirse para las áreas
fuera del tamaño lógico viejo.

**Código actual (buggy)** en `change-size` (gui.reds:1036-1040):
```reds
if type = rich-text [
    gtk_layout_set_size widget sx y          ; ← solo para rich-text
]
gtk_widget_set_size_request widget sx sy
gtk_widget_queue_resize widget
```

**Código corregido**:
```reds
if any [type = rich-text type = base type = panel][
    gtk_layout_set_size widget sx y
]
gtk_widget_set_size_request widget sx sy
gtk_widget_queue_resize widget
```

**Archivos afectados**:
- `modules/view/backends/gtk3/gui.reds` — `change-size` (~línea 1036)

---

## Bug B3: `set-buffer` nunca se llama para `base` tras resize

**Síntoma**: Tras restaurar de maximizado, el canvas se redibuja pero con
tamaño incorrecto — aparece con el tamaño maximizado, con franjas blancas
a la derecha y abajo.

**Causa**: En la creación del `base`, se llama `set-buffer widget sx sy color`
(gui.reds:1919) que crea un `cairo_image_surface_create CAIRO_FORMAT_ARGB32 x y`.
Este buffer offscreen se usa en `base-draw` (handlers.reds:316-323) para
renderizar el contenido del `base` cuando tiene transparencia.

En `base-draw`, el flujo es:
```reds
buf: GET-BASE-BUFFER(widget)               ; buffer al tamaño ORIGINAL
cr: cairo_create buf                        ; contexto cairo sobre buffer viejo
cairo_set_operator cr CAIRO_OPERATOR_CLEAR
cairo_paint cr                              ; limpia buffer viejo (tamaño original)
cairo_set_operator cr CAIRO_OPERATOR_OVER
; ... dibuja en cr (buffer viejo) ...
cairo_set_source_surface draw-cr buf 0.0 0.0 ; compone buffer viejo sobre pantalla
cairo_paint draw-cr
cairo_destroy cr
```

Si el `base` creció (maximizar), el buffer es más pequeño que el widget →
las áreas fuera del buffer se quedan transparentes/blancas.

Si el `base` se redujo (restaurar), el buffer es más grande que el widget →
no es tan visible pero desperdicia memoria.

**Solución**: En `change-size`, para tipo `base`, llamar `set-buffer` con el
nuevo tamaño. Esto recrea el buffer cairo al tamaño correcto.

**Código corregido** (en `change-size`, después de `gtk_widget_set_size_request`):
```reds
if any [type = rich-text type = base type = panel][
    gtk_layout_set_size widget sx y
]
if type = base [
    set-buffer widget sx sy as red-tuple! (get-face-values widget) + FACE_OBJ_COLOR
    gtk_widget_queue_draw widget
]
gtk_widget_set_size_request widget sx sy
gtk_widget_queue_resize widget
```

**NOTA**: `set-buffer` comprueba internamente `transparent-base? color` —
si el color NO es transparente, sale sin hacer nada (no crea buffer).
Solo crea buffer para bases con color transparente o sin color.

**Función `set-buffer`** (gui.reds:1789-1804):
```reds
set-buffer: func [
    widget  [handle!]
    x       [integer!]
    y       [integer!]
    color   [red-tuple!]
    /local
        buf [handle!]
][
    unless transparent-base? color [exit]      ; ← sale si color opaco

    buf: GET-BASE-BUFFER(widget)
    if buf <> null [cairo_surface_destroy buf]  ; ← destruye buffer viejo

    buf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 x y
    SET-BASE-BUFFER(widget buf)
]
```

**Función `transparent-base?`** (handlers.reds:415-426):
```reds
transparent-base?: func [
    color   [red-tuple!]
    return: [logic!]
][
    either all [
        TYPE_OF(color) = TYPE_TUPLE
        any [
            TUPLE_SIZE?(color) = 3               ; RGB sin alfa = opaco
            color/array1 and FF000000h <> FF000000h ; alfa != 255 = transparente
        ]
    ][false][true]                               ; no color o con alfa = transparente
]
```

**Archivos afectados**:
- `modules/view/backends/gtk3/gui.reds` — `change-size` (~línea 1040)

---

## Comparación con otros backends

| Aspecto | Windows | macOS | GTK3 (actual) |
|---------|---------|-------|---------------|
| EVT_SIZE al maximizar | `WM_SIZE` + `SIZE_MAXIMIZED` → EVT_SIZE inmediato | `windowDidResize:` → EVT_SIZING continuo; AppKit redibuja solito | Solo EVT_SIZING; EVT_SIZE solo vía focus-in-event |
| Forzar repintado | `InvalidateRect(hWnd, null, 1)` → WM_PAINT inmediato | `setNeedsDisplay: yes` → drawRect: automático | `gtk_widget_queue_draw` no funciona dentro de size-allocate |
| Layout interno | No aplica (GDI/D2D) | No aplica (Core Graphics) | `gtk_layout_set_size` NO se llama para `base` tras resize |
| Buffer offscreen | D2D render target se redimensiona en `update-base` | CoreGraphics layer se redimensiona automáticamente | Buffer cairo NUNCA se redimensiona tras creación |

---

## Archivos relevantes del backend GTK3

| Archivo | Funciones/elementos relevantes | Línea aprox. |
|---------|-------------------------------|--------------|
| `modules/view/backends/gtk3/gtk.reds` | `GdkEventWindowState!` (añadir), `GDK_WINDOW_STATE_MAXIMIZED` (añadir) | — |
| `modules/view/backends/gtk3/handlers.reds` | `window-size-allocate`, `window-configure-event`, `focus-in-event`, `window-state-changed` (añadir), `base-draw`, `transparent-base?` | 415, 659, 697, 1062 |
| `modules/view/backends/gtk3/events.reds` | `connect-signals` (sección window), `do-events` | 1086, 842 |
| `modules/view/backends/gtk3/gui.reds` | `change-size`, `set-buffer`, `OS-make-view` (creación de base), `OS-update-view` | 990, 1789, 1916, 2191 |

---

## Plan de ataque (orden recomendado)

1. **Corregir Bug A** — Añadir `window-state-event` handler
   - Añadir `GdkEventWindowState!` y `GDK_WINDOW_STATE_MAXIMIZED` en `gtk.reds`
   - Crear handler `window-state-changed` en `handlers.reds`
   - Conectar señal en `events.reds`
   - Verificar con test A

2. **Corregir Bugs B2+B3** — Actualizar `change-size` para `base`
   - Añadir `gtk_layout_set_size` para `base` y `panel`
   - Añadir `set-buffer` para `base`
   - Añadir `gtk_widget_queue_draw` para `base`
   - Verificar con tests B y D

3. **Evaluar Bug B1** — Si B2+B3 resuelven el dibujado, B1 puede no
   necesitar fix. Si persiste, considerar diferir `make-event EVT_SIZE`
   fuera de `size-allocate`.

4. **Test de regresión** — Maximizar + restaurar + drag-resize + focus

---

## Tests interactivos

Todos en `anlaco-tests/`. Cada test es un script `.red` independiente
con `Needs: 'View`. Compilar con:
```
./rebol -qws red.r "-c %anlaco-tests/<test>.red"
```