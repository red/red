# Cómo añadir librerías ANLACO a Red

Guía para integrar librerías propias con código Red/System (`routine`) en Red, usando el sistema de módulos `Needs`.

---

## Cómo funciona el sistema de módulos de Red

Red tiene **tres mecanismos** para incluir código, cada uno con un propósito distinto:

| Mecanismo | Dónde se configura | Cuándo se carga | Disponible en consola |
|-----------|-------------------|-----------------|----------------------|
| **Entorno base** (`boot.red`) | `encapper/boot.red` | Siempre, en todo binario | Sí |
| **Módulo** (`Needs`) | `encapper/modules.r` | Solo cuando el script lo pide | Solo si la consola lo incluye en su header |
| **Include** (`#include`) | En cada script | Al compilar ese script | No |

### Entorno base (`boot.red`)

Lo que está en `boot.red` se compila **siempre**. Es el núcleo de Red: tipos de datos, funciones básicas, networking. Todo lo que está aquí está disponible sin hacer nada.

```red
; encapper/boot.red — siempre se compila
#include %environment/networking.red    ; siempre disponible
#include %environment/functions.red     ; siempre disponible
```

**No** usamos esto para nuestras librerías ANLACO. Si lo hiciéramos, cada binario Red incluiría TODAS las librerías siempre, incluso si no las usa.

### Módulo (`Needs`)

Lo que está en `modules.r` se compila **solo cuando un script lo pide** en su header. Es el mecanismo que usan View, JSON y CSV:

```red
; encapper/modules.r
;-- Name ------ Entry file ------------------------ OS availability -----
	View		%modules/view/view.red				all
	JSON		%environment/codecs/JSON.red		all
	CSV 		%environment/codecs/CSV.red			all
	TCP		%environment/anlaco/tcp.red		all
```

```red
; En un script:
Red [Needs: [TCP]]
tcp/connect "example.com" 80
```

**Este es el mecanismo que usamos para las librerías ANLACO.**

### Include (`#include`)

Inclusión directa de archivos. Funciona solo al compilar, no en la consola interactiva. No requiere registro previo.

```red
Red []
#include %/ruta/a/mi-lib.red
mi-funcion 42
```

**No lo usamos** porque no funciona en la consola.

---

## Nuestro enfoque: módulos `Needs` + consolas con `Needs`

La solución es híbrida:

1. **Las librerías se registran como módulos** en `encapper/modules.r`
2. **Los scripts las piden con `Needs: [TCP]`** → solo se compilan cuando se necesitan
3. **Las consolas ANLACO las incluyen en su header** → disponibles en la consola interactiva

```
┌─────────────────────────────────────────────────────┐
│ Script: Red [Needs: [TCP]]                          │
│  → Compila TCP dentro del binario                   │
│                                                      │
│ Script: Red []                                      │
│  → NO compila TCP → binario más pequeño              │
│                                                      │
│ Consola ANLACO: Red [Needs: [View JSON CSV TCP]]    │
│  → TCP siempre disponible en la consola interactiva  │
└─────────────────────────────────────────────────────┘
```

---

## Estructura de una librería ANLACO

Las librerías se colocan en `environment/anlaco/` y siguen este patrón:

```red
Red [
	Title:   "Nombre de la librería"
	Author:  "ANLACO"
	File: 	 %nombre.red
	Tabs:	 4
	Rights:  "Copyright (C) 2026 ANLACO. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

mi-lib-ctx: context [

	;-- Código Red/System puro (implementación nativa)
	#system [
		mi-funcion-native: func [
			arg1	[integer!]
			return: [integer!]
		][
			arg1 + 1
		]
	]

	;-- Puente Red → Red/System
	mi-funcion: routine [
		"Descripción de la función"
		arg1		[integer!]
		return:		[integer!]
	][
		mi-funcion-native arg1
	]
]

;-- Exportar funciones al contexto global
set 'mi-funcion :mi-lib-ctx/mi-funcion
```

### Puntos clave

1. **`context [...]`** es obligatorio para `routine`. No se puede usar `set 'word routine [...]` directamente — Red exige que las `routine` tengan nombre.
2. **`#system [...]`** contiene la implementación nativa en Red/System. Solo visible desde `routine` dentro del mismo contexto.
3. **`routine [...]`** es el puente entre Red y Red/System. Declara tipos Red y llama a la función nativa.
4. **`set 'mi-funcion :mi-lib-ctx/mi-funcion`** exporta la función al contexto global. Sin esto, la función solo existe dentro de `mi-lib-ctx`.
5. **Las funciones Red puras** (sin `routine`) no necesitan `context`:

```red
set 'mi-funcion function [
	a [integer!] b [integer!]
	return: [integer!]
][
	a + b
]
```

---

## Conflicto de símbolos con el runtime

Red/System **no tiene namespaces**. Todos los `#import` crean nombres globales. Si tu librería importa `socket`, `close`, `poll`, etc. y el runtime de Red ya los importa, el linker da error:

```
*** Linker Warning: possibly conflicting import and export symbols: close socket connect send recv
```

