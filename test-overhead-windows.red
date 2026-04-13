Red [
    Title: "Test overhead — Windows (sin correcciones)"
    Needs: 'View
]

; ── Observador básico para Windows ────────────────────────────────
; En Windows las decoraciones son server-side (SSD): el SO gestiona
; el título y bordes. Red/View expone el área cliente en face/size.
; Se mide el overhead al primer on-time igual que en GTK para ver
; qué reporta Windows realmente — sin ningún workaround.

_spec-size:     600x400
_csd-overhead:  0x0
_last-size:     0x0
_event-log:     copy []
_tick:          0
_log-file:      %test-overhead-windows.log

write _log-file ""

canvas: make face! [
    type:   'base
    size:   580x380
    offset: 5x5
    color:  240.240.245
    draw:   []
]

log-event: func [label extra /local entry] [
    _tick: _tick + 1
    entry: rejoin ["#" _tick " " label " " extra]
    _event-log: head insert _event-log entry
    if (length? _event-log) > 12 [
        _event-log: copy/part _event-log 12
    ]
    write/append _log-file rejoin [entry newline]
]

log-size: func [label sz /local dx dy delta] [
    delta: ""
    if _last-size <> 0x0 [
        dx: sz/x - _last-size/x
        dy: sz/y - _last-size/y
        if any [dx <> 0  dy <> 0] [
            delta: rejoin [" Δ=" dx "x" dy]
        ]
    ]
    log-event label rejoin ["win:" sz delta]
    _last-size: sz
]

render-canvas: func [win /local cw ch _n] [
    cw: win/size/x - _csd-overhead/x - 10
    ch: win/size/y - _csd-overhead/y - 10
    if cw < 50 [cw: 50]
    if ch < 50 [ch: 50]
    canvas/size: as-pair cw ch
    canvas/draw: compose [
        pen red line-width 3
        fill-pen off
        box 1x1 (canvas/size - 2x2)
        pen black
        text 10x8  (rejoin ["canvas/size: " canvas/size])
        text 10x26 (rejoin ["win/size:    " win/size])
        text 10x44 (rejoin ["csd-overhead:" _csd-overhead " (medido)"])
        text 10x62 (rejoin ["ticks:       " _tick])
        pen gray
        line 10x82 (as-pair (cw - 10) 82)
        pen blue
        text 10x88 "-- EVENT LOG (más reciente arriba) --"
    ]
    _n: 0
    foreach entry _event-log [
        append canvas/draw compose [
            pen black
            text (as-pair 10 (108 + (_n * 16))) (entry)
        ]
        _n: _n + 1
    ]
]

win: make face! [
    type:   'window
    text:   "Test overhead — Windows"
    size:   _spec-size
    offset: 100x100
    flags:  [resize]
    color:  white
    pane:   reduce [canvas]
    rate:   0:0:0.2
    actors: make object! [
        on-resize: func [face event] [
            log-size "on-resize" face/size
            render-canvas face
        ]
        on-time: func [face event] [
            face/rate: none
            log-size "on-time" face/size
            if _csd-overhead = 0x0 [
                _csd-overhead: face/size - _spec-size
                log-event "INIT" rejoin ["overhead=" _csd-overhead]
            ]
            render-canvas face
        ]
        on-focus: func [face event] [
            log-size "on-focus" face/size
        ]
        on-unfocus: func [face event] [
            log-size "on-unfocus" face/size
        ]
    ]
]

view win
