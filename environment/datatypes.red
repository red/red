Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %datatypes.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- datatype! is not defined here for obvious circular reference issue

unset!:			make datatype! #get-definition TYPE_UNSET
none!:			make datatype! #get-definition TYPE_NONE
logic!:			make datatype! #get-definition TYPE_LOGIC
block!:			make datatype! #get-definition TYPE_BLOCK
string!:		make datatype! #get-definition TYPE_STRING
integer!:		make datatype! #get-definition TYPE_INTEGER
;symbol!:		make datatype! #get-definition TYPE_SYMBOL
;context!:		make datatype! #get-definition TYPE_CONTEXT
word!:			make datatype! #get-definition TYPE_WORD
error!:			make datatype! #get-definition TYPE_ERROR
typeset!:		make datatype! #get-definition TYPE_TYPESET
file!:			make datatype! #get-definition TYPE_FILE
url!:			make datatype! #get-definition TYPE_URL
set-word!:		make datatype! #get-definition TYPE_SET_WORD
get-word!:		make datatype! #get-definition TYPE_GET_WORD
lit-word!:		make datatype! #get-definition TYPE_LIT_WORD
refinement!:	make datatype! #get-definition TYPE_REFINEMENT
binary!:		make datatype! #get-definition TYPE_BINARY
paren!:			make datatype! #get-definition TYPE_PAREN
char!:			make datatype! #get-definition TYPE_CHAR
issue!:			make datatype! #get-definition TYPE_ISSUE
path!:			make datatype! #get-definition TYPE_PATH
set-path!:		make datatype! #get-definition TYPE_SET_PATH
get-path!:		make datatype! #get-definition TYPE_GET_PATH
lit-path!:		make datatype! #get-definition TYPE_LIT_PATH
native!:		make datatype! #get-definition TYPE_NATIVE
action!:		make datatype! #get-definition TYPE_ACTION
op!:			make datatype! #get-definition TYPE_OP
function!:		make datatype! #get-definition TYPE_FUNCTION
;closure!:		make datatype! #get-definition TYPE_CLOSURE
routine!:		make datatype! #get-definition TYPE_ROUTINE
object!:		make datatype! #get-definition TYPE_OBJECT
;port!:			make datatype! #get-definition TYPE_PORT
bitset!:		make datatype! #get-definition TYPE_BITSET
float!:			make datatype! #get-definition TYPE_FLOAT
point!:			make datatype! #get-definition TYPE_POINT
vector!:		make datatype! #get-definition TYPE_VECTOR
map!:			make datatype! #get-definition TYPE_MAP
hash!:			make datatype! #get-definition TYPE_HASH
pair!:			make datatype! #get-definition TYPE_PAIR
percent!:		make datatype! #get-definition TYPE_PERCENT
tuple!:			make datatype! #get-definition TYPE_TUPLE
image!:			make datatype! #get-definition TYPE_IMAGE
time!:			make datatype! #get-definition TYPE_TIME
tag!:			make datatype! #get-definition TYPE_TAG
email!:			make datatype! #get-definition TYPE_EMAIL
handle!:		make datatype! #get-definition TYPE_HANDLE

#if find config/modules 'view [
	event!: make datatype! #get-definition TYPE_EVENT
]

none:  			make none! 0
true:  			make logic! 1
false: 			make logic! 0