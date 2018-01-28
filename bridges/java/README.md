Red/Java Bridge
------------------------

This is a prototype of a higher-level Red to Java bridge using JNI.

A 32-bit JVM is required for this to work. 

In order to compile the example hello.red script, open a Rebol2 console and follow these steps:

On Windows:

1. Compile the hello.red script as a shared library:

        >> do/args %red.r "-dlib -o %bridges/java/hello %bridges/java/hello.red"   

2. Compile and run the bridge.java app from console:

        $ javac bridge.java
        $ java bridge

On Unix:

1. Compile the hello.red script as a shared library:

        >> do/args %red.r "-dlib -o %bridges/java/libhello %bridges/java/hello.red"

2. Compile and run the bridge.java app from console:

        $ javac bridge.java
        $ java -Djava.library.path=. bridge

You should see an AWT window opening with a small message.

_Note: On macOS, using the -d32 option allows to load the 32-bit JNI library, but some exceptions are thrown on exit anyway._


Red/Java bridge current API
----------------------------

* java-new: instantiate a Java class, returns a Java object.

* java-do: invoke an object's method with arguments.

* on-java-event: called by the JVM when a registered event occurs.
