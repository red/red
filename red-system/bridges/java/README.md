JNI low-level binding
------------------------

In order to compile the example JNIdemo script, follow these steps:

1. Compile the JNIdemo.reds script as a shared library:

        >> do/args %rsc.r "%bridge/java/JNIdemo.reds -o %bridge/java/JNIdemo"

2. Compile and run the JNIdemo.java app from console:

        $ javac JNIdemo.java
        $ java JNIdemo

You should see an AWT window opening with a small message.