Red [
	Title:   "Red JVM bridge"
	Author:  "Nenad Rakocevic"
	File: 	 %bridge.red
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#system-global [
	#define node! int-ptr!								;-- required for Red datatypes definitions
	
	#include %../../../red-system/bridges/java/JNI.reds
	#include %../../runtime/datatypes/structures.reds
	
	jni-env: declare JNI-env!
	
	store-type: func [
		env		[JNI-env!]
		name	[jstring!]
		/local	
			src	   [c-string!]
			str	   [c-string!]
			word   [red-word!]
			array? [logic!]
			len	   [integer!]
	][
		src: env/jni/GetStringUTFChars env name null
		str: src
		
		array?: str/1 = #"["
		if array? [str: str + 1]
		
		if str/1 = #"L" [
			str: str + 1
			len: length? str
			str/len: null-byte							;-- overwrite final #";"
		]
		word: red/word/load str
		#call [~java-type-event word array?]
		
		env/jni/ReleaseStringUTFChars env name src		;@@ restore last character??
	]
	
	enum-methods: func [
		env		[JNI-env!]
		class	[jclass!]
		init?	[logic!]								;-- TRUE: fetch constructors
		/local
			jni	  	 	  [JNI!]
			id			  [jmethodID!]
			list		  [jobject!]
			cls-list	  [jobject!]
			obj			  [jobject!]
			cls			  [jclass!]
			method		  [jclass!]
			getName		  [jmethodID!]
			cls.getName	  [jmethodID!]
			getParams	  [jmethodID!]
			getReturnType [jmethodID!]
			getClass 	  [jmethodID!]
			name		  [jstring!]
			str			  [c-string!]
			size		  [integer!]
			sz			  [integer!]
			idx			  [integer!]
			i			  [integer!]
			word		  [red-word!]
	][
		getReturnType: as jmethodID! 0
		
		jni: env/jni
		
		cls: jni/FindClass env "java/lang/Class"
		either init? [
			method: jni/FindClass env "java/lang/reflect/Constructor"
			id: get-method env cls "getConstructors" "()[Ljava/lang/reflect/Constructor;"
		][
			method: jni/FindClass env "java/lang/reflect/Method"
			getReturnType: get-method env method "getReturnType" "()Ljava/lang/Class;"
			id: get-method env cls "getDeclaredMethods" "()[Ljava/lang/reflect/Method;"
		]
		list: jni/CallObjectMethod [env class id]
		size: jni/GetArrayLength env list
		
		getName:   get-method env method "getName" "()Ljava/lang/String;"
		getParams: get-method env method "getParameterTypes" "()[Ljava/lang/Class;"
		
		idx: 0
		while [idx < size][
			obj: jni/GetObjectArrayElement env list idx
			
			either init? [
				#call [~java-new-constructor-event]
			][
				;--- Get method name ---
				name: jni/CallObjectMethod [env obj getName]
				str: jni/GetStringUTFChars env name null
				word: red/word/load str
				#call [~java-new-method-event word]
				jni/ReleaseStringUTFChars env name str
			]
			
			;--- Get method id ---
			id: jni/FromReflectedMethod env obj
			#call [~java-method-id-event as integer! id]
			
			unless init? [
				;--- Get method return type ---
				name: jni/CallObjectMethod [env obj getReturnType]
				cls: jni/GetObjectClass env name
				cls.getName: get-method env cls "getName" "()Ljava/lang/String;"
				name: jni/CallObjectMethod [env name cls.getName]
				store-type env name
			]
			
			;--- Get method arguments ---
			cls-list: jni/CallObjectMethod [env obj getParams]
			sz: jni/GetArrayLength env cls-list
			i: 0
			jni/DeleteLocalRef env obj					;-- release method object
			
			while [i < sz][
				obj: jni/GetObjectArrayElement env cls-list i
				cls: jni/GetObjectClass env obj
				cls.getName: get-method env cls "getName" "()Ljava/lang/String;"
				name: jni/CallObjectMethod [env obj cls.getName]
				store-type env name
				jni/DeleteLocalRef env obj				;-- release Class object
				i: i + 1
			]
			jni/DeleteLocalRef env cls-list				;-- release Class array
			idx: idx + 1
		]
	]
	
	fetch-super-class: func [
		env		[JNI-env!]
		class	[jclass!]
		/local
			jni				[JNI!]
			cls 			[jclass!]
			getSuperclass	[jmethodID!]
			getName			[jmethodID!]
			src				[c-string!]
			name			[jobject!]
			word			[red-word!]
			str				[c-string!]
	][
		jni: env/jni
		
		cls: jni/FindClass env "java/lang/Class"
		getSuperclass: get-method env cls "getSuperclass" "()Ljava/lang/Class;"
		class: jni/CallObjectMethod [env class getSuperclass]
		
		unless null? class [
			class: jni/NewGlobalRef env class
			#call [~java-parent-id-event as integer! class]

			getName: get-method env cls "getName" "()Ljava/lang/String;"
			name: jni/CallObjectMethod [env class getName]

			str: jni/GetStringUTFChars env name null
			word: red/word/load str
			#call [~java-parent-name-event word]
			jni/ReleaseStringUTFChars env name str
		]
	]
	
	Java_bridge_doMain: func [
		env		[JNI-env!]
		this	[jobject!]
	][
		jni-env: env
		#call [main]
	]
	
	Java_events_Receive: func [
		env		[JNI-env!]
		this	[jobject!]
		event	[integer!]
	][
		jni-env: env
		#call [on-java-event event]
	]
	
	#export JNICALL [
		Java_bridge_doMain
		Java_events_Receive
	]
]

