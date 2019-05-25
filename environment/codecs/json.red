Red [
    Title:   "JSON codec"
    Author:  "Gabriele Santilli"
    File:    %json.red
    Purpose: "Adds JSON as a valid data type to use with LOAD/AS and SAVE/AS"
	License: [
		http://www.apache.org/licenses/LICENSE-2.0 
		and "The Software shall be used for Good, not Evil."
	]
]

#include %environment/codecs/json/load-json.red
#include %environment/codecs/json/to-json.red

put system/codecs 'json context [
    Title:     "JSON codec"
    Name:      'JSON
    Mime-Type: [application/json]
    Suffixes:  [%.json]
    encode: func [data [any-type!] where [file! url! none!]] [
        to-json data
    ]
    decode: func [text [string! binary! file!]] [
        if file? text [text: read text]
        if binary? text [text: to string! text]
        load-json text
    ]
]
