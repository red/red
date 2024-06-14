Red/System [
	Title:	"Some utility functions"
	Author: "Xie Qingtian"
	File: 	%utils.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#if debug? = yes [
	log-saved-stdout: 0
	new-stdout: 0

	start-log: does [
		#either OS = 'Windows [
			platform/dos-console?: no
			log-saved-stdout: stdout
			stdout: simple-io/open-file "view-log.txt" simple-io/RIO_APPEND no
			simple-io/SetFilePointer stdout 0 null SET_FILE_END
		][
			fflush 0
			new-stdout: simple-io/open-file "./view-log.txt" simple-io/RIO_APPEND no
			log-saved-stdout: _dup 1
			platform/dup2 new-stdout 1
			simple-io/close-file new-stdout
		]
	]
	end-log: does [
		#either OS = 'Windows [
			simple-io/close-file stdout
			stdout: log-saved-stdout
			platform/dos-console?: yes
		][
			fflush 0
			platform/dup2 log-saved-stdout 1
			simple-io/close-file log-saved-stdout
		]
	]
]

#define LOG_MSG(msg) [
	#if debug? = yes [
		start-log
		print-line msg
		end-log
	]
]

#define CHILD_WIDGET(widget) [
	as red-block! (get-face-values widget) + FACE_OBJ_PANE
]

#either OS = 'Windows [
    LARGE_INTEGER: alias struct! [
        LowPart     [integer!]
        HighPart    [integer!]
    ]

    #import [
        "kernel32.dll" stdcall [
            QueryPerformanceFrequency: "QueryPerformanceFrequency" [
                lpFrequency [LARGE_INTEGER]
                return:     [logic!]
            ]
            QueryPerformanceCounter: "QueryPerformanceCounter" [
                lpCount     [LARGE_INTEGER]
                return:     [logic!]
            ]
        ]
    ]

    time-meter!: alias struct! [
        widget [LARGE_INTEGER value]
    ]

    sub64: func [
        a       [LARGE_INTEGER]
        b       [LARGE_INTEGER]
        return: [integer!]
    ][
        ;-- mov edx, [ebp + 8]
        ;-- mov ecx, [ebp + 12]
        ;-- mov eax, [edx]
        ;-- mov edx, [edx + 4]
        ;-- sub eax, [ecx]
        ;-- sbb edx, [ecx + 4]
        #inline [
            #{8B55088B4D0C8B028B52042B011B5104}
            return: [integer!]
        ]
    ]

    time-meter: context [
        freq: 0

        init: func [/local t [LARGE_INTEGER value]][
            QueryPerformanceFrequency :t
            freq: t/LowPart
        ]

        start: func [t [time-meter!]][
            if zero? freq [init]
            QueryPerformanceCounter t/widget
        ]

        elapse: func [ 
            t       [time-meter!]
            return: [float32!]      ;-- millisecond
            /local
            	t1  [LARGE_INTEGER value]
                d   [integer!]
        ][
            QueryPerformanceCounter t1
            d: sub64 t1 t/widget
            (as float32! d) * (as float32! 1e3) / (as float32! freq)
        ]
    ]
][
    time-meter!: alias struct! [
        widget-s  [integer!]
        widget-m  [integer!]          ;-- microsecond
    ]

    time-meter: context [
        timeval!: alias struct! [
            tv_sec  [integer!]
            tv_usec [integer!]
        ]
        #import [
            LIBC-file cdecl [
                gettimeofday: "gettimeofday" [
                    tv      [timeval!]
                    tz      [integer!]          ;-- obsolete
                    return: [integer!]          ;-- 0: success -1: failure
                ]
            ]
        ]

        start: func [
            t       [time-meter!]
            /local
                tm  [timeval! value]
        ][
            gettimeofday :tm 0
            t/widget-s: tm/tv_sec
            t/widget-m: tm/tv_usec    ;-- microsecond
        ]

        elapse: func [
            t       [time-meter!]
            return: [float32!]      ;-- millisecond
            /local
                tm  [timeval! value]
                s   [float32!]
                ms  [float32!]
        ][
            gettimeofday :tm 0
            s: as float32! (tm/tv_sec - t/widget-s)
            ms: as float32! (tm/tv_usec - t/widget-m)
            s * (as float32! 1000.0) + (ms / as float32! 1000.0)
        ]
    ]
]

