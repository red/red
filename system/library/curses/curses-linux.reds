Red/System [
	Title:   "Linux Red/System Curses binding constant"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %curses-linux.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum char-attibutes! [
	A_NORMAL:     00000000h
	A_UNDERLINE:  00020000h								;-- NCURSES_BITS(1U,9)  (add 8 to last argument)
	A_REVERSE:    00040000h								;-- NCURSES_BITS(1U,10)
	A_BLINK:      00080000h								;-- NCURSES_BITS(1U,11)
	A_DIM:        00100000h								;-- NCURSES_BITS(1U,12)
	A_BOLD:       00200000h								;-- NCURSES_BITS(1U,13)
	A_ALTCHARSET: 00400000h								;-- NCURSES_BITS(1U,14)
	A_INVIS:      00800000h								;-- NCURSES_BITS(1U,15)
	A_COLOR:      0000FF00h								;-- NCURSES_BITS(((1U) << 8) - 1U,0)
	A_ATTRIBUTES: FFFFFF00h								;-- NCURSES_BITS(~(1U - 1U),0)
	A_CHARTEXT:   000000FFh								;-- (NCURSES_BITS(1U,0) - 1U)
]
#enum bit-shifts! [
	PDC_COLOR_SHIFT: 8
	PDC_ATTR_SHIFT:  16
]
#enum char-colors! [
	COLOR_BLACK:   0
	COLOR_RED:     1
	COLOR_GREEN:   2
	COLOR_YELLOW:  3
	COLOR_BLUE:    4
	COLOR_MAGENTA: 5
	COLOR_CYAN:    6
	COLOR_WHITE:   7
]

	;-- Keypad Key Definitions.

