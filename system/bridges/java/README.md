JNI low-level binding
------------------------

A 32-bit JVM is required for this to work. 

In order to compile the example JNIdemo script, follow these steps:

On Windows:

1. Compile the JNIdemo.reds script as a shared library:

        >> do/args %rsc.r "-dlib %bridges/java/JNIdemo.reds -o %bridges/java/JNIdemo"

2. Compile and run the JNIdemo.java app from console:

        $ javac JNIdemo.java
        $ java JNIdemo

On Unix:

1. Compile the JNIdemo.reds script as a shared library:

        >> do/args %rsc.r "-dlib %bridges/java/JNIdemo.reds -o %bridges/java/libJNIdemo"

2. Compile and run the JNIdemo.java app from console:

        $ javac JNIdemo.java
        $ java -Djava.library.path=. JNIdemo

You should see an AWT window opening with a small message.

_Note: On macOS, using the -d32 option allows to load the 32-bit JNI library, but some exceptions are thrown on exit anyway._
