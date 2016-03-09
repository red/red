Red/System [
	Title:   "JVM bridge demo"
	Author:  "Nenad Rakocevic"
	File: 	 %JNIdemo.reds
	Type:	 'dll
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %JNI.reds

Java_events_Receive: func [
	env		[JNI-env!]
	this	[jobject!]
	event	[integer!]
	/local
		sys [jclass!]
		id  [jmethodID!]
][
	print ["event received: " event lf]
	switch event [
		201 [
			sys: env/jni/FindClass env "java/lang/System"
			id: get-static-method env sys "exit" "(I)V"
			env/jni/CallStaticObjectMethod [env sys id 0]
		]
	]
]

Java_JNIdemo_doMain: func [
	env		[JNI-env!]
	this	[jobject!]
	/local
		jni	  [JNI!]
		class [jobject!]
		frame [jobject!]
		label [jobject!]
		event [jobject!]
		id	  [jmethodID!]
][
	jni: env/jni
	class: jni/FindClass env "java/awt/Frame"
	frame: instantiate [env class "(Ljava/lang/String;)V" "Red AWT/JNI demo"]

	label: instantiate [
		env
		jni/FindClass env "java/awt/Label"
		"(Ljava/lang/String;I)V"
		"AWT app built from Red/System through JNI!"
		1												;-- CENTER: 1
	]
	
	id: get-method env class "add" "(Ljava/awt/Component;)Ljava/awt/Component;"
	jni/CallObjectMethod [env frame id label]
	
	id: get-method env class "setSize" "(II)V"
	jni/CallObjectMethod [env frame id 300 100]
	
	id: get-method env class "setVisible" "(Z)V"
	jni/CallObjectMethod [env frame id JNI_TRUE]
	
	event: instantiate [env jni/FindClass env "events" "()V"]
	
	id: get-method env class "addWindowListener" "(Ljava/awt/event/WindowListener;)V"
	jni/CallObjectMethod [env frame id event]
]


#export JNICALL [
	Java_events_Receive
	Java_JNIdemo_doMain
]