### Solución: prefijar todos los imports

Añadir un prefijo `tcp-` a todas las funciones importadas del sistema:

```red
; ANTES (conflicto):
#import [LIBC-file cdecl [
    socket: "socket" [...]       ; ← conflicto con el runtime
    close: "close" [...]         ; ← conflicto con el runtime
    poll: "poll" [...]           ; ← conflicto con el runtime
]]

; DESPUÉS (sin conflicto):
#import [LIBC-file cdecl [
    tcp-socket-func: "socket" [...]    ; apodo único
    tcp-close-func: "close" [...]      ; apodo único
    tcp-poll-func: "poll" [...]        ; apodo único
]]
```

La sintaxis del import es: `apodo: "nombre_real_en_C"`. El apodo es lo que usas en tu código. El nombre real es como se llama la función en la librería del sistema.

### Constantes y tipos del runtime

El runtime de Red define tipos como `pollfd!` y constantes como `POLLIN`, `O_NONBLOCK` en archivos `.reds` (Red/System). Desde `#system` dentro de un archivo `.red`, estos pueden no ser accesibles.

**Solución:** Redefinir localmente con prefijo:

```red
#system [
	#define TCP_POLLIN      0001h
	#define TCP_O_NONBLOCK  2048
	#define TCP_F_GETFL     3
	#define TCP_F_SETFL     4

	tcp-pollfd!: alias struct! [
		fd      [integer!]
		events  [integer!]
	]
]
```

### La función `platform/fcntl`

El runtime expone `platform/fcntl` en el namespace `red/platform`, pero desde `#system` en un `.red` puede no ser accesible.

**Solución:** Importar `fcntl` directamente desde libc:

```red
#import [LIBC-file cdecl [
    tcp-fcntl: "fcntl" [
        [variadic]
        return: [integer!]
    ]
]]
```

### Tipos personalizados en `#import`

Los tipos como `tcp-pollfd!` no se pueden usar como parámetros en `#import` de libRedRT. Usar `byte-ptr!` en su lugar:

```red
; ANTES (error):
tcp-poll-func: "poll" [
    fds         [tcp-pollfd!]    ; ← tipo no estándar, error en libRedRT
    ...
]

; DESPUÉS (correcto):
tcp-poll-func: "poll" [
    fds         [byte-ptr!]      ; ← tipo estándar
    ...
]

; Y hacer casting en la llamada:
result: tcp-poll-func as byte-ptr! pfd 1 timeout-ms
```

---

## Paso a paso: añadir una nueva librería

### Paso 1: Crear el archivo

Colocar en `environment/anlaco/`:

```
red/
├── environment/
│   ├── anlaco/
│   │   └── mi-lib.red        ← NUEVA LIBRERÍA
│   └── ...
```

### Paso 2: Registrar en `encapper/modules.r`

Añadir una línea al final de la tabla:

```rebol
;-- Name ------ Entry file ----------------------------- OS availability -----
	View		%modules/view/view.red					all
	JSON		%environment/codecs/JSON.red			all
	CSV 		%environment/codecs/CSV.red				all
	TCP		%environment/anlaco/tcp.red			all
	MiLib		%environment/anlaco/mi-lib.red			all
```

El nombre (`MiLib`) es lo que los scripts usan en `Needs: [MiLib]`.

### Paso 3: Añadir en `build/includes.r`

En la sección `%environment/`, añadir en el subdirectorio `%anlaco/`:

```rebol
	%environment/ [
		; ... otros archivos ...
		%anlaco/ [
			%tcp.red
			%mi-lib.red        ; ← AÑADIR
		]
		; ...
	]
```

`includes.r` define qué archivos se empaquetan en el binario encap. Si no se añade aquí, el módulo no estará disponible cuando se compile desde el binario autocontenido.

### Paso 4: Añadir `Needs` en las consolas (opcional)

Si quieres que la librería esté disponible en la consola interactiva, añadir el nombre del módulo en el header de las consolas:

**`environment/console/CLI/console.red`:**
```red
Red [
	Title:	"Red console"
	Needs:	[JSON CSV View MiLib]        ; ← añadir MiLib
	Config: [GUI-engine: 'terminal]
	; ...
]
```

**`environment/console/GUI/gui-console.red`:**
```red
Red [
	Title:	 "Red GUI Console"
	Needs:	 [View JSON CSV MiLib]        ; ← añadir MiLib
	Config:	 [gui-console?: yes red-help?: yes]
	; ...
]
```

Si no añades el módulo en las consolas, la librería **no estará disponible en la consola interactiva**. Solo estará disponible en scripts compilados que incluyan `Needs: [MiLib]`.

### Paso 5: Reconstruir

