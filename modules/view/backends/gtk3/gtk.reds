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
#define gobj_signal_connect_after(instance signal handler data) [
	g_signal_connect_data instance signal as-integer handler data null 1
]

#define g_signal_handlers_block_by_func(instance handler data) [
	g_signal_handlers_block_matched instance 8 + 16 0 0 null as-integer handler data
]

#define g_signal_handlers_unblock_by_func(instance handler data) [
	g_signal_handlers_unblock_matched instance 8 + 16 0 0 null as-integer handler data
]

#define g_signal_handlers_disconnect_by_data(instance data) [
	g_signal_handlers_disconnect_matched instance 16 0 0 null null data
]

#define G_ASCII_DTOSTR_BUF_SIZE	39

#define G_TYPE_MAKE_FUNDAMENTAL(x) [x << 2]
#define G_TYPE_INT		24 ;[G_TYPE_MAKE_FUNDAMENTAL(6)]

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

GdkWindowAttr!: alias struct! [
	title				[c-string!]
	event_mask			[integer!]
	x					[integer!]
	y					[integer!]
	width				[integer!]
	height				[integer!]
	wclass				[integer!]
	visual				[int-ptr!]
	window_type			[integer!]
	cursor				[int-ptr!]
	wmclass_name		[c-string!]
	wmclass_class		[c-string!]
	override_redirect	[integer!]
	type_hint			[integer!]
]

GdkRectangle!: alias struct! [
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
]

GdkRGBA!: alias struct! [
	red		[float!]
	green	[float!]
	blue	[float!]
	alpha	[float!]
]

GdkEventAny!: alias struct! [
	type		[integer!]
	window		[int-ptr!]
	send_event	[byte!]
]

GdkEventKey!: alias struct! [
	type		[integer!]
	window		[int-ptr!]
	send_event	[byte!]
	time		[integer!]
	state		[integer!]
	keyval		[integer!]
	length		[integer!]
	string		[c-string!]
	keycode1	[byte!]
	keycode2	[byte!]
	group		[byte!]
	is_modifier	[integer!]
]
GdkEventMotion!: alias struct! [
	type 		[integer!]
	window		[int-ptr!]
	send_event	[byte!]
	time 		[integer!]
	x			[float!]
	y			[float!]
	axes		[float-ptr!]
	state		[integer!]
	is_hint1	[byte!]
	is_hint2	[byte!]
	device		[int-ptr!]
	x_root		[float!]
	y_root		[float!]
]

GdkEventButton!: alias struct! [
	type 		[integer!]
	window		[int-ptr!]
	send_event	[byte!]
	time		[integer!]
	x			[float!]
	y			[float!]
	axes		[float-ptr!]
	state		[integer!]
	button		[integer!]
	device		[int-ptr!]
	x_root		[float!]
	y_root		[float!]
]

GdkEventCrossing!: alias struct! [
	type 		[integer!]
	window		[int-ptr!]
	send_event	[byte!]
	subwindow	[int-ptr!]
	time 		[integer!]
	x			[float!]
	y			[float!]
	x_root		[float!]
	y_root		[float!]
	axes		[float-ptr!]
	state		[integer!]
	is_hint1	[byte!]
	is_hint2	[byte!]
	device		[int-ptr!]
	mode		[integer!]
	detail		[integer!]
	focus		[logic!]
	state		[integer!]
]

GdkEventConfigure!: alias struct! [
	type		[integer!]
	window		[handle!]
	send_event	[byte!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
]

GdkEventScroll!: alias struct! [
	type		[integer!]
	window		[handle!]
	send_event	[byte!]
	time		[integer!]
	x			[float!]
	y			[float!]
	state		[integer!]
	direction	[integer!]
	device		[handle!]
	x_root		[float!]
	y_root		[float!]
	delta_x		[float!]
	delta_y		[float!]
	is_stop		[integer!]
]

GdkGeometry!: alias struct! [
	min_width	[integer!]
	min_height	[integer!]
	max_width	[integer!]
	max_height	[integer!]
	base_width	[integer!]
	base_height	[integer!]
	width_inc	[integer!]
	height_inc	[integer!]
	min_aspect	[float!]
	max_aspect	[float!]
	win_gravity	[integer!]
]

#enum GdkScrollDirection! [
	GDK_SCROLL_UP
	GDK_SCROLL_DOWN
	GDK_SCROLL_LEFT
	GDK_SCROLL_RIGHT
	GDK_SCROLL_SMOOTH
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
	GDK_SHIFT_MASK:		1
	GDK_LOCK_MASK:		2
	GDK_CONTROL_MASK:	4
	GDK_MOD1_MASK:		8
	GDK_MOD5_MASK:		128
	GDK_BUTTON1_MASK:	256
	GDK_BUTTON2_MASK:	512
	GDK_BUTTON3_MASK:	1024
	GDK_BUTTON4_MASK:	2048
	GDK_BUTTON5_MASK:	4096
	GDK_SUPER_MASK:		67108864
	GDK_HYPER_MASK:		134217728
	GDK_META_MASK:		268435456
]
#enum GdkEventType! [
	GDK_NOTHING: -1
	GDK_DELETE
	GDK_DESTROY
	GDK_EXPOSE
	GDK_MOTION_NOTIFY
	GDK_BUTTON_PRESS
	GDK_2BUTTON_PRESS:
	GDK_DOUBLE_BUTTON_PRESS: 5
	GDK_3BUTTON_PRESS:
	GDK_TRIPLE_BUTTON_PRESS: 6
	GDK_BUTTON_RELEASE
	GDK_KEY_PRESS
	GDK_KEY_RELEASE
	GDK_ENTER_NOTIFY
	GDK_LEAVE_NOTIFY
	GDK_FOCUS_CHANGE
	GDK_CONFIGURE
	GDK_MAP
	GDK_UNMAP
	GDK_PROPERTY_NOTIFY
	GDK_SELECTION_CLEAR
	GDK_SELECTION_REQUEST
	GDK_SELECTION_NOTIFY
	GDK_PROXIMITY_IN
	GDK_PROXIMITY_OUT
	GDK_DRAG_ENTER
	GDK_DRAG_LEAVE
	GDK_DRAG_MOTION
	GDK_DRAG_STATUS
	GDK_DROP_START
	GDK_DROP_FINISHED
	GDK_CLIENT_EVENT
	GDK_VISIBILITY_NOTIFY
	GDK_SCROLL: 31
	GDK_WINDOW_STATE
	GDK_SETTING
	GDK_OWNER_CHANGE
	GDK_GRAB_BROKEN
	GDK_DAMAGE
	GDK_TOUCH_BEGIN
	GDK_TOUCH_UPDATE
	GDK_TOUCH_END
	GDK_TOUCH_CANCEL
	GDK_TOUCHPAD_SWIPE
	GDK_TOUCHPAD_PINCH
	GDK_PAD_BUTTON_PRESS
	GDK_PAD_BUTTON_RELEASE
	GDK_PAD_RING
	GDK_PAD_STRIP
	GDK_PAD_GROUP_MODE
	GDK_EVENT_LAST
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

GtkAllocation!: alias struct! [
	x			[integer!]
	y			[integer!]
	w			[integer!]
	h			[integer!]
]

GtkTextIter!: alias struct! [
	dummy1		[handle!]
	dummy2		[handle!]
	dummy3		[integer!]
	dummy4		[integer!]
	dummy5		[integer!]
	dummy6		[integer!]
	dummy7		[integer!]
	dummy8		[integer!]
	dummy9		[handle!]
	dummy10		[handle!]
	dummy11		[integer!]
	dummy12		[integer!]
	dummy13		[integer!]
	dummy14		[handle!]
]

#enum GtkFileChooserAction! [
	GTK_FILE_CHOOSER_ACTION_OPEN
	GTK_FILE_CHOOSER_ACTION_SAVE
	GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
	GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER
]

#enum GtkResponseType! [
	GTK_RESPONSE_NONE
	GTK_RESPONSE_REJECT
	GTK_RESPONSE_ACCEPT
	GTK_RESPONSE_DELETE_EVENT
	GTK_RESPONSE_OK
	GTK_RESPONSE_CANCEL
	GTK_RESPONSE_CLOSE
	GTK_RESPONSE_YES
	GTK_RESPONSE_NO
	GTK_RESPONSE_APPLY
	GTK_RESPONSE_HELP
]

#enum GtkJustification! [
	GTK_JUSTIFY_LEFT
	GTK_JUSTIFY_RIGHT
	GTK_JUSTIFY_CENTER
	GTK_JUSTIFY_FILL
]

#enum GtkWrapMode! [
	GTK_WRAP_NONE
	GTK_WRAP_CHAR
	GTK_WRAP_WORD
	GTK_WRAP_WORD_CHAR
]

#enum GtkAlign! [
	GTK_ALIGN_FILL
	GTK_ALIGN_START
	GTK_ALIGN_END
	GTK_ALIGN_CENTER
	GTK_ALIGN_BASELINE
]

#enum GtkInputPurpose! [
	GTK_INPUT_PURPOSE_FREE_FORM
	GTK_INPUT_PURPOSE_ALPHA
	GTK_INPUT_PURPOSE_DIGITS
	GTK_INPUT_PURPOSE_NUMBER
	GTK_INPUT_PURPOSE_PHONE
	GTK_INPUT_PURPOSE_URL
	GTK_INPUT_PURPOSE_EMAIL
	GTK_INPUT_PURPOSE_NAME
	GTK_INPUT_PURPOSE_PASSWORD
	GTK_INPUT_PURPOSE_PIN
]

#enum GtkInputHints! [
	GTK_INPUT_HINT_NONE
	GTK_INPUT_HINT_SPELLCHECK
	GTK_INPUT_HINT_NO_SPELLCHECK
	GTK_INPUT_HINT_WORD_COMPLETION
	GTK_INPUT_HINT_LOWERCASE
	GTK_INPUT_HINT_UPPERCASE_CHARS
	GTK_INPUT_HINT_UPPERCASE_WORDS
	GTK_INPUT_HINT_UPPERCASE_SENTENCES
	GTK_INPUT_HINT_INHIBIT_OSK
	GTK_INPUT_HINT_VERTICAL_WRITING
	GTK_INPUT_HINT_EMOJI
	GTK_INPUT_HINT_NO_EMOJI
]

PangoAttribute!: alias struct! [
	klass		[handle!]
	start		[integer!]
	end 		[integer!]
]

#enum PangoWrapMode! [
	PANGO_WRAP_WORD
	PANGO_WRAP_CHAR
	PANGO_WRAP_WORD_CHAR
]

#enum PangoEllipsizeMode! [
	PANGO_ELLIPSIZE_NONE
	PANGO_ELLIPSIZE_START
	PANGO_ELLIPSIZE_MIDDLE
	PANGO_ELLIPSIZE_END
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

#enum pango-underline! [
	PANGO_UNDERLINE_NONE
	PANGO_UNDERLINE_SINGLE
	PANGO_UNDERLINE_DOUBLE
	PANGO_UNDERLINE_LOW
	PANGO_UNDERLINE_ERROR
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

