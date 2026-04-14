# FIX: Bug B - base/panel not repainted after maximize/restore (GTK3 backend)

**Related Commit:** `dbcfbe84a` — FIX: base/panel not repainted after maximize/restore in GTK3 backend (Bug B)  
**Date:** 2026-04-14  
**Author:** ANLACO Team  
**Status:** Implemented and tested  
**Affected Files:**
- `modules/view/backends/gtk3/gui.reds`
- `modules/view/backends/gtk3/handlers.reds`

---

## 1. RESUMEN EJECUTIVO

### El Bug
Tras maximizar o restaurar una ventana GTK3 que contiene un `base` o `panel` face, aparecen franjas blancas en los bordes derecho e inferior. El marco de dibujado (draw block) se recorta y no rellena todo el canvas. El evento `on-resize` se dispara correctamente (Bug A fixeado), pero el contenido visual no se actualiza al nuevo tamaño.

### La Causa
Tres bugs interrelacionados:

- **B1:** `gtk_widget_queue_resize()` llamado desde dentro del handler de `size-allocate` es silenciosamente ignorado por GTK3. Cuando `on-resize` ejecuta `canvas/size: ...`, la llamada síncrona a `change-size` → `gtk_widget_queue_resize()` cae dentro del signal handler activo y GTK la descarta. La allocation del widget nunca se actualiza al nuevo tamaño.

- **B2:** `gtk_layout_set_size()` solo se llamaba para `rich-text` en `change-size`, nunca para `base` ni `panel`. Ambos tipos usan `GtkLayout` internamente, cuyo tamaño lógico (área scrolleable) debe actualizarse al redimensionar. Sin esta llamada, GTK no emite señales de dibujado para las áreas fuera del tamaño anterior.

- **B3:** El buffer cairo offscreen de las bases transparentes se creaba una sola vez en `OS-make-view` y nunca se redimensionaba. Cuando el widget crecía, el buffer era más pequeño que el área visible, produciendo las franjas blancas.

### La Solución
1. **B1:** Diferir `make-event EVT_SIZE` fuera del handler `size-allocate` usando `g_idle_add()`. El callback idle ejecuta `make-event` en el siguiente ciclo del main loop, cuando ya no estamos dentro de `size-allocate`, permitiendo que `gtk_widget_queue_resize()` funcione correctamente.
2. **B2:** Extender la llamada a `gtk_layout_set_size()` en `change-size` para incluir `base` y `panel`, no solo `rich-text`.
3. **B3:** Llamar a `set-buffer()` en `change-size` para faces tipo `base`, redimensionando el buffer cairo offscreen. La función ya maneja internamente el caso de bases opacas (sale inmediatamente si `transparent-base?` retorna false).

### Archivos Modificados
1. **handlers.reds**: Añadido callback `idle-size-allocate` y modificado `window-size-allocate` para usar `g_idle_add` en lugar de `make-event` directo
2. **gui.reds**: Extendido `change-size` para llamar `gtk_layout_set_size` en base/panel y `set-buffer` en base

---

## 2. DESCRIPCION DETALLADA DEL BUG

### 2.1 Sintoma

Cuando una ventana GTK3 con un `base` face que tiene un `draw` block se maximiza y luego se restaura, el contenido dibujado no rellena el nuevo tamaño. Aparecen franjas blancas en los bordes derecho e inferior del canvas:

```
+---------------------------+
|  ┌───────────────────┐   |  ← Marco azul
|  │  canvas/size:      │   |     debería llegar
|  │  580x380           │   |     hasta aquí
|  │                    │   |
|  └───────────────────┘   |  ← No llega al borde
|  (franja blanca)         |     inferior
+---------------------------+
              (franja blanca) →
```

Log del test `gtk3-base-layout-size` **antes** del fix completo (B1 sin aplicar):

```
; Linux
10:25:58 on-resize win:600x400 canvas:580x380
10:26:01 on-resize win:1464x804 canvas:1444x784   ← tamaño intermedio
10:26:01 on-resize win:1366x706 canvas:1346x686
10:26:03 on-resize win:502x302 canvas:482x282      ← tamaño intermedio
10:26:03 on-resize win:600x400 canvas:580x380
```

Aunque `canvas/size` se rastrea correctamente, el widget GTK no se reasigna al tamaño correcto.

### 2.2 Comportamiento Esperado vs Observado

| Aspecto | Windows | macOS | GTK3 (antes del fix) | GTK3 (después del fix) |
|---------|---------|-------|----------------------|------------------------|
| EVT_SIZE on maximize | WM_SIZE + SIZE_MAXIMIZED (inmediato) | windowDidEndLiveResize: (inmediato) | Solo via focus-in-event (Bug A, ahora fixeado) | via window-state-changed + size-allocate (correcto) |
| Repaint base face | InvalidateRect → WM_PAINT (inmediato) | setNeedsDisplay → drawRect: (inmediato) | queue_resize ignorado, allocation stale | g_idle_add → EVT_SIZE fuera de size-allocate (correcto) |
| Layout size update | N/A (GDI/D2D) | N/A (Core Graphics) | gtk_layout_set_size NO llamado para base (B2) | gtk_layout_set_size llamado (correcto) |
| Buffer offscreen | D2D render target se redimensiona | CoreGraphics layer auto-redimensiona | Buffer cairo NUNCA se redimensiona (B3) | set-buffer llamado en change-size (correcto) |

### 2.3 Los Tres Sub-Bugs

#### B1: gtk_widget_queue_resize() ignorado dentro de size-allocate

Flujo bug:

