Red/System [
	Title:   "Windows Red/System Curses binding constant"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %curses-win32.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Comment: { Uses Public Domain Curses for windows : http://sourceforge.net/projects/pdcurses/files/
		Version : pdc34dllw.zip
	}
]

#enum char-attributes! [
	A_NORMAL:     00000000h
	A_DIM:        00000000h
	A_ALTCHARSET: 00010000h
	A_INVIS:      00080000h
	A_UNDERLINE:  00100000h
	A_REVERSE:    00200000h
	A_BLINK:      00400000h
	A_BOLD:       00800000h
	A_COLOR:      FF000000h
	A_ATTRIBUTES: FFFF0000h
	A_CHARTEXT:   0000FFFFh
]
#enum bit-shifts! [
	PDC_COLOR_SHIFT: 24
	PDC_ATTR_SHIFT:  20
]
#enum char-colors! [
	COLOR_BLACK:   0
	COLOR_BLUE:    1
	COLOR_GREEN:   2
	COLOR_CYAN:    3
	COLOR_RED:     4
	COLOR_MAGENTA: 5
	COLOR_YELLOW:  6
	COLOR_WHITE:   7
]

;-- Keypad Key Definitions.  Many are just for compatibility.

#enum key-code! [
	KEY_CODE_YES:  0100h								;-- If get_wch() gives a key code

	KEY_BREAK:     0101h								;-- Not on PC KBD
	KEY_DOWN:      0102h								;-- Down arrow key
	KEY_UP:        0103h								;-- Up arrow key
	KEY_LEFT:      0104h								;-- Left arrow key
	KEY_RIGHT:     0105h								;-- Right arrow key
	KEY_HOME:      0106h								;-- home key
	KEY_BACKSPACE: 0107h								;-- not on pc
	KEY_F0:        0108h								;-- function keys; 64 reserved
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
;-- KEY_F:(n)  (KEY_F0:+(n))  ; Value of function key n

	KEY_DL:        0148h								;-- delete line
	KEY_IL:        0149h								;-- insert line
	KEY_DC:        014Ah								;-- delete character
	KEY_IC:        014Bh								;-- insert char or enter ins mode
	KEY_EIC:       014Ch								;-- exit insert char mode
	KEY_CLEAR:     014Dh								;-- clear screen
	KEY_EOS:       014Eh								;-- clear to end of screen
	KEY_EOL:       014Fh								;-- clear to end of line
	KEY_SF:        0150h								;-- scroll 1 line forward
	KEY_SR:        0151h								;-- scroll 1 line back (reverse)
	KEY_NPAGE:     0152h								;-- next page
	KEY_PPAGE:     0153h								;-- previous page
	KEY_STAB:      0154h								;-- set tab
	KEY_CTAB:      0155h								;-- clear tab
	KEY_CATAB:     0156h								;-- clear all tabs
	KEY_ENTER:     0157h								;-- enter or send (unreliable)
	KEY_SRESET:    0158h								;-- soft/reset (partial/unreliable)
	KEY_RESET:     0159h								;-- reset/hard reset (unreliable)
	KEY_PRINT:     015Ah								;-- print/copy
	KEY_LL:        015Bh								;-- home down/bottom (lower left)
	KEY_ABORT:     015Ch								;-- abort/terminate key (any)
	KEY_SHELP:     015Dh								;-- short help
	KEY_LHELP:     015Eh								;-- long help
	KEY_BTAB:      015Fh								;-- Back tab key
	KEY_BEG:       0160h								;-- beg(inning) key
	KEY_CANCEL:    0161h								;-- cancel key
	KEY_CLOSE:     0162h								;-- close key
	KEY_COMMAND:   0163h								;-- cmd (command) key
	KEY_COPY:      0164h								;-- copy key
	KEY_CREATE:    0165h								;-- create key
	KEY_END:       0166h								;-- end key
	KEY_EXIT:      0167h								;-- exit key
	KEY_FIND:      0168h								;-- find key
	KEY_HELP:      0169h								;-- help key
	KEY_MARK:      016Ah								;-- mark key
	KEY_MESSAGE:   016Bh								;-- message key
	KEY_MOVE:      016Ch								;-- move key
	KEY_NEXT:      016Dh								;-- next object key
	KEY_OPEN:      016Eh								;-- open key
	KEY_OPTIONS:   016Fh								;-- options key
	KEY_PREVIOUS:  0170h								;-- previous object key
	KEY_REDO:      0171h								;-- redo key
	KEY_REFERENCE: 0172h								;-- ref(erence) key
	KEY_REFRESH:   0173h								;-- refresh key
	KEY_REPLACE:   0174h								;-- replace key
	KEY_RESTART:   0175h								;-- restart key
	KEY_RESUME:    0176h								;-- resume key
	KEY_SAVE:      0177h								;-- save key
	KEY_SBEG:      0178h								;-- shifted beginning key
	KEY_SCANCEL:   0179h								;-- shifted cancel key
	KEY_SCOMMAND:  017Ah								;-- shifted command key
	KEY_SCOPY:     017Bh								;-- shifted copy key
	KEY_SCREATE:   017Ch								;-- shifted create key
	KEY_SDC:       017Dh								;-- shifted delete char key
	KEY_SDL:       017Eh								;-- shifted delete line key
	KEY_SELECT:    017Fh								;-- select key
	KEY_SEND:      0180h								;-- shifted end key
	KEY_SEOL:      0181h								;-- shifted clear line key
	KEY_SEXIT:     0182h								;-- shifted exit key
	KEY_SFIND:     0183h								;-- shifted find key
	KEY_SHOME:     0184h								;-- shifted home key
	KEY_SIC:       0185h								;-- shifted input key

	KEY_SLEFT:     0187h								;-- shifted left arrow key
	KEY_SMESSAGE:  0188h								;-- shifted message key
	KEY_SMOVE:     0189h								;-- shifted move key
	KEY_SNEXT:     018Ah								;-- shifted next key
	KEY_SOPTIONS:  018Bh								;-- shifted options key
	KEY_SPREVIOUS: 018Ch								;-- shifted prev key
	KEY_SPRINT:    018Dh								;-- shifted print key
	KEY_SREDO:     018Eh								;-- shifted redo key
	KEY_SREPLACE:  018Fh								;-- shifted replace key
	KEY_SRIGHT:    0190h								;-- shifted right arrow
	KEY_SRSUME:    0191h								;-- shifted resume key
	KEY_SSAVE:     0192h								;-- shifted save key
	KEY_SSUSPEND:  0193h								;-- shifted suspend key
	KEY_SUNDO:     0194h								;-- shifted undo key
	KEY_SUSPEND:   0195h								;-- suspend key
	KEY_UNDO:      0196h								;-- undo key

