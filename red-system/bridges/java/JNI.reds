Red/System [
	Title:   "JVM bridge"
	Author:  "Nenad Rakocevic, Kaj de Vos"
	File: 	 %JNI.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic, Kaj de Vos. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define func-ptr!	integer!

#define jmethodID!	int-ptr!
#define jint!		integer!
#define jobject!	int-ptr!
#define jclass!		int-ptr!
#define jstring!	int-ptr!

#define JNI-ptr!	[struct! [jni [JNI!]]]


#switch OS [
	Windows  [#define JNICALL stdcall]
	#default [#define JNICALL cdecl]
]

#define JNI_FALSE	#"^(00)"
#define JNI_TRUE  	#"^(01)"

#enum version! [
	version-1.1:	00010001h
	version-1.2:	00010002h
	version-1.4:	00010004h
	version-1.6:	00010006h
]

JVM!: alias struct! [
    reserved0					[int-ptr!]
    reserved1					[int-ptr!]
    reserved2					[int-ptr!]
    
    DestroyJavaVM 				[function! [vm [JVM!] return: [jint!]]]
	AttachCurrentThread			[function! [vm [JVM!] penv [struct! [p [int-ptr!]]] args [byte-ptr!] return: [jint!]]]
	DetachCurrentThread 		[function! [vm [JVM!] return: [jint!]]]
    GetEnv						[function! [vm [JVM!] penv [struct! [p [int-ptr!]]] version [integer!] return: [jint!]]]
    AttachCurrentThreadAsDaemon [function! [vm [JVM!] penv [struct! [p [int-ptr!]]] args [byte-ptr!] return: [jint!]]]
]

