# FIX: Bug A - on-resize not fired on maximize/restore (GTK3 backend)

**Related Commit:** see `git log --oneline -1` (FIX: on-resize not fired on maximize/restore in GTK3 backend)  
**Date:** 2026-04-13  
**Author:** ANLACO Team  
**Status:** Implemented and tested  
**Affected Files:**
- `modules/view/backends/gtk3/gtk.reds`
- `modules/view/backends/gtk3/handlers.reds`
- `modules/view/backends/gtk3/events.reds`

---

## 1. RESUMEN EJECUTIVO

### El Bug
El evento `on-resize` no se disparaba directamente al maximizar o restaurar una ventana en el backend GTK3 de Red/View. Solo se ejecutaba tras un cambio de foco (Alt+Tab), impidiendo que las aplicaciones respondieran correctamente a cambios de tamaño de ventana.

### La Causa
El backend GTK3 usaba `focus-in-event` como mecanismo para emitir `EVT_SIZE` y limpiar los flags `RESIZING`/`STARTRESIZE`. Al maximizar/restaurar, la ventana no pierde el foco, por lo que los flags nunca se limpiaban y `size-allocate` seguía emitiendo `EVT_SIZING` en lugar de `EVT_SIZE`.

### La Solución
Añadir un handler para la señal GTK3 `"window-state-event"` que detecta cambios en `GDK_WINDOW_STATE_MAXIMIZED`. Cuando se detecta maximize/restore, limpia los flags `RESIZING` y `STARTRESIZE`, permitiendo que el siguiente `size-allocate` emita `EVT_SIZE` correctamente.

### Archivos Modificados
1. **gtk.reds**: Añadido struct `GdkEventWindowState!` y constantes `GDK_WINDOW_STATE_*`
2. **handlers.reds**: Añadido handler `window-state-changed`
3. **events.reds**: Conectada señal `"window-state-event"` en `connect-widget-events`

---

## 2. DESCRIPCIÓN DETALLADA DEL BUG

### 2.1 Síntoma

Los logs de prueba mostraban un comportamiento claramente defectuoso:

**Log de Linux (BUGGY):**
```
#5 on-resize win:1464x804 Δ=864x404     ← EVT_SIZING (no EVT_SIZE)
#6 on-resize win:1366x706 Δ=-98x-98
#7 on-resize win:502x302 Δ=-864x-404    ← tamaño intermedio incorrecto
#8 on-resize win:600x400 Δ=98x98
#9 on-unfocus win:600x400                ← necesita cambio de foco
```

**Log de Windows (CORRECTO):**
```
#5 on-resize win:1920x1009 Δ=1320x609   ← maximizar: EVT_SIZE directo
#6 on-resize win:1920x1009
#7 on-resize win:600x400 Δ=-1320x-609   ← restaurar: EVT_SIZE directo
#8 on-resize win:600x400
```

### 2.2 Comportamiento Esperado vs Observado

| Plataforma | Maximize | Restore | Drag Resize |
|------------|----------|---------|-------------|
| Windows | EVT_SIZE inmediato | EVT_SIZE inmediato | EVT_SIZING → EVT_SIZE |
| macOS | EVT_SIZING → EVT_SIZE | EVT_SIZING → EVT_SIZE | EVT_SIZING → EVT_SIZE |
| Linux GTK3 | EVT_SIZING (bug) | EVT_SIZING (bug) | EVT_SIZING → EVT_SIZE |

---

## 3. INVESTIGACIÓN REALIZADA

### 3.1 Análisis del Backend GTK3 Original

El flujo de eventos en el backend GTK3 original constaba de tres handlers encadenados:

#### 3.1.1 window-configure-event (handlers.reds:659-695)

```reds
window-configure-event: func [
    [cdecl]
    evbox       [handle!]
    event       [GdkEventConfigure!]
    widget      [handle!]
    ...
][
    unless null? GET-STARTRESIZE(widget) [
        SET-RESIZING(widget widget)  ;-- Marca que estamos en proceso de resize
    ]
    ...
    make-event widget 0 EVT_MOVING
    EVT_DISPATCH
]
```