copy-rect: func [
	src		[RECT_F!]
	dst		[RECT_F!]
][
	dst/left: src/left
	dst/right: src/right
	dst/top: src/top
	dst/bottom: src/bottom
]

zero-memory: func [
	dest	[byte-ptr!]
	size	[integer!]
][
	set-memory dest null-byte size
]

utf16-length?: func [
	s 		[c-string!]
	return: [integer!]
	/local widget [c-string!]
][
	widget: s
	while [any [s/1 <> null-byte s/2 <> null-byte]][s: s + 2]
	(as-integer s - widget) >>> 1							;-- do not count the terminal zero
]

style-table: [
	PIXEL_BOLD
	PIXEL_FAINT
	PIXEL_ITALIC
	PIXEL_UNDERLINE
	PIXEL_BLINK
	0
	PIXEL_INVERTED
	PIXEL_HIDDEN
	PIXEL_STRIKE
]

color-16-table: [
    "40"  "30" 
    "41"  "31" 
    "42"  "32" 
    "43"  "33" 
    "44"  "34" 
    "45"  "35" 
    "46"  "36" 
    "47"  "37" 
    "0"   "0"
    "49"  "39"
    "100" "90" 
    "101" "91" 
    "102" "92" 
    "103" "93" 
    "104" "94" 
    "105" "95" 
    "106" "96" 
    "107" "97" 
]

