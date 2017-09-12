Red [
	Title:   "Red JVM bridge"
	Author:  "Nenad Rakocevic"
	File: 	 %bridge.red
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system-global [
	#define node! int-ptr!								;-- required for Red datatypes definitions
	
	#include %../../system/bridges/java/JNI.reds
	#include %../../runtime/datatypes/structures.reds
	
	env: as JNI-env! 0
	jni: as JNI! 0
	
	#enum android-events! [
		event-click: 1
	]
	
	#enum java-types! [
		type-void:		1
		type-boolean:	3
		type-byte:		5
		type-int:		7
		type-short:		9
		type-long:		11
		type-float:		13
		type-double:	15
		type-string:	98
		type-object:	99
	]
	
	store-type: func [
		name	[jstring!]
		/local	
			src	   [c-string!]
			str	   [c-string!]
			word   [red-word!]
			array? [logic!]
			len	   [integer!]
	][
		src: jni/GetStringUTFChars env name null
		str: src
		
		array?: str/1 = #"["
		if array? [str: str + 1]
		
		if str/1 = #"L" [
			str: str + 1
			len: length? str
			str/len: null-byte							;-- overwrite final #";"
		]
		word: red/word/load str
		#call [~on-param-type word array?]
		
		jni/ReleaseStringUTFChars env name src			;@@ restore last character??
		jni/DeleteLocalRef env name
	]
	
	enum-methods: func [
		class	[jclass!]
		init?	[logic!]								;-- TRUE: fetch constructors
		/local
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
				#call [~on-new-constructor]
			][
				;--- Get method name ---
				name: jni/CallObjectMethod [env obj getName]
				str: jni/GetStringUTFChars env name null
				word: red/word/load str
				#call [~on-new-method word]
				jni/ReleaseStringUTFChars env name str
				jni/DeleteLocalRef env name
			]
			
			;--- Get method id ---
			id: jni/FromReflectedMethod env obj
			#call [~on-method-id as integer! id]
			
			unless init? [
				;--- Get method return type ---
				method: jni/CallObjectMethod [env obj getReturnType]
				cls: jni/GetObjectClass env method
				cls.getName: get-method env cls "getName" "()Ljava/lang/String;"
				name: jni/CallObjectMethod [env method cls.getName]
				jni/DeleteLocalRef env method
				store-type name
				jni/DeleteLocalRef env cls
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
				store-type name
				jni/DeleteLocalRef env cls
				jni/DeleteLocalRef env obj				;-- release Class object
				i: i + 1
			]
			jni/DeleteLocalRef env cls-list				;-- release Class array
			idx: idx + 1
		]
	]
	
	fetch-constructors: func [
		class	[jclass!]
		/local
			id			  [jmethodID!]
			list		  [jobject!]
			cls-list	  [jobject!]
			obj			  [jobject!]
			cls			  [jclass!]
			method		  [jclass!]
			getName		  [jmethodID!]
			cls.getName	  [jmethodID!]
			getParams	  [jmethodID!]
			name		  [jstring!]
			size		  [integer!]
			sz			  [integer!]
			idx			  [integer!]
			i			  [integer!]
	][
		cls: jni/FindClass env "java/lang/Class"
		method: jni/FindClass env "java/lang/reflect/Constructor"
		id: get-method env cls "getConstructors" "()[Ljava/lang/reflect/Constructor;"

		list: jni/CallObjectMethod [env class id]
		size: jni/GetArrayLength env list

		getName:   get-method env method "getName" "()Ljava/lang/String;"
		getParams: get-method env method "getParameterTypes" "()[Ljava/lang/Class;"

		idx: 0
		while [idx < size][
			obj: jni/GetObjectArrayElement env list idx

			#call [~on-new-constructor]

			;--- Get method id ---
			id: jni/FromReflectedMethod env obj
			#call [~on-method-id as integer! id]

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
				store-type name
				jni/DeleteLocalRef env cls
				jni/DeleteLocalRef env obj				;-- release Class object
				i: i + 1
			]
			jni/DeleteLocalRef env cls-list				;-- release Class array
			idx: idx + 1
		]
		jni/DeleteLocalRef env list						;-- release constructors Class array
	]
	
	fetch-super-class: func [
		class	[jclass!]
		/local
			cls 			[jclass!]
			getSuperclass	[jmethodID!]
			getName			[jmethodID!]
			src				[c-string!]
			name			[jobject!]
			word			[red-word!]
			str				[c-string!]
	][
		cls: jni/FindClass env "java/lang/Class"
		getSuperclass: get-method env cls "getSuperclass" "()Ljava/lang/Class;"
		class: jni/CallObjectMethod [env class getSuperclass]
		
		unless null? class [
			class: jni/NewGlobalRef env class
			#call [~on-super-id as integer! class]

			getName: get-method env cls "getName" "()Ljava/lang/String;"
			name: jni/CallObjectMethod [env class getName]

			str: jni/GetStringUTFChars env name null
			word: red/word/load str
			#call [~on-super-name word]
			jni/ReleaseStringUTFChars env name str
		]
	]
	