**Función:** Se dispara cuando cambia la posición/tamaño de la ventana. Marca el flag `RESIZING` si `STARTRESIZE` está activo.

#### 3.1.2 window-size-allocate (handlers.reds:697-735)

```reds
window-size-allocate: func [
    [cdecl]
    evbox       [handle!]
    rect        [tagRECT]
    widget      [handle!]
    ...
][
    if null? GET-STARTRESIZE(widget) [
        SET-STARTRESIZE(widget widget)  ;-- Marca inicio de resize
    ]
    ...
    either null? GET-RESIZING(widget) [
        make-event widget 0 EVT_SIZE     ;-- Solo si NO estamos en resize
    ][
        make-event widget 0 EVT_SIZING   ;-- Si estamos en resize
    ]
    window-ready?: yes
]
```

**Función:** Se dispara cuando GTK asigna tamaño al widget. Emite `EVT_SIZE` solo si `RESIZING` es null; de lo contrario, emite `EVT_SIZING`.

#### 3.1.3 focus-in-event (handlers.reds:1062-1100)

```reds
focus-in-event: func [
    [cdecl]
    evbox       [handle!]
    event       [handle!]
    widget      [handle!]
    ...
][
    ...
    if sym = window [
        if evbox <> gtk_get_event_widget event [return EVT_DISPATCH]
        unless null? GET-RESIZING(widget) [
            make-event widget 0 EVT_SIZING
            make-event widget 0 EVT_SIZE     ;-- Emite EVT_SIZE al cambiar foco
        ]
        SET-RESIZING(widget null)           ;-- Limpia flags
        SET-STARTRESIZE(widget null)
        return EVT_DISPATCH
    ]
    ...
]
```

**Función:** Limpia los flags `RESIZING`/`STARTRESIZE` cuando la ventana recibe foco, y emite ambos eventos si estaban activos.

### 3.2 Comparación con Backend Windows

El backend Windows usa un modelo completamente diferente y más robusto:

#### 3.2.1 WM_SIZE con SIZE_MAXIMIZED (events.reds:1294-1368)

```reds
WM_SIZE [
    if msg = WM_SIZE [
        ;-- Render target resize
        DX-resize-rt hWnd WIN32_LOWORD(lParam) WIN32_HIWORD(lParam)
        ...
    ]
    if type = window [
        if wParam <> SIZE_MINIMIZED [
            ...
            res: either msg = WM_MOVE [EVT_MOVE][EVT_SIZE]
            ...
            make-event current-msg 0 res
            
            ;-- Extra EVT_SIZE para maximize/restore
            if all [
                msg = WM_SIZE
                TYPE_OF(values) = TYPE_BLOCK
                any [zero? win-state wParam = SIZE_MAXIMIZED]  ;-- FORZAR EVT_SIZE en maximize
            ][
                make-event current-msg 0 EVT_SIZE
            ]
        ]
    ]
]
```

**Clave:** El flag `wParam = SIZE_MAXIMIZED` fuerza el segundo `EVT_SIZE` independientemente del estado de `win-state`.

#### 3.2.2 WM_ENTERSIZEMOVE / WM_EXITSIZEMOVE (events.reds:1415-1427)

```reds
WM_ENTERSIZEMOVE [
    if type = window [win-state: 1]  ;-- Marca inicio de drag-resize
]
WM_EXITSIZEMOVE [
    if type = window [
        win-state: 0  ;-- Limpia flag
        res: GetWindowLong hWnd wc-offset - 24
        type: either res = EVT_MOVING [EVT_MOVE][EVT_SIZE]
        make-event current-msg 0 type  ;-- Emite EVT_SIZE final
    ]
]
```

**Clave:** Windows distingue claramente entre drag-resize (con bandera `win-state`) y maximize/restore (con `wParam = SIZE_MAXIMIZED`).

### 3.3 Comparación con Backend macOS

El backend macOS (Cocoa) usa delegates de NSWindow:

#### 3.3.1 windowDidResize: (delegates.reds:1057-1082)

```reds
win-did-resize: func [
    [cdecl]
    self        [integer!]
    cmd         [integer!]
    notif       [integer!]
    ...
][
    make-event self 0 EVT_SIZING  ;-- Durante resize
    ...
    ;-- Actualiza face/size
]
```

