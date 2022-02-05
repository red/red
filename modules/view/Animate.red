Red [
    title: "Animation dialect tests"
    author: "Galen Ivanov"
    needs: view
]

; Docs and test at %https://github.com/GalenIvanov/Animation-tests 

st-time: now/precise
pascal: none
text-data: make map! 20
draw-blocks-data: make map! 20 
timeline: make map! 100 ; the timeline of effects key: value <- id: effect
time-map: make map! 100 ; for the named animations
text-fx-map: make map! 10
particles-map: make map! 10
curve-fx-map: make map! 10
curve-fx-init: make block! 10
scaled-fonts: copy []
stroke-path-map: make map! 10
morph-path-map: make map! 10
dummy: 0

random/seed now

effect: make object! [
    val1:       0.0          ; starting value to change
    val2:       1.0          ; end value
    start:      0.0          ; starting time
    dur:        1.0          ; duration of the animation
    delay:      0.0          ; delay between successive subanimations
    loop-count: 1            ; repetitions of the effect in time
    bi-dir:     off          ; does the animation runs backwards too? 
    started:    false        ; has the animation started?
    on-start:   []           ; actor   
    on-time:    []           ; actor
    on-exit:    []           ; actor  
    ease:       func [x][x]  ; easing function
]

text-effect: make object! [
    id: none        ; 
    text: ""        ; text to render   
    font: none      ; font to use
    mode: 'chars    ; how to split the text  
    from: 'center   ; origin of scaling
    posXY: 0x0      ; where to place the text  
    sp-x:  1.0      ; spacing factor for X direction
    sp-y:  1.0      ; spacing factor for Y direction
    start: 0.0      ; starting time
    dur:   1.0      ; duration 
    delay: 0.1      ; delay between subanimations
    expires: 0      ; when to remove the text primitives from the draw block 
                    ; if zero, uses the end of the last animation of the effect 
    random: false
]

process-timeline: has [
    t target v w d
][
    t: to float! difference now/precise st-time
    
    foreach [key val] timeline [
        w: val/2
        if w/val1 <> w/val2 [tween val/1 w/val1 w/val2 w/start w/dur t :w/ease]
        
        if t > w/start[
            unless w/started [
                do w/on-start
                w/started: true
            ]
            either t < (w/start + w/dur) [
                bind w/on-time context compose [time: (t)]  ; makes elapsed time visible to the caller as "time"
                do w/on-time
            ][
                d: w/dur
                if w/bi-dir [d: d * 2]        ; two-way loop - reset after 2 x duration
                either w/loop-count = -1 [    ; loop forever
                    w/start: w/start + d
                ][ 
                    either w/loop-count > 1 [
                        w/loop-count: w/loop-count - 1
                        w/start: w/start + d
                    ][
                        do w/on-exit
                        remove/key timeline key
                    ]    
                ]                    
            ]
        ]    
    ]
    
    foreach [key effect] particles-map [
        proto: effect/proto
        if t >= proto/start [
            either t <= (proto/start + proto/duration) [
                particle/update-particles to-word key
            ][
                if t > proto/expires [
                    clear at get key 3
                    remove/key particles-map key
                ]
            ]
        ]
    ]
    
    foreach [key v] curve-fx-map [
        target: 0.0
        if t >= v/start [
            either t <= (v/start + v/dur * 1.01) [
                tween 'target v/v1 v/v2 v/start v/dur t get v/ease
                switch/default v/type [
                    text  [text-along-curve v/id target]
                    block [block-along-curve v/id target]
                ][print "Unsupported effect type - must be text or block"]
            ][
                if all [v/expires <> 0 t > v/expires] [
                   remove/key curve-fx-map key
                   clear first get v/id  ; clear the effect's draw block
                ]   
            ]               
        ]
    ]
    
    ;clean-up text-fx
    foreach [key v] text-fx-map [
        if all [v <> 0 t > (1.02 * v)] [
            clear pick get key 1
            remove/key text-fx-map key
        ]
    ]
    
    foreach [key v] stroke-path-map [
        target: 0.0
        if t >= v/start [
            either t <= (v/start + v/duration) [
                tween 'target 0.0 1.0 v/start v/duration t get v/ease
                trace-path to-word key target
            ][
                trace-path to-word key 1.0 
                if all [v/expires > 0 t > v/expires] [
                    remove/key stroke-path-map key
                    clear first get key
                ]    
            ]
        ]
    ]
    
    foreach [key v] morph-path-map [
        s: v/started
        if all [t > (0.98 * v/start) not s][
            clear p: get to-path reduce [to-word key 1]
            append p v/block-1
            v/started: on
        ]
        
        if all [t >= v/start s] [
            either t <= (v/start + v/duration) [
                repeat n length? at v/block-1 2[
                    k: n + 1
                    tween to-path reduce [to-word key 1 k] v/block-1/:k v/block-2/:k v/start v/duration t get v/ease
                ]
            ][
               clear p: get to-path reduce [to-word key 1]
               append p v/end-block
               if all [v/expires > 0 t > v/expires] [
                   clear p
                   remove/key morph-path-map key
               ]    
            ]
        ]
    ]
    
    ani-start/2: 0.1  ; refresh the draw block in case onli font or image parameters have been changed
]

;-----------------------------------------------
; predifined forces effecting particles motion
; always take 2 rguments: direction and speed
; should return a block [dir speed]
;-----------------------------------------------
drag: func [dir speed][
    speed: speed * 0.99
    reduce [dir speed]
]

gravity: func [dir speed][
    vx: speed * cosine dir
    vy: speed *   sine dir
    vy: vy + 0.2  ; coef
    dir: arctangent2 vy vx
    speed: sqrt vx * vx + (vy * vy)
    reduce [dir speed]
]

particle: context [
    speck: [  ; a default template for particles
        [fill-pen 240.240.255.30 circle 0x0 5]
    ] 

    particle-base: make object! [
        number:     100                  ; how many particles
        start:      1.0                  ; start time of the effect
        duration:   5.0                  ; duration of the effect
        emitter:    [0x100 200x100]      ; where particles are born - a box
        direction:  90.0                 ; degrees
        dir-rnd:    0.0                  ; random spread of direction, symmetric
        speed:      1.0                  ; particle base speed
        speed-rnd:  0.2                  ; randomization of speed for each particle, always added
        shapes:     speck                ; a block of draw blocks (shapes to be used to render particles)
        forces:     []                   ; what forces affect the particles motion - a block of words
        limits:     []                   ; conditions for particle to be respawned - based on coordinates 
        new-coords: []                  ; where reposition the particle
        started:    false
        finished:   false
        expires:    0                   ; when to clear the particle draw block
        on-start:   []
        on-time:    []
        on-exit:    []
    ]
    
    create-particle: func [
        {Instantiates a sinlge particle using the prototype}
        proto [object!]
        /local
            em
            px  {position x}
            py  {position y}
            d   {direction}
            s   {speed}
    ][
        em: proto/emitter
        px: (em/1/x + random 1.0 * em/2/x - em/1/x) * 10.0 
        py: (em/1/y + random 1.0 * em/2/y - em/1/y) * 10.0 
        d: proto/direction - (proto/dir-rnd / 2.0) + random to-float proto/dir-rnd
        s: proto/speed + random to-float proto/speed-rnd
        shape: autoscale random/only proto/shapes
        reduce [px py d s shape]
    ]
    
    init-particles: func [
        {Populates a named set of particles using a prototype}
        id    [word!]       ; particles set identifier
        proto [object!]     ; particle-base object
        idx   [integer!]    ; unique identifier
        /local
            particles 
            particles-draw
            d n p
    ][
        particles: make block! 2 * n: proto/number
        f-body: 
        append particles reduce [
            'proto proto
            'respawn make function! compose/deep [
                [x y]
                [
                    c: false
                    if any [(proto/limits)] [
                        c: true
                        (proto/new-coords)
                    ] 
                    reduce [c x y]
                ]
            ]
            'spec copy []
            'draw copy []
        ]
        particles-draw: make block! 3 * n: proto/number 
        append particles-draw compose [(to-set-word rejoin [id "-" idx]) translate 0x0]
        
        loop n [
            p:  create-particle proto
            append/only particles/spec p
            d: compose/deep [translate (as-pair to-integer p/1 to-integer p/2) [(p/5)]]
            append particles/draw d
        ]
        ;put particles-map id particles        
        put particles-map to-word rejoin [id "-" idx] particles
        head append/only particles-draw particles/draw
    ]
    
    update-particles: func [
        id [word!]
        /local
           respawn i p ps pd tmp new-p
    ][
        ps: particles-map/:id/spec
        pd: particles-map/:id/draw
        
        repeat i length? ps [
            p: ps/:i
            ; check of it's time to respawn the particle
            ;tmp: particles-map/:id/proto/limits 0.1 * p/1 0.1 * p/2
            tmp: particles-map/:id/respawn 0.1 * p/1 0.1 * p/2
            if tmp/1 [
                new-p: create-particle particles-map/:id/proto
                p/1: 10.0 * tmp/2
                p/2: 10.0 * tmp/3
                p/3: new-p/3
                p/4: new-p/4
            ]
            
            ; apply forces - they make changes in place
            foreach force particles-map/:id/proto/forces [
                tmp: do reduce [:force p/3 p/4]
                p/3: tmp/1
                p/4: tmp/2
            ]
            
            ; calculate new position
            p/1:  p/4 * (cosine p/3) + p/1  
            p/2:  p/4 * (  sine p/3) + p/2
            pd/2: as-pair to-integer p/1 to-integer p/2
            pd: skip pd 3
        ]
    ]
]

