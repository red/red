Red/System [
	Title:	"GTK3 imports"
	Author: "Qingtian Xie"
	File: 	%gtk.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define RED_GTK_APP_ID	"org.red-lang.www"

#define handle! [pointer! [integer!]]

#define gobj_signal_connect(instance signal handler data) [
	g_signal_connect_data instance signal as-integer handler data null 0
]

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
		g_signal_connect_data: "g_signal_connect_data" [
			instance	[int-ptr!]
			signal		[c-string!]
			handler		[integer!]
			data		[int-ptr!]
			notify		[int-ptr!]
			flags		[integer!]
			return:		[integer!]
		]
		g_object_unref: "g_object_unref" [
			object		[int-ptr!]
		]
	;; ]
	;; LIBGDK-file cdecl [
		gdk_screen_width: "gdk_screen_width" [
			return:		[integer!]
		]
		gdk_screen_height: "gdk_screen_height" [
			return:		[integer!]
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
	;; ]
	;; LIBGIO-file cdecl [
		g_application_register: "g_application_register" [
			application [handle!]
			cancellable [int-ptr!]
			error		[int-ptr!]
			return:		[logic!]
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
		g_application_activate: "g_application_activate" [
			app			[handle!]
		]
		gtk_application_get_active_window: "gtk_application_get_active_window" [
			app			[handle!]
			return:		[handle!]
		]
		gtk_application_window_new: "gtk_application_window_new" [
			app			[handle!]
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
		gtk_widget_queue_draw: "gtk_widget_queue_draw" [
			widget		[handle!]
		]
		gtk_widget_show_all: "gtk_widget_show_all" [
			window		[handle!]
		]
		gtk_widget_grab_focus: "gtk_widget_grab_focus" [
			widget		[handle!]
		]
		gtk_widget_set_size_request: "gtk_widget_set_size_request" [
			widget		[handle!]
			width		[integer!]
			height		[integer!]
		]
		gtk_container_add: "gtk_container_add" [
			container	[handle!]
			widget		[handle!]
		]
		gtk_container_get_children: "gtk_container_get_children" [
			container	[handle!]
			return:		[int-ptr!]
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
		gtk_button_new_with_label: "gtk_button_new_with_label" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_check_button_new_with_label: "gtk_check_button_new_with_label" [
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
		gtk_drawing_area_new: "gtk_drawing_area_new" [
			return:		[handle!]
		]
		gtk_label_new: "gtk_label_new" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_entry_new: "gtk_entry_new" [
			return:		[handle!]
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
	;; LIBCAIRO-file cdecl [
		cairo_line_to: "cairo_line_to" [
			cr			[handle!]
			x			[float!]
			y			[float!]
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
		cairo_move_to: "cairo_move_to" [
			cr			[handle!]
			x			[float!]
			y			[float!]
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
		cairo_new_sub_path: "cairo_new_sub_path" [
			cr			[handle!]
		]
		cairo_close_path: "cairo_close_path" [
			cr			[handle!]
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
		cairo_set_line_width: "cairo_set_line_width" [
			cr			[handle!]
			width		[float!]
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
	]
]