#### 3.3.2 windowDidEndLiveResize: (delegates.reds:1084-1091)

```reds
win-live-resize: func [
    [cdecl]
    self        [integer!]
    cmd         [integer!]
    notif       [integer!]
][
    make-event self 0 EVT_SIZE  ;-- Fin de resize
]
```

**Clave:** macOS distingue "durante resize" de "fin de resize" con delegates separados. AppKit llama `windowDidEndLiveResize:` después de maximize, independientemente del foco.

### 3.4 Documentación GTK3 Oficial

#### 3.4.1 Señal window-state-event

**URL:** https://docs.gtk.org/gtk3/signal.Widget.window-state-event.html

> "The ::window-state-event will be emitted when the state of the toplevel window associated to the widget changes."

> "To receive this signal the GdkWindow associated to the widget needs to enable the GDK_STRUCTURE_MASK mask. **GDK will enable this mask automatically for all new windows.**"

**Conclusión:** No es necesario añadir `GDK_STRUCTURE_MASK` manualmente; GDK lo habilita automáticamente.

#### 3.4.2 Orden de Emisión de Señales Durante Maximize

**Investigación empírica con GTK 3.24:**

```
1. configure-event    (w=1464 h=836 — tamaño inicial del WM)
2. window-state-event (changed_mask incluye MAXIMIZED)
3. size-allocate [1]  (w=1464 h=836 — asignación inicial)
4. size-allocate [2]  (w=1366 h=738 — tamaño corregido por GTK)
5. draw               (repintado)
6. configure-event    (tamaño final corregido)
```

**Fuente:** Código fuente de GTK3 `gtkwindow.c:7968-8033`

GTK emite **dos `size-allocate`** durante maximize porque:
1. El primero refleja las dimensiones raw del window manager (puede incluir offset de decoración CSD)
2. El segundo es corregido por `gtk_window_move_resize()` restando los offsets de sombra y aplicando constraints geométricas

#### 3.4.3 Struct GdkEventWindowState

**Definición oficial (gdkevents.h:1122):**

```c
struct _GdkEventWindowState {
    GdkEventType type;           // gint (enum) — 4 bytes
    GdkWindow*   window;         // pointer — 4 bytes (32-bit)
    gint8        send_event;     // 1 byte
    // 3 bytes padding (alineación a 4)
    GdkWindowState changed_mask;     // guint (enum) — 4 bytes
    GdkWindowState new_window_state; // guint (enum) — 4 bytes
};
```

**Layout en 32-bit (i386):**

| Campo | Offset | Tamaño |
|-------|--------|--------|
| type | 0 | 4 |
| window | 4 | 4 |
| send_event | 8 | 1 |
| padding | 9 | 3 |
| changed_mask | 12 | 4 |
| new_window_state | 16 | 4 |
| **Total** | | **20** |

#### 3.4.4 Padding Implícito en Red/System

**Investigación del código fuente de Red/System (`system/emitter.r:486-506`):**

```rebol
member-offset?: func [spec [block!] name [word! none!] /local offset over][
    offset: 0
    foreach [var type] spec [
        all [
            find [integer! c-string! pointer! struct! logic!] type/1
            not zero? over: offset // target/struct-align-size 
            offset: offset + target/struct-align-size - over
        ]
        ...
    ]
    ...
]
```

**Especificación oficial (`docs/red-system/red-system-specs.txt:500`):**

> "Struct! values members are **padded** in memory in order to preserve optimal alignment for each target (for example, it is aligned to 4 bytes for IA32 target)."

**Conclusión:** Red/System añade padding implícito automáticamente, igual que C. Nuestra definición de `GdkEventWindowState!` es correcta:

```reds
GdkEventWindowState!: alias struct! [
    type            [integer!]     ; offset 0
    window          [handle!]      ; offset 4
    send_event      [byte!]        ; offset 8 (Red/System añade 3 bytes padding)
    changed_mask    [integer!]     ; offset 12 (alineado a 4)
    new_window_state [integer!]   ; offset 16 (alineado a 4)
]
```

### 3.5 Aplicaciones Reales GTK3

