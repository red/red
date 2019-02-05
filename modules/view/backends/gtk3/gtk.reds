Red/System [
	Title:	"GTK3 imports"
	Author: "Qingtian Xie, RCqls"
	File: 	%gtk.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define RED_GTK_APP_ID	"org.red-lang.www"

#define gobj_signal_connect(instance signal handler data) [
	g_signal_connect_data instance signal as-integer handler data null 0
]

#define G_ASCII_DTOSTR_BUF_SIZE	39

RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

tagPOINT: alias struct! [
	x		[integer!]
	y		[integer!]	
]

tagSIZE: alias struct! [
	width	[integer!]
	height	[integer!]
]

tagRECT: alias struct! [
	x		[integer!]
	y		[integer!]	
	width	[integer!]
	height	[integer!]
]

GdkEventKey!: alias struct! [
  type          [integer!]
  window        [int-ptr!]
  send_event    [byte!]
  time          [integer!]
  state         [integer!]
  keyval        [integer!]
  length        [integer!]
  string        [c-string!]
  keycode1      [byte!]
  keycode2		[byte!]
  group			[byte!]
  is_modifier 	[integer!]
]
GdkEventMotion!: alias struct! [
  type 			[integer!]
  window		[int-ptr!]
  send_event	[byte!]
  time 			[integer!]
  x				[float!]
  y				[float!]
  axes			[float-ptr!]
  state			[integer!]
  is_hint1		[byte!] 
  is_hint2		[byte!] 
  device		[int-ptr!]
  x_root		[float!]
  y_root		[float!]
]

GdkEventButton!: alias struct! [
  type 			[integer!]
  window		[int-ptr!]
  send_event	[byte!]
  time 			[integer!]
  x				[float!]
  y				[float!]
  axes			[float-ptr!]
  state			[integer!]
  button		[integer!] 
  device		[int-ptr!]
  x_root		[float!]
  y_root		[float!]
]

GdkEventCrossing!: alias struct! [
  type 			[integer!]
  window		[int-ptr!]
  send_event	[byte!]
  subwindow		[int-ptr!]
  time 			[integer!]
  x				[float!]
  y				[float!]
  x_root		[float!]
  y_root		[float!]
  axes			[float-ptr!]
  state			[integer!]
  is_hint1		[byte!] 
  is_hint2		[byte!] 
  device		[int-ptr!]
  mode			[integer!]
  detail		[integer!]
  focus 		[logic!]
  state 		[integer!]
]

#enum GGApplicationFlags! [
  G_APPLICATION_FLAGS_NONE: 0
  G_APPLICATION_IS_SERVICE: 1
  G_APPLICATION_IS_LAUNCHER: 2
  G_APPLICATION_HANDLES_OPEN: 4
  G_APPLICATION_HANDLES_COMMAND_LINE: 8
  G_APPLICATION_SEND_ENVIRONMENT: 16
  G_APPLICATION_NON_UNIQUE: 32
]

#enum GdkModifierType! [
  GDK_SHIFT_MASK: 1
  GDK_LOCK_MASK: 2
  GDK_CONTROL_MASK: 4
  GDK_MOD1_MASK: 8
  GDK_MOD5_MASK: 128
  GDK_BUTTON1_MASK: 256
  GDK_BUTTON2_MASK: 512
  GDK_BUTTON3_MASK: 1024
  GDK_BUTTON4_MASK: 2048
  GDK_BUTTON5_MASK: 4096
]

#enum GdkEventMask! [
  GDK_EXPOSURE_MASK:             2
  GDK_POINTER_MOTION_MASK:       4
  GDK_POINTER_MOTION_HINT_MASK:  8
  GDK_BUTTON_MOTION_MASK:        16
  GDK_BUTTON1_MOTION_MASK:       32
  GDK_BUTTON2_MOTION_MASK:       64
  GDK_BUTTON3_MOTION_MASK:       128
  GDK_BUTTON_PRESS_MASK:         256
  GDK_BUTTON_RELEASE_MASK:       512
  GDK_KEY_PRESS_MASK:            1024
  GDK_KEY_RELEASE_MASK:          2048
  GDK_ENTER_NOTIFY_MASK:         4096
  GDK_LEAVE_NOTIFY_MASK:         8192
  GDK_FOCUS_CHANGE_MASK:         16384
  GDK_STRUCTURE_MASK:            32768
  GDK_PROPERTY_CHANGE_MASK:      65536
  GDK_VISIBILITY_NOTIFY_MASK:    131072
  GDK_PROXIMITY_IN_MASK:         262144
  GDK_PROXIMITY_OUT_MASK:        524288
  GDK_SUBSTRUCTURE_MASK:         1048576
  GDK_SCROLL_MASK:               2097152
  GDK_TOUCH_MASK:                4194304
  GDK_SMOOTH_SCROLL_MASK:        8388608
  GDK_TOUCHPAD_GESTURE_MASK:     16777216
  GDK_TABLET_PAD_MASK:           33554432
  ;;GDK_ALL_EVENTS_MASK:           fffffffeh
]

GtkTextIter!: alias struct! [ 
  dummy1  [handle!]
  dummy2  [handle!]
  dummy3 [integer!]
  dummy4 [integer!]
  dummy5 [integer!]
  dummy6 [integer!]
  dummy7 [integer!]
  dummy8 [integer!]
  dummy9  [handle!]
  dummy10  [handle!]
  dummy11 [integer!]
  dummy12 [integer!]
  dummy13 [integer!]
  dummy14  [handle!]
]