#enum key-code! [
	KEY_CODE_YES:  0100h  								;-- A wchar_t contains a key code
	KEY_MIN:       0101h  								;-- Minimum curses key
	KEY_BREAK:     0101h  								;-- Break key (unreliable)
	KEY_SRESET:    0158h  								;-- Soft (partial) reset (unreliable)
	KEY_RESET:     0159h  								;-- Reset or hard reset (unreliable)

	KEY_DOWN:      0102h  								;-- down-arrow key
	KEY_UP:        0103h  								;-- up-arrow key
	KEY_LEFT:      0104h  								;-- left-arrow key
	KEY_RIGHT:     0105h  								;-- right-arrow key
	KEY_HOME:      0106h  								;-- home key
	KEY_BACKSPACE: 0107h  								;-- backspace key
	KEY_F0:        0108h  								;-- function keys; 64 reserved
	KEY_F1:        0109h
	KEY_F2:        010Ah
	KEY_F3:        010Bh
	KEY_F4:        010Ch
	KEY_F5:        010Dh
	KEY_F6:        010Eh
	KEY_F7:        010Fh
	KEY_F8:        0110h
	KEY_F9:        0111h
	KEY_F10:       0112h
	KEY_F11:       0113h
	KEY_F12:       0114h
	;--    KEY_F:(n)  (KEY_F0:+(n))  ; Value of function key n
	KEY_DL:        0148h  								;-- delete-line key
	KEY_IL:        0149h  								;-- insert-line key
	KEY_DC:        014Ah  								;-- delete-character key
	KEY_IC:        014Bh  								;-- insert-character key
	KEY_EIC:       014Ch  								;-- sent by rmir or smir in insert mode
	KEY_CLEAR:     014Dh  								;-- clear-screen or erase key
	KEY_EOS:       014Eh  								;-- clear-to-end-of-screen key
	KEY_EOL:       014Fh  								;-- clear-to-end-of-line key
	KEY_SF:        0150h  								;-- scroll-forward key
	KEY_SR:        0151h  								;-- scroll-backward key
	KEY_NPAGE:     0152h  								;-- next-page key
	KEY_PPAGE:     0153h  								;-- previous-page key
	KEY_STAB:      0154h  								;-- set-tab key
	KEY_CTAB:      0155h  								;-- clear-tab key
	KEY_CATAB:     0156h  								;-- clear-all-tabs key
	KEY_ENTER:     0157h  								;-- enter/send key
	KEY_PRINT:     015Ah  								;-- print key
	KEY_LL:        015Bh  								;-- lower-left key (home down)
	KEY_A1:        015Ch  								;-- upper left of keypad
	KEY_A3:        015Dh  								;-- upper right of keypad
	KEY_B2:        015Eh  								;-- center of keypad
	KEY_C1:        015Fh  								;-- lower left of keypad
	KEY_C3:        0160h  								;-- lower right of keypad
	KEY_BTAB:      0161h  								;-- back-tab key
	KEY_BEG:       0162h  								;-- begin key
	KEY_CANCEL:    0163h  								;-- cancel key
	KEY_CLOSE:     0164h  								;-- close key
	KEY_COMMAND:   0165h  								;-- command key
	KEY_COPY:      0166h  								;-- copy key
	KEY_CREATE:    0167h  								;-- create key
	KEY_END:       0168h  								;-- end key
	KEY_EXIT:      0169h  								;-- exit key
	KEY_FIND:      016Ah  								;-- find key
	KEY_HELP:      016Bh  								;-- help key
	KEY_MARK:      016Ch  								;-- mark key
	KEY_MESSAGE:   016Dh  								;-- message key
	KEY_MOVE:      016Eh  								;-- move key
	KEY_NEXT:      016Fh  								;-- next key
	KEY_OPEN:      0170h  								;-- open key
	KEY_OPTIONS:   0171h  								;-- options key
	KEY_PREVIOUS:  0172h  								;-- previous key
	KEY_REDO:      0173h  								;-- redo key
	KEY_REFERENCE: 0174h  								;-- reference key
	KEY_REFRESH:   0175h  								;-- refresh key
	KEY_REPLACE:   0176h  								;-- replace key
	KEY_RESTART:   0177h  								;-- restart key
	KEY_RESUME:    0178h  								;-- resume key
	KEY_SAVE:      0179h  								;-- save key
	KEY_SBEG:      017Ah  								;-- shifted begin key
	KEY_SCANCEL:   017Bh  								;-- shifted cancel key
	KEY_SCOMMAND:  017Ch  								;-- shifted command key
	KEY_SCOPY:     017Dh  								;-- shifted copy key
	KEY_SCREATE:   017Eh  								;-- shifted create key
	KEY_SDC:       017Fh  								;-- shifted delete-character key
	KEY_SDL:       0180h  								;-- shifted delete-line key
	KEY_SELECT:    0181h  								;-- select key
	KEY_SEND:      0182h  								;-- shifted end key
	KEY_SEOL:      0183h  								;-- shifted clear-to-end-of-line key
	KEY_SEXIT:     0184h  								;-- shifted exit key
	KEY_SFIND:     0185h  								;-- shifted find key
	KEY_SHELP:     0186h  								;-- shifted help key
	KEY_SHOME:     0187h  								;-- shifted home key
	KEY_SIC:       0188h  								;-- shifted insert-character key
	KEY_SLEFT:     0189h  								;-- shifted left-arrow key
	KEY_SMESSAGE:  018Ah  								;-- shifted message key
	KEY_SMOVE:     018Bh  								;-- shifted move key
	KEY_SNEXT:     018Ch  								;-- shifted next key
	KEY_SOPTIONS:  018Dh  								;-- shifted options key
	KEY_SPREVIOUS: 018Eh  								;-- shifted previous key
	KEY_SPRINT:    018Fh  								;-- shifted print key
	KEY_SREDO:     0190h  								;-- shifted redo key
	KEY_SREPLACE:  0191h  								;-- shifted replace key
	KEY_SRIGHT:    0192h  								;-- shifted right-arrow key
	KEY_SRSUME:    0193h  								;-- shifted resume key
	KEY_SSAVE:     0194h  								;-- shifted save key
	KEY_SSUSPEND:  0195h  								;-- shifted suspend key
	KEY_SUNDO:     0196h  								;-- shifted undo key
	KEY_SUSPEND:   0197h  								;-- suspend key
	KEY_UNDO:      0198h  								;-- undo key
	KEY_MOUSE:     0199h  								;-- Mouse event has occurred
	KEY_RESIZE:    019Ah  								;-- Terminal resize event
	KEY_EVENT:     019Bh  								;-- We were interrupted by an event

	KEY_MAX:       01FFh  								;-- Maximum key value is    019Bh

	;-- Not included in Linux curses.h. Added manually with Windows constant names.
	CTL_UP:        0236h								;-- ctl-up arrow
	CTL_DOWN:      020Dh								;-- ctl-down arrow
	CTL_LEFT:      0221h								;-- Control-Left-Arrow
	CTL_RIGHT:     0230h
	CTL_PGUP:      022Bh
	CTL_PGDN:      0226h
	CTL_HOME:      0217h
	CTL_END:       0207h
]