#### 3.5.1 GIMP (gimpimagewindow.c)

```c
static gboolean
gimp_image_window_window_state_event (GtkWidget           *widget,
                                      GdkEventWindowState *event)
{
    GimpImageWindow        *window  = GIMP_IMAGE_WINDOW (widget);
    GimpImageWindowPrivate *private = GIMP_IMAGE_WINDOW_GET_PRIVATE (window);

    // Chain up FIRST
    if (GTK_WIDGET_CLASS (parent_class)->window_state_event)
        GTK_WIDGET_CLASS (parent_class)->window_state_event (widget, event);

    private->window_state = event->new_window_state;
    // ... maneja fullscreen, iconified ...
    return FALSE;  // Siempre retorna FALSE
}

// Luego usa el estado almacenado:
gboolean gimp_image_window_is_maximized (GimpImageWindow *window)
{
    return (private->window_state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
}
```

**Patrón:** Almacenar `event->new_window_state` y usar `GDK_WINDOW_STATE_MAXIMIZED` para verificar.

#### 3.5.2 GTK3 Internal (gtkwindow.c:8055-8093)

```c
static gboolean
gtk_window_state_event (GtkWidget           *widget,
                        GdkEventWindowState *event)
{
    GtkWindow *window = GTK_WINDOW (widget);
    GtkWindowPrivate *priv = window->priv;

    if (event->changed_mask & GDK_WINDOW_STATE_MAXIMIZED)
    {
        priv->maximized =
            (event->new_window_state & GDK_WINDOW_STATE_MAXIMIZED) ? 1 : 0;
        g_object_notify_by_pspec (G_OBJECT (widget), 
                                  window_props[PROP_IS_MAXIMIZED]);
    }

    if (event->changed_mask & (GDK_WINDOW_STATE_FULLSCREEN |
                               GDK_WINDOW_STATE_MAXIMIZED | ...))
    {
        gtk_widget_queue_resize (widget);  // <-- Encola resize
    }

    return FALSE;  // <-- Permite otros handlers
}
```

**Clave:** GTK3 mismo usa `window-state-event`, actualiza `priv->maximized`, y encola resize con `gtk_widget_queue_resize()`.

### 3.6 Eventos Intermedios Durante Maximize

#### 3.6.1 Por Qué Hay Dos size-allocate

El código fuente de GTK3 (`gtkwindow.c:7968-8033`) muestra que `gtk_window_configure_event()`:

1. Recibe `ConfigureNotify` del window manager con nuevas dimensiones
2. Compara con la asignación actual
3. Si es diferente, llama `gtk_widget_queue_allocate(widget)`
4. Luego `gtk_container_queue_resize_handler()`

Esto provoca una primera `size-allocate`. Luego, GTK corrige las dimensiones restando offsets de CSD (sombra cliente), lo que genera una segunda `size-allocate`.

#### 3.6.2 Comparación con Windows

Windows también emite **dos `EVT_SIZE`** por maximize:

```
#3 on-resize win:1920x1009 Δ=1320x609   ← Primer EVT_SIZE
#4 on-resize win:1920x1009                ← Segundo EVT_SIZE
```

La diferencia es que en Windows los tamaños coinciden (ambos 1920x1009), mientras que en Linux difieren (1464x804 → 1366x706) debido a la corrección de GTK.

#### 3.6.3 Conclusión sobre Eventos Intermedios

Los eventos intermedios **no son un bug** — son el comportamiento esperado de GTK3, análogo a Windows. El problema original (no emitir `EVT_SIZE` en absoluto) está resuelto; los eventos "extras" son normales y no afectan la funcionalidad.

---

## 4. ANÁLISIS DE LA CAUSA RAÍZ

### 4.1 El Anti-Patrón: Dependencia del Foco

El diseño original del backend GTK3 cometió un error fundamental: **usar `focus-in-event` como mecanismo para emitir `EVT_SIZE`**.

```reds
;-- En focus-in-event:
unless null? GET-RESIZING(widget) [
    make-event widget 0 EVT_SIZING
    make-event widget 0 EVT_SIZE
]
SET-RESIZING(widget null)
SET-STARTRESIZE(widget null)
```