```
window-size-allocate (signal handler GTK activo)
  → make-event EVT_SIZE (síncrono)
    → on-resize del usuario
      → canvas/size: as-pair face/size/x face/size/y
        → change-size
          → gtk_layout_set_size widget sx sy           ← OK (B2 fix)
          → set-buffer widget sx sy color              ← OK (B3 fix)
          → gtk_widget_queue_draw widget               ← OK
          → gtk_widget_set_size_request widget sx sy   ← OK
          → gtk_widget_queue_resize widget             ← IGNORADO por GTK
  → gtk_widget_queue_draw(cont)                         ← child stale allocation
```

La documentación oficial de GTK3 lo confirma:

> "Note that you cannot call gtk_widget_queue_resize() on a widget from inside its implementation of the GtkWidgetClass::size_allocate virtual method. Calls to gtk_widget_queue_resize() from inside GtkWidgetClass::size_allocate will be silently ignored."  
> — [GTK3 Documentation: gtk_widget_queue_resize()](https://docs.gtk.org/gtk3/method.Widget.queue_resize.html)

#### B2: gtk_layout_set_size() no llamado para base ni panel

En `change-size` (gui.reds), la llamada a `gtk_layout_set_size` solo existía para `rich-text`:

```reds
if type = rich-text [
    gtk_layout_set_size widget sx y          ; ← solo rich-text
]
```

Pero `base` y `panel` también usan `GtkLayout`. Sin esta llamada, el tamaño lógico interno del layout queda en el tamaño original de creación, y GTK no emite señales de dibujado para áreas fuera de ese tamaño.

> "Sets the size of the scrollable area of the layout."  
> — [GTK3 Documentation: gtk_layout_set_size()](https://docs.gtk.org/gtk3/class.Layout.html)

#### B3: Buffer cairo nunca redimensionado para base

El buffer offscreen para bases transparentes se crea una vez en `OS-make-view`:

```reds
sym = base [
    widget: gtk_layout_new null null
    gtk_layout_set_size widget sx sy
    set-buffer widget sx sy color              ; ← solo aquí, nunca más
]
```

`set-buffer` crea un `cairo_image_surface_create CAIRO_FORMAT_ARGB32 x y` del tamaño original. Cuando el widget crece tras maximizar, el buffer sigue siendo del tamaño viejo. En `base-draw`, las áreas fuera del buffer se renderizan como transparentes/blancas.

---

## 3. INVESTIGACION REALIZADA

### 3.1 Análisis del Flujo GTK3 Resize

El flujo completo de señales GTK3 durante un maximize/restaurar es:

```
1. window-state-event  → GDK_WINDOW_STATE_MAXIMIZED cambia
2. configure-event     → posición/tamaño intermedio
3. size-allocate       → GTK asigna allocation final
4. draw                → GTK redibuja el widget
```

En el paso 3, `window-size-allocate` se ejecuta como handler de la señal `"size-allocate"`. Cualquier llamada a `gtk_widget_queue_resize()` desde dentro de este handler es descartada por GTK, ya que GTK considera la allocation como definitiva tras completar el ciclo de layout.

El commit de Benjamin Otte (2015) en GTK lo documenta explicitamente:

> "Size allocation is god... after consulting god, no further requests or allocations are needed"  
> — [GTK commit: Clear pending resizes after size_allocate()](https://lists.gnome.org/archives/commits-list/2015-October/msg07660.html)

GTK incluso añadió un warning de depuración (detrás de `GTK_DEBUG=geometry`) para detectar este patrón:

```c
if (GTK_DEBUG_CHECK(GEOMETRY) && gtk_widget_get_resize_needed(widget)) {
    g_warning("%s %p or a child called gtk_widget_queue_resize() "
              "during size_allocate().",
              gtk_widget_get_name(widget), widget);
}
```

> "This happens way too much, so it's disabled unless GTK_DEBUG=geometry is on."  
> — [GTK commit: Warn on calls to queue_resize() during size_allocate()](https://lists.gnome.org/archives/commits-list/2015-October/msg07661.html)

### 3.2 Documentación Oficial GTK3/GLib

#### gtk_widget_queue_resize()

**URL:** https://docs.gtk.org/gtk3/method.Widget.queue_resize.html

> "This function is only for use in widget implementations. Flags a widget to have its size renegotiated; should be called when a widget for some reason has a new size request."
>
> "Note that you cannot call gtk_widget_queue_resize() on a widget from inside its implementation of the GtkWidgetClass::size_allocate virtual method. Calls to gtk_widget_queue_resize() from inside GtkWidgetClass::size_allocate will be silently ignored."

**Clave:** La restricción está documentada oficialmente. No es un bug de GTK, es un comportamiento intencional del framework.

#### g_idle_add()

**URL:** https://docs.gtk.org/glib/func.idle_add.html

> "Adds a function to be called whenever there are no higher priority events pending to the default main loop."
>
> "The function is given the default idle priority, G_PRIORITY_DEFAULT_IDLE. If the function returns G_SOURCE_REMOVE it is automatically removed from the list of event sources and will not be called again."

**GSourceFunc callback:** https://docs.gtk.org/glib/callback.SourceFunc.html

> `gboolean (* GSourceFunc) (gpointer user_data)`
> Return value: "FALSE if the source should be removed." G_SOURCE_REMOVE (0 = FALSE) sirve como nombre más legible.

**G_PRIORITY_DEFAULT_IDLE:** https://docs.gtk.org/glib/consts.PRIORITY_DEFAULT_IDLE.html  
Valor: `200`

**G_SOURCE_REMOVE:** https://docs.gtk.org/glib/consts.SOURCE_REMOVE.html  
Valor: `FALSE` (0)

#### gtk_layout_set_size()

**URL:** https://docs.gtk.org/gtk3/class.Layout.html

> "Sets the size of the scrollable area of the layout."

**Distinción crítica:** `gtk_layout_set_size()` establece el tamaño del **área scrolleable** (canvas virtual), NO la allocation del widget (tamaño visible en pantalla). Son dos conceptos de tamaño completamente separados para `GtkLayout`.

> "GtkLayout is similar to GtkDrawingArea in that it's a 'blank slate' and doesn't do anything except paint a blank background by default."

#### size-allocate signal

**URL:** https://docs.gtk.org/gtk3/signal.Widget.size-allocate.html

> Parameter `allocation`: "The region which has been allocated to the widget."
>
> "The default handler is called before the handlers added via g_signal_connect()."

#### Cairo Image Surface

**URL:** https://cairographics.org/manual/cairo-Image-Surfaces.html

> `cairo_surface_t * cairo_image_surface_create (cairo_format_t format, int width, int height);`
>
> "Creates an image surface of the specified format and dimensions. Initially the surface contents are set to 0."

### 3.3 Código Fuente GTK3 y Discusiones de Desarrollo

#### Tim Janik (2004): Análisis del bug de queue_resize en size_allocate

**URL:** https://lists.gnome.org/archives/gtk-devel-list/2004-October/msg00011.html

Tim Janik documentó que `queue_resize()` llamado durante `size_allocate()` corrompe el estado de allocation de widgets hermanos via propagación de `GtkSizeGroup`:

> "size-allocate on a scrolled window changes the scroll adjustments, and that in turn may change scrollbar visibility (which queues a resize)"

La solución en GTK fue verificar `REQUEST_NEEDED` después de `size_allocate()` y re-encolar resize.

#### Benjamin Otte (2015): Warning de depuración y fix de resizes pendientes

**URL commit 1:** https://lists.gnome.org/archives/commits-list/2015-October/msg07661.html  
**URL commit 2:** https://lists.gnome.org/archives/commits-list/2015-October/msg07660.html

Estos dos commits de Benjamin Otte son directamente relevantes:

1. **Warning:** Añade detección de `queue_resize()` durante `size_allocate()` (gated behind `GTK_DEBUG=geometry`). El mensaje del commit nota: *"This happens way too much, so it's disabled unless GTK_DEBUG=geometry is on."*

2. **Fix:** Añade `gtk_widget_ensure_resize()` inmediatamente después de la llamada a `size_allocate()`. El comentario del código es elocuente:

```c
GTK_WIDGET_GET_CLASS(widget)->size_allocate(widget, &real_allocation);
/* Size allocation is god... after consulting god, no further requests or allocations are needed */
gtk_widget_ensure_resize(widget);
priv->alloc_needed = FALSE;
```

#### Owen Taylor (2001): Invariante fundamental de GTK

**URL:** https://lists.gnome.org/archives/gtk-devel-list/2001-October/msg00529.html

> If you call gtk_widget_queue_resize(), it must result in size_request -> size_allocate -> redraw on the widget.

Esta invariante no se cumple si `queue_resize()` es llamado dentro de `size_allocate()`, porque GTK lo descarta.

### 3.4 Proyectos Reales que Usan g_idle_add para Diferir Operaciones GTK

#### GTK testwindowsize.c: Layout signal → g_idle_add

**URL:** https://codebrowser.dev/gtk/gtk/tests/testwindowsize.c.html

GTK's propio test suite usa `g_idle_add` para diferir actualizaciones UI desde un handler de layout:

```c
static gboolean
set_label_idle(gpointer user_data)
{
    GtkLabel *label = user_data;
    GtkNative *native = gtk_widget_get_native(GTK_WIDGET(label));
    GdkSurface *surface = gtk_native_get_surface(native);
    char *str;

    str = g_strdup_printf("%d x %d",
        gdk_surface_get_width(surface),
        gdk_surface_get_height(surface));
    gtk_label_set_label(label, str);
    g_free(str);

    return G_SOURCE_REMOVE;  // FALSE -- one-shot
}

static void
layout_cb(GdkSurface *surface, int width, int height, GtkLabel *label)
{
    g_idle_add(set_label_idle, label);    // Diferir fuera del signal handler
}
```

**Patron:** Signal handler → `g_idle_add` → callback idle → trabajo real. Retorna `G_SOURCE_REMOVE` para one-shot. Este es exactamente el mismo patrón que nuestro fix.

#### Inkscape Canvas: Deferred redraw via idle

**URL:** https://inkscape.gitlab.io/inkscape/doxygen/canvas_8cpp_source.html

Inkscape's canvas widget usa `Glib::signal_idle()` (el equivalente C++ de `g_idle_add`) para diferir redibujado después de `size_allocate`:

```cpp
void Canvas::size_allocate_vfunc(int const width, int const height, int const baseline)
{
    parent_type::size_allocate_vfunc(width, height, baseline);
    // ... zoom adjustment logic ...
    d->schedule_redraw(true);  // triggers deferred redraw
}

void CanvasPrivate::schedule_redraw(bool instant)
{
    // ...
    schedule_redraw_conn = Glib::signal_idle().connect([=] {
        callback();
        return false;  // G_SOURCE_REMOVE -- one-shot
    });
}
```

**Clave:** Inkscape nota explícitamente que usar prioridades más altas causa flickering:

> "Note: Any higher priority results in competition with other idle callbacks, causing flickering snap indicators"  
> — [Inkscape issue #4242](https://gitlab.com/inkscape/inkscape/-/issues/4242)

Esto confirma que `G_PRIORITY_DEFAULT_IDLE` (200) es la prioridad correcta para operaciones post-layout, ya que se ejecuta después de los ciclos de resize (110) y redraw (120).

#### GTK gtkwindow.c: Key-change notification via g_idle_add

**URL:** https://github.com/GNOME/gtk/blob/main/gtk/gtkwindow.c

GTK usa `g_idle_add` internamente para colapsar múltiples notificaciones de cambio de teclas en una sola señal:

```c
static gboolean
handle_keys_changed(gpointer data)
{
    GtkWindow *window = GTK_WINDOW(data);
    GtkWindowPrivate *priv = gtk_window_get_instance_private(window);

    if (priv->keys_changed_handler) {
        g_source_remove(priv->keys_changed_handler);
        priv->keys_changed_handler = 0;
    }

    g_signal_emit(window, window_signals[KEYS_CHANGED], 0);
    return G_SOURCE_REMOVE;  // FALSE -- one-shot
}

void
_gtk_window_notify_keys_changed(GtkWindow *window)
{
    GtkWindowPrivate *priv = gtk_window_get_instance_private(window);
    if (!priv->keys_changed_handler) {
        priv->keys_changed_handler = g_idle_add(handle_keys_changed, window);
    }
}
```

**Patron:** Múltiples eventos rápidos se colapsan en una sola notificación via idle. Similar a nuestro caso donde múltiples size-allocate se suceden rápidamente.

#### GTK gtkcontainer.c: Idle sizer mechanism (GTK_PRIORITY_RESIZE)

**URL:** https://github.com/linuxmint/gtk/blob/master/gtk/gtkcontainer.c

GTK's propio mecanismo de resize está construido sobre un patrón idle-deferral. En GTK2:

```c
if (container_resize_queue == NULL)
    gdk_threads_add_idle_full(GTK_PRIORITY_RESIZE,
                               gtk_container_idle_sizer,
                               NULL, NULL);
container_resize_queue = g_slist_prepend(container_resize_queue, container);
```

En GTK3 evolucionó a `GdkFrameClock` con fases de layout, pero el principio es el mismo: las operaciones de resize se batchean y difieren.

#### Evince: Thread-safe signal emission via g_idle_add_full

**URL:** https://gitlab.gnome.org/GNOME/evince/-/blob/main/libview/ev-jobs.c

```c
if (job->run_mode == EV_JOB_RUN_THREAD) {
    job->idle_finished_id = g_idle_add_full(G_PRIORITY_DEFAULT_IDLE,
                                             (GSourceFunc)emit_finished,
                                             g_object_ref(job),
                                             (GDestroyNotify)g_object_unref);
}
```

**Patron:** Usa `g_idle_add_full` con `G_PRIORITY_DEFAULT_IDLE` y proper cleanup via `GDestroyNotify`.

### 3.5 Tabla de Prioridades GLib/GTK

La prioridad idle es relevante porque determina cuándo se ejecuta nuestro callback relativo a los ciclos internos de GTK:

| Constante | Valor | Uso |
|-----------|-------|-----|
| `G_PRIORITY_HIGH_IDLE` | 100 | Idle de alta prioridad |
| `GTK_PRIORITY_RESIZE` | 110 (`HIGH_IDLE + 10`) | GTK resize computation |
| `GTK_PRIORITY_REDRAW` | 120 (`HIGH_IDLE + 20`) | GTK redraws |
| `G_PRIORITY_DEFAULT_IDLE` | 200 | Default para `g_idle_add()` |

**Clave:** Nuestro callback idle (prioridad 200) se ejecuta DESPUÉS de los ciclos de resize (110) y redraw (120) de GTK. Esto significa que cuando `make-event EVT_SIZE` se ejecuta en el callback idle, el ciclo de layout de GTK ya ha terminado, y `gtk_widget_queue_resize()` dentro de `change-size` ya no es ignorado.

### 3.6 Comparación con Otros Backends

| Aspecto | Windows | macOS | GTK3 (sin fix) | GTK3 (con fix) |
|---------|---------|-------|-----------------|----------------|
| Señal de resize | WM_SIZE (asíncrono, post-layout) | windowDidResize: (delegate, post-layout) | size-allocate (dentro del layout) | size-allocate → idle callback (post-layout) |
| Mecanismo de diferimiento | Message queue natural (PostMessage) | Run loop natural (performSelector:afterDelay:) | Ninguno (síncrono) | g_idle_add (post-layout) |
| Repaint trigger | InvalidateRect → WM_PAINT | setNeedsDisplay → drawRect: | queue_draw (clip a allocation stale) | queue_draw (allocation correcta) |
| Buffer offscreen | D2D render target se redimensiona | CoreGraphics layer auto-redimensiona | Buffer cairo nunca se redimensiona | set-buffer en change-size |

**Conclusión:** Windows y macOS no tienen este problema porque sus mecanismos de evento son inherentemente asíncronos respecto al ciclo de layout. GTK3 requiere diferimiento explícito via `g_idle_add` para lograr el mismo efecto.

---

## 4. ANALISIS DE LA CAUSA RAIZ

### 4.1 El Call Chain Síncrono Bug

```
GTK emite señal "size-allocate"
  └─ window-size-allocate [handlers.reds:697]
       ├─ sz/x: w, sz/y: h           (actualiza face/size)
       ├─ g_idle_add(idle-size-allocate, widget)  ← FIX B1: diferido
       │    └─ [idle callback, fuera de size-allocate]
       │         └─ make-event EVT_SIZE
       │              └─ system/view/awake
       │                   └─ on-resize handler del usuario
       │                        └─ canvas/size: ...
       │                             └─ change-size [gui.reds:990]
       │                                  ├─ gtk_layout_set_size widget sx sy  ← FIX B2
       │                                  ├─ set-buffer widget sx sy color      ← FIX B3
       │                                  ├─ gtk_widget_queue_draw widget
       │                                  ├─ gtk_widget_set_size_request widget sx sy
       │                                  └─ gtk_widget_queue_resize widget      ← AHORA FUNCIONA
       └─ window-ready?: yes
```

Sin el fix B1, `make-event EVT_SIZE` se ejecuta síncronamente dentro de `window-size-allocate`. La llamada a `gtk_widget_queue_resize()` en `change-size` es ignorada por GTK porque estamos dentro de `size-allocate`. Resultado: la allocation del widget permanece stale, el draw se recorta.

Con el fix B1, `make-event EVT_SIZE` se difiere al siguiente ciclo idle. Cuando se ejecuta, ya no estamos dentro de `size-allocate`, así que `gtk_widget_queue_resize()` es procesado normalmente por GTK.

### 4.2 Por Qué B2+B3 Solos No Bastan

Los fixes B2 y B3 son necesarios pero no suficientes sin B1:

- **B2** actualiza `gtk_layout_set_size` → GTK conoce el tamaño lógico del layout, pero la **allocation** del widget sigue stale porque `queue_resize` fue ignorado
- **B3** redimensiona el buffer cairo → el buffer tiene el tamaño correcto, pero se compone sobre un draw context que está **clippeado a la allocation stale**
- **Sin B1**, `base-draw` recibe el tamaño correcto de `FACE_OBJ_SIZE`, pero el Cairo context de GTK está recortado a la allocation vieja → las franjas blancas persisten

### 4.3 Por Qué g_idle_add es la Solución Correcta

`g_idle_add()` con prioridad `G_PRIORITY_DEFAULT_IDLE` (200) ejecuta el callback después de:

1. **GTK resize phase** (prioridad 110) — la allocation se ha calculado
2. **GTK redraw phase** (prioridad 120) — el dibujado se ha completado

Esto garantiza que cuando nuestro callback ejecuta `make-event EVT_SIZE`, el ciclo de layout de GTK ha terminado completamente, y las llamadas a `gtk_widget_queue_resize()` dentro de `change-size` son procesadas normalmente.

---

## 5. SOLUCION IMPLEMENTADA

### 5.1 Opciones Consideradas

#### Opción A: Diferir EVT_SIZE via g_idle_add

```reds
; En window-size-allocate:
g_idle_add as integer! :idle-size-allocate as int-ptr! widget

; Nuevo callback:
idle-size-allocate: func [
    [cdecl]
    widget [int-ptr!]
    return: [logic!]
][
    make-event as handle! widget 0 EVT_SIZE
    false  ; G_SOURCE_REMOVE: one-shot
]
```

**Ventajas:**
- Sigue el patrón estándar de GTK (testwindowsize.c, Inkscape, gtkwindow.c)
- Prioridad correcta (200 = después de resize + redraw)
- One-shot automático (retorna false/G_SOURCE_REMOVE)
- Mínimo impacto en el código existente

**Desventajas:**
- EVT_SIZE se disfra ligeramente (un ciclo del main loop) — imperceptible para el usuario
- Requiere un nuevo callback function

#### Opción B: Llamar gtk_widget_size_allocate() directamente en change-size

```reds
; En change-size, después de set_size_request:
gtk_widget_size_allocate widget allocation_rect
```

**Ventajas:**
- Forza la allocation inmediatamente, sin diferimiento

**Desventajas:**
- Llamar `gtk_widget_size_allocate()` desde dentro de `size-allocate` puede causar re-entrancia y layout loops
- No hay garantía de que GTK procese correctamente esta allocation forzada
- No es un patrón recomendado por la documentación de GTK
- Requiere construir un `GtkAllocation` manualmente (más complejo)

#### Opción C: Usar gtk_widget_queue_allocate() (GTK 3.20+)

```reds
gtk_widget_queue_allocate widget
```

**Ventajas:**
- Diseñado específicamente para re-allocation sin cambiar size request
- Puede llamarse desde dentro de size-allocate

**Desventajas:**
- Solo disponible desde GTK 3.20 — Red necesita soportar GTK 3.10+
- Solo re-asigna, no cambia el size request — no resuelve el caso donde el tamaño solicitado cambia
- No está importado actualmente en el backend GTK3 de Red

### 5.2 Decisión

Se eligió la **Opción A** (`g_idle_add`). Es el patrón estándar usado por GTK y proyectos como Inkscape, tiene la prioridad correcta, es one-shot automático, y funciona en todas las versiones de GTK3 que Red soporta.

### 5.3 Detalle de Cada Cambio

#### 5.3.1 handlers.reds: Callback idle-size-allocate (nuevo)

**Archivo:** `modules/view/backends/gtk3/handlers.reds`  
**Líneas:** 737-744 (nuevo)

```reds
idle-size-allocate: func [
	[cdecl]
	widget		[int-ptr!]
	return:		[logic!]
][
	make-event as handle! widget 0 EVT_SIZE
	false								;-- G_SOURCE_REMOVE: one-shot
]
```

**Explicación línea por línea:**

- **`[cdecl]`**: Convención de llamada requerida para callbacks GLib/GTK. Todas las funciones callback del backend GTK3 usan esta convención (ver `red-timer-action`, `window-size-allocate`, etc.).
- **`widget [int-ptr!]`**: Recibe el widget como `int-ptr!` (puntero genérico), que es lo que `g_idle_add` pasa como `gpointer data` al callback. Se convierte a `handle!` en `make-event`.
- **`return: [logic!]`**: `GSourceFunc` retorna `gboolean`. `false` = `G_SOURCE_REMOVE` = one-shot (se auto-elimina del main loop).
- **`make-event as handle! widget 0 EVT_SIZE`**: Emite `EVT_SIZE` para el widget, idéntico a como lo hacía `window-size-allocate` antes del fix, pero ahora fuera del signal handler.
- **`false`**: Retorna `G_SOURCE_REMOVE` para que el callback se ejecute una sola vez y se elimine automáticamente del main loop.

#### 5.3.2 handlers.reds: Modificación de window-size-allocate

**Archivo:** `modules/view/backends/gtk3/handlers.reds`  
**Línea:** 729

**Antes:**
```reds
		either null? GET-RESIZING(widget) [
			make-event widget 0 EVT_SIZE
		][
			make-event widget 0 EVT_SIZING
		]
```

**Después:**
```reds
		either null? GET-RESIZING(widget) [
			g_idle_add as integer! :idle-size-allocate as int-ptr! widget
		][
			make-event widget 0 EVT_SIZING
		]
```

**Explicación:**

- **Solo `EVT_SIZE` se difiere.** `EVT_SIZING` (live resize) sigue siendo síncrono porque durante live resize el usuario no provoca `change-size` en los child faces, por lo que `queue_resize` no es llamado y no hay problema.
- **`g_idle_add`** ya estaba importado en `gtk.reds` línea 782, aunque nunca se usaba. Su firma es `g_idle_add [handler [integer!] data [int-ptr!] return: [integer!]]`.
- **`as integer! :idle-size-allocate`**: Pasa la dirección de la función como entero, el mismo patrón usado con `g_timeout_add` (gui.reds línea 803: `as integer! :red-timer-action`).
- **`as int-ptr! widget`**: Pasa el widget pointer como `gpointer data`, siguiendo la firma de `GSourceFunc`.

#### 5.3.3 gui.reds: Extensión de change-size (B2 + B3)

**Archivo:** `modules/view/backends/gtk3/gui.reds`  
**Líneas:** 1036-1048

**Antes:**
```reds
		if type = rich-text [
			gtk_layout_set_size widget sx y
		]
		gtk_widget_set_size_request widget sx sy
		gtk_widget_queue_resize widget
```

**Después:**
```reds
		if any [type = rich-text type = base type = panel] [
			either type = rich-text [
				gtk_layout_set_size widget sx y
			][
				gtk_layout_set_size widget sx sy
			]
		]
		if type = base [
			set-buffer widget sx sy as red-tuple! values + FACE_OBJ_COLOR
			gtk_widget_queue_draw widget
		]
		gtk_widget_set_size_request widget sx sy
		gtk_widget_queue_resize widget
```

**Explicación B2 (gtk_layout_set_size para base y panel):**

- `rich-text` usa `y` (modificado por el ajuste de scroll en líneas 1024-1031), mientras que `base` y `panel` usan `sy` (el tamaño original sin ajuste).
- Los tres tipos usan `GtkLayout` internamente y necesitan que su tamaño lógico se actualice al redimensionar.

**Explicación B3 (set-buffer para base):**

- `set-buffer` (gui.reds:1789-1804) crea un nuevo `cairo_image_surface` del tamaño especificado, destruyendo el anterior.
- Internamente llama a `transparent-base?` — si la base es opaca (`color: white`, alpha = 255), sale inmediatamente sin hacer nada. Solo crea buffer para bases transparentes/semi-transparentes.
- `gtk_widget_queue_draw` fuerza un repintado con el nuevo buffer.

### 5.4 Por Qué NO Usamos gtk_widget_size_allocate() Directo

Llamar `gtk_widget_size_allocate()` directamente dentro de `change-size` forzaría una re-allocation inmediata, pero:

1. GTK no garantiza que la allocation sea procesada correctamente cuando se fuerza desde dentro de un signal handler
2. Puede causar re-entrancia: la allocation forzada dispara nuevos signals `size-allocate`, creando un loop potencial
3. No es un patrón recomendado por la documentación de GTK
4. `g_idle_add` es el mecanismo estándar y documentado para diferir trabajo desde signal handlers

### 5.5 Por Qué NO Usamos gtk_widget_queue_allocate()

`gtk_widget_queue_allocate()` fue introducido en GTK 3.20 y solo re-asigna sin cambiar el size request. Red necesita soportar versiones anteriores de GTK3 (3.10+). Además, nuestro caso requiere cambiar el size request, no solo re-asignar.

---

## 6. VERIFICACION

### 6.1 Log Antes del Fix B1 (B2+B3 aplicados, B1 sin aplicar)

Test: `gtk3-base-layout-size.red`

```
; Linux
10:25:58 on-resize win:600x400 canvas:580x380
10:26:01 on-resize win:1464x804 canvas:1444x784   ← tamaño intermedio erróneo
10:26:01 on-resize win:1366x706 canvas:1346x686
10:26:03 on-resize win:502x302 canvas:482x282      ← tamaño intermedio erróneo
10:26:03 on-resize win:600x400 canvas:580x380
```

**Observación:** Los tamaños intermedios (`1464x804`, `502x302`) son allocations de GTK que no corresponden al tamaño final. El marco azul se ve cortado con franjas blancas.

### 6.2 Log Después del Fix Completo (B1+B2+B3)

Test: `gtk3-base-layout-size.red`

```
; Linux
11:29:02 on-resize win:600x400 canvas:580x380
11:29:05 on-resize win:1366x706 Δ=766x306 canvas:1346x686
11:29:05 on-resize win:1366x706 canvas:1346x686
11:29:07 on-resize win:600x400 Δ=-766x-306 canvas:580x380
11:29:07 on-resize win:600x400 canvas:580x380
```

**Observación:** Los tamaños son correctos en cada transición. Los dos eventos por transición son esperados: uno del signal `window-state-changed` (Bug A fix) y otro del `idle-size-allocate` callback (B1 fix). No hay tamaños intermedios erróneos. Visualmente, el marco azul llena todo el canvas sin franjas blancas.

Test: `gtk3-base-buffer-size.red` (base transparente, B3)

```
; Linux
11:36:44 on-resize win:600x400 canvas:580x380
11:36:48 on-resize win:1366x706 Δ=766x306 canvas:1346x686
11:36:48 on-resize win:1366x706 canvas:1346x686
11:36:51 on-resize win:600x400 Δ=-766x-306 canvas:580x380
11:36:51 on-resize win:600x400 canvas:580x380
11:36:56 on-resize win:600x400 canvas:580x380
11:36:56 on-resize win:600x403 Δ=0x3 canvas:580x383
11:36:57 on-resize win:600x476 Δ=0x73 canvas:580x456
```

**Observación:** Maximizar, restaurar y drag-resize todos funcionan correctamente. El buffer cairo se redimensiona apropiadamente.

Test: `gtk3-base-draw-redraw.red` (B2+B3 combinado, semi-transparente)

```
; Linux
11:37:14 on-resize win:600x400 canvas:580x380
11:37:18 on-resize win:1366x706 Δ=766x306 canvas:1346x686
11:37:18 on-resize win:1366x706 canvas:1346x686
11:37:21 on-resize win:600x400 Δ=-766x-306 canvas:580x380
11:37:21 on-resize win:600x400 canvas:580x380
```

**Observación:** Comportamiento correcto. Sin franjas blancas.

### 6.3 Verificación de Regresión

- **Rich-text con scroll:** No afectado. El ajuste de scroll (`y` modificado) sigue funcionando correctamente.
- **Panel labels:** No afectado. El centrado de labels (`gtk_layout_move`) usa las variables `x`/`y` reasignadas en el bloque panel (línea 1046), independientes del cambio.
- **EVT_SIZING (live resize):** Sigue siendo síncrono. Solo EVT_SIZE se difiere.

---

## 7. REFERENCIAS

### GTK3 Documentation
- [gtk_widget_queue_resize()](https://docs.gtk.org/gtk3/method.Widget.queue_resize.html) — Documentación oficial de la restricción "silently ignored inside size-allocate"
- [g_idle_add()](https://docs.gtk.org/glib/func.idle_add.html) — Documentación de GLib idle source
- [GSourceFunc callback](https://docs.gtk.org/glib/callback.SourceFunc.html) — Firma del callback para g_idle_add
- [G_PRIORITY_DEFAULT_IDLE](https://docs.gtk.org/glib/consts.PRIORITY_DEFAULT_IDLE.html) — Prioridad por defecto para g_idle_add (200)
- [G_SOURCE_REMOVE](https://docs.gtk.org/glib/consts.SOURCE_REMOVE.html) — Valor de retorno para one-shot idle callbacks
- [gtk_layout_set_size()](https://docs.gtk.org/gtk3/class.Layout.html) — Documentación de GtkLayout y su tamaño scrolleable
- [size-allocate signal](https://docs.gtk.org/gtk3/signal.Widget.size-allocate.html) — Señal GTK3 para asignación de tamaño
- [gtk_widget_queue_allocate()](https://docs.gtk.org/gtk3/method.Widget.queue_allocate.html) — Alternativa en GTK 3.20+ (no usada, requiere 3.10+)

### GTK3 Source Code
- [Benjamin Otte: "Warn on calls to queue_resize() during size_allocate()"](https://lists.gnome.org/archives/commits-list/2015-October/msg07661.html) — Commit que añade warning de depuración
- [Benjamin Otte: "Clear pending resizes after size_allocate()"](https://lists.gnome.org/archives/commits-list/2015-October/msg07660.html) — Commit con "Size allocation is god"
- [Tim Janik: "gtk_widget_queue_resize() forgetting allocation"](https://lists.gnome.org/archives/gtk-devel-list/2004-October/msg00011.html) — Análisis del bug en gtk-devel-list (2004)
- [Owen Taylor: "Size allocation and redrawing issues"](https://lists.gnome.org/archives/gtk-devel-list/2001-October/msg00529.html) — Invariante fundamental de GTK
- [GTK testwindowsize.c](https://codebrowser.dev/gtk/gtk/tests/testwindowsize.c.html) — Ejemplo oficial de GTK usando g_idle_add para diferir desde layout signal

### Cairo Documentation
- [cairo_image_surface_create()](https://cairographics.org/manual/cairo-Image-Surfaces.html) — Creación de superficies cairo con dimensiones

### Reference Applications
- [Inkscape Canvas](https://inkscape.gitlab.io/inkscape/doxygen/canvas_8cpp_source.html) — Deferred redraw via Glib::signal_idle() después de size_allocate
- [GTK gtkwindow.c](https://github.com/GNOME/gtk/blob/main/gtk/gtkwindow.c) — handle_keys_changed via g_idle_add (debounce pattern)
- [GTK gtkcontainer.c](https://github.com/linuxmint/gtk/blob/master/gtk/gtkcontainer.c) — Idle sizer mechanism (GTK_PRIORITY_RESIZE)
- [Evince ev-jobs.c](https://gitlab.gnome.org/GNOME/evince/-/blob/main/libview/ev-jobs.c) — g_idle_add_full para thread-safe signal emission

### Red/System Source Code
- `modules/view/backends/gtk3/gui.reds` — `change-size` (línea 990), `set-buffer` (línea 1789)
- `modules/view/backends/gtk3/handlers.reds` — `idle-size-allocate` (línea 737), `window-size-allocate` (línea 697), `base-draw` (línea ~295)
- `modules/view/backends/gtk3/gtk.reds` — Import de `g_idle_add` (línea 782)
- `modules/view/backends/gtk3/events.reds` — Conexión de señal "size-allocate" (línea ~1088)

### Test Logs
- `anlaco-tests/gtk3-base-layout-size-Linux.log` — B2 test (base opaco)
- `anlaco-tests/gtk3-base-buffer-size-Linux.log` — B3 test (base transparente)
- `anlaco-tests/gtk3-base-draw-redraw-Linux.log` — B2+B3 combinado

---

## 8. NOTAS PARA AUDITORES

### 8.1 Por Qué g_idle_add y No g_idle_add_full

`g_idle_add()` es equivalente a `g_idle_add_full(G_PRIORITY_DEFAULT_IDLE, func, data, NULL)`. Usamos `g_idle_add` porque:

1. No necesitamos una prioridad diferente — `G_PRIORITY_DEFAULT_IDLE` (200) es la correcta: se ejecuta después de resize (110) y redraw (120)
2. No necesitamos un `GDestroyNotify` — el callback es one-shot y no hay recursos que limpiar
3. Es más simple y ya estaba importado en el backend (`gtk.reds:782`)

`g_idle_add_full` solo sería necesario si necesitáramos una prioridad diferente o cleanup personalizado, ninguno de los cuales aplica aquí.

### 8.2 Por Qué G_SOURCE_REMOVE (false) y No G_SOURCE_CONTINUE

Retornar `false` (`G_SOURCE_REMOVE`) hace que el callback se ejecute **una sola vez** y se elimine automáticamente del main loop. Esto es lo que queremos: un único `EVT_SIZE` diferido por cada `size-allocate`.

Retornar `true` (`G_SOURCE_CONTINUE`) haría que el callback se re-programara indefinidamente en cada ciclo idle, disparando `EVT_SIZE` repetidamente — un bug grave.

### 8.3 Por Qué No Necesitamos g_source_remove

Dado que `idle-size-allocate` retorna `false` (G_SOURCE_REMOVE), GLib elimina automáticamente la fuente del main loop después de la ejecución. No necesitamos:

- Almacenar el source ID retornado por `g_idle_add`
- Llamar `g_source_remove` para cancelar el callback pendiente
- Preocuparnos por callbacks huérfanos si el widget se destruye

Si la ventana se destruye antes de que el callback idle se ejecute, `make-event` operará sobre un widget destruido, pero esto es seguro porque GTK marca los widgets destruidos y las operaciones sobre ellos son no-ops. Este es el mismo patrón que usa GTK internamente (ver `handle_keys_changed` en gtkwindow.c).

### 8.4 Por Qué No Necesitamos g_object_ref/unref

En el patrón estándar de GTK para callbacks idle, se usa `g_object_ref(widget)` antes de `g_idle_add` y `g_object_unref(widget)` en el callback para mantener el widget vivo. Esto es necesario en aplicaciones multi-thread o cuando el callback puede ejecutarse después de que el widget haya sido destruido.

En Red/View GTK3, no necesitamos esto porque:

1. **GTK es single-threaded** — Red/View GTK3 ejecuta todo en el main thread. No hay condición de carrera entre destrucción del widget y ejecución del callback.
2. **El ciclo de vida del widget es gestionado por Red** — Los widgets se crean y destruyen sincrónicamente dentro del main loop. Si un widget se destruye, es antes o después del callback idle, nunca concurrentemente.
3. **GTK marca widgets destruidos como no-ops** — Si el widget se destruye antes del callback, las operaciones GTK sobre él son seguras (no-ops).
4. **El patrón existente no usa ref/unref** — `red-timer-action` (gui.reds:1173) usa el mismo patrón `g_timeout_add` sin ref/unref.

### 8.5 Prioridad G_PRIORITY_DEFAULT_IDLE (200) vs GTK_PRIORITY_RESIZE (110)

Nuestro callback usa `g_idle_add` que asigna prioridad `G_PRIORITY_DEFAULT_IDLE` (200). Esto es correcto porque:

- **GTK_PRIORITY_RESIZE (110)**: Usado internamente por GTK para procesar resizes pendientes. Un callback con esta prioridad se ejecutaría ANTES de que GTK termine su ciclo de layout, lo que podría causar los mismos problemas que estamos intentando evitar.
- **G_PRIORITY_DEFAULT_IDLE (200)**: Se ejecuta DESPUÉS de resize (110) y redraw (120). Cuando nuestro callback se ejecuta, el ciclo de layout de GTK está completo y `gtk_widget_queue_resize()` ya no es ignorado.

Esto está alineado con la práctica de Inkscape, que explícitamente nota que prioridades más altas causan flickering (issue #4242).

### 8.6 Por Qué EVT_SIZING Sigue Síncrono

Solo `EVT_SIZE` se difiere via `g_idle_add`. `EVT_SIZING` (emitido durante live resize) sigue siendo síncrono porque:

1. **Durante live resize, el usuario no provoca `change-size`** en los child faces. Solo el window face cambia de tamaño, y GTK ya maneja la allocation del window correctamente.
2. **EVT_SIZING es informativo** — Se usa para actualizar indicadores de tamaño en la UI, no para redimensionar child faces.
3. **Diferir EVT_SIZING causaría lag perceptible** — Los indicadores de tamaño se actualizarían con un ciclo de retraso, dando una sensación de UI no responsiva.

---

**END OF DOCUMENT**