;-- PDCurses-specific KEY definitions -- PC only

	ALT_0:         0197h
	ALT_1:         0198h
	ALT_2:         0199h
	ALT_3:         019Ah
	ALT_4:         019Bh
	ALT_5:         019Ch
	ALT_6:         019Dh
	ALT_7:         019Eh
	ALT_8:         019Fh
	ALT_9:         01A0h
	ALT_A:         01A1h
	ALT_B:         01A2h
	ALT_C:         01A3h
	ALT_D:         01A4h
	ALT_E:         01A5h
	ALT_F:         01A6h
	ALT_G:         01A7h
	ALT_H:         01A8h
	ALT_I:         01A9h
	ALT_J:         01AAh
	ALT_K:         01ABh
	ALT_L:         01ACh
	ALT_M:         01ADh
	ALT_N:         01AEh
	ALT_O:         01AFh
	ALT_P:         01B0h
	ALT_Q:         01B1h
	ALT_R:         01B2h
	ALT_S:         01B3h
	ALT_T:         01B4h
	ALT_U:         01B5h
	ALT_V:         01B6h
	ALT_W:         01B7h
	ALT_X:         01B8h
	ALT_Y:         01B9h
	ALT_Z:         01BAh

	CTL_LEFT:      01BBh								;-- Control-Left-Arrow
	CTL_RIGHT:     01BCh
	CTL_PGUP:      01BDh
	CTL_PGDN:      01BEh
	CTL_HOME:      01BFh
	CTL_END:       01C0h

	KEY_A1:        01C1h								;-- upper left on Virtual keypad
	KEY_A2:        01C2h								;-- upper middle on Virt. keypad
	KEY_A3:        01C3h								;-- upper right on Vir. keypad
	KEY_B1:        01C4h								;-- middle left on Virt. keypad
	KEY_B2:        01C5h								;-- center on Virt. keypad
	KEY_B3:        01C6h								;-- middle right on Vir. keypad
	KEY_C1:        01C7h								;-- lower left on Virt. keypad
	KEY_C2:        01C8h								;-- lower middle on Virt. keypad
	KEY_C3:        01C9h								;-- lower right on Vir. keypad

	PADSLASH:      01CAh								;-- slash on keypad
	PADENTER:      01CBh								;-- enter on keypad
	CTL_PADENTER:  01CCh								;-- ctl-enter on keypad
	ALT_PADENTER:  01CDh								;-- alt-enter on keypad
	PADSTOP:       01CEh								;-- stop on keypad
	PADSTAR:       01CFh								;-- star on keypad
	PADMINUS:      01D0h								;-- minus on keypad
	PADPLUS:       01D1h								;-- plus on keypad
	CTL_PADSTOP:   01D2h								;-- ctl-stop on keypad
	CTL_PADCENTER: 01D3h								;-- ctl-enter on keypad
	CTL_PADPLUS:   01D4h								;-- ctl-plus on keypad
	CTL_PADMINUS:  01D5h								;-- ctl-minus on keypad
	CTL_PADSLASH:  01D6h								;-- ctl-slash on keypad
	CTL_PADSTAR:   01D7h								;-- ctl-star on keypad
	ALT_PADPLUS:   01D8h								;-- alt-plus on keypad
	ALT_PADMINUS:  01D9h								;-- alt-minus on keypad
	ALT_PADSLASH:  01DAh								;-- alt-slash on keypad
	ALT_PADSTAR:   01DBh								;-- alt-star on keypad
	ALT_PADSTOP:   01DCh								;-- alt-stop on keypad
	CTL_INS:       01DDh								;-- ctl-insert
	ALT_DEL:       01DEh								;-- alt-delete
	ALT_INS:       01DFh								;-- alt-insert
	CTL_UP:        01E0h								;-- ctl-up arrow
	CTL_DOWN:      01E1h								;-- ctl-down arrow
	CTL_TAB:       01E2h								;-- ctl-tab
	ALT_TAB:       01E3h
	ALT_MINUS:     01E4h
	ALT_EQUAL:     01E5h
	ALT_HOME:      01E6h
	ALT_PGUP:      01E7h
	ALT_PGDN:      01E8h
	ALT_END:       01E9h
	ALT_UP:        01EAh								;-- alt-up arrow
	ALT_DOWN:      01EBh								;-- alt-down arrow
	ALT_RIGHT:     01ECh								;-- alt-right arrow
	ALT_LEFT:      01EDh								;-- alt-left arrow
	ALT_ENTER:     01EEh								;-- alt-enter
	ALT_ESC:       01EFh								;-- alt-escape
	ALT_BQUOTE:    01F0h								;-- alt-back quote
	ALT_LBRACKET:  01F1h								;-- alt-left bracket
	ALT_RBRACKET:  01F2h								;-- alt-right bracket
	ALT_SEMICOLON: 01F3h								;-- alt-semi-colon
	ALT_FQUOTE:    01F4h								;-- alt-forward quote
	ALT_COMMA:     01F5h								;-- alt-comma
	ALT_STOP:      01F6h								;-- alt-stop
	ALT_FSLASH:    01F7h								;-- alt-forward slash
	ALT_BKSP:      01F8h								;-- alt-backspace
	CTL_BKSP:      01F9h								;-- ctl-backspace
	PAD0:          01FAh								;-- keypad 0

	CTL_PAD0:      01FBh								;-- ctl-keypad 0
	CTL_PAD1:      01FCh
	CTL_PAD2:      01FDh
	CTL_PAD3:      01FEh
	CTL_PAD4:      01FFh
	CTL_PAD5:      0200h
	CTL_PAD6:      0201h
	CTL_PAD7:      0202h
	CTL_PAD8:      0203h
	CTL_PAD9:      0204h

	ALT_PAD0:      0205h								;-- alt-keypad 0
	ALT_PAD1:      0206h
	ALT_PAD2:      0207h
	ALT_PAD3:      0208h
	ALT_PAD4:      0209h
	ALT_PAD5:      020Ah
	ALT_PAD6:      020Bh
	ALT_PAD7:      020Ch
	ALT_PAD8:      020Dh
	ALT_PAD9:      020Eh

	CTL_DEL:       020Fh								;-- clt-delete
	ALT_BSLASH:    0210h								;-- alt-back slash
	CTL_ENTER:     0211h								;-- ctl-enter

	SHF_PADENTER:  0212h								;-- shift-enter on keypad
	SHF_PADSLASH:  0213h								;-- shift-slash on keypad
	SHF_PADSTAR:   0214h								;-- shift-star  on keypad
	SHF_PADPLUS:   0215h								;-- shift-plus  on keypad
	SHF_PADMINUS:  0216h								;-- shift-minus on keypad
	SHF_UP:        0217h								;-- shift-up on keypad
	SHF_DOWN:      0218h								;-- shift-down on keypad
	SHF_IC:        0219h								;-- shift-insert on keypad
	SHF_DC:        021Ah								;-- shift-delete on keypad

	KEY_MOUSE:     021Bh								;-- "mouse" key
	KEY_SHIFT_L:   021Ch								;-- Left-shift
	KEY_SHIFT_R:   021Dh								;-- right-shift
	KEY_CONTROL_L: 021Eh								;-- Left-control
	KEY_CONTROL_R: 021Fh								;-- right-control
	KEY_ALT_L:     0220h								;-- Left-alt
	KEY_ALT_R:     0221h								;-- right-alt
	KEY_RESIZE:    0222h								;-- Window resize
	KEY_SUP:       0223h								;-- shifted up arrow
	KEY_SDOWN:     0224h								;-- shifted down arrow

	KEY_MIN:       KEY_BREAK    						;-- Minimum curses key value
	KEY_MAX:       KEY_SDOWN    						;-- Maximum curses key
]
