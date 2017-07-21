There are many ways to contribute to Red in addition to making [donations](http://www.red-lang.org/p/donations.html). This is a simple "how to" guide.

There are seven different ways to contribute to the Red project:
* Make fixes and enhancements to the Red and Red/System core and runtimes
* Write and maintain Red mezzanine functions, modules, objects and schemes   
* Write and maintain documentation and documentation systems
* Write and maintain Red and Red/System tests
* Use Red and Red/System and submit meaningful bug reports

No matter how small, your contribution will be valued and appreciated providing that you follow the guidelines. In particular, isolating bugs so that they can be easily identified and fixed is a great help.

### General Contribution Guidelines
1. You should be sure that you own the Intellectual Property Rights(IP) of any contribution you make to the Red project.
2. By submitting a contribution to the Red project, you are granting the Red project and, in particular, Nenad Rakocevic the right to publish your submission.
(A simple way for you to confirm both 1 & 2 will be introduced in due course.)
3. A lot of care and attention has been given to the design of both the Red and Red-System languages. Before starting work on anything to change or extend either language, please submit a proposal for your change by raising an issue on the Red project GitHub repository. (It could save you a lot of unnecessary work.)
4. All code submissions should include a reasonable set of tests written with [quick test](http://static.red-lang.org/red-system-quick-test.html).

### Coding Standards
All contributions should adhere to the following coding standards

1. All source code should be UTF-8 encoded.
2. All indents should be made using tabs not spaces and be 4 characters wide.
3. Functions specifications that don't include the datatypes of the arguments and locals should be kept concise. The specification should be on same line as function name, unless it doesn't fit on a line of around 90 characters. If the specification cannot fit on one line, the arguments and locals should be on different lines. If necessary put refinements on a separate line.
4. Function specifications that include datatypes should follow a vertical layout.
5. End-of-line comments are preferred over between line comments. They should be preceded with ";—-" starting at position 57.
```

short-spec: func [
    arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9
    /refinement1 ref1-arg1 ref1-arg2 /refinement2 ref2-arg2 ref2-arg3
    /local local1 local2 local3 local4 local5 local6 local7
][
    …
]

shorter-spec: func [
    arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 /refinement1 ref1-arg1 ref1-arg2 
    /local local1 local2 local3 local4 local5 local6 local7
][
    …
]

shortest-spec: func [ arg1 arg2 /refinement ref-arg /local local1 local2] [
    …
]

vertical-spec: func [
    arg1   [datatype!]
    arg2   [datatype!]
    /local
        local1    [datatype!]
        local2    [datatype!]     
][
    …
]
 
    my-result: my-fantastic-func a b                    ;-- my very clever comment
``` 


### Test Standards
Every code-based contribution should be accompanied by a meaningful set of tests. Tests should be written using the quick-test.red or quick-test.reds frameworks. Tests requiring checking console output from your code or compiler message should be written using quick-test.r. If you are unfamiliar with quick-test, check out the [documentation](http://static.red-lang.org/red-system-quick-test.html).

The following approach to writing tests should be used:

1. A separate test file should be used for each functional unit included in your code that you submit.
2. The test must run successfully on Windows, Linux and OS X.
3. Tests should be written for the compiler in preference to the interpreter.
4. Tests should be grouped by functionality.
5. Each test should be independent from all other tests. The results of a test should not be dependent upon the results of any other test. (It should be possible to remove any test from a file and the other tests should still all pass).
6. Each test should have a unique "name" so that it can be quickly found by searching the test file.
7. The project coding standards should be followed.
8. For short tests both the test header and the assert should be written on a single line.
9. With longer multi-line tests, the assert should be indented from the test header.
10. The following indentation scheme should be used:
```
Red [ … ]
#include %<path-to>/quick-test/quick-test.red

~~~start-file~~~ "my-contribution"

        startup code

===start-group=== "my-cont-func-str"

        group start up code

    --test-- "mcf-str-1" --assert "yes" = my-cont-func "A string"

    --test-- "mcf-str-2"
        mcf-str-2-str: "A string"
        --assert "yes" = my-cont-func mcf-str-2-str

       group tidy up code

===end-group===

===start-group=== "my-cont-func-block"

        group start up code

    --test-- "mcf-blk-1" --assert "no" = my-cont-func [a b c d]

    --test-- "mcf-blk-2"
        mcf-blk-2-blk: [a b c d]
        --assert "no" = my-cont-func mcf-blk-2-blk

       group tidy up code

===end-group===

       file tidy up code

~~~end-file~~~

```

### Red and Red/System core and runtimes
Contributions to the Red and Red/System core and runtimes should:

1. Conform to coding and testing standards.
2. Use Doc-Strings to document their API.
3. As much as possible, reflect the coding style of the existing core and runtimes.
4. Follow the existing core and runtime naming conventions and file locations.

### Red mezzanine functions, modules, objects and schemes
In the Red project, mezzanine code refers to functions, modules, objects and schemes written in Red that are included in the Red binary. 

The process for code to be included as Red mezzanine is as follows:

1. Submit a pull request of the code for inclusion with Red.
2. Once the code is included in the Red library, submit a proposal for its inclusion within the Red mezzanine code via a Red project GitHub issue.
3. If the proposal is accepted by the Red project team, submit a pull request with your code included as mezzanine code and a revised set of tests.

At the current stage of Red's development, mezzanine code is not yet being accepted so please do not submit proposals until they are.

### Documentation and documentation systems
At the moment, the content and format of Red documentation has still to be decided, as has the mechanism for automatically generating API documentation from the source. Please contact the Red team if you would like to volunteer. A reliable way to contact the Red team is via the [Red Group](https://groups.google.com/forum/?hl=en#!forum/red-lang).

### Red and Red/System tests
Writing additional tests is both an easy way to contribute to Red and a good way to learn the finer details of Red and Red/System. All you need to do is find the test file for a feature that you would like to help with and add some tests. Nothing could be easier.


### Using Red and Red/System and Submitting Bug reports
The more you use Red and Red/System the more likely you are to find hidden bugs that have smuggled themselves past the tests. Your finding those bugs is very helpful if you can actually isolate the bug. 

A major contribution is submitting bug reports that clearly identify the source of a bug. This requires not only isolating the bug but also writing concise code which demonstrates the bug.