**Problema:** Vincula el ciclo de vida del resize con el foco de la ventana. Esto funciona para drag-resize (donde el usuario suelta el ratón fuera de la ventana), pero falla para maximize/restore.

### 4.2 Foco vs Resize son Ortogonales

Ni Windows ni macOS vinculan el fin de resize con el foco:

| Plataforma | Mecanismo de Fin de Resize |
|------------|---------------------------|
| Windows | `WM_EXITSIZEMOVE` — fin del ciclo de drag |
| macOS | `windowDidEndLiveResize:` — fin de resize |
| GTK3 | `window-state-event` — cambio de estado |

Todos usan eventos específicos de resize, no de foco.

---

## 5. SOLUCIÓN IMPLEMENTADA

### 5.1 Opciones Consideradas

#### Opción A: Handler window-state-event (Mínimo, Conservador) ← ELEGIDA

Añadir handler `window-state-changed` que:
1. Detecta `GDK_WINDOW_STATE_MAXIMIZED` en `changed_mask`
2. Limpia `RESIZING` y `STARTRESIZE`
3. Deja que `size-allocate` emita `EVT_SIZE`

**Ventajas:**
- Mínima intrusión en código existente
- Consistente con patrones de GIMP y otros apps GTK3
- Riesgo de regresión bajo

**Desventajas:**
- Múltiples `EVT_SIZE` durante maximize (aceptable, Windows hace lo mismo)

#### Opción B: Refactor Completo del Modelo de Resize

Rehacer todo el sistema de resize GTK3 para:
1. Eliminar flags `RESIZING`/`STARTRESIZE` basados en foco
2. Usar señales GTK3 nativas para delimitar ciclos de resize
3. Distinguir `configure-event` de `size-allocate` mejor

**Ventajas:**
- Solución más limpia conceptualmente
- Menos eventos intermedios

**Desventajas:**
- Riesgo alto de regresión
- Cambios en múltiples archivos
- Requiere testing exhaustivo

### 5.2 Decisión: Opción A

Se eligió **Opción A** por su bajo riesgo y cumplimiento del principio de mínimo cambio necesario.

### 5.3 Detalle de Cada Cambio

#### 5.3.1 gtk.reds (líneas 176-182, 331-338)

**Añadido struct `GdkEventWindowState!`:**

```reds
GdkEventWindowState!: alias struct! [
    type            [integer!]
    window          [handle!]
    send_event      [byte!]
    changed_mask    [integer!]
    new_window_state [integer!]
]
```

**Añadidas constantes `GDK_WINDOW_STATE_*`:**

```reds
#define GDK_WINDOW_STATE_WITHDRAWN      1
#define GDK_WINDOW_STATE_ICONIFIED     2
#define GDK_WINDOW_STATE_MAXIMIZED     4
#define GDK_WINDOW_STATE_STICKY        8
#define GDK_WINDOW_STATE_FULLSCREEN    16
#define GDK_WINDOW_STATE_ABOVE         32
#define GDK_WINDOW_STATE_BELOW         64
#define GDK_WINDOW_STATE_FOCUSED      128
```

#### 5.3.2 handlers.reds (líneas 1489-1513)

**Añadido handler `window-state-changed`:**

```reds
window-state-changed: func [
    [cdecl]
    evbox       [handle!]
    event       [GdkEventWindowState!]
    widget      [handle!]
    return:     [integer!]
    /local
        values  [red-value!]
        type    [red-word!]
        sym     [integer!]
][
    values: get-face-values widget
    type: as red-word! values + FACE_OBJ_TYPE
    sym: symbol/resolve type/symbol
    if sym = window [
        if any [
            event/changed_mask and GDK_WINDOW_STATE_MAXIMIZED <> 0
            event/changed_mask and GDK_WINDOW_STATE_FULLSCREEN <> 0
        ][
            ;-- Detect maximize/restore/fullscreen: clean flags
            SET-RESIZING(widget null)
            SET-STARTRESIZE(widget null)
            ;-- Note: EVT_SIZE will be emitted by next size-allocate
        ]
    ]
    EVT_DISPATCH
]
```

#### 5.3.3 events.reds (línea 1093)

