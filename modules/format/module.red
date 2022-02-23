Red [
	Title:   "Format module inclusion list"
	Author:  @hiiamboris
	Rights:  "Copyright (C) 2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
    Needs: L10N											;@@ FIXME: doesn't work
]

#if object? :rebol [
	#include %split-float.red							;-- creates formatting/ context
]
#include %ordinal.red
#include %roman.red
#include %charmaps.red
#include %form-logic.red
#include %format-number-with-mask.red
#include %format-date-time.red
#include %format.red