~classes: 	make block! 20
;-- ~classes: [
;-- 	class.name [
;--			obj-id | none
;--			class-id
;--			class-name
;-- 		parent-id
;--			parent-name
;--			['init  [id '- [arg-type1 arg-type2 ...] ...]
;--			[method1 [id '- [arg-type1 arg-type2 ...] ...]
;--		]
;--		...
;-- ]

~class: 	none
~method:	none

~java-new-constructor-event: does [
	append ~class/6 'init
	append/only ~class/6 ~method: reduce [none '- make block! 2]
]

~java-new-method-event: func [word [word!]][
	append ~class/7 word
	append/only ~class/7 ~method: reduce [none none make block! 2]
]

~java-method-id-event: func [id [integer!]][~method/1: id]

~java-parent-id-event: func [id [integer!]][~class/4: id]

~java-parent-name-event: func [word [word!]][~class/5: word]

~java-type-event: func [type [word!] array? [logic!]][
	if array? [type: reduce [type]]
	
	either ~method/2 [									;-- if return type <> none, set argument type
		append/only ~method/3 type
	][
		~method/2: type
	]
]

~java-get-class-id: routine [
	name    [string!]
	return: [integer!]
	/local 
		id  [jclass!]
][
	as-integer jni-env/jni/NewGlobalRef
		jni-env
		jni-env/jni/FindClass jni-env as c-string! string/rs-head name
]

~java-populate: routine [
	id  	[integer!]
	return: [logic!]									;-- TRUE if ok, FALSE if class not found
	/local
		env [JNI-env!]
		cls [jclass!]
][
	env: jni-env
	cls: as jclass! id
	enum-methods env cls yes							;-- fetch constructors
	enum-methods env cls no								;-- fetch methods
	fetch-super-class env cls
	true
]

~java-instantiate-abstract: routine [
	cls     [integer!]
	return: [integer!]
	/local init-id
][
	init-id: get-method jni-env as jclass! cls "<init>" "()V"
	push cls											;-- class id
	push jni-env	
	as-integer jni-env/jni/NewGlobalRef jni-env jni-env/jni/NewObject
]

~java-instantiate: routine [
	cls     [integer!]
	id	    [integer!]
	spec    [block!]
	return: [integer!]
	/local
		value head jni bool int
][	
	jni: jni-env/jni
	
	value: block/rs-tail spec
	head:  block/rs-head spec
	
	value: value - 1
	while [value >= head][
		switch TYPE_OF(value) [
			TYPE_STRING [
				push jni/NewStringUTF 
					jni-env
					as-c-string string/rs-head as red-string! value
			]
			TYPE_LOGIC [
				bool: as red-logic! value
				push as-byte bool/value
			]
			default [
				int: as red-integer! value
				push int/value
			]
		]
		value: value - 1
	]
	push id												;-- <init> id
	push cls											;-- class id
	push jni-env	
	as-integer jni/NewObject
]

~java-invoke: routine [
	spec    [block!]
	return: [integer!]
	/local
		value head jni bool int
][	
	jni: jni-env/jni
	
	value: block/rs-tail spec
	head:  block/rs-head spec
	
	value: value - 1
	while [value >= head][
		switch TYPE_OF(value) [
			TYPE_STRING [
				push jni/NewStringUTF 
					jni-env
					as-c-string string/rs-head as red-string! value
			]
			TYPE_LOGIC [
				bool: as red-logic! value
				push as-byte bool/value
			]
			default [
				int: as red-integer! value
				push int/value
			]
		]
		value: value - 1
	]
	as-integer jni/CallObjectMethod jni-env
]

java-types-table: [
	void				none!
	boolean				logic!
	byte				char!
	int					integer!
	short				integer!
	long				integer!
	;float				float32!
	;double				float!
	java.lang.String	string!
]

to-java-type: func [type [word!]][
	pick find java-types-table type -1
]

to-Red-type: func [type [word!]][
	select/skip java-types-table type 2
]

java-process-args: function [args [block!]][
	forall args [
		if block? args/1 [
			args/1: any [args/1/1 args/1/2]				;-- replace block with id
		]
	]
	args
]

java-match-method: function [list [block!] spec [block!] fun [word!]][
	foreach [name entry] list [
		if name <> fun [return none]
		
		proto: entry/3
		if (length? proto) = length? spec [
			args: spec
			match?: yes
			foreach required proto [
				unless block? args/1 [					;-- is object or class?
					type: type?/word args/1
					expected: to-Red-type required
					match?: all [match? type = expected];-- cumulative matching
				]
				args: next args
			]
			if match? [return entry/1]
		]
	]
	none
]

java-fetch-class: func [name [word!] /with cls [integer!] /local class][
	append ~classes name								;-- original class name
	append/only ~classes class: make block! 1000		;-- class data
	append class none									;-- instance id (for objects only)
	unless with [
		cls: ~java-get-class-id replace/all form name dot slash
		if cls = 0 [
			print ["Error: not found class" form spec/1]
			exit
		]
	]
	append class cls									;-- class id
	append class name									;-- class name (original form)
	append class 0										;-- parent id
	append class none									;-- parent name
	append/only class make block! 2						;-- constructors block
	append/only class make block! 40					;-- methods block

	~class: class
	~java-populate cls									;-- fetch methods and fields
	~class: ~method: none
	class
]

;====== Public API ======

java-new: func [spec [block!] /local name class id obj][
	name: spec/1
	
	class: any [
		select/skip ~classes name 2
		java-fetch-class name
	]
	
	;-- Find matching constructor
	spec: reduce next spec
	
	either tail? class/6 [
		id: ~java-instantiate-abstract class/2
	][
		unless id: java-match-method class/6 spec 'init [
			print ["Error: no matching constructor found for class" form spec/1]
			exit
		]
		id: ~java-instantiate class/2 id spec
	]
	if id = 0 [
		print ["Error: cannot instantiate object from class" form spec/1]
		exit
	]
	obj: copy class
	obj/1: id	
	obj
]

java-do: func [spec [block!] /local call obj method id class][
	unless path? call: spec/1 [
		print ["Error: object/method expected as first argument in " mold spec]
		exit
	]
	obj: get spec/1/1
	unless all [
		block? :obj
		integer? obj/2
	][
		print ["Error:" form :obj "is not a Java object!"]
		exit
	]
	method: spec/1/2
	spec: reduce next spec
	class: obj
	
	while [
		all [
			not all [
				pos: find class/7 method
				id: java-match-method pos spec method
			]
			class/5
		]
	][
		class: any [
			select/skip ~classes class/5 2
			java-fetch-class/with class/5 class/4
		]
	]
	unless id [
		print ["Error: no matching method found for: " form call]
		exit
	]
	
	spec: append reduce [obj/1 id] java-process-args spec
	~java-invoke spec
]