do-not-scale: [
    ; this list might not be complete! 
    [circle 4]
    [circle 5] 
    [arc 4]
    [arc 5]
    [rotate 2]
    [scale 2]
    [scale 3]           
    [skew 2]
    [skew 3]
    [transform 3]
    [transform 4]
]

draw-words: split {line triangle box polygon circle ellipse arc curve spline
image text font pen fill-pen linear radial diamond pattern bitmap
line-width line-join line-cap anti-alias matrix reset-matrix
invert-matrix push rotate scale translate skew transform
clip shape move line arc curve curv qcurve qcurv hline vline} charset reduce [space newline]

draw-cmd: head clear back tail collect [
    foreach w difference draw-words split "linear radial diamond pattern bitmap" sp [
        keep to-lit-word w keep '|
    ]
]

autoscale: function [
    {Multiplies by 10 the linear sizes of draw block commands
    Used for subpixel precision,
    Returns a modified block}
    src [block!]
][
    dest: copy/deep src
    target: none
    offs: 1
    k: 1
    parse dest rule: [
        any [
            p: set target word! (offs: 1 k: 1)    
          | p: change [[integer! | float! | pair!] (offs: offs + 1)]
            (
                if not find/only do-not-scale reduce[target offs] [k: 10]
                p/1 * k
            )
          | tuple! | string!
          | into rule             
        ] 
    ]
    dest
]