JNI!: alias struct! [
    reserved0					[int-ptr!]
    reserved1					[int-ptr!]
    reserved2					[int-ptr!]
    reserved3					[int-ptr!]
	
	GetVersion					[func-ptr!]
	DefineClass					[func-ptr!]
	FindClass					[function! [env [JNI-ptr!] name [c-string!] return: [jclass!]]]
	FromReflectedMethod			[func-ptr!]
	FromReflectedField			[func-ptr!]
	ToReflectedMethod			[func-ptr!]
	GetSuperclass				[func-ptr!]
	IsAssignableFrom			[func-ptr!]
	ToReflectedField			[func-ptr!]
	
	Throw						[func-ptr!]
	ThrowNew					[func-ptr!]
	ExceptionOccurred			[func-ptr!]
	ExceptionDescribe			[func-ptr!]
	ExceptionClear				[func-ptr!]
	FatalError					[func-ptr!]
	
	PushLocalFrame				[func-ptr!]
	PopLocalFrame				[func-ptr!]
	
	NewGlobalRef				[func-ptr!]
	DeleteGlobalRef				[func-ptr!]
	DeleteLocalRef				[func-ptr!]
	IsSameObject				[func-ptr!]
	NewLocalRef					[func-ptr!]
	EnsureLocalCapacity			[func-ptr!]
	
	AllocObject					[func-ptr!]
	NewObject					[function! [return: [jobject!]]] ;-- stack frame is manually constructed
	NewObjectV					[func-ptr!]
	NewObjectA					[func-ptr!]
	
	GetObjectClass				[func-ptr!]
	IsInstanceOf				[func-ptr!]
	GetMethodID					[function! [env [JNI-ptr!] class [jclass!] name [c-string!] sig [c-string!] return: [jmethodID!]]]
	
	CallObjectMethod			[function! [[variadic]	return: [jobject!]]]
	CallObjectMethodV			[func-ptr!]
	CallObjectMethodA			[func-ptr!]
	
	CallBooleanMethod			[func-ptr!]
	CallBooleanMethodV			[func-ptr!]
	CallBooleanMethodA			[func-ptr!]
	
	CallByteMethod				[func-ptr!]
	CallByteMethodV				[func-ptr!]
	CallByteMethodA				[func-ptr!]
	
	CallCharMethod				[func-ptr!]
	CallCharMethodV				[func-ptr!]
	CallCharMethodA				[func-ptr!]
	
	CallShortMethod				[func-ptr!]
	CallShortMethodV			[func-ptr!]
	CallShortMethodA			[func-ptr!]
	
	CallIntMethod				[func-ptr!]
	CallIntMethodV				[func-ptr!]
	CallIntMethodA				[func-ptr!]
	
	CallLongMethod				[func-ptr!]
	CallLongMethodV				[func-ptr!]
	CallLongMethodA				[func-ptr!]
	
	CallFloatMethod				[func-ptr!]
	CallFloatMethodV			[func-ptr!]
	CallFloatMethodA			[func-ptr!]

	CallDoubleMethod			[func-ptr!]
	CallDoubleMethodV			[func-ptr!]
	CallDoubleMethodA			[func-ptr!]

	CallVoidMethod				[func-ptr!]
	CallVoidMethodV				[func-ptr!]
	CallVoidMethodA				[func-ptr!]
	
	CallNonvirtualObjectMethod	[func-ptr!]
	CallNonvirtualObjectMethodV	[func-ptr!]
	CallNonvirtualObjectMethodA	[func-ptr!]
	
	CallNonvirtualBooleanMethod	 [func-ptr!]
	CallNonvirtualBooleanMethodV [func-ptr!]
	CallNonvirtualBooleanMethodA [func-ptr!]
	
	CallNonvirtualByteMethod	[func-ptr!]
	CallNonvirtualByteMethodV	[func-ptr!]
	CallNonvirtualByteMethodA	[func-ptr!]
	
	CallNonvirtualCharMethod	[func-ptr!]
	CallNonvirtualCharMethodV	[func-ptr!]
	CallNonvirtualCharMethodA	[func-ptr!]
	
	CallNonvirtualShortMethod	[func-ptr!]
	CallNonvirtualShortMethodV	[func-ptr!]
	CallNonvirtualShortMethodA	[func-ptr!]
	
	CallNonvirtualIntMethod		[func-ptr!]
	CallNonvirtualIntMethodV	[func-ptr!]
	CallNonvirtualIntMethodA	[func-ptr!]
	
	CallNonvirtualLongMethod	[func-ptr!]
	CallNonvirtualLongMethodV	[func-ptr!]
	CallNonvirtualLongMethodA	[func-ptr!]
	
	CallNonvirtualFloatMethod	[func-ptr!]
	CallNonvirtualFloatMethodV	[func-ptr!]
	CallNonvirtualFloatMethodA	[func-ptr!]
	
	CallNonvirtualDoubleMethod	[func-ptr!]
	CallNonvirtualDoubleMethodV	[func-ptr!]
	CallNonvirtualDoubleMethodA	[func-ptr!]
	
	CallNonvirtualVoidMethod	[func-ptr!]
	CallNonvirtualVoidMethodV	[func-ptr!]
	CallNonvirtualVoidMethodA	[func-ptr!]
	
	GetFieldID					[func-ptr!]
	GetObjectField				[func-ptr!]
	GetBooleanField				[func-ptr!]
	GetByteField				[func-ptr!]
	GetCharField				[func-ptr!]
	GetShortField				[func-ptr!]
	GetIntField					[func-ptr!]
	GetLongField				[func-ptr!]
	GetFloatField				[func-ptr!]
	GetDoubleField				[func-ptr!]
	
	SetObjectField				[func-ptr!]
	SetBooleanField				[func-ptr!]
	SetByteField				[func-ptr!]
	SetCharField				[func-ptr!]
	SetShortField				[func-ptr!]
	SetIntField					[func-ptr!]
	SetLongField				[func-ptr!]
	SetFloatField				[func-ptr!]
	SetDoubleField				[func-ptr!]
	
	GetStaticMethodID			[func-ptr!]
	
	CallStaticObjectMethod		[func-ptr!]
	CallStaticObjectMethodV		[func-ptr!]
	CallStaticObjectMethodA		[func-ptr!]
	
	CallStaticBooleanMethod		[func-ptr!]
	CallStaticBooleanMethodV	[func-ptr!]
	CallStaticBooleanMethodA	[func-ptr!]
	
	CallStaticByteMethod		[func-ptr!]
	CallStaticByteMethodV		[func-ptr!]
	CallStaticByteMethodA		[func-ptr!]
	
	CallStaticCharMethod		[func-ptr!]
	CallStaticCharMethodV		[func-ptr!]
	CallStaticCharMethodA		[func-ptr!]
	
	CallStaticShortMethod		[func-ptr!]
	CallStaticShortMethodV		[func-ptr!]
	CallStaticShortMethodA		[func-ptr!]
	
	CallStaticIntMethod			[func-ptr!]
	CallStaticIntMethodV		[func-ptr!]
	CallStaticIntMethodA		[func-ptr!]
	
	CallStaticLongMethod		[func-ptr!]
	CallStaticLongMethodV		[func-ptr!]
	CallStaticLongMethodA		[func-ptr!]
	
	CallStaticFloatMethod		[func-ptr!]
	CallStaticFloatMethodV		[func-ptr!]
	CallStaticFloatMethodA		[func-ptr!]
	
	CallStaticDoubleMethod		[func-ptr!]
	CallStaticDoubleMethodV		[func-ptr!]
	CallStaticDoubleMethodA		[func-ptr!]
	
	CallStaticVoidMethod		[func-ptr!]
	CallStaticVoidMethodV		[func-ptr!]
	CallStaticVoidMethodA		[func-ptr!]
	
	GetStaticFieldID			[func-ptr!]
	GetStaticObjectField		[func-ptr!]
	GetStaticBooleanField		[func-ptr!]
	GetStaticByteField			[func-ptr!]
	GetStaticCharField			[func-ptr!]
	GetStaticShortField			[func-ptr!]
	GetStaticIntField			[func-ptr!]
	GetStaticLongField			[func-ptr!]
	GetStaticFloatField			[func-ptr!]
	GetStaticDoubleField		[func-ptr!]
	
	SetStaticObjectField		[func-ptr!]
	SetStaticBooleanField		[func-ptr!]
	SetStaticByteField			[func-ptr!]
	SetStaticCharField			[func-ptr!]
	SetStaticShortField			[func-ptr!]
	SetStaticIntField			[func-ptr!]
	SetStaticLongField			[func-ptr!]
	SetStaticFloatField			[func-ptr!]
	SetStaticDoubleField		[func-ptr!]
	
	NewString					[func-ptr!]
	GetStringLength				[func-ptr!]
	GetStringChars				[func-ptr!]
	ReleaseStringChars			[func-ptr!]
	
	NewStringUTF				[function! [env [JNI-ptr!] bytes [c-string!] return: [jobject!]]]
	GetStringUTFLength			[func-ptr!]
	GetStringUTFChars			[func-ptr!]
	ReleaseStringUTFChars		[func-ptr!]
	
	
	;...
]

