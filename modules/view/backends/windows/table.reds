Red/System [
	Title:	"Windows table widget"
	Author: "Nenad Rakocevic"
	File: 	%table.reds
	Tabs: 	4
	Rights: "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-table-data: func [
	hWnd	 [handle!]
	data	 [red-block!]
	selected [red-integer!]
	/local
		row		  [red-block!]
		end		  [red-block!]
		str		  [red-string!]
		tail	  [red-string!]
		c-str	  [c-string!]
		str-saved [c-string!]
		type	  [integer!]
		idx		  [integer!]
		cols	  [integer!]
		value	  [integer!]
		r		  [integer!]
		column	  [tagLVCOLUMNW value]
		item	  [tagLVITEMW value]
][	
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
	][
		row: as red-block! block/rs-head data
		end: as red-block! block/rs-tail data
		if any [row = end TYPE_OF(row) <> TYPE_BLOCK][exit]
		
		str:  as red-string! block/rs-head row
		tail: as red-string! block/rs-tail row
		cols: 0
		column/mask: 	 0Fh							;-- LVCF_FMT | LVCF_WIDTH | LVCF_TEXT | LVCF_SUBITEM
		column/cx: 		 100
		column/fmt: 	 0								;-- LVCFMT_LEFT
				
		while [str < tail][
			type: TYPE_OF(str)
			if ANY_STRING?(type) [
				column/mask: 	 0Fh							;-- LVCF_FMT | LVCF_WIDTH | LVCF_TEXT | LVCF_SUBITEM
				column/cx: 		 100
				column/fmt: 	 0								;-- LVCFMT_LEFT			
				column/iSubItem: cols
				column/pszText:  unicode/to-utf16 str
				SendMessage hWnd LVM_INSERTCOLUMNW cols as-integer column
				cols: cols + 1
			]
			str: str + 1
		]
		row: row + 1
		
		item/mask:		09h						;-- LVIF_TEXT | LVIF_STATE | LVIF_COLUMNS
		item/stateMask: 0
		item/state:		0

		r: 0
		while [row < end][
			str:  as red-string! block/rs-head row
			tail: as red-string! block/rs-tail row
			item/iItem: r
			type: TYPE_OF(str)
			if ANY_STRING?(type) [
				;item/cColumns:	cols
				item/iSubItem: 0
				item/pszText: unicode/to-utf16 str
				SendMessage hWnd LVM_INSERTITEMW 0 as-integer item
				idx: 0
				while [str < tail][
					type: TYPE_OF(str)
					if ANY_STRING?(type) [
						item/iSubItem: idx
						item/pszText: unicode/to-utf16 str
						SendMessage hWnd LVM_SETITEMW 0 as-integer item
						idx: idx + 1
					]
					str: str + 1
				]
			]
			r: r + 1
			row: row + 1
		]
	]
	;SendMessage hWnd LVM_SETTEXTBKCOLOR 0 22EEEEh
	SendMessage hWnd LVM_SETEXTENDEDLISTVIEWSTYLE 0	10018061h 


comment {
#define LVS_EX_GRIDLINES        0x00000001
#define LVS_EX_SUBITEMIMAGES    0x00000002
#define LVS_EX_CHECKBOXES       0x00000004
#define LVS_EX_TRACKSELECT      0x00000008
#define LVS_EX_HEADERDRAGDROP   0x00000010
#define LVS_EX_FULLROWSELECT    0x00000020 // applies to report mode only
#define LVS_EX_ONECLICKACTIVATE 0x00000040
#define LVS_EX_TWOCLICKACTIVATE 0x00000080
#if (_WIN32_IE >= 0x0400)
#define LVS_EX_FLATSB           0x00000100
#define LVS_EX_REGIONAL         0x00000200
#define LVS_EX_INFOTIP          0x00000400 // listview does InfoTips for you
#define LVS_EX_UNDERLINEHOT     0x00000800
#define LVS_EX_UNDERLINECOLD    0x00001000
#define LVS_EX_MULTIWORKAREAS   0x00002000
#endif
#if (_WIN32_IE >= 0x0500)
#define LVS_EX_LABELTIP         0x00004000 // listview unfolds partly hidden labels if it does not have infotip text
#define LVS_EX_BORDERSELECT     0x00008000 // border selection style instead of highlight
#endif  // End (_WIN32_IE >= 0x0500)
#if (_WIN32_WINNT >= 0x0501)
#define LVS_EX_DOUBLEBUFFER     0x00010000
#define LVS_EX_HIDELABELS       0x00020000
#define LVS_EX_SINGLEROW        0x00040000
#define LVS_EX_SNAPTOGRID       0x00080000  // Icons automatically snap to grid.
#define LVS_EX_SIMPLESELECT     0x00100000  // Also changes overlay rendering to top right for icon mode.
#endif
#if _WIN32_WINNT >= 0x0600
#define LVS_EX_JUSTIFYCOLUMNS   0x00200000  // Icons are lined up in columns that use up the whole view area.
#define LVS_EX_TRANSPARENTBKGND 0x00400000  // Background is painted by the parent via WM_PRINTCLIENT
#define LVS_EX_TRANSPARENTSHADOWTEXT 0x00800000  // Enable shadow text on transparent backgrounds only (useful with bitmaps)
#define LVS_EX_AUTOAUTOARRANGE  0x01000000  // Icons automatically arrange if no icon positions have been set
#define LVS_EX_HEADERINALLVIEWS 0x02000000  // Display column header in all view modes
#define LVS_EX_AUTOCHECKSELECT  0x08000000
#define LVS_EX_AUTOSIZECOLUMNS  0x10000000
#define LVS_EX_COLUMNSNAPPOINTS 0x40000000
#define LVS_EX_COLUMNOVERFLOW   0x80000000

Coloring and custom fonts:
https://www.codeproject.com/Articles/646482/Custom-Controls-in-Win-API-Control-Customization

SubItems editing:
https://www.codeproject.com/Articles/6646/In-place-Editing-of-ListView-subitems

Prevent item selection:
https://microsoft.public.win32.programmer.ui.narkive.com/DhrMbhyE/how-to-cancel-disable-selection-of-listview-items
}
	
	;either TYPE_OF(selected) <> TYPE_INTEGER [
	;	selected/header: TYPE_INTEGER
	;	selected/value: -1
	;][
	;	SendMessage hWnd LB_SETCURSEL selected/value - 1 0
	;]
]