context [
    ani-bl: copy []
    draw-block: make block! 1000
    cur-effect: make block! 20
    delay-v: 0.0
    start-v: 0.0
    start-anchor: 0
    dur-v: 0.0
    ease-v: none
    ref-ofs: 0.0
    val-ofs: 1
    val-idx: 1
    cur-idx: 0
    target: none
    cur-target: none
    user-target: none
    cur-effect: none
    time-id: none
    cur-ref: none
    scaled: none
    from-count: 0
    text-fx-id: 1
    loop-n: 1
    bi-dir: off
    t-fx: none
    st: none
    time-dir: 1  ; for referencing animations anchors, -1 means backwards
    t-offs: none
    new-fx: false
    path-id: none
    path-block: none
    from-on-start: copy []
    from-on-time: copy []
    from-on-exit: copy []
    pen-scale: 1.0
    
    make-effect: does [
        ani-bl: copy/part to-block effect 22
        append ani-bl [ease: none] 
        ani-bl/val1: v1
        ani-bl/val2: v2
        ani-bl/start: start-v
        ani-bl/dur: any [dur-v 1.0]
        ani-bl/delay: any [delay-v 0.0]
        ani-bl/loop-count: 1
        ani-bl/bi-dir: off
        ani-bl/ease: any [:ease-v to get-word! "ease-linear"]
        ani-bl/on-start: from-on-start 
        ani-bl/on-time: from-on-time
        ani-bl/on-exit: from-on-exit
        ani-bl/started: false
    ]   

    clear-anim-actors: does [
        from-on-start: copy []
        from-on-time: copy  []
        from-on-exit: copy  []
    ]
    
    text-fx-actors: does [
        v1: v2: 0
        make-effect  ; for a dummy tween that will manage actors
        target: to-word rejoin [txt-w cur-idx]
        cur-idx: cur-idx + 1
        cur-target: 'dummy
        cur-effect: make effect ani-bl
        cur-effect/dur: delay-v * from-count + dur-v
        put timeline target reduce [cur-target cur-effect]
        clear-anim-actors
    ]
    
    rescale: does [
        if all [
            find [integer! float! pair!] type?/word scaled
            not find/only do-not-scale reduce[target val-idx]
        ] [scaled: scaled * pen-scale * 10]
    ]
    
    value: [set scaled [float! | tuple! | string! | object! | integer! | pair!] (rescale)]
    
    start: [
        [
            p: 'start  (
                start-v: 0.0
                time-dir: 1
                ease-v: none
                ref-ofs: 0
                bi-dir: off
                loop-n: 1
                if cur-ref [   ; reg the previously named entry
                    put time-map cur-ref reduce [start-anchor dur-v delay-v from-count]
                    time-map/:cur-ref 
                ]
            ) 
            [
            set st [number! ahead not ['when | 'after | 'before]] (start-v: st)
            | [
                opt set t-offs number!
                ['when | 'after | 'before (time-dir: -1)]
                set ref word! (id: time-map/:ref start-v: id/1)
                [
                    'starts (ref-ofs: 0)
                  | 'ends (
                        ref-ofs: id/3 * id/4 + id/2
                        from-count: 0 ; ???
                    )
                ]
            ]
            ]
        ](
            t-offs: any [t-offs 0.0] 
            start-v: t-offs * time-dir + ref-ofs + start-v
            start-anchor: start-v
            cur-ref: time-id
            ref-ofs: 0
            t-offs: none
            delay-v: 0.0
            st: none
        )
    ]
    
    dur: [['duration set d number!] (dur-v: d)]
    
    delay: [['delay set dl number!](delay-v: dl)]
    
    ease: ['ease set ease-v any-word!]
    
    anim-loop: [
        'loop
        p: opt 'two-way (if p/1 = 'two-way [bi-dir: on])
        opt ['forever (loop-n: -1) | set loop-n integer! 'times ]
    ]
    
    anim-actors: [ 
        any [
            ['on-start set from-on-start block!] 
          | ['on-time  set from-on-time  block!]
          | ['on-exit  set from-on-exit  block!]
        ]      
    ]
    
    word-val: [
        w: word!
        if (not find draw-words lowercase form w/1) 
    ]
    
    keep-word-val: [
        w: word!
        if (not find draw-words lowercase form w/1) 
        :w keep word!
    ]
   
    from-value: [set v2 word-val | value (v2: scaled)]
    
    from: [
        [
            'from p1: [[set v1 keep-word-val ] | value keep (scaled) (v1: scaled)]
            'to p2: from-value (clear-anim-actors)
            opt anim-actors
        ] (
            make-effect
            ani-bl/loop-count: loop-n
            cur-effect: make effect ani-bl
            trgt: to-path reduce [to-word cur-target val-ofs]
            cur-effect/start: start-v
            either bi-dir [
                ani-bl/start: start-v
                ani-bl/dur: ani-bl/dur / 2.0
                ani-bl/bi-dir: on
                cur-effect: make effect ani-bl
                cur-effect/on-exit: copy []  ; on-exit will trigger only at the backward tween
                put timeline to-string trgt reduce [trgt cur-effect]  ; forward
                ani-bl/start: start-v + ani-bl/dur
                tmp: ani-bl/val1
                ani-bl/val1: ani-bl/val2
                ani-bl/val2: tmp
                cur-effect: make effect ani-bl 
                cur-effect/on-start: copy []  ; on-start wiil be trigegered only for the forward tween 
                put timeline rejoin [form trgt "_r"] reduce [trgt cur-effect] ; backward
            ][
                put timeline to-string trgt reduce [trgt cur-effect]
            ]    
            start-v: start-v + delay-v
            from-count: from-count + 1
         )
    ]
    
    param: [
        'parameter (clear-anim-actors)
        set t [path! | word!] (cur-target: t cur-idx: cur-idx + 1)
        'from set v1 skip 'to set v2 skip (
            make-effect        
            cur-effect: make effect ani-bl
            cur-effect/start: start-v
            start-v: start-v + delay-v
            put timeline rejoin [to-string cur-target cur-idx] reduce [cur-target cur-effect]
            from-count: from-count + 1
        )    
    ]
    
    ; Draw commands and markers for them
    word: [                             
        opt [set user-target set-word!]
        p: word!
        (
            val-ofs: 2
            val-idx: 1
            target: p/1
            cur-target: any [user-target rejoin [p/1 cur-idx]]
            if 'font = target [
                fnt: get p/2
                unless find scaled-fonts p/2 [
                    fnt/size: fnt/size * 10
                    append scaled-fonts p/2
                ]    
            ]
            if 'text = target [
                print ["text" val-ofs]
            ]
        )
        opt pens ; (val-ofs: val-ofs + 1 val-idx: val-idx + 1)]
        w1: to [draw-cmd | end]
        w2: [ 
            [ 
                if (any [user-target find copy/part w1 w2 'from])
                keep (to-set-word cur-target) ; marker
                :p keep word!
                (user-target: none cur-idx: cur-idx + 1)
            ]
          | :p keep word!
        ]
        opt [keep pens (scale-pen: 0.1 val-ofs: val-ofs + 1 val-idx: val-idx + 1)]
    ]
    
    particles: [
        'particles (
            particles-end: 0
            clear-anim-actors
        )
        set p-id word!
        set p-proto word! 
        (
           prt: get p-proto
           append prt compose [start: (start-v)]
           append prt compose [duration: (dur-v)]
        )
        opt [
                'expires [
                    ['after set particles-end number!] 
                  | 'never
                ]
                (if particles-end > 0 [append prt compose [expires: (max start-v + dur-v start-v + particles-end)]])
        ]
        opt anim-actors
        (
           v1: v2: 0
           make-effect  ; for a dummy tween that will manage actors
           cur-target: 'dummy
           cur-effect: make effect ani-bl
           put timeline p-id reduce [cur-target cur-effect]
           start-v: start-v + delay-v
           from-count: from-count + 1
        )   
        keep (particle/init-particles p-id make particle/particle-base prt cur-idx)
    ]
    
    curve-fx: [
        [
            'curve-fx (
                v2: none
                curve-fx-end: 0
                ease-v: any [:ease-v to get-word! "ease-linear"]
                clear-anim-actors
            )
            set crv-id word!
            set crv-data [block! | word!] 
            [
                ['from set v1 float! 'to set v2 float!]
                | set v1 float!
            ]
            opt [
                'expires [
                    ['after set curve-fx-end number!] 
                  | 'never
                ]  
            ]
            opt anim-actors (
                make-effect  ; for a dummy tween that will manage actors
                cur-target: 'dummy
                cur-effect: make effect ani-bl
                put timeline crv-id reduce [cur-target cur-effect]
            )
        ]
        (
            v2: any [v2 v1]
            if curve-fx-end > 0 [curve-fx-end: max start-v + curve-fx-end start-v + dur-v]
            if word? s-crv-data: select args: get crv-data 'data [s-crv-data: get s-crv-data]
            ; check if we are to move text or draw block along curve
            either string? s-crv-data [
                draw-data: text-along-curve/init crv-id v1 s-crv-data get args/font get args/curve args/space-x
                fx-type: 'text
            ][  ; block
                draw-data: block-along-curve/init crv-id v1 s-crv-data get args/curve args/space-x
                fx-type: 'block
            ]
            put curve-fx-map crv-lbl: to-word rejoin [crv-id "-" cur-idx] compose [
                id: (crv-id)
                start: (start-v)
                dur: (dur-v)
                v1: (v1)
                v2: (v2)
                ease: (:ease-v)
                expires: (curve-fx-end)
                type: (fx-type)
            ]
           
            cur-idx: cur-idx + 1            
            start-v: start-v + delay-v
            from-count: from-count + 1
        )
        keep (either find curve-fx-init crv-id [[]][to-set-word crv-id])
        keep (either find curve-fx-init crv-id [[]][also draw-data append curve-fx-init crv-id])
    ]
    
    scale-origin:  func [
        txt  "target text object"
        n    "index of text part to adjust"
        mode "scale origin"
        sc   "scale factor"
    ][
       sc-p: select [     ; scale adjustments
            top-left:     -2x-2
            top:          -2x-2 
            top-right:     2x-2 
            left:         -2x-2 
            center:        0x0 
            right:         2x-2 
            bottom-left:  -2x2 
            bottom:       -2x2 
            bottom-right:  2x2 
        ] mode
        pos: txt/:n/2 
        size: txt/:n/3
        size / 2 * sc-p * sc + size / 2 + pos
    ]
    
    scale-adjust: func [
        txt  "target text object"
        n    "index of text part to adjust"
        mode "scale origin"
        sc   "scale factor"
    ][
       sc-adj: select [  
            top-left:     0x0
            top:          0x0 
            top-right:    -2x0 
            left:         0x0 
            center:       -1x-1 
            right:        -2x0
            bottom-left:  0x-2 
            bottom:       0x-2
            bottom-right: -2x-2 
        ] mode
        sc-adj * sc * txt/:n/3 / 2
    ]
    
    scale-text-fx: func [
        txt-obj
        v1
        v2
        time
    ][
        txt: text-data/(txt-obj/id)/2
        mode: text-data/(txt-obj/id)/4/from
        sp-x: text-data/(txt-obj/id)/4/sp-x
        sp-y: text-data/(txt-obj/id)/4/sp-y
        
        dly: delay-v / text-data/(txt-obj/id)/4/delay
        
        repeat n length? txt [
            make-effect            
            ani-bl/start: txt/:n/5 * dly + time
            
            cur-target: to-path reduce [to-word rejoin [t-obj/id "-" n] 5 2]
            ani-bl/val1: v1/1
            ani-bl/val2: v1/2
            cur-effect: make effect ani-bl
            put timeline to-string rejoin [cur-target cur-idx] reduce [cur-target cur-effect]
            
            cur-target: to-path reduce [to-word rejoin [t-obj/id "-" n] 5 3]
            ani-bl/val1: v2/1
            ani-bl/val2: v2/2
            cur-effect: make effect ani-bl
            put timeline to-string rejoin [cur-target cur-idx] reduce [cur-target cur-effect]
                        
            sc-t: max v1/1 v2/1
            ani-bl/val1: scale-origin txt n mode sc-t
            if any [v1/1 > v1/2 v2/1 > v2/2] [
                ani-bl/val1: ani-bl/val1 + scale-adjust txt n mode sc-t
            ]
            
            sc-t: max v1/2 v2/2
            ani-bl/val2: (scale-origin txt n mode sc-t) + scale-adjust txt n mode sc-t
            scale-from: text-data/(txt-obj/id)/effect/from
            if (scale-from <> 'center) and to logic! any [v1/1 > v1/2 v2/1 > v2/2] [
                ani-bl/val2: scale-origin txt n mode sc-t
            ]
            
            cur-effect: make effect ani-bl
            cur-target: to-path reduce [to-word rejoin [t-obj/id "-" n] 4]
            put timeline to-string rejoin [cur-target cur-idx] reduce [cur-target cur-effect]
        ]
        cur-idx: cur-idx + 1 
    ]
    
    text-color: func [
        txt-obj
        v1
        v2
        time
    ][
        txt: text-data/(txt-obj/id)
        dly: delay-v / text-data/(txt-obj/id)/4/delay
        n: 1
        foreach item txt/chunks [
            make-effect            
            ani-bl/start: item/5 * dly + time
            ani-bl/val1: v1
            ani-bl/val2: v2
            cur-effect: make effect ani-bl
            fnt-id: to word! rejoin [item/1 "-fnt"]
            cur-target: to path! reduce [fnt-id 'color]
            put timeline to-string rejoin [fnt-id cur-idx] reduce [cur-target cur-effect]
            n: n + 1
        ]
        cur-idx: cur-idx + 1 
    ]
    
    text-move: func [
        txt-obj
        val
        time
    ][
        txt: text-data/(txt-obj/id)
        val: val * 10
        dly: delay-v / text-data/(txt-obj/id)/4/delay
        n: 1
        foreach item txt/chunks [
            make-effect            
            ani-bl/start: item/5 * dly + time
            ani-bl/val1: item/2
            ani-bl/val2: item/2 + val
            cur-effect: make effect ani-bl
            cur-target: to-path reduce [to-word rejoin [t-obj/id "-" n] 4]
            put timeline to-string rejoin [cur-target cur-idx] reduce [cur-target cur-effect]
            n: n + 1
        ]
        cur-idx: cur-idx + 1 
    ]
   
    from-text: [['from set v1 value 'to set v2 value] | set v1 value (v2: v1)]
    
    text-fx: [
        'text-fx (
            new-fx: false
            clear-anim-actors
        )
        [set txt-w word! | object!] (
            t-obj: get txt-w
            unless text-data/(t-obj/id) [
                fx-data: init-text-fx t-obj/id t-obj delay-v
                text-fx-id: text-fx-id + 1
                new-fx: true
            ]    
            from-count: length? text-data/(t-obj/id)/chunks  ; counted only once for text-scale, tex-color and text-move
            cur-text-fx-end: any [text-fx-map/(t-obj/id) 0.0]
            text-fx-map/(t-obj/id): max cur-text-fx-end delay-v * from-count + start-v  
        )
        keep (either new-fx [to-set-word t-obj/id][[]])
        keep (either new-fx [fx-data][[]]) (new-fx: false)
        any [ 
        opt [
            'text-scale
            from-text (val1: reduce [v1 v2])
            from-text (val2: reduce [v1 v2])
            opt anim-actors (
                text-fx-actors
                scale-text-fx t-obj val1 val2 start-v
            )    
        ]
        opt [
            'text-move
            set v1 value (text-move t-obj v1 start-v)
            opt anim-actors (
                text-fx-actors
            )
        ]
        opt [
            'text-color
            from-text (text-color t-obj v1 v2 start-v)
            opt anim-actors (
                text-fx-actors
            )    
        ]
        ]
        opt [
            'expires [
            [
                'after set text-end number!
                (text-fx-map/(t-obj/id): max text-end text-fx-map/(t-obj/id))
            ]
          | 'never (text-fx-map/(t-obj/id): 0)
          ]
        ]
        
        
    ]
    
    get-lines: function [
        lines [block!]  {block of points}
    ][
        collect [
            keep 'line
            foreach p lines [keep p * 10]
        ]
    ]

    bezier-to-lines: function [   
        bez-pts [block!]    {block of points}
        lim     [integer!]  {how many lines to split the curve into}
    ][ 
        tt: 0.01
        bez: copy bez-pts
        forall bez [bez/1: 10x10 * bez/1]
        len: bezier-lengths bez 200
        collect [
            keep 'line
            repeat n lim [
                u: bezier-lerp tt len
                keep bezier-n bez u
                tt: 1.0 * n / lim
            ]
        ]    
    ]
        
    path: [
        some [
            [
                'line set p1 pair! rest-pts: some pair!
                p-end: (lines: head insert copy/part rest-pts p-end p1)
                (append path-block get-lines lines)
            ]
          | [
                'arc 
                set arc-center pair!
                set arc-radius pair!  ; only x is used - circular arcs !!!
                set arc-begin number!
                set arc-sweep number!
                (cur-arc: reduce ['arc arc-center * 10 10x10 * arc-radius arc-begin arc-sweep])
                (append path-block cur-arc)
            ]
          | [
                'bezier
                set p1 pair!
                set p2 pair!
                rest-bezier: some pair! end-bezier: (
                    b-lines: head insert copy/part rest-bezier end-bezier reduce [p1 p2] 
                )
                (
                    cur-bezier: bezier-to-lines b-lines 100
                    append path-block 'bezier
                    forall b-lines [b-lines/1: 10x10 * b-lines/1]
                    append path-block b-lines
                )
            ]          
        ]
    ]
    
    line-length: function [a b][sqrt a/x - b/x ** 2 + (a/y - b/y ** 2)]    
    
    arc-length: function [r s][pi * r * (absolute s) / 180.0]
    
    arc-angle: function [r len][180.0 * len / (pi * r)]
    
    lengths: function [
        {Calculates the length of a block containing lines, arcs and bezier curves}
        data [block!]  {a block of line points, bezier points or arc radius and sweep values}
    ][
        collect/into [
            while [not tail? data][
                keep mode: data/1
                data: next data
                seq: offset? data any [find next data word! tail data]
                switch mode [
                    line [repeat n seq - 1 [keep line-length data/:n data/(n + 1)]]
                    arc [keep arc-length data/2/x data/4]
                    bezier [keep last bezier-lengths copy/part data seq 200] ; 200 -> parameter?
                ]
                data: skip data seq
            ]
        ] make block! 200
    ]
    
    break-path: function [
        {Breaks the path into segments that will be gradually colored}
        id    [word!]        {unique identifier}
        data  [block!]       {block of drawing primitives}
        w     [integer!]     {path width}
        color [tuple! word!] {path color}    
    ][
        data-len: lengths data ; a block of precalculated primitives length
        len: 0.0               ; total length 
        min-len: 1e6 
        parse data-len [some [set d number! (min-len: min d min-len len: len + d) | skip]]
        seg-len: min 50.0 min-len
        seg-n: len / seg-len
        path: make block! seg-n * 3
        carry: 0.0
        
        put stroke-path-map path-id compose/deep [
            data:      [(head data)]
            length:    (to-integer len)
            cur-pos:   0
            start:     (start-v)
            duration:  (dur-v)
            expires:   (stroke-path-end)
            color:     (color)
            count:     (seg-n)
            cur-count: 0
            ease:      (ease-v)
        ]
        
        color: transparent
      
        collect/into [
            keep compose [line-width (10 * w)]
            while [not tail? data][
                mode: data/1
                data: next data
                data-len: next data-len
                seq: offset? data any [find next data word! tail data]
                switch mode [
                    line [
                        repeat n seq - 1 [
                            px: data/:n/x
                            py: data/:n/y
                            phi: arctangent2 data/(n + 1)/y - py data/(n + 1)/x - px
                            line-len: data-len/1
                            
                            if carry > 0 [                         ; draw the remaining part of a line
                                keep reduce ['line as-pair px py]
                                px: px + (carry * cosine phi)
                                py: py + (carry * sine phi)
                                keep as-pair px py
                                line-len: line-len - carry
                            ]
                            
                            dx: seg-len * cosine phi
                            dy: seg-len * sine phi
                            
                            while [line-len >= seg-len][       ; break the line
                                keep compose [pen (color) line (as-pair px py)]
                                px: px + dx
                                py: py + dy
                                keep as-pair px py
                                line-len: line-len - seg-len
                            ]
                            if line-len > 0 [carry: line-len]
                            
                            if carry > 0 [                         ; draw the remaining part of a line
                                keep compose [pen (color) line (as-pair px py)]
                                px: px + (carry * cosine phi)
                                py: py + (carry * sine phi)
                                keep as-pair px py
                                carry: seg-len - carry
                            ]
                            data-len: next data-len
                        ]
                    ]
                    arc [
                        arc-c: data/1
                        arc-r: data/2
                        arc-b: data/3
                        arc-s: data/4
                        arc-len: data-len/1
                        sgn: pick [-1 1] arc-s < 0
                        phi: sgn * arc-angle arc-r/x seg-len
                        if carry > 0 [   ; if there is a leftover from a previous primitive
                            c-angle: sgn * arc-angle arc-r/x carry
                            keep reduce ['arc arc-c arc-r arc-b to-integer round c-angle]
                            arc-s: arc-s - c-angle
                            arc-b: arc-b + c-angle
                        ]
                        while  [(absolute arc-s) >= absolute phi][
                            keep reduce ['pen color 'arc arc-c arc-r to-integer round arc-b to-integer round phi]
                            arc-s: arc-s - phi
                            arc-b: arc-b + phi
                        ]
                        if (absolute arc-s) > 0 [
                            keep reduce ['pen (color) 'arc arc-c arc-r to-integer round arc-b to-integer round arc-s]
                            carry: seg-len - arc-length arc-r/x arc-s ; set carry
                        ]
                        data-len: next data-len
                    ]    
                    bezier [
                        bezier-len: data-len/1
                        bezier-pts: copy/part data seq
                        lookup-len: bezier-lengths bezier-pts 300
                        p1: data/1
                        if (t: carry / len) > 0.01 [ ;t is the position on the curve from 0.0 to 1.0
                            keep reduce ['pen (color) 'line p1]
                            keep p1: bezier-n bezier-pts bezier-lerp carry / len lookup-len
                            bezier-len: bezier-len - carry
                        ]
                        
                        delta-t: seg-len / bezier-len
                        while [bezier-len > seg-len][
                            keep reduce ['pen color 'line p1]
                            t: t + delta-t
                            keep p1: bezier-n bezier-pts bezier-lerp t lookup-len
                            bezier-len: bezier-len - seg-len
                        ]
                        if bezier-len > 0 [keep last bezier-pts carry: seg-len - bezier-len]
                        data-len: next data-len
                    ]
                ]
                data: skip data seq
            ]
        ] path
    ]
    
    set 'trace-path func [
        {Traverse the path's draw block and gradually change the pen color along the path}
        id [word!]     {effect id}
        t   [number!]  {time}
    ][
        p: stroke-path-map/(id)
        path: at pick get id 1 p/cur-pos
        unless tail? path [
            new-count: to-integer t * p/count
            while [p/cur-count < new-count][
                path: find/tail path 'pen
                path/1: p/color
                p/cur-count: p/cur-count + 1
            ]
            p/cur-pos: min 1 + offset? head path path length? head path
        ]    
    ]    
    
    stroke-path: [
        'stroke-path (
            ease-v: any [:ease-v to get-word! "ease-linear"]
            stroke-path-end: 0
            clear-anim-actors
        )
        set path-id word! (path-block: make block! 50)
        path 
        'width set width integer!
        'color set color [tuple! | word!]
        opt [
            'expires [
            [
                'after set stroke-path-end number!
                (stroke-path-end: start-v + max stroke-path-end dur-v)
            ]
          | 'never
          ]
        ]
        opt anim-actors (
            v1: v2: 0
            make-effect  ; for a dummy tween that will manage actors
            cur-target: 'dummy
            cur-effect: make effect ani-bl
            put timeline path-id reduce [cur-target cur-effect]
            
            path-id: to-word rejoin [path-id "-" cur-idx]
            new-block: break-path path-id path-block width color  ; how many segments? 200 
            start-v: start-v + delay-v
            from-count: from-count + 1
            cur-idx: cur-idx + 1
        )
        keep (to-set-word path-id)
        keep (new-block)
    ]
    
    path-to-lines: function [
        data  [block!]
        seg-n [integer!]
    ][
        data-len: lengths data
        len: 0.0
        parse data-len [some [set d number! (len: len + d) | skip]]
        seg-len: len / seg-n
        
        collect/into  [
            keep 'line
            while [not tail? data][
                mode: data/1
                data: next data
                data-len: next data-len
                seq: offset? data any [find next data word! tail data]
                switch mode [
                    line [
                        repeat n seq - 1 [
                            px: data/:n/x
                            py: data/:n/y
                            phi: arctangent2 data/(n + 1)/y - py data/(n + 1)/x - px
                            line-len: data-len/1
                            
                            keep as-pair px py
                            
                            dx: seg-len * cosine phi
                            dy: seg-len * sine phi
                            
                            k: to-integer line-len / seg-len
                            
                            loop k [
                                px: px + dx
                                py: py + dy
                                keep as-pair px py
                            ]
                            
                            if (line-len // seg-len) > 0 [keep data/(n + 1)]
                      
                            data-len: next data-len
                        ]
                    ]
                    arc [
                        arc-params: copy/part data 4
                        keep arc-to-lines arc-params seg-len
                        data-len: next data-len
                    ]
                    
                    bezier [
                        bezier-len: data-len/1
                        bezier-pts: copy/part data seq
                        data: back data
                        take/part data seq + 1
                        rest: take/part data tail data
                        append data 'line
                        seq: 1
                        lookup-len: bezier-lengths bezier-pts 500
                        
                        t: 0.005
                        delta-t: seg-len / bezier-len
                        while [bezier-len > seg-len][
                            keep p1: bezier-n bezier-pts bezier-lerp t lookup-len
                            bezier-len: bezier-len - seg-len
                            append data p1
                            seq: seq + 1
                            t: t + delta-t
                        ]
                        if bezier-len > 0 [keep lst: last bezier-pts append data lst seq: seq + 1]
                        append data rest
                        data-len: next data-len
                    ]
                ]
                data: skip data seq
            ]
        ] make block! seg-n
    ]
    
    arc-to-lines: function [
        {Turns an arc to line segments}
        p [block!]
        seg-len [number!]
    ][
        c: p/1
        r: p/2/x
        b: p/3
        s: p/4
        d-phi: (sign? s) * arc-angle r seg-len
        a: b
        collect [
            while [(absolute a) < absolute b + s][
                px: (r * cosine a) + c/x
                py: (r * sine a) + c/y
                keep as-pair px py
                a: a + d-phi
            ]
            px: (r * cosine b + s) + c/x
            py: (r * sine b + s) + c/y
            keep as-pair px py
        ]
    ]
    
    linearize-paths: function [
        {Replaces line, arc and bezier in both blocks with lines only}
        target [word!]
        p1 [block!]
        p2 [block!]
    ][
        len-1: 0.0   ; length of the first path 
        data-len-1: lengths p1
        parse data-len-1 [some [set d number! (len-1: len-1 + d) | skip]]
        
        len-2: 0.0  ; length of the second path
        data-len-2: lengths p2
        parse data-len-2 [some [set d number! (len-2: len-2 + d) | skip]]
        
        ; the segment length is different for the two paths
        ; Arcs and bezier curve should not look too jaggy 
        ; 50 (5 pixels0 ?
        seg-n: to-integer len-1 + len-2 / 100.0  ;  short for  / 2 / 50.0
              
        lines-1: path-to-lines p1 seg-n
        lines-2: path-to-lines p2 seg-n
        
        ; equalize the number of points in both blocks
        ; needs to be distrubuted evenly
        if (l1: length? lines-1) < l2: length? lines-2 [
            d: l2 - l1
            skp: to integer! l1 - 1 / d
            p: lines-1
            loop d - 1 [
               p: skip p skp
               insert p p/1
               p: next p
            ]
            append lines-1 last lines-1
        ]
        if (l1: length? lines-1) > l2: length? lines-2 [
            d: l1 - l2
            skp: to integer! l2 - 1 / d
            p: lines-2
            loop d - 1[
               p: skip p skp
               insert p p/1
               p: next p
            ]
            append lines-2 last lines-2
        ]

        put morph-path-map target compose/deep [
            start: (start-v)
            duration: (dur-v)
            expires: (morph-path-end)
            block-1: [(lines-1)]
            block-2: [(lines-2)]
            end-block: [(p2)]
            ease: (ease-v)
            started: (false)
        ]
    ]
    
    morph-path: [
        'morph-path (
            ease-v: any [:ease-v to get-word! "ease-linear"]
            path-block: make block! 100
            morph-path-end: 0
            show-first: false
            clear-anim-actors
        )
        path (path1: copy path-block clear path-block)
        'into
        path (path2: copy path-block)
        opt ['visible set show-first word! (show-first: get show-first)] 
        opt [
            'expires [
                ['after set morph-path-end number! 
                (morph-path-end: start-v + max morph-path-end dur-v)]
          | 'never
            ]
        ]
        opt anim-actors (
            v1: v2: 0
            make-effect  ; for a dummy tween that will manage actors
            target: to-word rejoin ["morph-" cur-idx]
            cur-idx: cur-idx + 1
            cur-target: 'dummy
            cur-effect: make effect ani-bl
            put timeline target reduce [cur-target cur-effect]
            linearize-paths target path1 path2
        )
        keep (to-set-word target)
        keep (either show-first [path1][[]])
    ]
    
    spread: ['pad | 'repeat | 'reflect]
    tile-mode:  ['tile | 'flip-x | 'flip-y | 'flip-xy | 'clamp]
    
    pen-scale-up: [
        keep ('scale)
        keep (to-lit-word "fill-pen")
        keep (10.0)
        keep (10.0)
    ]

    p-linear: [
        keep 'linear 
        some [(val-ofs: val-ofs + 1) from | keep [tuple! | word-val]]
        0 3 [from | value keep (scaled)] ; offset ; start ; end
        opt keep spread ;spread method
    ]
    
    p-radial: [
        keep 'radial
        some [(val-ofs: val-ofs + 1) from | keep [tuple! | word-val]]
        0 4 [from | value keep (scaled)] ; offset ; center ; radius ; focal
        opt keep spread  ;spread method
    ]
    
    p-diamond: [
        keep 'diamond 
        some [(val-ofs: val-ofs + 1) from | keep [tuple! | word-val]]
        0 4 [from | value keep (scaled)] ; offset ; uppper ; lower ; focal
        opt keep spread  ;spread method
    ]
    
    p-pattern: [
        keep 'pattern
        value keep (scaled) ; size
        0 2 [from | value keep (scaled)] ; start; end
        opt keep tile-mode  ;spread method
        into anim-rule         ; commands
    ]
    
    p-bitmap: [
        keep 'bitmap 
        p-img: keep word!
        0 2 [keep pair!]     ; start; end
        opt keep tile-mode  ;spread method
        pen-scale-up ; scale up 10x because of the initial scal 0.1
    ]
    
    pens: ['pen | 'fill-pen]
    
    pen-rule: [
        pen-mark: opt [set user-target set-word!]
        pens (cur-target: rejoin [pen-mark/1 cur-idx])
        :pen-mark word (val-ofs: 2) ;?
        [from | [keep tuple!] | keep-word-val | p-linear | p-radial | p-diamond | p-pattern | p-bitmap]
    ]
    
    matrix-rule: [
        keep 'matrix
        opt keep pens 
        keep block!
    ]
    
    from-pair:   [from | set v1 pair! keep (v1 * 10)]
    from-number: [from | keep number!]  ; not scaled - for angles and scalingg
    pair-val: [pair! | ['from pair! 'to pair!]] 
    
    image-rule: [
        img-mark: opt [set user-target set-word!]
        'image (
            cur-target: rejoin ["img" cur-idx]
            sz: 0x0
            img-d: none
        )
        :img-mark word (val-ofs: 3)
        [keep set img-d image!  | set img-d word! keep (get img-d)] 
        (
            if word? img-d [img-d: get img-d]
            sz: img-d/size
        ) 
        [
            [ahead [2 pair-val]2 [from-pair (val-ofs: val-ofs + 1)]]
          | [ahead pair-val from-pair keep (sz + v1 * 10 )] 
          | [keep (0x0) keep (sz * 10)]
        ]
        ; 4-point mode not yet implemented in Draw!
        ; color doesn't seem to work too!
        ; border mode is not yet implemented
    ]
    
    scale-rule: [
        scale-mark: opt [set user-target set-word!]
        'scale (
            cur-target: rejoin ["scale" cur-idx]
            target: 'scale
        )
        :scale-mark word
        [from-number (val-ofs: val-ofs + 1) from-number] (pen-scale: 1.0)
    ]
    
    translate-rule: [
        translate-mark: opt [set user-target set-word!]
        'translate (
            cur-target: rejoin ["translate" cur-idx]
            target: 'translate
        )
        :translate-mark word
        from-pair (pen-scale: 1.0)
    ] 
    
    rotate-rule: [
        rotate-mark: opt [set user-target set-word!]
        'rotate (
            cur-target: rejoin ["rotate" cur-idx]
            target: 'rotate
        )
        :rotate-mark word (pen-scale: 0.1)
        from-number (pen-scale: 1.0 val-ofs: val-ofs + 1)
        opt from-pair
    ]
    
    
    transform-rule: [
        trans-mark: opt [set user-target set-word!]
        'transform (
            cur-target: rejoin ["translate" cur-idx]
            target: 'transform
        )
        :trans-mark
        word 
        opt [ahead pair-val from-pair (val-idx: 3 val-ofs: val-ofs + 1)] ; center
        3 [from-number (val-ofs: val-ofs + 1)]    ; rotation angle, scale X, scale Y
        (val-idx: 1)                              ; to account for 
        from-pair                                 ; translation amount
        opt into anim-rule                        ; block of Draw commands 
    ]
    
    comb-modes: ['replace | 'intersect | 'union | 'xor | 'exclude]
    
    clip-rule: [
        'clip (
            cur-target: rejoin ["trans" cur-idx]
            target: 'clip
            val-ofs: 2
        )
        keep (to-set-word cur-target)
        keep (to-word "clip")
        [
            [2 from-pair]    ; start - end
          | [into anim-rule] ; shape
        ]  
        opt keep comb-modes
        opt into anim-rule
    ]
    
    command: [
        (time-id: none)
        opt [set time-id [set-word! ahead 'start]]   ; named animation
        opt start
        opt dur
        opt delay
        opt ease
        opt anim-loop
    ]
    
    anim-rule: [
        collect [
            some [
                command
                opt [
                    param
                  | text-fx
                  | particles
                  | curve-fx
                  | stroke-path
                  | morph-path
                  | pen-rule
                  | image-rule
                  | matrix-rule
                  | scale-rule
                  | translate-rule
                  | rotate-rule
                  | transform-rule
                  | clip-rule
                  | [keep 'reset-matrix opt keep pens]
                  | [keep 'invert-matrix opt keep pens]
                  | [keep 'push keep block!]
                  | word  ; Draw command
                    ; word parameter, like font or image value
                    opt [keep [not 'from not 'to word!](val-ofs: val-ofs + 1 val-idx: val-idx + 1)]
                    ; parameters, incl. animated ones
                    any [[from | value keep (scaled) ](val-ofs: val-ofs + 1 val-idx: val-idx + 1)]
                    opt keep 'closed ; for splines and arcs
                  | into anim-rule  ; block 
                ]                                      
              
            ]
        ]    
    ]

    set 'animate func [
        {Takes a block of draw and animate commands and generates a draw block
        for the target face and a timeline for the animations}
        spec   [block!]               {A block of draw and animate commands}
        target [word! path! object!]  {A face to render the draw block and animations}
    ][
        draw-block: parse spec anim-rule
        insert draw-block compose [
            (to set-word! "ani-start") 
            scale 0.1 0.1                ; for subpixel precision          
            line-width 10                
        ]
        ;probe draw-block
        ;probe ani-bl
        ;probe timeline
        target/draw: draw-block
       
        actors: make block! 10
        append clear actors [on-time: func [face event][process-timeline]]
        target/actors: object actors
        
        st-time: now/precise  
    ]
]

;------------------------------------------------------------------------------------------------
; easing functions
; the argument must be in the range 0.0 - 1.0
;------------------------------------------------------------------------------------------------
ease-linear: func [x][x]

ease-steps: func [x n][round/to x 1 / n]

ease-in-sine: func [x][1 - cos x * pi / 2]
ease-out-sine: func [x][sin x * pi / 2]
ease-in-out-sine: func [x][(cos pi * x) - 1 / -2]

ease-in-out-power: func [x n][either x < 0.5 [x ** n * (2 ** (n - 1))][1 - (-2 * x + 2 ** n / 2)]]

ease-in-quad:      func [x][x ** 2]
ease-out-quad:     func [x][2 - x * x]  ; shorter for [1 - (1 - x ** 2)]
ease-in-out-quad:  func [x][ease-in-out-power x 2]

ease-in-cubic:     func [x][x ** 3]
ease-out-cubic:    func [x][1 - (1 - x ** 3)] 
ease-in-out-cubic: func [x][ease-in-out-power x 3]

ease-in-quart:     func [x][x ** 4]
ease-out-quart:    func [x][1 - (1 - x ** 4)]
ease-in-out-quart: func [x][ease-in-out-power x 4]

ease-in-quint:     func [x][x ** 5]
ease-out-quint:    func [x][1 - (1 - x ** 5)]
ease-in-out-quint: func [x][ease-in-out-power x 5]

ease-in-expo:      func [x][2 ** (10 * x - 10)]
ease-out-expo:     func [x][1 - (2 ** (-10 * x))]
ease-in-out-expo:  func [x][
    either x < 0.5 [
        2 ** (20 * x - 10) / 2
    ][
        2 - (2 ** (-20 * x + 10)) / 2
    ]
]

ease-in-circ: func [x][1 - sqrt 1 - (x * x)] 
ease-out-circ: func [x][sqrt 1 - (x - 1 ** 2)]
ease-in-out-circ: func [x][
    either x < 0.5 [
        (1 - sqrt 1 - (2 * x ** 2)) / 2
    ][
        (sqrt 1 - (-2 * x + 2 ** 2)) + 1 / 2
    ]
]

ease-in-back: func [x /local c1 c3][
    c1: 1.70158
    c3: c1 + 1
    x ** 3 * c3 - (c1 * x * x)
]
ease-out-back: func [x /local c1 c3][
    c1: 1.70158
    c3: c1 + 1
    x - 1 ** 3 * c3 + 1 + (x - 1 ** 2 * c1) 
]
ease-in-out-back: func [x /local c1 c2][
    c1: 1.70158           ; why two constants? 
    c2: c1 * 1.525
    either x < 0.5 [
        2 * x ** 2 * (c2 + 1 * 2 * x - c2) / 2
    ][
        2 * x - 2 ** 2 * (c2 + 1 * (x * 2 - 2) + c2) + 2 / 2
    ]
]

ease-in-elastic: func [x /local c][
    c: 2 * pi / 3
    negate 2 ** (10 * x - 10) * sin x * 10 - 10.75 * c
] 
ease-out-elastic: func [x /local c][
    c: 2 * pi / 3
    (2 ** (-10 * x) * sin 10 * x - 0.75 * c) + 1
]
ease-in-out-elastic: func [x /local c][
    c: 2 * pi / 4.5
    either x < 0.5 [
        2 ** ( 20 * x - 10) * (sin 20 * x - 11.125 * c) / -2
    ][
        2 ** (-20 * x + 10) * (sin 20 * x - 11.125 * c) / 2 + 1
    ]
]
 
ease-in-bounce: func [x][1 - ease-out-bounce 1 - x] 
ease-out-bounce: func [x /local n d][
    n: 7.5625
    d: 2.75
    case [
        x < (1.0 / d) [n * x * x]
        x < (2.0 / d) [n * (x: x - (1.5   / d)) * x + 0.75]
        x < (2.5 / d) [n * (x: x - (2.25  / d)) * x + 0.9375]
        true          [n * (x: x - (2.625 / d)) * x + 0.9984375]
    ]
]
ease-in-out-bounce: func [x][
    either x < 0.5 [
        (1 - ease-out-bounce -2 * x + 1) / 2
    ][
        (1 + ease-out-bounce  2 * x - 1) / 2
    ]
]
;------------------------------------------------------------------------------------------------

tween: function [
    {Interpolates a value between value1 and value2 at time t
    in the stretch start .. start + duration using easing function ease}
    target   [word! any-path!]      {the word or path to set}
    val1     [number! pair! tuple!] {Value to interpolate from}
    val2     [number! pair! tuple!] {Value to interpolate to}
    start    [number!]              {Start of the time period}
    duration [number!]              {Duration of the time period}
    t        [number!]              {Current time}
    ease     [function!]            {Easing function}
][
    end-t: duration * 1.09 + start  ; depends on the easing!
    if all [t >= start t <= end-t][
        either t < (start + duration) [
            either tuple? val1 [
                if 3 = length? val1 [val1: val1 + 0.0.0.0]
                if 3 = length? val2 [val2: val2 + 0.0.0.0]
                val: val1
                repeat n length? val1 [
                    val/:n: to integer! val1/:n + (val2/:n - val1/:n * ease t - start / duration) % 256
                ]
            ][
                val: val1 + (val2 - val1 * ease t - start / duration)  
                if integer? val1 [val: to integer! val]
            ]    
            set target val
        ][set target val2]
    ]    
]

;------------------------------------------------------------------------------------------------
pascals-triangle: function [
    {Creates the first n rows of the Pascal's triangle, referenced by nCk}
    n [integer!]
][
    row: make vector! [1]
    PT: make block! n
    append/only PT copy row
    collect/into [
        loop n [
            row: add append copy row 0 head insert copy row 0
            keep/only copy row
        ]
    ] PT
]

pascal: pascals-triangle 30; stores the precalculated values for the first 30 rows  

nCk: function [
    {Calculates the binomial coefficient, n choose k}
    n k
][
    pascal/(n + 1)/(k + 1)
]

bezier-n: function [
    {Calculates a point in the Bezier curve, defined by pts, at t}
    pts [block!] {a set of pairs}
    t   [float!] {offset in the curve, from 0.0 to 1.0}
][
    if t < 0.0 [return pts/1]
    if t > 1.0 [return last pts]
    n: (length? pts) - 1
    bx: by: i: 0
    foreach p pts [
        c: (nCk n i) * ((1 - t) ** (n - i)) * (t ** i)
        bx: c * p/x + bx
        by: c * p/y + by
        i: i + 1
    ]
    as-pair bx by
]

bezier-tangent: function [  ; needs a better name!
    {Calculates the tangent angle for a Bezier curve
     defined with pts at point t}
    pts [block!] {a set of pairs}
    t   [float!] {offset in the curve, from 0.0 to 1.0}
][
    p1: bezier-n pts t
    p2: bezier-n pts t + 0.01
    arctangent2 p2/y - p1/y p2/x - p1/x
]

bezier-lengths: function [
    {Returns a block of accumulated lengths of the linear segments
     a bezier curve can be simplified to}
    pts  [block!]   {a set of 2d points defining a Bezier curve}
    seg-n [integer!] {number of linear segments to divide the curve into}
][
    t: 0.0
    length: 0.0
    p0: bezier-n pts t
    collect [
        repeat n seg-n [
           t: 1.0 * n / seg-n
           p1: bezier-n pts t
           keep length: length + sqrt p1/1 - p0/1 ** 2 + (p1/2 - p0/2 ** 2)
           p0: p1
        ]
    ]
]

half: func [a b][to integer! a + b / 2]

b-search: function [
    {Returns the index of the largest element of src 
    that is less than or equal to target}
    src    [block!]  {block of numbers}

    target [number!] {the number to be searched}
][
    L: 1
    R: length? src
    M: half L R
    while [L < R][
        case [
            src/:M = target [break]
            src/:M < target [L: M + 1]
            src/:M > target [R: M - 1]
        ]
        M: half L R
    ]
    M
]

bezier-lerp: function [
    {Returns a point in a Bezier curve. The distance from the 
    starting point is linearly interpolated.}
    u    [float!] {parameter of the interpolation, from 0.0 to 1.0}
    seg  [block!] {a precalculated block of segment lengths}
][
    ; !!! The points around 0.0 and 1.00 are much sparsely located!
    ;     This leads to uneven placement of objects along the curve !!!
    
    len: to integer! u * last seg 
    either len = seg/(idx: b-search seg len) [
        to float! idx / length? seg
    ][
        if idx = length? seg [return 1.0]
        l1: seg/:idx
        l2: seg/(idx + 1)
        seg-t: to float! len - l1 / (l2 - l1)
        to float! (idx + seg-t / length? seg)
    ]
]

;------------------------------------------------------------------------------------------------
; Text-related functions
;------------------------------------------------------------------------------------------------
char-offsets: function [
    {Calculates the offsets of the characters
    in a text for a given font settings}
    src [string!]
    fnt [object!]
][
    new-src: head append copy src "|"  ; to find the last offset
    size: as-pair fnt/size * length? new-src fnt/size
    ; as a general rule, never use make face!, only make-face
    txt: make make-face 'rich-text compose [size: (size) text: (new-src)]
    txt/font: copy fnt
    next collect [repeat n length? new-src [keep caret-to-offset txt n]]
]

text-box-size: function [
    {Calculates the size of the bounding box
    of a text for a given font settings}
    src [string!]
    fnt [object!]
][
    size: as-pair fnt/size * length? src fnt/size
    txt: make face! compose [size: (size)  type: 'text text: (src)]
    txt/font: copy fnt
    size-text txt
]

split-text: function [
    {Splits src on characters, words (on spaces and newlines) 
    or lines (on newlines) and returns a block of blocks,  
    each consisting of position, size and substring}
    src  [string!]   {Text to split}
    fnt  [object!]   {Font to use for measurements}
    mode [any-word!] {chars, words or lines}
    pos  [pair!]     {coordinates of the starting point}
    sx   [number!]   {x spacing factor}
    sy   [number!]   {y spacing factor} 
][
    size: as-pair fnt/size * length? src fnt/size
    txt: make make-face 'rich-text compose [size: (size) text: (src)]
    txt/font: copy fnt
    txt1: make face! compose [size: (size)  type: 'text text: (src)]
    txt1/font: copy fnt
    rule: select [chars [skip] words [space | newline] lines [newline]] mode
    
    collect [
        parse src [
            any [
                p: copy t thru [rule | end] 
                (
                    c-offs: caret-to-offset txt index? p  
                    c-offs/x: to integer! c-offs/x * sx
                    c-offs/y: to integer! c-offs/y * sy
                    c-offs: 10x10 * pos + c-offs  
                    keep/only reduce [
                        c-offs                        ; position  
                        size-text/with txt1 t         ; size 
                        t                             ; text
                    ]
                )
              | skip
            ]
        ]
    ]
]

init-text-fx: function [
    id     [any-word!]
    t-spec [block!]
    delay  [number!]
][
    
    if not text-data/:id [        ;init
        t-obj: make text-effect t-spec
        t-obj/delay: delay
        ; t-obj/dur: duration
        t-obj/font/size: t-obj/font/size * 10  ; upscale the provided font!
        chunks: split-text t-obj/text t-obj/font t-obj/mode t-obj/posXY t-obj/sp-x t-obj/sp-y ; too many args
        starts: collect [
            st: 0.0
            repeat n length? chunks [
                keep st
                st: round/to st + delay 0.001
           ]
        ]
        
        if t-obj/random [random starts]
        
        repeat n length? chunks [
            fnt-name: rejoin [id "-" n]
            insert chunks/:n fnt-name
            append chunks/:n reduce [starts/:n t-obj/dur]
        ]
            
        put text-data id compose/deep [chunks: [(chunks)] effect: (t-obj)]
        
        collect [
            foreach item chunks [
                fnt-name: to-word rejoin [item/1 "-fnt"]
                fnt: copy t-obj/font
                set fnt-name fnt
                fnt-id: to set-word! item/1
                keep compose/deep [
                    (fnt-id) font (fnt-name)
                    translate (item/2) [ 
                        scale 1.0 1.0 
                        rotate 0.0 (item/3 / 2)
                        text 0x0 (item/4)
                    ]
                ]
            ]
        ]
    ]    
]

; obsolete?
fade-in-text: function [
    {Animates the text so that each element (character, word or line)
    fades-in from transparent to the chosen font color}
    id         [any-word!] {identifier for the effect}
    t          [float!]    {current time}
    /init
        t-spec [block!]    {specification of the text effect}
    /rand    
][
    either init [   ; initialize
        t-obj: make text-effect t-spec
        chunks: split-text t-obj/text t-obj/font t-obj/mode
        starts: collect [
            st: t-obj/start
            repeat n length? chunks [
                keep st
                st: st + t-obj/delay
            ]
        ]
        if rand [random starts]
        
        repeat n length? chunks [
            fnt-name: rejoin [id "-fnt-" n]
            insert chunks/:n fnt-name
            append chunks/:n reduce [starts/:n t-obj/dur]
        ]
        
        put text-data id compose/deep [chunks: [(chunks)]]
        
        collect [
            foreach item chunks [
                fnt-name: to-word rejoin [item/1 "_"]
                set fnt-name copy t-obj/font
                fnt-id: to set-word! item/1
                posx: item/2/x * t-obj/sp-x
                posy: item/2/y * t-obj/sp-y
                p: as-pair posx posy
                keep compose [
                    (fnt-id) font (get fnt-name)
                    text (t-obj/posXY + p) (item/4)
                ]
            ]
        ]    
    ][  ; animate
        foreach item text-data/:id/chunks [
            fnt-id: get to word! rejoin [item/1 "_"]
            name: get to word! item/1
            name/4: name/4  ; refresh
            tween 'fnt-id/color/4 255 0 item/5 item/6 t :ease-in-out-quart
        ]
    ]
]

text-along-curve: function [
    {Flow a text along Bezier curve}
    id       [word!]   {effect identificator}
    t        [number!] {point on the curve} 
    /init          
        txt  [string!] {text to be displayed}  
        fnt  [object!] {font to use}
        pts  [block!]  {point of the Bezier curve}  
        spacing [number!] {multiplier for the space between the characters}
][
    either init [
        txt-ofs: char-offsets txt fnt
        len: last txt-ofs      ; text length
        txt-sz: 0x1 * text-box-size txt fnt  ; only the text height
        crv: copy pts
        forall crv [crv/1: crv/1 * 10]
        bez-segs: bezier-lengths crv 500  ; should it be an argument - for tuning performance / quality?
        put text-data id compose/deep [  ; the map of id's and objects 
            txt-ofs: [(txt-ofs)]
            len: (len)       
            txt-sz: (txt-sz)
            crv: [(crv)]            
            bez-segs: [(bez-segs)]
            spacing: (spacing)
        ]    
        
        draw-buf: make block! 10 * length? txt

        append/only draw-buf collect [
            repeat n length? txt [
                id-t: to set-word! rejoin [id "-t-" n] ;translate
                id-r: to set-word! rejoin [id "-r-" n] ; rotate
                keep compose/deep [
                    (id-t) translate 10000x0 [
                        (id-r) rotate 0 0x0
                        text 0x0 (to-string txt/:n)
                    ]
                ]
            ]
        ]
        draw-buf
    ][
        tt: t        
        d: d0: 0x0
        obj: text-data/:id
        txt-ofs: obj/txt-ofs
        txt-sz: obj/txt-sz
        crv: obj/crv
        bez-segs: obj/bez-segs
        len: last bez-segs
        spacing: obj/spacing
        
        repeat n length? txt-ofs [
            d: txt-ofs/:n - d0 + txt-sz / 2
            u: d/x / len * spacing + tt
            ;u: d/x / len + tt
            ttt: bezier-lerp u bez-segs
            if ttt > 0.999 [break]
            
            id-t: to word! rejoin [id "-t-" n] ;translate
            id-r: to word! rejoin [id "-r-" n] ; rotate
            
            c-offs: bezier-n crv ttt
            angle: round/to bezier-tangent crv ttt 0.01
           
            change at get id-t 2 c-offs - d
            change at get id-r 2 angle
            change at get id-r 3 d

            tt: (to-float txt-ofs/:n/x / len * spacing) + t
            d0: txt-ofs/:n
        ]
    ]
]

block-along-curve: function [
    {Flow a block of blocks of Draw commands along Bezier curve}
    id       [word!]   {effect identificator}
    t        [number!] {point on the curve} 
    /init          
        blocks  [block!]  {a block of blocks to be rendered}  
        pts     [block!]  {point of the Bezier curve}  
        spacing [number!] {linear distance between the blocks on the curve, pixels}
][
    either init [
        crv: copy pts
        forall crv [crv/1: crv/1 * 10]
        bez-segs: bezier-lengths crv 500  ; should it be an argument - for tuning performance / quality?
        
        draw-buf: make block! 3 * length? blocks

        draw-buf: collect [
            foreach block blocks [
                keep [translate 0x0]
                keep/only compose/deep [
                    translate 10000x0 [     ; outside the visible screen
                        rotate 0 0x0
                        (autoscale block)
                    ]
                ]
            ]
        ]
        
        put draw-blocks-data id compose/deep [  ; the map of id's and objects 
            blocks: [(draw-buf)]
            crv: [(crv)]            
            bez-segs: [(bez-segs)]
            spacing: (spacing)  
        ]    
        draw-buf
    ][
        t: max t 0.005
        d: 0
        obj: draw-blocks-data/:id
        crv: obj/crv
        bez-segs: obj/bez-segs
        len: last bez-segs
        spacing: 10 * obj/spacing
        
        foreach [a b block] obj/blocks [
            u: to-float d / len + t
            ttt: bezier-lerp u bez-segs
            if any [ttt < 0.001 ttt > 0.999] [break]
            block/2: bezier-n crv ttt
            block/3/2: round/to bezier-tangent crv ttt 0.01
            d: d + spacing
        ]
    ]
]