color-table: #{
	;; palette-16-index  red  green  blue
	00 00 00 00 	;-- Black
	01 80 00 00 	;-- Red
	02 00 80 00 	;-- Green
	03 80 80 00 	;-- Yellow
	04 00 00 80 	;-- Blue
	05 80 00 80 	;-- Magenta
	06 00 80 80 	;-- Cyan
	07 C0 C0 C0 	;-- GrayLight
	08 80 80 80 	;-- GrayDark
	09 FF 00 00 	;-- RedLight
	0A 00 FF 00 	;-- GreenLight
	0B FF FF 00 	;-- YellowLight
	0C 00 00 FF 	;-- BlueLight
	0D FF 00 FF 	;-- MagentaLight
	0E 00 FF FF 	;-- CyanLight
	0F FF FF FF 	;-- White
	00 00 00 00 	;-- Grey0
	04 00 00 5F 	;-- NavyBlue
	04 00 00 87 	;-- DarkBlue
	04 00 00 AF 	;-- Blue3
	0C 00 00 D7 	;-- Blue3Bis
	0C 00 00 FF 	;-- Blue1
	02 00 5F 00 	;-- DarkGreen
	06 00 5F 5F 	;-- DeepSkyBlue4
	06 00 5F 87 	;-- DeepSkyBlue4Bis
	06 00 5F AF 	;-- DeepSkyBlue4Ter
	0C 00 5F D7 	;-- DodgerBlue3
	0C 00 5F FF 	;-- DodgerBlue2
	02 00 87 00 	;-- Green4
	06 00 87 5F 	;-- SpringGreen4
	06 00 87 87 	;-- Turquoise4
	06 00 87 AF 	;-- DeepSkyBlue3
	0E 00 87 D7 	;-- DeepSkyBlue3Bis
	0E 00 87 FF 	;-- DodgerBlue1
	02 00 AF 00 	;-- Green3
	06 00 AF 5F 	;-- SpringGreen3
	06 00 AF 87 	;-- DarkCyan
	06 00 AF AF 	;-- LightSeaGreen
	0E 00 AF D7 	;-- DeepSkyBlue2
	0E 00 AF FF 	;-- DeepSkyBlue1
	0A 00 D7 00 	;-- Green3Bis
	0A 00 D7 5F 	;-- SpringGreen3Bis
	0E 00 D7 87 	;-- SpringGreen2
	0E 00 D7 AF 	;-- Cyan3
	0E 00 D7 D7 	;-- DarkTurquoise
	0E 00 D7 FF 	;-- Turquoise2
	0A 00 FF 00 	;-- Green1
	0A 00 FF 5F 	;-- SpringGreen2Bis
	0E 00 FF 87 	;-- SpringGreen1
	0E 00 FF AF 	;-- MediumSpringGreen
	0E 00 FF D7 	;-- Cyan2
	0E 00 FF FF 	;-- Cyan1
	01 5F 00 00 	;-- DarkRed
	05 5F 00 5F 	;-- DeepPink4Ter
	05 5F 00 87 	;-- Purple4
	05 5F 00 AF 	;-- Purple4Bis
	0C 5F 00 D7 	;-- Purple3
	0C 5F 00 FF 	;-- BlueViolet
	03 5F 5F 00 	;-- Orange4
	08 5F 5F 5F 	;-- Grey37
	04 5F 5F 87 	;-- MediumPurple4
	04 5F 5F AF 	;-- SlateBlue3
	0C 5F 5F D7 	;-- SlateBlue3Bis
	0C 5F 5F FF 	;-- RoyalBlue1
	03 5F 87 00 	;-- Chartreuse4
	08 5F 87 5F 	;-- DarkSeaGreen4
	06 5F 87 87 	;-- PaleTurquoise4
	04 5F 87 AF 	;-- SteelBlue
	0C 5F 87 D7 	;-- SteelBlue3
	0C 5F 87 FF 	;-- CornflowerBlue
	03 5F AF 00 	;-- Chartreuse3
	02 5F AF 5F 	;-- DarkSeaGreen4Bis
	02 5F AF 87 	;-- CadetBlue
	06 5F AF AF 	;-- CadetBlueBis
	0E 5F AF D7 	;-- SkyBlue3
	0C 5F AF FF 	;-- SteelBlue1
	0A 5F D7 00 	;-- Chartreuse3Bis
	0A 5F D7 5F 	;-- PaleGreen3Bis
	0A 5F D7 87 	;-- SeaGreen3
	0E 5F D7 AF 	;-- Aquamarine3
	0E 5F D7 D7 	;-- MediumTurquoise
	0E 5F D7 FF 	;-- SteelBlue1Bis
	0A 5F FF 00 	;-- Chartreuse2Bis
	0A 5F FF 5F 	;-- SeaGreen2
	0A 5F FF 87 	;-- SeaGreen1
	0A 5F FF AF 	;-- SeaGreen1Bis
	0E 5F FF D7 	;-- Aquamarine1Bis
	0E 5F FF FF 	;-- DarkSlateGray2
	01 87 00 00 	;-- DarkRedBis
	05 87 00 5F 	;-- DeepPink4Bis
	05 87 00 87 	;-- DarkMagenta
	05 87 00 AF 	;-- DarkMagentaBis
	0D 87 00 D7 	;-- DarkVioletBis
	0D 87 00 FF 	;-- PurpleBis
	03 87 5F 00 	;-- Orange4Bis
	08 87 5F 5F 	;-- LightPink4
	05 87 5F 87 	;-- Plum4
	04 87 5F AF 	;-- MediumPurple3
	0C 87 5F D7 	;-- MediumPurple3Bis
	0C 87 5F FF 	;-- SlateBlue1
	03 87 87 00 	;-- Yellow4
	08 87 87 5F 	;-- Wheat4
	08 87 87 87 	;-- Grey53
	04 87 87 AF 	;-- LightSlateGrey
	0C 87 87 D7 	;-- MediumPurple
	0C 87 87 FF 	;-- LightSlateBlue
	03 87 AF 00 	;-- Yellow4Bis
	07 87 AF 5F 	;-- DarkOliveGreen3
	07 87 AF 87 	;-- DarkSeaGreen
	07 87 AF AF 	;-- LightSkyBlue3
	0C 87 AF D7 	;-- LightSkyBlue3Bis
	0C 87 AF FF 	;-- SkyBlue2
	0B 87 D7 00 	;-- Chartreuse2
	0A 87 D7 5F 	;-- DarkOliveGreen3Bis
	07 87 D7 87 	;-- PaleGreen3
	0A 87 D7 AF 	;-- DarkSeaGreen3
	0E 87 D7 D7 	;-- DarkSlateGray3
	0E 87 D7 FF 	;-- SkyBlue1
	0B 87 FF 00 	;-- Chartreuse1
	0A 87 FF 5F 	;-- LightGreen
	0A 87 FF 87 	;-- LightGreenBis
	0A 87 FF AF 	;-- PaleGreen1
	0E 87 FF D7 	;-- Aquamarine1
	0E 87 FF FF 	;-- DarkSlateGray1
	01 AF 00 00 	;-- Red3
	05 AF 00 5F 	;-- DeepPink4
	05 AF 00 87 	;-- MediumVioletRed
	05 AF 00 AF 	;-- Magenta3
	0D AF 00 D7 	;-- DarkViolet
	0D AF 00 FF 	;-- Purple
	03 AF 5F 00 	;-- DarkOrange3
	07 AF 5F 5F 	;-- IndianRed
	05 AF 5F 87 	;-- HotPink3
	05 AF 5F AF 	;-- MediumOrchid3
	0D AF 5F D7 	;-- MediumOrchid
	0C AF 5F FF 	;-- MediumPurple2
	03 AF 87 00 	;-- DarkGoldenrod
	07 AF 87 5F 	;-- LightSalmon3
	07 AF 87 87 	;-- RosyBrown
	05 AF 87 AF 	;-- Grey63
	0C AF 87 D7 	;-- MediumPurple2Bis
	0C AF 87 FF 	;-- MediumPurple1
	03 AF AF 00 	;-- Gold3
	07 AF AF 5F 	;-- DarkKhaki
	07 AF AF 87 	;-- NavajoWhite3
	07 AF AF AF 	;-- Grey69
	0C AF AF D7 	;-- LightSteelBlue3
	0C AF AF FF 	;-- LightSteelBlue
	0B AF D7 00 	;-- Yellow3
	0B AF D7 5F 	;-- DarkOliveGreen3Ter
	07 AF D7 87 	;-- DarkSeaGreen3Bis
	07 AF D7 AF 	;-- DarkSeaGreen2
	07 AF D7 D7 	;-- LightCyan3
	0C AF D7 FF 	;-- LightSkyBlue1
	0B AF FF 00 	;-- GreenYellow
	0A AF FF 5F 	;-- DarkOliveGreen2
	0A AF FF 87 	;-- PaleGreen1Bis
	0F AF FF AF 	;-- DarkSeaGreen2Bis
	0F AF FF D7 	;-- DarkSeaGreen1
	0E AF FF FF 	;-- PaleTurquoise1
	09 D7 00 00 	;-- Red3Bis
	0D D7 00 5F 	;-- DeepPink3
	0D D7 00 87 	;-- DeepPink3Bis
	0D D7 00 AF 	;-- Magenta3Bis
	0D D7 00 D7 	;-- Magenta3Ter
	0D D7 00 FF 	;-- Magenta2
	09 D7 5F 00 	;-- DarkOrange3Bis
	09 D7 5F 5F 	;-- IndianRedBis
	0D D7 5F 87 	;-- HotPink3Bis
	0D D7 5F AF 	;-- HotPink2
	0D D7 5F D7 	;-- Orchid
	0D D7 5F FF 	;-- MediumOrchid1
	0B D7 87 00 	;-- Orange3
	09 D7 87 5F 	;-- LightSalmon3
	07 D7 87 87 	;-- LightPink3
	0D D7 87 AF 	;-- Pink3
	0D D7 87 D7 	;-- Plum3
	0D D7 87 FF 	;-- Violet
	0B D7 AF 00 	;-- Gold3Bis
	0B D7 AF 5F 	;-- LightGoldenrod3
	07 D7 AF 87 	;-- Tan
	07 D7 AF AF 	;-- MistyRose3
	0D D7 AF D7 	;-- Thistle3
	0C D7 AF FF 	;-- Plum2
	0B D7 D7 00 	;-- Yellow3Bis
	0B D7 D7 5F 	;-- Khaki3
	07 D7 D7 87 	;-- LightGoldenrod2
	07 D7 D7 AF 	;-- LightYellow3
	07 D7 D7 D7 	;-- Grey84
	0C D7 D7 FF 	;-- LightSteelBlue1
	0B D7 FF 00 	;-- Yellow2
	0B D7 FF 5F 	;-- DarkOliveGreen1
	0B D7 FF 87 	;-- DarkOliveGreen1Bis
	0F D7 FF AF 	;-- DarkSeaGreen1Bis
	0F D7 FF D7 	;-- Honeydew2
	0F D7 FF FF 	;-- LightCyan1Bis
	09 FF 00 00 	;-- Red1
	0D FF 00 5F 	;-- DeepPink2
	0D FF 00 87 	;-- DeepPink1
	0D FF 00 AF 	;-- DeepPink1Bis
	0D FF 00 D7 	;-- Magenta2Bis
	0D FF 00 FF 	;-- Magenta1
	09 FF 5F 00 	;-- OrangeRed1
	09 FF 5F 5F 	;-- IndianRed1
	0D FF 5F 87 	;-- IndianRed1Bis
	0D FF 5F AF 	;-- HotPink
	0D FF 5F D7 	;-- HotPinkBis
	0D FF 5F FF 	;-- MediumOrchid1Bis
	0B FF 87 00 	;-- DarkOrange
	09 FF 87 5F 	;-- Salmon1
	0F FF 87 87 	;-- LightCoral
	0D FF 87 AF 	;-- PaleVioletRed1
	0D FF 87 D7 	;-- Orchid2
	0D FF 87 FF 	;-- Orchid1
	0B FF AF 00 	;-- Orange1
	09 FF AF 5F 	;-- SandyBrown
	0F FF AF 87 	;-- LightSalmon1
	0F FF AF AF 	;-- LightPink1
	0D FF AF D7 	;-- Pink1
	0D FF AF FF 	;-- Plum1
	0B FF D7 00 	;-- Gold1
	0B FF D7 5F 	;-- LightGoldenrod2Bis
	0F FF D7 87 	;-- LightGoldenrod2Ter
	0F FF D7 AF 	;-- NavajoWhite1
	0F FF D7 D7 	;-- MistyRose1
	0D FF D7 FF 	;-- Thistle1
	0B FF FF 00 	;-- Yellow1
	0B FF FF 5F 	;-- LightGoldenrod1
	0F FF FF 87 	;-- Khaki1
	0F FF FF AF 	;-- Wheat1
	0F FF FF D7 	;-- Cornsilk1
	0F FF FF FF 	;-- Grey100
	00 08 08 08 	;-- Grey3
	00 12 12 12 	;-- Grey7
	00 1C 1C 1C 	;-- Grey11
	00 26 26 26 	;-- Grey15
	00 30 30 30 	;-- Grey19
	00 3A 3A 3A 	;-- Grey23
	08 44 44 44 	;-- Grey27
	08 4E 4E 4E 	;-- Grey30
	08 58 58 58 	;-- Grey35
	08 62 62 62 	;-- Grey39
	08 6C 6C 6C 	;-- Grey42
	08 76 76 76 	;-- Grey46
	08 80 80 80 	;-- Grey50
	08 8A 8A 8A 	;-- Grey54
	08 94 94 94 	;-- Grey58
	08 9E 9E 9E 	;-- Grey62
	07 A8 A8 A8 	;-- Grey66
	07 B2 B2 B2 	;-- Grey70
	07 BC BC BC 	;-- Grey74
	07 C6 C6 C6 	;-- Grey78
	07 D0 D0 D0 	;-- Grey82
	07 DA DA DA 	;-- Grey85
	0F E4 E4 E4 	;-- Grey89
	0F EE EE EE 	;-- Grey93
}