JNI-env!: alias JNI-ptr!


get-method: func [
	env		[JNI-env!]
	class	[jclass!]
	name	[c-string!]
	sig		[c-string!]
	return: [jmethodID!]
	/local
		id 	[jmethodID!]
][
	id: env/jni/GetMethodID env class name sig
	if null? id [print-line ["error: GetMethodID failed on " name]]
	id
]

instantiate: func [
	[typed]
	count	[integer!]
	list	[typed-value!]
	return: [jobject!]
	/local
		env	  [JNI-env!]
		class [jclass!]
		id	  [jmethodID!]
		item  [typed-value!]
][
	env: as JNI-env! list/value
	list: list + 1
	class: as jclass! list/value
	list: list + 1
	id: get-method env class "<init>" as c-string! list/value
	list: list - 2
	
	while [count > 0][
		either count = 3 [
			push id										;-- replace sig by the constructor id
		][
			item: list + count - 1	
			either item/type = type-c-string! [		
				push env/jni/NewStringUTF env as c-string! item/value
			][
				push item/value
			]
		]
		count: count - 1
	]
	env/jni/NewObject
]

JNI_OnLoad: func [
	vm 		 [int-ptr!]
	reserved [byte-ptr!]
	return:  [integer!]
][
	version-1.6
]

#export JNICALL [
	JNI_OnLoad
]