#either OS = 'Android [
	Java_org_redlang_eval_MainActivity_doMain:
][
	Java_bridge_doMain:
] func [
		jni-env	[JNI-env!]
		this	[jobject!]
		/local
			gid	[jobject!]
	][
		env: jni-env
		jni: env/jni
		gid: jni/NewGlobalRef env this
		;jni/DeleteLocalRef env this
		#call [main as integer! gid]
	]
	
#either OS = 'Android [
	Java_org_redlang_eval_ClickEvent_Receive:
][
	Java_events_Receive:
] func [
		jni-env	[JNI-env!]
		this	[jobject!]
		face	[integer!]
	][	
		env: jni-env
		jni: env/jni
		#call [on-java-event face event-click 0]
	]
	
	#either OS = 'Android [
		#export JNICALL [
			Java_org_redlang_eval_MainActivity_doMain
			Java_org_redlang_eval_ClickEvent_Receive
		]
	][
		#export JNICALL [
			Java_bridge_doMain
			Java_events_Receive
		]
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

~on-new-constructor: does [
	append ~class/6 'init
	append/only ~class/6 ~method: reduce [none '- make block! 2]
]

~on-new-method: func [word [word!]][
	append ~class/7 word
	append/only ~class/7 ~method: reduce [none none make block! 2]
]

~on-method-id: func [id [integer!]][~method/1: id]

~on-super-id: func [id [integer!]][~class/4: id]

~on-super-name: func [word [word!]][~class/5: word]

~on-param-type: func [type [word!] array? [logic!]][
	if array? [type: reduce [type]]
	
	either ~method/2 [									;-- if return type <> none, set argument type
		append/only ~method/3 type
	][
		~method/2: type
	]
]

java-get-class-id: routine [
	name    [string!]
	return: [integer!]
	/local
		id  [jclass!]
		gid	[jclass!]
][
	id: jni/FindClass env as c-string! string/rs-head name
	either null? id [
		print-line ["java-get-class-id failed!"]
		0
	][
		gid: jni/NewGlobalRef env id
		jni/DeleteLocalRef env id
		as-integer gid
	]
]

java-get-object-class: routine [
	obj		[integer!]
	return: [integer!]
	/local
		id  [jclass!]
		gid	[jclass!]
][
	id: jni/getObjectClass env as jobject! obj
	either null? id [
		print-line ["java-get-object-class failed!"]
		0
	][
		gid: jni/NewGlobalRef env id
		jni/DeleteLocalRef env id
		as-integer gid
	]
]

java-get-class-name: routine [
	class	[integer!]
	/local
		cls	 [jclass!]
		id	 [jmethodID!]
		name [jobject!]
		str  [c-string!]
][
	cls: jni/FindClass env "java/lang/Class"
	id: get-method env cls "getName" "()Ljava/lang/String;"
	name: jni/CallObjectMethod [env class id]
	str: jni/GetStringUTFChars env name null
	word: red/word/load str
	jni/ReleaseStringUTFChars env name str
	jni/DeleteLocalRef env name
	SET_RETURN(word)
]

java-populate: routine [
	id  	[integer!]
	return: [logic!]									;-- TRUE if ok, FALSE if class not found
	/local
		cls [jclass!]
][
	cls: as jclass! id
	fetch-constructors cls
	;enum-methods cls yes								;-- fetch constructors
	enum-methods cls no									;-- fetch methods
	fetch-super-class cls
	true
]

java-populate-super: routine [
	id  	[integer!]
][
	fetch-super-class as jclass! id
]

java-instantiate-abstract: routine [
	cls     [integer!]
	return: [integer!]
	/local
		init-id [jmethodID!]
		res		[jobject!]
		gid		[jobject!]
		saved	[int-ptr!]
][
	#if debug? = yes [print-wide ["java-instantiate-abstract" as byte-ptr! cls lf]]
	
	init-id: get-method env as jclass! cls "<init>" "()V"

	saved: system/stack/align
	push 0
	push init-id
	push cls											;-- class id
	push env
	res: jni/NewObjectA 4
	system/stack/top: saved
	
	if res <> null [
		gid: jni/NewGlobalRef env res
		jni/DeleteLocalRef env res
	]
	as-integer gid
]

java-instantiate: routine [
	cls     [integer!]
	id	    [integer!]
	spec    [block!]
	return: [integer!]
	/local
		value	[red-value!]
		head	[red-value!]
		bool	[red-logic!]
		int		[red-integer!]
		res		[jobject!]
		gid		[jobject!]
		saved	[int-ptr!]
][	
	#if debug? = yes [print-wide ["java-instantiate" as byte-ptr! cls as byte-ptr! id lf]]
	
	value: block/rs-tail spec
	head:  block/rs-head spec
	
	saved: system/stack/align
	
	value: value - 1
	while [value >= head][
		switch TYPE_OF(value) [
			TYPE_STRING [
				push 0									;-- jvalue slots are 64-bit!
				push jni/NewStringUTF 
					env
					as-c-string string/rs-head as red-string! value
			]
			TYPE_LOGIC [
				bool: as red-logic! value
				push 0									;-- jvalue slots are 64-bit!
				push as-byte bool/value
			]
			default [
				int: as red-integer! value
				push 0									;-- jvalue slots are 64-bit!
				push int/value
			]
		]
		value: value - 1
	]
	push system/stack/top
	push id												;-- <init> id
	push cls											;-- class id
	push env
	
	res: jni/NewObjectA 4
	system/stack/top: saved
	
	if res <> null [
		gid: jni/NewGlobalRef env res
		jni/DeleteLocalRef env res
	]
	as-integer gid
]

java-invoke: routine [
	obj		 [integer!]
	method	 [integer!]
	ret-type [integer!]
	spec     [block!]
	/local
		value	[red-value!]
		head	[red-value!]
		bool	[red-logic!]
		int		[red-integer!]
		buffer	[jobject!]
		str		[c-string!]
		id		[jobject!]
		gid		[jobject!]
		saved	[int-ptr!]
][	
	value: block/rs-tail spec
	head:  block/rs-head spec

	saved: system/stack/align

	value: value - 1
	while [value >= head][
		switch TYPE_OF(value) [
			TYPE_STRING [
				push 0									;-- jvalue slots are 64-bit!
				push jni/NewStringUTF 
					env
					as-c-string string/rs-head as red-string! value
			]
			TYPE_LOGIC [
				bool: as red-logic! value
				push 0									;-- jvalue slots are 64-bit!
				push as-byte bool/value
			]
			default [
				int: as red-integer! value
				push 0									;-- jvalue slots are 64-bit!
				push int/value
			]
		]
		value: value - 1
	]
	push system/stack/top
	push method
	push obj
	push env

	switch ret-type [
		type-void	 [jni/CallVoidMethodA 4	value: none-value]
		type-boolean [value: as red-value! logic/push as-logic jni/CallBooleanMethodA 4]
		type-byte	 [value: as red-value! integer/push as-integer jni/CallByteMethodA 4]
		type-int	 [value: as red-value! integer/push jni/CallIntMethodA 4]
		type-short	 [value: as red-value! integer/push jni/CallShortMethodA 4]
		type-long	 [value: as red-value! integer/push jni/CallLongMethodA 4]
		;type-float	 [jni/CallFloatMethodA 4]
		;type-double  [jni/CallDoubleMethodA 4]
		type-object	 [
			id: jni/CallObjectMethodA 4
			gid: jni/NewGlobalRef env id
			jni/DeleteLocalRef env id
			value: as red-value! integer/push as-integer gid
		]
		type-string	 [
			buffer: jni/CallObjectMethodA 4
			str: jni/GetStringUTFChars env buffer null
			value: as red-value! string/load str length? str UTF-8
			jni/ReleaseStringUTFChars env buffer str
			jni/DeleteLocalRef env buffer
		]
	]
	system/stack/top: saved
	SET_RETURN(value)
]

java-types-table: [
	void					none!
	boolean					logic!
	byte					char!
	int						integer!
	short					integer!
	long					integer!
	float					float32!
	double					float!
	java.lang.String		string!
	java.lang.CharSequence	string!
]

to-java-type: func [type [word!]][
	pick find java-types-table type -1
]

to-Red-type: func [type [word!]][
	select/skip java-types-table type 2
]

to-type-id: func [type [word!] /local pos][
	either all [
		type <> 'java.lang.CharSequence
		pos: find java-types-table type
	][
		either pos/2 = 'string! [98][index? pos]
	][
		99
	]
]

java-process-args: function [args [block!]][
	forall args [
		if block? args/1 [
			args/1: any [args/1/1 args/1/2]				;-- replace block with id
		]
	]
	args
]

java-match-method: function [list [block!] spec [block!] fun [word!] return-type [word! none!]][
	foreach [name entry] list [
		if name <> fun [return none]
		proto: entry/3
		if (length? proto) = length? spec [
			args: spec
			match?: yes
			foreach required proto [
				match?: either block? args/1 [			;-- is object or class?
					none? to-Red-type required
				][
					type: type?/word args/1
					expected: to-Red-type required
					all [match? type = expected]		;-- cumulative matching
				]
				args: next args
			]
			if return-type [
				match?: all [match? entry/2 = return-type]
			]
			if match? [return entry]
		]
	]
	none
]


java-fetch-class: func [name [word!] /with cls [integer!] /local class][
	unless with [
		cls: java-get-class-id replace/all form name dot slash
		if cls = 0 [
			print ["Error: not found class" form spec/1]
			exit
		]
	]
	class: reduce [
		none											;-- instance id (for objects only)
		cls												;-- class id
		name											;-- class name (original form)
		0												;-- parent id
		none											;-- parent name
		make block! 8									;-- constructors block
		make block! 16									;-- methods block
	]
	~class: class
	java-populate cls									;-- fetch methods and fields
	~class: ~method: none
	
	append ~classes name								;-- original class name
	append/only ~classes class
	class
]


;====== Public API ======

java-verbose: 0

to-java-object: func [obj-id [integer!] /local class cls name][
	class: reduce [
		obj-id
		cls:  java-get-object-class obj-id
		name: java-get-class-name	 cls
		0												;-- parent id
		none											;-- parent name
		make block! 2
		make block! 40
	]
	~class: class
	java-populate-super cls

	append ~classes name
	append/only ~classes class
	class
]

java-get-class: func [name [word!]][
	if java-verbose > 0 [print ["java-get-class:" name]]
	
	any [
		select/skip ~classes name 2
		java-fetch-class name
	]
]

java-new: func [spec [block!] /local name class id obj method][
	if java-verbose > 0 [print ["java-new:" mold spec]]
	
	class: java-get-class name: spec/1
	
	;-- Find matching constructor
	spec: reduce next spec
	either tail? class/6 [
		id: java-instantiate-abstract class/2
	][
		unless method: java-match-method class/6 spec 'init none [
			print ["Error: no matching constructor found for class" form name]
			exit
		]
		id: java-instantiate class/2 method/1 java-process-args spec
	]
	if id = 0 [
		print ["Error: cannot instantiate object from class" form name]
		exit
	]
	obj: copy class
	obj/1: id
	obj
]

java-do: function [spec [block!]][
	if java-verbose > 0 [print ["java-do:" mold spec]]

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
	return-type: spec/1/3
	spec: reduce next spec
	class: obj
	
	while [
		all [
			not all [
				pos: find class/7 method
				entry: java-match-method pos spec method return-type
			]
			class/5
		]
	][
		class: any [
			select/skip ~classes class/5 2
			java-fetch-class/with class/5 class/4
		]
	]
	unless entry [
		print ["Error: no matching method found for: " form call]
		exit
	]
	
	spec: java-process-args spec
	result: java-invoke obj/1 entry/1 type: to-type-id entry/2 spec
	
	either any [
		type = 99
		entry/2 = 'java.lang.CharSequence
	][
		to-java-object result
	][
		result
	]
]