#enum PangoAlignment! [
	PANGO_ALIGN_LEFT
	PANGO_ALIGN_CENTER
	PANGO_ALIGN_RIGHT
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

#enum cairo_antialias_t! [
	CAIRO_ANTIALIAS_DEFAULT
	CAIRO_ANTIALIAS_NONE
	CAIRO_ANTIALIAS_GRAY
	CAIRO_ANTIALIAS_SUBPIXEL
	CAIRO_ANTIALIAS_FAST
	CAIRO_ANTIALIAS_GOOD
	CAIRO_ANTIALIAS_BEST
]

#enum cairo_pattern_type_t! [
	CAIRO_PATTERN_TYPE_SOLID
	CAIRO_PATTERN_TYPE_SURFACE
	CAIRO_PATTERN_TYPE_LINEAR
	CAIRO_PATTERN_TYPE_RADIAL
	CAIRO_PATTERN_TYPE_MESH
	CAIRO_PATTERN_TYPE_RASTER_SOURCE
]

cairo_matrix_t!: alias struct! [
	xx		[float!]
	yx		[float!]
	xy		[float!]
	yy		[float!]
	x0		[float!]
	y0		[float!]
]

#enum cairo_extend_t! [
	CAIRO_EXTEND_NONE
	CAIRO_EXTEND_REPEAT
	CAIRO_EXTEND_REFLECT
	CAIRO_EXTEND_PAD
]

; @@ cairo structures to remove if pango_cairo is enough to draw text on cairo
; cairo_text_extents_t!: alias struct! [
;  	x_bearing	[float!]
;  	y_bearing	[float!]
;  	width			[float!]
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

#enum cairo_format_t! [
	CAIRO_FORMAT_INVALID: -1
	CAIRO_FORMAT_ARGB32: 0
	CAIRO_FORMAT_RGB24
	CAIRO_FORMAT_A8
	CAIRO_FORMAT_A1
	CAIRO_FORMAT_RGB16_565
	CAIRO_FORMAT_RGB30
]

GString!: alias struct! [
	str 			[c-string!]
	len				[integer!]
	allocated_len 	[integer!]
]

GList!: alias struct! [
	data 		[int-ptr!]
	next 		[GList!]
	prev 		[GList!]
]

GPtrArray!: alias struct! [
	pdata		[int-ptr!]
	len			[integer!]
]

#enum GtkPackDirection! [
	GTK_PACK_DIRECTION_LTR
	GTK_PACK_DIRECTION_RTL
	GTK_PACK_DIRECTION_TTB
	GTK_PACK_DIRECTION_BTT
]

#enum GtkOrientation! [
	GTK_ORIENTATION_HORIZONTAL
	GTK_ORIENTATION_VERTICAL
]

#enum GConnectFlags! [
	G_CONNECT_AFTER
	G_CONNECT_SWAPPED
]

#define GTK_STYLE_PROVIDER_PRIORITY_FALLBACK		1
#define GTK_STYLE_PROVIDER_PRIORITY_THEME			200
#define GTK_STYLE_PROVIDER_PRIORITY_SETTINGS		400
#define GTK_STYLE_PROVIDER_PRIORITY_APPLICATION		600
#define GTK_STYLE_PROVIDER_PRIORITY_USER			800