color-to-index: func [
	v		[integer!]
	return: [integer!]
][
	case [
		v < 48  [0]
		v < 115 [1]
		true [v - 35 / 40]
	]
]

make-color-256: func [
	clr		[integer!]
	return: [integer!]
	/local
		closest [integer!]
		best	[integer!]
		r g b	[integer!]
		rr gg bb [integer!]
		ci		[integer!]
		gray	[integer!]
		average [integer!]
		p		[byte-ptr!]
		d1 d2	[integer!]
][
	if clr >>> 24 = FFh [return 0]

	r: clr and FFh
	g: clr and FF00h >> 8
	b: clr and 00FF0000h >> 16 
	rr: color-to-index r
	gg: color-to-index g
	bb: color-to-index b

	ci: 36 * rr + (6 * gg) + bb
	ci: 16 + ci

	average: rr + gg + bb / 3
	gray: either average > 238 [23][average - 3 / 10]
	gray: 232 + gray

	p: color-table + (ci * 4)
	rr: as-integer p/2 gg: as-integer p/3 bb: as-integer p/4
	rr: rr - r gg: gg - g bb: bb - b
	d1: rr * rr + (gg * gg) + (bb * bb)

	p: color-table + (gray * 4)
	rr: as-integer p/2 gg: as-integer p/3 bb: as-integer p/4
	rr: rr - r gg: gg - g bb: bb - b
	d2: rr * rr + (gg * gg) + (bb * bb)
	ci: either d1 < d2 [ci][gray]
	MAKE_COLOR_256(ci)
]