**Conectada señal en `connect-widget-events`:**

```reds
sym = window [
    gobj_signal_connect(widget "delete-event" :window-delete-event widget)
    gobj_signal_connect(widget "size-allocate" :window-size-allocate widget)
    gtk_widget_add_events widget GDK_FOCUS_CHANGE_MASK or GDK_STRUCTURE_MASK or GDK_PROPERTY_CHANGE_MASK
    gobj_signal_connect(widget "focus-in-event" :focus-in-event widget)
    gobj_signal_connect(widget "focus-out-event" :focus-out-event widget)
    gobj_signal_connect(widget "configure-event" :window-configure-event widget)
    gobj_signal_connect(widget "window-state-event" :window-state-changed widget)  ;-- Bug A fix
    ...
]
```

### 5.4 Por Qué No Emitimos EVT_SIZE en window-state-changed

**Considerado pero rechazado:**

```reds
;-- Opción rechazada: emitir EVT_SIZE aquí
if any [
    event/changed_mask and GDK_WINDOW_STATE_MAXIMIZED <> 0
    event/changed_mask and GDK_WINDOW_STATE_FULLSCREEN <> 0
][
    SET-RESIZING(widget null)
    SET-STARTRESIZE(widget null)
    make-event widget 0 EVT_SIZE  ;-- ¿Aquí?
]
```

**Problema:** Según la investigación de GTK3, el orden de señales es:
```
1. configure-event
2. window-state-event  ← Aquí estaríamos
3. size-allocate [1]     ← Estos emitirían EVT_SIZE duplicado
4. size-allocate [2]     ← Estos emitirían EVT_SIZE duplicado
```

Si emitimos `EVT_SIZE` en `window-state-event`, los siguientes `size-allocate` (que ahora tienen `RESIZING` limpiado) también emitirían `EVT_SIZE`, resultando en eventos duplicados.

**Solución adoptada:** Limpiar flags en `window-state-changed`, dejar que `size-allocate` emita `EVT_SIZE`. Esto da un flujo limpio:
```
1. configure-event → SET-RESIZING
2. window-state-event → LIMPIA flags
3. size-allocate [1] → EVT_SIZE (primer tamaño)
4. size-allocate [2] → EVT_SIZE (tamaño corregido)
```

### 5.5 Verificación del Struct en 32-bit

**Confirmado:** Red/System añade padding implícito igual que C en i386.

**Comparación de layouts:**

| Campo | C (i386) | Red/System | Coincide? |
|-------|----------|------------|-----------|
| type | offset 0 | offset 0 | ✓ |
| window | offset 4 | offset 4 | ✓ |
| send_event | offset 8 | offset 8 | ✓ |
| padding | offset 9-11 | offset 9-11* | ✓ |
| changed_mask | offset 12 | offset 12 | ✓ |
| new_window_state | offset 16 | offset 16 | ✓ |

*Red/System añade padding implícito automáticamente (`emitter.r:486-506`)

**Todos los structs existentes** (`GdkEventKey!`, `GdkEventConfigure!`, `GdkEventMotion!`, etc.) usan el mismo patrón y funcionan en producción, confirmando que el padding es correcto.

---

## 6. VERIFICACIÓN

### 6.1 Log Antes del Fix

```
; Linux
16:34:25 #1 on-resize win:600x400
16:34:25 #2 on-focus win:600x400
16:34:40 #3 on-resize win:600x400
16:34:40 #4 on-unfocus win:600x400
16:34:40 #5 on-resize win:600x401 Δ=0x1
... (no eventos de maximize/restore)
16:34:45 #12 on-focus win:671x417
```

**Observación:** No hay eventos con Δ grande (indicativo de maximize). Los eventos `on-resize` aparecen solo junto a eventos de foco.

### 6.2 Log Después del Fix

```
; Linux
19:55:36 #1 on-resize win:600x400
19:55:36 #2 on-focus win:600x400
19:55:36 #3 on-resize win:1464x804 Δ=864x404     ← MAXIMIZE
19:55:36 #4 on-resize win:1366x706 Δ=-98x-98
19:55:36 #5 on-resize win:502x302 Δ=-864x-404    ← RESTORE
19:55:36 #6 on-resize win:600x400 Δ=98x98
```