#define GDK_KEY_KP_Space							FF80h
#define GDK_KEY_KP_Divide							FFAFh

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
		g_object_new: "g_object_new" [
			[variadic]
			return:		[handle!]
		]
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
		g_clear_object: "g_clear_object" [
			obj-ptr 		[integer!]
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
		g_signal_handlers_disconnect_matched: "g_signal_handlers_disconnect_matched" [
			instance	[int-ptr!]
			mask		[integer!]
			signal_id	[integer!]
			detail		[integer!]
			closure		[int-ptr!]
			handler		[int-ptr!]
			data		[int-ptr!]
			return:		[integer!]
		]
		g_signal_emit_by_name: "g_signal_emit_by_name" [
			[variadic]
		]
		g_signal_handler_block: "g_signal_handler_block" [
			object  [handle!]
			handler [integer!]
		]
		g_signal_handler_unblock: "g_signal_handler_unblock" [
			object  [handle!]
			handler [integer!]
		]
		g_signal_handlers_block_matched: "g_signal_handlers_block_matched" [
			object		[handle!]
			mask		[integer!]
			sig_id		[integer!]
			detail		[integer!]
			closure		[int-ptr!]
			handle		[integer!]
			data		[int-ptr!]
			return:		[integer!]
		]
		g_signal_handlers_unblock_matched: "g_signal_handlers_unblock_matched" [
			object		[handle!]
			mask		[integer!]
			sig_id		[integer!]
			detail		[integer!]
			closure		[int-ptr!]
			handle		[integer!]
			data		[int-ptr!]
			return:		[integer!]
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
			return:		[integer!]
		]
		g_timer_new: "g_timer_new" [
			return:		[handle!]
		]
		g_timer_start: "g_timer_start" [
			timer		[handle!]
		]
		g_timer_stop: "g_timer_stop" [
			timer		[handle!]
		]
		g_timer_continue: "g_timer_continue" [
			timer		[handle!]
		]
		g_timer_elapsed: "g_timer_elapsed" [
			timer		[handle!]
			ms			[int-ptr!]
			return:		[float!]
		]
		g_timer_destroy: "g_timer_destroy" [
			timer		[handle!]
		]
		g_idle_add: "g_idle_add" [
			handler		[integer!]
			data		[int-ptr!]
			return:		[integer!]
		]
		g_markup_escape_text: "g_markup_escape_text" [
			text		[c-string!]
			len			[integer!]
			return:		[c-string!]
		]
		g_type_check_instance_is_a: "g_type_check_instance_is_a" [
			handle		[handle!]
			gtype		[integer!]
			return:		[logic!]
		]
		g_application_run: "g_application_run" [
			app			[handle!]
			argc		[integer!]
			argv		[int-ptr!]
			return:		[integer!]
		]
		g_value_init: "g_value_init" [
			value		[handle!]
			type		[integer!]
			return:		[handle!]
		]
		g_value_get_int: "g_value_get_int" [
			value		[handle!]
			return:		[integer!]
		]
		g_memory_input_stream_new_from_data: "g_memory_input_stream_new_from_data" [
			data		[byte-ptr!]
			len			[integer!]
			destroy		[int-ptr!]
			return:		[handle!]
		]
	;; ]
	;; LIBGDK-file cdecl [
		gdk_flush: "gdk_flush" []
		gdk_window_process_all_updates: "gdk_window_process_all_updates" []
		gdk_screen_width: "gdk_screen_width" [
			return:		[integer!]
		]
		gdk_screen_height: "gdk_screen_height" [
			return:		[integer!]
		]
		gdk_screen_get_default: "gdk_screen_get_default" [
			return:		[handle!]
		]
		gdk_screen_get_root_window: "gdk_screen_get_root_window" [
			screen		[handle!]
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
		gdk_keyval_to_lower: "gdk_keyval_to_lower" [
			code		[integer!]
			return:		[integer!]
		]
		gdk_keyval_is_upper: "gdk_keyval_is_upper" [
			code		[integer!]
			return:		[logic!]
		]
		gdk_keyval_is_lower: "gdk_keyval_is_lower" [
			code		[integer!]
			return:		[logic!]
		]
		gdk_keyval_to_unicode: "gdk_keyval_to_unicode" [
			code		[integer!]
			return:		[integer!]
		]
		gdk_atom_intern_static_string: "gdk_atom_intern_static_string" [
			name 		[c-string!]
			return:		[handle!]
		]
		gdk_display_get_default: "gdk_display_get_default" [
			return: 	[handle!]
		]
		gdk_display_get_default_screen: "gdk_display_get_default_screen" [
			display 	[handle!]
			return: 	[handle!]
		]
		gdk_x11_window_get_xid: "gdk_x11_window_get_xid" [
			win			[handle!]
			return: 	[integer!]
		]
		gdk_x11_window_foreign_new_for_display: "gdk_x11_window_foreign_new_for_display" [
			display 	[handle!]
			xwin		[integer!]
			return:		[handle!]
		]
		gtk_clipboard_get: "gtk_clipboard_get" [
			atom 		[handle!]
			return: 	[handle!]
		]
		gtk_clipboard_set_text: "gtk_clipboard_set_text" [
			clipboard 	[handle!]
			text 		[c-string!]
			len 		[integer!]
		]
		gtk_clipboard_set_image: "gtk_clipboard_set_image" [
			clipboard 	[handle!]
			img 		[handle!]
		]
		gtk_clipboard_wait_for_text: "gtk_clipboard_wait_for_text" [
			clipboard 	[handle!]
			return: 	[c-string!]
		]
		gtk_clipboard_wait_for_image: "gtk_clipboard_wait_for_image" [
			clipboard 	[handle!]
			return: 	[handle!]
		]
		gtk_clipboard_request_text: "gtk_clipboard_request_text" [
			clipboard 	[handle!]
			handler 	[integer!]
			data		[handle!]
		]
		gtk_clipboard_request_image: "gtk_clipboard_request_image" [
			clipboard 	[handle!]
			handler 	[integer!]
			data		[handle!]
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
		g_main_context_pending: "g_main_context_pending" [
			context		[integer!]
			return:		[logic!]
		]
		g_main_context_is_owner: "g_main_context_is_owner" [
			context		[integer!]
			return:		[logic!]
		]
		g_main_current_source: "g_main_current_source" [
			return:		[handle!]
		]
		g_list_length: "g_list_length" [
			list		[GList!]
			return:		[integer!]
		]
		g_list_free: "g_list_free" [
			list		[GList!]
		]
		g_list_nth_data: "g_list_nth_data" [
			list		[GList!]
			nth 		[integer!]
			return:		[handle!]
		]
		g_list_append: "g_list_append" [
			list		[GList!]
			data		[handle!]
			return:		[GList!]
		]
		g_list_prepend: "g_list_prepend" [
			list		[GList!]
			data		[handle!]
			return:		[GList!]
		]
		g_list_first: "g_list_first" [
			list		[GList!]
			return:		[GList!]
		]
		g_list_last: "g_list_last" [
			list		[GList!]
			return:		[GList!]
		]
		g_list_delete_link: "g_list_delete_link" [
			list		[GList!]
			link		[GList!]
			return:		[GList!]
		]
		g_list_insert_sorted: "g_list_insert_sorted" [
			list		[GList!]
			data		[handle!]
			comp-func	[integer!]
			return:		[GList!]
		]
		g_list_remove: "g_list_remove" [
			list		[GList!]
			data		[handle!]
			return:		[GList!]
		]
		g_list_find: "g_list_find" [
			list		[GList!]
			data		[handle!]
			return:		[GList!]
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
		g_strdup: "g_strdup" [
			str			[c-string!]
			return:		[c-string!]
		]
		g_strndup: "g_strndup"[
			str			[c-string!]
			n			[integer!]
			return:		[c-string!]
		]
		g_strconcat: "g_strconcat" [
			[variadic]
			return:		[c-string!]
		]
		g_strcmp0: "g_strcmp0" [
			str			[c-string!]
			str2		[c-string!]
			return:		[integer!]
		]
		g_strsplit: "g_strsplit" [
			str			[c-string!]
			delim		[c-string!]
			tokens		[integer!]
			return:		[handle!]
		]
		g_strsplit_set: "g_strsplit_set" [
			str 		[c-string!]
			delim		[c-string!]
			tokens		[integer!]
			return:		[handle!]
		]
		g_free: "g_free" [
			ptr			[handle!]
		]
		g_strfreev: "g_strfreev" [
			str_array	[handle!]
		]
		g_string_new: "g_string_new" [
			return:		[GString!]
		]
		g_string_new_len: "g_string_new_len" [
			text		[c-string!]
			len 		[integer!]
			return:		[GString!]
		]
		g_string_sized_new: "g_string_sized_new" [
			dfl_size 	[integer!]
			return:		[GString!]
		]
		g_string_append: "g_string_append" [
			str			[GString!]
			text		[c-string!]
			return:		[GString!]
		]
		g_string_assign: "g_string_assign" [
			str			[GString!]
			text		[c-string!]
			return:		[GString!]
		]
		g_string_append_len: "g_string_append_len" [
			str			[GString!]
			text		[c-string!]
			len			[integer!]
			return:		[GString!]
		]
		g_string_append_printf: "g_string_append_printf" [
			[variadic]
		]
		g_string_free: "g_string_free" [
			str			[GString!]
			free		[logic!]
			return:		[c-string!]
		]
		g_string_set_size: "g_string_set_size" [
			str			[GString!]
			len			[integer!]
			return:		[GString!]
		]
		g_utf8_pointer_to_offset: "g_utf8_pointer_to_offset" [
			str			[c-string!]
			pos			[c-string!]
			return:		[integer!]
		]
		g_utf8_offset_to_pointer: "g_utf8_offset_to_pointer" [
			str			[c-string!]
			offset		[integer!]
			return:		[c-string!]
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
		gtk_disable_setlocale: "gtk_disable_setlocale" []
	;; ]
	;; LIBGTK-file cdecl [
		gtk_get_major_version: "gtk_get_major_version" [
			return:		[integer!]
		]
		gtk_get_minor_version: "gtk_get_minor_version" [
			return:		[integer!]
		]
		gtk_get_micro_version: "gtk_get_micro_version" [
			return:		[integer!]
		]
		gdk_cursor_new_from_pixbuf: "gdk_cursor_new_from_pixbuf" [
			display		[handle!]
			pixbuf		[handle!]
			x			[integer!]
			y			[integer!]
			return:		[handle!]
		]
		gdk_cursor_new_from_name: "gdk_cursor_new_from_name" [
			display		[handle!]
			name		[c-string!]
			return:		[handle!]
		]
		gtk_get_current_event_time: "gtk_get_current_event_time" [
			return:		[integer!]
		]
		gtk_get_current_event_state: "gtk_get_current_event_state" [
			state		[int-ptr!]
		]
		gtk_get_current_event: "gtk_get_current_event" [
			return:		[handle!]
		]
		gtk_get_current_event_device: "gtk_get_current_event_device" [
			return:		[handle!]
		]
		gtk_get_event_widget: "gtk_get_event_widget" [
			event		[handle!]
			return:		[handle!]
		]
		gdk_event_get: "gdk_event_get" [
			return:		[handle!]
		]
		gdk_event_peek: "gdk_event_peek" [
			return:		[handle!]
		]
		gdk_event_copy: "gdk_event_copy" [
			event		[handle!]
			return:		[handle!]
		]
		gdk_event_free: " gdk_event_free" [
			event		[handle!]
		]
		gdk_event_get_scroll_deltas: "gdk_event_get_scroll_deltas" [
			event		[handle!]
			dx			[float-ptr!]
			dy			[float-ptr!]
			return:		[integer!]
		]

		gdk_event_get_scroll_direction: "gdk_event_get_scroll_direction" [
			event		[handle!]
			direction	[int-ptr!]
		]
		gdk_window_get_position: "gdk_window_get_position" [
			window		[handle!]
			x			[int-ptr!]
			y			[int-ptr!]
		]
		gdk_window_get_display: "gdk_window_get_display" [
			window		[handle!]
			return:		[handle!]
		]
		gdk_window_get_device_position: "gdk_window_get_device_position" [
			window		[handle!]
			device		[handle!]
			x			[int-ptr!]
			y			[int-ptr!]
			mask		[handle!]
			return:		[handle!]
		]
		gdk_window_invalidate_rect: "gdk_window_invalidate_rect" [
			window		[handle!]
			rect		[tagRECT]
			invalid		[logic!]
		]
		gtk_application_new: "gtk_application_new" [
			app-id		[c-string!]
			flags		[integer!]
			return:		[handle!]
		]
		gtk_application_get_windows: "gtk_application_get_windows" [
			app			[handle!]
			return:		[GList!]
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
		g_application_quit: "g_application_quit" [
			app			[handle!]
		]
		gtk_menu_bar_new: "gtk_menu_bar_new" [
			return:		[handle!]
		]
		gtk_menu_bar_set_pack_direction: "gtk_menu_bar_set_pack_direction" [
			menubar		[handle!]
			dir			[GtkPackDirection!]
		]
		gtk_menu_bar_set_child_pack_direction: "gtk_menu_bar_set_child_pack_direction" [
			menubar		[handle!]
			dir			[GtkPackDirection!]
		]
		gtk_menu_new: "gtk_menu_new" [
			return:		[handle!]
		]
		gtk_menu_popup_at_pointer: "gtk_menu_popup_at_pointer" [
			menu		[handle!]
			event		[handle!]
		]
		gtk_menu_shell_append: "gtk_menu_shell_append" [
			menu		[handle!]
			item		[handle!]
		]
		gtk_menu_shell_prepend: "gtk_menu_shell_prepend" [
			menu		[handle!]
			item		[handle!]
		]
		gtk_menu_shell_insert: "gtk_menu_shell_insert" [
			menu		[handle!]
			item		[handle!]
			pos			[integer!]
		]
		gtk_menu_shell_select_item: "gtk_menu_shell_select_item" [
			menu		[handle!]
			item		[handle!]
		]
		gtk_menu_shell_select_first: "gtk_menu_shell_select_first" [
			menu		[handle!]
			sensitive	[logic!]
		]
		gtk_menu_shell_deselect: "gtk_menu_shell_deselect" [
			menu		[handle!]
		]
		gtk_menu_shell_activate_item: "gtk_menu_shell_activate_item" [
			menu		[handle!]
			item		[handle!]
			force		[integer!]
		]
		gtk_menu_shell_cancel: "gtk_menu_shell_cancel" [
			menu		[handle!]
		]
		gtk_menu_shell_set_take_focus: "gtk_menu_shell_set_take_focus" [
			menu		[handle!]
			focus		[integer!]
		]
		gtk_menu_shell_get_take_focus: "gtk_menu_shell_get_take_focus" [
			menu		[handle!]
			return:		[integer!]
		]
		gtk_menu_shell_get_selected_item: "gtk_menu_shell_get_selected_item" [
			menu		[handle!]
			return:		[handle!]
		]
		gtk_menu_shell_get_parent_shell: "gtk_menu_shell_get_parent_shell" [
			menu		[handle!]
			return:		[handle!]
		]
		gtk_menu_item_new: "gtk_menu_item_new" [
			return:		[handle!]
		]
		gtk_menu_item_new_with_label: "gtk_menu_item_new_with_label" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_menu_item_new_with_mnemonic: "gtk_menu_item_new_with_mnemonic" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_menu_item_get_label: "gtk_menu_item_get_label" [
			item		[handle!]
			return: 	[c-string!]
		]
		gtk_menu_item_set_label: "gtk_menu_item_set_label" [
			item		[handle!]
			label 		[c-string!]
		]
		gtk_menu_item_get_use_underline: "gtk_menu_item_get_use_underline" [
			item		[handle!]
			return: 	[logic!]
		]
		gtk_menu_item_set_use_underline: "gtk_menu_item_set_use_underline" [
			item		[handle!]
			setting 	[logic!]
		]
		gtk_menu_item_set_submenu: "gtk_menu_item_set_submenu" [
			item		[handle!]
			submenu		[handle!]
		]
		gtk_menu_item_get_submenu: "gtk_menu_item_get_submenu" [
			item		[handle!]
			return:		[handle!]
		]
		gtk_menu_item_select: "gtk_menu_item_select" [
			item		[handle!]
		]
		gtk_menu_item_deselect: "gtk_menu_item_deselect" [
			item		[handle!]
		]
		gtk_menu_item_activate: "gtk_menu_item_activate" [
			item		[handle!]
		]
		gtk_separator_menu_item_new: "gtk_separator_menu_item_new" [
			return: 	[handle!]
		]
		gtk_file_chooser_dialog_new: "gtk_file_chooser_dialog_new" [
			[variadic]
			return:		[handle!]
		]
		gtk_file_chooser_set_do_overwrite_confirmation: "gtk_file_chooser_set_do_overwrite_confirmation" [
			widget 		[handle!]
			mode		[logic!]
		]
		gtk_dialog_run: "gtk_dialog_run" [
			widget 		[handle!]
			return:		[integer!]
		]
		gtk_dialog_response: "gtk_dialog_response" [
			widget 		[handle!]
			resp  		[integer!]
		]
		gtk_file_chooser_set_current_folder: "gtk_file_chooser_set_current_folder" [
			widget		[handle!]
			file		[c-string!]
			return:		[logic!]
		]
		gtk_file_chooser_add_filter: "gtk_file_chooser_add_filter" [
			widget		[handle!]
			filter		[handle!]
		]
		gtk_file_filter_new: "gtk_file_filter_new" [
			return:		[handle!]
		]
		gtk_file_filter_add_pattern: "gtk_file_filter_add_pattern" [
			filter		[handle!]
			str			[c-string!]
		]
		gtk_file_filter_set_name: "gtk_file_filter_set_name" [
			filter		[handle!]
			str			[c-string!]
		]
		gtk_file_chooser_set_filename: "gtk_file_chooser_set_filename" [
			widget		[handle!]
			file		[c-string!]
			return:		[logic!]
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
		gtk_font_chooser_set_font_desc: "gtk_font_chooser_set_font_desc" [
			font-sel 	[handle!]
			font-desc 	[handle!]
		]
		gtk_init: "gtk_init" [
			argc		[int-ptr!]
			argv		[handle!]
		]
		gdk_init: "gdk_init" [
			argc		[int-ptr!]
			argv		[handle!]
		]
		gtk_main: "gtk_main" []
		gtk_main_quit: "gtk_main_quit" []
		gtk_main_iteration: "gtk_main_iteration" [
			return:		[logic!]
		]
		gtk_main_iteration_do: "gtk_main_iteration_do" [
			block?		[logic!]
			return:		[logic!]
		]
		gtk_events_pending: "gtk_events_pending" [
			return:		[logic!]
		]
		gtk_dialog_new: "gtk_dialog_new" [return: [handle!]]
		gtk_dialog_get_content_area: "gtk_dialog_get_content_area" [
			dialog		[handle!]
			return:		[handle!]
		]
		;gtk_window_group_add_window: "gtk_window_group_add_window" [
		;	group		[handle!]
		;	window		[handle!]
		;]
		;gtk_window_get_group: "gtk_window_get_group" [
		;	window		[handle!]
		;	return:		[handle!]
		;]
		gtk_window_new: "gtk_window_new" [
			type		[integer!]
			return:		[handle!]
		]
		gtk_window_get_type: "gtk_window_get_type" [
			return:		[integer!]
		]
		gtk_window_activate_focus: "gtk_window_activate_focus" [
			window		[handle!]
		]
		gtk_window_set_geometry_hints: "gtk_window_set_geometry_hints" [
			window		[handle!]
			widget		[handle!]
			geometry	[GdkGeometry!]
			mask		[integer!]
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
		gtk_window_set_resizable: "gtk_window_set_resizable" [
			window		[handle!]
			mode		[logic!]
		]
		gtk_window_resize: "gtk_window_resize" [
			window		[handle!]
			w			[integer!]
			h			[integer!]
		]
		gtk_window_set_decorated: "gtk_window_set_decorated" [
			window		[handle!]
			mode		[logic!]
		]
		gtk_window_set_deletable: "gtk_window_set_deletable" [
			window		[handle!]
			mode		[logic!]
		]
		gtk_window_set_type_hint: "gtk_window_set_type_hint" [
			window		[handle!]
			mode		[integer!]
		]
		gtk_window_move: "gtk_window_move" [
			window		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_window_get_position: "gtk_window_get_position" [
			window		[handle!]
			x			[int-ptr!]
			y			[int-ptr!]
		]
		gtk_window_present: "gtk_window_present" [
			window		[handle!]
		]
		gtk_window_is_active: "gtk_window_is_active" [
			window		[handle!]
			return:		[logic!]
		]
		gtk_window_get_modal: "gtk_window_get_modal" [
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
		gtk_window_propagate_key_event: "gtk_window_propagate_key_event" [
			widget		[handle!]
			event		[handle!]
		]
		gtk_window_get_focus: "gtk_window_get_focus" [
			window		[handle!]
			return:		[handle!]
		]
		gtk_window_set_focus: "gtk_window_set_focus" [
			window		[handle!]
			widget		[handle!]
		]
		gtk_window_get_default_widget: "gtk_window_get_default_widget" [
			window		[handle!]
			return:		[handle!]
		]
		gtk_window_set_default: "gtk_window_set_default" [
			window		[handle!]
			default		[handle!]
		]
		gtk_window_set_keep_above: "gtk_window_set_keep_above" [
			window		[handle!]
			setting		[logic!]
		]
		gtk_offscreen_window_new: "gtk_offscreen_window_new" [
			return:		[handle!]
		]
		gtk_offscreen_window_get_pixbuf: "gtk_offscreen_window_get_pixbuf" [
			window		[handle!]
			return:		[handle!]
		]
		gtk_propagate_event: "gtk_propagate_event" [
			widget		[handle!]
			event		[handle!]
		]
		gtk_widget_destroyed: "gtk_widget_destroyed" [
			widget		[handle!]
			pointer		[int-ptr!]
		]
		gtk_widget_get_window: "gtk_widget_get_window" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_widget_get_display: "gtk_widget_get_display" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_widget_register_window: "gtk_widget_register_window" [
			widget		[handle!]
			window		[handle!]
		]
		gtk_widget_unregister_window: "gtk_widget_unregister_window" [
			widget		[handle!]
			window		[handle!]
		]
		gtk_widget_event: "gtk_widget_event" [
			widget		[handle!]
			event		[handle!]
			return:		[logic!]
		]
		gtk_widget_draw: "gtk_widget_draw" [
			widget		[handle!]
			cr			[handle!]
		]
		gtk_widget_queue_draw: "gtk_widget_queue_draw" [
			widget		[handle!]
		]
		gtk_widget_queue_draw_area: "gtk_widget_queue_draw_area" [
			widget		[handle!]
			x			[integer!]
			y			[integer!]
			w			[integer!]
			h			[integer!]
		]
		gtk_widget_queue_resize: "gtk_widget_queue_resize" [
			widget		[handle!]
		]
		gtk_widget_queue_resize_no_redraw: "gtk_widget_queue_resize_no_redraw" [
			widget		[handle!]
		]
		gtk_widget_queue_allocate: "gtk_widget_queue_allocate" [
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
		gtk_widget_show_now: "gtk_widget_show_now" [
			widget		[handle!]
		]
		gtk_widget_realize: "gtk_widget_realize" [
			widget		[handle!]
		]
		gtk_widget_activate: "gtk_widget_activate" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_set_halign: "gtk_widget_set_halign" [
			widget		[handle!]
			type		[integer!]
		]
		gtk_widget_set_hexpand: "gtk_widget_set_hexpand" [
			widget		[handle!]
			type		[logic!]
		]
		gtk_widget_set_vexpand: "gtk_widget_set_vexpand" [
			widget		[handle!]
			type		[logic!]
		]
		gtk_widget_compute_expand: "gtk_widget_compute_expand" [
			widget		[handle!]
			orient		[GtkOrientation!]
			return: 	[logic!]
		]
		gtk_widget_set_visible: "gtk_widget_set_visible" [
			widget		[handle!]
			state 		[logic!]
		]
		gtk_widget_get_visible: "gtk_widget_get_visible" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_is_visible: "gtk_widget_is_visible" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_is_drawable: "gtk_widget_is_drawable" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_set_sensitive: "gtk_widget_set_sensitive" [
			widget		[handle!]
			state 		[logic!]
		]
		gtk_widget_get_sensitive: "gtk_widget_get_sensitive" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_is_sensitive: "gtk_widget_is_sensitive" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_is_focus: "gtk_widget_is_focus" [
			widget		[handle!]
			return: 	[logic!]
		]
		gtk_widget_grab_focus: "gtk_widget_grab_focus" [
			widget		[handle!]
		]
		gtk_widget_grab_default: "gtk_widget_grab_default" [
			widget		[handle!]
		]
		gtk_widget_has_grab: "gtk_widget_has_grab" [
			widget		[handle!]
			return:		[logic!]
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
			alloc		[GtkAllocation!]
		]
		gtk_widget_get_allocation: "gtk_widget_get_allocation" [
			widget		[handle!]
			alloc		[GtkAllocation!]
		]
		gtk_widget_get_allocated_width: "gtk_widget_get_allocated_width" [
			widget		[handle!]
			return: 	[integer!]
		]
		gtk_widget_get_allocated_height: "gtk_widget_get_allocated_height" [
			widget		[handle!]
			return: 	[integer!]
		]
		gtk_widget_get_can_focus: "gtk_widget_get_can_focus" [
			widget		[handle!]
			return:		[logic!]
		]
		gtk_widget_set_can_focus: "gtk_widget_set_can_focus" [
			widget		[handle!]
			focus		[logic!]
		]
		gtk_widget_set_can_default: "gtk_widget_set_can_default" [
			widget		[handle!]
			can_default	[logic!]
		]
		gtk_widget_set_focus_on_click: "gtk_widget_set_focus_on_click" [
			widget		[handle!]
			focus		[logic!]
		]
		gtk_widget_get_can_default: "gtk_widget_get_can_default" [
			widget		[handle!]
			return:		[logic!]
		]
		gtk_widget_get_focus_on_click: "gtk_widget_get_focus_on_click" [
			widget		[handle!]
			return:		[logic!]
		]
		gtk_widget_get_parent: "gtk_widget_get_parent" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_widget_get_toplevel: "gtk_widget_get_toplevel" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_widget_get_parent_window: "gtk_widget_get_parent_window" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_widget_destroy: "gtk_widget_destroy" [
			widget		[handle!]
		]
		gtk_widget_create_pango_layout: "gtk_widget_create_pango_layout" [
			widget		[handle!]
			text		[c-string!]
			return:		[handle!]
		]
		gtk_widget_create_pango_context: "gtk_widget_create_pango_context" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_widget_add_events: "gtk_widget_add_events" [
			widget		[handle!]
			mask		[integer!]
		]
		gtk_widget_get_events: "gtk_widget_get_events" [
			widget		[handle!]
			return:		[integer!]
		]
		gtk_widget_override_font: "gtk_widget_override_font" [
			widget		[handle!]
			fd			[handle!]
		]
		gtk_widget_override_color: "gtk_widget_override_color" [
			widget		[handle!]
			state		[integer!]
			color		[handle!]
		]
		gtk_container_add: "gtk_container_add" [
			container	[handle!]
			widget		[handle!]
		]
		gtk_container_get_children: "gtk_container_get_children" [
			container	[handle!]
			return:		[GList!]
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
		gtk_container_get_focus_child: "gtk_container_get_focus_child" [
			container	[handle!]
			return:		[handle!]
		]
		gtk_container_child_set: "gtk_container_child_set" [
			[variadic]
		]
		gtk_container_child_get_property: "gtk_container_child_get_property" [
			container	[handle!]
			widget		[handle!]
			prop		[c-string!]
			value		[int-ptr!]
		]
		gtk_calendar_new: "gtk_calendar_new" [
			return:		[handle!]
		]
		gtk_calendar_select_month: "gtk_calendar_select_month" [
			calendar	[handle!]
			month		[integer!]
			year		[integer!]
		]
		gtk_calendar_select_day: "gtk_calendar_select_day" [
			calendar	[handle!]
			day			[integer!]
		]
		gtk_calendar_mark_day: "gtk_calendar_mark_day" [
			calendar	[handle!]
			day			[integer!]
		]
		gtk_calendar_unmark_day: "gtk_calendar_unmark_day" [
			calendar	[handle!]
			day			[integer!]
		]
		gtk_calendar_get_day_is_marked: "gtk_calendar_get_day_is_marked" [
			calendar	[handle!]
			day			[integer!]
			return:		[logic!]
		]
		gtk_calendar_clear_marks: "gtk_calendar_clear_marks" [
			calendar	[handle!]
		]
		gtk_calendar_get_display_options: "gtk_calendar_get_display_options" [
			calendar	[handle!]
			return:		[integer!]
		]
		gtk_calendar_set_display_options: "gtk_calendar_set_display_options" [
			calendar	[handle!]
			flags		[integer!]
		]
		gtk_calendar_get_date: "gtk_calendar_get_date" [
			calendar	[handle!]
			year		[int-ptr!]
			month		[int-ptr!]
			day			[int-ptr!]
		]
		gtk_frame_new: "gtk_frame_new" [
			label		[c-string!]
			return:		[handle!]
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
		gtk_frame_get_label_widget: "gtk_frame_get_label_widget" [
			frame		[handle!]
			return:		[handle!]
		]
		gtk_box_new: "gtk_box_new" [
			orient		[GtkOrientation!]
			spacing		[integer!]
			return:		[handle!]
		]
		gtk_box_pack_start: "gtk_box_pack_start" [
			box			[handle!]
			widget		[handle!]
			expand		[logic!]
			fill		[logic!]
			padding		[integer!]
		]
		gtk_fixed_new: "gtk_fixed_new" [
			return:		[handle!]
		]
		gtk_fixed_put: "gtk_fixed_put" [
			fixed		[handle!]
			widget		[handle!]
			x				[integer!]
			y				[integer!]
		]
		gtk_fixed_move: "gtk_fixed_move" [
			fixed		[handle!]
			widget		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_layout_get_type: "gtk_layout_get_type" [
			return:		[integer!]
		]
		gtk_layout_new: "gtk_layout_new" [
			hadj		[handle!]
			vadj		[handle!]
			return:		[handle!]
		]
		gtk_scrolled_window_set_vadjustment: "gtk_scrolled_window_set_vadjustment" [
			win			[handle!]
			adj			[handle!]
		]
		gtk_layout_put: "gtk_layout_put" [
			layout		[handle!]
			widget		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_layout_move: "gtk_layout_move" [
			layout		[handle!]
			widget		[handle!]
			x			[integer!]
			y			[integer!]
		]
		gtk_layout_set_size: "gtk_layout_set_size" [
			layout		[handle!]
			w			[integer!]
			h			[integer!]
		]
		gtk_layout_get_size: "gtk_layout_get_size" [
			layout		[handle!]
			w			[int-ptr!]
			h			[int-ptr!]
		]
		gtk_layout_get_bin_window: "gtk_layout_get_bin_window" [
			layout		[handle!]
			return:		[handle!]
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
		gtk_list_box_unselect_all: "gtk_list_box_unselect_all" [
			listbox		[handle!]
		]
		gtk_list_box_set_selection_mode: "gtk_list_box_set_selection_mode" [
			listbox		[handle!]
			mode		[integer!]
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
		gtk_button_get_label: "gtk_button_get_label" [
			button		[handle!]
			return:		[c-string!]
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
		gtk_toggle_button_new_with_label: "gtk_toggle_button_new_with_label" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_toggle_button_get_active: "gtk_toggle_button_get_active" [
			button		[handle!]
			return:		[logic!]
		]
		gtk_toggle_button_set_active: "gtk_toggle_button_set_active" [
			button		[handle!]
			active?		[logic!]
		]
		gtk_toggle_button_get_inconsistent: "gtk_toggle_button_get_inconsistent" [
			button		[handle!]
			return:		[logic!]
		]
		gtk_toggle_button_set_inconsistent: "gtk_toggle_button_set_inconsistent" [
			button		[handle!]
			setting		[logic!]
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
		gtk_image_new: "gtk_image_new" [
			return: 	[handle!]
		]
		gtk_image_new_from_pixbuf: "gtk_image_new_from_pixbuf" [
			pixbuf 		[handle!]
			return: 	[handle!]
		]
		gtk_image_new_from_file: "gtk_image_new_from_file" [
			filename 	[c-string!]
			return: 	[handle!]
		]
		gtk_image_set_from_pixbuf: "gtk_image_set_from_pixbuf" [
			widget 		[handle!]
			pixbuf 		[handle!]
		]
		gtk_label_new: "gtk_label_new" [
			label		[c-string!]
			return:		[handle!]
		]
		gtk_label_get_type: "gtk_label_get_type" [
			return:		[integer!]
		]
		gtk_label_get_text: "gtk_label_get_text" [
			widget		[handle!]
			return:		[c-string!]
		]
		gtk_label_set_text: "gtk_label_set_text" [
			widget		[handle!]
			label		[c-string!]
		]
		gtk_label_set_markup: "gtk_label_set_markup" [
			widget		[handle!]
			label		[c-string!]
		]
		gtk_label_set_xalign: "gtk_label_set_xalign" [
			widget		[handle!]
			xalign		[float32!]
		]
		gtk_label_set_yalign: "gtk_label_set_yalign" [
			widget		[handle!]
			yalign		[float32!]
		]
		gtk_label_set_justify: "gtk_label_set_justify" [
			widget		[handle!]
			justify		[integer!]
		]
		gtk_label_set_line_wrap: "gtk_label_set_line_wrap" [
			widget		[handle!]
			wrap		[logic!]
		]
		gtk_label_set_angle: "gtk_label_set_angle" [
			widget		[handle!]
			angle		[float!]
		]
		gtk_label_set_use_underline: "gtk_label_set_use_underline" [
			widget		[handle!]
			setting		[logic!]
		]
		gtk_label_set_attributes: "gtk_label_set_attributes" [
			widget		[handle!]
			list		[handle!]
		]
		gtk_label_get_attributes: "gtk_label_get_attributes" [
			widget		[handle!]
			return:		[handle!]
		]
		gtk_label_set_max_width_chars: "gtk_label_set_max_width_chars" [
			widget		[handle!]
			nchars		[integer!]
		]
		;gtk_label_set_width_chars: "gtk_label_set_width_chars" [
		;	widget		[handle!]
		;	nchars		[integer!]
		;]
		gtk_label_get_layout: "gtk_label_get_layout" [
			label		[handle!]
			return:		[handle!]
		]
		gtk_event_box_new: "gtk_event_box_new" [
			return: 	[handle!]
		]
		gtk_event_box_set_above_child: "gtk_event_box_set_above_child" [
			evbox		[handle!]
			settings	[logic!]
		]
		gtk_entry_new: "gtk_entry_new" [
			return:		[handle!]
		]
		gtk_entry_set_width_chars: "gtk_entry_set_width_chars" [
			entry		[handle!]
			nchars		[integer!]
		]
		gtk_entry_set_max_width_chars: "gtk_entry_set_max_width_chars" [
			entry		[handle!]
			nchars		[integer!]
		]
		gtk_entry_get_buffer: "gtk_entry_get_buffer" [
			entry		[handle!]
			return:		[handle!]
		]
		gtk_entry_get_layout: "gtk_entry_get_layout" [
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
		gtk_entry_set_placeholder_text: "gtk_entry_set_placeholder_text" [
			buffer		[handle!]
			text		[c-string!]
		]
		gtk_entry_set_visibility: "gtk_entry_set_visibility" [
			entry		[handle!]
			visible		[logic!]
		]
		gtk_entry_buffer_set_text: "gtk_entry_buffer_set_text" [
			buffer		[handle!]
			text		[c-string!]
			len			[integer!]
		]
		gtk_entry_set_has_frame: "gtk_entry_set_has_frame" [
			entry		[handle!]
			has-frame	[logic!]
		]
		gtk_entry_set_attributes: "gtk_entry_set_attributes" [
			entry		[handle!]
			list		[handle!]
		]
		gtk_entry_set_alignment: "gtk_entry_set_alignment" [
			entry		[handle!]
			xalign		[float32!]
		]
		gtk_editable_select_region: "gtk_editable_select_region" [
			entry		[handle!]
			start		[integer!]
			end			[integer!]
		]
		gtk_editable_get_selection_bounds: "gtk_editable_get_selection_bounds" [
			entry		[handle!]
			start		[int-ptr!]
			end			[int-ptr!]
			return: [logic!]
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
		gtk_range_set_inverted: "gtk_range_set_inverted" [
			range		[handle!]
			bool		[logic!]
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
		gtk_text_view_set_justification: "gtk_text_view_set_justification" [
			view			[handle!]
			justify		[integer!]
		]
		gtk_text_view_set_wrap_mode: "gtk_text_view_set_wrap_mode" [
			view			[handle!]
			mode			[integer!]
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
		gtk_text_buffer_get_selection_bounds: "gtk_text_buffer_get_selection_bounds" [
			buffer		[handle!]
			start		[handle!]
			end			[handle!]
			return:		[logic!]
		]
		gtk_text_buffer_select_range: "gtk_text_buffer_select_range" [
			buffer		[handle!]
			ins			[handle!]
			bound		[handle!]
		]
		gtk_text_buffer_create_tag: "gtk_text_buffer_create_tag" [
			[variadic]
			return: 	[handle!]
		]
		gtk_text_iter_get_offset: "gtk_text_iter_get_offset" [
			iter		[handle!]
			return:		[integer!]
		]
		gtk_text_iter_set_offset: "gtk_text_iter_set_offset" [
			iter		[handle!]
			offset		[integer!]
		]
		gtk_text_iter_get_line: "gtk_text_iter_get_line" [
			iter		[handle!]
			return:		[integer!]
		]
		gtk_text_buffer_get_start_iter: "gtk_text_buffer_get_start_iter" [
			buffer		[handle!]
			iter		[handle!]
		]
		gtk_text_buffer_get_end_iter: "gtk_text_buffer_get_end_iter" [
			buffer		[handle!]
			iter		[handle!]
		]
		gtk_text_buffer_apply_tag: "gtk_text_buffer_apply_tag" [
			buffer		[handle!]
			tag			[handle!]
			start		[handle!]
			end			[handle!]
		]
		gtk_text_buffer_apply_tag_by_name: "gtk_text_buffer_apply_tag_by_name" [
			buffer		[handle!]
			name		[c-string!]
			start		[handle!]
			end			[handle!]
		]
		gtk_text_tag_table_lookup: "gtk_text_tag_table_lookup" [
			buffer		[handle!]
			name		[c-string!]
			return:		[handle!]
		]
		gtk_text_tag_table_remove: "gtk_text_tag_table_remove" [
			table		[handle!]
			tag			[handle!]
		]
		gtk_text_buffer_get_tag_table: "gtk_text_buffer_get_tag_table" [
			buffer		[handle!]
			return:		[handle!]
		]
		gtk_text_buffer_remove_all_tags: "gtk_text_buffer_remove_all_tags" [
			buffer		[handle!]
			start		[handle!]
			end			[handle!]
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
		gtk_combo_box_set_popup_fixed_width: "gtk_combo_box_set_popup_fixed_width" [
			combo		[handle!]
			fixed		[logic!]
		]
		gtk_notebook_new: "gtk_notebook_new" [
			return:		[handle!]
		]
		gtk_notebook_append_page: "gtk_notebook_append_page" [
			nb			[handle!]
			pane		[handle!]
			label		[handle!]
			return:		[integer!]
		]
		gtk_notebook_get_current_page: "gtk_notebook_get_current_page" [
			nb			[handle!]
			return:		[integer!]
		]

		gtk_notebook_set_current_page: "gtk_notebook_set_current_page" [
			nb			[handle!]
			index 		[integer!]
		]

		gtk_notebook_get_nth_page: "gtk_notebook_get_nth_page" [
			nb			[handle!]
			index		[integer!]
			return:		[handle!]
		]
		gtk_notebook_get_tab_label_text: "gtk_notebook_get_tab_label_text" [
			nb			[handle!]
			page		[handle!]
			return:		[c-string!]
		]
		gtk_notebook_get_n_pages: "gtk_notebook_get_n_pages" [
			nb			[handle!]
			return:		[integer!]
		]
		gtk_notebook_remove_page: "gtk_notebook_remove_page" [
			nb			[handle!]
			index		[integer!]
			return:		[integer!]
		]
		gtk_notebook_insert_page: "gtk_notebook_insert_page" [
			nb			[handle!]
			pane		[handle!]
			label		[handle!]
			index		[integer!]
			return:		[integer!]
		]
		gtk_css_provider_new: "gtk_css_provider_new" [
			return:		[handle!]
		]
		gtk_css_provider_load_from_data: "gtk_css_provider_load_from_data" [
			provider	[handle!]
			data		[c-string!]
			length		[integer!]
			error		[handle!]
			return:		[logic!]
		]
		gtk_css_provider_load_from_file: "gtk_css_provider_load_from_file" [
			provider	[handle!]
			url			[c-string!]
			error		[handle!]
		]
		gtk_css_provider_load_from_path: "gtk_css_provider_load_from_path" [
			provider	[handle!]
			path		[c-string!]
			error		[handle!]
			return:		[logic!]
		]
		gtk_css_provider_to_string: "gtk_css_provider_to_string" [
			provider	[handle!]
			return:		[c-string!]
		]
		gtk_style_context_add_provider: "gtk_style_context_add_provider" [
			context		[handle!]
			provider	[handle!]
			priority	[integer!]
		]
		gtk_style_context_remove_provider: "gtk_style_context_remove_provider" [
			context		[handle!]
			provider	[handle!]
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
		gtk_render_background: "gtk_render_background" [
			style			[handle!]
			cr				[handle!]
			x 				[float!]
			y 				[float!]
			w 				[float!]
			h 				[float!]
		]
		pango_layout_new: "pango_layout_new" [
			context		[handle!]
			return:		[handle!]
		]
		pango_layout_copy: "pango_layout_copy" [
			context		[handle!]
			return: 	[handle!]
		]
		pango_layout_get_context: "pango_layout_get_context" [
			layout		[handle!]
			return: 	[handle!]
		]
		pango_layout_get_attributes: "pango_layout_get_attributes" [
			layout		[handle!]
			return: 	[handle!]
		]
		pango_layout_get_text: "pango_layout_get_text" [
			layout		[handle!]
			return:		[c-string!]
		]
		pango_layout_set_text: "pango_layout_set_text" [
			layout		[handle!]
			text		[c-string!]
			len			[integer!]
		]
		pango_layout_set_markup: "pango_layout_set_markup" [
			layout	[handle!]
			markup	[c-string!]
			len			[integer!]
		]
		pango_layout_set_markup_with_accel: "pango_layout_set_markup_with_accel" [
			layout			[handle!]
			markup			[c-string!]
			len					[integer!]
			accel_mark	[integer!]
			accel_char	[int-ptr!]
		]
		pango_layout_get_font_description: "pango_layout_get_font_description" [
			layout		[handle!]
			return:		[handle!]
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
		pango_layout_get_line: "pango_layout_get_line" [
			layout		[handle!]
			line		[integer!]
			return:		[handle!]
		]
		pango_layout_get_line_readonly: "pango_layout_get_line_readonly" [
			layout		[handle!]
			line		[integer!]
			return:		[handle!]
		]
		pango_layout_get_character_count: "pango_layout_get_character_count" [
			layout		[handle!]
			return:		[integer!]
		]
		pango_layout_is_wrapped: "pango_layout_is_wrapped" [
			layout		[handle!]
			return:		[logic!]
		]
		pango_layout_set_wrap: "pango_layout_set_wrap" [
			layout		[handle!]
			mode			[PangoWrapMode!]
		]
		pango_layout_get_wrap: "pango_layout_get_wrap" [
			layout		[handle!]
			return:		[PangoWrapMode!]
		]
		pango_layout_is_ellipsized: "pango_layout_is_ellipsized" [
			layout		[handle!]
			return:		[logic!]
		]
		pango_layout_set_ellipsize: "pango_layout_set_ellipsize" [
			layout		[handle!]
			mode			[PangoEllipsizeMode!]
		]
		pango_layout_get_ellipsize: "pango_layout_get_ellipsize" [
			layout		[handle!]
			return:		[PangoEllipsizeMode!]
		]
		pango_layout_get_indent: "pango_layout_get_indent" [
			layout		[handle!]
			return:		[integer!]
		]
		pango_layout_set_indent: "pango_layout_set_indent" [
			layout		[handle!]
			indent		[integer!]
		]
		pango_layout_get_spacing: "pango_layout_get_spacing" [
			layout		[handle!]
			return:		[integer!]
		]
		pango_layout_set_spacing: "pango_layout_set_spacing" [
			layout		[handle!]
			spacing		[integer!]
		]
		pango_layout_get_justify: "pango_layout_get_justify" [
			layout		[handle!]
			return:		[logic!]
		]
		pango_layout_set_justify: "pango_layout_set_justify" [
			layout		[handle!]
			justify		[logic!]
		]
		pango_layout_set_alignment: "pango_layout_set_alignment" [
			layout		[handle!]
			align			[PangoAlignment!]
		]
		pango_layout_get_alignment: "pango_layout_get_alignment" [
			layout		[handle!]
			return:		[PangoAlignment!]
		]
		pango_layout_set_width: "pango_layout_set_width" [
			layout		[handle!]
			width			[integer!]
		]
		pango_layout_get_width: "pango_layout_get_width" [
			layout		[handle!]
			return:		[integer!]
		]
		pango_layout_set_height: "pango_layout_set_height" [
			layout		[handle!]
			height			[integer!]
		]
		pango_layout_get_height: "pango_layout_get_height" [
			layout		[handle!]
			return:		[integer!]
		]
		pango_layout_get_size: "pango_layout_get_size" [
			 layout		[handle!]
			 width		[int-ptr!]
			 height		[int-ptr!]
		]
		pango_layout_set_attributes: "pango_layout_set_attributes" [
			layout		[handle!]
			attrs		[handle!]
		]
		pango_layout_get_iter: "pango_layout_get_iter" [
			layout		[handle!]
			return: 	[handle!]
		]
		pango_layout_iter_get_baseline: "pango_layout_iter_get_baseline" [
			iter			[handle!]
			return:		[integer!]
		]
		pango_layout_get_extents: "pango_layout_get_extents" [
			layout		[handle!]
			irect			[tagRECT]
			lrect			[tagRECT]
		]
		pango_layout_get_pixel_extents: "pango_layout_get_pixel_extents" [
			layout		[handle!]
			irect			[tagRECT]
			lrect			[tagRECT]
		]
		pango_layout_index_to_pos: "pango_layout_index_to_pos" [
			layout		[handle!]
			index			[integer!]
			pos				[tagRECT]
		]
		pango_layout_index_to_line_x: "pango_layout_index_to_line_x" [
			layout		[handle!]
			index			[integer!]
			trailing	[integer!]
			line			[int-ptr!]
			x-pos			[int-ptr!]
		]
		pango_layout_xy_to_index: "pango_layout_xy_to_index" [
			layout		[handle!]
			x					[integer!]
			y					[integer!]
			index			[int-ptr!]
			trailing	[int-ptr!]
			return:		[logic!]
		]
		pango_layout_get_cursor_pos: "pango_layout_get_cursor_pos" [
			layout		[handle!]
			index			[integer!]
			spos			[tagRECT]
			wpos			[tagRECT]
		]
		pango_layout_move_cursor_visually: "pango_layout_move_cursor_visually" [
			layout		[handle!]
			strong		[logic!]
			old_ind		[integer!]
			old_trail	[integer!]
			direct		[integer!]
			new_ind		[int-ptr!]
			new_trail	[int-ptr!]
		]
		pango_layout_get_line_count: "pango_layout_get_line_count" [
			layout		[handle!]
			return:		[integer!]
		]
		pango_layout_line_get_pixel_extents: "pango_layout_line_get_pixel_extents" [
			line			[handle!]
			irect			[tagRECT]
			lrect			[tagRECT]
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

		gdk_pango_context_get_for_screen: "gdk_pango_context_get_for_screen" [
			screen		[handle!]
			return:		[handle!]
		]

		gtk_widget_get_pango_context: "gtk_widget_get_pango_context" [
			widget		[handle!]
			return:		[handle!]
		]

		gtk_settings_get_default: "gtk_settings_get_default" [
			return: 	[handle!]
		]
		gtk_scrolled_window_set_max_content_height: "gtk_scrolled_window_set_max_content_height" [
			scrolled	[handle!]
			height		[integer!]
		]
		gtk_scrolled_window_get_policy: "gtk_scrolled_window_get_policy" [
			win			[handle!]
			hs			[int-ptr!]
			vs			[int-ptr!]
		]
		gtk_adjustment_configure: "gtk_adjustment_configure" [
			adjustment	[handle!]
			value		[float!]
			lower		[float!]
			uppper		[float!]
			step		[float!]
			page		[float!]
			page-size	[float!]
		]
		gtk_scrollable_get_vadjustment: "gtk_scrollable_get_vadjustment" [
			scrollable	[handle!]
			return:		[handle!]
		]
		gtk_scrollable_get_hadjustment: "gtk_scrollable_get_hadjustment" [
			scrollable	[handle!]
			return:		[handle!]
		]
		gtk_scrollbar_new: "gtk_scrollbar_new" [
			orientation	[integer!]
			adjust		[handle!]
			return:		[handle!]
		]
		gtk_range_get_adjustment: "gtk_range_get_adjustment" [
			range		[handle!]
			return:		[handle!]
		]
		gtk_adjustment_new: "gtk_adjustment_new" [
			value		[float!]
			lower		[float!]
			uppper		[float!]
			step		[float!]
			page		[float!]
			page-size	[float!]
			return:		[handle!]
		]
		gtk_adjustment_set_upper: "gtk_adjustment_set_upper" [
			adjustment	[handle!]
			upper		[float!]
		]
		gtk_adjustment_set_value: "gtk_adjustment_set_value" [
			adjustment	[handle!]
			value		[float!]
		]
		gtk_adjustment_set_page_size: "gtk_adjustment_set_page_size" [
			adjustment	[handle!]
			value		[float!]
		]
		gtk_adjustment_get_value: "gtk_adjustment_get_value" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_adjustment_get_lower: "gtk_adjustment_get_lower" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_adjustment_get_page_size: "gtk_adjustment_get_page_size" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_adjustment_get_upper: "gtk_adjustment_get_upper" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_adjustment_get_page_increment: "gtk_adjustment_get_page_increment" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_adjustment_get_step_increment: "gtk_adjustment_get_step_increment" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_adjustment_get_minimum_increment: "gtk_adjustment_get_minimum_increment" [
			adjustment	[handle!]
			return:		[float!]
		]
		gtk_scrolled_window_set_policy: "gtk_scrolled_window_set_policy" [
			scrolled	[handle!]
			hpolicy		[integer!]
			vpolicy		[integer!]
		]
		gtk_im_context_set_client_window: "gtk_im_context_set_client_window" [
			ctx			[handle!]
			win			[handle!]
		]
		gtk_im_context_get_preedit_string: "gtk_im_context_get_preedit_string" [
			ctx			[handle!]
			str			[int-ptr!]
			attrs		[int-ptr!]
			pos			[int-ptr!]
		]
		gtk_im_context_filter_keypress: "gtk_im_context_filter_keypress" [
			ctx			[handle!]
			event		[GdkEventKey!]
			return:		[logic!]
		]
		gtk_im_context_focus_in: "gtk_im_context_focus_in" [
			ctx			[handle!]
		]
		gtk_im_context_focus_out: "gtk_im_context_focus_out" [
			ctx			[handle!]
		]
		gtk_im_context_reset: "gtk_im_context_reset" [
			ctx			[handle!]
		]
		gtk_im_context_set_cursor_location: "gtk_im_context_set_cursor_location" [
			ctx			[handle!]
			area		[GdkRectangle!]
		]
		gtk_im_context_set_use_preedit: "gtk_im_context_set_use_preedit" [
			ctx			[handle!]
			preedit?	[logic!]
		]
		gtk_im_context_set_surrounding: "gtk_im_context_set_surrounding" [
			ctx			[handle!]
			text		[c-string!]
			len			[integer!]
			index		[integer!]
		]
		gtk_im_context_get_surrounding: "gtk_im_context_get_surrounding" [
			ctx			[handle!]
			text		[int-ptr!]
			index		[int-ptr!]
			return:		[logic!]
		]
		gtk_im_context_delete_surrounding: "gtk_im_context_delete_surrounding" [
			ctx			[handle!]
			offset		[integer!]
			n_chars		[integer!]
			return:		[logic!]
		]
		gtk_im_context_simple_new: "gtk_im_context_simple_new" [
			return:		[handle!]
		]
		gtk_im_multicontext_new: "gtk_im_multicontext_new" [
			return:		[handle!]
		]
		gtk_im_multicontext_get_context_id: "gtk_im_multicontext_get_context_id" [
			ctx			[handle!]
			return:		[c-string!]
		]
		gtk_im_multicontext_set_context_id: "gtk_im_multicontext_set_context_id" [
			ctx			[handle!]
			id			[c-string!]
		]

	;; LIBCAIRO-file cdecl [
		cairo_create: "cairo_create" [
			surf		[handle!]
			return:		[handle!]
		]

		cairo_destroy: "cairo_destroy" [
			cr			[handle!]
		]
		cairo_push_group: "cairo_push_group" [
			cr			[handle!]
		]
		cairo_pop_group: "cairo_pop_group" [
			cr			[handle!]
			return:		[handle!]
		]
		cairo_clip: "cairo_clip" [
			cr			[handle!]
		]

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
		cairo_arc_negative: "cairo_arc_negative" [
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
		cairo_copy_path: "cairo_copy_path" [
			cr			[handle!]
			return:		[handle!]
		]
		cairo_append_path: "cairo_append_path" [
			cr			[handle!]
			path		[handle!]
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
		cairo_stroke_preserve: "cairo_stroke_preserve" [
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
		cairo_set_dash: "cairo_set_dash" [
			cr			[handle!]
			dashes		[float-ptr!]
			num			[integer!]
			offset		[float!]
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
		cairo_set_operator: "cairo_set_operator" [
			cr			[handle!]
			mode		[integer!]
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
		cairo_pattern_get_surface: "cairo_pattern_get_surface" [
			pattern		[handle!]
			surf		[int-ptr!]
			return:		[integer!]
		]
		cairo_pattern_get_type: "cairo_pattern_get_type" [
			pattern		[handle!]
			return:		[integer!]
		]
		cairo_pattern_set_matrix: "cairo_pattern_set_matrix" [
			pattern		[handle!]
			matrix		[cairo_matrix_t!]
		]
		cairo_pattern_get_matrix: "cairo_pattern_get_matrix" [
			pattern		[handle!]
			matrix		[cairo_matrix_t!]
		]
		cairo_pattern_set_extend: "cairo_pattern_set_extend" [
			pattern		[handle!]
			extend		[cairo_extend_t!]
		]
		cairo_pattern_get_extend: "cairo_pattern_get_extend" [
			pattern		[handle!]
			return:		[cairo_extend_t!]
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
		cairo_pattern_get_color_stop_count: "cairo_pattern_get_color_stop_count" [
			pattern		[handle!]
			cnt			[int-ptr!]
			return:		[integer!]
		]
		cairo_pattern_get_color_stop_rgba: "cairo_pattern_get_color_stop_rgba" [
			pattern		[handle!]
			index		[integer!]
			offset		[float-ptr!]
			r			[float-ptr!]
			g			[float-ptr!]
			b			[float-ptr!]
			a			[float-ptr!]
			return:		[integer!]
		]
		cairo_pattern_create_mesh: "cairo_pattern_create_mesh" [
			return:		[handle!]
		]
		cairo_pattern_destroy: "cairo_pattern_destroy" [
			pattern		[handle!]
		]
		cairo_pattern_create_for_surface: "cairo_pattern_create_for_surface" [
			surface		[handle!]
			return:		[handle!]
		]
		cairo_rotate: "cairo_rotate" [
			cr			[handle!]
			angle 		[float!]
		]
		cairo_identity_matrix: "cairo_identity_matrix" [
			cr			[handle!]
		]
		cairo_get_matrix: "cairo_get_matrix" [
			cr			[handle!]
			mat			[cairo_matrix_t!]
		]
		cairo_set_matrix: "cairo_set_matrix" [
			cr			[handle!]
			mat			[cairo_matrix_t!]
		]
		cairo_transform: "cairo_transform" [
			cr			[handle!]
			mat			[cairo_matrix_t!]
		]
		cairo_matrix_init: "cairo_matrix_init" [
			matrix		[cairo_matrix_t!]
			xx			[float!]
			yx			[float!]
			xy			[float!]
			yy			[float!]
			x0			[float!]
			y0			[float!]
		]
		cairo_matrix_init_identity: "cairo_matrix_init_identity" [
			matrix		[cairo_matrix_t!]
		]
		cairo_matrix_init_translate: "cairo_matrix_init_translate" [
			matrix		[cairo_matrix_t!]
			tx			[float!]
			ty			[float!]
		]
		cairo_matrix_init_scale: "cairo_matrix_init_scale" [
			matrix		[cairo_matrix_t!]
			sx			[float!]
			sy			[float!]
		]
		cairo_matrix_init_rotate: "cairo_matrix_init_rotate" [
			matrix		[cairo_matrix_t!]
			rad			[float!]
		]
		cairo_matrix_translate: "cairo_matrix_translate" [
			matrix		[cairo_matrix_t!]
			tx			[float!]
			ty			[float!]
		]
		cairo_matrix_scale: "cairo_matrix_scale" [
			matrix		[cairo_matrix_t!]
			sx			[float!]
			sy			[float!]
		]
		cairo_matrix_rotate: "cairo_matrix_rotate" [
			matrix		[cairo_matrix_t!]
			rad			[float!]
		]
		cairo_matrix_invert: "cairo_matrix_invert" [
			matrix		[cairo_matrix_t!]
			return:		[integer!]
		]
		cairo_matrix_multiply: "cairo_matrix_multiply" [
			res			[cairo_matrix_t!]
			a			[cairo_matrix_t!]
			b			[cairo_matrix_t!]
		]
		cairo_matrix_transform_distance: "cairo_matrix_transform_distance" [
			matrix		[cairo_matrix_t!]
			dx			[float-ptr!]
			dy			[float-ptr!]
		]
		cairo_matrix_transform_point: "cairo_matrix_transform_point" [
			matrix		[cairo_matrix_t!]
			dx			[float-ptr!]
			dy			[float-ptr!]
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
		;
		cairo_font_extents: "cairo_font_extents" [
			cr			[handle!]
			extents		[cairo_font_extents_t!]
		]
		; cairo_show_text: "cairo_show_text" [
		; 	cr			[handle!]
		; 	text 		[c-string!]
		; ]
		cairo_image_surface_create: "cairo_image_surface_create" [
			format		[cairo_format_t!]
			width		[integer!]
			height		[integer!]
			return:		[handle!]
		]
		cairo_image_surface_create_for_data: "cairo_image_surface_create_for_data" [
			data		[byte-ptr!]
			format		[cairo_format_t!]
			width		[integer!]
			height		[integer!]
			stride		[integer!]
			return:		[handle!]
		]
		cairo_surface_finish: "cairo_surface_finish" [
			surf		[handle!]
		]
		cairo_surface_destroy: "cairo_surface_destroy" [
			surf		[handle!]
		]
		cairo_image_surface_get_data: "cairo_image_surface_get_data" [
			surf		[handle!]
			return:		[byte-ptr!]
		]
		cairo_image_surface_get_width: "cairo_image_surface_get_width" [
			surf		[handle!]
			return:		[integer!]
		]
		cairo_surface_flush: "cairo_surface_flush" [
			surf		[handle!]
		]
		cairo_surface_mark_dirty: "cairo_surface_mark_dirty" [
			surf		[handle!]
		]
		cairo_format_stride_for_width: "cairo_format_stride_for_width" [
			format		[cairo_format_t!]
			width		[integer!]
			return: 	[integer!]
		]
		gdk_cairo_set_source_pixbuf: "gdk_cairo_set_source_pixbuf" [
			cr 			[handle!]
			pixbuf 		[handle!]
			x 			[float!]
			y 			[float!]
		]
		gdk_pixbuf_new: "gdk_pixbuf_new" [
			colorsp 	[integer!]
			alpha 		[logic!]
			bits 		[integer!]
			width 		[integer!]
			height 		[integer!]
			return: 	[handle!]
		]
		gdk_pixbuf_new_subpixbuf: "gdk_pixbuf_new_subpixbuf" [
			pixbuf 		[handle!]
			x 			[integer!]
			y 			[integer!]
			width 		[integer!]
			height 		[integer!]
			return:		[handle!]
		]
		gdk_pixbuf_new_from_stream: "gdk_pixbuf_new_from_stream" [
			stream		[handle!]
			cancel		[handle!]
			error		[handle!]
			return:		[handle!]
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
		gdk_pixbuf_get_from_surface: "gdk_pixbuf_get_from_surface" [
			surf		[handle!]
			src_x		[integer!]
			src_y		[integer!]
			width		[integer!]
			height		[integer!]
			return:		[handle!]
		]
		gdk_pixbuf_get_from_window: "gdk_pixbuf_get_from_window" [
			window		[handle!]
			src_x		[integer!]
			src_y		[integer!]
			width		[integer!]
			height		[integer!]
			return:		[handle!]
		]
		gdk_pixbuf_get_n_channels: "gdk_pixbuf_get_n_channels" [
			pixbuf		[handle!]
			return: 	[integer!]
		]
		gdk_get_default_root_window: "gdk_get_default_root_window" [
			return:		[handle!]
		]
		gdk_window_get_width: "gdk_window_get_width" [
			win 		[handle!]
			return:		[integer!]
		]
		gdk_window_get_height: "gdk_window_get_height" [
			win 		[handle!]
			return:		[integer!]
		]
		gdk_window_set_cursor: "gdk_window_set_cursor" [
			win 		[handle!]
			cursor		[handle!]
		]
		gdk_window_set_decorations: "gdk_window_set_decorations" [
			window		[handle!]
			flags		[integer!]
		]
		;; Useless since already called inside pango_cairo_create_context
		; pango_cairo_font_map_get_default: "pango_cairo_font_map_get_default" [
		; 	return: 	[handle!]
		; ]

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
		pango_cairo_show_layout_line: "pango_cairo_show_layout_line" [
			cr 			[handle!]
			layout_line [handle!]
		]
		pango_cairo_context_set_font_options: "pango_cairo_context_set_font_options" [
			cr 			[handle!]
			opts		[handle!]
		]
		pango_context_load_font: "pango_context_load_font" [
			context		[handle!]
			fd				[handle!]
			return: 	[handle!]
		]
		pango_font_map_create_context: "pango_font_map_create_context" [
			fontmap		[handle!]
			return:		[handle!]
		]
		pango_parse_markup: "pango_parse_markup" [
			markup_text		[c-string!]
			length 			[integer!]
			accel_marker	[integer!] 	;gunichar=guint32
			attr_list		[handle!] 	;[pointer! [handle!]]
			text			[handle!] 	;[pointer! [c-string!]]
			accel_char		[integer!] 	;gunichar=gunit32
			error			[handle!]
			return: 		[logic!]
		]
		pango_attr_list_new: "pango_attr_list_new" [
			return: 	[handle!]
		]
 		pango_attr_list_ref: "pango_attr_list_ref" [
			 attrs 		[handle!]
			 return: 	[handle!]
		]
 		pango_attr_list_unref: "pango_attr_list_unref" [
			 attrs 		[handle!]
		]
		pango_attr_list_copy: "pango_attr_list_copy" [
			attrs 		[handle!]
			return: 	[handle!]
		]
		pango_attr_list_insert: "pango_attr_list_insert" [
			attrs 		[handle!]
			attr 		[PangoAttribute!]
		]
		pango_attr_list_change: "pango_attr_list_change" [
			attrs 		[handle!]
			attr 		[PangoAttribute!]
		]
		pango_attr_list_insert_before: "pango_attr_list_insert_before" [
			attrs 		[handle!]
			attr 		[PangoAttribute!]
		]
		pango_attr_list_splice: "pango_attr_list_splice" [
			attrs 		[handle!]
			attrs2 		[handle!]
			pos			[integer!]
			len			[integer!]
		]

		pango_attribute_equal: "pango_attribute_equal" [
			attr		[handle!]
			attr2		[handle!]
			return:		[logic!]
		]
		pango_attribute_destroy: "pango_attribute_destroy" [
			attr		[PangoAttribute!]
		]
		;; font description attributes
		pango_attr_family_new: "pango_attr_family_new" [
			name		[c-string!]
			return:		[PangoAttribute!]
		]
		pango_attr_style_new: "pango_attr_style_new" [
			style		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_variant_new: "pango_attr_variant_new" [
			variant		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_stretch_new: "pango_attr_stretch_new" [
			stretch		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_weight_new: "pango_attr_weight_new" [
			weight		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_size_new: "pango_attr_size_new" [
			size		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_size_new_absolute: "pango_attr_size_new_absolute" [
			size		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_font_desc_new: "pango_attr_font_desc_new" [
			font-desc	[handle!]
			return:		[PangoAttribute!]
		]
		;; Color attributes
		pango_attr_foreground_new: "pango_attr_foreground_new" [
			r			[integer!]
			g			[integer!]
			b			[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_background_new: "pango_attr_background_new" [
			r			[integer!]
			g			[integer!]
			b			[integer!]
			return:		[PangoAttribute!]
		]
		;; styles attributes
		pango_attr_strikethrough_new: "pango_attr_strikethrough_new" [
			ok			[logic!]
			return: 	[PangoAttribute!]
		]
		pango_attr_strikethrough_color_new: "pango_attr_strikethrough_color_new" [
			r			[integer!]
			g			[integer!]
			b			[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_underline_new: "pango_attr_underline_new" [
			ok			[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_underline_color_new: "pango_attr_underline_color_new" [
			r			[integer!]
			g			[integer!]
			b			[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_shape_new: "pango_attr_shape_new" [
			ink-rect	[handle!]
			logic-rect	[handle!]
			return:		[PangoAttribute!]
		]
		;; size attributes
		pango_attr_scale_new: "pango_attr_scale_new" [
			scale		[float!]
			return:		[PangoAttribute!]
		]
		pango_attr_rise_new: "pango_attr_rise_new" [
			rise		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_letter_spacing_new: "pango_attr_letter_spacing_new" [
			spacing		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_gravity_new: "pango_attr_gravity_new" [
			gravity		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_gravity_hint_new: "pango_attr_gravity_hint_new" [
			hint		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_font_features_new: "pango_attr_font_features_new" [
			features	[c-string!]
			return:		[PangoAttribute!]
		]
		pango_attr_foreground_alpha_new: "pango_attr_foreground_alpha_new" [
			alpha		[integer!]
			return:		[PangoAttribute!]
		]
		pango_attr_background_alpha_new: "pango_attr_background_alpha_new" [
			alpha		[integer!]
			return:		[PangoAttribute!]
		]

		cairo_font_options_create: "cairo_font_options_create" [
			return:		[handle!]
		]
		cairo_font_options_destroy: "cairo_font_options_destroy" [
			fontopts	[handle!]
		]
		cairo_font_options_set_antialias: "cairo_font_options_set_antialias" [
			cfo			[handle!]
			antialias	[cairo_antialias_t!]
		]
	]
]

;; Identifiers for qdata
red-face-id1:		g_quark_from_string "red-face-id1"
red-face-id2:		g_quark_from_string "red-face-id2"
red-face-id3:		g_quark_from_string "red-face-id3"
red-face-id4:		g_quark_from_string "red-face-id4"
red-color-id:		g_quark_from_string "red-color-id"
red-color-str:		g_quark_from_string "red-color-str"
red-font-id:		g_quark_from_string "red-font-id"
red-font-str:		g_quark_from_string "red-font-str"
container-id:		g_quark_from_string "container-id"
red-timer-id:		g_quark_from_string "red-timer-id"
menu-key-id:		g_quark_from_string "menu-key-id"
red-event-id:		g_quark_from_string "red-event-id"
cursor-id:			g_quark_from_string "cursor-id"
resizing-id:		g_quark_from_string "resizing-id"
start-resize-id:	g_quark_from_string "start-resize-id"
caption-id:			g_quark_from_string "caption-id"
in-loop-id:			g_quark_from_string "in-loop-id"
first-radio-id:		g_quark_from_string "first-radio-id"
resend-event-id:	g_quark_from_string "resend-event-id"
hmenu-id:			g_quark_from_string "hmenu-id"
container-w:		g_quark_from_string "container-w"
container-h:		g_quark_from_string "container-h"
caret-id:			g_quark_from_string "caret-id"
im-context-id:		g_quark_from_string "im-context-id"
camera-cfg:			g_quark_from_string "camera-cfg"
camera-pixbuf:		g_quark_from_string "camera-pixbuf"
base-buffer:		g_quark_from_string "base-buffer"
base-enter:			g_quark_from_string "base-enter"
pair-size-facet:	g_quark_from_string "pair-size-facet"
;im-string-id:		g_quark_from_string "im-string-id"
;im-start-id:		g_quark_from_string "im-start-id"

#define SET-RED-COLOR(s d)		[g_object_set_qdata s red-color-id d]
#define GET-RED-COLOR(s)		[g_object_get_qdata s red-color-id]
#define SET-COLOR-STR(s d)		[g_object_set_qdata s red-color-str as handle! d]
#define GET-COLOR-STR(s)		[as GString! g_object_get_qdata s red-color-str]
#define SET-RED-FONT(s d)		[g_object_set_qdata s red-font-id d]
#define GET-RED-FONT(s)			[g_object_get_qdata s red-font-id]
#define SET-FONT-STR(s d)		[g_object_set_qdata s red-font-str as handle! d]
#define GET-FONT-STR(s)			[as GString! g_object_get_qdata s red-font-str]
#define SET-CONTAINER(s d)		[g_object_set_qdata s container-id d]
#define GET-CONTAINER(s)		[g_object_get_qdata s container-id]
#define SET-CURSOR(s d)			[g_object_set_qdata s cursor-id d]
#define GET-CURSOR(s)			[g_object_get_qdata s cursor-id]
#define SET-RESIZING(s d)		[g_object_set_qdata s resizing-id d]
#define GET-RESIZING(s)			[g_object_get_qdata s resizing-id]
#define SET-STARTRESIZE(s d)	[g_object_set_qdata s start-resize-id d]
#define GET-STARTRESIZE(s)		[g_object_get_qdata s start-resize-id]
#define SET-CAPTION(s d)		[g_object_set_qdata s caption-id d]
#define GET-CAPTION(s)			[g_object_get_qdata s caption-id]
#define SET-IN-LOOP(s d)		[g_object_set_qdata s in-loop-id d]
#define GET-IN-LOOP(s)			[g_object_get_qdata s in-loop-id]
#define SET-MENU-KEY(s d)		[g_object_set_qdata s menu-key-id d]
#define GET-MENU-KEY(s)			[g_object_get_qdata s menu-key-id]
#define SET-FIRST-RADIO(s d)	[g_object_set_qdata s first-radio-id d]
#define GET-FIRST-RADIO(s)		[g_object_get_qdata s first-radio-id]
#define SET-RESEND-EVENT(s d)	[g_object_set_qdata s resend-event-id d]
#define GET-RESEND-EVENT(s)		[g_object_get_qdata s resend-event-id]
#define SET-HMENU(s d)			[g_object_set_qdata s hmenu-id d]
#define GET-HMENU(s)			[g_object_get_qdata s hmenu-id]
#define SET-CONTAINER-W(s d)	[g_object_set_qdata s container-w as int-ptr! d]
#define GET-CONTAINER-W(s)		[as integer! g_object_get_qdata s container-w]
#define SET-CONTAINER-H(s d)	[g_object_set_qdata s container-h as int-ptr! d]
#define GET-CONTAINER-H(s)		[as integer! g_object_get_qdata s container-h]
#define SET-CAMERA-CFG(s d)		[g_object_set_qdata s camera-cfg as int-ptr! d]
#define GET-CAMERA-CFG(s)		[g_object_get_qdata s camera-cfg]
#define SET-CAMERA-IMG(s d)		[g_object_set_qdata s camera-pixbuf d]
#define GET-CAMERA-IMG(s)		[g_object_get_qdata s camera-pixbuf]
#define SET-CARET-OWNER(s d)	[g_object_set_qdata s caret-id d]
#define GET-CARET-OWNER(s)		[g_object_get_qdata s caret-id]
#define SET-IM-CONTEXT(s d)		[g_object_set_qdata s im-context-id d]
#define GET-IM-CONTEXT(s)		[g_object_get_qdata s im-context-id]
#define SET-BASE-BUFFER(s d)	[g_object_set_qdata s base-buffer d]
#define GET-BASE-BUFFER(s)		[g_object_get_qdata s base-buffer]
#define SET-BASE-ENTER(s d)		[g_object_set_qdata s base-enter d]
#define GET-BASE-ENTER(s)		[g_object_get_qdata s base-enter]
#define SET-PAIR-SIZE(s d)		[g_object_set_qdata s pair-size-facet d]
#define GET-PAIR-SIZE(s)		[g_object_get_qdata s pair-size-facet]

;#define SET-IM-STRING(s d)		[g_object_set_qdata s im-string-id as int-ptr! d]
;#define GET-IM-STRING(s)		[as c-string! g_object_get_qdata s im-string-id]
;#define SET-IM-START(s d)		[g_object_set_qdata s im-start-id as int-ptr! d]
;#define GET-IM-START(s)			[as logic! g_object_get_qdata s im-start-id]