#enum GtkFileChooserAction! [
  GTK_FILE_CHOOSER_ACTION_OPEN
  GTK_FILE_CHOOSER_ACTION_SAVE
  GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
  GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER
]


#enum pango-style! [
  PANGO_STYLE_NORMAL
  PANGO_STYLE_OBLIQUE
  PANGO_STYLE_ITALIC
]

#enum pango-variant! [
  PANGO_VARIANT_NORMAL
  PANGO_VARIANT_SMALL_CAPS
]

#enum pango-weight! [
  PANGO_WEIGHT_THIN: 100
  PANGO_WEIGHT_ULTRALIGHT: 200
  PANGO_WEIGHT_LIGHT: 300
  PANGO_WEIGHT_SEMILIGHT: 350
  PANGO_WEIGHT_BOOK: 380
  PANGO_WEIGHT_NORMAL: 400
  PANGO_WEIGHT_MEDIUM: 500
  PANGO_WEIGHT_SEMIBOLD: 600
  PANGO_WEIGHT_BOLD: 700
  PANGO_WEIGHT_ULTRABOLD: 800
  PANGO_WEIGHT_HEAVY: 900
  PANGO_WEIGHT_ULTRAHEAVY: 1000
]

#enum pango-stretch! [
  PANGO_STRETCH_ULTRA_CONDENSED
  PANGO_STRETCH_EXTRA_CONDENSED
  PANGO_STRETCH_CONDENSED
  PANGO_STRETCH_SEMI_CONDENSED
  PANGO_STRETCH_NORMAL
  PANGO_STRETCH_SEMI_EXPANDED
  PANGO_STRETCH_EXPANDED
  PANGO_STRETCH_EXTRA_EXPANDED
  PANGO_STRETCH_ULTRA_EXPANDED
]

#enum pango-font-mask! [
  PANGO_FONT_MASK_FAMILY: 1
  PANGO_FONT_MASK_STYLE: 2
  PANGO_FONT_MASK_VARIANT: 4
  PANGO_FONT_MASK_WEIGHT: 8
  PANGO_FONT_MASK_STRETCH: 16
  PANGO_FONT_MASK_SIZE: 32
  PANGO_FONT_MASK_GRAVITY: 64
]

#define PANGO_SCALE 1024
#define PANGO_SCALE_XX_SMALL 0.5787037037037
#define PANGO_SCALE_X_SMALL  0.6444444444444
#define PANGO_SCALE_SMALL    0.8333333333333
#define PANGO_SCALE_MEDIUM   1.0
#define PANGO_SCALE_LARGE    1.2
#define PANGO_SCALE_X_LARGE  1.4399999999999
#define PANGO_SCALE_XX_LARGE 1.728

#enum cairo_font_slant_t! [
	CAIRO_FONT_SLANT_NORMAL
	CAIRO_FONT_SLANT_ITALIC
	CAIRO_FONT_SLANT_OBLIQUE
]

#enum cairo_font_weight_t! [
	CAIRO_FONT_WEIGHT_NORMAL
 	CAIRO_FONT_WEIGHT_BOLD
]

; @@ cairo structures to remove if pango_cairo is enough to draw text on cairo
; cairo_text_extents_t!: alias struct! [ 
;  	x_bearing	[float!]
;  	y_bearing	[float!]
;  	width		[float!]
;  	height		[float!]
;  	x_advance	[float!]
;  	y_advance	[float!]
; ]

cairo_font_extents_t!: alias struct! [
	ascent			[float!]
	descent			[float!]
	height			[float!]
	max_x_advance	[float!]
	max_y_advance	[float!]
]

#either OS = 'Windows [
	;#define LIBGOBJECT-file "libgobject-2.0-0.dll"
	;#define LIBGLIB-file	"libglib-2.0-0.dll"
	;#define LIBGIO-file		"libgio-2.0-0.dll"
	;#define LIBGDK-file		"libgdk-3-0.dll"
	#define LIBGTK-file		"libgtk-3-0.dll"
	;#define LIBCAIRO-file	"libcairo-2.dll"
][
	;#define LIBGOBJECT-file "libgobject-2.0.so.0"
	;#define LIBGLIB-file	"libglib-2.0.so.0"
	;#define LIBGIO-file		"libgio-2.0.so.0"
	;#define LIBGDK-file		"libgdk-3.so.0"
	#define LIBGTK-file		"libgtk-3.so.0"
	;#define LIBCAIRO-file	"libcairo.so"
]

