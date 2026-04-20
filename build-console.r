REBOL [
	Title:	 "Build Red consoles (CLI + GUI)"
	Author:	 "ANLACO"
	File:	 %build-console.r
	Tabs:	 4
	Purpose: {
		Compila las consolas CLI y GUI de Red de forma rapida
		desde la consola Rebol.

		Uso (desde raiz del repo):
		    do %build-console.r
		    do %build-console.r --cli
		    do %build-console.r --gui --release
		    do %build-console.r --both
	}
]

do %red.r

cli-src:	%environment/console/CLI/console.red
gui-src:	%environment/console/GUI/gui-console.red

mode:		'dev
target:		'both
verbose:	0
cli-target:	"Linux"
gui-target:	"Linux-GTK"

print-help: does [
	print {
Build Red Console - Compilacion rapida

Uso:
    do %build-console.r [opciones]

Opciones:
    --cli          Solo consola CLI (terminal)
    --gui          Solo consola GUI (GTK3)
    --both         Ambas consolas (por defecto)
    --dev          Modo desarrollo (por defecto, usa libRedRT)
    --release      Modo release (binario independiente)
    --gtk          Target GUI = Linux-GTK (por defecto)
    --linux        Target CLI = Linux (por defecto)
    --verbose N    Nivel de verbose (0-6)
    --help         Esta ayuda

Ejemplos:
    do %build-console.r --cli --dev
    do %build-console.r --gui --release --gtk
    do %build-console.r --both --verbose 3
}
]

parse-args: func [args [string!] /local tokens][
	tokens: parse args none
	while [not tail? tokens][
		switch first tokens [
			"--cli"		[target: 'cli]
			"--gui"		[target: 'gui]
			"--both"	[target: 'both]
			"--dev"		[mode: 'dev]
			"--release"	[mode: 'release]
			"--gtk"		[gui-target: "Linux-GTK"]
			"--linux"	[cli-target: "Linux"]
			"--verbose"	[
				tokens: next tokens
				if not tail? tokens [
					verbose: to-integer first tokens
				]
			]
			"--help"	[print-help quit/return 0]
			--default	[
				print ["Opcion desconocida:" first tokens]
				print-help quit/return 1
			]
		]
		tokens: next tokens
	]
]

build-console: func [src [file!] target-spec [string!] /local cmd t0 t1][
	print [
		newline
		"=== Compilando:" mold src "==="		newline
		"  Modo:" either mode = 'release ["release"]["dev"]		newline
		"  Target:" target-spec					newline
	]

	cmd: rejoin [
		either mode = 'release ["-r"]["-c"]
		" -t " target-spec
		" " either verbose > 0 [rejoin ["-v " verbose " "]][]
		mold src
	]

	t0: now/time/precise
	redc/main/with cmd
	t1: now/time/precise

	print [newline "=== Tiempo:" round/to t1 - t0 0:00:01 "===" newline]
]

if system/options/args [parse-args system/options/args]

print {
========================================
  Red Console Builder
========================================
}

case [
	target = 'cli	[build-console cli-src cli-target]
	target = 'gui	[build-console gui-src gui-target]
	target = 'both	[
		build-console cli-src cli-target
		build-console gui-src gui-target
	]
]

print {
========================================
  Compilacion finalizada
========================================
}