char-width?: func [
	cp		[integer!]
	return: [integer!]
][
	wcwidth? cp
]

string-width?: func [
	str		[red-string!]
	limit-w [integer!]
	end-idx [int-ptr!]
	nlines	[int-ptr!]
	return: [integer!]
	/local
		series	[series!]
		unit	[integer!]
		offset	[byte-ptr!]
		tail	[byte-ptr!]
		cp idx	[integer!]
		len n	[integer!]
		max-len [integer!]
		cnt		[integer!]
][
	cnt: 	 1
	len:	 0
	max-len: 0
	idx:	 0
	series: GET_BUFFER(str)
	unit: 	GET_UNIT(series)
	offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
	tail:   as byte-ptr! series/tail

	while [
		all [offset < tail len < limit-w]
	][
		cp: string/get-char offset unit
		either cp = as-integer lf [
			cnt: cnt + 1
			if len > max-len [max-len: len]
			len: 0
		][
			n: char-width? cp
			len: len + n
		]
		idx: idx + 1
		offset: offset + unit
	]
	if len > max-len [max-len: len]
	if max-len > limit-w [
		max-len: max-len - n
		idx: idx - 1
	]
	if end-idx <> null [end-idx/value: idx]
	if nlines <> null [nlines/value: cnt]
	max-len
]

back-to-console: func [][
	if tty/raw-mode? [
		screen/reset-cursor
		screen/enter-tui?: no
		fflush 0
		tty/restore-output
	]
]

enter-tui: func [][
	if tty/raw-mode? [
		tty/set-output
		screen/present?: yes
		tty/report-cursor-position
	]
]