#import [
	LIBGTK-file cdecl [
	;; LIBGOBJECT-file cdecl [
		g_object_set_qdata: "g_object_set_qdata" [
			object		[int-ptr!]
			quark		[integer!]
			data		[int-ptr!]
		]
		g_object_get_qdata: "g_object_get_qdata" [
			object		[int-ptr!]
			quark		[integer!]
			return:		[int-ptr!]
		]
		g_object_set: "g_object_set" [
			[variadic]
		]
		g_object_get: "g_object_get" [
			[variadic]
		]
		g_signal_connect_data: "g_signal_connect_data" [
			instance	[int-ptr!]
			signal		[c-string!]
			handler		[integer!]
			data		[int-ptr!]
			notify		[int-ptr!]
			flags		[integer!]
			return:		[integer!]
		]
		g_signal_emit_by_name: "g_signal_emit_by_name" [
			instance	[int-ptr!]
			signal		[c-string!]
		]
		g_object_ref: "g_object_ref" [
			object		[int-ptr!]
			return:		[int-ptr!]
		]
		g_object_ref_sink: "g_object_ref_sink" [
			object		[int-ptr!]
			return:		[int-ptr!]
		]
		g_object_unref: "g_object_unref" [
			object		[int-ptr!]
		]
		g_source_remove: "g_source_remove" [
			timer		[integer!]
			return:		[logic!]
		]
		g_timeout_add: "g_timeout_add" [
			ts 			[integer!]
			handler		[integer!]
			data		[int-ptr!]
			return: 	[integer!]
		]
	;; ]
	;; LIBGDK-file cdecl [
		gdk_screen_width: "gdk_screen_width" [
			return:		[integer!]
		]
		gdk_screen_height: "gdk_screen_height" [
			return:		[integer!]
		]
		gdk_screen_get_default: "gdk_screen_get_default" [
			return:		[handle!]
		]
		gdk_keymap_get_default: "gdk_keymap_get_default" [
			return: 	[handle!]
		]
		gdk_keyval_name: "gdk_keyval_name" [
			code		[integer!]
			return:		[c-string!]
		]
		gdk_keyval_to_upper: "gdk_keyval_to_upper" [
			code		[integer!]
			return:		[integer!]
		]
		gdk_atom_intern_static_string: "gdk_atom_intern_static_string" [
			name 		[c-string!]
			return:		[handle!]
		]
	;; ]
	;; LIBGLIB-file cdecl [
		g_quark_from_string: "g_quark_from_string" [
			string		[c-string!]
			return:		[integer!]
		]
		g_main_context_default: "g_main_context_default" [
			return:		[integer!]
		]
		g_main_context_acquire: "g_main_context_acquire" [
			context		[integer!]
			return:		[logic!]
		]
		g_main_context_release: "g_main_context_release" [
			context		[integer!]
		]
		g_main_context_iteration: "g_main_context_iteration" [
			context		[integer!]
			block?		[logic!]
			return:		[logic!]
		]
		g_list_length: "g_list_length" [
			list		[int-ptr!]
			return:		[integer!]
		]
		g_list_nth_data: "g_list_nth_data" [
			list		[int-ptr!]
			nth 		[integer!]
			return:		[handle!]
		]
		g_ascii_dtostr: "g_ascii_dtostr" [
			buffer		[c-string!]
			buf_len		[integer!]
			d			[float!]
			return:		[c-string!]
		]
		g_strdup_printf: "g_strdup_printf" [
			[variadic]
			return:		[c-string!]
		]
		g_free: "g_free" [
			pointer		[handle!]
		]
		g_string_new: "g_string_new" [
			return:		[handle!]
		]
		g_string_append: "g_string_append" [
			str		[handle!]
			text	[c-string!]
		]
		g_string_free: "g_string_free" [
			str		[handle!]
			free	[logic!]
			return:	[c-string!]
		]
	;; ]
	;; LIBGIO-file cdecl [
		g_application_register: "g_application_register" [
			application [handle!]
			cancellable [int-ptr!]
			error		[int-ptr!]
			return:		[logic!]
		]
		g_application_activate: "g_application_activate" [
			app			[handle!]
		]
		g_application_id_is_valid: "g_application_id_is_valid" [
			id			[c-string!]
			return: 	[logic!]
		]
		g_settings_sync: "g_settings_sync" []
	;; ]
	;; LIBGTK-file cdecl [
		gtk_application_new: "gtk_application_new" [
			app-id		[c-string!]
			flags		[integer!]
			return:		[handle!]
		]
		gtk_application_get_windows: "gtk_application_get_windows" [
			app			[handle!]
			return:		[int-ptr!]
		]
		gtk_application_get_active_window: "gtk_application_get_active_window" [
			app			[handle!]
			return:		[handle!]
		]
		gtk_application_window_new: "gtk_application_window_new" [
			app			[handle!]
			return:		[handle!]
		]
		gtk_application_add_window: "gtk_application_add_window" [
			app			[handle!]
			window		[handle!]
		]
		gtk_application_remove_window: "gtk_application_remove_window" [
			app			[handle!]
			window		[handle!]
		]
		gtk_file_chooser_dialog_new: "gtk_file_chooser_dialog_new" [
			[variadic]
			return:		[handle!]
		]
		gtk_dialog_run: "gtk_dialog_run" [
			widget 		[handle!]
			return:		[integer!]
		]
		gtk_file_chooser_get_filename: "gtk_file_chooser_get_filename" [
			widget 		[handle!]
			return:		[c-string!]
		]
		; gtk_file_chooser_native_new: "gtk_file_chooser_native_new" [
		; 	[variadic]
		; 	return:		[handle!]
		; ]
		; gtk_native_dialog_run: "gtk_native_dialog_run" [
		; 	widget 		[handle!]
		; 	return:		[integer!]
		; ]
		gtk_font_chooser_dialog_new: "gtk_font_chooser_dialog_new" [
			title 		[c-string!]
			win 		[handle!]
			return: 	[handle!]
		]
		gtk_font_chooser_get_font_desc: "gtk_font_chooser_get_font_desc" [
			font-sel 	[handle!]
			return: 	[handle!]
		]
		gtk_main_iteration: "gtk_main_iteration" [
			return: 	[logic!]
		]
		gtk_events_pending: "gtk_events_pending" [
			return: 	[logic!]
		]
		gtk_window_new: "gtk_window_new" [
			type		[integer!]
			return:		[handle!]
		]
		gtk_window_set_title: "gtk_window_set_title" [
			window		[handle!]
			title		[c-string!]
		]
		gtk_window_set_default_size: "gtk_window_set_default_size" [
			window		[handle!]
			width		[integer!]
			height		[integer!]
		]
		gtk_window_move: "gtk_window_move" [
			window		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_window_present: "gtk_window_present" [
			window		[handle!]
		]
		gtk_window_is_active: "gtk_window_is_active" [
			window		[handle!]
			return:		[logic!]
		]
		gtk_window_set_modal: "gtk_window_set_modal" [
			window		[handle!]
			setting		[logic!]
		]
		gtk_window_set_transient_for: "gtk_window_set_transient_for" [
			window		[handle!]
			parent		[handle!]
		]
		gtk_window_iconify: "gtk_window_iconify" [
			window		[handle!]
		]
		gtk_window_close: "gtk_window_close" [
			window		[handle!]
		]
		gtk_window_set_destroy_with_parent: "gtk_window_set_destroy_with_parent" [
			window		[handle!]
			setting		[logic!]
		]
		gtk_window_get_size: "gtk_window_get_size" [
			window		[handle!]
			width		[handle!]
			height		[handle!]
		]
		gtk_widget_queue_draw: "gtk_widget_queue_draw" [
			widget		[handle!]
		]
		gtk_widget_queue_resize_no_redraw: "gtk_widget_queue_resize_no_redraw" [
			widget		[handle!]
		]
		gtk_widget_show_all: "gtk_widget_show_all" [
			widget		[handle!]
		]
		gtk_widget_hide: "gtk_widget_hide" [
			widget		[handle!]
		]
		gtk_widget_show: "gtk_widget_show" [
			widget		[handle!]
		]
		gtk_widget_set_halign: "gtk_widget_set_halign" [
			widget		[handle!]
			type		[integer!]
		]
		gtk_widget_set_visible: "gtk_widget_set_visible" [
			widget		[handle!]
			state 		[logic!]
		]
		gtk_widget_set_sensitive: "gtk_widget_set_sensitive" [
			widget		[handle!]
			state 		[logic!]
		]
		gtk_widget_grab_focus: "gtk_widget_grab_focus" [
			widget		[handle!]
		]
		gtk_widget_set_size_request: "gtk_widget_set_size_request" [
			widget		[handle!]
			width		[integer!]
			height		[integer!]
		]
		gtk_widget_get_size_request: "gtk_widget_get_size_request" [
			widget		[handle!]
			width		[int-ptr!]
			height		[int-ptr!]
		]
		gtk_widget_size_allocate: "gtk_widget_size_allocate" [
			widget		[handle!]
			alloc		[handle!]
		]
		gtk_widget_compute_expand: "gtk_widget_compute_expand" [
			widget		[handle!]
			direction	[integer!]
			return: 	[logic!]
		]
		gtk_widget_get_allocation: "gtk_widget_get_allocation" [
			widget		[handle!]
			alloc		[handle!]
		]
		gtk_widget_get_allocated_width: "gtk_widget_get_allocated_width" [
			widget		[handle!]
			return: 	[integer!]
		]
		gtk_widget_get_allocated_height: "gtk_widget_get_allocated_height" [
			widget		[handle!]
			return: 	[integer!]
		]
		gtk_widget_set_can_focus: "gtk_widget_set_can_focus" [
			widget		[handle!]
			focus		[logic!]
		]
		gtk_widget_set_focus_on_click: "gtk_widget_set_focus_on_click" [
			widget		[handle!]
			focus		[logic!]
		]
		gtk_widget_destroy: "gtk_widget_destroy" [
			widget 	[handle!]
		]
		gtk_widget_create_pango_layout: "gtk_widget_create_pango_layout" [
			widget 	[handle!]
			text	[c-string!]
			return:	[handle!]
		]
		gtk_widget_add_events: "gtk_widget_add_events" [
			widget 	[handle!]
			mask 	[integer!]
		]
		gtk_widget_override_font: "gtk_widget_override_font" [
			widget	[handle!]
			fd		[handle!] 
		]
		gtk_widget_override_color: "gtk_widget_override_color" [
			widget	[handle!]
			state	[integer!]
			color	[handle!] 
		]
		gtk_container_add: "gtk_container_add" [
			container	[handle!]
			widget		[handle!]
		]
		gtk_container_get_children: "gtk_container_get_children" [
			container	[handle!]
			return:		[int-ptr!]
		]
		gtk_container_foreach: "gtk_container_foreach" [
			container	[handle!]
			handler		[integer!]
			data		[int-ptr!]
		]
		gtk_container_remove: "gtk_container_remove" [
			container	[handle!]
			widget		[handle!]
		]
		gtk_frame_new: "gtk_frame_new" [
			label		[c-string!]
			return: 	[handle!]
		]
		gtk_frame_set_label: "gtk_frame_set_label" [
			frame		[handle!]
			label		[c-string!]
		]
		gtk_frame_set_label_align: "gtk_frame_set_label_align" [
			frame		[handle!]
			xalign		[float!]
			yalign		[float!]
		]
		gtk_frame_set_shadow_type: "gtk_frame_set_shadow_type" [
			frame		[handle!]
			shadow		[integer!]
		]
		gtk_fixed_new: "gtk_fixed_new" [
			return:		[handle!]
		]
		gtk_fixed_put: "gtk_fixed_put" [
			fixed		[handle!]
			widget		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_fixed_move: "gtk_fixed_move" [
			fixed		[handle!]
			widget		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_layout_new: "gtk_layout_new" [
			hadj		[handle!]
			vadj		[handle!]
			return:		[handle!]
		]
		gtk_layout_put: "gtk_layout_put" [
			layout		[handle!]
			widget		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_bin_get_child: "gtk_bin_get_child" [
			bin			[handle!]
			return:		[handle!]
		]
		gtk_list_box_new: "gtk_list_box_new" [
			return:		[handle!]
		]
		gtk_list_box_select_row: "gtk_list_box_select_row" [
			listbox		[handle!]
			row			[handle!]
		]
		gtk_list_box_get_selected_row: "gtk_list_box_get_selected_row" [
			listbox		[handle!]
			return:		[handle!]
		]
		gtk_list_box_get_row_at_index: "gtk_list_box_get_row_at_index" [
			listbox		[handle!]
			index		[integer!]
			return:		[handle!]
		]
		gtk_list_box_row_get_index: "gtk_list_box_row_get_index" [
			row			[handle!]
			return:		[integer!]
		]
		gtk_scrolled_window_new: "gtk_scrolled_window_new" [
			hadj		[handle!]
			vadj		[handle!]
			return:		[handle!]
		]
		gtk_scrolled_window_set_shadow_type: "gtk_scrolled_window_set_shadow_type" [
			hwnd		[handle!]
			type		[integer!]
		]
		gtk_button_new_with_label: "gtk_button_new_with_label" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_button_set_label: "gtk_button_set_label" [
			button		[handle!]
			label		[c-string!]
		]
		gtk_button_set_image: "gtk_button_set_image" [
			button 		[handle!]
			image 		[handle!]
		]
		gtk_check_button_new_with_label: "gtk_check_button_new_with_label" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_radio_button_new_with_label: "gtk_radio_button_new_with_label" [
			group		[handle!]
			label		[c-string!]
			return:		[handle!]
		]
		gtk_radio_button_new_with_label_from_widget: "gtk_radio_button_new_with_label_from_widget" [
			group		[handle!]
			label		[c-string!]
			return:		[handle!]
		]
		gtk_toggle_button_get_active: "gtk_toggle_button_get_active" [
			button		[handle!]
			return:		[logic!]
		]
		gtk_toggle_button_get_inconsistent: "gtk_toggle_button_get_inconsistent" [
			button		[handle!]
			return:		[logic!]
		]
		gtk_toggle_button_set_inconsistent: "gtk_toggle_button_get_inconsistent" [
			button		[handle!]
			inconsist?	[logic!]
		]
		gtk_toggle_button_set_active: "gtk_toggle_button_set_active" [
			button		[handle!]
			active?		[logic!]
		]
		gtk_toggle_button_toggled: "gtk_toggle_button_toggled" [
			button		[handle!]
		]
		gtk_radio_button_get_group: "gtk_radio_button_get_group" [
			radio 		[handle!]
			return:		[handle!]
		]
		gtk_drawing_area_new: "gtk_drawing_area_new" [
			return:		[handle!]
		]
		gtk_image_new_from_pixbuf: "gtk_image_new_from_pixbuf" [
			pixbuf 		[handle!]
			return: 	[handle!]
		]
		gtk_image_new_from_file: "gtk_image_new_from_file" [
			filename 	[c-string!]
			return: 	[handle!]
		]
		gtk_label_new: "gtk_label_new" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_label_get_text: "gtk_label_get_text" [
			widget		[handle!]
			return:		[c-string!]
		]
		gtk_label_set_text: "gtk_label_set_text" [
			widget		[handle!]
			label		[c-string!]
		]
		gtk_event_box_new: "gtk_event_box_new" [
			return: 	[handle!]
		]
		gtk_entry_new: "gtk_entry_new" [
			return:		[handle!]
		]
		gtk_entry_set_width_chars: "gtk_entry_set_width_chars" [
			entry		[handle!]
			nchars		[integer!]
		]
		gtk_entry_get_buffer: "gtk_entry_get_buffer" [
			entry		[handle!]
			return:		[handle!]
		]
		gtk_entry_get_text: "gtk_entry_get_text" [
			buffer		[handle!]
			return: 	[c-string!]
		]
		gtk_entry_set_text: "gtk_entry_set_text" [
			buffer		[handle!]
			text		[c-string!]
		]
		gtk_entry_buffer_set_text: "gtk_entry_buffer_set_text" [
			buffer		[handle!]
			text		[c-string!]
			len			[integer!]
		]

		gtk_scale_new_with_range: "gtk_scale_new_with_range" [
			vertical?	[logic!]
			min			[float!]
			max			[float!]
			step		[float!]
			return:		[handle!]
		]
		gtk_scale_set_draw_value: "gtk_scale_set_draw_value" [
			scale		[handle!]
			draw?		[logic!]
		]
		gtk_scale_set_has_origin: "gtk_scale_set_has_origin" [
			scale		[handle!]
			origin?		[logic!]
		]
		gtk_range_set_value: "gtk_range_set_value" [
			range		[handle!]
			value		[float!]
		]
		gtk_range_get_value: "gtk_range_get_value" [
			range		[handle!]
			return:		[float!]
		]
		gtk_progress_bar_new: "gtk_progress_bar_new" [
			return:		[handle!]
		]
		gtk_progress_bar_set_fraction: "gtk_progress_bar_set_fraction" [
			progress	[handle!]
			val			[float!]
		]
		gtk_progress_bar_get_fraction: "gtk_progress_bar_get_fraction" [
			progress	[handle!]
			return:		[float!]
		]
		gtk_progress_bar_set_inverted: "gtk_progress_bar_set_inverted" [
			progress 	[handle!]
			inv 		[logic!]
		]
		gtk_orientable_set_orientation: "gtk_orientable_set_orientation" [
			widget 		[handle!]
			orient		[integer!]
		]
		gtk_text_view_new: "gtk_text_view_new" [
			return:		[handle!]
		]
		gtk_text_view_get_buffer: "gtk_text_view_get_buffer" [
			view		[handle!]
			return:		[handle!]
		]
		gtk_text_buffer_set_text: "gtk_text_buffer_set_text" [
			buffer		[handle!]
			text		[c-string!]
			len			[integer!]
		]
		gtk_text_buffer_get_text: "gtk_text_buffer_get_text" [
			buffer		[handle!]
			start		[handle!]
			end			[handle!]
			exclude		[logic!]
			return:		[c-string!]
		]
		gtk_text_buffer_get_bounds: "gtk_text_buffer_get_bounds" [
			buffer		[handle!]
			start		[handle!]
			end			[handle!]
		]
		gtk_text_buffer_create_tag: "gtk_text_buffer_create_tag" [
			[variadic]
			return: 	[handle!]
		]
		gtk_combo_box_text_new: "gtk_combo_box_text_new" [
			return:		[handle!]
		]
		gtk_combo_box_text_new_with_entry: "gtk_combo_box_text_new_with_entry"  [
			return:		[handle!]
		]
		gtk_combo_box_text_append_text: "gtk_combo_box_text_append_text" [
			combo		[handle!]
			item 		[c-string!]
		]
		gtk_combo_box_text_remove_all: "gtk_combo_box_text_remove_all" [
			combo		[handle!]
		]
		gtk_combo_box_get_active: "gtk_combo_box_get_active" [
			combo		[handle!]
			return: 	[integer!]
		]
		gtk_combo_box_set_active: "gtk_combo_box_set_active" [
			combo		[handle!]
			item		[integer!]
		]
		gtk_combo_box_text_get_active_text: "gtk_combo_box_text_get_active_text"  [
			combo		[handle!]
			return:		[c-string!]
		]
		gtk_notebook_new: "gtk_notebook_new" [
			return:		[handle!]
		]
		gtk_notebook_append_page: "gtk_notebook_append_page" [
			nb			[handle!]
			pane		[handle!]
			label		[handle!]
			return: 	[integer!]
		]
		gtk_notebook_get_current_page: "gtk_notebook_get_current_page" [
			nb			[handle!]
			return: 	[integer!]
		]

		gtk_notebook_set_current_page: "gtk_notebook_set_current_page" [
			nb			[handle!]
			index 		[integer!]
		]

		gtk_notebook_get_nth_page: "gtk_notebook_get_nth_page" [
			nb			[handle!]
			index	 	[integer!]
			return: 	[handle!]
		]
		gtk_notebook_get_tab_label_text: "gtk_notebook_get_tab_label_text" [
			nb			[handle!]
			page		[handle!]
			return:		[c-string!]
		]
		gtk_notebook_get_n_pages: "gtk_notebook_get_n_pages" [
			nb			[handle!]
			return: 	[integer!]	
		]
		gtk_css_provider_new: "gtk_css_provider_new" [
			return:		[handle!]
		]
		gtk_css_provider_load_from_data: "gtk_css_provider_load_from_data" [
			provider	[handle!]
			data		[c-string!]
			length		[integer!]
			error		[handle!]
		]
		gtk_style_context_add_provider: "gtk_style_context_add_provider" [
			context		[handle!]
			provider	[handle!]
			priority	[integer!]
		]
		gtk_style_context_add_provider_for_screen: "gtk_style_context_add_provider_for_screen" [
			screen		[handle!]
			provider	[handle!]
			priority	[integer!]
		]
		gtk_style_context_add_class: "gtk_style_context_add_class" [
			context		[handle!]
			class		[c-string!]
		]
		gtk_style_context_to_string: "gtk_style_context_to_string" [
			context		[handle!]
			type		[integer!]
			return:		[c-string!]
		]
		gtk_style_context_get: "gtk_style_context_get" [
			[variadic]
		]
		gtk_style_context_get_font: "gtk_style_context_get_font" [
			context		[handle!]
			type		[integer!]
			return:		[handle!]
		]
		gtk_widget_get_style_context: "gtk_widget_get_style_context" [
			widget		[handle!]
			return:		[handle!]
		]
		pango_layout_new: "pango_layout_new" [
			context		[handle!]
			return:		[handle!]
		]
   		pango_layout_set_text: "pango_layout_set_text" [
			layout		[handle!]
			text		[c-string!]
			len			[integer!]
		]
   		pango_layout_set_font_description: "pango_layout_set_font_description" [
			layout		[handle!]
			fontdesc	[handle!]
		]
   		pango_layout_get_pixel_size: "pango_layout_get_pixel_size" [
			layout		[handle!]
			width		[int-ptr!]
			height		[int-ptr!]
		]
		pango_font_description_new: "pango_font_description_new" [
			return: 	[handle!]
		]
		pango_font_description_free: "pango_font_description_free" [
			fontdesc 	[handle!]
		]
		pango_font_description_from_string: "pango_font_description_from_string" [
			str			[c-string!]
			return:		[handle!]
		]
		pango_font_description_to_string: "pango_font_description_from_string" [
			fontdesc	[handle!]
			return:		[c-string!]
		]
		pango_font_description_set_family: "pango_font_description_set_family" [
			fontdesc 	[handle!]
			name		[c-string!]
		]
		pango_font_description_get_family: "pango_font_description_get_family" [
			fontdesc 	[handle!]
			return:		[c-string!]
		]
		pango_font_description_set_size: "pango_font_description_set_size" [
			fontdesc 	[handle!]
			size		[integer!]
		]
		pango_font_description_get_size: "pango_font_description_get_size" [
			fontdesc 	[handle!]
			return:		[integer!]
		]
		pango_font_description_set_weight: "pango_font_description_set_weight" [
			fontdesc 	[handle!]
			weight		[integer!]
		]
		pango_font_description_get_weight: "pango_font_description_get_weight" [
			fontdesc 	[handle!]
			return:		[integer!]
		]
		pango_font_description_set_style: "pango_font_description_set_style" [
			fontdesc 	[handle!]
			style		[integer!]
		]
		pango_font_description_get_style: "pango_font_description_get_style"  [
			fontdesc 	[handle!]
			return:		[integer!]
		]
		pango_font_description_set_stretch: "pango_font_description_set_stretch" [
			fontdesc 	[handle!]
			stretch		[integer!]
		]
		pango_font_description_get_stretch: "pango_font_description_get_stretch" [
			fontdesc 	[handle!]
			return:		[integer!]
		]
		pango_font_description_set_variant: "pango_font_description_set_variant" [
			fontdesc 	[handle!]
			variant		[integer!]
		]
		pango_font_description_get_variant: "pango_font_description_get_variant" [
			fontdesc 	[handle!]
			return:		[integer!]
		]
		gdk_pango_context_get: "gdk_pango_context_get" [
			return:		[handle!]
		]

		gtk_widget_get_pango_context: "gtk_widget_get_pango_context" [
			return:		[handle!]
		]
		
		gtk_settings_get_default: "gtk_settings_get_default" [
			return: 	[handle!]
		]

	;; LIBCAIRO-file cdecl [
		cairo_line_to: "cairo_line_to" [
			cr			[handle!]
			x			[float!]
			y			[float!]
		]

		cairo_rel_line_to: "cairo_rel_line_to" [
			cr			[handle!]
			dx			[float!]
			dy			[float!]
		]

		cairo_curve_to: "cairo_curve_to" [
			cr			[handle!]
			x1			[float!]
			y1			[float!]
			x2			[float!]
			y2			[float!]
			x3			[float!]
			y3			[float!]
		]

		cairo_rel_curve_to: "cairo_curve_to" [
			cr			[handle!]
			dx1			[float!]
			dy1			[float!]
			dx2			[float!]
			dy2			[float!]
			dx3			[float!]
			dy3			[float!]
		]

		cairo_move_to: "cairo_move_to" [
			cr			[handle!]
			x			[float!]
			y			[float!]
		]

		cairo_rel_move_to: "cairo_rel_move_to" [
			cr			[handle!]
			dx			[float!]
			dy			[float!]
		]

		cairo_arc: "cairo_arc" [
			cr			[handle!]
			xc			[float!]
			yc			[float!]
			radius		[float!]
			angle1		[float!]
			angle2		[float!]
		]
		cairo_rectangle: "cairo_rectangle" [
			cr			[handle!]
			x			[float!]
			y			[float!]
			w			[float!]
			h			[float!]
		]
		cairo_new_path: "cairo_new_path" [
			cr			[handle!]
		]
		cairo_new_sub_path: "cairo_new_sub_path" [
			cr			[handle!]
		]
		cairo_close_path: "cairo_close_path" [
			cr			[handle!]
		]
		cairo_get_current_point: "cairo_get_current_point" [
			cr			[handle!]
			x			[float-ptr!]
			y			[float-ptr!]
		]
		cairo_has_current_point: "cairo_has_current_point" [
			cr			[handle!]
			return:		[integer!]
		]
		cairo_stroke: "cairo_stroke" [
			cr			[handle!]
		]
		cairo_fill: "cairo_fill" [
			cr			[handle!]
		]
		cairo_fill_preserve: "cairo_fill_preserve" [
			cr			[handle!]
		]
		cairo_paint: "cairo_paint" [
			cr			[handle!]
		]
		cairo_save: "cairo_save" [
			cr			[handle!]
		]
		cairo_scale: "cairo_scale" [
			cr			[handle!]
			x			[float!]
			y			[float!]
		]
		cairo_translate: "cairo_translate" [
			cr			[handle!]
			x			[float!]
			y			[float!]
		]
		cairo_toy_font_face_create: "cairo_toy_font_face_create" [
			family		[c-string!]
			slant		[integer!]
			weight		[integer!]
			return:		[handle!]
		]
		cairo_restore: "cairo_restore" [
			cr			[handle!]
		]
		cairo_set_source_rgba: "cairo_set_source_rgba" [
			cr			[handle!]
			red			[float!]
			green		[float!]
			blue		[float!]
			alpha		[float!]
		]
		cairo_set_line_cap: "cairo_set_line_cap" [
			cr			[handle!]
			line_cap	[integer!]
		]
		cairo_set_line_width: "cairo_set_line_width" [
			cr			[handle!]
			width		[float!]
		]
		cairo_set_line_join: "cairo_set_line_join" [
			cr			[handle!]
			line_join	[integer!]
		]
		cairo_set_source: "cairo_set_source" [
			cr			[handle!]
			source		[handle!]
		]
		cairo_set_source_surface: "cairo_set_source_surface" [
			cr			[handle!]
			surface		[handle!]
			x			[float!]
			y			[float!]
		]
		cairo_set_font_face: "cairo_set_font_face" [
			cr			[handle!]
			font_face	[handle!]
		]
		cairo_set_font_size: "cairo_set_font_size" [
			cr			[handle!]
			size		[float!]
		]
		cairo_show_text: "cairo_show_text" [
			cr          [handle!]
			utf8		[c-string!]
		]
		cairo_get_source: "cairo_get_source" [
			cr			[handle!]
			return:		[handle!]
		]
		cairo_set_antialias: "cairo_set_antialias" [
			cr			[handle!]
			antialias	[integer!]
		]
		cairo_surface_destroy: "cairo_surface_destroy" [
			surface		[handle!]
		]
		cairo_pattern_create_linear: "cairo_pattern_create_linear" [
			x0			[float!]
			y0			[float!]
			x1			[float!]
			y1			[float!]
			return:		[handle!]
		]
		cairo_pattern_create_radial: "cairo_pattern_create_radial" [
			cx0			[float!]
			cy0			[float!]
			radius0		[float!]
			cx1			[float!]
			cy1			[float!]
			radius1		[float!]
			return:		[handle!]
		]
		cairo_pattern_add_color_stop_rgba: "cairo_pattern_add_color_stop_rgba" [
			pattern		[handle!]
			offset		[float!]
			red			[float!]
			green		[float!]
			blue		[float!]
			alpha		[float!]
		]
		cairo_pattern_destroy: "cairo_pattern_destroy" [
			pattern		[handle!]
		]
		cairo_rotate: "cairo_rotate" [
			cr			[handle!]
			angle 		[float!]
		]
		cairo_identity_matrix: "cairo_identity_matrix" [
			cr			[handle!]
		]
		cairo_stroke_preserve: "cairo_stroke_preserve" [
			cr			[handle!]
		]
		; Related to draw text with cairo (no succes for base widget) replaced by pango_cairo
		cairo_select_font_face: "cairo_select_font_face" [
			cr			[handle!]
			family		[c-string!]
			slant		[integer!]
			weight		[integer!]
		]
		; cairo_set_font_size: "cairo_set_font_size" [
		; 	cr			[handle!]
		; 	size		[integer!]
		; ]
		; cairo_text_extents: "cairo_text_extents" [
		; 	cr			[handle!]
		; 	text 		[c-string!]
		; 	extents		[handle!]
		; ]
		cairo_font_extents: "cairo_font_extents" [
			cr			[handle!]
			extents		[cairo_font_extents_t!]
		]
		; cairo_show_text: "cairo_show_text" [
		; 	cr			[handle!]
		; 	text 		[c-string!]
		; ]
		gdk_cairo_set_source_pixbuf: "gdk_cairo_set_source_pixbuf" [
			cr 			[handle!]
			pixbuf 		[handle!]
			x 			[integer!]
			y 			[integer!]
		]
		gdk_pixbuf_new: "gdk_pixbuf_new" [
			colorsp 	[integer!]
			alpha 		[logic!]
			bits 		[integer!]
			width 		[integer!]
			height 		[integer!]
			return: 	[handle!]
		]
		gdk_pixbuf_copy: "gdk_pixbuf_copy" [
			pixbuf 		[handle!]
			return: 	[handle!]
		]
		gdk_pixbuf_scale: "gdk_pixbuf_scale" [
			src			[handle!]
			dest		[handle!]
			dest_x		[integer!]
			dest_y		[integer!]
			dest_width	[integer!]
			dest_height	[integer!]
			offset_x	[float!]
			offset_y	[float!]
			scale_x		[float!]
			scale_y		[float!]
			interp_type	[integer!]
		]
		gdk_pixbuf_scale_simple: "gdk_pixbuf_scale_simple"  [
			src			[handle!]
			dest_width	[integer!]
			dest_height	[integer!]
			interp_type	[integer!]
			return: 	[handle!]
		]
		pango_cairo_create_context: "pango_cairo_create_context" [
			cr 			[handle!]
			return: 	[handle!]
		]
		pango_cairo_create_layout: "pango_cairo_create_layout" [
			cr 			[handle!]
			return: 	[handle!]
		]
		pango_cairo_update_layout: "pango_cairo_update_layout" [
			cr 			[handle!]
			layout 		[handle!]
		]
		pango_cairo_show_layout: "pango_cairo_show_layout" [
			cr 			[handle!]
			layout 		[handle!]
		]
	]
]