```bash
cd /ruta/a/red

# 1. Reconstruir libRedRT (requerido si la librería tiene routine o #system)
./rebol-core/rebol -qws red.r -u %environment/console/CLI/console.red

# 2. Compilar consola CLI
cat > build-cli.r << 'EOF'
REBOL [Title: "Build CLI console"]
do/args %red.r "-r %environment/console/CLI/console.red"
quit
EOF
./rebol-core/rebol -qws build-cli.r

# 3. Compilar consola GUI (GTK3 en Linux)
cat > build-gui.r << 'EOF'
REBOL [Title: "Build GUI console"]
do/args %red.r "-r -t Linux-GTK %environment/console/GUI/gui-console.red"
quit
EOF
./rebol-core/rebol -qws build-gui.r
```

Para otras plataformas:
```bash
# Windows
./rebol-core/rebol -qws red.r "-r -t Windows %environment/console/GUI/gui-console.red"

# macOS
./rebol-core/rebol -qws red.r "-r -t Darwin %environment/console/GUI/gui-console.red"
```

### Paso 6: Verificar

#### En la consola interactiva

```bash
./console
```

```red
>> mi-funcion 42
== 43
```

#### En un script compilado con `Needs`

Crear `test.red`:

```red
Red [Needs: [MiLib]]
print ["mi-funcion 10 =" mi-funcion 10]
```

```bash
./rebol-core/rebol -qws red.r -r test.red
./test
```

Salida: `mi-funcion 10 = 11`

#### En un script SIN `Needs`

Crear `test2.red`:

```red
Red []
mi-funcion 42
```

```bash
./rebol-core/rebol -qws red.r -r test2.red
```

Error: `*** Compilation Error: undefined word mi-funcion`

Esto es correcto — la librería solo se incluye cuando se pide explícitamente.

---

## Estructura de archivos completa

```
red/
├── environment/
│   ├── anlaco/
│   │   └── tcp.red                  ← NUESTRAS LIBRERÍAS
│   ├── codecs/
│   ├── console/
│   │   ├── CLI/
│   │   │   └── console.red          ← Needs: [JSON CSV View TCP]
│   │   └── GUI/
│   │       └── gui-console.red      ← Needs: [View JSON CSV TCP]
│   └── ...
├── encapper/
│   ├── boot.red                     ← NO MODIFICAR (solo entorno base)
│   ├── compiler.r
│   └── modules.r                    ← REGISTRAR MÓDULOS AQUÍ
├── build/
│   └── includes.r                  ← AÑADIR ARCHIVOS AQUÍ
├── libRedRT.so                      (rebuild con -u)
└── console / gui-console            (binarios reconstruidos)
```

---

## Resumen del flujo completo

```
1. Crear environment/anlaco/mi-lib.red
2. Registrar en encapper/modules.r        → Needs: [MiLib] en scripts
3. Añadir %mi-lib.red en build/includes.r → para empaquetado
4. (Opcional) Añadir MiLib en Needs de las consolas
5. ./rebol-core/rebol -qws red.r -u %environment/console/CLI/console.red
6. Reconstruir consolas (build-cli.r / build-gui.r)
7. Verificar:
   - ./console → mi-funcion               (si está en Needs de la consola)
   - Red [Needs: [MiLib]] → mi-funcion    (en scripts compilados)
   - Red [] → undefined word mi-funcion   (sin Needs, correctamente)
```

---

## Troubleshooting

### `*** Linker Warning: possibly conflicting import and export symbols`

Los nombres de tus `#import` colisionan con el runtime de Red. Solución: prefijar todos los imports (ver sección "Conflicto de símbolos").

### `*** Error: a routine must have a name`

Las `routine` no se pueden definir con `set` directamente. Usar `context` + `set` de exportación:

```red
mi-ctx: context [
	mi-funcion: routine [return: [integer!]][ 42 ]
]
set 'mi-funcion :mi-ctx/mi-funcion
```

### `*** Script Error: mi-funcion is unset`

La función no se exportó al contexto global. Asegurarse de que `set 'mi-funcion :mi-ctx/mi-funcion` está presente.

### `*** Compilation Error: invalid path value`

Un tipo personalizado (como `tcp-pollfd!`) se usó en un `#import` de libRedRT. Solución: usar `byte-ptr!` y hacer casting manual.

### `*** Compilation Error: module not found: MiLib`

El módulo no está registrado en `encapper/modules.r`. Añadir la entrada:

```rebol
MiLib		%environment/anlaco/mi-lib.red		all
```

### `?routine?` al ejecutar el binario

Si un binario compilado con `--dev` muestra `?routine?`, no encuentra `libRedRT.so`. Solución:

```bash
LD_LIBRARY_PATH=. ./mi-binario
```

O compilar en modo release (`-r`):

```bash
./rebol-core/rebol -qws red.r -r test.red
```

### Los cambios en la librería no se reflejan

Después de modificar archivos con `routine` o `#system`, reconstruir libRedRT:

```bash
./rebol-core/rebol -qws red.r -u %environment/console/CLI/console.red
```

Después de cambios en funciones Red puras (sin routine), basta con recompilar:

```bash
./rebol-core/rebol -qws red.r -c test.red
```

### Directorio de trabajo

Los comandos de compilación deben ejecutarse desde el directorio raíz del repositorio (`red/`), donde está `red.r`.