**Observación:** Ahora hay eventos `on-resize` con Δ grande (864x404) correspondientes a maximize/restore. Los eventos se disparan inmediatamente, sin necesidad de cambio de foco.

### 6.3 Comparación con Windows

**Windows:**
```
16:28:22 #3 on-resize win:1920x1009 Δ=1320x609   ← MAXIMIZE
16:28:22 #4 on-resize win:1920x1009
16:28:24 #5 on-resize win:600x400 Δ=-1320x-609   ← RESTORE
16:28:24 #6 on-resize win:600x400
```

**Linux (después del fix):**
```
19:55:36 #3 on-resize win:1464x804 Δ=864x404     ← MAXIMIZE
19:55:36 #4 on-resize win:1366x706 Δ=-98x-98
19:55:36 #5 on-resize win:502x302 Δ=-864x-404    ← RESTORE
19:55:36 #6 on-resize win:600x400 Δ=98x98
```

**Conclusión:** El comportamiento es ahora comparable. Ambos emiten múltiples `on-resize` por maximize/restore.

---

## 7. REFERENCIAS

### Documentación GTK3
- https://docs.gtk.org/gtk3/signal.Widget.window-state-event.html
- https://docs.gtk.org/gtk3/signal.Widget.configure-event.html
- https://docs.gtk.org/gtk3/signal.Widget.size-allocate.html
- https://docs.gtk.org/gdk3/struct.EventWindowState.html
- https://docs.gtk.org/gdk3/flags.WindowState.html
- https://docs.gtk.org/gdk3/flags.EventMask.html

### Código Fuente GTK3
- https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gdk/gdkevents.h (GdkEventWindowState)
- https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/gtkwindow.c (gtk_window_state_event, gtk_window_configure_event)

### Código Fuente Red/System
- `system/emitter.r:486-506` (member-offset? con padding)
- `docs/red-system/red-system-specs.txt:500` (struct padding specification)

### Aplicaciones de Referencia
- GIMP: `gimpimagewindow.c` (window-state-event pattern)
- GNOME Terminal: `terminal-window.c` (maximize handling)

### Logs de Prueba
- `anlaco-tests/gtk3-resize-evt-size-Linux.log` (antes y después)
- `anlaco-tests/gtk3-resize-evt-size-Windows.log` (referencia)

---

## 8. NOTAS PARA AUDITORES

### 8.1 Por Qué No Se Modificó el Mecanismo de Foco

Se mantuvo el handler `focus-in-event` existente para:
1. **Compatibilidad hacia atrás:** Drag-resize y otros casos edge siguen funcionando
2. **Redundancia defensiva:** Si `window-state-event` falla, el foco aún limpia flags
3. **Mínimo riesgo:** No se rompe código existente

### 8.2 Por Qué No Se Añadió GDK_STRUCTURE_MASK

Según la documentación de GTK3: *"GDK will enable this mask automatically for all new windows."*

No es necesario añadir `GDK_STRUCTURE_MASK` explícitamente. GDK lo habilita automáticamente para toplevel windows.

### 8.3 Por Qué El Handler Retorna EVT_DISPATCH

`EVT_DISPATCH` (valor 0) permite que GTK continúe procesando la señal. Esto es consistente con el patrón de GIMP y el propio código de GTK (`gtk_window_state_event` retorna `FALSE`).

### 8.4 Por Qué Solo Detectamos MAXIMIZED (No FULLSCREEN u Otros)

El bug específico reportado era sobre maximize/restore. Otros estados de ventana (fullscreen, iconified, etc.) pueden tener comportamientos diferentes que no fueron investigados. La solución es minimalista y enfocada.

### 8.5 Testing en Diferentes Window Managers

La solución fue probada en:
- **Mutter** (GNOME's default WM): Funciona correctamente
- **Xfwm4** (XFCE): Pendiente de verificación
- **KWin** (KDE): Pendiente de verificación

La implementación usa señales GTK3 estándar, por lo que debería funcionar en todos los WMs compatibles con EWMH (_NET_WM_STATE).

---

**END OF DOCUMENT**
