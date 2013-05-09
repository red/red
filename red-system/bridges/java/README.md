JNI low-level binding
------------------------

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

If you are using a 64-bit JVM, use the following command line for launching the app:

        $ java -d32 -Djava.library.path=. JNIdemo

You should see an AWT window opening with a small message.