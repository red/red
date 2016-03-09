Red/System [
	Title:    "panel Binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %panel.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.3.1
		panel      >= 5.9 (Linux)
		pdcurses   >= 3.4 (Windows)
	}
]

panel: context [

	#define window! integer!
	#define panel!  integer!

	#switch OS [
		Windows   [ #define panel-library "pdcurses.dll" ]
		MacOSX    [ #define panel-library "panelw.dylib" ] ;-- TODO: check this
		#default  [ #define panel-library "libpanelw.so.5" ]
	]

	#import [panel-library cdecl [
		new-panel: "new_panel" [						;-- Allocates a PANEL structure, places the panel on the top of the stack.
			win       [window!]
			return:   [panel!]
		]
		update-panels: "update_panels" [				;-- Refreshes the virtual screen to reflect the panels in the stack, but does not call doupdate to refresh the physical screen.
			return:   [integer!]
		]
		hide-panel: "hide_panel" [						;-- Removes the given panel from the panel stack and thus hides it from view.
			pan       [panel!]
			return:   [integer!]
		]
		show-panel: "show_panel" [						;-- Makes a hidden panel visible by placing it on top of the panels in the panel stack.
			pan       [panel!]
			return:   [integer!]
		]
		del-panel: "del_panel" [						;-- Removes the given panel from the stack and deallocates the PANEL structure (but not its associated window).
			pan       [panel!]
			return:   [integer!]
		]
		top-panel: "top_panel" [						;-- Puts the given visible panel on top of all panels in the stack.
			pan       [panel!]
			return:   [integer!]
		]
		bottom-panel: "bottom_panel" [					;-- Puts panel at the bottom of all panels.
			pan       [panel!]
			return:   [integer!]
		]
		panel-window: "panel_window" [					;-- Returns a pointer to the window of the given panel.
			pan       [panel!]
			return:   [window!]
		]
		panel-above: "panel_above" [					;-- Returns a pointer to the panel above pan.
			pan       [panel!]
			return:   [panel!]
		]
		panel-below: "panel_below" [					;-- Returns a pointer to the panel just below pan.
			pan       [panel!]
			return:   [panel!]
		]
		move-panel: "move_panel" [						;-- Moves the given panel window so that its upper-left corner is at starty, startx.
			pan       [panel!]
			starty    [integer!]
			startx    [integer!]
			return:   [integer!]
		]
		replace-panel: "replace_panel" [				;-- Replaces the current window of panel with window.
			pan       [panel!]
			win       [window!]
			return:   [integer!]
		]
		panel-hidden: "panel_hidden" [					;-- Returns TRUE if the panel is in the panel stack
			pan       [panel!]
			return:   [integer!]
		]
		set-panel-userptr: "set_panel_userptr" [		;-- Sets the panel’s user pointer.
			pan       [panel!]
			data      [int-ptr!]
			return:   [integer!]
		]
		panel-userptr: "panel_userptr" [				;-- Returns the user pointer for a given panel.
			pan       [panel!]
			return:   [int-ptr!]
		]
	] ; cdecl
	] ; #import [panel-library
] ; context panel
