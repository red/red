Building Red binaries
------------------------

_Prerequisite_

_You need a [Rebol SDK](http://www.rebol.com/sdk.html) copy with a valid license file in order to rebuild the Red binary, this is a constraint from using Rebol2 for the bootstrapping. Once selfhosted, Red will not have such constraint._

In order to build a Red binary:

1. Place a copy of one of the [encappers](http://www.rebol.com/docs/sdk/kernels.html) ( **enpro** would be a right choice) along with a copy of **license.key** file into the **%build/** folder.

2. Make a copy of **encap-paths.r.sample** file and name it **encap-paths.r**.

3. Edit **encap-paths.r** file and adjust the paths to your Rebol SDK folders.

4. Open a Rebol console, and CD to the **%build/** folder.

        >> change-dir %<path-to-Red>/build/

5. Run the build script from the console:

        >> do %build.r
        
6. After a few seconds, a new **red** binary will be available in the **build/bin/** folder.

7. Enjoy!


Red Command-Line Usage
------------------------

Syntax

    red <options> <script>
    
with:

    <script>: Red script filename with optional path.

    <options>:
    
        -d			: switches into debug mode.
    
        -o <file>	: outputs executable to given path and/or filename.
    
        -t <target>	: cross-compiles to another target (see table below).
    
        -v <level>	: sets verbose mode. 1-3 are for Red only, above for Red/System.